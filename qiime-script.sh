#!/bin/bash

# qiime-script.sh
# Workflow de bioinformática para análise de B pertussis
# Autor: Luciano Kalabric & Viviane Ferreira
# Objetivo: 
# Controle de versão: Incluir o log das próximas atualizações aqui
# Versão 1.0 de 07 DEZ 2022 - Programa inicial revisado

# Requirements: bbmap, fastqc, conda, trimmomatic, musket, flash, khmer, spades

# Import data into qiime2
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path data/manifest-file.tsv \
  --output-path ngs-analysis/prokariote/paired-end-sequences.qza \
  --input-format PairedEndFastqManifestPhred33V2

# Import reference sequences
qiime tools import \
  --input-path $HOME/data/QIIME/sequences.fna \
  --output-path $HOME/ngs-analysis/prokariote/sequences.qza \
  --type 'FeatureData[Sequence]'

# Import reference taxonomy file
# qiime tools import \
#  --type 'FeatureData[Taxonomy]' \
#  --input-format HeaderlessTSVTaxonomyFormat \
#  --input-path 85_otu_taxonomy.txt \
#  --output-path ngs-analysis/prokariote/ref-taxonomy.qza
# Alternativamente, download de http://https://docs.qiime2.org/2022.11/data-resources/ # Não funcionou

# Taxonomical classification
qiime feature-classifier classify-consensus-blast \
  --i-query $HOME/ngs-analysis/prokariote/paired-end-sequences.qza \ # Erro no formato de importação
  --i-reference-reads $HOME/ngs-analysis/prokariote/sequences.qza \
  --i-reference-taxonomy $HOME/data/QIIME/silva-138-99-nb-classifier.qza \ # Erro no formato de importação
  --o-classification FeatureData[Taxonomy] \
  --o-search-results FeatureData[BLAST6] \
  --output-dir $HOME/ngs-analysis/prokariote/teste
