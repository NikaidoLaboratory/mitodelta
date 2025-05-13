#!/bin/bash

#SBATCH --job-name=last
#SBATCH --output=out.txt
#SBATCH --error=err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=8G

apptainer exec --bind $HOME:$HOME --pwd $PWD ../mitosalt-env_1.0.1.sif ./2_flux20del_lastonly.sh
