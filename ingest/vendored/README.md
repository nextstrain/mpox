# ingest

Shared internal tooling for pathogen data ingest.  Used by our individual
pathogen repos which produce Nextstrain builds.  Expected to be vendored by
each pathogen repo using `git subtree` (or `git subrepo`).

Some tools may only live here temporarily before finding a permanent home in
`augur curate` or Nextstrain CLI.  Others may happily live out their days here.

## History

Much of this tooling originated in
[ncov-ingest](https://github.com/nextstrain/ncov-ingest) and was passaged thru
[monkeypox's ingest/](https://github.com/nextstrain/monkeypox/tree/@/ingest/).
It subsequently proliferated from [monkeypox][] to other pathogen repos
([rsv][], [zika][], [dengue][], [hepatitisB][], [forecasts-ncov][]) primarily
thru copying.  To [counter that
proliferation](https://bedfordlab.slack.com/archives/C7SDVPBLZ/p1688577879947079),
this repo was made.

[monkeypox]: https://github.com/nextstrain/monkeypox
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

- [notify-on-job-fail](notify-on-job-fail) - Send Slack message with details about failed workflow job on GitHub Actions and/or AWS Batch
- [notify-on-job-start](notify-on-job-start) - Send Slack message with details about workflow job on GitHub Actions and/or AWS Batch
- [notify-slack](notify-slack) - Send message or file to Slack
- [s3-object-exists](s3-object-exists) - Used to prevent 404 errors during S3 file comparisons in the notify-* scripts
- [trigger](trigger) - Triggers downstream GitHub Actions via the GitHub API using repository_dispatch events.

Potential Nextstrain CLI scripts

- [sha256sum](sha256sum) - Used to check if files are identical in upload-to-s3 and download-from-s3 scripts.
- [cloudfront-invalidate](cloudfront-invalidate) - CloudFront invalidation is already supported in the [nextstrain remote command for S3 files](https://github.com/nextstrain/cli/blob/a5dda9c0579ece7acbd8e2c32a4bbe95df7c0bce/nextstrain/cli/remote/s3.py#L104).
  This exists as a separate script to support CloudFront invalidation when using the upload-to-s3 script.

Potential augur curate scripts

- [merge-user-metadata](merge-user-metadata) - Merges user annotations with NDJSON records
- [transform-authors](transform-authors) - Abbreviates full author lists to '<first author> et al.'
- [transform-field-names](transform-field-names) - Rename fields of NDJSON records
- [transform-genbank-location](transform-genbank-location) - Parses `location` field with the expected pattern `"<country_value>[:<region>][, <locality>]"` based on [GenBank's country field](https://www.ncbi.nlm.nih.gov/genbank/collab/country/)
