import argparse
import sys
from collections import Counter

from Bio import Phylo


def get_branch_length_distribution(tree) -> Counter[float, int]:
    return Counter(node.branch_length for node in tree.find_clades() if node.branch_length is not None)


def collapse_near_zero_branches(tree, threshold=0.001, verbose=False, divide_by=1):
    """
    Collapses internal branches with lengths below the specified threshold.
    Args:
    tree (Bio.Phylo.BaseTree.Tree): Phylogenetic tree.
    threshold (float): Length threshold to consider for collapsing.
    verbose (bool): Print statistics if True.
    """
    pre_collapse_lengths = set()
    for node in tree.find_clades():
        if node.branch_length is not None:
            pre_collapse_lengths.add(node.branch_length)

    branch_length_counts_before = get_branch_length_distribution(tree)
    tree.collapse_all(lambda c: c.branch_length < threshold)
    branch_length_counts_after = get_branch_length_distribution(tree)

    # Print statistics of which branches were collapsed
    # Calculate the difference in the number of internal branches before and after collapsing
    difference = branch_length_counts_before - branch_length_counts_after

    if verbose:
        print(f"Collapsed {difference.total()} internal branches with lengths below {threshold}")
        print("Collapsed branches:")
        for length, count in difference.items():
            print(f"Branch length {length}: {count} branches")
    
    # Normalize branch lengths by dividing by the specified value
    for node in tree.find_clades():
        if node.branch_length is not None:
            node.branch_length /= divide_by


def main(args):
    # Load a Newick tree from file
    tree = Phylo.read(args.input_tree, "newick")

    # Collapse near-zero internal branches using the provided threshold
    collapse_near_zero_branches(tree, threshold=args.threshold, verbose=args.verbose, divide_by=args.divide_by)

    # Output the resulting tree
    if args.output_tree:
        Phylo.write(tree, args.output_tree, "newick", format_branch_length="%1.8f")
        if args.verbose:
            print(f"Output tree written to {args.output_tree}")
    else:
        Phylo.write(tree, sys.stdout, "newick")


if __name__ == "__main__":
    # Setup command line argument parsing
    parser = argparse.ArgumentParser(
        description="Process a Newick tree to collapse near-zero internal branches."
    )
    parser.add_argument(
        "--threshold",
        type=float,
        default=1.0e-7,
        help="Threshold for collapsing branches (default: 1.0e-7)",
    )
    parser.add_argument(
        "--input-tree",
        type=str,
        required=True,
        help="Path to the input Newick tree file",
    )
    parser.add_argument(
        "--output-tree",
        type=str,
        help="Path to the output Newick tree file (optional, defaults to stdout)",
    )
    parser.add_argument(
        "--verbose",
        action="store_true",
        help="Enable verbose output for more information",
    )
    parser.add_argument(
        "--divide-by",
        type=int,
        default=1,
        help="Divide branch lengths by this value (default: 1)",
    )

    args = parser.parse_args()
    main(args)
