time aws s3 cp s3://serratus-rayan/beetles/logan_april26_run/diamond-concat/all_diamond.txt.reduced.zst - | zstdcat | grep beetle | awk '{print | "zstd > /rs2/all_diamond.txt.reduced.zst_split/" NR % 10 ".txt.zst"}'

