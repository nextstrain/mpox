"""
Use provided metadata to assign clade to terminal nodes. If the metadata is complete (i.e. all tips are assigned a clade)
then for each clade we assign the clade to internal nodes and set a label for the MRCA node, iff the tips are monophyletic.
"""

import argparse
from sys import stderr, stdout, exit
from Bio import Phylo
import json
from augur.io import read_metadata
from augur.argparse_ import ExtendOverwriteDefault
from collections import defaultdict


def assign_internal_nodes(clade_name, terminal_nodes, node_data):
    print(f"Assigning {clade_name} to internal nodes")
    mrca = t.is_monophyletic(terminal_nodes)
    if not mrca:
        print(f"WARNING: {clade_name} wasn't monophyletic! Clades will not be assigned to internal nodes")
        return
    for node in mrca.get_nonterminals():
        node_data['nodes'][node.name] = {'clade_membership': clade_name}
    node_data['branches'][mrca.name] = {'labels': {'clade': clade_name}}

if __name__=="__main__":
    parser = argparse.ArgumentParser(description = __doc__)
    parser.add_argument('--metadata', required=True, type=str, help="Metadata TSV")
    parser.add_argument('--clade-column', required=False, type=str, default='clade', help="Column name in the metadata TSV where clade is defined")
    parser.add_argument('--metadata-id-columns', default=['accession'], nargs="+", action=ExtendOverwriteDefault, help="names of possible metadata columns containing identifier information, ordered by priority. Only one ID column will be inferred.")
    parser.add_argument('--tree', required=True, type=str, help="Newick tree")
    parser.add_argument('--output-node-data', required=True, type=str, help="Node-data JSON")
    args = parser.parse_args()

    metadata = read_metadata(args.metadata, id_columns=args.metadata_id_columns)
    try:
        clades = metadata[args.clade_column]
    except KeyError:
        print("Column {args.clade_column} not found in provided metadata {args.metadata}")
        exit(2)

    t = Phylo.read(args.tree, "newick")

    node_data = {'nodes': {}, 'branches': {}}
    counts = [0,0]
    terminals = defaultdict(list)

    for node in t.get_terminals():
        counts[0]+=1
        if node.name in clades:
            counts[1]+=1
            node_data['nodes'][node.name] = {'clade_membership': clades[node.name]}
            terminals[clades[node.name]].append(node)

    print(f"Metadata defined clades for {counts[1]}/{counts[0]} tips in tree", file=stderr)

    if counts[0]==counts[1]:
        for clade_name, clade_terminals in terminals.items():
            assign_internal_nodes(clade_name, clade_terminals, node_data)
    else:
        print(f"WARNING: incomplete metadata. Assignment of clade labels is uncertain and thus we are skipping it")

    with open(args.output_node_data, 'w') as fh:
        json.dump(node_data, fh)
