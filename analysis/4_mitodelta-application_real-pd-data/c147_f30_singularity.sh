#!/bin/bash

#SBATCH --job-name=last.c147_f30
#SBATCH --output=1_logs/c147_f30.o.txt
#SBATCH --error=1_logs/c147_f30.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd c147_f30
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./c147_f30_mitosalt.sh

