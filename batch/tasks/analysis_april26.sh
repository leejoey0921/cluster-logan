#!/bin/bash

THREADS=4

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
    # disregards the second argument (output bucket), we're hardcoding output paths here

    echo "Logan Analysis ('sakura', april 2024) task for file: $s3file"
    filename=$(echo $s3file | awk -F/ '{print $NF}')
    accession=$(echo $filename | cut -d '.' -f1)
    filename_noz=${filename%.*}

    mkdir -p /localdisk/"$accession"
    cd /localdisk/"$accession" || exit
   
	echo "Downloading accession $accession"
	if ! \time s5cmd cp -c $THREADS "$s3file" "$filename" ; then
		return 1  # This ensures the error trap is triggered if s3 cp fails.
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
	if [ "$file_size" -lt 200 ]; then
		echo "Contigs file is smaller than 200 bytes. Zstd somehow hangs on small files, so, skipping it entirely."
        empty_accession=1
    else
	    # decompress
    	\time zstdcat $filename > $filename_noz
    fi
    rm -f $filename

    # diamond
    # limits memory with b=0.4 as it is expected to use 6x that value in GB
    # also doesn't use the -c1 param to lower memory
    # https://github.com/bbuchfink/diamond/wiki/3.-Command-line-options#memory--performance-options
    # observed peak mem for a 800 MB database: 6.3GB
    if false; 
    then
    mkdir -p tmp_$accession
    diamond_status=1
	[ -s $filename_noz ] && {
        \time diamond blastx -q $filename_noz -d /april26.dmnd -p $THREADS \
		-b 0.4 --masking 0\
        --tmpdir tmp_$accession \
		-s 1 \
		--sensitive -f 6 qseqid qstart qend qlen qstrand sseqid sstart send slen pident evalue cigar  \
		> "$accession".diamond.april26.txt 
        diamond_status=$?
    } || true 
    [[ $diamond_status -eq 0 || $empty_accession -eq 1 ]] && touch "$accession".diamond.april26.txt # make it upload an empty file if no hits
	[ -f "$accession".diamond.april26.txt ] && s5cmd cp -c 1 "$accession".diamond.april26.txt s3://serratus-rayan/beetles/logan_april26_run/diamond/$accession/
    rm -Rf tmp_$accession
    fi

    # minimap2
    minimap_status=1
    [ -s $filename_noz ] && {
    \time minimap2 --sam-hit-only -a -x sr -t $THREADS /STB.fa $filename_noz 
    minimap_status=$?
    } | grep -v '^@' > "$accession".STB.sam || true
    [[ $minimap_status -eq 0 || $empty_accession -eq 1 ]] && touch "$accession".STB.sam
	[ -f "$accession".STB.sam ] && s5cmd cp -c 1 "$accession".STB.sam s3://serratus-rayan/beetles/logan_april26_run/minimap2/$accession/
    
    # circles
    circles_status=1
    [ -s $filename_noz ] && {
    \time python3 /circles-logan/circles.py $filename_noz 31 $filename_noz.circles.fa 
    circles_status=$?
    } || true
    [[ $circles_status -eq 0 || $empty_accession -eq 1 ]] && touch $filename_noz.circles.fa 
    [ -f $filename_noz.circles.fa ] && s5cmd cp -c 1 "$filename_noz".circles.fa s3://serratus-rayan/beetles/logan_april26_run/circles/$accession/


	rm -Rf /localdisk/"$accession"
	echo "Done with $accession"
	trap '' EXIT
}

export -f task
