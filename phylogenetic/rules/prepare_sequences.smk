"""
This part of the workflow prepares sequences for constructing the phylogenetic tree.

REQUIRED INPUTS:

    include     = path to file of sequences to in force include
    reference   = path to reference sequence FASTA for Nextclade alignment
    genemap     = path to genemap GFF for Nextclade alignment
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
    output:
        sequences=build_dir + "/{build_name}/good_sequences.fasta",
        metadata=build_dir + "/{build_name}/good_metadata.tsv",
        log=build_dir + "/{build_name}/good_filter.log",
    params:
        exclude=config["filter"]["exclude"],
        min_date=config["filter"]["min_date"],
        min_length=config["filter"]["min_length"],
        strain_id=config["strain_id_field"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} \
            --exclude {params.exclude} \
            --min-date {params.min_date} \
            --min-length {params.min_length} \
            --query "(QC_rare_mutations == 'good' | QC_rare_mutations == 'mediocre')" \
            --output-log {output.log}
        """


rule subsample:
    input:
        metadata=rules.filter.output.metadata,
    output:
        strains=build_dir + "/{build_name}/{sample}_strains.txt",
        log=build_dir + "/{build_name}/{sample}_filter.log",
    params:
        group_by=lambda w: config["subsample"][w.sample]["group_by"],
        sequences_per_group=lambda w: config["subsample"][w.sample][
            "sequences_per_group"
        ],
        other_filters=lambda w: config["subsample"][w.sample].get("other_filters", ""),
        exclude=lambda w: f"--exclude-where {' '.join([f'lineage={l}' for l in config['subsample'][w.sample]['exclude_lineages']])}"
        if "exclude_lineages" in config["subsample"][w.sample]
        else "",
        strain_id=config["strain_id_field"],
    shell:
        """
        augur filter \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-strains {output.strains} \
            {params.group_by} \
            {params.sequences_per_group} \
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
        sequences=rules.filter.output.sequences,
        metadata=rules.filter.output.metadata,
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
      - filling gaps with N
    """
    input:
        sequences=rules.reverse_reverse_complements.output,
        reference=config["reference"],
        genemap=config["genemap"],
    output:
        alignment=build_dir + "/{build_name}/aligned.fasta",
        insertions=build_dir + "/{build_name}/insertions.fasta",
    params:
        max_indel=config["max_indel"],
        seed_spacing=config["seed_spacing"],
    threads: workflow.cores
    shell:
        """
        nextalign run \
            --jobs {threads} \
            --reference {input.reference} \
            --genemap {input.genemap} \
            --max-indel {params.max_indel} \
            --seed-spacing {params.seed_spacing} \
            --retry-reverse-complement \
            --output-fasta - \
            --output-insertions {output.insertions} \
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
