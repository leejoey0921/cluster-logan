awk '{print $4}' pub-u.txt |cut -f1 -d'/' |cut -f1 -d'.' |sort > pub-u.acc.txt
