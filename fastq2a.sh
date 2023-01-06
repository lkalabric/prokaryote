FILENAME=`echo "$1" | cut -d'.' -f1`

sed -n '1~4s/^@/>/p;2~4p' "${FILENAME}.fastq" > "${FILENAME}.fasta"
