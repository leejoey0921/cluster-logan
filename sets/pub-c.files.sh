awk '{print "s3://logan-pub/c/"$4}' pub-c.txt |shuf > pub-c.files.txt
