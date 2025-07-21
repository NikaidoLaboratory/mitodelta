#!/bin/bash -l

#SBATCH --job-name=seqkit
#SBATCH --output=./out.txt
#SBATCH --error=./err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=4
#SBATCH --ntasks=1
#SBATCH --mem=64G

# downsample 2M ~ 20K, both WT or deleted ARPE-19 cell
input1="/home/hrknkg/geodata/GSE210331_ARPE19WT_250628/3_fastp/SRR20751597.fastq.gz"
input2="/home/hrknkg/geodata/GSE276718_mtdnadel_250622/5_bam2fq/SRR30600800.fastq.gz"

for input in $input1 $input2; do
	basename=$(basename "$input" .fastq.gz)
	for i in 2000000 200000 20000; do
		seqkit sample -n $i -j 4 $input > ${basename}.${i}.fastq
	done
done	


