aws s3 ls s3://serratus-rayan/beetles/logan_july5_run/diamond/ |awk '{print $2}' |sed 's/\///' > to-redo.done.txt
comm -13 to-redo.done.txt pub-c.acc.txt > to-redo.acc.txt
grep -Fwf to-redo.acc.txt ~/logan-analysis/sets/pub-c.files.txt > to-redo.txt
