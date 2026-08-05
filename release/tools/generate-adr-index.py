#!/usr/bin/env python3
"""Project the release-module ADR index from the ADR file set. All five columns derived.

WHY THIS EXISTS
---------------
`release/ADRs/README.md` carried FOUR independent hand-maintained enumerations of
one population — the index table, a prose roster in § Naming convention, a
cross-numbering table, and a scope-narrative paragraph — with four different
maxima (088 / 088 / 086 / 087). Four maxima over one file set is the proof that
they drift independently. Measured at the sweep baseline: 14 of 30 records absent
from the table, 8 of 16 present rows carrying a `Status` that contradicts the
record's own `status:`, and 9 of 16 carrying a `Title` that contradicts the
record's own `title:`.

Adding the missing rows would have fixed none of that. A hand-maintained row is a
SECOND copy of a fact the record already carries, so it re-drifts on the next
merge — and three of the four enumerations would have been left behind. The
remedy is projection: the table becomes a DERIVED surface, every column computed
from the record, and the other three enumerations are replaced by a statement of
the numbering RULE plus a pointer here.

THIS IS NOT A NEW MECHANISM. It registers under the existing Derived-Surface
Contract in `release/references/standards/release-corpus-schema.md`, which already
governs `RELEASE_INDEX.md` (projector `core/deploy/tools/generate_release_index.py`,
gated by `deploy.sh` Check 23, founding record ADR-105) and has a second in-corpus
instance in the generated hook registry (ADR-030,
`core/deploy/tools/build-hook-registry.py`). Same marker header, same
verification posture, same emission-and-custody rules.

NO SECOND PARSER
----------------
`ADR_FILE_RE` and `ADR_GLOB` are IMPORTED from `check-adr-numbers.py`, the declared
SSOT of the ADR number space. `frontmatter_bounds()` is IMPORTED from
`check-adr-durability.py`, the declared SSOT of the ADR frontmatter bound. This tool
re-encodes neither the filename regex nor the frontmatter detector: each lives in the
linter that enforces its half of the contract, and each is loaded here by path — one
pattern, one mechanism. The body-section set is not this tool's concern at all — that
is the durability lint's R5.

The frontmatter import is not stylistic. This tool originally shipped a COPY of the
bound's skip expression, and CodeQL flagged the copy and its original as one defect:
a PER-LINE comment matcher is blind to a comment that spans lines, so a marker wrapped
onto two lines makes the whole block undetectable and every column silently wrong. A
copy is a second thing to fix and a second thing to forget. The import means the next
repair to the bound lands here for free.

SCOPE — release module only
---------------------------
The population is `release/ADRs/ADR-*.md`. `core/ADRs/README.md` is deliberately
NOT projected: it is a curated thematic document, not an index (26 of 82 core
records are file-linked there; it was never an index), and that determination is
operator-ratified. Do not extend this projector to it.

DERIVATION RULES — one line per column, all five derived
--------------------------------------------------------
  ADR      the filename:            `[ADR-NNN](ADR-NNN-<slug>.md)`
  Title    frontmatter `title:`, with the leading `ADR-NNN — ` prefix stripped.
           The schema defines `title` as `ADR-NNN — <human title>` matching the H1,
           so the record's own field is the source. A record whose title carries no
           such prefix is used verbatim and reported as a visible NOTE — tolerated,
           never silently normalized.
  Status   the LEADING NYGARD TOKEN of frontmatter `status:` (`adr-schema.md` §2's
           leading-token rule). The sanctioned prose tail — a ratification anchor or
           supersession pointer — stays on the record; an index is not the place a
           ratification promise is tracked. This is what makes index status drift
           structurally impossible rather than merely currently-clean.
  Date     frontmatter `date:`, verbatim.
  Release  frontmatter `release:`, with a trailing parenthetical dropped. The tail
           is a version-binding annotation (`(v3.80 provisional; bound at Stage 12)`),
           not part of the release identity. Same shape as the Status rule: leading
           value, prose tail dropped.

  Row order: ascending by number — the corpus's own convention, and the order
  `renumber-adr.py`'s `resort_adr_table()` independently produces.

  Cell escaping: an UNESCAPED `|` in a derived value is escaped to `\\|` so it cannot
  break the table. An already-escaped `\\|` is left alone (ADR-100's own title
  carries one, so this is a live assertion and not a hypothetical).

USAGE
-----
    python3 release/tools/generate-adr-index.py --verify
        Read-only. Set-difference BOTH directions (glob − rows, rows − glob) plus a
        per-cell equality limb over every derived column. Prints its own denominator.
        Exit 0 = full match, 1 = drift, 3 = structural failure.

    python3 release/tools/generate-adr-index.py --write
        Regenerate the managed region in place. The README's prose sections are
        outside the region and are never touched.

    python3 release/tools/generate-adr-index.py --stdout
        Print the managed region. Writes nothing.

    python3 release/tools/generate-adr-index.py --self-test
        Hermetic fixtures (temp tree; no git, no network). Exit 0 = clean.

EMISSION AND CUSTODY
--------------------
The managed region is delimited and self-describing; everything outside it is
hand-authored and is neither read nor rewritten. A hand-edit INSIDE the region
fails `--verify` — that is the whole point, and it is the same posture Check 23
applies to the INDEX's derived columns. There is no hybrid source column here:
unlike `RELEASE_INDEX.Theme`, every column is derivable, so the projection is
whole-table and no round-trip limb is needed. Stated explicitly because the
contract's per-field table requires the SOURCE/DERIVED split to be declared.

Python 3.9-compatible — matches /usr/bin/python3 on the operator baseline.
"""
from __future__ import annotations

import argparse
import importlib.util
import os
import re
import sys
import tempfile
from pathlib import Path

TOOL_DIR = Path(__file__).resolve().parent


def _import_number_space():
    """Import the ADR filename contract from its SSOT (`check-adr-numbers.py`).

    Hyphens make it a non-importable module name, so it loads by path. This is a
    real import, not a copy: there is never a second filename regex to drift.
    """
    path = TOOL_DIR / "check-adr-numbers.py"
    spec = importlib.util.spec_from_file_location("check_adr_numbers", path)
    if spec is None or spec.loader is None:  # pragma: no cover - defensive
        raise RuntimeError("cannot load the ADR number-space contract from %s" % path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _import_durability_contract():
    """Import the ADR frontmatter bound from its SSOT (`check-adr-durability.py`).

    Same by-path mechanism, and for the same reason, as `_import_number_space()`
    above: the linter that ENFORCES a contract owns that contract's primitives, and
    every other tool reads them rather than re-encoding them. Loading the module is
    side-effect-free — its work is behind an `argparse` main guard.
    """
    path = TOOL_DIR / "check-adr-durability.py"
    spec = importlib.util.spec_from_file_location("check_adr_durability", path)
    if spec is None or spec.loader is None:  # pragma: no cover - defensive
        raise RuntimeError("cannot load the ADR frontmatter contract from %s" % path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


_NS = _import_number_space()
ADR_FILE_RE = _NS.ADR_FILE_RE
ADR_GLOB = _NS.ADR_GLOB

_DUR = _import_durability_contract()
# THE SHARED BOUND. Comment-tolerant (single-line AND multi-line) by construction —
# see `check-adr-durability.frontmatter_bounds`. Not re-implemented here.
frontmatter_bounds = _DUR.frontmatter_bounds

# The projected module. Deliberately singular — see the SCOPE block above.
ADR_DIR = "release/ADRs"
README_REL = "release/ADRs/README.md"

BEGIN_MARK = "<!-- ADR-INDEX:BEGIN -->"
END_MARK = "<!-- ADR-INDEX:END -->"

# The Derived-Surface Contract's header marker, byte-shaped like RELEASE_INDEX.md's.
DERIVED_SURFACE_MARKER = (
    "<!-- derived-surface: source=release/ADRs/ADR-*.md (filename + frontmatter) · "
    "projector=release/tools/generate-adr-index.py · anchor=none (no run-scoped input) · "
    "derived-columns=ADR,Title,Status,Date,Release · source-column=NONE (whole-table "
    "projection; every column is derivable, so there is no hybrid round-trip limb) · "
    "contract=release/references/standards/release-corpus-schema.md § Derived-Surface "
    "Contract · REGION-SCOPED: only the ADR-INDEX region below is projected -->"
)

TABLE_HEADER = ("| ADR | Title | Status | Date | Release |",
                "|---|---|---|---|---|")

REGION_NOTE = (
    "<!-- The table below is GENERATED from the ADR file set. Do not hand-edit a row: "
    "`generate-adr-index.py --verify` fails a hand-edit, and the record's own "
    "frontmatter is the source for every column. Add an ADR, then run "
    "`python3 release/tools/generate-adr-index.py --write`. -->"
)

# `adr-schema.md` §2 — the leading-token rule, cited not re-decided.
NYGARD = ("Proposed", "Accepted", "Deprecated", "Superseded")

FM_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):\s?(.*)$")
TITLE_PREFIX_RE = re.compile(r"^ADR-\d{3}\s*[—–-]\s*")
UNESCAPED_PIPE_RE = re.compile(r"(?<!\\)\|")


class IndexError_(Exception):
    """A structural failure: the projector cannot compute an answer (exit 3)."""


# --------------------------------------------------------------------------
# frontmatter
# --------------------------------------------------------------------------


def _unquote(value):
    """Strip matching quotes and unescape a double-quoted YAML scalar.

    Only the two escapes the corpus actually uses are handled (`\\\\` and `\\"`).
    A record needing more than that is a record this projector must not guess at.
    """
    v = value.strip()
    if len(v) >= 2 and v[0] == v[-1] and v[0] in "\"'":
        inner = v[1:-1]
        if v[0] == '"':
            inner = inner.replace('\\\\', '\x00').replace('\\"', '"').replace('\x00', '\\')
        return inner
    return v


def read_frontmatter(text):
    """Return the top-level scalar map of the leading `---` block, or None.

    The block's BOUNDS are not computed here. They come from the SHARED
    `frontmatter_bounds()` imported from `check-adr-durability.py`, so the projector
    and the durability lint can never disagree about which bytes are an ADR's
    frontmatter — and the comment tolerance (blank lines and HTML comments, SINGLE-
    LINE OR MULTI-LINE, before the opening delimiter) is inherited rather than
    re-encoded. Most of the ADR corpus opens with a marker comment; a reader that
    cannot see past one silently resolves NOTHING on those files and emits a wrong
    row for every column.

    This function owns only the SCALAR READ: top-level `key: value` pairs. A nested
    or continuation line is skipped — a record needing more than a scalar map is a
    record this projector must not guess at.
    """
    lines = text.split("\n")
    bounds = frontmatter_bounds(lines)
    if bounds is None:
        return None                        # absent, or an unterminated block
    start, end = bounds
    out = {}
    for line in lines[start + 1:end]:
        if line[:1] in (" ", "\t", "-"):
            continue                       # a nested/continuation line; not a scalar
        m = FM_KEY_RE.match(line)
        if m:
            out[m.group(1)] = m.group(2)
    return out


def leading_status_token(value):
    """The Nygard token a `status:` value begins with, or None."""
    v = re.sub(r"^[*_`\s\"']+", "", value).strip()
    for tok in NYGARD:
        if v == tok or v.startswith(tok + " ") or re.match(re.escape(tok) + r"\b", v):
            return tok
    return None


def release_slug(value):
    """`release:` with a trailing parenthetical annotation dropped."""
    return re.split(r"\s+\(", value.strip(), 1)[0].strip()


def escape_cell(value):
    """Escape an UNESCAPED `|` so a derived value cannot break the table."""
    return UNESCAPED_PIPE_RE.sub(r"\\|", value)


# --------------------------------------------------------------------------
# projection
# --------------------------------------------------------------------------


def collect_records(adr_dir):
    """[(number, filename, {column: value})] ascending, with per-file NOTEs.

    Raises IndexError_ on a record the projector cannot derive a row from — a
    missing frontmatter, a missing required field, or a `status:` whose leading
    token is outside the Nygard enum. Guessing at any of those would put a
    fabricated value into a governed surface.
    """
    d = Path(adr_dir)
    if not d.is_dir():
        raise IndexError_("the ADR directory %s does not resolve" % adr_dir)
    rows, notes = [], []
    for path in sorted(d.glob(ADR_GLOB)):
        m = ADR_FILE_RE.match(path.name)
        if not m:
            raise IndexError_("%s does not match ADR-NNN-<kebab-title>.md" % path.name)
        n = int(m.group(1))
        fm = read_frontmatter(path.read_text(encoding="utf-8"))
        if fm is None:
            raise IndexError_("%s carries no parseable frontmatter block" % path.name)
        for field in ("title", "status", "date", "release"):
            if field not in fm:
                raise IndexError_("%s carries no `%s:` frontmatter field" % (path.name, field))
        title = _unquote(fm["title"])
        stripped = TITLE_PREFIX_RE.sub("", title)
        if stripped == title:
            notes.append(
                "ADR-%03d title carries no `ADR-NNN — ` prefix (adr-schema.md §2); "
                "used verbatim" % n
            )
        token = leading_status_token(_unquote(fm["status"]))
        if token is None:
            raise IndexError_(
                "%s `status:` leading token is outside the Nygard enum (%s)"
                % (path.name, " | ".join(NYGARD))
            )
        rows.append((n, path.name, {
            "ADR": "[ADR-%03d](%s)" % (n, path.name),
            "Title": escape_cell(stripped.strip()),
            "Status": token,
            "Date": _unquote(fm["date"]).strip(),
            "Release": escape_cell(release_slug(_unquote(fm["release"]))),
        }))
    if not rows:
        raise IndexError_("no ADR files resolved under %s — the tree may have moved" % adr_dir)
    return sorted(rows, key=lambda r: r[0]), notes


def render_row(cells):
    return "| %s | %s | %s | %s | %s |" % (
        cells["ADR"], cells["Title"], cells["Status"], cells["Date"], cells["Release"])


def render_region(rows):
    """The managed region, markers included."""
    body = [BEGIN_MARK, REGION_NOTE, "", TABLE_HEADER[0], TABLE_HEADER[1]]
    body.extend(render_row(c) for _n, _f, c in rows)
    body.append(END_MARK)
    return "\n".join(body)


def split_readme(text):
    """(head, region, tail). Raises IndexError_ when the markers do not resolve."""
    b = text.find(BEGIN_MARK)
    e = text.find(END_MARK)
    if b < 0 or e < 0 or e < b:
        raise IndexError_(
            "the managed region markers %s / %s do not both resolve in %s"
            % (BEGIN_MARK, END_MARK, README_REL))
    return text[:b], text[b:e + len(END_MARK)], text[e + len(END_MARK):]


def parse_region_rows(region):
    """{number: {column: value}} parsed back out of the on-disk region."""
    out = {}
    row_re = re.compile(r"^\|\s*\[ADR-(\d+)\]")
    for line in region.split("\n"):
        m = row_re.match(line)
        if not m:
            continue
        cells = [c.strip() for c in line.strip().strip("|").split(" | ")]
        if len(cells) != 5:
            cells = [c.strip() for c in line.strip().strip("|").split("|")]
        out[int(m.group(1))] = dict(zip(("ADR", "Title", "Status", "Date", "Release"), cells))
    return out


# --------------------------------------------------------------------------
# modes
# --------------------------------------------------------------------------


def do_verify(root, out=print):
    """Set-difference both ways + per-cell equality. Returns an exit code."""
    rows, notes = collect_records(os.path.join(root, ADR_DIR))
    readme_path = os.path.join(root, README_REL)
    try:
        text = Path(readme_path).read_text(encoding="utf-8")
    except OSError as exc:
        raise IndexError_("%s is unreadable (%s)" % (README_REL, exc))
    _head, region, _tail = split_readme(text)
    if DERIVED_SURFACE_MARKER.split(" · ")[0] not in text:
        raise IndexError_(
            "%s carries no `derived-surface:` header marker — the Derived-Surface "
            "Contract requires the surface to declare itself" % README_REL)

    disk = parse_region_rows(region)
    derived = {n: c for n, _f, c in rows}

    # DENOMINATORS FIRST. A verification that does not state what it examined is
    # indistinguishable from one that examined nothing.
    out("SCANNED\t%d\t%s/%s" % (len(derived), ADR_DIR, ADR_GLOB))
    out("ROWS\t%d\t%s (managed region)" % (len(disk), README_REL))

    findings = 0
    for n in sorted(set(derived) - set(disk)):           # glob − rows
        out("MISSING\tADR-%03d\tin the ADR file set, absent from the index table" % n)
        findings += 1
    for n in sorted(set(disk) - set(derived)):           # rows − glob
        out("ORPHAN\tADR-%03d\tin the index table, absent from the ADR file set" % n)
        findings += 1
    for n in sorted(set(derived) & set(disk)):
        for col in ("ADR", "Title", "Status", "Date", "Release"):
            if disk[n].get(col) != derived[n][col]:
                out("DRIFT\tADR-%03d\t%s\tdisk=%r\tderived=%r"
                    % (n, col, disk[n].get(col), derived[n][col]))
                findings += 1
    for note in notes:
        out("NOTE\t%s" % note)

    out("COUNT\t%d" % findings)
    if findings:
        out("REMEDY\tpython3 release/tools/generate-adr-index.py --write")
        return 1
    return 0


def do_write(root, out=print):
    rows, notes = collect_records(os.path.join(root, ADR_DIR))
    readme_path = Path(os.path.join(root, README_REL))
    text = readme_path.read_text(encoding="utf-8")
    head, old_region, tail = split_readme(text)
    new_region = render_region(rows)
    if new_region == old_region:
        out("UNCHANGED\t%d row(s) — the projection already matches" % len(rows))
        for note in notes:
            out("NOTE\t%s" % note)
        return 0
    readme_path.write_text(head + new_region + tail, encoding="utf-8")
    out("WROTE\t%s\t%d row(s)" % (README_REL, len(rows)))
    for note in notes:
        out("NOTE\t%s" % note)
    return 0


# --------------------------------------------------------------------------
# self-test — hermetic fixtures, both arms
# --------------------------------------------------------------------------


_FIXTURE_ADR = """---
title: "ADR-%(n)03d — Fixture record %(n)d"
status: %(status)s
date: 2026-01-0%(d)d
release: %(release)s
---

# ADR-%(n)03d — Fixture record %(n)d
"""


def _seed(root, records):
    d = Path(root) / ADR_DIR
    d.mkdir(parents=True, exist_ok=True)
    for n, status, release, day in records:
        (d / ("ADR-%03d-fixture.md" % n)).write_text(
            _FIXTURE_ADR % {"n": n, "status": status, "release": release, "d": day},
            encoding="utf-8")
    (d / "README.md").write_text(
        DERIVED_SURFACE_MARKER + "\n# Fixture\n\n## Release-scoped ADRs\n\n"
        + BEGIN_MARK + "\n" + END_MARK + "\n\n## Tail prose\n\nuntouched.\n",
        encoding="utf-8")


def self_test():
    failures = []

    def eq(label, got, want):
        if got != want:
            failures.append("[%s] expected %r, got %r" % (label, want, got))

    # --- pure functions --------------------------------------------------
    eq("status/bare", leading_status_token("Accepted"), "Accepted")
    eq("status/prose-tail",
       leading_status_token("Proposed (flips to Accepted at Stage 9)"), "Proposed")
    eq("status/em-dash-tail",
       leading_status_token("Proposed — ratified at the operator's Stage 9"), "Proposed")
    eq("status/superseded", leading_status_token("Superseded by ADR-045"), "Superseded")
    # SPECIFICITY: a non-Nygard value must NOT resolve, or the projector would put a
    # fabricated enum into a governed surface.
    eq("status/outside-enum", leading_status_token("Draft"), None)
    eq("status/prefix-only", leading_status_token("Acceptedish"), None)

    eq("release/plain", release_slug("governance-hardening"), "governance-hardening")
    eq("release/annotated",
       release_slug("pipeline-telemetry-tail (v3.80 provisional; bound at Stage 12)"),
       "pipeline-telemetry-tail")

    eq("title/prefix-stripped",
       TITLE_PREFIX_RE.sub("", "ADR-001 — A title"), "A title")
    eq("title/no-prefix-preserved",
       TITLE_PREFIX_RE.sub("", "Records classification + retention model — 4-class"),
       "Records classification + retention model — 4-class")

    # Cell escaping, both arms. ADR-100's own title carries an ALREADY-escaped pipe,
    # so double-escaping is a live defect and not a hypothetical.
    eq("escape/bare-pipe", escape_cell("a | b"), r"a \| b")
    eq("escape/already-escaped", escape_cell(r"escaped `\|` separator"),
       r"escaped `\|` separator")

    eq("unquote/double-backslash", _unquote(r'"a \\| b"'), r"a \| b")
    eq("unquote/single", _unquote("'plain'"), "plain")
    eq("unquote/bare", _unquote("plain"), "plain")

    # --- frontmatter bound: the shared, comment-tolerant reader ----------------
    # The projector reads EVERY column out of the frontmatter, so a bound that cannot
    # find the block does not fail loudly — it emits a wrong row. These arms pin the
    # leading-comment tolerance the corpus actually depends on (70 of 115 records open
    # with a marker comment) and the MULTI-LINE case CodeQL flagged.
    _FM_BODY = "---\ntitle: \"ADR-001 — T\"\nstatus: Accepted\n---\n\n# ADR-001 — T\n"
    eq("fm/bare-delim", (read_frontmatter(_FM_BODY) or {}).get("status"), "Accepted")
    eq("fm/single-line-comment",
       (read_frontmatter("<!-- reference-durability: allow-link -->\n" + _FM_BODY)
        or {}).get("status"), "Accepted")
    eq("fm/multi-line-comment",
       (read_frontmatter("<!-- reference-durability: allow-link\n"
                         "     wrapped onto a second line -->\n" + _FM_BODY)
        or {}).get("status"), "Accepted")
    eq("fm/close-then-open-comment",
       (read_frontmatter("<!-- a --> <!-- b\n still b -->\n" + _FM_BODY)
        or {}).get("status"), "Accepted")
    # Controls — each must resolve to None, and for the stated reason.
    eq("fm/absent", read_frontmatter("# Title\n\nprose\n"), None)
    eq("fm/unterminated-block", read_frontmatter("---\ntitle: x\n"), None)
    eq("fm/unterminated-comment", read_frontmatter("<!-- never closed\nstill in\n"), None)
    eq("fm/prose-before-delim", read_frontmatter("prose\n" + _FM_BODY), None)
    # MUTATION ARM. Revert the shared bound to its pre-fix LINE-SCOPED form and the
    # multi-line case must go dark. A case that passes under both bounds is asserting
    # a property the fix did not supply. The legacy expression is imported from the
    # durability module too — reverting the fix must not require a third copy of it.
    global frontmatter_bounds
    _live, frontmatter_bounds = (frontmatter_bounds,
                                 _DUR._legacy_line_scoped_frontmatter_bounds)
    try:
        eq("fm/MUTATION-multi-line-goes-dark-on-pre-fix-bound",
           read_frontmatter("<!-- reference-durability: allow-link\n"
                            "     wrapped onto a second line -->\n" + _FM_BODY), None)
        # SPECIFICITY under the same mutation: the single-line form 70 of the shipped
        # corpus uses must read IDENTICALLY under both bounds. If this arm ever moves,
        # the fix has widened past the defect it was built for.
        eq("fm/MUTATION-single-line-unchanged-on-pre-fix-bound",
           (read_frontmatter("<!-- reference-durability: allow-link -->\n" + _FM_BODY)
            or {}).get("status"), "Accepted")
    finally:
        frontmatter_bounds = _live

    # --- fixture tree: projection + verify, both arms ---------------------
    with tempfile.TemporaryDirectory() as tmp:
        _seed(tmp, [(1, "Accepted", "alpha", 1),
                    (2, "Proposed (flips to Accepted at Stage 9)", "bravo (v9.9)", 2)])
        out = []
        rc = do_write(tmp, out.append)
        eq("write/rc", rc, 0)
        readme = (Path(tmp) / README_REL).read_text(encoding="utf-8")
        eq("write/tail-preserved", "## Tail prose" in readme, True)
        eq("write/status-token-only", "| Proposed | " in readme, True)
        eq("write/release-slug-only", "| bravo |" in readme, True)
        eq("write/row-count", readme.count("\n| [ADR-"), 2)

        # SUBJECT ARM — a freshly-written region verifies clean.
        out = []
        eq("verify/clean", do_verify(tmp, out.append), 0)
        eq("verify/prints-denominator",
           any(l.startswith("SCANNED\t2") for l in out), True)
        eq("verify/prints-row-denominator",
           any(l.startswith("ROWS\t2") for l in out), True)

        # CONTROL ARM 1 — delete a row: the check must FAIL with MISSING.
        text = (Path(tmp) / README_REL).read_text(encoding="utf-8")
        cut = "\n".join(l for l in text.split("\n") if "[ADR-002]" not in l)
        (Path(tmp) / README_REL).write_text(cut, encoding="utf-8")
        out = []
        eq("verify/deleted-row-fails", do_verify(tmp, out.append), 1)
        eq("verify/deleted-row-names-it",
           any(l.startswith("MISSING\tADR-002") for l in out), True)

        # CONTROL ARM 2 — hand-edit a derived cell: the check must FAIL with DRIFT.
        do_write(tmp, lambda _m: None)
        text = (Path(tmp) / README_REL).read_text(encoding="utf-8")
        (Path(tmp) / README_REL).write_text(
            text.replace("| Proposed | 2026-01-02", "| Accepted | 2026-01-02"),
            encoding="utf-8")
        out = []
        eq("verify/hand-edited-cell-fails", do_verify(tmp, out.append), 1)
        eq("verify/hand-edited-cell-names-column",
           any(l.startswith("DRIFT\tADR-002\tStatus") for l in out), True)

        # CONTROL ARM 3 — an orphan row (a record deleted from the file set).
        do_write(tmp, lambda _m: None)
        (Path(tmp) / ADR_DIR / "ADR-002-fixture.md").unlink()
        out = []
        eq("verify/orphan-row-fails", do_verify(tmp, out.append), 1)
        eq("verify/orphan-row-names-it",
           any(l.startswith("ORPHAN\tADR-002") for l in out), True)

    # --- end-to-end: a record whose file opens with a MULTI-LINE comment ---
    # The arms above are unit-level. This one drives the WHOLE projector over a record
    # shaped like the corpus's marker convention but wrapped onto two lines. The failure
    # it guards is not an exception — it is a wrong row emitted quietly.
    with tempfile.TemporaryDirectory() as tmp:
        _seed(tmp, [(1, "Accepted", "alpha", 1)])
        fp = Path(tmp) / ADR_DIR / "ADR-001-fixture.md"
        fp.write_text("<!-- reference-durability: allow-link\n"
                      "     wrapped onto a second line -->\n"
                      + fp.read_text(encoding="utf-8"), encoding="utf-8")
        try:
            rows, _notes = collect_records(os.path.join(tmp, ADR_DIR))
            eq("e2e/multi-line-comment-row-count", len(rows), 1)
            eq("e2e/multi-line-comment-status", rows[0][2]["Status"], "Accepted")
            eq("e2e/multi-line-comment-title", rows[0][2]["Title"], "Fixture record 1")
            eq("e2e/multi-line-comment-write", do_write(tmp, lambda _m: None), 0)
            eq("e2e/multi-line-comment-verify-clean", do_verify(tmp, lambda _m: None), 0)
        except IndexError_ as exc:
            # A bound that cannot see the marker reports the RECORD as unparseable.
            # Name it as a failure rather than letting it abort the suite: a traceback
            # here reads as a broken test, and it is a broken PROJECTOR.
            failures.append("[e2e/multi-line-comment] the record was unreadable: %s" % exc)

    # --- structural failures are exit 3, never a silent clean -------------
    with tempfile.TemporaryDirectory() as tmp:
        _seed(tmp, [(1, "Draft", "alpha", 1)])
        try:
            collect_records(os.path.join(tmp, ADR_DIR))
            failures.append("[structural/non-nygard] expected IndexError_, got none")
        except IndexError_:
            pass
    with tempfile.TemporaryDirectory() as tmp:
        _seed(tmp, [(1, "Accepted", "alpha", 1)])
        p = Path(tmp) / ADR_DIR / "ADR-001-fixture.md"
        p.write_text("# no frontmatter here\n", encoding="utf-8")
        try:
            collect_records(os.path.join(tmp, ADR_DIR))
            failures.append("[structural/no-frontmatter] expected IndexError_, got none")
        except IndexError_:
            pass
    with tempfile.TemporaryDirectory() as tmp:
        _seed(tmp, [(1, "Accepted", "alpha", 1)])
        rp = Path(tmp) / README_REL
        rp.write_text(rp.read_text(encoding="utf-8").replace(END_MARK, ""), encoding="utf-8")
        try:
            do_verify(tmp, lambda _m: None)
            failures.append("[structural/missing-marker] expected IndexError_, got none")
        except IndexError_:
            pass

    if failures:
        print("generate-adr-index self-test: FAIL")
        for f in failures:
            print("  - " + f)
        return 1
    print("generate-adr-index self-test: PASS (derivation rules / escaping / "
          "shared frontmatter bound: 4 tolerance + 4 control + 2 mutation arms / "
          "write / verify clean + 3 control arms / multi-line-comment end-to-end / "
          "3 structural-failure arms)")
    return 0


# --------------------------------------------------------------------------


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Project the release-module ADR index from the ADR file set.")
    ap.add_argument("--verify", action="store_true",
                    help="read-only: set-difference both ways + per-cell equality; "
                         "exit 1 on drift, 3 on structural failure")
    ap.add_argument("--write", action="store_true",
                    help="regenerate the managed region in place")
    ap.add_argument("--stdout", action="store_true",
                    help="print the managed region; write nothing")
    ap.add_argument("--self-test", action="store_true")
    ap.add_argument("--root", default=None,
                    help="repo root (default: inferred from this file's location)")
    args = ap.parse_args(argv)

    if args.self_test:
        return self_test()

    root = args.root or str(TOOL_DIR.parent.parent)
    try:
        if args.stdout:
            rows, _notes = collect_records(os.path.join(root, ADR_DIR))
            print(render_region(rows))
            return 0
        if args.write:
            return do_write(root)
        if args.verify:
            return do_verify(root)
    except IndexError_ as exc:
        print("ERROR\t%s" % exc, file=sys.stderr)
        return 3

    ap.print_help()
    return 1


if __name__ == "__main__":
    sys.exit(main())
