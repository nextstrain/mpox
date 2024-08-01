# Nextclade dataset for "Mpox virus (Clade I)"

| Key                    | Value                                                                                                                                                                                  |
| ---------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| authors                | [Cornelius Roemer](https://neherlab.org), [Richard Neher](https://neherlab.org), [Nextstrain](https://nextstrain.org)                                                                  |
| data source            | Genbank                                                                                                                                                                                |
| workflow               | [github.com/nextstrain/mpox/nextclade](https://github.com/nextstrain/mpox/nextclade)                                                                                                   |
| nextclade dataset path | nextstrain/mpox/clade-i                                                                                                                                                                |
| reference              | [DQ011155.1](https://www.ncbi.nlm.nih.gov/nuccore/DQ011155.1), isolate `Zaire_1979-005`, an early complete clade I sequence                                                            |
| annotation             | based on [DQ011155.1](https://www.ncbi.nlm.nih.gov/nuccore/DQ011155.1), but with genes called by modern names (OPGXXX)                                                                 |
| clade definitions      | [github.com/mpxv-lineages/lineage-designation](https://github.com/mpxv-lineages/lineage-designation)                                                                                   |
| related datasets       | Mpox virus (All clades): `nextstrain/mpox/all-clades`<br>Mpox virus (clade IIb) `nextstrain/mpox/clade-iib`<br>Mpox virus (Lineage B.1 within clade IIb) `nextstrain/mpox/lineage-b.1` |

## Scope of this dataset

This dataset is for Mpox viruses of clade I (Ia and Ib). A broader dataset for all clades I, IIa and IIb is available under `nextstrain/mpox/all-clades`.

## Reference sequence and reference tree

The reference used in this dataset is [DQ011155.1](https://www.ncbi.nlm.nih.gov/nuccore/DQ011155.1), an early complete clade I sequence (Isolate `Zaire_1979-005`).

This is in contrast to the reference used in the other Nextclade mpox datasets, which use a clade IIb reference sequence.

The reference tree consists of all good quality clade I sequences available within Genbank at the time of dataset creation (with identical sequences deduplicated to 1), as well as 3 outgroup genomes (a reconstructed ancestor of all clades, and one sequence for each of clade IIa and clade IIb).

## Further reading

Read more about Nextclade datasets in the Nextclade documentation: https://docs.nextstrain.org/projects/nextclade/en/stable/user/datasets.html
