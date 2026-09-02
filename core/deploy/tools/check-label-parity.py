#!/usr/bin/env python3
"""Label-taxonomy <-> GitHub label-set parity primitive [#749].

deploy.sh Check 51's scan engine. Parses the canonical label registry from one or
more --source files and compares the UNION to the live GitHub label set (the REST
labels endpoint, read via `gh api "repos/<slug>/labels?per_page=100" --paginate`),
emitting two asymmetric-severity directions:

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

Transport — REST, not GraphQL (#5058). The live set was previously read with
`gh label list`, which issues `POST /graphql` and therefore returns nothing once the
GraphQL quota is exhausted; the check then had to report exit 3 (indeterminate) even
though the label data was fully obtainable. GraphQL and REST are SEPARATE quota pools,
and quota exhaustion clusters precisely at release close-out — exactly when Check 51
runs. `gh label list` exposes no flag that selects transport, so the call is spelled as
`gh api` directly. This is an AVAILABILITY fix: the verdict logic, the TSV shape, and
the exit contract are unchanged; only the set of conditions that can force exit 3
shrinks. The repository slug is DERIVED (--repo, else `git remote origin`) and never
hardcoded — depersonalization gate, core/rules/git-workflow.md § Repository-Integrity
Gates — and the owner/name are spelled out rather than left as gh's placeholder form,
which core/config/allowlists/egress-allowlist.txt denies as an unresolvable authority.

Exit codes (the check-doc-links.py / check-skill-count-imp.py family convention):
  0  parity clean (or, under --emit-fix, nothing to emit)
  1  finding(s) — MISSING and/or ORPHAN (or, under --emit-fix, ≥1 emittable row)
  2  argument / input error
  3  a --source was unreadable OR the union parsed to zero canonical labels OR the
     live set was unreadable OR the repo slug was unresolvable OR the live set
     exceeded --max-labels (fail-loud: a relocated/renamed registry must not read
     green, and an over-large population must not silently truncate). A single
     readable-but-empty source is tolerated as long as the union is non-empty
     (e.g. a pack with no [[labels]] block yet).

Ships warn-mode-initial; deploy.sh Check 51 downgrades exit 1 per
core/rules/bypass-mode-readiness.md during the shakedown window. Authored under
the v3.28 Stage-5 spec (#749); multi-source union added under #1970.
"""
from __future__ import annotations

import argparse
import contextlib
import io
import json
import os
import re
import subprocess
import sys
import tempfile

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


DEFAULT_MAX_LABELS = 1000


def _derive_repo(explicit):
    """owner/name of the running clone's origin (fork-correct); never hardcode the
    operator handle (depersonalization gate). Returns None if unset and unresolved.

    Shape ported from check-work-hierarchy.py's sibling of the same name — the two
    deploy.sh Python checks that need a repo slug already spell it this way.
    """
    if explicit:
        return explicit
    try:
        url = subprocess.run(["git", "config", "--get", "remote.origin.url"],
                             capture_output=True, text=True).stdout.strip()
        m = re.search(r"[:/]([^/]+/[^/]+?)(?:\.git)?$", url)
        if m:
            return m.group(1)
    except Exception:  # noqa: BLE001 - unresolved slug is the caller's exit-3 case
        pass
    return None


def _iter_json_docs(text):
    """Yield each JSON document from a possibly-CONCATENATED stream.

    Shape ported from check-work-hierarchy.py's iter_json_docs. `gh --paginate`
    does NOT frame multi-page output uniformly across endpoint kinds: for a REST
    array endpoint it currently MERGES pages into one flat array, while for
    `gh api graphql` it emits one document per page with NO separator between
    them. Splitting on newlines therefore yields an unparseable blob the moment
    the framing is the latter, and the result silently reads as zero rows — a
    false-green. raw_decode walks either framing correctly.
    """
    decoder = json.JSONDecoder()
    idx, n = 0, len(text)
    while idx < n:
        while idx < n and text[idx].isspace():
            idx += 1
        if idx >= n:
            break
        obj, end = decoder.raw_decode(text, idx)
        yield obj
        idx = end


def parse_label_payload(text):
    """PURE + offline + total: normalise a `gh api ... --paginate` label payload.

    Deliberately tolerant of every framing `gh` may produce, so the check is not
    coupled to a `gh` version's array-merging behaviour (see _iter_json_docs):
      (a) a single merged JSON array of row objects  -> used as-is
      (b) concatenated per-page JSON documents       -> walked with raw_decode
      (c) a list of per-page lists (--slurp shape)   -> flattened one level

    Splitting fetch into "invoke" (the thin subprocess shell below) and "parse"
    (this function) is what makes the pagination arm testable: HTTP paging itself
    is gh's responsibility, but silent UNDER-READING can only happen here, so this
    is the half that carries fixture coverage. Returns a flat list of row dicts.
    """
    rows = []
    for doc in _iter_json_docs(text):
        if isinstance(doc, dict):
            rows.append(doc)
            continue
        if not isinstance(doc, list):
            raise RuntimeError(
                f"unexpected label payload element of type {type(doc).__name__}"
            )
        for item in doc:
            if isinstance(item, list):  # list-of-lists (--slurp framing)
                rows.extend(item)
            else:
                rows.append(item)
    for row in rows:
        if not isinstance(row, dict) or "name" not in row:
            raise RuntimeError("label payload row is not an object carrying `name`")
    return rows


def _enforce_label_bound(rows, max_labels):
    """Fail LOUD when the population exceeds the bound — never truncate.

    Replaces the previous `--limit 500`, which silently returned only the first 500
    labels: every unread canonical label would then report as a spurious MISSING,
    turning an availability guard into a correctness defect. Raising here lands on
    the caller's existing exit-3 ("live set unreadable") contract, mirroring the
    audit-epic-rollup-close.sh precedent of refusing rather than truncating.
    """
    if max_labels is not None and len(rows) > max_labels:
        raise RuntimeError(
            f"live label population ({len(rows)}) exceeds --max-labels ({max_labels}) "
            f"— raise the limit rather than silently truncating"
        )
    return rows


def _gh_labels_stdout(repo):
    """INVOKE half: raw stdout of the REST labels read. No parsing happens here.

    REST, not GraphQL (#5058): the GraphQL pool can be exhausted while this data is
    still fully served. `--jq` is deliberately NOT passed — it changes `--paginate`
    framing, which is precisely the coupling parse_label_payload exists to absorb.
    REST returns whole label objects, so no field selector is needed either.
    """
    res = subprocess.run(
        ["gh", "api", f"repos/{repo}/labels?per_page=100", "--paginate"],
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        raise RuntimeError(f"gh api repos/<slug>/labels failed: {res.stderr.strip()[:200]}")
    return res.stdout


def _live_label_rows(repo, max_labels=DEFAULT_MAX_LABELS, fixture=None):
    """Shared read path for both public fetchers: invoke -> parse -> bound.

    `fixture` injects a canned payload in place of the network leg (--fixture-labels),
    which is what lets the pagination arm be tested offline with no seeded labels.
    """
    if fixture is not None:
        with open(fixture, encoding="utf-8") as fh:
            text = fh.read()
    else:
        text = _gh_labels_stdout(repo)
    return _enforce_label_bound(parse_label_payload(text), max_labels)


def fetch_live_labels(repo, max_labels=DEFAULT_MAX_LABELS, fixture=None):
    """Live GitHub label-name set. Raises on failure (caller -> exit 3)."""
    return {row["name"] for row in _live_label_rows(repo, max_labels, fixture)}


def fetch_live_label_rows(repo, max_labels=DEFAULT_MAX_LABELS, fixture=None):
    """SIBLING of fetch_live_labels: live rows with color + description.

    fetch_live_labels returns names only, which is all diff_parity consumes. The
    emit path additionally needs the live color/description to tell an ABSENT row
    (create) from a DIVERGED one (edit). Same REST read and the same fail-loud
    contract; only the projected field set widens.

    Returns {name: {"color": str, "description": str}}.
    """
    return {
        row["name"]: {
            "color": (row.get("color") or ""),
            # GitHub returns null for a label created with no description; the
            # declaration side uses "" for the same state. Normalise so the two
            # compare equal instead of reporting a phantom divergence.
            "description": (row.get("description") or ""),
        }
        for row in _live_label_rows(repo, max_labels, fixture)
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
    ok = _self_test_rest_transport() and ok

    print("self-test: PASS" if ok else "self-test: FAIL")
    return 0 if ok else 1


def _run_main_captured(argv):
    """Drive main() end-to-end and capture its streams. Returns (exit_code, stdout).

    The fixture cases assert on the REAL exit code and the REAL emitted TSV rather
    than on an internal, so the self-test grades the contract deploy.sh consumes.
    Capturing also keeps the suite's own output readable — a self-test that prints a
    thousand fixture rows hides its own verdict.
    """
    out, err = io.StringIO(), io.StringIO()
    with contextlib.redirect_stdout(out), contextlib.redirect_stderr(err):
        rc = main(argv)
    return rc, out.getvalue()


def _labels_json(n, start=0):
    """n synthetic label row objects, as a JSON array string."""
    return json.dumps(
        [{"name": f"lbl-{i:04d}", "color": "ededed", "description": ""}
         for i in range(start, start + n)]
    )


def _self_test_rest_transport():
    """Fixture suite for the REST transport + pagination arm (#5058).

    Independent by construction of the two suites above: it exercises
    parse_label_payload / _enforce_label_bound and the --fixture-labels wiring, and
    asserts nothing about the taxonomy parsers. The pagination cases are the point —
    only the PARSE half can silently under-read, and a silent under-read reports
    every unread canonical label as a spurious MISSING.
    """
    ok = True

    # --- Case 1: >100 rows across CONCATENATED per-page documents (the framing
    #     `gh api graphql --paginate` is documented to emit). 3 pages: 100+100+50.
    concatenated = _labels_json(100, 0) + _labels_json(100, 100) + _labels_json(50, 200)
    got = len(parse_label_payload(concatenated))
    if got != 250:
        print(f"FAIL rest pagination (concatenated): parsed {got} want 250")
        ok = False

    # --- Case 2: the <100 CONTROL. AC-3 mandates it: a pagination fix that only
    #     works above the page boundary would break every normal-sized repository.
    got = len(parse_label_payload(_labels_json(80)))
    if got != 80:
        print(f"FAIL rest <100 control: parsed {got} want 80")
        ok = False

    # --- Case 3: single MERGED flat array (the framing gh currently emits for REST
    #     array endpoints). Same count, different framing — neither may under-read.
    got = len(parse_label_payload(_labels_json(250)))
    if got != 250:
        print(f"FAIL rest pagination (merged array): parsed {got} want 250")
        ok = False

    # --- Case 3b: list-of-lists (--slurp framing) flattens one level.
    got = len(parse_label_payload(json.dumps(
        [json.loads(_labels_json(100, 0)), json.loads(_labels_json(30, 100))]
    )))
    if got != 130:
        print(f"FAIL rest pagination (list-of-lists): parsed {got} want 130")
        ok = False

    # --- Case 4: the truncation SENTINEL. 1001 rows against --max-labels 1000 must
    #     exit 3, NOT return a quietly truncated pass. Driven end-to-end through
    #     main() so the assertion is on the real exit code, not on an internal.
    with tempfile.TemporaryDirectory() as td:
        src = os.path.join(td, "pack.toml")
        with open(src, "w", encoding="utf-8") as fh:
            fh.write('[[labels]]\nname = "lbl-0000"\ncolor = "ededed"\n')
        over = os.path.join(td, "over.json")
        with open(over, "w", encoding="utf-8") as fh:
            fh.write(_labels_json(1001))
        under = os.path.join(td, "under.json")
        with open(under, "w", encoding="utf-8") as fh:
            fh.write(_labels_json(999))
        empty = os.path.join(td, "empty.json")
        with open(empty, "w", encoding="utf-8") as fh:
            fh.write("[]")
        empty_src = os.path.join(td, "empty.toml")
        with open(empty_src, "w", encoding="utf-8") as fh:
            fh.write("[meta]\n")

        rc, out = _run_main_captured(["--source", src, "--fixture-labels", over,
                                      "--max-labels", "1000", "--output-format", "tsv"])
        if rc != 3:
            print(f"FAIL rest bound: 1001 rows vs --max-labels 1000 exited {rc} want 3")
            ok = False
        if out.strip():
            print("FAIL rest bound: emitted TSV rows instead of refusing")
            ok = False

        # SENSITIVITY control for the case above: the identical path one row UNDER
        # the bound must NOT exit 3, and must emit the full population. Without this
        # arm, "exit 3" would also pass if every fixture invocation failed for an
        # unrelated reason — a zero whose control also reads zero is a broken probe.
        rc, out = _run_main_captured(["--source", src, "--fixture-labels", under,
                                      "--max-labels", "1000", "--output-format", "tsv"])
        rows = [r for r in out.splitlines() if r]
        if rc == 3:
            print("FAIL rest bound control: 999 rows under the bound exited 3")
            ok = False
        # 999 fixture rows, one of which (lbl-0000) is declared -> 998 ORPHAN rows.
        if len(rows) != 998:
            print(f"FAIL rest bound control: emitted {len(rows)} rows want 998")
            ok = False
        # The TSV shape is the byte-compatibility contract deploy.sh parses: every
        # row exactly 2 tab-separated columns, col-1 drawn only from {MISSING, ORPHAN}.
        widths = {len(r.split("\t")) for r in rows}
        if widths != {2}:
            print(f"FAIL rest bound control: column widths {sorted(widths)} want {{2}}")
            ok = False
        classes = {r.split("\t")[0] for r in rows}
        if not classes <= {"MISSING", "ORPHAN"}:
            print(f"FAIL rest bound control: unexpected col-1 classes {sorted(classes)}")
            ok = False

        # --- Case 5: SPECIFICITY control. An empty live payload parses to zero rows
        #     (not an error), and the union-empty guard still exits 3 on its own.
        if parse_label_payload("[]") != []:
            print("FAIL rest empty payload: expected zero rows")
            ok = False
        rc, out = _run_main_captured(["--source", empty_src, "--fixture-labels", empty,
                                      "--output-format", "tsv"])
        if rc != 3:
            print(f"FAIL union-empty path: exited {rc} want 3")
            ok = False

    # --- A payload row that is not an object carrying `name` must raise rather than
    #     be silently dropped — a dropped row is an invented MISSING.
    try:
        parse_label_payload('["not-an-object"]')
        print("FAIL rest payload validation: malformed row did not raise")
        ok = False
    except RuntimeError:
        pass

    return ok


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
        "--repo",
        default=None,
        help=(
            "owner/name for the live label read; derived from git remote origin when "
            "omitted. Never hardcoded (depersonalization gate)."
        ),
    )
    ap.add_argument(
        "--max-labels",
        type=int,
        default=DEFAULT_MAX_LABELS,
        help=(
            f"fail loud (exit 3) if the live label set exceeds this many rows "
            f"(default {DEFAULT_MAX_LABELS}). Replaces the previous silent 500-row "
            f"truncation, which reported unread canonical labels as spurious MISSING."
        ),
    )
    ap.add_argument(
        "--fixture-labels",
        default=None,
        help=(
            "read the live label payload from this file instead of the network — "
            "drives the pagination arm offline with no seeded labels."
        ),
    )
    ap.add_argument(
        "--self-test", action="store_true", help="run the fixture suite; no gh/source needed"
    )
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    sources = args.source or ["core/specs/label-taxonomy.md"]

    # The live read needs a repo slug unless a fixture stands in for the network leg.
    # Unresolvable is fail-loud on the existing exit-3 contract, never a silent pass.
    repo = _derive_repo(args.repo)
    if repo is None and args.fixture_labels is None:
        print("ERROR\t--repo not supplied and git remote origin unresolved",
              file=sys.stderr)
        return 3

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
            live_rows = fetch_live_label_rows(
                repo, args.max_labels, args.fixture_labels
            )
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
        live = fetch_live_labels(repo, args.max_labels, args.fixture_labels)
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
