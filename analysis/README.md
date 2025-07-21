# Code Repository of Analyses for the Paper  

This repository contains scripts and results in the analyses presented in the associated publication.  
The analyses are organized into five directories, each corresponding to a specific analysis described in the paper.  
Custom scripts used across these analyses are stored in the `eklipse/`, `mitosalt/`, and `splicebreak/` directories.  

## Directory Structure
.  
├── ```eklipse/                                              # Custom scripts for Eklipse```  
├── mitosalt/                                             # Custom scripts for MitoSalt  
├── splicebreak/                                          # Custom scripts for SpliceBreak  
├── 1_defalut-benchmark_simulated-data/                   # Default benchmark using simulated data  
├── 2_customized-benchmark_simulated-data/                # Customized benchmark using simulated data  
├── 3_customized-benchmark_real-ps-data/                  # Customized benchmark using real data  
├── 4_mitodelta_application_genome-edited-cell-line-data/ # MitoDelta application to cell line data  
├── 5_mitodelta-application_real-pd-data/                 # MitoDelta application to Parkinson’s disease data  

## Overview of Contents

- **1_defalut-benchmark_simulated-data/**  
  Benchmarking analysis with default settings on simulated data.

- **2_customized-benchmark_simulated-data/**  
  Benchmarking (including customized existing tools) on simulated data.

- **3_customized-benchmark_real-ps-data/**  
  Benchmarking (including customized existing tools) using real Pearson syndrome patients’ scRNA-seq data.

- **4_mitodelta_application_genome-edited-cell-line-data/**  
  Application of MitoDelta to scRNA-seq data from cell lines, including wild-type and mtDNA deletion introduced cells.

- **5_mitodelta-application_real-pd-data/**  
  Application of MitoDelta to snRNA-seq data from postmortem brain samples of Parkinson’s disease patients and matched healthy controls.

