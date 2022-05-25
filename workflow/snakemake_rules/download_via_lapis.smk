rule download_via_lapis:
    output:
        sequences = "data/sequences.fasta",
        metadata = "data/metadata.tsv"
    shell:
        """
        curl https://mpox-lapis.gen-spectrum.org/v1/sample/fasta --output {output.sequences}
        curl https://mpox-lapis.gen-spectrum.org/v1/sample/details?dataFormat=csv | \
            tr -d "\r" |
            sed -E 's/("([^"]*)")?,/\\2\\t/g' > {output.metadata}
        """
