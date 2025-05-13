#!/bin/bash

#$ -q large.q
#$ -notify
#$ -N sb.star.benchmark
#$ -o ./logs/sb.star.benchmark.o.txt
#$ -e ./logs/sb.star.benchmark.e.txt
#$ -pe threads 8

INPUT="/data2/hrknkg/bulk/GSE173936_pearson_scrna/250124_pseudo_ds20K-20M_forSB"
OUTPUT="./star_benchmark"
SB_PATH="../../splicebreak/Splice-Break2_custom_241221"

# make dirs
mkdir -p $OUTPUT
mkdir -p ${OUTPUT}/log

# Splice-Break
$SB_PATH/Splice-Break2_single-end_star.sh ${INPUT}/pt1 ${OUTPUT} ${OUTPUT}/log $SB_PATH --align=yes --ref=human --skip_preAlign=yes
$SB_PATH/Splice-Break2_single-end_star.sh ${INPUT}/pt2 ${OUTPUT} ${OUTPUT}/log $SB_PATH --align=yes --ref=human --skip_preAlign=yes
$SB_PATH/Splice-Break2_single-end_star.sh ${INPUT}/pt3 ${OUTPUT} ${OUTPUT}/log $SB_PATH --align=yes --ref=human --skip_preAlign=yes

