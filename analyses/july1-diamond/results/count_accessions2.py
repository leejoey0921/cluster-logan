import sys
from collections import defaultdict

# Initialize counters
counts = defaultdict(set)

# Process each line
for line in sys.stdin:
    ls = line.split()
    acc = ls[0].split('_')[0]
    what = ls[5].split('.')[0]
    if what == 'anello':
        counts[acc].add('an')
    elif what == 'papilloma':
        counts[acc].add('pv')

print("acc,an,pv")
for acc in counts:
    print(acc,1 if 'an' in counts[acc] else 0, 1 if 'pv' in counts[acc] else 0,sep=',')

