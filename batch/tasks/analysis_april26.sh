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
    
	# decompress
	\time zstdcat $filename > $filename_noz
    rm -f $filename

    # diamond
    # limits memory with b=0.4 as it is expected to use 6x that value in GB
    # also doesn't use the -c1 param to lower memory
    # https://github.com/bbuchfink/diamond/wiki/3.-Command-line-options#memory--performance-options
    # observed peak mem for a 800 MB database: 6.3GB
    mkdir -p tmp_$accession
	[ -s $filename_noz ] && \time diamond blastx -q $filename_noz -d /april26.dmnd -p $THREADS \
		-b 0.4 --masking 0\
        --tmpdir tmp_$accession \
		-s 1 \
		--sensitive -f 6 qseqid qstart qend qlen qstrand sseqid sstart send slen pident evalue cigar  \
		> "$accession".diamond.april26.txt || true 
    rm -Rf tmp_$accession
    touch "$accession".diamond.april26.txt # make it upload an empty file if no hits
	[ -s "$accession".diamond.april26.txt ] && s5cmd cp -c 1 "$accession".diamond.april26.txt s3://serratus-rayan/beetles/logan_april26_run/diamond/$accession/

    # minimap2
    #[ -s $filename_noz ] && \time minimap2 --sam-hit-only -a -x sr -t $THREADS /STB.fa $filename_noz | grep -v '^@' > "$accession".STB.sam || true
	#[ -s "$accession".STB.sam ] && s5cmd cp -c 1 "$accession".STB.sam s3://serratus-rayan/beetles/logan_april26_run/minimap2/$accession/
    
    # circles
    #[ -s $filename_noz ] && \time python3 /circles-logan/circles.py $filename_noz 31 $filename_noz.circles.fa || true
    #[ -s $filename_noz.circles.fa ] && s5cmd cp -c 1 "$filename_noz".circles.fa s3://serratus-rayan/beetles/logan_april26_run/circles/$accession/


	rm -Rf /localdisk/"$accession"
	echo "Done with $accession"
	trap '' EXIT
}

export -f task
