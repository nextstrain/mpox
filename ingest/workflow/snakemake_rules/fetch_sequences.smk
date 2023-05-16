"""
This part of the workflow handles fetching sequences from various sources.
Uses `config.sources` to determine which sequences to include in final output.

Currently only fetches sequences from GenBank, but other sources can be
defined in the config. If adding other sources, add a new rule upstream
of rule `fetch_all_sequences` to create the file `data/{source}.ndjson` or the
file must exist as a static file in the repo.

Produces final output as

    sequences_ndjson = "data/sequences.ndjson"

"""


rule fetch_from_genbank:
    output:
        genbank_ndjson="data/genbank.ndjson",
    retries: 5  # Requires snakemake 7.7.0 or later
    shell:
        """
        ./bin/fetch-from-genbank 10244 > {output.genbank_ndjson}
        """


rule fetch_from_gisaid:
    output:
        fasta="data/gisaid.fasta.zst",
        metadata="data/gisaid_metadata.tsv",
    params:
        folder="data",
    shell:
        """
        cp {params.folder}/sequences_till_2023-05-05.fasta.zst {output.fasta}
        cp {params.folder}/metadata_till_2023-05-05.tsv {output.metadata}
        """


rule parse_gisaid_fasta:
    input:
        fasta="data/gisaid.fasta.zst",
    output:
        parsed="data/gisaid_parsed.fasta.gz",
    shell:
        """
        seqkit seq \
            --id-regexp "^.*\|([^\|]+)\|" \
            -i \
            {input.fasta} \
        | gzip -2 > {output.parsed}
        """


rule gisaid_to_ndjson:
    input:
        fasta="data/gisaid_parsed.fasta.gz",
        metadata="data/gisaid_metadata.tsv",
    output:
        ndjson="data/gisaid.ndjson.zst",
    shell:
        """
        augur curate passthru \
            --fasta {input.fasta} \
            --metadata {input.metadata} \
            --seq-field accession \
            --seq-id-column "Accession ID" \
            --unmatched-reporting warn \
        | zstd -c > {output.ndjson}
        """


def _get_all_sources(wildcards):
    return [f"data/{source}.ndjson" for source in config["sources"]]


rule fetch_all_sequences:
    input:
        all_sources=_get_all_sources,
    output:
        sequences_ndjson="data/sequences.ndjson.zst",
    shell:
        """
        zstdcat {input.all_sources} \
        | zstd > {output.sequences_ndjson}
        """
