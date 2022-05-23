# nextstrain.org/monkeypox

This is the [Nextstrain](https://nextstrain.org) build for monkeypox virus. Output from this build is visible at [nextstrain.org/monkeypox](https://nextstrain.org/monkeypox).

## Usage

Copy input data with:
```
mkdir -p data/
cp -v example_data/* data/
```
Add any additional sequences and metadata in separate fasta or metadata-tsv files to `data`, respectively.

Run pipeline with:
```
nextstrain build --image=nextstrain/base:branch-nextalign-v2 . --configfile=config/config.yaml
```

View results with:
```
nextstrain view auspice/
```

## Configuration

Configuration takes place the `config/config.yml`.
The analysis pipeline is contained in `workflow/snakemake_rule/core.smk`.
This can be read top-to-bottom, each rule specifies its file inputs and output and pulls its parameters from `config`.
There is little redirection and each rule should be able to be reasoned with on its own.

## Input data

### GenBank data

Input data is downloaded from [ViPR Poxviridae resource](https://www.viprbrc.org/brc/home.spg?decorator=pox).
- Subfamily: Chordopoxvirinae
- Genus: Orthopoxvirus
- Species: Monkeypox virus

Download Genome FASTA, select custom format, and choose the following fields in this order:
1. Strain name
2. GenBank accession
3. Country
4. Date
5. Host

This downloads the file `GenomicFastaResults.fasta`. Parse this file into sequences and metadata using:
```
augur parse \
 --sequences example_data/GenomicFastaResults.fasta \
 --fields strain accession date country host \
 --output-sequences example_data/sequences.fasta \
 --output-metadata example_data/metadata.tsv
```

ViPR dates are weird with a format of `2006_12_14`. This needs to be manually corrected to `2006-12-14` via regex.

This data is versioned as `example_data/sequences.fasta`.

### Outbreak data

- [Monkeypox/PT0001/2022](https://virological.org/t/first-draft-genome-sequence-of-monkeypox-virus-associated-with-the-suspected-multi-country-outbreak-may-2022-confirmed-case-in-portugal/799)
- [ITM_MPX_1_Belgium](https://virological.org/t/belgian-case-of-monkeypox-virus-linked-to-outbreak-in-portugal/801)
- [MPXV_USA_2022_MA001](https://www.ncbi.nlm.nih.gov/nuccore/ON563414)

has been saved to `example_data/outbreak.fasta`.

### Data preparation

Move metadata to `data/`:
```
cp example_data/metadata.tsv data/metadata.tsv
```

Move and append sequences to `data/`
```
cat example_data/sequences.fasta example_data/outbreak.fasta > data/sequences.fasta
```

### Data use

We gratefully acknowledge the authors, originating and submitting laboratories of the genetic
sequences and metadata for sharing their work. Please note that although data generators have
generously shared data in an open fashion, that does not mean there should be free license to
publish on this data. Data generators should be cited where possible and collaborations should be
sought in some circumstances. Please try to avoid scooping someone else's work. Reach out if
uncertain.

## Installation

Follow the [standard installation instructions](https://docs.nextstrain.org/en/latest/install.html) for Nextstrain's suite of software tools.
Please choose the installation method for your operating system which uses Docker, as currently a pre-release version of Nextalign is required which we've baked into the `--image` argument to `nextstrain build` above.
