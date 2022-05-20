

rule filter:
    message:
        """
        Filtering to
          - {params.sequences_per_group} sequence(s) per {params.group_by!s}
          - from {params.min_date} onwards
          - excluding strains in {input.exclude}
          - minimum genome length of {params.min_length}
        """
    input:
        sequences = build_dir + "/{build_name}/sequences.fasta",
        metadata = build_dir + "/{build_name}/metadata.tsv",
        exclude = config["exclude"]
    output:
        sequences = build_dir + "/{build_name}/filtered.fasta"
    params:
        group_by = "country year",
        sequences_per_group = 1000,
        min_date = 1950,
        min_length = 10000
    shell:
        """
        augur filter \
            --sequences {input.sequences} \
            --metadata {input.metadata} \
            --exclude {input.exclude} \
            --output {output.sequences} \
            --group-by {params.group_by} \
            --sequences-per-group {params.sequences_per_group} \
            --min-date {params.min_date} \
            --min-length {params.min_length}
        """

rule align:
    message:
        """
        Aligning sequences to {input.reference}
          - filling gaps with N
        """
    input:
        sequences = rules.filter.output.sequences,
        reference = config["reference"]
    output:
        alignment = build_dir + "/{build_name}/aligned.fasta"
    shell:
        """
        ./nextalign_rs run \
            --max-indel 4000 \
            -vvv \
            --jobs 1 \
            --sequences {input.sequences} \
            --reference {input.reference} \
            --output-fasta {output.alignment}
        """

rule tree:
    message: "Building tree"
    input:
        alignment = rules.align.output.alignment
    output:
        tree = build_dir + "/{build_name}/tree_raw.nwk"
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
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
        tree = rules.tree.output.tree,
        alignment = rules.align.output,
        metadata = build_dir +"/{build_name}/metadata.tsv"
    output:
        tree = build_dir + "/{build_name}/tree.nwk",
        node_data = build_dir + "/{build_name}/branch_lengths.json"
    params:
        coalescent = "opt",
        date_inference = "marginal",
        clock_filter_iqd = 10
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --timetree \
            --output-node-data {output.node_data} \
            --coalescent {params.coalescent} \
            --date-inference {params.date_inference} \
            --clock-filter-iqd {params.clock_filter_iqd}
        """

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = rules.refine.output.tree,
        alignment = rules.align.output
    output:
        node_data = build_dir + "/{build_name}/nt_muts.json"
    params:
        inference = "joint"
    shell:
        """
        augur ancestral \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --output-node-data {output.node_data} \
            --inference {params.inference}
        """

rule translate:
    message: "Translating amino acid sequences"
    input:
        tree = rules.refine.output.tree,
        node_data = rules.ancestral.output.node_data,
        genbank_reference = config["genbank_reference"]
    output:
        node_data = build_dir + "/{build_name}/aa_muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.genbank_reference} \
            --output {output.node_data}
        """

rule traits:
    message:
        """
        Inferring ancestral traits for {params.columns!s}
          - increase uncertainty of reconstruction by {params.sampling_bias_correction} to partially account for sampling bias
        """
    input:
        tree = rules.refine.output.tree,
        metadata = build_dir+"/{build_name}/metadata.tsv"
    output:
        node_data = build_dir + "/{build_name}/traits.json",
    params:
        columns = "country",
        sampling_bias_correction = 3
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

rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = rules.refine.output.tree,
        metadata = build_dir+"/{build_name}/metadata.tsv",
        branch_lengths = rules.refine.output.node_data,
        traits = rules.traits.output.node_data,
        nt_muts = rules.ancestral.output.node_data,
        aa_muts = rules.translate.output.node_data,
        colors = config["colors"],
        lat_longs = config["lat_longs"],
        auspice_config = config["auspice_config"]
    output:
        auspice_json = auspice_dir + "/monkeypox_{build_name}.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.traits} {input.nt_muts} {input.aa_muts} \
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """
