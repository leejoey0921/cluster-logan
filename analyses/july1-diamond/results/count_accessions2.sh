\time zstdcat all_diamond.txt.zst | python count_accessions2.py > count_accessions2.res.txt 
sort count_accessions2.res.txt |zstd -c> count_accessions2.res.sorted.txt.zst
rm -f count_accessions2.res.txt
