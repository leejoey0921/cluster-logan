awk '{print $2}' plist.txt |sed 's/\///g' |sort > acc.txt
