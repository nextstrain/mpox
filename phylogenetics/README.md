# nextstrain.org/monkeypox

This is the [Nextstrain](https://nextstrain.org) build for MPXV (mpox virus). Output from this build is visible at [nextstrain.org/monkeypox](https://nextstrain.org/monkeypox).
The lineages within the recent mpox outbreaks in humans are defined in a separate [lineage-designation repository](https://github.com/mpxv-lineages/lineage-designation).

## Usage

### Provision input data

Input sequences and metadata can be retrieved from data.nextstrain.org

* [sequences.fasta.xz](https://data.nextstrain.org/files/workflows/monkeypox/sequences.fasta.xz)
* [metadata.tsv.gz](https://data.nextstrain.org/files/workflows/monkeypox/metadata.tsv.gz)

Note that these data are generously shared by many labs around the world.
If you analyze and plan to publish using these data, please contact these labs first.

Within the analysis pipeline, these data are fetched from data.nextstrain.org and written to `data/` with:

```bash
nextstrain build . data/sequences.fasta data/metadata.tsv
```

### Run analysis pipeline

Run pipeline to produce the "overview" tree for `/mpox/all-clades` with:

```bash
nextstrain build . --configfile config/config_mpxv.yaml
```

Run pipeline to produce the "clade IIb" tree for `/mpox/clade-IIb` with:

```bash
nextstrain build . --configfile config/config_hmpxv1.yaml
```

Run pipeline to produce the "lineage B.1" tree for `/mpox/lineage-B.1` with:

```bash
nextstrain build . --configfile config/config_hmpxv1_big.yaml
```

### Deploying

⚠️ The below is outdated and needs to be adjusted for the new build names (mpxv instead of monkeypox, etc.)

<details>

Run the python script [`scripts/deploy.py`](scripts/deploy.py) to deploy the staging build to production.

This will also automatically create a dated build where each node has a unique (random) ID so it can be targeted in shared links/narratives.

```bash
python scripts/deploy.py --build-names hmpxv1 mpxv
```

If a dated build already exists it is not overwritten by default. To overwrite, pass `-f`.

To deploy a locally built build to staging, use the `--staging` flag.

To not deploy a dated build to production, add the `--no-dated` flag.

</details>

### Visualize results

View results with:

```bash
nextstrain view .
```

## Configuration

Configuration takes place in `config/config_*.yaml` files for each build..
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

If you don't use the `nextstrain` CLI but a custom conda environment, make sure that you have `tsv-utils` and `seqkit` installed, e.g. using:

```sh
mamba install -c bioconda tsv-utils seqkit
```

### Nextstrain build vs Snakemake

The above commands use the Nextstrain CLI and `nextstrain build` along with Docker to run using Nextalign v2.
Alternatively, if you [install Nextalign/Nextclade v2 locally](https://github.com/nextstrain/nextclade/releases) you can run the pipeline with:

```bash
snakemake --configfile config/config_mpxv.yaml
snakemake --configfile config/config_hmpxv1.yaml
snakemake --configfile config/config_hmpxv1_big.yaml
```

### Update colors to include new countries

Update `colors_hmpxv1.tsv` to group countries by region based on countries present in its `metadata.tsv`:

```bash
python3 scripts/update_colours.py --colors config/colors_hmpxv1.tsv \
    --metadata results/hmpxv1/metadata.tsv --output config/colors_hmpxv1.tsv
```

and similarly update `colors_mpxv.tsv`:

```bash
python3 scripts/update_colours.py --colors config/colors_mpxv.tsv \
    --metadata results/mpxv/metadata.tsv --output config/colors_mpxv.tsv
```

### Update example data

[Example data](./example_data/) is used by [CI](https://github.com/nextstrain/monkeypox/actions/workflows/ci.yaml). It can also be used as a small subset of real-world data.

Example data should be updated every time metadata schema is changed or a new clade/lineage emerges. To update, run:

```sh
nextstrain build . update_example_data -F
```
