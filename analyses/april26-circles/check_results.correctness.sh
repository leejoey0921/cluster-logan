#!/bin/bash

DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

getacc () {
	zstdcat $1 $2 | grep "^>" | awk -F'[>_]' '{print $2}' | sort | uniq
}
export -f getacc

# pick randomly a file 
suffix=$(ls -1 results/ |shuf |head -n 1 |cut -d"." -f2)
#suffix=axw
echo "chosen suffix: $suffix"

#mkdir -p tmp_check_correctness # on /mnt/raid actually
getacc results/complex.$suffix.fa.zst results/selfloops.$suffix.fa.zst > tmp_check_correctness/results.axw.acc.txt

cd tmp_check_correctness


mkdir -p dl/
cat results.axw.acc.txt | parallel -j 100 s5cmd cp s3://serratus-rayan/beetles/logan_april26_run/circles/{}/{}.contigs.fa.circles.fa dl/
cat dl/* |sort > correct.sorted.fa
cd ..

zstdcat results/complex.$suffix.fa.zst results/selfloops.$suffix.fa.zst |sort > tmp_check_correctness/local.sorted.fa

cd tmp_check_correctness
comm -3 correct.sorted.fa local.sorted.fa> com

#rm -Rf tmp_check_correctness
