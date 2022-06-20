# nextstrain.org/monkeypox/ingest

This is the ingest pipeline for Monkeypox virus sequences.

## Usage

> NOTE: All command examples assume you are within the `ingest` directory.
> If running commands from the outer `monkeypox` directory, please replace the `.` with `ingest`

Fetch sequences with

```sh
nextstrain build --cpus 1 . data/sequences.ndjson
```

Run the complete ingest pipeline with

```sh
nextstrain build --cpus 1 .
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

    ```gitignore
    !ingest/data/{file-name}.ndjson
    ```

3. Add the `file-name` (without the `.ndjson` extension) as a source to `ingest/config/config.yaml`. This will tell the ingest pipeline to concatenate the records to the GenBank sequences and run them through the same transform pipeline.

## Configuration

Configuration takes place in `config/config.yaml` by default.
Optional configs for uploading files and Slack notifications are in `config/optional.yaml`.

### Environment Variables

The complete ingest pipeline with AWS S3 uploads and Slack notifications uses the following environment variables:

#### Required

- `AWS_DEFAULT_REGION`
- `AWS_ACCESS_KEY_ID`
- `AWS_SECRET_ACCESS_KEY`
- `SLACK_TOKEN`
- `SLACK_CHANNELS`

#### Optional

These are optional environment variables used in our automated pipeline for providing detailed Slack notifications.

- `GITHUB_RUN_ID` - provided via [`github.run_id` in a GitHub Action workflow](https://docs.github.com/en/actions/learn-github-actions/contexts#github-context)
- `AWS_BATCH_JOB_ID` - provided via [AWS Batch Job environment variables](https://docs.aws.amazon.com/batch/latest/userguide/job_env_vars.html)

## Input data

### GenBank data

GenBank sequences and metadata are fetched via NCBI Virus.
The exact URL used to fetch data is constructed in `bin/genbank-url`.
