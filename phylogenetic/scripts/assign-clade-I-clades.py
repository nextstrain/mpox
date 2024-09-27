"""
Labels the two child nodes of the root as clade Ia and Ib
based on an expected tree structure. This approach is temporary and is
necessary because the distribution of mutations at these two nodes
(via augur ancestral) is random and thus we can't use our normal
`augur clades` approach.

This script expects certain tips to be present for each clade
which are force-included in the analysis.

Usage: provide the tree on STDIN, node-data JSON written to STDOUT
"""

import argparse
from sys import stdin,stdout
from Bio import Phylo
from collections import defaultdict
import json

TIPS = {
   "clade Ia": ["PP601197", "KJ642618"],
   "clade Ib": ["PP601222", "PP601209"]
}

if __name__=="__main__":
    parser = argparse.ArgumentParser(description = __doc__)
    args = parser.parse_args()

    t = Phylo.read(stdin, "newick")

    node_data = { # node-data JSON
        "nodes": defaultdict(dict),
        "branches": defaultdict(dict),
    }

    for node in t.clade:
        tips = set([n.name for n in node.get_terminals()])
        for clade_name, defining_tips in TIPS.items():
            if all([name in tips for name in defining_tips]):
                node_data['branches'][node.name]['labels'] = {'clade': clade_name}
                node_data['nodes'][node.name]["clade_membership"] = clade_name
                for descendant in node.find_clades():
                    node_data['nodes'][descendant.name]["clade_membership"] = clade_name

    json.dump(node_data, stdout)
