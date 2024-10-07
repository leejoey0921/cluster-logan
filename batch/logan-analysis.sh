#!/bin/bash
# ENTRYPOINT SCRIPT ===================
# logan-analysis.sh
# =====================================
set -eu

# modify me
#task=copy
#task=analysis_april26
#task=analysis_july1
#task=analysis_aug24
#task=analysis_aug26
task=analysis_oct7

# Usage
function usage {
  echo ""
  echo "Usage: docker run logan-analysis-job-x86_64 [OPTIONS]"
  echo ""
  echo "    -h    Show this help/usage message"
  echo ""
  echo "    Required Fields"
  echo "    -i    S3 path of list of Logan unitigs/contigs to process [s3://bucket/file.txt]"
  echo "    -o    Output S3 bucket name [testbucket]"
  echo "    -t    Number of threads"
  echo ""
  echo 'ex: docker build -t logan-analysis-job-x86_64 . && docker run logan-analysis-job-x86_64 -i s3://bucket/file.txt -o testbucket'
  false
  exit 1
}

S3FILE=''
OUTBUCKET=''
VERBOSE='false'

function log () {
    if [[ $VERBOSE == 'TRUE' ]]
    then
        echo "$@"
    fi
}

while getopts i:o:t:vh FLAG; do
  case $FLAG in
    # Search Files  -----------
    i)
      S3FILE=$OPTARG
      ;;
    o)
      OUTBUCKET=$OPTARG
      ;;
    t)
      THREADS=$OPTARG
      ;;
	v)
      VERBOSE='TRUE'
      ;;
    h)  #show help ----------
      usage
      ;;
    \?) #unrecognized option - show help
      echo "Input parameter not recognized"
      usage
      ;;
  esac
done

if [ -z "$S3FILE" ]; then
  echo "Error: Input file (-i) is not set."
  usage
fi

if [ -z "$OUTBUCKET" ]; then
  echo "Error: Output name (-o) is not set."
  usage
fi

source tasks/$task.sh

echo "Logan analysis, task: $task"
echo "Number of threads: $THREADS"
# get instance type
TOKEN=`curl -X PUT "http://169.254.169.254/latest/api/token" -s -H "X-aws-ec2-metadata-token-ttl-seconds: 21600"`
instance_type=$(curl -H "X-aws-ec2-metadata-token: $TOKEN" -s http://169.254.169.254/latest/meta-data/instance-type)
echo "Instance type: $instance_type"

date
df -h / /localdisk

# Check if Array Job
if [[ -z "${AWS_BATCH_JOB_ARRAY_INDEX-}" ]]
then
    echo "Not an array job"
    echo "Is this supported? I haven't bothered implementing just 1 input file"
    echo "If this crashes, fix the bug, or just add s3://logan-pub/c/DRR000001/DRR000001.contigs.fa.zst to your input so that it has at least 2 files.."
    #exit 1
else
    echo "Array job: ${AWS_BATCH_JOB_ARRAY_INDEX-}"
    printf -v padded_number "%05d" ${AWS_BATCH_JOB_ARRAY_INDEX-}
    S3FILE="$S3FILE"$padded_number
fi

# grab the list of accessions
s5cmd cp -c 1 $S3FILE s3file.txt
nb_files=$(wc -l < s3file.txt)
echo "$nb_files files to process"
counter=0

# for each accession (represented as a s3 path), do the task (e.g. copy)
for s3elt in $(cat s3file.txt)
do
    # currently $OUTBUCKET is not read
	task $s3elt $THREADS $OUTBUCKET
    counter=$((counter + 1))
    echo "Logan analysis: $counter of $nb_files tasks completed."
done

echo "Logan analysis, all done!"
date
df -h / /localdisk
