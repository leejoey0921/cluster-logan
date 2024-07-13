(find data -mindepth 2 -type f -exec cat {} + )| \time zstd -c > all_diamond.txt.zst  
