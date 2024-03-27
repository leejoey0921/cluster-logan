#!/bin/bash

# Initialize sum and target size in bytes (230GB in bytes)
sum=0
target=230000000000  # 230 GB in bytes

rm -f s3_make_file_group.txt

# Assuming the file list is stored in 'canada_r.txt',
# and each line in the file is structured as: 
# date time size path
while read -r line; do
    # Extract the size (in bytes) from each line
    size=$(echo "$line" | awk '{print $3}')
    
    # Update sum
    new_sum=$((sum + size))
    
    # Check if adding the current file exceeds the target size
    if [ "$new_sum" -le "$target" ]; then
        sum=$new_sum
        # Print the file path (or any other action required)
        echo "$line" | awk '{print $4}' >> s3_make_file_group.txt
    else
        # Exit the loop if the target size is reached or exceeded
        break
    fi
done < "../sets/canada_r.txt"

echo "Total grouped size: $sum bytes"

