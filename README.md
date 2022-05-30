# nextstrain.org/monkeypox

This is the [Nextstrain](https://nextstrain.org) build for monkeypox virus. Output from this build is visible at [nextstrain.org/monkeypox](https://nextstrain.org/monkeypox).

## Usage

### Provision input data

Retrieve input sequences using LAPIS and write to `data/` with:
```
nextstrain build --docker --image=nextstrain/base:branch-nextalign-v2 . data/sequences.fasta
```

Copy metadata with:
```
cp example_data/metadata.tsv data/
```

### Run analysis pipeline

Run pipeline with:
```
nextstrain build --docker --image=nextstrain/base:branch-nextalign-v2 --cpus 1 .
```

Adjust the number of CPUs to what your machine has available you want to perform alignment and tree building a bit faster.

### Visualize results

View results with:
```
nextstrain view auspice/
```

## Configuration

Configuration takes place in `config/config.yml` by default.
The analysis pipeline is contained in `workflow/snakemake_rule/core.smk`.
This can be read top-to-bottom, each rule specifies its file inputs and output and pulls its parameters from `config`.
There is little redirection and each rule should be able to be reasoned with on its own.

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

### Nextstrain build vs Snakemake

The above commands use the Nextstrain CLI and `nextstrain build` along with Docker to run using Nextalign v2. Alternatively, if you install Nextalign v2 locally. You can run pipeline with:
```
snakemake -j 1 -p --configfile config/config.yaml
```
