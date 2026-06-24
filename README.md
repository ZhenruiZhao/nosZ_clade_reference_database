# nosZ Clade Reference Database

A comprehensive reference database for the detection and phylogenetic classification of nitrous oxide reductase (`nosZ`) sequences belonging to clades I, II, and III. 

The database contains 11,747 curated nosZ protein sequences, including 5,332 clade I sequences, 6,319 clade II sequences, and 96 clade III sequences.

This repository provides a ready-to-use GraftM package for identifying and classifying `nosZ` sequences from metagenomic reads, assembled contigs, metagenome-assembled genomes (MAGs), and predicted protein sequences.

## Database contents

The repository contains:

* Comprehensive `nosZ` reference protein sequences 
* Multiple-sequence alignment
* Reference phylogenetic tree
* Sequence clade annotations
* Hidden Markov model and DIAMOND search databases
* Ready-to-use GraftM package
* Example scripts for reads-, contig-, and MAG-level analyses

## Installation

We recommend installing GraftM in an independent Conda environment.

```bash
conda create -n graftm \
  -c conda-forge \
  -c bioconda \
  graftm \
  -y

conda activate graftm
```

Check that GraftM was installed successfully:

```bash
graftM --version
```

## Download this database

Clone the repository:

```bash
git clone https://github.com/ZhenruiZhao/nosZ_clade_reference_database.git

cd nosZ_clade_reference_database
```

Set the path to the GraftM package:

```bash
GP=/path/to/nosZ_clade_reference_database/nosZ.gpkg
```

Replace `/path/to/` with the actual location of the downloaded repository.

---

# 1. Paired-end metagenomic reads

This mode is suitable for paired-end shotgun metagenomic or metatranscriptomic reads, such as:

```text
sample1_1.fastq.gz
sample1_2.fastq.gz
sample2_1.fastq.gz
sample2_2.fastq.gz
```

Example batch script:

```bash
#!/bin/bash

INDIR=/path/to/fastq
OUTDIR=/path/to/graftm_reads_output
GP=/path/to/nosZ.gpkg
THREADS=20

mkdir -p "$OUTDIR"

for f1 in "$INDIR"/*_1.fastq.gz
do
    base=$(basename "$f1" _1.fastq.gz)
    f2="$INDIR/${base}_2.fastq.gz"

    if [[ ! -f "$f2" ]]; then
        echo "Reverse read not found: $f2" >&2
        continue
    fi

    graftM graft \
      --graftm_package "$GP" \
      --forward "$f1" \
      --reverse "$f2" \
      --input_sequence_type nucleotide \
      --search_method diamond \
      --evalue 1e-5 \
      --threads "$THREADS" \
      --output_directory "$OUTDIR/$base"
done
```

Important parameters:

* `--forward`: forward reads
* `--reverse`: reverse reads
* `--input_sequence_type nucleotide`: input sequences are nucleotides
* `--search_method diamond`: use the DIAMOND search database included in the package, you can also use hmmsearch, diamond, or hmmsearch+diamond
* `--evalue 1e-5`: sequence-search significance threshold
* `--threads`: number of CPU threads
* `--output_directory`: output directory for each sample

## Single-end reads or assembled reads

For single-end sequencing data or assembled reads, omit `--reverse`:

```bash
graftM graft \
  --graftm_package "$GP" \
  --forward sample.fastq.gz \
  --input_sequence_type nucleotide \
  --search_method diamond \
  --evalue 1e-5 \
  --threads 20 \
  --output_directory sample_graftm
```


# 2. Assembled contigs in nucleotide format

This mode can be used for assembled metagenomic contigs in nucleotide FASTA format.

Example input:

```text
sample1.contigs.fa
sample2.contigs.fa
```

Batch analysis:

```bash
#!/bin/bash

INDIR=/path/to/contigs
OUTDIR=/path/to/graftm_contig_output
GP=/path/to/nosZ.gpkg
THREADS=20

mkdir -p "$OUTDIR"

for fasta in "$INDIR"/*.fa
do
    base=$(basename "$fasta" .fa)

    graftM graft \
      --graftm_package "$GP" \
      --forward "$fasta" \
      --input_sequence_type nucleotide \
      --search_method diamond \
      --evalue 1e-5 \
      --threads "$THREADS" \
      --output_directory "$OUTDIR/$base"
done
```

For files ending in `.fasta`, modify the loop accordingly:

```bash
for fasta in "$INDIR"/*.fasta
```

Although nucleotide contigs can be analyzed directly, protein-level analysis is generally recommended for assembled contigs and MAGs.

---

# 3. MAG nucleotide sequences

A MAG is normally stored as a nucleotide FASTA file containing multiple contigs.

Example:

```text
MAG001.fa
MAG002.fa
MAG003.fa
```

MAG nucleotide sequences can be analyzed using the same settings as assembled contigs:

```bash
#!/bin/bash

INDIR=/path/to/MAGs
OUTDIR=/path/to/graftm_mag_nucleotide_output
GP=/path/to/nosZ.gpkg
THREADS=20

mkdir -p "$OUTDIR"

for mag in "$INDIR"/*.fa
do
    base=$(basename "$mag" .fa)

    graftM graft \
      --graftm_package "$GP" \
      --forward "$mag" \
      --input_sequence_type nucleotide \
      --search_method diamond \
      --evalue 1e-5 \
      --threads "$THREADS" \
      --output_directory "$OUTDIR/$base"
done
```

However, for MAG-level analysis, we recommend predicting protein-coding genes first and then searching the predicted protein sequences.

---

# 4. Predicted proteins from contigs or MAGs

This is the recommended approach for contig- and MAG-level `nosZ` detection.

First, predict proteins using Prodigal.

## Protein prediction for individual MAGs

```bash
mkdir -p predicted_proteins

for mag in /path/to/MAGs/*.fa
do
    base=$(basename "$mag" .fa)

    prodigal \
      -i "$mag" \
      -a "predicted_proteins/${base}.faa" \
      -d "predicted_proteins/${base}.fna" \
      -o "predicted_proteins/${base}.gff" \
      -f gff \
      -p single
done
```

For individual MAGs, `-p single` is generally appropriate.

## Protein prediction for metagenomic contigs

```bash
prodigal \
  -i sample.contigs.fa \
  -a sample.orf.faa \
  -d sample.orf.fna \
  -o sample.orf.gff \
  -f gff \
  -p meta
```

For complex metagenomic assemblies, use `-p meta`.

## GraftM analysis of predicted proteins

```bash
#!/bin/bash

INDIR=/path/to/predicted_proteins
OUTDIR=/path/to/graftm_protein_output
GP=/path/to/nosZ.gpkg
THREADS=20

mkdir -p "$OUTDIR"

for faa in "$INDIR"/*.faa
do
    base=$(basename "$faa" .faa)

    graftM graft \
      --graftm_package "$GP" \
      --forward "$faa" \
      --input_sequence_type aminoacid \
      --search_method diamond \
      --evalue 1e-5 \
      --threads "$THREADS" \
      --output_directory "$OUTDIR/$base"
done
```

For gzip-compressed protein FASTA files:

```bash
for faa in "$INDIR"/*.faa.gz
do
    base=$(basename "$faa" .faa.gz)

    graftM graft \
      --graftm_package "$GP" \
      --forward "$faa" \
      --input_sequence_type aminoacid \
      --search_method diamond \
      --evalue 1e-5 \
      --threads "$THREADS" \
      --output_directory "$OUTDIR/$base"
done
```

---

# Recommended workflow by input type

| Input data              | Input format   | GraftM input type | Recommended workflow          |
| ----------------------- | -------------- | ----------------- | ----------------------------- |
| Paired-end reads        | FASTQ/FASTQ.GZ | `nucleotide`      | Analyze paired reads directly |
| Single-end reads        | FASTQ/FASTQ.GZ | `nucleotide`      | Analyze reads directly        |
| Metagenomic contigs     | FASTA          | `nucleotide`      | Direct analysis is possible   |
| Metagenomic contigs     | Predicted FAA  | `aminoacid`       | Recommended                   |
| MAG contigs             | FASTA          | `nucleotide`      | Direct analysis is possible   |
| MAG proteins            | Predicted FAA  | `aminoacid`       | Recommended                   |
| Isolate genome proteins | FAA            | `aminoacid`       | Recommended                   |

---

# Output files

Each sample is written to an independent GraftM output directory.

Example:

```text
graftm_reads_output/
├── sample1/
├── sample2/
└── sample3/
```

The exact files generated may depend on the installed GraftM version and package configuration. Output directories generally contain:

* Sequences matching the `nosZ` reference package
* Taxonomic or clade assignments
* Phylogenetic placement results
* Search and classification intermediate files
* Run logs

Users should inspect the output directory and the GraftM log file before downstream analysis.

---

# Counting nosZ sequences

The number of detected sequences should not be interpreted as gene abundance without considering sequencing depth.

For read-level comparisons among samples, sequence counts can be normalized as reads per million:

```text
RPM = nosZ-assigned reads / total reads × 1,000,000
```

For contig- or MAG-level analyses, detections are usually summarized as:

* Presence or absence of `nosZ`
* Number of `nosZ` genes per MAG
* Assignment to clade I, II, or III
* Taxonomic identity of the corresponding MAG
* Genomic context surrounding the detected `nosZ` gene

---

# Important notes

1. Sequence identifiers should not contain spaces or inconsistent special characters.

2. Keep sequence identifiers consistent among reference sequences, alignments, phylogenetic trees, and taxonomy files.

3. Use a separate output directory for every sample.

4. Do not mix nucleotide and amino-acid sequences in the same GraftM run.

5. For MAG and contig analyses, inspect candidate `nosZ` proteins for sequence completeness, conserved motifs, and phylogenetic placement.

6. A GraftM assignment should be interpreted together with sequence quality and phylogenetic evidence, particularly for divergent `nosZ` clades.

---

# Scripts for abundance analysis
summary.sh summarizes the numbers of reads assigned to nosZ clades I, II, and III from GraftM outputs, while calculate_rpm.py normalizes these counts to reads per million total metagenomic reads using sequence counts generated by SeqKit.


# Citation

If you use this database, please cite the GraftM software and the associated nosZ database publication.

Database citation information will be updated after publication.

## GraftM

Boyd JA, Woodcroft BJ, Tyson GW. GraftM: a tool for scalable, phylogenetically informed classification of genes within metagenomes. *Nucleic Acids Research*. 2018;46(10):e59.

---

# Database version

Current version: `v1.0.0`

Release date: 2026-06-24

Future releases may include:

* Additional reference sequences
* Updated taxonomy
* Improved clade assignments
* Updated phylogenetic trees
* Revised GraftM packages

---

# Contact

Zhenrui Zhao

zhaozhr@mail2.sysu.edu.cn

Marine Synthetic Ecology Research Center, Southern Marine Science and Engineering Guangdong Laboratory (Zhuhai), School of Marine Sciences, Sun Yat-sen University, Zhuhai 519082, China

Questions, bug reports, and suggestions can be submitted through GitHub Issues.
