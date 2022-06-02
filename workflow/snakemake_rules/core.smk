'''
This part of the workflow expects input files

        sequences = "data/sequences.fasta",
        metadata =  "data/metadata.tsv",

and will produce output files as

        auspice_json = auspice_dir + "/monkeypox_{build_name}.json"

Parameter are expected to sit in the `config` data structure.
In addition, `build_dir` and `auspice_dir` need to be defined upstream.
'''

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
        sequences = "data/sequences.fasta",
        metadata =  "data/metadata.tsv",
        exclude = config["exclude"]
    output:
        sequences = build_dir + "/{build_name}/filtered.fasta",
        log = build_dir + "/{build_name}/filtered.log"
    params:
        group_by = "country year",
        sequences_per_group = 1000,
        min_date = config['min_date'],
        min_length = config['min_length']
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
            --min-length {params.min_length} \
            --output-log {output.log}
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
        alignment = build_dir + "/{build_name}/aligned.fasta",
        insertions = build_dir + "/{build_name}/insertions.fasta"
    params:
        max_indel = config["max_indel"],
        seed_spacing = config["seed_spacing"]
    threads: workflow.cores
    shell:
        """
        nextalign run \
            -v \
            --jobs {threads} \
            --sequences {input.sequences} \
            --reference {input.reference} \
            --max-indel {params.max_indel} \
            --seed-spacing {params.seed_spacing} \
            --output-fasta {output.alignment} \
            --output-insertions {output.insertions}
        """

rule mask:
    message:
        """
        Mask ends of the alignement:
          - from start: {params.from_start}
          - from end: {params.from_end}
        """
    input:
        sequences = build_dir + "/{build_name}/aligned.fasta",
        mask = config["mask"]["maskfile"]
    output:
        build_dir + "/{build_name}/masked.fasta"
    params:
        from_start = config["mask"]["from_beginning"],
        from_end = config["mask"]["from_end"]
    shell:
        """
        augur mask --sequences {input.sequences} --mask {input.mask} --mask-from-beginning {params.from_start} --mask-from-end {params.from_end} --output {output}
        """

rule tree:
    message: "Building tree"
    input:
        alignment = build_dir + "/{build_name}/masked.fasta"
    output:
        tree = build_dir + "/{build_name}/tree_raw.nwk"
    threads: 8
    shell:
        """
        augur tree \
            --alignment {input.alignment} \
            --output {output.tree} \
            --nthreads {threads}
        """

if "two_rate_model" in config:
    rule refine_relax:
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
            alignment = build_dir + "/{build_name}/masked.fasta",
            metadata = "data/metadata.tsv"
        output:
            tree = build_dir + "/{build_name}/tree.nwk",
            node_data = build_dir + "/{build_name}/branch_lengths.json"
        params:
            coalescent = "opt",
            date_inference = "marginal",
            clock_filter_iqd = 10,
            speed_up = config["speed_up"],
            root = config["root"],
            clock_rate = lambda w: f"--base-rate {config['clock_rate']}" if "clock_rate" in config else ""
        shell:
            """
            python3 scripts/two_rate_model.py --tree {input.tree}\
                --alignment {input.alignment} \
                --metadata {input.metadata} \
                --output-tree {output.tree} \
                {params.clock_rate} \
                --outbreak-speed-up {params.speed_up} \
                --output-node-data {output.node_data} \
                --root {params.root} \
                --coalescent {params.coalescent}
            """
else:
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
            alignment = build_dir + "/{build_name}/masked.fasta",
            metadata = "data/metadata.tsv"
        output:
            tree = build_dir + "/{build_name}/tree.nwk",
            node_data = build_dir + "/{build_name}/branch_lengths.json"
        params:
            coalescent = "opt",
            date_inference = "marginal",
            clock_filter_iqd = 10,
            root = config["root"],
            clock_rate = lambda w: f"--clock-rate {config['clock_rate']}" if "clock_rate" in config else "",
            clock_std_dev = lambda w: f"--clock-std-dev {config['clock_std_dev']}" if "clock_std_dev" in config else ""
        shell:
            """
            augur refine \
                --tree {input.tree} \
                --alignment {input.alignment} \
                --metadata {input.metadata} \
                --output-tree {output.tree} \
                --timetree \
                --root {params.root} \
                --keep-polytomies \
                {params.clock_rate} \
                {params.clock_std_dev} \
                --output-node-data {output.node_data} \
                --coalescent {params.coalescent} \
                --date-inference {params.date_inference} \
                --clock-filter-iqd {params.clock_filter_iqd}
            """


rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = build_dir + "/{build_name}/tree.nwk",
        alignment = build_dir + "/{build_name}/masked.fasta",
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
        tree = build_dir + "/{build_name}/tree.nwk",
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
        tree = build_dir + "/{build_name}/tree.nwk",
        metadata = "data/metadata.tsv"
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

rule mutation_context:
    input:
        tree = build_dir + "/{build_name}/tree.nwk",
        node_data = build_dir + "/{build_name}/nt_muts.json"
    output:
        node_data = build_dir + "/{build_name}/mutation_context.json",
    shell:
        """
        python3 scripts/mutation_context.py \
            --tree {input.tree} \
            --mutations {input.node_data} \
            --output {output.node_data}
        """

rule remove_time:
    input:
        "results/{build_name}/branch_lengths.json"
    output:
        "results/{build_name}/branch_lengths_no_time.json"
    shell:
        """
        python3 scripts/remove_timeinfo.py --input-node-data {input} --output-node-data {output}
        """

rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = build_dir + "/{build_name}/tree.nwk",
        metadata = "data/metadata.tsv",
        branch_lengths = lambda w: "results/{build_name}/branch_lengths.json" if config.get('timetree', False) else "results/{build_name}/branch_lengths_no_time.json",
        traits = rules.traits.output.node_data,
        nt_muts = rules.ancestral.output.node_data,
        aa_muts = rules.translate.output.node_data,
        mutation_context = rules.mutation_context.output.node_data,
        colors = config["colors"],
        lat_longs = config["lat_longs"],
        description = config["description"],
        auspice_config = config["auspice_config"]
    output:
        auspice_json =  build_dir + "/{build_name}/tree.json",
        root_sequence = build_dir + "/{build_name}/tree_root-sequence.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} {input.mutation_context} \
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --description {input.description} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """
