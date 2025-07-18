"""
This part of the workflow handles triggering new mpox builds after the
latest metadata TSV and sequence FASTA files have been uploaded to S3.

Designed to be used internally by the Nextstrain team with hard-coded paths
to expected upload flag files.
"""


rule trigger_build:
    """
    Triggering monekypox builds via repository action type `rebuild`.
    """
    input:
        metadata_upload="data/upload/s3/metadata.tsv.zst.done",
        fasta_upload="data/upload/s3/sequences.fasta.zst.done",
    output:
        touch("data/trigger/rebuild.done"),
    params:
        vendored_scripts=VENDORED_SCRIPTS,
    shell:
        """
        {params.vendored_scripts}/trigger-on-new-data nextstrain/mpox rebuild {input.metadata_upload} {input.fasta_upload}
        """
