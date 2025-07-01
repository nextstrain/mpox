"""
Shared functions used to parse the config.
Originally copied from
<https://github.com/nextstrain/zika/blob/3c17db54698cf7836641308f6aa50d714959992b/phylogenetic/rules/config.smk>
"""
from textwrap import dedent, indent
from typing import Union


def as_list(config_param: Union[list,str]) -> list:
    if isinstance(config_param, list):
        return config_param

    if isinstance(config_param, str):
        return config_param.split()

    raise TypeError(indent(dedent(f"""\
        'config_param' must be a list or a string.
        Provided {config_param}, which is {type(config_param)}.
        """),"    "))


# Config manipulations to keep workflow backwards compatible with older configs
if isinstance(config["root"], str):
    print("Converting config['root'] from a string to a list; "
          "consider updating the config param in the config file.", file=sys.stderr)
    config["root"] = as_list(config["root"])

if isinstance(config["traits"]["columns"], str):
    print("Converting config['traits']['columns'] from a string to a list; "
          "consider updating the config param in the config file.", file=sys.stderr)
    config["traits"]["columns"] = as_list(config["traits"]["columns"])

if isinstance(config.get("colors", {}).get("ignore_categories"), str):
    print("Converting config['colors']['ignore_categories'] from a string to a list; "
          "consider updating the config param in the config file.", file=sys.stderr)
    config["colors"]["ignore_categories"] = as_list(config["colors"]["ignore_categories"])

for name, params in config["subsample"].items():
    if isinstance(params, dict):
        print(f"Converting config['subsample']['{name}'] from a dictionary to a string; "
              "consider updating the config param in the config file.", file=sys.stderr)
        config["subsample"][name] = " ".join((
            params["group_by"],
            params["sequences_per_group"],
            f"--query {params['query']}" if "query" in params else "",
            f"--exclude-where {' '.join([f'lineage={l}' for l in params['exclude_lineages']])}" if "exclude_lineages" in params else "",
            params.get("other_filters", ""),
        ))

ROOT_FLAG = "--root "
if config.get("treefix_root", "").startswith(ROOT_FLAG):
    print(f"Removing the flag {ROOT_FLAT!r} from config['treefix_root'] ; "
          f"consider updating the config param in the config file.", file=sys.stderr)
    config["treefix_root"] = config["treefix_root"][len(ROOT_FLAG):]
