# to create the pub-c- files necessary for the run_many script
\time s5cmd ls "s3://logan-pub/c/*" > pub-c.txt
# edit s3_make_file_group.py to point to pub-c
python s3_make_file_group.py 
for f in $(ls pub-c-*); do cat $f | shuf -o $f; done
