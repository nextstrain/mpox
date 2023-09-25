import pandas as pd
import argparse




if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="remove time info",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--metadata', type=str, required=True, help="input data")
    parser.add_argument('--strain-id', type=str, required=True, help="field to use as strain id")
    parser.add_argument('--output', type=str, required=True, help="output metadata")
    args = parser.parse_args()

    metadata = pd.read_csv(args.metadata, sep='\t')
    if 'strain' in metadata.columns:
        metadata.rename(columns={'strain': 'strain_original'}, inplace=True)

    metadata.rename(columns={args.strain_id: 'strain'}, inplace=True)

    metadata.to_csv(args.output, sep='\t', index=False)
