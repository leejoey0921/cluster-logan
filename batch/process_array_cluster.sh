#!/bin/bash -e

# changeme
jobqueue=LoganClusterJobQueueDisques
# TODO: determine thread count per job
vcpus=8 # important, is also passed to container in the THREADS variable. number of vcpus per task.
jobdef=logan-cluster-${vcpus}c-job

dryrun=$1

JOBTIMEOUT=172800 # 48 hour max per job
# for copy, timelimit was 40000, aiming at > 20 GB/hour processed by core, should be around 140 GB/hour when all alone
JOBSIZE=100 # human-00000 to human-00099

echo "Running process_array_cluster.sh with params"
echo "jobqueue=$jobqueue"
echo "vcpus=$vcpus"
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
tag=logan-cluster-$arch-$date-$set
echo "tag: $tag"

$MAYBEDRY aws batch submit-job \
            --job-name $tag \
            --job-definition $jobdef  \
            --job-queue  $jobqueue \
            --array-properties "{ \"size\": ${JOBSIZE} }" \
            --timeout attemptDurationSeconds="$JOBTIMEOUT" \
            --parameters threads="$vcpus" \
            --container-overrides '{
                "command": [
            "-t", "Ref::threads"
                ]}'
echo "array job submitted! (threads=$vcpus)"
