from collections import defaultdict
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
        new_node_data[name] = {
            "mutation_length": node["mutation_length"],
            "branch_length": node["branch_length"]
        }
        if "raw_date" in node:
            new_node_data[name]["date"] = node["raw_date"]

    data["nodes"] = new_node_data
    with open(args.output_node_data, 'w') as fh:
        json.dump(data, fh)
