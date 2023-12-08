# nextstrain.org/mpox/ingest

This is the ingest pipeline for mpox virus sequences.

## Software requirements

Follow the [standard installation instructions](https://docs.nextstrain.org/en/latest/install.html) for Nextstrain's suite of software tools.

## Usage

> NOTE: All command examples assume you are within the `ingest` directory.
> If running commands from the outer `mpox` directory, please replace the `.` with `ingest`

Fetch sequences with

```sh
nextstrain build . data/sequences.ndjson
```

Run the complete ingest pipeline with

```sh
nextstrain build .
```

This will produce two files (within the `ingest` directory):

- `results/metadata.tsv`
- `results/sequences.fasta`

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

GenBank sequences and metadata are fetched via [NCBI datasets](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/).

## `ingest/vendored`

This repository uses [`git subrepo`](https://github.com/ingydotnet/git-subrepo) to manage copies of ingest scripts in [ingest/vendored](./vendored), from [nextstrain/ingest](https://github.com/nextstrain/ingest).

See [vendored/README.md](vendored/README.md#vendoring) for instructions on how to update
the vendored scripts.
