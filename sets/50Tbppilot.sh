\time python 50Tbppilot.py > 50Tbppilot.dir.txt
awk '{print "s3://logan-pub/c/"$4}' 50Tbppilot.dir.txt > 50Tbppilot.files.txt
