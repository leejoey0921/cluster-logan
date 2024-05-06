set -ex
rm -f results/complex.* results/selfloops.*
#separator.file.cpp is an old version which took a local file. Now i'm directly reading from s3, much better
g++ -o separator separator.s3.cpp 

# slow
#find data/ -type f -name '*.contigs.fa.circles.fa'  | parallel -j 100 './separator {} {%}' 
# faster
#find data/ -type f -name '*.contigs.fa.circles.fa' | xargs -I{} --process-slot-var=index -P 10 -n 1 sh -c './separator {} $index'

mkfifo results/complex.test.fa
mkfifo results/selfloops.test.fa
zstd -c results/complex.test.fa > results/complex.test.fa.zst &
zstd_pid1=$!
zstd -c results/selfloops.test.fa > results/selfloops.test.fa.zst &
zstd_pid2=$!

# open the named pipes in read/write to a custom fd to prevent them from closing when ./separator exits
exec 3<>results/selfloops.test.fa
exec 4<>results/complex.test.fa

split=plist.acc.txt_split/aa
for acc in $(head -n 20 $split)
do
    ./separator s3://serratus-rayan/beetles/logan_april26_run/circles/$acc/$acc.contigs.fa.circles.fa test
    echo "done"
done

exec 3>&-
exec 4>&-

echo "waiting to zstd to finish"
wait $zstd_pid1 
wait $zstd_pid2

rm results/complex.test.fa results/selfloops.test.fa 

echo "fifo complete"
