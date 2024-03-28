#!/bin/bash

set -e

# Initialize variables to hold the last executed command and its line number.
LAST_CMD=""
LAST_CMD_LINE=0

# Function to log the last command executed (for DEBUG trap).
log_last_command() {
    LAST_CMD="$BASH_COMMAND"
    LAST_CMD_LINE="$BASH_LINENO"
}

handle_error() {
    local error_code=$?
    echo "Error occurred in COPY function at line $LAST_CMD_LINE: '$LAST_CMD' exited with status $error_code."
}

cleanup() {
    if [[ -n "$accession" ]]; then
        rm -Rf /localdisk/"$accession"
    fi
    echo "Cleanup of $accession complete."
}

task() {
	trap 'log_last_command' DEBUG
    trap 'handle_error $LINENO' ERR
    trap 'cleanup' EXIT
	
	s3file=$1
	outbucket=$2

    echo "COPY task for file: $s3file"
    filename=$(echo $s3file | awk -F/ '{print $NF}')
    accession=$(echo $filename | cut -d '.' -f1)
    filename_noz=${filename%.*}

    mkdir -p /localdisk/"$accession"
    cd /localdisk/"$accession" || exit
   
    echo "Downloading accession $accession"
    if ! \time s5cmd cp -c 1 "$s3file" "$filename" ; then
        return 1  # This ensures the error trap is triggered if aws s3 cp fails.
    fi

    echo "$filename"
    # also opportunistically run palmscan on contigs
    if [[ "$filename" == *"contigs"* ]]; then
        zstd -d -c $filename > $filename_noz
        if ! palmscan2 -search_pssms $filename_noz -tsv "$filename_noz".hits.tsv -threads 1; then
            return 1  # Trigger error handling if palmscan2 fails.
        fi
        s5cmd cp -c 1 "$filename_noz".hits.tsv s3://serratus-rayan/logan_palmscan_contigs/"$accession"/
        folder="c"
    else
        folder="u"
    fi

    echo "Uploading accession $accession"
    if ! \time s5cmd cp -c 1 "$filename" s3://"$outbucket"/"$folder"/"$accession"/; then
        return 1  # Trigger error handling if aws s3 cp fails.
    fi
    
    rm -Rf /localdisk/"$accession"
    echo "Done with $accession"
    trap '' EXIT
}

export -f task
