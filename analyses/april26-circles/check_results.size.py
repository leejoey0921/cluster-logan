import os

def read_raw_file(file_path):
    with open(file_path, 'r') as file:
        lines = file.readlines()
    entries = []
    for line in lines:
        parts = line.strip().split()
        timestamp, size, filename = parts[0] + ' ' + parts[1], int(parts[2]), parts[3]
        entries.append((timestamp, size, filename))
    return entries

def compare_file_sizes(entries, folder_path):
    discrepancies = []
    for entry in entries:
        timestamp, size, filename = entry
        file_path = os.path.join(folder_path, filename)
        if os.path.exists(file_path):
            local_size = os.path.getsize(file_path)
            if local_size != size:
                discrepancies.append((filename, size, local_size))
            else:
                print("OK",file_path,local_size,size)
        else:
            discrepancies.append((filename, size, 'File not found'))
    return discrepancies

def main():
    raw_file_path = 'raw.txt'
    folder_path = '.'  # current directory
    entries = read_raw_file(raw_file_path)
    discrepancies = compare_file_sizes(entries, folder_path)
    
    if discrepancies:
        print("Discrepancies found:")
        for discrepancy in discrepancies:
            print(discrepancy)
    else:
        print("No discrepancies found. All file sizes match.")

if __name__ == '__main__':
    main()

