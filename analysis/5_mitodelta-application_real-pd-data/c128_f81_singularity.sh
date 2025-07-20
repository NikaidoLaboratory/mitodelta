#!/bin/bash

#SBATCH --job-name=last.c128_f81
#SBATCH --output=1_logs/c128_f81.o.txt
#SBATCH --error=1_logs/c128_f81.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd c128_f81
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./c128_f81_mitosalt.sh

