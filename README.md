# Below Ground Microbiome

Qiime2 pipelines for 16s rDNA, 18s rDNA and ITS2 soil analysis.
This repository contains QIIME2 workflows for processing and taxonomically classifying amplicon sequencing data from 16S rRNA, 18S rRNA, and ITS2 markers. This repository is not owned or run by the developers of QIIME2. 

The pipelines follow three core stages:

1. Import sequencing data using a manifest file
2. Denoise reads using Cutadapt and DADA2
3. Assign taxonomy using reference databases

Detailed commands for each marker-specific workflow can be found in the scripts provided in this repository. Below is an overview of the process
```
Raw FASTQ files
       │
       ▼
1. Import (Manifest)
       │
       ▼
2. Denoising
   ├── Cutadapt
   └── DADA2
       │
       ▼
3. Taxonomic Classification
       │
       ▼
Feature Table + Representative Sequences + Taxonomy

```
# Import
Raw sequencing data are imported into QIIME2 using a manifest file that maps sample identifiers to paired-end FASTQ files. Manifests are tab separated files showing where your raw demultiplexed data is.
Manifests look like this example:
```
sample-id	forward-absolute-filepath	reverse-absolute-filepath
SampleA	/home/soil-ecology/upland_data/raw/P02-F04-JHI-12-SampleA_R1.fastq.gz	/home/soil-ecology/upland_data/raw/P02-F04-JHI-12-SampleA_R2.fastq.gz
SampleB	/home/soil-ecology/upland_data/raw/P03-G01-JHI-13-SampleB_R1.fastq.gz	/home/soil-ecology/upland_data/raw/P03-G01-JHI-13-SampleB_R2.fastq.gz
SampleC	/home/soil-ecology/upland_data/raw/P03-G08-JHI-13-SampleC_R1.fastq.gz	/home/soil-ecology/upland_data/raw/P03-G08-JHI-13-SampleC_R2.fastq.gz
SampleD	/home/soil-ecology/upland_data/raw/P03-C01-JHI-13-SampleD_R1.fastq.gz	/home/soil-ecology/upland_data/raw/P03-C01-JHI-13-SampleD_R2.fastq.gz
SampleE	/home/soil-ecology/upland_data/raw/P01-G03-JHI-11-SampleE_R1.fastq.gz	/home/soil-ecology/upland_data/raw/P01-G03-JHI-11-SampleE_R2.fastq.gz
SampleF	/home/soil-ecology/upland_data/raw/P04-G04-JHI-14-SampleF_R1.fastq.gz	/home/soil-ecology/upland_data/raw/P04-G04-JHI-14-SampleF_R2.fastq.gz
SampleG	/home/soil-ecology/upland_data/raw/P04-H02-JHI-14-SampleG_R1.fastq.gz	/home/soil-ecology/upland_data/raw/P04-H02-JHI-14-SampleG_R2.fastq.gz
```
You then use this file to import the data into QIIME2, and create a visualisation to inspect read quality profiles and length distributions of your sequence data. :
```
qiime tools import \
  --type 'SampleData[PairedEndSequencesWithQuality]' \
  --input-path manifest.tsv \
  --input-format PairedEndFastqManifestPhred33V2 \
  --output-path paired-end-data.qza

qiime demux summarize \
  --i-data paired-end-data \
  --o-visualization paired-end-data-summary.qzv
```
The .qzv file output called paired-end-data-summary.qzv can be view at [QIIME 2 View](https://view.qiime2.org/).
This information informs the trimming or truncation steps in denoising. 

# Denoising and Quality filtering
Sequence denosing and quality filtering happens in two steps.
1. Primer removal
2. Sequence denoising

## Primer removal
PCR primers are removed from the sequences, this is important for denoising, downstream taxonomic assignment and discarding reads that lack the unexpected primer region. We do this with cutadapt trim paired, as we have paired end read data. You insert your primer sequence into this command:

```
qiime cutadapt trim-paired \
--i-demultiplexed-sequences paired-end-data.qza \
--p-front-f GTGYCAGCMGCCGCGGTAA \
--p-front-r GGACTACNVGGGTWTCTAAT \
--o-trimmed-sequences paired-end-data-cutadapt.qza
```
## Denoising loop
Truncation (which is trimming all reads to a length and discarding any reads below that length) values are chosen based on the quality profiles observed in the paired-end-data-summary.qzv output viewed earlier in QIIME2 view. Rather than choosing a single value, it is best to test several values around the point where sequence quality began to decline in your graph.

For example, if quality scores begin to drop at approximately 220-240 bases, multiple truncation length values can be examined to identify the best fit for the data regarding read retention, quality filtering, and successful read merging. We can do this with a bash loop, it will run each value and then produce multiple outputs for you to examine.
```
# Example truncation lengths selected based on quality plots
trunc_lengths=(220 225 230 235 240)

for trunc_len in "${trunc_lengths[@]}"
do
    qiime dada2 denoise-paired \
        --i-demultiplexed-seqs paired-end-cutadapt.qza \
        --p-trunc-len-f "$trunc_len" \
        --p-trunc-len-r "$trunc_len" \
        --o-table "${trunc_len}_table.qza" \
        --o-representative-sequences "${trunc_len}_rep-seqs.qza" \
        --o-denoising-stats "${trunc_len}_denoising-stats.qza"

    qiime metadata tabulate \
        --m-input-file "${trunc_len}_denoising-stats.qza" \
        --o-visualization "${trunc_len}_denoising-stats-viz.qzv"
done

```
The best fit for the data will vary between sequencing runs, markers (16S, 18S, ITS2), and datasets, so parameter evaluation should be performed for each project. For more information and tips on denoising see [QIIME 2 documentation](https://docs.qiime2.org/). 
Compare each of the .qzv files `{trunc_len}_denoising-stats-viz.qzv` at [QIIME 2 View](https://view.qiime2.org/).
You are looking for the best read retention, sucessful merging, and sufficient depth for your marker. 

# Taxonomic Classification

The representative sequences you keep after denoising are then read for taxonomic assignment. 
You need to pick a database, train it into a classifier and then use that classifier to assign taxonomy. 

There are multiple database for these markers:

| Marker | Common Databases |
|---------|------------------|
| 16S | SILVA, GTDB, Greengenes2 |
| 18S | SILVA, BOLD |
| ITS2 | UNITE, BOLD |

In this example we will train Silva for 16s. You can download a the database at the [silva website]([https://www.arb-silva.de/current-release/QIIME2/2026.7/SSU](https://www.arb-silva.de/documentation/release-144)). The reference sequences needs to be imported, then trimmed to match the amplicon region generated by your primers. The trimmed reference sequences and associated taxonomy can then be used to train a Naive Bayes classifier in QIIME2.

Import the sequences and the text document taxonomy like this:
```
qiime tools import \
  --type 'FeatureData[Sequence]' \
  --input-path SILVA_144_SSURef_NR99_tax_silva_trunc.fasta \
  --output-path SILVA_144_seqs.qza

qiime tools import \
  --type 'FeatureData[Taxonomy]' \
  --input-format HeaderlessTSVTaxonomyFormat \
  --input-path tax_slv_ssu_144.txt.gz \
  --output-path slv-ssu-144-taxonomy.qza
```
Then we extract the primer region:
```
qiime feature-classifier extract-reads \
  --i-sequences SILVA_144_seqs.qza \
  --p-f-primer CCTACGGGNGGCWGCAG \
  --p-r-primer GACTACHVGGGTATCTAATCC \
  --o-reads SILVA_144_V3V4_primer-extracted.qza

```
And train the classifier:

```
qiime feature-classifier fit-classifier-naive-bayes \
  --i-reference-reads SILVA_144_V3V4_ref-seqs.qza \
  --i-reference-taxonomy slv-ssu-144-taxonomy.qza \
  --o-classifier SILVA_144_V3V4_classifier.qza
```
Now we are ready to cluster our reads into OTUs using vsearch:
```
qiime vsearch cluster-features-de-novo \
  --i-table table.qza \
  --i-sequences rep-seqs.qza \
  --p-perc-identity 0.97 \
  --o-clustered-table clustered-table.qza \
  --o-clustered-sequences clustered-rep-seqs.qza
```
Classify representative sequences using the trained classifier you made earlier:
```
qiime feature-classifier classify-sklearn \
  --i-classifier SILVA_144_V3V4_classifier.qza \
  --p-n-jobs 10 \
  --p-confidence 0.8 \
  --i-reads clustered-rep-seqs.qza \
  --o-classification taxonomy.qza
```
Export the table with all the metadata and the taxonomic information tagged on at the end for each read ready for downstream analyses. This pipeline seems long but all it's doing is formatting. It is making the table into a biom table, then converting that to a human readable tsv, and attaching the taxonomic information on the end and making that a tsv as well and placing it inside a directory called exported-results.
```
mkdir -p exported-results

qiime tools export \
  --input-path clustered-table.qza \
  --output-path exported-results

biom convert \
  -i exported-results/feature-table.biom \
  -o exported-results/feature-table.tsv \
  --to-tsv

qiime tools export \
  --input-path taxonomy.qza \
  --output-path exported-taxonomy

awk 'BEGIN{FS=OFS="\t"} NR==1{print "#OTUID","taxonomy"} NR>1{print $1,$2}' \
  exported-taxonomy/taxonomy.tsv \
  > exported-taxonomy/taxonomy_biom.tsv

biom add-metadata \
  -i exported-results/feature-table.biom \
  -o exported-results/feature-table-tax.biom \
  --observation-metadata-fp exported-taxonomy/taxonomy_biom.tsv \
  --sc-separated taxonomy

biom convert \
  -i exported-results/feature-table-tax.biom \
  -o exported-results/feature-table-tax.tsv \
  --to-tsv \
  --header-key taxonomy

```
This table output `feature-table-tax.tsv` in exported-results directory produces a taxonomically annotated feature table suitable for downstream ecological analyses, including diversity and community composition analysis.
