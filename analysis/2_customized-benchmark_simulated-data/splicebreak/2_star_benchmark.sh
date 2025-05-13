#!/bin/bash

#SBATCH --job-name=s.ben.sp
#SBATCH --output=./2_star_benchmark/out.txt
#SBATCH --error=./2_star_benchmark/err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=64G

outdir="2_star_benchmark"
sbpath="/../../splicebreak/Splice-Break2_custom_241221_v2"
fastqs="/home/hrknkg/flux/250410_flux20del_80error/2_merge_wt_del_500K"

mkdir -p $outdir/log

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> $outdir/out.txt

# Splice-Break2
apptainer exec --bind $HOME:$HOME --pwd $PWD ../splicebreak-env_1.0.0.sif\
 $sbpath/Splice-Break2_single-end_star.sh $fastqs $outdir $outdir/log $sbpath --align=yes --ref=mouse --skip_preAlign=yes

end_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $end_time" >> $outdir/out.txt
