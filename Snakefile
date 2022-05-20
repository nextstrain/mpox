build_dir = "results"
auspice_dir = "auspice"

rule all:
    input:
        auspice_json = auspice_dir + "/monkeypox.json"

rule rename:
    input:
        auspice_json = auspice_dir + "/monkeypox_global.json",
        root_sequence = auspice_dir + "/monkeypox_global_root-sequence.json"
    output:
        auspice_json = auspice_dir + "/monkeypox.json",
        root_sequence = auspice_dir + "/monkeypox_root-sequence.json"
    shell:
        """
        mv {input.auspice_json} {output.auspice_json}
        mv {input.root_sequence} {output.root_sequence}
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
