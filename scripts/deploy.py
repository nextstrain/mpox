"""
- Generate dated builds where each node has random id
- Deploy builds from staging to production

Builds are downloaded from staging
This script is to be run independently from snakemake
"""

import argparse
import datetime
import gzip
import json
import os
import uuid


def add_branch_id_recursive(node):
    """
    Recursively add randomly generated id to each node in auspice json tree 
    """
    node["branch_attrs"]["labels"] = {}
    node["branch_attrs"]["labels"]["id"] = str(uuid.uuid4())[:8]
    if "children" in node:
        for child in node["children"]:
            add_branch_id_recursive(child)



if __name__=="__main__":
    parser = argparse.ArgumentParser(
        description="Deploy builds from staging to production, generate dated builds where each node has random id",
        formatter_class=argparse.ArgumentDefaultsHelpFormatter
    )


    parser.add_argument('--build-names', nargs='+', type=str, required=True, help="build names to upload")
    parser.add_argument('-f','--force', action='store_true', help="force overwrite of existing dated builds")
    parser.add_argument('--no-dated' , action='store_true', help="do not deploy dated build")
    parser.add_argument('--staging' , action='store_true', help="deploy to staging")
    parser.set_defaults(feature=True)
    args = parser.parse_args()

    print(f"> Deploying builds {args.build_names} to {'staging' if args.staging else 'production'}")
    print("----------------------------------------")

    if not os.path.isdir('staging'):
        os.mkdir('staging')
    for build_name in args.build_names:
        if not args.staging:
            print(f">> Deploying build {build_name} to production")

            # Upload basic builds to staging
            for auspice_file in ['', '_root-sequence']:
                os.system(f"aws s3 cp s3://nextstrain-staging/monkeypox_{build_name}{auspice_file}.json s3://nextstrain-data/monkeypox_{build_name}{auspice_file}.json")
            print(f">> Uploaded {build_name} to production: https://nextstrain.org/staging/monkeypox/{build_name.replace('_', '/')}/")


            if not args.no_dated:
                # Check how many today dated builds exist
                today = datetime.date.today().strftime("%Y-%m-%d")
                os.system(f"aws s3 ls nextstrain-data/monkeypox_{build_name}_{today}.json > dated_builds.txt")

                with open('dated_builds.txt') as fh:
                    today_dated_builds_count = len(fh.readlines())
                os.remove('dated_builds.txt')
                if today_dated_builds_count == 0 or args.force:
                    if today_dated_builds_count > 0:
                        print(f">> Overwriting existing dated build due to --force flag being present")

                    for auspice_file in ['', '_root-sequence']:
                        os.system(f"aws s3 cp s3://nextstrain-staging/monkeypox_{build_name}{auspice_file}.json staging/")
                
                    # Load auspice json
                    with gzip.open(f"staging/monkeypox_{build_name}.json") as fh:
                        auspice_json = json.load(fh)

                    add_branch_id_recursive(auspice_json['tree'])
                    
                    with open(f"staging/monkeypox_{build_name}_{today}.json", 'wt') as fh:
                        json.dump(auspice_json, fh)

                    os.system(f"aws s3 cp staging/monkeypox_{build_name}_{today}.json s3://nextstrain-data")
                    os.system(f"aws s3 cp s3://nextstrain-staging/monkeypox_{build_name}_root-sequence.json s3://nextstrain-data/monkeypox_{build_name}_{today}_root-sequence.json")
                    print(f">> Uploaded dated {build_name} to production: https://nextstrain.org/monkeypox/{build_name.replace('_', '/')}/{today}/")
            
                else:
                    print(f">> Warning: Dated {build_name} with date today already exists, skipping upload: https://nextstrain.org/monkeypox/{build_name.replace('_', '/')}/{today}/")
                    print(f">> Hint: Use the --f/--force flag to overwrite existing dated builds")
        if args.staging:
            print(f">> Deploying build {build_name} to staging")
            for auspice_file in ['', '_root-sequence']:
                os.system(f"aws s3 cp auspice/monkeypox_{build_name}{auspice_file}.json s3://nextstrain-staging/monkeypox_{build_name}{auspice_file}.json")
            print(f">> Uploaded {build_name} to staging: https://nextstrain.org/staging/monkeypox/{build_name.replace('_', '/')}/")

        print("----------------------------------------")
