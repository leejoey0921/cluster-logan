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

    echo "Logan analysis ('back2back', august 2024) task for file: $s3file"
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
    outdate=aug26




    # diamond
    # in the small database opt mode https://github.com/bbuchfink/diamond/wiki/5.-Advanced-topics#small-database-optimization
    mkdir -p tmp_$accession
    diamond_status=0
    diamond_output_file="$accession".diamond.$outdate.txt
	[ -s $filename_noz ] && {
        \time diamond blastx -q $filename_noz -d /$outdate.dmnd -p $THREADS \
		-c 1 --masking 0\
        --target-indexed \
        --tmpdir tmp_$accession \
        --sensitive -s 1 \
        --evalue 1e-8 \
        -k 1\
        -f 6 qseqid qstart qend qlen qstrand \
             sseqid  sstart send slen \
             pident evalue cigar \
             qseq_translated full_qseq \
		> $diamond_output_file 
        diamond_status=$?
    } || true 
    [[ $empty_accession -eq 1 ]] && touch $diamond_output_file # make it upload an empty file if no hits
	[[ $diamond_status -eq 0 && -f $diamond_output_file ]] && s5cmd cp -c 1 $diamond_output_file s3://serratus-rayan/beetles/logan_${outdate}_run/diamond/$accession/
    [[ $diamond_status -ne 0 ]] && echo "Diamond failed, error code: $diamond_status"
    rm -Rf tmp_$accession

    # minimap2
    suffix=aug26
    samfile=$accession.$suffix.sam
    minimap_status=0
    [ -s $filename_noz ] && {
    \time minimap2 --sam-hit-only -a -t $THREADS /aug26.fna $filename_noz 
    minimap_status=$?
    } | grep -v '^@' > $samfile || true
    [[ $empty_accession -eq 1 ]] && touch $samfile
	[[ $minimap_status -eq 0 && -f $samfile ]] && s5cmd cp -c 1 $samfile s3://serratus-rayan/beetles/logan_${outdate}_run/minimap2/$accession/
    [[ $minimap_status -ne 0 ]] && echo "Minimap2 failed, error code: $minimap_status"
 
	rm -Rf /localdisk/"$accession"
	echo "Done with $accession"
	trap '' EXIT
}

export -f task
