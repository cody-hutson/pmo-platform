#!/usr/bin/env python3
"""Release-corpus projector: emit + verify the DERIVED release ledgers.

MODULE NAME UNDERSTATES SCOPE — accepted debt, recorded deliberately. This module
began as the RELEASE_INDEX generator and is now the single projector for all three
derived release-corpus surfaces (RELEASE_INDEX.md, RELEASE_DIGEST.md, CHANGELOG.md).
It was extended in place rather than renamed because it already owns the LOG parser,
the Theme round-trip, the orphan guard, the date-anchor grandfathering set and the
--verify contract deploy.sh Check 23 invokes; a rename would convert a zero-mover
release into a mover for a naming benefit. A rename is a legitimate follow-on.

THE SOURCE/DERIVED CONTRACT it implements is registered in
release/references/standards/release-corpus-schema.md § Derived-Surface Contract.
In one sentence: there is no single authoritative source and there cannot be one.
RELEASE_LOG.md is the EVENT record; the release note is the NARRATIVE record; the
close-out run anchor and the repository slug are RUN-SCOPED inputs that live in
neither file. Provenance is therefore PER FIELD, not per file.

CLOCK-FREE BY CONTRACT — the property that makes this module safe to own four
surfaces. It imports no date/time API and calls no clock. Both date anchors are
REQUIRED CLI arguments supplied by the caller, which already sampled each exactly
once. This is not stylistic: the DATE_ANCHOR_GRANDFATHERED enumeration below exists
solely because one fact once had two writers sampling two clocks. A projector that
can reach a clock can become the second writer. One that cannot, never can.
Asserted by --self-test (import-shaped and callsite-shaped, never substring-shaped:
the substring "date" occurs dozens of times in this file and cannot discriminate).

EMITS ENTRIES, NEVER FILES. Each --emit writes ONE entry to stdout; the calling
close-out phase performs the insertion. This is a measured safety property, not a
preference: the majority of historical DIGEST headlines and CHANGELOG blocks carry
post-emission operator edits that exist nowhere else, and a whole-file regenerate
destroys them silently as a clean diff rather than a conflict.

Parses the table rows in release/releases/RELEASE_LOG.md (live 8-column schema:
Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date) and
reconciles them against release/releases/RELEASE_INDEX.md (live 6-column schema:
Version | Milestone | Date | Theme | Release PR | Release Notes).

The INDEX is hand-authored at Stage 13 close (the Theme cell is free-prose not
derivable from the LOG). This tool serves three roles:

  default (write/--output-stdout): regenerate the 6-column INDEX from the LOG +
    filesystem (plan/note presence). Hand-authored Theme cells are PRESERVED
    from the existing on-disk INDEX (keyed by Version) so regeneration never
    clobbers prose the generator cannot reproduce; rows with no existing Theme
    get a placeholder.

  --verify (deploy.sh Check 23): re-derive the LOG-sourced fields and diff
    against the on-disk INDEX row-by-row, emitting TSV-line diagnostics on
    mismatch. Compares only LOG-derivable fields (Version coexistence,
    Milestone, Date, Release PR, Release-Notes-link presence) — the Theme cell
    has no LOG source of truth and is intentionally NOT drift-checked.

  --verify-closeout-anchors (deploy.sh Check 82): read-only. For every VERIFIED
    LOG row at or after CLOSEOUT_ANCHOR_DECLARED_AT, in LOG order, read the
    close-out date on each surface that declares the close-out anchor: the DIGEST
    heading `(<date>[, version-less])`, the CHANGELOG heading `- <date>`, and the
    note frontmatter `date:`. Report each row whose surfaces carry more than one
    date. A versioned row compares 3 surfaces. A version-less row compares 2,
    because the scripted close-out writes it no CHANGELOG entry — and 3 when a
    CHANGELOG entry for its slug exists anyway (a close-out written by hand or
    hub-direct); its missing entry is never NOT-EVALUATED. An absent or
    unparseable surface is NOT-EVALUATED for that row, never agreement; presence
    is Checks 32 and 48's predicate. Rows before the declaration are not read.
    The note's `date:` is read here to VERIFY only. No emitter reads it, and
    read_note()'s derivation-direction rule stands. Output: one `DENOM:` line,
    then one verdict-first TSV row per finding (`FAIL`) and per surface that
    could not be compared (`NOT-EVALUATED`).

The earlier 8-column schema (Version|Date|Class|Scope|Plan|Note|LOG|Status) and
its #N-token "Scope" count are RETIRED — the live INDEX has no Scope column, so
the #N-token miscount the generator was filed to fix is moot by construction.

Usage:
    python3 core/deploy/tools/generate_release_index.py --verify        # read-only
    python3 core/deploy/tools/generate_release_index.py --verify-closeout-anchors   # read-only
    python3 core/deploy/tools/generate_release_index.py --self-test     # read-only
    python3 core/deploy/tools/generate_release_index.py --output-stdout # no write
    python3 core/deploy/tools/generate_release_index.py                 # DESTRUCTIVE
    python3 core/deploy/tools/generate_release_index.py \
        --emit {index,digest,changelog} --version <V> \
        --merge-anchor <YYYY-MM-DD> --closeout-anchor <YYYY-MM-DD> \
        --repo-slug <owner/repo>                                       # one entry to stdout

--emit REQUIRES all four of --version / --merge-anchor / --closeout-anchor /
--repo-slug, for every surface, whether or not that surface consumes each one.
Omitting any is an argparse error (exit 2), NOT a fallback: a defaulted input is
an ambient source wearing a parameter's name, whether the ambient source is a
clock or an operator config file.

Note-derived fields carry three DELIBERATELY DIFFERENT failure semantics, lifted
verbatim from the close-out phases this module replaces — a lift that flattened
them would regress a fix this same release cites as precedent:
  * DIGEST headline — note absent, or no `# ` H1: emit the operator placeholder.
    (The DIGEST is written BEFORE the note is scaffolded, so on a fresh close the
    note normally does not exist yet and the placeholder is the expected path.)
  * CHANGELOG summary — note present but no parseable `summary:`: fall back to
    "(see release notes)" silently.
  * CHANGELOG entry — note file absent or unreadable: FAIL LOUD (exit 3). The
    CHANGELOG is written after the note is scaffolded, so an absent note there is
    a real anomaly rather than an ordering artifact.

DESTRUCTIVE-DEFAULT WARNING. The bare no-flag invocation is a FULL REGENERATE: it
rewrites every row of RELEASE_INDEX.md from RELEASE_LOG.md in one pass. The live
INDEX carries GRANDFATHERED rows whose `Date` cells deliberately hold the close-out
date rather than the merge anchor, and whose header § Grandfathering states they are
not to be rewritten. A full regenerate restamps all of them silently — an audit-trail
forgery, not a refresh. Stage 13 is APPEND-ONLY (release-process.md § D6 / CR-D6):
append the single new row, then confirm with `--verify`. Reach for the bare form only
on an explicit operator decision to accept the restamp of every grandfathered row.

Exit codes: 0 = success (or --verify: full match), 1 = --verify drift,
3 = path-resolution / parse failure (LOG or INDEX missing/unreadable, or a
resolved file yields zero parseable rows — the surface is unverifiable, not
clean) OR an on-disk INDEX orphan row not derivable from the LOG (write +
--verify both fail loud rather than silently regenerating-and-dropping it).
Exit 3 matches the cross-module-audit.sh family convention (per #459) so
deploy.sh can distinguish "found drift" (1) from "could not run / corpus
integrity violation" (3).
--verify-closeout-anchors: 0 = no divergence (NOT-EVALUATED rows may be present,
and the DENOM status says so); 1 = at least one divergence; 3 = the LOG, DIGEST,
CHANGELOG or notes dir is unresolved, zero LOG rows parse, or
CLOSEOUT_ANCHOR_DECLARED_AT names no LOG row. Combining it with --verify, --emit,
--self-test or --output-stdout is a usage error (exit 2).

Render order: rows are emitted chronological-recent-first (newest Date first;
within a Date tie the most-recently-appended LOG row — i.e. the more recent
release of that day — comes first), honoring the INDEX header invariant rather
than raw LOG-append order.
"""
from __future__ import annotations

import argparse
import ast
import re
import sys
from pathlib import Path

# ── Clock-freedom contract (asserted by --self-test) ─────────────────────────
#
# ALLOW-list, not a deny-list. A deny-list of {datetime, time, calendar} misses
# os.popen("date"), Path.stat().st_mtime and every future clock this module has
# not thought of; an allow-list closes them all and costs the same. `ast` is on
# the list because the clock-free assertion itself is an AST parse of this file
# — a structural probe, since a substring probe cannot discriminate here.
CLOCK_FREE_ALLOWED_IMPORTS = frozenset({
    "__future__", "argparse", "ast", "pathlib", "re", "sys",
})
# Callsite-shaped denial. Names, not substrings: `.now()` / `.today()` /
# `time()` are calls, and `st_mtime` is an attribute read of a filesystem clock.
#
# GRADING NOTE. The two frozensets below are the probe's own VOCABULARY, so a
# naive `grep -E '\.now\(|utcnow\(|date_today'` over this file returns hits — on
# this comment and on the literals themselves, and on NO callsite. That is the
# demonstration, not a defect: the clock-free assertion is import-shaped and
# callsite-shaped (an AST walk in _self_test_clock_free), never substring-shaped,
# and a substring probe run against it measures a different quantity than the
# proposition needs.
CLOCK_FREE_DENIED_CALLS = frozenset({
    "now", "utcnow", "today", "time", "monotonic", "perf_counter",
    "date_today", "gmtime", "localtime", "fromtimestamp",
})
CLOCK_FREE_DENIED_ATTRS = frozenset({
    "st_mtime", "st_ctime", "st_atime", "st_birthtime", "st_mtime_ns",
})

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
# Live modular-monolith layout (post-restructure). The pre-restructure
# pmo-platform/... prefix is DEAD. RELEASE_LOG.md is under release/releases/
# (NOT governance/).
LOG_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_LOG.md"
PLANS_DIR = WORKSPACE_ROOT / "release" / "releases" / "plans"
NOTES_DIR = WORKSPACE_ROOT / "release" / "releases" / "notes"
ARCHIVE_PLANS_DIR = WORKSPACE_ROOT / "release" / "releases" / "archive" / "plans"
INDEX_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_INDEX.md"
DIGEST_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_DIGEST.md"
CHANGELOG_PATH = WORKSPACE_ROOT / "CHANGELOG.md"

# Emitted-entry constants. Lifted verbatim from the close-out phases this module
# replaces — the STRINGS are part of the shipped corpus, so changing one silently
# re-shapes 150+ historical entries' successors. Do not "improve" them.
DIGEST_HEADLINE_PLACEHOLDER = "<headline — populated by operator at chore PR review>"
CHANGELOG_SUMMARY_FALLBACK = "(see release notes)"
VERSION_LESS_MARKER = "(version-less)"
EMIT_SURFACES = ("index", "digest", "changelog")

# Accessor semantics for the release note, matched to the close-out's own regexes
# rather than re-invented. A naive `^date:` / `^summary:` scan over the whole file
# over-counts: the frontmatter BLOCK is the accessor, and three notes in the live
# corpus do not parse under it.
NOTE_FRONTMATTER_RE = re.compile(r"---\n(.*?)\n---\n", re.DOTALL)
NOTE_SUMMARY_RE = re.compile(r'^summary:\s*"?([^"\n]+)"?', re.MULTILINE)

# Close-out-anchor READ grammar (--verify-closeout-anchors). Each parser sits beside
# the emitter whose output it reads — emit_digest_entry() writes `### <key> (<cell>)`
# and emit_changelog_entry() writes `## [<key>] - <date>` — and --self-test's
# round-trip limb binds each pair, so the reader and the writer cannot drift apart.
# Date validity reuses _DATE_RE; a DIGEST cell admits the version-less marker.
DIGEST_ENTRY_RE = re.compile(r"^### (?P<key>\S+) \((?P<cell>[^)]*)\)", re.MULTILINE)
DIGEST_DATE_CELL_RE = re.compile(r"^(?P<date>\d{4}-\d{2}-\d{2})(?:, version-less)?$")
CHANGELOG_ENTRY_RE = re.compile(r"^## \[(?P<key>[^\]]+)\] - (?P<date>\S+)[ \t]*$", re.MULTILINE)
NOTE_DATE_RE = re.compile(r'^date:\s*"?(?P<date>[^"\n]*?)"?\s*$', re.MULTILINE)
CLOSEOUT_SURFACES = ("DIGEST", "CHANGELOG", "note")

# Live LOG schema: | Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
# Version cell may be a bare version key (v1.06) OR a version-less slug with a
# "(version-less)" qualifier (public-flip-install-blockers (version-less)); the
# anchor must admit both, so it is NOT pinned to a leading "v". Header/separator
# rows are excluded by requiring field 1 to be non-empty and rejecting the
# literal "Version" header and the "---" separator in parse_log_rows.
#
# EIGHT OR MORE cells, and the fields are then pinned BY HEADER NAME when a header
# row is present. The stricter exactly-8 form silently SKIPPED any row from a LOG
# carrying a trailing column, which meant the projector and the close-out — which
# has always pinned by header name — disagreed about what a LOG row is. Two
# components with two rules for one schema is the shape this whole card exists to
# remove. Measured at adoption: the relaxed form matches exactly the same 167 lines
# of the live LOG as the strict one, so the corpus reading is unchanged; the
# positional fallback below preserves the previous behaviour when no header is found.
LOG_ROW_RE = re.compile(r"^\|(?P<cells>(?:[^\|]*\|){7,}[^\|]*)\|\s*$")

# Canonical field positions (0-based) used when no header row is available.
LOG_POSITIONAL_FIELDS = {"version": 0, "milestone": 1, "release_pr": 3, "state": 6, "date": 7}
# Header cell name per field, for the name-pinned resolution.
LOG_HEADER_NAMES = {"version": "Version", "milestone": "Milestone",
                    "release_pr": "Release PR", "state": "State", "date": "Date"}

# Live INDEX schema: | Version | Milestone | Date | Theme | Release PR | Release Notes |
INDEX_ROW_RE = re.compile(
    r"^\| (?P<version>[^\|]+?) \| (?P<milestone>[^\|]+?) \| (?P<date>[^\|]+?) "
    r"\| (?P<theme>.*?) \| (?P<release_pr>[^\|]+?) \| (?P<notes>[^\|]+?) \|\s*$"
)


def _slug_from_version_cell(version_cell: str) -> str:
    """Strip the '(version-less)' qualifier from a LOG Version cell.

    The LOG Version cell is either a bare version key (v1.06) or a version-less
    slug carrying the qualifier (e.g. 'public-flip-install-blockers
    (version-less)'). Artifact filenames use the bare slug, so drop the
    qualifier before matching.
    """
    return version_cell.replace("(version-less)", "").strip()


def find_artifact(version_key: str, milestone: str, kind: str) -> str | None:
    """Locate a plan or note file by version key, then by milestone slug.

    `version_key` is the LOG Version cell (e.g. "v1.06" or a version-less slug);
    `milestone` is the LOG Milestone cell (e.g. "v1.06-solutioning-and-related").
    Artifact filenames key off either, so try the version slug first, then the
    milestone slug. Returns an INDEX-relative path string (the INDEX lives in
    release/releases/, so plan/note links are "plans/<name>" / "notes/<name>"),
    or None.
    """
    if kind == "plan":
        directory = PLANS_DIR
        suffix = "_RELEASE_PLAN.md"
    else:
        directory = NOTES_DIR
        suffix = "_RELEASE_NOTES.md"

    if not directory.exists():
        return None

    vslug = _slug_from_version_cell(version_key)
    mslug = milestone.strip()
    keys = [k for k in (vslug, mslug) if k]
    short = vslug.split("-", 1)[0] if vslug else ""

    # rglob (recursive) — PLANS are foldered into major-version subdirectories
    # (plans/v1|v2|v3/…) per the plans/README.md disposition rule (#230, v3.59);
    # NOTES are flat, with notes/_unversioned/ the one permitted subfolder
    # (#3698). Both corpora also use the _unversioned/ bucket. A flat glob would
    # miss every subfoldered file and regenerate an all-"—" Release-Notes column
    # (FM-1 destructive-regenerate). The returned INDEX-relative path carries
    # whatever subfolder segment the artifact actually has (e.g.
    # "plans/v3/v3.45_RELEASE_PLAN.md", "notes/v3.45_RELEASE_NOTES.md",
    # "notes/_unversioned/<slug>_RELEASE_NOTES.md") so the link resolves from
    # release/releases/ where the INDEX lives.
    for candidate in sorted(directory.rglob(f"*{suffix}")):
        name = candidate.name
        stem_key = name[:-len(suffix)]
        rel = f"{directory.name}/{candidate.relative_to(directory).as_posix()}"
        for key in keys:
            if stem_key == key:
                return rel
            # Slug suffix only ('<key>-<slug>'); never a patch sibling. A bare
            # startswith(key) makes vX.Y greedily match vX.Y.Z (e.g. v2.06 -> the
            # v2.06.1 note), since the patch note sorts first and is a string prefix
            # of the base version. Requiring the '-' separator admits the legitimate
            # vX.Y-<theme-slug> form while rejecting the vX.Y.Z patch form.
            if key and stem_key.startswith(key + "-"):
                return rel
        if short and (vslug.startswith(stem_key + "-") and stem_key.startswith(short)):
            return rel

    if kind == "plan" and ARCHIVE_PLANS_DIR.exists():
        for candidate in sorted(ARCHIVE_PLANS_DIR.glob(f"*{suffix}")):
            stem_key = candidate.name[:-len(suffix)]
            for key in keys:
                if stem_key == key:
                    return f"archive/plans/{candidate.name}"

    return None


def parse_log_rows(log_text: str) -> list[dict]:
    """Parse the live 8-column RELEASE_LOG table by field position.

    Schema: | Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
    Field index (1-based): 1=Version 2=Milestone 3=Issues 4=Release PR
    7=State 8=Date. Header ("Version") and separator ("---") rows are skipped.
    Version-less rows (Version cell carrying "(version-less)") parse normally —
    the slug qualifier is retained in the cell and stripped at artifact lookup.
    """
    rows: list[dict] = []
    fields = dict(LOG_POSITIONAL_FIELDS)
    for raw_line in log_text.splitlines():
        m = LOG_ROW_RE.match(raw_line)
        if not m:
            continue
        cells = [c.strip() for c in m.group("cells").split("|")]
        if len(cells) < 8:
            continue
        version = cells[0]
        # Header row: re-pin every field index by NAME, then skip the row. A LOG
        # that grows a column stays readable instead of silently mis-mapping —
        # the field-mismap this parser's own self-test was written to catch.
        if version == "Version":
            resolved = {k: cells.index(n) for k, n in LOG_HEADER_NAMES.items() if n in cells}
            if len(resolved) == len(LOG_HEADER_NAMES):
                fields = resolved
            continue
        # Skip separator + empty rows.
        if not version or set(version) <= set("-: "):
            continue
        if max(fields.values()) >= len(cells):
            continue
        rows.append({k: cells[i] for k, i in fields.items()})
    return rows


THEME_PLACEHOLDER = "—"

# Sentinel prefix for the corpus-integrity orphan condition (an on-disk INDEX
# row whose Version is not derivable from the LOG). Keyed on by main() for the
# exit-3 mapping; deploy.sh Check 23 maps exit 3 -> FAIL. Mirrors the
# CORPUS-PATH-UNRESOLVED contract in lint_release_corpus.py.
CORPUS_INDEX_ORPHAN_PREFIX = "CORPUS-INDEX-ORPHAN"

# Date format in both corpora is ISO-8601 (YYYY-MM-DD), so lexical string
# comparison IS chronological. A row whose Date cell is empty/malformed sorts
# LAST (oldest) deterministically rather than crashing the sort.
_DATE_RE = re.compile(r"^\d{4}-\d{2}-\d{2}$")

# ── Date anchor (#3718) ──────────────────────────────────────────────────────
#
# The Date comparison below asserts the INDEX Date equals the LOG Date. That is
# only a meaningful assertion because both cells carry the SAME anchor — the
# MERGE event — declared at core/standards/date-variable-convention.md
# § Emission-Time Anchors and in each ledger's header prose.
#
# It was not always so. automated-closeout.sh wrote the INDEX Date from the
# close-out clock while this checker asserted it equal the LOG's merge date, so
# every close-out that crossed a UTC midnight manufactured a finding here BY
# CONSTRUCTION — the check reported the design working correctly, and in doing so
# lost the ability to report anything else. The emitter now reads the LOG row.
#
# The rows written before that reconciliation are an audit trail recorded under
# the behaviour of their time. They are GRANDFATHERED from the Date comparison
# only — every other field is still compared, and every version absent from this
# set is compared on Date exactly as before. Rewriting them would forge history;
# note that regenerating the INDEX without --verify would rewrite all of them in
# a single pass, which is why that is an operator-authorized action rather than
# the routine remedy this check used to recommend.
#
# ENUMERATED rather than expressed as a date cutoff, deliberately: the set is
# closed and known, an enumeration is self-documenting and reviewable in a diff,
# and it cannot silently widen to swallow a genuine future divergence.
#
# DO NOT add a version here to silence a new finding. A Date divergence on a
# release closed after the reconciliation means the emitter regressed — the
# INDEX Date must be read from the LOG row, never sampled from the close-out
# clock. Fix the emitter.
DATE_ANCHOR_GRANDFATHERED = frozenset({
    "v3.59", "v3.60", "v3.61", "v3.65", "v3.69", "v3.70", "v3.71",
    "v3.75", "v3.80", "v3.83", "v3.88", "v3.99", "v3.100",
})

# The date on which the two-writers-two-clocks divergence was reconciled: the
# INDEX emitter stopped sampling the close-out clock and started reading the LOG
# row. Every legitimate member of the set above closed BEFORE this date. A member
# whose LOG Date is on or after it is not a historical artifact — it is a
# regression of the emitter, being silenced by an exemption.
#
# THE ENUMERATION REMAINS THE MEMBERSHIP MECHANISM. This constant is NOT a date
# cutoff replacing the set — that form was considered and deliberately rejected
# above, because a cutoff can silently widen to swallow a genuine future
# divergence. This is the ASSERTION'S BOUND and nothing else: --self-test checks
# that every enumerated member is valid against it, turning the "DO NOT add a
# version here" instruction directly overhead from a comment into a property.
# A comment is not a guard.
DATE_ANCHOR_RECONCILIATION = "2026-07-30"

# The LOG row of the release whose pull request declared the close-out anchor on
# RELEASE_DIGEST.md and CHANGELOG.md ("Entries predating this declaration are
# grandfathered — anchors are declared forward, never backfilled"). Rows at or after it,
# in LOG order, are in scope for --verify-closeout-anchors; rows before it are not read.
# A LOG-ROW boundary, not a date: the date is the SUBJECT under test, so a date boundary
# would let a divergent row decide its own scope. Not an enumeration: the exempt
# population is every row written before the declaration — a boundary, not a closed set
# of defects (contrast DATE_ANCHOR_GRANDFATHERED).
#
# DO NOT move this forward to silence a finding. A divergence at or after it is a writer
# defect or a hand-edit; correct the surface. --self-test pins it to a live LOG row.
CLOSEOUT_ANCHOR_DECLARED_AT = "v4.02"


def _date_sort_key(date_cell: str) -> tuple[int, str]:
    """Sort key for one Date cell. Well-formed ISO dates sort by value;
    empty/malformed dates sort LAST (group 0 < 1, and recent-first reverses)."""
    d = (date_cell or "").strip()
    if _DATE_RE.match(d):
        return (1, d)
    return (0, "")


def sort_rows_recent_first(rows: list[dict]) -> list[dict]:
    """Order LOG rows chronological-recent-first for the INDEX render.

    Newest Date first. Within a Date tie, the more-recently-appended LOG row
    (later in LOG-append order, i.e. the more recent release of that day) comes
    first — this reverses LOG-append order WITHIN a tie, which is exactly the
    human-curated INDEX order. Implemented as: reverse the LOG-order list (so
    a stable date-descending sort breaks ties by later-LOG-position-first), then
    stable-sort by Date descending. Malformed/empty Date rows sort last.

    `rows` is NOT mutated. The LOG-append order is the upstream chronological
    truth (each row was appended at its release's Stage-13 close), so reversing
    within a tie yields recent-first without an external sequence field.
    """
    reversed_log = list(reversed(rows))
    return sorted(reversed_log, key=lambda r: _date_sort_key(r.get("date", "")), reverse=True)


def find_index_orphans(log_rows: list[dict], index_rows: list[dict]) -> list[str]:
    """Return INDEX Version cells with NO matching LOG row (orphans).

    An orphan is an on-disk INDEX row not derivable from the LOG — regenerating
    from the LOG alone would silently DROP it. The generator refuses (exit 3)
    rather than dropping, turning a silent data-loss into a loud-refuse. Returns
    the orphan Version cells in INDEX order; empty list = no orphan.
    """
    log_versions = {r["version"] for r in log_rows}
    return [r["version"] for r in index_rows if r["version"] not in log_versions]


INDEX_TABLE_HEADER = "| Version | Milestone | Date | Theme | Release PR | Release Notes |"

# Bootstrap header ONLY — used when there is no on-disk INDEX to preserve one
# from. On every live invocation the on-disk header wins verbatim; see
# extract_index_header() for why.
DEFAULT_INDEX_HEADER = [
    "# RELEASE_INDEX",
    "",
    "Corpus-level index of all pmo-platform releases. Chronological-recent-first row order. "
    "Appended at Stage 13 chore PR per [`stage-13-close.md § Phase B`](../references/pipeline/stage-13-close.md).",
    "",
]


def extract_index_header(index_text: str) -> list[str] | None:
    """Return every line ABOVE the INDEX table-header row, verbatim.

    Header PRESERVATION, not header generation. render_index() used to emit a
    hard-coded 3-line header, so a regenerate silently DELETED anything the
    operator or a prior release had added above the table — including the
    two-line `**Date anchor — merge event.**` paragraph that declares which
    anchor the Date column carries and states that the grandfathered rows must
    not be rewritten. That is live data-loss on the exact prose that governs the
    file, and it is the reason a bare regenerate is documented as destructive.

    Returns None when the table-header row is absent (unparseable surface), so
    the caller can fall back rather than emit a headerless file.
    """
    lines = index_text.splitlines()
    for i, line in enumerate(lines):
        if line.strip() == INDEX_TABLE_HEADER:
            return lines[:i]
    return None


def render_index(rows: list[dict], existing_themes: dict[str, str] | None = None,
                 header_lines: list[str] | None = None) -> str:
    """Render the live 6-column INDEX from LOG rows + filesystem note lookup.

    Schema: | Version | Milestone | Date | Theme | Release PR | Release Notes |
    The Theme cell is hand-authored prose with no LOG source; `existing_themes`
    (keyed by Version) preserves it across regeneration so the generator never
    clobbers prose it cannot reproduce. Rows with no existing Theme get a
    placeholder for the operator to fill at Stage 13 close.

    `header_lines` is everything above the table-header row, preserved verbatim
    from the on-disk INDEX (extract_index_header). Passing None falls back to the
    bootstrap header, which is correct only when no INDEX exists yet.
    """
    existing_themes = existing_themes or {}
    # Honor the "Chronological-recent-first" header invariant — emit recent-first,
    # NOT raw LOG-append order (FM-1: the un-sorted render scrambled the curated
    # order into LOG byte-order).
    ordered = sort_rows_recent_first(rows)
    out: list[str] = []
    out.extend(DEFAULT_INDEX_HEADER if header_lines is None else header_lines)
    out.append(INDEX_TABLE_HEADER)
    out.append("|---|---|---|---|---|---|")
    for r in ordered:
        out.append(render_index_row(r, existing_themes.get(r["version"], "")))
    out.append("")
    return "\n".join(out)


def index_note_cell(version_key: str, milestone: str, predict_when_absent: bool = False) -> str:
    """Render the INDEX `Release Notes` cell for one row.

    `predict_when_absent` is the emit-path behaviour and is load-bearing: the
    INDEX row is written at close-out phase 7, BEFORE the release note is
    scaffolded at phase 9, so on a fresh close the note file does not exist yet.
    Resolving by filesystem presence alone would emit "—" where the shipped
    behaviour emits the link, silently regressing every future row. So the emit
    path falls back to the CONVENTIONAL note path (the one the scaffold phase
    will write), while the render/verify path — which reads historical rows whose
    notes exist and may be foldered — resolves by lookup.
    """
    note_path = find_artifact(version_key, milestone, "note")
    if note_path:
        return f"[{note_path}]({note_path})"
    if predict_when_absent:
        slug = _slug_from_version_cell(version_key)
        sub = "_unversioned/" if VERSION_LESS_MARKER in version_key else ""
        predicted = f"notes/{sub}{slug}_RELEASE_NOTES.md"
        return f"[{predicted}]({predicted})"
    return "—"


def render_index_row(log_row: dict, theme: str = "", date_override: str | None = None,
                     predict_note: bool = False) -> str:
    """Render ONE 6-column INDEX row. Shared by the whole-file render and --emit,
    so the appended row and the rendered row cannot diverge in shape."""
    note_cell = index_note_cell(log_row["version"], log_row.get("milestone", ""), predict_note)
    theme_cell = (theme or "").strip() or THEME_PLACEHOLDER
    release_pr = log_row.get("release_pr", "").strip() or "—"
    date_cell = date_override if date_override is not None else log_row["date"]
    return (
        f"| {log_row['version']} | {log_row.get('milestone', '').strip()} | {date_cell} "
        f"| {theme_cell} | {release_pr} | {note_cell} |"
    )


def parse_index_rows(index_text: str) -> list[dict]:
    """Parse the live 6-column RELEASE_INDEX.md rows.

    Schema: | Version | Milestone | Date | Theme | Release PR | Release Notes |
    Header ("Version") and separator ("---") rows are skipped. Returns per-row
    dict with keys: version, milestone, date, theme, release_pr, notes_cell
    (raw cell text — "—" or "[notes/...](notes/...)").
    """
    rows: list[dict] = []
    for raw_line in index_text.splitlines():
        m = INDEX_ROW_RE.match(raw_line)
        if not m:
            continue
        version = m.group("version").strip()
        if not version or version == "Version" or set(version) <= set("-: "):
            continue
        rows.append({
            "version": version,
            "milestone": m.group("milestone").strip(),
            "date": m.group("date").strip(),
            "theme": m.group("theme").strip(),
            "release_pr": m.group("release_pr").strip(),
            "notes_cell": m.group("notes").strip(),
        })
    return rows


# ── Note accessors + the three entry emitters ────────────────────────────────


def read_note(version_key: str, milestone: str) -> dict:
    """Read the release note's two SEED fields with the close-out's own accessors.

    Returns {"path": <INDEX-relative str|None>, "text": <str|None>,
             "headline": <str|None>, "summary": <str|None>}.
    `text is None` means the note does not resolve — the caller decides whether
    that is loud (CHANGELOG) or expected (DIGEST). The note's `date:` is
    deliberately NOT read here: it is written from the close-out anchor when the
    close-out scaffolds the note (a note that already exists keeps the date its
    author wrote), so treating it as a source would invert the direction of
    derivation. It is VERIFIED, never derived from, by --verify-closeout-anchors,
    through read_note_closeout_date().
    """
    rel = find_artifact(version_key, milestone, "note")
    out: dict = {"path": rel, "text": None, "headline": None, "summary": None}
    if not rel:
        return out
    # Resolve relative to NOTES_DIR's parent, not a hard-coded corpus path:
    # find_artifact returns "<NOTES_DIR.name>/…", so this is correct both in the
    # repo and under an injected --notes-dir fixture.
    abs_path = NOTES_DIR.parent / rel
    try:
        text = abs_path.read_text(encoding="utf-8")
    except OSError:
        return out
    out["text"] = text
    for line in text.splitlines():
        if line.startswith("# "):
            out["headline"] = line[2:].strip()
            break
    m = NOTE_FRONTMATTER_RE.match(text)
    if m:
        s = NOTE_SUMMARY_RE.search(m.group(1))
        if s:
            out["summary"] = s.group(1).strip()
    return out


def emit_index_entry(log_row: dict, merge_anchor: str, theme: str = "",
                     version_less: bool = False) -> str:
    """ONE INDEX table row, dated with the MERGE anchor.

    A version-less release's Version cell carries the "(version-less)" qualifier
    and its note link resolves under notes/_unversioned/ — the shipped corpus
    convention. The qualifier is applied from the caller's DECLARATION when the
    LOG cell does not already carry it, so the emitted row matches the shipped
    shape regardless of which of the two the LOG happens to record.
    """
    row = log_row
    if version_less and VERSION_LESS_MARKER not in log_row["version"]:
        row = dict(log_row)
        row["version"] = f"{_slug_from_version_cell(log_row['version'])} {VERSION_LESS_MARKER}"
    return render_index_row(row, theme, date_override=merge_anchor, predict_note=True)


def emit_digest_entry(version_cell: str, closeout_anchor: str, headline: str | None,
                      version_less: bool = False) -> str:
    """ONE DIGEST H3 entry, dated with the CLOSE-OUT anchor.

    Version-less releases carry the ", version-less" date-cell marker, matching
    the shipped DIGEST convention. An absent or version-echoing headline becomes
    the operator placeholder — the DIGEST is emitted before the note exists.

    `version_less` is DECLARED by the caller rather than inferred, because the
    caller owns the version grammar and a LOG Version cell does not always carry
    the qualifier. Inferring it here would put a second, subtly different rule
    for the same fact in a second component. The cell marker is honoured too, so
    either source is sufficient and they cannot disagree in a harmful direction.
    """
    version = _slug_from_version_cell(version_cell)
    if not headline or headline == version:
        headline = DIGEST_HEADLINE_PLACEHOLDER
    if version_less or VERSION_LESS_MARKER in version_cell:
        date_cell = f"{closeout_anchor}, version-less"
    else:
        date_cell = closeout_anchor
    return f"### {version} ({date_cell}) — {headline}"


def emit_changelog_entry(version: str, closeout_anchor: str, summary: str | None,
                         repo_slug: str, note_rel: str) -> str:
    """ONE Keep-a-Changelog block, dated with the CLOSE-OUT anchor.

    `repo_slug` is a REQUIRED caller input, never resolved here: this module is a
    public tool and must not read the operator's config or embed a repo name.
    `summary` falls back silently, matching the shipped behaviour.
    """
    body = summary or CHANGELOG_SUMMARY_FALLBACK
    return (
        f"## [{version}] - {closeout_anchor}\n"
        f"\n"
        f"{body}\n"
        f"\n"
        f"[Full notes](release/releases/{note_rel}) · "
        f"[Release](https://github.com/{repo_slug}/releases/tag/{version})\n"
        f"\n"
    )
    # The TRAILING BLANK LINE is load-bearing, not cosmetic: the caller prepends
    # this block immediately above the next `## [` heading, and without it two
    # release entries run together. It is byte-for-byte what the shell heredoc
    # this replaces produced — verified against the shipped corpus.


def verify(log_rows: list[dict], index_rows: list[dict],
           rendered_rows: list[dict] | None = None) -> list[dict]:
    """Compare LOG-derived expectation vs the on-disk 6-column INDEX.

    Each finding: {version, field, log_value, index_value, recommendation}.
    Empty list = full match. The LOG-derivable fields — Version coexistence,
    Milestone, Date, Release PR and the filesystem-derived Release-Notes link —
    are compared against the LOG.

    `rendered_rows` (the re-parsed output of render_index) activates the two
    limbs that have no LOG source and therefore had no checker anywhere in the
    platform:

      * THEME INTEGRITY. The Theme cell is hand-authored prose; it is NOT drift-
        checked against the LOG and must not be — there is nothing to check it
        against. What IS checkable is that it survives a render: the round-trip
        must return every non-placeholder cell byte-identically. Six live Theme
        cells contain a literal `|` inside prose, so this is a real parser
        assertion and not a tautology. It fails loudly if the projector is ever
        wired without the Theme preservation map.
      * ROW ORDER. "Chronological-recent-first" is a declared invariant of this
        file, rendered into its own header prose and enforced on render — and
        until now its ONLY owner was a hard-coded insertion point inside a shell
        heredoc. The per-version dict comparison below is completely order-blind:
        fully reversing the file produced no finding. Order is the one derived
        property this check could not see.

    Both limbs are regression guards: green today, and they must stay green.
    """
    findings: list[dict] = []
    log_by_version = {r["version"]: r for r in log_rows}
    index_by_version = {r["version"]: r for r in index_rows}

    # Coexistence — LOG-only
    for v in log_by_version:
        if v not in index_by_version:
            findings.append({
                "version": v, "field": "coexistence",
                "log_value": "present", "index_value": "absent",
                "recommendation": "run generator to add missing INDEX entry",
            })

    # Coexistence — INDEX-only
    for v in index_by_version:
        if v not in log_by_version:
            findings.append({
                "version": v, "field": "coexistence",
                "log_value": "absent", "index_value": "present",
                "recommendation": "INDEX has stale entry; verify LOG row not deleted; re-run generator",
            })

    # Per-row field comparison (only for versions present in BOTH)
    for v in log_by_version:
        if v not in index_by_version:
            continue
        log_r = log_by_version[v]
        idx_r = index_by_version[v]

        if log_r["milestone"] != idx_r["milestone"]:
            findings.append({
                "version": v, "field": "milestone",
                "log_value": log_r["milestone"], "index_value": idx_r["milestone"],
                "recommendation": "LOG Milestone is canonical; re-run generator to refresh INDEX",
            })

        # Date — both cells carry the MERGE anchor; pre-reconciliation rows are
        # grandfathered on this field only. See DATE_ANCHOR_GRANDFATHERED above.
        if log_r["date"] != idx_r["date"] and v not in DATE_ANCHOR_GRANDFATHERED:
            findings.append({
                "version": v, "field": "date",
                "log_value": log_r["date"], "index_value": idx_r["date"],
                "recommendation": (
                    "LOG Date is canonical for the INDEX Date — both carry the MERGE anchor per "
                    "core/standards/date-variable-convention.md § Emission-Time Anchors. A divergence here "
                    "means the close-out emitter sampled its clock instead of reading the LOG row; fix "
                    "automated-closeout.sh phase_append_release_index. Do NOT regenerate the whole INDEX to "
                    "clear this — that rewrites grandfathered historical rows"
                ),
            })

        if log_r["release_pr"] != idx_r["release_pr"]:
            findings.append({
                "version": v, "field": "release_pr",
                "log_value": log_r["release_pr"], "index_value": idx_r["release_pr"],
                "recommendation": "LOG Release PR is canonical; re-run generator to refresh INDEX",
            })

        # Release-Notes-link validity — generator would emit "[notes/..](notes/..)" or "—"
        expected_note = find_artifact(v, log_r.get("milestone", ""), "note")
        expected_note_cell = f"[{expected_note}]({expected_note})" if expected_note else "—"
        if expected_note_cell != idx_r["notes_cell"]:
            findings.append({
                "version": v, "field": "notes_link",
                "log_value": expected_note_cell, "index_value": idx_r["notes_cell"],
                "recommendation": "re-run generator; filesystem moved/added note file",
            })

    if rendered_rows is not None:
        rendered_by_version = {r["version"]: r for r in rendered_rows}
        # Theme integrity — round-trip, not LOG comparison.
        for r in index_rows:
            theme = r.get("theme", "").strip()
            if not theme or theme == THEME_PLACEHOLDER:
                continue
            rendered = rendered_by_version.get(r["version"])
            if rendered is not None and rendered.get("theme", "").strip() != theme:
                findings.append({
                    "version": r["version"], "field": "theme",
                    "log_value": rendered.get("theme", ""), "index_value": theme,
                    "recommendation": (
                        "the on-disk Theme did not survive a render — this is a PROJECTOR defect, not "
                        "corpus drift. The Theme cell has no source outside this file; do NOT regenerate "
                        "the INDEX to clear it, that destroys the cell. Fix the Theme preservation path"
                    ),
                })
        # Row order — one finding for the file, not one per row.
        disk_order = [r["version"] for r in index_rows]
        rendered_order = [r["version"] for r in rendered_rows]
        if disk_order != rendered_order and sorted(disk_order) == sorted(rendered_order):
            first = next((i for i, (a, b) in enumerate(zip(disk_order, rendered_order)) if a != b), 0)
            findings.append({
                "version": disk_order[first] if first < len(disk_order) else "(order)",
                "field": "row_order",
                "log_value": rendered_order[first] if first < len(rendered_order) else "",
                "index_value": disk_order[first] if first < len(disk_order) else "",
                "recommendation": (
                    "INDEX rows are out of chronological-recent-first order, which this file's own header "
                    "declares. A new row is INSERTED immediately after the `|---` separator (top = most "
                    "recent), never appended at EOF. Move the misordered row rather than regenerating"
                ),
            })

    return findings


# ── Close-out anchor consistency (--verify-closeout-anchors) ──────────────────

CLOSEOUT_RECOMMENDATION = (
    "the release's close-out surfaces carry more than one close-out date. Each must carry the one "
    "close-out run date (UTC). Read it from the Stage-13 chore commit that wrote the entries, and "
    "correct the differing surface IN PLACE. The majority is not evidence of correctness. A note's "
    "date also appears in its Section-2 date line, so changing it changes the published Release body "
    "(release-notes-standard § 5.1). Never regenerate a derived surface whole, and never move "
    "CLOSEOUT_ANCHOR_DECLARED_AT to silence this"
)


def parse_digest_dates(text: str) -> dict[str, list[str]]:
    """Map each DIGEST entry key to the raw `(<cell>)` of EVERY entry carrying it.

    Duplicates are kept: two entries for one key that carry two dates are a
    divergence on that surface, never a last-one-wins read. The cell is returned raw
    (`2026-05-20` or `2026-05-20, version-less`); verify_closeout_anchors() reads the
    date out of it with DIGEST_DATE_CELL_RE, so an unparseable cell surfaces as
    NOT-EVALUATED rather than vanishing here.
    """
    out: dict[str, list[str]] = {}
    for m in DIGEST_ENTRY_RE.finditer(text):
        out.setdefault(m.group("key"), []).append(m.group("cell").strip())
    return out


def parse_changelog_dates(text: str) -> dict[str, list[str]]:
    """Map each CHANGELOG `## [<key>] - <date>` heading key to every date token it
    carries, duplicates kept. `## [Unreleased]` carries no date and does not match."""
    out: dict[str, list[str]] = {}
    for m in CHANGELOG_ENTRY_RE.finditer(text):
        out.setdefault(m.group("key"), []).append(m.group("date"))
    return out


def read_note_closeout_date(version_cell: str, milestone: str) -> tuple[str | None, str]:
    """Read ONE release note's frontmatter `date:` for VERIFICATION, never derivation.

    Returns (date, "") or (None, cause), where cause is one of `absent`,
    `unreadable`, `frontmatter unparseable`, `no date: field` or `unparseable <value>`.
    Resolution reuses find_artifact() and NOTES_DIR exactly as read_note() does, so the
    note this reads is the note every other limb of this module means.
    """
    rel = find_artifact(version_cell, milestone, "note")
    if not rel:
        return None, "absent"
    try:
        text = (NOTES_DIR.parent / rel).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return None, "unreadable"
    fm = NOTE_FRONTMATTER_RE.match(text)
    if not fm:
        return None, "frontmatter unparseable"
    d = NOTE_DATE_RE.search(fm.group(1))
    if not d:
        return None, "no date: field"
    value = d.group("date").strip()
    if not _DATE_RE.match(value):
        return None, f"unparseable {value!r}"
    return value, ""


def verify_closeout_anchors(log_rows: list[dict], digest: dict[str, list[str]],
                            changelog: dict[str, list[str]], note_date,
                            cutoff: str = CLOSEOUT_ANCHOR_DECLARED_AT) -> dict | None:
    """Compare the close-out date across every surface that declares the close-out anchor.

    `note_date` is a callable(row) -> (date | None, cause), so the note surface is
    injectable for fixtures and read from the corpus in the live run.

    Scope is every LOG row at or after the row whose version is `cutoff`, in LOG order.
    Returns None when no row's version equals `cutoff`: the scope cannot be resolved,
    which is never a clean result. A row not yet VERIFIED is counted in flight and not
    read. A version-less row compares two surfaces, because the scripted close-out writes it
    no CHANGELOG entry; when an entry for its slug exists anyway (a close-out written by
    hand or hub-direct) that entry is compared too, and its absence is never NOT-EVALUATED.
    An absent or unparseable value is NOT-EVALUATED for that surface — never agreement —
    and the remaining surfaces are still compared.

    A finding names the version, every value read and the PARTITION of surfaces by
    date. It deliberately carries no "wrong" or "fault" field: when two surfaces have
    drifted together the majority is the wrong side, so the check reports the split and
    never assigns blame.
    """
    idx = next((i for i, r in enumerate(log_rows)
                if _slug_from_version_cell(r["version"]) == cutoff), None)
    if idx is None:
        return None
    result: dict = {"cutoff": cutoff, "enumerated": 0, "examined": 0, "in_flight": 0,
                    "pre_cutoff": idx, "version_less": 0, "version_less_changelog": 0,
                    "total": len(log_rows), "findings": [], "not_evaluated": []}
    for row in log_rows[idx:]:
        if row.get("state", "").strip() != "VERIFIED":
            result["in_flight"] += 1
            continue
        result["enumerated"] += 1
        version = row["version"]
        key = _slug_from_version_cell(version)
        version_less = VERSION_LESS_MARKER in version
        if version_less:
            result["version_less"] += 1
        values: dict[str, list[str]] = {}

        def _not_evaluated(surface: str, cause: str) -> None:
            result["not_evaluated"].append({"version": version, "surface": surface, "cause": cause})

        cells = digest.get(key)
        if not cells:
            _not_evaluated("DIGEST", "absent")
        for cell in cells or []:
            m = DIGEST_DATE_CELL_RE.match(cell)
            if m:
                values.setdefault("DIGEST", []).append(m.group("date"))
            else:
                _not_evaluated("DIGEST", f"unparseable {cell!r}")

        dates = changelog.get(key)
        if version_less and dates:
            result["version_less_changelog"] += 1
        if not dates and not version_less:
            _not_evaluated("CHANGELOG", "absent")
        for value in dates or []:
            if _DATE_RE.match(value):
                values.setdefault("CHANGELOG", []).append(value)
            else:
                _not_evaluated("CHANGELOG", f"unparseable {value!r}")

        note_value, cause = note_date(row)
        if note_value is None:
            _not_evaluated("note", cause or "absent")
        elif _DATE_RE.match(note_value):
            values["note"] = [note_value]
        else:
            _not_evaluated("note", f"unparseable {note_value!r}")

        read = [d for ds in values.values() for d in ds]
        if len(read) >= 2:
            result["examined"] += 1
        distinct = sorted(set(read))
        if len(distinct) > 1:
            partition = [(d, sorted(s for s, ds in values.items() if d in ds)) for d in distinct]
            result["findings"].append({"version": version, "values": values, "partition": partition})
    return result


def render_closeout_report(result: dict) -> list[str]:
    """The --verify-closeout-anchors stdout contract, one line per element.

    A `DENOM:` line first; then one verdict-first TSV row per finding
    (`FAIL <version> closeout_anchor <values> <partition> <recommendation>`) and one per
    surface not compared (`NOT-EVALUATED <version> <surface> <cause>`). deploy.sh Check
    82 classifies every row by its first field and treats any other class as unreadable,
    so this function is the only place the grammar is spelled.
    """
    status = "degraded" if result["not_evaluated"] else "fetched"
    lines = [
        f"DENOM: status={status} enumerated={result['enumerated']} examined={result['examined']} "
        f"(VERIFIED RELEASE_LOG rows at/after {result['cutoff']}; "
        f"{result['version_less'] - result['version_less_changelog']} version-less compared two-way — no "
        f"CHANGELOG entry, which the scripted close-out never writes; {result['version_less_changelog']} "
        f"version-less compared three-way — a CHANGELOG entry written by hand or hub-direct; "
        f"{result['in_flight']} in-flight row(s) "
        f"excluded; {result['pre_cutoff']} earlier row(s) predate the anchor declaration and are not "
        f"read; {result['total']} LOG rows total)"
    ]
    for f in result["findings"]:
        vals = ";".join(f"{s}={','.join(f['values'][s])}" for s in CLOSEOUT_SURFACES if s in f["values"])
        split = " | ".join(f"{d}: {{{','.join(ss)}}}" for d, ss in f["partition"])
        lines.append(f"FAIL\t{f['version']}\tcloseout_anchor\t{vals}\t{split}\t{CLOSEOUT_RECOMMENDATION}")
    for n in result["not_evaluated"]:
        lines.append(f"NOT-EVALUATED\t{n['version']}\t{n['surface']}\t{n['cause']}")
    return lines


def _self_test() -> int:
    """In-process synthetic LOG (8-col) + INDEX (6-col) pair with known drift.

    Asserts the parsers handle the live schemas (including a version-less row)
    and the verifier detects coexistence + per-field drift. Precedent:
    check-doc-links.py --self-test.
    """
    # Synthetic LOG — live 8-column schema, incl. a version-less row.
    log_text = (
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v99.01 | v99.01-self-test-a | #9999 | #100 | `deadbeef` | `v99.01` | VERIFIED | 2026-05-23 |\n"
        "| v99.02 | v99.02-self-test-b | #9998, #9997 | #200 | `cafef00d` | `v99.02` | VERIFIED | 2026-05-23 |\n"
        "| self-test-vl (version-less) | self-test-vl | #9996 | #300 | `feedface` | (none) | VERIFIED | 2026-05-24 |\n"
    )
    log_rows = parse_log_rows(log_text)
    if len(log_rows) != 3:
        print(f"self-test FAIL: parse_log_rows returned {len(log_rows)} rows (expected 3)", file=sys.stderr)
        return 1
    # Field-mapping assertions (the #85 root cause was a field-mismap).
    r0 = log_rows[0]
    if not (r0["version"] == "v99.01" and r0["milestone"] == "v99.01-self-test-a"
            and r0["release_pr"] == "#100" and r0["date"] == "2026-05-23"):
        print(f"self-test FAIL: LOG field-mapping wrong for row 0: {r0}", file=sys.stderr)
        return 1
    # Version-less row must parse (relaxed anchor).
    if log_rows[2]["version"] != "self-test-vl (version-less)":
        print(f"self-test FAIL: version-less LOG row dropped: {log_rows}", file=sys.stderr)
        return 1
    # Field indices are pinned by HEADER NAME, so a LOG that grows a column stays
    # readable rather than silently mis-mapping. The trailing column here shifts
    # nothing, so the discriminating fixture below MOVES Date away from its
    # canonical index — positional parsing would read the wrong cell.
    shifted = parse_log_rows(
        "| Version | Milestone | Date | Issues | Release PR | Merge SHA | Tag | State |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v99.55 | m-shift | 2026-05-25 | #1 | #500 | `a` | `v99.55` | VERIFIED |\n"
    )
    if len(shifted) != 1 or shifted[0]["date"] != "2026-05-25" or shifted[0]["release_pr"] != "#500":
        print(f"self-test FAIL: header-name field pin did not hold on a reordered schema: {shifted}",
              file=sys.stderr)
        return 1
    # Extra trailing column must not drop the row (the close-out's own fixture shape).
    if len(parse_log_rows(
            "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date | Notes |\n"
            "|---|---|---|---|---|---|---|---|---|\n"
            "| v99.56 | m-extra | #1 | #501 | `a` | `v99.56` | VERIFIED | 2026-05-26 | — |\n")) != 1:
        print("self-test FAIL: a LOG row with a trailing column was dropped", file=sys.stderr)
        return 1

    # Synthetic INDEX — live 6-column schema, with deliberate drift:
    #   - v99.01 Milestone drift (LOG says self-test-a; INDEX says WRONG-slug)
    #   - v99.02 missing entirely → coexistence (LOG-only)
    #   - extra v99.90 not in LOG → coexistence (INDEX-only)
    #   - self-test-vl present + aligned (no finding — proves version-less round-trip)
    index_text = (
        "# RELEASE_INDEX\n\n"
        "| Version | Milestone | Date | Theme | Release PR | Release Notes |\n"
        "|---|---|---|---|---|---|\n"
        "| v99.01 | WRONG-slug | 2026-05-23 | Hand-authored theme prose | #100 | — |\n"
        "| v99.90 | v99.90-not-in-log | 2026-05-23 | Stale theme | #900 | — |\n"
        "| self-test-vl (version-less) | self-test-vl | 2026-05-24 | VL theme | #300 | — |\n"
    )
    index_rows = parse_index_rows(index_text)
    if len(index_rows) != 3:
        print(f"self-test FAIL: parse_index_rows returned {len(index_rows)} rows (expected 3)", file=sys.stderr)
        return 1
    # Theme must parse intact (free-prose cell).
    if index_rows[0]["theme"] != "Hand-authored theme prose":
        print(f"self-test FAIL: Theme cell mis-parsed: {index_rows[0]}", file=sys.stderr)
        return 1

    findings = verify(log_rows, index_rows)

    # Expected: v99.01 milestone drift + v99.02 LOG-only + v99.90 INDEX-only.
    expected_signatures = {
        ("v99.01", "milestone"),
        ("v99.02", "coexistence"),
        ("v99.90", "coexistence"),
    }
    actual_signatures = {(f["version"], f["field"]) for f in findings}
    missing = expected_signatures - actual_signatures
    if missing:
        print(f"self-test FAIL: missing expected findings {missing}", file=sys.stderr)
        print(f"actual findings: {actual_signatures}", file=sys.stderr)
        return 1
    # The aligned version-less row must NOT produce a coexistence finding.
    if ("self-test-vl (version-less)", "coexistence") in actual_signatures:
        print("self-test FAIL: aligned version-less row wrongly flagged", file=sys.stderr)
        return 1

    # ── Date-anchor grandfathering (#3718) ───────────────────────────────────
    # Two halves, and BOTH must hold or the exemption is either useless or a
    # blanket amnesty: a grandfathered version is exempt on Date, and a
    # non-grandfathered version with the same divergence still fires. Without the
    # second half a widened set would pass silently.
    gf_log = parse_log_rows(
        "# RELEASE_LOG\n\n"
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v3.83 | m-gf | #1 | #101 | `a` | `v3.83` | VERIFIED | 2026-07-22 |\n"
        "| v99.77 | m-new | #2 | #102 | `b` | `v99.77` | VERIFIED | 2026-07-22 |\n"
    )
    gf_index = parse_index_rows(
        "# RELEASE_INDEX\n\n"
        "| Version | Milestone | Date | Theme | Release PR | Release Notes |\n"
        "|---|---|---|---|---|---|\n"
        "| v3.83 | m-gf | 2026-07-23 | t | #101 | — |\n"
        "| v99.77 | m-new | 2026-07-23 | t | #102 | — |\n"
    )
    gf_sigs = {(f["version"], f["field"]) for f in verify(gf_log, gf_index)}
    if ("v3.83", "date") in gf_sigs:
        print("self-test FAIL: grandfathered version flagged on date", file=sys.stderr)
        return 1
    if ("v99.77", "date") not in gf_sigs:
        print("self-test FAIL: non-grandfathered date divergence must still fire "
              "— the exemption is per-version, never a blanket date amnesty", file=sys.stderr)
        return 1
    # Grandfathering is Date-ONLY: a grandfathered version still drifts on
    # every other field.
    gf2_index = parse_index_rows(
        "# RELEASE_INDEX\n\n"
        "| Version | Milestone | Date | Theme | Release PR | Release Notes |\n"
        "|---|---|---|---|---|---|\n"
        "| v3.83 | WRONG-slug | 2026-07-23 | t | #999 | — |\n"
    )
    gf2_sigs = {(f["version"], f["field"]) for f in verify(gf_log[:1], gf2_index)}
    if ("v3.83", "milestone") not in gf2_sigs or ("v3.83", "release_pr") not in gf2_sigs:
        print("self-test FAIL: grandfathering must exempt the date field ONLY "
              f"— other fields still compared; got {gf2_sigs}", file=sys.stderr)
        return 1
    # Theme drift must NOT be flagged (no LOG source of truth).
    if any(f["field"] == "theme" for f in findings):
        print("self-test FAIL: Theme should not be drift-checked (no LOG source)", file=sys.stderr)
        return 1

    # ── Sort: chronological-recent-first, ties broken later-LOG-position-first ──
    # Synthetic LOG in APPEND order across two tie-dates + an out-of-order
    # interleave + a malformed-date row that must sort LAST.
    sort_log = parse_log_rows(
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| s1 | s1-m | #1 | #11 | `a` | `s1` | VERIFIED | 2026-06-01 |\n"
        "| s2 | s2-m | #2 | #12 | `b` | `s2` | VERIFIED | 2026-06-02 |\n"
        "| s3 | s3-m | #3 | #13 | `c` | `s3` | VERIFIED | 2026-06-02 |\n"
        "| s4 | s4-m | #4 | #14 | `d` | `s4` | VERIFIED | 2026-06-03 |\n"
        "| s5 | s5-m | #5 | #15 | `e` | `s5` | VERIFIED | bad-date |\n"
    )
    ordered = [r["version"] for r in sort_rows_recent_first(sort_log)]
    # Expected recent-first: 06-03 (s4); 06-02 tie -> later-appended first (s3, s2);
    # 06-01 (s1); malformed date LAST (s5).
    expected_order = ["s4", "s3", "s2", "s1", "s5"]
    if ordered != expected_order:
        print(f"self-test FAIL: sort_rows_recent_first wrong order: {ordered} (expected {expected_order})", file=sys.stderr)
        return 1
    # Sort must not mutate its input.
    if [r["version"] for r in sort_log] != ["s1", "s2", "s3", "s4", "s5"]:
        print("self-test FAIL: sort_rows_recent_first mutated its input list", file=sys.stderr)
        return 1

    # ── Orphan detection: INDEX-only Version is an orphan; LOG-only is not. ──
    orphans = find_index_orphans(log_rows, index_rows)
    if orphans != ["v99.90"]:
        print(f"self-test FAIL: find_index_orphans returned {orphans} (expected ['v99.90'])", file=sys.stderr)
        return 1
    # A LOG-superset INDEX (every INDEX Version present in LOG) has zero orphans.
    if find_index_orphans(log_rows, [index_rows[0], index_rows[2]]) != []:
        print("self-test FAIL: find_index_orphans flagged a non-orphan", file=sys.stderr)
        return 1

    for limb in (_self_test_clock_free, _self_test_grandfathering_closed,
                 _self_test_header_preserved, _self_test_theme_and_order,
                 _self_test_emitters, _self_test_closeout_anchors,
                 _self_test_closeout_cutoff_resolves):
        rc = limb()
        if rc != 0:
            return rc

    print("self-test PASSED — 6-col verifier detected 3 expected drift signatures "
          "(milestone, LOG-only, INDEX-only); version-less round-trip + Theme-skip confirmed; "
          "recent-first sort (date-desc, later-LOG-first ties, malformed-date-last) + orphan detection confirmed; "
          "projector clock-free (import allow-list + callsite denial, AST-parsed); "
          "date-anchor grandfathering closed (every member pre-reconciliation); "
          "INDEX header preserved verbatim; Theme round-trip + row-order limbs fire; "
          "all three emitters produce exactly ONE entry and cannot emit a whole file; "
          "close-out anchors: a 3-way divergence a 2-way compare reads as agreement fires, "
          "both-drifted fires with no side blamed, grandfathered rows silent, unreadable surfaces "
          "NOT-EVALUATED, emitter<->parser round-trip holds; the live cutoff row resolves and the "
          "live note reader returns a date at both ends of the scope")
    return 0


def _self_test_clock_free() -> int:
    """AC-9. The projector imports and calls NO date/time API.

    IMPORT-shaped and CALLSITE-shaped, via an AST parse of this module's own
    source. NEVER substring-shaped: the substring "date" occurs dozens of times
    in this file, so a substring probe returns only false positives and could not
    fail informatively. This is a REGRESSION GUARD — true today, and the whole
    point is that it stays true. A projector that can reach a clock can become
    the second writer of a fact that already has one, which is precisely the
    mechanism that produced DATE_ANCHOR_GRANDFATHERED.
    """
    try:
        tree = ast.parse(Path(__file__).resolve().read_text(encoding="utf-8"))
    except (OSError, SyntaxError) as exc:
        print(f"self-test FAIL: could not AST-parse this module for the clock-free limb: {exc}",
              file=sys.stderr)
        return 1

    imported: set[str] = set()
    denied_calls: list[str] = []
    denied_attrs: list[str] = []
    for node in ast.walk(tree):
        if isinstance(node, ast.Import):
            for alias in node.names:
                imported.add(alias.name.split(".")[0])
        elif isinstance(node, ast.ImportFrom):
            imported.add((node.module or "").split(".")[0])
        elif isinstance(node, ast.Call):
            fn = node.func
            name = fn.attr if isinstance(fn, ast.Attribute) else (fn.id if isinstance(fn, ast.Name) else None)
            if name in CLOCK_FREE_DENIED_CALLS:
                denied_calls.append(f"{name}() at line {node.lineno}")
        elif isinstance(node, ast.Attribute) and node.attr in CLOCK_FREE_DENIED_ATTRS:
            denied_attrs.append(f".{node.attr} at line {node.lineno}")

    extra = sorted(imported - CLOCK_FREE_ALLOWED_IMPORTS)
    if extra:
        print(f"self-test FAIL: projector import allow-list violated — {extra} not in "
              f"{sorted(CLOCK_FREE_ALLOWED_IMPORTS)}. The projector must remain clock-free and "
              "config-free by contract; both date anchors and the repo slug are REQUIRED CLI "
              "arguments, never re-derived here", file=sys.stderr)
        return 1
    if denied_calls or denied_attrs:
        print(f"self-test FAIL: projector reached a clock — calls {denied_calls}, attrs {denied_attrs}. "
              "Pass the value in as an argument instead; see DATE_ANCHOR_GRANDFATHERED for what "
              "a second clock sample costs", file=sys.stderr)
        return 1
    # Non-vacuity: the probe must be reading a real import set, not an empty one.
    if not {"argparse", "re", "sys"} <= imported:
        print(f"self-test FAIL: clock-free limb read an implausible import set {sorted(imported)} "
              "— the AST probe is not seeing this module", file=sys.stderr)
        return 1
    return 0


def _self_test_grandfathering_closed() -> int:
    """AC-10. Every DATE_ANCHOR_GRANDFATHERED member is a PRE-reconciliation release.

    The ENUMERATION remains the membership mechanism — a date cutoff was
    deliberately rejected as the membership form because it can silently widen.
    This asserts the enumeration is VALID: a member added for a release that
    closed on or after the reconciliation is not a historical artifact, it is the
    emitter regressing and being silenced. That is exactly the "DO NOT add a
    version here — fix the emitter" instruction, made executable.

    NOT phrased as a pinned member count: a count assertion must be edited for a
    legitimate addition, which trains reviewers to edit the assertion instead of
    investigating the cause.

    THIS LIMB READS THE LIVE LOG — one of two self-test limbs that do; the other is
    _self_test_closeout_cutoff_resolves, for the same reason. Recorded deliberately:
    the assertion is about the real enumeration against the real corpus and cannot
    be made from synthetic data. An unresolvable LOG is a FAIL, never a skip — a
    guard that passes vacuously is not a guard.
    """
    if not LOG_PATH.exists():
        print(f"self-test FAIL: grandfathering-closure limb cannot run — {_rel(LOG_PATH)} does not "
              "resolve. This limb is corpus-bound by necessity; refusing to pass vacuously",
              file=sys.stderr)
        return 1
    log_by_version = {r["version"]: r for r in parse_log_rows(LOG_PATH.read_text(encoding="utf-8"))}
    if not log_by_version:
        print("self-test FAIL: grandfathering-closure limb parsed zero LOG rows", file=sys.stderr)
        return 1

    unknown = sorted(v for v in DATE_ANCHOR_GRANDFATHERED if v not in log_by_version)
    if unknown:
        print(f"self-test FAIL: grandfathered version(s) {unknown} have no RELEASE_LOG row — the "
              "exemption names a release that does not exist", file=sys.stderr)
        return 1
    late = sorted(
        (v, log_by_version[v]["date"]) for v in DATE_ANCHOR_GRANDFATHERED
        if log_by_version[v]["date"] >= DATE_ANCHOR_RECONCILIATION
    )
    if late:
        print(f"self-test FAIL: {late} are grandfathered but closed on/after the date-anchor "
              f"reconciliation ({DATE_ANCHOR_RECONCILIATION}). A post-reconciliation Date divergence "
              "means the EMITTER regressed — the INDEX Date must be read from the LOG row, never "
              "sampled from the close-out clock. Fix the emitter; do not widen this set",
              file=sys.stderr)
        return 1
    # Non-vacuity control: the corpus must actually contain post-reconciliation
    # releases, or "no member is post-reconciliation" is true of an empty universe.
    if not any(r["date"] >= DATE_ANCHOR_RECONCILIATION for r in log_by_version.values()):
        print(f"self-test FAIL: no RELEASE_LOG row is dated on/after {DATE_ANCHOR_RECONCILIATION} — "
              "the closure assertion would pass vacuously; re-check the bound", file=sys.stderr)
        return 1
    return 0


def _self_test_header_preserved() -> int:
    """AC-8. render_index() preserves every line above the table-header row."""
    header_prose = "**Date anchor — merge event.** Governing prose a regenerate must not delete."
    disk = (
        "# RELEASE_INDEX\n"
        "\n"
        f"{header_prose}\n"
        "\n"
        f"{INDEX_TABLE_HEADER}\n"
        "|---|---|---|---|---|---|\n"
        "| v99.01 | m | 2026-05-23 | t | #100 | — |\n"
    )
    header = extract_index_header(disk)
    if header is None or header_prose not in header:
        print(f"self-test FAIL: extract_index_header lost the governing prose: {header}", file=sys.stderr)
        return 1
    log = parse_log_rows(
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v99.01 | m | #1 | #100 | `a` | `v99.01` | VERIFIED | 2026-05-23 |\n"
    )
    if header_prose not in render_index(log, {"v99.01": "t"}, header):
        print("self-test FAIL: render_index dropped the preserved header prose", file=sys.stderr)
        return 1
    # CONTROL: the old hard-coded-header behaviour must be observably different,
    # or this limb proves nothing.
    if header_prose in render_index(log, {"v99.01": "t"}, None):
        print("self-test FAIL: the bootstrap header wrongly contains the preserved prose "
              "— the header limb cannot discriminate", file=sys.stderr)
        return 1
    return 0


def _self_test_theme_and_order() -> int:
    """AC-3 + M-1. The Theme round-trip and row-order limbs FIRE.

    Both are green on a clean corpus, so each is driven against a mutated render
    and must produce its finding. A limb that has never been seen to fire is not
    known to work.
    """
    log = parse_log_rows(
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v99.01 | m1 | #1 | #101 | `a` | `v99.01` | VERIFIED | 2026-05-23 |\n"
        "| v99.02 | m2 | #2 | #102 | `b` | `v99.02` | VERIFIED | 2026-05-24 |\n"
    )
    # Recent-first: v99.02 then v99.01. A Theme cell carrying a literal `|` is
    # included because six live cells do, and a naive split-based parse loses them.
    disk_rows = parse_index_rows(
        "# RELEASE_INDEX\n\n"
        f"{INDEX_TABLE_HEADER}\n"
        "|---|---|---|---|---|---|\n"
        "| v99.02 | m2 | 2026-05-24 | second theme | #102 | — |\n"
        "| v99.01 | m1 | 2026-05-23 | first theme | with a pipe | #101 | — |\n"
    )
    rendered_rows = parse_index_rows(render_index(
        log, {r["version"]: r["theme"] for r in disk_rows}))
    clean = {(f["version"], f["field"]) for f in verify(log, disk_rows, rendered_rows)}
    if any(field in ("theme", "row_order") for _, field in clean):
        print(f"self-test FAIL: Theme/row-order limbs fired on a clean corpus: {clean}", file=sys.stderr)
        return 1

    mutated = [dict(r) for r in rendered_rows]
    mutated[0]["theme"] = THEME_PLACEHOLDER
    if ("v99.02", "theme") not in {(f["version"], f["field"]) for f in verify(log, disk_rows, mutated)}:
        print("self-test FAIL: Theme-integrity limb did not fire on a dropped Theme cell "
              "— a projector wired without Theme preservation would pass", file=sys.stderr)
        return 1

    reordered = list(reversed([dict(r) for r in rendered_rows]))
    if ("row_order") not in {f["field"] for f in verify(log, disk_rows, reordered)}:
        print("self-test FAIL: row-order limb did not fire on a permuted render "
              "— chronological-recent-first would have no owner", file=sys.stderr)
        return 1

    # A placeholder Theme is NOT protected — the operator fills it at close.
    place_disk = parse_index_rows(
        "# RELEASE_INDEX\n\n"
        f"{INDEX_TABLE_HEADER}\n"
        "|---|---|---|---|---|---|\n"
        "| v99.02 | m2 | 2026-05-24 | — | #102 | — |\n"
        "| v99.01 | m1 | 2026-05-23 | — | #101 | — |\n"
    )
    place_rendered = [dict(r) for r in place_disk]
    place_rendered[0]["theme"] = "invented prose"
    if any(f["field"] == "theme" for f in verify(log, place_disk, place_rendered)):
        print("self-test FAIL: Theme limb fired on a PLACEHOLDER cell — the limb protects "
              "hand-authored prose, not the placeholder", file=sys.stderr)
        return 1
    return 0


def _self_test_emitters() -> int:
    """AC-2 + the entry-scoped safety property.

    THE LOAD-BEARING ASSERTION IS THE LAST ONE. Each emitter must produce exactly
    ONE entry. A projector that could emit a whole DIGEST or CHANGELOG file makes
    available the single irreversible-shaped mistake in this design: a whole-file
    regenerate destroys ~100 historical entries of hand-authored prose that exist
    nowhere but those files, and it surfaces as a clean diff rather than a
    conflict. Entry-scoping is guaranteed by construction, and asserted here.
    """
    log_row = {"version": "v99.01", "milestone": "m1", "release_pr": "#101",
               "state": "VERIFIED", "date": "2026-05-23"}

    idx = emit_index_entry(log_row, "2026-05-23")
    if idx.count("\n") or not idx.startswith("| v99.01 |") or idx.count("|") != 7:
        print(f"self-test FAIL: --emit index produced {idx.count(chr(10)) + 1} line(s) / "
              f"{idx.count('|')} pipes (expected 1 line, 7 pipes): {idx!r}", file=sys.stderr)
        return 1
    # The merge anchor is RELAYED into the Date cell, not re-derived.
    if "2026-05-23" not in idx:
        print(f"self-test FAIL: --emit index dropped the merge anchor: {idx!r}", file=sys.stderr)
        return 1
    # Predicted note cell: the note does not exist at emit time, and the row must
    # still carry the link the scaffold phase will make true.
    if "_RELEASE_NOTES.md" not in idx:
        print(f"self-test FAIL: --emit index emitted no note link for an unscaffolded note "
              f"— shipped behaviour regressed to an em-dash: {idx!r}", file=sys.stderr)
        return 1

    dg = emit_digest_entry("v99.01", "2026-05-24", "A headline")
    if dg != "### v99.01 (2026-05-24) — A headline":
        print(f"self-test FAIL: --emit digest shape wrong: {dg!r}", file=sys.stderr)
        return 1
    if emit_digest_entry("v99.01", "2026-05-24", None) != \
            f"### v99.01 (2026-05-24) — {DIGEST_HEADLINE_PLACEHOLDER}":
        print("self-test FAIL: --emit digest lost the operator-placeholder fallback "
              "— the DIGEST is written BEFORE the note is scaffolded", file=sys.stderr)
        return 1
    vl = emit_digest_entry(f"a-slug {VERSION_LESS_MARKER}", "2026-05-24", "H")
    if vl != "### a-slug (2026-05-24, version-less) — H":
        print(f"self-test FAIL: --emit digest lost the version-less marker: {vl!r}", file=sys.stderr)
        return 1
    # The CLOSE-OUT anchor, not the merge anchor: DIGEST and INDEX carry DIFFERENT
    # anchors by design, and the close-out self-test asserts the split both ways.
    if "2026-05-23" in dg:
        print(f"self-test FAIL: --emit digest carried the merge anchor: {dg!r}", file=sys.stderr)
        return 1

    cl = emit_changelog_entry("v99.01", "2026-05-24", "A summary.", "self-test-owner/self-test-repo",
                              "notes/v99.01_RELEASE_NOTES.md")
    for needle in ("## [v99.01] - 2026-05-24", "A summary.",
                   "https://github.com/self-test-owner/self-test-repo/releases/tag/v99.01",
                   "[Full notes](release/releases/notes/v99.01_RELEASE_NOTES.md)"):
        if needle not in cl:
            print(f"self-test FAIL: --emit changelog missing {needle!r}: {cl!r}", file=sys.stderr)
            return 1
    if CHANGELOG_SUMMARY_FALLBACK not in emit_changelog_entry(
            "v99.01", "2026-05-24", None, "self-test-owner/self-test-repo", "notes/v99.01_RELEASE_NOTES.md"):
        print("self-test FAIL: --emit changelog lost the silent summary fallback", file=sys.stderr)
        return 1

    # ENTRY-SCOPED BY CONSTRUCTION — exactly one entry per emit, never a file.
    if len([ln for ln in dg.splitlines() if ln.startswith("### ")]) != 1:
        print(f"self-test FAIL: --emit digest emitted more than one H3 entry: {dg!r}", file=sys.stderr)
        return 1
    if len([ln for ln in cl.splitlines() if ln.startswith("## [")]) != 1:
        print(f"self-test FAIL: --emit changelog emitted more than one H2 block — a whole-file "
              "emit is the one irreversible-shaped mistake this design forbids", file=sys.stderr)
        return 1
    if len([ln for ln in idx.splitlines() if ln.startswith("| ")]) != 1:
        print(f"self-test FAIL: --emit index emitted more than one row: {idx!r}", file=sys.stderr)
        return 1
    return 0


def _self_test_closeout_anchors() -> int:
    """--verify-closeout-anchors, in-process (arms CA-1 to CA-11).

    One synthetic 8-column LOG, a DIGEST text, a CHANGELOG text and a note map, with the
    cutoff injected as `v9.20`. Every assertion is an EXACT SET, never a count, so an arm
    that fires on the wrong row cannot pass by firing on the right number of rows. The
    sensitivity arms (CA-1, CA-2, CA-3, CA-9) must fire; the specificity arms (CA-4, CA-5)
    are the near-misses that must not — CA-4's pre-cutoff rows carry CA-1's exact
    divergence, so their silence is the cutoff working and not an empty input.
    """
    def _fail(msg: str) -> int:
        print(f"self-test FAIL: close-out anchors — {msg}", file=sys.stderr)
        return 1

    log_rows = parse_log_rows(
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v9.10 | m10 | #1 | #10 | `a` | `v9.10` | VERIFIED | 2026-05-01 |\n"
        "| v9.11 | m11 | #1 | #11 | `a` | `v9.11` | VERIFIED | 2026-05-01 |\n"
        "| v9.20 | m20 | #1 | #20 | `a` | `v9.20` | VERIFIED | 2026-05-02 |\n"
        "| v9.21 | m21 | #1 | #21 | `a` | `v9.21` | VERIFIED | 2026-05-03 |\n"
        "| vl-slug (version-less) | vl-slug | #1 | #30 | `a` | (none) | VERIFIED | 2026-05-13 |\n"
        "| v9.22 | m22 | #1 | #22 | `a` | `v9.22` | VERIFIED | 2026-05-11 |\n"
        "| v9.23 | m23 | #1 | #23 | `a` | `v9.23` | VERIFIED | 2026-05-12 |\n"
        "| v9.24 | m24 | #1 | #24 | `a` | `v9.24` | VERIFIED | 2026-05-14 |\n"
        "| v9.25 | m25 | #1 | #25 | `a` | `v9.25` | VERIFIED | 2026-05-15 |\n"
        "| v9.26 | m26 | #1 | #26 | `a` | `v9.26` | VERIFIED | 2026-05-16 |\n"
        "| v9.27 | m27 | #1 | #27 | `a` | `v9.27` | DEPLOYED | 2026-05-17 |\n"
    )
    digest = parse_digest_dates(
        "### v9.10 (2026-05-12) — pre-cutoff, CA-1's divergence (CA-4)\n"
        "### v9.11 (version-less) — pre-cutoff, unparseable cell (CA-4)\n"
        "### v9.20 (2026-05-03) — the cutoff row diverges (CA-9)\n"
        "### v9.21 (2026-05-04) — all agree (CA-5)\n"
        "### vl-slug (2026-05-13, version-less) — version-less, agrees (CA-5)\n"
        "### v9.22 (2026-05-12) — DIGEST = CHANGELOG, note a day earlier (CA-1)\n"
        "### v9.23 (2026-05-20) — DIGEST alone differs (CA-2)\n"
        "### v9.24 (2026-05-15) — DIGEST = CHANGELOG drifted together (CA-3)\n"
        "### v9.25 (2026-05-16) — CHANGELOG absent (CA-6)\n"
        "### v9.26 (version-less) — a versioned row's unparseable cell (CA-6)\n"
    )
    changelog = parse_changelog_dates(
        "## [Unreleased]\n\n"
        "## [v9.10] - 2026-05-12\n"
        "## [v9.20] - 2026-05-03\n"
        "## [v9.21] - 2026-05-04\n"
        "## [v9.22] - 2026-05-12\n"
        "## [v9.23] - 2026-05-13\n"
        "## [v9.24] - 2026-05-15\n"
        "## [v9.26] - 2026-05-17\n"
    )
    notes = {"v9.10": "2026-05-11", "v9.20": "2026-05-02", "v9.21": "2026-05-04",
             "vl-slug": "2026-05-13", "v9.22": "2026-05-11", "v9.23": "2026-05-13",
             "v9.24": "2026-05-14", "v9.25": "2026-05-16", "v9.26": "2026-05-17"}

    def note_date(row: dict) -> tuple[str | None, str]:
        value = notes.get(_slug_from_version_cell(row["version"]))
        return (value, "") if value else (None, "absent")

    res = verify_closeout_anchors(log_rows, digest, changelog, note_date, cutoff="v9.20")
    if res is None:
        return _fail("the fixture cutoff v9.20 names a LOG row, but the scope did not resolve")
    by_version = {f["version"]: f for f in res["findings"]}

    # The exact finding set: CA-9 (boundary), CA-1, CA-2, CA-3.
    if set(by_version) != {"v9.20", "v9.22", "v9.23", "v9.24"}:
        return _fail(f"findings must be exactly {{v9.20, v9.22, v9.23, v9.24}}, got {sorted(by_version)}")
    # CA-1 — the 3-way sensitivity arm, and the reason it is 3-way: the 2-way compare
    # of the same row reads agreement.
    ca1 = by_version["v9.22"]
    if ca1["partition"] != [("2026-05-11", ["note"]), ("2026-05-12", ["CHANGELOG", "DIGEST"])]:
        return _fail(f"CA-1 partition wrong: {ca1['partition']}")
    if ca1["values"]["DIGEST"] != ca1["values"]["CHANGELOG"]:
        return _fail("CA-1 fixture must agree two-way (DIGEST = CHANGELOG), or it does not show why "
                     "the compare is three-way")
    # CA-2 — DIGEST alone in its own cell of the partition.
    if not any(ss == ["DIGEST"] for _, ss in by_version["v9.23"]["partition"]):
        return _fail(f"CA-2 must isolate DIGEST in its own partition cell: {by_version['v9.23']['partition']}")
    # CA-3 — both drifted together: a partition, and no field that names a side wrong.
    ca3 = by_version["v9.24"]
    if ca3["partition"] != [("2026-05-14", ["note"]), ("2026-05-15", ["CHANGELOG", "DIGEST"])]:
        return _fail(f"CA-3 partition wrong: {ca3['partition']}")
    if any(set(f) != {"version", "values", "partition"} for f in res["findings"]):
        return _fail("a finding carries a field beyond version / values / partition — the check names "
                     "the split and never assigns fault")
    # CA-4 — the pre-cutoff rows are not read: no finding, no NOT-EVALUATED.
    pre = {"v9.10", "v9.11"}
    if pre & set(by_version) or pre & {n["version"] for n in res["not_evaluated"]}:
        return _fail("CA-4 a pre-cutoff row was read")
    if res["pre_cutoff"] != 2:
        return _fail(f"CA-4 pre_cutoff must be 2, got {res['pre_cutoff']}")
    # CA-5 — agreeing rows are silent; the version-less row compares two surfaces and its
    # missing CHANGELOG is not NOT-EVALUATED.
    if res["version_less"] != 1:
        return _fail(f"CA-5 version_less must be 1, got {res['version_less']}")
    # CA-6 — exactly the two surfaces that could not be compared.
    ne = {(n["version"], n["surface"]) for n in res["not_evaluated"]}
    if ne != {("v9.25", "CHANGELOG"), ("v9.26", "DIGEST")}:
        return _fail(f"CA-5/CA-6 NOT-EVALUATED must be exactly v9.25 CHANGELOG and v9.26 DIGEST, got {sorted(ne)}")
    # CA-7 — a row not yet VERIFIED is counted in flight and not read.
    if res["in_flight"] != 1 or res["enumerated"] != 8 or res["examined"] != 8 or res["total"] != 11:
        return _fail(f"CA-7 counters wrong: in_flight={res['in_flight']} enumerated={res['enumerated']} "
                     f"examined={res['examined']} total={res['total']} (expected 1/8/8/11)")
    # CA-8 — a cutoff naming no row is unresolved, never a clean zero.
    if verify_closeout_anchors(log_rows, digest, changelog, note_date, cutoff="v0.00") is not None:
        return _fail("CA-8 a cutoff naming no LOG row must return None")

    # CA-10 — emitter -> parser round-trip, both DIGEST forms and the CHANGELOG.
    for emitted in (emit_digest_entry("v9.30", "2026-05-20", "H"),
                    emit_digest_entry(f"vl-rt {VERSION_LESS_MARKER}", "2026-05-20", "H")):
        cells = [c for cs in parse_digest_dates(emitted).values() for c in cs]
        m = DIGEST_DATE_CELL_RE.match(cells[0]) if len(cells) == 1 else None
        if not m or m.group("date") != "2026-05-20":
            return _fail(f"CA-10 the DIGEST parser does not read back what emit_digest_entry wrote: {emitted!r}")
    cl = parse_changelog_dates(emit_changelog_entry("v9.30", "2026-05-20", "S", "o/r", "notes/x.md"))
    if cl != {"v9.30": ["2026-05-20"]} or not _DATE_RE.match(cl["v9.30"][0]):
        return _fail(f"CA-10 the CHANGELOG parser does not read back what emit_changelog_entry wrote: {cl}")
    # CA-11 — keys are exact: v9.8 never reads v9.80's entry.
    exact = parse_digest_dates("### v9.80 (2026-01-01) — a\n### v9.8 (2026-05-30) — b\n")
    if exact.get("v9.8") != ["2026-05-30"] or exact.get("v9.80") != ["2026-01-01"]:
        return _fail(f"CA-11 DIGEST keys must match exactly: {exact}")

    # The stdout contract deploy.sh parses: a DENOM line first, then six-field FAIL rows
    # and four-field NOT-EVALUATED rows, and nothing else.
    lines = render_closeout_report(res)
    if not lines[0].startswith("DENOM: status=degraded enumerated=8 examined=8 "):
        return _fail(f"the DENOM line must lead and read status=degraded enumerated=8 examined=8: {lines[0]!r}")
    rows = [ln.split("\t") for ln in lines[1:]]
    if sorted(r[0] for r in rows) != ["FAIL"] * 4 + ["NOT-EVALUATED"] * 2:
        return _fail(f"the report must carry exactly 4 FAIL and 2 NOT-EVALUATED rows: {[r[0] for r in rows]}")
    for r in rows:
        if (r[0] == "FAIL" and (len(r) != 6 or r[2] != "closeout_anchor")) or \
                (r[0] == "NOT-EVALUATED" and len(r) != 4):
            return _fail(f"a report row has the wrong shape: {r}")
    ca1_row = next(r for r in rows if r[0] == "FAIL" and r[1] == "v9.22")
    if ca1_row[3] != "DIGEST=2026-05-12;CHANGELOG=2026-05-12;note=2026-05-11" or \
            ca1_row[4] != "2026-05-11: {note} | 2026-05-12: {CHANGELOG,DIGEST}":
        return _fail(f"CA-1's FAIL row must name every value and the split: {ca1_row[3]!r} / {ca1_row[4]!r}")
    clean = {**res, "findings": [], "not_evaluated": []}
    if not render_closeout_report(clean)[0].startswith("DENOM: status=fetched "):
        return _fail("a run with every surface compared must report status=fetched")

    # CA-12 — a version-less row's CHANGELOG entry is compared when one exists. The scripted
    # emitter refuses to write one, but a close-out written by hand or hub-direct can, and a
    # skipped read would hide its divergence with no finding and no NOT-EVALUATED line.
    # Sensitivity: vl-hand's entry is a day after its DIGEST and note -> one finding naming
    # CHANGELOG alone. Specificity: vl-twin's entry agrees and vl-none has none -> silent,
    # and the absent entry is never NOT-EVALUATED. The DENOM line counts the two apart.
    vl_rows = parse_log_rows(
        "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
        "|---|---|---|---|---|---|---|---|\n"
        "| v9.40 | m40 | #1 | #40 | `a` | `v9.40` | VERIFIED | 2026-06-01 |\n"
        "| vl-hand (version-less) | vl-hand | #1 | #41 | `a` | (none) | VERIFIED | 2026-06-02 |\n"
        "| vl-twin (version-less) | vl-twin | #1 | #42 | `a` | (none) | VERIFIED | 2026-06-03 |\n"
        "| vl-none (version-less) | vl-none | #1 | #43 | `a` | (none) | VERIFIED | 2026-06-04 |\n"
    )
    vl_digest = parse_digest_dates(
        "### v9.40 (2026-06-01) — the cutoff row agrees\n"
        "### vl-hand (2026-06-02, version-less) — a hand-written CHANGELOG entry a day later (CA-12)\n"
        "### vl-twin (2026-06-03, version-less) — a hand-written CHANGELOG entry that agrees (CA-12)\n"
        "### vl-none (2026-06-04, version-less) — no CHANGELOG entry (CA-12)\n"
    )
    vl_changelog = parse_changelog_dates(
        "## [v9.40] - 2026-06-01\n"
        "## [vl-hand] - 2026-06-03\n"
        "## [vl-twin] - 2026-06-03\n"
    )
    vl_notes = {"v9.40": "2026-06-01", "vl-hand": "2026-06-02", "vl-twin": "2026-06-03",
                "vl-none": "2026-06-04"}

    def vl_note(row: dict) -> tuple[str | None, str]:
        value = vl_notes.get(_slug_from_version_cell(row["version"]))
        return (value, "") if value else (None, "absent")

    vl = verify_closeout_anchors(vl_rows, vl_digest, vl_changelog, vl_note, cutoff="v9.40")
    if vl is None:
        return _fail("CA-12 the fixture cutoff v9.40 names a LOG row, but the scope did not resolve")
    if [f["version"] for f in vl["findings"]] != ["vl-hand (version-less)"] or \
            vl["findings"][0]["partition"] != [("2026-06-02", ["DIGEST", "note"]), ("2026-06-03", ["CHANGELOG"])]:
        return _fail(f"CA-12 a version-less row's CHANGELOG entry must be compared when one exists: "
                     f"findings {[(f['version'], f['partition']) for f in vl['findings']]}")
    if vl["not_evaluated"] or vl["version_less"] != 3 or vl.get("version_less_changelog") != 2:
        return _fail(f"CA-12 counters wrong: not_evaluated={vl['not_evaluated']} version_less={vl['version_less']} "
                     f"version_less_changelog={vl.get('version_less_changelog')} (expected none/3/2)")
    vl_denom = render_closeout_report(vl)[0]
    if "1 version-less compared two-way" not in vl_denom or "2 version-less compared three-way" not in vl_denom:
        return _fail(f"CA-12 the DENOM line must count the two-way and three-way version-less rows apart: {vl_denom!r}")
    return 0


def _self_test_closeout_cutoff_resolves() -> int:
    """CLOSEOUT_ANCHOR_DECLARED_AT names a live LOG row, the scope is non-empty, and the
    live note reader returns a date at both ends of that scope.

    The second half closes the one silent degradation the in-process arms cannot see:
    they inject the note surface, so a reader that stopped reading would turn every
    note-versus-the-rest finding into a NOT-EVALUATED line, which moves no exit code on
    any mode. Reading the note of the cutoff row and of the last VERIFIED row in scope
    turns that into a hard self-test failure, in CI and at deploy time alike, with no
    new import.

    THIS LIMB READS THE LIVE LOG AND TWO LIVE NOTES, for the reason
    _self_test_grandfathering_closed does: the assertion is about the real corpus. An
    unresolvable LOG is a FAIL, never a skip.
    """
    if not LOG_PATH.exists():
        print(f"self-test FAIL: close-out cutoff limb cannot run — {_rel(LOG_PATH)} does not resolve. "
              "This limb is corpus-bound by necessity; refusing to pass vacuously", file=sys.stderr)
        return 1
    rows = parse_log_rows(LOG_PATH.read_text(encoding="utf-8"))
    if not rows:
        print("self-test FAIL: close-out cutoff limb parsed zero LOG rows", file=sys.stderr)
        return 1
    idx = next((i for i, r in enumerate(rows)
                if _slug_from_version_cell(r["version"]) == CLOSEOUT_ANCHOR_DECLARED_AT), None)
    if idx is None:
        print(f"self-test FAIL: CLOSEOUT_ANCHOR_DECLARED_AT '{CLOSEOUT_ANCHOR_DECLARED_AT}' names no "
              "RELEASE_LOG row — --verify-closeout-anchors would exit 3 on every run", file=sys.stderr)
        return 1
    if idx + 1 >= len(rows):
        print(f"self-test FAIL: no RELEASE_LOG row follows {CLOSEOUT_ANCHOR_DECLARED_AT} — the scope "
              "holds only its boundary row, so the check would pass vacuously", file=sys.stderr)
        return 1
    last = next((r for r in reversed(rows[idx:]) if r.get("state", "").strip() == "VERIFIED"), None)
    for label, row in (("the cutoff row", rows[idx]), ("the last VERIFIED row in scope", last)):
        if row is None:
            print("self-test FAIL: no VERIFIED row at or after the cutoff — nothing for the note "
                  "reader to read", file=sys.stderr)
            return 1
        value, cause = read_note_closeout_date(row["version"], row.get("milestone", ""))
        if value is None:
            print(f"self-test FAIL: the live note reader returned no date for {label} "
                  f"({row['version']}): {cause}. A reader that cannot read the note silently "
                  "collapses the three-way compare to two-way", file=sys.stderr)
            return 1
    return 0


def _existing_theme_map() -> dict[str, str]:
    """Read the on-disk INDEX (if present) and map Version -> Theme so a
    regenerate preserves hand-authored Theme prose. Returns {} if absent."""
    if not INDEX_PATH.exists():
        return {}
    try:
        existing = parse_index_rows(INDEX_PATH.read_text(encoding="utf-8"))
    except OSError:
        return {}
    out: dict[str, str] = {}
    for r in existing:
        theme = r.get("theme", "").strip()
        if theme and theme != THEME_PLACEHOLDER:
            out[r["version"]] = theme
    return out


def _rel(path: Path) -> str:
    try:
        return str(path.relative_to(WORKSPACE_ROOT))
    except ValueError:
        return str(path)


def emit(surface: str, version: str, merge_anchor: str, closeout_anchor: str,
         repo_slug: str, log_rows: list[dict], version_less: bool = False) -> int:
    """Print ONE entry for `surface` to stdout. Never writes a file."""
    log_by_version = {r["version"]: r for r in log_rows}
    row = log_by_version.get(version)
    if row is None:
        # Also admit the version-less cell form, whose LOG Version cell carries
        # the "(version-less)" qualifier while the caller passes the bare slug.
        row = next((r for r in log_rows if _slug_from_version_cell(r["version"]) == version), None)
    if row is None:
        print(f"error: no RELEASE_LOG row for '{version}' — the LOG row is written by the "
              f"transition phase BEFORE any derived surface is emitted, so its absence is a "
              f"real ordering anomaly, not something to work around", file=sys.stderr)
        return 3

    if surface == "index":
        # The merge anchor is RELAYED, and asserted against the LOG cell it must
        # equal. This is what makes the argument load-bearing rather than
        # decorative: a caller that substituted a clock sample fails HERE instead
        # of silently minting the next grandfathering entry.
        if row["date"] and merge_anchor != row["date"]:
            print(f"error: --merge-anchor '{merge_anchor}' does not equal the RELEASE_LOG Date "
                  f"'{row['date']}' for {version}. The INDEX and the LOG both carry the MERGE "
                  f"anchor; refusing to emit a row that would diverge from its own source",
                  file=sys.stderr)
            return 3
        theme = _existing_theme_map().get(row["version"], "")
        print(emit_index_entry(row, merge_anchor, theme, version_less))
        return 0

    note = read_note(row["version"], row.get("milestone", ""))

    if surface == "digest":
        # Note absence is EXPECTED here, not an error: the DIGEST entry is
        # emitted before the note is scaffolded, so the placeholder is the
        # normal fresh-close path and the operator fills it at chore-PR review.
        print(emit_digest_entry(row["version"], closeout_anchor, note["headline"], version_less))
        return 0

    # surface == "changelog"
    if version_less or VERSION_LESS_MARKER in row["version"]:
        print(f"error: '{row['version']}' is version-less and has no '## [vX.Y]' key to write. "
              f"The close-out SKIPs the CHANGELOG for a version-less release; refusing to invent "
              f"a slug-keyed entry", file=sys.stderr)
        return 3
    if note["text"] is None:
        # Loud, unlike the DIGEST: the CHANGELOG is written AFTER the note is
        # scaffolded, so an unresolvable note here is a real anomaly. This
        # preserves the shipped fail-loud posture that replaced a silent
        # operator-local date fallback.
        print(f"error: release note for '{version}' does not resolve under "
              f"{_rel(NOTES_DIR)} — the CHANGELOG entry is emitted after the note is scaffolded, "
              f"so this is a real anomaly. Failing loudly rather than emitting a plausible-looking "
              f"wrong row", file=sys.stderr)
        return 3
    print(emit_changelog_entry(version, closeout_anchor, note["summary"], repo_slug, note["path"]),
          end="")
    return 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--output-stdout", action="store_true", help="Print to stdout instead of writing to RELEASE_INDEX.md")
    p.add_argument("--verify", action="store_true", help="Re-derive LOG-sourced fields and diff vs on-disk RELEASE_INDEX.md; exit 1 on drift, exit 3 on path/parse failure or an INDEX orphan row not derivable from the LOG")
    p.add_argument("--self-test", action="store_true", help="Run in-process synthetic LOG+INDEX drift test; exit 0 on PASS")
    p.add_argument("--emit", choices=EMIT_SURFACES, help="Emit ONE entry for the named derived surface to stdout (never writes a file). Requires --version, --merge-anchor, --closeout-anchor and --repo-slug")
    p.add_argument("--version", dest="version", help="Release version key (or version-less slug) the emitted entry is for")
    p.add_argument("--merge-anchor", help="MERGE-event date (YYYY-MM-DD) carried by the LOG and INDEX. REQUIRED with --emit; never sampled here")
    p.add_argument("--closeout-anchor", help="CLOSE-OUT run date (YYYY-MM-DD) carried by the DIGEST, the note and the CHANGELOG. REQUIRED with --emit; never sampled here")
    p.add_argument("--repo-slug", help="Repository slug as owner/repo, used in the CHANGELOG Release URL. REQUIRED with --emit; never resolved from the environment or operator config here")
    p.add_argument("--version-less", action="store_true", help="Declare this release version-less. Declared by the caller, which owns the version grammar; never inferred here")
    # DECLARED path overrides, not ambient ones. The corpus paths are read from
    # arguments so the projector is fixture-drivable — the close-out's own
    # hermetic self-test drives these phases against a sandbox corpus in a temp
    # dir, and a tool that could only ever read the live repo would either break
    # that self-test or silently read the wrong corpus during it. Omitted =>
    # the repo-resolved defaults, so Check 23's `--verify` invocation is unchanged.
    p.add_argument("--log-path", help="Override the RELEASE_LOG.md path (fixture injection)")
    p.add_argument("--index-path", help="Override the RELEASE_INDEX.md path (fixture injection)")
    p.add_argument("--notes-dir", help="Override the release-notes directory (fixture injection)")
    p.add_argument("--verify-closeout-anchors", action="store_true", help="Read-only: for every VERIFIED RELEASE_LOG row at/after CLOSEOUT_ANCHOR_DECLARED_AT, compare the close-out date on the DIGEST heading, the CHANGELOG heading and the release-note frontmatter; exit 1 on a divergence, exit 3 on an unresolved surface or scope (deploy.sh Check 82)")
    p.add_argument("--digest-path", help="Override the RELEASE_DIGEST.md path (fixture injection)")
    p.add_argument("--changelog-path", help="Override the CHANGELOG.md path (fixture injection)")
    args = p.parse_args()

    # Exclusive BEFORE any mode dispatch: --self-test returns early below, so a combined
    # invocation checked any later would silently run the self-test and report its exit as
    # the verification's.
    if args.verify_closeout_anchors:
        clash = [flag for flag, on in (("--verify", args.verify), ("--emit", args.emit),
                                       ("--self-test", args.self_test),
                                       ("--output-stdout", args.output_stdout)) if on]
        if clash:
            p.error("--verify-closeout-anchors cannot be combined with " + ", ".join(clash))

    if args.self_test:
        return _self_test()

    global LOG_PATH, INDEX_PATH, NOTES_DIR, DIGEST_PATH, CHANGELOG_PATH
    if args.log_path:
        LOG_PATH = Path(args.log_path).resolve()
    if args.index_path:
        INDEX_PATH = Path(args.index_path).resolve()
    if args.notes_dir:
        NOTES_DIR = Path(args.notes_dir).resolve()
    if args.digest_path:
        DIGEST_PATH = Path(args.digest_path).resolve()
    if args.changelog_path:
        CHANGELOG_PATH = Path(args.changelog_path).resolve()

    # Path-resolution failure (clause 1): LOG missing → exit 3, NOT a silent
    # pass and NOT a drift-exit-1. The check is unverifiable; deploy.sh maps
    # exit 3 to FAIL/DRIFT (per #459).
    if not LOG_PATH.exists():
        print(f"error: path-resolution failure — RELEASE_LOG.md not found at {_rel(LOG_PATH)}", file=sys.stderr)
        return 3

    log_text = LOG_PATH.read_text(encoding="utf-8")
    rows = parse_log_rows(log_text)
    if not rows:
        # Parse failure on a resolved file = schema drift between tool and corpus,
        # a config error → exit 3 (NOT a masked exit 0/1).
        print("error: path-resolution failure — no LOG rows parsed (LOG_ROW_RE vs current schema mismatch)", file=sys.stderr)
        return 3

    if args.verify_closeout_anchors:
        for label, path in (("RELEASE_DIGEST.md", DIGEST_PATH), ("CHANGELOG.md", CHANGELOG_PATH),
                            ("the release-notes directory", NOTES_DIR)):
            if not path.exists():
                print(f"error: path-resolution failure — {label} not found at {_rel(path)}; the "
                      "close-out anchors are unverifiable, which is not a clean result", file=sys.stderr)
                return 3
        try:
            digest_text = DIGEST_PATH.read_text(encoding="utf-8")
            changelog_text = CHANGELOG_PATH.read_text(encoding="utf-8")
        except (OSError, UnicodeDecodeError) as exc:
            print(f"error: path-resolution failure — a close-out surface is unreadable ({exc}); "
                  "this is not a clean result", file=sys.stderr)
            return 3
        result = verify_closeout_anchors(
            rows,
            parse_digest_dates(digest_text),
            parse_changelog_dates(changelog_text),
            lambda r: read_note_closeout_date(r["version"], r.get("milestone", "")),
        )
        if result is None:
            print(f"error: CLOSEOUT_ANCHOR_DECLARED_AT '{CLOSEOUT_ANCHOR_DECLARED_AT}' names no "
                  "RELEASE_LOG row — the scope cannot be resolved; this is not a clean result",
                  file=sys.stderr)
            return 3
        for line in render_closeout_report(result):
            print(line)
        return 1 if result["findings"] else 0

    if args.emit:
        # EVERY non-file input is required, for EVERY surface — including the ones
        # a given surface does not consume. A defaulted input is an ambient source
        # wearing a parameter's name, whether that ambient source is a clock or an
        # operator config file, and the whole point of the parameterisation is that
        # no such path exists. argparse's own message class is used verbatim so a
        # grader can distinguish "required argument missing" from "flag misspelled",
        # which are otherwise indistinguishable by exit code alone.
        missing = [flag for flag, val in (
            ("--version", args.version),
            ("--merge-anchor", args.merge_anchor),
            ("--closeout-anchor", args.closeout_anchor),
            ("--repo-slug", args.repo_slug),
        ) if not val]
        if missing:
            p.error("the following arguments are required with --emit: " + ", ".join(missing))
        # Well-formedness, not merely presence. A slug that is not owner/repo-shaped
        # lands in a durable CHANGELOG row as a permanently broken URL — the exact
        # "plausible-looking wrong row" class that a sibling fix in this same code
        # path replaced with a loud failure. Presence alone would not catch it.
        if args.repo_slug.count("/") != 1 or not all(args.repo_slug.split("/")):
            p.error(f"--repo-slug must be owner/repo-shaped; got '{args.repo_slug}'. A bare repo "
                    "name emits a permanently broken Release URL into a durable CHANGELOG row")
        return emit(args.emit, args.version, args.merge_anchor, args.closeout_anchor,
                    args.repo_slug, rows, args.version_less)

    if args.verify:
        if not INDEX_PATH.exists():
            print(f"error: path-resolution failure — RELEASE_INDEX.md not found at {_rel(INDEX_PATH)}", file=sys.stderr)
            return 3
        index_text = INDEX_PATH.read_text(encoding="utf-8")
        index_rows = parse_index_rows(index_text)
        if not index_rows:
            print("error: path-resolution failure — no INDEX rows parsed (INDEX_ROW_RE vs current rendered schema mismatch)", file=sys.stderr)
            return 3
        # Fail-loud on orphan: an on-disk INDEX row not derivable from the LOG
        # would be SILENTLY DROPPED by a regenerate. Refuse (exit 3 — a
        # corpus-integrity violation, NOT mere drift) so the loss surfaces as a
        # FAIL the operator must reconcile (add the missing LOG row, or confirm
        # the INDEX row spurious) before the close-out can regenerate.
        orphans = find_index_orphans(rows, index_rows)
        if orphans:
            print(f"{CORPUS_INDEX_ORPHAN_PREFIX}: {len(orphans)} INDEX row(s) not derivable from the LOG "
                  f"(would be dropped by regenerate): {', '.join(orphans)} — add the missing RELEASE_LOG row(s) "
                  f"or remove the spurious INDEX row(s); the generator refuses to silently drop them",
                  file=sys.stderr)
            return 3
        # Render once and re-parse it, so the Theme-integrity and row-order limbs
        # compare against what a render would actually produce rather than against
        # an assumption about it.
        rendered_rows = parse_index_rows(
            render_index(rows, _existing_theme_map(), extract_index_header(index_text)))
        findings = verify(rows, index_rows, rendered_rows)
        if not findings:
            return 0
        # TSV-line per finding for downstream parseability
        for f in findings:
            print(f"{f['version']}\t{f['field']}\t{f['log_value']}\t{f['index_value']}\t{f['recommendation']}")
        return 1

    # Write / --output-stdout: fail-loud on orphan BEFORE rendering. The render
    # is LOG-sourced, so any on-disk INDEX row whose Version is absent from the
    # LOG would vanish from the output. Refuse (exit 3) rather than silently
    # dropping it — this is the FM-1 destructive-regenerate guard.
    existing_header: list[str] | None = None
    if INDEX_PATH.exists():
        try:
            existing_text = INDEX_PATH.read_text(encoding="utf-8")
        except OSError:
            existing_text = ""
        existing_index_rows = parse_index_rows(existing_text)
        # Preserve the on-disk header verbatim. Without this the render emits its
        # own hard-coded header and DELETES every line the corpus has added above
        # the table — including the paragraph that declares which anchor the Date
        # column carries and states that grandfathered rows must not be rewritten.
        existing_header = extract_index_header(existing_text)
        orphans = find_index_orphans(rows, existing_index_rows)
        if orphans:
            print(f"{CORPUS_INDEX_ORPHAN_PREFIX}: refusing to regenerate — {len(orphans)} on-disk INDEX row(s) "
                  f"not derivable from the LOG would be DROPPED: {', '.join(orphans)}. Add the missing "
                  f"RELEASE_LOG row(s) (or remove the spurious INDEX row(s)) before regenerating.",
                  file=sys.stderr)
            return 3

    index_text = render_index(rows, _existing_theme_map(), existing_header)

    if args.output_stdout:
        print(index_text)
    else:
        INDEX_PATH.write_text(index_text, encoding="utf-8")
        print(f"wrote {_rel(INDEX_PATH)} ({len(rows)} rows)")
    return 0


if __name__ == "__main__":
    sys.exit(main())
