#!/usr/bin/env python3
"""
Graft recombinant sequences onto a phylogenetic tree.

This script takes a tree and a list of recombinant sequences, roots the tree
on specified root sequences, and attaches recombinants to the root with long branches.
"""

import argparse
import sys

from Bio import Phylo


def read_recombinants(recombinants_file):
    """
    Read recombinant sequence names from a file.

    Args:
        recombinants_file (str): Path to file containing recombinant names (one per line)

    Returns:
        list: List of recombinant sequence names
    """
    try:
        with open(recombinants_file, 'r') as f:
            recombinants = [line.strip() for line in f if line.strip()]
        return recombinants
    except FileNotFoundError:
        print(f"Warning: Recombinants file not found: {recombinants_file}", file=sys.stderr)
        return []


def graft_recombinants(tree, recombinants, root_sequences, branch_length=10.0, verbose=False):
    """
    Graft recombinant sequences onto the root of a tree.

    Args:
        tree: Bio.Phylo tree object
        recombinants (list): List of recombinant sequence names to graft
        root_sequences (list): List of sequence names to use for rooting
        branch_length (float): Branch length for grafted recombinants (default: 10.0)
        verbose (bool): Print verbose output
    """
    if not recombinants:
        if verbose:
            print("No recombinants to graft", file=sys.stderr)
        return tree

    # Root the tree on specified sequences
    if root_sequences:
        # If multiple root sequences provided, root on first available
        root_found = False
        for root_seq in root_sequences:
            # Check if root sequence exists in tree
            for clade in tree.find_clades():
                if clade.name == root_seq:
                    try:
                        tree.root_with_outgroup(root_seq)
                        root_found = True
                        if verbose:
                            print(f"Rooted tree on: {root_seq}", file=sys.stderr)
                        break
                    except Exception as e:
                        if verbose:
                            print(f"Warning: Could not root on {root_seq}: {e}", file=sys.stderr)
                        continue
            if root_found:
                break

        if not root_found and verbose:
            print("Warning: None of the specified root sequences found in tree", file=sys.stderr)

    # Graft each recombinant to the root with a long branch
    clade_cls = type(tree.root)
    for recombinant in recombinants:
        new_clade = clade_cls(name=recombinant, branch_length=branch_length)
        tree.root.clades.append(new_clade)
        if verbose:
            print(f"Grafted recombinant: {recombinant} (branch length: {branch_length})", file=sys.stderr)

    return tree


def main(args):
    """Main function to orchestrate the grafting process."""
    # Load the input tree
    tree = Phylo.read(args.input_tree, "newick")

    if args.verbose:
        print(f"Loaded tree from: {args.input_tree}", file=sys.stderr)
        terminal_count = len(list(tree.get_terminals()))
        print(f"Tree has {terminal_count} terminal nodes", file=sys.stderr)

    # Read recombinants file
    recombinants = read_recombinants(args.recombinants)

    if args.verbose:
        print(f"Found {len(recombinants)} recombinant(s): {', '.join(recombinants) if recombinants else 'none'}", file=sys.stderr)

    # Parse root sequences (can be space-separated)
    root_sequences = args.root.split() if args.root else []

    # Graft recombinants onto the tree
    tree = graft_recombinants(
        tree,
        recombinants,
        root_sequences,
        branch_length=args.branch_length,
        verbose=args.verbose
    )

    # Write output tree
    Phylo.write(tree, args.output_tree, "newick", format_branch_length="%1.8f")

    if args.verbose:
        print(f"Output tree written to: {args.output_tree}", file=sys.stderr)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(
        description="Graft recombinant sequences onto a phylogenetic tree"
    )
    parser.add_argument(
        "--input-tree",
        type=str,
        required=True,
        help="Path to input Newick tree file"
    )
    parser.add_argument(
        "--recombinants",
        type=str,
        required=True,
        help="Path to file containing recombinant sequence names (one per line)"
    )
    parser.add_argument(
        "--root",
        type=str,
        default="",
        help="Space-separated sequence name(s) to root the tree on"
    )
    parser.add_argument(
        "--output-tree",
        type=str,
        required=True,
        help="Path to output Newick tree file"
    )
    parser.add_argument(
        "--branch-length",
        type=float,
        default=10.0,
        help="Branch length for grafted recombinants (default: 10.0)"
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Print verbose output"
    )

    args = parser.parse_args()
    main(args)
