#!/bin/bash

#SBATCH --job-name=last.p103_m68
#SBATCH --output=1_logs/p103_m68.o.txt
#SBATCH --error=1_logs/p103_m68.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p103_m68
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p103_m68_mitosalt.sh

