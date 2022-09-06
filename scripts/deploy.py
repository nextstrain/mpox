import json, argparse,os,uuid, datetime, gzip

def add_branch_id_recursive(node):
    if "labels" not in node["branch_attrs"]:
        node["branch_attrs"]["labels"] = {}
    node["branch_attrs"]["labels"]["id"] = str(uuid.uuid4())[:8]
    if "children" in node:
        for child in node["children"]:
            add_branch_id_recursive(child)



if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="deploy",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )

    parser.add_argument('--builds', nargs='+', type=str, required=True, help="input auspice_json")
    args = parser.parse_args()

    if not os.path.isdir('staging'):
        os.mkdir('staging')
    for build in args.builds:
        for f in ['', '_root-sequence']:
            os.system(f"aws s3 cp s3://nextstrain-staging/monkeypox_{build}{f}.json staging/")
            os.system(f"aws s3 cp s3://nextstrain-staging/monkeypox_{build}{f}.json s3://nextstrain-data/monkeypox_{build}{f}.json")

        with gzip.open(f"staging/monkeypox_{build}.json") as fh:
            d = json.load(fh)

        add_branch_id_recursive(d['tree'])

        today = datetime.date.today().strftime("%Y-%m-%d")
        with open(f"staging/monkeypox_{build}_{today}.json", 'wt') as fh:
            json.dump(d, fh)

        os.system(f"aws s3 cp staging/monkeypox_{build}_{today}.json s3://nextstrain-data")
        os.system(f"aws s3 cp s3://nextstrain-staging/monkeypox_{build}_root-sequence.json s3://nextstrain-data/monkeypox_{build}_{today}_root-sequence.json")


