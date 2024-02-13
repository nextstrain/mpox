rule download_sequences_via_lapis:
    output:
        sequences="data/sequences.fasta",
    shell:
        """
        curl https://mpox-lapis.genspectrum.org/v1/sample/fasta --output {output.sequences}
        """


rule download_metadata_via_lapis:
    output:
        metadata="data/metadata.tsv",
    shell:
        """
        curl https://mpox-lapis.genspectrum.org/v1/sample/details?dataFormat=csv | \
            tr -d "\r" |
            sed -E 's/("([^"]*)")?,/\\2\\t/g' > {output.metadata}
        """

# Override the default download/decompress rules to download data from LAPIS
ruleorder: download_sequences_via_lapis > decompress
ruleorder: download_metadata_via_lapis > decompress
