"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    include     = path to file of sequences to in force include
    reference   = path to reference sequence FASTA for Nextclade alignment
    genome_annotation     = path to genome_annotation GFF for Nextclade alignment
    maskfile    = path to maskfile of sites to be masked

OUTPUTS:

    prepared_sequences = {build_dir}/{build_name}/masked.fasta

"""


rule download:
    """
    Downloading sequences and metadata from data.nextstrain.org
    """
    output:
        sequences="data/sequences.fasta.zst",
        metadata="data/metadata.tsv.zst",
    params:
        sequences_url="https://data.nextstrain.org/files/workflows/mpox/sequences.fasta.zst",
        metadata_url="https://data.nextstrain.org/files/workflows/mpox/metadata.tsv.zst",
    log:
        "logs/download.txt",
    benchmark:
        "benchmarks/download.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences:q}
        curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata:q}
        """


rule decompress:
    """
    Decompressing sequences and metadata
    """
    input:
        sequences="data/sequences.fasta.zst",
        metadata="data/metadata.tsv.zst",
    output:
        sequences="data/sequences.fasta",
        metadata="data/metadata.tsv",
    log:
        "logs/decompress.txt",
    benchmark:
        "benchmarks/decompress.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        zstd --decompress --stdout {input.sequences:q} > {output.sequences:q}
        zstd --decompress --stdout {input.metadata:q} > {output.metadata:q}
        """


rule filter:
    """
    Removing strains that do not satisfy certain requirements.
    """
    input:
        sequences="data/sequences.fasta",
        metadata="data/metadata.tsv",
        exclude="defaults/exclude_accessions.txt",
    output:
        sequences=build_dir + "/{build_name}/good_sequences.fasta",
        metadata=build_dir + "/{build_name}/good_metadata.tsv",
        log=build_dir + "/{build_name}/good_filter.log",
    params:
        min_date=config["filter"]["min_date"],
        min_length=config["filter"]["min_length"],
        strain_id=config["strain_id_field"],
        exclude_where=lambda w: (
            f"--exclude-where {config['filter']['exclude_where']!r}"
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
            --query "(QC_rare_mutations == 'good' | QC_rare_mutations == 'mediocre')" \
            --output-log {output.log:q}
        """


# Basic config sanity checking in lieu of a proper schema
if any([k in config for k in ["private_sequences", "private_metadata"]]):
    assert all(
        [k in config for k in ["private_sequences", "private_metadata"]]
    ), "Your config defined one of ['private_sequences', 'private_metadata'] but both must be supplied together"


# At this point we merge in private data (iff requested)
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
        group_by=lambda w: config["subsample"][w.sample]["group_by"],
        sequences_per_group=lambda w: config["subsample"][w.sample][
            "sequences_per_group"
        ],
        query=lambda w: (
            f"--query {config['subsample'][w.sample]['query']}"
            if "query" in config["subsample"][w.sample]
            else ""
        ),
        other_filters=lambda w: config["subsample"][w.sample].get("other_filters", ""),
        exclude=lambda w: (
            f"--exclude-where {' '.join([f'lineage={l}' for l in config['subsample'][w.sample]['exclude_lineages']])}"
            if "exclude_lineages" in config["subsample"][w.sample]
            else ""
        ),
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
            {params.group_by} \
            {params.sequences_per_group} \
            {params.query} \
            {params.exclude} \
            {params.other_filters} \
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
        include=config["include"],
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


rule reverse_reverse_complements:
    input:
        metadata=build_dir + "/{build_name}/metadata.tsv",
        sequences=build_dir + "/{build_name}/filtered.fasta",
    output:
        build_dir + "/{build_name}/reversed.fasta",
    log:
        "logs/{build_name}/reverse_reverse_complements.txt",
    benchmark:
        "benchmarks/{build_name}/reverse_reverse_complements.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        python3 scripts/reverse_reversed_sequences.py \
            --metadata {input.metadata:q} \
            --sequences {input.sequences:q} \
            --output {output:q}
        """


rule align:
    """
    Aligning sequences to {input.reference}
    """
    input:
        sequences=build_dir + "/{build_name}/reversed.fasta",
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
