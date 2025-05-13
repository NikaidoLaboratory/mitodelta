#!/bin/bash

#SBATCH --job-name=b.w.b.mito
#SBATCH --output=./01_bwa_whole_blast/out.txt
#SBATCH --error=./01_bwa_whole_blast/err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=8G

cd ./01_bwa_whole_blast

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> ./out.txt

apptainer exec --bind $HOME:$HOME --pwd $PWD ../../eklipse_1.8--hdfd78af_1.sif \
  python /home/hrknkg/eklipse/eKLIPse_blast_250126/eKLIPse.py \
  -in ../pathdir/1_bwa_whole_path.tsv \
  -ref /home/hrknkg/eklipse/eKLIPse_default/data/NC_005089.1.gb \
  -out ./ \
  -downcov 0 -minlen 50 -bilateral False -mitosize 100

mv eKLIPse_*/* ./
rm eKLIPse_*/

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $start_time" >> ./out.txt

