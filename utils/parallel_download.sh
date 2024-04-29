for prefix in DRR ERR SRR ;do
    for prefix2 in $(seq 0 9) ;do
        p=${prefix}${prefix2}
                if [[ "$p" == "SRR1" || "$p" == "SRR2" ]]; then
            for subprefix in $(seq 0 9); do
                subp=${p}${subprefix}
                \time s5cmd cp s3://serratus-rayan/beetles/logan_april26_run/diamond/${subp}* . >  &
            done
                else
                \time s5cmd cp s3://serratus-rayan/beetles/logan_april26_run/diamond/${p}* . &
        fi
    done
done
wait
