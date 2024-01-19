# Nextstrain repository for mpox virus

[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/nextstrain/mpox/master.svg)](https://results.pre-commit.ci/latest/github/nextstrain/mpox/master)

This repository contains three workflows for the analysis of mpox virus (MPXV) data:

- [`ingest/`](./ingest) - Download data from GenBank, clean and curate it and upload it to S3
- [`phylogenetic/`](./phylogenetic) - Make phylogenetic trees for nextstrain.org
- [`nextclade/`](./nextclade) - Make Nextclade datasets for nextstrain/nextclade_data

Each folder contains a README.md with more information.

## Quickstart

Follow the [standard installation instructions](https://docs.nextstrain.org/page/install.html) for Nextstrain's suite of software tools.

Then run the default phylogenetic workflow via:
```
cd phylogenetic/
nextstrain build .
nextstrain view .
```

## Documentation

- [Contributor documentation](./CONTRIBUTING.md)
