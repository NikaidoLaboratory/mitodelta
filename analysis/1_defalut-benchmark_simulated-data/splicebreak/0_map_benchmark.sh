#!/bin/bash

#SBATCH --job-name=m.ben.sp
#SBATCH --output=./out.txt
#SBATCH --error=./err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=64G

outdir="0_map_benchmark"
sbpath="/home/hrknkg/splicebreak/Splice-Break2_custom_241221_v2/Single-End_Download/Splice-Break2-v3.0.1_SINGLE-END"
fastq="/home/hrknkg/flux/250410_flux20del_80error/2_merge_wt_del_500K"

mkdir -p $outdir/log

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> ./out.txt

# Splice-Break2
apptainer exec --bind $HOME:$HOME --pwd $PWD ../250408_benchmark_flux3del/splicebreak-env_1.0.0.sif\
 $sbpath/Splice-Break2_single-end.sh $fastq $outdir $outdir/log $sbpath --align=yes --ref=mouse --skip_preAlign=yes

end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $end_time" >> ./out.txt
