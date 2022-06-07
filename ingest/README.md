# nextstrain.org/monkeypox/ingest

This is the ingest pipeline for Monkeypox virus sequences.

## Usage

> NOTE: All command examples assume you are within the `ingest` directory.
> If running commands from the outer `monkeypox` directory, please replace the `.` with `ingest`


Fetch sequences with

```sh
nextstrain build . data/sequences.ndjson
```

Run the complete ingest pipeline with

```sh
nextstrain build .
```
This will produce two files (within the `ingest` directory):

- data/metadata.tsv
- data/sequences.fasta

Run the complete ingest pipeline and upload results to AWS S3 with

```sh
nextstrain build . --configfiles config/config.yaml config/optional.yaml
```

## Configuration

Configuration takes place in `config/config.yaml` by default.
Optional configs for uploading files and Slack notifications are in `config/optional.yaml`.

## Input data

### GenBank data

GenBank sequences and metadata are fetched via NCBI Virus.
The exact URL used to fetch data is constructed in `bin/genbank-url`.
