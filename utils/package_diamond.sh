cd data3
for f in $(find  . -maxdepth 1 -mindepth 1 -type d)
do
echo $f
bash -c "(find $f -type f -exec cat {} + )| \time zstd -c > $f.all_diamond.txt.zst" &
done
wait
