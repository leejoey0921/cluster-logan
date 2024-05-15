set -e

#rm -f results/complex.*.fa results/selfloops.*.fa

#separator.file.cpp is an old version which took a local file. Now i'm directly reading from s3, much better
g++ -o separator separator.s3.cpp 

# slow
#find data/ -type f -name '*.contigs.fa.circles.fa'  | parallel -j 100 './separator {} {%}' 
# faster
#find data/ -type f -name '*.contigs.fa.circles.fa' | xargs -I{} --process-slot-var=index -P 10 -n 1 sh -c './separator {} $index'


#folder=plist.acc.txt_split
#folder=to_redo.acc.txt_split
folder=check_results.completeness.txt_split

task () {
	i=$1
	folder=$2

mkfifo results/complex.$i.fa
mkfifo results/selfloops.$i.fa
zstd -c results/complex.$i.fa > results/complex.$i.fa.zst &
zstd_pid1=$!
zstd -c results/selfloops.$i.fa > results/selfloops.$i.fa.zst &
zstd_pid2=$!

# open the named pipes in read/write to a custom fd to prevent them from closing when ./separator exits
exec 3<>results/selfloops.$i.fa
exec 4<>results/complex.$i.fa

split=$folder/$i
for acc in $(cat $split)
do
    ./separator s3://serratus-rayan/beetles/logan_april26_run/circles/$acc/$acc.contigs.fa.circles.fa $i
done

exec 3>&-
exec 4>&-

echo "waiting to zstd to finish"
wait $zstd_pid1 
wait $zstd_pid2

rm results/complex.$i.fa results/selfloops.$i.fa 

echo "$i fifo complete"
}
export -f task

ls -1 $folder | parallel -j 100 "task {} $folder"
