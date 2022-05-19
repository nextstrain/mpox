# nextstrain.org/monkeypox

This is the [Nextstrain](https://nextstrain.org) build for monkeypox virus. This build is currently
work-in-progress and is not yet publicly visible.

## Usage

Copy input data with:
```
mkdir -p data/
cp -v example_data/* data/
```

Run pipeline with:
```
snakemake -j 1 -p
```
or with:
```
nextstrain build .
```

View results with:
```
auspice view --datasetDir auspice/
```
or with:
```
nextstrain view auspice/
```

## Configuration

Configuration takes place entirely with the `Snakefile`. This can be read top-to-bottom, each rule
specifies its file inputs and output and also its parameters. There is little redirection and each
rule should be able to be reasoned with on its own.

## Input data

Input data is downloaded from [ViPR Poxviridae resource](https://www.viprbrc.org/brc/home.spg?decorator=pox).
- Subfamily: Chordopoxvirinae
- Genus: Orthopoxvirus
- Species: Monkeypox virus

Download Genome FASTA, select custom format, and select all fields:
1. GenBank accession
2. Strain name
3. Segment
4. Date
5. Host
6. Country
7. Subtype
8. Virus Species

This downloads the file `GenomicFastaResults.fasta`. Parse this file into sequences and metadata using:
```
augur parse \
 --sequences example_data/GenomicFastaResults.fasta \
 --fields acession strain segment date host country subtype species \
 --output-sequences sequences.fasta \
 --output-metadata metadata.tsv
```

ViPR dates are weird with a format of `2006_12_14`. This needs to be manually corrected to `2006-12-14` via regex.

This data is versioned on `example_data/`. The first step in the workflow is to copy `example_data/` to `data/` via:
```
mkdir -p data/
cp -v example_data/* data/
```

Data from GenBank follows Open Data principles, such that we can make input data and intermediate
files available for further analysis. Open Data is data that can be freely used, re-used and
redistributed by anyone - subject only, at most, to the requirement to attribute and sharealike.

We gratefully acknowledge the authors, originating and submitting laboratories of the genetic
sequences and metadata for sharing their work in open databases. Please note that although data
generators have generously shared data in an open fashion, that does not mean there should be free
license to publish on this data. Data generators should be cited where possible and collaborations
should be sought in some circumstances. Please try to avoid scooping someone else's work. Reach out
if uncertain. Authors, paper references (where available) and links to GenBank entries are provided
in the metadata file.
