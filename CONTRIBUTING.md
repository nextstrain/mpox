# Developer guide

## CI

This repository uses GitHub Actions for CI. The workflows are defined in `.github/workflows/`.

## Pre-commit

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

## Snakemake formatting

We use [`snakefmt`](https://github.com/snakemake/snakefmt) to ensure consistency in style across Snakemake files in this project.

### Installing

- Using mamba/bioconda:

```bash
mamba install -c bioconda snakefmt
```

- Using pip:

```bash
pip install snakefmt
```

### IDE-independent

1. Check for styling issues with `snakefmt --check .`
1. Automatically fix styling issues with `snakefmt .`

### Using VSCode extension

1. Install the [VSCode extension](https://marketplace.visualstudio.com/items?itemName=tfehlmann.snakefmt)
1. Check for styling issues with `Ctrl+Shift+P` and select `snakefmt: Check`
1. Automatically fix styling issues with `Ctrl+Shift+P` and select `Format document`
