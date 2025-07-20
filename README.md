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
Or build it locally from the provided Dockerfile:
```
cd mitodelta
docker build -t mitodelta_env .
```
The -t mitodelta_env option tags your image for easier reference.


## Usage
The workflow is managed via [Snakemake](https://snakemake.readthedocs.io/en/stable/).
Each step of the pipeline is described below.

### Step 1. Split BAM files by cell types
First, copy the `Snakefile` to your working directory, and then configure according to your environment.
In the `Snakefile`, set the paths to the following:
- BAM directory (`bam_dir`)
- Cell-type label directory (`label_dir`)
- Output directory (`out_dir`)

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
snakemake --cores 1 results/step2.txt
```
This will execute `02_step2.sh`,`2_deletion_call.py` and generate a table of candidate deletions.

### Step 3. Variant filtering
This step applies a beta-binomial error model to filter out likely false positives.
The filtering thresholds (error rate and FDR) are configurable in the `Snakefile`.

Run this step with:
```
snakemake --cores 1 /path/to/output_dir/step3_deletions_afterfiltering.tsv
```
The result is a list of high-confidence deletions.


## Notes
- You must define the variable `mitodelta` (the path to the pipeline) in the `Snakefile`.
- Intermediate steps generate dummy files (`results/step1.txt`, `results/step2.txt`) to help Snakemake manage dependencies.
- Ensure all required input files exist and paths are correct.

## License
This project is licensed under the MIT License - see the [LICENSE](./LICENSE) file for details.
