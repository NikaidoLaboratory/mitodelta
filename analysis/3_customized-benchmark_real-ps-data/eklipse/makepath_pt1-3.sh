#!/bin/bash

base_dir="/data2/hrknkg/eklipse/250124_benchmark_psrna_50K-50M/250124_bam"
out_dir="blast_result"
mkdir -p $out_dir

for input_dir in "$base_dir"/*; do
  [ -d "$input_dir" ] || continue
  dir_name=$(basename "$input_dir")
  output_file="${out_dir}/${dir_name}_path.tsv"
  # file name
  for file_path in "$input_dir"/*.bam; do
    [ -f "$file_path" ] || continue
    file_name=$(basename "$file_path" .R1.bam)
    echo -e "${file_path}\t${file_name}" >> "$output_file"
  done
done

cp -r $out_dir "last_result"

echo "All processes completed."

