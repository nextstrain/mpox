"""
Shared functions used to parse the config.
Originally copied from
<https://github.com/nextstrain/zika/blob/3c17db54698cf7836641308f6aa50d714959992b/phylogenetic/rules/config.smk>
"""

from typing import Union


# Basic config sanity checking in lieu of a proper schema
if any([k in config for k in ["private_sequences", "private_metadata"]]):
    assert all(
        [k in config for k in ["private_sequences", "private_metadata"]]
    ), "Your config defined one of ['private_sequences', 'private_metadata'] but both must be supplied together"


def str_to_list_for_backcompat(val: Any, param: str) -> list:
    if not isinstance(val, str):
        return val
    print(
        f"Workflow deprecation warning: Converting `config{param!r}` from a string to a list; "
        "update the config file to silence this warning",
        file=sys.stderr,
    )
    return val.split()


config["root"] = str_to_list_for_backcompat(config["root"], "['root']")
config["traits"]["columns"] = str_to_list_for_backcompat(
    config["traits"]["columns"], "['traits']['columns']"
)
config["colors"]["ignore_categories"] = str_to_list_for_backcompat(
    config["colors"]["ignore_categories"], "['colors']['ignore_categories']"
)


# Looping over a shallow copy of the dict since we remove disabled subsampling groups
for name, params in config["subsample"].copy().items():
    if isinstance(params, dict):
        print(
            f"Converting config['subsample']['{name}'] from a dictionary to a string; "
            "consider updating the config param in the config file.",
            file=sys.stderr,
        )
        config["subsample"][name] = " ".join(
            (
                params["group_by"],
                params["sequences_per_group"],
                f"--query {params['query']}" if "query" in params else "",
                (
                    f"--exclude-where {' '.join([f'lineage={l}'for l in params['exclude_lineages']])}"
                    if "exclude_lineages" in params
                    else ""
                ),
                params.get("other_filters", ""),
            )
        )

    # Null subsample params represent disabled subsampling groups
    # This allows config overlays to disable the default subsampling groups with
    # YAML null value (~) which gets mapped to the Python `None`
    #   subsampling:
    #       non_b1: ~
    if params is None:
        print(
            f"Ignoring disabled subsample group config['subsample']['{name}']",
            file=sys.stderr,
        )
        del config["subsample"][name]

assert len(
    config["subsample"]
), "All subsampling groups were disabled! Must have at least one valid subsample group in config['subsample']"


ROOT_FLAG = "--root "
if config.get("treefix_root", "").startswith(ROOT_FLAG):
    print(
        f"Workflow deprecation warning: Removing `{ROOT_FLAG!r}` from config['treefix_root'] ; "
        f"consider removing the unnecessary substring `--root` from the config param in the config file to silence this warning.",
        file=sys.stderr,
    )
    config["treefix_root"] = config["treefix_root"][len(ROOT_FLAG) :]
