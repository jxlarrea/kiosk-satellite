#!/usr/bin/env python3
"""Validate catalogs and exchange pinned localization snapshots."""

import argparse
import base64
import hashlib
import json
import re
import subprocess
import sys
from pathlib import Path
from xml.sax.saxutils import escape


SCHEMA = 2
TAG = re.compile(r"[a-z]{2,3}(?:-[A-Z][a-z]{3})?(?:-(?:[A-Z]{2}|[0-9]{3}))?\Z")
BUNDLE = re.compile(r"[a-z][a-z0-9]*(?:_[a-z0-9]+)*_en\.arb\Z")
KEY = re.compile(r"[a-z][A-Za-z0-9]*\Z")
PARAM = re.compile(r"\{([a-z][A-Za-z0-9]*)\}")
REPOSITORY = "https://github.com/jxlarrea/kiosk-satellite-localization"


def encoded(value):
    return (json.dumps(value, ensure_ascii=False, indent=2) + "\n").encode()


def sha(value):
    return hashlib.sha256(value).hexdigest()


def no_duplicates(pairs):
    result = {}
    for key, value in pairs:
        if key in result:
            raise ValueError(f"Duplicate JSON key: {key}")
        result[key] = value
    return result


def decode(raw):
    result = json.loads(raw.decode("utf-8"), object_pairs_hook=no_duplicates)
    if not isinstance(result, dict):
        raise ValueError("Catalogs and metadata must be JSON objects")
    return result


def read(path):
    return decode(read_bytes(path))


def file_limit(path):
    # Review records aggregate every section, unlike individual ARB files.
    return 5_000_000 if "metadata" in Path(path).parts and any(
        part in Path(path).parts for part in ("reviews", "provenance")
    ) else 500_000


def read_bytes(path):
    limit = file_limit(path)
    if path.is_symlink() or not path.is_file() or path.stat().st_size > limit:
        raise ValueError(f"Expected a regular file no larger than {limit} bytes: {path}")
    return path.read_bytes()


def write(path, value):
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_bytes(encoded(value))


def messages(catalog):
    return {key: value for key, value in catalog.items() if not key.startswith("@")}


def parameters(text):
    if "{" in PARAM.sub("", text) or "}" in PARAM.sub("", text):
        raise ValueError("This catalog supports plain text and named placeholders only. ICU plurals and selects need a later formatter update.")
    return set(PARAM.findall(text))


def validate_text(text):
    if not isinstance(text, str) or not text.strip() or len(text) > 8000:
        raise ValueError("Messages must be nonempty strings of at most 8000 characters")
    if re.search(r"[\x00-\x08\x0b\x0c\x0e-\x1f\u2013\u2014]", text):
        raise ValueError("Messages contain a prohibited control character or dash")
    if re.search(r"<[^>]+>", text):
        raise ValueError("HTML and markup are not supported")
    return parameters(text)


def validate_source(source):
    if source.get("@@locale") != "en" or not messages(source):
        raise ValueError("The English source catalog is missing")
    for key, value in messages(source).items():
        if not KEY.fullmatch(key):
            raise ValueError(f"Invalid message ID: {key}")
        params = validate_text(value)
        metadata = source.get("@" + key, {})
        if not isinstance(metadata, dict):
            raise ValueError(f"Invalid message metadata: {key}")
        for field in ("context", "description"):
            if not isinstance(metadata.get(field), str) or not metadata[field].strip():
                raise ValueError(f"Missing {field}: {key}")
        if "x-notes" in metadata and (not isinstance(metadata["x-notes"], str) or not metadata["x-notes"].strip()):
            raise ValueError(f"Invalid translator notes: {key}")
        declared = metadata.get("placeholders", {})
        if not isinstance(declared, dict) or set(declared) != params or any(
            not isinstance(v, dict) or v.get("type") != "String" for v in declared.values()
        ):
            raise ValueError(f"Placeholder definitions do not match: {key}")
    allowed = {"@@locale", *messages(source), *("@" + k for k in messages(source))}
    if set(source) != allowed:
        raise ValueError("Unexpected source metadata")


def validate_translation(source, catalog, locale):
    if not TAG.fullmatch(locale) or locale == "en" or catalog.get("@@locale") != locale.replace("-", "_"):
        raise ValueError(f"Invalid locale marker or language tag: {locale}")
    for key, value in catalog.items():
        if key == "@@locale":
            continue
        if key not in messages(source):
            raise ValueError(f"Unknown message or translator-supplied metadata: {key}")
        if validate_text(value) != parameters(source[key]):
            raise ValueError(f"Placeholders do not match: {key}")
        urls = lambda text: {url.rstrip(".;:!?)]") for url in re.findall(r"https?://[^\s,]+", text)}
        if urls(value) != urls(source[key]):
            raise ValueError(f"Preserve URLs exactly: {key}")


def source_digest(source, key):
    return sha(encoded({"message": source[key], "metadata": source["@" + key]}))


def merge_bundles(bundles, locale):
    result = {"@@locale": locale.replace("-", "_")}
    for name, bundle in sorted(bundles.items()):
        for key, value in bundle.items():
            if key == "@@locale":
                continue
            if key in result:
                raise ValueError(f"Duplicate message ID across files: {key} in {name}")
            result[key] = value
    return result


def source_bundles(files):
    if not files:
        raise ValueError("The English source catalogs are missing")
    bundles = {}
    for name, raw in sorted(files.items()):
        if not BUNDLE.fullmatch(name):
            raise ValueError(f"Invalid source filename: {name}")
        bundles[name] = decode(raw)
        validate_source(bundles[name])
    merge_bundles(bundles, "en")
    return bundles


def bundle_files(directory, *, source=False):
    if directory.is_symlink() or not directory.is_dir():
        raise ValueError(f"Expected a catalog directory: {directory}")
    return {path.name: read_bytes(path) for path in sorted(directory.iterdir())
            if not (source and path.name == "manifest.json")}


def load_sources(directory):
    return source_bundles(bundle_files(directory, source=True))


def translation_name(source_name, locale):
    return source_name.removesuffix("_en.arb") + f"_{locale.replace('-', '_')}.arb"


def translation_catalog(bundles, files, locale):
    if not TAG.fullmatch(locale) or locale == "en":
        raise ValueError(f"Invalid language tag: {locale}")
    expected = {translation_name(name, locale): source for name, source in bundles.items()}
    translated = {}
    for name, raw in sorted(files.items()):
        if name not in expected:
            raise ValueError(f"Unexpected translation path: {locale}/{name}")
        translated[name] = decode(raw)
        validate_translation(expected[name], translated[name], locale)
    return merge_bundles(translated, locale)


def validate_manifest(manifest, files):
    if manifest.get("schema") != SCHEMA or manifest.get("files") != {
        name: sha(raw) for name, raw in files.items()
    }:
        raise ValueError("Source manifest does not match the English catalogs")


def canonical_digest(value):
    return sha(json.dumps(value, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode())


def verify_provenance(proof, locale):
    """Verify retained acceptance and merge evidence before trusting review metadata."""
    try:
        record, outcome = proof["record"], proof["outcome"]
        context = record["context"]
        identity = context["id"]
        if (record["repository"] != REPOSITORY.removeprefix("https://github.com/")
                or record["kind"] != "contributor_acceptance" or record["schema"] != 1
                or identity != canonical_digest({k: v for k, v in context.items() if k != "id"})
                or record["actor"]["id"] != context["author_id"] or record["actor"]["type"] != "User"
                or record["event_action"] != "edited"
                or sha(record["agreement_text"].encode()) != context["agreement"]["sha256"]
                or "- [x]" not in record["declaration"].lower()
                or "- [ ]" not in record["previous_declaration"]
                or context["head"] not in record["declaration"]
                or identity not in record["declaration"]
                or outcome["kind"] != "pr_closed" or outcome["merged"] is not True
                or outcome["covered"] is not True or outcome["matches_merge"] is not True
                or outcome["merged_by"] != proof["owner_id"]
                or outcome["number"] != context["number"] or outcome["head"] != context["head"]
                or outcome["acceptance"]["sha256"] != canonical_digest(record)
                or not re.fullmatch(r"[a-f0-9]{40}", proof["records_revision"])):
            raise ValueError("Community acceptance or merge evidence is invalid")
        if "disclosures_sha256" in context:
            description = re.sub(
                r"<!-- ks-contributor-acceptance:start -->.*?<!-- ks-contributor-acceptance:end -->",
                "", record["pr_description"], flags=re.DOTALL,
            ).replace("\r\n", "\n").strip()
            if sha(description.encode()) != context["disclosures_sha256"]:
                raise ValueError("Community disclosures do not match the accepted reference")
        if [entry["file"] for entry in record["snapshot"]] != context["files"]:
            raise ValueError("Community evidence omits contribution files")
        changed = {}
        for entry in record["snapshot"]:
            path = entry["file"]["filename"]
            if not path.startswith(f"translations/{locale}/"):
                raise ValueError("Community evidence covers another language")
            versions = {}
            for version in ("before", "after"):
                if version not in entry:
                    continue
                data = base64.b64decode(entry[version]["base64"], validate=True)
                blob = sha(data)
                git_blob = hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()
                if blob != entry[version]["sha256"] or git_blob != entry[version]["sha"]:
                    raise ValueError("Community evidence contains altered translation bytes")
                if version == "after" and git_blob != entry["file"]["sha"]:
                    raise ValueError("Community evidence does not match its manifest")
                versions[version] = messages(decode(data))
            for key, value in versions.get("after", {}).items():
                if versions.get("before", {}).get(key) != value:
                    changed[key] = value
        return identity, record["actor"]["login"], changed
    except (KeyError, TypeError) as error:
        raise ValueError("Community provenance is incomplete") from error


def community_review_valid(key, value, review, proofs):
    if isinstance(review, dict) and review.get("author") == "Xavier Larrea" and review.get("ownerAuthored") is True:
        return ("provenance" not in review and "maintainerCorrection" not in review
                and not any(key in changed for _, _, changed in proofs.values()))
    if not isinstance(review, dict) or review.get("provenance") not in proofs:
        return False
    _, author, changed = proofs[review["provenance"]]
    if review.get("author") != author or key not in changed or review.get("ownerAuthored"):
        return False
    if "maintainerCorrection" not in review:
        return changed[key] == value
    correction = review["maintainerCorrection"]
    return (isinstance(correction, dict) and correction.get("reviewer") == "Xavier Larrea"
            and correction.get("originalTranslation") == sha(changed[key].encode())
            and valid_correction_reason(correction.get("reason")) and changed[key] != value)


def valid_correction_reason(reason):
    return (isinstance(reason, str) and bool(reason.strip()) and len(reason) <= 1000
            and not re.search(r"[\x00-\x1f\x7f]", reason))


def load_proofs(files, locale):
    proofs = {}
    for path, raw in files.items():
        if path.startswith(f"metadata/provenance/{locale}/"):
            proof = decode(raw)
            identity, author, changed = verify_provenance(proof, locale)
            if Path(path).stem != identity:
                raise ValueError("Community provenance filename does not match its acceptance reference")
            proofs[identity] = (identity, author, changed)
    return proofs


def github_json(path):
    return decode(subprocess.check_output(["gh", "api", path]))


def github_record(path, revision):
    from urllib.parse import quote
    prefix = "repos/" + REPOSITORY.removeprefix("https://github.com/")
    obj = github_json(prefix + "/contents/" + quote(path, safe="/") + "?ref=" + revision)
    if obj.get("encoding") == "none":
        obj = github_json(prefix + "/git/blobs/" + obj["sha"])
    if obj.get("encoding") != "base64":
        raise ValueError("GitHub did not return the complete acceptance evidence")
    return decode(base64.b64decode(obj["content"]))


def review_community(repository, locale, pr_number, credit, language_name, confirmed):
    if not TAG.fullmatch(locale) or locale in ("en", "es"):
        raise ValueError("Choose a community language tag")
    if not confirmed:
        raise ValueError("Confirm fluent wording review and device and remote rendering review with --confirm-reviewed")
    for label in (credit, language_name):
        if not label or len(label) > 120 or re.search(r"[\x00-\x1f<>\[\]`\\\u2013\u2014]", label):
            raise ValueError("Use a short plain-text credit and native language name")
    source = validate_repository(repository)
    prefix = "repos/" + REPOSITORY.removeprefix("https://github.com/")
    repo = github_json(prefix)
    pr = github_json(prefix + f"/pulls/{pr_number}")
    if (not pr.get("merged") or (pr.get("merged_by") or {}).get("id") != repo["owner"]["id"]
            or pr["base"]["ref"] != repo["default_branch"]):
        raise ValueError("Community review requires a PR merged by the repository owner")
    subprocess.run(["git", "-C", str(repository), "merge-base", "--is-ancestor", pr["merge_commit_sha"], "HEAD"], check=True)
    revision = github_json(prefix + "/git/ref/heads/contributor-records")["object"]["sha"]
    tree = github_json(prefix + "/git/trees/" + revision + "?recursive=1")
    if tree.get("truncated"):
        raise ValueError("Acceptance records tree is incomplete")
    outcomes = [entry["path"] for entry in tree["tree"]
                if entry["path"].startswith(f"outcomes/{repo['id']}/{pr_number}/") and entry["type"] == "blob"]
    proof = None
    for path in sorted(outcomes, reverse=True):
        outcome = github_record(path, revision)
        if outcome.get("merge_commit") != pr["merge_commit_sha"] or not outcome.get("acceptance"):
            continue
        record = github_record(outcome["acceptance"]["path"], revision)
        candidate = {"records_revision": revision, "outcome_path": path,
                     "owner_id": repo["owner"]["id"], "record": record, "outcome": outcome}
        if record.get("repository_id") != repo["id"] or record.get("context", {}).get("head") != pr["head"]["sha"]:
            continue
        verify_provenance(candidate, locale)
        proof = candidate
        break
    if proof is None:
        raise ValueError("No verified merge outcome is available on contributor-records yet")
    identity, author, changed = verify_provenance(proof, locale)
    translated = translation_catalog(load_sources(repository / "source"),
                                     bundle_files(repository / "translations" / locale), locale)
    review_path = repository / f"metadata/reviews/{locale}.json"
    reviews = read(review_path) if review_path.exists() else {}
    count = 0
    for key, value in changed.items():
        if key in messages(source) and translated.get(key) == value:
            reviews[key] = {"source": source_digest(source, key), "translation": sha(value.encode()),
                            "author": author, "provenance": identity}
            count += 1
    if not count:
        raise ValueError("No current translation matches the accepted contribution")
    write(repository / f"metadata/provenance/{locale}/{identity}.json", proof)
    write(review_path, reviews)
    credits_path = repository / "metadata/credits.json"
    credits = read(credits_path) if credits_path.exists() else {}
    entries = credits.setdefault(locale, {})
    entries[str(record["actor"]["id"])] = {"name": credit, "login": author}
    write(credits_path, credits)
    lines = ["# Translation credits", ""]
    for tag, authors in sorted(credits.items()):
        lines.extend(f"- {entry['name']} ({tag})" for _, entry in sorted(authors.items()))
    (repository / "CREDITS.md").write_text("\n".join(lines) + "\n")
    names_path = repository / "metadata/languages.json"
    names = read(names_path) if names_path.exists() else {"en": "English", "es": "Español"}
    names[locale] = language_name
    write(names_path, names)
    print(f"Recorded {count} reviewed {locale} messages from PR #{pr_number}. Commit reviews, evidence and credits before import.")


def review_corrections(repository, locale, pr_number, message_ids, reason, confirmed):
    """Review explicit maintainer edits while retaining the accepted original."""
    if not TAG.fullmatch(locale) or locale in ("en", "es"):
        raise ValueError("Choose a community language tag")
    if not confirmed or not message_ids:
        raise ValueError("Confirm wording review and supply explicit --message-id values")
    if not valid_correction_reason(reason):
        raise ValueError("Supply a short plain-text correction reason")
    source = validate_repository(repository)
    translated = translation_catalog(load_sources(repository / "source"),
                                     bundle_files(repository / "translations" / locale), locale)
    candidates = []
    for path in (repository / "metadata/provenance" / locale).glob("*.json"):
        proof = read(path)
        identity, author, changed = verify_provenance(proof, locale)
        if path.stem != identity:
            raise ValueError("Community provenance filename does not match its acceptance reference")
        if proof["outcome"]["number"] == pr_number:
            candidates.append((identity, author, changed))
    if len(candidates) != 1:
        raise ValueError("Corrections require one retained verified contribution for this PR")
    identity, author, changed = candidates[0]
    selected = set(message_ids)
    if not selected <= changed.keys() or not selected <= messages(translated).keys():
        raise ValueError("Every correction must name a translated message covered by this PR")
    if any(translated[key] == changed[key] for key in selected):
        raise ValueError("Correction must differ from its accepted original")
    review_path = repository / f"metadata/reviews/{locale}.json"
    reviews = read(review_path) if review_path.exists() else {}
    for key in sorted(selected):
        reviews[key] = {"source": source_digest(source, key), "translation": sha(translated[key].encode()),
                        "author": author, "provenance": identity,
                        "maintainerCorrection": {"reviewer": "Xavier Larrea",
                                                 "originalTranslation": sha(changed[key].encode()),
                                                 "reason": reason.strip()}}
    write(review_path, reviews)
    print(f"Recorded {len(selected)} maintainer corrections to PR #{pr_number}. Original evidence and public credits are unchanged.")


def effective(source, catalog, reviews, proofs=None):
    result = dict(source)
    result["@@locale"] = catalog["@@locale"]
    counts = {"reviewed": 0, "missing": 0, "stale": 0}
    for key in messages(source):
        if key not in catalog:
            counts["missing"] += 1
        elif (not isinstance(reviews.get(key), dict)
              or reviews[key].get("source") != source_digest(source, key)
              or reviews[key].get("translation") != sha(catalog[key].encode())
              or (reviews[key].get("author") != "Xavier Larrea" if proofs is None
                  else not community_review_valid(key, catalog[key], reviews[key], proofs))):
            counts["stale"] += 1
        else:
            result[key] = catalog[key]
            counts["reviewed"] += 1
    return result, counts


def validate_repository(root):
    files = bundle_files(root / "source", source=True)
    bundles = source_bundles(files)
    source = merge_bundles(bundles, "en")
    manifest = read(root / "source/manifest.json")
    validate_manifest(manifest, files)
    for directory in sorted((root / "translations").iterdir()):
        locale = directory.name
        files = bundle_files(directory)
        catalog = translation_catalog(bundles, files, locale)
        for name, raw in files.items():
            source_name = next(name_en for name_en in bundles if translation_name(name_en, locale) == name)
            print(f"{locale}/{name}: {len(messages(decode(raw)))}/{len(messages(bundles[source_name]))} translated")
        print(f"{locale}: {len(messages(catalog))}/{len(messages(source))} translated")
    return source


def git_paths(repository, revision, prefix):
    if not re.fullmatch(r"[a-f0-9]{40}", revision):
        raise ValueError("Use a full 40-character commit SHA")
    return subprocess.check_output([
        "git", "-C", str(repository), "ls-tree", "-r", "--name-only", revision, "--", prefix
    ], text=True).splitlines()


def git_sources(repository, revision):
    return source_bundles({Path(path).name: git_file(repository, revision, path)
                          for path in git_paths(repository, revision, "source/") if path.endswith(".arb")})


def validate_pr(repository, base_revision, head_revision):
    """Require full new languages against the target source, allowing small updates."""
    base = git_sources(repository, base_revision)
    head = git_sources(repository, head_revision)
    current = merge_bundles(base, "en")
    previous = merge_bundles(head, "en")
    if load_sources(repository / "source") != base:
        raise ValueError("Translation PRs cannot change the English source. Sync with main.")
    base_paths = git_paths(repository, base_revision, "translations/")
    changed_paths = subprocess.check_output([
        "git", "-C", str(repository), "diff", "--name-only", f"{base_revision}...{head_revision}", "--", "translations/"
    ], text=True).splitlines()
    existing = {Path(path).parts[1] for path in base_paths}
    failures = []
    for locale in sorted({Path(path).parts[1] for path in changed_paths}):
        directory = repository / "translations" / locale
        if not directory.exists():
            continue
        translated = translation_catalog(base, bundle_files(directory), locale)
        missing = sorted(set(messages(current)) - set(messages(translated)))
        changed = sorted(key for key in messages(current) if key in previous
                         and source_digest(current, key) != source_digest(previous, key))
        new = locale not in existing
        print(f"{locale}: {'new language' if new else 'existing language'}; "
              f"{len(missing)} missing; {len(changed)} source changes need review")
        for name, bundle in base.items():
            for key in sorted(set(missing + changed) & set(messages(bundle))):
                reason = "missing" if key in missing else "source changed; sync and review"
                print(f"  {locale}/{translation_name(name, locale)}: {key}: {reason}")
        if new and (missing or changed):
            failures.append(locale)
    if failures:
        raise ValueError("New languages must be complete against current main: " + ", ".join(failures))


def export_catalog(app, repository):
    bundles = load_sources(app / "l10n/source")
    source = merge_bundles(bundles, "en")
    revision = subprocess.check_output(["git", "-C", str(app), "rev-parse", "HEAD"], text=True).strip()
    dirty = bool(subprocess.check_output(["git", "-C", str(app), "status", "--porcelain", "--", "l10n/source/"]))
    for path in (repository / "source").glob("*.arb"):
        if path.name not in bundles:
            path.unlink()
    for name, bundle in bundles.items():
        write(repository / "source" / name, bundle)
    write(repository / "source/manifest.json", {
        "schema": SCHEMA, "repository": "https://github.com/jxlarrea/kiosk-satellite",
        "revision": revision, "workingTree": dirty,
        "files": {name: sha(encoded(bundle)) for name, bundle in bundles.items()},
        "scope": "setup-settings-navigation-and-device-drawer",
    })
    target = repository / "tools/catalog.py"
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(Path(__file__).read_bytes())
    tests = repository / "tests/test_catalog.py"
    tests.parent.mkdir(parents=True, exist_ok=True)
    tests.write_bytes((app / "test/test_localization.py").read_bytes())
    print(f"Exported {len(messages(source))} messages. Source includes uncommitted catalog changes: {dirty}")


def review_owner(repository, locale, message_ids=None):
    # Community contributions retain their PR evidence. Only explicitly named
    # maintainer additions can use owner review in a community language.
    if not TAG.fullmatch(locale) or locale == "en":
        raise ValueError("Choose a non-English language tag")
    if locale != "es" and not message_ids:
        raise ValueError("Owner-authored additions require explicit --message-id values")
    source = validate_repository(repository)
    catalog = translation_catalog(load_sources(repository / "source"),
                                  bundle_files(repository / "translations" / locale), locale)
    path = repository / f"metadata/reviews/{locale}.json"
    reviews = read(path) if path.exists() else {}
    selected = set(message_ids) if message_ids else set(messages(catalog))
    if not selected <= messages(catalog).keys():
        raise ValueError("Owner review contains untranslated or unknown message IDs")
    if any(reviews.get(key, {}).get("provenance") for key in selected):
        raise ValueError("Community translations must retain their contributor provenance")
    if locale != "es":
        proofs = load_proofs({str(path.relative_to(repository)): path.read_bytes()
                              for path in (repository / "metadata/provenance" / locale).glob("*.json")}, locale)
        if any(selected.intersection(changed) for _, _, changed in proofs.values()):
            raise ValueError("Community translations must retain their contributor provenance")
    for key in selected:
        reviews[key] = {"source": source_digest(source, key), "translation": sha(catalog[key].encode()),
                        "author": "Xavier Larrea", **({"ownerAuthored": True} if locale != "es" else {})}
    write(path, reviews)
    print("Recorded owner review. Commit the translations and review metadata before importing.")


def git_file(repository, revision, path):
    mode = subprocess.check_output(["git", "-C", str(repository), "ls-tree", revision, "--", path], text=True)
    if not mode.startswith("100644 blob "):
        raise ValueError(f"Snapshot path must be an ordinary file: {path}")
    data = subprocess.check_output(["git", "-C", str(repository), "show", f"{revision}:{path}"])
    limit = file_limit(path)
    if len(data) > limit:
        raise ValueError(f"Snapshot file too large: {path}")
    return data


def import_catalog(app, repository, revision, locale):
    if not TAG.fullmatch(locale) or locale == "en":
        raise ValueError("Choose a non-English language tag")
    if not re.fullmatch(r"[a-f0-9]{40}", revision):
        raise ValueError("Import requires a full 40-character commit SHA")
    manifest = decode(git_file(repository, revision, "source/manifest.json"))
    names = manifest.get("files", {})
    if manifest.get("schema") != SCHEMA or not isinstance(names, dict) or not names or any(
        not BUNDLE.fullmatch(name) for name in names
    ):
        raise ValueError("Source manifest is invalid")
    lock_path = app / "l10n/localization.lock.json"
    previous = read(lock_path) if lock_path.exists() else {}
    locales = sorted(set(previous.get("locales", [])) | {locale})
    paths = ["source/manifest.json", *("source/" + name for name in names),
             "LICENSE", "CREDITS.md", "docs/CONTRIBUTOR-AGREEMENT.md"]
    metadata = git_paths(repository, revision, "metadata/")
    for optional in ("metadata/languages.json", "metadata/credits.json"):
        if optional in metadata:
            paths.append(optional)
    for tag in locales:
        if not TAG.fullmatch(tag) or tag == "en":
            raise ValueError("Invalid installed language")
        translations = git_paths(repository, revision, f"translations/{tag}/")
        expected = {f"translations/{tag}/{translation_name(name, tag)}" for name in names}
        if set(translations) - expected:
            raise ValueError("Unexpected translation path in snapshot")
        paths.extend(translations)
        paths.append(f"metadata/reviews/{tag}.json")
        paths.extend(path for path in metadata if path.startswith(f"metadata/provenance/{tag}/"))
    files = {path: git_file(repository, revision, path) for path in paths}
    source_files = {name: files["source/" + name] for name in names}
    validate_manifest(manifest, source_files)
    bundles = source_bundles(source_files)
    source = merge_bundles(bundles, "en")
    if bundles != load_sources(app / "l10n/source"):
        raise ValueError("Export the current app source before importing translations")
    for tag in locales:
        catalog = translation_catalog(bundles, {Path(path).name: raw for path, raw in files.items()
                                              if path.startswith(f"translations/{tag}/")}, tag)
        reviews = decode(files[f"metadata/reviews/{tag}.json"])
        proofs = None if tag == "es" else load_proofs(files, tag)
        _, counts = effective(source, catalog, reviews, proofs)
        if tag not in previous.get("locales", []) and (counts["missing"] or counts["stale"]):
            raise ValueError(f"The initial {tag} scope must be complete and reviewed before activation")
        if tag != "es":
            credits = decode(files.get("metadata/credits.json", b"{}"))
            if not credits.get(tag) or not files["CREDITS.md"].strip():
                raise ValueError(f"Community language {tag} needs public translation credits")
    for path, data in files.items():
        target = app / "l10n/vendor" / path
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_bytes(data)
    write(lock_path, {"schema": SCHEMA, "repository": REPOSITORY, "revision": revision,
                      "locales": locales, "files": {path: sha(data) for path, data in files.items()}})
    generate(app)


def android_resource_text(value):
    # Android applies its escapes after XML parsing. Quotes preserve spaces.
    value = value.replace('\\', '\\\\').replace('"', '\\"').replace("'", "\\'")
    value = value.replace('\n', '\\n').replace('\r', '\\r').replace('\t', '\\t')
    return escape('"' + value + '"')


def generate_android(app, catalogs):
    mapping_path = app / "l10n/android.json"
    if not mapping_path.exists():
        return
    mapping = read(mapping_path)
    for resource, identifier in mapping.items():
        if not re.fullmatch(r"[a-z][a-z0-9_]*", resource) or not isinstance(identifier, str) or any(
            identifier not in messages(bundle) or parameters(bundle[identifier])
            for bundle in catalogs.values()
        ):
            raise ValueError(f"Invalid Android resource mapping: {resource}")
    root = app / "android/app/src/main/res"
    paths = set()
    for locale, bundle in catalogs.items():
        if not TAG.fullmatch(locale):
            raise ValueError(f"Invalid Android locale: {locale}")
        qualifier = "values" if locale == "en" else "values-b+" + locale.replace("-", "+")
        path = root / qualifier / "ks_localization.xml"
        paths.add(path)
        lines = ['<?xml version="1.0" encoding="utf-8"?>',
                 '<!-- Generated by tool/localization.py. Do not edit. -->', '<resources>']
        if locale == "en":
            lines.append('    <string-array name="ks_message_languages" translatable="false">')
            lines.extend(f'        <item>{code}</item>' for code in catalogs)
            lines.append('    </string-array>')
        lines.extend(f'    <string name="{resource}" formatted="false">'
                     + android_resource_text(bundle[identifier]) + '</string>'
                     for resource, identifier in mapping.items())
        lines.append('</resources>')
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text('\n'.join(lines) + '\n')
    for path in root.glob('values*/ks_localization.xml'):
        if path not in paths:
            path.unlink()


def generate(app, preview_repo=None, preview_locale="es"):
    source = merge_bundles(load_sources(app / "l10n/source"), "en")
    settings = read(app / "l10n/settings.json")
    for setting, fields in settings.items():
        if not isinstance(fields, dict) or set(fields) != {"title", "description"} or any(
            not isinstance(key, str) or key not in messages(source) or parameters(source[key])
            for key in fields.values()
        ):
            raise ValueError(f"Invalid setting message mapping: {setting}")
    catalogs = {"en": source}
    lock_path = app / "l10n/localization.lock.json"
    if lock_path.exists():
        lock = read(lock_path)
        if (lock.get("schema") != SCHEMA or not isinstance(lock.get("locales"), list)
                or any(not TAG.fullmatch(tag) or tag == "en" for tag in lock["locales"])):
            raise ValueError("Unsupported localization lock schema or languages")
        for path, digest in lock["files"].items():
            if Path(path).is_absolute() or ".." in Path(path).parts:
                raise ValueError("Invalid vendor path")
            if sha(read_bytes(app / "l10n/vendor" / path)) != digest:
                raise ValueError(f"Vendored file changed outside import: {path}")
        source_files = {Path(path).name: read_bytes(app / "l10n/vendor" / path)
                        for path in lock["files"] if path.startswith("source/") and path.endswith(".arb")}
        validate_manifest(read(app / "l10n/vendor/source/manifest.json"), source_files)
        vendor_files = {path: read_bytes(app / "l10n/vendor" / path) for path in lock["files"]}
        for locale in lock["locales"]:
            catalog = translation_catalog(source_bundles(source_files), {
                Path(path).name: raw for path, raw in vendor_files.items()
                if path.startswith(f"translations/{locale}/")
            }, locale)
            # Removed IDs belong to the old snapshot and are never generated.
            catalog = {key: value for key, value in catalog.items() if key == "@@locale" or key in messages(source)}
            reviews = decode(vendor_files[f"metadata/reviews/{locale}.json"])
            proofs = None if locale == "es" else load_proofs(vendor_files, locale)
            catalogs[locale], counts = effective(source, catalog, reviews, proofs)
            print(f"{locale}: {counts}")
        notices = app / "assets/l10n"
        notices.mkdir(parents=True, exist_ok=True)
        for name, path in {"LICENSE.txt": "LICENSE", "CREDITS.md": "CREDITS.md",
                           "CONTRIBUTOR-AGREEMENT.md": "docs/CONTRIBUTOR-AGREEMENT.md"}.items():
            (notices / name).write_bytes((app / "l10n/vendor" / path).read_bytes())
    if preview_repo is not None:
        if not TAG.fullmatch(preview_locale) or preview_locale == "en":
            raise ValueError("Choose a non-English preview language tag")
        # Drafts are only for a local test build. Never create review evidence.
        validate_repository(preview_repo)
        bundles = load_sources(app / "l10n/source")
        if bundles != load_sources(preview_repo / "source"):
            raise ValueError("Export the current source before previewing translations")
        draft = translation_catalog(bundles, bundle_files(preview_repo / "translations" / preview_locale), preview_locale)
        catalogs[preview_locale] = {**source, **draft, "@@locale": preview_locale.replace("-", "_")}
        print(f"PREVIEW: includes unreviewed {preview_locale}. Run generate without --preview-repo before committing.")
    generate_android(app, catalogs)
    out = app / "l10n/effective"
    out.mkdir(parents=True, exist_ok=True)
    # gen-l10n refuses zh_CN without a zh catalog. Give each regional
    # language a base fallback with the same messages. It is not a choice in
    # the language picker, which lists only the catalogs above.
    effective_catalogs = dict(catalogs)
    for locale in sorted(catalogs):
        language = locale.split("-")[0]
        if language != locale and language not in effective_catalogs:
            effective_catalogs[language] = {**catalogs[locale], "@@locale": language}
    for path in out.glob("ui_*.arb"):
        if path.stem[3:] not in {tag.replace("-", "_") for tag in effective_catalogs}:
            path.unlink()
    for locale, catalog in effective_catalogs.items():
        filename_locale = locale.replace("-", "_")
        write(out / f"ui_{filename_locale}.arb", catalog)
    output = app / "lib/l10n/generated"
    viewer_path = app / "l10n/source/camera_view_status_en.arb"
    if viewer_path.exists():
        viewer = read(viewer_path)
        viewer_dir = app / "assets/camera-view"
        viewer_dir.mkdir(parents=True, exist_ok=True)
        (viewer_dir / "messages.js").write_text(
            "// Generated by tool/localization.py. Do not edit.\n"
            + "window.__ksCameraViewEnglish = "
            + json.dumps({key: viewer[key] for key in messages(viewer)}, ensure_ascii=False, indent=2)
            + ";\n")
    output.mkdir(parents=True, exist_ok=True)
    language_names = {"en": "English", "es": "Español", "de": "Deutsch", "fr": "Français", "ja": "日本語"}
    if lock_path.exists() and "metadata/languages.json" in lock["files"]:
        language_names.update(read(app / "l10n/vendor/metadata/languages.json"))
    if preview_repo is not None and (preview_repo / "metadata/languages.json").exists():
        language_names.update(read(preview_repo / "metadata/languages.json"))
    for tag, name in language_names.items():
        if not TAG.fullmatch(tag) or not isinstance(name, str) or not name.strip() or len(name) > 120:
            raise ValueError("Invalid native language name")
    (output / "language_codes.dart").write_text(
        "// Generated by tool/localization.py. Do not edit.\n"
        + "const messageLanguageOptions = <String>[\n"
        + "".join(f"  '{locale.replace('_', '-')}',\n" for locale in catalogs)
        + "];\n"
        + "const messageLanguageLabels = <String, String>"
        + json.dumps({tag: language_names.get(tag, tag) for tag in catalogs}, ensure_ascii=False).replace("$", r"\$")
        + ";\n")
    credits = {}
    if lock_path.exists() and "metadata/credits.json" in lock["files"]:
        credits = read(app / "l10n/vendor/metadata/credits.json")
    if preview_repo is not None and (preview_repo / "metadata/credits.json").exists():
        credits = read(preview_repo / "metadata/credits.json")
    # Original English and Spanish catalogs predate the community registry.
    for tag in ("en", "es"):
        credits.setdefault(tag, {"owner": {"name": "Xavier Larrea", "login": "jxlarrea"}})
    public_credits = {}
    for tag in sorted(catalogs):
        authors = credits.get(tag, {})
        if not isinstance(authors, dict):
            raise ValueError("Invalid localization credits")
        contributors = {}
        for author in authors.values():
            name = author.get("name") if isinstance(author, dict) else None
            if not isinstance(name, str) or not name.strip() or len(name) > 120 or re.search(r"[\x00-\x1f<>]", name):
                raise ValueError("Invalid localization contributor name")
            login = author.get("login", "")
            if not isinstance(login, str) or (login and not re.fullmatch(r"[A-Za-z0-9](?:[A-Za-z0-9-]{0,37}[A-Za-z0-9])?", login)):
                raise ValueError("Invalid localization contributor GitHub username")
            contributors[(name, login)] = {"name": name, "login": login}
        if contributors:
            public_credits[tag] = sorted(contributors.values(), key=lambda person: (person["name"].casefold(), person["login"].casefold()))
    payload = json.dumps(public_credits, ensure_ascii=False, indent=2)
    (output / "localization_credits.dart").write_text(
        "// Generated by tool/localization.py. Do not edit.\n"
        + "const localizationCredits = <String, List<Map<String, String>>>" + payload.replace("$", r"\$") + ";\n")
    (app / "remote-ui/static/localization_credits.js").write_text(
        "// Generated by tool/localization.py. Do not edit.\n"
        + "export const localizationCredits = " + payload + ";\n"
        + "export const localizationLanguageNames = "
        + json.dumps({tag: language_names.get(tag, tag) for tag in public_credits}, ensure_ascii=False) + ";\n")
    for filename, variable in [("navigation", "navigationMessageIds"), ("device_text", "deviceTextMessageIds"), ("ha_text", "haTextMessageIds"), ("screen_audio_text", "screenAudioTextMessageIds"), ("screensaver_text", "screensaverTextMessageIds"), ("camera_text", "cameraTextMessageIds"), ("camera_streams_text", "cameraStreamsTextMessageIds"), ("media_text", "mediaTextMessageIds"), ("intercom_text", "intercomTextMessageIds"), ("kiosk_text", "kioskTextMessageIds"), ("launcher_text", "launcherTextMessageIds"), ("gesture_text", "gestureTextMessageIds"), ("fleet_text", "fleetTextMessageIds"), ("plugin_text", "pluginTextMessageIds"), ("support_text", "supportTextMessageIds"), ("esphome_text", "esphomeTextMessageIds"), ("voice_text", "voiceTextMessageIds"), ("overview_text", "overviewTextMessageIds"), ("setup_text", "setupTextMessageIds")]:
        path = app / f"l10n/{filename}.json"
        mapping = read(path) if path.exists() else {}
        for label, identifier in mapping.items():
            if identifier not in messages(source) or source[identifier] != label or parameters(label):
                raise ValueError(f"Invalid {filename.replace('_text', '')} message mapping: {label}")
        payload = json.dumps(mapping, ensure_ascii=False, indent=2)
        (output / f"{filename}_ids.dart").write_text(
            "// Generated by tool/localization.py. Do not edit.\n"
            + f"const {variable} = <String, String>" + payload.replace('$', r'\$') + ";\n")
        (app / f"remote-ui/static/{filename}_ids.js").write_text(
            "// Generated by tool/localization.py. Do not edit.\n"
            + f"export const {variable} = " + payload + ";\n")
    options_path = app / "l10n/setting_options.json"
    options = read(options_path) if options_path.exists() else {}
    placeholders_path = app / "l10n/setting_placeholders.json"
    placeholders = read(placeholders_path) if placeholders_path.exists() else {}
    ids = [*placeholders.values(), *(identifier for values in options.values() for identifier in values.values())]
    if any(identifier not in messages(source) or parameters(source[identifier]) for identifier in ids):
        raise ValueError("Invalid setting option or placeholder message mapping")
    (output / "setting_option_ids.dart").write_text(
        "// Generated by tool/localization.py. Do not edit.\n"
        + "const settingOptionMessageIds = <String, Map<String, String>>" + json.dumps(options, indent=2) + ";\n"
        + "const settingPlaceholderMessageIds = <String, String>" + json.dumps(placeholders, indent=2) + ";\n")
    setting_lines = ["// Generated by tool/localization.py. Do not edit.",
                     "const settingMessageIds = <String, Map<String, String>>{"]
    for key, fields in settings.items():
        setting_lines.append(f'  "{key}": {{')
        setting_lines.extend(f'    "{field}": "{identifier}",' for field, identifier in fields.items())
        setting_lines.append("  },")
    setting_lines.extend(["};", ""])
    (output / "setting_ids.dart").write_text(
        "\n".join(setting_lines))
    # A map of getters, built once on first use. A switch over thousands of
    # ids was one huge function the Dart VM's optimizing compiler ran out
    # of memory on in flutter_tester, and it compared the id with every
    # case in turn.
    lookup = ["// Generated by tool/localization.py. Do not edit.", "import 'ui_strings.dart';", "",
              "String messageById(UiStrings strings, String? id, String fallback) {",
              "  final message = id == null ? null : _messages[id];",
              "  return message == null ? fallback : message(strings);",
              "}", "",
              "final _messages = <String, String Function(UiStrings)>{"]
    for key in messages(source):
        if parameters(source[key]):
            continue
        line = f"  '{key}': (s) => s.{key},"
        if len(line) <= 80:
            lookup.append(line)
        elif len(f"  '{key}': (s) =>") <= 80:
            lookup.extend([f"  '{key}': (s) =>", f"      s.{key},"])
        else:
            lookup.extend([f"  '{key}':", "      (s) => s", f"          .{key},"])
    lookup += ["};", ""]
    (output / "message_lookup.dart").write_text("\n".join(lookup))
    remote = app / "remote-ui/static/catalogs.js"
    remote.write_text("// Generated by tool/localization.py. Do not edit.\nexport const catalogs = "
                      + json.dumps({locale: messages(catalog) for locale, catalog in catalogs.items()}, ensure_ascii=False, indent=2)
                      + ";\n")
    print(f"Generated local catalogs: {', '.join(catalogs)}")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    commands = parser.add_subparsers(dest="command", required=True)
    for name in ("validate", "review-owner"):
        cmd = commands.add_parser(name)
        cmd.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
        if name == "review-owner":
            cmd.add_argument("--locale", default="es")
            cmd.add_argument("--message-id", action="append", help="Explicit owner-authored addition to review")
        if name == "validate":
            cmd.add_argument("--base-ref", help="Target commit for new-language completeness checks")
            cmd.add_argument("--head-ref", help="Contributor commit whose English source was reviewed")
    for name in ("export", "import", "generate"):
        cmd = commands.add_parser(name)
        cmd.add_argument("--app", type=Path, default=Path(__file__).resolve().parents[1])
        if name == "generate":
            cmd.add_argument("--preview-repo", type=Path, help="Include an unreviewed language in a local test build only")
            cmd.add_argument("--preview-locale", default="es")
        if name != "generate":
            cmd.add_argument("--repo", type=Path, required=True)
        if name == "import":
            cmd.add_argument("--revision", required=True)
            cmd.add_argument("--locale", default="es")
    cmd = commands.add_parser("review-community")
    cmd.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    cmd.add_argument("--locale", required=True)
    cmd.add_argument("--pr", type=int, required=True)
    cmd.add_argument("--credit", required=True)
    cmd.add_argument("--language-name", required=True)
    cmd.add_argument("--confirm-reviewed", action="store_true")
    cmd = commands.add_parser("review-corrections")
    cmd.add_argument("--repo", type=Path, default=Path(__file__).resolve().parents[1])
    cmd.add_argument("--locale", required=True)
    cmd.add_argument("--pr", type=int, required=True)
    cmd.add_argument("--message-id", action="append", required=True)
    cmd.add_argument("--reason", required=True)
    cmd.add_argument("--confirm-reviewed", action="store_true", help="Confirm review of the corrected wording")
    args = parser.parse_args()
    if args.command == "validate":
        validate_repository(args.repo)
        if args.base_ref or args.head_ref:
            if not args.base_ref or not args.head_ref:
                raise ValueError("Pass both --base-ref and --head-ref")
            validate_pr(args.repo, args.base_ref, args.head_ref)
    elif args.command == "review-community":
        review_community(args.repo, args.locale, args.pr, args.credit, args.language_name, args.confirm_reviewed)
    elif args.command == "review-corrections":
        review_corrections(args.repo, args.locale, args.pr, args.message_id, args.reason, args.confirm_reviewed)
    elif args.command == "review-owner":
        review_owner(args.repo, args.locale, args.message_id)
    elif args.command == "export":
        export_catalog(args.app, args.repo)
    elif args.command == "import":
        import_catalog(args.app, args.repo, args.revision, args.locale)
    elif args.command == "generate":
        generate(args.app, args.preview_repo, args.preview_locale)


if __name__ == "__main__":
    try:
        main()
    except (ValueError, OSError, subprocess.CalledProcessError) as error:
        sys.exit(str(error))
