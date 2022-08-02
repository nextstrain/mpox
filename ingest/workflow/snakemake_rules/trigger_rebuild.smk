"""
This part of the workflow handles triggering new monkeypox builds after the
latest metadata TSV and sequence FASTA files have been uploaded to S3.

Designed to be used internally by the Nextstrain team with hard-coded paths
to expected upload flag files.
"""

rule trigger_build:
    message: "Triggering monekypox builds via repository action type `rebuild`."
    input:
        metadata_upload = "data/upload/s3/metadata.tsv-to-metadata.tsv.gz.done",
        fasta_upload = "data/upload/s3/sequences.fasta-to-sequences.fasta.xz.done"
    output:
        touch("data/trigger/rebuild.done")
    shell:
        """
        ./bin/trigger-on-new-data {input.metadata_upload} {input.fasta_upload}
        """
