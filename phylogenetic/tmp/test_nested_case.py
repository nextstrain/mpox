"""
Create a test case with nested reversions to validate the greedy algorithm.

Tree structure:
  ROOT
    - GRANDPARENT (has 2 muts: G10A, G11A)
      - PARENT (reverts both: A10G, A11G, adds C20T)
        - CHILD (has 2 muts: G30A, G31A)
          - GRANDCHILD (reverts both: A30G, A31G, adds C40T)

Without the greedy check, we might try to:
1. Move PARENT from GRANDPARENT to GREAT_GRANDPARENT
2. Move GRANDCHILD from CHILD to PARENT
   But PARENT has already been moved, so this creates inconsistency!

With the greedy check:
1. Move PARENT from GRANDPARENT to GREAT_GRANDPARENT (mark GREAT_GRANDPARENT as touched)
2. Try to move GRANDCHILD from CHILD to PARENT
   → Skip because PARENT is in the subtree of touched GREAT_GRANDPARENT
"""
from Bio.Phylo.BaseTree import Clade
from Bio import Phylo

# This would need actual alignment and proper TreeTime setup
# For now, just document the scenario
print(__doc__)
