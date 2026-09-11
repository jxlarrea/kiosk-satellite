"""Check architecture contents, version codes and signatures before upload."""

import os
from pathlib import Path
import re
import subprocess
import sys
from zipfile import ZipFile


def signing_certificates(output):
    # New build tools identify signers by signature scheme or SDK range.
    # Compare all signer certificates and ignore public-key and stamp hashes.
    digests = re.findall(
        r"^(?:Signer|V\d+(?:\.\d+)? Signer)[^\r\n]* certificate SHA-256 digest: "
        r"([0-9a-fA-F]{64})[ \t]*\r?$",
        output,
        re.MULTILINE,
    )
    if not digests:
        raise RuntimeError("apksigner reported no signing certificate SHA-256 digests")
    return frozenset(digest.lower() for digest in digests)


def check(directory, version, build_number, sdk):
    abis = {"armeabi-v7a", "arm64-v8a", "x86_64"}
    tools = max(
        sdk.glob("build-tools/*/aapt"),
        key=lambda p: tuple(int(n) for n in re.findall(r"\d+", p.parent.name)),
    ).parent
    outputs = {"app-release.apk": abis}
    outputs.update({f"app-{abi}-release.apk": {abi} for abi in sorted(abis)})
    signatures = set()
    for name, expected in outputs.items():
        apk = directory / name
        metadata = subprocess.check_output([str(tools / "aapt"), "dump", "badging", str(apk)], text=True)
        package = re.search(r"package: name='([^']+)' versionCode='([^']+)' versionName='([^']+)'", metadata)
        if not package or package.groups() != ("me.jxl.kiosk_satellite", build_number, version):
            raise RuntimeError(f"Unexpected package or version in {name}")
        with ZipFile(apk) as archive:
            files = set(archive.namelist())
            actual = {n.split('/')[1] for n in files if n.startswith('lib/') and n.endswith('.so')}
            if actual != expected:
                raise RuntimeError(f"Unexpected architectures in {name}: {sorted(actual)}")
            for abi in actual:
                for library in ("libapp.so", "libflutter.so"):
                    if f"lib/{abi}/{library}" not in files:
                        raise RuntimeError(f"Missing {abi}/{library} in {name}")
        certificate = subprocess.check_output(
            [str(tools / "apksigner"), "verify", "--print-certs", str(apk)], text=True,
        )
        signatures.add(signing_certificates(certificate))
        print(f"Verified {name}: version {version}+{build_number}, {', '.join(sorted(actual))}")
    if len(signatures) != 1:
        raise RuntimeError("APK signing certificates differ")


if __name__ == "__main__":
    sdk = Path(os.environ.get("ANDROID_HOME") or os.environ["ANDROID_SDK_ROOT"])
    check(Path(sys.argv[1]), sys.argv[2], sys.argv[3], sdk)
