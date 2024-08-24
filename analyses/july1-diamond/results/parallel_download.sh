#folder=beetles/logan_april26_run/diamond
#folder=beetles/logan_april26_run/circles
#folder=beetles/logan_july5_run/diamond
folder=beetles/logan_july5_run/minimap2

set -ex

cd data # always download elsewhere
for prefix in DRR ERR SRR ;do
    for prefix2 in $(seq 0 9) ;do
        p=${prefix}${prefix2}
                if [[ "$p" == "SRR1" || "$p" == "SRR2" ]]; then
            for subprefix in $(seq 0 9); do
                subp=${p}${subprefix}
                \time s5cmd cp s3://serratus-rayan/$folder/${subp}* . >/dev/null &
            done
                else
                \time s5cmd cp s3://serratus-rayan/$folder/${p}* . >/dev/null &
        fi
    done
done
wait
