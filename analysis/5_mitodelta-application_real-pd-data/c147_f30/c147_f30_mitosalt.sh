#!/bin/bash

# Read: Real snRNA-seq(10x), cell type splited and pooled read, without downsample
input="/home/hrknkg/scomatic/250313_pd_snrna_sctransformv2_ds50/2_bamtofq"
script="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/MitoSAlt_SE1.1.1_lastonly.pl"
config="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/config_human_last_sing.txt"

# make dir
mkdir -p bam bw indel log tab

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> ../1_logs/c147_f30.o.txt

# mitosalt
for fastq in "${input}"/c147_f30.*.fastq; do
    [ -f "$fastq" ] || continue
    name=$(basename "$fastq" .fastq)
    perl "$script" "$config" "$fastq" "$name"
done

# remove dirs
rm -r bam bw log tab
rm -f delplot.Rout

echo "All FASTQ files have been processed."
end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $end_time" >> ../1_logs/c147_f30.o.txt

