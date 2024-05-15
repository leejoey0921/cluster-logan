# first call the .sh script
# then call this python script

import sys

def parse_file_sizes(filename):
    """Parses file with format `date time size path` and returns a dictionary with accession as key and size as value."""
    file_sizes = {}
    with open(filename, 'r') as file:
        for line in file:
            parts = line.split()
            size = int(parts[2])
            accession = parts[3].split('/')[0]
            file_sizes[accession] = size
    return file_sizes

def parse_completeness(filename):
    """Parses file with accession and size, returning a dictionary with accession as key and reported size as value."""
    completeness = {}
    with open(filename, 'r') as file:
        for line in file:
            parts = line.split()
            if len(parts) != 2: continue
            accession = parts[0]
            size = int(parts[1])
            completeness[accession] = size
    return completeness

def compare_sizes(file_sizes, completeness):
    """Compares sizes from file_sizes and completeness, returning accessions with mismatched sizes."""
    mismatches = []
    for accession in file_sizes:
        if accession in completeness and file_sizes[accession] != completeness[accession]:
            mismatches.append(accession)
    return mismatches

def main():
    file_sizes = parse_file_sizes('/mnt/raid/plist/plist.txt')
    sys.stderr.write("plist parsed\n")
    completeness = parse_completeness('completeness.all.txt')
    sys.stderr.write("completeness parsed\n")
    mismatches = compare_sizes(file_sizes, completeness)

    for mismatch in mismatches:
        print(mismatch)

if __name__ == "__main__":
    main()

