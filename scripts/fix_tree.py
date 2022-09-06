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

    # make list of mutations that are phylogenetically informative (not gaps of N)
    for n in T.find_clades():
        n.relevant_mutations = set()
        for mut in n.mutations:
            if (mut[0] in 'ACGT') and (mut[2] in 'ACGT'):
                n.relevant_mutations.add(mut)

    # find mutations that occur multiple times in branches leading to children of a node.
    # use these mutations to group clades to merge later.
    max_iter = 5
    for ii in range(max_iter):
        print(f"###\nIteration: {ii+1}\n")
        nodes_to_merge = defaultdict(list)
        for n in T.get_nonterminals():
            shared_mutations = defaultdict(list)
            for c in n:
                for mut in c.relevant_mutations:
                    shared_mutations[mut].append(c)

            for mut in shared_mutations:
                if len(shared_mutations[mut])>1:
                    nodes_to_merge[(n,tuple(shared_mutations[mut]))].append(mut)

        if len(nodes_to_merge)==0:
            print("No more shared mutations -- breaking out of loop.")
            break

        already_touched = set()
        for (parent, children), mutations in sorted(nodes_to_merge.items(), key=lambda x:len(x[1]), reverse=True):
            if any([c in already_touched for c in children]):
                continue

            print("####\nmerging clades:\n\t", '\n\t'.join([f"{c.name} with mutations {c.relevant_mutations} and {c.count_terminals()} tips" for c in children]))
            print("shared mutations:", mutations)
            print("\n")

            parent.clades = [c for c in parent if c not in children]
            new_clade = Phylo.BaseTree.Clade(branch_length=tt.one_mutation*len(mutations))
            new_clade.relevant_mutations = set(mutations)
            for c in children:
                left_over_mutations = c.relevant_mutations.difference(mutations)
                if len(left_over_mutations):
                    c.relevant_mutations = left_over_mutations
                    c.branch_length = tt.one_mutation*len(c.relevant_mutations)
                    new_clade.clades.append(c)
                else:
                    new_clade.clades.extend(c.clades)
                already_touched.add(c)

            parent.clades.append(new_clade)

    Phylo.write(T, args.output, 'newick')
