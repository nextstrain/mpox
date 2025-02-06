import csv
import subprocess

import pandas as pd


def process_location(location):
    if pd.isna(location):
        return "", "", "", ""

    parts = [part.strip() for part in location.split('/')]
    region = parts[0] if len(parts) > 0 else ""
    country = parts[1].strip() if len(parts) > 1 else ""
    division = parts[2].strip() if len(parts) > 2 else ""
    location = parts[3].strip() if len(parts) > 3 else ""

    return region, country, division, location

def convert_metadata(input_file, output_file):
    # Read input TSV
    df = pd.read_csv(input_file, sep='\t')

    # Create output dataframe with all required columns
    output_columns = [
        'accession', 'genbank_accession_rev', 'strain', 'date', 'region',
        'country', 'division', 'location', 'host', 'date_submitted',
        'sra_accession', 'authors', 'full_authors', 'institution', 'clade',
        'outbreak', 'lineage', 'coverage', 'missing_data', 'divergence',
        'nonACGTN', 'QC_missing_data', 'QC_mixed_sites', 'QC_rare_mutations',
        'QC_frame_shifts', 'QC_stop_codons', 'frame_shifts', 'is_reverse_complement'
    ]

    output_df = pd.DataFrame(columns=output_columns)

    # Map the columns we have
    output_df['accession'] = df['accessionVersion']
    output_df['date'] = df['sampleCollectionDate']
    output_df['date_submitted'] = df['releasedDate']

    # Massage dates by replacing missing date parts (day or month) with XX
    # 2024 -> 2024-XX-XX
    # 2024-05 -> 2024-05-XX




    # Process location field
    output_df['region'] = "Africa"
    output_df['country'] = df["geoLocCountry"]
    output_df['division'] = df["geoLocAdmin1"]

    output_df['strain'] = output_df.apply(lambda row: f"{row['date']}|{row['country']}|{row['division']}", axis=1)

    output_df['date'] = output_df['date'].apply(lambda x: 'XXXX-XX-XX' if isinstance(x, float) else f'{x}-XX-XX' if len(x) == 4 else f'{x}-XX' if len(x) == 7 else x)

    output_df['authors'] = df['authors']

    # Fill default values for other columns
    default_values = {
        'genbank_accession_rev': '',
        'host': 'Homo sapiens',
        'sra_accession': '',
        'authors': '',
        'full_authors': '',
        'institution': '',
        'clade': 'Ib',
        'outbreak': '',
        'lineage': '',
        'coverage': '',
        'missing_data': '',
        'divergence': '',
        'nonACGTN': '',
        'QC_missing_data': 'good',
        'QC_mixed_sites': 'good',
        'QC_rare_mutations': 'good',
        'QC_frame_shifts': 'good',
        'QC_stop_codons': 'good',
        'frame_shifts': '',
        'source': 'Pathoplexus',
        'is_reverse_complement': 'false'
    }

    for col, value in default_values.items():
        output_df[col] = value

    # Write to output TSV
    output_df.to_csv(output_file, sep='\t', index=False, quoting=csv.QUOTE_NONE)

# Usage
if __name__ == "__main__":
    convert_metadata("data/mpox_metadata.tsv", "data/ppx_massaged.tsv")
