#!/bin/bash

# Step 2. Identifying candidate deletions via LAST

if [ "$#" -ne 2 ]; then
  echo "Usage: $0 <mitodelta path> <config file>"
  exit 1
fi

mitodelta="$1"
config="$2"
fq_dir="1_splitfq"
output="2_lastout"

mkdir -p $output


# Run deletion calling
cd $output || exit 1

for fastq in ../$fq_dir/*.fastq; do
  filename=$(basename "$fastq")
  sample="${filename%.fastq}"
  python "$mitodelta/scripts/2_deletion_call.py" "$config" "$fastq" "$sample" "$mitodelta"
done

rm -rf "bam" "bw" "tab"
cd ../


# Collect results
result="./results/step2_deletions_beforefiltering.tsv"
echo -e "name\tbreak5\tbreak3\tdelread\twtread\theteroplasmy" > "$result"

if ls $output/del/*.cluster 1> /dev/null 2>&1; then
  for file in "$output/del"/*.cluster; do
    base_name=$(basename "$file" .cluster)
    awk -F'\t' -v name="$base_name" '
      {
        split($3, c3_values, ",");
        split($4, c4_values, ",");
        print name "\t" c3_values[1] "\t" c4_values[1] "\t" $7 "\t" $8 "\t" $9
      }' "$file" >> "$result"
  done
else
  echo "Warning: No .cluster files found in $output/del/"
fi
