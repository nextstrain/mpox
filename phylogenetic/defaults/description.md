We gratefully acknowledge the authors, originating and submitting laboratories of the genetic sequences and metadata for sharing their work via INSDC or Pathoplexus. Please note that data from Pathoplexus comes with specific data use terms that need to be abided by. If data are shared under RESTRICTED terms, you can not use these data in publications without collaborating with the group that generated the data, please consult the [Data Use Terms of Pathoplexus](https://pathoplexus.org/about/terms-of-use/restricted-data) for details. Even if data are shared without restrictions, that does not mean there should be free license to publish on this data. Data generators should be cited where possible and collaborations should be sought in some circumstances. Please try to avoid scooping someone else's work. Reach out if uncertain.

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
We source sequence data and metadata from [Pathoplexus](https://pathoplexus.org) which ingests data from INSDC and provides data from INSDC together with data that were submitted directly to Pathoplexus. See our [ingest configuration file](https://github.com/nextstrain/mpox/blob/-/ingest/defaults/config.yaml).
Curated sequences and metadata are available as flat files at the links below.
The data in the files provided below is the subset of data from Pathoplexus under the OPEN [data use terms](https://pathoplexus.org/about/terms-of-use/data-use-terms). In the metadata files below, each sequence contains a field specifying the data use terms of this sequence and a link to the data use terms.

Curated sequences and metadata are available as flat files at:
- [data.nextstrain.org/files/workflows/mpox/sequences.fasta.zst](https://data.nextstrain.org/files/workflows/mpox/sequences.fasta.zst)
- [data.nextstrain.org/files/workflows/mpox/metadata.tsv.zst](https://data.nextstrain.org/files/workflows/mpox/metadata.tsv.zst)

Pairwise alignments with [Nextclade](https://clades.nextstrain.org/) against the [reference sequence MPXV-M5312_HM12_Rivers](https://www.ncbi.nlm.nih.gov/nuccore/NC_063383), Nextclade analysis results, and translated ORFs are available at
- [data.nextstrain.org/files/workflows/mpox/alignment.fasta.zst](https://data.nextstrain.org/files/workflows/mpox/alignment.fasta.zst)
- [data.nextstrain.org/files/workflows/mpox/nextclade.tsv.zst](https://data.nextstrain.org/files/workflows/mpox/nextclade.tsv.zst)
- [data.nextstrain.org/files/workflows/mpox/translations.zip](https://data.nextstrain.org/files/workflows/mpox/translations.zip)

These files are updated regularly as new sequences become available. For reproducibility, please download and save your own copies of the data files you use in your analyses, as the file contents at these URLs will change over time.

Archived data files from before the Pathoplexus transition (published 05 November 2025) are available at [data.nextstrain.org/files/workflows/mpox/archive/20251105/](https://data.nextstrain.org/files/workflows/mpox/archive/20251105/)

If you are interested in the RESTRICTED USE data, we ask you to obtain those directly from Pathoplexus.

---

Screenshots may be used under a [CC-BY-4.0 license](https://creativecommons.org/licenses/by/4.0/) and attribution to nextstrain.org must be provided.
