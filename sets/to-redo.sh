prefix=aug26
# as a rule of thumb, always examine the last folder uploaded. It's minimap2 typically, or diamond if no minimap2
folder=minimap2
echo "examining $folder folder"
aws s3 ls s3://serratus-rayan/beetles/logan_${prefix}_run/$folder/ |awk '{print $2}' |sed 's/\///' > to-redo.done.txt
comm -13 to-redo.done.txt pub-c.acc.txt > to-redo.acc.txt
grep -Fwf to-redo.acc.txt ~/logan-analysis/sets/pub-c.files.txt > to-redo.txt
echo "to-redo" > ../set
