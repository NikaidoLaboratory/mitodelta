#!/bin/bash -l

#SBATCH --job-name=bwa.mt
#SBATCH --nodes=1
#SBATCH --output=./log/0_bwa_mt.o.txt
#SBATCH --error=./log/0_bwa_mt.e.txt
#SBATCH --partition=hss
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=8G

module load apptainer/samtools/1.21
module load apptainer/bwa-mem2/2.2.1

input="/home/hrknkg/flux/250410_flux20del_80error/2_merge_wt_del_500K"
ref="/home/hrknkg/ref/GRCm39_bwamem2_mtonly/Mus_musculus.GRCm39.dna.chromosome.MT.fa"
output="0_bwa_mt"

mkdir -p $output
cd $output

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> ../log/${output}.o.txt

for file in ${input}/*.fastq; do
    sample=$(basename "$file" .fastq)
    bwa-mem2 mem "${ref}" "${file}" > "${sample}.sam"
    samtools view -bS "${sample}.sam" | samtools sort -o "${sample}.bam"
    rm "${sample}.sam"
done

end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $end_time" >> ../log/${output}.o.txt
