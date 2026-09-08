#!/bin/bash

#SBATCH --partition=medium
#SBATCH --cpus-per-task=1
#SBATCH --mem=45G
#SBATCH --job-name="16s.taxo"
#SBATCH --mail-user=user@example.com
#SBATCH --mail-type=END,FAIL

source activate qiime2-amplicon-2024.10

#Classifier reads in rep-seq file usign trained database and output is the taxa results.
#classifeier must be either trained using the classifier_pipeline.sh pipeline or downloaded from the qiime2 resources page. 

qiime feature-classifier classify-sklearn \
--i-classifier databases/silva-138-99-2024.10-515f-806r-classifier-extracted.qza \
--i-reads qiime2_artifacts/515F-806R_FLS_235_rep-seqs.qza \
--o-classification qiime2_artifacts/515F-806R_FLS_235_taxonomy_results.qza

#examin the output
#515F-806R_FLS_235_table
qiime metadata tabulate \
--m-input-file qiime2_artifacts/515F-806R_FLS_235_taxonomy_results.qza \
--o-visualization qiime2_artifacts/515F-806R_FLS_235_taxonomy_results_visualisation_tabulate.qzv

#taxa bar plot based on taxonomic "levels" and add on any metadata you have in a tsv format

qiime taxa barplot \
--m-metadata-file FLS-515F-806R-metadata.tsv \
--i-table qiime2_artifacts/515F-806R_FLS_235_table.qza \
--i-taxonomy qiime2_artifacts/515F-806R_FLS_235_taxonomy_results.qza \
--o-visualization qiime2_artifacts/515F-806R_FLS_235_taxa_bar_plots.qzv

qiime metadata tabulate \
--m-input-file qiime2_artifacts/515F-806R_FLS_235_taxonomy_results.qza \
--m-input-file qiime2_artifacts/515F-806R_FLS_235_rep-seqs.qza \
--o-visualization qiime2_artifacts/515F-806R_FLS_235_tabulated-taxonomy-seqs.qzv

qiime tools export \
--input-path qiime2_artifacts/515F-806R_FLS_235_table.qza \
--output-path qiime2_artifacts/515F-806R_FLS_abundance_table

biom convert -i qiime2_artifacts/515F-806R_FLS_abundance_table/feature-table.biom \
-o qiime2_artifacts/515F-806R_FLS_abundance_table/feature-table.tsv --to-tsv

#place the below qzv file into qiime2 view website and download the tsv file 

qiime metadata tabulate \
--m-input-file qiime2_artifacts/515F-806R_FLS_235_rep-seqs.qza \
--m-input-file qiime2_artifacts/515F-806R_FLS_235_taxonomy_results.qza \
--o-visualization qiime2_artifacts/515F-806R_FLS_235_rep_seq_taxa_results_combind.qzv

