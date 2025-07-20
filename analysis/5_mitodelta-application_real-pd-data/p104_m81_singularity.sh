#!/bin/bash

#SBATCH --job-name=last.p104_m81
#SBATCH --output=1_logs/p104_m81.o.txt
#SBATCH --error=1_logs/p104_m81.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p104_m81
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p104_m81_mitosalt.sh

