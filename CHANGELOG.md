# CHANGELOG

We use this CHANGELOG to document breaking changes, new features, bug fixes,
and config value changes that may affect both the usage of the workflows and
the outputs of the workflows.

Changes for this project _do not_ currently follow the [Semantic Versioning rules](https://semver.org/spec/v2.0.0.html).
Instead, changes appear below grouped by the date they were added to the workflow.


## 2025

* 05 November 2025: Data files archived before transition to Pathoplexus data source.
    * The data files published on 05 November 2025 (prior to the Pathoplexus transition) are available at:
        * https://data.nextstrain.org/files/workflows/mpox/archive/20251105/metadata.tsv.zst
        * https://data.nextstrain.org/files/workflows/mpox/archive/20251105/sequences.fasta.zst
        * https://data.nextstrain.org/files/workflows/mpox/archive/20251105/alignment.fasta.zst
        * https://data.nextstrain.org/files/workflows/mpox/archive/20251105/nextclade.tsv.zst
        * https://data.nextstrain.org/files/workflows/mpox/archive/20251105/translations.zip
        * https://data.nextstrain.org/files/workflows/mpox/archive/20251105/ncbi.ndjson.zst
    * After this date, the main data files at https://data.nextstrain.org/files/workflows/mpox/ might contain data from Pathoplexus (which includes INSDC data).

* 08 October 2025: phylogenetic - Major update to the definition of inputs. ([#339][])
    * Configs are now required to include the `inputs` param to define inputs for the workflow

        ```yaml
        inputs:
          - name: ncbi
            metadata: "https://data.nextstrain.org/files/workflows/mpox/metadata.tsv.zst"
            sequences: "https://data.nextstrain.org/files/workflows/mpox/sequences.fasta.zst"
        ```

* 02 July 2025: phylogenetic - config schema updates for easier config overlays ([#321][])
    * new required config params
        * `exclude` - path to exclude.txt for `augur filter`
        * `filter["query"]` - argument for the `--query` option for `augur filter`
        * `color_ordering` - path to color_ordering.tsv for generating colors.tsv
        * `color_schemes` - path to color_schemes.tsv for generating colors.tsv
    * string params that were converted to lists.
    These are automatically converted to lists in the workflow but you are still encouraged to update your config file
        * `root`
        * `traits["columns"]`
        * `colors["ignore_categories"]`
    * `["subsampling"][<name>]` values are now expected to be a single string of `augur filter` options.
    These are automatically converted to a string if they are still a dict in the config file but you are still encouraged to update your config file.
    See the [default config](./phylogenetic/defaults/hmpxv1/config.yaml) for an example.
    * specific subsamples can now be disabled by setting the value to null.
    This is useful for disabling default subsampling when running the workflow with config overlays.
    For example, you can disable the `non_b1` subsampling in the [default config](./phylogenetic/defaults/hmpxv1/config.yaml) with the YAML null value (~):
    ```yaml
    subsample:
        non_b1: ~
    ```
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
[#321]: https://github.com/nextstrain/mpox/pull/321
[#339]: https://github.com/nextstrain/mpox/pull/339
[NCBI Datasets mnemonics]: https://www.ncbi.nlm.nih.gov/datasets/docs/v2/reference-docs/command-line/dataformat/tsv/dataformat_tsv_virus-genome/#fields
