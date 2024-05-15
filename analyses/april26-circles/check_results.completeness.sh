#!/bin/bash

count () {
	suffix=$1
	zstdcat results/complex.$suffix.fa.zst results/selfloops.$suffix.fa.zst| awk -f count_bytes.awk > completeness/$suffix.count_bytes
}
export -f count 

ls results/*.zst -1  |cut -d"." -f2  |sort |uniq | parallel -j 100 count {}

