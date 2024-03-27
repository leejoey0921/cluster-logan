#!/bin/bash -e

outputbucket=$1
jobqueue=$2
dryrun=$3

JOBTIMEOUT=3600 # 1 hour max per job

# Check if an argument is provided
if [ $# -lt 2 ]; then
    echo "Missing arguments, need \$1 for bucket and \$2 for jobqueue. Exiting."
    exit 1
fi

if [ -n "$dryrun" ]; then
	echo "this is a dry run"
fi

# stores the job array .txt files
arraybucket=$(if [[ -z $(aws sts get-caller-identity |grep serratus-rayan) ]]; then echo "logan-dec2023-testbucket"; else echo "logan-testing-march2024"; fi)
arrayfolder=logan-analysis-jobarray
nbCE=1

set=$(cat set)
date=$(date +"%b%d-%Y")
arch=$(uname -m)
tag=logan-analysis-$arch-$date-$set

rm -f array_1c.txt

cat sets/$set.txt > array_1c.txt

# Upload files to S3 with a unique identifier (e.g., timestamp)
timestamp=$(date +"%Y%m%d%H%M%S")_$(cat set)_$$_$(head /dev/urandom | tr -dc A-Za-z0-9 | head -c 13)

split_and_upload() {
    file=$1
    jobdef=$2
    jobqueue=$3
    dryrun=$4
    
    size=1c

	# Split the file and upload each part
	split -d -n l/$nbCE $file array_${size}_part_
	nb_parts=$(ls array_${size}_part_*  2>/dev/null | wc -l)
	if [ "$nb_parts" -gt $nbCE ]; then
		echo "warning! more array jobs ($nb_parts) than the number of queues/CEs ($nbCE)"
		exit 1
	fi
	for part in array_${size}_part_*; do
	    part_lines=$(wc -l < $part)
	    if [ "$part_lines" -gt 10000 ]; then
		echo "warning! array job ($part) has more jobs ($part_lines) than allowed (10000)"
		exit 1
	    fi
	done
	for part in array_${size}_part_*; do
	    part_lines=$(wc -l < $part)
	    suffix="${part##*_}"
	    # proper suffix for the job queue
	    suffix=$((10#$suffix))
	    #jq=$jobqueue$suffix
	    if [ -n "$dryrun" ]; then
		echo "dry run, not executing array_submit_job for $part to job queue $jq"
	    else
		s3file=s3://$arraybucket/$arrayfolder/$part"_"$timestamp
		aws s3 cp $part $s3file
		aws batch submit-job \
		    --job-name $tag \
		    --job-definition $jobdef  \
		    --job-queue  $jobqueue \
		    --timeout attemptDurationSeconds="$JOBTIMEOUT" \
		    --parameters s3file="$s3file",outputbucket="$outputbucket" \
		    --container-overrides '{
		      "command": [
			"-i", "Ref::s3file",
			"-o", "Ref::outputbucket"
		      ]}'
		echo "array job submitted! ($s3file)"
		fi
	done
}

OneCoreJob=logan-analysis-1c-job

# submit job arrays
echo "Submitting to JobQueue: $jobqueue"
[ -f array_1c.txt  ] && split_and_upload array_1c.txt $OneCoreJob "$jobqueue" "$dryrun"

rm -f array_*
