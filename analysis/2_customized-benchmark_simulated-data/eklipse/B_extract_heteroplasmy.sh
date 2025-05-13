#!/bin/bash

# Collect and convert heteroplasmy files
output_dir="result"
mkdir -p $output_dir

# Process each .cluster file in the subdirectory
for input_file in ./*/eKLIPse_deletions.csv; do
    if [[ -f "$input_file" ]]; then
        subdir_name=$(basename "$(dirname "$input_file")")
        output_file="${output_dir}/${subdir_name}.tsv"
        cat "$input_file" \
	    | tr -d '"' \
	    | tr ';' '\t' \
	    | sed -E 's/([0-9]),([0-9])/\1.\2/g' \
	    > "$output_file"
    fi
done

echo "All processing completed. Results are in $output_dir"

