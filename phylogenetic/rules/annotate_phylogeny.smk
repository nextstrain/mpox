"""
This part of the workflow creates additional annotations for the phylogenetic tree.

REQUIRED INPUTS:

    sequences  = {build_dir}/{build_name}/masked.fasta
    metadata   = {build_dir}/{build_name}/metadata.tsv
    tree       = {build_dir}/{build_name}/tree.nwk
    clades     = path to clades definition TSV

OUTPUTS:

    nt_muts             = {build_dir}/{build_name}/nt_muts.json
    aa_muts             = {build_dir}/{build_name}/aa_muts.json
    traits              = {build_dir}/{build_name}/traits.json
    clades              = {build_dir}/{build_name}/clades.json
    mutation_context    = {build_dir}/{build_name}/mutation_context.json
    recency             = {build_dir}/{build_name}/recency.json

"""


rule ancestral:
    """
    Reconstructing ancestral sequences and mutations
    """
    input:
        tree=build_dir + "/{build_name}/tree.nwk",
        alignment=build_dir + "/{build_name}/masked.fasta",
    output:
        node_data=build_dir + "/{build_name}/nt_muts.json",
    params:
        inference="joint",
        root_sequence=lambda w: (
            ("--root-sequence " + config["ancestral_root_seq"])
            if config.get("ancestral_root_seq")
            else ""
        ),
    log:
        "logs/{build_name}/ancestral.txt",
    benchmark:
        "benchmarks/{build_name}/ancestral.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur ancestral \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --inference {params.inference:q} \
            {params.root_sequence} \
            --output-node-data {output.node_data:q}
        """


rule translate:
    """
    Translating amino acid sequences
    """
    input:
        tree=build_dir + "/{build_name}/tree.nwk",
        node_data=build_dir + "/{build_name}/nt_muts.json",
        genome_annotation=config["genome_annotation"],
    output:
        node_data=build_dir + "/{build_name}/aa_muts.json",
    log:
        "logs/{build_name}/translate.txt",
    benchmark:
        "benchmarks/{build_name}/translate.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur translate \
            --tree {input.tree:q} \
            --ancestral-sequences {input.node_data:q} \
            --reference-sequence {input.genome_annotation:q} \
            --output {output.node_data:q}
        """


rule traits:
    """
    Inferring ancestral traits for {params.columns!s}
      - increase uncertainty of reconstruction by {params.sampling_bias_correction} to partially account for sampling bias
    """
    input:
        tree=build_dir + "/{build_name}/tree.nwk",
        metadata=build_dir + "/{build_name}/metadata.tsv",
    output:
        node_data=build_dir + "/{build_name}/traits.json",
    params:
        columns=config["traits"]["columns"],
        sampling_bias_correction=config["traits"]["sampling_bias_correction"],
        strain_id=config["strain_id_field"],
    log:
        "logs/{build_name}/traits.txt",
    benchmark:
        "benchmarks/{build_name}/traits.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur traits \
            --tree {input.tree:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output {output.node_data:q} \
            --columns {params.columns:q} \
            --confidence \
            --sampling-bias-correction {params.sampling_bias_correction:q}
        """


rule clades:
    """
    Adding internal clade labels
    """
    input:
        tree=build_dir + "/{build_name}/tree.nwk",
        aa_muts=build_dir + "/{build_name}/aa_muts.json",
        nuc_muts=build_dir + "/{build_name}/nt_muts.json",
        clades=config["clades"],
    output:
        node_data=build_dir + "/{build_name}/clades_raw.json",
    log:
        "logs/{build_name}/clades.txt",
    benchmark:
        "benchmarks/{build_name}/clades.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur clades \
            --tree {input.tree:q} \
            --mutations {input.nuc_muts:q} {input.aa_muts:q} \
            --clades {input.clades:q} \
            --output-node-data {output.node_data:q}
        """


rule rename_clades:
    input:
        build_dir + "/{build_name}/clades_raw.json",
    output:
        node_data=build_dir + "/{build_name}/clades.json",
    log:
        "logs/{build_name}/rename_clades.txt",
    benchmark:
        "benchmarks/{build_name}/rename_clades.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        python scripts/clades_renaming.py \
            --input-node-data {input:q} \
            --output-node-data {output.node_data:q}
        """


rule mutation_context:
    input:
        tree=build_dir + "/{build_name}/tree.nwk",
        node_data=build_dir + "/{build_name}/nt_muts.json",
    output:
        node_data=build_dir + "/{build_name}/mutation_context.json",
    log:
        "logs/{build_name}/mutation_context.txt",
    benchmark:
        "benchmarks/{build_name}/mutation_context.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        python3 scripts/mutation_context.py \
            --tree {input.tree:q} \
            --mutations {input.node_data:q} \
            --output {output.node_data:q}
        """


rule recency:
    """
    Use metadata on submission date to construct submission recency field
    """
    input:
        metadata=build_dir + "/{build_name}/metadata.tsv",
    output:
        node_data=build_dir + "/{build_name}/recency.json",
    params:
        strain_id=config["strain_id_field"],
    log:
        "logs/{build_name}/recency.txt",
    benchmark:
        "benchmarks/{build_name}/recency.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        python3 scripts/construct-recency-from-submission-date.py \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.strain_id:q} \
            --output {output:q} 2>&1
        """
