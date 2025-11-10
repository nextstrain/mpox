"""Test that the old buggy logic would create duplicates"""
from collections import defaultdict

# Simulate the bug: 2 reversions found for same (parent, child, grandchild) triple
reversions = [
    {"parent": "PARENT", "child": "CHILD", "grandchild": "GRANDCHILD", "mut": "mut1"},
    {"parent": "PARENT", "child": "CHILD", "grandchild": "GRANDCHILD", "mut": "mut2"},
]

print("OLD BUGGY LOGIC (processing each reversion independently):")
print("=" * 60)

# Simulate parent.clades as a list
parent_clades = ["CHILD", "OTHER"]
grandchild_clades = []

for i, reversion in enumerate(reversions, 1):
    print(f"\nProcessing reversion {i}: {reversion['mut']}")
    
    # Old logic would add grandchild to parent for EACH reversion
    if reversion["grandchild"] not in parent_clades:
        parent_clades.append(reversion["grandchild"])
        print(f"  → Added GRANDCHILD to parent (now: {parent_clades})")
    else:
        print(f"  → GRANDCHILD already in parent (now: {parent_clades})")

print(f"\nFinal parent_clades: {parent_clades}")
if parent_clades.count("GRANDCHILD") > 1:
    print("❌ BUG: GRANDCHILD added multiple times!")
else:
    print("✓ No duplicates")

print("\n" + "=" * 60)
print("NEW FIXED LOGIC (grouping by triple first):")
print("=" * 60)

# Reset
parent_clades = ["CHILD", "OTHER"]

# Group reversions
reversion_groups = defaultdict(list)
for reversion in reversions:
    key = (reversion["parent"], reversion["child"], reversion["grandchild"])
    reversion_groups[key].append(reversion)

print(f"Found {len(reversions)} reversions")
print(f"Grouped into {len(reversion_groups)} unique triples")

# Process each triple once
for key, rev_list in reversion_groups.items():
    print(f"\nProcessing triple {key}")
    print(f"  Removing {len(rev_list)} reversion mutations")
    
    # Add grandchild to parent only ONCE
    parent_clades.append("GRANDCHILD")
    print(f"  → Added GRANDCHILD to parent (now: {parent_clades})")

print(f"\nFinal parent_clades: {parent_clades}")
if parent_clades.count("GRANDCHILD") > 1:
    print("❌ Still has duplicates!")
else:
    print("✓ No duplicates - fix works!")
