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

# Caminhos dos dados de entrada
RAWDIR="${HOME}/data/${LIBNAME}"
if [[ ! -d $RAWDIR ]]; then
	echo "Erro: Pasta de dados não encontrada!"
	exit 2
fi
IODIR=$RAWDIR
REFSEQFILENAME="${HOME}/data/REFSEQ/Bper/NZ_CP025371.fasta"
GENEFILEDIR="${HOME}/data/REFSEQ/Bper/GENE"

# Validação dos dados
# Lê o nome dos arquivos de entreda. O nome curto será o próprio nome da library
INDEX=0
for FILE in $(find ${IODIR} -mindepth 1 -type f -name *.fastq.gz -exec basename {} \; | sort); do
	FULLNAME[$INDEX]=${FILE}
	((INDEX++))
done
SAMPLENAME=$(echo $FULLNAME[0] | cut -d "E" -f 1)
LIBSUFIX=$(echo $LIBNAME | cut -d "_" -f 2)
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
SPADES2DIR="${RESULTSDIR}/SPADES2"
FLAG=0

# Parâmetro de otimização das análises
KMER=21 # Defaut MAX_KMER_SIZE=28. Se necessário, alterar o Makefile e recompilar
THREADS="$(lscpu | grep 'CPU(s):' | awk '{print $2}' | sed -n '1p')"

# Quality control report
# Foi utilizado para avaliar o sequenciamento e extrair alguns parâmtros para o Trimmomatic
# Link: https://www.bioinformatics.babraham.ac.uk/projects/fastqc/
function qc_bper () {
	if [[ ! -d $FASTQCDIR ]]; then
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
	if [[ ! -d $TRIMMOMATICDIR ]]; then
		mkdir -vp $TRIMMOMATICDIR
		mkdir -vp $TEMPDIR
		echo -e "Executando trimmomatic em ${IODIR}...\n"
		# Executa o filtro de qualidade
		trimmomatic PE -threads ${THREADS} -trimlog ${TRIMMOMATICDIR}/${LIBNAME}_trimlog.txt \
					-summary ${TRIMMOMATICDIR}/${LIBNAME}_summary.txt \
					${IODIR}/*.fastq* \
					${TRIMMOMATICDIR}/${LIBNAME}_R1.fastq ${TEMPDIR}/${LIBNAME}_R1u.fastq \
					${TRIMMOMATICDIR}/${LIBNAME}_R2.fastq ${TEMPDIR}/${LIBNAME}_R2u.fastq \
					SLIDINGWINDOW:4:20 MINLEN:35
		# Concatena as reads forward e reversar não pareadas para seguir como arquivo singled-end
		cat ${TEMPDIR}/${LIBNAME}_R1u.fastq ${TEMPDIR}/${LIBNAME}_R2u.fastq > ${TRIMMOMATICDIR}/${LIBNAME}_R1R2u.fastq
	else
		echo "Dados analisados previamente..."
	fi
  	FLAG=1
	IODIR=$TRIMMOMATICDIR              
}

# Correção de erros
# Link: https://musket.sourceforge.net/homepage.htm
function musket_bper () {
	if [[ ! -d $MUSKETDIR ]]; then
		mkdir -vp $MUSKETDIR
		echo -e "Executando musket em ${IODIR}...\n"
		
		# New code
		musket -k ${KMER} 536870912 -p ${THREADS} \
			${IODIR}/${LIBNAME}*.fastq \
			-omulti ${MUSKETDIR}/${LIBNAME} -inorder -lowercase
		mv ${MUSKETDIR}/${LIBNAME}.0 ${MUSKETDIR}/${LIBNAME}_R1.fastq
		mv ${MUSKETDIR}/${LIBNAME}.1 ${MUSKETDIR}/${LIBNAME}_R1R2u.fastq
		mv ${MUSKETDIR}/${LIBNAME}.2 ${MUSKETDIR}/${LIBNAME}_R2.fastq
				
		# Original code (somente paired-end data)
		# musket -k ${KMER} 536870912 -p ${THREADS} \
		#	${IODIR}/${LIBNAME}_R1.fastq ${IODIR}/${LIBNAME}_R2.fastq \
		#	-omulti ${MUSKETDIR}/${LIBNAME} -inorder -lowercase
		# mv ${MUSKETDIR}/${LIBNAME}.0 ${MUSKETDIR}/${LIBNAME}_R1.fastq
		# mv ${MUSKETDIR}/${LIBNAME}.1 ${MUSKETDIR}/${LIBNAME}_R2.fastq
	else		
		echo "Dados analisados previamente..."
	fi
  	IODIR=$MUSKETDIR              
}

# Concatenar as reads forward e reverse para extender as reads
# Link: http://ccb.jhu.edu/software/FLASH/
function flash_bper () {
	if [[ ! -d $FLASHDIR ]]; then
		mkdir -vp $FLASHDIR
		echo -e "Executando flash em ${IODIR}...\n"
		flash ${IODIR}/${LIBNAME}_R1.fastq ${IODIR}/${LIBNAME}_R2.fastq \
			-t ${THREADS} -o ${LIBNAME} -d ${FLASHDIR} 2>&1 | tee ${FLASHDIR}/${LIBNAME}_flash.log	
		mv ${FLASHDIR}/${LIBNAME}.extendedFrags.fastq ${FLASHDIR}/${LIBNAME}_R1R2e.fastq
		mv ${FLASHDIR}/${LIBNAME}.notCombined_1.fastq ${FLASHDIR}/${LIBNAME}_R1nc.fastq
		mv ${FLASHDIR}/${LIBNAME}.notCombined_2.fastq ${FLASHDIR}/${LIBNAME}_R2nc.fastq
		cp ${MUSKETDIR}/${LIBNAME}_R1R2u.fastq ${FLASHDIR}/
	else
		echo "Dados analisados previamente..."
	fi
  	FLAG=2
	IODIR=$FLASHDIR              
}

# Normalização digital (remove a maioria das sequencias redundantes)
# Link: https://khmer-protocols.readthedocs.io/en/v0.8.2/mrnaseq/2-diginorm.html
function khmer_bper () {
	if [[ ! -d $KHMERDIR ]]; then
		mkdir -vp $KHMERDIR
		echo -e "Executando khmer em ${IODIR}...\n"
		khmer normalize-by-median -k ${KMER} ${IODIR}/${LIBNAME}*.fastq \
			-R ${KHMERDIR}/${LIBNAME}_report.txt --report-frequency 100000 \
			-o ${KHMERDIR}/${LIBNAME}.fastq
	else
		echo "Dados analisados previamente..."
	fi
  	IODIR=$KHMERDIR              
}

# Assemble reads de novo
# Link: https://github.com/ablab/spades
function spades_bper () {
	if [[ ! -d $SPADESDIR ]]; then
		mkdir -vp $SPADESDIR
		echo -e "Executando spades em ${IODIR}...\n"
		
		# New
		case FLAG in
		0) 
			echo -e "Flag para controle de fluxo da montagem pelo Spades: $FLAG\n"
			spades.py -1 ${IODIR}/*R1*.fastq* -2 ${IODIR}/*R2*.fastq* \
				--only-assembler --careful --isolate -o ${SPADESDIR}
			;;
		1) 
			echo -e "Flag para controle de fluxo da montagem pelo Spades: $FLAG\n"
			spades.py -1 ${IODIR}/*R1.fastq* -2 ${IODIR}/*R2.fastq* \
				-s ${IODIR}/*R1R2u.fastq* \
				--only-assembler --careful --isolate -o ${SPADESDIR}
			;;
		2)
			echo -e "Flag para controle de fluxo da montagem pelo Spades: $FLAG\n"
			spades.py -s ${IODIR}/*.fastq
				--only-assembler --careful --isolate -o ${SPADESDIR}
			;;
		*)
			echo -e "Parece que houve algo errado aqui!\n" 
			if [[ $(ls ${IODIR}/*.fastq* | wc -l) -eq 2 ]]; then
				spades.py -1 ${IODIR}/*R1*.fastq* -2 ${IODIR}/*R2*.fastq* \
					--only-assembler --careful -o ${SPADESDIR}
			else
				spades.py -1 ${IODIR}/*R1.fastq* -2 ${IODIR}/*R2.fastq* \
					-s ${IODIR}/*R1R2u.fastq* \
					--only-assembler --careful -o ${SPADESDIR}
			fi
			;;
		esac
		# Original 
		# Verifica o número de arquivos em ${IODIR}
		#if [[ $(ls ${IODIR}/*.fastq* | wc -l) -eq 1 ]]; then
		#	spades --12 ${IODIR}/${LIBNAME}.fastq \
		#		--only-assembler --careful -o ${SPADESDIR}		
		#else
		#	spades -1 ${IODIR}/*R1*.fastq* -2 ${IODIR}/*R2*.fastq* \
		#	--only-assembler --careful -o ${SPADESDIR}
		#fi
	else
		echo "Dados analisados previamente..."
	fi
 		IODIR=$SPADESDIR              
}

# Assemble contigs-end-to-end
# Link: https://github.com/ablab/spades
function spades2_bper () {
	if [[ ! -d $SPADES2DIR ]]; then
		mkdir -vp $SPADES2DIR
		echo -e "Executando spades em ${IODIR}...\n"
		# Verifica o número de arquivos em ${IODIR}
		if [[ $(ls ${IODIR}/*.fastq | wc -l) -eq 1 ]]; then
			spades --12 ${IODIR}/${LIBNAME}.fastq \
				--only-assembler --careful -o ${SPADESDIR}		
		else
			spades -1 ${IODIR}/${LIBNAME}_R1.fastq -2 ${IODIR}/${LIBNAME}_R2.fastq \
			--only-assembler --careful -o ${SPADESDIR}
		fi
	else
		echo "Dados analisados previamente..."
	fi
 		IODIR=$SPADES2DIR              
}


#
# Main do script
#

# wf1 - full script
# wf2 - naive assembly with no filtering or correction
# wf3 - method with filtering but without error correction
# wf4 - method with filtering and error correction
# wf5 - tests of parts of the script

# Define as etapas de cada workflow
# Etapas obrigatórios: basecalling, demux/primer_removal ou demux_headcrop, reads_polishing e algum método de classificação taxonômica
WORKFLOWLIST=(
	'qc_bper trim_bper musket_bper flash_bper khmer_bper spades_bper'
	'spades_bper'
	'trim_bper spades_bper'
	'trim_bper musket_bper spades_bper'
	'trim_bper musket_bper flash_bper spades_bper'
	'trim_bper musket_bper khmer_bper spades_bper'
)

# Validação do WF
if [[ $WF -gt ${#WORKFLOWLIST[@]} ]]; then
	echo "Erro: Workflow não definido!"
	exit 4
fi

# Execução das análises propriamente ditas a partir do workflow selecionado
echo -e "\nExecutando o workflow WF$WF..."

# Índice para o array workflowList 0..n
INDICE=$(expr $WF - 1)
echo "Passos do WF$WF: ${WORKFLOWLIST[$INDICE]}"

# Separa cada etapa do workflow no vetor steps
read -r -a STEPS <<< "${WORKFLOWLIST[$INDICE]}"
for CALL_FUNC in ${STEPS[@]}; do
	echo -e "\nExecutando o passo $CALL_FUNC... "
	eval $CALL_FUNC
done
exit 4
