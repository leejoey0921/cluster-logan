\time zstdcat /rs2/all_diamond.evalfiltered.txt.zst| ~/tools/pypy3.10-v7.3.16-linux64/bin/pypy count_accessions2.py > count_accessions2.results.txt
sort count_accessions2.results.txt|grep -v acc |zstd -c > count_accessions2.results.sorted.txt.zst

