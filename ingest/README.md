# nextstrain.org/monkeypox/ingest

This is the ingest pipeline for Monkeypox virus sequences.

## Usage

Fetch sequences with
```
nextstrain build . data/sequences.ndjson
```

Run the complete ingest pipeline with
```
nextstrain build .
```
This will produce two files:

    - data/metadata.tsv
    - data/sequences.fasta

## Configuration

Configuration takes place in `config/config.yaml` by default.


## Input data

### GenBank data

GenBank sequences and metadata are fetched via NCBI Virus.
The exact URL used to fetch data is constructed in `bin/genbank-url`.

