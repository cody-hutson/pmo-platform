#!/usr/bin/env python3
"""Label-taxonomy <-> GitHub label-set parity primitive [#749].

deploy.sh Check 51's scan engine. Parses the canonical label registry from
core/specs/label-taxonomy.md (the --source, repointable for the #1970
per-pack restructure) and compares it to the live GitHub label set
(`gh label list`), emitting two asymmetric-severity directions:

  MISSING  a canonical label is absent from GitHub  -> ENFORCE-capable (the #457
           `status: rejected` defect class: a gate referencing a non-existent
           label fails silently).
  ORPHAN   a live GitHub label is not registered in the taxonomy  -> WARN only
           (some are legitimately operator-local or pending registration, e.g.
           the `type:*` family until #1777 documents it).

Source-agnostic: the canonical set is read from --source (default the doc); when
#1970 moves the per-pack label lists to core/packs/*, repoint --source — this
primitive is unchanged.

Concrete-enum vs namespace-pattern (the R4 nuance): the doc registers most
labels as a concrete enumerated set (category, `status:*`, `cluster:*`,
`triage:*`, the disposition labels) and a few as a namespace PATTERN with
examples (`project:*`, `epic:*`). A live label is an ORPHAN only if it matches
neither a concrete registered label nor a registered namespace prefix. The
parser keys on label-definition table rows (col-2 is a backticked hex color),
which structurally excludes the `## Removed Labels` table (col-2 is prose) and
header/separator rows. Title-prefix parity (the #74 `[Observation]:` invariant)
is a SEPARATE concern and is NOT evaluated here.

Exit codes (the check-doc-links.py / check-skill-count-imp.py family convention):
  0  parity clean
  1  finding(s) — MISSING and/or ORPHAN
  2  argument / input error
  3  --source unreadable OR parsed to zero canonical labels OR the live set was
     unreadable (fail-loud: a relocated/renamed registry must not read green)

Ships warn-mode-initial; deploy.sh Check 51 downgrades exit 1 per
core/rules/bypass-mode-readiness.md during the shakedown window. Authored under
the v3.28 Stage-5 spec (#749).
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys

# Namespaces the doc registers as a PATTERN (examples, not an exhaustive enum).
# A live label under one of these prefixes is NOT an orphan.
REGISTERED_NAMESPACES = ("project:", "epic:")

# A label-definition table data row: | `label` | `hexcolor` (name) | ...
# Requiring a backticked 3/6-hex in col-2 pins the match to the label tables and
# excludes the `## Removed Labels` table (col-2 = prose reason), headers, and
# separators.
_ROW_RE = re.compile(r"^\s*\|\s*`([^`]+)`\s*\|\s*`[0-9a-fA-F]{3,6}`")


def parse_canonical_labels(source_text):
    """Return (concrete_labels:set, namespace_prefixes:tuple) registered by --source."""
    concrete = set()
    for line in source_text.splitlines():
        m = _ROW_RE.match(line)
        if not m:
            continue
        token = m.group(1).strip()
        if "*" in token:  # namespace PATTERN row (e.g. `project:*`, `epic:*`)
            continue
        concrete.add(token)
    return concrete, REGISTERED_NAMESPACES


def fetch_live_labels():
    """Live GitHub label-name set via gh. Raises on gh failure (caller -> exit 3)."""
    res = subprocess.run(
        ["gh", "label", "list", "--limit", "500", "--json", "name"],
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        raise RuntimeError(f"gh label list failed: {res.stderr.strip()[:200]}")
    return {row["name"] for row in json.loads(res.stdout)}


def diff_parity(concrete, namespaces, live):
    """(missing, orphan) sorted lists. missing = canonical absent from live;
    orphan = live not in canonical and not under a registered namespace."""
    missing = sorted(c for c in concrete if c not in live)
    orphan = sorted(
        l for l in live
        if l not in concrete and not any(l.startswith(ns) for ns in namespaces)
    )
    return missing, orphan


def _self_test():
    fixture = (
        "### Category Labels\n"
        "| Label | Color | Description | Applied At |\n"
        "|---|---|---|---|\n"
        "| `improvement` | `0E8A16` (green) | x | y |\n"
        "| `status: rejected` | `D93F0B` (red) | x | y | z |\n"
        "### Cluster Labels\n"
        "| `cluster: security` | `BFDADC` (pale cyan) | x |\n"
        "### Initiative Labels\n"
        "| `project:*` | `0052CC` (blue) / per-label | x | y |\n"
        "## Removed Labels\n"
        "| Label | Reason |\n"
        "| `good first issue` | Single-operator platform |\n"
    )
    concrete, ns = parse_canonical_labels(fixture)
    want = {"improvement", "status: rejected", "cluster: security"}
    ok = True
    if concrete != want:
        print(f"FAIL parse: got {sorted(concrete)} want {sorted(want)}")
        ok = False
    # cluster: security canonical-but-absent -> MISSING; type:bug & zz-orphan ->
    # ORPHAN; project:foo under a registered namespace -> NOT orphan.
    live = {"improvement", "status: rejected", "project:foo", "type:bug", "zz-orphan"}
    missing, orphan = diff_parity(concrete, ns, live)
    if missing != ["cluster: security"]:
        print(f"FAIL missing: {missing}")
        ok = False
    if orphan != ["type:bug", "zz-orphan"]:
        print(f"FAIL orphan: {orphan}")
        ok = False
    print("self-test: PASS" if ok else "self-test: FAIL")
    return 0 if ok else 1


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="label-taxonomy <-> GitHub label-set parity [#749]"
    )
    ap.add_argument(
        "--source",
        default="core/specs/label-taxonomy.md",
        help="canonical label registry (repointable for the #1970 per-pack restructure)",
    )
    ap.add_argument("--output-format", choices=("tsv", "text"), default="tsv")
    ap.add_argument(
        "--self-test", action="store_true", help="run the fixture suite; no gh/source needed"
    )
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    try:
        with open(args.source, encoding="utf-8") as fh:
            source_text = fh.read()
    except OSError as e:
        print(f"source unreadable: {args.source}: {e}", file=sys.stderr)
        return 3

    concrete, namespaces = parse_canonical_labels(source_text)
    if not concrete:
        print(
            f"parsed zero canonical labels from {args.source} — registry moved/renamed?",
            file=sys.stderr,
        )
        return 3

    try:
        live = fetch_live_labels()
    except Exception as e:  # noqa: BLE001 - any gh/parse failure is fail-loud (exit 3)
        print(f"cannot read live label set: {e}", file=sys.stderr)
        return 3

    missing, orphan = diff_parity(concrete, namespaces, live)

    if args.output_format == "tsv":
        for m in missing:
            print(f"MISSING\t{m}")
        for o in orphan:
            print(f"ORPHAN\t{o}")
    else:
        if missing:
            print("MISSING (canonical label absent from GitHub):")
            for m in missing:
                print(f"  - {m}")
        if orphan:
            print("ORPHAN (GitHub label not registered in the taxonomy):")
            for o in orphan:
                print(f"  - {o}")
        if not missing and not orphan:
            print("label-taxonomy.md and the GitHub label set are in parity")

    return 1 if (missing or orphan) else 0


if __name__ == "__main__":
    sys.exit(main())
