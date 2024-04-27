head -n 3500 pub-c.acc.tsv > 4Tpilot.tsv
awk '{print $1}' 4Tpilot.tsv > 4Tpilot.acc.txt
grep -Fwf 4Tpilot.acc.txt  pub-c.files.txt |shuf > 4Tpilot.txt

