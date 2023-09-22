from collections import defaultdict
import json, argparse




if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="calculate mutation context json",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--tree', type=str, required=True, help="tree file")
    parser.add_argument('--mutations', type=str, required=True, help="mutations")
    parser.add_argument('--output', type=str, metavar="JSON", required=True, help="output Auspice JSON")
    args = parser.parse_args()


    with open(args.mutations) as fh:
        data = json.load(fh)['nodes']


    terminal_muts = defaultdict(lambda: defaultdict(int))
    internal_muts = defaultdict(lambda: defaultdict(int))

    node_data = {}

    for name, node in data.items():
        GA_count = 0
        CT_count = 0
        total_muts = 0
        for mut in node["muts"]:
            a, pos, d = mut[0], int(mut[1:-1]), mut[-1]
            if a in 'ACGT' and d in 'ACGT':
                total_muts += 1
                if a+d == 'GA':
                    GA_count += 1
                elif a+d == 'CT':
                    CT_count += 1
        GA_CT_count = GA_count + CT_count
        if total_muts:
            node_data[name] = {"GA_CT_fraction": GA_CT_count/total_muts}
        else:
            node_data[name] = {"GA_CT_fraction": None }


        dinuc_count = 0
        if GA_CT_count:
            #node_data[name]["CT_fraction"] = CT_count/GA_CT_count
            for mut in node["muts"]:
                a, pos, d = mut[0], int(mut[1:-1]), mut[-1]
                if a in 'ACGT' and d in 'ACGT':
                    if a+d == 'GA' and node['sequence'][pos]=='A':
                        dinuc_count+=1
                    elif a+d == 'CT' and node['sequence'][pos-2]=='T':
                        dinuc_count+=1
            node_data[name]["dinuc_context_fraction"] = dinuc_count/GA_CT_count
        else:
            node_data[name]["dinuc_context_fraction"] = None
            #node_data[name]["CT_fraction"] = None

    with open(args.output, 'w') as fh:
        json.dump({"nodes":node_data}, fh)
