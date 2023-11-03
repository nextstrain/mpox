"""
This part of the workflow handles uploading files to a specified destination.

Uses predefined wildcard `file_to_upload` determine input and predefined
wildcard `remote_file_name` as the remote file name in the specified destination.

Produces output files as `data/upload/{upload_target_name}/{remote_file_name}.done`.

Currently only supports uploads to AWS S3, but additional upload rules can
be easily added as long as they follow the output pattern described above.
"""
import os

slack_envvars_defined = "SLACK_CHANNELS" in os.environ and "SLACK_TOKEN" in os.environ
send_notifications = (
    config.get("send_slack_notifications", False) and slack_envvars_defined
)


def _get_upload_inputs(wildcards):
    """
    If the file_to_upload has Slack notifications that depend on diffs with S3 files,
    then we want the upload rule to run after the notification rule.

    This function is mostly to keep track of which flag files to expect for
    the rules in `slack_notifications.smk`, so it only includes flag files if
    `send_notifications` is True.
    """
    inputs = {
        "file_to_upload": config["upload"]["s3"]["files_to_upload"][
            wildcards.remote_file_name
        ],
    }

    if send_notifications:
        flag_file = []

        if file_to_upload == "data/genbank.ndjson":
            flag_file = "data/notify/genbank-record-change.done"
        elif file_to_upload == "results/metadata.tsv":
            flag_file = "data/notify/metadata-diff.done"

        inputs["notify_flag_file"] = flag_file

    return inputs


rule upload_to_s3:
    input:
        unpack(_get_upload_inputs),
    output:
        "data/upload/s3/{remote_file_name}.done",
    params:
        quiet="" if send_notifications else "--quiet",
        s3_dst=config["upload"].get("s3", {}).get("dst", ""),
        cloudfront_domain=config["upload"].get("s3", {}).get("cloudfront_domain", ""),
    shell:
        """
        ./vendored/upload-to-s3 \
            {params.quiet} \
            {input.file_to_upload:q} \
            {params.s3_dst:q}/{wildcards.remote_file_name:q} \
            {params.cloudfront_domain} 2>&1 | tee {output}
        """
