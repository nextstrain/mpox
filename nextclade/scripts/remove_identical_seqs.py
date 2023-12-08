#%%
import json
#%%
tree = json.load(open('auspice/nextclade_monkeypox_b1.json'))
#%%
# For each internal node create a list of children with 0 divergence
id_children = {}

def get_identical_children(tree,parent_div=0, parent=""):
    if 'node_attrs' in tree and 'div' in tree['node_attrs'] and tree['node_attrs']['div'] == parent_div:
        if 'strain' in tree['node_attrs']:
            if parent not in id_children:
                id_children[parent] = []
            id_children[parent].append(tree['node_attrs']['strain']['value'])
    if 'children' in tree:
        for child in tree['children']:
            get_identical_children(child, tree['node_attrs']['div'], tree['name'])

get_identical_children(tree['tree'],0,"root")

# %%
# Print all but first of identical children
for parent in id_children:
    if len(id_children[parent]) > 1:
        for child in id_children[parent][1:]:
            print(child)

# %%
