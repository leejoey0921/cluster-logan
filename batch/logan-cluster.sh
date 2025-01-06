#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# logan-cluster.sh
# =====================================
set -euo pipefail


while getopts i:o:t:vh FLAG; do
  case $FLAG in
    t)
      THREADS=$OPTARG
      ;;
    \?) #unrecognized option - show help
      echo "Input parameter not recognized"
      usage
      ;;
  esac
done


echo "Logan cluster"
echo "Number of threads: $THREADS"
# get instance type
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
instance_type=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
echo "Instance type: $instance_type"

date
df -h / /localdisk

jobid=0

# job id (00000~00099)
echo "Array job: ${AWS_BATCH_JOB_ARRAY_INDEX-}"
printf -v padded_number "%05d" ${AWS_BATCH_JOB_ARRAY_INDEX-}
S3FILE="$S3FILE"$padded_number
jobid=$padded_number

# split_file(filename, split count, file line count, output prefix)
# ex) filename=foo.fa -> prefix0.fa, prefix1.fa, ...
split_file() {
    local file="$1"
    local number_of_splits="$2"
    local line_count="$3"
    local prefix="$4"

    local lines_per_split=$(( (line_count + number_of_splits - 1) / number_of_splits ))

    split -l "${lines_per_split}" -d -a 1 "${file}" "${prefix}"

    for i in $(seq 0 $((number_of_splits-1))); do
        mv "${prefix}${i}" "${prefix}${i}.fa"
    done
}


partial="human-${jobid}-partial.fa"
complete="human-${jobid}-complete.fa"
s3prefix="s3://serratus-rayan/beetles/logan_oct7_run/prodigal-concat/"

# copy compressed fastas from s3
aws s3 cp "${s3prefix}${partial}.zst" .
aws s3 cp "${s3prefix}${complete}.zst" .

# 8 billion (4 billion seqs)
MAX_LINES=8000000000

echo "START: SPLIT FASTA"
# count lines
lines_partial=$(wc -l < "${partial}")
lines_complete=$(wc -l < "${complete}")
sum_lines=$((lines_partial + lines_complete))

if [[ "${sum_lines}" -le "${MAX_LINES}" ]]; then
    number_of_splits=1
    mv "${partial}"  "human-${jobid}-partial-0.fa"
    mv "${complete}" "human-${jobid}-complete-0.fa"
else
    # split file ceil(sum_lines / MAX_LINES)
    number_of_splits=$(( (sum_lines + MAX_LINES - 1) / MAX_LINES ))

    split_file "${partial}" "${number_of_splits}" "${lines_partial}" "human-${jobid}-partial-"
    rm "${partial}"
    split_file "${complete}" "${number_of_splits}" "${lines_complete}" "human-${jobid}-complete-"
    rm "${complete}"
fi
echo "COMPLETE: SPLIT FASTA"

mkdir db tmp clu result
for i in $(seq -w 0 $((number_of_splits-1))); do
    partial_file="human-${jobid}-partial-${i}.fa"
    complete_file="human-${jobid}-complete-${i}.fa"
    splitname="human-${jobid}-${i}"

    db="db/${splitname}-db"
    rep="db/${splitname}-rep"
    clu="clu/${splitname}"
    tsv="result/tsv/${splitname}-clu.tsv"
    fasta="result/fa/${splitname}-rep.fa"

    echo "START: CREATEDB ${i}"
    time ./mmseqs createdb $partial_file $complete_file $db --shuffle 0 --write-lookup 0
    rm $partial_file $complete_file
    echo "COMPLETE: CREATEDB ${i}"

    echo "START: CLUSTER ${i}"
    time ./mmseqs linclust $db $clu tmp -c 0.9 --cov-mode 1 --min-seq-id 0.3 --threads $THREADS
    time ./mmseqs createtsv $db $db $clu $tsv --threads $THREADS
    time zstd $tsv && rm $tsv
    time ./mmseqs createsubdb $clu $db $rep
    time ./mmseqs convert2fasta $rep $fasta
    time zstd $fasta && rm $fasta

    # TODO: decide whether to align reps to human genome
    # aln="db/${splitname}-aln"

    # # TODO: copy and unpack human orfs from S3
    # orfs="db/orfs_aa"
    # alntsv="result/tsv/${splitname}-rep-aln.tsv"
    # alnrep="db/${splitname}-rep-alnfilter"
    # alnfasta="result/fa/${splitname}-rep-alnfilter.fa"
    # 
    # time ./mmseqs search $rep $orfs $aln $tmp --threads $THREADS --min-seq-id 0.9 --exact-kmer-matching 1 --mask 0 --comp-bias-corr 0 --alignment-mode 4
    # time ./mmseqs createtsv $rep $orfs $aln "${tsv}"
    # extract seqs WITHOUT alignment to fasta
    # time ./mmseqs filterdb $rep $alnrep --filter-file "${aln}.index" --positive-filter false
    # time ./mmseqs convert2fasta $alnrep $alnfasta
    # time zstd $alnfasta && rm $alnfasta

    # cleanup to free disk space
    rm "${db}"* "${rep}"* "${clu}"*
    rm -r tmp/*
    echo "COMPLETE: CLUSTER ${i}"
done

# TODO: check output s3 location
# store result to S3
s3resultprefix="s3://serratus-rayan/joey/logan-cluster/"
aws s3 cp result/tsv/* "${s3resultprefix}tsv/"
aws s3 cp result/fa/* "${s3resultprefix}fa/"

echo "Logan cluster, all done!"
date
df -h / /localdisk
