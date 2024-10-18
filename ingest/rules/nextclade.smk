
rule get_nextclade_dataset:
    output:
        temp("data/mpxv.zip"),
    params:
        dataset_name="MPXV",
    shell:
        r"""
        nextclade3 dataset get \
            --name {params.dataset_name:q} \
            --output-zip {output:q}
        """


rule run_nextclade:
    input:
        sequences="results/sequences.fasta",
        dataset="data/mpxv.zip",
    output:
        nextclade="results/nextclade.tsv",
        alignment="results/alignment.fasta",
        translations="results/translations.zip",
    params:
        # The lambda is used to deactivate automatic wildcard expansion.
        # https://github.com/snakemake/snakemake/blob/384d0066c512b0429719085f2cf886fdb97fd80a/snakemake/rules.py#L997-L1000
        translations=lambda w: "results/translations/{cds}.fasta",
    threads: 4
    shell:
        r"""
        nextclade3 run \
            {input.sequences:q} \
            --jobs {threads:q} \
            --retry-reverse-complement \
            --input-dataset {input.dataset:q} \
            --output-tsv {output.nextclade:q} \
            --output-fasta {output.alignment:q} \
            --output-translations {params.translations:q}

        zip -rj {output.translations:q} results/translations
        """


rule join_metadata_clades:
    input:
        nextclade="results/nextclade.tsv",
        metadata="data/subset_metadata.tsv",
        nextclade_field_map=config["nextclade"]["field_map"],
    output:
        metadata="results/metadata.tsv",
    params:
        id_field=config["curate"]["id_field"],
        nextclade_id_field=config["nextclade"]["id_field"],
    shell:
        r"""
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
