#!/usr/bin/env python3
"""
Test script to validate fix for double-reversion bug in fix_tree.py

Creates a tree with:
- Parent node
- Child node with 2 mutations (G1A, G2A)
- Grandchild node that reverts BOTH mutations (A1G, A2G) plus has other mutations

The bug: grandchild gets added to parent multiple times (once per reversion)
The fix: group reversions by (parent, child, grandchild) and process each triple once
"""

from Bio import Phylo
from Bio.Phylo.BaseTree import Clade
from collections import defaultdict

# Create a minimal tree structure
# Root -> Parent -> Child -> (Grandchild, Terminal1, Terminal2)
#                -> Outgroup

root = Clade(name="root", branch_length=0.0)
parent = Clade(name="NODE_PARENT", branch_length=0.001)
child = Clade(name="NODE_CHILD", branch_length=0.001)
grandchild = Clade(name="NODE_GRANDCHILD", branch_length=0.001)
terminal1 = Clade(name="TIP1", branch_length=0.001)
terminal2 = Clade(name="TIP2", branch_length=0.001)
outgroup = Clade(name="OUTGROUP", branch_length=0.001)

# Build tree topology
root.clades = [parent, outgroup]
parent.clades = [child]
child.clades = [grandchild]
grandchild.clades = [terminal1, terminal2]

# Add mutations to simulate TreeTime output
# Mutations are tuples of (old_base, position, new_base)
parent.mutations = []
parent.relevant_mutations = set()

# Child has 2 mutations: G->A at positions 1 and 2
child.mutations = [('G', 1, 'A'), ('G', 2, 'A')]
child.relevant_mutations = {('G', 1, 'A'), ('G', 2, 'A')}

# Grandchild reverts BOTH mutations and adds 3 new ones
grandchild.mutations = [
    ('A', 1, 'G'),  # Reversion 1
    ('A', 2, 'G'),  # Reversion 2
    ('C', 10, 'T'),  # New mutation 1
    ('C', 11, 'T'),  # New mutation 2
    ('C', 12, 'T'),  # New mutation 3
]
grandchild.relevant_mutations = {
    ('A', 1, 'G'),
    ('A', 2, 'G'),
    ('C', 10, 'T'),
    ('C', 11, 'T'),
    ('C', 12, 'T'),
}

terminal1.mutations = []
terminal1.relevant_mutations = set()
terminal2.mutations = []
terminal2.relevant_mutations = set()
outgroup.mutations = []
outgroup.relevant_mutations = set()

tree = Phylo.BaseTree.Tree(root=root)

print("=" * 60)
print("INITIAL TREE STRUCTURE")
print("=" * 60)
Phylo.draw_ascii(tree)
print(f"\nParent clades: {[c.name for c in parent.clades]}")
print(f"Child clades: {[c.name for c in child.clades]}")
print(f"Grandchild mutations: {grandchild.relevant_mutations}")

# Now run the reversion detection and fixing logic (from fix_tree.py lines 35-87)
print("\n" + "=" * 60)
print("DETECTING REVERSIONS")
print("=" * 60)

reversions = list()
for clade in tree.find_clades():
    for child_node in clade.clades:
        if child_node.is_terminal():
            continue
        for grandchild_node in child_node.clades:
            if grandchild_node.is_terminal():
                continue
            # Check if one of grandchild mutation reverts one of child
            for mut_child in child_node.relevant_mutations:
                for mut_grandchild in grandchild_node.relevant_mutations:
                    if mut_child[1] == mut_grandchild[1] and mut_child[2] == mut_grandchild[0]:
                        reversions.append(
                            {
                                "parent": clade,
                                "child": child_node,
                                "grandchild": grandchild_node,
                                "mut_child": mut_child,
                                "mut_grandchild": mut_grandchild
                            }
                        )
                        print(f"Found reversion: {mut_child} in {child_node.name} -> {mut_grandchild} in {grandchild_node.name}")

print(f"\nTotal reversions found: {len(reversions)}")

# Group reversions by unique (parent, child, grandchild) triple to avoid duplicate processing
reversion_groups = defaultdict(list)
for reversion in reversions:
    key = (id(reversion["parent"]), id(reversion["child"]), id(reversion["grandchild"]))
    reversion_groups[key].append(reversion)

print(f"Unique (parent, child, grandchild) triples: {len(reversion_groups)}")

print("\n" + "=" * 60)
print("APPLYING FIX")
print("=" * 60)

# Process each unique (parent, child, grandchild) triple only once
for key, rev_list in reversion_groups.items():
    # Use first reversion to get the nodes (all reversions in group have same nodes)
    parent_node = rev_list[0]["parent"]
    child_node = rev_list[0]["child"]
    grandchild_node = rev_list[0]["grandchild"]

    print(f"\nProcessing triple: {parent_node.name} -> {child_node.name} -> {grandchild_node.name}")
    print(f"  Removing {len(rev_list)} reversion mutations from {grandchild_node.name}")

    # Remove all reversion mutations from grandchild
    for rev in rev_list:
        if rev["mut_grandchild"] in grandchild_node.relevant_mutations:
            grandchild_node.relevant_mutations.remove(rev["mut_grandchild"])
            print(f"    Removed: {rev['mut_grandchild']}")

    # Remove grandchild from child (only once)
    if grandchild_node in child_node.clades:
        child_node.clades.remove(grandchild_node)
        print(f"  Removed {grandchild_node.name} from {child_node.name}.clades")

    # Add grandchild to parent (only once)
    if grandchild_node.relevant_mutations != parent_node.relevant_mutations:
        parent_node.clades.append(grandchild_node)
        print(f"  Added {grandchild_node.name} to {parent_node.name}.clades")
    else:
        # Otherwise add grandchild clades to parent
        parent_node.clades.extend(grandchild_node.clades)
        print(f"  Extended {parent_node.name}.clades with {grandchild_node.name}'s children")

print("\n" + "=" * 60)
print("FINAL TREE STRUCTURE")
print("=" * 60)
Phylo.draw_ascii(tree)
print(f"\nParent clades: {[c.name for c in parent.clades]}")
print(f"Child clades: {[c.name for c in child.clades]}")
print(f"Grandchild mutations: {grandchild.relevant_mutations}")

# Validation
print("\n" + "=" * 60)
print("VALIDATION")
print("=" * 60)

parent_clade_names = [c.name for c in parent.clades]
has_duplicates = len(parent_clade_names) != len(set(parent_clade_names))

if has_duplicates:
    print("❌ FAIL: Duplicate nodes found in parent.clades!")
    print(f"   Clades: {parent_clade_names}")
else:
    print("✓ PASS: No duplicate nodes in parent.clades")

if grandchild.name in parent_clade_names and grandchild.name not in [c.name for c in child.clades]:
    print("✓ PASS: Grandchild moved from child to parent")
else:
    print("❌ FAIL: Grandchild not properly moved")

expected_mutations = {('C', 10, 'T'), ('C', 11, 'T'), ('C', 12, 'T')}
if grandchild.relevant_mutations == expected_mutations:
    print("✓ PASS: Reversion mutations removed from grandchild")
else:
    print(f"❌ FAIL: Expected mutations {expected_mutations}, got {grandchild.relevant_mutations}")

if len(parent_clade_names) == 2:  # child + grandchild
    print("✓ PASS: Parent has correct number of children")
else:
    print(f"❌ FAIL: Expected 2 children for parent, got {len(parent_clade_names)}")

print("\n" + "=" * 60)
if not has_duplicates:
    print("SUCCESS: Fix prevents duplicate nodes!")
else:
    print("FAILURE: Fix did not prevent duplicate nodes!")
print("=" * 60)
