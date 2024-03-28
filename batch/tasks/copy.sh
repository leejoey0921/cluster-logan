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
    filename_trans=$filename_noz.transeq

    mkdir -p /localdisk/"$accession"
    cd /localdisk/"$accession" || exit
   
    echo "$filename"
    # also opportunistically run palmscan on contigs
    if [[ "$filename" == *"contigs"* ]]; then
        folder="c"
        echo "Downloading accession $accession"
        if ! \time s5cmd cp -c 1 "$s3file" "$filename" ; then
            return 1  # This ensures the error trap is triggered if s3 cp fails.
        fi

        \time zstd -d -c $filename > $filename_noz
        \time gotranseq --sequence $filename_noz --outseq $filename_trans --frame 6 -n 1
        if ! \time palmscan2 -search_pssms $filename_trans -tsv "$filename_trans".hits.tsv -min_palm_score 5.0 -fasta "$filename_trans".pps.fa -threads 1; then
            return 1  # Trigger error handling if palmscan2 fails.
        fi
        s5cmd cp -c 1 "$filename_trans".hits.tsv s3://serratus-rayan/logan_palmscan_contigs/"$accession"/
        s5cmd cp -c 1 "$filename_trans".pps.fa   s3://serratus-rayan/logan_palmscan_contigs/"$accession"/

        echo "Uploading accession $accession"
        if ! \time s5cmd cp -c 1 "$filename" s3://"$outbucket"/"$folder"/"$accession"/; then
            return 1  # Trigger error handling if s3 cp fails.
        fi
    else
        folder="u"
        # for unitigs: don't even download locally, do a server-side copy
        clean_path="${s3file#s3://}"
        if ! \time rclone copy aws:$clean_path aws:"$outbucket"/"$folder"/"$accession"/ --s3-use-already-exists 0 -v; then
            return 1  # Trigger error handling if s3 cp fails.
        fi

    fi

   
    rm -Rf /localdisk/"$accession"
    echo "Done with $accession"
    trap '' EXIT
}

export -f task
