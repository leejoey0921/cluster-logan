#!/bin/bash


job () {
	zstdcat $1 | grep "^>" | awk -F'[>_]' '{print $2}' | uniq
}
export -f job

ls results/*.zst | parallel -j 100 job > results.acc.txt
