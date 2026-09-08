#!/bin/bash

#SBATCH --partition=short
#SBATCH --cpus-per-task=1
#SBATCH --mem=2G
#SBATCH --job-name="qiime_import"
#SBATCH --mail-user=user@example.com
#SBATCH --mail-type=END,FAIL

# Import raw FASTQ files into QIIME2

source activate qiime2-amplicon-2024.10

# Import paired-end sequences using a manifest file.
# The manifest file specifies the location of each FASTQ file.

qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.tsv \
  --input-format PairedEndFastqManifestPhred33V2 \
  --output-path qiime2_artifacts/515F-806R_FLS_paired_end.qza

# Generate a summary of sequence quality and read lengths.
# The resulting .qzv file can be viewed with QIIME 2 View.

qiime demux summarize \
  --i-data qiime2_artifacts/515F-806R_FLS_paired_end.qza \
  --o-visualization qiime2_artifacts/515F-806R_FLS_paired_end.qzv