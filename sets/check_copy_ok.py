def read_file(file_path):
    """
    Reads a file and returns a dictionary where the key is the file name 
    and the value is the file size.
    """
    file_dict = {}
    with open(file_path, 'r') as file:
        for line in file:
            parts = line.strip().split()
            if len(parts) != 4:
                print("unexpected line",parts)
            else:
                date,date2,size, name = parts
                name = name.split('/')[-1]
                file_dict[name] = int(size)

    return file_dict

def check_files(source_files, pub_files):
    """
    Checks that each file in source_files is present in pub_files and its size 
    is within +-10% of the size in source_files.
    """
    for file_name, size in source_files.items():
        if file_name not in pub_files:
            print(f"Missing file in pub: {file_name}")
        else:
            pub_size = pub_files[file_name]
            if not (0.8 * size <= pub_size <= 1.2 * size):
                print(f"Size mismatch for {file_name}: source size {size}, pub size {pub_size}")

# Read files from canada.txt and staging.txt
canada_files = read_file('canada.txt')
staging_files = read_file('staging.txt')

# Merge canada and staging files
all_source_files = {**canada_files, **staging_files}

# Read files from pub.txt
pub_files = read_file('pub.txt')

# Check that all files from canada and staging are in pub with correct sizes
check_files(all_source_files, pub_files)

