"""Signing checks accept Android tool output changes without skipping validation."""

import importlib.util
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch
from zipfile import ZipFile


SCRIPT = Path(__file__).resolve().parents[2] / ".github/scripts/check_apks.py"
SPEC = importlib.util.spec_from_file_location("check_apks", SCRIPT)
checker = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(checker)

CERT = "a1" * 32
OTHER = "b2" * 32
NUMBERED = f"Signer #1 certificate SHA-256 digest: {CERT}\n"
SCHEME = f"V2 Signer: certificate SHA-256 digest: {CERT}\n"
RANGED = f"Signer (minSdkVersion=24, maxSdkVersion=2147483647) certificate SHA-256 digest: {CERT}\n"


class CertificateTest(unittest.TestCase):
    def test_numbered_signer(self):
        self.assertEqual(checker.signing_certificates(NUMBERED), {CERT})

    def test_build_tools_37_signature_scheme_label(self):
        self.assertEqual(checker.signing_certificates(SCHEME), {CERT})

    def test_sdk_range_signers(self):
        output = RANGED + RANGED.replace("24", "33", 1)
        self.assertEqual(checker.signing_certificates(output), {CERT})

    def test_multiple_signers_and_crlf(self):
        output = NUMBERED + f"Signer #2 certificate SHA-256 digest: {OTHER.upper()}\r\n"
        self.assertEqual(checker.signing_certificates(output), {CERT, OTHER})

    def test_sdk_range_with_development_release(self):
        output = RANGED.replace("minSdkVersion=24", "minSdkVersion=33 (dev release=true)")
        self.assertEqual(checker.signing_certificates(output), {CERT})

    def test_public_key_and_source_stamp_are_not_signers(self):
        output = (
            f"Signer #1 public key SHA-256 digest: {OTHER}\n"
            f"Source Stamp Signer certificate SHA-256 digest: {OTHER}\n"
        )
        self.assertEqual(checker.signing_certificates(NUMBERED + output), {CERT})
        with self.assertRaisesRegex(RuntimeError, "no signing certificate"):
            checker.signing_certificates(output)

    def test_missing_or_malformed_digest_is_a_clear_failure(self):
        for output in ("", "Signer #1 certificate SHA-256 digest: invalid\n"):
            with self.subTest(output=output):
                with self.assertRaisesRegex(RuntimeError, "no signing certificate"):
                    checker.signing_certificates(output)


class ApkCheckTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / "build-tools/37.0.0").mkdir(parents=True)
        (self.root / "build-tools/37.0.0/aapt").touch()
        abis = {"armeabi-v7a", "arm64-v8a", "x86_64"}
        outputs = {"app-release.apk": abis}
        outputs.update({f"app-{abi}-release.apk": {abi} for abi in abis})
        for name, architectures in outputs.items():
            with ZipFile(self.root / name, "w") as archive:
                for abi in architectures:
                    for library in ("libapp.so", "libflutter.so"):
                        archive.writestr(f"lib/{abi}/{library}", b"test")
        self.certificates = {name: RANGED for name in outputs}
        self.certificates["app-release.apk"] = NUMBERED
        self.certificates["app-arm64-v8a-release.apk"] = SCHEME

    def command(self, args, **kwargs):
        if Path(args[0]).name == "aapt":
            return "package: name='me.jxl.kiosk_satellite' versionCode='239' versionName='2026.9.40'"
        return self.certificates[Path(args[-1]).name]

    def check(self):
        with patch.object(checker.subprocess, "check_output", self.command):
            checker.check(self.root, "2026.9.40", "239", self.root)

    def test_equal_certificates_across_tool_formats_pass(self):
        self.check()

    def test_a_different_signing_certificate_still_fails(self):
        self.certificates["app-x86_64-release.apk"] = RANGED.replace(CERT, OTHER)
        with self.assertRaisesRegex(RuntimeError, "signing certificates differ"):
            self.check()

    def test_an_additional_signer_is_not_ignored(self):
        self.certificates["app-x86_64-release.apk"] += NUMBERED.replace(CERT, OTHER)
        with self.assertRaisesRegex(RuntimeError, "signing certificates differ"):
            self.check()

    def test_invalid_apk_signature_is_not_ignored(self):
        with patch.object(checker.subprocess, "check_output", side_effect=subprocess.CalledProcessError(1, "apksigner")):
            with self.assertRaises(subprocess.CalledProcessError):
                checker.check(self.root, "2026.9.40", "239", self.root)


if __name__ == "__main__":
    unittest.main()
