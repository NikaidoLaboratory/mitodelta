#!/bin/bash

mkdir 1_logs

sample_list=(
  "c127_m65" "c128_f81" "c129_m86" "c130_m61" "c131_m65"
  "c142_m62" "c147_f30" "c151_f77" "c152_f93" "c153_m91"
  "c154_m93" "c158_m89" "c159_f73" "c165_m91"
  "p096_f90" "p098_m99" "p100_m89" "p102_f57" "p103_m68"
  "p104_m81" "p105_m78" "p107_m82" "p109_m98" "p110_m82"
  "p111_m80" "p116_m77" "p118_f85" "p119_m84" "p120_f85")

for sample in "${sample_list[@]}"; do
  mkdir -p ${sample}
  job_script="${sample}/${sample}_mitosalt.sh"
  run_script="${sample}_singularity.sh"

  cat > "$job_script" <<EOF
#!/bin/bash

# Read: Real snRNA-seq(10x), cell type splited and pooled read, without downsample
input="/home/hrknkg/scomatic/250313_pd_snrna_sctransformv2_ds50/2_bamtofq"
script="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/MitoSAlt_SE1.1.1_lastonly.pl"
config="/home/hrknkg/mitosalt/MitoSAlt_custom_250130/config_human_last_sing.txt"

# make dir
mkdir -p bam bw indel log tab

start_time=\$(date "+%Y-%m-%d %H:%M:%S")
echo "Job started at: \$start_time" >> ../1_logs/$sample.o.txt

# mitosalt
for fastq in "\${input}"/${sample}.*.fastq; do
    [ -f "\$fastq" ] || continue
    name=\$(basename "\$fastq" .fastq)
    perl "\$script" "\$config" "\$fastq" "\$name"
done

# remove dirs
rm -r bam bw log tab
rm -f delplot.Rout

echo "All FASTQ files have been processed."
end_time=\$(date "+%Y-%m-%d %H:%M:%S")
echo "Job ended at: \$end_time" >> ../1_logs/$sample.o.txt

EOF

  chmod +x "$job_script"

  cat > "$run_script" <<EOF
#!/bin/bash

#SBATCH --job-name=last.$sample
#SBATCH --output=1_logs/$sample.o.txt
#SBATCH --error=1_logs/$sample.e.txt
#SBATCH --nodes=1
#SBATCH --partition=hss
#SBATCH --cpus-per-task=8
#SBATCH --ntasks=1
#SBATCH --mem=24G

cd $sample
apptainer exec --bind \$HOME:\$HOME --pwd \$PWD ../../mitosalt-env_1.0.1.sif ./${sample}_mitosalt.sh

EOF

  chmod +x "$run_script"

  echo "Saved job script: $job_script & $run_script"
done
