#!/bin/bash

if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <folder> <outfile>"
    exit 1
fi


s3path=$1
outfile=$2

for prefix in DRR ERR SRR ;do
    for prefix2 in $(seq 0 9) ;do
        p=${prefix}${prefix2}
		if [[ "$p" == "SRR1" || "$p" == "SRR2" ]]; then
            for subprefix in $(seq 0 9); do
                subp=${p}${subprefix}
                \time s5cmd ls $s3path/$subp > "${outfile}_${subp}" &
            done
		else
	        \time s5cmd ls $s3path/$p > "${outfile}_${p}" &
        fi
    done
done
wait
cat "${outfile}_"* > "$outfile"
rm -f "${outfile}_"*
echo "Results in $outfile"
