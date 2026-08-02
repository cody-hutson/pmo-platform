#!/usr/bin/env python3
"""Unresolved release-version token gate for deploy.sh Check 63.

`claim-version.sh` resolves `{{RELEASE_VERSION}}` at the Stage-12 claim, but its
`_stamp_release_identity()` pass covers only the pre-claim release plan and the
files named in explicit `--stamp-file` arguments. Every other tracked carrier of
the token depends entirely on the operator remembering to name it. Nothing
verified that they had been, so a canonical artifact could ship with a literal
`{{RELEASE_VERSION}}` in a field a downstream consumer reads as a version.

This check closes that gap PRE-MERGE: any tracked file carrying an unresolved
token, other than the release plan itself and the adjudicated documented-mention
allowlist, is a finding. It asserts an ABSENCE, so it fails closed everywhere —
an unreadable file, a missing allowlist, an unavailable git index, or a zero-file
scan all exit 3 rather than reading green. An absence gate that cannot enumerate
its population has not verified the absence; it has only failed to observe it.

**Why the release plan is excluded structurally rather than by allowlist.** The
plan is the token's sanctioned pre-claim home — ADR-092 makes the unresolved
token the plan's claim-state oracle, and deploy.sh Check 59 reads it as exactly
that. Allowlisting it would make the exclusion look like an adjudicated exception
when it is a property of the identity model.

**Why documented mentions are an allowlist rather than a pattern exemption.** The
token appears in governance prose, ADR-092, tooling source, historical RELEASE_LOG
rows, and the release-plan template, where it is the SUBJECT rather than an
instance awaiting substitution. No lexical property separates a mention from an
instance — `version: {{RELEASE_VERSION}}` in a template and the same string quoted
in a protocol doc are lexically identical. So the split is adjudicated per path and
recorded, and a NEW carrier fails closed until someone either stamps it or writes
down why it is a mention. That default is the point of the gate.

Exit codes: 0 = clean (no unresolved token outside the plan and the allowlist),
1 = finding(s), 3 = input/context failure (git unavailable, allowlist unreadable,
unreadable tracked file, or an empty scan — fail-loud per the Check 20/57/58/59
convention).

Usage:
    python3 core/deploy/tools/check-release-version-tokens.py [--root .]
    python3 core/deploy/tools/check-release-version-tokens.py --output-format tsv
    python3 core/deploy/tools/check-release-version-tokens.py --self-test
"""
from __future__ import annotations

import argparse
import os
import subprocess
import sys

# Byte-oriented so text and binary tracked files scan through one path with no
# decode step: a decode failure on a legitimately-binary tracked file would
# otherwise force a skip, and a skip inside an absence gate is a silent pass.
CLAIM_TOKEN = b"{{RELEASE_VERSION}}"

ALLOWLIST = "core/deploy/allowlists/skip-release-version-token-check.txt"
# The token's sanctioned pre-claim home (ADR-092 claim-state oracle), excluded by
# the predicate rather than adjudicated as an exception.
PLAN_DIR = "release/releases/plans/"
PLAN_SUFFIX = "_RELEASE_PLAN.md"

EXIT_CLEAN = 0
EXIT_FINDING = 1
EXIT_CONTEXT = 3


def is_release_plan(path: str) -> bool:
    """The pre-claim plan is the token's home; a plan at any plans/ depth qualifies."""
    return path.startswith(PLAN_DIR) and path.endswith(PLAN_SUFFIX)


def evaluate(carriers, allowlist):
    """Pure predicate over already-resolved inputs — the --self-test surface.

    carriers:  iterable of (path, occurrence_count) for tracked files holding the token
    allowlist: set of adjudicated documented-mention paths
    Returns (exit_code, message, findings) where findings is [(path, count), ...].
    """
    findings = []
    for path, count in sorted(carriers):
        if is_release_plan(path):
            continue
        if path in allowlist:
            continue
        findings.append((path, count))
    if not findings:
        return EXIT_CLEAN, "CLEAN no unresolved {{RELEASE_VERSION}} outside the release plan", []
    total = sum(c for _, c in findings)
    return (
        EXIT_FINDING,
        "FAIL %d unresolved {{RELEASE_VERSION}} token(s) in %d tracked file(s) "
        "outside the release plan" % (total, len(findings)),
        findings,
    )


def load_allowlist(root: str):
    """Read the adjudicated documented-mention paths. Missing/unreadable = fail-closed."""
    path = os.path.join(root, ALLOWLIST)
    if not os.path.isfile(path):
        raise OSError("allowlist missing: %s" % ALLOWLIST)
    entries = set()
    with open(path, "r", encoding="utf-8") as handle:
        for line in handle:
            line = line.strip()
            if line and not line.startswith("#"):
                entries.add(line)
    return entries


def scan(root: str):
    """Enumerate tracked files and byte-scan each for the token. Fail-closed on IO."""
    out = subprocess.run(
        ["git", "-C", root, "ls-files", "-z"],
        capture_output=True,
        check=True,
    )
    tracked = [p for p in out.stdout.split(b"\0") if p]
    if not tracked:
        raise OSError("git ls-files returned zero tracked files — population unverifiable")
    carriers = []
    for raw in tracked:
        rel = raw.decode("utf-8", "surrogateescape")
        full = os.path.join(root, rel)
        if not os.path.isfile(full):  # submodule entry or a delete staged in the index
            continue
        with open(full, "rb") as handle:
            blob = handle.read()
        count = blob.count(CLAIM_TOKEN)
        if count:
            carriers.append((rel, count))
    return carriers, len(tracked)


def run_main(root: str, output_format: str) -> int:
    try:
        allowlist = load_allowlist(root)
        carriers, scanned = scan(root)
    except (subprocess.CalledProcessError, FileNotFoundError, OSError) as exc:
        # Every input failure lands here: an absence is not established by a scan
        # that did not complete, so this is exit 3 and never a clean read.
        print("CONTEXT-FAIL: cannot establish the token population (%s)" % exc)
        return EXIT_CONTEXT
    code, msg, findings = evaluate(carriers, allowlist)
    if output_format == "tsv":
        print("VERDICT\t%s" % msg.split(" ", 1)[0])
        print("SCANNED\t%d" % scanned)
        print("CARRIERS\t%d" % len(carriers))
        print("FINDINGS\t%d" % len(findings))
        for path, count in findings:
            print("UNRESOLVED\t%s\t%d" % (path, count))
    else:
        print(msg)
        for path, count in findings:
            print("  %s (%d occurrence(s))" % (path, count))
    return code


# ---------------------------------------------------------------------------
# Self-test — fixtures over the pure predicate (the Stage-7 DevTest surface)
# ---------------------------------------------------------------------------
def run_self_test() -> int:
    allow = {"release/tools/claim-version.sh"}
    # (label, carriers, expected_exit, expected_finding_count)
    fixtures = [
        ("no carriers at all", [], EXIT_CLEAN, 0),
        ("only the pre-claim release plan carries it",
         [("release/releases/plans/widget_RELEASE_PLAN.md", 3)], EXIT_CLEAN, 0),
        ("a versioned plan under a year subdir still counts as the plan",
         [("release/releases/plans/v3/v3.60_RELEASE_PLAN.md", 1)], EXIT_CLEAN, 0),
        ("only an allowlisted documented mention",
         [("release/tools/claim-version.sh", 17)], EXIT_CLEAN, 0),
        ("an unstamped canonical template — THE defect this gate exists for",
         [("operations/templates/raci-template.md", 2)], EXIT_FINDING, 1),
        ("template finding survives alongside plan + allowlist carriers",
         [("operations/templates/raci-template.md", 2),
          ("release/tools/claim-version.sh", 17),
          ("release/releases/plans/widget_RELEASE_PLAN.md", 3)], EXIT_FINDING, 1),
        ("a NEW unadjudicated carrier fails closed rather than being assumed a mention",
         [("core/standards/some-new-standard.md", 1)], EXIT_FINDING, 1),
        ("a near-name file that is NOT a plan is not exempted",
         [("release/releases/plans/README.md", 2)], EXIT_FINDING, 1),
    ]
    failures = 0
    for label, carriers, expected, expected_n in fixtures:
        code, msg, findings = evaluate(carriers, allow)
        ok = code == expected and len(findings) == expected_n
        if not ok:
            failures += 1
        print("  [%s] %s: exit %d (expected %d), %d finding(s) (expected %d)"
              % ("PASS" if ok else "FAIL", label, code, expected, len(findings), expected_n))
    if failures:
        print("check-release-version-tokens.py --self-test: FAIL (%d fixture(s))" % failures)
        return EXIT_FINDING
    print("check-release-version-tokens.py --self-test: PASS (%d fixtures; the plan and the "
          "adjudicated allowlist are exempt, every other carrier fails closed)" % len(fixtures))
    return EXIT_CLEAN


def main(argv) -> int:
    ap = argparse.ArgumentParser(
        description="Unresolved release-version token gate (deploy.sh Check 63).")
    ap.add_argument("--root", default=".", help="repo root (default: cwd)")
    ap.add_argument("--output-format", default="text", choices=("text", "tsv"),
                    help="text (human) or tsv (deploy.sh parses this)")
    ap.add_argument("--self-test", action="store_true", help="run the embedded fixture harness")
    args = ap.parse_args(argv)
    if args.self_test:
        return run_self_test()
    return run_main(args.root, args.output_format)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
