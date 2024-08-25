#!/bin/bash
set -euo pipefail 
aws sts get-session-token --duration-seconds 6000 > credentials.json

echo "AWS_ACCESS_KEY_ID=$(jq -r '.Credentials.AccessKeyId' credentials.json)" > credentials.env
echo "AWS_SECRET_ACCESS_KEY=$(jq -r '.Credentials.SecretAccessKey' credentials.json)" >> credentials.env 
echo "AWS_SESSION_TOKEN=$(jq -r '.Credentials.SessionToken' credentials.json)" >> credentials.env 


bucket=$(if [[ -z $(aws sts get-caller-identity |grep serratus-rayan) ]]; then echo "logan-dec2023-testbucket"; else echo "logan-testing-march2024"; fi)

#echo s3://logan-testing-march2024/u/DRR000001/DRR000001.unitigs.fa.zst >  array_1c.txt
#echo s3://logan-testing-march2024/u/DRR000002/DRR000002.unitigs.fa.zst >> array_1c.txt
echo s3://logan-testing-march2024/c/DRR000002/DRR000002.contigs.fa.zst > array_1c.txt
echo s3://logan-testing-march2024/c/DRR000003/DRR000003.contigs.fa.zst >> array_1c.txt
echo s3://logan-pub/c/SRR26996305/SRR26996305.contigs.fa.zst >> array_1c.txt
#echo s3://logan-pub/c/DRR030840/DRR030840.contigs.fa.zst >> array_1c.txt # a meatier set that has diamond hits in july1 analysis


s3file=s3://$bucket/array_1c.txt
aws s3 cp array_1c.txt $s3file

docker build -t logan-analysis-job-x86_64 . 
docker run \
    --env-file credentials.env \
    logan-analysis-job-x86_64 \
    -i $s3file -o serratus-rayan-batchops-paris -t 2

rm -f credentials.env credentials.json
