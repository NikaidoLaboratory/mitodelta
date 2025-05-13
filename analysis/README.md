# Code Repository for Paper Analyses

This repository contains scripts used for analyses presented in the associated publication.  
The analyses are organized into four directories, each corresponding to a specific analysis described in the paper.  
Custom scripts used across these analyses are stored in the `eklipse/`, `mitosalt/`, and `splicebreak/` directories.  

## Directory Structure
.  
├── eklipse/ # Custom scripts for Eklipse  
├── mitosalt/ # Custom scripts for MitoSalt  
├── splicebreak/ # Custom scripts for SpliceBreak  
├── 1_defalut-benchmark_simulated-data/ # Default benchmark using simulated data  
├── 2_customized-benchmark_simulated-data/ # Customized benchmark using simulated data  
├── 3_customized-benchmark_real-ps-data/ # Customized benchmark using real data  
├── 4_mitodelta-application_real-pd-data/ # MitoDelta application using real Parkinson’s disease data  

## Overview of Contents

- **1_defalut-benchmark_simulated-data/**  
  Benchmarking analysis with default settings on simulated data.

- **2_customized-benchmark_simulated-data/**  
  Customized benchmarking on simulated data. This analysis uses scripts from the `eklipse/`, `mitosalt/`, and `splicebreak/` directories.

- **3_customized-benchmark_real-ps-data/**  
  Customized benchmarking using real Pearson syndrome patients' scRNA-seq data.

- **4_mitodelta-application_real-pd-data/**  
  Application of MitoDelta analysis on real Parkinson’s disease data.

## Environment & Usage

Each directory includes scripts and/or documentation (`README.md`) detailing the environment, dependencies, and execution steps required for the analysis. Please refer to the respective folders for specifics.

