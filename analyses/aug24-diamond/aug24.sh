#/bin/bash
set -e
prefix=aug24
rm -f $prefix.faa
cat *.faa > tmp
mv tmp $prefix.faa
diamond makedb -d $prefix --in $prefix.faa
diamond makeidx -d $prefix --sensitive -s 1
aws s3 cp $prefix.dmnd s3://serratus-rayan/beetles/ --acl public-read
aws s3 cp $prefix.dmnd.seed_idx s3://serratus-rayan/beetles/ --acl public-read
