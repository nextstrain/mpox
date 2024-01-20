# Nextstrain repository for mpox virus

[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/nextstrain/mpox/master.svg)](https://results.pre-commit.ci/latest/github/nextstrain/mpox/master)

This repository contains three workflows for the analysis of mpox virus (MPXV) data:

- [`ingest/`](./ingest) - Download data from GenBank, clean and curate it and upload it to S3
- [`phylogenetic/`](./phylogenetic) - Filter sequences, align, construct phylogeny and export for visualization
- [`nextclade/`](./nextclade) - Make Nextclade datasets for nextstrain/nextclade_data

Each folder contains a README.md with more information. The results of running both workflows are publicly visible at [nextstrain.org/mpox](https://nextstrain.org/mpox).

## Installation

Follow the [standard installation instructions](https://docs.nextstrain.org/en/latest/install.html) for Nextstrain's suite of software tools.

## Quickstart

Run the default phylogenetic workflow via:
```
cd phylogenetic/
nextstrain build .
nextstrain view .
```

## Documentation

- [Running a pathogen workflow](https://docs.nextstrain.org/en/latest/tutorials/running-a-workflow.html)
- [Contributor documentation](./CONTRIBUTING.md)
