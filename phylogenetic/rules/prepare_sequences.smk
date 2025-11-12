"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    metadata    = results/metadata.tsv
    sequences   = results/sequences.fasta
    include     = path to file of sequences to force include
    exclude     = path to file of sequences to exclude
    reference   = path to reference sequence FASTA for Nextclade alignment
    genome_annotation     = path to genome_annotation GFF for Nextclade alignment
    maskfile    = path to maskfile of sites to be masked

OUTPUTS:

    prepared_sequences = {build_dir}/{build_name}/masked.fasta

"""


rule map_accessions:
    """
    Map INSDC accessions to PPX accessions in exclude/include files.
    INSDC accessions (versioned or unversioned) are transformed to PPX accessions.
    PPX accessions pass through unchanged. This allows exclude/include files to
    contain a mixture of INSDC and PPX accessions.
    """
    input:
        accession_list=lambda w: config[w.in_ex_clude],
        metadata="results/metadata.tsv",
        script="scripts/map_accessions.py",
    output:
        accession_list=build_dir + "/{build_name}/{in_ex_clude}_ppx.txt",
    wildcard_constraints:
        in_ex_clude="(include|exclude)",
    log:
        "logs/{build_name}/map_accessions_{in_ex_clude}.txt",
    benchmark:
        "benchmarks/{build_name}/map_accessions_{in_ex_clude}.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        {input.script:q} \
            --input {input.accession_list:q} \
            --metadata {input.metadata:q} \
            --output {output.accession_list:q}
        """


rule filter:
    """
    Removing strains that do not satisfy certain requirements.
    """
    input:
        sequences="results/sequences.fasta",
        metadata="results/metadata.tsv",
        exclude=build_dir + "/{build_name}/exclude_ppx.txt",
    output:
        sequences=build_dir + "/{build_name}/good_sequences.fasta",
        metadata=build_dir + "/{build_name}/good_metadata.tsv",
        log=build_dir + "/{build_name}/good_filter.log",
    params:
        min_date=config["filter"]["min_date"],
        min_length=config["filter"]["min_length"],
        strain_id=config["strain_id_field"],
        query=config["filter"]["query"],
        exclude_where=lambda w: (
            ("--exclude-where " + config["filter"]["exclude_where"])
            if "exclude_where" in config["filter"]
            else ""
        ),
    log:
        "logs/{build_name}/filter.txt",
    benchmark:
        "benchmarks/{build_name}/download.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q} \
            --exclude {input.exclude:q} \
            {params.exclude_where} \
            --min-date {params.min_date:q} \
            --min-length {params.min_length:q} \
            --query {params.query:q} \
            --output-log {output.log:q}
        """


# Only define `add_private_data` rule when the config params are provided
# so that Snakemake >= 9.12.0 doesn't fail due to optional inputs
if config.get("private_sequences") and config.get("private_metadata"):

    rule add_private_data:
        """
        This rule is conditionally added to the DAG if a config defines 'private_sequences' and 'private_metadata'
        """
        input:
            sequences=build_dir + "/{build_name}/good_sequences.fasta",
            metadata=build_dir + "/{build_name}/good_metadata.tsv",
            private_sequences=config.get("private_sequences", ""),
            private_metadata=config.get("private_metadata", ""),
        output:
            sequences=build_dir + "/{build_name}/good_sequences_combined.fasta",
            metadata=build_dir + "/{build_name}/good_metadata_combined.tsv",
        log:
            "logs/{build_name}/add_private_data.txt",
        benchmark:
            "benchmarks/{build_name}/add_private_data.txt"
        shell:
            r"""
            exec &> >(tee {log:q})

            python3 scripts/combine_data_sources.py \
                --metadata nextstrain={input.metadata:q} private={input.private_metadata:q} \
                --sequences {input.sequences:q} {input.private_sequences:q} \
                --output-metadata {output.metadata:q} \
                --output-sequences {output.sequences:q}
            """


rule subsample:
    input:
        metadata=(
            build_dir + "/{build_name}/good_metadata_combined.tsv"
            if config.get("private_metadata", False)
            else build_dir + "/{build_name}/good_metadata.tsv"
        ),
    output:
        strains=build_dir + "/{build_name}/{sample}_strains.txt",
        log=build_dir + "/{build_name}/{sample}_filter.log",
    params:
        augur_filter_args=lambda w: config["subsample"][w.sample],
        strain_id=config["strain_id_field"],
    log:
        "logs/{build_name}/{sample}_subsample.txt",
    benchmark:
        "benchmarks/{build_name}/{sample}_subsample.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output-strains {output.strains:q} \
            {params.augur_filter_args} \
            --output-log {output.log:q}
        """


rule combine_samples:
    input:
        strains=lambda w: [
            f"{build_dir}/{w.build_name}/{sample}_strains.txt"
            for sample in config["subsample"]
        ],
        sequences=(
            build_dir + "/{build_name}/good_sequences_combined.fasta"
            if config.get("private_sequences", False)
            else build_dir + "/{build_name}/good_sequences.fasta"
        ),
        metadata=(
            build_dir + "/{build_name}/good_metadata_combined.tsv"
            if config.get("private_metadata", False)
            else build_dir + "/{build_name}/good_metadata.tsv"
        ),
        include=build_dir + "/{build_name}/include_ppx.txt",
    output:
        sequences=build_dir + "/{build_name}/filtered.fasta",
        metadata=build_dir + "/{build_name}/metadata.tsv",
    params:
        strain_id=config["strain_id_field"],
    log:
        "logs/{build_name}/combine_samples.txt",
    benchmark:
        "benchmarks/{build_name}/combine_samples.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur filter \
            --metadata-id-columns {params.strain_id:q} \
            --sequences {input.sequences:q} \
            --metadata {input.metadata:q} \
            --exclude-all \
            --include {input.strains:q} {input.include:q}\
            --output-sequences {output.sequences:q} \
            --output-metadata {output.metadata:q}
        """


rule align:
    """
    Aligning sequences to {input.reference}
    """
    input:
        sequences=build_dir + "/{build_name}/filtered.fasta",
        reference=config["reference"],
        genome_annotation=config["genome_annotation"],
    output:
        alignment=build_dir + "/{build_name}/aligned.fasta",
    params:
        # Alignment params from all-clades nextclade dataset
        excess_bandwidth=100,
        terminal_bandwidth=300,
        window_size=40,
        min_seed_cover=0.1,
        allowed_mismatches=8,
        gap_alignment_side="left",
    threads: workflow.cores
    log:
        "logs/{build_name}/align.txt",
    benchmark:
        "benchmarks/{build_name}/align.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        nextclade3 run \
            --jobs {threads} \
            --input-ref {input.reference:q} \
            --input-annotation {input.genome_annotation:q} \
            --excess-bandwidth {params.excess_bandwidth:q} \
            --terminal-bandwidth {params.terminal_bandwidth:q} \
            --window-size {params.window_size:q} \
            --min-seed-cover {params.min_seed_cover:q} \
            --allowed-mismatches {params.allowed_mismatches:q} \
            --gap-alignment-side {params.gap_alignment_side:q} \
            --output-fasta - \
            {input.sequences:q} \
            | seqkit seq -i > {output.alignment:q}
        """


rule mask:
    """
    Mask ends of the alignment:
      - from start: {params.from_start}
      - from end: {params.from_end}
    """
    input:
        sequences=build_dir + "/{build_name}/aligned.fasta",
        mask=config["mask"]["maskfile"],
    output:
        build_dir + "/{build_name}/masked.fasta",
    params:
        from_start=config["mask"]["from_beginning"],
        from_end=config["mask"]["from_end"],
    log:
        "logs/{build_name}/mask.txt",
    benchmark:
        "benchmarks/{build_name}/mask.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur mask \
            --sequences {input.sequences:q} \
            --mask {input.mask:q} \
            --mask-from-beginning {params.from_start:q} \
            --mask-from-end {params.from_end:q} \
            --output {output:q}
        """
