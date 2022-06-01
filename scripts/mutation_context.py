from collections import defaultdict
import json, argparse
from timeit import repeat
from Bio import Phylo
import numpy as np



if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="calculate mutation context json",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--tree', type=str, required=True, help="tree file")
    parser.add_argument('--mutations', type=str, required=True, help="mutations")
    parser.add_argument('--output', type=str, metavar="JSON", required=True, help="output Auspice JSON")
    args = parser.parse_args()

    T = Phylo.read(args.tree, 'newick')

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
            node_data[name]["CT_fraction"] = CT_count/GA_CT_count
            print(f'\n\nNODE: {name}\n')
            for mut in node["muts"]:
                a, pos, d = mut[0], int(mut[1:-1]), mut[-1]
                if a in 'ACGT' and d in 'ACGT':
                    print(f"{pos}:\t {a}->{d} \t {node['sequence'][pos-3:pos-1]}|{a}->{d}|{node['sequence'][pos:pos+2]}", end='')
                    if a+d == 'GA' and node['sequence'][pos]=='A':
                        print("\ty", end='')
                        dinuc_count+=1
                    elif a+d == 'CT' and node['sequence'][pos-2]=='T':
                        print("\ty", end='')
                        dinuc_count+=1
                    print()
            node_data[name]["dinuc_context_fraction"] = dinuc_count/GA_CT_count
        else:
            node_data[name]["dinuc_context_fraction"] = None
            node_data[name]["CT_fraction"] = None

    with open(args.output, 'w') as fh:
        json.dump({"nodes":node_data}, fh)


    alphabet = ['A', 'C', 'G', 'T']
    q = len(alphabet)
    root_of_outbreak = T.common_ancestor(["3025", "MPXV_UK_2022_3"])

    tri_all_nodes = np.zeros((len(alphabet)**3, len(alphabet)), dtype=float)
    tri_outbreak =  np.zeros((len(alphabet)**3, len(alphabet)), dtype=float)
    tri_all_nodes_internal = np.zeros((len(alphabet)**3, len(alphabet)), dtype=float)
    tri_outbreak_internal =  np.zeros((len(alphabet)**3, len(alphabet)), dtype=float)
    all_nodes = np.zeros((len(alphabet), len(alphabet)), dtype=float)
    outbreak = np.zeros((len(alphabet), len(alphabet)), dtype=float)
    all_nodes_internal = np.zeros((len(alphabet), len(alphabet)), dtype=float)
    outbreak_internal = np.zeros((len(alphabet), len(alphabet)), dtype=float)

    for root, M, M_int, tri_nuc, tri_nuc_internal in [(T, all_nodes, all_nodes_internal, tri_all_nodes, tri_all_nodes_internal), (root_of_outbreak, outbreak, outbreak_internal, tri_outbreak, tri_outbreak_internal)]:
        for n in root.get_nonterminals():
            if n==T.root:
                continue

            for c in n:
                for mut in data[c.name]['muts']:
                    a, pos, d = mut[0], int(mut[1:-1]), mut[-1]
                    if a in 'ACGT' and d in 'ACGT':
                        tri_nuc_str = data[c.name]['sequence'][pos-2:pos+1]
                        if '-' not in tri_nuc_str:
                            context = alphabet.index(data[c.name]['sequence'][pos-2]), alphabet.index(a), alphabet.index(data[c.name]['sequence'][pos])
                            tri_nuc[context[0]*q**2 + context[1]*q + context[2], alphabet.index(d)] += 1
                        M[alphabet.index(a), alphabet.index(d)] += 1
                        if not c.is_terminal():
                            M_int[alphabet.index(a), alphabet.index(d)] += 1
                            if '-' not in tri_nuc_str:
                                context = alphabet.index(data[c.name]['sequence'][pos-2]), alphabet.index(a), alphabet.index(data[c.name]['sequence'][pos])
                                tri_nuc_internal[context[0]*q**2 + context[1]*q + context[2], alphabet.index(d)] += 1


    non_outbreak = all_nodes - outbreak
    outbreak_length = root_of_outbreak.total_branch_length()
    non_outbreak_length = T.total_branch_length() - outbreak_length
    aseq = np.array(list(data[T.root.name]['sequence']))
    nuc_counts = np.array([np.sum(aseq==nuc) for nuc in alphabet])
    T_i_non_outbreak = np.array([non_outbreak_length*f for f in nuc_counts])
    T_i_outbreak = np.array([outbreak_length*f for f in nuc_counts])

    from treetime import GTR

    model_non_outbreak = GTR.infer(non_outbreak, T_i_non_outbreak, nuc_counts, alphabet='nuc_nogap', pc=0.01)
    model_outbreak = GTR.infer(outbreak, T_i_outbreak, nuc_counts, alphabet='nuc_nogap', pc=0.01)
    print(model_outbreak)
    print(model_non_outbreak)


    def cost(x, M, M_base, CT, AG):
        lam = x[0]*M_base + x[1]*CT + x[2]*AG
        return np.sum(lam - M*np.log(np.maximum(lam,1e-10)))

    from scipy.optimize import minimize

    CT = np.zeros((4,4))
    AG = np.zeros((4,4))
    M_base = non_outbreak/non_outbreak.sum()
    CT[1,3] = 1
    AG[2,0] = 1

    sol = minimize(cost, [10, 45, 45], args=(outbreak, M_base, CT, AG))
    print(sol['x'][0]*M_base + sol['x'][1]*CT + sol['x'][2]*AG)

    sol_int = minimize(cost, [10, 45, 45], args=(outbreak_internal, M_base, CT, AG))
    print(sol_int['x'][0]*M_base + sol_int['x'][1]*CT + sol_int['x'][2]*AG)

    for i, tri in product(alphabet, repeat=3):
        print("".join(tri), tri_all_nodes[i])

    from itertools import product
    for i, tri in enumerate(product(alphabet, repeat=3)):
        print("".join(tri), ":\t", "\t".join(map(lambda x:f"{int(x)}", tri_all_nodes[i]-tri_outbreak[i])),"\t---\t", "\t".join(map(lambda x:f"{int(x)}", tri_outbreak[i])))
