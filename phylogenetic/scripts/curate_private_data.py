from typing import Any
from Bio import SeqIO
import argparse
from openpyxl import load_workbook
from datetime import datetime
from os import path, mkdir
from sys import exit

Sequences = dict[str, SeqIO.SeqRecord]
Metadata = dict[str, dict[str, str]]
MetadataHeader = list[str]

# The following seem reasonable to hardcode, as they're central to the current mpox workflows
DATE_COLUMN = 'date'
ACCESSION = 'accession'
REQUIRED_COLUMNS = [ACCESSION, DATE_COLUMN, 'strain']

# The following could be better provided via parsing the (S3) metadata here, but I want to keep this script isolated
# from the Snakemake workflow as much as possible
RECOMMENDED_COLUMNS = ['country', 'division', 'location']

def parse_args():
    parser = argparse.ArgumentParser(
        description="Parse metadata (xlsx format) and sequences (FASTA) for integration into our canonical mpox pipelines",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )
    parser.add_argument('--sequences', type=str, required=True, nargs='+', metavar='FASTA', help="input sequences")
    parser.add_argument('--fasta-header-idx', type=int,
        help='If FASTA headers are "|" separated, this index (1-based) is the accession')
    parser.add_argument('--xlsx', type=str, required=True, help="Metadata file (Excel .xlsx format)")
    parser.add_argument('--remap-columns', type=str, nargs='+', default=[], metavar='old:new', required=False,
        help="Change column names. Note all column names are converted to lower case.")
    return parser.parse_args()


def convert(accession: str, k: str, v: Any) -> str:
    if k==DATE_COLUMN:
        # If we need to attempt to parse a string as a date see
        # <https://github.com/inrb-drc/ebola-nord-kivu/blob/ba9b9b48ba1e8db83486d653f3043d9671611594/scripts/add-new-data#L88-L128>
        assert type(v)==datetime, f"The provided {DATE_COLUMN!r} for {accession!r} must be encoded as a date within Excel"
        return f"{v.year}-{v.month:02}-{v.day:02}"
    return str(v)


def column_map(names: tuple[str], remap: list[tuple[str, str]]) -> list[tuple[str, str]]:
    remap_idx_used = []
    columns = []
    for name in names:
        # any  matching renames / duplications?
        changes = [(idx, name_map) for idx, name_map in enumerate(remap) if name_map[0]==name.lower()]
        if len(changes):
            for idx, name_map in changes:
                remap_idx_used.append(idx)
                columns.append((name, name_map[1]))
        else:
            columns.append((name, name.lower()))

    assert len(set([n[1] for n in columns]))==len(columns), "Requested column names aren't unique!"

    for i,name_map in enumerate(remap):
        if i not in remap_idx_used:
            print(f"WARNING: You asked to remap column {name_map[0]!r} but that column doesn't exist!")
    return columns

def parse_excel(fname: str, remap: list[tuple[str, str]]) -> tuple[Metadata, MetadataHeader]:
    workbook = load_workbook(filename=fname)
    worksheet = workbook.active
    n_rows = 0

    rows = worksheet.values # type: ignore
    assert rows is not None, f"The metadata file {fname!r} seemed to be empty!"

    existing_column_names: tuple[str] = next(rows) # type: ignore
    column_names = column_map(existing_column_names, remap)

    for name in REQUIRED_COLUMNS:
        assert name in [c[1] for c in column_names], f"Metadata didn't have an {name!r} column (after column names were remapped)"
    for name in RECOMMENDED_COLUMNS:
        if name not in [c[1] for c in column_names]:
            print(f"Warning: Metadata didn't have an {name!r} column (after column names were remapped) which is recommended ")

    accession_idx = [c[1] for c in column_names].index(ACCESSION)

    metadata: Metadata = {}
    for row in rows:
        n_rows+=1
        accession = str(row[accession_idx])
        metadata[accession] = {new_name:convert(accession, new_name, row[existing_column_names.index(old_name)]) for old_name,new_name in column_names}

    print(f"Parsed {n_rows} metadata rows (excluding header) from xlsx file")
    return (metadata, [c[1] for c in column_names])


def compare_ids(sequences: Sequences, metadata: Metadata) -> tuple[Sequences, Metadata]:

    acc_meta = set(list(metadata.keys()))
    acc_seqs = set(list(sequences.keys()))

    meta_not_seqs = acc_meta - acc_seqs
    seqs_not_meta = acc_seqs - acc_meta

    if meta_not_seqs:
        print(f"WARNING! Metadata contained entries for {meta_not_seqs!r} but these are not present in the provided sequences and will be removed")
        metadata = {k:v for k,v in metadata.items() if k not in meta_not_seqs}

    if seqs_not_meta:
        print(f"WARNING! Sequences provided for {seqs_not_meta!r} but there is no corresponding metadata. These will be removed")
        sequences = {k:v for k,v in sequences.items() if k not in seqs_not_meta}

    return (sequences, metadata)


def parse_sequences(fnames: list[str], fasta_header_idx: int|None) -> Sequences:
    sequences = {}
    errors = False
    seq_count = 0
    for fname in fnames:
        for seq_record in SeqIO.parse(fname, "fasta"):
            seq_count+=1
            name = seq_record.id
            if fasta_header_idx is not None:
                try:
                    name = name.split('|')[fasta_header_idx-1] # convert 1-based to 0-based
                except IndexError:
                    print("Sequence name {name!r}, when split by '|', did not have enough fields")
            seq_record.id = name
            seq_record.description = seq_record.id
            if name in sequences:
                print(f"ERROR - the sequence {name!r} (from {fname!r}) has already been seen!")
                errors = True
            sequences[name] = seq_record

    assert errors is not True, "Please remove those duplicate sequences!"
    print(f"Parsed {seq_count} sequences from FASTA file(s)")
    return sequences

def fname_in_data_dir(fname: str) -> str:
    # This assumes the folder structure used in mpox doesn't change...
    data_dir = path.normpath(path.join(path.dirname(path.realpath(__file__)), "..", "data"))
    if not path.isdir(data_dir):
        mkdir(data_dir)
    return path.join(data_dir, fname)

def write_sequences(sequences: Sequences) -> None:
    fname = fname_in_data_dir("sequences-private.fasta")
    print(f"Writing sequences to {fname}")
    SeqIO.write([x for x in sequences.values()], fname, "fasta")

def write_metadata(metadata: Metadata, header: MetadataHeader) -> None:
    fname = fname_in_data_dir("metadata-private.tsv")
    print(f"Writing metadata to {fname}")
    with open(fname, "w") as fh:
        print("\t".join(header), file=fh)
        for _, value in metadata.items():
            print("\t".join([value[field] for field in header]), file=fh)

def parse_remap_columns(arg: list[str]) -> list[tuple[str, str]]:
    try:
        return [(x[0].lower(),x[1].lower()) for x in [a.split(':') for a in arg]]
    except:
        print("Error while parsing the remap-columns argument. Each entry must be two column names with a ':' between them.")
        print("For instance: \"--remap-columns 'collection date:date' 'province:division'\"")
        exit(2)

if __name__=="__main__":
    args = parse_args()
    metadata, header = parse_excel(args.xlsx, parse_remap_columns(args.remap_columns))
    sequences = parse_sequences(args.sequences, args.fasta_header_idx)
    sequences, metadata = compare_ids(sequences, metadata)
    write_sequences(sequences)
    write_metadata(metadata, header)
