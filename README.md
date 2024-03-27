# Logan-analsis

System to analyze Logan unitigs/contigs at scale with AWS Batch.

Adapted from https://github.com/ababaian/logan

## Running in production

1) run spinupd.sh to deploy the CloudFormation template

2) run deploy-docker.sh

3) put your list of accessions in `set` file

4) run `process_array.sh`


## Running a test

run `test_docker.sh`


## Cleanup

Manually delete the CloudFormation stack. Also delete the ECR image. 
