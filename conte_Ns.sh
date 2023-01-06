#!/bin/bash

# prokaryote.sh
# Workflow de bioinformática para análise de Bordetella pertussis
# Autor: Luciano Kalabric & Viviane Ferreira
# Objetivo: Análise das sequencias, filtro de qualidade, correção das reads e montagem de novo
# Controle de versão: Incluir o log das próximas atualizações aqui
# Versão 1.0 de 07 DEZ 2022 - Programa inicial revisado

# Requirements: bbmap, fastqc, conda, trimmomatic, musket, flash, khmer, spades

# Entrada de dados
LIBNAME=$1
WF=$2
if [[ $# -ne 2 ]]; then
	echo "Erro: Faltou o nome da biblioteca ou número do worflow!"
	echo "Sintáxe: ./prokaryote.sh <LIBRARY> <WF: 1, 2, 3,...>"
	exit 0
fi

KHMERDIR="/media/brazil1/Seagate Expansion Drive/ngs-analysis/${LIBNAME}/wf${WF}/KHMER"
SPADESDIR="/media/brazil1/Seagate Expansion Drive/ngs-analysis/${LIBNAME}/wf${WF}/SPADES"
LOGDIR="/media/brazil1/Seagate Expansion Drive/ngs-analysis/${LIBNAME}/wf${WF}"

# Dados do KHMER
# Converte fastq para fasta
sed -n '1~4s/^@/>/p;2~4p' "${KHMERDIR}/${LIBNAME}.fastq" > "${KHMERDIR}/${LIBNAME}.fasta"

# Total de reads
echo -e "\nTotal de reads:" >> "${LOGDIR}/${LIBNAME}_report.log"
echo -e "$(grep -c ">" "${KHMERDIR}/${LIBNAME}.fasta")\n" >> "${LOGDIR}/${LIBNAME}_report.log"

# Total de base
echo "Total de bases:" >> "${LOGDIR}/${LIBNAME}_report.log"
echo -e "$(grep -v ">" "${KHMERDIR}/${LIBNAME}.fasta" | wc -m)\n" >> "${LOGDIR}/${LIBNAME}_report.log"

# Conta o número de Ns
echo "Total de Ns:" >> "${LOGDIR}/${LIBNAME}_report.log"
echo -e "$(grep -v ">" "${KHMERDIR}/${LIBNAME}.fasta" | grep -c "N")\n" >> "${LOGDIR}/${LIBNAME}_report.log"

# Dados do SPADES
# Total de contigs
echo -e "\nTotal de contigs:" >> "${LOGDIR}/${LIBNAME}_report.log"
echo -e "$(grep -c ">" "${SPADESDIR}/contigs.fasta")\n" >> "${LOGDIR}/${LIBNAME}_report.log"

# Total de base
echo "Total de bases:" >> "${LOGDIR}/${LIBNAME}_report.log"
echo -e "$(grep -v ">" "${SPADESDIR}/contigs.fasta" | wc -m)\n" >> "${LOGDIR}/${LIBNAME}_report.log"

# Conta o número de Ns
echo "Total de Ns:" >> "${LOGDIR}/${LIBNAME}_report.log"
echo -e "$(grep -v ">" "${SPADESDIR}/contigs.fasta" | grep -c "N")\n" >> "${LOGDIR}/${LIBNAME}_report.log"
