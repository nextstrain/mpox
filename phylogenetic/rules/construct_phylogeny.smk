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
    # It's faster to use 4 threads rather than doing a full search - hence hardcoding 4
    threads: min(workflow.cores, 4)
    log:
        "logs/{build_name}/tree.txt",
    benchmark:
        "benchmarks/{build_name}/tree.txt"
    shell:
        r"""
        exec &> >(tee {log:q})

        augur tree \
            --alignment {input.alignment:q} \
            --exclude-sites {input.tree_mask:q} \
            --tree-builder-args "-T {threads} --pathogen" \
            --output {output.tree:q} \
            --nthreads {threads}
        """


def root_mode(wildcards):
    if "root" in config:
        if config["root"]["method"] == "outgroup":
            return f"--reroot-tips {config['root']['tips']}"
        elif config["root"]["method"] == "min-dev":
            return "--reroot min-dev"

rule fix_tree:
    """
    Fixing tree
    """
    input:
        treetime=TREETIME_BINARY,
        treetime_source=TREETIME_SOURCE,
        tree=build_dir + "/{build_name}/tree_raw.nwk",
        alignment=build_dir + "/{build_name}/masked.fasta",
    output:
        tree=build_dir + "/{build_name}/divergence_tree.nwk",
        node_data=build_dir + "/{build_name}/divergence_branch_lengths.json",
    params:
        root = root_mode
    log:
        "logs/{build_name}/fix_tree.txt",
    benchmark:
        "benchmarks/{build_name}/fix_tree.txt"
    threads: 1
    shell:
        r"""
        exec &> >(tee {log:q})

        cat {input.treetime_source:q} >&2
        {input.treetime:q} optimize -j {threads} \
            --alignment {input.alignment:q} --divergence-units mutations \
            {params.root} \
            --tree {input.tree:q} --no-indels \
            --output-tree-nwk {output.tree:q} --output-augur-node-data {output.node_data:q}
        """


rule timetree:
    input:
        treetime=TREETIME_BINARY,
        treetime_source=TREETIME_SOURCE,
        tree=build_dir + "/{build_name}/divergence_tree.nwk",
        alignment=build_dir + "/{build_name}/masked.fasta",
        metadata=build_dir + "/{build_name}/metadata.tsv"
    output:
        tree=build_dir + "/{build_name}/time_tree.nwk",
        node_data=build_dir + "/{build_name}/timetree_branch_lengths.json",
        auspice_tree=build_dir + "/{build_name}/tree.auspice.json",
    params:
        clock_rate = config.get("clock_rate", None),
        clock_std_dev = config.get("clock_std_dev", None),
        metadata_id_columns = config["strain_id_field"],
    shell:
        r"""
        exec &> >(tee {log:q})

        cat {input.treetime_source:q} >&2
        {input.treetime:q} timetree \
            --tree {input.tree:q} \
            --alignment {input.alignment:q} \
            --metadata {input.metadata:q} \
            --metadata-id-columns {params.metadata_id_columns:q} \
            --output-tree-nwk {output.tree:q} \
            --clock-rate {params.clock_rate} \
            --clock-std-dev {params.clock_std_dev} \
            --keep-root \
            --keep-polytomies \
            --divergence-units mutations --no-indels \
            --output-augur-node-data {output.node_data:q} \
            --output-tree-auspice {output.auspice_tree:q}
        """

# rule refine:
#     """
#     Refining tree
#         - estimate timetree
#         - use {params.coalescent} coalescent timescale
#         - estimate {params.date_inference} node dates
#         - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
#     """
#     input:
#         tree=(
#             build_dir + "/{build_name}/tree_fixed.nwk"
#             if config["fix_tree"]
#             else build_dir + "/{build_name}/tree_raw.nwk"
#         ),
#         alignment=build_dir + "/{build_name}/masked.fasta",
#         metadata=build_dir + "/{build_name}/metadata.tsv",
#     output:
#         tree=build_dir + "/{build_name}/tree.nwk",
#         node_data=build_dir + "/{build_name}/branch_lengths.json",
#     params:
#         coalescent="opt",
#         date_inference="marginal",
#         clock_filter_iqd=0,
#         root=config["root"],
#         clock_rate=(
#             ("--clock-rate " + str(config["clock_rate"]))
#             if "clock_rate" in config
#             else ""
#         ),
#         clock_std_dev=(
#             ("--clock-std-dev " + str(config["clock_std_dev"]))
#             if "clock_std_dev" in config
#             else ""
#         ),
#         strain_id=config["strain_id_field"],
#         divergence_units=config["divergence_units"],
#     log:
#         "logs/{build_name}/refine.txt",
#     benchmark:
#         "benchmarks/{build_name}/refine.txt"
#     shell:
#         r"""
#         exec &> >(tee {log:q})

#         augur refine \
#             --tree {input.tree:q} \
#             --alignment {input.alignment:q} \
#             --metadata {input.metadata:q} \
#             --metadata-id-columns {params.strain_id:q} \
#             --output-tree {output.tree:q} \
#             --timetree \
#             --root {params.root:q} \
#             --precision 3 \
#             --keep-polytomies \
#             --use-fft \
#             {params.clock_rate} \
#             {params.clock_std_dev} \
#             --output-node-data {output.node_data:q} \
#             --coalescent {params.coalescent:q} \
#             --date-inference {params.date_inference:q} \
#             --date-confidence \
#             --divergence-units {params.divergence_units:q} \
#             --clock-filter-iqd {params.clock_filter_iqd:q}
#         """
