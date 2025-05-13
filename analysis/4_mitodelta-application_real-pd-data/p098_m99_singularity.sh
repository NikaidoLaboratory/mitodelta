#!/bin/bash

#SBATCH --job-name=last.p098_m99
#SBATCH --output=1_logs/p098_m99.o.txt
#SBATCH --error=1_logs/p098_m99.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p098_m99
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p098_m99_mitosalt.sh

