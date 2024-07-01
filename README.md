# Logan-analysis

System to analyze Logan unitigs/contigs at scale with AWS Batch.

Adapted from https://github.com/ababaian/logan

## Warning / Costs

Running this system costs real \$'s in your AWS bill. Spot instances with local disk are 0.022$ per vCPU-hour (https://instances.vantage.sh/aws/ec2/c5d.4xlarge). E.g. a 10,000 vCPU workload during 10 hours is 2,200$ total. This corresponds roughly to a job capable of processing Logan compressed contigs at 1 MB per second per core. Do a pilot run and use AWS Cost Explorer 24 hours later to see real costs.


## Setup

So far this setup has only been tested on `c5d` instances because tasks are relying on a local disk to download contig files.

- Ask Rayan to share `ami-09f62d2604cc5b8fe` with you, or make your own AMI with `mdadm` and `awlcliv2`

- Run `spinupd.sh` to deploy the Cloudformation stack and check your Cloudformation web Interface to make sure the stack is `CREATE_COMPLETE`.

- If needed to make adjustments to the stack, do them and run `spinupd.sh --update ` and check your Cloudformation to make sure the stack is `UPDATE_COMPLETE`.

## Running in production

In the ̀`batch/` folder:

0) Modify the beginning of `logan-analysis.sh` so that it does the task you want.

1) Modify the task itself in `task/` folder.

2) Modify `Dockerfile` to upload the desired references indexes.

3) Test the container with `test_docker.sh`. 

3) Run `deploy-docker.sh` to upload the container.


In the root folder of this repository:

0) Modify `process_array.sh` to correct `jobdef` (`logan-analysis-2c-job` should be fine, jobs will be 2 cores and 3.5 GB RAM, DIAMOND needs that).

1) Put your list of accessions in `sets/mylist.txt` and `echo mylist > set`, change ̀`mylist` to any useful name.

2) Run `process_array.sh [dest_bucket] [nb_jobs]`

Where `dest_bucket` is the name of the destination bucket, and `nb_jobs` is the number of jobs to submit (can't exceed 10000). The more jobs, the faster it will be. Each job takes 1 vcpu and 1.5G memory. Destination bucket file structure is decided by the task.

## Running tests

Run `test_docker.sh` for a local test.
Modify and run `run_test.sh` for a Batch test job, then `run_pilot.sh` for an estimation of costs. Those scripts have a hardcoded output bucket name that needs to be changed.

## Cleanup

Manually delete the CloudFormation stack. Also delete the ECR image. 

