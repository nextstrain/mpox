# Developer guide

## CI

Checks are automatically run on certain pushed commits for testing and linting
purposes. Some are defined by [.github/workflows/ci.yaml][] while others are
configured outside of this repository.

[.github/workflows/ci.yaml]: ./.github/workflows/ci.yaml

## Pre-commit

[pre-commit][] is used for various checks (see [configuration][]).

You can either [install it yourself][] to catch issues before pushing or look
for the [pre-commit.ci run][] after pushing.

[pre-commit]: https://pre-commit.com/
[configuration]: ./.pre-commit-config.yaml
[install it yourself]: https://pre-commit.com/#install
[pre-commit.ci run]: https://results.pre-commit.ci/repo/github/493877605

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
