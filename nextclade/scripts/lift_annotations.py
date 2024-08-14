"""
#%%
Use the output of nextclade to lift annotations from reference to query
"""


from pathlib import Path

import pandas as pd

df = pd.read_csv("out3/nextclade.tsv", sep="\t")

# get the first row
df = df.iloc[0]

alignment_start = df["alignmentStart"]
alignment_end = df["alignmentEnd"]
insertions = df["insertions"].split(",")
deletions = df["deletions"].split(",")

# Turn insertions and deletions into a list of tuples: (pos, length)

dels = []
for i in deletions:
    if "-" in i:
        start, end = i.split("-")
        dels.append((int(start), int(end) - int(start) + 1))
        continue
    dels.append((int(i), 1))

# print(dels)


ins = []
for i in insertions:
    pos, seq = i.split(":")
    ins.append((int(pos), len(seq)))

offset = - (alignment_start - 1)
next_del = dels.pop(0) if dels else None
next_ins = ins.pop(0) if ins else None

offsets = {}

for r in range(alignment_start, alignment_end + 1):
    # if inside deletion, bump offset
    # if end of deletion, pop next deletion
    if next_del:
        if r >= next_del[0]:
            offset -= 1
        if r == next_del[0] + next_del[1] - 1:
            next_del = dels.pop(0) if dels else None

    offsets[int(r)] = [int(offset), int(r + offset)]

    # if inside insertion, bump offset, pop next insertion
    if next_ins:
        if r == next_ins[0]:
            offset += next_ins[1]
            next_ins = ins.pop(0) if ins else None




print(offsets)

import json

with open("out/offsets.json", "w") as f:
    f.write(json.dumps(offsets, indent=2))



# %%

# We can check that these are correct by looking at ref and query sequences
ref = "".join(Path("/Users/corneliusromer/Downloads/sequence (20).fasta").read_text().split("\n")[1:])
print(ref)
# %%
qry = "".join(Path("resources/clade-i/reference.fasta").read_text().split("\n")[1:])
# %%

for ref_pos, (offset, qry_pos) in offsets.items():
    # only print if ref and query are different
    if ref[ref_pos - 1] != qry[qry_pos - 1]:
        print(f"Ref: {ref_pos} {ref[ref_pos - 1]} Query: {qry_pos} {qry[qry_pos - 1]} Offset: {offset}")

# %%

# Read in GFF file
# Treat as simple TSV

gff = pd.read_csv("resources/clade-i/sequence (20).gff3", sep="\t", comment="#", header=None)
new_gff = gff.copy()

# Map columns 2/3 to qry positions from ref positions
# Editing the gff DataFrame new_gff in place
qry_len = len(qry)
new_gff[3] = gff[3].apply(lambda x: offsets.get(x, [1, 1])[1])
new_gff[4] = gff[4].apply(lambda x: offsets.get(x, [qry_len,qry_len])[1])



# %%
new_gff

Path("resources/clade-i/genome_annotation2.gff3").write_text(new_gff.to_csv(sep="\t", header=False, index=False))

# %%

mask = pd.read_csv("resources/clade-iib/mask.bed", sep="\t")
new_mask = mask.copy()
new_mask["ChromStart"] = mask["ChromStart"].apply(lambda x: offsets.get(x, [1, 1])[1])
new_mask["ChromEnd"] = mask["ChromEnd"].apply(lambda x: offsets.get(x, [qry_len, qry_len])[1])
Path("resources/clade-i/mask2.bed").write_text(new_mask.to_csv(sep="\t", index=False))
# %%
