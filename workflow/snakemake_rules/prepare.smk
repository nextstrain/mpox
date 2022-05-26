
rule concatenate_data:
    output:
        sequences = "data/sequences.fasta",
        metadata =  "data/metadata.tsv"
    shell:
        """
        cat example_data/*fasta > {output.sequences}
        cat example_data/*tsv > {output.metadata}
        """

