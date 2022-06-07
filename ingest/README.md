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

### Adding new sequences not from GenBank

#### Static Files

Do the following to include sequences from static FASTA files.

1. Convert the FASTA files to NDJSON files with:
    ```sh
    ./ingest/bin/fasta-to-ndjson \
        --fasta {path-to-fasta-file} \
        --fields {fasta-header-field-names} \
        --separator {field-separator-in-header} \
        --exclude {fields-to-exclude-in-output} \
        > ingest/data/{file-name}.ndjson
    ```
2. Add the following to the `.gitignore` to allow the file to be included in the repo:
    ```
    !ingest/data/{file-name}.ndjson
    ```
3. Add the `file-name` (without the `.ndjson` extension) as a source to `ingest/config/config.yaml`. This will tell the ingest pipeline to concatenate the records to the GenBank sequences and run them through the same transform pipeline.

## Configuration

Configuration takes place in `config/config.yaml` by default.
Optional configs for uploading files and Slack notifications are in `config/optional.yaml`.

## Input data

### GenBank data

GenBank sequences and metadata are fetched via NCBI Virus.
The exact URL used to fetch data is constructed in `bin/genbank-url`.
