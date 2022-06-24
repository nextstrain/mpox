import pandas as pd
import argparse
from Bio import SeqIO

if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="Reverse-complement reverse-complemented sequence",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--metadata', type=str, required=True, help="input metadata")
    parser.add_argument('--sequences', type=str, required=True, help="input sequences")
    parser.add_argument('--output', type=str, required=True, help="output sequences")
    args = parser.parse_args()

    metadata = pd.read_csv(args.metadata, sep='\t')
    
    # Read in fasta file
    with open(args.sequences, 'r') as f_in:
        with open(args.output, 'w') as f_out:
            for seq in SeqIO.parse(f_in, 'fasta'):
                # Check if metadata['reverse'] is True
                try:
                    if metadata.loc[metadata['strain'] == seq.id, 'reverse'].values[0] == True:
                        # Reverse-complement sequence
                        seq.seq = seq.seq.reverse_complement()
                        print("Reverse-complementing sequence:", seq.id)
                except:
                    print("No reverse complement for:", seq.id)
                    
                # Write sequences to file
                SeqIO.write(seq, f_out, 'fasta')
