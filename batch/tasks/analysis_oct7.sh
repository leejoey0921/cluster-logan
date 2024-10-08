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

    echo "Logan analysis ('copenhagen', october 2024) task for file: $s3file"
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
        \time zstdcat $filename | seqtk seq -L 120 > $filename_noz
    fi
    rm -f $filename # saves space




    # CHANGEME
    outdate=oct7




    # prodigal 
    #tool=pyrodigal # runs out of mem
    tool=prodigal
    prodigal_status=0
    prodigal_outfile=$accession.$tool.fa.zst
    [ -s $filename_noz ] && {
    \time prodigal -q      -i $filename_noz -p meta -o /dev/null -a $prodigal_outfile.interm.fa
    #\time $tool -j $THREADS -i $filename_noz -p meta -o /dev/null -a $prodigal_outfile.interm.fa
    prodigal_status=$?
    cat $prodigal_outfile.interm.fa | seqtk seq -A |zstd -c > $prodigal_outfile
    }  || true
    [[ $empty_accession -eq 1 ]] && touch $prodigal_outfile
	[[ $prodigal_status -eq 0 && -f $prodigal_outfile ]] && s5cmd cp -c 1 $prodigal_outfile s3://serratus-rayan/beetles/logan_${outdate}_run/$tool/$accession/
    [[ $prodigal_status -ne 0 ]] && echo "$tool failed, error code: $prodigal_status"
 
	rm -Rf /localdisk/"$accession"
	echo "Done with $accession"
	trap '' EXIT
}

export -f task
