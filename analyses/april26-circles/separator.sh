set -ex
rm -f results/complex.* results/selfloops.*
g++ -o separator separator.cpp 
# slow
#find data/ -type f -name '*.contigs.fa.circles.fa'  | parallel -j 100 './separator {} {%}' 
find data/ -type f -name '*.contigs.fa.circles.fa' | xargs -I{} --process-slot-var=index -P 10 -n 1 sh -c './separator {} $index'

