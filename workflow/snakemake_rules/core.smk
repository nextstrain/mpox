"""
This part of the workflow expects input files

        sequences = "data/sequences.fasta",
        metadata =  "data/metadata.tsv",

and will produce output files as

        auspice_json = auspice_dir + "/monkeypox_{build_name}.json"

Parameter are expected to sit in the `config` data structure.
In addition, `build_dir` and `auspice_dir` need to be defined upstream.
"""


rule wrangle_metadata:
    input:
        metadata="data/metadata.tsv",
    output:
        metadata="results/metadata.tsv",
    params:
        strain_id=lambda w: config.get("strain_id_field", "strain"),
    shell:
        """
        python3 scripts/wrangle_metadata.py --metadata {input.metadata} \
                    --strain-id {params.strain_id} \
                    --output {output.metadata}
        """


rule exclude_bad:
    message:
        """
        Removing strains that violate one of
          - from {params.min_date} onwards
          - excluding strains in {input.exclude}
          - minimum genome length of {params.min_length}
        """
    input:
        sequences="data/sequences.fasta",
        metadata="results/metadata.tsv",
        exclude=config["exclude"],
    output:
        sequences=build_dir + "/{build_name}/good_sequences.fasta",
        metadata=build_dir + "/{build_name}/good_metadata.tsv",
        log=build_dir + "/{build_name}/good_filter.log",
    params:
        min_date=config["min_date"],
        min_length=config["min_length"],
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --exclude {input.exclude} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} \
            --min-date {params.min_date} \
            --min-length {params.min_length} \
            --output-log {output.log}
        """


rule include_A_strains:
    input:
        metadata=rules.exclude_bad.output.metadata,
    output:
        include_strains=build_dir + "/{build_name}/include_strains.txt",
    shell:
        """
        tsv-filter -H \
            --str-in-fld lineage:'A'\
            {input.metadata} \
        | tsv-select -f 1 \
        > {output.include_strains}
        """


rule filter:
    message:
        """
        Filtering to
          - {params.sequences_per_group} sequence(s) per {params.group_by!s}
        """
    input:
        sequences=rules.exclude_bad.output.sequences,
        metadata=rules.exclude_bad.output.metadata,
        include=rules.include_A_strains.output.include_strains,
    output:
        sequences=build_dir + "/{build_name}/filtered.fasta",
        metadata=build_dir + "/{build_name}/metadata.tsv",
        log=build_dir + "/{build_name}/filter.log",
    params:
        group_by=config.get("group_by", "--group-by clade lineage"),
        sequences_per_group=config["sequences_per_group"],
        other_filters=config.get("filters", ""),
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --include {input.include} \
            --output-sequences {output.sequences} \
            --output-metadata {output.metadata} \
            {params.group_by} \
            {params.sequences_per_group} \
            {params.other_filters} \
            --output-log {output.log}
        """


rule separate_reverse_complement:
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
    message:
        """
        Aligning sequences to {input.reference}
          - filling gaps with N
        """
    input:
        sequences=rules.separate_reverse_complement.output,
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
    message:
        """
        Mask ends of the alignement:
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


rule tree:
    message:
        "Building tree"
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
    message:
        "Building tree"
    input:
        tree=rules.tree.output.tree,
        alignment=build_dir + "/{build_name}/masked.fasta",
    output:
        tree=build_dir + "/{build_name}/tree_fixed.nwk",
    shell:
        """
        python3 scripts/fix_tree.py \
            --alignment {input.alignment} \
            --input-tree {input.tree} \
            --output {output.tree}
        """


rule refine:
    message:
        """
        Refining tree
          - estimate timetree
          - use {params.coalescent} coalescent timescale
          - estimate {params.date_inference} node dates
          - filter tips more than {params.clock_filter_iqd} IQDs from clock expectation
        """
    input:
        tree=lambda w: rules.fix_tree.output.tree
        if config["fix_tree"]
        else rules.tree.output.tree,
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
        clock_rate=lambda w: f"--clock-rate {config['clock_rate']}"
        if "clock_rate" in config
        else "",
        clock_std_dev=lambda w: f"--clock-std-dev {config['clock_std_dev']}"
        if "clock_std_dev" in config
        else "",
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --timetree \
            --root {params.root} \
            --precision 3 \
            --keep-polytomies \
            {params.clock_rate} \
            {params.clock_std_dev} \
            --output-node-data {output.node_data} \
            --coalescent {params.coalescent} \
            --date-inference {params.date_inference} \
            --date-confidence \
            --clock-filter-iqd {params.clock_filter_iqd}
        """


rule ancestral:
    message:
        "Reconstructing ancestral sequences and mutations"
    input:
        tree=rules.refine.output.tree,
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
    message:
        "Translating amino acid sequences"
    input:
        tree=rules.refine.output.tree,
        node_data=rules.ancestral.output.node_data,
        genemap=config["genemap"],
    output:
        node_data=build_dir + "/{build_name}/aa_muts.json",
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.genemap} \
            --output {output.node_data}
        """


rule traits:
    message:
        """
        Inferring ancestral traits for {params.columns!s}
          - increase uncertainty of reconstruction by {params.sampling_bias_correction} to partially account for sampling bias
        """
    input:
        tree=rules.refine.output.tree,
        metadata=build_dir + "/{build_name}/metadata.tsv",
    output:
        node_data=build_dir + "/{build_name}/traits.json",
    params:
        columns="country",
        sampling_bias_correction=3,
    shell:
        """
        augur traits \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --output {output.node_data} \
            --columns {params.columns} \
            --confidence \
            --sampling-bias-correction {params.sampling_bias_correction}
        """


rule clades:
    message:
        "Adding internal clade labels"
    input:
        tree=rules.refine.output.tree,
        aa_muts=rules.translate.output.node_data,
        nuc_muts=rules.ancestral.output.node_data,
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
        rules.clades.output.node_data,
    output:
        node_data=build_dir + "/{build_name}/clades.json",
    shell:
        """
        python scripts/clades_renaming.py \
        --input-node-data {input} \
        --output-node-data {output.node_data}
        """


rule mutation_context:
    input:
        tree=rules.refine.output.tree,
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


rule remove_time:
    input:
        "results/{build_name}/branch_lengths.json",
    output:
        "results/{build_name}/branch_lengths_no_time.json",
    shell:
        """
        python3 scripts/remove_timeinfo.py --input-node-data {input} --output-node-data {output}
        """


rule recency:
    message:
        "Use metadata on submission date to construct submission recency field"
    input:
        metadata=build_dir + "/{build_name}/metadata.tsv",
    output:
        node_data=build_dir + "/{build_name}/recency.json",
    shell:
        """
        python3 scripts/construct-recency-from-submission-date.py \
            --metadata {input.metadata} \
            --output {output} 2>&1
        """


rule colors:
    input:
        ordering="config/color_ordering.tsv",
        color_schemes="config/color_schemes.tsv",
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
    message:
        "Exporting data files for for auspice"
    input:
        tree=rules.refine.output.tree,
        metadata=build_dir + "/{build_name}/metadata.tsv",
        branch_lengths=lambda w: "results/{build_name}/branch_lengths.json"
        if config.get("timetree", False)
        else "results/{build_name}/branch_lengths_no_time.json",
        traits=rules.traits.output.node_data,
        nt_muts=rules.ancestral.output.node_data,
        aa_muts=rules.translate.output.node_data,
        clades=build_dir + "/{build_name}/clades.json",
        mutation_context=rules.mutation_context.output.node_data,
        recency=lambda w: rules.recency.output.node_data
        if config.get("recency", False)
        else [],
        colors=rules.colors.output.colors,
        lat_longs=config["lat_longs"],
        description=config["description"],
        auspice_config=config["auspice_config"],
    output:
        auspice_json=build_dir + "/{build_name}/raw_tree.json",
        root_sequence=build_dir + "/{build_name}/raw_tree_root-sequence.json",
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} {input.mutation_context} {input.clades} {input.recency}\
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
        display_strain_field=lambda w: config.get("display_strain_field", "strain"),
    shell:
        """
        python3 scripts/set_final_strain_name.py --metadata {input.metadata} \
                --input-auspice-json {input.auspice_json} \
                --display-strain-name {params.display_strain_field} \
                --output {output.auspice_json}
        cp {input.root_sequence} {output.root_sequence}
        """
