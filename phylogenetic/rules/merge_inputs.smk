"""
This part of the workflow merges inputs based on what is defined in the config.

OUTPUTS:

    metadata  = results/metadata.tsv
    sequences = results/sequences.fasta

The config dict is expected to have a top-level `inputs` list that defines the
separate inputs' name, metadata, and sequences. Optionally, the config can have
a top-level `additional-inputs` list that is used to define additional data that
are combined with the default inputs:

```yaml
inputs:
    - name: default
      metadata: <path-or-url>
      sequences: <path-or-url>

additional_inputs:
    - name: private
      metadata: <path-or-url>
      sequences: <path-or-url>
```

Supports any of the compression formats that are supported by `augur read-file`,
see <https://docs.nextstrain.org/projects/augur/page/usage/cli/read-file.html>
"""
from pathlib import Path


def _gather_inputs():
    all_inputs = [*config['inputs'], *config.get('additional_inputs', [])]

    if len(all_inputs)==0:
        raise InvalidConfigError("Config must define at least one element in config.inputs or config.additional_inputs lists")
    if not all([isinstance(i, dict) for i in all_inputs]):
        raise InvalidConfigError("All of the elements in config.inputs and config.additional_inputs lists must be dictionaries. "
            "If you've used a command line '--config' double check your quoting.")
    if len({i['name'] for i in all_inputs})!=len(all_inputs):
        raise InvalidConfigError("Names of inputs (config.inputs and config.additional_inputs) must be unique")
    if not all(['name' in i and ('sequences' in i or 'metadata' in i) for i in all_inputs]):
        raise InvalidConfigError("Each input (config.inputs and config.additional_inputs) must have a 'name' and 'metadata' and/or 'sequences'")
    if not any(['metadata' in i for i in all_inputs]):
        raise InvalidConfigError("At least one input must have 'metadata'")
    if not any (['sequences' in i for i in all_inputs]):
        raise InvalidConfigError("At least one input must have 'sequences'")

    available_keys = set(['name', 'metadata', 'sequences'])
    if any([len(set(el.keys())-available_keys)>0 for el in all_inputs]):
        raise InvalidConfigError(f"Each input (config.inputs and config.additional_inputs) can only include keys of {', '.join(available_keys)}")

    return {el['name']: {k:(v if k=='name' else path_or_url(v)) for k,v in el.items()} for el in all_inputs}

input_sources = _gather_inputs()
_input_metadata = [info['metadata'] for info in input_sources.values() if info.get('metadata', None)]
_input_sequences = [info['sequences'] for info in input_sources.values() if info.get('sequences', None)]


if len(_input_metadata) == 1:

    rule decompress_metadata:
        """
        This rule is invoked when there is a single metadata input to
        ensure that we have a decompressed input for downstream rules to match
        the output of rule.merge_metadata.
        """
        input:
            metadata = _input_metadata[0],
        output:
            metadata = "results/metadata.tsv",
        log:
            "logs/decompress_metadata.txt",
        benchmark:
            "benchmarks/decompress_metadata.txt",
        shell:
            r"""
            exec &> >(tee {log:q})

            augur read-file {input.metadata:q} > {output.metadata:q}
            """

else:

    rule merge_metadata:
        """
        This rule is invoked when there are multiple defined metadata inputs
        (config.inputs + config.additional_inputs)
        """
        input:
            **{name: info['metadata'] for name,info in input_sources.items() if info.get('metadata', None)}
        params:
            metadata = lambda w, input: list(map("=".join, input.items())),
            id_field = config['strain_id_field'],
        output:
            metadata = "results/metadata.tsv"
        log:
            "logs/merge_metadata.txt",
        benchmark:
            "benchmarks/merge_metadata.txt"
        shell:
            r"""
            exec &> >(tee {log:q})

            augur merge \
                --metadata {params.metadata:q} \
                --metadata-id-columns {params.id_field:q} \
                --output-metadata {output.metadata:q}
            """


if len(_input_sequences) == 1:

    rule decompress_sequences:
        """
        This rule is invoked when there is a single sequences input to
        ensure that we have a decompressed input for downstream rules to match
        the output of rule.merge_sequences.
        """
        input:
            sequences = _input_sequences[0],
        output:
            sequences = "results/sequences.fasta",
        log:
            "logs/decompress_sequences.txt",
        benchmark:
            "benchmarks/decompress_sequences.txt",
        shell:
            r"""
            exec &> >(tee {log:q})

            augur read-file {input.sequences:q} > {output.sequences:q}
            """

else:

    rule merge_sequences:
        """
        This rule is invoked when there are multiple defined sequences inputs
        (config.inputs + config.additional_inputs)
        """
        input:
            **{name: info['sequences'] for name,info in input_sources.items() if info.get('sequences', None)}
        output:
            sequences = "results/sequences.fasta",
        log:
            "logs/merge_sequences.txt",
        benchmark:
            "benchmarks/merge_sequences.txt"
        shell:
            r"""
            exec &> >(tee {log:q})

            augur merge \
                --sequences {input:q} \
                --output-sequences {output.sequences:q}
            """
