#!/bin/bash

#SBATCH --job-name=last.p102_f57
#SBATCH --output=1_logs/p102_f57.o.txt
#SBATCH --error=1_logs/p102_f57.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p102_f57
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p102_f57_mitosalt.sh

