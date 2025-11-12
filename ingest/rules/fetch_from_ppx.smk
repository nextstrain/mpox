"""
This part of the workflow handles fetching sequences and metadata from Pathoplexus.

REQUIRED INPUTS:

    None

OUTPUTS:

    ndjson = results/ppx.ndjson.zst
    flat_ndjson = results/ppx_flat.ndjson.zst

"""


rule fetch_ppx_data:
    output:
        ppx_ndjson="results/ppx.ndjson.zst",
        ppx_headers="results/ppx.headers.txt",
    benchmark:
        "benchmarks/fetch_ppx_data.txt"
    params:
        ppx_api_url="https://backend.pathoplexus.org/mpox/get-released-data?compression=zstd",
    log:
        "logs/fetch_ppx_data.txt",
    shell:
        r"""
        exec &> >(tee {log:q})


        echo "Downloading: {params.ppx_api_url:q}"
        curl {params.ppx_api_url:q} -fS -D {output.ppx_headers:q} -o {output.ppx_ndjson:q}

        expected="$(grep -i '^x-total-records:' {output.ppx_headers:q} | awk '{{print $2}}' | tr -d '[:space:]' || true)"

        echo "Counting records..."
        actual="$(zstd -d -c {output.ppx_ndjson:q} | jq -n 'reduce inputs as $item (0; . + 1)')"

        echo "Actual records:   $actual"
        echo "Expected records: $expected"
        if [[ "$actual" -ne "$expected" ]]; then
            echo "Mismatch: expected $expected, got $actual" >&2
            exit 2
        fi

        echo "OK: record counts match."
        """


rule flatten_ppx_data:
    input:
        ppx_ndjson="results/ppx.ndjson.zst",
    output:
        ppx_flat="results/ppx_flat.ndjson.zst",
    benchmark:
        "benchmarks/flatten_ppx_data.txt"
    log:
        "logs/flatten_ppx_data.txt",
    shell:
        r"""
        exec &> >(tee {log:q})

        echo "Flattening Pathoplexus data and removing all-null fields..."
        zstdcat {input.ppx_ndjson:q} | jq -c '
          select(.metadata.versionStatus == "LATEST_VERSION")
          | (.metadata
              | del(
                .bodyProduct,
                .comment,
                .diagnosticMeasurementMethod,
                .diagnosticMeasurementUnit,
                .diagnosticMeasurementValue,
                .diagnosticTargetGeneName,
                .diagnosticTargetPresence,
                .environmentalMaterial,
                .experimentalSpecimenRoleType,
                .exposureDetails,
                .exposureEvent,
                .exposureSetting,
                .foodProduct,
                .foodProductProperties,
                .geoLocLatitude,
                .geoLocLongitude,
                .gisaidIsolateId,
                .hostAgeBin,
                .hostHealthOutcome,
                .hostRole,
                .hostVaccinationStatus,
                .ncbiSubmitterCountry,
                .passageMethod,
                .presamplingActivity,
                .purposeOfSampling,
                .qualityControlDetails,
                .qualityControlDetermination,
                .qualityControlIssues,
                .qualityControlMethodName,
                .qualityControlMethodVersion,
                .rawSequenceDataProcessingMethod,
                .signsAndSymptoms,
                .specimenProcessing,
                .specimenProcessingDetails,
                .travelHistory,
                .versionComment
              )
            )
          + {{sequence: .unalignedNucleotideSequences.main}}
        ' | zstd -c > {output.ppx_flat:q}
        """
