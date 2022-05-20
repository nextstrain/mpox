build_dir = "results"
auspice_dir = "auspice"

rule all:
    input:
        auspice_json = auspice_dir + "/monkeypox_global.json",

include: "workflow/snakemake_rules/prepare.smk"

include: "workflow/snakemake_rules/core.smk"


rule clean:
    message: "Removing directories: {params}"
    params:
        build_dir,
        auspice_dir
    shell:
        "rm -rfv {params}"
