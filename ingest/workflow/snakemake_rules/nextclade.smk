
rule nextclade_dataset:
    output:
        temp("mpxv.zip")
    shell:
        """
        nextclade dataset get --name MPXV --output-zip {output}
        """

rule nextclade:
    input:
        sequences = "data/sequences.fasta",
        dataset = "mpxv.zip"
    output:
        "data/nextclade.tsv"
    threads: 4
    shell:
        """
        nextclade run -D {input.dataset} -j {threads} --output-tsv {output}  {input.sequences}  --retry-reverse-complement
        """

rule join_metadata_clades:
    input:
        nextclade = "data/nextclade.tsv",
        metadata = "data/metadata_raw.tsv"
    output:
        "data/metadata.tsv"
    params:
        id_field = config['transform']['id_field']
    shell:
        """
        python3 bin/join-metadata-and-clades.py \
                --id-field {params.id_field} \
                --metadata {input.metadata} \
                --nextclade {input.nextclade} \
                -o {output}
        """
