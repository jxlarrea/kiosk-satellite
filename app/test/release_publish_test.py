"""Older updaters must see universal first during publication and reruns."""

import importlib.util
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[2] / ".github/scripts/publish_apks.py"
SPEC = importlib.util.spec_from_file_location("publish_apks", SCRIPT)
publisher = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(publisher)


class PublishTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.directory = Path(self.temp.name)
        self.tag = "v1.2.3"
        self.universal = "kiosk-satellite-v1.2.3.apk"
        self.splits = [f"kiosk-satellite-v1.2.3.{abi}.apk" for abi in publisher.ABIS]
        for name in [self.universal, *self.splits]:
            (self.directory / name).touch()
        self.remote = []
        self.legacy_choices = []
        self.fail_upload = None
        self.reverse = False

    def gh(self, *args):
        if args[0] == "api":
            names = self.remote[::-1] if self.reverse else self.remote
            return json.dumps({"assets": [{"name": name} for name in names]})
        action = args[1]
        if action == "delete-asset":
            self.remote.remove(args[3])
        elif action == "upload":
            name = Path(args[3]).name
            if name == self.fail_upload:
                raise RuntimeError("upload failed")
            if name in self.remote:
                assert "--clobber" in args
                self.remote.remove(name)
            self.remote.append(name)
        else:
            raise AssertionError(args)
        # This is the selection used by already-released app versions.
        self.legacy_choices.append(next((n for n in self.remote if n.endswith(".apk")), None))
        return ""

    def publish(self):
        with patch.object(publisher, "gh", self.gh):
            publisher.publish(self.tag, self.directory)

    def test_new_release_keeps_universal_first(self):
        self.remote = ["checksums.txt"]
        self.publish()
        self.assertEqual(self.remote, ["checksums.txt", self.universal, *self.splits])
        self.assertTrue(all(n == self.universal for n in self.legacy_choices))

    def test_rerun_never_exposes_a_split_as_the_legacy_download(self):
        self.remote = [self.universal, *self.splits]
        self.publish()
        self.assertEqual(self.remote, [self.universal, *self.splits])
        self.assertTrue(all(n == self.universal for n in self.legacy_choices))

    def test_universal_is_also_first_when_assets_are_sorted_by_name(self):
        self.publish()
        self.assertEqual(sorted(self.remote)[0], self.universal)

    def test_partial_split_upload_leaves_universal_first(self):
        self.fail_upload = self.splits[1]
        with self.assertRaisesRegex(RuntimeError, "upload failed"):
            self.publish()
        self.assertEqual(self.remote[0], self.universal)
        self.assertTrue(all(n == self.universal for n in self.legacy_choices))

    def test_unexpected_api_order_removes_splits(self):
        self.reverse = True
        with self.assertRaisesRegex(RuntimeError, "Unexpected APK order"):
            self.publish()
        self.assertEqual(self.remote, [self.universal])

    def test_missing_output_does_not_touch_published_assets(self):
        self.remote = [self.universal]
        (self.directory / self.splits[0]).unlink()
        with self.assertRaisesRegex(RuntimeError, "Missing build output"):
            self.publish()
        self.assertEqual(self.remote, [self.universal])
        self.assertFalse(self.legacy_choices)

    def test_unknown_apk_is_not_deleted_or_published_over(self):
        self.remote = ["unrelated.apk"]
        with self.assertRaisesRegex(RuntimeError, "Unexpected APK"):
            self.publish()
        self.assertEqual(self.remote, ["unrelated.apk"])
        self.assertFalse(self.legacy_choices)


if __name__ == "__main__":
    unittest.main()
