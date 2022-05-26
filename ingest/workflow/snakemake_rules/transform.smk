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
        field_map = config['transform']['field_map'],
        strain_regex = config['transform']['strain_regex'],
        strain_backup_fields = config['transform']['strain_backup_fields'],
        date_fields = config['transform']['date_fields'],
        expected_date_formats = config['transform']['expected_date_formats'],
        metadata_columns = config['transform']['metadata_columns'],
        id_field = config['transform']['id_field'],
        sequence_field = config['transform']['sequence_field']
    shell:
        """
        cat {input.sequences_ndjson} \
            | ./bin/transform-field-names \
                --field-map {params.field_map} \
            | ./bin/transform-string-fields --normalize \
            | ./bin/transform-strain-names \
                --strain-regex {params.strain_regex} \
                --backup-fields {params.strain_backup_fields} \
            | ./bin/transform-date-fields \
                --date-fields {params.date_fields} \
                --expected-date-formats {params.expected_date_formats} \
            | ./bin/ndjson-to-tsv-and-fasta \
                --metadata-columns {params.metadata_columns} \
                --id-field {params.id_field} \
                --sequence-field {params.sequence_field}
        """
