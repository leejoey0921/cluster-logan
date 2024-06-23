cut -d"/" -f4 pub-c.txt |cut -d"." -f1 |sort > pub-c.acc.txt
bash ~/erc-unitigs-prod/sets/txt_to_tsv.sh pub-c.acc.txt > pub-c.acc.tsv
