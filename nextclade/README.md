# Nextclade reference tree workflow for monkeypox

This README doesn't end up in the datasets, so it's more of a developer README, rather than a dataset user README.

## Usage

```bash
snakemake
```

### Visualize results

View results with:

```bash
nextstrain view auspice/
```

## Maintenance

### Updating for new clades

- [ ] Update each `config/{build}/clades.tsv` with new clades
- [ ] Add new clades to color ordering
- [ ] Check that clades look good, exclude problematic sequences as necessary

### Creating a new dataset version

- [ ] Edit CHANGELOG.md
- [ ] Switch to `nextclade_data/data/mpox` repo
- [ ] Create branch there, copy datasets, commit, push, open PR:

```bash
cd ../../nextclade_data
git checkout master
git pull
git checkout -b mpox-update
cp -r ../monkeypox/nextclade/datasets/ data/nextstrain/mpox
git add data/nextstrain/mpox
git commit -m "Update mpox dataset"
git push -u origin mpox-update
gh pr create
```

## Configuration

Builds differ in paths, relevant configs are pulled in through lookup.

## Installation

Follow the [standard installation instructions](https://docs.nextstrain.org/en/latest/install.html) for Nextstrain's suite of software tools.

## Data use

We gratefully acknowledge the authors, originating and submitting laboratories of the genetic
sequences and metadata for sharing their work. Please note that although data generators have
generously shared data in an open fashion, that does not mean there should be free license to
publish on this data. Data generators should be cited where possible and collaborations should be
sought in some circumstances. Please try to avoid scooping someone else's work. Reach out if
uncertain.
