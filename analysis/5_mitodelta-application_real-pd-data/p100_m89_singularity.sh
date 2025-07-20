#!/bin/bash

#SBATCH --job-name=last.p100_m89
#SBATCH --output=1_logs/p100_m89.o.txt
#SBATCH --error=1_logs/p100_m89.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p100_m89
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p100_m89_mitosalt.sh

