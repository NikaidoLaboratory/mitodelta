#!/bin/bash

#SBATCH --job-name=last.c130_m61
#SBATCH --output=1_logs/c130_m61.o.txt
#SBATCH --error=1_logs/c130_m61.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd c130_m61
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./c130_m61_mitosalt.sh

