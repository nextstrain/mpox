import argparse
import csv
import re
import sys


def load_accession_map(metadata_file):
    """
    Load mapping from GenBank accessions to PPX accessions from metadata.tsv
    """
    accession_map = {}

    with open(metadata_file, 'r', newline='') as tsv_file:
        reader = csv.DictReader(tsv_file, delimiter='\t')
        for row in reader:
            ppx_accession = row.get('accession')
            genbank_base = row.get('insdcAccessionBase')
            genbank_full = row.get('insdcAccessionFull')

            # Map both forms of GenBank accessions to PPX
            if genbank_base and ppx_accession:
                accession_map[genbank_base] = ppx_accession
            if genbank_full and ppx_accession:
                accession_map[genbank_full] = ppx_accession

    return accession_map

def replace_accessions_inplace(input_file, accession_map):
    """
    Process file line by line:
    - Keep original lines
    - Add new lines with replacements when GenBank accessions are found
    """
    # Sort accessions by length (longest first) to avoid partial replacements
    sorted_accessions = sorted(accession_map.keys(), key=len, reverse=True)

    # Compile regex pattern for faster matching
    # This creates a pattern like: (acc1|acc2|acc3) with proper escaping
    pattern = '|'.join(re.escape(acc) for acc in sorted_accessions)
    regex = re.compile(f'({pattern})')

    with open(input_file, 'r') as f:
        lines = f.readlines()

    new_lines = []
    replacement_count = 0
    lines_modified = 0

    for line in lines:
        new_lines.append(line)

        # Check if line contains any accessions
        matches = regex.findall(line)
        if matches:
            # Create a new line with replacements
            modified_line = line
            replacements_in_line = 0

            for match in set(matches):  # Use set to avoid counting duplicates multiple times
                modified_line = modified_line.replace(match, accession_map[match])
                replacements_in_line += modified_line.count(accession_map[match])

            # If we made replacements, add the modified line
            if modified_line != line:
                new_lines.append(modified_line)
                replacement_count += replacements_in_line
                lines_modified += 1

    # Only write back if we made changes
    if replacement_count > 0:
        with open(input_file, 'w') as f:
            f.writelines(new_lines)

    return replacement_count, lines_modified

def main():
    parser = argparse.ArgumentParser(description='Process GenBank accessions to PPX accessions')
    parser.add_argument('--metadata', required=True, help='Path to the metadata.tsv file')
    parser.add_argument('--input', required=True, nargs='+', help='Input file(s) containing GenBank accessions')

    args = parser.parse_args()

    # Load the accession mapping
    print(f"Loading accession mapping from {args.metadata}...", file=sys.stderr)
    accession_map = load_accession_map(args.metadata)
    print(f"Loaded {len(accession_map)} accession mappings", file=sys.stderr)

    # Process each input file
    total_files = len(args.input)
    changed_files = 0
    total_replacements = 0
    total_lines_modified = 0

    for idx, input_file in enumerate(args.input, 1):
        print(f"Processing file {idx}/{total_files}: {input_file}...", file=sys.stderr)
        replacements, lines_modified = replace_accessions_inplace(input_file, accession_map)

        if replacements > 0:
            changed_files += 1
            total_replacements += replacements
            total_lines_modified += lines_modified
            print(f"  - Made {replacements} replacements across {lines_modified} lines", file=sys.stderr)
        else:
            print(f"  - No replacements needed", file=sys.stderr)

    # Print summary statistics
    print("\nSummary:", file=sys.stderr)
    print(f"- Files processed: {total_files}", file=sys.stderr)
    print(f"- Files modified: {changed_files}", file=sys.stderr)
    print(f"- Total replacements: {total_replacements}", file=sys.stderr)
    print(f"- Total lines with replacements: {total_lines_modified}", file=sys.stderr)

if __name__ == "__main__":
    main()
