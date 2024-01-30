"""
These custom rules handle the automation for Nextstrain builds that
include

    - Slack notifications
    - Uploads to AWS S3
    - Triggering downstream workflows
"""

send_slack_notifications = config.get("send_slack_notifications", False)

def _get_all_targets(wildcards):
    # Default targets are the metadata TSV and sequences FASTA files
    all_targets = ["results/sequences.fasta", "results/metadata.tsv"]

    # Add additional targets based on upload config
    upload_config = config.get("upload", {})

    for target, params in upload_config.items():
        files_to_upload = params.get("files_to_upload", {})

        if not params.get("dst"):
            print(
                f"Skipping file upload for {target!r} because the destination was not defined."
            )
        else:
            all_targets.extend(
                expand(
                    [f"data/upload/{target}/{{remote_file_name}}.done"],
                    zip,
                    remote_file_name=files_to_upload.keys(),
                )
            )

    # Add additional targets for Nextstrain's internal Slack notifications
    if send_slack_notifications:
        all_targets.extend(
            [
                "data/notify/genbank-record-change.done",
                "data/notify/metadata-diff.done",
            ]
        )

    if config.get("trigger_rebuild", False):
        all_targets.append("data/trigger/rebuild.done")

    return all_targets


rule nextstrain_automation:
    input:
        _get_all_targets,


if config.get("upload", False):

    include: "upload.smk"


if send_slack_notifications:

    include: "slack_notifications.smk"


if config.get("trigger_rebuild", False):

    include: "trigger_rebuild.smk"
