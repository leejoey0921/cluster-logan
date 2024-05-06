awk '{print $2}' plist.txt |sed 's/\///g' |sort > plist.acc.txt
comm -23 ~/logan-analysis/sets/pub-c.acc.txt plist.acc.txt > to-redo.acc.txt
grep -Fwf to-redo.acc.txt ~/logan-analysis/sets/pub-c.files.txt > to-redo.txt 
