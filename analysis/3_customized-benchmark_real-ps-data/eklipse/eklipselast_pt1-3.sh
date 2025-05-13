#!/bin/bash

#$ -q node.q
#$ -notify
#$ -N eklipsel2
#$ -o ./log/out2.txt
#$ -e ./log/err2.txt
#$ -pe threads 8

input_dir="last_result"

conda activate eklipse_env2

for tsv_file in "${input_dir}"/*_path.tsv; do
  prefix=$(basename "$tsv_file" _path.tsv)

  # last version
  python /data2/hrknkg/eklipse/eKLIPse_custom_250117/eKLIPse.py \
  -in "$tsv_file" \
  -ref /data2/hrknkg/eklipse/eKLIPse/data/NC_012920.1.gb \
  -out ${input_dir} \
  -scsize 15 -mapsize 15 -downcov 0 -minlen 50 -bilateral False -mitosize 100 -thread 8
  # rename dir
  mv $(ls -d ${input_dir}/eKLIPse_* | head -n 1) "${input_dir}/${prefix}" 2>/dev/null || { exit 1; }

done

conda deactivate

