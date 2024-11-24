"""
Use provided metadata to assign clades to internal nodes and those with missing metadata.
For each valid clades (i.e. those which match a hardcoded list) as long as the tips are monophyletic
in the tree (ignoring missing data) then we label all internal nodes and missing tips with that clade
as well as labelling the MRCA branch.
"""

import argparse
from sys import exit
from Bio import Phylo
import json
from augur.io import read_metadata
from augur.argparse_ import ExtendOverwriteDefault
from collections import defaultdict

VALID_CLADES = set(['Ia', 'Ib', 'I'])
MISSING = ''

def assign_internal_nodes(t, clade_name, terminal_nodes, missing_nodes, node_data):
    print(f"[clade metadata] Assigning {clade_name} to internal nodes & labelling MRCA branch")
    mrca = t.common_ancestor(terminal_nodes)

    if not all([(n in terminal_nodes or n in missing_nodes) for n in mrca.get_terminals()]):
        print(f"[clade metadata] ERROR {clade_name} wasn't monophyloetic (after accounting for nodes missing clade values).  Clades will not be assigned to internal nodes.")
        return

    for node in (n for n in mrca.find_clades() if n not in terminal_nodes): # skip ones we have already assigned
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
    counts = {'missing': 0, 'valid': 0, 'invalid': 0}
    terminals = defaultdict(list)
    missing_nodes = []


    print(f"[clade metadata] Pass 1/2 - assigning clades from metadata to nodes")
    for node in t.get_terminals():
        clade_value = clades[node.name]
        if clade_value == MISSING:
            counts['missing']+=1
            missing_nodes.append(node)
        elif clade_value in VALID_CLADES:
            counts['valid']+=1
            node_data['nodes'][node.name] = {'clade_membership': clade_value}
            terminals[clade_value].append(node)
        else:
            counts['invalid']+=1
    print(f"[clade metadata] {sum(counts.values())} tips: {counts['valid']} valid, {counts['invalid']} invalid, {counts['missing']} missing clade values")


    print(f"[clade metadata] Pass 2/2 - if (valid) clades are monophyletic then label internal nodes (and missing tips)")
    for clade_name, clade_terminals in terminals.items():
        assign_internal_nodes(t, clade_name, clade_terminals, missing_nodes, node_data)

    with open(args.output_node_data, 'w') as fh:
        json.dump(node_data, fh)
