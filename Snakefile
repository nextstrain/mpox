

# Add default ingest config if config is not defined
if not config or "transform" not in config:
    configfile: "ingest/config/config.yaml"

# Set up ingest workflow as a module that can be run from this top level Snakefile
module ingest_workflow:
    snakefile: "ingest/Snakefile"
    config: config
    prefix: "ingest"

# Use all rules from the ingest workflow so they can be specified as targets
# e.g. `nextstrain build . ingest_all`
use rule * from ingest_workflow as ingest_*


# Add default phylogenetic config if config is not defined
if not config or "build_name" not in config:
    configfile: "phylogenetic/config/hmpxv1/config.yaml"

# Set up phylogenetic workflow as a modue that can be run from this top level Snakefile
module phylogenetic_workflow:
    snakefile:"phylogenetic/Snakefile"
    config: config
    prefix: "phylogenetic"


# Use all rules from the phylogenetic workflow so that they can be specified as targets
# e.g. `nextstrain build . phylogenetic_all`
use rule * from phylogenetic_workflow as phylogenetic_*


# This rule needs to be defined in the top level Snakefile because the
# phylogenetic/Snakefile does not have access to the ingest rules and outputs.
if config.get("data_source", None) == "ingest":

    rule mv_from_ingest:
        input:
            sequences="ingest/data/sequences.fasta",
            metadata="ingest/data/metadata.tsv",
        output:
            sequences="phylogenetic/data/sequences.fasta",
            metadata="phylogenetic/data/metadata.tsv",
        shell:
            """
            mv {input.sequences} {output.sequences}
            mv {input.metadata} {output.metadata}
            """

    ruleorder: mv_from_ingest > phylogenetic_decompress
