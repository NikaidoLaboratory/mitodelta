#!/bin/bash

# Extract heteroplasmy for clusters (6072-13094,8469-13446,10381-15406)
# 250129: Changed to include all clusters

output_dir="result"

# Create output dir
mkdir -p $output_dir

# Loop through each subdirectory
for sub_dir in ./indel.*; do
    if [[ -d "$sub_dir" ]]; then
        sub_dir_name=$(basename "$sub_dir")
        output_file="${output_dir}/${sub_dir_name}.tsv"
        # Create or empty the output file
        echo -e "name\tbreak5\tbreak3\tdelread\twtread\theteroplasmy" > "$output_file"
        # Process each .cluster file in the subdirectory
        for file in "$sub_dir"/*.cluster; do
            if [[ -f "$file" ]]; then
                base_name=$(basename "$file" .cluster)
                # Extract lines by 3rd and 4th column
                awk -F'\t' '
                    {
                        split($3, break3_values, ",");
                        split($4, break4_values, ",");
                        print "'"$base_name"'\t"break3_values[1]"\t"break4_values[1]"\t"$7"\t"$8"\t"$9
                    }' "$file" >> "$output_file"
            fi
        done
        echo "Processed $sub_dir_name, output written to $output_file"
    fi
done

echo "All processing completed. Results are in $output_dir"

