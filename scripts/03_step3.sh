#!/bin/bash

# Step 3. Filtering candidate deletions by a beta-binomial model

if [ "$#" -ne 4 ]; then
  echo "Usage: $0 <mitodelta path> <output dir> <error threshold> <fdr threshold>"
  exit 1
fi

mitodelta="$1"
out_dir="$2"
err="$3"
fdr="$4"
input_file="$out_dir/step2_deletions_beforefiltering.tsv"
output_file="$out_dir/step3_deletions_afterfiltering.tsv"


python $mitodelta/scripts/3_filter_variant.py $input_file $output_file --err $err --fdr $fdr 
