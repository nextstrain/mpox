"""
Adds a new column `--output-column` that is a concatenation of
`--input-columns` with a separator `--separator`.
Usage:
python3 scripts/make_nice_strain_names.py \
    --metadata {input.metadata} \
    --input-columns accession country date \
    --separator '|' \
    --output-column strain_display \
    --output {output.metadata}
"""

import argparse

import pandas as pd

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--metadata', required=True)
    parser.add_argument('--input-columns', nargs='+', required=True)
    parser.add_argument('--separator', required=True)
    parser.add_argument('--output-column', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()

    df = pd.read_csv(args.metadata, sep='\t', dtype=str)
    separator = str(args.separator)
    df[args.output_column] = df[args.input_columns].astype(str).apply(lambda x: separator.join(x), axis=1)
    df.to_csv(args.output, sep='\t', index=False)

if __name__ == '__main__':
    main()
