zstdcat /rs2/all_diamond.txt.zst | head -n 30000000|awk -F'\t' '
{
    # Grab the first field and remove everything after "_"
    accession = $1;
    sub(/_.*/, "", accession);

    # Grab the sixth field
    category = $6;
    
    # Remove everything after any "_"
    sub(/_.*/, "", category);

    # Remove everything after any second "."
    split(category, parts, ".");
    if (length(parts) > 2) {
        category = parts[1] "." parts[2];
    }

    # Remove everything after the first "-"
    sub(/-.*/, "", category);

    # Print the accession and category
    print accession, category;
}
'
