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
        sequences="data/sequences.fasta.xz",
        metadata="data/metadata.tsv.gz",
    params:
        sequences_url="https://data.nextstrain.org/files/workflows/mpox/sequences.fasta.xz",
        metadata_url="https://data.nextstrain.org/files/workflows/mpox/metadata.tsv.gz",
    shell:
        """
        curl -fsSL --compressed {params.sequences_url:q} --output {output.sequences}
        curl -fsSL --compressed {params.metadata_url:q} --output {output.metadata}
        """


rule decompress:
    """
    Decompressing sequences and metadata
    """
    input:
        sequences="data/sequences.fasta.xz",
        metadata="data/metadata.tsv.gz",
    output:
        sequences="data/sequences.fasta",
        metadata="data/metadata.tsv",
    shell:
        """
        gzip --decompress --keep {input.metadata}
        xz --decompress --keep {input.sequences}
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
            f"--exclude-where {config['filter']['exclude_where']}"
            if "exclude_where" in config["filter"]
            else ""
        ),
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} \
            --exclude {input.exclude} \
            {params.exclude_where} \
            --min-date {params.min_date} \
            --min-length {params.min_length} \
            --query "(QC_rare_mutations == 'good' | QC_rare_mutations == 'mediocre')" \
            --output-log {output.log}
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
    shell:
        """
        python3 scripts/combine_data_sources.py \
            --metadata nextstrain={input.metadata} private={input.private_metadata} \
            --sequences {input.sequences} {input.private_sequences} \
            --output-metadata {output.metadata} \
            --output-sequences {output.sequences}
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
    shell:
        """
        augur filter \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-strains {output.strains} \
            {params.group_by} \
            {params.sequences_per_group} \
            {params.query} \
            {params.exclude} \
            {params.other_filters} \
            --output-log {output.log}
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
    shell:
        """
        augur filter \
            --metadata-id-columns {params.strain_id} \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --exclude-all \
            --include {input.strains} {input.include}\
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata}
        """


rule reverse_reverse_complements:
    input:
        metadata=build_dir + "/{build_name}/metadata.tsv",
        sequences=build_dir + "/{build_name}/filtered.fasta",
    output:
        build_dir + "/{build_name}/reversed.fasta",
    shell:
        """
        python3 scripts/reverse_reversed_sequences.py \
            --metadata {input.metadata} \
            --sequences {input.sequences} \
            --output {output}
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
    shell:
        """
        nextclade3 run \
            --jobs {threads} \
            --input-ref {input.reference} \
            --input-annotation {input.genome_annotation} \
            --excess-bandwidth {params.excess_bandwidth} \
            --terminal-bandwidth {params.terminal_bandwidth} \
            --window-size {params.window_size} \
            --min-seed-cover {params.min_seed_cover} \
            --allowed-mismatches {params.allowed_mismatches} \
            --gap-alignment-side {params.gap_alignment_side} \
            --output-fasta - \
            {input.sequences} | seqkit seq -i > {output.alignment}
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
    shell:
        """
        augur mask \
            --sequences {input.sequences} \
            --mask {input.mask} \
            --mask-from-beginning {params.from_start} \
            --mask-from-end {params.from_end} --output {output}
        """
