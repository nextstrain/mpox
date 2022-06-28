#!/usr/bin/env python3
import argparse
import re
import sys
from datetime import datetime
import pandas as pd

NEXTCLADE_JOIN_COLUMN_NAME = 'seqName'
VALUE_MISSING_DATA = '?'

column_map = {
    "clade": "clade",
    "lineage": "lineage",
    "totalMissing": "missing_data",
    "totalSubstitutions": "divergence",
    "totalNonACGTNs": "nonACGTN",
    "qc.missingData.status": "QC_missing_data",
    "qc.mixedSites.status": "QC_mixed_sites",
    "qc.privateMutations.status": "QC_rare_mutations",
    "qc.frameShifts.status": "QC_frame_shifts",
    "qc.stopCodons.status": "QC_stop_codons",
    "frameShifts": "frame_shifts",
    "isReverseComplement": "is_reverse_complement",
#    "deletions": "deletions",
#    "insertions": "insertions"
#    "substitutions": "substitutions",
#    "aaSubstitutions": "aaSubstitutions"
}


def parse_args():
    parser = argparse.ArgumentParser(
        description="Joins metadata file with Nextclade clade output",
    )
    parser.add_argument("--metadata")
    parser.add_argument("--nextclade")
    parser.add_argument("--id-field")
    parser.add_argument("-o", default=sys.stdout)
    return parser.parse_args()

def main():
    args = parse_args()

    metadata = pd.read_csv(args.metadata, index_col=args.id_field,
                           sep='\t', low_memory=False, na_filter = False)

    # Read and rename clade column to be more descriptive
    clades = pd.read_csv(args.nextclade, index_col=NEXTCLADE_JOIN_COLUMN_NAME,
                         sep='\t', low_memory=False, na_filter = False) \
            .rename(columns=column_map)
    
    clades.index = clades.index.map(lambda x: re.sub(" \|.*", "", x))

    # Select columns in column map
    clades = clades[list(column_map.values())]

    # Separate long from short columns
    short_metadata = metadata.iloc[:,:-2].copy()
    long_metadata = metadata.iloc[:,-2:].copy()

    # Concatenate on columns
    result = pd.merge(
        short_metadata, clades,
        left_index=True,
        right_index=True,
        how='left'
    )

    # Add long columns to back
    result = pd.concat([result, long_metadata], axis=1)

    result.to_csv(args.o, index_label=args.id_field, sep='\t')


if __name__ == '__main__':
    main()
