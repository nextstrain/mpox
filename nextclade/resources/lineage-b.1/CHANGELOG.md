## Unreleased

Initial release of this dataset. This dataset is similar to the v2 dataset [`hMPXV_B.1/pseudo_ON563414`](https://github.com/nextstrain/nextclade_data/tree/2023-08-17--15-51-24--UTC/data/datasets/hMPXV_B.1/references/pseudo_ON563414/versions/2023-08-01T12%3A00%3A00Z/files) with some differences.

### New and changed gene names

Some genes have been renamed and one has been added. The new annotation is based on NCBI refseq annotations that were released in November 2022. The v2 dataset predates this refseq:

- The 4 genes in the inverted terminal repeat segment (ITR) on both ends of the genome (OPG001, OPG002, OPG003,OPG015) are now all included. The genes on the 3' end (~positions 190000-197000) now have an `_dup` appended to distinguish them.
- The gene previously named `NBT03_gp052` is now called `OPG073`
- The gene previously named `NBT03_gp174` is now called `OPG016`
- The gene previously named `NBT03_gp175` is now called `OPG015_dup`
- Gene `OPG166` has been added
