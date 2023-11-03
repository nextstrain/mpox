
rule nextclade_dataset:
    output:
        temp("mpxv.zip"),
    shell:
        """
        nextclade dataset get --name MPXV --output-zip {output}
        """


rule nextclade_dataset_hMPXV:
    output:
        temp("hmpxv.zip"),
    shell:
        """
        nextclade dataset get --name hMPXV --output-zip {output}
        """


rule align:
    input:
        sequences="results/sequences.fasta",
        dataset="hmpxv.zip",
    output:
        alignment="data/alignment.fasta",
        insertions="data/insertions.csv",
        translations="data/translations.zip",
    params:
        # The lambda is used to deactivate automatic wildcard expansion.
        # https://github.com/snakemake/snakemake/blob/384d0066c512b0429719085f2cf886fdb97fd80a/snakemake/rules.py#L997-L1000
        translations=lambda w: "data/translations/{gene}.fasta",
    threads: 4
    shell:
        """
        nextclade run -D {input.dataset} -j {threads}   --retry-reverse-complement \
                  --output-fasta {output.alignment}  --output-translations {params.translations} \
                  --output-insertions {output.insertions} {input.sequences}
        zip -rj {output.translations} data/translations
        """


rule nextclade:
    input:
        sequences="results/sequences.fasta",
        dataset="mpxv.zip",
    output:
        "data/nextclade.tsv",
    threads: 4
    shell:
        """
        nextclade run -D {input.dataset} -j {threads} --output-tsv {output}  {input.sequences}  --retry-reverse-complement
        """


rule join_metadata_clades:
    input:
        nextclade="data/nextclade.tsv",
        metadata="data/metadata_raw.tsv",
        nextclade_field_map=config["nextclade"]["field_map"],
    output:
        metadata="results/metadata.tsv",
    params:
        id_field=config["transform"]["id_field"],
        nextclade_id_field=config["nextclade"]["id_field"],
    shell:
        """
        export SUBSET_FIELDS=`awk 'NR>1 {{print $1}}' {input.nextclade_field_map} | tr '\n' ',' | sed 's/,$//g'`

        csvtk -tl cut -f $SUBSET_FIELDS \
            {input.nextclade} \
        | csvtk -tl rename2 \
            -F \
            -f '*' \
            -p '(.+)' \
            -r '{{kv}}' \
            -k {input.nextclade_field_map} \
        | tsv-join -H \
            --filter-file - \
            --key-fields {params.nextclade_id_field} \
            --data-fields {params.id_field} \
            --append-fields '*' \
            --write-all ? \
            {input.metadata} \
        | tsv-select -H --exclude {params.nextclade_id_field} \
            > {output.metadata}
        """
