folder=beetles/logan_april26_run/circles

for prefix in DRR ERR SRR ;do
    for prefix2 in $(seq 0 9) ;do
        p=${prefix}${prefix2}
		if [[ "$p" == "SRR1" || "$p" == "SRR2" ]]; then
            for subprefix in $(seq 0 9); do
                subp=${p}${subprefix}
                \time s5cmd ls s3://serratus-rayan/$folder/$subp > plist_$subp &
            done
		else
	        \time s5cmd ls s3://serratus-rayan/$folder/$p > plist_$p &
        fi
    done
done
wait
cat plist_* > plist.txt
rm -f plist_*
echo "results in plist.txt"
