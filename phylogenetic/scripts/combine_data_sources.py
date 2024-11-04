# TODO: with the release of `augur merge` this script should be replaced
# (it was written prior to `augur merge` existing, however it should be a drop-in replacement)

from typing import Any
from Bio import SeqIO
import argparse
import csv

Sequences = dict[str, SeqIO.SeqRecord]
Metadata = list[dict[str, Any]]
MetadataHeader = list[str]

ACCESSION = 'accession'

def parse_args():
    parser = argparse.ArgumentParser(
        description="Merge sequences and metadata. Duplicate sequences: last one used. Duplicate metadata: values are backfilled, in the case of conflicts the last seen is used.",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('--metadata', type=str, required=True, nargs='+', metavar='TSV',
        help="Input metadata files. If entries are specified as name=FILE then one-hot columns named 'source_{name}' will be added.")
    parser.add_argument('--sequences', type=str, required=True, nargs='+', metavar='FASTA', help="Input fasta sequences")
    parser.add_argument('--metadata-id-column', type=str, default=ACCESSION, help="Metadata column to match with sequence name")
    parser.add_argument('--output-metadata', type=str, required=True, help="output metadata")
    parser.add_argument('--output-sequences', type=str, required=True, help="output sequences")
    return parser.parse_args()

def parse_tsv(fname: str) -> Metadata:
    source_name = None
    assert list(fname).count('=')<=1, f"Too many '=' characters in argument {fname!r}"
    if '=' in fname:
        source_name, fname = fname.split('=')
    with open(fname, "r") as fh:
        reader = csv.DictReader(fh, delimiter="\t")
        metadata = [row for row in reader]
    if source_name:
        for row in metadata:
            row[f"source_{source_name}"] = 'true'
    return metadata

def parse_sequences(fnames: list[str]) -> tuple[Sequences, set[str]]:
    sequences = {}
    for fname in fnames:
        for seq_record in SeqIO.parse(fname, "fasta"):
            name = seq_record.id
            seq_record.id = name
            seq_record.description = seq_record.id
            if name in sequences:
                print(f"WARNING: the sequence {name!r} (from {fname!r}) has already been seen! Overwriting...")
            sequences[name] = seq_record
    return sequences, set(list(sequences.keys()))

def merge_meta(data: list[Metadata], id_col:str) -> tuple[Metadata, MetadataHeader]:
    header: MetadataHeader = list(data[0][0].keys()) # first metadata file...
    for metadata in data[1:]:
        for col_name in list(metadata[0].keys()):
            if col_name not in header:
                header.append(col_name)

    row_by_id: dict[str, dict[str, Any]] = {}
    for metadata in data:
        for row in metadata:
            assert id_col in row, f"ERROR: metadata file missing {id_col!r}"
            if row[id_col] in row_by_id:
                print(f"Multiple entries for {row[id_col]} - merging!")
                master_row = row_by_id[row[id_col]]
                for key,value in row.items():
                    master_row[key] = value
            else:
                row_by_id[row[id_col]] = row

    return list(row_by_id.values()), header

def write_sequences(fname: str, sequences: Sequences) -> None:
    print(f"Writing sequences to {fname}")
    SeqIO.write([x for x in sequences.values()], fname, "fasta")

def write_metadata(fname: str, metadata: Metadata, header: MetadataHeader) -> None:
    print(f"Writing metadata to {fname}")
    with open(fname, "w") as fh:
        print("\t".join(header), file=fh)
        for row in metadata:
            print("\t".join([row.get(field, '') for field in header]), file=fh)

if __name__=="__main__":
    args = parse_args()
    metadatas = [parse_tsv(f) for f in args.metadata]
    sequences, sequence_names = parse_sequences(args.sequences)
    metadata, header = merge_meta(metadatas, args.metadata_id_column)
    write_sequences(args.output_sequences, sequences)
    write_metadata(args.output_metadata, metadata, header)
