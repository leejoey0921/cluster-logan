cut -f5 rice_sra.tsv > rice_sra.experiment_acc.txt
grep -Fwf rice_sra.experiment_acc.txt ~/erc-unitigs-prod/sra_experiment.csv |cut -d"," -f1 |sed 's/\"//g' |sort > rice_sra.acc.txt
 
