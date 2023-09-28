# Nextstrain repository for mpox virus

This repository contains two workflows for the analysis of mpox virus (MPXV) data:

- [`ingest/`](./ingest) - Download data from GenBank, clean and curate it and upload it to S3
- [`phylogenetic/`](./phylogenetic) - Make phylogenetic trees for nextstrain.org

Each folder contains a README.md with more information.

## CI

This repository uses GitHub Actions for CI. The workflows are defined in `.github/workflows/`.

## Development

### Pre-commit

This repository uses [pre-commit](https://pre-commit.com/) to run checks on the code before committing.

To install pre-commit on macOS, run:

```bash
brew install pre-commit
```

To install pre-commit on Ubuntu, run:

```bash
sudo apt install pre-commit
```

To activate pre-commit, run:

```bash
pre-commit install
```

## Development

[![pre-commit.ci status](https://results.pre-commit.ci/badge/github/nextstrain/monkeypox/master.svg)](https://results.pre-commit.ci/latest/github/nextstrain/monkeypox/master)

This repository can be used with pre-commit to automatically run checks before committing.
