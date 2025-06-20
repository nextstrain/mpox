# CHANGELOG

We use this CHANGELOG to document breaking changes, new features, bug fixes,
and config value changes that may affect both the usage of the workflows and
the outputs of the workflows.

Changes for this project _do not_ currently follow the [Semantic Versioning rules](https://semver.org/spec/v2.0.0.html).
Instead, changes appear below grouped by the date they were added to the workflow.


## 2025

* 23 June 2025: ingest - updated intermediate NDJSON file. ([#316][])
    * Removed the following intermediate NDJSON files
        * https://data.nextstrain.org/files/workflows/mpox/all_sequences.ndjson.xz
        * https://data.nextstrain.org/files/workflows/mpox/genbank.ndjson.xz
    * Added a new NDJSON file that is zstd compressed and uses the [NCBI Datasets mnemonics][] as field names.
        * https://data.nextstrain.org/files/workflows/mpox/ncbi.ndjson.zst
* 23 June 2025: ingest - removed path for separate data sources. ([#316][])
    * The config param `sources` is no longer supported

[#316]: https://github.com/nextstrain/mpox/pull/316
[NCBI Datasets mnemonics]: https://www.ncbi.nlm.nih.gov/datasets/docs/v2/reference-docs/command-line/dataformat/tsv/dataformat_tsv_virus-genome/#fields
