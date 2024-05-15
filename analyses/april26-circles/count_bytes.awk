BEGIN {
    FS="\n"; RS=">"; ORS="";
}

# Skip the first empty record
NF > 1 {
    # Extract accession from the first part of the line, before the '_'
    split($1, parts, "_")
    accession = parts[1]

    # Calculate bytes of the header and the sequence including newlines
    # Add 1 for the newline after each line (header and sequence)
    header_length = length($1) + 1 +1 # +1 for the newline after the header #+1 for the >
    sequence_length = length($2) + 1 # +1 for the newline after the sequence
    
    # Accumulate total bytes for each accession
    bytes[accession] += header_length + sequence_length
}

END {
    # Output the total bytes for each accession
    for (acc in bytes) {
        print acc, bytes[acc], "\n"
    }
}

