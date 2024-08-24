import sys
from collections import Counter 

s = set()
for line in open("../../april26-diamond/plot/plants.acc.txt"):
    s.add(line.strip())

c = Counter()

for line in sys.stdin:
    ls = line.split()
    acc = ls[0].split('_')[0]
    if acc not in s: continue
    hit = ls[5]
    c[hit] += 1


with open('plant_hits.txt', 'w') as f:
    for key, value in sorted(c.items(), key=lambda item: item[1], reverse=True):
        f.write(f'{key} {value}\n')

print("Counter dumped to plant_hits.txt")

