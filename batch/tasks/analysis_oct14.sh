#!/bin/bash

set -eu

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
    THREADS=$2
    # disregards the third argument (output bucket), we're hardcoding output paths here

    echo "Logan analysis ('knowles', october 2024) task for file: $s3file"
    filename=$(echo $s3file | awk -F/ '{print $NF}')
    accession=$(echo $filename | cut -d '.' -f1)
    filename_noz=${filename%.*}

    mkdir -p /localdisk/"$accession"
    cd /localdisk/"$accession" || exit
   
	echo "Downloading accession $accession"
	if ! \time s5cmd cp -c $THREADS "$s3file" "$filename" ; then
		echo "Error with s5cmd cp, function error should trap. If not, cleaning up anyway. Remove this if all OK"
	    rm -Rf /localdisk/"$accession"
		return 1  # This ensures the error trap is triggered if s3 cp fails. TODO check this
	fi
   
    if ! zstd --test $filename ; then
        touch $accession.corrupt
        s5cmd cp $accession.corrupt s3://serratus-rayan/logan_corrupt_contigs/
        # here we want to just ignore that accession and continue
        echo "Corrupt accession!"
	    rm -Rf /localdisk/"$accession"
		return 0 
	fi

	# Get the file size in bytes
	file_size=$(stat -c %s "$filename")
    empty_accession=0

	# Check if the file size is less than 200 bytes
	if [[ -f $filename && "$file_size" -lt 200 ]]; then
		echo "Contigs file is smaller than 200 bytes. Zstd somehow hangs on small files, so, skipping it entirely."
        empty_accession=1
    else
	    # decompress
        # also converts spaces in header to underscores to be included in diamond output
        \time zstdcat $filename | perl -pe "if (/^>/) { s/\h+/_/g }"> $filename_noz
    fi
    rm -f $filename # saves space




    # CHANGEME
    outdate=oct14

    # minimap2
    suffix=$outdate
    samfile=$accession.$suffix.sam
    tmp_minimap_status_file=$(mktemp)
    echo "-1" > "$tmp_minimap_status_file" # assume error until correct
    if [ -s $filename_noz ]; then
    {
    \time minimap2 -x sr --sam-hit-only -a -t $THREADS /GCF_034140825.1_ASM3414082v1_genomic.fna.gz $filename_noz 
    echo "$?" > "$tmp_minimap_status_file"
    } | grep -v '^@' > $samfile || true
    minimap_status=$(cat "$tmp_minimap_status_file")
    echo "minimap2 status: $minimap_status"
    fi
    [[ $empty_accession -eq 1 ]] && touch $samfile
	[[ $minimap_status -eq 0 && -f $samfile ]] && s5cmd cp -c 1 $samfile s3://serratus-rayan/beetles/logan_${outdate}_run/minimap2/$accession/
    [[ $minimap_status -ne 0 ]] && echo "Minimap2 failed, error code: $minimap_status"
 
    rm -f "$tmp_minimap_status_file"
	rm -Rf /localdisk/"$accession"
	echo "Done with $accession"
	trap '' EXIT
}

export -f task
