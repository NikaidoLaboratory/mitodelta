#!/bin/bash

#SBATCH --job-name=last.p118_f85
#SBATCH --output=1_logs/p118_f85.o.txt
#SBATCH --error=1_logs/p118_f85.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p118_f85
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p118_f85_mitosalt.sh

