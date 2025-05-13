#!/bin/bash

#SBATCH --job-name=b.m.b.mito
#SBATCH --output=./log/2_eklipse_out.txt
#SBATCH --error=./log/2_eklipse_err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=8G

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> ./log/2_eklipse_out.txt

apptainer exec --bind $HOME:$HOME --pwd $PWD ../eklipse_1.8--hdfd78af_1.sif \
  python ../../eklipse/eKLIPse/eKLIPse.py \
  -in ./1_bam_path.tsv \
  -ref /home/hrknkg/eklipse/eKLIPse_default/data/NC_005089.1.gb \
  -out ./ \
  -downcov 0 -minlen 50 -bilateral False -mitosize 100

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $start_time" >> ./log/2_eklipse_out.txt

mv eKLIPse_*/ 2_eKLIPse_result/
