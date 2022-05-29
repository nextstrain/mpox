from ast import Assign
from collections import defaultdict
import json, argparse
import matplotlib.pyplot as plt
from matplotlib import cm
from Bio import Phylo
import numpy as np

def run_two_rate_model(tree, aln, dates, Tc, base_rate, speed_up, vary_rate=None):
    from treetime import TreeTime
    LH = {}
    def assign_gamma(T):
        for n in T.find_clades():
            if n.up:
                n.branch_length_interpolator.gamma = 1.0

        root_of_outbreak = T.common_ancestor(["3025", "MPXV_UK_2022_3"])
        for n in root_of_outbreak.find_clades():
            if n.name == root_of_outbreak.name:
                n.branch_length_interpolator.gamma=speed_up*0.5
            else:
                n.branch_length_interpolator.gamma=speed_up

    tt = TreeTime(tree=tree, aln=aln, dates=dates, use_fft=True)
    if vary_rate:
        clock_std = base_rate*vary_rate
    else:
        clock_std = None
    tt.run(Tc=Tc, infer_gtr=True, max_iter=3, resolve_polytomies=False,
        branch_length_mode='joint',
        root=args.root, vary_rate=clock_std,
        time_marginal=True, fixed_clock_rate=base_rate, assign_gamma=assign_gamma)

    print(f"LH: {tt.timetree_likelihood(time_marginal=True)}")
    return tt


if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="calculate mutation context json",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--tree', type=str, required=True, help="tree file")
    parser.add_argument('--metadata', type=str, required=True, help="metadata")
    parser.add_argument('--alignment', type=str, required=True, help="alignment")
    parser.add_argument('--base-rate', type=float, required=True, help="ancestral rate")
    parser.add_argument('--outbreak-speed-up', type=float, required=True, help="ancestral rate")
    parser.add_argument('--output-tree', type=str, required=True, help="tree")
    parser.add_argument('--output-node-data', type=str, required=True, help="node-data")
    parser.add_argument('--root', type=str)
    parser.add_argument('--coalescent', type=str)
    args = parser.parse_args()


    from treetime.utils import parse_dates
    speed_up = args.outbreak_speed_up
    rate = args.base_rate
    dates = parse_dates(args.metadata)

    Tc=args.coalescent
    try:
        Tc=float(Tc)
    except:
        pass

    # LH = []
    # for rate in [1e-6, 2e-6, 3e-6, 4e-6]:
    #     tmp = []
    #     for speed_up in [5,10,15,20]:
    #         tt = run_two_rate_model(args.tree, args.alignment, dates, Tc, rate, speed_up)
    #         tmp.append(tt.timetree_likelihood(time_marginal=True))
    #     LH.append(tmp)

    tt = run_two_rate_model(args.tree, args.alignment, dates, Tc, rate, speed_up, vary_rate=0.5)
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

    Phylo.write(tt.tree, args.output_tree, 'newick')

    with open(args.output_node_data, 'w') as fh:
        json.dump({"nodes":node_data}, fh)