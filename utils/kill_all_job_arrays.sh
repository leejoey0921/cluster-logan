#!/bin/bash

echo "canceling for all job queues."

read -p "Do you want to proceed (Yes/No)? " answer

case $answer in
    [yY] | [yY][eE][sS])
        echo "You chose Yes"
        # Add your commands for 'Yes' response here
        ;;
    [nN] | [nN][oO])
        echo "You chose No"
        # Add your commands for 'No' response here
        ;;
    *)
        echo "Invalid choice. Please choose Yes or No."
        # Add your commands for invalid response here, or exit
        ;;
esac


# Set the job queue
jobQueue="LoganAnalysisJobQueueDisques"

echo "canceling for job queue $jobQueue."

# List all pending job arrays
pendingJobs=$(aws batch list-jobs --job-queue $jobQueue --job-status PENDING --query "jobSummaryList[*].jobId" --output text)

# Iterate through each pending job and cancel it
for jobId in $pendingJobs; do
    echo "Cancelling and terminating job: $jobId"
    aws batch cancel-job    --job-id $jobId --reason "Cancelling pending job"
    aws batch terminate-job --job-id $jobId --reason "Terminating pending job"
done

# List all pending job arrays
submittedJobs=$(aws batch list-jobs --job-queue $jobQueue --job-status SUBMITTED --query "jobSummaryList[*].jobId" --output text)

# Iterate through each pending job and cancel it
for jobId in $submittedJobs; do
    echo "Cancelling job: $jobId"
    aws batch cancel-job    --job-id $jobId --reason "Cancelling submitted job"
done


echo "All pending jobs in the queue '$jobQueue' have been cancelled."
