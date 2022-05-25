"""
This part of the workflow handles transforming the data into standardized
formats and expects input file

    sequences_ndjson = "data/sequences.ndjson"

This will produce output files as

    metadata = "data/metadata.tsv"
    sequences = "data/sequences.fasta"

Parameters are expected to be defined in `config.transform`.
"""

rule transform:
    input:
        sequences_ndjson = "data/sequences.ndjson"
    output:
        metadata = "data/metadata.tsv",
        sequences = "data/sequences.fasta"
    params:
        metadata_columns = config['transform']['metadata_columns'],
        id_field = config['transform']['id_field'],
        sequence_field = config['transform']['sequence_field']
    shell:
        """
        cat {input.sequences_ndjson} \
            | ./bin/ndjson-to-tsv-and-fasta \
                --metadata-columns {params.metadata_columns} \
                --id-field {params.id_field} \
                --sequence-field {params.sequence_field}
        """
