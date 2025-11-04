"""custom curate script to add URLs"""
import argparse
import sys
from typing import Iterable

from augur.curate import validate_records
from augur.io.json import dump_ndjson, load_ndjson


def run(args: argparse.Namespace, records: Iterable[dict]) -> Iterable[dict]:

    for index, record in enumerate(records):
        record = record.copy()

        ppx_accession = record.get('PPX_accession', None) # unversioned
        ppx_accession_version = record.get('PPX_accession_version', None) # versioned
        insdc_accession_version = record.get('INSDC_accession_version', None) # versioned
        group_id = record.get('Pathoplexus_group_id', None)

        # Add INSDC_accession__url and PPX_accession__url fields to NDJSON records
        record['PPX_accession__url'] = f"https://pathoplexus.org/seq/{ppx_accession}" \
            if ppx_accession \
            else ""
        record['PPX_accession_version__url'] = f"https://pathoplexus.org/seq/{ppx_accession_version}" \
            if ppx_accession_version \
            else ""
        record['INSDC_accession_version__url'] = f"https://www.ncbi.nlm.nih.gov/nuccore/{insdc_accession_version}" \
            if insdc_accession_version \
            else ""
        record['Pathoplexus_group__url'] = f"https://pathoplexus.org/group/{group_id}" \
            if group_id \
            else ""
        record['submission_database'] = "INSDC" if str(group_id) == "1" else "Pathoplexus"

        yield record


if __name__ == "__main__":
    docstring = __annotations__.get("__doc__", "")
    parser = argparse.ArgumentParser(description=docstring)
    args = parser.parse_args()

    records = load_ndjson(sys.stdin)

    # Validate records have the same input fields
    validated_input_records = validate_records(records, docstring, True)

    # Run this custom curate command to get modified records
    modified_records = run(args, validated_input_records)

    # Validate modified records have the same output fields
    validated_output_records = validate_records(modified_records, docstring, False)

    dump_ndjson(validated_output_records)
