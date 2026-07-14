"""Fetch a TreeTime nightly release for the current platform."""

from __future__ import annotations

import argparse
import json
import logging
import os
import platform
import shutil
import stat
import tempfile
from dataclasses import dataclass
from pathlib import Path
from urllib.error import HTTPError, URLError
from urllib.parse import quote
from urllib.request import Request, urlopen


NIGHTLY_REPOSITORY = "neherlab/treetime-nightly"
GITHUB_API = f"https://api.github.com/repos/{NIGHTLY_REPOSITORY}"
LOGGER = logging.getLogger(__name__)


def main() -> None:
    args = _parse_args()
    logging.basicConfig(level=logging.INFO, format="%(message)s")

    if isinstance(args.source, _ReleaseSource):
        release = _release_get(args.source.release)
        asset_name = _asset_name()
        asset = next(
            (asset for asset in release.assets if asset.name == asset_name), None
        )
        if asset is None:
            available = ", ".join(asset.name for asset in release.assets)
            message = (
                f"release {release.tag!r} has no {asset_name!r} asset; "
                f"available: {available}"
            )
            raise RuntimeError(message)

        if args.source.release == "latest":
            description = (
                "TreeTime nightly: requested latest; "
                f"resolved tag {release.tag}; URL {asset.url}"
            )
        else:
            description = f"TreeTime nightly: tag {release.tag}; URL {asset.url}"
        url = asset.url
    else:
        description = f"TreeTime URL: {args.source.url}"
        url = args.source.url

    LOGGER.info(description)
    _download(url, args.output)
    args.source_output.parent.mkdir(parents=True, exist_ok=True)
    args.source_output.write_text(f"{description}\n", encoding="utf-8")


@dataclass(frozen=True)
class _Arguments:
    source: _ReleaseSource | _UrlSource
    output: Path
    source_output: Path


@dataclass(frozen=True)
class _ReleaseSource:
    release: str


@dataclass(frozen=True)
class _UrlSource:
    url: str


@dataclass(frozen=True)
class _Asset:
    name: str
    url: str


@dataclass(frozen=True)
class _Release:
    tag: str
    assets: tuple[_Asset, ...]


def _parse_args() -> _Arguments:
    parser = argparse.ArgumentParser(description=__doc__)
    source = parser.add_mutually_exclusive_group(required=True)
    source.add_argument(
        "--release",
        help="Nightly release tag, or 'latest' for the newest release",
    )
    source.add_argument("--url", help="URL of a TreeTime binary")
    parser.add_argument("--output", required=True, type=Path)
    parser.add_argument("--source-output", required=True, type=Path)
    args = parser.parse_args()
    source = (
        _ReleaseSource(release=args.release)
        if args.release is not None
        else _UrlSource(url=args.url)
    )
    return _Arguments(
        source=source,
        output=args.output,
        source_output=args.source_output,
    )


def _release_get(version: str) -> _Release:
    endpoint = (
        "releases?per_page=1"
        if version == "latest"
        else f"releases/tags/{quote(version, safe='')}"
    )
    payload = _json_get(f"{GITHUB_API}/{endpoint}")
    if version == "latest":
        if not isinstance(payload, list) or not payload:
            raise RuntimeError(f"{NIGHTLY_REPOSITORY} has no releases")
        payload = payload[0]
    return _release_parse(payload)


def _json_get(url: str) -> object:
    request = Request(
        url,
        headers={
            "Accept": "application/vnd.github+json",
            "User-Agent": "nextstrain-mpox-workflow",
            "X-GitHub-Api-Version": "2022-11-28",
        },
    )
    try:
        with urlopen(request) as response:
            return json.load(response)
    except (HTTPError, URLError) as error:
        message = f"fetching GitHub release metadata from {url}: {error}"
        raise RuntimeError(message) from error


def _release_parse(payload: object) -> _Release:
    if not isinstance(payload, dict):
        raise RuntimeError("GitHub release response is not an object")

    tag = payload.get("tag_name")
    assets = payload.get("assets")
    if not isinstance(tag, str) or not isinstance(assets, list):
        raise RuntimeError("GitHub release response is missing tag_name or assets")

    return _Release(tag=tag, assets=tuple(_asset_parse(asset) for asset in assets))


def _asset_parse(payload: object) -> _Asset:
    if not isinstance(payload, dict):
        raise RuntimeError("GitHub release asset is not an object")

    name = payload.get("name")
    url = payload.get("browser_download_url")
    if not isinstance(name, str) or not isinstance(url, str):
        raise RuntimeError(
            "GitHub release asset is missing name or browser_download_url"
        )
    return _Asset(name=name, url=url)


def _asset_name() -> str:
    system = platform.system().lower()
    machine = platform.machine().lower()
    machine = {"amd64": "x86_64", "arm64": "aarch64"}.get(machine, machine)

    targets = {
        ("darwin", "aarch64"): "aarch64-apple-darwin",
        ("darwin", "x86_64"): "x86_64-apple-darwin",
        ("linux", "aarch64"): "aarch64-unknown-linux-gnu",
        ("linux", "x86_64"): "x86_64-unknown-linux-gnu",
        ("windows", "x86_64"): "x86_64-pc-windows-gnu",
    }
    target = targets.get((system, machine))
    if target is None:
        raise RuntimeError(f"no TreeTime nightly is available for {system}/{machine}")

    extension = ".exe" if system == "windows" else ""
    return f"treetime-{target}{extension}"


def _download(url: str, output: Path) -> None:
    output.parent.mkdir(parents=True, exist_ok=True)
    request = Request(url, headers={"User-Agent": "nextstrain-mpox-workflow"})
    temporary_path: Path | None = None
    try:
        with urlopen(request) as response:
            with tempfile.NamedTemporaryFile(
                dir=output.parent, delete=False
            ) as temporary:
                temporary_path = Path(temporary.name)
                shutil.copyfileobj(response, temporary)
        os.chmod(
            temporary_path,
            stat.S_IRUSR
            | stat.S_IWUSR
            | stat.S_IXUSR
            | stat.S_IRGRP
            | stat.S_IXGRP
            | stat.S_IROTH
            | stat.S_IXOTH,
        )
        temporary_path.replace(output)
    except (HTTPError, URLError) as error:
        raise RuntimeError(f"downloading TreeTime from {url}: {error}") from error
    finally:
        if temporary_path is not None and temporary_path.exists():
            temporary_path.unlink()


if __name__ == "__main__":
    main()
