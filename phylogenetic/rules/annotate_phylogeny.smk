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
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
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
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.genome_annotation} \
            --output {output.node_data}
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
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output {output.node_data} \
            --columns {params.columns} \
            --confidence \
            --sampling-bias-correction {params.sampling_bias_correction}
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
        "logs/clades_{build_name}.txt",
    shell:
        """
        augur clades \
            --tree {input.tree} \
            --mutations {input.nuc_muts} {input.aa_muts} \
            --clades {input.clades} \
            --output-node-data {output.node_data} 2>&1 | tee {log}
        """


rule rename_clades:
    input:
        build_dir + "/{build_name}/clades_raw.json",
    output:
        node_data=build_dir + "/{build_name}/clades.json",
    wildcard_constraints:
        build_name="^(?!clade-i)$",
    shell:
        """
        python scripts/clades_renaming.py \
        --input-node-data {input} \
        --output-node-data {output.node_data}
        """


rule clades_for_clade_I:
    input:
        tree=build_dir + "/clade-i/tree.nwk",
    output:
        node_data=build_dir + "/clade-i/clades.json",
    shell:
        """
        python scripts/assign-clade-I-clades.py \
            < {input.tree} \
            > {output.node_data}
        """


rule mutation_context:
    input:
        tree=build_dir + "/{build_name}/tree.nwk",
        node_data=build_dir + "/{build_name}/nt_muts.json",
    output:
        node_data=build_dir + "/{build_name}/mutation_context.json",
    shell:
        """
        python3 scripts/mutation_context.py \
            --tree {input.tree} \
            --mutations {input.node_data} \
            --output {output.node_data}
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
    shell:
        """
        python3 scripts/construct-recency-from-submission-date.py \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output {output} 2>&1
        """
