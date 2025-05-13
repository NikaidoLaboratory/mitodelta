#!/bin/bash

#$ -q node.q
#$ -notify
#$ -N eklipse1
#$ -o ./log/out1.txt
#$ -e ./log/err1.txt
#$ -pe threads 8

for tsv_file in blast_result/*_path.tsv; do
  prefix=$(basename "$tsv_file" _path.tsv)

  # docker container
  /usr/bin/docker run --rm --init -u `id -u`:`id -g`\
    -v /etc/passwd:/etc/passwd:ro \
    -v /etc/group:/etc/group:ro \
    -v $HOME:$HOME \
    -v /data2/hrknkg:/data2/hrknkg \
    -w $PWD --name ${USER}_eklipse \
    quay.io/biocontainers/eklipse:1.8--hdfd78af_1 \
    python /data2/hrknkg/eklipse/eKLIPse_custom_250126/eKLIPse.py \
    -in "$tsv_file" \
    -ref /data2/hrknkg/eklipse/eKLIPse/data/NC_012920.1.gb \
    -out blast_result \
    -scsize 15 -mapsize 15 -downcov 0 -minlen 50 -bilateral False -mitosize 100 -thread 8

  mv $(ls -d blast_result/eKLIPse_* | head -n 1) "blast_result/${prefix}" 2>/dev/null || { exit 1; }
done

