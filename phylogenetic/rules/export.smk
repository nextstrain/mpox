"""
This part of the workflow collects the phylogenetic tree and annotations to
export a Nextstrain dataset.

REQUIRED INPUTS:

    metadata            = {build_dir}/{build_name}/metadata.tsv
    tree                = {build_dir}/{build_name}/tree.nwk
    branch_lengths      = {build_dir}/{build_name}/branch_lengths.json
    nt_muts             = {build_dir}/{build_name}/nt_muts.json
    aa_muts             = {build_dir}/{build_name}/aa_muts.json
    traits              = {build_dir}/{build_name}/traits.json
    clades              = {build_dir}/{build_name}/clades.json
    mutation_context    = {build_dir}/{build_name}/mutation_context.json
    color_ordering      = defaults/color_ordering.tsv
    color_schemes       = defaults/color_schemes.tsv
    lat_longs           = path to lat/long TSV
    description         = path to description Markdown
    auspice_config      = path to Auspice config JSON

OPTIONAL INPUTS:

    recency             = {build_dir}/{build_name}/recency.json

OUTPUTS:

    auspice_json        = {build_dir}/{build_name}/tree.json
    root_sequence       = {build_dir}/{build_name}/tree_root-sequence.json

"""


rule remove_time:
    input:
        build_dir + "/{build_name}/branch_lengths.json",
    output:
        build_dir + "/{build_name}/branch_lengths_no_time.json",
    shell:
        """
        python3 scripts/remove_timeinfo.py --input-node-data {input} --output-node-data {output}
        """


rule colors:
    input:
        ordering="defaults/color_ordering.tsv",
        color_schemes="defaults/color_schemes.tsv",
        metadata=build_dir + "/{build_name}/metadata.tsv",
    output:
        colors=build_dir + "/{build_name}/colors.tsv",
    params:
        ignore_categories=lambda w: config.get("colors", {}).get(
            "ignore_categories", ""
        ),
    shell:
        r"""
        python3 scripts/assign-colors.py \
            --ordering {input.ordering} \
            --color-schemes {input.color_schemes} \
            --output {output.colors} \
            --ignore-categories {params.ignore_categories} \
            --metadata {input.metadata} 2>&1
        """


rule export:
    """
    Exporting data files for auspice
    """
    input:
        tree=build_dir + "/{build_name}/tree.nwk",
        metadata=build_dir + "/{build_name}/metadata.tsv",
        branch_lengths=(
            build_dir + "/{build_name}/branch_lengths.json"
            if config.get("timetree", False)
            else build_dir + "/{build_name}/branch_lengths_no_time.json"
        ),
        traits=(
            build_dir + "/{build_name}/traits.json"
            if config.get("traits", {}).get("columns", False)
            else []
        ),
        nt_muts=build_dir + "/{build_name}/nt_muts.json",
        aa_muts=build_dir + "/{build_name}/aa_muts.json",
        clades=build_dir + "/{build_name}/clades.json",
        mutation_context=build_dir + "/{build_name}/mutation_context.json",
        recency=(
            build_dir + "/{build_name}/recency.json"
            if config.get("recency", False)
            else []
        ),
        colors=build_dir + "/{build_name}/colors.tsv",
        lat_longs=config["lat_longs"],
        description=config["description"],
        auspice_config=config["auspice_config"],
    output:
        auspice_json=build_dir + "/{build_name}/tree.json",
        root_sequence=build_dir + "/{build_name}/tree_root-sequence.json",
    params:
        strain_id=config["strain_id_field"],
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --metadata-id-columns {params.strain_id} \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} {input.mutation_context} {input.clades} {input.recency}\
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --description {input.description} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """
