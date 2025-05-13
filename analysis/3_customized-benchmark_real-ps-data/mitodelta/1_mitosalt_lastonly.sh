#!/bin/bash

#$ -q node.q
#$ -notify
#$ -N last
#$ -o log/last.o.txt
#$ -e log/last.e.txt
#$ -pe threads 12

# Read: Real scRNA-seq pseudo bulk read, downsampled to 20K-20M read (Pearson syndrome)
script="/data2/hrknkg/mitosalt/MitoSAlt_custom_250130/MitoSAlt_SE1.1.1_lastonly.pl"
config="/data2/hrknkg/mitosalt/MitoSAlt_custom_250130/config_human_last.txt"
fastqs="/data2/hrknkg/bulk/GSE173936_pearson_scrna/250124_pseudo_ds20K-20M"

# make dir
mkdir -p bam bw indel log tab

# mitosalt
for fastq in $fastqs/*.R1.fastq; do
    file_name=$(basename $fastq .R1.fastq)
    perl $script $config $fastq $file_name
done

# remove dirs
rm -r bam bw log tab
rm delplot.Rout
mv indel indel.lastonly.breakspan
