#!/bin/bash

basedir="/home/hrknkg/eklipse/250416_flux20del_bam"
subdirs=("0_bwa_mt" "1_bwa_whole" "2_hisat_mt" "3_hisat_whole" "4_star_mt" "5_star_whole")
pathdir="pathdir"
mkdir -p $pathdir

for subdir in "${subdirs[@]}"; do
    input_dir="${basedir}/${subdir}"
    output_file="${pathdir}/${subdir}_path.tsv"
    > "$output_file"
    for file_path in "$input_dir"/*.bam; do
        if [ -f "$file_path" ]; then
	    file_name=$(basename "$file_path" .bam)
	    echo -e "${file_path}\t${file_name}" >> "$output_file"
	fi
    done
done


