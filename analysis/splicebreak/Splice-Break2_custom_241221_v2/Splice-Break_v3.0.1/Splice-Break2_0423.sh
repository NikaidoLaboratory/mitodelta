#!/bin/bash
#LiLi Xu and Michelle Webb
#University of Southern California
#v3.0.0-stable
#April 1, 2022

inputDir=$1
outputDir=$2
refDir=$3
sampleName=$4
nohupOutput=$5
reference_name=$6
SB_Path=$7
filterFails=0

time=`date +%d-%m-%Y-%H-%M-%S`
hostname=`hostname`
echo "Starting $0 at ${time} on ${hostname}">> ${nohupOutput}/${sampleName}_nohup.log

if [[ -d ${inputDir} && -d ${outputDir} && -d ${refDir} ]] ; then
        echo "MapSplice Dir: ${inputDir}">> ${nohupOutput}/${sampleName}_nohup.log
        echo "Output Dir: ${outputDir}">> ${nohupOutput}/${sampleName}_nohup.log
        echo "Reference Dir: ${refDir}">> ${nohupOutput}/${sampleName}_nohup.log
else
        echo "### ERROR: Check input parameters">> ${nohupOutput}/${sampleName}_nohup.log
        exit
fi

#Run Samtools mPileup
echo "Running Samtools">> ${nohupOutput}/${sampleName}_nohup.log
samtools mpileup -d 1000000 ${inputDir}/alignments.bam > ${outputDir}/pileup.txt
if [ $? -gt 0 ]; then
    echo "#ERROR: Please check that samtools is in your PATH">> ${nohupOutput}/${sampleName}_nohup.log
    exit
fi

#Run CountBases
echo "Running CountBases.py">> ${nohupOutput}/${sampleName}_nohup.log
/usr/bin/python ${refDir}/CountBases.py ${outputDir}/pileup.txt > ${outputDir}/BaseCounts.pileup.txt
if [ $? -gt 0 ]; then
    echo "#ERROR: Please check your Python version or pileup output">> ${nohupOutput}/${sampleName}_nohup.log
    exit
fi

#Add coverage across bases
echo "Adding per base coverage">> ${nohupOutput}/${sampleName}_nohup.log
awk 'NR>1{print $2+$3+$4+$5}' ${outputDir}/BaseCounts.pileup.txt > ${outputDir}/init_coverage.txt
sed -i '1i COVERAGE' ${outputDir}/init_coverage.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

#Prints an index for the coverage values
awk -F'\t' -v OFS='\t' '
  NR == 1 {print "NUM",$0; next}
  {print (NR-1), $0}
' ${outputDir}/init_coverage.txt > ${outputDir}/combined.txt

#Joins the reference position and actual coverage
join <( sed '1d' ${outputDir}/combined.txt)  <(sed '1d' ${refDir}/reference_and_primer_positions.txt) > ${outputDir}/coverage.txt

#   adjust NC with Nsub or rCRS
if [ $reference_name == "NC_012920.1_NSub" ]; then
    echo "Coverage with Nsub reference">> ${nohupOutput}/${sampleName}_nohup.log
    awk -v s=97 '{print $1+s, $2, $3}' ${outputDir}/coverage.txt > ${outputDir}/Coverage.txt
    #If col1 <= 16425, then newcol = col3 + 97 Else newcol=col3 - 16472
    awk '{ if($1<=16425) $4=$3+97; else $4=$3-16472; print $0; }' ${outputDir}/Coverage.txt > ${outputDir}/coverage.txt
    # delete column 3 and add the header
    awk '!($3="")' ${outputDir}/coverage.txt | sed $"1i${reference_name}\tCoverage\tPrimer_Position" | tr ' ' '\t' | sed -e "s/^M//" > ${outputDir}/Coverage.txt

else
    echo "Coverage with rCRS reference">> ${nohupOutput}/${sampleName}_nohup.log
    sed $"1i${reference_name}\tCoverage\tPrimer_Position" ${outputDir}/coverage.txt | tr ' ' '\t' | sed -e "s/^M//" > ${outputDir}/coverage2.txt

    awk '{ sub("\r$", ""); print }' ${outputDir}/coverage2.txt > ${outputDir}/Coverage.txt
fi

if [ $? -gt 0 ]; then
    ((filterFails++))
fi
#Calculates benchmark coverage and determines appropriate value
left_benchmark=$(awk '$1>=957 && $1<=1206' ${outputDir}/Coverage.txt | awk '{ total += $2 } END { print total/NR }')
right_benchmark=$(awk '$1>=15357 && $1<=15606' ${outputDir}/Coverage.txt | awk '{ total += $2 } END { print total/NR }')
left_div_right=$(echo "scale=3;$left_benchmark / $right_benchmark" | bc)
avg_benchmark=$(echo "scale=3;($left_benchmark + $right_benchmark) / 2" | bc)
junction_length=`cat ${inputDir}/junctions.txt | wc -l`
if (( $(echo "${left_div_right}  <= 1.4" | bc -l) )) ; then
    echo "Using average_benchmark" >> ${nohupOutput}/${sampleName}_nohup.log
    eval $(echo printf '"${avg_benchmark}%.s\n"' {1..${junction_length}}) | sed '1i Benchmark_Coverage' > ${outputDir}/avgBenchmark.txt
else
    echo "Using left_benchmark" >> ${nohupOutput}/${sampleName}_nohup.log
    eval $(echo printf '"${left_benchmark}%.s\n"' {1..${junction_length}}) | sed '1i Benchmark_Coverage' > ${outputDir}/avgBenchmark.txt
fi


#Assembling Junctions File
cat ${inputDir}/junctions.txt | cut -d$'\t' -f1-3,5,11 | awk -F ',' '{print $1 "\t" $2}' | awk -F '\t' '{print $1"\t"$2"\t"$3"\t"$4"\t"$5"\t"$6"\t"$2"-"$3"\t"$3 - $2 - 1}' > ${outputDir}/modifiedJunc.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

#Annotating
echo "Annotating">> ${nohupOutput}/${sampleName}_nohup.log
awk 'NR==FNR{a[$1]=$2;next}{if($1 in a){print $0,a[$1]; delete a[$1]} else print $0,"novel_deletion"}' ${refDir}/deletion_frequency_types.txt <(cut -f7 ${outputDir}/modifiedJunc.txt) > ${outputDir}/breakpoints.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

#Assembling
paste ${outputDir}/modifiedJunc.txt <(awk '{print $2}' ${outputDir}/breakpoints.txt) <( sed '1d' ${outputDir}/avgBenchmark.txt) | column -t -s $'\t' > ${outputDir}/intermediate.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

paste ${outputDir}/intermediate.txt <(awk '{printf "%.4f\n", ($4/$10)*100}' ${outputDir}/intermediate.txt) > ${outputDir}/intermediate_junctions.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

awk '{print $1"\t"$7"\t"$2"\t"$3"\t"$8"\t"$4"\t"$10"\t"$11"\t"$9"\t"$5"\t"$6}' ${outputDir}/intermediate_junctions.txt > ${outputDir}/intermediate_junctions2.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

#Filter1: Remove junction calls with read overhang < 20bp
echo "Applying Filter 1">> ${nohupOutput}/${sampleName}_nohup.log
awk '( ($10>=20) ) && ( ($11>=20) )' ${outputDir}/intermediate_junctions2.txt > ${outputDir}/large_deletion.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

## Remove deletion_size_bp smaller than 50 in larger deletions txt
awk '($5>=50)' ${outputDir}/large_deletion.txt > ${outputDir}/large_deletions.txt

## Adding the sampleID and replace the 2nd column with NC_012920.1
sed "s/^/${sampleName}\t&/g" ${outputDir}/large_deletions.txt > ${outputDir}/large_deletion.txt

awk -v var="$reference_name" '{$2=var}1' ${outputDir}/large_deletion.txt> ${outputDir}/large_deletions.txt

### LargeMTDeletions_WGS-only_NoPositionFilter.txt be created from large_deletion.txt
echo "Create LargeMTDeletions_WGS-only_NoPositionFilter.txt" >> ${nohupOutput}/${sampleName}_nohup.log
sed $"1iSample_ID\tReference_Genome\tMapSplice_Breakpoint\t5'_Break\t3'_Break\tDeletion_Size_bp\tDeletion_Reads\tBenchmark_Coverage\tDeletion_Read_%\tAnnotation\tLeft_Overhang\tRight_Overhang" ${outputDir}/large_deletions.txt | column -t > ${outputDir}/Large_Deletions_NC_012920.1_No-Position-Filter.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi
#### Annotation with the Impact of Gene  #241221escaped
#echo "Annotation with Impact of Gene" >> ${nohupOutput}/${sampleName}_nohup.log
#java -cp "${SB_Path}/Splice-Break_v3.0.1/mitomap_java_annotate/src" SpliceBreak.CompareMT ${outputDir}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${SB_Path}/Splice-Break_v3.0.1/mitomap_java_annotate/src/mitomap-genes-etc-position_110521.csv
#mv -v ${outputDir}/new_Impact.txt ${outputDir}/Large_Deletions_NC_012920.1_No-Position-Filter.txt >> ${nohupOutput}/${sampleName}_nohup.log


#Filter2: 5' Breakpoint greater than 357, 3' Breakpoint less than 15925
echo "Applying Filter 2">> ${nohupOutput}/${sampleName}_nohup.log
awk 'NR==1 || ((NR>1) && (($4>=357) && ($5<=15925)))' ${outputDir}/Large_Deletions_NC_012920.1_No-Position-Filter.txt > ${outputDir}/Large_Deletions_NC_012920.1_357-15925.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

#Filter2: 5' Breakpoint greater than 157, 3' Breakpoint less than 16125
awk 'NR==1 || ((NR>1) && (($4>=157) && ($5<=16125)))' ${outputDir}/Large_Deletions_NC_012920.1_No-Position-Filter.txt > ${outputDir}/Large_Deletions_NC_012920.1_157-16125.txt
if [ $? -gt 0 ]; then
    ((filterFails++))
fi

## filiter Top 30 MapSplice_Break
echo "Filtering Top 30 MapSplice_Break" >> ${nohupOutput}/${sampleName}_nohup.log
sed '1d' ${outputDir}/Large_Deletions_NC_012920.1_357-15925.txt  > ${outputDir}/Large_Deletions_NC_012920.1_357-15925.noheader.txt
sort ${outputDir}/Large_Deletions_NC_012920.1_357-15925.noheader.txt > ${outputDir}/Large_Deletions_NC_012920.1_357-15925.sorted.noheader.txt
join -a 1 -e 0 -1 2 -2 3 -o 2.1 1.1 0 1.3 1.4 1.5 2.7 2.8 2.9 1.6 2.11 2.12 1.7 1.8 1.9 1.10 1.11 1.12 1.13 1.14 1.15 1.16 1.17 1.18 1.19 1.20 1.21 1.22 1.23 1.24 1.25 1.26 1.27 1.28 1.29 1.30 1.31 1.32 1.33 1.34 1.35 1.36 1.37 1.38 1.39 1.40 1.41 1.42 1.43 1.44 1.45 1.46 1.47 1.48 1.49 1.50 1.51 1.52 1.53 1.54 1.55 1.56 1.57 1.58 1.59 1.60 1.61 1.62 1.63 1.64 1.65 1.66 1.67 1.68 1.69 1.70 1.71 1.72 1.73 1.74 1.75 1.76 1.77 1.78 1.79 1.80 1.81 1.82 ${refDir}/top30listsorted.noheader.txt ${outputDir}/Large_Deletions_NC_012920.1_357-15925.sorted.noheader.txt > ${outputDir}/joined2.txt
sed $"1iSample_ID Reference_Genome MapSplice_Breakpoint 5'_Break 3'_Break Deletion_Size_bp Deletion_Reads Benchmark_Coverage Deletion_Read_% Annotation Left_Overhang Right_Overhang IMPACT_MT-HV2 IMPACT_MT-OHR57 IMPACT_MT-OHR IMPACT_MT-CSB1 IMPACT_MT-TFX IMPACT_MT-TFY IMPACT_MT-CSB2 IMPACT_MT-HPR IMPACT_MT-CSB3 IMPACT_MT-4H IMPACT_MT-3H IMPACT_MT-LSP IMPACT_MT-TFL IMPACT_MT-HV3 IMPACT_MT-TFH IMPACT_MT-HSP1 IMPACT_MT-TF IMPACT_MT-HSP2 IMPACT_MT-RNR1 IMPACT_MT-TV IMPACT_MT-RNR2 IMPACT_MT-Hum IMPACT_MT-RNR3 IMPACT_MT-TER IMPACT_MT-TL1 IMPACT_MT-NC1 IMPACT_MT-ND1 IMPACT_MT-TI IMPACT_MT-TQ IMPACT_MT-NC2 IMPACT_MT-TM IMPACT_MT-ND2 IMPACT_MT-TW IMPACT_MT-NC3 IMPACT_MT-TA IMPACT_MT-NC4 IMPACT_MT-TN IMPACT_MT-OLR IMPACT_MT-TC IMPACT_MT-TY IMPACT_MT-NC5 IMPACT_MT-CO1 IMPACT_MT-TS1 IMPACT_MT-NC6 IMPACT_MT-TD IMPACT_MT-CO2 IMPACT_MT-NC7 IMPACT_MT-TK IMPACT_MT-NC8 IMPACT_MT-ATP8 IMPACT_MT-ATP6 IMPACT_MT-CO3 IMPACT_MT-TG IMPACT_MT-ND3 IMPACT_MT-TR IMPACT_MT-ND4L IMPACT_MT-ND4 IMPACT_MT-TH IMPACT_MT-TS2 IMPACT_MT-TL2 IMPACT_MT-ND5 IMPACT_MT-ND6 IMPACT_MT-TE IMPACT_MT-NC9 IMPACT_MT-CYB IMPACT_MT-TT IMPACT_MT-ATT IMPACT_MT-NC10 IMPACT_MT-TP IMPACT_MT-CR IMPACT_MT-HV1 IMPACT_MT-TAS2 IMPACT_MT-7SDNA IMPACT_MT-TAS IMPACT_MT-5 IMPACT_MT-3L" ${outputDir}/joined2.txt | column -t > ${outputDir}/joined3.txt
awk -v newvar="$sampleName" 'NR>=2 {$1=newvar}1' ${outputDir}/joined3.txt > ${outputDir}/joined4.txt
awk -v newbc="$avg_benchmark" 'NR>=2 {$8=newbc}1' ${outputDir}/joined4.txt > ${outputDir}/LargeMTDeletions_DNAorRNA_Top30_NARpub.txt

#Delete Intermediary Files
head -2 ${outputDir}/avgBenchmark.txt > ${outputDir}/Benchmark.txt
rm ${outputDir}/{init_coverage.txt,large_deletions.txt,large_deletion.txt,breakpoints.txt,avgBenchmark.txt,modifiedJunc.txt,intermediate.txt,intermediate_junctions.txt,intermediate_junctions2.txt,combined.txt,pileup.txt,BaseCounts.pileup.txt,insertions.txt,deletions.txt,coverage.txt,coverage2.txt,alignments.unsorted,joined2.txt,joined3.txt,joined4.txt,Large_Deletions_NC_012920.1_357-15925.sorted.noheader.txt}
rm -rf ${outputDir}/bowtie_index

#Final error check
if [[ ${filterFails} -eq 0 ]]; then
    echo "Junction Filter Steps Success">> ${nohupOutput}/${sampleName}_nohup.log
else
    echo "#ERROR: ${filterFails} steps failed. Please check your input files.">> ${nohupOutput}/${sampleName}_nohup.log
fi

time=`date +%d-%m-%Y-%H-%M-%S`
echo "Ending $0 at ${time}">> ${nohupOutput}/${sampleName}_nohup.log



