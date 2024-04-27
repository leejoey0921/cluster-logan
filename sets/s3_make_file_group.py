# Initialize variables
#target_size = 500_000_000_000_000  # 500 TB in bytes
target_size  =  20_000_000_000_000  # 20 TB in bytes

#s3prefix = "s3://logan-canada/u/"
#setname = "canada_u"
#s3prefix = "s3://logan-staging/u/"
#setname = "staging-u"
#s3prefix = "s3://logan-canada/c/"
#setname = "canada-c"
s3prefix = "s3://logan-pub/c/"
setname = "pub-c"

current_group_size = 0
group_index = 1
file_paths = []

# Function to write file paths to a group
def write_group(file_paths, group_index):
    with open(f"{setname}-{group_index}.txt", "w") as f:
        for path in file_paths:
            f.write(f"{s3prefix}{path}\n")

# Read file list and distribute into groups
with open(f"{setname}.txt", "r") as file:
    for line in file:
        parts = line.split()
        size = int(parts[2])  # Assuming the size is the third element in the line
        file_path = parts[3]  # Assuming the file path is the fourth element
        
        if current_group_size + size > target_size:
            # Write the current group to a file and start a new group
            write_group(file_paths, group_index)
            file_paths = []  # Reset the file paths for the new group
            current_group_size = 0  # Reset the group size
            group_index += 1  # Increment the group index
        
        # Add the current file to the group
        file_paths.append(file_path)
        current_group_size += size

# Write the last group to a file if it has any files
if file_paths:
    write_group(file_paths, group_index)

print(f"Total groups created: {group_index}")

