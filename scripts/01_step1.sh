#!/bin/bash

# Step 1. Split bam files by cell type

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <mitodelta path> <bam dir> <label dir> <output dir>"
  exit 1
fi

mitodelta="$1"
bam_dir="$2"
lab_dir="$3"
out_dir="$4"
output="$out_dir/1_splitfq"


mkdir -p $output
mkdir -p $output/log


# Make job script
for label in $lab_dir/*.tsv; do
  filename=$(basename "$label")
  sample="${filename%.tsv}"
  bam="$bam_dir/$sample.bam"
  script="$output/1_$sample.sh"

  cat > "$script" <<EOF
#!/bin/bash

python $mitodelta/scripts/1_split_bam.py \
--bam $bam \
--meta $label \
--outdir $output \
--max_NH 1 \
--min_MQ 0

for outbam in "$output/$sample".*.bam; do
  outfq="\$(dirname "\$outbam")/\$(basename "\${outbam%.bam}").fastq"
  samtools fastq "\$outbam" > "\$outfq"
  rm "\$outbam"
done
EOF

  chmod +x "$script"
done


for script in "$output"/*.sh; do
  bash $script
done
