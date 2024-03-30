# Logan-analysis

System to analyze Logan unitigs/contigs at scale with AWS Batch.

Adapted from https://github.com/ababaian/logan

## Warning / Costs

Running this system costs real $'s in your AWS bill. Spot instances with local disk are 0.0022$ per vCPU-hour (https://instances.vantage.sh/aws/ec2/c5d.4xlarge). E.g. a 10,000 vCPU workload during 10 hours is 220$ total. Do a test run and use AWS Cost Explorer 24 hours later to see real costs.

## Running in production

In the ̀`batch/` folder:

0) modify the beginning of `logan-analysis.sh` so that it does the task you want

1) run `spinupd.sh` to deploy the CloudFormation template

2) run `deploy-docker.sh`

In the root folder:

3) put your list of accessions in `sets/mylist.txt` and `echo mylist > set`, change ̀`mylist` to any useful name.

4) run `process_array.sh [dest_bucket] [nb_jobs]`

Where `dest_bucket` is the name of the destination bucket, and `nb_jobs` is the number of jobs to submit (can't exceed 10000). The more jobs, the faster it will be. Each job takes 1 vcpu and 1.5G memory. Destination bucket file structure is decided by the task.

## Running a test

Run `test_docker.sh` for a local test or `run_test.sh` for a Batch test job.

## Cleanup

Manually delete the CloudFormation stack. Also delete the ECR image. 

