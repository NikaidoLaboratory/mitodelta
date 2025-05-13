#!/bin/bash
#Michelle Webb
#University of Southern California
#v1.3.0-stable
#December 15, 2020

#Remove PCR Replicates and Adapter sequences from FASTQ's, followed by Mapsplice2 alignment and the Splice-Break v1.0.0 pipeline

#Arguments:
inputDir=$1
outputDir=$2
logDir=$3
align=$4
### indicate --align=yes or --align=no
ref=$5
### indicate --ref=Nsub or --ref=rCRS
fastq_keep=$6
### indicate --fastq_keep=Yes defalut will deleteing the fq, unless user choose keep
skip_preAlign=$7
### indicate --skip_prealign=yes Yes y Y


#Tool Locations
bbmap="/scratch/lilixu/splicebreak/bbmap/v38.75"
mapsplice="/scratch/lilixu/splicebreak/MapSplice/v2.2.1"
samtools="/scratch/lilixu/splicebreak/samtools/v1.8/bin/samtools"
SB="/scratch/lilixu/splicebreak/v1.3.0-stable/Splice-Break.sh"
# put own direct wrapper with sp
rCRS_ref="/scratch/lilixu/splicebreak/NC_012820.1"
Nsub_ref="/scratch/lilixu/splicebreak/ref_Nsub"
refGenome=${rCRS_ref}}
SB_ref="/scratch/lilixu/splicebreak/v1.3.0-stable/reference"
sampleName=empty


#START
time=`date +%d-%m-%Y-%H-%M-%S`
hostname=`hostname`
echo "Starting $0 at ${time} on ${hostname}"
echo "Splice-Break v1.3.0-stable"
#gunzip files prior to starting
count=`ls -1 ${inputDir}/*.gz 2>/dev/null | wc -l`
if [ $count != 0 ]
then
    echo true
    for i in `ls ${inputDir}/*.gz` ; do
    echo "{$i}"
    gunzip $i
    done
fi


if [ ${ref} == "--ref=Nsub" ];then
    refGenome=${Nsub_ref}
    echo "${refGenome}"
fi
###skip the pre-alignment step; if statement 
#cp statement
#output/dedpued.....

if [ ${skip_preAlign} == '--skip_preAlign=yes' ]||[ ${skip_preAlign} == '--skip_preAlign=y' ]||[ ${skip_preAlign} == '--skip_preAlign=Yes' ]||[ ${skip_preAlign} == '--skip_preAlign=Y' ];then
    for i in `ls ${inputDir}/*.{R1.fastq,r1.fastq,READ1.fastq,read1.fastq,R1.fq,R2.fq,r1.fq,r2.fq,READ1.fq,READ2.fq,read1.fq,read2.fq,R1.txt,R2.txt,r1.txt,r2.txt,READ1.txt,READ2.txt,read1.txt,read2.txt}` ; do
    # get the ext:fastq,fq,txt; and then get the second ext:read1,R1,READ1,r1
    ext="${i##*.}"
    pre="${i%.*}"
    ext2="${pre##*.}"
   # get the filename as j
    j="${pre##*/}"
    j="${j%.${ext2}}"
    sample="${j}"
    sampleName="${j}"
    
    cp ${i} ${outputDir}/${j}-READ1.deduped.fq
    cp ${i} ${outputDir}/${j}-READ1.deduped.deAdapt.fq
    cp ${i} ${outputDir}/${j}-READ2.deduped.fq
    cp ${i} ${outputDir}/${j}-READ2.deduped.deAdapt.fq
    
fi



if [ ${align} == "--align=no" ] ; then

    for i in `ls ${inputDir}/*.{R1.fastq,r1.fastq,READ1.fastq,read1.fastq,R1.fq,R2.fq,r1.fq,r2.fq,READ1.fq,READ2.fq,read1.fq,read2.fq,R1.txt,R2.txt,r1.txt,r2.txt,READ1.txt,READ2.txt,read1.txt,read2.txt}` ; do
    start_time="$(date -u +%s)"
   
    # get the ext:fastq,fq,txt; and then get the second ext:read1,R1,READ1,r1
    ext="${i##*.}"
    pre="${i%.*}"
    ext2="${pre##*.}"
   # get the filename as j
    j="${pre##*/}"
    j="${j%.${ext2}}"
    sample="${j}"
    sampleName="${j}"
    echo "### Running Pre-Alignment Pipeline">> ${finalOutput}/${sampleName}_nohup.log
    ts=`date +%d%m%Y%S`
    finalOutput=${outputDir}/${j}_mapsplice-${ts}
    echo "### Sample: ${sample}" >> ${finalOutput}/${sampleName}_nohup.log
    if [ -f ${outputDir}/${j}-READ1.deduped.deAdapt.fq ] && [ -f ${outputDir}/${j}-READ2.deduped.deAdapt.fq ] ; then
    	echo "### PCR Replicates and Adapter Sequences previously removed. Running alignment and Splice-Break" >> ${finalOutput}/${sampleName}_nohup.log
        READ_FILE_END1=${outputDir}/${j}-READ1.deduped.deAdapt.fq
        READ_FILE_END2=${outputDir}/${j}-READ2.deduped.deAdapt.fq
        echo "Editing output" >> ${finalOutput}/${sampleName}_nohup.log
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END1} 
        sed -i 's/\/2_dd0 \/2/\/2/g' ${READ_FILE_END2}
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd1 \/2/\/2/g' ${READ_FILE_END2}
    elif [[ -f ${outputDir}/${j}-READ1.deduped.fq ]] && [[ -f ${outputDir}/${j}-READ2.deduped.fq ]] ; then
    	echo "### PCR Replicates previously removed. Running BBMAP BBDUK and REFORMAT" >> ${finalOutput}/${sampleName}_nohup.log
        R1_dedupe=`wc -l < ${outputDir}/${j}-READ1.deduped.fq`
        R2_dedupe=`wc -l < ${outputDir}/${j}-READ2.deduped.fq`
        echo "DEDUPE READ1 Line Count: ${R1_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE READ2 Line Count: ${R2_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        ${bbmap}/bbduk.sh in1=${outputDir}/${j}-READ1.deduped.fq in2=${outputDir}/${j}-READ2.deduped.fq out=${outputDir}/${j}_interleaved2.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log
        ${bbmap}/reformat.sh in=${outputDir}/${j}_interleaved2.fq out1=${outputDir}/${j}-READ1.deduped.deAdapt.fq out2=${outputDir}/${j}-READ2.deduped.deAdapt.fq &>> ${logDir}/${j}.log
        R1_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ1.deduped.deAdapt.fq`
        R2_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ2.deduped.deAdapt.fq`
        echo "DEDUPE + DEADAPT READ1 Line Count: ${R1_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE + DEADAPT READ2 Line Count: ${R2_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        Deduped1=`echo "${R1} - ${R1_dedupe}" | bc`
        Deduped2=`echo "${R2} - ${R2_dedupe}" | bc`
        echo "${Deduped1} R1 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        echo "${Deduped2} R2 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        rm ${outputDir}/${j}_interleaved*
        echo "-------------------------------------" >> ${finalOutput}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        READ_FILE_END1=${outputDir}/${j}-READ1.deduped.deAdapt.fq
        READ_FILE_END2=${outputDir}/${j}-READ2.deduped.deAdapt.fq
        echo "Editing output" >> ${finalOutput}/${sampleName}_nohup.log
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd0 \/2/\/2/g' ${READ_FILE_END2}
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd1 \/2/\/2/g' ${READ_FILE_END2}
    else
        echo "### PSB Pipeline: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        R1=`wc -l < ${inputDir}/${j}-READ1-Sequences.txt`
        R2=`wc -l < ${inputDir}/${j}-READ2-Sequences.txt`
        echo "READ1 Line Count: ${R1}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "READ2 Line Count: ${R2}" >> ${finalOutput}/${sampleName}_nohup.log
        ${bbmap}/dedupe.sh in1=${inputDir}/${j}-READ1-Sequences.txt in2=${inputDir}/${j}-READ2-Sequences.txt out=${outputDir}/${j}_interleaved1.fq ac=f &> ${logDir}/${j}.log
        ${bbmap}/reformat.sh in=${outputDir}/${j}_interleaved1.fq out1=${outputDir}/${j}-READ1.deduped.fq out2=${outputDir}/${j}-READ2.deduped.fq &>> ${logDir}/${j}.log
        R1_dedupe=`wc -l < ${outputDir}/${j}-READ1.deduped.fq`
        R2_dedupe=`wc -l < ${outputDir}/${j}-READ2.deduped.fq`
        echo "DEDUPE READ1 Line Count: ${R1_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE READ2 Line Count: ${R2_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        ${bbmap}/bbduk.sh in1=${outputDir}/${j}-READ1.deduped.fq in2=${outputDir}/${j}-READ2.deduped.fq out=${outputDir}/${j}_interleaved2.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log
        ${bbmap}/reformat.sh in=${outputDir}/${j}_interleaved2.fq out1=${outputDir}/${j}-READ1.deduped.deAdapt.fq out2=${outputDir}/${j}-READ2.deduped.deAdapt.fq &>> ${logDir}/${j}.log
        R1_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ1.deduped.deAdapt.fq`
        R2_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ2.deduped.deAdapt.fq`
        echo "DEDUPE + DEADAPT READ1 Line Count: ${R1_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE + DEADAPT READ2 Line Count: ${R2_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        Deduped1=`echo "${R1} - ${R1_dedupe}" | bc`
        Deduped2=`echo "${R2} - ${R2_dedupe}" | bc`
        echo "${Deduped1} R1 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        echo "${Deduped2} R2 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        rm ${outputDir}/${j}_interleaved*
        echo "-------------------------------------" >> ${finalOutput}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        mkdir -v ${finalOutput} >> ${finalOutput}/${sampleName}_nohup.log
        READ_FILE_END1=${outputDir}/${j}-READ1.deduped.deAdapt.fq
        READ_FILE_END2=${outputDir}/${j}-READ2.deduped.deAdapt.fq
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd0 \/2/\/2/g' ${READ_FILE_END2}
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd1 \/2/\/2/g' ${READ_FILE_END2}
    fi
    end_time="$(date -u +%s)"
    elapsed="$(bc <<<"$end_time-$start_time")"
    elapsedMin=`echo "${elapsed} / 60" | bc`
    echo "### ${j} RUNTIME: ${elapsedMin}m" >> ${finalOutput}/${sampleName}_nohup.log
    done
elif [ ${align} == "--align=yes" ] ; then
    
    for i in `ls ${inputDir}/*.{R1.fastq,r1.fastq,READ1.fastq,read1.fastq,R1.fq,R2.fq,r1.fq,r2.fq,READ1.fq,READ2.fq,read1.fq,read2.fq,R1.txt,R2.txt,r1.txt,r2.txt,READ1.txt,READ2.txt,read1.txt,read2.txt}` ; do
    start_time="$(date -u +%s)"
        # get the ext:fastq,fq,txt; and then get the second ext:read1,R1,READ1,r1
    ext="${i##*.}"
    pre="${i%.*}"
    ext2="${pre##*.}"
   # get the filename as j
    j="${pre##*/}"
    j="${j%.${ext2}}"
    sample="${j}"
    sampleName="${j}"
    echo "### Running Full Splice-Break Pipeline" >> ${finalOutput}/${sampleName}_nohup.log
    ts=`date +%d%m%Y%S`
    finalOutput=${outputDir}/${j}_mapsplice-${ts}
    echo "### Sample: ${sample}" >> ${finalOutput}/${sampleName}_nohup.log
    if [ -d ${outputDir}/${j}_mapsplice* ] && [ -f ${outputDir}/${j}_mapsplice*/Large_Deletions_NC_012920.1_No-Position-Filter.txt ] ; then
    	echo "### Sample previously completed Splice-Break" >> ${finalOutput}/${sampleName}_nohup.log
        exit
    elif [ -d ${outputDir}/${j}_mapsplice* ] && [ -f ${outputDir}/${j}_mapsplice*/alignments.bam ] ; then
    	echo "### Sample completed alignment. Running Splice-Break" >> ${finalOutput}/${sampleName}_nohup.log
    	${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_106-16176.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_106-16176.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_356-15926.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_356-15926.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_No-Position-Filter.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.unsorted ${finalOutput}/${j}_alignments.unsorted >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam >> ${finalOutput}/${sampleName}_nohup.log
    elif [ -f ${outputDir}/${j}-READ1.deduped.deAdapt.fq ] && [ -f ${outputDir}/${j}-READ2.deduped.deAdapt.fq ] ; then
    	echo "### PCR Replicates and Adapter Sequences previously removed. Running alignment and Splice-Break" >> ${finalOutput}/${sampleName}_nohup.log
    	mkdir -v ${finalOutput} >> ${finalOutput}/${sampleName}_nohup.log
        READ_FILE_END1=${outputDir}/${j}-READ1.deduped.deAdapt.fq
        READ_FILE_END2=${outputDir}/${j}-READ2.deduped.deAdapt.fq
        echo "Editing out" >> ${finalOutput}/${sampleName}_nohup.log
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd0 \/2/\/2/g' ${READ_FILE_END2}
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd1 \/2/\/2/g' ${READ_FILE_END2}
        echo "/usr/bin/python ${mapsplice}/mapsplice.py -1 $READ_FILE_END1 -2 $READ_FILE_END2 -c ${refGenome} --non-canonical-double-anchor --bam --qual-scale phred33 -p 8 -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log" >> ${finalOutput}/${sampleName}_nohup.log
        /usr/bin/python ${mapsplice}/mapsplice.py \
           -1 $READ_FILE_END1 \
           -2 $READ_FILE_END2 \
           -c ${refGenome} \
           --non-canonical-double-anchor \
           --bam \
           --qual-scale phred33 \
           -p 8 \
           -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log
        if [ $? -gt 0 ]; then
           echo "#ERROR: Mapsplice Fail. Check logs" >> ${finalOutput}/${sampleName}_nohup.log
           exit
        fi
        echo "### Sorting output" >> ${finalOutput}/${sampleName}_nohup.log
        ${samtools} sort ${finalOutput}/alignments.bam -o ${finalOutput}/alignments.sorted.bam
        if [ $? -gt 0 ]; then
            echo "#ERROR: Samtools sort fail. Check logs" >> ${finalOutput}/${sampleName}_nohup.log
            exit
        fi
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/alignments.unsorted >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.sorted.bam ${finalOutput}/alignments.bam >> ${finalOutput}/${sampleName}_nohup.log
        echo "--------------------------------------" >> ${finalOutput}/${sampleName}_nohup.log
        echo "### Splice-Break: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        ${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_106-16176.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_106-16176.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_356-15926.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_356-15926.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_No-Position-Filter.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.unsorted ${finalOutput}/${j}_alignments.unsorted >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam >> ${finalOutput}/${sampleName}_nohup.log
    elif [[ -f ${outputDir}/${j}-READ1.deduped.fq ]] && [[ -f ${outputDir}/${j}-READ2.deduped.fq ]] ; then
    	echo "### PCR Replicates previously removed. Running BBMAP BBDUK and REFORMAT" >> ${finalOutput}/${sampleName}_nohup.log
        R1_dedupe=`wc -l < ${outputDir}/${j}-READ1.deduped.fq`
        R2_dedupe=`wc -l < ${outputDir}/${j}-READ2.deduped.fq`
        echo "DEDUPE READ1 Line Count: ${R1_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE READ2 Line Count: ${R2_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        ${bbmap}/bbduk.sh in1=${outputDir}/${j}-READ1.deduped.fq in2=${outputDir}/${j}-READ2.deduped.fq out=${outputDir}/${j}_interleaved2.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log
        ${bbmap}/reformat.sh in=${outputDir}/${j}_interleaved2.fq out1=${outputDir}/${j}-READ1.deduped.deAdapt.fq out2=${outputDir}/${j}-READ2.deduped.deAdapt.fq &>> ${logDir}/${j}.log 
        R1_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ1.deduped.deAdapt.fq`
        R2_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ2.deduped.deAdapt.fq`
        echo "DEDUPE + DEADAPT READ1 Line Count: ${R1_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE + DEADAPT READ2 Line Count: ${R2_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        Deduped1=`echo "${R1} - ${R1_dedupe}" | bc`
        Deduped2=`echo "${R2} - ${R2_dedupe}" | bc`
        echo "${Deduped1} R1 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        echo "${Deduped2} R2 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        rm ${outputDir}/${j}_interleaved* 
        echo "-------------------------------------">> ${finalOutput}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        mkdir -v ${finalOutput} >> ${finalOutput}/${sampleName}_nohup.log
        READ_FILE_END1=${outputDir}/${j}-READ1.deduped.deAdapt.fq
        READ_FILE_END2=${outputDir}/${j}-READ2.deduped.deAdapt.fq
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd0 \/2/\/2/g' ${READ_FILE_END2}
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd1 \/2/\/2/g' ${READ_FILE_END2}
    	echo "/usr/bin/python ${mapsplice}/mapsplice.py -1 $READ_FILE_END1 -2 $READ_FILE_END2 -c ${refGenome} --non-canonical-double-anchor --bam --qual-scale phred33 -p 8 -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log" >> ${finalOutput}/${sampleName}_nohup.log
        /usr/bin/python ${mapsplice}/mapsplice.py \
           -1 $READ_FILE_END1 \
           -2 $READ_FILE_END2 \
           -c ${refGenome} \
           --non-canonical-double-anchor \
           --bam \
           --qual-scale phred33 \
           -p 8 \
           -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log
        if [ $? -gt 0 ]; then
          echo "#ERROR: Mapsplice Fail. Check logs" >> ${finalOutput}/${sampleName}_nohup.log
          exit
        fi
        echo "### Sorting output" >> ${finalOutput}/${sampleName}_nohup.log
        ${samtools} sort ${finalOutput}/alignments.bam -o ${finalOutput}/alignments.sorted.bam >> ${finalOutput}/${sampleName}_nohup.log
        if [ $? -gt 0 ]; then
          echo "#ERROR: Samtools sort fail. Check logs" >> ${finalOutput}/${sampleName}_nohup.log
          exit
        fi
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/alignments.unsorted >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.sorted.bam ${finalOutput}/alignments.bam >> ${finalOutput}/${sampleName}_nohup.log
        echo "--------------------------------------" >> ${finalOutput}/${sampleName}_nohup.log
        echo "### Splice-Break: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        ${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_106-16176.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_106-16176.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_356-15926.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_356-15926.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_No-Position-Filter.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.unsorted ${finalOutput}/${j}_alignments.unsorted >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam >> ${finalOutput}/${sampleName}_nohup.log
    else
        echo "### PSB Pipeline: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        # replace read1 to read2
        replace=2
        newext="${ext2//1/$replace}"
        R1=`wc -l < ${inputDir}/${j}.${ext2}.${ext}`
        R2=`wc -l < ${inputDir}/${j}.${newext}.${ext}`
        echo "READ1 Line Count: ${R1}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "READ2 Line Count: ${R2}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "${bbmap}/dedupe.sh in1=${inputDir}/${j}.${ext2}.${ext} in2=${inputDir}/${j}.${newext}.${ext} out=${outputDir}/${j}_interleaved1.fq ac=f &> ${logDir}/${j}.log" >> ${finalOutput}/${sampleName}_nohup.log
        ${bbmap}/dedupe.sh in1=${inputDir}/${j}.${ext2}.${ext} in2=${inputDir}/${j}.${newext}.${ext} out=${outputDir}/${j}_interleaved1.fq ac=f &> ${logDir}/${j}.log
        ${bbmap}/reformat.sh in=${outputDir}/${j}_interleaved1.fq out1=${outputDir}/${j}-READ1.deduped.fq out2=${outputDir}/${j}-READ2.deduped.fq &>> ${logDir}/${j}.log
        R1_dedupe=`wc -l < ${outputDir}/${j}-READ1.deduped.fq`
        R2_dedupe=`wc -l < ${outputDir}/${j}-READ2.deduped.fq`
        echo "DEDUPE READ1 Line Count: ${R1_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE READ2 Line Count: ${R2_dedupe}" >> ${finalOutput}/${sampleName}_nohup.log
        ${bbmap}/bbduk.sh in1=${outputDir}/${j}-READ1.deduped.fq in2=${outputDir}/${j}-READ2.deduped.fq out=${outputDir}/${j}_interleaved2.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log
        ${bbmap}/reformat.sh in=${outputDir}/${j}_interleaved2.fq out1=${outputDir}/${j}-READ1.deduped.deAdapt.fq out2=${outputDir}/${j}-READ2.deduped.deAdapt.fq &>> ${logDir}/${j}.log
        R1_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ1.deduped.deAdapt.fq`
        R2_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ2.deduped.deAdapt.fq`
        echo "DEDUPE + DEADAPT READ1 Line Count: ${R1_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        echo "DEDUPE + DEADAPT READ2 Line Count: ${R2_dedupe_deAdapt}" >> ${finalOutput}/${sampleName}_nohup.log
        Deduped1=`echo "${R1} - ${R1_dedupe}" | bc`
        Deduped2=`echo "${R2} - ${R2_dedupe}" | bc`
        echo "${Deduped1} R1 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        echo "${Deduped2} R2 PCR replicates removed" >> ${finalOutput}/${sampleName}_nohup.log
        rm ${outputDir}/${j}_interleaved*
        echo "-------------------------------------" >> ${finalOutput}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        mkdir -v ${finalOutput} >> ${finalOutput}/${sampleName}_nohup.log
        READ_FILE_END1=${outputDir}/${j}-READ1.deduped.deAdapt.fq
        READ_FILE_END2=${outputDir}/${j}-READ2.deduped.deAdapt.fq
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd0 \/2/\/2/g' ${READ_FILE_END2}
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END1}
        sed -i 's/\/2_dd1 \/2/\/2/g' ${READ_FILE_END2}
    	echo "/usr/bin/python ${mapsplice}/mapsplice.py -1 $READ_FILE_END1 -2 $READ_FILE_END2 -c ${refGenome} --non-canonical-double-anchor --bam --qual-scale phred33 -p 8 -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log" >> ${finalOutput}/${sampleName}_nohup.log
        /usr/bin/python ${mapsplice}/mapsplice.py \
           -1 $READ_FILE_END1 \
           -2 $READ_FILE_END2 \
           -c ${refGenome} \
           --non-canonical-double-anchor \
           --bam \
           --qual-scale phred33 \
           -p 8 \
           -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log
        if [ $? -gt 0 ]; then
          echo "#ERROR: Mapsplice Fail. Check logs" >> ${finalOutput}/${sampleName}_nohup.log
          exit
        fi
        echo "### Sorting output" >> ${finalOutput}/${sampleName}_nohup.log
        ${samtools} sort ${finalOutput}/alignments.bam -o ${finalOutput}/alignments.sorted.bam
        if [ $? -gt 0 ]; then
          echo "#ERROR: Samtools sort fail. Check logs" >> ${finalOutput}/${sampleName}_nohup.log
          exit
        fi
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/alignments.unsorted >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.sorted.bam ${finalOutput}/alignments.bam >> ${finalOutput}/${sampleName}_nohup.log
        echo "--------------------------------------" >> ${finalOutput}/${sampleName}_nohup.log
        echo "### Splice-Break: ${j}" >> ${finalOutput}/${sampleName}_nohup.log
        ${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_106-16176.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_106-16176.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_356-15926.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_356-15926.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_Large_Deletions_NC_012920.1_No-Position-Filter.txt >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.unsorted ${finalOutput}/${j}_alignments.unsorted >> ${finalOutput}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam >> ${finalOutput}/${sampleName}_nohup.log
    fi
    end_time="$(date -u +%s)"
    elapsed="$(bc <<<"$end_time-$start_time")"
    elapsedMin=`echo "${elapsed} / 60" | bc`
    echo "### ${j} RUNTIME: ${elapsedMin}m" >> ${finalOutput}/${sampleName}_nohup.log
    
    
    if [ ${fastq_keep} != "--fastq_keep=Yes" ] ||[ ${fastq_keep} != "--fastq_keep=Y" ] || [ ${fastq_keep} != "--fastq_keep=yes" ]||[ ${fastq_keep} != "--fastq_keep=y" ];then
    ### if fastqKeep not equal to Yes, then delete all deduped fq.
        rm ${outputDir}/${sampleName}-READ1.deduped.deAdapt.fq
        rm ${outputDir}/${sampleName}-READ2.deduped.deAdapt.fq
        rm ${outputDir}/${sampleName}-READ1.deduped.fq
        rm ${outputDir}/${sampleName}-READ2.deduped.fq
    fi

    ####combine all logs into one file
    cat "     " >> ${outputDir}/${sampleName}.log
    cat "End of bbmap.log" >> ${outputDir}/${sampleName}.log
    cat "-----------------------------------------------------------" >> ${outputDir}/${sampleName}.log
    cat ${finalOutput}/${j}_mapsplice.log >> ${outputDir}/${sampleName}.log
    cat "     " >> ${outputDir}/${sampleName}.log
    cat "End of mapsplice.log" >> ${outputDir}/${sampleName}.log
    cat "-----------------------------------------------------------" >> ${outputDir}/${sampleName}.log
    cat ${finalOutput}/${sampleName}_nohup.log >> ${outputDir}/${sampleName}.log
    cat "     " >> ${outputDir}/${sampleName}.log
    cat "End of nohup.log" >> ${outputDir}/${sampleName}.log
    cat "-----------------------------------------------------------" >> ${outputDir}/${sampleName}.log

    ###delete other logs
    rm ${finalOutput}/${j}_mapsplice.log
    rm ${finalOutput}/${sampleName}_nohup.log

    done
else
	echo "Please indicate whether to run alignment and try again" >> ${finalOutput}/${sampleName}_nohup.log
fi

