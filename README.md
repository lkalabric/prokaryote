# prokaryote.sh

This project aims to implement the bioinformatics workflow described in Genomic sequencing of Bordetella pertussis for epidemiology and global surveillance by Bouchez et al. (2018) (Available at DOI: https://doi.org/10.3201/eid2406.171464)


Wetlab:
Isolates of B. pertussis were sequenced paired-ends in a Illumina plataform

Bioinfo:
For de novo assembly, paired-end reads were clipped and trimmed with AlienTrimmer (1), corrected with Musket (2), merged (if needed) with FLASH (3), and subjected to a digital
normalization procedure with khmer (4). For each sample, the remaining processed reads were assembled and scaffolded with SPAdes (5).
Note: Here, we replaced AlienTrimmer with Trimmomatic just because we are more familiar with this tool. The remaining steps are exactly the way they were proposed by the authors.

Step 0 - Quality control report using Fasqc
This step was intended to evaluate the sequencing it self and obtain two parameters: minlen and qc

Step 1 - Clip and trim reads using Trimmomatic
This step basically filtered out reads with mean base quality below our cut-off (qc < 20) using an sliding window strategy of 4 bases and removed short reads (minlen < 35). This step generates up to four files: two paired-end files with both surviving reads, one forward suviving reads only and one reverse suviving reads only.

Step 2 - Erro correction using Musket (http://dx.doi.org/10.1093/bioinformatics/bts690)

Step 3 - Merge R1 to R2 to extend read lengths

Step 4 - Digital normalization

Step 5 - Assembly itself
