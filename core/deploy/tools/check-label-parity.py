#!/usr/bin/env python3
"""Label-taxonomy <-> GitHub label-set parity primitive [#749].

deploy.sh Check 51's scan engine. Parses the canonical label registry from one or
more --source files and compares the UNION to the live GitHub label set (the REST
labels endpoint, read via `gh api "repos/<slug>/labels?per_page=100" --paginate`),
emitting four asymmetric-severity directions:

  MISSING        a canonical label is absent from GitHub  -> ENFORCE-capable (the
                 #457 `status: rejected` defect class: a gate referencing a
                 non-existent label fails silently).
  ORPHAN         a live GitHub label is not registered in the taxonomy  -> WARN
                 (some are legitimately operator-local or pending registration).
  EXCLUDED_LIVE  a live GitHub label the grammar declares EXCLUDED  -> WARN. A
                 distinct class from ORPHAN because the remedies are OPPOSITE: an
                 orphan may simply need registering, whereas an excluded-but-live
                 row means one of the two surfaces must change (delete the label,
                 or withdraw the exclusion). Folding it into ORPHAN made the
                 contradiction invisible to the gate that reads both surfaces.
  DIVERGED       a row declared AND live whose colour and/or description disagrees
                 with the declaration  -> ADVISORY, structurally non-escalating
                 (#5057). The three arms above are all NAME-keyed and every one of
                 them passes on such a row. Its remediation OVERWRITES live label
                 metadata — repository STATE, not git-revertible — and the gate
                 cannot tell a deliberate operator override from drift, so this arm
                 is read-only by construction: it does not enter the exit
                 expression, and deploy.sh routes it through flag_advisory_only.
                 A row registered in the disposition file (--dispositions) is
                 suppressed; see parse_dispositions / classify_divergence.
  DIVERGED-STALE a disposition-registry row naming a label that is no longer
                 divergent, or no longer live  -> ADVISORY. The audit affordance a
                 suppression surface owes: a suppression that silently stops
                 matching is the defect class this arm exists to close.

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
label-definition table rows; `.toml` reads `[[labels]]` `name = "..."` entries PLUS
the `type:<kind_id>` projection of each `[[kinds]]` declaration (#5291).

`--list-declared-kinds` exposes that kind projection as a read-only listing mode, one
`type:<kind_id>` per line on stdout. It exists so a second consumer needing the same
resolution — release/tools/compute-release-velocity.sh's work-class map (#4223) —
CONSUMES this resolver instead of forking a parallel one, which is the drift surface
a second derivation would create. Two properties are load-bearing on that consumer
and are asserted in the self-test: the mode is entirely OFFLINE (it returns before
the repo-slug derivation and the live-label read, so it runs inside a CI step
declared offline + stdlib-only), and an empty result EXITS 0 (a deployment selecting
packs that declare no kinds is a legitimate empty set, not a failure).

Concrete-enum vs namespace-pattern (the R4 nuance): most labels are a concrete
enumerated set (category, `status:*`, `cluster:*`, `triage:*`, disposition); two are
a namespace PATTERN with examples (`project:*`, `epic:*`). A live label is an ORPHAN
only if it matches neither a concrete registered label nor a registered namespace
prefix. The markdown parser keys on label-definition table rows (col-2 is a
backticked hex color), which structurally excludes the `## Excluded Labels` table
(col-2 is prose) and header/separator rows. Title-prefix parity (the #74
`[Observation]:` invariant) is a SEPARATE concern, NOT evaluated here.

`type:*` is NOT a resolution pattern (#5291), and the distinction from `project:*` /
`epic:*` is the point. It was registered as a prefix, which made the whole
work-item-kind family unfalsifiable — a prefix match accepts any live `type:X`
whether or not a selected pack declares kind X, so the gate believed it reconciled
that family while verifying only that the string began with `type:`. It now resolves
against the union of each source's concrete `[[labels]]` rows and the
`type:<kind_id>` projection of each source's `[[kinds]]` declarations (see
parse_toml_kind_ids). Both arms of the union are needed: `work-item-type-schema.md`
§1.1.1 requires `projects_kind` ON a `type:*` row but never requires a row PER
declared kind, so a K4 operator-local pack may declare `kind_id = "bug"` with no row
at all and the kind is still legitimately declared. `type:*` stays a namespace
pattern in the GRAMMAR — core/specs/label-taxonomy.md § Work-Item-Kind Labels still
declines to enumerate the kinds, because they belong to the packs.

Tolerated legacy alias: `type:subtask` (TOLERATED_TYPE_ALIASES) resolves to no
declared kind and is nonetheless correct — a frozen alias of the `sub-task` category
row that core/specs/label-taxonomy.md § Tolerated Legacy Alias states must not be
deleted, because three consumers read it. It is filtered out of ORPHAN and appears in
no arm; see diff_parity for why it is filtered rather than declared canonical.

Excluded labels (#5054): `label-taxonomy.md` § Excluded Labels states, in the
PRESENT tense, which default GitHub labels this platform's canonical set excludes.
The section is read by a SEPARATE, section-anchored parser — not `_ROW_RE` — because
its col-2 is prose by hard requirement: a backticked hex there would make the four
rows canonical, and after the operator deletes the labels they would flip straight
into the enforce-capable MISSING arm. The exclusion is declared HERE rather than in
a pack's `[[labels]]` facet because packs are a CONTRIBUTION surface, unioned and
overridable by K4 operator-local rows — an exclusion a pack can be added to override
is not an exclusion. Parsing fails LOUD (exit 3) when >=1 `.md` source was supplied
and none carries the header, reusing the "registry moved/renamed" contract: a
renamed heading would otherwise silently empty the excluded set and read green for a
reason nobody chose.

--emit-fix (read-only repair renderer): the diff above reports that a declared row
is absent; nothing in the corpus CREATES it, so the declared->live materialization
step had no owner and no implementation. `--emit-fix` renders the `gh label` commands
that would close the gap and runs none of them, in four blocks: CREATE (declared,
absent), RECONCILE (live but colour/description diverged), UNRESOLVABLE (declared
with no colour — not emittable, since a colourless create takes GitHub's default grey
and re-creates the drift), and DELETE (declared EXCLUDED yet live). DELETE renders
LAST, after UNRESOLVABLE, so an operator pasting from the top never reaches a
destructive command by momentum. It is a separate boolean flag, NOT an --output-format
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
  1  finding(s) — MISSING and/or ORPHAN and/or EXCLUDED_LIVE (or, under --emit-fix,
     ≥1 emittable row)
     DIVERGED and DIVERGED-STALE are DELIBERATELY absent from this line: the
     divergence arms report, they never move the exit code (see the DIVERGED entry
     above). A run whose only finding is attribute divergence still exits 0.
  2  argument / input error, INCLUDING a malformed --dispositions record (that file
     is an argument, not a --source, so it takes the usage class rather than 3)
  3  a --source was unreadable OR the union parsed to zero canonical labels OR the
     live set was unreadable OR the repo slug was unresolvable OR the live set
     exceeded --max-labels OR a PRESENT --dispositions file was unreadable (an
     ABSENT one is tolerated as an empty registry) OR >=1 `.md` --source was
     supplied and none carried the
     `## Excluded Labels` header (fail-loud: a relocated/renamed registry must not
     read green, and an over-large population must not silently truncate). A single
     readable-but-empty source is tolerated as long as the union is non-empty
     (e.g. a pack with no [[labels]] block yet). A pure-`.toml` source set supplies
     no `.md` at all, so its excluded set is legitimately empty and no exit-3 fires.

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
# label under one of these prefixes is NOT an orphan.
#
# `type:` is DELIBERATELY NOT a member (#5291). It was, and that made the entire
# work-item-kind family unfalsifiable: a prefix match accepts any live `type:X`
# whether or not a selected pack declares kind X, so five undeclared labels sat in
# the live set with no gate complaint. `type:*` remains a namespace pattern in the
# GRAMMAR (core/specs/label-taxonomy.md § Work-Item-Kind Labels still declines to
# enumerate the kinds — they live in the packs) but it is no longer a RESOLUTION
# pattern here: a live `type:X` now resolves only against the union of each source's
# concrete `[[labels]]` rows and its `[[kinds]]` `kind_id` projections (see
# parse_toml_kind_ids / parse_source), or against TOLERATED_TYPE_ALIASES below.
REGISTERED_NAMESPACES = ("project:", "epic:")

# `type:*` rows that resolve to NO declared kind and are nonetheless correct.
#
# `type:subtask` is a tolerated legacy alias of the `sub-task` category row: it joins
# no pack's `kinds[]`, projects no `work_item_type`, and predates the canonical row it
# aliases. The authority is core/specs/label-taxonomy.md § Tolerated Legacy Alias,
# which freezes it and states outright that it MUST NOT be deleted —
# check-milestone-epic-membership.py admits it in the wide sub-task predicate its
# counting legs use, release/tools/automated-closeout.sh accepts it in the Stage-13
# auto-close exclusion filter, and release/skills/release-executor/SKILL.md documents
# that filter. Reporting it as an orphan forever would invite exactly the deletion
# those three consumers cannot survive.
#
# It lives HERE, as a corpus-side module constant, rather than as a pack `[[labels]]`
# row or an operator-local allowlist entry. A `[[labels]]` row would be schema-invalid
# — work-item-type-schema.md §1.1.1 makes `projects_kind` REQUIRED on a `type:*` row
# and this alias joins no `kinds[]` — and an allowlist entry is the K4 operator-local
# surface, which would let a deployment silently drop a corpus-governed tolerance and
# shrink the census check-milestone-epic-membership.py reports on.
TOLERATED_TYPE_ALIASES = ("type:subtask",)

# The per-row ATTRIBUTE-DISPOSITION registry (#5057). The MISSING/ORPHAN/EXCLUDED_LIVE
# arms are all NAME-keyed; a row that exists on both sides with the wrong colour or
# description passes every one of them. That class is reported here as DIVERGED, and
# the registry is what stops a DISPOSITIONED row from re-presenting as drift forever.
#
# WHY A REGISTRY AND NOT A SWEEP. The gate cannot tell a deliberate operator override
# from drift — both are "live disagrees with the declaration" — so a bulk `gh label
# edit` would silently overwrite deliberate choices, against repository STATE that is
# not git-revertible. The decision is irreducibly human; this file records it once so
# the arm becomes drainable instead of a permanent signal stream.
#
# It lives under core/config/allowlists/ rather than core/deploy/allowlists/ because
# the two directories split on AUTHORSHIP, read from their own headers:
# core/config/allowlists/ holds operator-authored governance registries (its members
# state "additions follow the 'No ungoverned changes' protocol"), while
# core/deploy/allowlists/ holds machine-maintained/derived data ("Do NOT hand-edit the
# path list"). A disposition IS operator judgement, so it belongs with the former.
DISPOSITIONS_DEFAULT = "core/config/allowlists/label-attribute-dispositions.txt"

# The closed disposition enum. `accept-override` additionally takes an optional AXIS
# qualifier (`accept-override:color` / `accept-override:description`); the bare form is
# equivalent to both. Axis scoping is load-bearing rather than a nicety: accepting a
# deliberate colour choice must not also silently accept an unreviewed description.
DISPOSITION_VALUES = ("reconcile-live", "reconcile-declaration", "accept-override")
DISPOSITION_AXES = ("color", "description")

# A registry line's inline rationale: the `<record>  # <rationale>` idiom shared by
# core/config/allowlists/*.txt. Two-or-more spaces (or a tab) before the `#` is what
# separates a rationale from a `#` inside a label name, so the split is anchored on
# the run rather than on the bare character.
_DISPOSITION_RATIONALE_RE = re.compile(r"(?: {2,}|\t+)#")

# The ONLY place the § Excluded Labels anchor string appears (#5054). Single-sourced
# so a heading rename has exactly one place to change — and a rename that misses it
# is caught by the fail-loud exit-3 in main() rather than silently emptying the set.
_EXCLUDED_SECTION_HDR = "## Excluded Labels"

# A label-definition table data row: | `label` | `hexcolor` (name) | ...
# Requiring a backticked 3/6-hex in col-2 pins the match to the label tables and
# excludes the `## Excluded Labels` table (col-2 = prose exclusion basis), headers,
# and separators. That exclusion is LOAD-BEARING, not incidental: were the excluded
# rows to become canonical, deleting the labels they name would flip them from this
# check's WARN-only EXCLUDED_LIVE arm into its ENFORCE-capable MISSING arm.
_ROW_RE = re.compile(r"^\s*\|\s*`([^`]+)`\s*\|\s*`[0-9a-fA-F]{3,6}`")

# A § Excluded Labels data row: | `label` | <prose exclusion basis> |
# Col-1 ONLY. Deliberately NOT _ROW_RE, which demands the hex col-2 this table must
# never carry; and deliberately not shape-anchored, because "two-column table with a
# backticked first cell" cannot discriminate the excluded table from any other.
_EXCLUDED_ROW_RE = re.compile(r"^\s*\|\s*`([^`]+)`\s*\|")

# Any `## ` heading — the close condition for the section scan above.
_MD_H2_RE = re.compile(r"^\s*##\s")

# A pack.toml `[[labels]]` name assignment. Minimal, dependency-free extraction
# (no tomllib on py3.9, and this check must stay green without an optional TOML
# lib): within the file we scan for `name = "..."` lines that sit under a
# `[[labels]]` array-of-tables header. Keying the scan to the [[labels]] section
# excludes the pack's `[meta]`/`[[kinds]]` `name`-like keys.
_TOML_LABELS_HDR_RE = re.compile(r"^\s*\[\[labels\]\]\s*$")
_TOML_TABLE_HDR_RE = re.compile(r"^\s*\[")
_TOML_NAME_RE = re.compile(r'^\s*name\s*=\s*"([^"]+)"')

# A pack.toml `[[kinds]]` kind_id assignment — the SIBLING scan to the two above,
# and the reason `type:` could be dropped from REGISTERED_NAMESPACES (#5291). Same
# dependency-free shape, keyed to the `[[kinds]]` array-of-tables so that a
# `kind_id`-like key under `[meta]` or a `[kinds.*]` sub-table is not miscollected.
_TOML_KINDS_HDR_RE = re.compile(r"^\s*\[\[kinds\]\]\s*$")
_TOML_KIND_ID_RE = re.compile(r'^\s*kind_id\s*=\s*"([^"]+)"')

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


def parse_md_excluded_labels(source_text):
    """Names declared under `## Excluded Labels`. Returns (names:set, header_found:bool).

    SECTION-anchored, not shape-anchored, and the distinction is the whole design.
    `_ROW_RE` is shape-anchored (backticked hex in col-2) and therefore robust to a
    heading rename — but that shape cannot discriminate an excluded table from any
    other two-column table with a backticked first cell, and the excluded table's
    col-2 is prose by hard requirement (see `_ROW_RE`). So this parser keys on the
    heading, and `header_found` is returned alongside the names so the caller can
    fail LOUD when the anchor is gone: a rename would otherwise empty the set, the
    new class would report clean, and the gate would be green for a reason nobody
    chose — the same defect one layer up from the one this class exists to close.

    Same dependency-free line-scan shape as parse_toml_labels (no tomllib on py3.9).
    Opens on a stripped line equal to the header; closes on the next `## ` heading.
    """
    names = set()
    header_found = False
    in_section = False
    for line in source_text.splitlines():
        if line.strip() == _EXCLUDED_SECTION_HDR:
            header_found = True
            in_section = True
            continue
        if in_section and _MD_H2_RE.match(line):
            in_section = False
            continue
        if not in_section:
            continue
        m = _EXCLUDED_ROW_RE.match(line)
        if m:
            names.add(m.group(1).strip())
    return names, header_found


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


def parse_toml_kind_ids(source_text):
    """Declared `kind_id`s from a pack.toml `[[kinds]]` array-of-tables (#5291).

    SIBLING of parse_toml_labels, and the two answer genuinely different questions —
    which is the whole reason this function exists. `work-item-type-schema.md` §1.1.1
    requires `projects_kind` ON a `type:*` label row, but nowhere requires a label row
    PER declared kind. So "declared kinds" and "declared `type:*` rows" are two
    different sets. They coincide in the shipped corpus packs and DIVERGE in exactly
    the case that matters: a K4 operator-local pack declaring `kind_id = "bug"` with
    no `[[labels]]` row. A label-row-only predicate cannot see that pack, so it would
    report `type:bug` as an orphan on a deployment that legitimately declares it —
    with and without the pack, identically, which is a degenerate probe rather than a
    check.

    Dependency-free line-scan (no tomllib on py3.9), identical in shape to
    parse_toml_labels: any other table header closes the context, so `[kinds.fields]`
    and `[kinds.criteria.readiness]` sub-tables correctly end collection and a
    `kind_id` key elsewhere is not miscollected. Returns a set of BARE kind ids
    (`{"epic", "story"}`), not `type:`-prefixed — the caller owns the projection.
    """
    kinds = set()
    in_kinds = False
    for line in source_text.splitlines():
        if _TOML_KINDS_HDR_RE.match(line):
            in_kinds = True
            continue
        if _TOML_TABLE_HDR_RE.match(line):
            # some other table header ([meta], [[labels]], [kinds.fields], ...)
            in_kinds = False
            continue
        if in_kinds:
            km = _TOML_KIND_ID_RE.match(line)
            if km:
                kinds.add(km.group(1).strip())
    return kinds


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


def parse_dispositions(text):
    """Parse the attribute-disposition registry (#5057). Raises ValueError on a bad line.

    Grammar: ``<disposition> <label-name>  # <rationale>`` — disposition FIRST.

    The order is forced, not stylistic: a label name may contain spaces
    (``cluster: architecture``), so a name-first space-separated record is
    unparseable, whereas the disposition is a closed space-free enum and
    ``split(None, 1)`` then resolves the record unambiguously with the name as the
    free-form remainder. Blank lines and lines whose first non-space character is
    ``#`` are ignored, matching every other registry in core/config/allowlists/.

    An unknown disposition value, an unknown axis qualifier, an axis on a
    disposition that does not take one, a duplicate label, or a line carrying no
    second field is a HARD parse error (caller -> exit 2, the usage class: this file
    arrives as an argument, not as a --source). It is deliberately not skipped: a
    silently-dropped record is a suppression the operator believes is in force.

    Returns ``{label_name: (base_value, axis_or_None)}``.
    """
    out = {}
    for lineno, raw in enumerate(text.splitlines(), start=1):
        line = raw.rstrip()
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        record = _DISPOSITION_RATIONALE_RE.split(line, 1)[0].strip()
        if not record:
            continue
        parts = record.split(None, 1)
        if len(parts) != 2 or not parts[1].strip():
            raise ValueError(
                f"line {lineno}: expected `<disposition> <label-name>`, got {record!r}"
            )
        token, name = parts[0], parts[1].strip()
        base, _, axis = token.partition(":")
        axis = axis or None
        if base not in DISPOSITION_VALUES:
            raise ValueError(
                f"line {lineno}: unknown disposition {base!r} — expected one of "
                f"{', '.join(DISPOSITION_VALUES)}"
            )
        if axis is not None:
            if base != "accept-override":
                raise ValueError(
                    f"line {lineno}: disposition {base!r} takes no axis qualifier "
                    f"(got {axis!r}); only accept-override does"
                )
            if axis not in DISPOSITION_AXES:
                raise ValueError(
                    f"line {lineno}: unknown axis {axis!r} — expected one of "
                    f"{', '.join(DISPOSITION_AXES)}"
                )
        if name in out:
            raise ValueError(
                f"line {lineno}: duplicate disposition for label {name!r} — a label "
                f"carries exactly one recorded disposition"
            )
        out[name] = (base, axis)
    return out


def parse_source(path, source_text):
    """Dispatch by extension: .toml -> [[labels]] names + kind projections; else -> md.

    The `.toml` arm is a UNION, not a replacement (#5291): a pack contributes both its
    concrete `[[labels]]` names AND the `type:<kind_id>` projection of every kind it
    declares. Union rather than either alone because §1.1.1 binds the two only in one
    direction — every `type:*` row must name a kind, but a declared kind need not have
    a row — so taking only the rows blinds the gate to a kind-only K4 pack, and taking
    only the kinds drops every non-`type:` label the pack contributes.
    """
    if path.lower().endswith(".toml"):
        return (parse_toml_labels(source_text)
                | {f"type:{k}" for k in parse_toml_kind_ids(source_text)})
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
    a strictly separate finding class; folding it into diff_parity would change what
    an existing green check means.

    The gate now REPORTS that class and still does not ENFORCE it (#5057). Both
    halves matter. classify_divergence CALLS this function to build the DIVERGED
    arm, so the gate path and the --emit-fix path share one definition of
    "diverged" and cannot drift apart; and the arm is emitted through
    flag_advisory_only and excluded from the exit expression, so reporting it moves
    no verdict. This function's own signature, body and callers are unchanged.
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


def divergent_axes(want, have):
    """The axes on which one declared row and its live counterpart disagree.

    Returns a frozenset drawn from DISPOSITION_AXES. Mirrors diff_declarations'
    comparison EXACTLY — case-insensitive on colour, exact on description — so the
    axis attribution can never disagree with the classification that produced it.
    """
    axes = set()
    if have["color"].lower() != (want.get("color") or "").lower():
        axes.add("color")
    if have["description"] != want.get("description", ""):
        axes.add("description")
    return frozenset(axes)


def classify_divergence(declared_rows, live_rows, dispositions):
    """Partition the attribute-divergence class by its recorded disposition (#5057).

    CALLS diff_declarations; deliberately does not fork it. One classifier with two
    consumers (the --emit-fix renderer and this gate arm) is what keeps the two from
    drifting into disagreeing about what "diverged" means — the same reason
    parse_toml_label_rows was authored as a SIBLING of parse_toml_labels rather than
    as a widening of it.

    undispositioned         diverged, with no registry row covering every axis on
                            which it actually diverges -> the drainable arm.
    dispositioned_pending   diverged, and OWNED by a `reconcile-*` row: the operator
                            has ruled which side is right but the cascade (an
                            operator-run `gh label edit`, outside every acceptance
                            criterion) has not run. Still reported, because it is
                            still divergent.
    stale                   a registry row naming a label that is not currently
                            divergent, or not live at all. The minimal audit
                            affordance a suppression surface owes: a suppression
                            that silently stops matching is the same defect class
                            this arm exists to close.

    An `accept-override` row is SUPPRESSED — it appears in no arm, which is the
    whole point of registering it. Suppression is AXIS-SCOPED: a row registered
    `accept-override:color` that also diverges on description reports on the
    residual axis, because accepting a colour is not accepting a description.

    Returns three sorted lists of label names.
    """
    _absent, diverged, _unresolvable = diff_declarations(declared_rows, live_rows)
    diverged_set = set(diverged)

    undispositioned, dispositioned_pending = [], []
    for name in diverged:
        entry = dispositions.get(name)
        if entry is None:
            undispositioned.append(name)
            continue
        base, axis = entry
        if base != "accept-override":
            dispositioned_pending.append(name)
            continue
        covered = frozenset(DISPOSITION_AXES) if axis is None else frozenset([axis])
        residual = divergent_axes(declared_rows[name], live_rows[name]) - covered
        if residual:
            undispositioned.append(name)

    stale = sorted(n for n in dispositions if n not in diverged_set)
    return sorted(undispositioned), sorted(dispositioned_pending), stale


def _shq(s):
    """Single-quote a value for safe paste into a POSIX shell."""
    return "'" + str(s).replace("'", "'\\''") + "'"


def render_emit_fix(declared_rows, live_rows, excluded_live=(), repo=None):
    """Render the READ-ONLY repair script. Returns (lines, actionable_count).

    Emits commands; never runs them. The blocks are kept separate on purpose and
    their ORDER is part of the contract: creating an absent row is additive and safe,
    editing a diverged row OVERWRITES live metadata a human may have set
    deliberately, and DELETING a row destroys repository state outright. An operator
    must be able to run the first block without being led into the later ones, so
    severity increases monotonically down the output and DELETE renders LAST — after
    UNRESOLVABLE — where nobody reaches it by momentum.

    `excluded_live` (the rows the grammar declares excluded yet found live) defaults
    to empty, keeping every existing call site valid.

    `repo` is the DERIVED owner/name, used only to spell the DELETE block's pre-flight
    capture command. It defaults to None so every existing call site stays valid; with
    no slug the block names the flag that resolves one rather than emitting a command
    that would run against a literal "None".
    """
    absent, diverged, unresolvable = diff_declarations(declared_rows, live_rows)
    out = []
    out.append("# check-label-parity.py --emit-fix — READ-ONLY. Nothing below has been run.")
    out.append("# Review, then paste the block(s) you want. A label is repository STATE,")
    out.append("# not repository CONTENT: `git revert` cannot undo any of it (see the")
    out.append("# release rollback protocol). Blocks run in increasing severity —")
    out.append("# CREATE (additive) then RECONCILE (overwrites) then DELETE (destroys).")
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
    out.append("")
    excluded_live = sorted(excluded_live)
    out.append(f"# --- DELETE: declared excluded, live ({len(excluded_live)}) ---")
    out.append("#   IRREVERSIBLE. Label DELETION is repository STATE: `git revert` cannot")
    out.append("#   undo it, no snapshot in this repository holds it, and any issue that")
    out.append("#   carries one of these labels LOSES it permanently — open and closed")
    out.append("#   alike. Before running a single line, capture the current state with")
    # Transport: REST, not GraphQL — the SAME substitution, for the same reason, as
    # the live read in _gh_labels_stdout (module docstring, "Transport — REST, not
    # GraphQL"). `gh label list` issues POST /graphql, and GraphQL quota exhaustion
    # clusters precisely at release close-out, which is when Check 51 runs and
    # therefore when this block is reached. The instruction guarding an IRREVERSIBLE
    # deletion must not ride the pool most likely to be dead at the moment it is
    # needed: a capture that cannot run is no reconstruction record at all. REST
    # returns whole label objects, so name/color/description all come back.
    #
    # The slug is DERIVED, never hardcoded (depersonalization gate,
    # core/rules/git-workflow.md § Repository-Integrity Gates) and never left as
    # gh's placeholder form, which core/config/allowlists/egress-allowlist.txt
    # denies as an unresolvable authority. With no slug resolvable — the
    # --fixture-labels path, the only one that reaches here without one — name the
    # flag that resolves it rather than emit a command that would run against a
    # literal "None".
    if repo:
        out.append(
            f'#   `gh api "repos/{repo}/labels?per_page=100" --paginate` and re-measure the'
        )
    else:
        out.append("#   a REST labels read — re-run with `--repo owner/name` to have")
        out.append("#   this block render the exact command — and re-measure the")
    out.append("#   carrier count of each row: with zero carriers that capture is the")
    out.append("#   COMPLETE reconstruction record, and with any carrier it is not.")
    out.append("#   The alternative remedy is the opposite one — withdraw the row from")
    out.append("#   label-taxonomy.md § Excluded Labels, which is CHEAP and revertible.")
    if not excluded_live:
        out.append("#   (none)")
    for n in excluded_live:
        out.append(f"gh label delete {_shq(n)} --yes")
    return out, len(absent) + len(diverged) + len(unresolvable) + len(excluded_live)


def diff_parity(concrete, namespaces, live, excluded=frozenset()):
    """(missing, orphan, excluded_live) sorted lists.

    missing       canonical, absent from live
    orphan        live, in neither the canonical set nor a registered namespace,
                  not a tolerated legacy alias, and NOT declared excluded
    excluded_live live and declared EXCLUDED by the grammar

    The orphan and excluded_live arms are MUTUALLY EXCLUSIVE by construction. That
    is load-bearing rather than tidy: a row counted in both would double-report, and
    any control arm reading the ORPHAN denominator would read wrong. `excluded`
    defaults to an empty frozenset so every existing caller and fixture stays valid
    and a pure-`.toml` invocation (no `.md` source, hence no excluded declaration)
    behaves exactly as before.

    TOLERATED_TYPE_ALIASES is filtered out of the orphan arm and contributes to NO
    arm at all (#5291) — it is inert, not reclassified. That inertness is what bounds
    the `type:*` hardening: `type:subtask` is corpus-governed as permanently correct,
    so a class that merely renamed its report would keep inviting the deletion its
    three consumers cannot survive. It is filtered rather than added to `concrete`
    deliberately: `concrete` feeds the enforce-capable MISSING arm, and an alias that
    is tolerated-if-present must not become required-if-absent.
    """
    missing = sorted(c for c in concrete if c not in live)
    excluded_live = sorted(l for l in live if l in excluded)
    orphan = sorted(
        l for l in live
        if l not in concrete
        and l not in excluded
        and l not in TOLERATED_TYPE_ALIASES
        and not any(l.startswith(ns) for ns in namespaces)
    )
    return missing, orphan, excluded_live


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
        "## Excluded Labels\n"
        "| Label | Exclusion basis |\n"
        "|---|---|\n"
        "| `good first issue` | Single-operator platform |\n"
        "| `zz-excluded-absent` | Never created here |\n"
        "## Rules\n"
        "| `not-a-label` | this row is past the section close |\n"
    )
    md_concrete = parse_md_labels(md_fixture)
    # Namespace-pattern rows (project:*/epic:*/type:*) and the Excluded table are
    # excluded; only `improvement` is a concrete row. The Excluded table's exclusion
    # from the CANONICAL union is the specificity control for the whole class: were
    # it to leak in, deleting an excluded label would flip it into the MISSING arm.
    if md_concrete != {"improvement"}:
        print(f"FAIL md parse: got {sorted(md_concrete)} want ['improvement']")
        ok = False

    # --- § Excluded Labels parse. Both names collected; the `## Rules` heading closes
    #     the section, so the row beneath it must NOT be collected (the section-scan
    #     specificity control — without it a runaway scan would read the whole file).
    md_excluded, hdr_found = parse_md_excluded_labels(md_fixture)
    want_excl = {"good first issue", "zz-excluded-absent"}
    if md_excluded != want_excl:
        print(f"FAIL excluded parse: got {sorted(md_excluded)} want {sorted(want_excl)}")
        ok = False
    if not hdr_found:
        print("FAIL excluded parse: header_found False on a fixture carrying the header")
        ok = False
    # SPECIFICITY control for header_found: a doc with no such section reports False
    # and an empty set — the signal the caller's exit-3 fail-loud path keys on.
    no_hdr_names, no_hdr_found = parse_md_excluded_labels(
        "## Label Groups\n| `improvement` | `0E8A16` (green) | x | y |\n"
    )
    if no_hdr_found or no_hdr_names:
        print(f"FAIL excluded parse control: got ({sorted(no_hdr_names)}, {no_hdr_found}) "
              f"want (set(), False)")
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
        "[[labels]]\n"
        'group = "category"\n'
        'name = "type:task"\n'                 # a kind with BOTH a row and a kind_id
        'projects_kind = "task"\n'
        "\n"
        "[[kinds]]\n"
        'kind_id = "story"\n'                  # a kind declared with NO label row
        'name = "also-not-a-label"\n'          # a name key under [[kinds]]
        "\n"
        "[kinds.fields]\n"
        'kind_id = "not-a-declared-kind"\n'    # a kind_id key under a SUB-table
    )
    toml_concrete = parse_toml_labels(toml_fixture)
    want_toml = {"status: rejected", "cluster: security", "type:task"}
    if toml_concrete != want_toml:
        print(f"FAIL toml parse: got {sorted(toml_concrete)} want {sorted(want_toml)}")
        ok = False

    # --- `[[kinds]]` parse (#5291). `story` is collected; the `[kinds.fields]`
    #     sub-table closes the context, so its decoy `kind_id` is NOT — the
    #     specificity control that distinguishes a section-scoped scan from a
    #     whole-file grep for `kind_id`.
    toml_kinds = parse_toml_kind_ids(toml_fixture)
    if toml_kinds != {"story"}:
        print(f"FAIL kinds parse: got {sorted(toml_kinds)} want ['story']")
        ok = False

    # --- parse_source unions the two for a .toml (#5291): the pack contributes its
    #     `[[labels]]` names AND `type:<kind_id>` for every declared kind. `type:task`
    #     arrives by BOTH paths (row + kind) and `type:story` by the kind path alone.
    toml_union = parse_source("fixture-pack.toml", toml_fixture)
    want_union = {"status: rejected", "cluster: security", "type:task", "type:story"}
    if toml_union != want_union:
        print(f"FAIL parse_source union: got {sorted(toml_union)} want {sorted(want_union)}")
        ok = False

    # --- Union + diff. Concrete = md ∪ parse_source(toml). `type:bug` and `type:adr`
    #     are live and declared by NOTHING, so both now ORPHAN — before #5291 the
    #     registered `type:` prefix accepted them and the whole family was
    #     unfalsifiable. `type:task` (label row) and `type:story` (kind projection)
    #     resolve; `type:subtask` is the tolerated alias and appears in no arm;
    #     `project:foo` still resolves by namespace; `zz-orphan` orphans; a canonical
    #     row absent from live (`cluster: security`) is MISSING.
    concrete = md_concrete | toml_union
    ns = REGISTERED_NAMESPACES
    live = {"improvement", "status: rejected", "project:foo", "zz-orphan",
            "good first issue", "type:task", "type:story", "type:subtask",
            "type:bug", "type:adr"}
    missing, orphan, excluded_live = diff_parity(concrete, ns, live, md_excluded)
    if missing != ["cluster: security"]:
        print(f"FAIL missing: {missing}")
        ok = False
    if orphan != ["type:adr", "type:bug", "zz-orphan"]:
        print(f"FAIL orphan: {orphan}")
        ok = False

    # --- THE AC-5 PAIR (#5291), and BOTH arms are required. The subject: a K4
    #     operator-local pack declaring `kind_id = "bug"` with NO `[[labels]]` row.
    #     With it selected, `type:bug` must NOT be reported; without it, it MUST be.
    #     A one-armed assertion is the degenerate probe this card exists to close —
    #     the label-row-only predicate reports `type:bug` identically with and
    #     without the pack, so it satisfies "absent when selected" never, and
    #     "reported when absent" always, while proving nothing about K4 resolution.
    k4_fixture = "[[kinds]]\n" 'kind_id = "bug"\n'
    # The discriminating fact, asserted directly: this pack declares a kind and NO
    # label row, so a rows-only parse sees an empty set and cannot resolve `type:bug`.
    if parse_toml_labels(k4_fixture) != set():
        print("FAIL k4 fixture: the kind-only pack must contribute no [[labels]] rows")
        ok = False
    k4_union = parse_source("k4-pack.toml", k4_fixture)
    if k4_union != {"type:bug"}:
        print(f"FAIL k4 fixture union: got {sorted(k4_union)} want ['type:bug']")
        ok = False
    _m4, orphan_with_k4, _x4 = diff_parity(concrete | k4_union, ns, live, md_excluded)
    if "type:bug" in orphan_with_k4:
        print(f"FAIL AC-5 subject: type:bug reported with the K4 pack selected: {orphan_with_k4}")
        ok = False
    # CONTROL for the arm above (already computed): without the K4 pack it IS
    # reported. Restated as its own assertion so the pair fails loudly rather than
    # degrading to a subject-only check if the set above is ever edited.
    if "type:bug" not in orphan:
        print("FAIL AC-5 control: type:bug NOT reported without the K4 pack — "
              "the probe cannot distinguish reading the pack from ignoring type:*")
        ok = False
    # The K4 projection must not leak into the ENFORCE-capable arm for a kind whose
    # label IS live: declaring `bug` locally makes `type:bug` resolvable, never required.
    if "type:bug" in _m4:
        print(f"FAIL AC-5: type:bug entered the MISSING arm while live: {_m4}")
        ok = False

    # --- The TOLERATED alias (#5291), asserted in both directions. `type:subtask`
    #     appears in NO arm — not ORPHAN, and specifically not MISSING, because it is
    #     tolerated-if-present and must never become required-if-absent. Its control
    #     is `type:adr`: still undeclared and untolerated, and still reported — without
    #     that arm a blanket `type:` suppression would pass this assertion.
    if "type:subtask" in missing + orphan + excluded_live:
        print("FAIL tolerated alias: type:subtask surfaced in an arm")
        ok = False
    if "type:adr" not in orphan:
        print("FAIL tolerated-alias control: type:adr (undeclared, untolerated) "
              f"not reported — suppression is over-broad: {orphan}")
        ok = False
    # SIBLING-NAMESPACE control: narrowing `type:*` must not collapse the surviving
    # namespace patterns into concrete matching. `project:foo` is declared by nothing
    # and must still resolve by prefix.
    if "project:foo" in orphan:
        print(f"FAIL sibling namespace: project:foo reported as ORPHAN: {orphan}")
        ok = False

    # --- PARAMETER COMBINATION: the check reads the SELECTED source scope, not a
    #     hardcoded union. Drop the pack from the selection and its kinds stop
    #     resolving — `type:task` and `type:story` both report.
    _m5, orphan_md_only, _x5 = diff_parity(md_concrete, ns, live, md_excluded)
    if not {"type:task", "type:story"} <= set(orphan_md_only):
        print(f"FAIL source-scope arm: pack kinds still resolved with the pack "
              f"deselected: {orphan_md_only}")
        ok = False

    # --- The EXCLUDED_LIVE class, asserted in BOTH halves (#5054). A subject-only
    #     assertion is the degenerate probe this whole card is about: reclassifying a
    #     row satisfies "it is EXCLUDED_LIVE" while leaving it double-counted in
    #     ORPHAN, so the second half is what makes the first mean anything.
    if excluded_live != ["good first issue"]:
        print(f"FAIL excluded_live: {excluded_live}")
        ok = False
    if "good first issue" in orphan:
        print("FAIL excluded_live: an excluded-and-live row ALSO reported as ORPHAN")
        ok = False
    # SPECIFICITY control: an excluded row that is NOT live appears in no arm at all —
    # and specifically NOT in MISSING, which is the enforce-capable one. This is the
    # assertion that keeps the Excluded table out of the canonical union; it fails the
    # moment someone gives that table a hex col-2.
    if "zz-excluded-absent" in missing + orphan + excluded_live:
        print("FAIL excluded control: an excluded-but-absent row surfaced in an arm")
        ok = False
    # DEFAULT-PARAMETER control: the same inputs with no excluded set must route the
    # row back to ORPHAN, proving the reclassification is caused by the declaration
    # and not by some unrelated property of the name.
    _m, orphan_noexcl, excl_noexcl = diff_parity(concrete, ns, live)
    if excl_noexcl or "good first issue" not in orphan_noexcl:
        print(f"FAIL excluded default-arg control: excluded_live={excl_noexcl} "
              f"orphan={orphan_noexcl}")
        ok = False

    ok = _self_test_emit_fix() and ok
    ok = _self_test_rest_transport() and ok
    ok = _self_test_excluded_live() and ok
    ok = _self_test_list_declared_kinds() and ok
    ok = _self_test_dispositions() and ok

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

    lines, actionable = render_emit_fix(rows, live, repo="fixture-owner/fixture-repo")
    text = "\n".join(lines)

    # The DELETE block's pre-flight capture is the ONLY reconstruction record for an
    # IRREVERSIBLE deletion, so its transport is asserted, not commented. Both arms:
    # the REST spelling must be present AND the GraphQL-bound one must be absent —
    # a one-armed check would pass on a render that emitted both.
    if 'gh api "repos/fixture-owner/fixture-repo/labels?per_page=100" --paginate' not in text:
        print("FAIL: DELETE-block capture does not render the REST read with the derived slug")
        ok = False
    if "gh label list" in text:
        print("FAIL: DELETE-block capture still rides GraphQL (`gh label list`)")
        ok = False

    # The RENDERED capture above is asserted; the LIVE READ was not, so reverting
    # _gh_labels_stdout to `gh label list` passed the whole suite (#5058 Stage 8 M-2).
    # Assert the argv the live read actually builds, on the same two arms.
    _captured_argv = []

    class _FakeCompleted:
        returncode = 0
        stdout = "[]"
        stderr = ""

    _real_run = subprocess.run
    try:
        subprocess.run = lambda cmd, *a, **k: (_captured_argv.append(list(cmd)), _FakeCompleted())[1]
        _gh_labels_stdout("fixture-owner/fixture-repo")
    finally:
        subprocess.run = _real_run

    if not _captured_argv:
        print("FAIL: live-read transport arm captured no argv — the probe cannot answer")
        ok = False
    else:
        _argv = _captured_argv[0]
        if _argv[:2] != ["gh", "api"] or not any(
            a.startswith("repos/") and "/labels?per_page=" in a for a in _argv
        ):
            print(f"FAIL: live read is not the REST labels path: {_argv}")
            ok = False
        if "label" in _argv and "list" in _argv:
            print(f"FAIL: live read reverted to GraphQL (`gh label list`): {_argv}")
            ok = False
    # With no slug the block must name the flag, never emit a command against "None".
    no_slug = "\n".join(render_emit_fix(rows, live)[0])
    if "repos/None/labels" in no_slug or "--repo owner/name" not in no_slug:
        print("FAIL: slugless render does not degrade to naming --repo")
        ok = False
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


_EXCL_MD_BODY = (
    "### Category Labels\n"
    "| Label | Color | Description | Applied At |\n"
    "|---|---|---|---|\n"
    "| `improvement` | `0E8A16` (green) | x | y |\n"
    "{hdr}\n"
    "| Label | Exclusion basis |\n"
    "|---|---|\n"
    "| `question` | Not a valid issue category |\n"
)


def _self_test_excluded_live():
    """End-to-end fixture suite for the EXCLUDED_LIVE class (#5054).

    Driven through main() rather than through diff_parity, because the contract the
    consumers depend on is the emitted TSV, the text verdict line and the EXIT CODE —
    three separate surfaces that all carried the same fail-open shape, and two of
    which an internal-only assertion cannot reach.
    """
    ok = True
    md_ok = _EXCL_MD_BODY.format(hdr=_EXCLUDED_SECTION_HDR)
    md_renamed = _EXCL_MD_BODY.format(hdr="## Removed Labels")

    def _w(d, nm, text):
        p = os.path.join(d, nm)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(text)
        return p

    with tempfile.TemporaryDirectory() as td:
        src_md = _w(td, "taxonomy.md", md_ok)
        src_md_renamed = _w(td, "taxonomy-renamed.md", md_renamed)
        src_toml = _w(td, "pack.toml",
                      '[[labels]]\nname = "improvement"\ncolor = "0E8A16"\n')
        live_mixed = _w(td, "live-mixed.json", json.dumps([
            {"name": "improvement", "color": "0E8A16", "description": ""},
            {"name": "question", "color": "d876e3", "description": ""},
            {"name": "zz-orphan", "color": "ededed", "description": ""},
        ]))
        live_clean = _w(td, "live-clean.json", json.dumps([
            {"name": "improvement", "color": "0E8A16", "description": ""},
        ]))
        # An EXCLUDED_LIVE finding and NOTHING else — the isolating payload.
        live_excl_only = _w(td, "live-excl-only.json", json.dumps([
            {"name": "improvement", "color": "0E8A16", "description": ""},
            {"name": "question", "color": "d876e3", "description": ""},
        ]))

        # --- Case 0: THE EXIT CONTRACT, isolated. A run whose ONLY finding is
        #     EXCLUDED_LIVE must exit 1. This is the assertion that matters most:
        #     the old predicate `1 if (missing or orphan) else 0` returned 0 here,
        #     so every consumer reading the exit code alone — not just a human
        #     reading a log line — was told the run was clean while the tool held a
        #     finding. Paired with its clean control immediately below, so "exit 1"
        #     cannot pass merely because every fixture invocation fails.
        rc, out = _run_main_captured(["--source", src_md,
                                      "--fixture-labels", live_excl_only,
                                      "--output-format", "tsv"])
        rows = [r for r in out.splitlines() if r]
        if rc != 1:
            print(f"FAIL excluded exit contract: excluded-only run exited {rc} want 1")
            ok = False
        if rows != ["EXCLUDED_LIVE\tquestion"]:
            print(f"FAIL excluded exit contract: rows {rows} want one EXCLUDED_LIVE row")
            ok = False
        rc, out = _run_main_captured(["--source", src_md, "--fixture-labels", live_clean,
                                      "--output-format", "tsv"])
        if rc != 0 or [r for r in out.splitlines() if r]:
            print(f"FAIL excluded exit control: clean run exited {rc} with {out!r} want 0 + no rows")
            ok = False

        # --- Case 1: TSV. The excluded-and-live row lands in EXCLUDED_LIVE and NOT
        #     in ORPHAN (both halves), a genuine orphan still routes to ORPHAN (the
        #     sensitivity control), and every row is exactly 2 tab-separated fields —
        #     the shape CIAC-1 pins, unchanged by the new class.
        rc, out = _run_main_captured(["--source", src_md, "--fixture-labels", live_mixed,
                                      "--output-format", "tsv"])
        rows = [r for r in out.splitlines() if r]
        if rc != 1:
            print(f"FAIL excluded tsv: exit {rc} want 1")
            ok = False
        if "EXCLUDED_LIVE\tquestion" not in rows:
            print(f"FAIL excluded tsv: no EXCLUDED_LIVE row in {rows}")
            ok = False
        if "ORPHAN\tquestion" in rows:
            print("FAIL excluded tsv: the excluded row ALSO emitted as ORPHAN")
            ok = False
        if "ORPHAN\tzz-orphan" not in rows:
            print(f"FAIL excluded tsv control: genuine orphan missing from {rows}")
            ok = False
        widths = {len(r.split("\t")) for r in rows}
        if widths != {2}:
            print(f"FAIL excluded tsv shape: column widths {sorted(widths)} want {{2}}")
            ok = False

        # --- Case 2: TEXT mode. This is CIAC-2's own instrument: with an
        #     EXCLUDED_LIVE row present it must NOT print the parity line, and must
        #     exit 1. Before this fix it printed "in parity" and returned 0.
        rc, out = _run_main_captured(["--source", src_md, "--fixture-labels", live_mixed,
                                      "--output-format", "text"])
        if rc != 1:
            print(f"FAIL excluded text: exit {rc} want 1")
            ok = False
        if "are in parity" in out:
            print("FAIL excluded text: printed the parity line while holding a finding")
            ok = False
        if "EXCLUDED_LIVE" not in out:
            print(f"FAIL excluded text: no EXCLUDED_LIVE block in {out!r}")
            ok = False

        # --- Case 2b: the CLEAN CONTROL for Case 2. With nothing in any arm the
        #     parity line still prints and the exit is still 0 — so the absence above
        #     is caused by the finding, not by the message having been broken.
        rc, out = _run_main_captured(["--source", src_md, "--fixture-labels", live_clean,
                                      "--output-format", "text"])
        if rc != 0 or "are in parity" not in out:
            print(f"FAIL excluded text control: exit {rc} out {out!r} want 0 + parity line")
            ok = False

        # --- Case 3: the FAIL-LOUD pair. A markdown source whose § Excluded Labels
        #     heading was renamed exits 3 rather than silently reporting an empty
        #     excluded set; the pure-`.toml` invocation (no .md source at all) is
        #     exempt and must NOT exit 3. One arm without the other proves nothing.
        rc, _ = _run_main_captured(["--source", src_md_renamed,
                                    "--fixture-labels", live_mixed,
                                    "--output-format", "tsv"])
        if rc != 3:
            print(f"FAIL excluded fail-loud: renamed heading exited {rc} want 3")
            ok = False
        rc, _ = _run_main_captured(["--source", src_toml, "--fixture-labels", live_mixed,
                                    "--output-format", "tsv"])
        if rc == 3:
            print("FAIL excluded fail-loud control: pure-.toml source set exited 3")
            ok = False

        # --- Case 4: --emit-fix renders a DELETE block for the excluded-and-live row,
        #     LAST in the output, and renders no delete for a row that is merely
        #     orphaned (the specificity control — deleting an orphan is the wrong
        #     remedy and the emitter must never suggest it).
        rc, out = _run_main_captured(["--source", src_md, "--source", src_toml,
                                      "--fixture-labels", live_mixed, "--emit-fix"])
        if "gh label delete 'question' --yes" not in out:
            print("FAIL excluded emit-fix: no delete line for the excluded-and-live row")
            ok = False
        if "gh label delete 'zz-orphan'" in out:
            print("FAIL excluded emit-fix: emitted a delete for a plain ORPHAN")
            ok = False
        if out.index("--- DELETE:") < out.index("--- UNRESOLVABLE:"):
            print("FAIL excluded emit-fix: DELETE block rendered before UNRESOLVABLE")
            ok = False
        if rc != 1:
            print(f"FAIL excluded emit-fix: exit {rc} want 1 (>=1 emittable row)")
            ok = False

    return ok


_DISP_PACK = '''\
[[labels]]
name = "subject-color"
color = "AABBCC"
description = "d1"

[[labels]]
name = "subject-both"
color = "AABBCC"
description = "d1"

[[labels]]
name = "control-diverged"
color = "AABBCC"
description = "d1"

[[labels]]
name = "clean-row"
color = "AABBCC"
description = "d1"
'''


def _self_test_dispositions():
    """End-to-end fixture suite for the DIVERGED / DIVERGED-STALE arms (#5057).

    Driven through main(), not through classify_divergence, for the same reason the
    EXCLUDED_LIVE suite is: the contract the consumers depend on is the emitted TSV,
    the text verdict and the EXIT CODE, and an internal-only assertion reaches none
    of the three. Every subject arm is paired with the control that makes its result
    readable — a suppression that "works" because nothing was ever reported is the
    degenerate probe this class exists to detect.

    A pure-`.toml` source set is used deliberately: it supplies no `.md`, so the
    § Excluded Labels fail-loud is legitimately exempt and the fixture isolates the
    divergence arms with no MISSING and no ORPHAN rows to read around.
    """
    ok = True

    def _w(d, nm, text):
        p = os.path.join(d, nm)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(text)
        return p

    def _rows(out):
        return [r for r in out.splitlines() if r.strip()]

    with tempfile.TemporaryDirectory() as td:
        pack = _w(td, "pack.toml", _DISP_PACK)
        # subject-color diverges on COLOUR only; subject-both on BOTH axes;
        # control-diverged on colour and is NEVER registered; clean-row matches.
        live = _w(td, "live.json", json.dumps([
            {"name": "subject-color", "color": "FFFFFF", "description": "d1"},
            {"name": "subject-both", "color": "FFFFFF", "description": "d2"},
            {"name": "control-diverged", "color": "FFFFFF", "description": "d1"},
            {"name": "clean-row", "color": "AABBCC", "description": "d1"},
        ]))
        # Everything byte-identical — the specificity control for arm (e).
        live_clean = _w(td, "live-clean.json", json.dumps([
            {"name": "subject-color", "color": "AABBCC", "description": "d1"},
            {"name": "subject-both", "color": "AABBCC", "description": "d1"},
            {"name": "control-diverged", "color": "AABBCC", "description": "d1"},
            {"name": "clean-row", "color": "AABBCC", "description": "d1"},
        ]))
        # A genuine ORPHAN alongside the divergence — the exit-code control.
        live_orphan = _w(td, "live-orphan.json", json.dumps([
            {"name": "subject-color", "color": "FFFFFF", "description": "d1"},
            {"name": "subject-both", "color": "AABBCC", "description": "d1"},
            {"name": "control-diverged", "color": "AABBCC", "description": "d1"},
            {"name": "clean-row", "color": "AABBCC", "description": "d1"},
            {"name": "zz-orphan", "color": "ededed", "description": ""},
        ]))

        empty_reg = _w(td, "empty.txt", "# header only, no records\n")
        reg_accept = _w(td, "accept.txt",
                        "# comment\naccept-override subject-color  # deliberate\n")
        reg_axis = _w(td, "axis.txt", "accept-override:color subject-both\n")
        reg_axis_ok = _w(td, "axis-ok.txt", "accept-override:color subject-color\n")
        reg_stale = _w(td, "stale.txt", "accept-override clean-row  # no longer drift\n")
        reg_pending = _w(td, "pending.txt", "reconcile-live subject-color\n")
        reg_bad = _w(td, "bad.txt", "not-a-disposition subject-color\n")
        reg_nofield = _w(td, "nofield.txt", "accept-override\n")

        def _run(reg, fixture=live, fmt="tsv"):
            argv = ["--source", pack, "--fixture-labels", fixture,
                    "--output-format", fmt]
            if reg is not None:
                argv += ["--dispositions", reg]
            return _run_main_captured(argv)

        # --- Arm (a): AC-2's exact method. A name-matched, colour-divergent row
        #     appears in DIVERGED and in NEITHER MISSING nor ORPHAN. The negative
        #     halves are the assertion — a class that merely EXISTS while the row
        #     also reports as ORPHAN has not separated anything.
        rc, out = _run(empty_reg)
        rows = _rows(out)
        if "DIVERGED\tsubject-color" not in rows:
            print(f"FAIL disp (a): subject-color not in DIVERGED: {rows}")
            ok = False
        if any(r.startswith("MISSING\t") or r.startswith("ORPHAN\t") for r in rows):
            print(f"FAIL disp (a): a MISSING/ORPHAN row is present: {rows}")
            ok = False
        # THE EXIT CONTRACT (E8), isolated: a run whose only findings are DIVERGED
        # exits 0. Paired with the ORPHAN control below, so "exit 0" cannot pass
        # merely because the fixture produces nothing.
        if rc != 0:
            print(f"FAIL disp (a): divergence-only run exited {rc} want 0")
            ok = False
        rc_ctl, out_ctl = _run(empty_reg, fixture=live_orphan)
        if rc_ctl != 1 or "ORPHAN\tzz-orphan" not in _rows(out_ctl):
            print(f"FAIL disp (a) exit control: orphan run exited {rc_ctl}: {out_ctl!r}")
            ok = False
        # Shape (CIAC-1): every emitted row is exactly 2 tab-separated fields.
        if any(r.count("\t") != 1 for r in rows):
            print(f"FAIL disp (a): a row is not 2 tab-separated fields: {rows}")
            ok = False

        # --- Arm (b): AC-3's exact method, BOTH halves. The registered row leaves
        #     the arm WHILE the unregistered control-diverged row remains. Half one
        #     alone is satisfied by an arm that reports nothing at all.
        rc, out = _run(reg_accept)
        rows = _rows(out)
        if "DIVERGED\tsubject-color" in rows:
            print(f"FAIL disp (b): accept-override row still reported: {rows}")
            ok = False
        if "DIVERGED\tcontrol-diverged" not in rows:
            print(f"FAIL disp (b) control: unregistered divergent row vanished: {rows}")
            ok = False

        # --- Arm (c): axis-scoped suppression. `accept-override:color` on a row that
        #     ALSO diverges on description leaves it reported on the residual axis;
        #     the same qualifier on a colour-only divergence DOES suppress. Without
        #     the second half, "still reported" could just mean the qualifier is
        #     ignored entirely.
        rc, out = _run(reg_axis)
        if "DIVERGED\tsubject-both" not in _rows(out):
            print(f"FAIL disp (c): axis-scoped accept swallowed a residual axis: {_rows(out)}")
            ok = False
        rc, out = _run(reg_axis_ok)
        if "DIVERGED\tsubject-color" in _rows(out):
            print(f"FAIL disp (c) control: axis-matched accept did not suppress: {_rows(out)}")
            ok = False

        # --- Arm (d): a registry row naming a CLEAN label reports DIVERGED-STALE.
        rc, out = _run(reg_stale)
        rows = _rows(out)
        if "DIVERGED-STALE\tclean-row" not in rows:
            print(f"FAIL disp (d): stale registry row not reported: {rows}")
            ok = False
        if "DIVERGED\tclean-row" in rows:
            print(f"FAIL disp (d): a clean row also emitted as DIVERGED: {rows}")
            ok = False

        # --- Arm (e): SPECIFICITY. Byte-identical declarations produce NO row of
        #     either kind, with a non-empty declared set and a non-empty live set.
        rc, out = _run(empty_reg, fixture=live_clean)
        if rc != 0 or _rows(out):
            print(f"FAIL disp (e): clean fixture emitted {out!r} (exit {rc})")
            ok = False

        # --- Arm (f): a malformed registry record is exit 2 (usage class), not a
        #     silent skip. Two shapes: an unknown value, and a record with no
        #     second field. Control: the same run against a VALID registry exits 0.
        rc, _ = _run(reg_bad)
        if rc != 2:
            print(f"FAIL disp (f): unknown disposition value exited {rc} want 2")
            ok = False
        rc, _ = _run(reg_nofield)
        if rc != 2:
            print(f"FAIL disp (f): record with no label name exited {rc} want 2")
            ok = False
        rc, _ = _run(empty_reg)
        if rc != 0:
            print(f"FAIL disp (f) control: valid registry exited {rc} want 0")
            ok = False

        # --- A `reconcile-*` row is OWNED but still divergent, so it is still
        #     reported. This is what keeps the arm honest between the ruling and the
        #     operator-run cascade.
        rc, out = _run(reg_pending)
        if "DIVERGED\tsubject-color" not in _rows(out):
            print(f"FAIL disp: reconcile-live row stopped reporting: {_rows(out)}")
            ok = False

        # --- Registry FILE contract. Absent -> empty registry, tolerated silently
        #     (no exit 3). Present-but-unreadable -> exit 3. A directory stands in
        #     for the unreadable case: it raises an OSError that is not
        #     FileNotFoundError, which is exactly the branch under test.
        rc, _ = _run(os.path.join(td, "no-such-registry.txt"))
        if rc != 0:
            print(f"FAIL disp: absent registry exited {rc} want 0 (tolerated)")
            ok = False
        rc, _ = _run(td)
        if rc != 3:
            print(f"FAIL disp: unreadable registry exited {rc} want 3")
            ok = False

        # --- The DEFAULT registry is NOT applied to a fixture run. A registry row is
        #     a statement about one population; applied to a synthetic one, every row
        #     names a label the fixture does not carry and reports DIVERGED-STALE.
        #     This is the arm that keeps every OTHER fixture suite in this file
        #     meaningful — they invoke main() with no --dispositions, and without this
        #     guard each of them acquires one spurious stale row per registry record.
        #     Subject: no --dispositions on a fixture run -> no stale row. Control:
        #     the SAME fixture with an explicit registry naming a clean label DOES
        #     produce one, so the subject's zero is a suppression and not an
        #     unreachable arm.
        rc, out = _run(None, fixture=live)
        if any(r.startswith("DIVERGED-STALE") for r in _rows(out)):
            print(f"FAIL disp: default registry applied to a fixture run: {_rows(out)}")
            ok = False
        rc, out = _run(reg_stale, fixture=live)
        if not any(r.startswith("DIVERGED-STALE") for r in _rows(out)):
            print(f"FAIL disp control: explicit registry produced no stale row: {_rows(out)}")
            ok = False

        # --- Text format carries the mirror arms, and names the disposition on an
        #     owned row so the operator can tell "unruled" from "ruled, not yet run".
        rc, out = _run(reg_pending, fmt="text")
        if "DIVERGED" not in out or "[reconcile-live]" not in out:
            print(f"FAIL disp: text mode missing the divergence arm: {out!r}")
            ok = False
        rc, out = _run(empty_reg, fixture=live_clean, fmt="text")
        if "in parity" not in out:
            print(f"FAIL disp: clean text run did not print the parity line: {out!r}")
            ok = False

    return ok


def _self_test_list_declared_kinds():
    """Fixture suite for `--list-declared-kinds` (#5291), the #4223 extend-seam.

    Driven through main() because the two properties #4223 depends on are properties
    of the MODE, not of the parser: that it is OFFLINE, and that an empty result exits
    0. Both are contractual — #4223's self-test is discovered by
    check-selftest-coverage.py --run inside a CI step declared offline + stdlib-only,
    and this module carries a live-label read on its normal path.
    """
    ok = True

    def _w(d, nm, text):
        p = os.path.join(d, nm)
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(text)
        return p

    with tempfile.TemporaryDirectory() as td:
        pack = _w(td, "pack.toml",
                  '[meta]\nkind_id = "not-a-declared-kind"\n\n'   # outside [[kinds]]
                  "[[kinds]]\n" 'kind_id = "story"\n\n'
                  "[[kinds]]\n" 'kind_id = "epic"\n\n'
                  "[[labels]]\n" 'name = "improvement"\ncolor = "0E8A16"\n')
        nokinds = _w(td, "nokinds.toml",
                     "[[labels]]\n" 'name = "improvement"\ncolor = "0E8A16"\n')
        doc = _w(td, "taxonomy.md", "## Excluded Labels\n| `question` | prose |\n")

        # --- SUBJECT: the declared kinds are listed, `type:`-prefixed and sorted, and
        #     the `[meta]` decoy is not collected.
        rc, out = _run_main_captured(["--source", pack, "--list-declared-kinds"])
        lines = [r for r in out.splitlines() if r.strip()]
        if rc != 0:
            print(f"FAIL list-kinds: exit {rc} want 0")
            ok = False
        if lines != ["type:epic", "type:story"]:
            print(f"FAIL list-kinds: got {lines} want ['type:epic', 'type:story']")
            ok = False

        # --- EMPTY-RESULT EXIT CONTRACT: a source set declaring no kinds is a
        #     legitimate empty result, NOT a failure. This is the arm #4223 needs —
        #     a nonzero exit here would red its CI step on a correct deployment.
        #     Paired with the subject above, so "exit 0" cannot pass merely because
        #     every invocation exits 0 for an unrelated reason.
        rc, out = _run_main_captured(["--source", nokinds, "--list-declared-kinds"])
        if rc != 0 or [r for r in out.splitlines() if r.strip()]:
            print(f"FAIL list-kinds empty: exit {rc} out {out!r} want 0 + no output")
            ok = False
        # A `.md`-only source set is the same empty case by a different route: the
        # mode reads `.toml` sources only, so the grammar doc contributes nothing.
        rc, out = _run_main_captured(["--source", doc, "--list-declared-kinds"])
        if rc != 0 or [r for r in out.splitlines() if r.strip()]:
            print(f"FAIL list-kinds md-only: exit {rc} out {out!r} want 0 + no output")
            ok = False

        # --- OFFLINE, proven rather than asserted. The network leg is replaced with a
        #     function that raises; if the mode reached it, the run would fail. Note
        #     the invocation passes NEITHER --repo NOR --fixture-labels, so on the
        #     normal path it would derive a slug and fetch. Restored in `finally` so a
        #     failure here cannot corrupt the suites that follow.
        global _gh_labels_stdout
        _real = _gh_labels_stdout

        def _explode(_repo):
            raise AssertionError("--list-declared-kinds reached the network leg")

        try:
            _gh_labels_stdout = _explode
            rc, out = _run_main_captured(["--source", pack, "--list-declared-kinds"])
        finally:
            _gh_labels_stdout = _real
        if rc != 0 or [r for r in out.splitlines() if r.strip()] != ["type:epic",
                                                                    "type:story"]:
            print(f"FAIL list-kinds offline: exit {rc} out {out!r} — the mode must "
                  f"return before the repo-slug derivation and the live read")
            ok = False
        # SENSITIVITY control for the arm above: with the same stub installed, the
        # NORMAL path must fail — otherwise the offline result proves nothing, because
        # the stub was never reachable in the first place.
        try:
            _gh_labels_stdout = _explode
            rc_norm, _ = _run_main_captured(["--source", pack, "--output-format", "tsv"])
        finally:
            _gh_labels_stdout = _real
        if rc_norm != 3:
            print(f"FAIL list-kinds offline control: the normal path exited {rc_norm} "
                  f"want 3 with the network leg stubbed — the stub is not reachable, "
                  f"so the offline arm above is a broken probe")
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
            ".md reads label-table rows AND the `## Excluded Labels` section; "
            ".toml reads [[labels]] name entries. Supplying at least one .md source "
            "whose text carries no `## Excluded Labels` header is exit-3 fail-loud. "
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
        "--dispositions",
        default=None,
        help=(
            "per-row attribute-disposition registry consumed by the DIVERGED arm "
            f"(default {DISPOSITIONS_DEFAULT}, consulted only when the live set is "
            "read for real — a registry describes ONE population, so it is not "
            "applied by default to a --fixture-labels run; pass it explicitly to "
            "apply it anyway). An ABSENT file is tolerated silently as an empty "
            "registry (mirroring the readable-but-empty --source contract); a "
            "present-but-unreadable file is exit-3 fail-loud; a malformed record is "
            "exit 2 (usage class — this file is an argument, not a source)."
        ),
    )
    ap.add_argument(
        "--list-declared-kinds",
        action="store_true",
        help=(
            "READ-ONLY listing mode: print `type:<kind_id>` for every kind the .toml "
            "--source set declares, one per line, sorted. OFFLINE — no gh call and no "
            "repo-slug derivation — and exit 0 on an empty result. Both properties are "
            "contractual: the velocity instrument (#4223) consumes this rather than "
            "forking a second kind resolver, and its self-test runs in a CI step "
            "declared offline + stdlib-only."
        ),
    )
    ap.add_argument(
        "--self-test", action="store_true", help="run the fixture suite; no gh/source needed"
    )
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    sources = args.source or ["core/specs/label-taxonomy.md"]

    # LISTING MODE — returns BEFORE _derive_repo and before any live read, which is
    # what makes the offline property structural rather than incidental. An
    # unreadable --source is still fail-loud on the shared exit-3 contract; an empty
    # result is NOT a failure (a deployment whose selected packs declare no kinds is
    # a legitimate empty set), so it exits 0 with no output.
    if args.list_declared_kinds:
        kinds = set()
        for src in sources:
            if not src.lower().endswith(".toml"):
                continue
            try:
                with open(src, encoding="utf-8") as fh:
                    kinds |= parse_toml_kind_ids(fh.read())
            except OSError as e:
                print(f"source unreadable: {src}: {e}", file=sys.stderr)
                return 3
        for k in sorted(kinds):
            print(f"type:{k}")
        return 0

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
    # The EXCLUDED set is accumulated over the `.md` sources only — the grammar doc
    # owns it, and a pack must not be able to contribute or override an exclusion
    # (see the module docstring). `md_sources` is tracked so the fail-loud test below
    # can tell "no .md source was supplied" (legitimately empty) from ".md sources
    # were supplied and none carried the anchor" (the renamed-heading defect).
    excluded = set()
    md_sources, md_with_header = [], 0
    for src in sources:
        try:
            with open(src, encoding="utf-8") as fh:
                source_text = fh.read()
        except OSError as e:
            print(f"source unreadable: {src}: {e}", file=sys.stderr)
            return 3
        concrete |= parse_source(src, source_text)
        if not src.lower().endswith(".toml"):
            md_sources.append(src)
            names, header_found = parse_md_excluded_labels(source_text)
            excluded |= names
            md_with_header += 1 if header_found else 0

    # FAIL LOUD on a lost anchor, reusing the existing "registry moved/renamed"
    # exit-3 contract rather than inventing a token or a branch. A silently-empty
    # excluded set would report clean on exactly the condition the class exists to
    # detect. A pure-`.toml` invocation supplies no `.md` at all and is exempt.
    if md_sources and md_with_header == 0:
        print(
            f"no `{_EXCLUDED_SECTION_HDR}` section in any of the "
            f"{len(md_sources)} markdown source(s) ({', '.join(md_sources)}) — "
            f"registry moved/renamed? The excluded set would read empty, which is "
            f"indistinguishable from 'nothing is excluded'.",
            file=sys.stderr,
        )
        return 3

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
        lines, actionable = render_emit_fix(
            declared_rows, live_rows, sorted(n for n in live_rows if n in excluded),
            repo=repo,
        )
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

    missing, orphan, excluded_live = diff_parity(concrete, namespaces, live, excluded)

    # ATTRIBUTE DIVERGENCE (#5057) — the third question, computed ALONGSIDE the
    # name-level diff above and never folded into it. diff_parity's verdicts are
    # correct for what they assert (a NAME-level registry reconciliation); a row that
    # is live with the wrong colour or description satisfies every one of them. This
    # arm reports that class, and the registry is what makes it drainable.
    #
    # FAIL-SOFT, and only on the widened live read. If the attribute read fails, the
    # divergence arms emit NOTHING and MISSING/ORPHAN/EXCLUDED_LIVE are untouched: a
    # divergence-arm outage must never move the name-parity verdict, which is the one
    # leg that is enforce-capable. Registry problems are NOT fail-soft — an
    # unreadable file is exit 3 and a malformed record is exit 2, because a silently
    # empty registry reads as "nothing is dispositioned", which is the opposite of
    # what a missing suppression means.
    # THE DEFAULT IS CONSULTED ONLY FOR A REAL LIVE READ. A registry row is a
    # statement about ONE population — the labels this repository actually has — so
    # applying it to a synthetic one is a guaranteed false alarm: every row names a
    # label the fixture does not carry, and every row therefore reports DIVERGED-STALE.
    # An EXPLICIT --dispositions is always honoured, because a caller who names a
    # registry has said which population it describes. deploy.sh passes it explicitly
    # for exactly that reason.
    explicit_disp = args.dispositions is not None
    disp_path = args.dispositions or DISPOSITIONS_DEFAULT
    dispositions = {}
    disp_text = None
    if explicit_disp or args.fixture_labels is None:
        try:
            with open(disp_path, encoding="utf-8") as fh:
                disp_text = fh.read()
        except FileNotFoundError:
            disp_text = None  # absent registry == empty registry, tolerated silently
        except OSError as e:
            print(f"dispositions unreadable: {disp_path}: {e}", file=sys.stderr)
            return 3
    if disp_text is not None:
        try:
            dispositions = parse_dispositions(disp_text)
        except ValueError as e:
            print(f"dispositions parse error: {disp_path}: {e}", file=sys.stderr)
            return 2

    undispositioned, disp_pending, disp_stale = [], [], []
    try:
        declared_rows = {}
        for src in sources:
            if not src.lower().endswith(".toml"):
                continue
            with open(src, encoding="utf-8") as fh:
                declared_rows.update(parse_toml_label_rows(fh.read()))
        live_rows = fetch_live_label_rows(repo, args.max_labels, args.fixture_labels)
        undispositioned, disp_pending, disp_stale = classify_divergence(
            declared_rows, live_rows, dispositions
        )
    except Exception as e:  # noqa: BLE001 - fail-SOFT: see the contract above
        print(f"attribute-divergence arm not evaluated: {e}", file=sys.stderr)

    if args.output_format == "tsv":
        # Two tab-separated fields per row, same order, same separator — the shape
        # deploy.sh Check 51 parses is UNCHANGED by the new class. That is precisely
        # why a shape guard cannot see this class arriving, and why the consumer was
        # rewritten to bucket unrecognized col-1 VALUES rather than to check columns.
        for m in missing:
            print(f"MISSING\t{m}")
        for o in orphan:
            print(f"ORPHAN\t{o}")
        for x in excluded_live:
            print(f"EXCLUDED_LIVE\t{x}")
        # APPENDED AFTER the existing arms, so column count, column order and
        # separator are all unchanged — the new rows are additional ROWS, never a
        # wider shape. Undispositioned first, then dispositioned-pending: both are
        # still divergent, and the consumer aggregates them into one advisory line.
        for d in undispositioned:
            print(f"DIVERGED\t{d}")
        for d in disp_pending:
            print(f"DIVERGED\t{d}")
        for s in disp_stale:
            print(f"DIVERGED-STALE\t{s}")
    else:
        if missing:
            print("MISSING (canonical label absent from GitHub):")
            for m in missing:
                print(f"  - {m}")
        if orphan:
            print("ORPHAN (GitHub label not registered in the taxonomy):")
            for o in orphan:
                print(f"  - {o}")
        if excluded_live:
            print("EXCLUDED_LIVE (live label the taxonomy declares excluded — "
                  "delete it, or withdraw the exclusion):")
            for x in excluded_live:
                print(f"  - {x}")
        if undispositioned:
            print("DIVERGED (declared and live, but colour and/or description "
                  "differ, with no recorded disposition):")
            for d in undispositioned:
                print(f"  - {d}")
        if disp_pending:
            print("DIVERGED (dispositioned, cascade pending — the ruling is "
                  "recorded; the operator-run reconciliation has not happened):")
            for d in disp_pending:
                print(f"  - {d} [{dispositions[d][0]}]")
        if disp_stale:
            print("DIVERGED-STALE (registry row naming a label that is no longer "
                  "divergent, or no longer live — remove the row):")
            for s in disp_stale:
                print(f"  - {s}")
        if not (missing or orphan or excluded_live
                or undispositioned or disp_pending or disp_stale):
            print("label-taxonomy.md and the GitHub label set are in parity")

    # EXIT SEMANTICS DELIBERATELY UNCHANGED (#5057). DIVERGED does NOT enter this
    # expression. The class is advisory by construction — its remediation overwrites
    # live label metadata that is repository STATE and not git-revertible, and the
    # gate cannot distinguish a deliberate override from drift — so it must not be
    # able to move an exit code that a caller may branch on. deploy.sh routes it
    # through flag_advisory_only for the same reason, one layer up.
    return 1 if (missing or orphan or excluded_live) else 0


if __name__ == "__main__":
    sys.exit(main())
