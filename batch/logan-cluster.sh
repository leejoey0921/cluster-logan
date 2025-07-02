#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# logan-cluster.sh
# =====================================
set -euo pipefail

rm -rf /localdisk/logan-cluster-run
mkdir /localdisk/logan-cluster-run && cd /localdisk/logan-cluster-run

echo "Logan clustering"
# get instance type
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

s3fastaprefix="s3://serratus-rayan/beetles/logan_oct7_run/prodigal-concat/"

inputfilename="inputfile.txt"
s3inputfile="s3://logan-cluster/input/${inputfilename}"
s3resultprefix="s3://logan-cluster/output/"

echo "START: DOWNLOAD INPUTFILE"
aws s3 cp "${s3inputfile}" . --no-progress
echo "COMPLETE: DOWNLOAD INPUTFILE"


echo "START: PARSE JOB BLOCK"
: '
input file will be formatted like the following:
00000
file1.fa
file2.fa

00001
file3.fa
'
awk -v JOBID="$jobid" '
  $0 == JOBID {reading=1; next}
  /^[0-9]{5}$/ && $0 != JOBID && reading {exit}
  reading && NF>0 {print}
' "$inputfilename" > jobfiles.txt
echo "COMPLETE: PARSE JOB BLOCK"

echo "INPUT FILES:"
cat jobfiles.txt

echo "START: DOWNLOAD FASTAS"
fasta_list=""
while read -r fname; do
    aws s3 cp "${s3fastaprefix}${fname}" . --no-progress
    echo "Copied: $fname"
    zstd -d "$fname" && rm "$fname"
    base="${fname%.*}"
    fasta_list="${fasta_list} ${base}"
done < jobfiles.txt
echo "COMPLETE: DOWNLOAD FASTAS"
df -h / /localdisk

MAX_LINES=3000000000

echo "START: SPLIT FASTA"
mkdir -p split-chunks
(
  for f in $fasta_list; do
    cat "$f"
    rm "$f"
  done
) | split -l "$MAX_LINES" -d -a 3 - split-chunks/split-

for f in split-chunks/split-*; do
    mv "$f" "$f.fa"
done
echo "COMPLETE: SPLIT FASTA"
du -sh split-chunks/split-*.fa
df -h / /localdisk

mkdir -p result/tsv result/fa

i=0
for split_file in split-chunks/split-*.fa; do
    mkdir db tmp

    db="db/db"
    rep="db/rep"
    clu="db/clu"
    tsv="result/tsv/${jobid}-clu-${i}.tsv"
    fasta="result/fa/${jobid}-rep-${i}.fa"

    echo "START: CREATEDB ${i}"
    time mmseqs createdb "$split_file" "$db" --shuffle 0 --write-lookup 0 --createdb-mode 1
    echo "COMPLETE: CREATEDB ${i}"

    echo "START: CLUSTER ${i}"
    time mmseqs linclust "$db" "$clu" tmp -c 0.9 --cov-mode 1 --min-seq-id 0.9 --remove-tmp-files 1 --split-memory-limit 700G --threads 63
    echo "COMPLETE: CLUSTER ${i}"

    echo "START: STORE CLUSTER TSV ${i} TO S3"
    time mmseqs createtsv "$db" "$db" "$clu" "$tsv" --threads 63
    time zstd "$tsv" && rm "$tsv"
    aws s3 cp "${tsv}.zst" "${s3resultprefix}tsv/" --no-progress && rm "${tsv}.zst"
    echo "COMPLETE: COPY CLUSTER TSV ${i} TO S3"

    echo "START: COPY REP FASTA ${i} TO S3"
    time mmseqs createsubdb "$clu" "$db" "$rep" --subdb-mode 1
    time mmseqs convert2fasta "$rep" "$fasta"
    time zstd "$fasta" && rm "$fasta"
    aws s3 cp "${fasta}.zst" "${s3resultprefix}fa/" --no-progress && rm "${fasta}.zst"
    echo "COMPLETE: COPY REP FASTA ${i} TO S3"

    df -h / /localdisk
    echo "CLEANING UP DISK SPACE"

    rm -rf db tmp clu "$split_file"
    i=$((i+1))
    echo "STATUS CHECK AFTER ${i}th SPLIT RUN"
    date
    df -h / /localdisk
done

echo "COMPLETE"
