
rule prepare:
    output:
        sequences = build_dir + "/{build_name}/sequences.fasta",
        metadata = build_dir + "/{build_name}/metadata.tsv"
    shell:
        """
        cat data/*fasta > {output.sequences}
        cat data/*tsv > {output.metadata}
        """