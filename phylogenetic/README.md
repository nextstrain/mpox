# nextstrain.org/mpox

This is the [Nextstrain](https://nextstrain.org) build for MPXV (mpox virus). Output from this build is visible at [nextstrain.org/mpox](https://nextstrain.org/mpox).
The lineages within the recent mpox outbreaks in humans are defined in a separate [lineage-designation repository](https://github.com/mpxv-lineages/lineage-designation).

## Software requirements

Follow the [standard installation instructions](https://docs.nextstrain.org/en/latest/install.html)
for Nextstrain's suite of software tools.

## Usage

If you're unfamiliar with Nextstrain builds, you may want to follow our
[Running a Pathogen Workflow guide][] first and then come back here.

The easiest way to run this pathogen build is using the Nextstrain
command-line tool from within the `phylogenetic/` directory:

    cd phylogenetic/
    nextstrain build .

Once you've run the build, you can view the results with:

    nextstrain view .

### Example build

You can run an example build using the example data provided in this repository via:

```
nextstrain build .  --configfile build-configs/ci/config.yaml
```

When the build has finished running, view the output Auspice trees via:

```
nextstrain view .
```

### Provision input data

Input sequences and metadata can be retrieved from data.nextstrain.org

* [sequences.fasta.xz](https://data.nextstrain.org/files/workflows/mpox/sequences.fasta.xz)
* [metadata.tsv.gz](https://data.nextstrain.org/files/workflows/mpox/metadata.tsv.gz)

The above datasets have been preprocessed and cleaned from GenBank using the
[ingest/](../ingest/) workflow and are updated at regular intervals.

Note that these data are generously shared by many labs around the world.
If you analyze and plan to publish using these data, please contact these labs first.

Within the analysis pipeline, these data are fetched from data.nextstrain.org and written to `data/` with:

```bash
nextstrain build . data/sequences.fasta data/metadata.tsv
```

### Run analysis pipeline

Run pipeline to produce the "overview" tree for `/mpox/all-clades` with:

```bash
nextstrain build . --configfile defaults/mpxv/config.yaml
```

Run pipeline to produce the "clade IIb" tree for `/mpox/clade-IIb` with:

```bash
nextstrain build . --configfile defaults/hmpxv1/config.yaml
```

Run pipeline to produce the "lineage B.1" tree for `/mpox/lineage-B.1` with:

```bash
nextstrain build . --configfile defaults/hmpxv1_big/config.yaml
```

### Deploy

⚠️ The below is outdated and needs to be adjusted for the new build names (mpox instead of monkeypox, etc.)

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

The default configuration takes place in `defaults/*/config.yaml` files for each build.
The analysis pipeline is contained in `rules/core.smk`.
This can be read top-to-bottom, each rule specifies its file inputs and output and pulls its parameters from `config`.
There is little redirection and each rule should be able to be reasoned with on its own.

### Custom build configs

The build-configs directory contains configs and customizations that override and/or extend the default workflow.

- [chores](build-configs/chores/) - internal Nextstrain chores such as [updating the example data](#update-example-data).
- [ci](build-configs/ci/) - CI build that run the [example build](#example-build) with the [example data](example_data/).

## Update example data

[Example data](./example_data/) is used by [CI](https://github.com/nextstrain/mpox/actions/workflows/ci.yaml).
It can also be used as a small subset of real-world data.

Example data should be updated every time metadata schema is changed or a new clade/lineage emerges.
To update, run:

```sh
nextstrain build . update_example_data -F \
    --configfiles build-configs/ci/config.yaml build-configs/chores/config.yaml
```

## Data use

We gratefully acknowledge the authors, originating and submitting laboratories of the genetic
sequences and metadata for sharing their work. Please note that although data generators have
generously shared data in an open fashion, that does not mean there should be free license to
publish on this data. Data generators should be cited where possible and collaborations should be
sought in some circumstances. Please try to avoid scooping someone else's work. Reach out if
uncertain.
