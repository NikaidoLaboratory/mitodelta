#!/bin/bash

#SBATCH --job-name=last.p110_m82
#SBATCH --output=1_logs/p110_m82.o.txt
#SBATCH --error=1_logs/p110_m82.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p110_m82
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p110_m82_mitosalt.sh

