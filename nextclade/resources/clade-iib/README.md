# Nextclade dataset for "Mpox virus (Clade IIb)"

| property            | value                                                                                                                                                   |
| ------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| authors             | [Cornelius Roemer](https://neherlab.org), [Richard Neher](https://neherlab.org), [Nextstrain](https://nextstrain.org)                                   |
| data source         | Genbank                                                                                                                                                 |
| workflow            | [github.com/nextstrain/mpox/nextclade](https://github.com/nextstrain/mpox/nextclade)                                                                    |
| issue tracker       | github.com/nextstrain/mpox/issues                                                                                                                       |
| nextclade data path | nextstrain/mpox/lineage-iib/rivers
| title               | Mpox virus (Clade IIb)                                                                                                                                 |
| taxon               | [NCBI:txid10244](https://www.ncbi.nlm.nih.gov/Taxonomy/Browser/wwwtax.cgi?mode=Info&id=10244)                                                           |
| annotation          | [NC_063383.1](https://www.ncbi.nlm.nih.gov/nuccore/NC_063383)                                                                                           |
| clade definitions   | github.com/mpxv-lineages/lineage-designation                                                                                                            |
| references          | [Urgent need for a non-discriminatory and non-stigmatizing nomenclature for monkeypox virus](https://doi.org/10.1371/journal.pbio.3001769)              |
| related datasets    | Mpox virus (All clades): `nextstrain/mpox/all-clades/rivers-with-ancestral-snps`<br> Mpox virus (Lineage B.1) `nextstrain/mpox/lineage-iib/rivers-with-usa-2022-ma001-snps` |

This Nextclade dataset is intended for use with Mpox viruses that fall within clade IIb. If your sequences are all or mostly descended from the 2022 outbreak lineage B.1 you may want to use the even more specific dataset for that lineage instead: `nextstrain/mpox/lineage-iib/rivers-with-usa-2022-ma001-snps`. If you want to analyze broader Mpox diversity, i.e. also clade I or clade II, use the more general dataset `nextstrain/mpox/all-clades/rivers-with-ancestral-snps`. The more specific a dataset, the faster it will run and the less overwhelming the results will be (fewer SNPs), more relevant reference sequences will be included for tree placement. Sequences that are beyond the scope of a dataset will still be included in the results but will get assigned to the fallback clade `outgroup`.

This dataset supports calling all designated lineages within the clade IIb (A, A.1, A.2, A.3, A.1.1, B.1, etc.). The clade and lineage nomenclature used is outlined in [Urgent need for a non-discriminatory and non-stigmatizing nomenclature for monkeypox virus](https://doi.org/10.1371/journal.pbio.3001769). The ground truth for lineage definitions is available at [github.com/mpxv-lineages/lineage-designation](https://github.com/nextstrain/mpox/nextclade). This dataset will be updated as new lineages are designated.

The reference used in this dataset is based on mpox virus NCBI refseq NC_063383.1 (`MPXV-M5312_HM12_Rivers`).

The sequences used for construction of the reference tree are obtained from the `/ingest` workflow of the `nextstrain/monkeypox` repo. This workflow downloads and processes sequences from NCBI/Genbank. Sequences are sampled from all clades and all lineages over time and countries for a representative sample of the diversity of Mpox virus. The sequences are then aligned with Nextclade and a maximum likelihood tree is inferred with IQ-TREE. The tree is then rooted with the reconstructed ancestral sequence and ancestral states are inferred with TreeTime.

## Further reading

Read more about Nextclade datasets in Nextclade documentation: https://docs.nextstrain.org/projects/nextclade/en/stable/user/datasets.html
