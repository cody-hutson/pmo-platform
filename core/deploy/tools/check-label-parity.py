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
(ADR-070 D2). The canonical set is therefore the UNION across:
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

--emit-fix (read-only repair renderer): the diff above reports that a declared row
is absent; nothing in the corpus CREATES it, so the declared->live materialization
step had no owner and no implementation. `--emit-fix` renders the `gh label` commands
that would close the gap and runs none of them, in three blocks: CREATE (declared,
absent), RECONCILE (live but colour/description diverged), UNRESOLVABLE (declared
with no colour — not emittable, since a colourless create takes GitHub's default grey
and re-creates the drift). It is a separate boolean flag, NOT an --output-format
value, because deploy.sh Check 51 pins `--output-format tsv` and parses that shape.
Note the asymmetry it exposes: the MISSING/ORPHAN diff compares NAMES ONLY, so a row
that exists live with the wrong colour is invisible to the gate and visible only here.

Exit codes (the check-doc-links.py / check-skill-count-imp.py family convention):
  0  parity clean (or, under --emit-fix, nothing to emit)
  1  finding(s) — MISSING and/or ORPHAN (or, under --emit-fix, ≥1 emittable row)
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

# The keys parse_toml_label_rows collects from a `[[labels]]` entry. Deliberately
# narrower than the row's full key set: `group`, `applied_at` and `removed_at` are
# documentation facets with no live GitHub counterpart, so emitting them would
# invent a diff that the label API cannot express.
_TOML_ROW_KV_RE = re.compile(r'^\s*(name|color|description)\s*=\s*"(.*)"\s*$')


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


def parse_toml_label_rows(source_text):
    """SIBLING of parse_toml_labels: full `[[labels]]` ROWS, not just names.

    parse_toml_labels answers "which names are declared?" — the only question the
    MISSING/ORPHAN diff asks, and its signature is pinned by that caller. The emit
    path asks a strictly larger question ("what should this label LOOK like?"), so
    it needs `color` and `description` alongside the name. Widening the existing
    parser's return type would break its caller and its fixture; this sibling
    carries the wider shape and leaves that contract untouched.

    Returns {name: {"color": str|None, "description": str}}. A row with no `color`
    key yields color=None — the emit path reports those as UNRESOLVABLE rather than
    guessing, because a colourless create would silently take GitHub's default and
    reintroduce the very drift this flag exists to close.
    """
    rows = {}
    cur = None
    in_labels = False
    for line in source_text.splitlines():
        if _TOML_LABELS_HDR_RE.match(line):
            in_labels = True
            cur = {"color": None, "description": ""}
            continue
        if _TOML_TABLE_HDR_RE.match(line):
            in_labels = False
            cur = None
            continue
        if in_labels and cur is not None:
            kv = _TOML_ROW_KV_RE.match(line)
            if not kv:
                continue
            key, val = kv.group(1), kv.group(2)
            if key == "name":
                rows[val.strip()] = cur
            else:
                cur[key] = val
    return rows


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


def fetch_live_label_rows():
    """SIBLING of fetch_live_labels: live rows with color + description.

    fetch_live_labels returns names only, which is all diff_parity consumes. The
    emit path additionally needs the live color/description to tell an ABSENT row
    (create) from a DIVERGED one (edit). Same `gh label list` invocation and the
    same fail-loud contract; only the requested field set widens.

    Returns {name: {"color": str, "description": str}}.
    """
    res = subprocess.run(
        ["gh", "label", "list", "--limit", "500", "--json", "name,color,description"],
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        raise RuntimeError(f"gh label list failed: {res.stderr.strip()[:200]}")
    return {
        row["name"]: {
            "color": (row.get("color") or ""),
            # GitHub returns null for a label created with no description; the
            # declaration side uses "" for the same state. Normalise so the two
            # compare equal instead of reporting a phantom divergence.
            "description": (row.get("description") or ""),
        }
        for row in json.loads(res.stdout)
    }


def diff_declarations(declared_rows, live_rows):
    """Emit-path classifier. Read-only; returns three sorted lists.

    absent       declared name with no live counterpart          -> create
    diverged     live, but color and/or description differ       -> edit
    unresolvable declared with no color                          -> neither

    This is DELIBERATELY NOT part of diff_parity. The MISSING/ORPHAN verdicts that
    Check 51 consumes compare NAMES ONLY, and that logic is correct for what it
    asserts — a name-level registry reconciliation. Colour/description divergence is
    a strictly separate finding class that the gate does not (and here still does
    not) enforce; folding it into diff_parity would change what an existing green
    check means. The emit path reports it; the gate's verdict is unchanged.
    """
    absent, diverged, unresolvable = [], [], []
    for name in sorted(declared_rows):
        want = declared_rows[name]
        if want.get("color") in (None, ""):
            unresolvable.append(name)
            continue
        if name not in live_rows:
            absent.append(name)
            continue
        have = live_rows[name]
        if (have["color"].lower() != want["color"].lower()
                or have["description"] != want.get("description", "")):
            diverged.append(name)
    return absent, diverged, unresolvable


def _shq(s):
    """Single-quote a value for safe paste into a POSIX shell."""
    return "'" + str(s).replace("'", "'\\''") + "'"


def render_emit_fix(declared_rows, live_rows):
    """Render the READ-ONLY repair script. Returns (lines, actionable_count).

    Emits commands; never runs them. The two blocks are kept separate on purpose:
    creating an absent row is additive and safe, whereas editing a diverged row
    OVERWRITES live metadata that a human may have set deliberately. An operator
    must be able to run the first block without being led into the second.
    """
    absent, diverged, unresolvable = diff_declarations(declared_rows, live_rows)
    out = []
    out.append("# check-label-parity.py --emit-fix — READ-ONLY. Nothing below has been run.")
    out.append("# Review, then paste the block(s) you want. Label creation is repository")
    out.append("# STATE, not repository CONTENT: `git revert` cannot undo it (see the")
    out.append("# release rollback protocol — deletion is a separate, manual step).")
    out.append("")
    out.append(f"# --- CREATE: declared row absent from the live set ({len(absent)}) ---")
    if not absent:
        out.append("#   (none)")
    for n in absent:
        r = declared_rows[n]
        out.append(
            f"gh label create {_shq(n)} --color {_shq(r['color'])} "
            f"--description {_shq(r.get('description', ''))}"
        )
    out.append("")
    out.append(f"# --- RECONCILE: live row diverges from its declaration ({len(diverged)}) ---")
    out.append("#   REVIEW FIRST — each line OVERWRITES live label metadata. A live value")
    out.append("#   that differs may be a deliberate operator override rather than drift;")
    out.append("#   the gate cannot tell the two apart, so a human decides per row.")
    if not diverged:
        out.append("#   (none)")
    for n in diverged:
        r, have = declared_rows[n], live_rows[n]
        out.append(
            f"#   live: color={have['color']} description={have['description']!r}"
        )
        out.append(
            f"gh label edit {_shq(n)} --color {_shq(r['color'])} "
            f"--description {_shq(r.get('description', ''))}"
        )
    out.append("")
    out.append(f"# --- UNRESOLVABLE: declared row carries no colour ({len(unresolvable)}) ---")
    out.append("#   Not emitted: a create with no --color silently takes GitHub's default")
    out.append("#   grey, which is the drift this flag exists to close. Fix the declaration.")
    if not unresolvable:
        out.append("#   (none)")
    for n in unresolvable:
        out.append(f"#   {n}")
    return out, len(absent) + len(diverged) + len(unresolvable)


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

    ok = _self_test_emit_fix() and ok

    print("self-test: PASS" if ok else "self-test: FAIL")
    return 0 if ok else 1


def _self_test_emit_fix():
    """Fixture suite for the --emit-fix siblings. Independent of the assertions
    above by construction: it exercises parse_toml_label_rows / diff_declarations /
    render_emit_fix and asserts nothing about the name-only parsers."""
    ok = True

    fixture = (
        "[meta]\n"
        'name = "should-not-be-collected"\n'
        "\n"
        "[[labels]]\n"
        'group = "status"\n'
        'name = "status: absent"\n'
        'color = "0E8A16"\n'
        'description = "declared, never created"\n'
        "\n"
        "[[labels]]\n"
        'group = "status"\n'
        'name = "status: diverged"\n'
        'color = "FEF2C0"\n'
        'description = "declared text"\n'
        "\n"
        "[[labels]]\n"
        'group = "status"\n'
        'name = "status: clean"\n'
        'color = "0052CC"\n'
        'description = "matches live"\n'
        "\n"
        "[[labels]]\n"
        'group = "status"\n'
        'name = "status: colourless"\n'
        'description = "no colour key"\n'
    )
    rows = parse_toml_label_rows(fixture)
    if set(rows) != {"status: absent", "status: diverged", "status: clean",
                     "status: colourless"}:
        print(f"FAIL row parse names: {sorted(rows)}")
        ok = False
    if rows.get("status: absent", {}).get("color") != "0E8A16":
        print("FAIL row parse: color not captured")
        ok = False
    if rows.get("status: colourless", {}).get("color") is not None:
        print("FAIL row parse: colourless row should yield color=None")
        ok = False

    live = {
        # same name, DIFFERENT colour and description -> diverged
        "status: diverged": {"color": "ededed", "description": ""},
        # byte-identical -> clean, must NOT appear in any bucket
        "status: clean": {"color": "0052CC", "description": "matches live"},
    }
    absent, diverged, unresolvable = diff_declarations(rows, live)
    if absent != ["status: absent"]:
        print(f"FAIL absent: {absent}")
        ok = False
    if diverged != ["status: diverged"]:
        print(f"FAIL diverged: {diverged}")
        ok = False
    if unresolvable != ["status: colourless"]:
        print(f"FAIL unresolvable: {unresolvable}")
        ok = False

    # Colour comparison is case-insensitive (packs mix `0052cc` and `0052CC`);
    # a case-only difference must NOT be reported as drift.
    if diff_declarations(
        {"x": {"color": "AABBCC", "description": ""}},
        {"x": {"color": "aabbcc", "description": ""}},
    )[1]:
        print("FAIL: case-only colour difference reported as diverged")
        ok = False

    # A live null description normalises to "" and must match a declaration that
    # omits `description` — otherwise every such row reports a phantom divergence.
    if diff_declarations(
        {"x": {"color": "AABBCC"}},
        {"x": {"color": "AABBCC", "description": ""}},
    )[1]:
        print("FAIL: absent-description declaration reported as diverged")
        ok = False

    lines, actionable = render_emit_fix(rows, live)
    text = "\n".join(lines)
    if actionable != 3:
        print(f"FAIL actionable count: {actionable} want 3")
        ok = False
    if "gh label create 'status: absent' --color '0E8A16'" not in text:
        print("FAIL: create line not rendered")
        ok = False
    if "gh label edit 'status: diverged' --color 'FEF2C0'" not in text:
        print("FAIL: edit line not rendered")
        ok = False
    # The clean row is the specificity control: it is present in a non-empty input
    # and must generate NO command of either kind.
    if "status: clean'" in text:
        print("FAIL: clean row emitted a command")
        ok = False
    # The colourless row is reported, but only as a comment — never as a command.
    if "gh label create 'status: colourless'" in text:
        print("FAIL: colourless row emitted a create")
        ok = False
    # Quoting must survive an embedded apostrophe.
    q = _shq("it's")
    if q != "'it'\\''s'":
        print(f"FAIL shell quoting: {q}")
        ok = False

    return ok


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
        "--emit-fix",
        action="store_true",
        help=(
            "READ-ONLY: print the gh commands that would reconcile the live label set "
            "to the declarations (create absent rows, edit diverged ones). Runs nothing. "
            "A separate boolean flag rather than an --output-format value, because "
            "deploy.sh Check 51 pins --output-format tsv and parses that shape."
        ),
    )
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

    # --emit-fix is a distinct read-only MODE: it reports what the live set would
    # need in order to match the declarations, which is a strictly wider question
    # than the name-level MISSING/ORPHAN diff below. It re-reads the .toml sources
    # through the row parser (the name-only union above cannot answer it) and never
    # touches the gate's verdict path.
    if args.emit_fix:
        declared_rows = {}
        for src in sources:
            if not src.lower().endswith(".toml"):
                continue
            with open(src, encoding="utf-8") as fh:
                declared_rows.update(parse_toml_label_rows(fh.read()))
        if not declared_rows:
            print(
                f"parsed zero declared label rows from the .toml source(s) of "
                f"{len(sources)} --source arg(s) — registry moved/renamed?",
                file=sys.stderr,
            )
            return 3
        try:
            live_rows = fetch_live_label_rows()
        except Exception as e:  # noqa: BLE001 - fail-loud, same contract as the gate path
            print(f"cannot read live label set: {e}", file=sys.stderr)
            return 3
        lines, actionable = render_emit_fix(declared_rows, live_rows)
        print("\n".join(lines))
        return 1 if actionable else 0

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
