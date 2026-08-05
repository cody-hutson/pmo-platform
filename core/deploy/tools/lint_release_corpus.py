#!/usr/bin/env python3
"""Release-corpus integrity validator for deploy.sh Check 20.

Per the v11.04b-3 D5 Stage 5 spec; extended with the note-content
checks from release-notes-standard.md §3.2 (checks 9-12). Check 15
(release-corpus cross-link integrity) was RETIRED in v2; this validator is
wired to Check 20 (note-content lint).

Validates:

  (a) Filename naming regex compliance on releases/plans/ (with allowlist
      for 3 grandfathered exceptions: v11.01-Z, v11.01-I phase plans + the
      v10.3_retrospective_validation analysis artifact).
  (b) Frontmatter schema validity on plans + notes (forward-only from
      v11.04b-3 per D2 phasing — pre-v11.04b-3 files exempt until the F-3
      backfill).
  (c) RETIRED (identifier reserved, must NOT be reused) — was "INDEX surface
      row count >= LOG entry count". Strictly weaker than the LOG<->INDEX
      coexistence limb of generate_release_index.py --verify (deploy.sh
      Check 23), which names the drifted version instead of a count and also
      catches a same-count-different-set INDEX. `--check index` is still an
      accepted value and now runs nothing.
  (d) Frontmatter `type:` field matches filename type-suffix (Tier 3
      discriminator coherence per release-corpus-schema.md).
  (e) Note-content lint (release-notes-standard.md §3.2 checks 9-14):
      - 9: Section 6a present with >=1 bullet or 'No user-visible' placeholder
      - 10: Banned-jargon scan (§2.4 deny-list)
      - 11: 'Why it matters:' beat present per Section 6a bullet
            (or <!-- impact:foundational --> escape marker)
      - 12: No raw file paths in Section 6a bullet bodies
      - 13: Whole-published-body link purity — every markdown-link target in
            the frontmatter-stripped body (the exact bytes that publish to the
            GitHub Release page, Surface 1) must be absolute (https://, #, or
            mailto:); a repo-relative target (../, ./, release/, core/, docs/,
            .claude/, pmo-platform/) 404s on the Release surface and is flagged.
            Floored at NOTE_LINK_CUTOVER (forward-only) so the historical notes
            that carry the Section-6b ](../RELEASE_LOG.md) template link are not
            retroactively failed.
      - 14: Schema/format sample block (ADVISORY, flag-gated). For a release
            DECLARED schema/format-changing by the Stage-13 closer via
            --sample-block-advisory <version>, the note body must carry >=1
            fenced sample block positioned outside the Section 6a bullet span,
            or the '<!-- sample-block: n/a - <reason> -->' escape marker.
            Whether a release is schema/format-changing is DECLARED, not
            detected: the authoritative source is the release plan's File
            Change Matrix, not the note (a note that omits the sample block
            also omits the vocabulary that would betray the omission).
            Check 14 therefore does NOT run without the flag, is NOT part of
            the corpus-wide Check 20 run, and its findings NEVER contribute to
            the blocking exit status (see ADVISORY_PREFIX).
      Checks 9-12 floored at the lowest live version family (v1.x) per
      NOTE_CONTENT_CUTOVER; check 13 floored at NOTE_LINK_CUTOVER; check 14 has
      no floor (a declared release is by definition current).

This validator handles the schema/structural checks that go beyond link
resolution. (The doc-link primitive `check-doc-links.py` covers cross-link
resolution separately under Check 14; Check 15 was retired in v2.)

Authored under the v11.04b-3 D5 deliverable; lives at
core/deploy/tools/lint_release_corpus.py per the established engineering
tooling location. Corpus paths target the live modular-monolith layout
(release/releases/...).

Usage:
    python3 core/deploy/tools/lint_release_corpus.py
    python3 core/deploy/tools/lint_release_corpus.py --check filename
    python3 core/deploy/tools/lint_release_corpus.py --check schema
    python3 core/deploy/tools/lint_release_corpus.py --check index
    python3 core/deploy/tools/lint_release_corpus.py --check type-coherence
    python3 core/deploy/tools/lint_release_corpus.py --check note-content
    python3 core/deploy/tools/lint_release_corpus.py --check note-content \
        --sample-block-advisory v<version>

Exit codes: 0 = pass, 1 = content findings (one or more checks failed),
3 = path-resolution failure (a required corpus dir/file did not resolve —
CORPUS-PATH-UNRESOLVED — the surface is unverifiable, not clean). Exit 3
matches the cross-module-audit.sh family convention (per #459).
"""
from __future__ import annotations

import argparse
import re
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
# Live modular-monolith layout (post-restructure). The pre-restructure
# pmo-platform/... prefix is DEAD — the corpus lives under release/releases/.
# Note: RELEASE_LOG.md is under release/releases/ (NOT governance/).
PLANS_DIR = WORKSPACE_ROOT / "release" / "releases" / "plans"
NOTES_DIR = WORKSPACE_ROOT / "release" / "releases" / "notes"
INDEX_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_INDEX.md"
LOG_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_LOG.md"

# Coordinated regex (#2548 slug-primary pre-claim + #3307 vX.Y.Z patch form) — authored
# as ONE union expression per CIAC-3. It accepts:
#   (1) the versioned form v<MAJOR>.<MINOR>[.<PATCH>][<letter>][-<N>][-<slug>] — the
#       prior form PLUS the optional third (patch) component #3307 admits
#       (e.g. v3.65.1_RELEASE_PLAN.md);
#   (2) the slug-primary pre-claim form <slug>_RELEASE_PLAN.md (kebab-case: a
#       lowercase-alnum start, then lowercase-alnum/hyphen) — every in-flight release is
#       slug-keyed before the Stage-12 claim (#2548, ADR-092), so the pre-claim form is
#       admitted GENERALLY rather than per-release-allowlisted.
# It still rejects genuinely malformed names (v3.65.1.2, v3.65., v3.65.1.): the version
# branch has no trailing/extra dot, and the slug branch excludes '.' entirely. This
# GENERALIZES the former enumerated theme-plan allowlist entries (now regex-matched);
# only the 3 true grandfathered exceptions (non-_RELEASE_* suffixes) + README remain in
# FILENAME_ALLOWLIST below.
CANONICAL_FILENAME_RE = re.compile(
    r"^(?:v[0-9]+\.[0-9]+(?:\.[0-9]+)?[a-z]?(-[0-9]+)?(-[0-9a-z][-0-9a-z]*)?"
    r"|[0-9a-z][-0-9a-z]*)_(RELEASE_PLAN|RELEASE_NOTES)\.md$"
)

FILENAME_ALLOWLIST = {
    # Grandfathered exceptions — pre-convention phase/analysis artifacts whose suffix
    # is NOT _RELEASE_PLAN / _RELEASE_NOTES, so the canonical regex structurally cannot
    # match them (they are not release plans/notes). These stay allowlisted by name.
    "v11.01-Z_PHASE_PLAN.md",
    "v11.01-I_PHASE_PLAN.md",
    "v10.3_retrospective_validation.md",
    # Plans README (index for the plans/ directory, not a release plan).
    "README.md",
    # NOTE: the former per-plan theme-named entries were REMOVED here — the coordinated
    # CANONICAL_FILENAME_RE above now admits the slug-primary pre-claim form GENERALLY
    # (#2548), so those entries became dead (regex-matched) and are pruned per the
    # register-or-remove discipline. New slug-keyed pre-claim plans need no allowlist
    # entry; they match the regex.
}

CUTOVER_RELEASES = {"v11.04b-3", "v11.04b-3-doc-cleanup"}

REQUIRED_FIELDS = {"version", "date", "type", "issues", "pr", "links"}
TYPE_VALUES = {"plan", "note", "abandoned-plan", "phase-plan", "audit-plan"}

# Note-content lint (release-notes-standard.md §3.2 checks 9-12).
#
# Cutover floor reset to (1, 0, "", 0) for the re-versioned modular-monolith
# corpus: every live note is in the v1.x / v3.x families, all of which are
# BELOW the prior (11, 18) floor — so the old floor skipped all 11 live notes
# and Check 20 passed vacuously even with correct paths. The §3.2 content
# discipline is forward-going; the re-versioned corpus has no pre-standard
# legacy to grandfather, so the floor is the lowest live family (v1.x) and the
# exempt set is empty. (Version-less notes parse to (0,0,'',0). They are now
# linted via an explicit version-less BRANCH — VERSIONLESS_KEY below — exactly as
# this comment previously prescribed; the floor itself was NOT moved.)
#
# VERSIONLESS_KEY is what version_tuple() returns for any name VERSION_KEY_RE
# does not match — i.e. a slug-keyed (version-less) note. It is a MARKER, not a
# version: it must not be compared against the forward-only floors, because
# "no version" is not "older than v1.0". Naming it keeps the branch site
# self-documenting.
#
# WHAT THE BRANCH DOES *NOT* DO. It does not separate "version-less" from
# "unparseable name": version_tuple() returns this same sentinel for BOTH, so
# both are in scope under the branch AND under a lowered floor alike. There is
# no malformed-vs-version-less call here to collapse. Nor does anything else
# make that call for a NOTE: CANONICAL_FILENAME_RE has a single call site, and
# it walks PLANS_DIR only. A malformed note filename is therefore linted for
# CONTENT like any other in-scope note, while its SHAPE goes unchecked. That
# gap is pre-existing and out of scope here — do not widen the lint from this
# comment.
#
# WHAT IT DOES PRESERVE — the floor itself. Lowering NOTE_CONTENT_CUTOVER to
# this sentinel would additionally admit every name that parses to a REAL
# version sorting below the floor: "v0.5_RELEASE_NOTES.md" is (0, 5, "", 0),
# correctly dropped today and admitted by a lowered floor.
VERSIONLESS_KEY = (0, 0, "", 0)
NOTE_CONTENT_CUTOVER = (1, 0, "", 0)
PRE_CUTOVER_EXEMPT_VERSIONS: set[str] = set()
SECTION_6A_HEADER_RE = re.compile(r"^##\s+What changed for everyone", re.IGNORECASE)
NEXT_H2_RE = re.compile(r"^##\s+")
VERSION_KEY_RE = re.compile(r"^v(\d+)\.(\d+)([a-z])?(?:-(\d+))?")

# ─── Scaffold-residue detection (release-notes-standard.md §3.2; check 9b) ────
#
# THE SINGLE DEFINITION of the scaffold-residue token set for the whole platform.
# Every token below is a literal emitted by a Stage-13 close-out PRODUCER:
#
#   automated-closeout.sh phase_scaffold_release_notes  -> the note scaffold heredoc
#     "<one-sentence <=140"        frontmatter `summary:` placeholder (also reaches
#                                  CHANGELOG.md, which sources its blurb from `summary:`)
#     "<Headline - user-visible"   the H1 headline placeholder
#     "<!-- agent:"                every authoring-instruction comment
#     "AUTHOR_SUMMARY_HERE"        the summary-authoring marker
#   automated-closeout.sh phase_append_release_digest  -> the DIGEST H3 fallback
#     "<headline - populated by operator"
#
# A note carrying any of these is UNAUTHORED BY CONSTRUCTION: the close-out wrote it
# and nobody filled it in. That is a stronger signal than any Section-6a heuristic,
# and it is the one the §3.2 checks previously missed entirely — the scaffold's own
# guidance comment contains the literal "No user-visible behavior changes", which IS
# check 9's escape hatch, so an untouched scaffold graded CLEAN.
#
# Shell callers read this set via `--print-scaffold-tokens` rather than retyping the
# literals, so the python anchor and the automated-closeout.sh anchors cannot drift.
# The exact byte forms (em dash, U+2264) matter: files are read as UTF-8, keep them so.
SCAFFOLD_RESIDUE_TOKENS = [
    "<!-- agent:",
    "AUTHOR_SUMMARY_HERE",
    "<Headline — user-visible",
    "<one-sentence ≤140",
    "<headline — populated by operator",
]
# The `or r"(?!)"` fallback matters: "|".join over an EMPTY list yields "", and an
# empty pattern matches at every position — an emptied token list would silently flag
# every note in the corpus. `(?!)` never matches, so the degenerate case fails closed
# here and is caught loudly where it should be: the shell anchors return "token set
# unreadable" and the --self-test round-trip goes red. (Found by mutation testing.)
SCAFFOLD_RESIDUE_RE = re.compile(
    "|".join(re.escape(t) for t in SCAFFOLD_RESIDUE_TOKENS) or r"(?!)"
)

# Comment-stripper for the check-9 predicate. Section 6a's scaffold comment quotes
# check 9's own escape-hatch string, so evaluating check 9 on the raw span lets a
# scaffold satisfy the check it is supposed to fail. Check 9 is evaluated on the
# comment-stripped span; checks 10-12 keep reading authored prose.
HTML_COMMENT_RE = re.compile(r"<!--.*?-->", re.DOTALL)

# Check 13 (whole-body link purity) cutover floor. Forward-only at v2.37 — the
# release that introduces the check. 42 of 64 historical version-keyed notes
# carry the Section-6b `](../RELEASE_LOG.md)` / `](../plans/…)` template link
# (a repo-relative target that 404s on the Release page); a floorless rule would
# fail them all and red Check 20 on this release's own merge. The defect has
# already stopped behaviorally (v2.28+ use absolute blob/main/… URLs) but had no
# structural enforcement — this floor adds the enforcement going forward while
# leaving the historical notes as authored (accepted-residual, consistent with
# the NOTE_CONTENT_CUTOVER forward-only discipline). Mirrors NOTE_CONTENT_CUTOVER
# tuple shape (major, minor, suffix, sub).
NOTE_LINK_CUTOVER = (2, 37, "", 0)

# Check 13 chronology-mismatch exemption. The corpus carries a v3.x note lineage
# that predates the v1.x→v2.x mainline renumber, so a v3.x version-tuple sorts
# ABOVE the (2,37) floor numerically while being chronologically OLDER than the
# v2.37 release that introduces the check. Those older v3.x notes legitimately
# carry the legacy Section-6b `](../RELEASE_LOG.md)` / `](../plans/…)` template
# link — the exact accepted-residual the forward-only floor exists to protect.
# A pure tuple comparison mis-classifies them as "new" and would flag the legacy
# link, contradicting the floor's intent (and blocking Check 20's warn→enforce
# flip on a false positive). Exempt them by version key, mirroring how
# PRE_CUTOVER_EXEMPT_VERSIONS handles the same version-tuple/chronology mismatch
# for checks 9-12. (Newly-authored v3.x+ notes would use absolute URLs, so this
# set covers only the historical legacy-link members present at v2.37.)
NOTE_LINK_EXEMPT_VERSIONS: set[str] = {"v3.20"}

# Check 13 regexes. INLINE_LINK_RE captures a markdown link target (group 1).
# REPO_RELATIVE_TARGET_RE flags targets that render broken on the Release page;
# ABSOLUTE_TARGET_RE passes targets that render correctly there. A target that
# matches neither (e.g. an unresolved <OPERATOR_INSTANCE_…> token starting with
# '<') is not flagged — it is an operator-instance pointer, out of scope.
INLINE_LINK_RE = re.compile(r"\[[^\]]*\]\(([^)]+)\)")
REPO_RELATIVE_TARGET_RE = re.compile(r"^(?:\.\.?/|release/|core/|docs/|\.claude/|pmo-platform/)")
ABSOLUTE_TARGET_RE = re.compile(r"^(?:https?://|#|mailto:)")

# §2.4 banned-jargon deny-list — literal substrings, case-insensitive.
BANNED_JARGON_LITERAL = [
    "reflexive-pipeline self-exemption",
    "mirror byte-identity",
    "warn-mode posture",
    "warn-mode initially",
    "cutover effective date",
    "all-or-nothing rule",
    "structurally gate-blocking",
    "sub-window mutability",
    "disjoint scope",
    "forward-only",
    "reflexive-pipeline loop",
]

# §2.4 banned-jargon deny-list — regex patterns for parameterized terms.
BANNED_JARGON_REGEX = [
    (re.compile(r"schema v\d+\.\d+\s*(?:→|->)\s*v\d+\.\d+", re.IGNORECASE), "schema vX.Y → vX.Z"),
    (re.compile(r"\bcollective review CR-", re.IGNORECASE), "collective review CR-X"),
    (re.compile(r"\bgate-blocking\b", re.IGNORECASE), "gate-blocking"),
    (re.compile(r"\breversibility tier\b", re.IGNORECASE), "reversibility tier (standalone phrase)"),
]


# Sentinel prefix for path-resolution-failure findings. main() maps any finding
# carrying this prefix to exit 3 (path-config error) per the #459 fail-loud
# contract — distinct from content findings (exit 1) and clean (exit 0).
CORPUS_PATH_UNRESOLVED_PREFIX = "CORPUS-PATH-UNRESOLVED"

# Sentinel prefix for ADVISORY findings (release-notes-standard.md §3.2 check
# 14). Advisories are PRINTED but NEVER contribute to the blocking exit status:
# main() partitions findings on this prefix exactly as it partitions on
# CORPUS_PATH_UNRESOLVED_PREFIX above. Two properties are load-bearing and must
# survive any future edit:
#
#   (1) Advisories go to STDOUT in the findings list — never to stderr with
#       exit 0. All four callers capture the lint with `2>&1` but only INSPECT
#       the buffer when the exit code is non-zero, so a stderr advisory on a
#       clean run would be silently swallowed. An invisible advisory is not a
#       check.
#   (2) An advisory line cites the VERSION KEY and the BARE FILENAME only —
#       never the repo-root-relative note path. The close-out callers scope
#       findings to the closing version by grepping the output for
#       "release/releases/notes/<V>_RELEASE_NOTES.md" whenever the exit code is
#       non-zero; an advisory carrying that path would FALSE-BLOCK a close any
#       time an unrelated legacy finding made the exit non-zero.
ADVISORY_PREFIX = "ADVISORY"

# Check 14 recognizers. The escape marker mirrors the existing
# `<!-- impact:foundational -->` convention (an honest marker beats a
# decorative block, per the standard's fabricate-or-omit rule). The fence
# recognizer allows leading whitespace so a fence nested INSIDE a Section 6a
# bullet is still detected — that nesting is precisely the placement §2.8
# prohibits, so a column-zero-only match would miss the case the check exists
# to flag.
SAMPLE_BLOCK_NA_RE = re.compile(r"<!--\s*sample-block:\s*n/a\b", re.IGNORECASE)
FENCE_RE = re.compile(r"^[ \t]*```")


def _rel(path: Path) -> str:
    """Repo-root-relative display string; defensive against paths outside root.

    All corpus dirs resolve inside WORKSPACE_ROOT in normal operation, but a
    misconfigured path could sit outside it; relative_to() would then raise
    ValueError. Fall back to the absolute path string so a path-resolution
    finding never crashes the linter (Mode-3 robustness, per the Stage 5 spec).
    """
    try:
        return str(path.relative_to(WORKSPACE_ROOT))
    except ValueError:
        return str(path)


def parse_frontmatter(text: str) -> dict | None:
    """Naive YAML frontmatter parser. Returns dict or None if absent."""
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return None
    end = None
    for i, line in enumerate(lines[1:], start=1):
        if line.strip() == "---":
            end = i
            break
    if end is None:
        return None
    body = lines[1:end]
    fm: dict = {}
    current_key = None
    for line in body:
        if not line.strip() or line.lstrip().startswith("#"):
            continue
        if line[0] in (" ", "\t") and current_key is not None:
            stripped = line.strip()
            if isinstance(fm.get(current_key), dict):
                if ":" in stripped:
                    k, v = stripped.split(":", 1)
                    fm[current_key][k.strip()] = v.strip()
            continue
        if ":" in line:
            key, val = line.split(":", 1)
            key = key.strip()
            val = val.strip()
            if not val:
                fm[key] = {}
                current_key = key
            else:
                fm[key] = val
                current_key = key
    return fm


def is_post_cutover(version: str) -> bool:
    """Returns True if the release version is at or after v11.04b-3 (post-cutover)."""
    if version in CUTOVER_RELEASES:
        return True
    if not version.startswith("v"):
        return False
    return False


def check_filename_compliance() -> list[str]:
    findings: list[str] = []
    if not PLANS_DIR.exists():
        # A missing corpus dir is a PATH-RESOLUTION FAILURE, not a clean pass:
        # silently returning [] is the exact vacuous-pass #83 fixes. Emit a
        # distinct finding so main() can exit 3 (path-config error) rather than
        # let Check 20 read GREEN against a non-existent surface.
        return [f"CORPUS-PATH-UNRESOLVED: plans dir does not resolve at {_rel(PLANS_DIR)} — corpus path misconfigured"]
    # rglob (recursive) — plans are foldered into major-version subdirectories
    # (plans/v1|v2|v3/… + the _unversioned/ bucket) per plans/README.md (#230,
    # v3.54). A flat glob would stop scanning every subfoldered plan, silently
    # passing the filename gate. README.md lives only at the plans/ top level and
    # stays allowlisted.
    for path in sorted(PLANS_DIR.rglob("*.md")):
        name = path.name
        if name in FILENAME_ALLOWLIST:
            continue
        if not CANONICAL_FILENAME_RE.match(name):
            findings.append(f"FILENAME-NONCOMPLIANT: {_rel(path)} does not match canonical regex; add to FILENAME_ALLOWLIST if intentional")
    return findings


def check_schema_validity() -> list[str]:
    findings: list[str] = []
    for directory in (PLANS_DIR, NOTES_DIR):
        if not directory.exists():
            findings.append(f"{CORPUS_PATH_UNRESOLVED_PREFIX}: corpus dir does not resolve at {_rel(directory)} — corpus path misconfigured")
            continue
        for path in sorted(directory.rglob("v11.04b-3*.md")):
            text = path.read_text(encoding="utf-8")
            fm = parse_frontmatter(text)
            rel = _rel(path)
            if fm is None:
                findings.append(f"SCHEMA-MISSING: {rel} is post-cutover (v11.04b-3+) but lacks YAML frontmatter")
                continue
            missing = REQUIRED_FIELDS - set(fm.keys())
            if missing:
                findings.append(f"SCHEMA-MISSING-FIELDS: {rel} missing required field(s): {sorted(missing)}")
            type_val = fm.get("type", "")
            if type_val and type_val not in TYPE_VALUES:
                findings.append(f"SCHEMA-INVALID-TYPE: {rel} has type='{type_val}', expected one of {sorted(TYPE_VALUES)}")
    return findings


# ── Sub-check (c) — INDEX row count — RETIRED (identifier RESERVED) ──────────
#
# `check_index_row_count()` is RETIRED. Its identifier is RESERVED for citation
# continuity and MUST NOT be reused for a different assertion — the same
# convention deploy.sh applies to retired check numbers.
#
# Why retired, and why this one only. Its entire content was
# `index_rows < log_rows`, which is strictly WEAKER than Check 23's coexistence
# limb: `generate_release_index.py --verify` already fires on any LOG row absent
# from the INDEX, names the version rather than a count, and fires on a
# same-count-different-set INDEX that a row-count comparison cannot see at all.
# Under the release-corpus Derived-Surface Contract the INDEX is a PROJECTION of
# the LOG written by one emitter, so a count-only gate on the pair is the weakest
# available restatement of a stronger check that is already wired.
#
# Sub-checks (a) filename compliance, (b) frontmatter schema, (d) type-discriminator
# coherence and (e) note-content are UNRELATED to the ledger pair and are untouched.
#
# `--check index` remains an ACCEPTED value so no existing invocation breaks; it
# now runs nothing and says so. Callers wanting the LOG↔INDEX assertion should
# invoke `generate_release_index.py --verify` (deploy.sh Check 23) directly.


def check_type_coherence() -> list[str]:
    findings: list[str] = []
    for directory, expected_type in ((PLANS_DIR, "plan"), (NOTES_DIR, "note")):
        if not directory.exists():
            findings.append(f"{CORPUS_PATH_UNRESOLVED_PREFIX}: corpus dir does not resolve at {_rel(directory)} — corpus path misconfigured")
            continue
        for path in sorted(directory.rglob("v11.04b-3*.md")):
            text = path.read_text(encoding="utf-8")
            fm = parse_frontmatter(text)
            if fm is None:
                continue
            rel = _rel(path)
            type_val = fm.get("type", "")
            if not type_val:
                continue
            name = path.name
            if expected_type == "plan" and type_val == "plan":
                if not name.endswith("_RELEASE_PLAN.md"):
                    findings.append(f"TYPE-MISMATCH: {rel} type='plan' but filename does not end with _RELEASE_PLAN.md")
            elif expected_type == "note" and type_val == "note":
                if not name.endswith("_RELEASE_NOTES.md"):
                    findings.append(f"TYPE-MISMATCH: {rel} type='note' but filename does not end with _RELEASE_NOTES.md")
    return findings


def version_tuple(version_or_filename: str) -> tuple:
    """Parse 'v11.18' or 'v11.04b-3' or 'v12.09_RELEASE_NOTES.md' to a sortable tuple."""
    m = VERSION_KEY_RE.match(version_or_filename)
    if not m:
        return (0, 0, "", 0)
    major = int(m.group(1))
    minor = int(m.group(2))
    suffix = m.group(3) or ""
    sub = int(m.group(4)) if m.group(4) else 0
    return (major, minor, suffix, sub)


def extract_section_6a(text: str) -> str | None:
    """Return body of '## What changed for everyone…' section, or None if header absent."""
    lines = text.splitlines()
    start = None
    for i, line in enumerate(lines):
        if SECTION_6A_HEADER_RE.match(line):
            start = i + 1
            break
    if start is None:
        return None
    end = len(lines)
    for i in range(start, len(lines)):
        if NEXT_H2_RE.match(lines[i]):
            end = i
            break
    return "\n".join(lines[start:end])


def extract_body(text: str) -> str:
    """Return the frontmatter-stripped body — the exact bytes that publish to
    the GitHub Release page (Surface 1).

    Mirrors the emit transform `sed '1,/^---$/d; 1,/^---$/d'` (release-notes-
    standard.md §5.1 / stage-12-execute.md): drop every line through the SECOND
    `---` delimiter. If the file does not open with a `---` frontmatter fence,
    the whole text is the body (no stripping) — matching the sed behaviour when
    the second address is never found is NOT relied upon here; absent a leading
    fence the published body is the file verbatim, which is what we lint.
    """
    lines = text.splitlines()
    if not lines or lines[0].strip() != "---":
        return text
    # Find the closing fence of the frontmatter (second '---').
    for i in range(1, len(lines)):
        if lines[i].strip() == "---":
            return "\n".join(lines[i + 1 :])
    # Opened a fence that never closed — degenerate; treat as no body stripped
    # so a malformed note still gets its links scanned rather than silently
    # passing on an empty body.
    return text


def check_body_link_purity(rel: str, body: str) -> list[str]:
    """Check 13: flag repo-relative markdown-link targets in the published body.

    Every inline markdown link target in the frontmatter-stripped body must be
    absolute (https://, #, mailto:) because the body renders on the GitHub
    Release page. A repo-relative target (../, ./, release/, core/, docs/,
    .claude/, pmo-platform/) 404s there. Keyed on "renders on the Release
    surface" — NOT a blanket relative-link ban (the committed note file
    legitimately lives in release/releases/notes/, so a relative link is correct
    in the file; it is only wrong for the published Surface-1 body).
    """
    findings: list[str] = []
    for n, line in enumerate(body.splitlines(), start=1):
        for m in INLINE_LINK_RE.finditer(line):
            target = m.group(1).strip()
            if ABSOLUTE_TARGET_RE.match(target):
                continue
            if REPO_RELATIVE_TARGET_RE.match(target):
                findings.append(
                    f"NOTE-BODY-RELATIVE-LINK: {rel} body link target '{target}' is repo-relative "
                    f"— renders broken on the GitHub Release surface; use an absolute https://github.com/… URL "
                    f"(release-notes-standard.md §5.1/§5.3 Surface-1 link rule). Line: {n}"
                )
    return findings


def parse_bullets(section_text: str) -> list[str]:
    """Group lines into top-level bullets (lines starting with '- ' at column 0)."""
    bullets: list[str] = []
    current: str | None = None
    for line in section_text.splitlines():
        if line.startswith("- "):
            if current is not None:
                bullets.append(current)
            current = line[2:]
        elif current is not None and (line.startswith("  ") or line.startswith("\t")):
            current += "\n" + line
        elif current is not None and not line.strip():
            bullets.append(current)
            current = None
    if current is not None:
        bullets.append(current)
    return bullets


def check_note_content() -> list[str]:
    """Lint Section 6a content per release-notes-standard.md §3.2 checks 9-12.

    Floor is NOTE_CONTENT_CUTOVER for version-KEYED notes. Version-less
    (slug-keyed) notes are IN SCOPE for checks 9-12: they carry no version, so
    they bypass the content floor via the VERSIONLESS_KEY branch rather than by
    the floor being moved. They remain EXEMPT from check 13 (whole-body link
    purity), whose independent NOTE_LINK_CUTOVER floor exists to grandfather
    exactly this class of historical note — the same accepted-residual rationale
    NOTE_LINK_EXEMPT_VERSIONS encodes for the older v3.x lineage.
    """
    findings: list[str] = []
    if not NOTES_DIR.exists():
        # PATH-RESOLUTION FAILURE — a missing notes dir is the exact vacuous
        # pass #83 fixes (Check 20 lints nothing and reads GREEN). Emit a
        # distinct finding so main() exits 3, never silently exits 0.
        return [f"{CORPUS_PATH_UNRESOLVED_PREFIX}: notes dir does not resolve at {_rel(NOTES_DIR)} — corpus path misconfigured"]

    # check-12 banned-path needle: detects RAW pre-restructure repo paths in
    # Section 6a prose. The pmo-platform/ literal is intentionally retained
    # (modernizing it to also catch release/-rooted paths is accepted-residual
    # for v3.20 per the Stage 5 spec; the ratified deliberate-violation DT proof
    # depends on this needle matching pmo-platform/...).
    path_re = re.compile(r"(?:pmo-platform/|\.claude/)\S+")
    link_strip_re = re.compile(r"\[[^\]]*\]\([^)]*\)")

    # rglob (recursive) — notes are foldered into major-version subdirectories
    # (notes/v1|v2|v3/… + the _unversioned/ bucket) per plans/README.md (#230,
    # v3.54). version_tuple keys off path.name (folder-agnostic), so the cutover
    # floor and exempt-set logic are unchanged; only discovery must recurse or the
    # §3.2 content lint silently stops scanning the foldered notes.
    #
    # The pattern keys on the _RELEASE_NOTES.md suffix, NOT on a leading "v",
    # because that suffix is the corpus's own type discriminator — the same token
    # CANONICAL_FILENAME_RE already anchors note identity on. Keying discovery to
    # it makes filename-authority and discovery agree by construction. A "v*"
    # pattern instead keyed on the VERSION, which silently excluded every
    # slug-keyed (version-less) note: the lint declared those files canonical at
    # the filename check and was then structurally unable to read them here.
    # The pattern is deliberately LAYOUT-INDEPENDENT — no _unversioned/ segment
    # and no major-version segment appears in it — so it holds under any layout.
    for path in sorted(NOTES_DIR.rglob("*_RELEASE_NOTES.md")):
        ver = version_tuple(path.name)
        # Version-less notes carry no version, so the forward-only floor does not
        # apply to them at all — "no version" is not "older than the floor".
        # Admitting them by BRANCH keeps NOTE_CONTENT_CUTOVER untouched.
        is_versionless = ver == VERSIONLESS_KEY
        if not is_versionless and ver < NOTE_CONTENT_CUTOVER:
            continue
        # Extract version key (e.g., "v12.09" from "v12.09_RELEASE_NOTES.md") for exempt-set lookup
        ver_match = VERSION_KEY_RE.match(path.name)
        ver_key = ver_match.group(0) if ver_match else ""
        if ver_key in PRE_CUTOVER_EXEMPT_VERSIONS:
            continue

        text = path.read_text(encoding="utf-8")
        rel = _rel(path)

        # Check 9b: scaffold residue. A note still carrying a producer token was
        # written by phase_scaffold_release_notes and never authored, so it is
        # unauthored by construction — no downstream content check is meaningful
        # on it. `continue` is deliberate: without it one unfilled note emits five
        # findings and buries the only actionable one.
        m_res = SCAFFOLD_RESIDUE_RE.search(text)
        if m_res:
            line_no = text[: m_res.start()].count("\n") + 1
            findings.append(
                f"NOTE-SCAFFOLD-RESIDUE: {rel}:{line_no} carries unfilled scaffold token "
                f"{m_res.group(0)!r} — the note is unauthored by construction "
                f"(release-notes-standard.md §3.2; automated-closeout.sh phase_scaffold_release_notes)"
            )
            continue

        # Check 13: whole-published-body link purity (release-notes-standard.md
        # §3.2 check 13). Independent forward-only floor at NOTE_LINK_CUTOVER —
        # runs on the frontmatter-stripped body (the Surface-1 published bytes),
        # not just Section 6a. Gated separately from checks 9-12 because its
        # floor (v2.37) is higher than NOTE_CONTENT_CUTOVER (v1.x): a note above
        # the content floor but below the link floor still gets checks 9-12 but
        # is exempt from check 13. NOTE_LINK_EXEMPT_VERSIONS additionally exempts
        # the older v3.x lineage notes whose tuple sorts above the floor but
        # which predate v2.37 and carry the legacy 6b template link.
        #
        # Version-less notes are DELIBERATELY exempt from check 13 and the
        # exemption is load-bearing, not incidental: VERSIONLESS_KEY sorts below
        # NOTE_LINK_CUTOVER, so the comparison below already excludes them, and
        # that is the intended scope. They are the same class of historical
        # artifact NOTE_LINK_EXEMPT_VERSIONS grandfathers — their Section-6b links
        # are the legacy `../../RELEASE_LOG.md#…` template form the forward-only
        # link floor exists to protect. Do NOT add an `is_versionless or …` limb
        # here: that would retroactively fail exactly the population the floor
        # grandfathers. The version-less branch above admits them to checks 9-12
        # ONLY. (release-notes-standard.md §3.2.)
        if ver >= NOTE_LINK_CUTOVER and ver_key not in NOTE_LINK_EXEMPT_VERSIONS:
            findings.extend(check_body_link_purity(rel, extract_body(text)))

        section_6a = extract_section_6a(text)

        if section_6a is None:
            findings.append(f"NOTE-6A-MISSING: {rel} lacks '## What changed for everyone' section (release-notes-standard.md §3.2 check 9)")
            continue

        # CHECK 9 ONLY is evaluated on the COMMENT-STRIPPED span. The scaffold's own
        # authoring comment quotes the escape-hatch string ("No user-visible behavior
        # changes"), so evaluating the raw span lets an untouched scaffold satisfy the
        # very check meant to reject it.
        #
        # The stripping is deliberately NOT shared with checks 11-12. Check 11's escape
        # marker `<!-- impact:foundational -->` IS an HTML comment: stripping comments
        # out of the bullet list deletes the marker and makes check 11 fire on 10
        # already-conformant notes that legitimately use it. `bullets` therefore keeps
        # reading the authored span; only the check-9 emptiness predicate reads the
        # stripped one.
        section_6a_eval = HTML_COMMENT_RE.sub("", section_6a)
        bullets = parse_bullets(section_6a)
        bullets_eval = parse_bullets(section_6a_eval)
        placeholder_present = "No user-visible behavior changes" in section_6a_eval
        if not bullets_eval and not placeholder_present:
            findings.append(f"NOTE-6A-EMPTY: {rel} Section 6a has no bullets and no 'No user-visible behavior changes' placeholder (release-notes-standard.md §3.2 check 9)")

        # Check 10: banned-jargon scan
        lower_section = section_6a.lower()
        for term in BANNED_JARGON_LITERAL:
            if term.lower() in lower_section:
                findings.append(f"NOTE-BANNED-JARGON: {rel} Section 6a contains banned term '{term}' (release-notes-standard.md §3.2 check 10; see §2.4 for plain-language replacement)")
        for pattern, label in BANNED_JARGON_REGEX:
            if pattern.search(section_6a):
                findings.append(f"NOTE-BANNED-JARGON: {rel} Section 6a matches banned pattern '{label}' (release-notes-standard.md §3.2 check 10; see §2.4 for plain-language replacement)")

        # Check 11: 'Why it matters' beat per bullet
        for bullet in bullets:
            has_marker = "<!-- impact:foundational -->" in bullet
            has_beat = "Why it matters" in bullet
            if not (has_beat or has_marker):
                snippet = bullet[:80].strip().replace("\n", " ")
                findings.append(f"NOTE-NO-WHY-IT-MATTERS: {rel} Section 6a bullet lacks 'Why it matters' beat or <!-- impact:foundational --> marker (release-notes-standard.md §3.2 check 11): {snippet!r}")

        # Check 12: no raw file paths in bullet bodies (inline markdown links allowed)
        for bullet in bullets:
            stripped = link_strip_re.sub("", bullet)
            m_path = path_re.search(stripped)
            if m_path:
                snippet = bullet[:80].strip().replace("\n", " ")
                findings.append(f"NOTE-FILE-PATH-IN-6A: {rel} Section 6a bullet contains raw file path '{m_path.group(0)}' (release-notes-standard.md §3.2 check 12; use inline anchor text via markdown link instead): {snippet!r}")

    return findings


def _find_note_for_version(version: str) -> Path | None:
    """Resolve the note whose version KEY equals `version` (folder-agnostic).

    Mirrors check_note_content()'s discovery idiom: rglob so the foldered
    notes/v1|v2|v3/… layout is reached, keyed on the _RELEASE_NOTES.md type
    discriminator so both discovery sites agree, and matched off path.name via
    VERSION_KEY_RE so the folder never participates in the match.

    NOTE — the glob widening here is a deliberate NO-OP, kept for single-idiom
    consistency with check_note_content() (and so no version-keyed discovery
    pattern survives in this file). It cannot change a resolution: the guard below
    filters version-less names out regardless of the pattern, and a version-less
    note can never be the answer to "find the note for version X". Do not go
    looking for a behaviour delta from this line — there is none by construction.
    """
    want = version if version.startswith("v") else f"v{version}"
    for path in sorted(NOTES_DIR.rglob("*_RELEASE_NOTES.md")):
        m = VERSION_KEY_RE.match(path.name)
        if m and m.group(0) == want:
            return path
    return None


def _section_6a_span(body: str) -> tuple[int, int] | None:
    """1-based inclusive line span of Section 6a's CONTENT within `body`.

    Uses the same header regexes as extract_section_6a(); returns None when the
    section is absent or empty.
    """
    lines = body.splitlines()
    start = None
    for i, line in enumerate(lines):
        if SECTION_6A_HEADER_RE.match(line):
            start = i + 1
            break
    if start is None:
        return None
    end = len(lines)
    for i in range(start, len(lines)):
        if NEXT_H2_RE.match(lines[i]):
            end = i
            break
    if end <= start:
        return None
    return (start + 1, end)


def check_sample_block(version: str) -> list[str]:
    """Check 14 (ADVISORY): schema/format sample block for a DECLARED release.

    Runs ONLY when the Stage-13 closer passes --sample-block-advisory, because
    "is this release schema/format-changing?" is not answerable from the note —
    it is answerable from the release plan's File Change Matrix. Every finding
    carries ADVISORY_PREFIX, so main() keeps it out of the exit decision.

    Emits the version key + bare filename ONLY (never the repo-root-relative
    note path) per invariant (2) on ADVISORY_PREFIX — a path in an advisory
    would false-block a close through the callers' version-scoping grep.
    """
    if not NOTES_DIR.exists():
        # check_note_content() already emits CORPUS-PATH-UNRESOLVED for this
        # condition (and the flag is only honoured alongside it), so re-emitting
        # here would duplicate the line without adding signal. Exit 3 still wins.
        return []

    path = _find_note_for_version(version)
    if path is None:
        return [
            f"{ADVISORY_PREFIX}: NOTE-SAMPLE-BLOCK-UNRESOLVED — no release note resolves for "
            f"declared version key '{version}'; check 14 could not evaluate "
            f"(release-notes-standard.md §3.2 check 14)"
        ]

    text = path.read_text(encoding="utf-8")
    name = path.name  # bare filename ONLY — see ADVISORY_PREFIX invariant (2)

    if SAMPLE_BLOCK_NA_RE.search(text):
        return []

    body = extract_body(text)
    fence_lines = [n for n, line in enumerate(body.splitlines(), start=1) if FENCE_RE.match(line)]

    if not fence_lines:
        return [
            f"{ADVISORY_PREFIX}: NOTE-SAMPLE-BLOCK-MISSING — {version} ({name}) is declared "
            f"schema/format-changing but its note body carries no fenced sample block and no "
            f"'<!-- sample-block: n/a - <reason> -->' marker "
            f"(release-notes-standard.md §2.8 / §3.2 check 14)"
        ]

    span = _section_6a_span(body)
    if span is not None and all(span[0] <= n <= span[1] for n in fence_lines):
        return [
            f"{ADVISORY_PREFIX}: NOTE-SAMPLE-BLOCK-MISPLACED — {version} ({name}) carries its only "
            f"fenced block(s) inside the Section 6a span; §2.8 requires the sample block outside "
            f"Section 6a (Section 6b, or its own section after 6a) because a fence terminates the "
            f"bullet check 11 scans (release-notes-standard.md §2.8 / §3.2 check 14)"
        ]

    return []


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--check", choices=["all", "filename", "schema", "index", "type-coherence", "note-content"], default="all", help="Which check(s) to run")
    p.add_argument(
        "--sample-block-advisory",
        metavar="VERSION",
        default=None,
        help=(
            "Declare the release schema/format-changing and run check 14 (ADVISORY) against its "
            "note. Supplied by the Stage-13 closer from the release plan's File Change Matrix. "
            "Findings are printed but never affect the exit status; omitted by every existing "
            "call site, so default behaviour is unchanged."
        ),
    )
    p.add_argument(
        "--print-scaffold-tokens",
        action="store_true",
        help=(
            "Print the scaffold-residue token set (one per line) and exit 0. This is the "
            "single-source seam the automated-closeout.sh shell anchors read instead of "
            "retyping the literals, so the python and shell detectors cannot drift apart. "
            "Runs no checks and touches no corpus path."
        ),
    )
    args = p.parse_args()

    # Token-set query short-circuits before any corpus read: it must succeed even
    # where the corpus does not resolve (the shell anchors call it from sandboxes).
    if args.print_scaffold_tokens:
        for token in SCAFFOLD_RESIDUE_TOKENS:
            print(token)
        return 0

    findings: list[str] = []
    if args.check in ("all", "filename"):
        findings.extend(check_filename_compliance())
    if args.check in ("all", "schema"):
        findings.extend(check_schema_validity())
    # Sub-check (c) RETIRED — see the reserved-identifier block above. The choice
    # value is retained so existing invocations keep working; it runs nothing.
    if args.check == "index":
        print("NOTE: sub-check (c) (INDEX row count) is RETIRED — it was strictly weaker than "
              "the LOG↔INDEX coexistence limb of `generate_release_index.py --verify` "
              "(deploy.sh Check 23). Run that instead. No checks were executed.")
    if args.check in ("all", "type-coherence"):
        findings.extend(check_type_coherence())
    if args.check in ("all", "note-content"):
        findings.extend(check_note_content())
    # Check 14 is flag-gated: absent --sample-block-advisory this branch never
    # runs, so every existing call site is byte-identically unaffected.
    if args.sample_block_advisory and args.check in ("all", "note-content"):
        findings.extend(check_sample_block(args.sample_block_advisory))

    for f in findings:
        print(f)

    # Exit-code contract (per #459 fail-loud): a path-resolution failure
    # (CORPUS-PATH-UNRESOLVED — a required corpus dir/file did not resolve) is
    # NOT a content finding. It exits 3 (path-config error) so deploy.sh can
    # distinguish "could not run against the corpus" from real §3.2 findings
    # (exit 1) and clean (exit 0). A path-resolution failure dominates: if any
    # is present, exit 3 regardless of other findings.
    if any(f.startswith(CORPUS_PATH_UNRESOLVED_PREFIX) for f in findings):
        return 3
    # ADVISORY findings (check 14) are excluded from the exit decision — they
    # are reported, never blocking. Absent the flag no advisory can exist, so
    # this predicate is identical to the prior `1 if findings else 0` on every
    # existing call site.
    blocking = [f for f in findings if not f.startswith(ADVISORY_PREFIX)]
    return 1 if blocking else 0


if __name__ == "__main__":
    sys.exit(main())
