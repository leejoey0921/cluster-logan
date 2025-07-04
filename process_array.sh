#!/bin/bash -e

# changeme
jobqueue=LoganAnalysisJobQueueDisques
vcpus=8 # important, is also passed to container in the THREADS variable. number of vcpus per task.
jobdef=logan-analysis-${vcpus}c-job

outputbucket=$1
nbsplit=$2
dryrun=$3

JOBTIMEOUT=44000 # 12 hour max per job
# for copy, timelimit was 40000, aiming at > 20 GB/hour processed by core, should be around 140 GB/hour when all alone

echo "Running process_array.sh with params"
echo "jobqueue=$jobqueue"
echo "vcpus=$vcpus"
echo "jobdef=$jobdef"
echo "outputbucket=$outputbucket"

# Check if an argument is provided
if [ $# -lt 1 ]; then
    echo "Missing arguments, need \$1 for output bucket. Exiting."
    exit 1
fi

if [ -n "$dryrun" ]; then
	echo "this is a dry run"
fi

# stores the job array .txt files
arraybucket=$(if [[ -z $(aws sts get-caller-identity |grep serratus-rayan) ]]; then echo "logan-dec2023-testbucket"; else echo "logan-testing-march2024"; fi)
arrayfolder=logan-analysis-jobarrays

set=$(cat set)
date=$(date +"%F")
arch=$(uname -m)
tag=logan-analysis-$arch-$date-$set
echo "tag: $tag"

rm -f array.txt

cat sets/$set.txt > array.txt

# Upload files to S3 with a unique identifier (e.g., timestamp)
timestamp=$(date +"%Y%m%d%H%M%S")_$(cat set)_$$_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)

split_and_upload() {
    file=$1
    jobdef=$2
    jobqueue=$3
    dryrun=$4
    
    size=1c

	# Split the file and upload each part
    partfolder=array_${size}_$timestamp/
    mkdir -p $partfolder
	split -a 5 -d -n l/$nbsplit $file $partfolder
    if [ "$?" -ne 0 ]; then 
        echo "Unknown error while splitting set into $nbsplit chunks"
        exit 1
    fi
	nb_parts=$(ls "$partfolder"*  2>/dev/null | wc -l)
	if [ "$nb_parts" -gt $nbsplit ]; then
        echo "error: more array jobs ($nb_parts) than the number asked to split ($nbsplit)"
        echo "make sure to cleanup $partfolder"
		exit 1
	fi
    if [ "$nb_parts" -gt 10000 ]; then
        echo "error: array job has more jobs ($nb_parts) than allowed (10000)"
        echo "make sure to cleanup $partfolder"
        exit 1
    fi
    MAYBEDRY=""
    if [ -n "$dryrun" ]; then
	    echo "dry run, not executing array_submit_job for $nb_parts parts to job queue $jobqueue"
        MAYBEDRY="echo "
    fi
    s3folder=s3://$arraybucket/$arrayfolder/$partfolder
    $MAYBEDRY s5cmd cp --sp $partfolder"*" $s3folder
    s3files=$s3folder
    ARRAYPROP=""
    ARRAYPROP2=""
    if [[ "$nb_parts" -gt 1 ]]; then
        echo "This is a job array:"
        wc -l "$partfolder"* | head 
        if [[ "$nb_parts" -gt 5 ]]; then
            echo "..."
        fi
        ARRAYPROP="--array-properties"                                                                                                            
        ARRAYPROP2="{ \"size\": $nb_parts }"
    else
        s3files=s3://$arraybucket/$arrayfolder/$(find $partfolder -type f)
    fi

    $MAYBEDRY aws batch submit-job \
                --job-name $tag \
                --job-definition $jobdef  \
                --job-queue  $jobqueue \
                $ARRAYPROP "$ARRAYPROP2" \
                --timeout attemptDurationSeconds="$JOBTIMEOUT" \
                --parameters s3files="$s3files",outputbucket="$outputbucket",threads="$vcpus" \
                --container-overrides '{
                  "command": [
                "-i", "Ref::s3files",
                "-o", "Ref::outputbucket",
                "-t", "Ref::threads"
                  ]}'
    echo "array job submitted! (s3files=$s3files, threads=$vcpus)"

    rm -Rf $partfolder
}

# submit job arrays
echo "Submitting to JobQueue: $jobqueue JobDef: $jobdef"
[ -f array.txt  ] && split_and_upload array.txt $jobdef "$jobqueue" "$dryrun"

rm -f array.txt
