# ingest

Shared internal tooling for pathogen data ingest.  Used by our individual
pathogen repos which produce Nextstrain builds.  Expected to be vendored by
each pathogen repo using `git subtree`.

Some tools may only live here temporarily before finding a permanent home in
`augur curate` or Nextstrain CLI.  Others may happily live out their days here.

## Vendoring

Nextstrain maintained pathogen repos will use [`git subrepo`](https://github.com/ingydotnet/git-subrepo) to vendor ingest scripts.
(See discussion on this decision in https://github.com/nextstrain/ingest/issues/3)

For a list of Nextstrain repos that are currently using this method, use [this
GitHub code search](https://github.com/search?type=code&q=org%3Anextstrain+subrepo+%22remote+%3D+https%3A%2F%2Fgithub.com%2Fnextstrain%2Fingest%22).

If you don't already have `git subrepo` installed, follow the [git subrepo installation instructions](https://github.com/ingydotnet/git-subrepo#installation).
Then add the latest ingest scripts to the pathogen repo by running:

```
git subrepo clone https://github.com/nextstrain/ingest ingest/vendored
```

Any future updates of ingest scripts can be pulled in with:

```
git subrepo pull ingest/vendored
```

If you run into merge conflicts and would like to pull in a fresh copy of the
latest ingest scripts, pull with the `--force` flag:

```
git subrepo pull ingest/vendored --force
```

> **Warning**
> Beware of rebasing/dropping the parent commit of a `git subrepo` update

`git subrepo` relies on metadata in the `ingest/vendored/.gitrepo` file,
which includes the hash for the parent commit in the pathogen repos.
If this hash no longer exists in the commit history, there will be errors when
running future `git subrepo pull` commands.

If you run into an error similar to the following:
```
$ git subrepo pull ingest/vendored
git-subrepo: Command failed: 'git branch subrepo/ingest/vendored '.
fatal: not a valid object name: ''
```
Check the parent commit hash in the `ingest/vendored/.gitrepo` file and make
sure the commit exists in the commit history. Update to the appropriate parent
commit hash if needed.

## History

Much of this tooling originated in
[ncov-ingest](https://github.com/nextstrain/ncov-ingest) and was passaged thru
[mpox's ingest/](https://github.com/nextstrain/mpox/tree/@/ingest/). It
subsequently proliferated from [mpox][] to other pathogen repos ([rsv][],
[zika][], [dengue][], [hepatitisB][], [forecasts-ncov][]) primarily thru
copying.  To [counter that
proliferation](https://bedfordlab.slack.com/archives/C7SDVPBLZ/p1688577879947079),
this repo was made.

[mpox]: https://github.com/nextstrain/mpox
[rsv]: https://github.com/nextstrain/rsv
[zika]: https://github.com/nextstrain/zika/pull/24
[dengue]: https://github.com/nextstrain/dengue/pull/10
[hepatitisB]: https://github.com/nextstrain/hepatitisB
[forecasts-ncov]: https://github.com/nextstrain/forecasts-ncov

## Elsewhere

The creation of this repo, in both the abstract and concrete, and the general
approach to "ingest" has been discussed in various internal places, including:

- https://github.com/nextstrain/private/issues/59
- @joverlee521's [workflows document](https://docs.google.com/document/d/1rLWPvEuj0Ayc8MR0O1lfRJZfj9av53xU38f20g8nU_E/edit#heading=h.4g0d3mjvb89i)
- [5 July 2023 Slack thread](https://bedfordlab.slack.com/archives/C7SDVPBLZ/p1688577879947079)
- [6 July 2023 team meeting](https://docs.google.com/document/d/1FPfx-ON5RdqL2wyvODhkrCcjgOVX3nlXgBwCPhIEsco/edit)
- _…many others_

## Scripts

Scripts for supporting ingest workflow automation that don’t really belong in any of our existing tools.

- [notify-on-diff](notify-on-diff) - Send Slack message with diff of a local file and an S3 object
- [notify-on-job-fail](notify-on-job-fail) - Send Slack message with details about failed workflow job on GitHub Actions and/or AWS Batch
- [notify-on-job-start](notify-on-job-start) - Send Slack message with details about workflow job on GitHub Actions and/or AWS Batch
- [notify-on-record-change](notify-on-recod-change) - Send Slack message with details about line count changes for a file compared to an S3 object's metadata `recordcount`.
  If the S3 object's metadata does not have `recordcount`, then will attempt to download S3 object to count lines locally, which only supports `xz` compressed S3 objects.
- [notify-slack](notify-slack) - Send message or file to Slack
- [s3-object-exists](s3-object-exists) - Used to prevent 404 errors during S3 file comparisons in the notify-* scripts
- [trigger](trigger) - Triggers downstream GitHub Actions via the GitHub API using repository_dispatch events.
- [trigger-on-new-data](trigger-on-new-data) - Triggers downstream GitHub Actions if the provided `upload-to-s3` outputs do not contain the `identical_file_message`
  A hacky way to ensure that we only trigger downstream phylogenetic builds if the S3 objects have been updated.

NCBI interaction scripts that are useful for fetching public metadata and sequences.

- [fetch-from-ncbi-entrez](fetch-from-ncbi-entrez) - Fetch metadata and nucleotide sequences from [NCBI Entrez](https://www.ncbi.nlm.nih.gov/books/NBK25501/) and output to a GenBank file.
  Useful for pathogens with metadata and annotations in custom fields that are not part of the standard [NCBI Datasets](https://www.ncbi.nlm.nih.gov/datasets/) outputs.

Historically, some pathogen repos used the undocumented NCBI Virus API through [fetch-from-ncbi-virus](https://github.com/nextstrain/ingest/blob/c97df238518171c2b1574bec0349a55855d1e7a7/fetch-from-ncbi-virus) to fetch data. However we've opted to drop the NCBI Virus scripts due to https://github.com/nextstrain/ingest/issues/18.

Potential Nextstrain CLI scripts

- [sha256sum](sha256sum) - Used to check if files are identical in upload-to-s3 and download-from-s3 scripts.
- [cloudfront-invalidate](cloudfront-invalidate) - CloudFront invalidation is already supported in the [nextstrain remote command for S3 files](https://github.com/nextstrain/cli/blob/a5dda9c0579ece7acbd8e2c32a4bbe95df7c0bce/nextstrain/cli/remote/s3.py#L104).
  This exists as a separate script to support CloudFront invalidation when using the upload-to-s3 script.
- [upload-to-s3](upload-to-s3) - Upload file to AWS S3 bucket with compression based on file extension in S3 URL.
  Skips upload if the local file's hash is identical to the S3 object's metadata `sha256sum`.
  Adds the following user defined metadata to uploaded S3 object:
    - `sha256sum` - hash of the file generated by [sha256sum](sha256sum)
    - `recordcount` - the line count of the file
- [download-from-s3](download-from-s3) - Download file from AWS S3 bucket with decompression based on file extension in S3 URL.
  Skips download if the local file already exists and has a hash identical to the S3 object's metadata `sha256sum`.

Potential augur curate scripts

- [apply-geolocation-rules](apply-geolocation-rules) - Applies user curated geolocation rules to NDJSON records
- [merge-user-metadata](merge-user-metadata) - Merges user annotations with NDJSON records
- [transform-authors](transform-authors) - Abbreviates full author lists to '<first author> et al.'
- [transform-field-names](transform-field-names) - Rename fields of NDJSON records
- [transform-genbank-location](transform-genbank-location) - Parses `location` field with the expected pattern `"<country_value>[:<region>][, <locality>]"` based on [GenBank's country field](https://www.ncbi.nlm.nih.gov/genbank/collab/country/)
- [transform-strain-names](transform-strain-names) - Ordered search for strain names across several fields.

## Software requirements

Some scripts may require Bash ≥4. If you are running these scripts on macOS, the builtin Bash (`/bin/bash`) does not meet this requirement. You can install [Homebrew's Bash](https://formulae.brew.sh/formula/bash) which is more up to date.

## Testing

Most scripts are untested within this repo, relying on "testing in production". That is the only practical testing option for some scripts such as the ones interacting with S3 and Slack.

For more locally testable scripts, Cram-style functional tests live in `tests` and are run as part of CI. To run these locally,

1. Download Cram: `pip install cram`
2. Run the tests: `cram tests/`
