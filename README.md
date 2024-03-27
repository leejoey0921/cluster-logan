# Logan-analsis

System to analyze Logan unitigs/contigs at scale with AWS Batch.

Adapted from https://github.com/ababaian/logan

## Running in production

1) run `spinupd.sh` to deploy the CloudFormation template

2) run `deploy-docker.sh`

3) put your list of accessions in `set` file

4) run `process_array.sh [dest_bucket] [nb_jobs]`

Where `dest_bucket` is the name of the destination bucket, and `nb_jobs` is the number of jobs to submit (can't exceed 10000).


## Running a test

Run `test_docker.sh` for a local test or `run_test.sh` for a Batch test job.


## Cleanup

Manually delete the CloudFormation stack. Also delete the ECR image. 
