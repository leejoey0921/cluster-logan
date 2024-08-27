# Logan-analysis

System to analyze Logan unitigs/contigs at scale with AWS Batch.

Adapted from https://github.com/ababaian/logan

## Warning / Costs

Running this system costs real \$'s in your AWS bill. Spot instances with local disk are 0.022$ per vCPU-hour (https://instances.vantage.sh/aws/ec2/c5d.4xlarge). E.g. a 10,000 vCPU workload during 10 hours is 2,200$ total. This corresponds roughly to a job capable of processing Logan compressed contigs at 1 MB per second per core. Do a pilot run and use AWS Cost Explorer 24 hours later to see real costs.

## How to prepare a new task

To create a new task to run at scale, follow the steps below:

1. Fork this Repository

2. **Add a New Script:**
   - Navigate to the `batch/tasks/` directory in your forked repository.
   - Create a new shell script for your analysis task. This script should contain the specific commands for your analysis.
   - Use an existing script as a reference, such as [analysis_aug26.sh](https://gitlab.pasteur.fr/rchikhi_pasteur/logan-analysis/-/blob/master/batch/tasks/analysis_aug26.sh). If there is any newer analysis file in the `tasks/` folder, take that one instead as a reference.

3. **Modify the Dockerfile:**
   - If your analysis requires additional software, modify the Dockerfile to include the necessary installations. This ensures that all dependencies are available in the container.
   - The Dockerfile can be found here: [Dockerfile](https://gitlab.pasteur.fr/rchikhi_pasteur/logan-analysis/-/blob/master/batch/Dockerfile).

4. **Testing Locally:**
   - Before deploying at scale, test your task locally to ensure it runs as expected.
   - Use the `test_docker.sh` script in the `batch/` folder to test your task within the Docker container.

5. **Deploying the Task:**
   - Once tested, commit your script to the `tasks/` directory and push it to your forked repository.
   - Notify Rayan (or the current maintainer) to run your task at scale. The maintainer will pull your changes and execute the task on AWS Batch.



## Setup to run in production

You don't need to do this section if all you do is test the container locally. Read on if you're going to run analyses on cloud yourself (unlikely).

So far this setup has only been tested on `c5d` instances because tasks are relying on a local disk to download contig files.

- Ask Rayan to share `ami-09f62d2604cc5b8fe` with you, or make your own AMI with `awlcliv2`, or just include AWS CLI in the `Dockerfile` and use no AMI.

- Run `spinupd.sh` to deploy the Cloudformation stack and check your Cloudformation web Interface to make sure the stack is `CREATE_COMPLETE`.

- If needed to make adjustments to the stack, do them and run `spinupd.sh --update ` and check your Cloudformation to make sure the stack is `UPDATE_COMPLETE`.

## Checklist for running in production

Again, no need to do this section unless you're the maintainer (typically, Rayan).

Prepare your data in the `analyses/` folder, see previous runs for an example of file organization.

In the ̀`batch/` folder:

0) Modify the beginning of `logan-analysis.sh` so that it does the task you want.

1) Modify the task itself in `task/` folder.

2) Modify `Dockerfile` to upload the desired references indexes.

3) Test the container with `test_docker.sh`. 

3) Run `deploy-docker.sh` to upload the container.


Go to the root folder of this repository. Pay attention to the output bucket names bucket hard coded in `run_*.sh` (`serratus-rayan`).


0) Modify the `vcpus` variable in `process_array.sh` to correct `jobdef`. 2 vcpus, i.e. `jobdef=logan-analysis-2c-job` should be fine, jobs will be 2 cores and 3.5 GB RAM, DIAMOND needs at least that.

1) Run `run_test.sh` to see that it works at all.

2) Run `run_pilot.sh` to get an estimate of the costs

2) Run `run_many.sh` for the big run on all Logan contigs.

Behind the scenes, these scripts call `process_array.sh [dest_bucket] [nb_jobs]`. Where `dest_bucket` is the name of the destination bucket, and `nb_jobs` is the number of jobs to submit (can't exceed 10000). The more jobs, the faster it will be. Destination bucket file structure is decided by the task.

## Running tests

Run `test_docker.sh` for a local test.

Modify and run `run_test.sh` for a Batch test job, then `run_pilot.sh` for an estimation of costs. Those scripts have a hardcoded output bucket name that needs to be changed.

## Cleanup

Manually delete the CloudFormation stack. Also delete the ECR image. 

