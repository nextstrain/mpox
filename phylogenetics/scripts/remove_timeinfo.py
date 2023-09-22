import argparse
import json
from collections import defaultdict


def sample_date(node):
    """
    Returns the sample date in numeric form.
    In the future, we could examine the 'raw_date' attr here to decide whether to ignore
    some sequences, as 'numdate' is the inferred (timetree) date which can hide
    uncertainty in actual sampling date,
    """
    if "raw_date" not in node: # internal node or tip with no date info
        return
    return node['numdate']



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
        try:
            new_node_data[name] = {
                "mutation_length": node["mutation_length"],
                "branch_length": node["branch_length"]
            }
            sdate = sample_date(node)
            if sdate:
                new_node_data[name]["sample_date"] = sdate
        except KeyError:
            # internal node or tip with no date info
            pass

    data["nodes"] = new_node_data
    with open(args.output_node_data, 'w') as fh:
        json.dump(data, fh)
