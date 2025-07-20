#!/bin/bash

#SBATCH --job-name=last.p109_m98
#SBATCH --output=1_logs/p109_m98.o.txt
#SBATCH --error=1_logs/p109_m98.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p109_m98
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p109_m98_mitosalt.sh

