import json, argparse

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="remove time info",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )
    parser.add_argument(
        "--input-node-data", type=str, required=True, help="input data"
    )
    parser.add_argument(
        "--output-node-data",
        type=str,
        metavar="JSON",
        required=True,
        help="output Auspice JSON",
    )
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
        # Need to set up clade dictionary for when we have other outbreaks
        # if old_clade_name.startswith('outbreak'):
        #     outbreak_name = old_clade_name.split()[1]
        #     clade_name = clade[outbreak_name]
        elif old_clade_name.startswith("outgroup"):
            clade_name = "outgroup"
        else:
            clade_name = "IIb"
            outbreak_name = "hMPXV-1"
            lineage_name = old_clade_name

        new_node_data[name] = {
            "clade_membership": clade_name,
            "outbreak": outbreak_name,
            "lineage": lineage_name,
        }
        if "clade_annotation" in node:
            new_node_data[name]["clade_annotation"] = node["clade_annotation"]
            if node["clade_annotation"] == "A":
                new_node_data[name]["clade_annotation"] = "hMPXV-1 A"

    data["nodes"] = new_node_data
    with open(args.output_node_data, "w") as fh:
        json.dump(data, fh)
