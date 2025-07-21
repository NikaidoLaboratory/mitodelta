# MitoDelta
**MitoDelta** is a computational pipeline for identifying mitochondrial DNA (mtDNA) deletion variants at cell-type resolution from single cell RNA-seq data.

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
**1. Copy the Snakefile**  
First, copy the `Snakefile` to your working directory.
```
cp /path/to/mitodelta/Snakefile /path/to/your/working_directory/
```

**2. Configure Paths**  
In the `Snakefile`, set the paths to match your environment:
- `bam_dir/`: Directory containing sample BAM files (`.bam`)  
- `label_dir/`: Directory containing cell-type label files (`.tsv`)

**3. Prepare Input Files**  
For each sample, provide:  
- A BAM file in `bam_dir/`
- A corresponding cell-type label file in `label_dir/`  

Example directory structure:  
```
bam_dir/
├── Sample1.bam
├── Sample2.bam
├── Sample3.bam

label_dir/
├── Sample1.tsv
├── Sample2.tsv
├── Sample3.tsv
```
> Both files must share the same file name prefix (e.g., Sample1.bam and Sample1.tsv).
  
**4. Format of Cell-Type Label Files (`*.tsv`)**  
Each `.tsv` file should contain two columns:  
- `Index`: Cell barcode
- `Cell_type`: Annotated cell type  

Example: `Sample1.tsv`
```
Index	Cell_type
GACCACTAAGTTGTT	Astrocyte
AGGAGAGGAGGTGAA	Neuron
GCTAGGATAACCTTG	Oligodendrocyte
CTAGGTCGGATGACG	Astrocyte
CACAACAGCCTTATA	Microglia
```
**5. Run Step 1: Splitting BAM Files by Cell Type and Converting to Corresponding FASTQ Files**  
To execute this step, run the following command:
```
snakemake --cores 1 results/step1.txt
```
This step executes the script `01_step1.sh`, which calls `1_split_bam.py` to split your BAM files based on cell-type labels. The resulting output will be cell-type-splitted FASTQ files, saved in the `1_splitfq/` directory.

### Step 2. Candidate Deletion Calling
This step detects candidate mtDNA deletions using the provided configuration file (e.g., config_human.txt).
Update the `Snakefile` to specify the correct path to the config file.

Run the step with:
```
snakemake --cores 1 results/step2_deletions_beforefiltering.tsv
```
This will execute `02_step2.sh`,`2_deletion_call.py` and generate a table of candidate deletions.

### Step 3. Variant Filtering
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

## Citation
TBD
