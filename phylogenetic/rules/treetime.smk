"""Resolve the TreeTime executable selected by the workflow configuration."""

import hashlib
import os
from pathlib import Path


treetime_environment_variables = {
    "TREETIME_NIGHTLY": "nightly",
    "TREETIME_PATH": "path",
    "TREETIME_URL": "url",
}
treetime_environment = {
    selector: os.environ[name]
    for name, selector in treetime_environment_variables.items()
    if name in os.environ
}
if len(treetime_environment) > 1:
    names = ", ".join(
        name for name in treetime_environment_variables if name in os.environ
    )
    raise ValueError(f"set exactly one TreeTime environment variable; found {names}")

treetime_config = treetime_environment or config.get("treetime")
if not isinstance(treetime_config, dict):
    raise TypeError("config['treetime'] must be a mapping")

treetime_config_keys = set(treetime_config)
if treetime_config_keys == {"path"}:
    treetime_path = treetime_config["path"]
    if not isinstance(treetime_path, str) or not treetime_path:
        raise ValueError("config['treetime']['path'] must be a non-empty string")
    TREETIME_BINARY = str(Path(treetime_path).expanduser().resolve())
    treetime_path_hash = hashlib.sha256(TREETIME_BINARY.encode()).hexdigest()
    TREETIME_SOURCE = f".snakemake/treetime/path/{treetime_path_hash}/source.txt"

    rule record_treetime_local:
        output:
            source=temp(TREETIME_SOURCE),
        params:
            path=TREETIME_BINARY,
        shell:
            r"""
            mkdir -p "$(dirname {output.source:q})"
            printf 'TreeTime local path: %s\n' {params.path:q} > {output.source:q}
            """
elif treetime_config_keys == {"nightly"}:
    treetime_nightly = treetime_config["nightly"]
    if not isinstance(treetime_nightly, str) or not treetime_nightly:
        raise ValueError(
            "config['treetime']['nightly'] must be 'latest' or a release tag"
        )

    treetime_extension = ".exe" if os.name == "nt" else ""
    TREETIME_BINARY = (
        f".snakemake/treetime/{treetime_nightly}/treetime{treetime_extension}"
    )
    TREETIME_SOURCE = f".snakemake/treetime/{treetime_nightly}/source.txt"

    rule fetch_treetime_nightly:
        output:
            binary=temp(TREETIME_BINARY),
            source=temp(TREETIME_SOURCE),
        params:
            release=treetime_nightly,
        shell:
            r"""
            python scripts/fetch-treetime.py \
                --release {params.release:q} \
                --output {output.binary:q} \
                --source-output {output.source:q}
            """
elif treetime_config_keys == {"url"}:
    treetime_url = treetime_config["url"]
    if not isinstance(treetime_url, str) or not treetime_url:
        raise ValueError("config['treetime']['url'] must be a non-empty string")

    treetime_url_hash = hashlib.sha256(treetime_url.encode()).hexdigest()
    treetime_extension = ".exe" if os.name == "nt" else ""
    TREETIME_BINARY = (
        f".snakemake/treetime/url/{treetime_url_hash}/treetime{treetime_extension}"
    )
    TREETIME_SOURCE = (
        f".snakemake/treetime/url/{treetime_url_hash}/source.txt"
    )

    rule fetch_treetime_url:
        output:
            binary=temp(TREETIME_BINARY),
            source=temp(TREETIME_SOURCE),
        params:
            url=treetime_url,
        shell:
            r"""
            python scripts/fetch-treetime.py \
                --url {params.url:q} \
                --output {output.binary:q} \
                --source-output {output.source:q}
            """
else:
    raise ValueError(
        "config['treetime'] must contain exactly one of 'nightly', 'path', or 'url'"
    )
