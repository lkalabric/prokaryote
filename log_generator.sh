#!/bin/bash

# command name: log_generator.sh
# author: Luciano Kalabric Silva
# institution: Oswaldo Cruz Foundation, Goncalo Moniz Institute, Bahia, Brazil
# last update: 09 AGO 2023
# objetive: Gera uma contagem do número de reads em cada etapa do pipeline prokaryote2.sh
# Syntax: ./log_generator.sh

# Decalração de variáveis
LIBNAME=$1
WF=$2
RAWDIR="${HOME}/data/${LIBNAME}"

# Validating arguments
if [[ $# -ne 2 ]]; then
    echo "Illegal number of parameters"
    echo "Syntax: log_generator.sh <LIBRARY> <WF: 1, 2, 3,...>"
    exit 0    
fi

if [ ! -d ${RAWDIR} ]; then
  echo "Library não existe!"
  exit 1
fi

echo -e "Summary sequencing analysis of ${LIBNAME}\n" | tee "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Total reads - $(zcat ${HOME}/data/${LIBNAME}/*.fastq.gz | grep -h -c "HHYF3BCX3")\n" | tee -a "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Passed reads" | tee -a  "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Trimmomatic - $(grep -c "HHYF3BCX3" ${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/TRIMMOMATIC/*.fastq | awk 'BEGIN {cnt=0;FS=":"}; {cnt+=$2;}; END {print cnt;}')" | tee -a "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Musket - $(grep -c "HHYF3BCX3" ${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/MUSKET/*.fastq | awk 'BEGIN {cnt=0;FS=":"}; {cnt+=$2;}; END {print cnt;}')" | tee -a "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Flash - $(grep -c "HHYF3BCX3" ${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/FLASH/*.fastq | awk 'BEGIN {cnt=0;FS=":"}; {cnt+=$2;}; END {print cnt;}')" | tee -a "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Khmer - $(grep -h -c "HHYF3BCX3" ${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/KHMER/${LIBNAME}.fastq)\n" | tee -a "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Number of contigs" | tee -a "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
echo -e "Spades - $(grep -c ">" ${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/SPADES/contigs.fasta)" | tee -a "${HOME}/ngs-analysis/${LIBNAME}/wf${WF}/${LIBNAME}_report.log"
