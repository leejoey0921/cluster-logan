#!/bin/bash

prefix=canada_u

# Initialize variables
target=500000000000000  # 500.0 TB in bytes
group_index=1
sum=0
rm -f "$prefix"_*.txt  # Remove existing group files

# Function to add file to group
add_to_group() {
    local line=$1
    local group_file="${prefix}_${group_index}.txt"
    echo "$line" | awk '{print $4}' >> "$group_file"
}

# Process each line from the file
while read -r line; do
    # Extract the size (in bytes) from each line
    size=$(echo "$line" | awk '{print $3}')
    
    # Update sum
    new_sum=$((sum + size))
    
    # Check if adding the current file exceeds the target size
    if [ "$new_sum" -le "$target" ]; then
        sum=$new_sum
        # Add the file path to the current group
        add_to_group "$line"
    else
        # Reset sum for a new group, update group index, and add the current file to the new group
        sum=$size
        group_index=$((group_index + 1))
        add_to_group "$line"
    fi
done < "../sets/$prefix.txt"

# Display the total number of groups created
echo "Total groups created: $group_index"

