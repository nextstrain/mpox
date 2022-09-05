from collections import defaultdict
import argparse
from treetime import TreeAnc
from Bio import Phylo

if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="remove time info",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--alignment', type=str, required=True, help="input sequences")
    parser.add_argument('--input-tree', type=str, required=True, help="input nwk")
    parser.add_argument('--output', type=str, required=True, help="output nwk")
    args = parser.parse_args()

    T = Phylo.read(args.input_tree, 'newick')

    T.root_at_midpoint()

    tt = TreeAnc(tree=T, aln=args.alignment, gtr='JC69')
    tt.optimize_tree(prune_short=True)

    nodes_to_merge = defaultdict(list)
    for n in T.get_nonterminals():
        shared_mutations = defaultdict(list)
        for c in n:
            for mut in c.mutations:
                if (mut[0] in 'ACGT') and (mut[2] in 'ACGT'):
                    shared_mutations[mut].append(c)
        for mut in shared_mutations:
            if len(shared_mutations[mut])>1:
                nodes_to_merge[(n,tuple(shared_mutations[mut]))].append(mut)

    for parent, children in nodes_to_merge:
        parent.clades = [c for c in parent if c not in children]
        parent.clades.append(Phylo.BaseTree.Clade(
                branch_length=tt.one_mutation))
        parent.clades[-1].clades=list(children)
        print("merging",children)

    Phylo.write(T, args.output, 'newick')
