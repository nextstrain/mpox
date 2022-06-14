'''
This part of the workflow expects input files

        sequences = "data/sequences.fasta",
        metadata =  "data/metadata.tsv",

and will produce output files as

        auspice_json = auspice_dir + "/monkeypox_{build_name}.json"

Parameter are expected to sit in the `config` data structure.
In addition, `build_dir` and `auspice_dir` need to be defined upstream.
'''

rule wrangle_metadata:
    input:
        metadata =  "data/metadata.tsv"
    output:
        metadata = build_dir + "/{build_name}/metadata.tsv"
    params:
        strain_id = lambda w: config.get('strain_id_field', 'strain')
    shell:
        """
        python3 scripts/wrangle_metadata.py --metadata {input.metadata} \
                    --strain-id {params.strain_id} \
                    --output {output.metadata}
        """

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
        metadata =  build_dir + "/{build_name}/metadata.tsv",
        exclude = config["exclude"],
        include = config["include"],
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
            --metadata-id-columns strain \
            --exclude {input.exclude} \
            --include {input.include} \
            --output {output.sequences} \
            --min-length {params.min_length} \
            --output-log {output.log}
        cat config/reference.fasta >> {output.sequences}
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
            --nthreads {threads} \
            --tree-builder-args '-ninit 10 -n 4 -czb'
        """

rule refine:
    message:
        """
        Refining tree
        """
    input:
        tree = rules.tree.output.tree,
        alignment = build_dir + "/{build_name}/masked.fasta",
        metadata = build_dir + "/{build_name}/metadata.tsv"
    output:
        tree = build_dir + "/{build_name}/tree.nwk",
        node_data = build_dir + "/{build_name}/branch_lengths.json"
    params:
        root = config["root"],
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --root {params.root} \
            --divergence-unit mutations \
            --keep-polytomies \
            --output-node-data {output.node_data}
        """

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = rules.refine.output.tree,
        alignment = build_dir + "/{build_name}/aligned.fasta",
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
        genemap = config["genemap"]
    output:
        node_data = build_dir + "/{build_name}/aa_muts.json"
    shell:
        """
        augur translate \
            --tree {input.tree} \
            --ancestral-sequences {input.node_data} \
            --reference-sequence {input.genemap} \
            --output {output.node_data}
        """

rule clades:
    message: "Adding internal clade labels"
    input:
        tree = rules.refine.output.tree,
        aa_muts = rules.translate.output.node_data,
        nuc_muts = rules.ancestral.output.node_data,
        clades = config["clades"]
    output:
        node_data = build_dir + "/{build_name}/clades.json"
    shell:
        """
        augur clades \
            --tree {input.tree} \
            --mutations {input.nuc_muts} {input.aa_muts} \
            --clades {input.clades} \
            --output-node-data {output.node_data} 2>&1 | tee {log}
        """


rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = rules.refine.output.tree,
        metadata = build_dir + "/{build_name}/metadata.tsv",
        branch_lengths = "results/{build_name}/branch_lengths.json",
        clades = rules.clades.output.node_data,
        nt_muts = rules.ancestral.output.node_data,
        aa_muts = rules.translate.output.node_data,
        description = config["description"],
        auspice_config = config["auspice_config"]
    output:
        auspice_json =  build_dir + "/{build_name}/raw_tree.json",
        root_sequence = build_dir + "/{build_name}/raw_tree_root-sequence.json"
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.nt_muts} {input.aa_muts} {input.clades} \
            --description {input.description} \
            --auspice-config {input.auspice_config} \
            --include-root-sequence \
            --output {output.auspice_json}
        """


rule final_strain_name:
    input:
        auspice_json =  build_dir + "/{build_name}/raw_tree.json",
        metadata = build_dir + "/{build_name}/metadata.tsv",
        root_sequence = build_dir + "/{build_name}/raw_tree_root-sequence.json"
    output:
        auspice_json =  build_dir + "/{build_name}/tree.json",
        root_sequence =  build_dir + "/{build_name}/tree_root-sequence.json"
    params:
        display_strain_field = lambda w: config.get('display_strain_field', 'strain')
    shell:
        """
        python3 scripts/set_final_strain_name.py --metadata {input.metadata} \
                --input-auspice-json {input.auspice_json} \
                --display-strain-name {params.display_strain_field} \
                --output {output.auspice_json}
        cp {input.root_sequence} {output.root_sequence}
        """
