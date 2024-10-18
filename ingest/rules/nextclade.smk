import sys


rule get_nextclade_dataset:
    output:
        temp("data/mpxv.zip"),
    params:
        dataset_name="MPXV",
    shell:
        r"""
        nextclade3 dataset get \
            --name {params.dataset_name:q} \
            --output-zip {output:q}
        """


rule run_nextclade:
    input:
        sequences="results/sequences.fasta",
        dataset="data/mpxv.zip",
    output:
        nextclade="results/nextclade.tsv",
        alignment="results/alignment.fasta",
        translations="results/translations.zip",
    params:
        # The lambda is used to deactivate automatic wildcard expansion.
        # https://github.com/snakemake/snakemake/blob/384d0066c512b0429719085f2cf886fdb97fd80a/snakemake/rules.py#L997-L1000
        translations=lambda w: "results/translations/{cds}.fasta",
    threads: 4
    shell:
        r"""
        nextclade3 run \
            {input.sequences:q} \
            --jobs {threads:q} \
            --retry-reverse-complement \
            --input-dataset {input.dataset:q} \
            --output-tsv {output.nextclade:q} \
            --output-fasta {output.alignment:q} \
            --output-translations {params.translations:q}

        zip -rj {output.translations:q} results/translations
        """


if isinstance(config["nextclade"]["field_map"], str):
    print(
        f"Converting config['nextclade']['field_map'] from TSV file ({config['nextclade']['field_map']}) to dictionary; "
        f"consider putting the field map directly in the config file.",
        file=sys.stderr,
    )
    with open(config["nextclade"]["field_map"], "r") as f:
        config["nextclade"]["field_map"] = dict(
            line.rstrip("\n").split("\t", 1) for line in f if not line.startswith("#")
        )


rule join_metadata_clades:
    input:
        nextclade="results/nextclade.tsv",
        metadata="data/subset_metadata.tsv",
    output:
        metadata="results/metadata.tsv",
    params:
        id_field=config["curate"]["id_field"],
        nextclade_id_field=config["nextclade"]["id_field"],
        nextclade_field_map=[
            f"{old}={new}" for old, new in config["nextclade"]["field_map"].items()
        ],
        nextclade_fields=",".join(config["nextclade"]["field_map"].keys()),
    shell:
        r"""
        tsv-select --header --fields {params.nextclade_fields:q} {input.nextclade} \
        | augur curate rename \
            --metadata - \
            --id-column {params.nextclade_id_field:q} \
            --field-map {params.nextclade_field_map:q} \
            --output-metadata - \
        | tsv-join -H \
            --filter-file - \
            --key-fields {params.nextclade_id_field} \
            --data-fields {params.id_field} \
            --append-fields '*' \
            --write-all ? \
            {input.metadata} \
        | tsv-select -H --exclude {params.nextclade_id_field} \
            > {output.metadata}
        """
