#!/bin/bash
set -e
bucket=$(if [[ -z $(aws sts get-caller-identity |grep serratus-rayan) ]]; then echo "logan-dec2023-testbucket"; else echo "logan-testing-march2024"; fi)
echo s3://logan-testing-march2024/c/DRR000001/DRR000001.contigs.fa.zst >  sets/test-array.txt
echo s3://logan-testing-march2024/c/DRR000002/DRR000002.contigs.fa.zst >> sets/test-array.txt
echo s3://logan-testing-march2024/c/DRR000003/DRR000003.contigs.fa.zst >> sets/test-array.txt
echo s3://logan-testing-march2024/c/DRR000005/DRR000005.contigs.fa.zst >> sets/test-array.txt
echo s3://logan-testing-march2024/c/DRR030840/DRR030840.contigs.fa.zst >> sets/test-array.txt # a meatier set that has diamond hits in july1 analysis

mv set set.bak && echo "test-array" > set

bash -c "cd batch && bash deploy-docker.sh"

bash process_array.sh serratus-rayan 2

rm -f sets/test-array && mv set.bak set
