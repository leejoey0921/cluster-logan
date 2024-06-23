import io
import zstandard

def parse_file(file_path):
    file_dict = {}
    with open(file_path, 'rb') as file:
        dctx = zstandard.ZstdDecompressor()
        stream_reader = dctx.stream_reader(file)
        text_stream = io.TextIOWrapper(stream_reader, encoding='utf-8')
        for line in text_stream:
            if file_path == 'list_files.txt.zst':
                fields = line.split()
                if len(fields) >= 9:
                    filename = fields[10][2:]
                    size = int(fields[6])
                    file_dict[filename] = size
            elif file_path == 's3_files.txt.zst':
                fields = line.split()
                if len(fields) >= 3:
                    filename = fields[3]
                    size = int(fields[2])
                    file_dict[filename] = size
            elif file_path == 'missing_files.txt.zst':
                fields = line.split()
                if len(fields) >= 9:
                    filename = fields[10][2:]
                    size = int(fields[6])
                    acc = filename.split('/')[1].split('.')[0]
                    filename = acc + '/' + filename.split('/')[1]
                    file_dict[filename] = size
    return file_dict

def compare_dictionaries(dict1, dict2):
    discrepancies = []
    for filename, size in dict1.items():
        if filename in dict2:
            if size != dict2[filename]:
                discrepancies.append(f"Size mismatch for {filename}: {size} != {dict2[filename]}")
        else:
            discrepancies.append(f"File {filename} not found in s3_files.txt.zst")
    for filename in dict2:
        if filename not in dict1:
            discrepancies.append(f"File {filename} not found in list_files.txt.zst")
    return discrepancies

# Parse the input files and store the filenames and sizes in dictionaries
missing_files_dict = parse_file('missing_files.txt.zst')
list_files_dict = parse_file('list_files.txt.zst')
s3_files_dict = parse_file('s3_files.txt.zst')

for filename in missing_files_dict:
    list_files_dict[filename] = missing_files_dict[filename]

# Compare the dictionaries and print any discrepancies
discrepancies = compare_dictionaries(list_files_dict, s3_files_dict)
if discrepancies:
    print("Discrepancies found:")
    for discrepancy in discrepancies:
        print(discrepancy)
else:
    print("No discrepancies found.")

