#!/bin/bash


job () {
	zstdcat $1 | python3 check_results.cleanup.py | zstd -o $1.cleanup -
	rm -f $1
}
export -f job

ls results/*.zst | parallel -j 50 job
