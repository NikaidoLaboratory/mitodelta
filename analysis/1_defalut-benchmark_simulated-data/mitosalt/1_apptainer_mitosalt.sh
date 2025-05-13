#!/bin/bash

#SBATCH --job-name=mitosalt
#SBATCH --output=out.txt
#SBATCH --error=err.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=8G

apptainer exec --bind $HOME:$HOME --pwd $PWD ../250407_benchmark_flux3del_v2/mitosalt_full-env_1.0.1.sif ./2_flux20del_mitosalt.sh
