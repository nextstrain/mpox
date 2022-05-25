
rule prepare:
    output:
        sequences = build_dir + "/{build_name}/sequences.fasta",
        metadata = build_dir + "/{build_name}/metadata.tsv"
    shell:
        """
        cat data/*fasta > {output.sequences}
        cat data/*tsv > {output.metadata}
        """

rule download_via_lapis:
    output:
        sequences = "data/sequences_lapis.fasta",
        metadata = "data/metadata_lapis.tsv"
    shell:
        """
        curl https://mpox-lapis.gen-spectrum.org/v1/sample/fasta --output {output.sequences}
        curl https://mpox-lapis.gen-spectrum.org/v1/sample/details?dataFormat=csv | \
            tr -d "\r" |
            sed -E 's/("([^"]*)")?,/\\2\\t/g' > {output.metadata}
        """
