prefix=aug26
for folder in minimap2 diamond
    do
        echo "examining $folder folder"
    aws s3 ls s3://serratus-rayan/beetles/logan_${prefix}_run/$folder/ |awk '{print $2}' |sed 's/\///' > to-redo.done.txt
    comm -13 to-redo.done.txt pub-c.acc.txt > to-redo.$folder.acc.txt
done
sort to-redo.minimap2.acc.txt to-redo.diamond.acc.txt | uniq > to-redo.acc.txt
grep -Fwf to-redo.acc.txt ~/logan-analysis/sets/pub-c.files.txt > to-redo.txt
echo "to-redo" > ../set
