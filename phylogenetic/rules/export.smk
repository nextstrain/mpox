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


rule clade_i_color_ordering:
    """
    We don't want an ordering for division & location in the clade-I builds as these are constantly
    changing and we want to avoid auspice using greys for demes
    """
    input:
        ordering="defaults/color_ordering.tsv",
    output:
        ordering=build_dir + "/{build_name}/color_ordering.tsv",
    shell:
        r"""
        cat {input.ordering} \
            | grep -v '^division' \
            | grep -v '^location' \
            > {output.ordering}
        """


rule colors:
    input:
        ordering=lambda w: config.get("color_ordering", "defaults/color_ordering.tsv"),
        color_schemes="defaults/color_schemes.tsv",
        metadata=build_dir + "/{build_name}/metadata.tsv",
    output:
        colors=build_dir + "/{build_name}/colors.tsv",
    shell:
        """
        python3 scripts/assign-colors.py \
            --ordering {input.ordering} \
            --color-schemes {input.color_schemes} \
            --output {output.colors} \
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
        auspice_json=build_dir + "/{build_name}/raw_tree.json",
        root_sequence=build_dir + "/{build_name}/raw_tree_root-sequence.json",
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


rule final_strain_name:
    input:
        auspice_json=build_dir + "/{build_name}/raw_tree.json",
        metadata=build_dir + "/{build_name}/metadata.tsv",
        root_sequence=build_dir + "/{build_name}/raw_tree_root-sequence.json",
    output:
        auspice_json=build_dir + "/{build_name}/tree.json",
        root_sequence=build_dir + "/{build_name}/tree_root-sequence.json",
    params:
        strain_id=config["strain_id_field"],
        display_strain_field=config.get("display_strain_field", "strain"),
    shell:
        """
        python3 scripts/set_final_strain_name.py --metadata {input.metadata} \
                --metadata-id-columns {params.strain_id} \
                --input-auspice-json {input.auspice_json} \
                --display-strain-name {params.display_strain_field} \
                --output {output.auspice_json}
        cp {input.root_sequence} {output.root_sequence}
        """
