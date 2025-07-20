# MitoDelta
**MitoDelta** is a computational pipeline for identifying mitochondrial DNA (mtDNA) deletion variants at cell-type resolution.

## Instalation
First, clone the MitoDelta repository:
```
git clone https://github.com/NikaidoLaboratory/mitodelta.git
```
Then, pull the pre-built Docker image:
```
docker pull harukonak/mitodelta_env:1.0.2
```
When you run MitoDelta, activate the Docker environment using the command below.  
Replace `/path/to/mitodelta_repository` with the absolute path to the cloned mitodelta GitHub repository (e.g., `/home/username/projects/mitodelta`), then proceed with Steps 1–3.
```
docker run -it --rm --name my_container \
  -v "$(pwd)":/workspace \
  -v /path/to/mitodelta_repository:/mitodelta_abs \
  -w /workspace \
  mitodelta_env:1.0.2 \
  /bin/bash
```

## Usage
The workflow is managed via [Snakemake](https://snakemake.readthedocs.io/en/stable/).
Each step of the pipeline is described below.

### Step 1. Split BAM files by cell types
First, copy the `Snakefile` to your working directory, and then configure according to your environment.
In the `Snakefile`, set the paths to the following:
- BAM directory (`bam_dir`)
- Cell-type label directory (`label_dir`)

Then run:
```
snakemake --cores 1 results/step1.txt
```
This step will call the script `01_step1.sh`,`1_split_bam.py` to split your BAM files based on cell-type labels.

### Step 2. Candidate deletion calling
This step detects candidate mtDNA deletions using the provided configuration file (e.g., config_human.txt).
Update the `Snakefile` to specify the correct path to the config file.

Run the step with:
```
snakemake --cores 1 results/step2_deletions_beforefiltering.tsv
```
This will execute `02_step2.sh`,`2_deletion_call.py` and generate a table of candidate deletions.

### Step 3. Variant filtering
This step applies a beta-binomial error model to filter out likely false positives.
The filtering thresholds (error rate and FDR) are configurable in the `Snakefile`.

Run this step with:
```
snakemake --cores 1 results/step3_deletions_afterfiltering.tsv
```
This will execute `3_filter_variant.py` and return the final list of high-confidence deletions at the `results/` directory.


## Notes
- You must define the variable `mitodelta` (the path to the pipeline) in the `Snakefile`.
- Step 1 generates a dummy file (`results/step1.txt`) to help Snakemake manage dependencies.
- Ensure all required input files exist and paths are correct.

## License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
