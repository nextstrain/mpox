import argparse
import json

from Bio import Phylo

OUTBREAK_CLADES = {
    "sh2017": "IIb",
    "sh2023": "Ib",
}


def split_outbreak_lineage(clade_name: str) -> tuple[str, str]:
    outbreak_name, lineage_name = clade_name.split("/", maxsplit=1)
    if outbreak_name not in OUTBREAK_CLADES or not lineage_name:
        raise ValueError(f"Invalid outbreak/lineage clade name: {clade_name}")
    return outbreak_name, lineage_name


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Split clade membership into clade, outbreak and lineage",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument("--input-node-data", type=str, required=True, help="input data")
    parser.add_argument(
        "--output-node-data",
        type=str,
        metavar="JSON",
        required=True,
        help="output Auspice JSON",
    )
    parser.add_argument("--outgroup-clade-name", type=str, default="outgroup", help="name for outgroup clade")
    parser.add_argument("--tree-file", type=str, help="input tree file (not used)")
    args = parser.parse_args()
    # get all node names
    with open (args.tree_file) as fh:
        tree = Phylo.read(fh, "newick")
        all_node_names = {clade.name for clade in tree.find_clades() if clade.name is not None}
    with open(args.input_node_data) as fh:
        data = json.load(fh)
    new_node_data = {}
    for name, node in data["nodes"].items():
        old_clade_name = node["clade_membership"]
        outbreak_name = ""
        lineage_name = ""

        # Namespaced lineages identify both their outbreak and parent clade.
        if old_clade_name.startswith("clade"):
            clade_name = old_clade_name.split()[1]
            match clade_name:
                case "Ib":
                    outbreak_name = "sh2023"
                    lineage_name = "A"
                case "Ib/IIb":
                    outbreak_name = "recombinant"
        elif old_clade_name == "sh2024":
            clade_name = "Ia"
            outbreak_name = old_clade_name
        elif "/" in old_clade_name:
            outbreak_name, lineage_name = split_outbreak_lineage(old_clade_name)
            clade_name = OUTBREAK_CLADES[outbreak_name]
        elif old_clade_name.startswith(args.outgroup_clade_name) or old_clade_name == "unassigned" or old_clade_name == "":
            clade_name = args.outgroup_clade_name
        else:
            raise ValueError(f"Unrecognized clade name: {old_clade_name}")

        node_data = {
            "clade_membership": clade_name,
            "outbreak": outbreak_name,
            "lineage": lineage_name,
        }

        # Add placement prior for Ib/IIb recombinants
        # To discourage attachment of short sequences to this clade
        if clade_name == "Ib/IIb":
            node_data["placement_prior"] = -11.0

        new_node_data[name] = node_data

    for name in all_node_names - new_node_data.keys():
        new_node_data[name] = {
            "clade_membership": args.outgroup_clade_name,
            "outbreak": "",
            "lineage": "",
        }

    new_branch_labels = {}

    for name, node in data["branches"].items():
        if "labels" in node and "clade" in node["labels"]:
            label = node["labels"]["clade"]
            match label:
                case "clade Ib":
                    label = "clade Ib/sh2023/A"
                case _:
                    if label.startswith(tuple(f"{outbreak}/" for outbreak in OUTBREAK_CLADES)):
                        _, lineage_name = split_outbreak_lineage(label)
                        label = label if lineage_name == "A" else lineage_name

            new_branch_labels[name] = node | {
                "labels": node["labels"] | {"clade": label}
            }
    data["branches"] = new_branch_labels
    data["nodes"] = new_node_data
    with open(args.output_node_data, "w") as fh:
        json.dump(data, fh)
