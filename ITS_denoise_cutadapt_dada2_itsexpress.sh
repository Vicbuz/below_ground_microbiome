#!/bin/bash

#SBATCH --partition=medium 
#SBATCH --cpus-per-task=1 
#SBATCH --mem=3G 
#SBATCH --job-name="ITSdenoise" 
#SBATCH --mail-user=user@example.com 
#SBATCH --mail-type=END,FAIL 

source activate qiime2-amplicon-2024.10

#fITS7	GTGARTCATCGAATCTTTG
#ITS4	TCCTCCGCTTATTGATATGC

qiime cutadapt trim-paired \
--i-demultiplexed-sequences ITS_paired_end.qza \
--p-front-f GTGARTCATCGAATCTTTG \
--p-front-r TCCTCCGCTTATTGATATGC \
--verbose \
--o-trimmed-sequences ITS_paired_end_cutadapt.qza 

qiime itsxpress trim-pair-output-unmerged \
--i-per-sample-sequences ITS_paired_end_cutadapt.qza \
--p-region ITS2 \
--p-taxa F \
--p-cluster-id 1.0 \
--o-trimmed ITS_paired_end_cutadapt_itsexpress.qza

qiime dada2 denoise-paired \
--i-demultiplexed-seqs ITS_paired_end_cutadapt_itsexpress.qza \
--p-trunc-len-f 0 \
--p-trunc-len-r 0 \
--o-table ITS_paired_end_cutadapt_itsexpress_dada2_table.qza \
--o-representative-sequences ITS_paired_end_cutadapt_itsexpress_dada2_rep_seq.qza \
--o-denoising-stats ITS_paired_end_cutadapt_itsexpress_dada2_denoise.qza

qiime metadata tabulate \
--m-input-file ITS_paired_end_cutadapt_itsexpress_dada2_denoise.qza \
--o-visualization ITS_paired_end_cutadapt_itsexpress_dada2_denoise_stats.qzv
