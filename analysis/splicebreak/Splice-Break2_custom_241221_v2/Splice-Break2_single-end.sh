#!/bin/bash
#LiLi Xu and Michelle Webb
#University of Southern California
#v3.0.0-stable
#April 1, 2022

#Remove PCR Replicates and Adapter sequences from FASTQ's, followed by Mapsplice2 alignment and the Splice-Break2 v3.0.0 pipeline

#Arguments:
inputDir=$1
outputDir=$2
logDir=$3
SB_Path=$4
### indicate --SB-PATH= full path of SB directory
align=$5
### indicate --align=yes or --align=no
ref=$6
### indicate --ref=Nsub or --ref=rCRS
fastq_keep=$7
### indicate --fastq_keep=Yes defalut will deleteing the fq, unless user choose keep
skip_preAlign=$8
### indicate --skip_prealign=yes Yes y Y

#Tool Locations
bbmap="${SB_Path}/bbmap/v38.75"
mapsplice="${SB_Path}/MapSplice/v2.2.1"
samtools="samtools"
SB="${SB_Path}/Splice-Break_v3.0.1/Splice-Break2_0423.sh"
# put own direct wrapper with sp
rCRS_ref="${SB_Path}/NC_012920.1"
Nsub_ref="${SB_Path}/ref_Nsub"
mouse_ref="${SB_Path}/ref_mouse"
refGenome=${rCRS_ref}
SB_ref="${SB_Path}/Splice-Break_v3.0.1/reference"
sampleName=empty
#with default which will using rCRS:NC_012920.1
reference_name=NC_012920.1_rCRS


#START
time=`date +%d-%m-%Y-%H-%M-%S`
hostname=`hostname`
echo "Starting $0 at ${time} on ${hostname}" > ${SB_Path}/temp.log
echo "Splice-Break2 v3.0.0 Single-End" >> ${SB_Path}/temp.log
#gunzip files prior to starting
count=`ls -1 ${inputDir}/*.gz 2>/dev/null | wc -l`
if [ $count != 0 ]
then
    echo true
    for i in `ls ${inputDir}/*.gz` ; do
    echo "gunzip {$i}" >> ${SB_Path}/temp.log
    gunzip $i
    done
fi

# create directory for output or log
if [  -d ${outputDir} ];then
    echo "outputDir: ${outputDir}" >> ${SB_Path}/temp.log
else
    mkdir -v ${outputDir} >> ${SB_Path}/temp.log
    echo "outputDir Created: ${outputDir}" >> ${SB_Path}/temp.log
fi

if [  -d ${logDir} ];then
    echo "logDir: ${logDir}" >> ${SB_Path}/temp.log
else
    mkdir -v ${logDir} >> ${SB_Path}/temp.log
    echo "logDir Created: ${logDir}" >> ${SB_Path}/temp.log
fi

cat ${SB_Path}/temp.log > ${logDir}/temp.log
rm ${SB_Path}/temp.log

#default the option
if [ ${align}=null ];then
    align="--align=yes"
    echo "Default Align: ${align}" >> ${logDir}/temp.log
else
    echo "Alignment: ${align}" >> ${logDir}/temp.log
fi

#select the reference source
if [ ${ref} == "--ref=Nsub" ];then
    refGenome=${Nsub_ref}
    reference_name=NC_012920.1_NSub
    echo "refGenome: ${refGenome}" >> ${logDir}/temp.log
    echo "reference Name: ${reference_name}" >> ${logDir}/temp.log
elif [ ${ref} == "--ref=mouse" ];then
    refGenome=${mouse_ref}
    reference_name=NC_005089.1
    echo "refGenome: ${refGenome}" >> ${logDir}/temp.log
    echo "reference Name: ${reference_name}" >> ${logDir}/temp.log
fi


###skip the pre-alignment step; if statement
#cp statement
#output/dedpued.....

if [ ${skip_preAlign} == '--skip_preAlign=yes' ]||[ ${skip_preAlign} == '--skip_preAlign=y' ]||[ ${skip_preAlign} == '--skip_preAlign=Yes' ]||[ ${skip_preAlign} == '--skip_preAlign=Y' ]||[ ${skip_preAlign} == '--skip_preAlign=YES' ];then
    for i in `ls ${inputDir}/*{fastq,fq,txt}` ; do
    # get the ext:fastq,fq,txt; and then get the second ext:read1,R1,READ1,r1
    ext="${i##*.}"
    pre="${i%.*}"
   # get the filename as j
    j="${pre##*/}"
    sample="${j}"
    sampleName="${j}"
    
    echo "Skip Pre-Alignment">> ${outputDir}/${sampleName}_nohup.log

    cp ${i} ${outputDir}/${j}-READ.deduped.deAdapt.fq
    done
fi

if [ ${align} == "--align=no" ]||[ ${align} == '--align=n' ]||[ ${align} == '--align=No' ]||[ ${align} == '--align=N' ]||[ ${align} == '--align=NO' ]; then
    
    for i in `ls ${inputDir}/*{fastq,fq,txt}` ; do
    start_time="$(date -u +%s)"
    # get the ext:fastq,fq,txt;
    ext="${i##*.}"
    pre="${i%.*}"
    # get the filename as j
    j="${pre##*/}"
    sample="${j}"
    sampleName="${j}"
    echo "### Running Pre-Alignment Pipeline">> ${outputDir}/${sampleName}_nohup.log
    
    ts=`date +%d%m%Y%S`
    finalOutput=${outputDir}/${j}_mapsplice-${ts}
    echo "### Sample: ${sample}">> ${outputDir}/${sampleName}_nohup.log
    if [ -f ${outputDir}/${j}-READ.deduped.deAdapt.fq ]; then
        echo "### PCR Replicates and Adapter Sequences previously removed. Running alignment and Splice-Break">> ${outputDir}/${sampleName}_nohup.log
        READ_FILE_END=${outputDir}/${j}-READ.deduped.deAdapt.fq
        
        echo "Editing output">> ${outputDir}/${sampleName}_nohup.log
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END}
        
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END}
        
    elif [[ -f ${outputDir}/${j}-READ.deduped.fq ]]; then
        echo "### PCR Replicates previously removed. Running BBMAP BBDUK and REFORMAT">> ${outputDir}/${sampleName}_nohup.log
        R_dedupe=`wc -l < ${outputDir}/${j}-READ.deduped.fq`
        
        echo "DEDUPE READ Line Count: ${R_dedupe}">> ${outputDir}/${sampleName}_nohup.log
        
        ${bbmap}/bbduk.sh in=${outputDir}/${j}-READ.deduped.fq  out=${outputDir}/${j}-READ.deduped.deAdapt.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log
        
        R_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ.deduped.deAdapt.fq`
        echo "DEDUPE + DEADAPT READ Line Count: ${R_dedupe_deAdapt}">> ${outputDir}/${sampleName}_nohup.log
        
        Deduped=`echo "${R} - ${R_dedupe}" | bc`
        
        echo "${Deduped} R PCR replicates removed">> ${outputDir}/${sampleName}_nohup.log
        
        
        echo "-------------------------------------">> ${outputDir}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}">> ${outputDir}/${sampleName}_nohup.log
        READ_FILE_END=${outputDir}/${j}-READ.deduped.deAdapt.fq
        
        echo "Editing output">> ${outputDir}/${sampleName}_nohup.log
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END}
        
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END}
        
    else
        echo "### PSB Pipeline: ${j}">> ${outputDir}/${sampleName}_nohup.log
        R=`wc -l < ${inputDir}/${j}.${ext}`
        
        echo "READ Line Count: ${R}">> ${outputDir}/${sampleName}_nohup.log
        
        ${bbmap}/dedupe.sh in=${inputDir}/${j}.${ext}  out=${outputDir}/${j}-READ.deduped.fq ac=f &> ${logDir}/${j}.log
        
        R_dedupe=`wc -l < ${outputDir}/${j}-READ.deduped.fq`
        
        echo "DEDUPE READ Line Count: ${R_dedupe}">> ${outputDir}/${sampleName}_nohup.log
        
        ${bbmap}/bbduk.sh in=${outputDir}/${j}-READ.deduped.fq  out=${outputDir}/${j}-READ.deduped.deAdapt.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log
        
        R_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ.deduped.deAdapt.fq`
        
        echo "DEDUPE + DEADAPT READ Line Count: ${R_dedupe_deAdapt}">> ${outputDir}/${sampleName}_nohup.log
        
        Deduped=`echo "${R} - ${R_dedupe}" | bc`
        
        echo "${Deduped} R PCR replicates removed">> ${outputDir}/${sampleName}_nohup.log
        
        
        echo "-------------------------------------">> ${outputDir}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}">> ${outputDir}/${sampleName}_nohup.log
        mkdir -v ${finalOutput}>> ${outputDir}/${sampleName}_nohup.log
        READ_FILE_END=${outputDir}/${j}-READ.deduped.deAdapt.fq
        
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END}
        
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END}
        
    fi
    end_time="$(date -u +%s)"
    elapsed="$(bc <<<"$end_time-$start_time")"
    elapsedMin=`echo "${elapsed} / 60" | bc`
    echo "### ${j} RUNTIME: ${elapsedMin}m">> ${outputDir}/${sampleName}_nohup.log
    
    if [ ${fastq_keep} == "--fastq_keep=Yes" ]||[ ${fastq_keep} == "--fastq_keep=Y" ]|| [ ${fastq_keep} == "--fastq_keep=yes" ]||[ ${fastq_keep} == "--fastq_keep=y" ]||[ ${fastq_keep} == "--fastq_keep=YES" ];then
        echo "Keep all fq files">> ${outputDir}/${sampleName}_nohup.log
    else
    ### if fastqKeep not equal to Yes, then delete all deduped fq.
        echo "Delete all fq files">> ${outputDir}/${sampleName}_nohup.log
        if [ -f ${outputDir}/${sampleName}-READ.deduped.deAdapt.fq ]; then
            rm ${outputDir}/${sampleName}-READ.deduped.deAdapt.fq
        fi
        if [ -f ${outputDir}/${sampleName}-READ.deduped.fq ]; then
            rm ${outputDir}/${sampleName}-READ.deduped.fq
        fi
    fi

    ####combine all logs into one file
    if [ -f ${logDir}/${j}.log ]; then
        echo "     " >> ${logDir}/${j}.log
        echo "End of bbmap.log" >> ${logDir}/${j}.log
        echo "-----------------------------------------------------------" >> ${logDir}/${j}.log
    fi
    if [ -f ${finalOutput}/${j}_mapsplice.log ]; then
        cat ${finalOutput}/${j}_mapsplice.log >> ${logDir}/${j}.log
        echo "     " >> ${logDir}/${j}.log
        echo "End of mapsplice.log" >> ${logDir}/${j}.log
        echo "-----------------------------------------------------------" >> ${logDir}/${j}.log
        ###delete other logs
        rm ${finalOutput}/${j}_mapsplice.log
    fi
    cat ${logDir}/temp.log >> ${logDir}/${j}.log
    cat ${outputDir}/${sampleName}_nohup.log >> ${logDir}/${j}.log
    echo "     " >> ${logDir}/${j}.log
    echo "End of nohup.log" >> ${logDir}/${j}.log
    echo "-----------------------------------------------------------" >> ${logDir}/${j}.log
    
    ###delete other logs
    rm ${outputDir}/${sampleName}_nohup.log

    done
elif [ ${align} == "--align=yes" ]||[ ${align} == '--align=y' ]||[ ${align} == '--align=Yes' ]||[ ${align} == '--align=Y' ]||[ ${align} == '--align=YES' ]; then
    
    for i in `ls ${inputDir}/*{fastq,fq,txt}` ; do
    start_time="$(date -u +%s)"
    # get the ext:fastq,fq,txt; and then get the second ext:read1,R1,READ1,r1
    ext="${i##*.}"
    pre="${i%.*}"
   # get the filename as j
    j="${pre##*/}"
    sample="${j}"
    sampleName="${j}"
    echo "### Running Full Splice-Break Pipeline">> ${outputDir}/${sampleName}_nohup.log
    ts=`date +%d%m%Y%S`
    finalOutput=${outputDir}/${j}_mapsplice-${ts}
    echo "### Sample: ${sample}">> ${outputDir}/${sampleName}_nohup.log
    if [ -d ${outputDir}/${j}_mapsplice* ] && [ -f ${outputDir}/${j}_mapsplice*/Large_Deletions_NC_012920.1_No-Position-Filter.txt ] ; then
        echo "### Sample previously completed Splice-Break">> ${outputDir}/${sampleName}_nohup.log
        exit
    elif [ -d ${outputDir}/${j}_mapsplice* ] && [ -f ${outputDir}/${j}_mapsplice*/alignments.bam ] ; then
        echo "### Sample completed alignment. Running Splice-Break">> ${outputDir}/${sampleName}_nohup.log
        ${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName} ${outputDir} ${reference_name} ${SB_Path}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_157-16125.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_conservative_pos157-16125.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_357-15925.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_STRINGENT_pos357-15925.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_LargeMTDeletions_WGS-only_NoPositionFilter.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/LargeMTDeletions_DNAorRNA_Top30_NARpub.txt ${finalOutput}/${j}_LargeMTDeletions_DNAorRNA_Top30_NARpub.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam>> ${outputDir}/${sampleName}_nohup.log
    elif [ -f ${outputDir}/${j}-READ.deduped.deAdapt.fq ]; then
        echo "### PCR Replicates and Adapter Sequences previously removed. Running alignment and Splice-Break">> ${outputDir}/${sampleName}_nohup.log
        mkdir -v ${finalOutput}>> ${outputDir}/${sampleName}_nohup.log
        READ_FILE_END=${outputDir}/${j}-READ.deduped.deAdapt.fq
        
        echo "Editing out">> ${outputDir}/${sampleName}_nohup.log
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END}
        
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END}
        
        echo "/usr/bin/python ${mapsplice}/mapsplice.py -1 $READ_FILE_END -c ${refGenome} --non-canonical-double-anchor --bam --qual-scale phred33 -p 8 -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log">> ${outputDir}/${sampleName}_nohup.log
        /usr/bin/python ${mapsplice}/mapsplice.py \
           -1 $READ_FILE_END \
           -c ${refGenome} \
           --non-canonical-double-anchor \
           --bam \
           --qual-scale phred33 \
           -p 8 \
           -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log
        if [ $? -gt 0 ]; then
           echo "#ERROR: Mapsplice Fail. Check logs">> ${outputDir}/${sampleName}_nohup.log
           exit
        fi
        echo "### Sorting output" >> ${outputDir}/${sampleName}_nohup.log
        ${samtools} sort ${finalOutput}/alignments.bam -o ${finalOutput}/alignments.sorted.bam
        if [ $? -gt 0 ]; then
            echo "#ERROR: Samtools sort fail. Check logs">> ${outputDir}/${sampleName}_nohup.log
            exit
        fi
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/alignments.unsorted>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.sorted.bam ${finalOutput}/alignments.bam>> ${outputDir}/${sampleName}_nohup.log
        echo "--------------------------------------">> ${outputDir}/${sampleName}_nohup.log
        echo "### Splice-Break: ${j}">> ${outputDir}/${sampleName}_nohup.log
        ${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName} ${outputDir} ${reference_name} ${SB_Path}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_157-16125.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_conservative_pos157-16125.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_357-15925.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_STRINGENT_pos357-15925.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_LargeMTDeletions_WGS-only_NoPositionFilter.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/LargeMTDeletions_DNAorRNA_Top30_NARpub.txt ${finalOutput}/${j}_LargeMTDeletions_DNAorRNA_Top30_NARpub.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam>> ${outputDir}/${sampleName}_nohup.log
    elif [[ -f ${outputDir}/${j}-READ.deduped.fq ]]; then
        echo "### PCR Replicates previously removed. Running BBMAP BBDUK and REFORMAT">> ${outputDir}/${sampleName}_nohup.log
        R_dedupe=`wc -l < ${outputDir}/${j}-READ.deduped.fq`
        
        echo "DEDUPE READ Line Count: ${R_dedupe}">> ${outputDir}/${sampleName}_nohup.log
        
        ${bbmap}/bbduk.sh in=${outputDir}/${j}-READ.deduped.fq  out=${outputDir}/${j}-READ.deduped.deAdapt.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log
        
        R_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ.deduped.deAdapt.fq`
        
        echo "DEDUPE + DEADAPT READ Line Count: ${R_dedupe_deAdapt}">> ${outputDir}/${sampleName}_nohup.log
        
        Deduped=`echo "${R} - ${R_dedupe}" | bc`
        
        echo "${Deduped} R PCR replicates removed">> ${outputDir}/${sampleName}_nohup.log
        
        
        echo "-------------------------------------">> ${outputDir}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}">> ${outputDir}/${sampleName}_nohup.log
        mkdir -v ${finalOutput}>> ${outputDir}/${sampleName}_nohup.log
        READ_FILE_END=${outputDir}/${j}-READ.deduped.deAdapt.fq
        
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END}
        
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END}
        
        echo "/usr/bin/python ${mapsplice}/mapsplice.py -1 $READ_FILE_END -c ${refGenome} --non-canonical-double-anchor --bam --qual-scale phred33 -p 8 -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log">> ${outputDir}/${sampleName}_nohup.log
        /usr/bin/python ${mapsplice}/mapsplice.py \
           -1 $READ_FILE_END \
           -c ${refGenome} \
           --non-canonical-double-anchor \
           --bam \
           --qual-scale phred33 \
           -p 8 \
           -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log
        if [ $? -gt 0 ]; then
          echo "#ERROR: Mapsplice Fail. Check logs">> ${outputDir}/${sampleName}_nohup.log
          exit
        fi
        echo "### Sorting output">> ${outputDir}/${sampleName}_nohup.log
        ${samtools} sort ${finalOutput}/alignments.bam -o ${finalOutput}/alignments.sorted.bam
        if [ $? -gt 0 ]; then
          echo "#ERROR: Samtools sort fail. Check logs">> ${outputDir}/${sampleName}_nohup.log
          exit
        fi
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/alignments.unsorted>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.sorted.bam ${finalOutput}/alignments.bam>> ${outputDir}/${sampleName}_nohup.log
        echo "--------------------------------------">> ${outputDir}/${sampleName}_nohup.log
        echo "### Splice-Break: ${j}">> ${outputDir}/${sampleName}_nohup.log
        ${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName} ${outputDir} ${reference_name} ${SB_Path}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_157-16125.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_conservative_pos157-16125.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_357-15925.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_STRINGENT_pos357-15925.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_LargeMTDeletions_WGS-only_NoPositionFilter.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/LargeMTDeletions_DNAorRNA_Top30_NARpub.txt ${finalOutput}/${j}_LargeMTDeletions_DNAorRNA_Top30_NARpub.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam>> ${outputDir}/${sampleName}_nohup.log
    else
        echo "### PSB Pipeline: ${j}">> ${outputDir}/${sampleName}_nohup.log
            R=`wc -l < ${inputDir}/${j}.${ext}`
        
        echo "READ Line Count: ${R}">> ${outputDir}/${sampleName}_nohup.log
        
        echo "${bbmap}/dedupe.sh in=${inputDir}/${j}.${ext} out=${outputDir}/${j}-READ.deduped.fq ac=f &> ${logDir}/${j}.log">> ${outputDir}/${sampleName}_nohup.log
        ${bbmap}/dedupe.sh in=${inputDir}/${j}.${ext} out=${outputDir}/${j}-READ.deduped.fq ac=f &> ${logDir}/${j}.log
        
        R_dedupe=`wc -l < ${outputDir}/${j}-READ.deduped.fq`
        
        echo "DEDUPE READ Line Count: ${R_dedupe}">> ${outputDir}/${sampleName}_nohup.log
       
        ${bbmap}/bbduk.sh in=${outputDir}/${j}-READ.deduped.fq  out=${outputDir}/${j}-READ.deduped.deAdapt.fq ref=${bbmap}/resources/truseq.fa.gz &>> ${logDir}/${j}.log

        R_dedupe_deAdapt=`wc -l < ${outputDir}/${j}-READ.deduped.deAdapt.fq`
        
        echo "DEDUPE + DEADAPT READ Line Count: ${R_dedupe_deAdapt}">> ${outputDir}/${sampleName}_nohup.log
        
        Deduped=`echo "${R} - ${R_dedupe}" | bc`
        
        echo "${Deduped} R PCR replicates removed">> ${outputDir}/${sampleName}_nohup.log
        
        
        echo "-------------------------------------">> ${outputDir}/${sampleName}_nohup.log
        echo "### MAPSPLICE: ${j}">> ${outputDir}/${sampleName}_nohup.log
      
        mkdir -v ${finalOutput}>> ${outputDir}/${sampleName}_nohup.log
        READ_FILE_END=${outputDir}/${j}-READ.deduped.deAdapt.fq
        
        sed -i 's/\/1_dd0 \/1/\/1/g' ${READ_FILE_END}
        
        sed -i 's/\/1_dd1 \/1/\/1/g' ${READ_FILE_END}
        
        echo "/usr/bin/python ${mapsplice}/mapsplice.py -1 $READ_FILE_END -c ${refGenome} --non-canonical-double-anchor --bam --qual-scale phred33 -p 8 -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log">> ${outputDir}/${sampleName}_nohup.log
        /usr/bin/python ${mapsplice}/mapsplice.py \
           -1 $READ_FILE_END \
           -c ${refGenome} \
           --non-canonical-double-anchor \
           --bam \
           --qual-scale phred33 \
           -p 8 \
           -o ${finalOutput} 2> ${finalOutput}/${j}_mapsplice.log
        if [ $? -gt 0 ]; then
          echo "#ERROR: Mapsplice Fail. Check logs">> ${outputDir}/${sampleName}_nohup.log
          exit
        fi
        echo "### Sorting output">> ${outputDir}/${sampleName}_nohup.log
        ${samtools} sort ${finalOutput}/alignments.bam -o ${finalOutput}/alignments.sorted.bam
        if [ $? -gt 0 ]; then
          echo "#ERROR: Samtools sort fail. Check logs">> ${outputDir}/${sampleName}_nohup.log
          exit
        fi
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/alignments.unsorted>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.sorted.bam ${finalOutput}/alignments.bam>> ${outputDir}/${sampleName}_nohup.log
        echo "--------------------------------------">> ${outputDir}/${sampleName}_nohup.log
        echo "### Splice-Break: ${j}"　>> ${outputDir}/${sampleName}_nohup.log
        ${SB} ${finalOutput} ${finalOutput} ${SB_ref} ${sampleName} ${outputDir} ${reference_name} ${SB_Path}
        mv -v ${finalOutput}/Coverage.txt ${finalOutput}/${j}_Coverage.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_157-16125.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_conservative_pos157-16125.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_357-15925.txt ${finalOutput}/${j}_LargeMTDeletions_LR-PCR_STRINGENT_pos357-15925.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/Large_Deletions_NC_012920.1_No-Position-Filter.txt ${finalOutput}/${j}_LargeMTDeletions_WGS-only_NoPositionFilter.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/LargeMTDeletions_DNAorRNA_Top30_NARpub.txt ${finalOutput}/${j}_LargeMTDeletions_DNAorRNA_Top30_NARpub.txt>> ${outputDir}/${sampleName}_nohup.log
        mv -v ${finalOutput}/alignments.bam ${finalOutput}/${j}_alignments.bam>> ${outputDir}/${sampleName}_nohup.log
    fi
    end_time="$(date -u +%s)"
    elapsed="$(bc <<<"$end_time-$start_time")"
    elapsedMin=`echo "${elapsed} / 60" | bc`
    echo "### ${j} RUNTIME: ${elapsedMin}m">> ${outputDir}/${sampleName}_nohup.log
    
    if [ ${fastq_keep} == "--fastq_keep=Yes" ] ||[ ${fastq_keep} == "--fastq_keep=Y" ] || [ ${fastq_keep} == "--fastq_keep=yes" ]||[ ${fastq_keep} == "--fastq_keep=y" ]||[ ${fastq_keep} == "--fastq_keep=YES" ];then
        echo "Keep all fq files">> ${outputDir}/${sampleName}_nohup.log
    else
    ### if fastqKeep not equal to Yes, then delete all deduped fq.
        echo "Delete all fq files">> ${outputDir}/${sampleName}_nohup.log
        if [ -f ${outputDir}/${sampleName}-READ.deduped.deAdapt.fq ]; then
            rm ${outputDir}/${sampleName}-READ.deduped.deAdapt.fq
        fi
        if [ -f ${outputDir}/${sampleName}-READ.deduped.fq ]; then
            rm ${outputDir}/${sampleName}-READ.deduped.fq
        fi
    fi

    #### combine all logs into one file
    if [ -f ${logDir}/${j}.log ]; then
        echo "     " >> ${logDir}/${j}.log
        echo "End of bbmap.log" >> ${logDir}/${j}.log
        echo "-----------------------------------------------------------" >> ${logDir}/${j}.log
    fi
    if [ -f ${finalOutput}/${j}_mapsplice.log ]; then
        cat ${finalOutput}/${j}_mapsplice.log >> ${logDir}/${j}.log
        echo "     " >> ${logDir}/${j}.log
        echo "End of mapsplice.log" >> ${logDir}/${j}.log
        echo "-----------------------------------------------------------" >> ${logDir}/${j}.log
        ###delete other logs
        rm ${finalOutput}/${j}_mapsplice.log
    fi
    cat ${logDir}/temp.log >> ${logDir}/${j}.log
    cat ${outputDir}/${sampleName}_nohup.log >> ${logDir}/${j}.log
    echo "     " >> ${logDir}/${j}.log
    echo "End of nohup.log" >> ${logDir}/${j}.log
    echo "-----------------------------------------------------------" >> ${logDir}/${j}.log
    
    ###delete other logs
    rm ${outputDir}/${sampleName}_nohup.log
    done
else
    echo "Please indicate whether to run alignment and try again"
fi

###delete other logs
rm ${logDir}/temp.log
