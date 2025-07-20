#!/bin/bash

#SBATCH --job-name=last.p116_m77
#SBATCH --output=1_logs/p116_m77.o.txt
#SBATCH --error=1_logs/p116_m77.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p116_m77
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p116_m77_mitosalt.sh

