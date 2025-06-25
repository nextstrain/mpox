We gratefully acknowledge the authors, originating and submitting laboratories of the genetic sequences and metadata for sharing their work. Please note that although data generators have generously shared data in an open fashion, that does not mean there should be free license to publish on this data. Data generators should be cited where possible and collaborations should be sought in some circumstances. Please try to avoid scooping someone else's work. Reach out if uncertain.

We maintain four views of MPXV evolution:

The first is [`mpox/lineage-B.1`](https://nextstrain.org/mpox/lineage-B.1), which focuses on lineage B.1 of the global outbreak that started in 2022 and includes as many sequences as possible. Here, we conduct a molecular clock analysis in which evolutionary rate is estimated from the data (with a resulting estimate of ~6 &times; 10<sup>-5</sup> subs per site per year).

The second is [`mpox/clade-IIb`](https://nextstrain.org/mpox/clade-IIb), which focuses on recent viruses transmitting from human-to-human and includes viruses belonging to clade IIb. All good quality sequences that are not lineage B.1 are included, while lineage B.1 sequences is heavily subsampled to allow non-B.1 diversity to be studied.Here, we also conduct a molecular clock analysis in which evolutionary rate is estimated from the data (with a resulting estimate of ~6 &times; 10<sup>-5</sup> subs per site per year).

The third is [`mpox/all-clades`](https://nextstrain.org/mpox/all-clades), which focuses on broader viral diversity and includes viruses from the animal reservoir and previous human outbreaks, encompassing clades I, IIa and IIb as described in [Happi et al](https://doi.org/10.1371/journal.pbio.3001769) and endorsed by a [WHO convened consultation](https://worldhealthorganization.cmail20.com/t/ViewEmail/d/422BD62D623B6A3D2540EF23F30FEDED/F75AF81C90108C72B4B1B1F623478121?alternativeLink=False).

The fourth is [`mpox/clade-I`](https://nextstrain.org/mpox/clade-I), which focuses on clade I sequences and includes as many sequences as possible.

#### Analysis
Our bioinformatic processing workflow can be found at [github.com/nextstrain/mpox](https://github.com/nextstrain/mpox) and includes:
- sequence alignment by [Nextclade](https://docs.nextstrain.org/projects/nextclade/en/stable/user/nextclade-cli/index.html)
- masking several regions of the genome, including the first 1350 and last 6422 base pairs and multiple repetitive regions of variable length
- phylogenetic reconstruction using [IQTREE-2](http://www.iqtree.org/)
- ancestral state reconstruction and temporal inference using [TreeTime](https://github.com/neherlab/treetime)
- clade assignment via [clade definitions defined here](https://github.com/nextstrain/mpox/blob/-/phylogenetic/defaults/clades.tsv), to label broader MPXV clades I, IIa and IIb and to label hMPXV1 lineages A, A.1, A.1.1, etc. (defined by [mpxv-lineages/lineage-designation](https://github.com/mpxv-lineages/lineage-designation))

#### Underlying data
We curate sequence data and metadata from the [NCBI Datasets command line tools](https://www.ncbi.nlm.nih.gov/datasets/docs/v2/download-and-install/),
using an NCBI Taxonomy ID defined in [ingest/defaults/config.yaml](https://github.com/nextstrain/mpox/blob/-/ingest/defaults/config.yaml), as starting point for these analyses.

Curated sequences and metadata are available as flat files at:
- [data.nextstrain.org/files/workflows/mpox/sequences.fasta.zst](https://data.nextstrain.org/files/workflows/mpox/sequences.fasta.zst)
- [data.nextstrain.org/files/workflows/mpox/metadata.tsv.zst](https://data.nextstrain.org/files/workflows/mpox/metadata.tsv.zst)

Pairwise alignments with [Nextclade](https://clades.nextstrain.org/) against the [reference sequence MPXV-M5312_HM12_Rivers](https://www.ncbi.nlm.nih.gov/nuccore/NC_063383), Nextclade analysis results, and translated ORFs are available at
- [data.nextstrain.org/files/workflows/mpox/alignment.fasta.zst](https://data.nextstrain.org/files/workflows/mpox/alignment.fasta.zst)
- [data.nextstrain.org/files/workflows/mpox/nextclade.tsv.zst](https://data.nextstrain.org/files/workflows/mpox/nextclade.tsv.zst)
- [data.nextstrain.org/files/workflows/mpox/translations.zip](https://data.nextstrain.org/files/workflows/mpox/translations.zip)

---

Screenshots may be used under a [CC-BY-4.0 license](https://creativecommons.org/licenses/by/4.0/) and attribution to nextstrain.org must be provided.
