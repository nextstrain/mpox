"""
This part of the workflow constructs the phylogenetic tree.

REQUIRED INPUTS:

    sequences   = {build_dir}/{build_name}/masked.fasta
    metadata    = {build_dir}/{build_name}/metadata.tsv
    tree_mask   = path to maskfile of sites to exclude for tree building

OUTPUTS:

    tree            = {build_dir}/{build_name}/tree.nwk
    branch_lengths  = {build_dir}/{build_name}/branch_lengths.json

"""


rule tree:
    """
    Building tree
    """
    input:
        alignment=build_dir + "/{build_name}/masked.fasta",
        tree_mask=config["tree_mask"],
    output:
        tree=build_dir + "/{build_name}/tree_raw.nwk",
    threads: workflow.cores
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --exclude-sites {input.tree_mask} \
            --tree-builder-args="-redo" \
            --output {output.tree} \
            --nthreads {threads}
        """


rule fix_tree:
    """
    Fixing tree
    """
    input:
        tree=build_dir + "/{build_name}/tree_raw.nwk",
        alignment=build_dir + "/{build_name}/masked.fasta",
    output:
        tree=build_dir + "/{build_name}/tree_fixed.nwk",
    params:
        root=lambda w: config.get("treefix_root", ""),
    shell:
        """
        python3 scripts/fix_tree.py \
            --alignment {input.alignment} \
            --input-tree {input.tree} \
            {params.root} \
            --output {output.tree}
        """


rule refine:
    """
    Refining tree
        - estimate timetree
        - use {params.coalescent} coalescent timescale
        - estimate {params.date_inference} node dates
        - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
    """
    input:
        tree=build_dir + "/{build_name}/tree_fixed.nwk"
        if config["fix_tree"]
        else build_dir + "/{build_name}/tree_raw.nwk",
        alignment=build_dir + "/{build_name}/masked.fasta",
        metadata=build_dir + "/{build_name}/metadata.tsv",
    output:
        tree=build_dir + "/{build_name}/tree.nwk",
        node_data=build_dir + "/{build_name}/branch_lengths.json",
    params:
        coalescent="opt",
        date_inference="marginal",
        clock_filter_iqd=0,
        root=config["root"],
        clock_rate=f"--clock-rate {config['clock_rate']}"
        if "clock_rate" in config
        else "",
        clock_std_dev=f"--clock-std-dev {config['clock_std_dev']}"
        if "clock_std_dev" in config
        else "",
        strain_id=config["strain_id_field"],
        divergence_units=config["divergence_units"],
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --output-tree {output.tree} \
            --timetree \
            --root {params.root} \
            --precision 3 \
            --keep-polytomies \
            --use-fft \
            {params.clock_rate} \
            {params.clock_std_dev} \
            --output-node-data {output.node_data} \
            --coalescent {params.coalescent} \
            --date-inference {params.date_inference} \
            --date-confidence \
            --divergence-units {params.divergence_units} \
            --clock-filter-iqd {params.clock_filter_iqd}
        """
