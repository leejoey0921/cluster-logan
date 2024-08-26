cd card
cat nucleotide* > card_nucl.fna
cat protein* > card_prot.faa
usearch -cluster_fast card_nucl.fna -id 0.9 -centroids ../card_nucl.id90.fna
usearch -cluster_fast card_prot.faa -id 0.9 -centroids ../card_prot.id90.faa
cd ..
bash add_prefix.sh
