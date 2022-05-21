build_dir = "results"
auspice_dir = "auspice"

wildcard_constraints:
    build_name="[^_]*"

rule all:
    input:
        auspice_json = auspice_dir + "/monkeypox.json"

rule rename:
    input:
        auspice_json = auspice_dir + "/monkeypox_global.json",
    output:
        auspice_json = auspice_dir + "/monkeypox.json",
    shell:
        """
        mv {input.auspice_json} {output.auspice_json}
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
