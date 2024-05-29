

for input_file_1 in /home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_*_R1_001.fastq.gz; do 
    if [[ "$input_file_1" =~ ^(/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_02N_S83_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_02T_S84_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_11N_S85_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_11T_S86_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_13N_S87_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_13T_S88_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_14N_S89_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_14T_S90_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_15N_S91_R1_001.fastq.gz|/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/AS_15T_S92_R1_001.fastq.gz)$ ]]; then
        base_name=$(basename "$input_file_1" _R1_001.fastq.gz) 
        input_file_2="/home/LabNAS/SHARE/ASC_rawdata/NGS1120957/${base_name}_R2_001.fastq.gz" 
        cp "${input_file_1}" .
        cp "${input_file_2}" .
        cutadapt -a AGATCGGAAGAG -A AGATCGGAAGAG -o "${base_name}_R1_trimmed.fastq" -p "${base_name}_R2_trimmed.fastq" -m 20 -j 16 -q 10 "${base_name}_R1_001.fastq.gz" "${base_name}_R2_001.fastq.gz" > "${base_name}trim_log.txt"
        rm -f "${base_name}_R1_001.fastq.gz" 
        rm -f "${base_name}_R2_001.fastq.gz"
        # Run bwa-mem2
        bwa-mem2 mem -R "@RG\tID:${base_name}\tSM:${base_name}\tPL:ILLUMINA" -t 20 /home/sealight1999/references/GRCH38/GRCh38_no_alt.fna "${base_name}_R1_trimmed.fastq" "${base_name}_R2_trimmed.fastq" | samtools view -b -o "${base_name}_output.bam" -@ 20 
        rm "${base_name}_R1_trimmed.fastq"
        rm "${base_name}_R2_trimmed.fastq"
        samtools sort -o "${base_name}_sorted.bam" "${base_name}_output.bam"
        rm "${base_name}_output.bam"
        samtools index "${base_name}_sorted.bam" 
        samtools flagstat -@ 20 "${base_name}_sorted.bam" > "${base_name}_mapping_rate_human.txt"
        picard MarkDuplicates I="${base_name}_sorted.bam" O="${base_name}_du.bam" M="${base_name}_du_matrix.txt" CREATE_INDEX=true > "${base_name}_picard_markdup.log" 2>&1
        if [ $? -eq 0 ]; then
          message="${base_name} finished successfully."
        else
          message="${base_name} job failed."
        fi
    
        # Call the Python script to send a notification
        python3 /home/sealight1999/telegram_bot.py "$message"
   fi
done
  
