# Nextclade dataset for "Mpox virus (All Clades)"

| property            | value                                                                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| authors             | [Cornelius Roemer](https://neherlab.org), [Richard Neher](https://neherlab.org), [Nextstrain](https://nextstrain.org)                                   |
| data source         | Genbank                                                                                                                                                 |
| workflow            | [github.com/nextstrain/mpox/nextclade](https://github.com/nextstrain/mpox/nextclade)                                                                    |
| issues              | github.com/nextstrain/mpox/issues                                                                                                                       |
| nextclade data path | nextstrain/mpox/all-clades/rivers-with-ancestral-snps                                                                                                   |
| title               | Mpox virus (All Clades)                                                                                                                                 |
| taxon               | [NCBI:txid10244](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=10244)                                                           |
| annotation          | [NC_063383.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_063383)                                                                                           |
| clade definitions   | github.com/mpxv-lineages/lineage-designation                                                                                                            |
| references          | [Urgent need for a non-discriminatory and non-stigmatizing nomenclature for monkeypox virus](https://doi.org/10.1371/journal.pbio.3001769)              |
| related datasets    | Mpox virus (Clade IIb): `nextstrain/mpox/lineage-iib/rivers`<br> Mpox virus (Lineage B.1) `nextstrain/mpox/lineage-iib/rivers-with-usa-2022-ma001-snps` |

This Nextclade dataset is intended for use with Mpox viruses of all clades (I, IIa and IIb). If your sequences are all from clade IIb, you may want to use the more specific dataset for that clade instead: `nextstrain/mpox/lineage-iib/rivers`. If your sequences are not only all from clade IIb but also specifically from the 2022 outbreak lineage B.1 (and sublineages), you may want to use the even more specific dataset for that lineage instead: `nextstrain/mpox/lineage-iib/rivers-with-usa-2022-ma001-snps`. The more specific a dataset, the faster it will run and the less overwhelming the results will be (fewer SNPs), more relevant reference sequences will be included for tree placement.

The dataset supports calling broad Mpox virus clades (I, IIa, IIb) and for sequences within clade IIb the more focused lineages (A, A.1, A.2, A.3, A.1.1, B.1, etc.). The clade and lineage nomenclature used is outlined in [Urgent need for a non-discriminatory and non-stigmatizing nomenclature for monkeypox virus](https://doi.org/10.1371/journal.pbio.3001769). The ground truth for lineage definitions is available at [github.com/mpxv-lineages/lineage-designation](https://github.com/nextstrain/mpox/nextclade). This dataset will be updated as new lineages are designated.

The reference used in this dataset is based on mpox virus NCBI refseq NC_063383.1 (`MPXV-M5312_HM12_Rivers`) but with SNPs (but not indels) that were inferred to be in the ancestor of clades I and II with a suitable orthopox outgroup. Due to this construction, the nucleotide and amino acid coordinates are hence identical to NC_063383.1.

The sequences used for construction of the reference tree are obtained from the `/ingest` workflow of the `nextstrain/monkeypox` repo. This workflow downloads and processes sequences from NCBI/Genbank. Sequences are sampled from all clades and all lineages over time and countries for a representative sample of the diversity of Mpox virus. The sequences are then aligned with Nextclade and a maximum likelihood tree is inferred with IQ-TREE. The tree is then rooted with the reconstructed ancestral sequence and ancestral states are inferred with TreeTime.

## Further reading

Read more about Nextclade datasets in Nextclade documentation: https://docs.nextstrain.org/projects/nextclade/en/stable/user/datasets.html
