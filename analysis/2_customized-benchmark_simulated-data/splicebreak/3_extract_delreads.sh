#!/bin/bash

# Base directory where SB results are located
output_dir="./result"
mkdir -p "$output_dir"

# Loop through each directory in the base directory
for parent_dir in ./*/; do
    parent_name=$(basename "$parent_dir")

    # Process files
    files=$(find "$parent_dir" -type f -name "*_LargeMTDeletions_WGS-only_NoPositionFilter.txt")
    if [ -z "$files" ]; then
        continue
    fi

    output_file="${output_dir}/${parent_name}.tsv"
    header_written=false

    for file in $files; do
        # Skip empty files
        if [ ! -s "$file" ]; then
            continue
        fi

	# Sample name
	name=$(basename "$file" | sed 's/\.flux_LargeMTDeletions_WGS-only_NoPositionFilter.txt$//')

	# Write header from the first non-empty file
        if [ "$header_written" = false ]; then
            head -n 1 "$file" | awk -F'[[:space:]]+' '{print $1, $3, $7, $8, $9, $10, "name"}' OFS='\t' >> "$output_file"
            header_written=true
        fi
        # Append data (excluding header) from subsequent non-empty files
        tail -n +2 "$file" | awk -F'[[:space:]]+' -v sample="$name" '{print $1, $3, $7, $8, $9, $10, sample}' OFS='\t' >> "$output_file"
    done
done

echo "Processing completed. Merged files are saved in: $output_dir"
