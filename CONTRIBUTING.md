# Developer guide

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
