#!/bin/bash

#SBATCH --job-name=b.m.l.mito
#SBATCH --output=./02_bwa_mt_last/out.txt
#SBATCH --error=./02_bwa_mt_last/err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=1
#SBATCH --ntasks=1
#SBATCH --mem=8G

cd ./02_bwa_mt_last

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: $start_time" >> ./out.txt

module load miniforge3/24.11.3
eval "$(conda shell.bash hook)"

conda activate eklipse_last-env
python /home/hrknkg/eklipse/eKLIPse_last_250117/eKLIPse.py \
  -in ../pathdir/0_bwa_mt_path.tsv \
  -ref /home/hrknkg/eklipse/eKLIPse_default/data/NC_005089.1.gb \
  -out ./ \
  -downcov 0 -minlen 50 -bilateral False -mitosize 100
conda deactivate

mv eKLIPse_*/* ./
rm -rf eKLIPse_*/

start_time=$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: $start_time" >> ./out.txt

