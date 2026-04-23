# MPXV Washington Focused Build

## Build Overview
- **Build Name**: MPXV Washington Focused Build
- **Pathogen/Strain**: MPXV/Monkeypox Virus/MPOX
- **Scope**: Whole genome, IIb clade
- **Purpose**: This repository contains the Nextstrain build for Washington State genomic surveillance of MPOX clade IIb. The purpose of this Nextstrain build is to monitor and analyze the genetic variations and spread of the MPOX virus within the Washington state region. By utilizing genomic sequencing data, this build helps track the lineage and evolution of the virus, facilitating early detection of any emerging variants. It ultimately aids public health officials in understanding and responding to the outbreak, ensuring that interventions are informed by the latest science.
- **Considerations**: The Washington-focused MPOX build is located within the phylogenetic folder of the Nextstrain MPOX build. This document will explain the components of the Global MPOX build and its dependencies that the Washington-focused build relies on, as well as the dependencies specific to the Washington-focused build, providing necessary context and clarity.  


- **Nextstrain Build/s Location/s**: https://nextstrain.org/groups/wadoh/mpox/wa

## Table of Contents
- [Pathogen Background](#pathogen-background)
- [Scientific Decisions](#scientific-decisions)
- [Getting Started](#getting-started)
  - [Data Sources & Inputs](#data-sources--inputs)
  - [Setup & Dependencies](#setup--dependencies)
    - [Installation](#installation)
    - [Clone the repository](#clone-the-repository)
- [Run the Build](#run-the-build-with-test-data)
- [Repository File Structure Overview](#repository-file-structure-overview)
- [Expected Outputs](#expected-outputs)
- [Customization for Local Adaptation](#customization-for-local-adaptation)
- [Contributing](#contributing)
- [License](#license)
- [Acknowledgements](#acknowledgements)

## Pathogen Background
As of 2025, there are three recognized clades of MPOX:
- Clade I: Present in the Congo Basin, causes up to 10% human mortality and is transmitted by rodents with little known human-to-human spread.
- Clade IIa: Present in West Africa, has a low mortality and is also zoonotic. 
- Clade IIb: Currently spreading globally via human transmission. 

The MPXV Nextstrain builds were created in response to the global outbreak of a novel clade IIb variant of MPXV which started in May 2022. 

https://pmc.ncbi.nlm.nih.gov/articles/PMC9974501/

## Scientific Decisions
Nextstrain builds are designed for specific purposes and not all types of builds for a particular pathogen will answer the same questions. The following are critical decisions that were made during the development of this build that should be kept in mind when analyzing the data and using this build.

- **Subsampling**: 
The subsampling strategy for the Washington focused build can be located here `mpox/phylogenetic/wa_mpxv/wa_config_hmpxv1.yaml`. The Washington-focused build filters out samples before 2017 and those with less than 100,000 base pairs. It then organizes the remaining samples by division year, with 500 sequences in each group, while excluding samples that are not from Washington state. In contrast, the Global build categorizes sequences by lineage, also with 500 sequences per group, and excludes samples from Washington and those not belonging to the IIb clade. The Washington-focused build subsequently combines these datasets for use in the final build.

  Washington Focused MPOX Build Subsampling Schema:
    group_by: "--group-by division year"
    sequences_per_group: "--sequences-per-group 500"
    other_filters: "--exclude-where division!=Washington"

  Global MPOX Build Subsampling Schema:
    group_by: "--group-by lineage"
    sequences_per_group: "--subsample-max-sequences 500"
    other_filters: "--exclude-where division=Washington outbreak!=hMPXV-1 clade!=IIb"

- **Root selection**: 
In the Global MPOX build, MK783032 and MK783030 are utilized to establish the root of the tree, with MK783032 serving as the root for the Washington MPOX build. These root sequences were selected due to problems encountered when the build attempted to determine its own root. MK783030 and MK783032 were identified as the most suitable samples for rooting the tree due to their more uniform appearance. The samples were likely selected based on their clock rates, possibly using BEAST to assess these rates. It was important for the samples to be distinct from the A.1 and B.1 clades as the B.1 clade likely exhibits a higher clock rate. Generally, Clade I viruses exhibit slower clock rates when compared to Clade II. Notably, MK783032 completely outgroups MK783030.

- **Reference selection**:
NCBI Reference Sequence: NC_063383.1
https://www.ncbi.nlm.nih.gov/nuccore/NC_063383.1/
Monkeypox virus, complete genome
LOCUS       NC_063383             197209 bp    DNA     linear   VRL 18-NOV-2022
The reference sequence is identical to MT903340.
The sequence was isolate from a human, within Rivers State, Nigeria and belongs to MPXV clade 2.

- **Inclusion/Exclusion**: 
Rooting sequences MK783032 and MK783030 are included in the include.txt file, located here `mpox\phylogenetic\wa_mpxv`. 

Samples that have been excluded from the Global MPXV build and subsequently the Washington focused build are located here, `mpox/phylogenetic/defaults/exclude_accessions.txt`. The excluded sequences consist of potential recombinants, duplicate sequences, those that do not align well, and highly divergent sequences, as well as overdiverged sequences or those with questionable clusters. Additional filtering criteria for exclusions include sequences from before 2017 and those that do not meet the minimum length requirement of 100,000 base pairs.

## Getting Started
Some high-level features and capabilities specific to this build include:

- **G -> A or C -> T Fraction:** The G → A or C → T fraction refers to the proportion of specific types of nucleotide mutations in a sequence of DNA or RNA. Specifically, it denotes the frequency or occurrence of mutations where guanine (G) changes to adenine (A) or cytosine (C) changes to thymine (T). 
  - These mutations are often studied in the context of genetic variation and evolution, as they can impact the function of genes and the characteristics of organisms over time. In genomic studies, understanding the G → A and C → T mutations can give insights into evolutionary processes, disease mechanisms, and the dynamics of epidemics. 
  - Mutations from G to A or C to T are thought to have played a role in the escaping drift loss, which contributed to the evolution of MPXV seen in the ongoing epidemic.

- **NGA/TCN Context of G -> A/C:** The term "NGA/TCN" refers to specific contexts in which nucleotide mutations occur, particularly in relation to the positions surrounding the nucleotides being mutated. 
  - NGA indicates that the guanine (G) is preceded by any nucleotide (N can be A, T, C, or G) and is followed by adenine (A).
  - TCN indicates that the nucleotide preceding the change (which is usually a guanine in this case) is cytosine (C) and is followed by any nucleotide (N can also be A, T, C, or G).
  - In the context of mutations from G to A or G to C, examining these specific nucleotide contexts can provide insights into how mutations arise and their potential effects on the function of genes. This approach is often used in evolutionary biology and genetics to understand patterns of mutations and their implications in various biological processes, including in the study of viruses like MPXV.
 

### Data Sources & Inputs
How Samples are Ingested from NCBI: `mpox/ingest/rules/fetch_from_ncbi.smk`
How Samples are Prepared for Sequencing: `mpox/phylogenetic/rules/prepare_sequences.smk`

This build relies on publicly available data sourced from data.nextstrain.org which originates from NCBI. This data is generously shared by labs around the world and deposited in NCBI genbank by the authors. Please contact these labs first if you plan to publish using their data. 

MPXV sequences and metadata can be downloaded in the `/ingest` folder using
`nextstrain build --cpus 1 ingest` or `nextstrain build --cpus 1 .` if running directly from the `/ingest` directory.

- **Expected Inputs**:
    - `mpox/phylogenetic/data/sequences.fasta.xz` is decrompressed for a final output of `mpox/phylogenetic/data/sequences.fasta` (containing viral genome sequences)
    - `mpox/phylogenetic/data/metadata.tsv.gz` is decompressed for a final output of `mpox/phylogenetic/data/metadata.tsv` (with relevant sample information)

### Setup & Dependencies
#### Installation
Ensure that you have [Nextstrain](https://docs.nextstrain.org/en/latest/install.html) installed.

To check that Nextstrain is installed:
```
nextstrain check-setup
```
#### Clone the repository:

```
git clone https://github.com/NW-PaGe/mpox
```

## Run the Build With Test Data
To test the pipeline with the provided example data located in `mpox/phylogenetic/example_data` make sure you are located in the build folder `mpox/phylogenetic/example_data` before running the build command:
If you want to use this test data, move it to "this" folder. 
```
nextstrain build .
```

When you run the build using `nextstrain build .`, Nextstrain uses Snakemake as the workflow manager to automate genomic analyses. The Snakefile in a Nextstrain build defines how raw input data (sequences and metadata) are processed step-by-step in an automated way. Nextstrain builds are powered by Augur (for phylogenetics) and Auspice (for visualization) and Snakemake is used to automate the execution of these steps using Augur and Auspice based on file dependencies.

## Run the Build
Ensure you are in the `mpox/phylogenetic` folder when running this build.
```
 nextstrain build --cpus 6 . --configfile wa_mpxv/wa_config_hmpxv1.yaml
```

## Repository File Structure Overview
This Nextstrain build follows the structure detailed in the [Pathogen Repo Guide](https://github.com/nextstrain/pathogen-repo-guide).

The file structure of the repository is as follows with `*`" folders denoting folders that are the build's expected outputs.
`mpox/phylogenetic`
```
.
├── README.md
├── Snakefile
├── .snakemake
├── auspice*
├── bin
├── build-configs
├── data
├── defaults
├── example_data
├── logs
├── profiles
├── results*
├── rules
└── scripts
├── wa_mpxv
```

- `Snakefile`: A Snakefile is a key component of the Snakemake workflow management system, serving as the blueprint for defining and organizing data processing workflows. It is a plain text file that contains a series of rules, each specifying how to transform input files into output files.  
- `.snakemake/`: This folder is created by the Snakemake workflow management system and contains important components that assist in the execution and management of data workflows. The contents help manage the workflow's execution efficiently, ensuring reproducibility and tracking changes throughout the data processing pipeline. 
- `bin/`: Inert files that outline Slack tokens that alert users on Slack of when the build is starting, if an error occurs, where it is being deployed and if it was successful. 
- `build-configs/`: Inert files and folders that have been included for automating Nextstrain builds.
- `data/`: Contains ingested compressed metadata and sequences folders that are then decompressed into their respected .tsv and .fasta files.
- <details><summary><code>defaults/</code>: Folder contains default parameters, such as:</summary>

  - <details><summary><code>clade-i/</code>: Folder containing the workflow for building a clade I focused build.</summary>

    - `auspice_config.JSON`: This file provides settings and parameters that define how the data is visualized and interacted with in Auspice. It allows users to customize the layout, filters, colors, and other visualization aspects according to their needs.
    - `config.YAML`: A configuration file used in applications and scripts to manage settings and parameters in an organized and structured manner.
    - `genome_annotation.gff3`: Gene annotation file for sequence-region KJ642613.1 1 196442.
    - `include.txt`: An include file that is blank.
    - `mask.bed`: A masked BED file is a file that contains intervals or ranges that correspond to low complexity regions within a genome or a FASTA. These intervals are used to mask the FASTA file, creating a new FASTA file with the masked ranges.
    - `reference.fasta`: The FASTA format is a text-based format used in bioinformatics and biochemistry to represent nucleotide sequences or amino acid (protein) sequences. This FASTA file is for the reference sequence "KJ642613.1 Monkeypox virus strain Congo_8, complete genome". 
    - `reference.gb`: GB files are a standard plain-text format used for storing biological sequence information, protein sequences and associated metadata. This GB file is for the reference sequence "KJ642613.1 Monkeypox virus strain Congo_8, complete genome".
    - `tree_mask.tsv`: A tree mask file is used to exclude specific parts of a phylogenetic tree from analysis. This can be useful for various reasons, such as removing poorly sequenced regions, excluding outliers, or focusing on specific clades or lineages. The tree mask file typically contains a list of nodes or branches that should be ignored during the tree-building process.
  - <details><summary><code>hmpxv1/</code>: Folder containing the workflow for building a clade IIb focused build.</summary>

    - `auspice_config.JSON`: This file provides settings and parameters that define how the data is visualized and interacted with in Auspice. It allows users to customize the layout, filters, colors, and other visualization aspects according to their needs.
    - `config.YAML`: A configuration file used in applications and scripts to manage settings and parameters in an organized and structured manner.
    - `include.txt`: An include file that contains sequences MK783030 and MK783032.

  - <details><summary><code>hmpxv1_big/</code>: Folder containing the workflow for building a B.1 lineage focused build.</summary>

    - `auspice_config.JSON`: This file provides settings and parameters that define how the data is visualized and interacted with in Auspice. It allows users to customize the layout, filters, colors, and other visualization aspects according to their needs.
    - `config.YAML`: A configuration file used in applications and scripts to manage settings and parameters in an organized and structured manner.
    - `include.txt`: An include file that contains sequence OP890401. 

  - <details><summary><code>mpxv/</code>: Folder containing the workflow for building an MPOX build across clades.</summary>  

    - `auspice_config.JSON`: This file provides settings and parameters that define how the data is visualized and interacted with in Auspice. It allows users to customize the layout, filters, colors, and other visualization aspects according to their needs.
    - `config.YAML`: A configuration file used in applications and scripts to manage settings and parameters in an organized and structured manner.
    - `include.txt`: An include file that is blank.</details>

    - `clades.tsv`: Nucleotide coordinates for reference sequence. 
    - `color_ordering.tsv`: Georgraphical settings for coloring.
    - `color_schemes.tsv`: Assigned colors for geographical settings.
    - `description`: Nextstrain's discussion of the global build and MPXV's evolution.
    - `exclude_accessions.txt`: Text document of samples that are excluded from the build, their accessions numbers and resonining behind their exclusion. 
    - `genemap.gff`: General Feature Format files are used in genome mapping, annotation, and comparative genomics. They provide a comprehensive overview of genomic features across DNA, RNA, and proteins. This file focuses on sequence-region NC_063383.1 1 197209. (For more information: https://www.biobam.com/differences-between-gtf-and-gff-files-in-genomic-data-analysis/)
    - `genome_annotation.gff3`: Gene annotation file for sequence-region NC_063383.1 1 197209.
    -`lat_longs.tsv`: Latitude and longitude for countries, regions, divisions and locations, derived from the geographical settings. 
    - `mask.bed`: A masked BED file is a file that contains intervals or ranges that correspond to low complexity regions within a genome or a FASTA. These intervals are used to mask the FASTA file, creating a new FASTA file with the masked ranges.
    - `mask_overview.bed`: A mask_overview.bed file is a BED file that contains intervals or ranges on a genome or other sequence. These intervals are used for various purposes, such as masking a FASTA file or creating a genome coverage plot.
    - `reference.fasta`: The FASTA format is a text-based format used in bioinformatics and biochemistry to represent nucleotide sequences or amino acid (protein) sequences. This FASTA file is for the reference sequence "NC_063383.1 Monkeypox virus, complete genome". 
    - `reference.gb`: GB files are a standard plain-text format used for storing biological sequence information, protein sequences and associated metadata. This GB file is for the reference sequence "NC_063383.1 Monkeypox virus, complete genome".
    - `tree_mask.tsv`: A tree mask file is used to exclude specific parts of a phylogenetic tree from analysis. This can be useful for various reasons, such as removing poorly sequenced regions, excluding outliers, or focusing on specific clades or lineages. The tree mask file typically contains a list of nodes or branches that should be ignored during the tree-building process.
    </details>
 </details>
</details>
</details>

- <details><summary><code>example_data/</code>: Folder containing example data for testing out a build run.</summary> 

  - `metadata.tsv`: This file contains descriptive information about the genomic sequences being analyzed. 
  - `sequences.fasta`: File that contains genomic sequence data for the genomic sequences being analyzed.</details>
  </details>
 </details>
</details>
</details>

- `logs/`: A folder created by Snakemake that is used to store log files that capture detailed information about the execution of the workflow. This folder is essential for monitoring, debugging, and optimizing workflow runs.  

- <details><summary><code>profiles/</code>: This folder is created by Snakemake and is vital for organizing and managing environment-specific configurations, enabling users to run workflows efficiently and consistently across different computing setups. It enhances the flexibility and usability of Snakemake, particularly in multi-user environments or when transitioning between local and distributed computing resources.</summary>

  - <details><summary><code>default/</code>:</summary>

    - `config.YAML`: Configuration options that enhance the flexibility, usability, and robustness of the Snakemake workflow by optimizing resource use, facilitating troubleshooting, and ensuring reliability in task execution.
</details>
 </details>
</details>
</details>

- <details><summary><code>rules/</code>: This folder is created by Snakemake and is a dedicated directory for rule definitions relating to your workflow.</summary>

  - `annotate_phylogeny.smk`: A Snakemake file that creates additional annotations for the phylogenetic tree. 
  - `construct_phylogeny.smk`: A Snakemake file that constructs the phylogenetic tree.
  - `export.smk`: A Snakemake file that collects the phylogenetic tree and annotations to
export a Nextstrain dataset. 
  - `prepare_sequences.smk`: A Snakemake file that prepares sequences for constructing the phylogenetic tree.
  </details>
 </details>
</details>
</details>

- <details><summary><code>scripts/</code>: This folder is contains Python scripts dedicated to the workflow.</summary>

  - `assign-clades-via-metadata.py`: Uses provided metadata to assign clades to internal nodes and those with missing metadata.
  - `assign-colors.py`: Assigns colors to a variety of parameters if not already outlined in config files. 
  - `clades_renaming.py`: Assigns clades and outbreak parameters to data notes. 
  - `combine_data_sources.py`: Python script implemented before the release of 'augur merge'. This script is no longer used due to 'augur merge' being used in it's place. 
  - `construct-recency-from-submission-date.py`: Script originally from https://github.com/nextstrain/ncov/blob/master/scripts/construct-recency-from-submission-date.py
  - `fix_tree.py`: Python script used for correcting and/or refining phylogenetic trees generated from genomic data.
  - `mutation_context.py`: Python script designed to analyze the genomic context of mutations within a set of sequences.
  - `remove_timeinfo.py`: Python script that returns the sample date in numeric form. 
  - `reverse_reversed_sequences.py`: Python script designed to manipulate DNA or RNA sequences by reversing them and then reversing the order of the nucleotides within each sequence.
  - `set_final_strain_name.py`: Python scripts that swaps out the strain names in the Auspice JSON with the final strain name.
  </details>
 </details>
</details>
</details>  

- <details><summary><code>wa_mpxv/</code>: Folder containing the workflow for building a Washington focused MPXV Clade IIb build.</summary>

  - `.git/`: This folder is created when you initialize a Git repository and contains all the necessary files and data that Git uses to manage version control for the project.
  - `README.md`: ReadMe file dedicated to this build. 
  - `wa_auspice_config_hmpxv1.JSON`: This file provides settings and parameters that define how the data is visualized and interacted with in Auspice. It allows users to customize the layout, filters, colors, and other visualization aspects according to their needs.
  - `wa_config_hmpxv1.YAML`: Configuration options that enhance the flexibility, usability, and robustness of the Snakemake workflow by optimizing resource use, facilitating troubleshooting, and ensuring reliability in task execution.
  - `wa_description.md`: Discussion of the build and acknowledgements.   
   </details>
 </details>
</details>
</details> 

## Expected Outputs
After successfully running the build there will be two output folders containing the build results.

- `auspice/` folder contains `mpox_wa.JSON` and `mpox_wa_root_sequence.JSON`
- <details><summary><code>results/</code> folder contains <code>hmpxv1_wa/</code> which contains the following files:</summary>

  - `aa_nuts.JSON`: Amino acid genome annotations.
  - `aligned.FASTA`: FASTA file of aligned sequences.
  - `branch_lengths.JSON`: Branch lengths of sequences. 
  - `clades.JSON`: Clade assignments to nodes, associated labels and clades. 
  - `clades_raw.JSON`: Original file designating branches with their nodes and clade assignments. 
  - `colors.tsv`: Assigned colors for geographical settings.
  - `filtered.FASTA`: FASTA file of sequences that have been through the filtering process. 
  - `global_filter.txt`: Log file of samples that were filtered out of the global build due to the filtering schema. 
  - `global_strain.txt`: List of samples from the global build after filtering has been applied.  
  - `good_filter.txt`: Log file of samples that were filtered out of the Washington focused build due to the filtering schema.
  - `good_metadata.tsv`: TSV file of samples that have been filtered due to the Washington focused schema. 
  - `good_sequences.FASTA`: FASTA file of samples that have been filtered due to the Washington focused schema. 
  - `masked.FASTA`: Nucleotide sequences of regions that are being masked/filtered out. Masking is often performed to focus on specific portions of the sequences that are of interest for analysis while ignoring areas that may introduce noise or aren't relevant, such as low-quality regions or highly conserved areas that aren't informative for phylogenetic analysis.
  - `masked_masked.FASTA`: Ncleotide sequences that have been doubly masked for specific regions. This means that any areas of the sequences that are deemed uninformative or problematic have been filtered out twice, ensuring that only high-quality, relevant regions remain for analysis.
  - `masked_masked-delim.FASTA`: Specialized version of the `masked_masked.fasta file`, where the sequences are not only masked but also formatted with delimiter characters to help with data processing and analysis. This file is used as the reading alignment file for IQ-Tree.  
  - `masked_masked-delim.iqtree`: IQ-Tree is used for inferring phylogenetic trees based on various models of sequence evolution. This file contains the results of IQ-Tree's alignments.  
  - `metadata.tsv`: This file contains descriptive information about the genomic sequences being analyzed in the global build. 
  - `mutation_context.JSON`: File that contains information about the context and characteristics of specific mutations observed in the sequences being analyzed. 
  - `nt_muts.JSON`: Data file that lists nucleotide mutations observed in the sequences being analyzed.
  - `raw_tree.JSON`: Initial tree structure generated from the sequence data depicting the evolutionary relationships among different samples or lineages of a pathogen. This file typically includes information about the branching patterns, node relationships, and branch lengths that represent the divergence times or genetic distances between the sequences analyzed. 
  - `raw_tree_root-sequence.JSON`: File contains the phylogenetic tree structure specifically with a designated root sequence that serves as a reference point for the evolutionary relationships among the pathogen samples. This file includes details about the tree's structure, such as branching patterns, node relationships, and branch lengths, all anchored to a particular root sequence that represents the common ancestor of the analyzed lineages. 
  - `recency.JSON`: File contains information about the timing and relative recency of sampled sequences used in phylogenetic analysis. This file typically includes details such as the dates of collection for the samples, which helps researchers assess how recently the sequences were obtained relative to each other.
  - `reversed.FASTA`: File contains nucleotide or amino acid sequences that have been reversed, typically representing the reverse complement of the original sequences. This type of file is often generated for specific analyses, such as when studying sequences from single-stranded viruses or for preparing input for software that requires sequences in reverse orientation. 
  - `tree.JSON`: File contains the finalized phylogenetic tree that represents the evolutionary relationships among different sequences or lineages of a pathogen. This file includes crucial information such as branching patterns, node relationships, and branch lengths, which indicate the genetic distances between the analyzed sequences.
  - `tree.nwk`: Newick format file that encodes the phylogenetic tree structure representing the evolutionary relationships among sequences of a pathogen. In this file, the tree is represented in a compact, text-based format that allows for easy storage and sharing of phylogenetic data. The Newick format includes information about the branching patterns and distances between different lineages, making it suitable for input into various software tools used for further analysis or visualization of evolutionary relationships. 
  - `tree_fixed.nwk`: Newick format file that contains a phylogenetic tree structure with specified branch lengths and topological constraints that have been adjusted or "fixed" for analysis. This file typically reflects a refined tree model, where certain nodes or relationships between sequences have been set to ensure that the tree meets specific criteria or hypotheses about the evolutionary relationships being studied. 
  - `tree_raw.nwk`: Initial phylogenetic tree representation of the sequences analyzed, formatted in Newick syntax. This file includes basic information about the evolutionary relationships among different samples or lineages, showing the branching patterns and distances between them as they were originally constructed. The "raw" designation signifies that this tree has not undergone any post-processing or adjustments, making it a straightforward depiction of the initial analysis. 
  - `tree_root-sequence.JSON`: Phylogenetic tree structure that explicitly includes a designated root sequence, which acts as a reference point for understanding the evolutionary relationships among different sequences of a pathogen. This file provides details about the branching patterns, node relationships, and branch lengths, all anchored to the specified root sequence that represents the common ancestor of the lineages being analyzed.
  - `wa_filter.txt`: Log file of samples that were filtered out of the Washington build due to the filtering schema.
  - `wa_strains.txt`: List of samples from the Washington build after filtering has been applied.
   </details>
 </details>
</details>
</details> 

## Customization for Local Adaptation
This build can be customized for use by other states, cities, counties, or countries. By utilizing the Washington focused folder model, `mpox/phylogenetic/wa_mpxv`, and altering specifications within the files to meet your needs, the Global MPXV Nextstrain build can be tailored to fit your requirements. The following steps are recommendations on how to easily alter the build to meet your adaptations:
- Create a folder for your build in `mpox/phlogenetic`. 
- Copy over the files in `mpox/phylogenetic/wa_mpxv` into your folder.
- In your folder, start to alter the following files to meet your needs. Use the dropdown arrows to expand on what areas of the file you may want to change:
  - <details><summary><code> wa_auspice_config_hmpxv1.json</code>: Alter how your build will look.</summary> 
    - <code>title</code>
    <br>
    - <code>maintainers</code>
    <br>
    - <code>build_url</code></details>
   
  - <details><summary><code> wa_config_hmpxv1.yaml</code>: Alter the filtering and sampling of your build.</summary>
      - <code>auspice_config</code>
      <br>
      - <code>description</code>
      <br>
      - <code>build_name</code>
      <br>
      - <code>auspice_name</code>
      <br>
      - <code>filter</code>
      <br>
      - <code>subsample</code>
      <br>

  - `wa_description.md`: Alter your builds description

## Contributing
For any questions please submit them to our [Discussions] https://github.com/orgs/NW-PaGe/discussions/categories/q-a page otherwise software issues and requests can be logged as a Git [Issue] https://github.com/NW-PaGe/wa_mpxv/issues.

## License
This project is licensed under a modified GPL-3.0 License.
You may use, modify, and distribute this work, but commercial use is strictly prohibited without prior written permission.

## Acknowledgements
This work is made possible by the open sharing of genetic data by research groups from all over the world. We gratefully acknowledge their contributions. Special thanks to Kristian Andersen, Josh Batson, David Blazes, Jesse Bloom, Peter Bogner, Anderson Brito, Matt Cotten, Ana Crisan, Tulio de Oliveira, Gytis Dudas, Vivien Dugan, Karl Erlandson, Nuno Faria, Jennifer Gardy, Nate Grubaugh, Becky Kondor, Dylan George, Ian Goodfellow, Betz Halloran, Christian Happi, Jeff Joy, Paul Kellam, Philippe Lemey, Nick Loman, Steph Lunn, Duncan MacCannell, Erick Matsen, Sebastian Maurer-Stroh, Placide Mbala, Danny Park, Oliver Pybus, Andrew Rambaut, Colin Russell, Pardis Sabeti, Katherine Siddle, Kristof Theys, Dave Wentworth, Shirlee Wohl and Cecile Viboud for comments, suggestions and data sharing.
