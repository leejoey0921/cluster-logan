#!/bin/bash
set -ex
threads=10
for filename in $(awk '{print $4}' ../sets/2fix/2fix.txt)
do
    accession=$(echo $filename |cut -d"/" -f1)
    echo $accession

    for which in contigs unitigs
    do
        s5cmd cp s3://logan-pub/${which:0:1}/$accession/$accession.$which.fa.zst .
        zstd -d $accession.$which.fa.zst
        rm -f $accession.$which.fa.zst
    
        perl -i -pe "if (/^>/) { s/^>_/>${accession}_/;}" $accession.$which.fa
        \time f2sz -l 13 -b 128M -F -i -f -T $threads $accession.$which.fa
        s5cmd cp $accession.$which.fa.zst s3://logan-pub/${which:0:1}/$accession/
        rm -f $accession.$which.fa.zst $accession.$which.fa $accession.$which.fa.zst.idx

    done
done
