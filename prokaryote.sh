#!/bin/bash

# prokaryote.sh
# Workflow de bioinformática para análise de B pertussis
# Autor: Luciano Kalabric & Viviane Ferreira
# Objetivo: Análise das sequencias, filtro de qualidade, correção das reads e montagem de novo
# Controle de versão: Incluir o log das próximas atualizações aqui
# Versão 1.0 de 07 DEZ 2022 - Programa inicial revisado

# Entrada de dados
LIBNAME=$1
WF=$2
if [[ $# -ne 2 ]]; then
	echo "Erro: Faltou o nome da biblioteca ou número do worflow!"
	echo "Sintáxe: ./prokaryote.sh <LIBRARY> <WF: 1, 2, 3,...>"
	exit 0
fi
if [[ $WF > 1 ]]; then
  echo "Erro: Workflow não disponível! Tente WF 1!"
  exit 1
fi

# Caminhos dos dados de entrada
RAWDIR="${HOME}/data/${LIBNAME}"
if [ ! -d $RAWDIR ]; then
	echo "Erro: Pasta de dados não encontrada!"
	exit 2
fi
REFSEQFILENAME="${HOME}/data/REFSEQ/Bper/NZ_CP025371.fasta"
GENEFILEDIR="${HOME}/data/REFSEQ/Bper/GENE"

# Configuração das pastas de saída
echo "Preparando pastas para (re-)análise dos dados..."
RESULTSDIR="${HOME}/ngs-analysis/${LIBNAME}/wf${WF}"
# Cria a pasta de resultados
#[[ ! -d "${RESULTSDIR}" ]] || mkdir -vp ${RESULTSDIR}
read -p "Re-analisar os dados [S-apagar e re-analisa os dados / N-continuar as análises de onde pararam]? " -n 1 -r
if [[ $REPLY =~ ^[Ss]$ ]]; then
  # Reseta a pasta de resultados do worflow
	echo "Apagando as pastas e re-iniciando as análises..."
	[[ ! -d "${RESULTSDIR}" ]] || mkdir -vp ${RESULTSDIR} && rm -r "${RESULTSDIR}"; mkdir -vp "${RESULTSDIR}"
fi
FASTQCDIR="${RESULTSDIR}/FASTQC"
TRIMMOMATICDIR="${RESULTSDIR}/TRIMMOMATIC"
MUSKETDIR="${RESULTSDIR}/MUSKET"
SPADESDIR="${RESULTSDIR}/SPADES"

# Parâmetro de otimização das análises
THREADS="$(lscpu | grep 'CPU(s):' | awk '{print $2}' | sed -n '1p')"

# Quality control report
# Foi utilizado para avaliar o sequenciamento e extrair alguns parâmtros para o Trimmomatic
function qc_bper () {
	if [ ! -d $FASTQCDIR ]; then
		mkdir -vp $FASTQCDIR
		echo -e "Executando fastqc em ${RAWDIR}...\n"
		fastqc --noextract --nogroup -o ${FASTQCDIR} "${RAWDIR}/*.fastq.gz
	# for file in ${RAWDIR}; do
	#		zcat file | fastqc -o ${FASTQCDIR} 
    	#	done
	else
		echo "Reanalisando os dados..."
	fi
    IODIR=$FASTQCDIR
}


# Quality control filter using Trimmomatic
function trim_bper () {
  # trimmomatic PE "${IODIR}/SRR2589044_1.fastq.gz" ${IODIR}/SRR2589044_2.fastq.gz" \
                  SRR2589044_1.trim.fastq.gz SRR2589044_1un.trim.fastq.gz \
                  SRR2589044_2.trim.fastq.gz SRR2589044_2un.trim.fastq.gz \
                  SLIDINGWINDOW:4:20 MINLEN:25 ILLUMINACLIP:NexteraPE-PE.fa:2:40:15
  IODIR=$TRIMMOMATICDIR              
}

# 3) Assembly das reads
# spapes -1 "${IODIR}/1E1_S1_L001_R1_001.fastq.gz" -2 "${IODIR}/1E1_S1_L001_R2_001.fastq.gz" --only-assembler --careful -o assembly-analysis

# 4) Assembly das contigs

# 5) Visualização da montagem

#
# Main do script
#

# Define as etapas de cada workflow
# Etapas obrigatórios: basecalling, demux/primer_removal ou demux_headcrop, reads_polishing e algum método de classificação taxonômica
workflowList=(
	'qc_bper'
)

# Validação do WF
if [[ $WF -gt ${#workflowList[@]} ]]; then
	echo "Erro: Workflow não definido!"
	exit 4
fi
# Índice para o array workflowList 0..n
indice=$(expr $WF - 1)

# Execução das análises propriamente ditas a partir do workflow selecionado
echo -e "\nExecutando o workflow WF$WF..."
echo "Passos do WF$WF: ${workflowList[$indice]}"
# Separa cada etapa do workflow no vetor steps
read -r -a steps <<< "${workflowList[$indice]}"
for call_func in ${steps[@]}; do
	echo -e "\nExecutando o passo $call_func... "
	eval $call_func
done
exit 4
