'''
This part of the workflow expects input files

        sequences = build_dir + "/{build_name}/sequences.fasta",
        metadata = build_dir + "/{build_name}/metadata.tsv",

and will produce output files as

        auspice_json = auspice_dir + "/monkeypox_{build_name}.json"

Parameter are expected to sit in the `config` data structure.
In addition, `build_dir` and `auspice_dir` need to be defined upstream.
'''

rule download_nextalign:
    output:
        executable = "bin/nextalign"
    shell:
        """
        curl -fsSL "https://github.com/nextstrain/nextclade/releases/download/2.0.0-alpha.2/nextalign-x86_64-apple-darwin" -o {output.executable} && chmod +x {output.executable} && ./{output.executable} --version
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
        sequences = build_dir + "/{build_name}/sequences.fasta",
        metadata = build_dir + "/{build_name}/metadata.tsv",
        exclude = config["exclude"],
        include = config["include"]
    output:
        sequences = build_dir + "/{build_name}/filtered.fasta",
        strains = build_dir + "/{build_name}/filtered.txt",
        log = build_dir + "/{build_name}/filter.log",
        metadata = build_dir + "/{build_name}/filtered.tsv"
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
            --include {input.include} \
            --output {output.sequences} \
            --group-by {params.group_by} \
            --exclude-where "clade!='WA'" \
            --sequences-per-group {params.sequences_per_group} \
            --min-date {params.min_date} \
            --min-length {params.min_length} \
            --output-strains {output.strains} \
            --output-metadata {output.metadata} \
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
        reference = config["reference"],
        nextalign = rules.download_nextalign.output.executable
    output:
        alignment = build_dir + "/{build_name}/aligned.fasta"
    params:
        max_indel = config["max_indel"],
        seed_spacing = config["seed_spacing"]
    shell:
        """
        ./{input.nextalign} run \
            -v \
            --jobs 1 \
            --sequences {input.sequences} \
            --reference {input.reference} \
            --max-indel {params.max_indel} \
            --seed-spacing {params.seed_spacing} \
            --output-fasta {output.alignment}
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
        augur mask --sequences {input.sequences} --mask-from-beginning {params.from_start} --mask-from-end {params.from_end} --output {output}
        """

rule tree:
    message: "Building tree"
    input:
        alignment = build_dir + "/{build_name}/masked.fasta"
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
        """
    input:
        tree = rules.tree.output.tree,
        alignment = build_dir + "/{build_name}/masked.fasta",
        metadata = build_dir +"/{build_name}/metadata.tsv"
    output:
        tree = build_dir + "/{build_name}/tree.nwk",
        node_data = build_dir + "/{build_name}/branch_lengths.json"
    params:
        root = config["root"],
        divergence_unit = config["divergence_unit"],
    shell:
        """
        augur refine \
            --tree {input.tree} \
            --alignment {input.alignment} \
            --metadata {input.metadata} \
            --output-tree {output.tree} \
            --root {params.root} \
            --divergence-unit {params.divergence_unit} \
            --output-node-data {output.node_data} \
        """

rule ancestral:
    message: "Reconstructing ancestral sequences and mutations"
    input:
        tree = rules.refine.output.tree,
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
        tree = rules.refine.output.tree,
        node_data = rules.ancestral.output.node_data,
        genbank_reference = config["genemap"]
        
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
        augur clades --tree {input.tree} \
            --mutations {input.nuc_muts} {input.aa_muts} \
            --clades {input.clades} \
            --output-node-data {output.node_data} 2>&1 | tee {log}
        """


rule export:
    message: "Exporting data files for for auspice"
    input:
        tree = rules.refine.output.tree,
        metadata = build_dir+"/{build_name}/metadata.tsv",
        branch_lengths = rules.refine.output.node_data,
        nt_muts = rules.ancestral.output.node_data,
        aa_muts = rules.translate.output.node_data,
        clades = rules.clades.output.node_data,
        colors = config["colors"],
        lat_longs = config["lat_longs"],
        auspice_config = config["auspice_config"]
    output:
        auspice_json = auspice_dir + "/monkeypox_{build_name}.json",
    shell:
        """
        augur export v2 \
            --tree {input.tree} \
            --metadata {input.metadata} \
            --node-data {input.branch_lengths} {input.clades} {input.nt_muts} {input.aa_muts} \
            --colors {input.colors} \
            --lat-longs {input.lat_longs} \
            --auspice-config {input.auspice_config} \
            --output {output.auspice_json} \
            # --skip-validation
        """

# rule add_fake_clades:
#     input: rules.export.output.auspice_json
#     output:
#         auspice_json = auspice_dir + "/monkeypox_{build_name}.json"
#     shell: """
#             jq <{input} \
#             'walk( 
#                 if type == "object" and has("node_attrs") \
#                     then .node_attrs += {{"clade_membership": {{ "value": "WA" }} }} \
#                     else . \
#                 end
#             )' \
#             > {output.auspice_json}
#             """
