"""Publish APKs with the universal asset first for older app versions."""

import json
from pathlib import Path
import subprocess
import sys
from urllib.parse import quote


ABIS = ("armeabi-v7a", "arm64-v8a", "x86_64")


def gh(*args):
    return subprocess.check_output(["gh", *args], text=True)


def assets(tag):
    endpoint = f"repos/{{owner}}/{{repo}}/releases/tags/{quote(tag, safe='')}"
    return json.loads(gh("api", endpoint))["assets"]


def publish(tag, directory):
    universal = f"kiosk-satellite-{tag}.apk"
    # Dots also keep universal first when the filenames are sorted.
    splits = [f"kiosk-satellite-{tag}.{abi}.apk" for abi in ABIS]
    names = [universal, *splits]
    for name in names:
        if not (directory / name).is_file():
            raise RuntimeError(f"Missing build output: {name}")

    existing = assets(tag)
    for asset in existing:
        if asset["name"].endswith(".apk") and asset["name"] not in names:
            raise RuntimeError(f"Unexpected APK could break older updaters: {asset['name']}")

    # --clobber deletes and recreates universal on a rerun. Remove our old
    # splits first so an older updater never sees one ahead of universal.
    for asset in existing:
        if asset["name"] in splits:
            gh("release", "delete-asset", tag, asset["name"], "--yes")

    gh("release", "upload", tag, str(directory / universal), "--clobber")
    for name in splits:
        gh("release", "upload", tag, str(directory / name))

    published = [a["name"] for a in assets(tag) if a["name"].endswith(".apk")]
    if not published or published[0] != universal or set(published) != set(names):
        # The first APK is the whole selection algorithm in older versions.
        # Leave only universal if GitHub returns an unexpected asset order.
        for name in splits:
            if name in published:
                gh("release", "delete-asset", tag, name, "--yes")
        raise RuntimeError(f"Unexpected APK order: {published}")


if __name__ == "__main__":
    publish(sys.argv[1], Path(sys.argv[2]))
