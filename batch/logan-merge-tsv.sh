#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# logan-merge-tsv.sh
# =====================================
set -euo pipefail

SRC_ROUND="first"
DST_ROUND="fifth"
SET1="human"
SET2="partial"
THREAD_COUNT=95
SORT_RESULT=true    # needs to be in order only in the final round
DEBUG=false         # check if the sequence counts match between src and dst

rm -rf /localdisk/logan-cluster-run /localdisk/sort-tmp
mkdir /localdisk/sort-tmp
mkdir /localdisk/logan-cluster-run && cd /localdisk/logan-cluster-run

echo "Logan merge cluster output tsvs"
# Get instance type
TOKEN=$(curl -X PUT "http://169.254.169.254/latest/api/token" -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600")
instance_type=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
echo "Instance type: $instance_type"

date
df -h / /localdisk

jobid=0
AWS_BATCH_JOB_ARRAY_INDEX=${AWS_BATCH_JOB_ARRAY_INDEX:-0}
echo "Array job: ${AWS_BATCH_JOB_ARRAY_INDEX-}"
printf -v padded_number "%05d" "${AWS_BATCH_JOB_ARRAY_INDEX-}"
jobid=$padded_number

s3srcprefix="s3://logan-cluster/${SRC_ROUND}/${SET1}/${SET2}/tsv/"
srclistname="${SET1}-${SET2}-src.txt"
s3srclist="s3://logan-cluster/${DST_ROUND}/${SET1}/${SET2}/${srclistname}"

s3dstprefix="s3://logan-cluster/${DST_ROUND}/${SET1}/${SET2}/tsv/"
dstlistname="${SET1}-${SET2}-dst.txt"
s3dstlist="s3://logan-cluster/${DST_ROUND}/${SET1}/${SET2}/${dstlistname}"

mkdir src-files dst-files

echo "START: DOWNLOAD SRC INPUTFILE"
aws s3 cp "${s3srclist}" . --no-progress
echo "COMPLETE: DOWNLOAD SRC INPUTFILE"

echo "START: PARSE SRC JOB BLOCK"
awk -v JOBID="$jobid" '
  $0 == JOBID {reading=1; next}
  /^[0-9]{5}$/ && $0 != JOBID && reading {exit}
  reading && NF>0 {print}
' "$srclistname" > srcfiles.txt
echo "COMPLETE: PARSE SRC JOB BLOCK"

echo "INPUT SRC FILES:"
cat srcfiles.txt

# --- Parallelized download of SRC TSV files ---
echo "START: DOWNLOAD SRC TSV"
max_parallel=5
src_tmp_file="downloaded_src_files.txt"
rm -f "$src_tmp_file"

download_and_decompress_src() {
    local fname="$1"
    aws s3 cp "${s3srcprefix}${fname}" src-files/ --no-progress
    echo "Copied: $fname"
    zstd -d "src-files/${fname}" && rm "src-files/${fname}"
    local base="src-files/${fname%.*}"
    echo "$base" >> "$src_tmp_file"
}

while read -r fname; do
    download_and_decompress_src "$fname" &
    # Control concurrency: wait if we've reached max_parallel jobs.
    while [ "$(jobs -p | wc -l)" -ge "$max_parallel" ]; do
         wait -n
    done
done < srcfiles.txt

wait
echo "COMPLETE: DOWNLOAD SRC TSV"
# Load downloaded source filenames into an array for later use.
readarray -t src_list < "$src_tmp_file"

df -h / /localdisk
date

echo "START: DOWNLOAD DST INPUTFILE"
aws s3 cp "${s3dstlist}" . --no-progress
echo "COMPLETE: DOWNLOAD DST INPUTFILE"

echo "START: PARSE DST JOB BLOCK"
awk -v JOBID="$jobid" '
  $0 == JOBID {reading=1; next}
  /^[0-9]{5}$/ && $0 != JOBID && reading {exit}
  reading && NF>0 {print}
' "$dstlistname" > dstfiles.txt
echo "COMPLETE: PARSE DST JOB BLOCK"

echo "INPUT DST FILES:"
cat dstfiles.txt

echo "START: DOWNLOAD DST TSV"
declare -a dst_list=()
while read -r fname; do
    aws s3 cp "${s3dstprefix}${fname}" dst-files/ --no-progress
    echo "Copied: $fname"
    zstd -d "dst-files/${fname}" && rm "dst-files/${fname}"
    base="dst-files/${fname%.*}"
    dst_list+=("$base")
done < dstfiles.txt
echo "COMPLETE: DOWNLOAD DST TSV"
df -h / /localdisk
du -sh src-files/*.tsv dst-files/*.tsv
date

# Concatenate into one merged source file
for file in "${src_list[@]}"; do
    parallel --pipe -j "$THREAD_COUNT" --block 10M "awk -F'\t' '\$1 != \$2'" < "$file" >> merged_src.tsv
    if [ "$DEBUG" != "true" ]; then
        rm "$file"
    fi
done
echo "COMPLETE: MERGE SRC"
date

# Sort by the first column
time sort -T /localdisk/sort-tmp -t$'\t' -k1,1 merged_src.tsv -o merged_src.tsv --buffer-size=90% --parallel="$THREAD_COUNT"
echo "COMPLETE: SORT SRC"

for dst in "${dst_list[@]}"; do
    echo "Processing ${dst} ..."

    # Sort this dst file by the second column (member)
    time sort -T /localdisk/sort-tmp -t$'\t' -k2,2 "$dst" -o "$dst" --buffer-size=90% --parallel="$THREAD_COUNT"
    echo "COMPLETE: SORT ${dst}"

    # Join where merged_src.col1 = dst.col2 and append dst.col1 merged_src.col2
    append_dst="append_$(basename "$dst")"
    time join -1 1 -2 2 -t$'\t' -o '2.1 1.2' merged_src.tsv "$dst" > "$append_dst"
    echo "COMPLETE: JOIN ${dst}"

    du -sh "$dst" "$append_dst"

    time cat "$append_dst" >> "$dst" && rm "$append_dst"
    echo "COMPLETE: APPEND ${dst}"

    # Re-sort by first column while keeping rep first in order
    if [ "$SORT_RESULT" = "true" ]; then
        date
        echo "START: RE-SORT ${dst}" && date
        zstd "$dst"
        aws s3 cp "${dst}.zst" "${s3dstprefix}${SET1}-${SET2}-${SRC_ROUND}-final-unsorted.tsv.zst" --no-progress
        rm "${dst}.zst"
        parallel --pipe -j "$THREAD_COUNT" --block 10M --keep-order \
        "awk 'BEGIN {FS=OFS=\"\t\"} { tmp = (\$1 == \$2) ? 0 : 1; print \$1, tmp, \$2 }'" < "$dst" \
        | sort -T /localdisk/sort-tmp -t$'\t' -k1,1 -k2,2 -k3,3 --buffer-size=90% --parallel="$THREAD_COUNT" \
        | parallel --pipe -j "$THREAD_COUNT" --block 10M --keep-order \
        "awk 'BEGIN {FS=OFS=\"\t\"} { print \$1, \$3 }'" \
        > finalfile
        mv finalfile "$dst"
        echo "COMPLETE: RE-SORT ${dst}" && date
    fi
    zstd "$dst"
    if [ "$DEBUG" != "true" ]; then
        rm "$dst"
    fi
    aws s3 cp "${dst}.zst" "${s3dstprefix}${SET1}-${SET2}-${SRC_ROUND}-final.tsv.zst" --no-progress
    rm "${dst}.zst"

    echo "Done processing ${dst}."
done

if [ "$DEBUG" = "true" ]; then
    echo "Checking if line counts match..." && date
    # Check if line count matches and print error if it doesn't
    src_lines=$(awk 'NF' "${src_list[@]}" | wc -l)
    dst_lines=$(awk 'NF' "${dst_list[@]}" | wc -l)

    if [[ "$src_lines" != "$dst_lines" ]]; then
        echo "ERROR: line counts do not match: src_lines=${src_lines}, dst_lines=${dst_lines}"
        echo "Calculating missing sequences..."
        cat "${src_list[@]}" | awk -F"\t" '{print $2 "\t" $1}' > missing.tsv
        sort -T /localdisk/sort-tmp -t$'\t' -k1,1 missing.tsv -o missing.tsv --buffer-size=90% --parallel="$THREAD_COUNT" 
        for f in "${dst_list[@]}"; do
            sort -T /localdisk/sort-tmp -t $'\t' -k2,2 "$f" --buffer-size=90% --parallel="$THREAD_COUNT" > "resorted_$f"
            join -v 1 -1 1 -2 2 -t$'\t' missing.tsv "resorted_$f" > next_missing.tsv
            mv next_missing.tsv missing.tsv
        done
        echo "Missing sequences:"
        awk -F"\t" '{print $2 "\t" $1}' missing.tsv
    fi
    date
fi

echo "COMPLETE"
