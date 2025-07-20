#!/bin/bash

#SBATCH --job-name=last.c127_m65
#SBATCH --output=1_logs/c127_m65.o.txt
#SBATCH --error=1_logs/c127_m65.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd c127_m65
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./c127_m65_mitosalt.sh

