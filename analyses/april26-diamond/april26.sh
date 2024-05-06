rm -f april26.faa
cat *.faa > tmp
mv tmp april26.faa
diamond makedb -d april26 --in april26.faa 
aws s3 cp april26.dmnd s3://serratus-rayan/beetles/   
