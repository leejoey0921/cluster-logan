rm -f july1.faa
cat *.faa > tmp
mv tmp july1.faa
diamond makedb -d july1 --in july1.faa
diamond makeidx -d july1 --sensitive
aws s3 cp july1.dmnd s3://serratus-rayan/beetles/ --acl public-read
aws s3 cp july1.dmnd.seed_idx s3://serratus-rayan/beetles/ --acl public-read
aws s3 cp rep12.fa s3://serratus-rayan/beetles/ --acl public-read
