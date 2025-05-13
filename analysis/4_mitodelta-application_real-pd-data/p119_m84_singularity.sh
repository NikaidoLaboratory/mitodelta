#!/bin/bash

#SBATCH --job-name=last.p119_m84
#SBATCH --output=1_logs/p119_m84.o.txt
#SBATCH --error=1_logs/p119_m84.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p119_m84
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p119_m84_mitosalt.sh

