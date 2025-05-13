#!/bin/bash

#SBATCH --job-name=s.w.b.mito
#SBATCH --output=./10_star_whole_blast/out.txt
#SBATCH --error=./10_star_whole_blast/err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=128G

cd ./10_star_whole_blast
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt_full-env_1.0.1.sif bash -c '

# Read: Flux-simulator 3 reads
config="/home/hrknkg/mitosalt/MitoSAlt_custom_241227/config_mouse_whole_blast.txt"
script="/home/hrknkg/mitosalt/MitoSAlt_custom_241227/MitoSAlt_SE1.1.1_STAR_blast_breakspan.pl"
fastqs="/home/hrknkg/flux/250410_flux20del_80error/2_merge_wt_del_500K"
outdir="indel.STAR.whole.BLAST"

# make dir
mkdir -p bam bw indel log tab

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> ./out.txt

# mitosalt
for fastq in $fastqs/*.fastq; do
    id=$(basename "$fastq" .fastq)
    perl $script $config "$fastq" "$id"
done

# remove & rename dirs
mv indel $outdir
rm -r bam bw log tab
rm -f delplot.Rout

end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $end_time" >> ./out.txt

'

