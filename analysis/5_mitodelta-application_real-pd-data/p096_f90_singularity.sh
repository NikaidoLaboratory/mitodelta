#!/bin/bash

#SBATCH --job-name=last.p096_f90
#SBATCH --output=1_logs/p096_f90.o.txt
#SBATCH --error=1_logs/p096_f90.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p096_f90
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p096_f90_mitosalt.sh

