"""
These custom rules handle the automation for Nextstrain builds that
include

    - Slack notifications
    - Uploads to AWS S3
    - Triggering downstream workflows
"""

VENDORED_SCRIPTS = f"{str(workflow.current_basedir)}/../../../shared/vendored/scripts"
send_slack_notifications = config.get("send_slack_notifications", False)


def _get_all_targets(wildcards) -> list[str]:
    # Default targets are the metadata TSV and sequences FASTA files
    all_targets = ["results/sequences.fasta", "results/metadata.tsv"]

    # Add additional targets based on upload config
    upload_config = config.get("upload", {})

    for target, params in upload_config.items():
        files_to_upload = params.get("files_to_upload", {})

        if not params.get("dst"):
            print(
                f"Skipping file upload for {target} because the destination was not defined."
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
                "data/notify/input-data-change.done",
                "data/notify/metadata-diff.done",
            ]
        )

    if config.get("trigger_rebuild", False):
        all_targets.append("data/trigger/rebuild.done")

    return all_targets


rule nextstrain_automation:
    input:
        _get_all_targets,


# Custom rule to copy `date_released` to `date_submitted` column so that
# users of our metadata.tsv have time to update their workflows to use the new
# `date_released` column.
# This custom rule and the `date_submitted` column will be removed on 28 July 2025.
rule custom_subset_metadata:
    input:
        metadata="data/all_metadata_added.tsv",
    output:
        subset_metadata="data/subset_metadata.tsv",
    params:
        metadata_fields=",".join(config["curate"]["metadata_columns"]),
    benchmark:
        "benchmarks/subset_metadata.txt"
    log:
        "logs/subset_metadata.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        csvtk cut -t -f {params.metadata_fields:q} \
            {input.metadata:q} \
            | csvtk mutate -t -f date_released -n date_submitted \
            > {output.subset_metadata:q}
        """


ruleorder: custom_subset_metadata > subset_metadata


if config.get("upload", False):

    include: "upload.smk"


if send_slack_notifications:

    include: "slack_notifications.smk"


if config.get("trigger_rebuild", False):

    include: "trigger_rebuild.smk"
