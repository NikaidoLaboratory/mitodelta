#!/bin/bash

# Base directory where the script is located
base_dir="$(dirname "$0")"
output_dir="${base_dir}/result"

# Create output directory if it doesn't exist
mkdir -p "$output_dir"

# Loop through each directory in the base directory
for main_dir in "$base_dir"/*; do
    if [ -d "$main_dir" ]; then
        main_name=$(basename "$main_dir") # Get the main directory name
        # Process pt1, pt2, pt3 directories
        for read_dir in "$main_dir"/*; do
            if [ -d "$read_dir" ]; then
                read_name=$(basename "$read_dir" .R1_mapsplice-*)
                output_file="${output_dir}/${main_name}_${read_name}.tsv"
                header_written=false

                # Find and process *_LargeMTDeletions_WGS-only_NoPositionFilter.txt files
                find "$read_dir" -type f -name "*_LargeMTDeletions_WGS-only_NoPositionFilter.txt" | while read -r file; do
                    # Skip empty files
                    if [ ! -s "$file" ]; then
                        continue
                    fi
                    # Write header from the first non-empty file
                    if [ "$header_written" = false ]; then
                        head -n 1 "$file" | awk -F'[[:space:]]+' '{print $1, $3, $7, $8, $9, $10}' OFS='\t' >> "$output_file"
                        header_written=true
                    fi
                    # Append data (excluding header) from subsequent non-empty files
                    tail -n +2 "$file" | awk -F'[[:space:]]+' '{print $1, $3, $7, $8, $9, $10}' OFS='\t' >> "$output_file"
                done
            fi
        done
    fi
done

echo "Processing completed. Merged files are saved in: $output_dir"
