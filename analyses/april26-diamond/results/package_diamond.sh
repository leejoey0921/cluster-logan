(cat ~/logan-analysis/analyses/april26-diamond/results/missing_files/* ; find /rs/ -mindepth 2 -type f -exec cat {} + )| \time zstd -c > all_diamond.txt.zst  
