import json, argparse

if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="remove time info",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('--input-node-data', type=str, required=True, help="input data")
    parser.add_argument('--output-node-data', type=str, metavar="JSON", required=True, help="output Auspice JSON")
    args = parser.parse_args()
    with open(args.input_node_data) as fh:
        data = json.load(fh)
    new_node_data = {}
    for name, node in data["nodes"].items():
        old_clade_name = node["clade_membership"]
        lineage_name = ''
        if old_clade_name.startswith('hMPXV-1'):
            clade_name = old_clade_name.split()[0]
            lineage_name = old_clade_name.split()[1]
        else:
            clade_name = old_clade_name
        new_node_data[name] = {
            "clade_membership": clade_name,
            "lineage": lineage_name
        }
        if "clade_annotation" in node:
            annot = node["clade_annotation"]
            if annot.startswith('hMPXV-1') and annot != 'hMPXV-1 A':
                new_node_data[name]["clade_annotation"] = annot.split()[1]
            else:
                new_node_data[name]["clade_annotation"] = annot
    data["nodes"] = new_node_data
    with open(args.output_node_data, 'w') as fh:
        json.dump(data, fh)