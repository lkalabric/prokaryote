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

RESULTSDIR="/media/brazil1/Seagate Expansion Drive/ngs-analysis/${LIBNAME}/wf${WF}/KHMER"

# FILENAME=`echo "$1" | cut -d'.' -f1`

# Converte fastq para fasta
sed -n '1~4s/^@/>/p;2~4p' "${RESULTSDIR}/${LIBNAME}.fastq" > "${RESULTSDIR}/${LIBNAME}.fasta"

# Total de reads
echo -e "Total de reads:\n"
grep -c ">" "${RESULTSDIR}/${LIBNAME}.fasta"

# Total de base
echo -e "Total de bases:\n"
grep -v ">" "${RESULTSDIR}/${LIBNAME}.fasta" > wc -m

# Conta o número de Ns
echo -e "Total de Ns:\n"
grep -c "N" "${RESULTSDIR}/${LIBNAME}.fasta"
