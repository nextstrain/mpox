## Unreleased

## TKTK

- Clade Ia and clade Ib are now distinguished
- Sequences shared via Genbank since 2024 have been added

## 2024-04-19T07:50:39Z

- New hMPXV-1 lineages B.1.21, B.1.22, and C.1.1 are now included in the dataset. For more information on these lineages, see the [hMPXV-1 lineage definitions PR](https://github.com/mpxv-lineages/lineage-designation/pull/37)
- The sequences used in the reference trees have been updated to include the latest sequences available in Genbank as of 2024-04-16

## 2024-01-16T20:31:02Z

Initial release of this dataset. This dataset is similar to the v2 dataset [`MPXV/ancestral`](https://github.com/nextstrain/nextclade_data/tree/2023-08-17--15-51-24--UTC/data/datasets/MPXV/references/ancestral/versions/2023-08-01T12%3A00%3A00Z/files) with some differences.

### New and changed gene names

Some genes have been renamed and one has been added. The new annotation is based on NCBI refseq annotations that were released in November 2022. The v2 dataset predates this refseq:

- The 4 genes in the inverted terminal repeat segment (ITR) on both ends of the genome (OPG001, OPG002, OPG003,OPG015) are now all included. The genes on the 3' end (~positions 190000-197000) now have an `_dup` appended to distinguish them.
- The gene previously named `NBT03_gp052` is now called `OPG073`
- The gene previously named `NBT03_gp174` is now called `OPG016`
- The gene previously named `NBT03_gp175` is now called `OPG015_dup`
- Gene `OPG166` has been added
