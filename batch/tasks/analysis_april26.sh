#!/bin/bash

THREADS=2

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
	outbucket=$2

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

	# decompress and drop short contigs
	\time zstd -d -c $filename  > $filename_noz

    # diamond
	[ -s $filename_noz ] && \time diamond blastx -q $filename_noz -d /april26.dmnd -p $THREADS \
		-c1 -b 0.75 --masking 0\
		-s 1 \
		--sensitive -f 6 qseqid qstart qend qlen qstrand sseqid sstart send slen pident evalue cigar  \
		> "$accession".diamond.april26.txt 
	[ -s "$accession".diamond.april26.txt ] && s5cmd cp -c 1 "$accession".diamond.april26.txt s3://serratus-rayan/beetles/logan_april26_run/diamond/$accession/

    # minimap2
    [ -s $filename_noz ] && \time minimap2 --sam-hit-only -a -x sr -t $THREADS /STB.fa $filename_noz | grep -v '^@' > "$accession".STB.sam || true
	[ -s "$accession".STB.sam ] && s5cmd cp -c 1 "$accession".STB.sam s3://serratus-rayan/beetles/logan_april26_run/minimap2/$accession/
    
    # circles
    [ -s $filename_noz ] && \time python3 /circles-logan/circles.py $filename_noz 31 $filename_noz.circles.fa
    [ -s $filename_noz.circles.fa ] && s5cmd cp -c 1 "$filename_noz".circles.fa s3://serratus-rayan/beetles/logan_april26_run/circles/$accession/


	rm -Rf /localdisk/"$accession"
	echo "Done with $accession"
	trap '' EXIT
}

export -f task
