#!/bin/bash

#SBATCH --job-name=mitosalt_lastonly
#SBATCH --output=out0.txt
#SBATCH --error=err0.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=16G

# WT
fastqs="/home/hrknkg/revise_202506/250628_ARPE19_dsfq/SRR20751597"
script="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/MitoSAlt_SE1.1.1_lastonly.pl"
config="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/config_human_last_sing.txt"

# make dir
mkdir -p 0_wt
cd 0_wt
mkdir -p bam bw indel log tab

for fastq in "$fastqs"*.fastq; do
	name=$(basename "$fastq" .fastq)
	apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif \
		perl "$script" "$config" "$fastq" "$name"
done

# remove dirs
rm -r bam bw log tab
rm -f delplot.Rout

mv indel indel.wt

