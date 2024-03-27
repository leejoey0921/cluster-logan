#!/bin/bash
set -e
bucket=$(if [[ -z $(aws sts get-caller-identity |grep serratus-rayan) ]]; then echo "logan-dec2023-testbucket"; else echo "logan-testing-march2024"; fi)
echo s3://logan-testing-march2024/u/DRR000001/DRR000001.unitigs.fa.zst >  sets/test-array.txt
echo s3://logan-testing-march2024/u/DRR000002/DRR000002.unitigs.fa.zst >> sets/test-array.txt
mv set set.bak && echo "test-array" > set

bash -c "cd batch && bash deploy-docker.sh"

bash process_array.sh serratus-rayan-batchops-paris 1

rm -f sets/test-array && mv set.bak set
