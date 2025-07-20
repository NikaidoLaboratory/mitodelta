#!/bin/bash

#SBATCH --job-name=last.p111_m80
#SBATCH --output=1_logs/p111_m80.o.txt
#SBATCH --error=1_logs/p111_m80.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd p111_m80
apptainer exec --bind $HOME:$HOME --pwd $PWD ../../mitosalt-env_1.0.1.sif ./p111_m80_mitosalt.sh

