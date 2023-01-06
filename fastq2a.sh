#!/bin/bash

# prokaryote.sh
# Workflow de bioinformática para análise de Bordetella pertussis
# Autor: Luciano Kalabric & Viviane Ferreira
# Objetivo: Análise das sequencias, filtro de qualidade, correção das reads e montagem de novo
# Controle de versão: Incluir o log das próximas atualizações aqui
# Versão 1.0 de 07 DEZ 2022 - Programa inicial revisado

# Requirements: bbmap, fastqc, conda, trimmomatic, musket, flash, khmer, spades

# Entrada de dados
RESULTSDIR=ngs-library/

FILENAME=`echo "$1" | cut -d'.' -f1`

# Converte fastq para fasta
sed -n '1~4s/^@/>/p;2~4p' "${FILENAME}.fastq" > "${FILENAME}.fasta"

# Conta o número de Ns
grep -c "N" "${FILENAME}.fasta"
