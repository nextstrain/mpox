# CHANGELOG

We use this CHANGELOG to document breaking changes, new features, bug fixes,
and config value changes that may affect both the usage of the workflows and
the outputs of the workflows.

Changes for this project _do not_ currently follow the [Semantic Versioning rules](https://semver.org/spec/v2.0.0.html).
Instead, changes appear below grouped by the date they were added to the workflow.


## 2025

* 01 July 2025: phylogenetic - Use `strain_id_field` for node name. ([#275][])
    The final Auspice JSONs now use the `strain_id_field` config param as the
    node name and the `display_strain_field` config param is no longer supported.
    If you want to use a different field as the default tip label, then add
    `display_defaults['tip_label']` to your auspice_config.json.
* 25 June 2025: metadata.tsv column changes. ([#319][])
    * `date_submitted` has been corrected to `date_released`.
    * added columns `date_updated`, `length`, and `url`
    Note that our public metadata.tsv files still has the `date_submitted` column
    for backwards compatibility, but it will be removed by 28 July 2025 so please
    update your workflows to use the new `date_released` column.
* 25 June 2025: All workflows now use the zstd compressed outputs on S3. ([#318][])
    Note that the gzip and xz compressed files on S3 will be removed by 28 July 2025,
    so please update your workflows to use the zstd compressed files.
* 23 June 2025: added the following zstd compressed outputs. ([#317][])
    * https://data.nextstrain.org/files/workflows/mpox/metadata.tsv.zst
    * https://data.nextstrain.org/files/workflows/mpox/sequences.fasta.zst
    * https://data.nextstrain.org/files/workflows/mpox/alignment.fasta.zst
* 23 June 2025: ingest - updated intermediate NDJSON file. ([#316][])
    * Removed the following intermediate NDJSON files
        * https://data.nextstrain.org/files/workflows/mpox/all_sequences.ndjson.xz
        * https://data.nextstrain.org/files/workflows/mpox/genbank.ndjson.xz
    * Added a new NDJSON file that is zstd compressed and uses the [NCBI Datasets mnemonics][] as field names.
        * https://data.nextstrain.org/files/workflows/mpox/ncbi.ndjson.zst
* 23 June 2025: ingest - removed path for separate data sources. ([#316][])
    * The config param `sources` is no longer supported


[#275]: https://github.com/nextstrain/mpox/pull/275
[#316]: https://github.com/nextstrain/mpox/pull/316
[#317]: https://github.com/nextstrain/mpox/pull/317
[#318]: https://github.com/nextstrain/mpox/pull/318
[#319]: https://github.com/nextstrain/mpox/pull/319
[NCBI Datasets mnemonics]: https://www.ncbi.nlm.nih.gov/datasets/docs/v2/reference-docs/command-line/dataformat/tsv/dataformat_tsv_virus-genome/#fields
