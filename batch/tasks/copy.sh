#!/bin/bash

set -e

task() {
	s3file=$1
    echo "COPY task for file: $s3file"
    filename=$(echo $s3file | awk -F/ '{print $NF}')
    accession=$(echo $filename | cut -d '.' -f1)
    echo "accession: $accession"

    mkdir -p /localdisk/$accession
    cd /localdisk/$accession

    aws s3 cp $s3file $filename --quiet

    aws s3 cp $filename s3://serratus-rayan-batchops-paris/u/$accession/ --quiet

    rm -Rf /localdisk/$accession
}

export -f task
