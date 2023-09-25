# Nextstrain repository for mpox virus

This repository contains two workflows for the analysis of mpox virus (MPXV) data:

- `ingest/` - Download data from GenBank, clean and curate it and upload it to S3
- `phylogenetic/` - Make phylogenetic trees for nextstrain.org

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
