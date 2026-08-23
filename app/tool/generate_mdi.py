#!/usr/bin/env python3
"""Regenerates the bundled Material Design Icons path data.

Home Assistant names icons the way its frontend does, `mdi:washing-machine`,
and those names reach this app through notifications, entity attributes and
the At a Glance rows. Drawing them needs the shapes, so the icon set is
bundled: one JSON file per first letter under assets/mdi, each mapping an
icon name to the SVG path that draws it on a 24 by 24 grid.

Sharded on purpose. The whole set is about 2.7MB of path data and a kiosk
draws a handful of icons; loading one letter (the largest is under half a
megabyte, and nothing is kept once the icon is resolved) beats holding all
7000 of them in memory on a tablet with 2GB.

The paths come from the @mdi/js package and the alias list from @mdi/svg's
metadata, both the upstream sources the Home Assistant frontend builds on.
Run this to move to a newer Material Design Icons release:

    python3 app/tool/generate_mdi.py

It writes assets/mdi/<letter>.json plus assets/mdi/VERSION, and needs
network access. Nothing at runtime depends on this script.
"""

import json
import os
import re
import urllib.request

PATHS_URL = "https://cdn.jsdelivr.net/npm/@mdi/js@latest/mdi.js"
META_URL = "https://cdn.jsdelivr.net/npm/@mdi/svg@latest/meta.json"
OUT_DIR = os.path.join(os.path.dirname(__file__), "..", "assets", "mdi")


def fetch(url: str) -> str:
    with urllib.request.urlopen(url) as response:
        return response.read().decode("utf-8")


def kebab(export_name: str) -> str:
    """mdiWashingMachine -> washing-machine, the name Home Assistant uses."""
    stem = export_name[3:]
    out = []
    for index, char in enumerate(stem):
        if char.isupper() and index > 0:
            out.append("-")
        out.append(char.lower())
    return "".join(out)


def main() -> None:
    source = fetch(PATHS_URL)
    version = re.search(r"Material Design Icons v([\d.]+)", source)
    paths = {
        kebab(name): path
        for name, path in re.findall(
            r'export var (mdi[A-Za-z0-9]+)\s*=\s*"([^"]+)"', source
        )
    }
    if not paths:
        raise SystemExit("no icons parsed; the upstream format changed")

    # Aliases are how renamed icons keep working: someone's dashboard may
    # still say mdi:radiobox-marked years after it became mdi:record-circle.
    # They are stored as "@name" pointers rather than a second copy of the
    # path, which is most of a megabyte across the set.
    aliases = 0
    for icon in json.loads(fetch(META_URL)):
        if icon["name"] not in paths:
            continue
        for alias in icon.get("aliases", []):
            if alias not in paths:
                paths[alias] = "@" + icon["name"]
                aliases += 1

    shards: dict[str, dict[str, str]] = {}
    for name, path in sorted(paths.items()):
        letter = name[0] if name[:1].isalpha() else "_"
        shards.setdefault(letter, {})[name] = path

    os.makedirs(OUT_DIR, exist_ok=True)
    for stale in os.listdir(OUT_DIR):
        os.remove(os.path.join(OUT_DIR, stale))
    for letter, icons in shards.items():
        with open(os.path.join(OUT_DIR, f"{letter}.json"), "w") as out:
            json.dump(icons, out, separators=(",", ":"), sort_keys=True)
    with open(os.path.join(OUT_DIR, "VERSION"), "w") as out:
        out.write((version.group(1) if version else "unknown") + "\n")

    total = sum(len(icons) for icons in shards.values())
    print(f"{total} icons ({aliases} aliases) in {len(shards)} files")


if __name__ == "__main__":
    main()
