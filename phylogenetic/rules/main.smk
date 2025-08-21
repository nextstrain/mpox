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


build_dir = "results"
auspice_dir = "auspice"

prefix = config.get("auspice_prefix", None)
AUSPICE_PREFIX = ("trial_" + prefix + "_") if prefix is not None else ""
# Defaults to the `build_name` if no `auspice_name` is provided in the config
AUSPICE_FILENAME = AUSPICE_PREFIX + config.get("auspice_name", config["build_name"])


rule all:
    input:
        auspice_json=build_dir + f"/{config['build_name']}/tree.json",
        root_sequence=build_dir + f"/{config['build_name']}/tree_root-sequence.json",
    output:
        auspice_json=f"{auspice_dir}/{AUSPICE_FILENAME}.json",
        root_sequence_json=f"{auspice_dir}/{AUSPICE_FILENAME}_root-sequence.json",
    shell:
        r"""
        cp {input.auspice_json:q} {output.auspice_json:q}
        cp {input.root_sequence:q} {output.root_sequence_json:q}
        """


include: "config.smk"
include: "prepare_sequences.smk"
include: "construct_phylogeny.smk"
include: "annotate_phylogeny.smk"
include: "export.smk"


# Include custom rules defined in the config.
if "custom_rules" in config:
    for rule_file in config["custom_rules"]:

        # Relative custom rule paths in the config are relative to the analysis
        # directory (i.e. the current working directory, or workdir, usually
        # given by --directory), but the "include" directive treats relative
        # paths as relative to the workflow (e.g. workflow.current_basedir).
        # Convert to an absolute path based on the analysis/current directory
        # to avoid this mismatch of expectations.
        include: os.path.join(os.getcwd(), rule_file)


rule clean:
    """
    Removing directories: {params}
    """
    params:
        build_dir,
        auspice_dir,
    shell:
        "rm -rfv {params}"


rule cleanall:
    """
    Removing directories: {params}
    """
    params:
        build_dir,
        auspice_dir,
        "data",
    shell:
        "rm -rfv {params}"
