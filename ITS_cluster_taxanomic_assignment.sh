#!/bin/bash

#SBATCH --partition=medium
#SBATCH --cpus-per-task=2
#SBATCH --mem=40G
#SBATCH --job-name="clasITS"
#SBATCH --mail-user=user@example.com 
#SBATCH --mail-type=END,FAIL 

source activate qiime2-amplicon-2024.10

### cluster
qiime vsearch cluster-features-de-novo \
--i-table ITS_paired_end_cutadapt_itsexpress_dada2_table.qza \
--i-sequences ITS_paired_end_cutadapt_itsexpress_dada2_rep_seq.qza \
--p-perc-identity 0.975 \
--o-clustered-table ITS_paired_end_cutadapt_itsexpress_dada2_table_clustered.qza \
--o-clustered-sequences ITS_paired_end_cutadapt_itsexpress_dada2_rep_seq_clustered.qza

### assign taxa
qiime feature-classifier classify-sklearn \
--i-classifier unite-classifier-ver10-dynamic-19.02.2025-qiime.202xxxx.qza \
--i-reads ITS_paired_end_cutadapt_itsexpress_dada2_rep_seq_clustered.qza \
--o-classification ITS_paired_end_cutadapt_itsexpress_dada2_rep_seq_clustered_taxo_results.qza

### output a taxa and rep seq table

qiime metadata tabulate \
--m-input-file ITS_paired_end_cutadapt_itsexpress_dada2_rep_seq_clustered_taxo_results.qza \
--m-input-file ITS_paired_end_cutadapt_itsexpress_dada2_rep_seq_clustered.qza \
--o-visualization ITS_paired_end_cutadapt_itsexpress_dada2_clustered_tabulated-taxonomy-seqs.qzv

### abundance table output

qiime tools export \
 --input-path tp_bacteria_280_table_clustered.qza \
 --output-path tp_bacteria_280_table

biom convert \
 -i tp_bacteria_280_table/feature-table.biom \
 -o tp_bacteria_280_table/feature-table.tsv \
 --to-tsv

qiime tools export \
 --input-path tp_bacteria_280_taxonomy_results_clustered.qza \
 --output-path tp_bacteria_280_taxonomy

# move into taxonomy directory so paths are safe
cd tp_bacteria_280_taxonomy

awk 'BEGIN{FS=OFS="\t"} NR==1{print "#OTUID","taxonomy"} NR>1{print $1,$2}' taxonomy.tsv > taxonomy_biom.tsv

cd ..

biom add-metadata \
 -i tp_bacteria_280_table/feature-table.biom \
 -o tp_bacteria_280_table/feature-table-tax.biom \
 --observation-metadata-fp tp_bacteria_280_taxonomy/taxonomy_biom.tsv \
 --sc-separated taxonomy

biom convert \
 -i tp_bacteria_280_table/feature-table-tax.biom \
 -o tp_bacteria_280_table/feature-table-tax.tsv \
 --to-tsv \
 --header-key taxonomy
