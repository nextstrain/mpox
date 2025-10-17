#!/usr/bin/env bash
#
# Find metadata fields that are null across all records in Pathoplexus data
#
# Usage: ./scripts/find_null_metadata_fields.sh results/ppx.ndjson.zst
#

set -euo pipefail

input_file="${1:-results/ppx.ndjson.zst}"

echo "Analyzing metadata fields in: $input_file" >&2
echo "This may take a moment..." >&2
echo "" >&2

zstdcat "$input_file" | jq -s '
  # Collect all keys that have non-null values across all records
  map(.metadata | to_entries) |
  flatten |
  group_by(.key) |
  map({key: .[0].key, hasNonNull: any(.value != null)}) |
  map(select(.hasNonNull == false) | .key)
' | jq -r '.[]'

echo "" >&2
echo "Done!" >&2
