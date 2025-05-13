#!/bin/bash

basedir="/home/hrknkg/eklipse/250414_flux20del"
subdirs=("0_bwa_mt")

for subdir in "${subdirs[@]}"; do
    input_dir="${basedir}/${subdir}"
    output_file="1_bam_path.tsv"
    > "$output_file"
    for file_path in "$input_dir"/*.bam; do
        if [ -f "$file_path" ]; then
            file_name=$(basename "$file_path" .bam)
            echo -e "${file_path}\t${file_name}" >> "$output_file"
        fi
    done
done
