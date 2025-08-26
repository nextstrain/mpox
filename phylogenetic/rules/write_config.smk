"""
This part of the workflow writes run time configuration to a YAML file.

OUTPUTS:

    results/{build_name}/run_config.yaml
"""


rule write_config:
    output:
        config=build_dir + "/{build_name}/run_config.yaml",
    log:
        "logs/{build_name}/write_config.txt",
    benchmark:
        "benchmarks/{build_name}/write_config.txt"
    run:
        import yaml

        with open(output.config, "w") as f:
            yaml.dump(config, f, sort_keys=False)
