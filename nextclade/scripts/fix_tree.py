import argparse
from collections import defaultdict

from Bio import Phylo
from treetime import TreeAnc

if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="remove time info",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter,
    )

    parser.add_argument("--alignment", type=str, required=True, help="input sequences")
    parser.add_argument("--input-tree", type=str, required=True, help="input nwk")
    parser.add_argument("--root", type=str, required=False, help="root node")
    parser.add_argument("--output", type=str, required=True, help="output nwk")
    args = parser.parse_args()

    T = Phylo.read(args.input_tree, "newick")

    if args.root:
        T.root_with_outgroup(args.root)
    else:
        T.root_at_midpoint()

    tt = TreeAnc(tree=T, aln=args.alignment, gtr="JC69")
    tt.optimize_tree(prune_short=True)

    # make list of mutations that are phylogenetically informative (not gaps of N)
    for n in T.find_clades():
        n.relevant_mutations = set()
        for mut in n.mutations:
            if (mut[0] in "ACGT") and (mut[2] in "ACGT"):
                n.relevant_mutations.add(mut)

    print("### Checking for immediate reversions\n")
    reversions = list()
    for clade in T.find_clades():
        for child in clade.clades:
            if child.is_terminal():
                continue
            for grandchild in child.clades:
                if grandchild.is_terminal():
                    continue
                # Check if one of grandchild mutation reverts one of child
                for mut_child in child.relevant_mutations:
                    for mut_grandchild in grandchild.relevant_mutations:
                        if mut_child[1] == mut_grandchild[1] and mut_child[2] == mut_grandchild[0]:
                            reversions.append(
                                {
                                    "parent": clade,
                                    "child": child,
                                    "grandchild": grandchild,
                                    "mut_child": mut_child,
                                    "mut_grandchild": mut_grandchild,
                                }
                            )
                            print(f"Below {clade}: {mut_child} in {child.name} reverted in {grandchild.name}")

    for reversion in reversions:
        # Remove reversion from grandchild
        reversion["grandchild"].relevant_mutations.remove(reversion["mut_grandchild"])
        # Remove grandchild from child
        reversion["child"].clades.remove(reversion["grandchild"])
        # If there are mutations, add grandchild as child of parent
        if reversion["grandchild"].relevant_mutations != reversion["parent"].relevant_mutations:
            reversion["parent"].clades.append(reversion["grandchild"])
        else:
            # Otherwise add grandchild clades to parent
            reversion["parent"].clades.extend(reversion["grandchild"].clades)

    # find mutations that occur multiple times in branches leading to children of a node.
    # use these mutations to group clades to merge later.
    max_iter = 5
    for ii in range(max_iter):
        print(f"###\nIteration: {ii+1}\n")
        nodes_to_merge = defaultdict(list)

        # For each node, for each mutation, find all children that have this mutation
        for n in T.get_nonterminals():
            shared_mutations = defaultdict(list)
            for c in n:
                for mut in c.relevant_mutations:
                    shared_mutations[mut].append(c)

            # For each mutation, if it occurs in more than one child, add the node and the children to the list of nodes to merge
            for mut in shared_mutations:
                if len(shared_mutations[mut]) > 1:
                    nodes_to_merge[(n, tuple(shared_mutations[mut]))].append(mut)

        if len(nodes_to_merge) == 0:
            print("No more shared mutations -- breaking out of loop.")
            break

        already_touched = set()

        # Merge children starting with the ones that have the most shared mutations
        for (parent, children), mutations in sorted(
            nodes_to_merge.items(), key=lambda x: len(x[1]), reverse=True
        ):
            # Each child can only be merged once per iteration
            if any([c in already_touched for c in children]):
                continue

            print(
                "####\nmerging clades:\n\t",
                "\n\t".join(
                    [
                        f"{c.name} with mutations {c.relevant_mutations} and {c.count_terminals()} tips"
                        for c in children
                    ]
                ),
            )
            print("shared mutations:", mutations)
            print("\n")

            # Remove children to be merged from parent
            parent.clades = [c for c in parent if c not in children]

            # Create new internal node for the merged children
            new_clade = Phylo.BaseTree.Clade(
                branch_length=tt.one_mutation * len(mutations),
                name=f"{'_'.join([c.name for c in children])}_merged",
            )
            new_clade.relevant_mutations = set(mutations)

            # Add merged children to new internal node
            for c in children:
                left_over_mutations = c.relevant_mutations.difference(mutations)

                # Terminal nodes and internal nodes with mutations should be added as children to the new internal node
                if len(left_over_mutations) or c.is_terminal():
                    c.relevant_mutations = left_over_mutations
                    c.branch_length = tt.one_mutation * len(c.relevant_mutations)
                    new_clade.clades.append(c)
                # Internal branches of 0 length should be removed and children added to the new internal node directly
                else:
                    new_clade.clades.extend(c.clades)
                already_touched.add(c)

            parent.clades.append(new_clade)

    # Prune all terminals without names
    count = 0
    while True:
        for n in T.find_clades():
            if n.is_terminal() and n.name is None:
                T.prune(n)
                print("Warning: Pruned terminal node without name. This should not happen.")
                count += 1
        if count == 0:
            break

    Phylo.write(T, args.output, "newick")
