import sys


rule get_nextclade_dataset:
    output:
        "data/mpxv.zip",
    params:
        dataset_name="MPXV",
    log:
        "logs/get_nextclade_dataset.txt",
    benchmark:
        "benchmarks/get_nextclade_dataset.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

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
    threads: workflow.cores
    log:
        "logs/run_nextclade.txt",
    benchmark:
        "benchmarks/run_nextclade.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

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


rule nextclade_metadata:
    input:
        nextclade="results/nextclade.tsv",
    output:
        nextclade_metadata="results/nextclade_metadata.tsv",
    params:
        nextclade_id_field=config["nextclade"]["id_field"],
        nextclade_field_map=[
            f"{old}={new}" for old, new in config["nextclade"]["field_map"].items()
        ],
        nextclade_fields=",".join(config["nextclade"]["field_map"].keys()),
    log:
        "logs/nextclade_metadata.txt",
    benchmark:
        "benchmarks/nextclade_metadata.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        csvtk cut -t --fields {params.nextclade_fields:q} {input.nextclade} \
        | augur curate rename \
            --metadata - \
            --id-column {params.nextclade_id_field:q} \
            --field-map {params.nextclade_field_map:q} \
            --output-metadata {output.nextclade_metadata:q}
        """


rule join_metadata_and_nextclade:
    input:
        metadata="data/subset_metadata.tsv",
        nextclade_metadata="results/nextclade_metadata.tsv",
    output:
        metadata="results/metadata.tsv",
    params:
        metadata_id_field=config["curate"]["id_field"],
        nextclade_id_field=config["nextclade"]["id_field"],
    log:
        "logs/join_metadata_and_nextclade.txt",
    benchmark:
        "benchmarks/join_metadata_and_nextclade.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur merge \
            --metadata \
                metadata={input.metadata:q} \
                nextclade={input.nextclade_metadata:q} \
            --metadata-id-columns \
                metadata={params.metadata_id_field:q} \
                nextclade={params.nextclade_id_field:q} \
            --output-metadata {output.metadata:q} \
            --no-source-columns
        """
