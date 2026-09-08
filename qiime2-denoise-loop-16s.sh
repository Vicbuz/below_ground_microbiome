#!/bin/bash

#SBATCH --partition=long
#SBATCH --cpus-per-task=1
#SBATCH --mem=10G
#SBATCH --job-name="FLS16denoise"
#SBATCH --mail-user=Victoria.Buswell@hutton.ac.uk
#SBATCH --mail-type=END,FAIL

#read raw fastq into qiime2  

source activate qiime2-amplicon-2024.10

#cutadapt remove adapters
# echo "Trimming 16s adapters with cutadapt"
# --p-front-f is your forward adapter and --p-front-r is the reverse

qiime cutadapt trim-paired \
--i-demultiplexed-sequences qiime2_artifacts/515F-806R_FLS_paired_end.qza \
--p-front-f GTGCCAGCMGCCGCGGTAA \
--p-front-r GGACTACHVGGGTWTCTAAT \
--o-trimmed-sequences qiime2_artifacts/515F-806R_FLS_paired_end_read_cutadapt.qza

#this command below will giove you a visulation output you can place into the qiime2 view website

qiime demux summarize \
--i-data qiime2_artifacts/515F-806R_FLS_paired_end_read_cutadapt.qza \
--o-visualization qiime2_artifacts/515F-806R_FLS_paired_end_read_cutadapt.qzv

#denoise in a loop max read length is 300. so work down from that, this will allow you to find the best fit for the dataset. 
echo "denoising 16s data with dada2 using a loop of values"

#edit this list of numbers for your truncation values
length_set=(240 235 230)

for len in "${length_set[@]}"
do
    echo " DENOISING WITH $len DENOISING WITH $len DENOISING WITH $len"

	qiime dada2 denoise-paired \
	--i-demultiplexed-seqs qiime2_artifacts/515F-806R_FLS_paired_end.qza \
	--p-trunc-len-f $len \
	--p-trunc-len-r $len \
	--o-table "qiime2_artifacts/515F-806R_FLS_${len}_table.qza" \
	--o-representative-sequences "qiime2_artifacts/515F-806R_FLS_${len}_rep-seqs.qza" \
	--o-denoising-stats "qiime2_artifacts/515F-806R_FLS_${len}_denoising-stats.qza" \
	--verbose

	qiime metadata tabulate \
	--m-input-file "qiime2_artifacts/515F-806R_FLS_${len}_denoising-stats.qza" \
	--o-visualization "qiime2_artifacts/515F-806R_FLS_${len}_denoising-stats.qzv"

done

