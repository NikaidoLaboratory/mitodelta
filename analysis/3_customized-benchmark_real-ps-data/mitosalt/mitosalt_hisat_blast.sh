#!/bin/bash

#$ -q node.q
#$ -notify
#$ -N mito.hb
#$ -o log/hisat.blast.o.txt
#$ -e log/hisat.blast.e.txt
#$ -pe threads 4

# Read: Real scRNA-seq pseudo bulk read, downsampled to 20K-20M read (Pearson syndrome)
input="/data2/hrknkg/mitosalt/MitoSAlt_custom_241227"
fastq="/data2/hrknkg/bulk/GSE173936_pearson_scrna/250124_pseudo_ds20K-20M"
outdir="./hisat_blast"

sizes=(20000 100000 200000 1000000 2000000 10000000 20000000)

mkdir -p $outdir
cd $outdir

# make dir
mkdir -p bam bw indel log tab

# mitosalt
for ref in whole mt; do
    for back in breakspan spotdepth; do
        script="${input}/MitoSAlt_SE1.1.1_HISAT_blast_${back}.pl"
        config="${input}/config_human_${ref}_blast.txt"
        for i in 7 8 9; do
            pt=$((i - 6))
            for seed in 1 2 3 4 5; do
                for size in "${sizes[@]}"; do
                    perl $script $config "$fastq/SRR1443333${i}_${size}_s${seed}.R1.fastq" "pt${pt}.${size}.s${seed}"
                done
                rm -f core.*
            done
        done
        mv indel "indel.HISAT.${ref}.blast.${back}"
        mkdir -p indel
    done
done

# remove dirs
rm -r bam bw log tab indel
rm delplot.Rout


