import argparse
import json

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
    args = parser.parse_args()
    with open(args.input_node_data) as fh:
        data = json.load(fh)
    new_node_data = {}
    for name, node in data["nodes"].items():
        old_clade_name = node["clade_membership"]
        outbreak_name = ""
        lineage_name = ""

        # if it starts with clade -> it's a clade
        # if it starts with outbreak -> it's outbreak, need to look up clade
        # if it starts with lineage -> it's clade IIb, outbreak hMPXV-1
        if old_clade_name.startswith("clade"):
            clade_name = old_clade_name.split()[1]
            match clade_name:
                case "Ib":
                    outbreak_name = "sh2023"
                case "Ib/IIb":
                    outbreak_name = "rec2025"
        elif old_clade_name == "sh2024":
            clade_name = "Ia"
            outbreak_name = old_clade_name
        elif old_clade_name == "sh2017":
            clade_name = "IIb"
            outbreak_name = old_clade_name
            lineage_name = "A"
        elif old_clade_name.startswith(args.outgroup_clade_name):
            clade_name = args.outgroup_clade_name
        elif old_clade_name.startswith("outgroup"):
            clade_name = "outgroup"
        elif old_clade_name.startswith("unassigned"):
            clade_name = "unassigned"
        else:
            clade_name = "IIb"
            outbreak_name = "sh2017"
            lineage_name = old_clade_name

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

    new_branch_labels = {}

    for name, node in data["branches"].items():
        # Rename sh2017 -> sh2017/A
        # Rename clade Ib -> clade IIb/outbreak sh2023
        if "labels" in node and "clade" in node["labels"]:

            def make_label(label: str) -> dict:
                return {"labels": {"clade": label}}

            match node["labels"]["clade"]:
                case "sh2017":
                    new_branch_labels[name] = make_label("sh2017/A")
                case "clade Ib":
                    new_branch_labels[name] = make_label("clade Ib/sh2023")
                case "A":
                    new_branch_labels[name] = make_label("sh2017/A")
                case _:
                    new_branch_labels[name] = node
    data["branches"] = new_branch_labels
    data["nodes"] = new_node_data
    with open(args.output_node_data, "w") as fh:
        json.dump(data, fh)
