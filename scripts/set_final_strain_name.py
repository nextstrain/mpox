from operator import index
import pandas as pd
import json, argparse

def replace_name_recursive(node, lookup):
    if node["name"] in lookup:
        node["name"] = lookup[node["name"]]

    if "children" in node:
        for child in node["children"]:
            replace_name_recursive(child, lookup)

if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="remove time info",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--input-auspice-json', type=str, required=True, help="input auspice_json")
    parser.add_argument('--metadata', type=str, required=True, help="input data")
    parser.add_argument('--display-strain-name', type=str, required=True, help="field to use as strain name in auspice")
    parser.add_argument('--output', type=str, metavar="JSON", required=True, help="output Auspice JSON")
    args = parser.parse_args()

    metadata = pd.read_csv(args.metadata, sep='\t')
    name_lookup = {}
    for ri, row in metadata.iterrows():
        strain_id = row['strain']
        name_lookup[strain_id] = args.display_strain_name if pd.isna(row[args.display_strain_name]) else row[args.display_strain_name]

    with open(args.input_auspice_json, 'r') as fh:
        data = json.load(fh)

    replace_name_recursive(data['tree'], name_lookup)

    with open(args.output, 'w') as fh:
        json.dump(data, fh)
