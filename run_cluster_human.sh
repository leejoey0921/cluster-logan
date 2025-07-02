#!/bin/bash -e

# changeme
jobqueue=LoganClusteringJobQueueDisques
jobdef=logan-clustering-job

dryrun=$1

JOBTIMEOUT=172800 # 48 hour max per job
# for copy, timelimit was 40000, aiming at > 20 GB/hour processed by core, should be around 140 GB/hour when all alone
# TODO: FIX
JOBSIZE=100 # human-00000 to human-00099

echo "Running run_cluster_human.sh with params"
echo "jobqueue=$jobqueue"
echo "jobdef=$jobdef"

# Check dryrun
MAYBEDRY=""
if [ -n "$dryrun" ]; then
	echo "this is a dry run"
    MAYBEDRY="echo "
fi

set=$(cat set)
date=$(date +"%F")
arch=$(uname -m)
tag=logan-clustering-$arch-$date-$set
echo "tag: $tag"

$MAYBEDRY aws batch submit-job \
            --job-name "$tag" \
            --job-definition "$jobdef"  \
            --job-queue  "$jobqueue" \
            --array-properties "{ \"size\": ${JOBSIZE} }" \
            --timeout attemptDurationSeconds="$JOBTIMEOUT"
echo "array job submitted!"
