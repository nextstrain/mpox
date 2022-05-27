from collections import defaultdict
from Bio import SeqIO, Seq, SeqRecord
import json, argparse, os
import pandas as pd



if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="determine repeat variation json",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--sequences', type=str, required=True, help="sequence file")
    parser.add_argument('--reference', type=str, required=True, help="reference sequence")
    parser.add_argument('--repeats', type=str, required=True, help="repeats to analyze")
    parser.add_argument('--output-dir', type=str, metavar="JSON", required=True, help="directory for analysis")
    parser.add_argument('--output', type=str, metavar="JSON", required=True, help="output node data")
    args = parser.parse_args()

    repeats = pd.read_csv(args.repeats, sep='\t')
    ref = str(SeqIO.read(args.reference, 'fasta').seq)

    start = 0
    clipped_seq = ""
    insertion_positions = {}
    for ri, repeat in repeats.iterrows():
        clipped_seq += ref[start:repeat.start]
        start = repeat.end
        insertion_positions[len(clipped_seq)] = repeat.start
    clipped_seq += ref[start:]

    ref_fname = args.output_dir + '/clipped_ref.fasta'
    insertions_fname = args.output_dir + '/insertions.csv'

    SeqIO.write([SeqRecord.SeqRecord(seq=Seq.Seq(clipped_seq), id='repeat_clipped_reference')], ref_fname, format='fasta')

    os.system(f'nextalign run -r {ref_fname} -i {args.sequences} --max-indel 10000 --seed-spacing 1000 --output-insertions {insertions_fname}')

    insertions = pd.read_csv(insertions_fname, sep=',')

    node_data = {}
    for ri, seq_info in insertions.iterrows():
        tmp = {}
        for x in seq_info.insertions.split(';'):
            entries = x.split(':')
            pos = int(entries[0])
            seq = entries[1]
            if pos in insertion_positions:
                orig_pos = insertion_positions[pos]
                tmp[f"repeat-{orig_pos}"] = len(seq)
        node_data[seq_info.seqName] = tmp

    with open(args.output,'w') as fh:
        json.dump({"nodes": node_data},fh)

