!/bin/bash

# Extract heteroplasmy for all clusters

# Create or empty the output file
output_file="result_flux20del_lastonly.tsv"

# Process each .cluster file in the subdirectory
echo -e "name\tbreak5\tbreak3\tdelread\twtread\theteroplasmy" > "$output_file"
for file in ./indel/*.cluster; do
    if [[ -f "$file" ]]; then
        base_name=$(basename "$file" .cluster)
        # Extract lines by 3rd and 4th column
        awk -F'\t' -v name="$base_name" '
            {
                split($3, break3_values, ",");
                split($4, break4_values, ",");
                print name "\t" break3_values[1] "\t" break4_values[1] "\t" $7 "\t" $8 "\t" $9
            }' "$file" >> "$output_file"
    fi
done

echo "All processing completed. Results are in $output_dir"
