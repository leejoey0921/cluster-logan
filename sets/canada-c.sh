\time s5cmd ls "s3://logan-canada/c/*" > canada-c.txt
# edit s3_make_file_group.py to point to canada-c
python s3_make_file_group.py 
for f in $(ls canada-c-*); do cat $f | shuf -o $f; done
