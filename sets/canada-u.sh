#\time s5cmd ls "s3://logan-canada/u/*" > canada_u.txt
# edit s3_make_file_group.py to point to canada_u
#python s3_make_file_group.py 
for f in $(ls canada-u-*); do cat $f | shuf -o $f; done
