if not config:
    configfile: "config/config.yaml"

build_dir = "results"
auspice_dir = "auspice"

rule all:
    input:
        auspice_json = auspice_dir + f"/{config.get('auspice_name','tree')}.json",
        root_sequence_json = auspice_dir + f"/{config.get('auspice_name','')}_root-sequence.json",

rule rename:
    input:
        auspice_json = build_dir + f"/{config.get('build_name')}/tree.json",
        root_sequence = build_dir + f"/{config.get('build_name')}/tree_root-sequence.json"
    output:
        auspice_json = auspice_dir + f"/{config.get('auspice_name','tree')}.json",
        root_sequence_json = auspice_dir + f"/{config.get('auspice_name','')}_root-sequence.json",
    shell:
        """
        cp {input.auspice_json} {output.auspice_json}
        cp {input.root_sequence} {output.root_sequence_json}
        """


include: "workflow/snakemake_rules/prepare.smk"

include: "workflow/snakemake_rules/core.smk"


rule clean:
    message: "Removing directories: {params}"
    params:
        build_dir,
        auspice_dir
    shell:
        "rm -rfv {params}"
