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
    parser.add_argument('--root', type=str, required=False, help="root node")
    parser.add_argument('--output', type=str, required=True, help="output nwk")
    args = parser.parse_args()

    T = Phylo.read(args.input_tree, 'newick')

    if args.root:
        T.root_with_outgroup(args.root)
    else:
        T.root_at_midpoint()

    tt = TreeAnc(tree=T, aln=args.alignment, gtr='JC69')
    tt.optimize_tree(prune_short=True)

    # make list of mutations that are phylogenetically informative (not gaps of N)
    for n in T.find_clades():
        n.relevant_mutations = set()
        for mut in n.mutations:
            if (mut[0] in 'ACGT') and (mut[2] in 'ACGT'):
                n.relevant_mutations.add(mut)

    # Helper function to check if a node is a descendant of any node in a set
    def is_descendant_of_any(node, ancestor_set, tree):
        """Check if node is a descendant of any node in ancestor_set using tree paths"""
        # Get the path from root to node
        path = tree.get_path(node)
        # Check if any ancestor is in the path
        for ancestor in ancestor_set:
            if ancestor in path:
                return True
        return False

    # Main iteration loop: fix reversions and merge homoplasies until nothing changes
    max_iter = 5
    for ii in range(max_iter):
        print(f"###\nIteration: {ii+1}\n")

        changes_made = False

        # Step 1: Check for and fix immediate reversions
        print(f"Checking for immediate reversions...")
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
                                        "mut_grandchild": mut_grandchild
                                    }
                                )
                                print(f"  Below {clade.name}: {mut_child} in {child.name} reverted in {grandchild.name}")

        if reversions:
            # Group reversions by unique (parent, child, grandchild) triple to avoid duplicate processing
            reversion_groups = defaultdict(list)
            for reversion in reversions:
                key = (id(reversion["parent"]), id(reversion["child"]), id(reversion["grandchild"]))
                reversion_groups[key].append(reversion)

            # Track nodes that have been modified to avoid nested modifications within this iteration
            touched_nodes = set()

            # Process each unique (parent, child, grandchild) triple only once, greedily
            for key, rev_list in reversion_groups.items():
                # Use first reversion to get the nodes (all reversions in group have same nodes)
                parent = rev_list[0]["parent"]
                child = rev_list[0]["child"]
                grandchild = rev_list[0]["grandchild"]

                # Skip if parent is a descendant of an already-touched node (avoid nested modifications)
                if is_descendant_of_any(parent, touched_nodes, T):
                    print(f"    Skipping reversion at {parent.name} (descendant of already-touched node)")
                    continue

                # Remove all reversion mutations from grandchild
                for rev in rev_list:
                    if rev["mut_grandchild"] in grandchild.relevant_mutations:
                        grandchild.relevant_mutations.remove(rev["mut_grandchild"])

                # Remove grandchild from child (only once)
                if grandchild in child.clades:
                    child.clades.remove(grandchild)

                # Add grandchild to parent (only once)
                if grandchild.relevant_mutations != parent.relevant_mutations:
                    parent.clades.append(grandchild)
                else:
                    # Otherwise add grandchild clades to parent
                    parent.clades.extend(grandchild.clades)

                # Mark parent as touched to prevent nested modifications
                touched_nodes.add(parent)
                changes_made = True

            print(f"  Fixed {len(touched_nodes)} reversion groups")

        # Step 2: Check for and merge homoplasies
        print(f"Checking for homoplasies...")
        nodes_to_merge = defaultdict(list)
        for n in T.get_nonterminals():
            shared_mutations = defaultdict(list)
            for c in n:
                for mut in c.relevant_mutations:
                    shared_mutations[mut].append(c)

            for mut in shared_mutations:
                if len(shared_mutations[mut])>1:
                    nodes_to_merge[(n,tuple(shared_mutations[mut]))].append(mut)

        if nodes_to_merge:
            already_touched = set()
            for (parent, children), mutations in sorted(nodes_to_merge.items(), key=lambda x:len(x[1]), reverse=True):
                if any([c in already_touched for c in children]):
                    continue

                print("  Merging clades:\n\t", '\n\t'.join([f"{c.name} with mutations {c.relevant_mutations} and {c.count_terminals()} tips" for c in children]))
                print("  Shared mutations:", mutations)
                print()

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
                changes_made = True

            print(f"  Merged {len(already_touched)} homoplasy groups")

        # If no changes were made this iteration, stop
        if not changes_made:
            print("No changes made in this iteration -- stopping.")
            break

    Phylo.write(T, args.output, 'newick')
