#folder=beetles/logan_april26_run/diamond
#folder=beetles/logan_april26_run/circles
#folder=beetles/logan_july5_run/diamond
#folder=beetles/logan_aug24_run/diamond
folder=beetles/logan_aug26_run/minimap2

set -ex

for prefix in DRR ERR SRR ;do
    for prefix2 in $(seq 0 9) ;do
        p=${prefix}${prefix2}
        if [[ "$p" == "SRR1" || "$p" == "SRR2" || "$p" == "ERR1" ]]; then
            for subprefix in $(seq 0 9); do
                subp=${p}${subprefix}
                outfolder=data3/$subp/
                mkdir -p $outfolder
                \time s5cmd cp -c 10 --flatten s3://serratus-rayan/$folder/${subp}* $outfolder >/dev/null &
            done
        else
                outfolder=data3/$p/
                mkdir -p $outfolder
                \time s5cmd cp -c 10 --flatten s3://serratus-rayan/$folder/${p}* $outfolder >/dev/null &
        fi
    done
done
wait
