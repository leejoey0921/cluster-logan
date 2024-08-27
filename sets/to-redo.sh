prefix=aug26
for folder in minimap2 diamond
do
    (
    echo "examining $folder folder"
    #does a aws s3 ls faster
    bash ../utils/parallel_listing.sh "s3://serratus-rayan/beetles/logan_${prefix}_run/$folder" to-redo.listing.$folder.txt
    cat to-redo.listing.$folder.txt |awk '{print $2}' |sed 's/\///' > to-redo.done.$folder.txt
    rm -f to-redo.listing.$folder.txt
    comm -13 to-redo.done.$folder.txt pub-c.acc.txt > to-redo.$folder.acc.txt
    ) &
done
wait

sort to-redo.minimap2.acc.txt to-redo.diamond.acc.txt | uniq > to-redo.acc.txt
grep -Fwf to-redo.acc.txt ~/logan-analysis/sets/pub-c.files.txt > to-redo.txt
echo "to-redo" > ../set
