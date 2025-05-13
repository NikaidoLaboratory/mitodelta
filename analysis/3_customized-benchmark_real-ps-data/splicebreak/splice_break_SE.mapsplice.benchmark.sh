#!/bin/bash

#$ -q large.q
#$ -notify
#$ -N sb.map.benchmark
#$ -o ./logs/sb.map.benchmark.o.txt
#$ -e ./logs/sb.map.benchmark.e.txt
#$ -pe threads 8

INPUT="/data2/hrknkg/bulk/GSE173936_pearson_scrna/250124_pseudo_ds20K-20M_forSB"
OUTPUT="./map_benchmark"
SB_PATH="../../splicebreak/Splice-Break2_custom_241221"

mkdir -p $OUTPUT # make dirs
mkdir -p ${OUTPUT}/log

# Splice-Break
$SB_PATH/Splice-Break2_single-end.sh ${INPUT}/pt1 ${OUTPUT} ${OUTPUT}/log $SB_PATH --align=yes --ref=human --skip_preAlign=yes
$SB_PATH/Splice-Break2_single-end.sh ${INPUT}/pt2 ${OUTPUT} ${OUTPUT}/log $SB_PATH --align=yes --ref=human --skip_preAlign=yes
$SB_PATH/Splice-Break2_single-end.sh ${INPUT}/pt3 ${OUTPUT} ${OUTPUT}/log $SB_PATH --align=yes --ref=human --skip_preAlign=yes

