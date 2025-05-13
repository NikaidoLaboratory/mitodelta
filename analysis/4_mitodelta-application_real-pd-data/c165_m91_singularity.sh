#!/bin/bash

#SBATCH --job-name=last.c165_m91
#SBATCH --output=1_logs/c165_m91.o.txt
#SBATCH --error=1_logs/c165_m91.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd c165_m91
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./c165_m91_mitosalt.sh

