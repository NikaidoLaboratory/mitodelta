#!/bin/bash

#SBATCH --job-name=last.c154_m93
#SBATCH --output=1_logs/c154_m93.o.txt
#SBATCH --error=1_logs/c154_m93.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd c154_m93
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./c154_m93_mitosalt.sh

