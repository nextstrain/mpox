from collections import defaultdict
import json, argparse
import matplotlib.pyplot as plt
from matplotlib import cm
from Bio import Phylo
import numpy as np

if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="calculate mutation context json",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--tree', type=str, required=True, help="tree file")
    parser.add_argument('--metadata', type=str, required=True, help="metadata")
    parser.add_argument('--alignment', type=str, required=True, help="alignment")
    parser.add_argument('--output-tree', type=str, required=True, help="tree")
    parser.add_argument('--output-node-data', type=str, required=True, help="node-data")
    parser.add_argument('--root', type=str)
    parser.add_argument('--coalescent', type=str)
    args = parser.parse_args()


    from treetime import TreeTime
    from treetime.utils import parse_dates

    dates = parse_dates(args.metadata)
    relaxed_clock = {'slack':0.2, 'coupling':0.1}

    Tc=args.coalescent
    try:
        Tc=float(Tc)
    except:
        pass

    tt = TreeTime(tree=args.tree, aln=args.alignment, dates=dates, use_fft=False)

    tt.reroot(args.root)
    relaxed_clock = {n.name:1.0 for n in tt.tree.find_clades()}
    root_of_outbreak = tt.tree.common_ancestor(["3025", "MPXV_UK_2022_3"])
    for n in root_of_outbreak.find_clades():
        if n.name == root_of_outbreak.name:
            continue
        relaxed_clock[n.name]=20
        print(n.name)

    tt.run(Tc=Tc, max_iter=3, resolve_polytomies=False, branch_length_mode='joint',
           root=args.root, relaxed_clock=relaxed_clock, vary_rate=2e-6,
           time_marginal=True, fixed_clock_rate=4e-6)

    node_data = {}

    for n in tt.tree.find_clades():
        tmp = { "date":n.date,
                "numdate": n.numdate,
                "branch_length":n.branch_length,
                "mutation_length":n.mutation_length,
                "clock_length":n.clock_length,
                "gamma": n.branch_length_interpolator.gamma if n.up else 1.0,
                "date_confidence":list(tt.get_confidence_interval(n))
                }
        node_data[n.name] = tmp



    # vmin, vmax = 0.5, 2.5 # color branches according to the rate deviation
    # for n in tt.tree.find_clades():
    #     if n.up:
    #         print(f"{n.name}: {n.branch_length_interpolator.gamma:1.3f}, {n.mutation_length:1.3e}")
    #         n.color = [int(x*255) for x in cm.cool((min(max(vmin, n.branch_length_interpolator.gamma),vmax)-vmin)/(vmax-vmin))[:3]]
    #     else:
    #         n.color = [200,200,200]

    # Phylo.draw(tt.tree, show_confidence=False, label_func = lambda x:'')

    Phylo.write(tt.tree, args.output_tree, 'newick')

    with open(args.output_node_data, 'w') as fh:
        json.dump({"nodes":node_data}, fh)