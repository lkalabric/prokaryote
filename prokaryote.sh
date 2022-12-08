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
if [[ $WF > 3 ]]; then
  echo "Erro: Workflow não disponível! Tente WF 1!"
  exit 1
fi

# Caminhos dos dados de entrada
RAWDIR="${HOME}/data/${LIBNAME}"
if [ ! -d $RAWDIR ]; then
	echo "Erro: Pasta de dados não encontrada!"
	exit 2
fi
IODIR=$RAWDIR
REFSEQFILENAME="${HOME}/data/REFSEQ/Bper/NZ_CP025371.fasta"
GENEFILEDIR="${HOME}/data/REFSEQ/Bper/GENE"

# Lê o nome dos arquivos de entreda. O nome curto será o próprio nome da library
INDEX=0
for FILE in $(find ${IODIR} -mindepth 1 -type f -name *.fastq.gz -exec basename {} \; | sort); do
	FULLNAME[$INDEX]=${FILE}
	((INDEX++))
done

# Validação dos dados
LIBSUFIX=$(echo $LIBNAME | cut -d "_" -f 2)
SAMPLENAME=$(echo $FULLNAME[0] | cut -d "E" -f 1)
if [[ $SAMPLENAME -ne $LIBSUFIX ]]; then
	echo "Você copiou os dados errados para a pasta $LIBNAME!"
	exit 3
fi

# Configuração das pastas de saída
echo "Preparando pastas para (re-)análise dos dados..."
RESULTSDIR="${HOME}/ngs-analysis/${LIBNAME}/wf${WF}"
# Cria a pasta de resultados
if [[ ! -d "${RESULTSDIR}" ]]; then
	mkdir -vp ${RESULTSDIR}
else
	read -p "Re-analisar os dados [S-apagar e re-analisa os dados / N-continuar as análises de onde pararam]? " -n 1 -r
	if [[ $REPLY =~ ^[Ss]$ ]]; then
	  # Reseta a pasta de resultados do worflow
		echo "Apagando as pastas e re-iniciando as análises..."
		[[ ! -d "${RESULTSDIR}" ]] || mkdir -vp ${RESULTSDIR} && rm -r "${RESULTSDIR}"; mkdir -vp "${RESULTSDIR}"
	fi
fi
FASTQCDIR="${RESULTSDIR}/FASTQC"
TEMPDIR="${RESULTSDIR}/TEMP"
TRIMMOMATICDIR="${RESULTSDIR}/TRIMMOMATIC"
MUSKETDIR="${RESULTSDIR}/MUSKET"
FLASHDIR="${RESULTSDIR}/FLASH"
KHMERDIR="${RESULTSDIR}/KHMER"
SPADESDIR="${RESULTSDIR}/SPADES"

# Parâmetro de otimização das análises
KMER=21 # Defaut MAX_KMER_SIZE=28. Se necessário, alterar o Makefile e recompilar
THREADS="$(lscpu | grep 'CPU(s):' | awk '{print $2}' | sed -n '1p')"

# Quality control report
# Foi utilizado para avaliar o sequenciamento e extrair alguns parâmtros para o Trimmomatic
# Link: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
function qc_bper () {
	if [ ! -d $FASTQCDIR ]; then
		mkdir -vp $FASTQCDIR
		echo -e "Executando fastqc em ${IODIR}...\n"
		fastqc --noextract --nogroup -o ${FASTQCDIR} ${IODIR}/*.fastq.gz
	else
		echo "Dados analisados previamente..."
	fi
}

# Quality control filter using Trimmomatic
# Link: http://www.usadellab.org/cms/?page=trimmomatic
function trim_bper () {
	source activate trimmomatic
	if [ ! -d $TRIMMOMATICDIR ]; then
		mkdir -vp $TRIMMOMATICDIR
		mkdir -vp $TEMPDIR
		echo -e "Executando trimmomatic em ${IODIR}...\n"
		# Executa o filtro de qualidade
		trimmomatic PE -threads ${THREADS} -trimlog ${TRIMMOMATICDIR}/${LIBNAME}_trimlog.txt \
					-summary ${TRIMMOMATICDIR}/${LIBNAME}_summary.txt \
					${IODIR}/${FULLNAME[0]} ${IODIR}/${FULLNAME[1]} \
					${TRIMMOMATICDIR}/${LIBNAME}_R1.fastq ${TEMPDIR}/${LIBNAME}_R1_u.fastq \
					${TRIMMOMATICDIR}/${LIBNAME}_R2.fastq ${TEMPDIR}/${LIBNAME}_R2_u.fastq \
					SLIDINGWINDOW:4:20 MINLEN:35
	else
		echo "Dados analisados previamente..."
	fi
  	IODIR=$TRIMMOMATICDIR              
}

# Correção de erros
# Link: https://musket.sourceforge.net/homepage.htm
function musket_bper () {
	if [ ! -d $MUSKETDIR ]; then
		mkdir -vp $MUSKETDIR
		echo -e "Executando musket em ${IODIR}...\n"
		musket -k ${KMER} 536870912 -p ${THREADS} \
			${IODIR}/${LIBNAME}_R1.fastq ${IODIR}/${LIBNAME}_R2.fastq \
			-omulti ${MUSKETDIR}/${LIBNAME} -inorder
		mv ${MUSKETDIR}/${LIBNAME}.0 ${MUSKETDIR}/${LIBNAME}_R1.fastq
		mv ${MUSKETDIR}/${LIBNAME}.1 ${MUSKET*IR}/${LIBNAME}_R2.fastq
	else		echo "Dados analisados previamente..."
	fi
  	IODIR=$MUSKETDIR              
}

# Concatenar as reads forward e reverse para extender as reads
# Link: http://ccb.jhu.edu/software/FLASH/
function flash_bper () {
	if [ ! -d $FLASHDIR ]; then
		mkdir -vp $FLASHDIR
		echo -e "Executando flash em ${IODIR}...\n"
		flash ${IODIR}/${LIBNAME}*.fastq \
			-t ${THREADS} -o ${LIBNAME} -d ${FLASHDIR} 2>&1 | tee ${FLASHDIR}/${LIBNAME}_flash.log	
		mv ${FLASHDIR}/${LIBNAME}.extendedFrags.fastq ${FLASHDIR}/${LIBNAME}.fastq
		mv ${FLASHDIR}/${LIBNAME}.notCombined_1.fastq ${FLASHDIR}/${LIBNAME}.notCombined_1.fastnq
		mv ${FLASHDIR}/${LIBNAME}.notCombined_2.fastq ${FLASHDIR}/${LIBNAME}.notCombined_2.fastnq
	else
		echo "Dados analisados previamente..."
	fi
  	IODIR=$FLASHDIR              
}

# Normalização digital (remove a maioria das sequencias redundantes)
# Link: 
function khmer_bper () {
	if [ ! -d $KHMERDIR ]; then
		mkdir -vp $KHMERDIR
		echo -e "Executando khmer em ${IODIR}...\n"
		khmer normalize-by-median --force-single \
			-s ${IODIR}/${LIBNAME}*.fastq \
			-R ${KHMERDIR}/${LIBNAME}_report.txt --report-frequency 100000 \
			-o ${KHMERDIR}/${LIBNAME}.fastq
	else
		echo "Dados analisados previamente..."
	fi
  	IODIR=$KHMERDIR              
}

# Assemble reads de novo
# Link: 
function spades_bper () {
	if [ ! -d $SPADESDIR ]; then
		mkdir -vp $SPADESDIR
		echo -e "Executando spades em ${IODIR}...\n"
		spapes -1 ${IODIR}/${LIBNAME}.fastq \
			--only-assembler --careful -o assembly-analysis
	else
		echo "Dados analisados previamente..."
	fi
 		IODIR=$KHMERDIR              
}

#
# Main do script
#

# Define as etapas de cada workflow
# Etapas obrigatórios: basecalling, demux/primer_removal ou demux_headcrop, reads_polishing e algum método de classificação taxonômica
workflowList=(
	'qc_bper trim_bper musket_bper flash_bper khmer_bper'
	'trim_bper musket_bper'
	'trim_bper musket_bper flash_bper khmer_bper'
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
