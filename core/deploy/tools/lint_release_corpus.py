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
  (f) Tier-1 `links.plan` resolution (release-corpus-schema.md § Tier 1): every
      note's links.plan value must name an existing file under
      release/releases/plans/. Two-limbed on its own floor,
      PLAN_LINK_CUTOVER — blocking at/above it, tallied below it as inherited
      pre-ADR-092 corpus debt. Carried INSIDE check_note_content() rather than
      behind its own --check value because --check note-content is the only
      value any executable caller passes; a check reachable solely under
      ("all", …) would run in its own acceptance test and nowhere else.
      Emits one ADVISORY tally line per run carrying BOTH limbs' denominators,
      so a zero finding count is distinguishable from an unrun check.
  (g) Plan-file identity + placement (ADR-092). Two limbs over one ledger read,
      in opposite directions, shipped together because their reaches are
      complements:
        - IDENTITY (file -> ledger): for every plan whose FILENAME declares a
          version, the version it declares must be the one the ledger says that
          release shipped as. Resolved by a ledger-row identity join (filename
          slug / frontmatter issues / links.log_anchor / frontmatter milestone),
          each oracle accepted only on a unique match. NO era floor — a plan
          named for a version it did not ship as was never correct.
        - PLACEMENT (ledger -> file): every concrete-version ledger row must
          have a plan at plans/v<MAJOR>/<VERSION>_RELEASE_PLAN.md. Floored at
          PLAN_IDENTITY_CUTOVER, because ADR-092 is what made that the home.
          NOT filtered by State — State is transient, and a VERIFIED-only
          antecedent is blind over the window a misplaced plan is created in.
      The RELEASE_LOG is the comparison source; no version->plan mapping is
      restated anywhere in this module. Emits a DENOM line every run carrying
      the glob expression and every denominator, and itemises the UNVERIFIABLE
      set at/above the floor rather than reducing it to a count.

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
    python3 core/deploy/tools/lint_release_corpus.py --check plan-identity
    python3 core/deploy/tools/lint_release_corpus.py --self-test

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

# Plan-status lifecycle (release-corpus-schema.md § Plan-status lifecycle).
#
# THE SCHEMA IS THE HOME; these names are the executable projection of the enum
# stated there, not a second declaration of it. UPPERCASE by the corpus's own
# frequency dominance, matching the ledger's own State vocabulary.
#
# The enum is CLOSED at three members and jointly exhaustive over how a plan
# stops being a live working reference: it closed, or it was abandoned. A value
# outside the set is an enum violation, never an extension.
#
# DELIBERATELY SEPARATE FROM TYPE_VALUES ABOVE. Widening that set is a distinct
# piece of work (the `type: release-plan` dialect the plan corpus actually
# carries) and is out of scope here; these constants are additive and are read
# by one limb.
PLAN_STATUS_VALUES = ("ACTIVE", "CLOSED", "ABANDONED")
PLAN_STATUS_TERMINAL = "CLOSED"

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

# ─── Tier-1 links.plan resolution floor (release-corpus-schema.md § Tier 1) ───
#
# ADR-092 made plans/v<MAJOR>/ the claim-time home for a versioned plan. BEFORE
# it a flat links.plan pointer was CORRECT when written, so a pre-cutover dangle
# is inherited corpus debt stranded by the later foldering reorg — not a breach
# of the contract this limb enforces. Blocking at or above the floor; counted and
# named below it, never silently zeroed.
#
# Mirrors the NOTE_CONTENT_CUTOVER / NOTE_LINK_CUTOVER tuple shape, and inherits
# their sentinel behaviour: version_tuple() returns VERSIONLESS_KEY for a
# slug-keyed (version-less) note, which sorts below this floor, so version-less
# notes route to the advisory count with no special-casing.
PLAN_LINK_CUTOVER = (4, 0, "", 0)

# ─── Plan-identity floor + machinery (sub-check (g); ADR-092) ────────────────
#
# SAME TUPLE VALUE AND SAME ADR-092 RATIONALE as PLAN_LINK_CUTOVER above — the
# two are siblings, not a coincidence, and the comment says so because a reader
# who finds two identical tuples ten lines apart will otherwise assume one is a
# copy-paste. ADR-092 is what made plans/v<MAJOR>/ the claim-time home; before
# it a flat plan was CORRECT when written.
#
# IT FLOORS ONLY THE PLACEMENT LIMB (and the UNVERIFIABLE itemisation). The
# identity limbs carry NO floor: a plan named for a version it did not ship as
# was never correct in any era, so flooring them would suppress both live
# defects and reduce the check to a fixture-only assertion.
PLAN_IDENTITY_CUTOVER = (4, 0, "", 0)

# The re-version ledger. Read ONLY to EXPLAIN an advisory residual — it never
# downgrades a verdict, and a missing file is not an error (see the reader).
REVERSIONS_PATH = WORKSPACE_ROOT / "release" / "releases" / "RELEASE_REVERSIONS.md"

# The identity limbs' ANTECEDENT: the filename's stem IS a version (optionally
# carrying a `-<slug>` tail). Full-match, deliberately — "the filename declares a
# version" is the antecedent, never "the file sits at a versioned home", and the
# full match is what makes the three non-declaring layout forms (nested
# slug-named, _unversioned/, flat slug-primary pre-claim) pass BY CONSTRUCTION
# rather than by three special cases. A home-based antecedent would flag every
# in-flight plan the moment it was authored, including this release's own.
PLAN_STEM_VERSION_RE = re.compile(
    r"^(v[0-9]+\.[0-9]+(?:\.[0-9]+)?[a-z]?(?:-[0-9]+)?)(?:-([0-9a-z][-0-9a-z]*))?$"
)

# A RELEASE_LOG Version cell. The `(version-less)` exclusion is realised by the
# SHAPE OF THIS CELL and by nothing else — never by a filename denylist. That is
# the structural exclusion #4707's P-AC4 hand-off requires: a denylist would have
# to be maintained per-release and would silently stop excluding the moment a new
# version-less release landed.
LEDGER_VCELL_RE = re.compile(r"^`?(v[0-9]+\.[0-9]+(?:\.[0-9]+)?[a-z]?(?:-[0-9]+)?)`?$")

# The two live mis-named plans, shipped as a PRINTED advisory residual per the
# operator's rendered E-1 disposition. Repair is routed to its follow-on card;
# suppressing them into a constant was explicitly REJECTED, because a suppressed
# finding cannot serve as the control AC4 asks for.
#
# KEYED BY THE FULL TRIPLE (path, declared, ledger), never by path alone, and the
# key shape is the whole point:
#   • a correct repair drops the advisory to 0 (the control moves);
#   • a RE-mis-naming changes the triple and becomes BLOCKING;
#   • a brand-new mis-named plan is blocking on day one.
KNOWN_IDENTITY_RESIDUALS: set[tuple[str, str, str]] = {
    ("release/releases/plans/v2/v2.42_RELEASE_PLAN.md", "v2.42", "v3.21"),
    (
        "release/releases/plans/v2/v2.39-per-project-processing-orchestration_RELEASE_PLAN.md",
        "v2.39",
        "v2.40",
    ),
}

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
#       exit 0. EVERY caller that captures this lint captures it with `2>&1` and
#       INSPECTS the buffer only when the exit code is non-zero, so a stderr
#       advisory on a clean run would be silently swallowed. An invisible
#       advisory is not a check.
#
#       THE QUANTIFIER IS UNIVERSAL ON PURPOSE, where it used to be a count.
#       "All four callers" was true when it was written and was falsified by the
#       very commit that added the ADR-092 plan-identity gate: that commit
#       brought two more callers — automated-closeout.sh phase 9.3, and the
#       hub-spoke-bridge.md Procedure 7 Step 4 command that mirrors it on the
#       script-less close path — and left the number behind. A count here is a
#       defect with a delay fuse: it goes stale the next time a caller is added
#       and nothing announces it. What binds is the PROPERTY, which every caller
#       owes however many there are. To enumerate the set rather than trust a
#       figure, re-derive it — the pathspec excludes THIS file, which carries the
#       two needles only as the documentation you are reading:
#         git grep -n -e '--check note-content 2>&1' -e '--check plan-identity 2>&1' \
#           -- ':!core/deploy/tools/lint_release_corpus.py'
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


def _plan_link_state(text: str) -> tuple[str, str]:
    """Classify a note's frontmatter `links.plan`, distinguishing FOUR outcomes.

    The four are kept apart deliberately, because collapsing any of them into
    "skip" is how a resolution check reads green over notes it never examined:

      "unreadable" — parse_frontmatter() returned None, so this file's links
                     block was never read. NOT the same as "has no pointer":
                     the corpus carries notes that open with the
                     `<!-- reference-durability: allow-link -->` marker before
                     the `---` fence, and parse_frontmatter() keys on line 1
                     being the fence. Those notes DO carry a links.plan value
                     the parser cannot reach.
      "absent"     — read fine; no links object, or no plan key inside it. That
                     is a required-field finding, owned by the Tier-1 schema
                     scan, not by this resolution limb — reported in the tally
                     so it is visible, not re-flagged here.
      "null"       — the key is present and explicitly null/empty. The schema
                     permits null, so there is nothing to resolve.
      "value"      — a non-empty scalar, returned as the second element.
    """
    fm = parse_frontmatter(text)
    if fm is None:
        return ("unreadable", "")
    links = fm.get("links")
    if not isinstance(links, dict) or "plan" not in links:
        return ("absent", "")
    raw = (links.get("plan") or "").strip().strip('"').strip("'")
    if raw in ("", "null", "~"):
        return ("null", "")
    return ("value", raw)


def _plan_link_resolves(value: str) -> bool:
    """True iff `value` names an existing file under release/releases/plans/.

    The value is repo-root-relative by contract (release-corpus-schema.md
    § Tier 1). Containment is asserted rather than assumed: an absolute value,
    or one whose normalised form lands outside PLANS_DIR, does not resolve — so
    a `../`-bearing pointer becomes a finding instead of a silent traversal out
    of the corpus.
    """
    if not value or value.startswith("/"):
        return False
    target = (WORKSPACE_ROOT / value).resolve()
    try:
        target.relative_to(PLANS_DIR.resolve())
    except ValueError:
        return False
    return target.is_file()


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

    # Tier-1 links.plan resolution tallies. Accumulated across the whole loop and
    # emitted as ONE advisory line after it, so the limb states the denominator it
    # actually examined rather than a bare finding count — "0 found" and "nothing
    # examined" must not read the same.
    pl_block_seen = pl_block_bad = 0
    pl_adv_seen = pl_adv_bad = 0
    pl_unreadable = pl_absent = pl_null = 0

    # rglob (recursive) — notes are FLAT except for the notes/_unversioned/
    # bucket, per release-notes-standard.md § File Location (#3698). The
    # major-version foldering this comment used to describe (notes/v1|v2|v3/,
    # authored by #230, v3.54) was migrated flat; the recursion is RETAINED
    # because _unversioned/ still needs it. version_tuple keys off path.name
    # (folder-agnostic), so the cutover floor and exempt-set logic are unchanged;
    # only discovery must recurse or the §3.2 content lint silently stops
    # scanning the version-less notes.
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
        # Extract version key (e.g., "v12.09" from "v12.09_RELEASE_NOTES.md") for exempt-set lookup
        ver_match = VERSION_KEY_RE.match(path.name)
        ver_key = ver_match.group(0) if ver_match else ""

        text = path.read_text(encoding="utf-8")
        rel = _rel(path)

        # ── Tier-1 links.plan resolution (release-corpus-schema.md § Tier 1) ──
        #
        # WHY IT LIVES HERE rather than behind its own --check value. No caller
        # anywhere passes --check all: deploy.sh (x2), automated-closeout.sh's
        # Phase 9.2 and the version-less regression test all pass
        # --check note-content, which reaches exactly this function. A check
        # dispatched only under ("all", …) would run solely inside its own
        # acceptance test — green, and enforcing nothing.
        #
        # WHY IT SITS ABOVE THE §3.2 FLOORS AND ABOVE THE RESIDUE `continue`.
        # This is a Tier-1 SCHEMA assertion, not a §3.2 content check: it carries
        # its own forward-only floor (PLAN_LINK_CUTOVER) and must not silently
        # inherit NOTE_CONTENT_CUTOVER, the exempt set, or the residue skip. The
        # residue `continue` below is correct for its own scope — no prose check
        # is meaningful on an unauthored note — but a links.plan value is not
        # prose. It is machine data the close-out scaffold itself just emitted,
        # which makes a fresh scaffold the single most important place to read it,
        # not a place to skip. Below the residue skip this limb would be blind to
        # exactly the artifact that mints the defect.
        #
        # WHY EVERY BLOCKING FINDING LEADS WITH `rel`. Phase 9.2 scopes the lint
        # to the closing release by grepping the output for that release's
        # repo-root-relative NOTE path (automated-closeout.sh
        # phase_lint_release_notes). A finding that named only the PLANS path
        # would miss that needle and take the caller's explicit
        # "no finding for this version" PASS branch — blocking in name, fail-open
        # in fact. The note path is the load-bearing token here, not decoration.
        pl_state, pl_value = _plan_link_state(text)
        pl_blocking = (not is_versionless) and ver >= PLAN_LINK_CUTOVER
        if pl_state == "unreadable":
            pl_unreadable += 1
            if pl_blocking:
                findings.append(
                    f"NOTE-PLAN-LINK-NO-FRONTMATTER: {rel} is at/above the ADR-092 links.plan "
                    f"floor but its frontmatter does not open with a '---' fence on line 1, so "
                    f"links.plan could not be read — the pointer is UNVERIFIED, not clean "
                    f"(release-corpus-schema.md § Tier 1 / § Failure modes 'NO FRONTMATTER')"
                )
        elif pl_state == "absent":
            pl_absent += 1
        elif pl_state == "null":
            pl_null += 1
        else:
            if pl_blocking:
                pl_block_seen += 1
            else:
                pl_adv_seen += 1
            if not _plan_link_resolves(pl_value):
                if pl_blocking:
                    pl_block_bad += 1
                    findings.append(
                        f"NOTE-PLAN-LINK-UNRESOLVED: {rel} links.plan -> '{pl_value}' does not "
                        f"resolve to an existing file under release/releases/plans/ "
                        f"(release-corpus-schema.md § Tier 1; the plan's home is defined by "
                        f"release/releases/plans/README.md § Disposition rule)"
                    )
                else:
                    pl_adv_bad += 1

        # §3.2 content checks 9-14 begin here. Their forward-only floors and the
        # exempt set are unchanged and apply to them ONLY.
        if not is_versionless and ver < NOTE_CONTENT_CUTOVER:
            continue
        if ver_key in PRE_CUTOVER_EXEMPT_VERSIONS:
            continue

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

    # ── Tier-1 links.plan tally — ONE advisory line, always emitted ───────────
    #
    # It carries BOTH limbs' denominators so a zero is interpretable: a blocking
    # limb reporting 0 findings over 0 examined notes is not a clean corpus, it is
    # an unrun check, and the two must be distinguishable from the output alone.
    #
    # It is the whole advisory output, by design and against the obvious
    # alternative of one advisory line per pre-cutover dangle. Two shipped callers
    # make the per-line form actively harmful rather than merely noisy:
    #   • deploy.sh Check 20 reports `wc -l` of the lint output as its finding
    #     count and shows `head -10`. Roughly a hundred advisory lines would
    #     inflate that count several-fold and push every real §3.2 finding out of
    #     the displayed window.
    #   • test_lint_release_corpus_versionless.sh's specificity arm asserts its
    #     must-not-flag fixture's BARE FILENAME appears zero times in stdout. A
    #     per-note advisory naming the bare filename — the shape ADVISORY_PREFIX
    #     invariant (2) prescribes — would land in that grep and fail the arm.
    # The count is what the advisory limb owes; the enumeration belongs to the
    # follow-on card that repairs the inherited debt.
    #
    # NO REPO-ROOT-RELATIVE NOTE PATH APPEARS ON THIS LINE, per ADVISORY_PREFIX
    # invariant (2): the close-out callers grep the output for the closing note's
    # path whenever the exit code is non-zero, so an advisory carrying one would
    # false-block a close on unrelated legacy debt.
    findings.append(
        f"{ADVISORY_PREFIX}: NOTE-PLAN-LINK-TALLY — links.plan resolution: "
        f"blocking limb {pl_block_bad} unresolved of {pl_block_seen} pointer(s) examined "
        f"at/above the ADR-092 floor; advisory limb {pl_adv_bad} unresolved of {pl_adv_seen} "
        f"examined below it (inherited pre-ADR-092 corpus debt, tracked separately); "
        f"{pl_unreadable} note(s) with unreadable frontmatter, {pl_null} explicit null, "
        f"{pl_absent} carrying no links.plan key (release-corpus-schema.md § Tier 1)"
    )

    return findings


def _find_note_for_version(version: str) -> Path | None:
    """Resolve the note whose version KEY equals `version` (folder-agnostic).

    Mirrors check_note_content()'s discovery idiom: rglob so the
    notes/_unversioned/ bucket is reached, keyed on the _RELEASE_NOTES.md type
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


# ─── Sub-check (g) — plan-file identity + placement (ADR-092) ────────────────


def _norm_slug(value: str) -> str:
    """Normalise a milestone slug for the ledger join.

    The quote-stripping is NOT cosmetic. A `links.log_anchor` value ships quoted
    (`"#v1-01-intake"`); omitting the quote from the strip set silently zeroes
    that oracle while its three siblings keep firing, which reads as "this oracle
    has no coverage" rather than "this probe is broken".
    """
    s = (value or "").strip().strip("`").strip('"').strip("'").strip()
    s = re.sub(r"\s*\([^)]*\)\s*$", "", s)   # drop a trailing parenthetical
    s = re.sub(r"^[0-9]+-", "", s)           # drop a leading NN- milestone number
    return s.strip().lower()


def _issue_set(value) -> frozenset:
    """The issue-number set of a ledger `Issues` cell or a frontmatter `issues:`."""
    if not isinstance(value, str):
        return frozenset()
    return frozenset(re.findall(r"[0-9]+", value))


def parse_release_log(log_path: Path = LOG_PATH) -> tuple[list[dict], list[str]]:
    """Parse the RELEASE_LOG pipe table into rows. Returns (rows, findings).

    THE LEDGER IS THE COMPARISON SOURCE (the card's AC3), and this is where that
    is discharged: the only mapping from a plan to a version is the one parsed
    here. No version->plan table exists anywhere in this module, because a
    restated mapping is a second source that drifts — and, measured, a
    filename-vs-frontmatter restatement scores 0 of the 2 live defects, since
    both mis-named plans carry frontmatter agreeing with their own stale name.

    COLUMN POSITIONS ARE RESOLVED FROM THE HEADER LINE, never counted from
    memory. `State` is column 6 and `Date` is column 7; reading index 7 as State
    yields a plausible-looking distribution of calendar dates rather than an
    error, so the mistake survives a casual glance. The shipped
    `_c32_compute_verdict` awk in deploy.sh reads the same header and is the
    reference.

    ARCHIVES ARE DELIBERATELY NOT READ. The four RELEASE_LOG_ARCHIVE-*.md
    segments carry narrative H4 blocks, not table rows; parsing a narrative
    surface as a table is how a denominator silently doubles.

    ANTI-VACUITY: a parse yielding ZERO rows returns a CORPUS-PATH-UNRESOLVED
    finding, which main() maps to exit 3. It is never a clean zero. A check whose
    denominator can silently reach zero is the same failure class as a glob that
    matches no files.
    """
    if not log_path.is_file():
        return [], [
            f"{CORPUS_PATH_UNRESOLVED_PREFIX}: release ledger does not resolve at "
            f"{_rel(log_path)} — plan-identity is unverifiable, not clean"
        ]

    lines = log_path.read_text(encoding="utf-8").splitlines()
    header_idx = None
    cols: list[str] = []
    for i, line in enumerate(lines):
        if line.startswith("| Version |"):
            header_idx = i
            cols = [c.strip() for c in line.strip().strip("|").split("|")]
            break
    if header_idx is None:
        return [], [
            f"{CORPUS_PATH_UNRESOLVED_PREFIX}: {_rel(log_path)} carries no '| Version |' table "
            f"header — the ledger table shape changed; plan-identity is unverifiable, not clean"
        ]

    idx = {name: n for n, name in enumerate(cols)}
    need = {"Version", "Milestone", "Issues", "State"}
    missing = need - set(idx)
    if missing:
        return [], [
            f"{CORPUS_PATH_UNRESOLVED_PREFIX}: {_rel(log_path)} ledger header lacks column(s) "
            f"{sorted(missing)} — plan-identity is unverifiable, not clean"
        ]

    rows: list[dict] = []
    for i, line in enumerate(lines):
        if i <= header_idx or not line.startswith("| "):
            continue
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if len(cells) < len(cols):
            continue
        if set(cells[0]) <= set("-: "):        # the |---| separator row
            continue
        vcell = cells[idx["Version"]]
        m = LEDGER_VCELL_RE.match(vcell)
        rows.append({
            "line": i + 1,
            "version": m.group(1) if m else None,
            # Version-less classified by CELL SHAPE — the structural exclusion
            # P-AC4 requires. Never a filename denylist.
            "versionless": m is None and "(version-less)" in vcell,
            "milestone": _norm_slug(cells[idx["Milestone"]]),
            "issues": _issue_set(cells[idx["Issues"]]),
            # State is CARRIED but never filtered on — see check_plan_identity().
            "state": cells[idx["State"]],
        })

    if not rows:
        return [], [
            f"{CORPUS_PATH_UNRESOLVED_PREFIX}: {_rel(log_path)} parsed 0 ledger rows — the ledger "
            f"is unreadable or its table shape changed; plan-identity is unverifiable, not clean"
        ]
    return rows, []


def _fm_for_identity(text: str) -> dict:
    """Comment-tolerant frontmatter read, used ONLY by resolve_plan_identity().

    parse_frontmatter() returns None whenever line 1 is not the `---` fence, and
    the corpus carries plans that open with `<!-- reference-durability: … -->`
    marker comments ABOVE the fence. Nothing governs that ordering, so whether a
    plan's join keys are readable is a coin flip on author habit — measured, it
    lands on both sides within a single release family, and the class is GROWING
    rather than legacy.

    A version-declaring plan whose join keys are unreadable does not fail loudly;
    it falls to the UNVERIFIABLE bucket. The escape shape is exactly the defect
    class this check exists to catch — a plan naming a version that DOES exist in
    the ledger but belongs to another release.

    parse_frontmatter() itself is deliberately NOT modified: it is shared with
    check_schema_validity() / check_type_coherence(), and widening it would newly
    expose files to those semantics in a file whose ownership is an open
    decision. This reader is private, additive, and used by one caller.
    """
    lines = text.splitlines()
    i = 0
    while i < len(lines) and (not lines[i].strip() or lines[i].lstrip().startswith("<!--")):
        i += 1
    return parse_frontmatter("\n".join(lines[i:])) or {}


def resolve_plan_identity(text: str, stem_slug: str, rows: list[dict]) -> tuple[dict | None, bool]:
    """Resolve a plan to its ledger row. Returns (row, ambiguous).

    FOUR ORACLES, each accepted ONLY on a UNIQUE ledger match — it refuses rather
    than guesses. Two oracles resolving to DIFFERENT rows returns ambiguous=True
    (blocking) rather than silently picking one.

      J1  filename slug component after the version stem  -> Milestone
      J2  frontmatter `issues:`  (set equality)           -> Issues
      J3  frontmatter `links.log_anchor` (strip #vN-NN-)  -> Milestone
      J4  frontmatter `milestone:`                        -> Milestone

    J4 is the forward-going oracle: it survives the Stage-12 rename, which
    changes only the filename. Its availability across the current release family
    is a RATIO, not a property evidenced from the newest file — that single-
    exemplar reading is what the marker-comment ordering falsifies.
    """
    fm = _fm_for_identity(text)
    candidates: dict[str, dict] = {}

    def _unique(pred) -> dict | None:
        hits = [r for r in rows if pred(r)]
        return hits[0] if len(hits) == 1 else None

    j1 = _norm_slug(stem_slug)
    if j1:
        hit = _unique(lambda r: r["milestone"] == j1)
        if hit:
            candidates["J1"] = hit

    issues = _issue_set(fm.get("issues"))
    if issues:
        hit = _unique(lambda r: r["issues"] == issues)
        if hit:
            candidates["J2"] = hit

    links = fm.get("links")
    anchor = links.get("log_anchor", "") if isinstance(links, dict) else ""
    anchor = re.sub(r"^#?v[0-9]+-[0-9]+-", "", _norm_slug(anchor))
    if anchor:
        hit = _unique(lambda r: r["milestone"] == anchor)
        if hit:
            candidates["J4-anchor"] = hit

    milestone = fm.get("milestone")
    j4 = _norm_slug(milestone) if isinstance(milestone, str) else ""
    if j4:
        hit = _unique(lambda r: r["milestone"] == j4)
        if hit:
            candidates["J4"] = hit

    if not candidates:
        return None, False
    lines_hit = {c["line"] for c in candidates.values()}
    if len(lines_hit) > 1:
        return None, True
    return next(iter(candidates.values())), False


def _reversion_pairs(reversions_path: Path = REVERSIONS_PATH) -> set[tuple[str, str]]:
    """The (abandoned_version, final_version) pairs from the re-version ledger.

    Read STRUCTURALLY — two named columns — not by prose-matching the
    `residual_labels` cell. It is used to EXPLAIN an advisory line and never to
    downgrade a verdict: the ledger RECORDS that a filename was left as-authored,
    it does not AUTHORIZE it. An absent or unparseable file yields an empty set
    and no finding; the explanation is simply omitted.
    """
    pairs: set[tuple[str, str]] = set()
    if not reversions_path.is_file():
        return pairs
    lines = reversions_path.read_text(encoding="utf-8").splitlines()
    idx = None
    for line in lines:
        cells = [c.strip() for c in line.strip().strip("|").split("|")]
        if idx is None:
            if line.startswith("| slug |") and "abandoned_version" in cells:
                idx = (cells.index("abandoned_version"), cells.index("final_version"))
            continue
        if not line.startswith("| ") or len(cells) <= max(idx):
            continue
        if set(cells[0]) <= set("-: "):
            continue
        pairs.add((cells[idx[0]], cells[idx[1]]))
    return pairs


def check_plan_identity(
    plans_dir: Path = PLANS_DIR,
    log_path: Path = LOG_PATH,
    reversions_path: Path = REVERSIONS_PATH,
) -> list[str]:
    """Assert a plan filename names the version it shipped as, and sits at its home.

    TWO LIMBS, ONE LEDGER, TWO DIRECTIONS — and they must ship together because
    their REACHES are complements, not overlaps:

      • IDENTITY (file -> ledger, truthfulness). Antecedent: the filename
        declares a version. FILE-KEYED, and deliberately so — it is a
        CONDITIONAL assertion over declaring files, and every non-declaring case
        is covered from the other side.
      • PLACEMENT (ledger -> file, existence). This is #4707 AC4, absorbed here
        per the operator's rendered mechanism decision. LEDGER-KEYED: the
        expected path is derived from the ledger ROW, never from the plan's own
        name, so a plan named ANYTHING AT ALL — wrong version, slug-only, still
        un-renamed because its Stage-12 stamp never fired — is caught by "the
        expected path is absent". Its reach is INDEPENDENT of the property under
        test, which is the anti-circularity property.

    THE PARAMETERS ARE DEFAULTED so every existing call site stays byte-identical
    while --self-test can hand it a temp corpus and never read the live tree.
    """
    if not plans_dir.exists():
        return [
            f"{CORPUS_PATH_UNRESOLVED_PREFIX}: plans dir does not resolve at {_rel(plans_dir)} "
            f"— plan-identity is unverifiable, not clean"
        ]

    rows, log_findings = parse_release_log(log_path)
    if log_findings:
        return log_findings

    concrete_versions = {r["version"] for r in rows if r["version"]}
    findings: list[str] = []
    advisories: list[str] = []
    reversions = _reversion_pairs(reversions_path)

    n_plans = n_declaring = n_joined = n_unverifiable = 0
    # E1/E2 denominators — reported unconditionally by the PLAN-STATUS-DENOM
    # advisory below, so a zero-finding run is distinguishable from a run that
    # walked no status-carrying plans at all.
    n_status = n_status_closed = n_status_joined = 0
    unverifiable_above_floor: list[str] = []
    declared_seen: dict[str, list[str]] = {}

    # ITS OWN LIVE ITERATION, keyed on the _RELEASE_PLAN.md type discriminator —
    # the same reasoning check_note_content() records for its own pattern, and
    # layout-independent by construction (no major-version segment and no
    # _unversioned segment appears in it). It must NOT be homed inside
    # check_schema_validity() or check_type_coherence(): both iterate a pattern
    # matching zero files, so a check placed there is dead on arrival and its
    # green run vacuous — the exact outcome this card's own AC forbids.
    for path in sorted(plans_dir.rglob("*_RELEASE_PLAN.md")):
        n_plans += 1
        rel = _rel(path)
        stem = path.name[: -len("_RELEASE_PLAN.md")]
        m = PLAN_STEM_VERSION_RE.match(stem)
        text = path.read_text(encoding="utf-8")

        # ── E1 / E2: plan-status lifecycle ───────────────────────────────────
        #
        # Placed BEFORE the version-declaring antecedent below, and that is
        # load-bearing rather than stylistic: the status-carrying cohort
        # includes SLUG-named plans (a version-less release's plan, and a
        # pre-claim plan not yet renamed), none of which declare a version. A
        # limb homed after the `if not m: continue` would silently exempt every
        # one of them — the same shrunken-denominator failure this file's own
        # DENOM lines exist to make visible.
        #
        # READ COMMENT-TOLERANTLY via _fm_for_identity(). parse_frontmatter()
        # returns None whenever line 1 is not the fence, and the plan corpus
        # carries files opening with `<!-- … -->` marker comments above it.
        # Measured on the live corpus, a strict reader sees 28 of the 33
        # status-carrying plans — a green result over a population five files
        # short. The schema states this reader requirement unconditionally.
        #
        # BOTH LIMBS ARE CONDITIONAL, which is what preserves the field's
        # OPTIONAL / forward-only tier: a plan carrying no `status:` reaches
        # neither, and a plan joining to no ledger row reaches only E1.
        fm_status = _fm_for_identity(text).get("status")
        if isinstance(fm_status, str) and fm_status.strip():
            fm_status = fm_status.strip()
            n_status += 1
            if fm_status not in PLAN_STATUS_VALUES:
                # E1 — enum membership. Fail loudly on an unrecognised value
                # rather than treating it as a silent non-terminal.
                findings.append(
                    f"PLAN-STATUS-ENUM: {rel} carries status: '{fm_status}' — the enum is "
                    f"{'|'.join(PLAN_STATUS_VALUES)} (release-corpus-schema.md "
                    f"§ Plan-status lifecycle)"
                )
            else:
                if fm_status == PLAN_STATUS_TERMINAL:
                    n_status_closed += 1
                # E2 — terminal coherence. THE ANTECEDENT IS THE LEDGER ROW, so
                # a plan that joins to nothing asserts nothing.
                #
                # THIS LIMB FILTERS ON `State`, and that does NOT contradict the
                # placement limb's "never filter on State" contract below. That
                # contract protects an EXISTENCE assertion whose reach would be
                # blinded by a transient State; this is a COHERENCE assertion
                # whose whole content is "the ledger says shipped, the plan says
                # live" — State is the antecedent, not a filter narrowing a
                # population. Reading it here cannot shrink any denominator: a
                # non-VERIFIED row simply leaves the assertion vacuous, and the
                # DENOM line below reports how often that happened.
                s_row, s_ambiguous = resolve_plan_identity(
                    text, (m.group(2) or "") if m else stem, rows
                )
                if s_row is not None and not s_ambiguous:
                    n_status_joined += 1
                    if s_row["state"] == "VERIFIED" and fm_status != PLAN_STATUS_TERMINAL:
                        findings.append(
                            f"PLAN-STATUS-NOT-TERMINAL: {rel} reads status: {fm_status} but "
                            f"{_rel(log_path)}:{s_row['line']} records State VERIFIED — a "
                            f"released plan carries status: {PLAN_STATUS_TERMINAL} "
                            f"(release-corpus-schema.md § Plan-status lifecycle)"
                        )

        if not m:
            # Antecedent vacuous — the filename declares no version. Nested
            # slug-named, _unversioned/ and flat pre-claim plans all land here
            # and pass BY CONSTRUCTION, with no per-form rule.
            continue
        n_declaring += 1
        declared, slug_tail = m.group(1), (m.group(2) or "")
        declared_seen.setdefault(declared, []).append(rel)

        ver = version_tuple(declared)
        row, ambiguous = resolve_plan_identity(text, slug_tail, rows)

        if ambiguous:
            findings.append(
                f"PLAN-IDENTITY-AMBIGUOUS: {rel} resolves to two different {_rel(log_path)} rows "
                f"— the join refuses rather than guessing (ADR-092)"
            )
            continue

        if row is None:
            n_unverifiable += 1
            # PLAN-VERSION-UNKNOWN is the O1 limb and fires HERE, where the join
            # could say nothing. On a JOINED file the MISMATCH below is strictly
            # more informative, so emitting both would double-report one defect.
            if declared not in concrete_versions:
                findings.append(
                    f"PLAN-VERSION-UNKNOWN: {rel} declares {declared}, which is not any concrete "
                    f"Version cell in {_rel(log_path)} — no release shipped as {declared} (ADR-092)"
                )
            elif ver >= PLAN_IDENTITY_CUTOVER:
                # ITEMISED above the floor, tallied below it. A bare count of the
                # unexamined is the same fail-open one level in: a member of this
                # bucket can BE the defect under test, and a count cannot say so.
                unverifiable_above_floor.append(rel)
        else:
            n_joined += 1
            if row["versionless"]:
                findings.append(
                    f"PLAN-VERSION-VERSIONLESS-ROW: {rel} declares {declared} but its identity "
                    f"resolves to a version-less {_rel(log_path)} row at line {row['line']} "
                    f"— a version-less release claims no version (ADR-092)"
                )
            elif row["version"] != declared:
                line = (
                    f"PLAN-VERSION-MISMATCH: {rel} declares {declared}; {_rel(log_path)}:"
                    f"{row['line']} records {row['version']} — the filename names a version the "
                    f"release did not ship as (ADR-092)"
                )
                triple = (rel, declared, row["version"])
                if triple in KNOWN_IDENTITY_RESIDUALS:
                    explain = ""
                    if (declared, row["version"]) in reversions:
                        explain = (
                            f" {_rel(reversions_path)} records the re-version "
                            f"({declared} -> {row['version']}); the ledger RECORDS the retained "
                            f"filename, it does not authorize it."
                        )
                    advisories.append(
                        f"{ADVISORY_PREFIX}: {line} [KNOWN RESIDUAL — repair routed to the "
                        f"follow-on card].{explain}"
                    )
                else:
                    findings.append(line)

        # Major-directory coherence. Only meaningful for a file that declares a
        # major to compare — a nested SLUG-named plan declares none and is
        # already outside the antecedent, so it can never reach here.
        parts = path.relative_to(plans_dir).parts
        if len(parts) > 1 and re.fullmatch(r"v[0-9]+", parts[0]):
            if parts[0] != f"v{version_tuple(declared)[0]}":
                findings.append(
                    f"PLAN-MAJOR-DIR-MISMATCH: {rel} declares {declared} but sits under "
                    f"{parts[0]}/ — the major-version folder disagrees with the filename (ADR-092)"
                )

    for declared, paths in sorted(declared_seen.items()):
        if len(paths) > 1:
            findings.append(
                f"PLAN-VERSION-DUPLICATE: {len(paths)} plan files declare {declared}: "
                f"{', '.join(sorted(paths))} — a version is claimed once (ADR-092)"
            )

    # ── Placement limb (#4707 AC4, absorbed) ─────────────────────────────────
    #
    # NOT FILTERED BY State, and the omission is load-bearing rather than an
    # oversight. State is TRANSIENT — the same ledger reads a different State
    # distribution at two instants hours apart — so a `VERIFIED`-only antecedent
    # is blind over exactly the window in which a misplaced plan is created.
    # State is parsed and carried; it is never used as a filter. Do not re-add it.
    place_blocking = place_advisory = 0
    for row in rows:
        if not row["version"]:
            continue
        major = f"v{version_tuple(row['version'])[0]}"
        expected_abs = plans_dir / major / f"{row['version']}_RELEASE_PLAN.md"
        if expected_abs.is_file():
            continue
        expected = _rel(expected_abs)
        text = (
            f"PLAN-MISSING-FOR-LEDGER-ROW: {row['version']} ({_rel(log_path)}:{row['line']}) "
            f"has no plan at {expected}"
        )
        if version_tuple(row["version"]) >= PLAN_IDENTITY_CUTOVER:
            place_blocking += 1
            findings.append(f"{text} (ADR-092 claim-time home)")
        else:
            place_advisory += 1

    if place_advisory:
        advisories.append(
            f"{ADVISORY_PREFIX}: PLAN-PLACEMENT-TALLY — {place_advisory} concrete ledger row(s) "
            f"below the ADR-092 floor have no plan at their nested home (inherited pre-ADR-092 "
            f"corpus debt, tracked separately); {place_blocking} at/above the floor"
        )
    if unverifiable_above_floor:
        advisories.append(
            f"{ADVISORY_PREFIX}: PLAN-IDENTITY-UNVERIFIABLE — {len(unverifiable_above_floor)} "
            f"version-declaring plan(s) at/above the ADR-092 floor resolve to no ledger row: "
            f"{', '.join(sorted(unverifiable_above_floor))}"
        )

    # ── The DENOM line, emitted EVERY run ────────────────────────────────────
    #
    # Not a finding — carried under ADVISORY_PREFIX so it never contributes to
    # the exit status, and printed unconditionally so a green run is
    # INTERPRETABLE. It states the glob expression and the denominators, because
    # a zero over a collapsed denominator is not a pass and the output is the
    # only place a reader can tell the two apart.
    # The E1/E2 counterpart of the DENOM line below, and it exists for the same
    # reason: the status-carrying cohort is a SUBSET of the walked population,
    # so "no status findings" is uninterpretable without knowing how many files
    # carried the field and how many of those reached the E2 antecedent. Carried
    # under ADVISORY_PREFIX, so it is filtered out of the blocking list by
    # construction and contributes nothing to any verdict — that inertness is
    # the point.
    advisories.append(
        f"{ADVISORY_PREFIX}: PLAN-STATUS-DENOM — {n_status} of {n_plans} plan file(s) carry a "
        f"frontmatter status: (read comment-tolerantly); {n_status_closed} read "
        f"{PLAN_STATUS_TERMINAL}, {n_status_joined} joined to a ledger row and so reached the "
        f"terminal-coherence antecedent; enum {'|'.join(PLAN_STATUS_VALUES)}"
    )
    advisories.append(
        f'{ADVISORY_PREFIX}: PLAN-IDENTITY-DENOM — {n_plans} plan file(s) walked via '
        f'plans_dir.rglob("*_RELEASE_PLAN.md") under {_rel(plans_dir)}; {n_declaring} declare a '
        f"version, {n_joined} identity-joined, {n_unverifiable} unverifiable; ledger "
        f"{len(rows)} row(s) ({len(concrete_versions)} concrete / "
        f"{sum(1 for r in rows if r['versionless'])} version-less) from {_rel(log_path)}"
    )

    return findings + advisories


# ─── --self-test for sub-check (g) ───────────────────────────────────────────
#
# HERMETIC BY CONSTRUCTION. Every arm hands check_plan_identity() a temp corpus
# through its defaulted parameters and never reads the live repository tree, so
# the suite cannot pass or fail because of what the corpus happens to contain
# today. That is the direct fix for the non-hermeticity class flagged as a latent
# flake in the sibling tooling.
#
# THE VERDICT-BEARING OBSERVABLE IS THE FINDING TEXT, never the exit code: each
# must-flag arm asserts its fixture's path appears verbatim in the findings, and
# each must-not-flag arm asserts it appears zero times. The exit code is a
# secondary consistency check. A suite graded on exit codes alone cannot tell
# "flagged the right file" from "flagged something".

_LEDGER_HEADER = (
    "| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |\n"
    "|---|---|---|---|---|---|---|---|\n"
)


def _fixture_ledger(rows: list[tuple[str, str, str]]) -> str:
    """Render a fixture ledger. Each row is (version-cell, milestone, state).

    THE `State` COLUMN IS POPULATED, and that is the point of its being here:
    with every fixture row left at one state, the placement limb returns
    identically whether or not it filters on `State == VERIFIED`, so the
    contract the operator pre-decided has no executable lock. One DEPLOYED row
    whose plan is absent converts an unfalsifiable criterion into a regression
    lock — it FAILS on a VERIFIED-filtered implementation and PASSES on a
    conformant one.
    """
    body = "".join(
        f"| {v} | {m} | #1 | #2 | abc1234 | v-tag | {s} | 2026-01-01 |\n" for v, m, s in rows
    )
    return "# Fixture ledger\n\n## Releases\n\n" + _LEDGER_HEADER + body


def _write_ledger(path: Path, rows: list[tuple[str, str, str]]) -> Path:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(_fixture_ledger(rows), encoding="utf-8")
    return path


def _write(root: Path, rel: str, milestone: str | None = None, lead: str = "") -> Path:
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    fm = "---\ntype: plan\n"
    if milestone is not None:
        fm += f"milestone: {milestone}\n"
    fm += "---\n"
    path.write_text(lead + fm + "\n# Fixture plan\n", encoding="utf-8")
    return path


def _write_status_plan(
    root: Path, rel: str, milestone: str, status: str | None, lead: str = ""
) -> Path:
    """Fixture plan carrying a frontmatter `status:` — the E1/E2 seed.

    SEPARATE from _write() because `status=None` must produce a plan with NO
    status key at all, which is the forward-only specificity arm, and because
    `lead` here is load-bearing in its own right: bytes above the `---` fence
    are what make a strict reader blind to the frontmatter. The live corpus
    carries that shape on 5 of its status-bearing plans, so an arm that never
    exercises it would pass a reader that silently under-enforces on them.

    The body carries a `| **Status** | … |` row deliberately. It is the
    registered non-authoritative narrative surface, and its presence here is
    the regression lock for "rewrite only the frontmatter line": a limb that
    read the body row instead would see a value the enum does not contain and
    misreport it.
    """
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    fm = f"---\ntype: plan\nmilestone: {milestone}\n"
    if status is not None:
        fm += f"status: {status}\n"
    fm += "---\n"
    body = (
        "\n# Fixture plan\n\n"
        "| Field | Value |\n|---|---|\n"
        "| **Status** | Executing (Stage 6 Engineering) |\n"
    )
    path.write_text(lead + fm + body, encoding="utf-8")
    return path


def _write_note(root: Path, rel: str, plan_link: str | None = None, lead: str = "") -> Path:
    """Fixture release note carrying a Tier-1 `links.plan` pointer.

    `lead` places bytes ABOVE the `---` fence, which is the whole reason this
    helper exists separately from _write(): parse_frontmatter() keys on line 1
    being the fence, so a leading marker comment makes the frontmatter
    UNREADABLE to the strict parser while the note still carries a real
    links.plan value. That is not a synthetic shape — it is the corpus shape
    that produced the A6.5 census undercount, and it is the only way to reach
    the NOTE-PLAN-LINK-NO-FRONTMATTER limb.

    The body is deliberately §3.2-conformant (a Section 6a bullet carrying the
    'Why it matters' beat, no links, no banned jargon, no raw repo path), so
    every finding a Scenario-H arm sees comes from the links.plan limb under
    test rather than from content checks the fixture happened to trip.
    """
    path = root / rel
    path.parent.mkdir(parents=True, exist_ok=True)
    fm = "---\ntype: release-notes\nlinks:\n"
    fm += f"  plan: {plan_link}\n" if plan_link is not None else "  plan: null\n"
    fm += "---\n"
    body = (
        "\n# Fixture note\n\n"
        "## What changed for everyone\n\n"
        "- A fixture thing changed. Why it matters: the arm needs a conformant body.\n"
    )
    path.write_text(lead + fm + body, encoding="utf-8")
    return path


def _self_test() -> int:
    import tempfile

    failures: list[str] = []
    checked = 0

    def arm(name: str, ok: bool, detail: str) -> None:
        nonlocal checked
        checked += 1
        status = "PASS" if ok else "FAIL"
        print(f"  [{status}] {name}: {detail}")
        if not ok:
            failures.append(name)

    def names(findings: list[str], needle: str) -> int:
        return sum(1 for f in findings if needle in f)

    def blocking(findings: list[str]) -> list[str]:
        return [f for f in findings if not f.startswith(ADVISORY_PREFIX)]

    def fires(findings: list[str], prefix: str, needle: str) -> int:
        """Count BLOCKING findings of `prefix` naming `needle`.

        Sensitivity arms grade through this rather than through names(), and the
        difference is the whole point: a build that emits every finding under
        ADVISORY_PREFIX still produces matching finding TEXT while blocking
        nothing. Grading on text alone passes such a build — measured, it did.
        Posture is part of the assertion, not a separate concern.
        """
        return sum(1 for f in blocking(findings) if f.startswith(prefix) and needle in f)

    print("lint_release_corpus.py --self-test — sub-check (g) plan-identity")

    with tempfile.TemporaryDirectory() as td:
        root = Path(td)

        # ── Scenario A — the main sensitivity/specificity corpus ─────────────
        a = root / "A"
        plans = a / "plans"
        log = _write_ledger(a / "RELEASE_LOG.md", [
            ("v9.01", "widget-one", "VERIFIED"),
            ("v9.02", "widget-two", "VERIFIED"),
            ("v9.04", "widget-four", "VERIFIED"),
            ("widget-three (version-less)", "widget-three", "VERIFIED"),
        ])
        f_s1 = _write(plans, "v9/v9.01_RELEASE_PLAN.md", "widget-two")
        f_s2 = _write(plans, "v9/v9.77_RELEASE_PLAN.md")
        f_s3 = _write(plans, "v9/v9.03_RELEASE_PLAN.md", "widget-three")
        f_s7 = _write(plans, "v9/v9.02_RELEASE_PLAN.md", "widget-two")
        f_s8 = _write(plans, "widget-five_RELEASE_PLAN.md")
        f_s9 = _write(plans, "_unversioned/widget-three_RELEASE_PLAN.md")
        f_s10 = _write(plans, "v9/widget-six_RELEASE_PLAN.md")
        fa = check_plan_identity(plans_dir=plans, log_path=log, reversions_path=root / "none.md")

        arm("S-1 sensitivity — filename names a version it did not ship as",
            fires(fa, "PLAN-VERSION-MISMATCH", str(f_s1)) == 1
            and "v9.02" in " ".join(f for f in fa if str(f_s1) in f),
            "BLOCKING PLAN-VERSION-MISMATCH names the fixture and cites ledger version v9.02")
        arm("S-2 sensitivity — declared version is in no ledger row",
            fires(fa, "PLAN-VERSION-UNKNOWN", str(f_s2)) == 1,
            "BLOCKING PLAN-VERSION-UNKNOWN names the fixture")
        arm("S-3 sensitivity — identity resolves to a version-less row",
            fires(fa, "PLAN-VERSION-VERSIONLESS-ROW", str(f_s3)) == 1,
            "BLOCKING PLAN-VERSION-VERSIONLESS-ROW names the fixture")
        arm("S-6 sensitivity — ledger row with no plan (the absorbed AC4 arm)",
            fires(fa, "PLAN-MISSING-FOR-LEDGER-ROW", "v9.04") == 1,
            "BLOCKING PLAN-MISSING-FOR-LEDGER-ROW names v9.04's expected home")
        arm("S-7 specificity — correctly-named plan",
            names(fa, str(f_s7)) == 0, "zero findings name the conformant fixture")
        arm("S-8 specificity — layout form 3 (flat slug-primary, pre-claim)",
            names(fa, str(f_s8)) == 0, "zero findings name it (antecedent vacuous)")
        arm("S-9 specificity — layout form 2 (_unversioned/)",
            names(fa, str(f_s9)) == 0, "zero findings name it (antecedent vacuous)")
        arm("S-10 specificity — layout form 1c (nested, slug-named)",
            names(fa, str(f_s10)) == 0
            and names([f for f in fa if "PLAN-MAJOR-DIR-MISMATCH" in f], str(f_s10)) == 0,
            "zero findings, and specifically no MAJOR-DIR — it declares no major")
        arm("S-1/S-7 pairing — the suite DISCRIMINATES",
            names(fa, str(f_s1)) > 0 and names(fa, str(f_s7)) == 0,
            "must-flag non-zero AND must-not-flag zero on one run")
        arm("DENOM line present and non-collapsed",
            any("PLAN-IDENTITY-DENOM" in f and "7 plan file(s) walked" in f for f in fa),
            "the denominator is stated, so a zero would be interpretable")

        # ── Scenario B — duplicate version claim ─────────────────────────────
        b = root / "B"
        bp = b / "plans"
        blog = _write_ledger(b / "RELEASE_LOG.md", [("v9.02", "widget-two", "VERIFIED")])
        _write(bp, "v9/v9.02_RELEASE_PLAN.md", "widget-two")
        _write(bp, "v9/v9.02-alt_RELEASE_PLAN.md")
        fb = check_plan_identity(plans_dir=bp, log_path=blog, reversions_path=root / "none.md")
        arm("S-4 sensitivity — two plans declare one version",
            fires(fb, "PLAN-VERSION-DUPLICATE", "v9.02") == 1,
            "BLOCKING PLAN-VERSION-DUPLICATE fires once naming both paths")

        # ── Scenario C — major-directory mismatch ────────────────────────────
        c = root / "C"
        cp = c / "plans"
        clog = _write_ledger(c / "RELEASE_LOG.md", [("v9.02", "widget-two", "VERIFIED")])
        f_s5 = _write(cp, "v8/v9.02_RELEASE_PLAN.md", "widget-two")
        fc = check_plan_identity(plans_dir=cp, log_path=clog, reversions_path=root / "none.md")
        arm("S-5 sensitivity — nested under the wrong major",
            fires(fc, "PLAN-MAJOR-DIR-MISMATCH", str(f_s5)) == 1,
            "BLOCKING PLAN-MAJOR-DIR-MISMATCH names the fixture")

        # ── Scenario D — anti-vacuity ────────────────────────────────────────
        d = root / "D"
        dp, dlog = d / "plans", d / "RELEASE_LOG.md"
        dp.mkdir(parents=True)
        dlog.write_text("# Fixture ledger\n\n" + _LEDGER_HEADER, encoding="utf-8")
        fd = check_plan_identity(plans_dir=dp, log_path=dlog, reversions_path=root / "none.md")
        arm("S-11 anti-vacuity — header present, zero data rows",
            len(fd) == 1 and fd[0].startswith(CORPUS_PATH_UNRESOLVED_PREFIX),
            "CORPUS-PATH-UNRESOLVED (main() maps it to exit 3), never a clean 0")
        # The ledger handed to S-11b is the VALID scenario-A one, deliberately.
        # Pointing it at scenario D's empty ledger would satisfy the arm from the
        # ledger guard one branch earlier, and the arm would pass on a build with
        # no plans-dir guard at all — a fixture green for the wrong reason.
        arm("S-11b anti-vacuity — plans dir absent (valid ledger, so only this guard can fire)",
            check_plan_identity(plans_dir=d / "nope", log_path=log)[0]
            .startswith(CORPUS_PATH_UNRESOLVED_PREFIX),
            "a missing plans dir is unverifiable, not clean")

        # ── Scenario E — parser tolerance (the regression lock) ──────────────
        e = root / "E"
        ep = e / "plans"
        elog = _write_ledger(e / "RELEASE_LOG.md", [("v9.01", "widget-one", "VERIFIED"),
                                                   ("v9.02", "widget-two", "VERIFIED")])
        lead = ("<!-- reference-durability: allow-link -->\n"
                "<!-- reference-durability: allow-version-ref -->\n"
                "<!-- repo-integrity: allow-issue-ref -->\n")
        f_s13 = _write(ep, "v9/v9.01_RELEASE_PLAN.md", "widget-two", lead=lead)
        _write(ep, "v9/v9.02_RELEASE_PLAN.md", "widget-two")
        raw = f_s13.read_text(encoding="utf-8")
        fe = check_plan_identity(plans_dir=ep, log_path=elog, reversions_path=root / "none.md")
        arm("S-13 parser tolerance — frontmatter behind leading marker comments",
            fires(fe, "PLAN-VERSION-MISMATCH", str(f_s13)) == 1,
            "BLOCKING MISMATCH still fires when the `---` fence is not line 1")
        arm("S-13b the arm is NOT vacuous — the strict parser really is blind here",
            parse_frontmatter(raw) is None and "milestone" in _fm_for_identity(raw),
            "parse_frontmatter -> None while _fm_for_identity recovers `milestone`")

        # ── Scenario F — the State column (the pre-decided contract's lock) ──
        f_ = root / "F"
        fp = f_ / "plans"
        fp.mkdir(parents=True)
        flog = _write_ledger(f_ / "RELEASE_LOG.md", [("v9.01", "widget-one", "VERIFIED"),
                                                     ("v9.05", "widget-five", "DEPLOYED")])
        _write(fp, "v9/v9.01_RELEASE_PLAN.md", "widget-one")
        ff = check_plan_identity(plans_dir=fp, log_path=flog, reversions_path=root / "none.md")
        arm("S-16 contract lock — a DEPLOYED row's missing plan still blocks",
            fires(ff, "PLAN-MISSING-FOR-LEDGER-ROW", "v9.05") == 1,
            "blocks on a non-VERIFIED row — FAILS on a State==VERIFIED-filtered build")
        arm("S-16b specificity — the conformant VERIFIED row does not fire",
            names([f for f in ff if "PLAN-MISSING-FOR-LEDGER-ROW" in f], "v9.01") == 0,
            "the placement limb discriminates rather than flagging every row")
        rows_f, _ = parse_release_log(flog)
        arm("S-17 ledger columns resolved BY NAME, not by index",
            {r["state"] for r in rows_f} == {"VERIFIED", "DEPLOYED"},
            "State is read from column 6 per the header; index-counting yields dates")

        # ── Scenario G — advisory is non-blocking ────────────────────────────
        g = root / "G"
        gp = g / "plans"
        glog = _write_ledger(g / "RELEASE_LOG.md", [("v3.01", "widget-old", "VERIFIED")])
        _write(gp, "v9/v9.01_RELEASE_PLAN.md", "widget-one")
        fg = check_plan_identity(plans_dir=gp, log_path=glog, reversions_path=root / "none.md")
        arm("S-12 advisory non-blocking — below-floor placement debt does not block",
            any("PLAN-PLACEMENT-TALLY" in f for f in fg)
            and not any("PLAN-MISSING-FOR-LEDGER-ROW" in f for f in blocking(fg)),
            "the pre-ADR-092 row is tallied under ADVISORY, never blocking")
        arm("S-12b the same run still blocks on a real identity defect",
            any("PLAN-VERSION-UNKNOWN" in f for f in blocking(fg)),
            "advisory routing did not swallow the blocking limb")

        # ── Scenario I — the UNVERIFIABLE advisory's ITEMISATION ─────────────
        #
        # THE PROPERTY THE CODE DOCUMENTS AS LOAD-BEARING, WITH NOTHING WATCHING
        # IT. The comment above `unverifiable_above_floor.append(rel)` states the
        # design outright: "A bare count of the unexamined is the same fail-open
        # one level in: a member of this bucket can BE the defect under test, and
        # a count cannot say so." Measured: replacing that append with
        # `.append("")` renders the live advisory as a bare comma-run
        # (`... resolve to no ledger row: , , , ...`) and left this suite at 27
        # arms / 0 failures. The itemisation was reached on every run and asserted
        # by nothing.
        #
        # THE COUNT IS NOT A SUBSTITUTE FOR THE NAMES, and that is exactly why
        # S-21 grades the paths. `len(unverifiable_above_floor)` is UNCHANGED by
        # the blanking mutation — a list of two empty strings still has length
        # two — so an arm asserting the figure passes on the blanked build. Only
        # a name-grading arm discriminates.
        #
        # FIXTURE SHAPE IS THE LIVE SHAPE, not a synthetic one. A version-named
        # plan carrying no join key of any kind (no filename slug tail, no
        # `milestone:`, no `issues:`, no `links.log_anchor`) makes all four
        # oracles come back empty, so resolve_plan_identity() returns
        # (None, False) while the declared version IS a concrete ledger version —
        # which is what routes it past PLAN-VERSION-UNKNOWN and into this bucket.
        # That is the shape of every member of the live residual.
        i_ = root / "I"
        ip = i_ / "plans"
        ilog = _write_ledger(i_ / "RELEASE_LOG.md", [
            ("v4.05", "widget-i-five", "VERIFIED"),
            ("v4.06", "widget-i-six", "VERIFIED"),
            ("v3.05", "widget-i-old", "VERIFIED"),
        ])
        f_unv_hi_a = _write(ip, "v4/v4.05_RELEASE_PLAN.md")
        f_unv_hi_b = _write(ip, "v4/v4.06_RELEASE_PLAN.md")
        # The SAME unjoinable shape BELOW the ADR-092 floor — reached and counted,
        # never itemised. It is what makes S-21b a partition assertion rather than
        # a restatement of S-21.
        f_unv_lo = _write(ip, "v3/v3.05_RELEASE_PLAN.md")
        fi = check_plan_identity(plans_dir=ip, log_path=ilog, reversions_path=root / "none.md")
        i_unv = next((f for f in fi if "PLAN-IDENTITY-UNVERIFIABLE" in f), "")
        i_denom = next((f for f in fi if "PLAN-IDENTITY-DENOM" in f), "")

        arm("S-21 sensitivity — the UNVERIFIABLE advisory NAMES its members, not just their count",
            str(f_unv_hi_a) in i_unv and str(f_unv_hi_b) in i_unv
            and "2 version-declaring plan(s)" in i_unv,
            "both at/above-floor members appear verbatim beside the figure — blanking the "
            "itemisation reddens this arm while leaving the figure intact")
        arm("S-21b partition + anti-vacuity — the below-floor twin is REACHED but not itemised",
            str(f_unv_lo) not in i_unv and "3 unverifiable" in i_denom,
            "DENOM counts all 3 unverifiable plans, so the below-floor file was walked and "
            "classified; its absence from the itemisation is the floor, not a blind walker")
        arm("S-21c the advisory stays ADVISORY — an itemised residual never blocks",
            i_unv.startswith(ADVISORY_PREFIX) and blocking(fi) == [],
            "itemising the unexamined is a control payload, not a finding")

        # ── Scenario J — the PLACEMENT tally's at/above-floor COUNTER ────────
        #
        # `place_blocking` is the number an operator reads to conclude the v4-era
        # corpus is clean, and it was pinned by nothing: `place_blocking += 1`
        # mutated to `+= 0` left the suite green. S-12 asserts the enclosing
        # string EXISTS; `place_advisory` is pinned only indirectly, because it
        # gates emission. The at/above-floor figure had neither.
        #
        # SCOPE, STATED NARROWLY. The placement FINDING is already guarded (S-6,
        # S-16, S-16b). What was inert is the reported COUNT — so these arms pin
        # the figure to the findings it is a count OF, which is the durable form:
        # a future limb that emits a finding without incrementing, or increments
        # without emitting, reddens on the disagreement rather than on a literal.
        j_ = root / "J"
        jp = j_ / "plans"
        jlog = _write_ledger(j_ / "RELEASE_LOG.md", [
            ("v4.07", "widget-j-seven", "VERIFIED"),
            ("v4.08", "widget-j-eight", "VERIFIED"),
            ("v4.09", "widget-j-nine", "VERIFIED"),
            ("v3.07", "widget-j-old", "VERIFIED"),
        ])
        # v4.09 is the conformant control — its plan sits at the nested home, so
        # the limb must discriminate rather than count every row.
        _write(jp, "v4/v4.09_RELEASE_PLAN.md", "widget-j-nine")
        fj = check_plan_identity(plans_dir=jp, log_path=jlog, reversions_path=root / "none.md")
        j_tally = next((f for f in fj if "PLAN-PLACEMENT-TALLY" in f), "")
        j_missing = [f for f in blocking(fj) if "PLAN-MISSING-FOR-LEDGER-ROW" in f]

        arm("S-22 sensitivity — the tally's at/above-floor figure is PINNED to the findings it counts",
            "; 2 at/above the floor" in j_tally and len(j_missing) == 2,
            "the reported 2 and the 2 blocking findings agree — a counter mutated to `+= 0` "
            "reports 0 beside two live findings and reddens here")
        arm("S-22b partition — the below-floor row is tallied under ADVISORY and never blocks",
            "1 concrete ledger row(s) below the ADR-092 floor" in j_tally
            and fires(fj, "PLAN-MISSING-FOR-LEDGER-ROW", "v3.07") == 0,
            "one below-floor row counted as inherited debt, zero blocking findings name it")
        arm("S-22c specificity — the conformant at/above-floor row is neither counted nor flagged",
            fires(fj, "PLAN-MISSING-FOR-LEDGER-ROW", "v4.09") == 0,
            "a row whose plan sits at its nested home contributes to neither figure")

        # ── Scenario K — E1/E2 plan-status lifecycle ────────────────────────
        #
        # SEEDED FIXTURE, AND THAT IS THE POINT. After this release's sweep the
        # live corpus contains ZERO non-terminal shipped plans, so a green run
        # over it proves nothing about whether these limbs discriminate — it is
        # the unsatisfiable-control trap the card itself named. Every arm below
        # therefore seeds the positive it asserts on.
        k = root / "K"
        kp = k / "plans"
        klog = _write_ledger(k / "RELEASE_LOG.md", [
            ("v9.50", "widget-k-closed", "VERIFIED"),
            ("v9.51", "widget-k-active", "VERIFIED"),
            ("v9.52", "widget-k-flight", "DEPLOYED"),
            ("v9.53", "widget-k-bogus", "VERIFIED"),
            ("v9.54", "widget-k-nofield", "VERIFIED"),
            ("v9.55", "widget-k-marker", "VERIFIED"),
        ])
        k_ok = _write_status_plan(kp, "v9/v9.50-widget-k-closed_RELEASE_PLAN.md",
                                  "widget-k-closed", "CLOSED")
        k_bad = _write_status_plan(kp, "v9/v9.51-widget-k-active_RELEASE_PLAN.md",
                                   "widget-k-active", "ACTIVE")
        k_flight = _write_status_plan(kp, "v9/v9.52-widget-k-flight_RELEASE_PLAN.md",
                                      "widget-k-flight", "ACTIVE")
        k_enum = _write_status_plan(kp, "v9/v9.53-widget-k-bogus_RELEASE_PLAN.md",
                                    "widget-k-bogus", "SHIPPED")
        k_none = _write_status_plan(kp, "v9/v9.54-widget-k-nofield_RELEASE_PLAN.md",
                                    "widget-k-nofield", None)
        k_mark = _write_status_plan(kp, "v9/v9.55-widget-k-marker_RELEASE_PLAN.md",
                                    "widget-k-marker", "ACTIVE",
                                    lead="<!-- reference-durability: allow-link -->\n")
        fk = check_plan_identity(plans_dir=kp, log_path=klog,
                                 reversions_path=root / "none.md")
        r_ok, r_bad = _rel(k_ok), _rel(k_bad)
        r_flight, r_enum = _rel(k_flight), _rel(k_enum)
        r_none, r_mark = _rel(k_none), _rel(k_mark)
        k_denom = next((f for f in fk if "PLAN-STATUS-DENOM" in f), "")

        arm("S-23 anti-vacuity — the marker-lead fixture really IS invisible to a strict reader",
            parse_frontmatter(k_mark.read_text(encoding="utf-8")) is None
            and _fm_for_identity(k_mark.read_text(encoding="utf-8")).get("status") == "ACTIVE",
            "parse_frontmatter -> None while the comment-tolerant reader still sees ACTIVE; "
            "without this, S-24b could pass on a shape the corpus never produces")
        arm("S-24 sensitivity — a VERIFIED release whose plan still reads ACTIVE BLOCKS",
            fires(fk, "PLAN-STATUS-NOT-TERMINAL", r_bad) == 1,
            f"exactly one blocking PLAN-STATUS-NOT-TERMINAL naming {r_bad}")
        arm("S-24b sensitivity — the SAME defect below a marker comment blocks identically",
            fires(fk, "PLAN-STATUS-NOT-TERMINAL", r_mark) == 1,
            "the regression lock for the comment-tolerant reader: a strict reader scores 0 here "
            "while every other arm in this scenario stays green")
        arm("S-24c specificity — a shipped plan reading CLOSED fires nothing",
            names(blocking(fk), r_ok) == 0,
            f"{r_ok} joins a VERIFIED row and carries the terminal value — no finding")
        arm("S-24d specificity — an IN-FLIGHT release's plan may still read ACTIVE",
            fires(fk, "PLAN-STATUS-NOT-TERMINAL", r_flight) == 0,
            "the ledger row reads DEPLOYED, not VERIFIED, so the antecedent is unmet — this is "
            "what stops the limb demanding a terminal value from a live release")
        arm("S-25 sensitivity — a status: outside the enum BLOCKS rather than passing silently",
            fires(fk, "PLAN-STATUS-ENUM", r_enum) == 1,
            "SHIPPED is a plausible-looking value and is NOT an enum member; it fails loudly")
        arm("S-25b specificity — the enum limb does not fire on any legal member",
            fires(fk, "PLAN-STATUS-ENUM", r_ok) == 0
            and fires(fk, "PLAN-STATUS-ENUM", r_bad) == 0
            and fires(fk, "PLAN-STATUS-ENUM", r_flight) == 0,
            "CLOSED and ACTIVE both pass E1; only the non-member trips it")
        arm("S-26 forward-only — a plan carrying NO status: reaches neither limb",
            names(blocking(fk), r_none) == 0,
            f"{r_none} joins a VERIFIED row but declares no status — the OPTIONAL tier is "
            "preserved, which is what keeps 146 historical plans out of the finding list")
        # S-27 grades the DENOMINATORS. A limb that examined nothing and a limb
        # that found nothing read identically from a finding count alone.
        arm("S-27 denominator — the tally reports the partition the fixture actually produced",
            "5 of 6 plan file(s) carry a frontmatter status:" in k_denom
            and "1 read CLOSED" in k_denom,
            "6 plans walked, 5 carrying the field, 1 terminal — a counter mutated to `+= 0` "
            "reports 0 beside five live carriers and reddens here")

        # ── Scenario H — check_note_content()'s Tier-1 links.plan limb ───────
        #
        # THE FIRST ARMS THIS SUITE HAS OVER check_note_content(). Everything
        # above drives check_plan_identity(); the two surfaces below shipped with
        # NO executor anywhere, and a 7-mutation campaign measured it rather than
        # inferred it — stripping the note path out of the NO-FRONTMATTER finding,
        # and lowering PLAN_LINK_CUTOVER far enough to convert every inherited
        # below-floor dangle into a blocking finding, each left this suite AND the
        # shell suite green. Both are missing guards on working code, which is the
        # "reachable and inert" shape moved up a level: from the code to the tests
        # watching it.
        #
        # WHY THE GLOBALS ARE REBOUND. check_note_content() takes no parameters
        # and reads module-level corpus paths, so binding a fixture corpus means
        # rebinding those three names for the duration of the call and restoring
        # them in a `finally`. That buys a hermetic drive of the REAL function.
        # The alternative — asserting over the emitter's source text — would grade
        # the shape of a string literal rather than the behaviour of the limb, and
        # this release has already been bitten twice by assertions that graded
        # finding TEXT while nothing checked whether anything blocked.
        #
        # The restore is in a `finally` because a failure inside the window would
        # otherwise leave the module pointed at a deleted temp tree and turn every
        # later live-corpus call in the same process into a path-resolution error.
        h = root / "H"
        h_notes = h / "release" / "releases" / "notes"
        h_plans = h / "release" / "releases" / "plans"
        h_plans.mkdir(parents=True, exist_ok=True)
        _write(h_plans, "v4/v4.02_RELEASE_PLAN.md", "widget-two")
        real_link = "release/releases/plans/v4/v4.02_RELEASE_PLAN.md"
        dead_link = "release/releases/plans/v4/v4.99_RELEASE_PLAN.md"
        marker = "<!-- reference-durability: allow-link -->\n"
        # F-01 fixtures — the marker-before-fence shape, one each side of the floor.
        n_nofm_hi = _write_note(h_notes, "v4/v4.01_RELEASE_NOTES.md", real_link, lead=marker)
        n_nofm_lo = _write_note(h_notes, "v3/v3.99_RELEASE_NOTES.md", real_link, lead=marker)
        # F-02 fixtures — readable frontmatter, pointer dangles, one each side.
        n_dead_hi = _write_note(h_notes, "v4/v4.03_RELEASE_NOTES.md", dead_link)
        n_dead_lo = _write_note(h_notes, "v3/v3.98_RELEASE_NOTES.md", dead_link)
        # Specificity fixture — at/above the floor and RESOLVING; fires neither limb.
        n_ok_hi = _write_note(h_notes, "v4/v4.04_RELEASE_NOTES.md", real_link)

        _h_saved = {k: globals()[k] for k in ("WORKSPACE_ROOT", "NOTES_DIR", "PLANS_DIR")}
        try:
            globals().update(WORKSPACE_ROOT=h, NOTES_DIR=h_notes, PLANS_DIR=h_plans)
            fh = check_note_content()
            # Resolved INSIDE the window — _rel() renders against WORKSPACE_ROOT.
            r_nofm_hi, r_nofm_lo = _rel(n_nofm_hi), _rel(n_nofm_lo)
            r_dead_hi, r_dead_lo = _rel(n_dead_hi), _rel(n_dead_lo)
            r_ok_hi = _rel(n_ok_hi)
        finally:
            globals().update(_h_saved)

        h_tally = next((f for f in fh if "NOTE-PLAN-LINK-TALLY" in f), "")

        arm("S-18 anti-vacuity — the marker-lead fixture really IS unreadable to the strict parser",
            parse_frontmatter(n_nofm_hi.read_text(encoding="utf-8")) is None
            and _plan_link_state(n_nofm_hi.read_text(encoding="utf-8")) == ("unreadable", ""),
            "parse_frontmatter -> None and the limb classifies it 'unreadable'; without this "
            "S-19 could pass on a shape the corpus never produces")

        # S-19 — F-01. THE FAIL-OPEN GUARD, and the reason it is not optional.
        # Phase 9.2 scopes the lint to the closing release by grepping the output
        # for THAT release's repo-root-relative NOTE path
        # (automated-closeout.sh phase_lint_release_notes). A NO-FRONTMATTER
        # finding that did not carry the note path would be blocking in name and
        # fail-open in fact — the caller would take its "no finding for this
        # version" PASS branch. That is the identical exposure PL-9/PL-10 guard
        # for the other finding classes; this class had nothing.
        arm("S-19 sensitivity — NO-FRONTMATTER blocks AND carries the note path the caller greps",
            fires(fh, "NOTE-PLAN-LINK-NO-FRONTMATTER", r_nofm_hi) == 1,
            f"exactly one BLOCKING finding, and it names {r_nofm_hi}")
        arm("S-19b specificity — the same unreadable shape BELOW the floor does not block",
            fires(fh, "NOTE-PLAN-LINK-NO-FRONTMATTER", r_nofm_lo) == 0,
            "a pre-ADR-092 note with unreadable frontmatter is inherited debt, not a block")

        # S-20 — F-02. THE CUTOVER GUARD. PLAN_LINK_CUTOVER is the operator-
        # rendered decision this card ships: a dangling links.plan pointer BLOCKS
        # at or above the ADR-092 floor and is inherited debt below it. It had no
        # arm of any kind, so lowering it — which converts the whole below-floor
        # dangle population into blocking findings — left --self-test PASSing.
        # The three arms are TWO-SIDED on purpose: lowering the floor reddens
        # S-20b and S-20c, raising it reddens S-20 and S-20c, so neither direction
        # of drift is silent.
        arm("S-20 sensitivity — a dangling links.plan AT/ABOVE the floor blocks",
            fires(fh, "NOTE-PLAN-LINK-UNRESOLVED", r_dead_hi) == 1,
            f"exactly one BLOCKING NOTE-PLAN-LINK-UNRESOLVED naming {r_dead_hi}")
        arm("S-20b specificity — the SAME dangle BELOW the floor never blocks",
            fires(fh, "NOTE-PLAN-LINK-UNRESOLVED", r_dead_lo) == 0
            and names(blocking(fh), r_ok_hi) == 0,
            "the pre-ADR-092 dangle stays advisory, and the resolving pointer fires nothing")
        # S-20c grades the DENOMINATORS, not just the findings. A limb that
        # examined nothing and a limb that found nothing read identically from a
        # finding count alone, and the partition these numbers express IS the
        # cutover: move the floor and the two denominators move with it.
        arm("S-20c denominator — the tally reports the partition the floor actually produced",
            "blocking limb 1 unresolved of 2 pointer(s) examined" in h_tally
            and "advisory limb 1 unresolved of 1 examined below it" in h_tally
            and "2 note(s) with unreadable frontmatter" in h_tally,
            "2 pointers at/above the floor (1 dangling), 1 below it (dangling), 2 unreadable")

    print(f"\n{checked} arm(s) run, {len(failures)} failure(s)"
          + (f": {failures}" if failures else ""))
    return 1 if failures else 0


def main() -> int:
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    p.add_argument("--check", choices=["all", "filename", "schema", "index", "type-coherence", "note-content", "plan-identity"], default="all", help="Which check(s) to run")
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
    p.add_argument(
        "--self-test",
        action="store_true",
        help=(
            "Run the hermetic sub-check (g) fixture suite and exit. Builds temp corpora and "
            "calls check_plan_identity() through its defaulted parameters — it never reads the "
            "live repository tree, so a corpus change cannot turn the suite green or red."
        ),
    )
    args = p.parse_args()

    # Hermetic fixture suite. Short-circuits BEFORE any corpus read, exactly as
    # --print-scaffold-tokens does, so it runs where the corpus does not resolve.
    if args.self_test:
        return _self_test()

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
    # Sub-check (g). Dispatched under ("all", "plan-identity") — and unlike the
    # four values that reach no runtime invoker, this one HAS an executable
    # caller in the same change: automated-closeout.sh Phase 9.3 passes
    # `--check plan-identity` explicitly and blocks the Stage-13 close on a
    # finding for the closing release. A value reachable only under ("all", …)
    # would run inside its own acceptance test and nowhere else.
    if args.check in ("all", "plan-identity"):
        findings.extend(check_plan_identity())
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
