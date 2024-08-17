import sys
from collections import defaultdict

# Initialize counters
counts = defaultdict(set)

# Process each line
for line in sys.stdin:
    ls = line.split()
    if ls[0].startswith("_"): continue #no acc
    acc = ls[0].split('_')[0]
    if ls[5].startswith('beetle'):
        if '|' in ls[5]:
            what = ls[5].split('|')[1]
            if 'COI' in what or 'COX' in what:
                counts[acc].add('COX')
            if 'ITS' in what:
                counts[acc].add('ITS')
            elif '16S' in what:
                counts[acc].add('16S')
    elif ls[5].startswith('palmcores'):
        counts[acc].add('palm')
    elif ls[5].startswith('var.obelisk'):
        if ls[5] == 'var.obelisk-1.SRR5319850_39367':
            evalue = float(ls[10])
            if evalue > 1e-20: continue # blacklists most small hits for that seq
        counts[acc].add('OBL')

print("acc,cox,its,16s,obli,palm")
for acc in counts:
    print(acc,1 if 'COX' in counts[acc] else 0, 1 if 'ITS' in counts[acc] else 0,1 if '16S' in counts[acc] else 0,
          1 if 'OBL' in counts[acc] else 0,1 if 'palm' in counts[acc] else 0,sep=',')

