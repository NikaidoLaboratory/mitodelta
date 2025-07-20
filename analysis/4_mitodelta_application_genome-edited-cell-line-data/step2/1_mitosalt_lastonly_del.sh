#!/bin/bash

#SBATCH --job-name=mitosalt_lastonly
#SBATCH --output=out1.txt
#SBATCH --error=err1.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=16G

# deleted
fastqs="/home/hrknkg/revise_202506/250628_ARPE19_dsfq/SRR30600800"
script="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/MitoSAlt_SE1.1.1_lastonly.pl"
config="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/config_human_last_sing.txt"

# make dir
mkdir -p 1_del
cd 1_del
mkdir -p bam bw indel log tab

for fastq in "$fastqs"*.fastq; do
	name=$(basename "$fastq" .fastq)
	apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif \
		perl "$script" "$config" "$fastq" "$name"
done

# remove dirs
rm -r bam bw log tab
rm -f delplot.Rout

mv indel indel.del

