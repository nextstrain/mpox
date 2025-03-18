#%%
# Read genbank file
# Replace coordinates

from Bio import SeqIO

with open("phylogenetic/defaults/reference.gb") as handle:
    record_src = SeqIO.read(handle, "genbank")

with open("phylogenetic/defaults/clade-i/reference.gb") as handle:
    record_qry = SeqIO.read(handle, "genbank")

print(record_qry)
# %%

# Try to identify corresponding features using the mapping.txt

with open("refmap/results/mapping.tsv") as handle:
    mapping = handle.readlines()

# Parse mapping
mapping = {int(line.split()[0]): int(line.split()[1]) for line in mapping}

#%%
# make inverse mapping
inverse_mapping = {}
for start, src_start in mapping.items():
    if src_start not in inverse_mapping:
        inverse_mapping[src_start] = []
    inverse_mapping[src_start].append(start)

# # get dictionary of features
# def start_from_location(location):
#     """location is either complement(28603..29262) or 75587..75865"""
#     if location.startswith("complement"):
#         return int(location.split("(")[1].split("..")[0])
#     else:
#         return int(location.split("..")[0])

def start_from_location(location):
    return int(location.start)

# create a dictionary to store the features so we can access them by their start position
src_feats = {"CDS": {}, "gene": {}}
for feature in record_src.features:
    if feature.type == "CDS":
        src_feats["CDS"][start_from_location(feature.location)] = feature
    if feature.type == "gene":
        src_feats["gene"][start_from_location(feature.location)] = feature

# %%
# see if we can find a corresponding feature for each qry feat

replacements = {}

for feature in record_qry.features:
    # Get the start position of the feature
    if not hasattr(feature, "type") or feature.type not in ["CDS", "gene"]:
        continue
    feature_type = feature.type
    start = start_from_location(feature.location)
    if start in inverse_mapping:
        # get the corresponding src features
        src_starts = inverse_mapping[start]
        for src_start in src_starts:
            if src_start in src_feats[feature_type]:
                corresponding_feature = src_feats[feature_type][src_start]
            else:
                # Heuristically try the one that's nearest
                # walk both directions
                found = False
                for i in range(1, 100):
                    if src_start - i in src_feats[feature_type]:
                        corresponding_feature = src_feats[feature_type][src_start - i]
                        found = True
                        break
                    if src_start + i in src_feats[feature_type]:
                        corresponding_feature = src_feats[feature_type][src_start + i]
                        found = True
                        break
                if not found:
                    print(f"Could not find corresponding feature for {feature.location}, tried {src_start}")
                    continue
            print(f"Found corresponding feature for {feature.location}: {corresponding_feature.location}")
            feature.qualifiers = corresponding_feature.qualifiers

with open("refmap/results/qry.gb", "w") as handle:
    SeqIO.write([record_qry], handle, "genbank")

# %%
# Do as string operations: find strings to replace, add to dict
# this way can redo for gff
# Iterate over qry features and replace the qualifiers with src feature qualifiers

for feature in record_qry.features:
    if feature.key in ["CDS", "gene"]:
        pass
        # lookup the corresponding feature

#%%
with open("phylogenetic/defaults/reference.gb") as handle:
    record = next(SeqIO.parse(handle, "genbank"))

record.name = "anything"

#try writing directly to file
with open("refmap/results/src.gb", "w") as handle:
    SeqIO.write([record], handle, "genbank")
