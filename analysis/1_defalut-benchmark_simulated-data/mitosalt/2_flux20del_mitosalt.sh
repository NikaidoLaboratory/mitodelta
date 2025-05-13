#!/bin/bash

# Read
input="/home/hrknkg/flux/250410_flux20del_80error/2_merge_wt_del_500K"
script="../../mitosalt/MitoSAlt_custom_241227/MitoSAlt_SE1.1.1_HISAT_last_breakspan.pl"
config="../../mitosalt/MitoSAlt_custom_241227/config_mouse_whole_last.txt"

# make dir
mkdir -p bam bw indel log tab

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> out.txt

# mitosalt
for fastq in "${input}"/*.fastq; do
    [ -f "$fastq" ] || continue
    name=$(basename "$fastq" .fastq)
    perl "$script" "$config" "$fastq" "$name"
done

# remove dirs
rm -r bam bw log tab
rm -f delplot.Rout

echo "All FASTQ files have been processed."
end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $end_time" >> out.txt
