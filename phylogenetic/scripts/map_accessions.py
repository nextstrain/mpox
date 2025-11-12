#!/usr/bin/env python3
"""
Map INSDC accessions to PPX accessions using metadata.

This script reads an accession list file (exclude.txt or include.txt) that contains
INSDC accessions and/or PPX accessions. INSDC accessions (versioned or unversioned)
are transformed to PPX accessions by looking up the mapping in the metadata file.
PPX accessions pass through unchanged. Comments and formatting are preserved.
"""

import argparse
import pandas as pd
import sys
from pathlib import Path


def parse_args():
    parser = argparse.ArgumentParser(
        description=__doc__,
        formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument(
        '--input',
        required=True,
        help='Input accession list file (contains INSDC and/or PPX accessions)'
    )
    parser.add_argument(
        '--metadata',
        required=True,
        help='Metadata TSV file containing INSDC to PPX accession mapping'
    )
    parser.add_argument(
        '--output',
        required=True,
        help='Output accession list file (will contain PPX accessions)'
    )
    parser.add_argument(
        '--insdc-column',
        default='INSDC_accession_version',
        help='Column name for INSDC accessions in metadata (default: INSDC_accession_version)'
    )
    parser.add_argument(
        '--ppx-column',
        default='PPX_accession',
        help='Column name for PPX accessions in metadata (default: PPX_accession)'
    )
    parser.add_argument(
        '--warn-unmapped',
        action='store_true',
        help='Warn about accessions that cannot be mapped (default: silent)'
    )
    return parser.parse_args()


def load_metadata(metadata_path, insdc_column, ppx_column):
    """Load metadata and create INSDC -> PPX mapping dictionary and PPX accession set."""
    try:
        metadata = pd.read_csv(metadata_path, sep='\t', low_memory=False)
    except Exception as e:
        print(f"Error reading metadata file: {e}", file=sys.stderr)
        sys.exit(1)

    # Check required columns exist
    if insdc_column not in metadata.columns:
        print(f"Error: Column '{insdc_column}' not found in metadata", file=sys.stderr)
        print(f"Available columns: {', '.join(metadata.columns)}", file=sys.stderr)
        sys.exit(1)

    if ppx_column not in metadata.columns:
        print(f"Error: Column '{ppx_column}' not found in metadata", file=sys.stderr)
        print(f"Available columns: {', '.join(metadata.columns)}", file=sys.stderr)
        sys.exit(1)

    # Create mapping dictionary for INSDC -> PPX
    insdc_to_ppx = {}
    # Create set of valid PPX accessions
    valid_ppx = set()

    for _, row in metadata.iterrows():
        insdc = row[insdc_column]
        ppx = row[ppx_column]

        # Skip rows where either value is NaN
        if pd.notna(ppx):
            ppx_str = str(ppx).strip()
            valid_ppx.add(ppx_str)

            if pd.notna(insdc):
                # Handle INSDC accessions with version numbers (e.g., "AB123456.1")
                insdc_str = str(insdc).strip()

                # Map versioned INSDC accession to unversioned PPX
                insdc_to_ppx[insdc_str] = ppx_str

                # Also map the base accession without version
                if '.' in insdc_str:
                    base_accession = insdc_str.split('.')[0]
                    # Prefer versioned mapping, but add base if not present
                    if base_accession not in insdc_to_ppx:
                        insdc_to_ppx[base_accession] = ppx_str

    return insdc_to_ppx, valid_ppx


def map_accession_line(line, insdc_to_ppx, valid_ppx, warn_unmapped):
    """
    Map a single line from the accession list file.

    Preserves comments and blank lines. Maps INSDC accessions to PPX accessions.
    PPX accessions pass through unchanged.
    """
    # Preserve blank lines
    if not line.strip():
        return line

    # Check if line starts with comment
    if line.strip().startswith('#'):
        return line

    # Split line into accession and comment parts
    parts = line.split('#', 1)
    accession = parts[0].strip()
    comment = f"#{parts[1]}" if len(parts) > 1 else ""

    # If no accession on this line, return as-is
    if not accession:
        return line

    # Check if it's already a PPX accession - if so, pass through
    if accession in valid_ppx:
        return line

    # Try to map INSDC accession to PPX
    if accession in insdc_to_ppx:
        mapped_accession = insdc_to_ppx[accession]
        # Preserve original formatting with tabs
        if comment:
            return f"{mapped_accession}\t{comment}\n"
        else:
            return f"{mapped_accession}\n"
    else:
        # Accession not found in mapping
        if warn_unmapped:
            print(f"Warning: Could not map accession '{accession}' (not found as INSDC or PPX)",
                  file=sys.stderr)

        # Keep original accession with a note in comment
        if comment:
            return f"{accession}\t{comment} [unmapped]\n"
        else:
            return f"{accession}\t# [unmapped - not found in metadata]\n"


def main():
    args = parse_args()

    # Load metadata and create mapping
    print(f"Loading metadata from {args.metadata}...", file=sys.stderr)
    insdc_to_ppx, valid_ppx = load_metadata(args.metadata, args.insdc_column, args.ppx_column)
    print(f"Loaded {len(insdc_to_ppx)} INSDC -> PPX accession mappings", file=sys.stderr)
    print(f"Found {len(valid_ppx)} valid PPX accessions", file=sys.stderr)

    # Read input file and transform
    print(f"Reading input from {args.input}...", file=sys.stderr)
    try:
        with open(args.input, 'r') as f:
            input_lines = f.readlines()
    except Exception as e:
        print(f"Error reading input file: {e}", file=sys.stderr)
        sys.exit(1)

    # Map each line
    output_lines = []
    mapped_count = 0
    passthrough_count = 0
    unmapped_count = 0

    for line in input_lines:
        original_line = line
        mapped_line = map_accession_line(line, insdc_to_ppx, valid_ppx, args.warn_unmapped)
        output_lines.append(mapped_line)

        # Track statistics
        original_accession = original_line.split('#', 1)[0].strip() if original_line.strip() and not original_line.strip().startswith('#') else None

        if original_accession:
            if '[unmapped]' in mapped_line:
                unmapped_count += 1
            elif original_accession in valid_ppx:
                passthrough_count += 1
            elif mapped_line != original_line:
                mapped_count += 1

    # Write output file
    print(f"Writing output to {args.output}...", file=sys.stderr)
    try:
        with open(args.output, 'w') as f:
            f.writelines(output_lines)
    except Exception as e:
        print(f"Error writing output file: {e}", file=sys.stderr)
        sys.exit(1)

    # Print summary
    print(f"Successfully mapped {mapped_count} INSDC accessions to PPX", file=sys.stderr)
    print(f"Passed through {passthrough_count} existing PPX accessions", file=sys.stderr)
    if unmapped_count > 0:
        print(f"Warning: {unmapped_count} accessions could not be mapped", file=sys.stderr)

    print(f"Done!", file=sys.stderr)


if __name__ == '__main__':
    main()
