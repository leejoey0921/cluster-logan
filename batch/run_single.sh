#!/bin/bash
## that's for single long jobs to fix manually, e.g. to avoid spot interruptions
set -euo pipefail 
aws sts get-session-token --duration-seconds 129000 > credentials.json

echo "AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' credentials.json)" > credentials.env
echo "AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' credentials.json)" >> credentials.env 
echo "AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' credentials.json)" >> credentials.env 


bucket=$(if [[ -z $(aws sts get-caller-identity |grep serratus-rayan) ]]; then echo "logan-dec2023-testbucket"; else echo "logan-testing-march2024"; fi)

echo s3://logan-pub/c/ERR6862846/ERR6862846.contigs.fa.zst > array_1c.txt 


s3file=s3://$bucket/array_1c.txt
aws s3 cp array_1c.txt $s3file

docker build -t logan-analysis-job-x86_64 . 
docker run \
    --env-file credentials.env \
    logan-analysis-job-x86_64 \
    -i $s3file -o serratus-rayan -t 2

rm -f credentials.env credentials.json
