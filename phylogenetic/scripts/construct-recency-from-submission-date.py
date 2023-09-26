import argparse
from datetime import datetime
from augur.io import read_metadata
import json

## Script originally from https://github.com/nextstrain/ncov/blob/master/scripts/construct-recency-from-submission-date.py

def get_recency(date_str, ref_date):
    date_submitted = datetime.strptime(date_str, '%Y-%m-%d').toordinal()
    ref_day = ref_date.toordinal()

    delta_days = ref_day - date_submitted
    if delta_days<=0:
        return 'New'
    elif delta_days<3:
        return '1-2 days ago'
    elif delta_days<8:
        return '3-7 days ago'
    elif delta_days<15:
        return 'One week ago'
    elif delta_days<31:
        return 'One month ago'
    elif delta_days < 121:
        return '1-3 months ago'
    elif delta_days < 365:
        return '3-12 months ago'
    elif delta_days < 365*4:
        return '1-3 years ago'
    elif delta_days < 365*16:
        return '3-15 years ago'
    elif delta_days>=31:
        return 'Older than 15 years'

if __name__ == '__main__':
    parser = argparse.ArgumentParser(
        description="Assign each sequence a field that specifies when it was added",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--metadata', type=str, required=True, help="metadata file")
    parser.add_argument('--metadata-id-columns', nargs="+", help="names of possible metadata columns containing identifier information, ordered by priority. Only one ID column will be inferred.")
    parser.add_argument('--output', type=str, required=True, help="output json")
    args = parser.parse_args()

    meta = read_metadata(args.metadata, id_columns=args.metadata_id_columns).to_dict(orient="index")

    node_data = {'nodes':{}}
    ref_date = datetime.now()

    for strain, d in meta.items():
        if 'date_submitted' in d and d['date_submitted'] and d['date_submitted'] != "undefined":
            node_data['nodes'][strain] = {'recency': get_recency(d['date_submitted'], ref_date)}

    with open(args.output, 'wt') as fh:
        json.dump(node_data, fh)
