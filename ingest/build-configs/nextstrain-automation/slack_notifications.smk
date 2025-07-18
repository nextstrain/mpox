"""
This part of the workflow handles various Slack notifications.
Designed to be used internally by the Nextstrain team with hard-coded paths
to files on AWS S3.

All rules here require two environment variables:
    * SLACK_TOKEN
    * SLACK_CHANNELS
"""

import os
import sys

slack_envvars_defined = "SLACK_CHANNELS" in os.environ and "SLACK_TOKEN" in os.environ
if not slack_envvars_defined:
    print(
        "ERROR: Slack notifications require two environment variables: 'SLACK_CHANNELS' and 'SLACK_TOKEN'.",
        file=sys.stderr,
    )
    sys.exit(1)

S3_SRC = "s3://nextstrain-data/files/workflows/mpox"


rule notify_on_genbank_record_change:
    input:
        genbank_ndjson="data/ncbi.ndjson",
    output:
        touch("data/notify/genbank-record-change.done"),
    params:
        s3_src=S3_SRC,
        vendored_scripts=VENDORED_SCRIPTS,
    shell:
        """
        {params.vendored_scripts}/notify-on-record-change {input.genbank_ndjson} {params.s3_src:q}/ncbi.ndjson.zst Genbank
        """


rule notify_on_metadata_diff:
    input:
        metadata="results/metadata.tsv",
    output:
        touch("data/notify/metadata-diff.done"),
    params:
        s3_src=S3_SRC,
        vendored_scripts=VENDORED_SCRIPTS,
    shell:
        """
        {params.vendored_scripts}/notify-on-diff {input.metadata} {params.s3_src:q}/metadata.tsv.zst
        """


onstart:
    shell(f"{VENDORED_SCRIPTS}/notify-on-job-start Ingest nextstrain/mpox")


onerror:
    shell(f"{VENDORED_SCRIPTS}/notify-on-job-fail Ingest nextstrain/mpox")
