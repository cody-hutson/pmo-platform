#!/usr/bin/env python3
"""Label-taxonomy <-> GitHub label-set parity primitive [#749].

deploy.sh Check 51's scan engine. Parses the canonical label registry from one or
more --source files and compares the UNION to the live GitHub label set
(`gh label list`), emitting two asymmetric-severity directions:

  MISSING  a canonical label is absent from GitHub  -> ENFORCE-capable (the #457
           `status: rejected` defect class: a gate referencing a non-existent
           label fails silently).
  ORPHAN   a live GitHub label is not registered in the taxonomy  -> WARN only
           (some are legitimately operator-local or pending registration).

Source-agnostic + multi-source (the #1970 per-pack restructure): --source is
repeatable. After #1970 the concrete label ROWS moved out of
core/specs/label-taxonomy.md (which keeps the GRAMMAR — group definitions, rules,
and namespace PATTERNS) into the per-pack `[[labels]]` facets under core/packs/*
(ADR-069 D2). The canonical set is therefore the UNION across:
  - the grammar doc (label-taxonomy.md) — namespace patterns + any retained rows;
  - the selected packs' `pack.toml` `[[labels]]` blocks — the relocated concrete rows.
deploy.sh Check 51 passes `--source label-taxonomy.md` plus the `core/packs/*/pack.toml`
set so a relocated-but-still-live label resolves in the pack union and does not
false-orphan. Two per-source formats are auto-detected by extension: `.md` reads
label-definition table rows; `.toml` reads `[[labels]]` `name = "..."` entries.

Concrete-enum vs namespace-pattern (the R4 nuance): most labels are a concrete
enumerated set (category, `status:*`, `cluster:*`, `triage:*`, disposition); a few
are a namespace PATTERN with examples (`project:*`, `epic:*`, `type:*`). A live
label is an ORPHAN only if it matches neither a concrete registered label nor a
registered namespace prefix. The markdown parser keys on label-definition table
rows (col-2 is a backticked hex color), which structurally excludes the
`## Removed Labels` table (col-2 is prose) and header/separator rows. Title-prefix
parity (the #74 `[Observation]:` invariant) is a SEPARATE concern, NOT evaluated
here.

Exit codes (the check-doc-links.py / check-skill-count-imp.py family convention):
  0  parity clean
  1  finding(s) — MISSING and/or ORPHAN
  2  argument / input error
  3  a --source was unreadable OR the union parsed to zero canonical labels OR the
     live set was unreadable (fail-loud: a relocated/renamed registry must not read
     green). A single readable-but-empty source is tolerated as long as the union
     is non-empty (e.g. a pack with no [[labels]] block yet).

Ships warn-mode-initial; deploy.sh Check 51 downgrades exit 1 per
core/rules/bypass-mode-readiness.md during the shakedown window. Authored under
the v3.28 Stage-5 spec (#749); multi-source union added under #1970.
"""
from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys

# Namespaces registered as a PATTERN (examples, not an exhaustive enum). A live
# label under one of these prefixes is NOT an orphan. `type:*` is the work-item-kind
# category family: the grammar doc documents it as a namespace pattern (like
# project:*/epic:*) and the packs contribute concrete `type:<kind_id>` rows via
# `projects_kind` — so any live `type:*` resolves as a pattern match (#1970 FM-2).
REGISTERED_NAMESPACES = ("project:", "epic:", "type:")

# A label-definition table data row: | `label` | `hexcolor` (name) | ...
# Requiring a backticked 3/6-hex in col-2 pins the match to the label tables and
# excludes the `## Removed Labels` table (col-2 = prose reason), headers, and
# separators.
_ROW_RE = re.compile(r"^\s*\|\s*`([^`]+)`\s*\|\s*`[0-9a-fA-F]{3,6}`")

# A pack.toml `[[labels]]` name assignment. Minimal, dependency-free extraction
# (no tomllib on py3.9, and this check must stay green without an optional TOML
# lib): within the file we scan for `name = "..."` lines that sit under a
# `[[labels]]` array-of-tables header. Keying the scan to the [[labels]] section
# excludes the pack's `[meta]`/`[[kinds]]` `name`-like keys.
_TOML_LABELS_HDR_RE = re.compile(r"^\s*\[\[labels\]\]\s*$")
_TOML_TABLE_HDR_RE = re.compile(r"^\s*\[")
_TOML_NAME_RE = re.compile(r'^\s*name\s*=\s*"([^"]+)"')


def parse_md_labels(source_text):
    """Concrete labels + namespace-pattern rows from a label-taxonomy-style .md."""
    concrete = set()
    for line in source_text.splitlines():
        m = _ROW_RE.match(line)
        if not m:
            continue
        token = m.group(1).strip()
        if "*" in token:  # namespace PATTERN row (e.g. `project:*`, `epic:*`, `type:*`)
            continue
        concrete.add(token)
    return concrete


def parse_toml_labels(source_text):
    """Concrete label `name`s from a pack.toml `[[labels]]` array-of-tables.

    Dependency-free: tracks whether the current TOML table is a `[[labels]]` entry
    and collects each entry's `name = "..."`. Any other table header (`[meta]`,
    `[[kinds]]`, `[kinds.criteria.readiness]`, ...) closes the labels context so a
    `name` key elsewhere is not miscollected.
    """
    concrete = set()
    in_labels = False
    for line in source_text.splitlines():
        if _TOML_LABELS_HDR_RE.match(line):
            in_labels = True
            continue
        if _TOML_TABLE_HDR_RE.match(line):
            # some other table header ([meta], [[kinds]], [kinds.x], ...)
            in_labels = False
            continue
        if in_labels:
            nm = _TOML_NAME_RE.match(line)
            if nm:
                concrete.add(nm.group(1).strip())
    return concrete


def parse_source(path, source_text):
    """Dispatch by extension: .toml -> [[labels]] names; else -> md table rows."""
    if path.lower().endswith(".toml"):
        return parse_toml_labels(source_text)
    return parse_md_labels(source_text)


def parse_canonical_labels(source_text):
    """Back-compat single-source (markdown) entrypoint.

    Retained for the self-test and any caller passing one doc's text. Returns
    (concrete_labels:set, namespace_prefixes:tuple). Multi-source callers use
    parse_source per file and union the concrete sets.
    """
    return parse_md_labels(source_text), REGISTERED_NAMESPACES


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
    ok = True

    # --- Markdown grammar-doc parse (post-#1970 the doc keeps grammar + patterns;
    #     the concrete status/cluster ROWS below stand in for any retained rows).
    md_fixture = (
        "### Category Labels\n"
        "| Label | Color | Description | Applied At |\n"
        "|---|---|---|---|\n"
        "| `improvement` | `0E8A16` (green) | x | y |\n"
        "### Initiative Labels\n"
        "| `project:*` | `0052CC` (blue) / per-label | x | y |\n"
        "| `epic:*` | `5319e7` (purple) | x | y |\n"
        "### Work-Item-Kind Labels\n"
        "| `type:*` | per-kind | x | y |\n"
        "## Removed Labels\n"
        "| Label | Reason |\n"
        "| `good first issue` | Single-operator platform |\n"
    )
    md_concrete = parse_md_labels(md_fixture)
    # Namespace-pattern rows (project:*/epic:*/type:*) and the Removed table are
    # excluded; only `improvement` is a concrete row.
    if md_concrete != {"improvement"}:
        print(f"FAIL md parse: got {sorted(md_concrete)} want ['improvement']")
        ok = False

    # --- TOML pack `[[labels]]` parse (the relocated concrete rows).
    toml_fixture = (
        "[meta]\n"
        'pack_id = "_common"\n'
        'name = "should-not-be-collected"\n'   # a name key OUTSIDE [[labels]]
        "\n"
        "[[labels]]\n"
        'group = "status"\n'
        'name = "status: rejected"\n'
        'color = "D93F0B"\n'
        "\n"
        "[[labels]]\n"
        'group = "cluster"\n'
        'name = "cluster: security"\n'
        "\n"
        "[[kinds]]\n"
        'kind_id = "story"\n'
        'name = "also-not-a-label"\n'          # a name key under [[kinds]]
    )
    toml_concrete = parse_toml_labels(toml_fixture)
    want_toml = {"status: rejected", "cluster: security"}
    if toml_concrete != want_toml:
        print(f"FAIL toml parse: got {sorted(toml_concrete)} want {sorted(want_toml)}")
        ok = False

    # --- Union + diff. Concrete = md ∪ toml; a live `type:bug`/`project:foo`
    #     resolves via a registered namespace (NOT orphan); `zz-orphan` orphans;
    #     a canonical row absent from live (`cluster: security`) is MISSING.
    concrete = md_concrete | toml_concrete
    ns = REGISTERED_NAMESPACES
    live = {"improvement", "status: rejected", "project:foo", "type:bug", "zz-orphan"}
    missing, orphan = diff_parity(concrete, ns, live)
    if missing != ["cluster: security"]:
        print(f"FAIL missing: {missing}")
        ok = False
    # type:bug now resolves under the registered `type:` namespace (#1970 FM-2) —
    # only zz-orphan is a true orphan.
    if orphan != ["zz-orphan"]:
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
        action="append",
        default=None,
        help=(
            "canonical label registry; repeatable (#1970 multi-source union). "
            ".md reads label-table rows; .toml reads [[labels]] name entries. "
            "Default: core/specs/label-taxonomy.md."
        ),
    )
    ap.add_argument("--output-format", choices=("tsv", "text"), default="tsv")
    ap.add_argument(
        "--self-test", action="store_true", help="run the fixture suite; no gh/source needed"
    )
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    sources = args.source or ["core/specs/label-taxonomy.md"]

    # Union the concrete labels across every --source. A single readable-but-empty
    # source is tolerated (e.g. a pack with no [[labels]] yet); the union being
    # empty is the fail-loud condition (registry moved/renamed).
    concrete = set()
    for src in sources:
        try:
            with open(src, encoding="utf-8") as fh:
                source_text = fh.read()
        except OSError as e:
            print(f"source unreadable: {src}: {e}", file=sys.stderr)
            return 3
        concrete |= parse_source(src, source_text)

    namespaces = REGISTERED_NAMESPACES
    if not concrete:
        print(
            f"parsed zero canonical labels from {len(sources)} source(s) "
            f"({', '.join(sources)}) — registry moved/renamed?",
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
