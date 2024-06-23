python check_properly_downloaded.py > check_properly_downloaded.to_redo.txt
cat check_properly_downloaded.to_redo.txt |grep april|awk '{print $2}'   > check_properly_downloaded.to_redo.files.txt

for file in $(cat check_properly_downloaded.to_redo.files.txt)
do
   s5cmd cp s3://serratus-rayan/beetles/logan_april26_run/diamond/$file missing_files/
done
