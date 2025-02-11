We gratefully acknowledge the authors, originating and submitting laboratories of the genetic sequences and metadata for sharing their work. Please note that although data generators have generously shared data in an open fashion, that does not mean there should be free license to publish on this data. Data generators should be cited where possible and collaborations should be sought in some circumstances. Please try to avoid scooping someone else's work. Reach out if uncertain.

This build was specifically made to show proposed lineage designations and is not intended for general use beyond this purpose. It contains restricted-use data from 2 data sources: GISAID and Pathoplexus and should not be redistributed.

#### Analysis

Our bioinformatic processing workflow can be found at [github.com/nextstrain/mpox](https://github.com/nextstrain/mpox) and includes:
- sequence alignment by [Nextclade](https://docs.nextstrain.org/projects/nextclade/en/stable/user/nextclade-cli/index.html)
- masking several regions of the genome, including the first 1350 and last 6422 base pairs and multiple repetitive regions of variable length
- phylogenetic reconstruction using [IQTREE-2](http://www.iqtree.org/)
- ancestral state reconstruction and temporal inference using [TreeTime](https://github.com/neherlab/treetime)

#### Underlying data
- Restricted-use data from Pathoplexus: https://pathoplexus.org/mpox/search?dataUseTerms=RESTRICTED
- Mpox clade Ib sequences from GISAID (including sequences shared originally via INSDC)

---

Screenshots may be used under a [CC-BY-4.0 license](https://creativecommons.org/licenses/by/4.0/) and attribution to nextstrain.org must be provided.
