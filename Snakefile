from packaging import version
from augur.__version__ import __version__ as augur_version
import sys

min_augur_version = "22.2.0"
if version.parse(augur_version) < version.parse(min_augur_version):
    print("This pipeline needs a newer version of augur than you currently have...")
    print(
        f"Current augur version: {augur_version}. Minimum required: {min_augur_version}"
    )
    sys.exit(1)

# Set the maximum recursion limit globally for all shell commands, to avoid
# issues with large trees crashing the workflow.  Preserve Snakemake's default
# use of Bash's "strict mode", as we rely on that behaviour.
# Copied directly from the ncov workflow
# https://github.com/nextstrain/ncov/blob/c6fcdf6b19f9dcb92c9f59d0fda1c953192e3950/Snakefile#L15-L18
shell.prefix("set -euo pipefail; export AUGUR_RECURSION_LIMIT=10000; ")

if not config:

    configfile: "config/config_hmpxv1.yaml"


build_dir = "results"


auspice_dir = "auspice"


rule all:
    input:
        auspice_json=auspice_dir + f"/{config.get('auspice_name','tree')}.json",
        root_sequence_json=auspice_dir
        + f"/{config.get('auspice_name','')}_root-sequence.json",


rule rename:
    input:
        auspice_json=build_dir + f"/{config['build_name']}/tree.json",
        root_sequence=build_dir + f"/{config['build_name']}/tree_root-sequence.json",
    output:
        auspice_json=auspice_dir + f"/{config.get('auspice_name','tree')}.json",
        root_sequence_json=auspice_dir
        + f"/{config.get('auspice_name','')}_root-sequence.json",
    shell:
        """
        cp {input.auspice_json} {output.auspice_json}
        cp {input.root_sequence} {output.root_sequence_json}
        """


if config.get("data_source", None) == "lapis":

    include: "workflow/snakemake_rules/download_via_lapis.smk"

else:

    include: "workflow/snakemake_rules/prepare.smk"


include: "workflow/snakemake_rules/chores.smk"
include: "workflow/snakemake_rules/core.smk"


if config.get("deploy_url", False):

    include: "workflow/snakemake_rules/nextstrain_automation.smk"


rule clean:
    message:
        "Removing directories: {params}"
    params:
        build_dir,
        auspice_dir,
    shell:
        "rm -rfv {params}"


rule cleanall:
    message:
        "Removing directories: {params}"
    params:
        build_dir,
        auspice_dir,
        "data",
    shell:
        "rm -rfv {params}"
