#!/usr/bin/env python3
"""check-adr-durability.py — ADR durability lint (#1490).

The `adr-number-integrity` gate already guards ADR *identity* (one global, gap-free
`ADR-NNN` sequence). Nothing guards ADR *durability*: a newly-authored ADR can
reintroduce a non-enum `status:` value, bake a commit SHA or a live corpus count into
durable prose, or carry the operator's literal GitHub handle. This checker is the
durability sibling — same self-tested-gate shape as `check-adr-numbers.py`, wired as a
`repo-integrity.yml` job.

RULES
-----
  R1  STATUS-ENUM      the `status:` frontmatter value's LEADING token is one of
                       Proposed | Accepted | Deprecated | Superseded. A prose tail is
                       permitted (the ratification anchor / supersession pointer) —
                       the schema's leading-token rule, not a strict closed enum.
  R2  STALE-ANCHOR     durable prose carries a hardcoded commit SHA or a live
                       corpus-population count. Both rot the moment history is
                       rewritten or the corpus grows; the durability ladder puts a
                       commit hash on its least-durable rung.
  R3  OPERATOR-HANDLE  the operator's literal GitHub handle appears anywhere in the
                       ADR. The sanctioned ADR carve-out is NAME-scoped (the literal
                       name on a `deciders:` frontmatter line, architect-of-record
                       attribution) — the HANDLE is never sanctioned, and R3 closes
                       the gap a line-scoped skip would otherwise open.
  R4  IDENT-REF        a bare issue reference `#N` in an ADR IDENTITY frontmatter
                       field (`title:` / `release:` / `deciders:`). An issue number is
                       the durability ladder's rung 5; an identity field names WHAT
                       THE RECORD IS, so a number that rots there corrupts identity
                       rather than merely provenance. See R4 SCOPE + EXEMPTIONS below.

  R5  STRUCT           a NET-NEW ADR that does not carry the §3 body-section set, or
                       a CHANGED ADR that has LOST a section it carried at the diff
                       base. Delta-scoped and requires `--diff-base`. See the SCOPE
                       block below for exactly what it does and does not assert.

SCOPE — WHAT THIS LINT CHECKS STRUCTURALLY, AND WHAT IT STILL DOES NOT
----------------------------------------------------------------------
This lint governs ADR *durability* (R1-R4). It additionally carries ONE structural
rule, R5, and that rule is deliberately narrow. The canonical section set is DEFINED
once, in `core/schemas/adr-schema.md` §3; this file only CITES it (see DOC_SECTION_SET
below) and R5 asserts against the cited copy, which `--self-test` pins to the schema.

R5's population is DELTA-SCOPED on two limbs, and both have an EMPTY POPULATION over
the existing corpus by construction — which is the whole reason the rule is admissible
at all:

  R5-NEW   an ADR file that does not exist at `--diff-base` and is missing a §3
           section. A record the repository has never seen has no pre-existing
           condition to grandfather.
  R5-LOST  an ADR file that existed at `--diff-base` carrying section S whose head
           revision no longer carries it. A section that disappears in a diff is a
           net-new defect on any corpus, clean or not.

WHAT R5 DOES NOT ASSERT, AND WHY — each measured, not assumed:

  * NOT a pre-existing absence on a merely-CHANGED file. Measured at the conformance
    sweep's own exit: 29 of 111 sweepable records carry a §3 gap the sweep scoped OUT
    with a named blocking authority (25 `## Related ADRs`, 12 `## Reversibility`, 1
    `## Consequences` — backfilling any of them is authoring decision content, not
    hygiene). Asserting over changed files would fire on 26% of ADR-touching PRs
    against records the sweep deliberately did not reach — precisely the
    guarding-before-cleaning condition that got a whole-corpus structural rule
    rejected. The NEW/LOST split keeps the delta posture and keeps the population
    empty on a corpus that is still mid-remediation.
  * NOT position. 27 records carry `## Alternatives Considered` AFTER
    `## Consequences`; the schema's conformance assertion is PRESENCE, and it says so
    ("structurally checkable … never that nothing else is").
  * NOT a heading-form COUNT. A literal `#{2,4}` census cannot reach 1: `ADR-003` and
    `ADR-004` carry legitimate `### Decision N alternatives` H3 sub-headings BENEATH an
    already-canonical H2, pairing one-to-one with their `### Decision N` blocks. R5
    asserts exact H2 membership, so those records pass a check they should pass.
  * NOT the frozen records. `Superseded` / `Deprecated` are whole-file exempt and can
    never conform — one live record needs two edits the immutability policy forbids.
    A predicate over the full glob can never go green; R5 runs over the sweepable set.
  * NOTHING AT ALL without `--diff-base`. A run with no delta base emits a visible
    `CONFIG` row saying R5 scanned nothing, rather than reading green — the same
    "never read green on a scan that examined nothing" discipline R3 applies to an
    unresolved handle.

The consequence, stated so that no reader has to infer it: a GREEN run of this lint
does NOT mean the scanned ADRs are structurally conformant. It means they carry no
durability violation AND introduced no net-new structural one. Those are different
claims, and the second is the narrower.

`--self-test` asserts that DOC_SECTION_SET still equals the schema's §3 table, so the
citation cannot drift from the standard without a test failing. When the schema does
not resolve (running outside a clone), that case reports a visible SKIP rather than
passing silently — the same discipline again.

NEVER HARDCODE THE HANDLE
-------------------------
R3's subject is RESOLVED, never embedded: `--handle`, else the owner segment of
`git config --get remote.origin.url`. Unresolvable → R3 is reported SKIPPED via a
`CONFIG` row (visible, not silent) rather than scanning nothing and reading green.
This file therefore contains no operator handle, and neither does its self-test
(which drives a synthetic fixture handle).

R2 EXEMPTIONS (all structural — no per-instance judgment)
---------------------------------------------------------
  1. Fenced code blocks — stripped before scanning (a worked `git` example is not
     durable prose).
  2. The `source_observations:` frontmatter block — the schema defines it as the
     grounding evidence the decision rests on. Evidence is point-in-time BY
     CONSTRUCTION; pinning it is correct, not rot. The block is located through the
     SHARED `frontmatter_bounds()`, which tolerates the marker HTML comment that opens
     most of the corpus — single-line or multi-line; an earlier line-0-anchored form
     resolved NOTHING on those files, so this exemption silently no-opped on a majority
     of the corpus and reported policy-exempt evidence as a violation. See
     `source_observation_lines()`.
  3. A closed set of explicit historical-framing anchors on the line ("as of",
     "at the time", "at authoring", "at merge time", "then-current", "originally",
     …). An anchored count/SHA is a dated fact, not a live claim. Closed vocabulary,
     so the exemption is falsifiable — never a prose-similarity guess.
  4. A whole-file exemption for `Superseded` / `Deprecated` ADRs. Those records are
     frozen for the audit trail (supersede-not-edit); flagging them would demand an
     edit the immutability policy forbids.
  5. A per-file override marker, `<!-- adr-durability: allow-anchor -->`, mirroring
     the repo-integrity / reference-durability marker convention.

R2-COUNT RECALL BOUND (measured, not asserted)
----------------------------------------------
R2-COUNT is a HIGH-PRECISION PARTIAL NET over a closed vocabulary. It does not claim
to see every live population count, and a green run is NOT evidence that none is
present. What it admits, and what it deliberately does not:

  ADMITTED   <n> (thousands separators allowed) followed by a POPULATION_NOUNS member,
             case-insensitive, with an optional single hyphenated-or-plain qualifier
             word (`11 release-standards` -> `standards`, `126 grep occurrences` ->
             `occurrences`, `13 per-stage files` -> `files`); plus the
             `<n> <singular> files` exemplar shape. Floor >= COUNT_FLOOR.

  NOT ADMITTED — four named classes. Three are deliberate choices; the fourth was
  found by dev testing and is a MEASURED GAP, named here rather than papered over:
   1. FIXED-CARDINALITY CONSTANTS. `13 stages`, `8 columns`, `15 fields`, `104 cells`,
      `180 days` are excluded BY VOCABULARY. They share the `<n> <plural>` shape with
      a true positive and differ only in whether the noun names a GROWING population
      — the one distinction no structural guard can make. This is also where the
      rule's residual false positives live: a design constant whose noun happens to
      be in the vocabulary (a matrix's `13 rows`, a derived `26 cross-references`)
      cannot be separated from a live count by any means available here.
   2. AD-HOC COMPOUND POPULATION NOUNS outside the vocabulary, and compounds needing
      MORE THAN ONE qualifier word. The corpus mints new ones as it grows
      (`role-Specialists`, `7 emitter wirings`, `45 broken links`, `12 retention
      constants`, `8 governance-model-branched folders`). Measured against the whole
      corpus, the residual miss set is dominated by nouns seen exactly ONCE. THIS IS
      THE REAL BOUND: the miss set grows in VOCABULARY, not only in volume, so this
      rule DECAYS with the corpus and must be re-measured, not trusted.
   3. SPELLED-OUT NUMBERS ("forty-four skills"). Probed corpus-wide: zero occurrences
      at the time of writing (the probe's sensitivity control, a fixture carrying the
      shape, returned one). Cheap to add should one ever appear.
   4. A NUMBER CLOSED BY MARKUP OR PUNCTUATION BEFORE THE POPULATION NOUN — emphasis
      (``**10** lines``), a parenthetical (`45 (core) files`), a bracket, a quote.
      `COUNT_RE` requires whitespace immediately after the number, so the intervening
      token defeats the match. This class is NOT one of the three above: the noun is
      IN the vocabulary, the number clears the floor, and the record carries no
      exemption of any kind. It has a live instance —
      `core/ADRs/ADR-106-generated-artifact-retention-purge-declined.md:66` carries
      ``**10** lines``, a genuine count over a growing population on an `Accepted`
      record with no override marker, no historical anchor, and not inside
      `source_observations:`.

      THIS CLASS IS OUTSIDE THE DENOMINATOR, NOT MERELY OUTSIDE THE NUMERATOR, and
      that is the sharp part. The vocabulary-lifted arm in RE-DERIVE below — the arm
      that DEFINES the measured recall floor — replaces the noun alternation and
      holds every other guard constant, so it inherits the same separator requirement
      and misses this shape too. **The measured recall figure is therefore an
      UNDERSTATEMENT of the miss set, not a bound on it.** Read the floor as "at
      least this much of what the lifted arm can see", never as "at most this much is
      missed".

      DO NOT WIDEN THE PREDICATE TO CLOSE THIS WITHOUT RE-MEASURING PRECISION.
      Admitting markup or punctuation before the separator changes the match set, and
      every other guard in this file was admitted on MEASUREMENT rather than on
      plausibility. Widening also moves the denominator every recall figure taken
      against this rule rests on, so a widened predicate and an old recall figure
      cannot be reported together. Reproduce the class first, on the live instance,
      with a one-variable pair: remove the emphasis and change nothing else ->
      `['R2-COUNT']`; keep the emphasis and drop the number below the floor ->
      silent; as-is -> silent.

  WHY A VOCABULARY AT ALL. Dropping it entirely was built and measured, not argued
  about: with every guard in this file retained and only the noun set lifted, the
  predicate's precision falls to roughly two thirds while the closed vocabulary holds
  above nine tenths. The false positives a lifted predicate admits are NOT killable by
  another structural guard, because they are the class-1 constants above.

  RE-DERIVE, DO NOT TRUST THIS PARAGRAPH:
      python3 release/tools/check-adr-durability.py --root .        # shipped result
      # then re-run with the noun alternation in COUNT_RE replaced by
      # `[A-Za-z][A-Za-z\-]*s` and every other guard held constant; the set difference
      # is the vocabulary miss set. Classify each row genuine / constant by hand —
      # there is no mechanical oracle for "does this noun name a growing population".
  A PRECISION FIGURE WITHOUT A RECALL FIGURE READS AS COVERAGE THIS RULE DOES NOT
  CLAIM. The rule's own introducing record reported precision only, and reported it as
  perfect; re-measuring found two of the six then-reported findings were not genuine —
  one an identifier-prefixed verb, one a policy-exempt grounding block the frontmatter
  detector could not see. Both are fixed above. State both halves or neither.

R4 SCOPE + EXEMPTIONS (each decided, not defaulted)
---------------------------------------------------
SCOPE is the LEADING frontmatter block only, bounded by `frontmatter_bounds()`, and
within it only the keys in IDENT_FIELDS. A wrapped/continuation value inherits the
last key, so a multi-line `deciders:` value is covered.

  1. Fenced code blocks — exempt. A worked ADR template that RENDERS a frontmatter
     block is a rendering, not an identity claim. (Structurally redundant — the
     leading-block bound already excludes a fenced template further down the file —
     and kept anyway so the exemption does not depend on that coincidence.)
  2. `source_observations:` — exempt BY CONSTRUCTION: it is not an identity field.
     It is the SANCTIONED provenance home, so an issue number there is correct.
  3. Frozen `Superseded` / `Deprecated` records — exempt, same ground as R2: the
     record is frozen for the audit trail and the fix would demand a forbidden edit.
  4. `<!-- adr-durability: allow-anchor -->` — does NOT suppress R4, mirroring R3.
     The marker's subject is a pinned ANCHOR, not a rotting identity field.
  5. `repo-integrity: allow-issue-ref` — does NOT suppress R4 either. That marker's
     over-reach is the defect R4 exists to close: it is a WHOLE-FILE skip at the CI
     surface that suppresses placement AND validity, so treating it as an R4
     exemption would let the identity rule be silenced by the very default this
     rule was written to retire.
  6. Historical anchors ("as of", …) — NOT applied. An identity field is not a dated
     claim, so anchoring it historically is not a remedy.

The remedy is never a marker: name the release by its slug, the deciders by role or
literal name, and move the issue reference to `source_observations:` or to the ADR's
designated `## References` block with a summary noun phrase, per
`core/standards/adr-authoring-guide.md` § Issue references in ADRs.

WARN-MODE ONLY AT THE CI SURFACE — ENFORCE-FLIP IS DEFERRED
-----------------------------------------------------------
This lint LOCKS a clean baseline; it does not create one. The ADR corpus has not yet
had its full structural-conformance pass, so an enforce-mode flip today would red-CI
the existing corpus — the exact ordering the issue's own dependency note forbids
("guarding before cleaning would red-CI the existing corpus"). The `repo-integrity.yml`
job therefore ships `WARN_MODE: 'true'`, and the flip to enforce is a POST-CONFORMANCE
shakedown step, gated on the ADR full-conformance pass landing first. The checker
itself is mode-agnostic: it always reports the true verdict via its exit code; the
warn/enforce decision lives at the CI surface.

OUTPUT (TSV) / EXIT CODES
-------------------------
  CONFIG    <note>                       # e.g. R3 skipped, handle unresolved
  SCANNED   <n>                          # ADR files examined
  R1        <path>:<line>\t<detail>      # status-enum violation
  R2-SHA    <path>:<line>\t<detail>      # hardcoded commit SHA
  R2-COUNT  <path>:<line>\t<detail>      # live corpus-population count
  R3        <path>:<line>\t<detail>      # operator handle
  R4        <path>:<line>\t<detail>      # issue ref in an identity frontmatter field
  R5-NEW    <path>:1\t<detail>           # net-new ADR missing a §3 section (file-scoped)
  R5-LOST   <path>:1\t<detail>           # changed ADR lost a §3 section it had (file-scoped)
  EXEMPT    <path>\t<reason>             # whole-file exemption applied
  COUNT     <n>                          # total violations

  exit 0 — clean
  exit 1 — violation(s) present (or self-test failure)
  exit 3 — input failure (no ADR files resolved; the tree moved)

Python 3.9-compatible — matches /usr/bin/python3 on the operator baseline.
"""

import argparse
import os
import re
import subprocess
import sys
import tempfile

ADR_DIRS = ("core/ADRs", "release/ADRs")
ADR_GLOB_RE = re.compile(r"^ADR-\d+-.+\.md$")

# ── R1 ───────────────────────────────────────────────────────────────────────
# Leading-token rule per the ADR schema: the value MUST begin with one of the four
# Nygard tokens; an optional prose tail (ratification anchor / supersession pointer)
# follows. Not a strict closed enum — that is the schema's own wording.
STATUS_ENUM = ("Proposed", "Accepted", "Deprecated", "Superseded")
STATUS_LINE_RE = re.compile(r"^status:\s*(.*)$")
# Strip leading markdown emphasis so `status: **Accepted**` is read on its token.
EMPHASIS_LEAD_RE = re.compile(r"^[*_`\s]+")

# ── R2 ───────────────────────────────────────────────────────────────────────
# SHA: word-bounded 7–40 hex. Requiring BOTH an a-f letter AND a digit excludes pure
# decimal runs (dates, large numbers) and pure-alpha runs — the two false-positive
# families a naive `[0-9a-f]{7,40}` would import.
SHA_RE = re.compile(r"(?<![0-9a-zA-Z])([0-9a-f]{7,40})(?![0-9a-zA-Z])")

# COUNT: closed corpus-population vocabulary — the nouns whose live totals GROW, so a
# pinned number rots. Structural constants ("3 kinds", "4 tiers", "6 sections") are
# outside the vocabulary by construction, and the >=5 floor drops the residual small
# design constants that share a noun ("2 checks", "3 hooks").
#
# The membership below is DERIVED, not chosen: it is the head of the population-noun
# distribution measured across the whole ADR corpus with the vocabulary constraint
# lifted, plus the long-tail members whose semantics are unambiguously population.
# Nouns deliberately EXCLUDED despite appearing in the corpus — `stages`, `flows`,
# `archetypes`, `cells`, `columns`, `fields`, `values`, `entities`, `days` — each names
# a FIXED-CARDINALITY design constant. Admitting them was measured and is what drops a
# delexicalised predicate to ~40% precision. See the R2-COUNT RECALL BOUND block in the
# module docstring for what this vocabulary does NOT reach, and why.
#
# FOUR PRECISION GUARDS, each measured against the live corpus rather than asserted
# (a naive `<n> <noun>` predicate scored ~60% false positives on the shipped ADRs):
#   (a) PLURAL-ONLY — a live count is plural ("44 skills"); a singular noun after a
#       number is nearly always a REFERENCE ("§ 6 ADR Recommendation", "Stage 12 gate",
#       "8 criterion"). The one singular form kept is the `<n> <noun> files` shape,
#       which is the exemplar failure the issue cites ("22 ADR files").
#   (b) NO IDENTIFIER PREFIX — a number glued to `-`, `.`, a LETTER or `#` is an
#       identifier segment, not a count ("ADR-076 gates", "v3.80 checks", "C5 gates"
#       where `gates` is a verb, "#1472 lands"). The letter and `#` classes complete
#       the rule guard (b) already states; without them the two commonest false-
#       positive families in the corpus — alphanumeric control ids and issue
#       references followed by a verb ending in -s — both survive.
#   (c) NO REFERENCE-WORD PREFIX — a closed set of preceding tokens turns the number
#       into an ordinal reference, never a population ("Stage 12", "§ 6", "ADR 030").
#   (d) NO CEILING PREFIX — a closed set of preceding comparison words makes the number
#       a BOUND the corpus is authored to stay under, not a measurement of it ("per-doc
#       files stay under 500 lines", "<=200 lines per precedent"). A ceiling is authored
#       to be stable; it is the opposite of the rot class.
#
# The residual, which no guard reaches: VOCABULARY, NOT SHAPE. The noun must name a
# growing population, and that is the one distinction no structural guard can make —
# "13 stages" and "13 files" are the same shape, and only the noun separates a frozen
# design constant from live rot. That is why the vocabulary is retained and widened
# rather than dropped.
POPULATION_NOUNS = (
    # the originally-shipped ten
    "ADRs", "skills", "checks", "hooks", "agents", "workflows",
    "criteria", "issues", "milestones", "gates",
    # measured additions — corpus artifacts whose totals grow
    "files", "lines", "paths", "locations", "places",
    "references", "refs", "occurrences", "matches", "hits",
    "standards", "specs", "rules", "roadmaps", "tools",
    "rows", "records", "entries", "declarations", "summaries",
    "headlines", "patterns", "instances", "consumers", "operations",
    "CIs",
)
POPULATION_SINGULAR = (
    "ADR", "skill", "check", "hook", "agent", "workflow",
    "criterion", "issue", "milestone", "gate",
)
# An optional single qualifier word (plain or hyphenated) may sit between the number and
# the population noun. This is the load-bearing structural clause, not a convenience: it
# converts an unbounded COMPOUND space (`release-standards`, `incoming refs`, `grep
# occurrences`, `per-stage files`, `occurrence-lines`) into vocabulary hits with one
# clause instead of one vocabulary entry per compound — and a closed enumeration of
# compounds is exactly the thing that cannot be kept complete. Non-capturing, so
# group(1) remains the number for the floor and reference-prefix logic.
# The number itself may carry thousands separators. Matching them is not cosmetic: with
# a bare `\d+` the predicate starts INSIDE `1,317` and reports `317 lines`, which
# understates the very count it is flagging and makes the finding unciteable. The comma
# is therefore in the lookbehind (so a match cannot begin mid-number) and inside the
# capture; the floor arithmetic strips it.
COUNT_RE = re.compile(
    r"(?<![0-9.\-A-Za-z#,])(\d[\d,]*\d|\d)\s+(?:more\s+|additional\s+|live\s+|total\s+)?"
    r"(?:(?:[A-Za-z][A-Za-z\-]*[-\s])?(" + "|".join(POPULATION_NOUNS) + r")\b"
    r"|(" + "|".join(POPULATION_SINGULAR) + r")\s+files?\b)",
    re.IGNORECASE,
)
# Preceding tokens that make the number an ORDINAL REFERENCE, not a population count.
#
# THE WORD BOUNDARY IS LOAD-BEARING, and its absence was a measured recall defect.
# The word alternatives were originally unanchored, so the single-letter members `v`
# and `g` matched the TAIL of any longer word — `addin[g] 24 cross-references`,
# `containin[g] 14 files`, `Existin[g] 115 refs` were each silently demoted to an
# ordinal reference and never reported. Measured over the 111-record mainline corpus:
# 97 COUNT_RE hits clear the floor and ceiling guards, of which the unanchored form
# suppressed 9 and the anchored form suppresses 6 — three genuine live counts
# recovered, with the six real reference-word suppressions preserved as the control.
#
# `\b` is applied to the WORD GROUP and deliberately not to `§`, which is not a word
# character (a boundary assertion before it fails against a preceding space and would
# disable the section-symbol arm entirely). Anchoring the whole group rather than only
# `v` and `g` was measured to recover EXACTLY the same three findings — `\b` can only
# ever narrow a match set, so the broader anchor closes the whole shape class at zero
# observed cost rather than patching the two members that happened to be observed.
REFERENCE_PREFIX_RE = re.compile(
    r"(?:§|§§|\b(?:stage|gate|check|adr|phase|wave|tier|step|rule|section|part|"
    r"chapter|item|option|qc|v|g))\s*$",
    re.IGNORECASE,
)
# Preceding tokens that make the number a CEILING the population is authored to stay
# under ("per-doc files stay under 500 lines", "a thin index (<=50 lines)") rather than a
# measurement of it. A ceiling is authored to be stable, so it does not rot; flagging it
# is noise. Closed set, same falsifiability discipline as the reference-prefix and
# historical-anchor guards.
#
# CEILINGS ONLY — the symmetric floor words ("exceeds", "at least", ">=", "more than")
# were measured and REJECTED: they suppress empirical lower-bound measurements such as
# "grep >=80 matches", which are live counts that DO rot, and they killed no false
# positive the ceiling half had not already killed. A guard that looks symmetric is not
# thereby correct; this one is asymmetric because the corpus is.
CEILING_PREFIX_RE = re.compile(
    r"(?:under|below|≤|<=|at most|no more than|up to|fewer than|"
    r"max(?:imum)?(?:\s+of)?)[\s*_`(\[]*$",
    re.IGNORECASE,
)
COUNT_FLOOR = 5

# Closed historical-framing vocabulary. A count/SHA carrying one of these anchors on
# the same line is a DATED fact, not a live claim, so it does not rot.
HISTORICAL_ANCHORS = (
    "as of", "at the time", "at authoring", "at merge time", "at the authoring commit",
    "then-current", "originally", "at that time", "was ", "were ", "historical",
    "at authoring time", "at the time of", "point-in-time",
    # Measured additions. Each was tested against the whole corpus and admitted only
    # because its suppression set contains NO live-population claim. Five further
    # candidates were REJECTED on the same test: "live survey", "empirical survey" and
    # "corpus probe returned" each suppress genuine counts (a survey METHOD is not a
    # date), and "live-state reconciliation" / "live registry drift" match nothing —
    # a vocabulary entry that suppresses nothing is not an exemption, it is noise.
    "at survey baseline", "audit-baseline",
)

OVERRIDE_MARKER = "adr-durability: allow-anchor"
FROZEN_STATUSES = ("Superseded", "Deprecated")

# ── R4 ───────────────────────────────────────────────────────────────────────
# Identity fields per `adr-schema.md` §2. The schema's own split is what makes this
# set principled rather than chosen: it defines these as the record's identity /
# metadata, and defines `source_observations:` SEPARATELY as point-in-time grounding
# evidence. `title:` currently carries no live violation and is kept anyway — the
# schema requires it to match the H1, so a number leaking there is an identity
# corruption the rule must still forbid. A deliberate zero-population limb, not dead
# code.
IDENT_FIELDS = ("title", "release", "deciders")
# A `#` that opens a bare issue token: not preceded by another `#` (so a doubled hash
# and a markdown heading are excluded) and not glued to a word character. Mirrors
# SHA_RE's boundary idiom rather than introducing a second convention.
IDENT_ISSUE_RE = re.compile(r"(?<![0-9A-Za-z_#])#(\d+)\b")
# Frontmatter parsing. Blank lines and HTML comments may PRECEDE the opening `---`.
#
# The comment tolerance is a STATE MACHINE, not a per-line regular expression. A
# line-scoped expression cannot see a comment that SPANS lines, and no flag repairs
# that: the subject handed to the expression is ONE line, so it contains no `-->` to
# match and no newline for `re.DOTALL`'s `.` to cross. (DOTALL is the right tool where
# the subject is the whole document — `av-verify.py` and `lint_release_corpus.py` both
# use it correctly for exactly that. It is the wrong tool here.) Carrying an
# `in_comment` bit ACROSS lines is the only shape that sees the whole construct.
FM_COMMENT_OPEN = "<!--"
FM_COMMENT_CLOSE = "-->"
FM_DELIM = "---"
FM_KEY_RE = re.compile(r"^([A-Za-z_][A-Za-z0-9_]*):")

# ── section-set citation (NOT a rule — see the SCOPE block in the module docstring) ──
# The body-section set is DEFINED in the schema below and CITED here. This copy exists
# so the docstring's scope claim names a concrete set; `--self-test` asserts the copy
# still equals the schema's §3 table, which is what makes "no drift between the
# standard and its linter" a mechanical assertion rather than a promise in prose.
SECTION_SET_SOURCE = os.path.join("core", "schemas", "adr-schema.md")
DOC_SECTION_SET = (
    "## Status",
    "## Context",
    "## Decision",
    "## Alternatives Considered",
    "## Consequences",
    "## Reversibility",
    "## Related ADRs",
)
# §3's heading, any heading that ends §3's table, and a numbered §3 table row.
SCHEMA_S3_HEADING_RE = re.compile(r"^##\s*3\.\s")
SCHEMA_ANY_HEADING_RE = re.compile(r"^#{2,3}\s")
SCHEMA_S3_ROW_RE = re.compile(r"^\|\s*\d+\s*\|\s*`(##\s[^`]+)`\s*\|")


def _leading_status_token(value):
    """The first bare word of a `status:` value, emphasis and quoting stripped."""
    v = EMPHASIS_LEAD_RE.sub("", value).strip()
    if not v:
        return ""
    return re.split(r"[\s,.;:(*_`]", v, 1)[0]


def strip_fences(lines):
    """Blank out fenced-code lines in place (index-preserving, so line numbers hold)."""
    out = []
    in_fence = False
    for line in lines:
        if line.lstrip().startswith("```"):
            in_fence = not in_fence
            out.append("")
            continue
        out.append("" if in_fence else line)
    return out


def _strip_html_comments(line, in_comment):
    """Remove HTML-comment spans from `line`; return `(residue, still_open)`.

    `in_comment` carries state IN from the previous line, which is the entire point:
    an HTML comment is a MULTI-LINE construct, so a scanner that restarts at every
    line structurally cannot see one that spans.

    Comments do not nest (HTML spec), so a `<!--` met while already inside a comment
    is ordinary comment text — and a single line may legitimately close one span and
    open another (`<!-- a --> <!-- b`), which is why the returned bit is computed from
    the LAST transition on the line rather than from a count.
    """
    out = []
    i = 0
    while i < len(line):
        if in_comment:
            j = line.find(FM_COMMENT_CLOSE, i)
            if j < 0:
                break                       # the comment runs past end-of-line
            i = j + len(FM_COMMENT_CLOSE)
            in_comment = False
            continue
        j = line.find(FM_COMMENT_OPEN, i)
        if j < 0:
            out.append(line[i:])
            break
        out.append(line[i:j])
        i = j + len(FM_COMMENT_OPEN)
        in_comment = True
    return ("".join(out), in_comment)


def frontmatter_bounds(lines):
    """(start, end) 0-based indices of the LEADING `---` frontmatter block, or None.

    TOLERATES blank lines and HTML comments — SINGLE-LINE OR MULTI-LINE — before the
    opening delimiter. That tolerance is load-bearing, not cosmetic: a majority of the
    shipped ADR corpus opens with a durability or repo-integrity marker comment rather
    than with `---`, so a detector that requires line 0 to be `---` silently resolves
    NOTHING on those files — it returns "no frontmatter" instead of "frontmatter I
    could not parse", and a caller cannot tell the two apart.

    The multi-line limb is the same defect one generation on. The first repair matched
    a comment with a per-line regex, which handles the whole-line form the corpus
    happens to use today and is blind to a comment that spans two lines — reopening
    the identical silent no-op for the next marker anyone wraps. The scan is therefore
    stateful (`_strip_html_comments`).

    ASYMMETRY, DELIBERATE. Comment-awareness applies to the LEADING region ONLY. The
    closing-delimiter scan below stays literal because between the delimiters the
    content is YAML, where `<!--` is STRING CONTENT and not markup: `ADR-089` carries
    a quoted ``<!-- key: value -->`` inside a `source_observations:` scalar. Tracking
    comment state through the block would let an unbalanced `<!--` inside a YAML
    string swallow the closing `---` — trading this defect for a worse one.

    This is the SHARED bound. Three consumers resolve through it — R4
    (`identity_field_findings()`), the R2 provenance exemption
    (`source_observation_lines()`), and `generate-adr-index.py`'s `read_frontmatter()`,
    which imports this module by path — so no two of them can disagree about where an
    ADR's frontmatter begins, and there is no second copy to fix next time.
    """
    start = None
    in_comment = False
    for i, line in enumerate(lines):
        residue, in_comment = _strip_html_comments(line, in_comment)
        residue = residue.strip()
        if not residue:
            continue                        # blank, or nothing outside a comment
        start = i if residue == FM_DELIM else None
        break
    if start is None:
        return None
    for j in range(start + 1, len(lines)):
        if lines[j].strip() == FM_DELIM:
            return (start, j)
    return None


def identity_field_findings(raw, body):
    """R4 — (line_no_1based, key, token) for each issue ref in an identity field.

    `raw` bounds the frontmatter; `body` is the fence-stripped copy the token is read
    from, so a fenced rendering of a frontmatter block can never yield a finding.
    """
    bounds = frontmatter_bounds(raw)
    if bounds is None:
        return []
    start, end = bounds
    out = []
    key = None
    for i in range(start + 1, end):
        m = FM_KEY_RE.match(raw[i])
        if m:
            key = m.group(1)          # a continuation line inherits the last key
        if key not in IDENT_FIELDS:
            continue
        for tok in IDENT_ISSUE_RE.finditer(body[i]):
            out.append((i + 1, key, tok.group(0)))
    return out


def source_observation_lines(lines):
    """Line indices (0-based) inside the frontmatter `source_observations:` block.

    Frontmatter is the leading block bounded by `frontmatter_bounds()`; the field's
    value is its following indented / `- ` continuation lines. Point-in-time by
    construction.

    The bound is the SHARED one deliberately. An earlier form of this function opened
    the block only when line 0 was literally `---`, and the majority of the shipped ADR
    corpus opens with a marker HTML comment instead — so this exemption silently
    resolved NOTHING on those files and reported policy-exempt grounding evidence as an
    R2 violation. A no-op exemption is worse than an absent one: it reads as "no
    evidence block here" rather than "I could not find the block", and no caller can
    tell those apart.
    """
    marked = set()
    bounds = frontmatter_bounds(lines)
    if bounds is None:
        return marked
    start, end = bounds
    inside = False
    for i in range(start + 1, end):
        stripped = lines[i]
        if re.match(r"^source_observations:", stripped):
            inside = True
            marked.add(i)
            continue
        if inside:
            # A continuation is indented or a list item; any other top-level key ends it.
            if stripped[:1] in (" ", "\t", "-") or not stripped.strip():
                marked.add(i)
                continue
            inside = False
    return marked


def has_historical_anchor(line):
    low = line.lower()
    return any(a in low for a in HISTORICAL_ANCHORS)


def body_h2_set(text):
    """Exact H2 heading strings in an ADR body, fence-aware and space-normalized.

    PRESENCE, not position, and H2 only — see the R5 half of the SCOPE block for the
    two measurements (27 out-of-position records; two records with legitimate H3
    sub-headings beneath a canonical H2) that make both choices load-bearing rather
    than stylistic.
    """
    out = set()
    for line in strip_fences(text.splitlines()):
        if line.startswith("## "):
            out.add(" ".join(line.split()))
    return out


def struct_findings(text, base_text, is_new):
    """R5. Returns [(rule, detail)] — file-scoped, so no line number.

    `is_new`   the file does not exist at the diff base.
    `base_text` the file's content at the diff base, or None when it is net-new.

    Both limbs are DELTA properties. Neither can fire on a record whose gap
    pre-dates the diff base, which is what keeps this rule out of the
    guarding-before-cleaning hazard a whole-corpus structural rule would hit.
    """
    head = body_h2_set(text)
    if is_new:
        missing = [s for s in DOC_SECTION_SET if s not in head]
        if missing:
            return [(
                "R5-NEW",
                "net-new ADR is missing the required §3 section(s) %s — the set is "
                "defined in %s §3 and this is a presence assertion, not a position or "
                "heading-count one (add the exact H2 string; a section declaring a "
                "single forced approach is conformant content)"
                % (", ".join(repr(s) for s in missing), SECTION_SET_SOURCE),
            )]
        return []
    if base_text is None:
        return []
    base = body_h2_set(base_text)
    lost = [s for s in DOC_SECTION_SET if s in base and s not in head]
    if lost:
        return [(
            "R5-LOST",
            "this change REMOVES the required §3 section(s) %s, which the record "
            "carried at the diff base — a section that disappears in a diff is a "
            "net-new structural defect regardless of the rest of the corpus's state"
            % ", ".join(repr(s) for s in lost),
        )]
    return []


def scan_text(path, text, handle, allowed_lines=None, struct=None):
    """Evaluate one ADR's text. Returns (findings, exempt_reason_or_None).

    findings — list of (rule, line_no_1based, detail).
    allowed_lines — when not None, only these 1-based line numbers may yield a
                    finding (the net-new added-lines delta posture).
    struct — when not None, a dict {"is_new": bool, "base_text": str|None} that
             activates R5. R5 is NOT gated on `allowed_lines`: a section that is
             absent has no added line to be allowed, so the added-line gate would
             silence it in every case. Its delta scoping is the NEW/LOST split
             instead, which is the structural analogue of the same posture.
    """
    findings = []
    raw = text.splitlines()
    frozen = False
    status_value = None

    # --- R1 (always evaluated; a status line is the ADR's identity field) --------
    for idx, line in enumerate(raw):
        m = STATUS_LINE_RE.match(line)
        if m:
            status_value = m.group(1)
            token = _leading_status_token(status_value)
            if token in FROZEN_STATUSES:
                frozen = True
            if token not in STATUS_ENUM:
                if allowed_lines is None or (idx + 1) in allowed_lines:
                    findings.append((
                        "R1", idx + 1,
                        "status leading token %r is outside the enum (%s)"
                        % (token, " | ".join(STATUS_ENUM)),
                    ))
            break  # frontmatter `status:` is the first one; body restatements are prose

    # --- whole-file R2 exemptions ------------------------------------------------
    exempt = None
    if OVERRIDE_MARKER in text:
        exempt = "override marker present"
    elif frozen:
        exempt = "frozen record (%s) — supersede-not-edit" % _leading_status_token(status_value or "")

    body = strip_fences(raw)
    src_obs = source_observation_lines(raw)

    # --- R5 (structural, delta-scoped) -------------------------------------------
    # Keyed on `frozen`, never on `exempt`: a frozen record can never conform (it
    # would need edits the immutability policy forbids), while the per-file anchor
    # marker is a DURABILITY override and says nothing about structure. The
    # repo-integrity `allow-adr-durability` marker is honored at the CI surface,
    # which filters the file list before this function ever sees it.
    if struct is not None and not frozen:
        for rule, detail in struct_findings(text, struct.get("base_text"),
                                            struct.get("is_new", False)):
            findings.append((rule, 1, detail))

    # --- R4 (frontmatter identity fields) ---------------------------------------
    # Keyed on `frozen` DIRECTLY, never on `exempt`: `exempt` is also set by the
    # per-file anchor marker, and neither that marker nor the repo-integrity
    # issue-ref marker suppresses R4 — an identity field never becomes durable-
    # correct, exactly as R3 is never suppressed either.
    if not frozen:
        for lineno, key, tok in identity_field_findings(raw, body):
            if allowed_lines is not None and lineno not in allowed_lines:
                continue
            findings.append((
                "R4", lineno,
                "issue reference %s in the identity field %r (an identity field names "
                "what the record IS; move the reference to source_observations: or to "
                "a designated `## References` block with a summary noun phrase, and "
                "name the value by its slug / role / literal name)" % (tok, key),
            ))

    for idx, line in enumerate(body):
        if not line.strip():
            continue
        lineno = idx + 1
        if allowed_lines is not None and lineno not in allowed_lines:
            continue

        # --- R3 (NOT exempt by the R2 exemptions — a handle never becomes durable) -
        if handle:
            if re.search(r"(?<![0-9A-Za-z_-])" + re.escape(handle) + r"(?![0-9A-Za-z_-])",
                         line):
                findings.append((
                    "R3", lineno,
                    "operator GitHub handle present (the ADR carve-out is NAME-scoped, "
                    "on a deciders: line only — the handle is never sanctioned)",
                ))

        if exempt is not None or idx in src_obs or has_historical_anchor(line):
            continue

        for m in SHA_RE.finditer(line):
            tok = m.group(1)
            if not (re.search(r"[a-f]", tok) and re.search(r"[0-9]", tok)):
                continue
            findings.append((
                "R2-SHA", lineno,
                "hardcoded commit SHA %r in durable prose (least-durable rung; "
                "summarize the change inline or anchor it historically)" % tok,
            ))

        for m in COUNT_RE.finditer(line):
            try:
                n = int(m.group(1).replace(",", ""))
            except ValueError:
                continue
            if n < COUNT_FLOOR:
                continue
            if REFERENCE_PREFIX_RE.search(line[:m.start(1)]):
                continue
            if CEILING_PREFIX_RE.search(line[:m.start(1)]):
                continue
            findings.append((
                "R2-COUNT", lineno,
                "live corpus count %r in durable prose (the population grows; cite the "
                "deriving command or anchor the number historically)" % m.group(0).strip(),
            ))

    return findings, exempt


# ── inputs ───────────────────────────────────────────────────────────────────

def derive_handle(explicit):
    """Operator GitHub handle — NEVER hardcoded.

    `--handle` wins (CI passes the run actor). Otherwise the owner segment of the
    running clone's origin remote, which is fork-correct and operator-neutral in
    source. Returns None when neither resolves.
    """
    if explicit:
        return explicit.strip() or None
    try:
        url = subprocess.run(["git", "config", "--get", "remote.origin.url"],
                             capture_output=True, text=True).stdout.strip()
        m = re.search(r"[:/]([^/]+)/[^/]+?(?:\.git)?$", url)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None


def repo_root_from_file():
    """Repo root inferred from this file's own location (`release/tools/<this>`)."""
    return os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))


def parse_schema_section_set(root):
    """The body-section set as the SCHEMA declares it, in table order.

    Reads the §3 table of the schema named by SECTION_SET_SOURCE — the defining
    authority for the set. Returns None (never a silent empty tuple) when the schema
    does not resolve or its table does not parse, so the caller reports a visible SKIP
    rather than asserting equality against nothing.
    """
    try:
        with open(os.path.join(root, SECTION_SET_SOURCE),
                  "r", encoding="utf-8", errors="replace") as fh:
            lines = fh.read().splitlines()
    except OSError:
        return None
    out = []
    inside = False
    for line in lines:
        if SCHEMA_S3_HEADING_RE.match(line):
            inside = True
            continue
        if inside:
            if SCHEMA_ANY_HEADING_RE.match(line):
                break           # §3's own table ends at the next heading (e.g. §3.1)
            m = SCHEMA_S3_ROW_RE.match(line)
            if m:
                out.append(" ".join(m.group(1).split()))
    return tuple(out) or None


def collect_adrs(root, explicit_files):
    """Absolute ADR paths to scan (explicit list, else both ADR dirs)."""
    if explicit_files:
        out = []
        for f in explicit_files:
            base = os.path.basename(f)
            if not ADR_GLOB_RE.match(base):
                continue
            p = f if os.path.isabs(f) else os.path.join(root, f)
            if os.path.isfile(p):
                out.append(p)
        return sorted(out)
    out = []
    for d in ADR_DIRS:
        full = os.path.join(root, d)
        if not os.path.isdir(full):
            continue
        for name in sorted(os.listdir(full)):
            if ADR_GLOB_RE.match(name):
                out.append(os.path.join(full, name))
    return out


def base_blob_map(diff_base, paths, root):
    """{path: (is_new, base_text_or_None)} at `diff_base` — R5's delta substrate.

    `git show <base>:<path>` is invoked through a subprocess ARGUMENT LIST, never a
    shell string: some shells apply their own history/modifier expansion to a
    `rev:path` word and silently mangle it, which reads back as a file that does not
    exist at the base — i.e. as a false "net-new". A read error is reported as
    `(False, None)`, which makes BOTH R5 limbs silent for that file rather than
    inventing a net-new verdict from a failed read.
    """
    result = {}
    for p in paths:
        rel = os.path.relpath(p, root)
        try:
            proc = subprocess.run(["git", "show", "%s:%s" % (diff_base, rel)],
                                  capture_output=True, text=True, cwd=root)
        except Exception:
            result[p] = (False, None)
            continue
        if proc.returncode == 0:
            result[p] = (False, proc.stdout)
            continue
        # Distinguish "absent at the base" (net-new — the R5-NEW population) from
        # any other git failure (bad ref, not a repo), which must stay silent.
        exists = subprocess.run(["git", "cat-file", "-e", "%s^{commit}" % diff_base],
                                capture_output=True, text=True, cwd=root).returncode == 0
        result[p] = (True, None) if exists else (False, None)
    return result


def added_line_map(diff_base, paths, root):
    """{path: set(1-based added line numbers)} since `diff_base` (net-new posture)."""
    result = {}
    for p in paths:
        rel = os.path.relpath(p, root)
        try:
            diff = subprocess.run(
                ["git", "diff", "--unified=0", diff_base + "...HEAD", "--", rel],
                capture_output=True, text=True, cwd=root).stdout
        except Exception:
            result[p] = None      # cannot compute -> scan whole file (fail loud, not blind)
            continue
        lines = set()
        newln = 0
        for dl in diff.splitlines():
            if dl.startswith("@@"):
                mm = re.search(r"\+(\d+)", dl)
                newln = int(mm.group(1)) if mm else 0
                continue
            if dl.startswith("+++") or dl.startswith("---"):
                continue
            if dl.startswith("+"):
                lines.add(newln)
                newln += 1
            elif dl.startswith("-"):
                continue
        result[p] = lines
    return result


# ── self-test ────────────────────────────────────────────────────────────────

FIXTURE_HANDLE = "octo-fixture"          # synthetic; never the real operator handle

# A predicate that cannot match anything, for the mutation-kill controls below.
NEVER_MATCH_RE = re.compile(r"(?!x)x")


def _legacy_line0_source_observation_lines(lines):
    """The PRE-REPAIR `source_observations:` bound — kept ONLY as a mutation control.

    It requires line 0 to be literally `---`, which is false for most of the shipped
    corpus. Never call this outside the self-test: it exists so the suite can prove its
    own exemption case is load-bearing, by asserting that the case FAILS when the repair
    is reverted. A test that passes both before and after a fix tests nothing.
    """
    marked = set()
    if not lines or lines[0].strip() != FM_DELIM:
        return marked
    end = None
    for i in range(1, len(lines)):
        if lines[i].strip() == FM_DELIM:
            end = i
            break
    if end is None:
        return marked
    inside = False
    for i in range(1, end):
        stripped = lines[i]
        if re.match(r"^source_observations:", stripped):
            inside = True
            marked.add(i)
            continue
        if inside:
            if stripped[:1] in (" ", "\t", "-") or not stripped.strip():
                marked.add(i)
                continue
            inside = False
    return marked


def _legacy_line_scoped_frontmatter_bounds(lines):
    """The PRE-FIX frontmatter bound — kept ONLY as a mutation control.

    The defect it reproduces is the loss of STATE AT THE LINE BOUNDARY, so that is
    what it is written as: the same `_strip_html_comments` scanner, re-entered with
    `in_comment=False` on EVERY line. A line whose comment does not close within it
    leaves the scanner open, the line is not skippable, and the bound gives up — which
    is precisely how the shipped per-line regex behaved on a comment spanning lines.

    Written this way ON PURPOSE, rather than by keeping a copy of the flagged
    expression. A verbatim copy of the flagged pattern would re-raise the very CodeQL
    alert this change exists to clear ("this regular expression does not match comments
    containing newlines") — a control that reintroduces the defect it controls for is
    not a control. Its per-line behaviour is instead pinned CASE BY CASE in the
    self-test (blank / whole-line comment / two adjacent comments / unterminated /
    comment-with-trailing-text / text-then-comment), which is the shipped expression's
    behaviour on each of those shapes.

    Never call this outside the self-test. It exists so the suite can prove the
    multi-line cases are load-bearing, by asserting they FAIL when the fix is reverted.
    A test that passes both before and after a fix tests nothing.
    """
    start = None
    for i, line in enumerate(lines):
        # The whole defect, in one argument: the carried state is thrown away.
        residue, still_open = _strip_html_comments(line, False)
        if not still_open and not residue.strip():
            continue
        start = i if line.strip() == FM_DELIM else None
        break
    if start is None:
        return None
    for j in range(start + 1, len(lines)):
        if lines[j].strip() == FM_DELIM:
            return (start, j)
    return None


def _mutation_kill_count_re(cases, rules_fn):
    """Neuter COUNT_RE; return the must-flag cases that STILL report R2-COUNT.

    A non-empty return is a self-test FAILURE. A case that keeps passing when the
    predicate CANNOT MATCH ANYTHING was never testing the predicate — it was testing
    some other rule, or nothing. This is the control that stops the R2-COUNT suite from
    growing cases that assert a verdict the widened vocabulary did not actually produce.
    """
    global COUNT_RE
    live, COUNT_RE = COUNT_RE, NEVER_MATCH_RE
    try:
        return [name for name, text in cases if "R2-COUNT" in rules_fn(text)]
    finally:
        COUNT_RE = live


#: The pre-fix REFERENCE_PREFIX_RE — unanchored word alternatives, so the bare `v`
#: and `g` members matched the tail of any longer word. Kept ONLY as a mutation
#: control; never call it outside the self-test.
_LEGACY_UNANCHORED_REFERENCE_PREFIX_RE = re.compile(
    r"(?:§|§§|stage|gate|check|adr|phase|wave|tier|step|rule|section|part|"
    r"chapter|item|option|qc|v|g)\s*$",
    re.IGNORECASE,
)


def _mutation_revert_reference_prefix(text, rules_fn):
    """Re-evaluate `text` with the PRE-FIX unanchored reference-prefix predicate.

    The third mutation arm. The word-boundary recall cases must be SILENT here: a case
    that reports R2-COUNT both before and after the anchor was never measuring the
    anchor, and the suite would read green over an unrepaired predicate.
    """
    global REFERENCE_PREFIX_RE
    live, REFERENCE_PREFIX_RE = (REFERENCE_PREFIX_RE,
                                 _LEGACY_UNANCHORED_REFERENCE_PREFIX_RE)
    try:
        return rules_fn(text)
    finally:
        REFERENCE_PREFIX_RE = live


def _mutation_revert_frontmatter(text, rules_fn):
    """Re-evaluate `text` with the PRE-REPAIR line-0 frontmatter bound restored.

    The second mutation arm. The comment-first exemption case must FAIL here: if it
    passed on an unrepaired tree, it would be asserting a property the repair did not
    supply, and the whole suite could read green against a broken detector.
    """
    global source_observation_lines
    live, source_observation_lines = (source_observation_lines,
                                      _legacy_line0_source_observation_lines)
    try:
        return rules_fn(text)
    finally:
        source_observation_lines = live


def _mutation_revert_line_scoped_bound(fn):
    """Run `fn()` with the PRE-FIX LINE-SCOPED frontmatter bound restored.

    The third mutation arm, and the one that makes the multi-line cases falsifiable.
    Every consumer resolves the block through the module-global `frontmatter_bounds`,
    so swapping that global reverts the fix for R4, the R2 exemption, and the index
    projector alike — which is precisely the blast radius the shared bound buys.
    """
    global frontmatter_bounds
    live, frontmatter_bounds = (frontmatter_bounds,
                                _legacy_line_scoped_frontmatter_bounds)
    try:
        return fn()
    finally:
        frontmatter_bounds = live


def self_test():
    results = []

    def check(name, ok):
        """ok True = PASS, False = FAIL, None = SKIP (visible, never a silent pass)."""
        results.append((name, ok))

    def rules(text, handle=FIXTURE_HANDLE):
        f, _ = scan_text("fixture.md", text, handle)
        return sorted(set(r for r, _, _ in f))

    CLEAN = (
        "---\n"
        "title: ADR-999 — Fixture\n"
        "status: Accepted\n"
        "deciders: \"operator + Stage 5 spoke\"\n"
        "---\n"
        "\n"
        "# ADR-999 — Fixture\n"
        "\n"
        "## Status\n"
        "\n"
        "Accepted at the Collective Review scope-lock.\n"
    )
    check("clean ADR yields no findings", rules(CLEAN) == [])

    # R1 — a non-enum leading token.
    check("R1 fires on a non-enum status value",
          rules(CLEAN.replace("status: Accepted", "status: Draft")) == ["R1"])
    check("R1 accepts a prose tail after the enum token",
          rules(CLEAN.replace(
              "status: Accepted",
              "status: Proposed (flips to Accepted at the Stage 9 review)")) == [])
    check("R1 accepts an emphasis-wrapped enum token",
          rules(CLEAN.replace("status: Accepted", "status: **Superseded** by ADR-045")) == [])

    # R2-SHA.
    check("R2-SHA fires on a bare commit SHA in prose",
          rules(CLEAN + "\nResolved by commit f0a0516 in the prior release.\n") == ["R2-SHA"])
    check("R2-SHA ignores a pure-decimal run",
          rules(CLEAN + "\nThe identifier 12345678 is not a SHA.\n") == [])
    check("R2-SHA ignores a pure-alpha hex-letter word",
          rules(CLEAN + "\nThe deface facade is prose, not a hash.\n") == [])
    check("R2-SHA is suppressed inside a fenced code block",
          rules(CLEAN + "\n```\ngit show f0a0516\n```\n") == [])
    check("R2-SHA is suppressed by a historical anchor on the line",
          rules(CLEAN + "\nAs of commit f0a0516 the count held.\n") == [])
    check("R2-SHA is suppressed on a frozen (Superseded) record",
          rules(CLEAN.replace("status: Accepted", "status: Superseded by ADR-045")
                + "\nResolved by commit f0a0516.\n") == [])
    check("R2-SHA is suppressed by the per-file override marker",
          rules(CLEAN + "\n<!-- " + OVERRIDE_MARKER + " -->\nCommit f0a0516.\n") == [])

    # R2-COUNT.
    check("R2-COUNT fires on a live corpus count",
          rules(CLEAN + "\nThe platform carries 22 ADR files today.\n") == ["R2-COUNT"])
    check("R2-COUNT ignores a small structural constant",
          rules(CLEAN + "\nThe union has 3 kinds and 2 gates.\n") == [])
    check("R2-COUNT ignores an out-of-vocabulary noun",
          rules(CLEAN + "\nThe table carries 12 columns.\n") == [])
    check("R2-COUNT fires on the '<n> <noun> files' exemplar shape",
          rules(CLEAN + "\nThe corpus holds 22 ADR files.\n") == ["R2-COUNT"])
    # Precision guard (a) — a singular noun after a number is a reference, not a count.
    check("R2-COUNT ignores a singular noun (reference, not population)",
          rules(CLEAN + "\nSee Stage 5 spec section 6 ADR Recommendation.\n") == [])
    # Precision guard (b) — a number glued to '-' or '.' is an identifier segment.
    check("R2-COUNT ignores an identifier-prefixed number",
          rules(CLEAN + "\nADR-076 gates the surface; v3.80 checks ran.\n") == [])
    # Precision guard (c) — a closed set of preceding reference words.
    check("R2-COUNT ignores a reference-word-prefixed number",
          rules(CLEAN + "\nThe Stage 12 gates and the § 9 checks both ran.\n") == [])
    check("R2-COUNT still fires when no reference word precedes",
          rules(CLEAN + "\nThe platform deploys 44 skills.\n") == ["R2-COUNT"])
    check("R2-COUNT is suppressed by a historical anchor",
          rules(CLEAN + "\nAs of authoring there were 22 ADRs.\n") == [])
    check("R2-COUNT is suppressed inside source_observations",
          rules(CLEAN.replace(
              "---\n\n# ADR-999",
              "source_observations:\n  - \"A scan found 22 ADRs stale.\"\n---\n\n# ADR-999")) == [])

    # ── The widened vocabulary, its guard repairs, and the stated recall bound ──
    # Every must-flag case below is enrolled in mutation-kill arm A at the end of this
    # suite; every must-not-flag case is paired with the same-shape positive it must be
    # distinguished from, so neither arm can pass by accident.

    # The bare `<n> files` shape — named in the issue as the confirmed miss, and the
    # single largest miss class in the corpus. Now caught, with its near-miss control.
    check("R2-COUNT fires on bare '<n> files' (no singular population noun precedes)",
          rules(CLEAN + "\nThe corpus holds 8 files today.\n") == ["R2-COUNT"])
    check("R2-COUNT ignores the SAME shape with a fixed-cardinality noun",
          rules(CLEAN + "\nThe table carries 8 columns.\n") == [])
    # The hyphenated-qualifier arm, and the control proving a qualifier does not
    # license an arbitrary head.
    check("R2-COUNT fires through a hyphenated qualifier",
          rules(CLEAN + "\nRelease migration absorbs 11 release-standards.\n") == ["R2-COUNT"])
    check("R2-COUNT does not fire when the qualifier's head is out of vocabulary",
          rules(CLEAN + "\nThe check ran 11 release-blocking times.\n") == [])
    # Guard (b) completed — the two false-positive families the shipped rule carried.
    check("R2-COUNT ignores an alphanumeric-identifier prefix (a shipped false positive)",
          rules(CLEAN + "\nC5 gates every mutation, so a deny-default would break it.\n") == [])
    check("R2-COUNT ignores an issue-reference prefix",
          rules(CLEAN + "\n#1472 lands the fix; #218 owns the framework.\n") == [])
    check("R2-COUNT still fires on the same verb-shaped noun when it IS a population",
          rules(CLEAN + "\nThe release adds 12 gates to the pipeline.\n") == ["R2-COUNT"])
    # Case-insensitive noun match.
    check("R2-COUNT fires on a capitalized population noun",
          rules(CLEAN + "\nThe registry drifted; 7 Hooks are listed.\n") == ["R2-COUNT"])
    # Guard (d) — ceilings only. The symmetric floor words were measured and are
    # deliberately NOT suppressed; this pair is what pins that asymmetry.
    check("R2-COUNT ignores a ceiling ('stay under 500 lines')",
          rules(CLEAN + "\nPer-doc files stay under 500 lines.\n") == [])
    check("R2-COUNT STILL fires on an empirical lower bound (a floor is not a ceiling)",
          rules(CLEAN + "\nThe cycle-prevention grep returned at least 80 matches.\n")
          == ["R2-COUNT"])
    # Thousands separators — the finding must cite the whole number, not its tail.
    _comma = [d for r, _, d in scan_text(
        "fixture.md", CLEAN + "\nThe monolith grew to 1,317 lines.\n",
        FIXTURE_HANDLE)[0] if r == "R2-COUNT"]
    check("R2-COUNT reports a comma-separated number WHOLE, not from its tail",
          len(_comma) == 1 and "1,317 lines" in _comma[0])
    # The two measured historical anchors. Five further candidates were rejected on
    # measurement; "live survey" is retained here as the control that they were.
    check("R2-COUNT is suppressed by the 'at survey baseline' anchor",
          rules(CLEAN + "\nAt survey baseline it lived inline in 8 files.\n") == [])
    check("R2-COUNT is suppressed by the 'audit-baseline' anchor",
          rules(CLEAN + "\nMeasured against audit-baseline state, 8 files carried it.\n") == [])
    check("R2-COUNT is NOT suppressed by a survey METHOD phrase (a method is not a date)",
          rules(CLEAN + "\nThe live survey found 43 skills deployed.\n") == ["R2-COUNT"])

    # The frontmatter-detector repair. Most of the corpus opens with a marker HTML
    # comment rather than `---`, so the provenance exemption must resolve through it.
    COMMENT_FIRST_SRCOBS = (
        "<!-- reference-durability: allow-link -->\n"
        + CLEAN.replace(
            "---\n\n# ADR-999",
            "source_observations:\n  - \"A survey found 44 skills.\"\n---\n\n# ADR-999"))
    check("R2-COUNT is suppressed inside source_observations BEHIND a leading comment",
          rules(COMMENT_FIRST_SRCOBS) == [])
    check("R2-COUNT still fires on the same count in that file's BODY prose "
          "(the exemption is scoped to the block, not the file)",
          rules(COMMENT_FIRST_SRCOBS + "\nThe platform deploys 44 skills.\n") == ["R2-COUNT"])
    check("R2-SHA is likewise suppressed inside a comment-first source_observations block",
          rules("<!-- reference-durability: allow-link -->\n"
                + CLEAN.replace(
                    "---\n\n# ADR-999",
                    "source_observations:\n  - \"Measured at commit f0a0516.\""
                    "\n---\n\n# ADR-999")) == [])

    # ── Mutation-kill controls: the suite proves its own assertions are load-bearing ──
    R2_COUNT_MUST_FLAG = [
        ("bare '<n> files'", CLEAN + "\nThe corpus holds 8 files today.\n"),
        ("hyphenated qualifier",
         CLEAN + "\nRelease migration absorbs 11 release-standards.\n"),
        ("capitalized noun", CLEAN + "\nThe registry drifted; 7 Hooks are listed.\n"),
        ("verb-shaped noun as population", CLEAN + "\nThe release adds 12 gates.\n"),
        ("empirical lower bound",
         CLEAN + "\nThe grep returned at least 80 matches.\n"),
        ("comma-separated number", CLEAN + "\nThe monolith grew to 1,317 lines.\n"),
        ("survey-method phrase", CLEAN + "\nThe live survey found 43 skills deployed.\n"),
        ("scoped-exemption body prose",
         COMMENT_FIRST_SRCOBS + "\nThe platform deploys 44 skills.\n"),
        ("'<n> <noun> files' exemplar", CLEAN + "\nThe corpus holds 22 ADR files.\n"),
        ("live corpus count", CLEAN + "\nThe platform deploys 44 skills.\n"),
    ]
    _survivors = _mutation_kill_count_re(R2_COUNT_MUST_FLAG, rules)
    check("mutation-kill A: every R2-COUNT must-flag case dies under a no-op predicate"
          + ("" if not _survivors else " — SURVIVORS: " + ", ".join(_survivors)),
          _survivors == [])
    check("mutation-kill B: the comment-first exemption case FAILS on the unrepaired "
          "line-0 detector (so it cannot pass vacuously on an unfixed tree)",
          _mutation_revert_frontmatter(COMMENT_FIRST_SRCOBS, rules) == ["R2-COUNT"])

    # R3 — handle blocked everywhere; the carve-out is NAME-scoped, not handle-scoped.
    check("R3 fires on the handle in body prose",
          rules(CLEAN + "\nAuthored by " + FIXTURE_HANDLE + ".\n") == ["R3"])
    check("R3 fires on the handle even on a deciders: line (carve-out is name-scoped)",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "' + FIXTURE_HANDLE + '"')) == ["R3"])
    check("R3 passes the carved-out literal NAME on a deciders: line",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "Ada Lovelace (operator)"')) == [])
    check("R3 does not fire on a handle substring inside a longer token",
          rules(CLEAN + "\nSee " + FIXTURE_HANDLE + "-extended-token here.\n") == [])
    check("R3 is NOT suppressed by the R2 override marker",
          rules(CLEAN + "\n<!-- " + OVERRIDE_MARKER + " -->\nBy " + FIXTURE_HANDLE + ".\n")
          == ["R3"])
    check("R3 is skipped when no handle resolves (never scans nothing silently)",
          rules(CLEAN + "\nAuthored by " + FIXTURE_HANDLE + ".\n", handle=None) == [])

    # R4 — issue refs in identity frontmatter fields. The #NNNNNN tokens below are
    # SYNTHETIC fixture issue numbers, chosen above any live issue in this repo so a
    # fixture can never be mistaken for — or collide with — a real reference. Same
    # discipline as ADR-999 and the synthetic FIXTURE_HANDLE above.
    # A CLEAN fixture that opens with an HTML-comment marker instead of `---`. This is
    # the regression arm: the majority of the shipped corpus opens this way, and a
    # line-0-must-be-`---` bound resolves NOTHING on it.
    COMMENT_FIRST = "<!-- reference-durability: allow-link -->\n" + CLEAN
    check("R4 yields nothing on a clean ADR", rules(CLEAN) == [])
    check("R4 fires on an issue ref in title:",
          rules(CLEAN.replace("title: ADR-999 — Fixture",
                              "title: ADR-999 — Fixture for #999901")) == ["R4"])
    check("R4 fires on an issue ref in release:",
          rules(CLEAN.replace("status: Accepted",
                              "release: some-slug (#999901)\nstatus: Accepted")) == ["R4"])
    check("R4 fires on an issue ref in deciders:",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "operator + Stage 5 spoke (#999901)"')) == ["R4"])
    check("R4 fires THROUGH a leading HTML comment (the comment-first corpus arm)",
          rules(COMMENT_FIRST.replace('deciders: "operator + Stage 5 spoke"',
                                      'deciders: "spoke (#999901)"')) == ["R4"])
    check("R4 counts every token on one identity line",
          len([f for f in scan_text(
              "fixture.md",
              CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                            'deciders: "spoke (#999901) + reviewer (#999902)"'),
              FIXTURE_HANDLE)[0] if f[0] == "R4"]) == 2)
    check("R4 ignores an issue ref in BODY prose (that is the positional rule's job)",
          rules(CLEAN + "\nThe intake ticket #999901 framed the criterion.\n") == [])
    check("R4 ignores an issue ref in source_observations: (the sanctioned home)",
          rules(CLEAN.replace(
              "---\n\n# ADR-999",
              "source_observations:\n  - \"Intake #999901 framed it.\"\n---\n\n# ADR-999")) == [])
    check("R4 ignores a fenced rendering of an identity field",
          rules(CLEAN + "\n```markdown\ndeciders: \"spoke (#999901)\"\n```\n") == [])
    check("R4 ignores a bare number with no '#'",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "operator + Stage 5 spoke 4242"')) == [])
    check("R4 is NOT suppressed by the adr-durability override marker",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "spoke (#999901)"')
                + "\n<!-- " + OVERRIDE_MARKER + " -->\n") == ["R4"])
    check("R4 is NOT suppressed by a repo-integrity issue-ref marker",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "spoke (#999901)"')
                + "\n<!-- repo-integrity: allow-issue" + "-ref -->\n") == ["R4"])
    check("R4 is suppressed on a frozen (Superseded) record",
          rules(CLEAN.replace("status: Accepted", "status: Superseded by ADR-045")
                .replace('deciders: "operator + Stage 5 spoke"',
                         'deciders: "spoke (#999901)"')) == [])
    check("R4 covers a wrapped continuation line of an identity field",
          rules(CLEAN.replace('deciders: "operator + Stage 5 spoke"',
                              'deciders: "operator\n  + Stage 5 spoke (#999901)"')) == ["R4"])
    check("frontmatter_bounds resolves through a leading HTML comment",
          frontmatter_bounds(COMMENT_FIRST.splitlines()) == (1, 5))
    check("frontmatter_bounds returns None when there is no frontmatter",
          frontmatter_bounds(["# Title", "", "prose"]) is None)

    # ── MULTI-LINE leading comment ──────────────────────────────────────────────
    # The CodeQL arm. A leading marker comment that SPANS lines is invisible to any
    # per-line expression, so the bound resolved NOTHING and every consumer silently
    # no-opped — the identical failure the comment-first repair above was built for,
    # one generation on. The mutation arms below prove these cases are load-bearing.
    MULTI_COMMENT_FIRST = ("<!-- reference-durability: allow-link\n"
                           "     and the marker spans a second line -->\n" + CLEAN)
    MULTI_COMMENT_THREE = ("<!-- a\n b\n c -->\n" + CLEAN)
    # HTML comments do not nest, but one line may CLOSE a span and OPEN another.
    CLOSE_THEN_OPEN = ("<!-- first --> <!-- second\n still second -->\n" + CLEAN)
    check("frontmatter_bounds resolves through a MULTI-LINE leading HTML comment",
          frontmatter_bounds(MULTI_COMMENT_FIRST.splitlines()) == (2, 6))
    check("frontmatter_bounds resolves through a THREE-line leading HTML comment",
          frontmatter_bounds(MULTI_COMMENT_THREE.splitlines()) == (3, 7))
    check("frontmatter_bounds handles a line that closes one comment and opens another",
          frontmatter_bounds(CLOSE_THEN_OPEN.splitlines()) == (2, 6))
    check("frontmatter_bounds returns None on a comment left UNTERMINATED at EOF",
          frontmatter_bounds("<!-- never closed\nstill inside\n".splitlines()) is None)
    check("frontmatter_bounds still refuses PROSE before the delimiter",
          frontmatter_bounds(("prose\n" + CLEAN).splitlines()) is None)
    check("R4 fires THROUGH a MULTI-LINE leading HTML comment (consumer arm)",
          rules(MULTI_COMMENT_FIRST.replace('deciders: "operator + Stage 5 spoke"',
                                            'deciders: "spoke (#999901)"')) == ["R4"])
    # Mutation arms. Each case above must FAIL against the pre-fix line-scoped bound;
    # a case that passes on an unrepaired tree asserts a property the fix did not supply.
    check("MUTATION: the multi-line bound FAILS on the pre-fix line-scoped expression",
          _mutation_revert_line_scoped_bound(
              lambda: frontmatter_bounds(MULTI_COMMENT_FIRST.splitlines())) is None)
    check("MUTATION: the close-then-open bound FAILS on the pre-fix expression",
          _mutation_revert_line_scoped_bound(
              lambda: frontmatter_bounds(CLOSE_THEN_OPEN.splitlines())) is None)
    check("MUTATION: R4 goes SILENT through a multi-line comment on the pre-fix bound",
          _mutation_revert_line_scoped_bound(
              lambda: rules(MULTI_COMMENT_FIRST.replace(
                  'deciders: "operator + Stage 5 spoke"',
                  'deciders: "spoke (#999901)"'))) == [])
    # Specificity control: the single-line form 70 of the shipped corpus depends on
    # must resolve IDENTICALLY under both bounds. If this ever diverges, the fix has
    # widened past the defect it was built for.
    check("SPECIFICITY: single-line comment resolves identically under both bounds",
          frontmatter_bounds(COMMENT_FIRST.splitlines())
          == _mutation_revert_line_scoped_bound(
              lambda: frontmatter_bounds(COMMENT_FIRST.splitlines()))
          == (1, 5))
    check("SPECIFICITY: a bare `---` opening resolves identically under both bounds",
          frontmatter_bounds(CLEAN.splitlines())
          == _mutation_revert_line_scoped_bound(
              lambda: frontmatter_bounds(CLEAN.splitlines()))
          == (0, 4))
    # `_strip_html_comments` unit arms — the state machine's own contract.
    check("_strip_html_comments carries an OPEN comment across a line boundary",
          _strip_html_comments("<!-- open", False) == ("", True))
    check("_strip_html_comments closes a carried comment and returns the residue",
          _strip_html_comments("tail --> rest", True) == (" rest", False))
    check("_strip_html_comments treats a nested `<!--` as comment TEXT (no nesting)",
          _strip_html_comments("<!-- a <!-- b --> c", False) == (" c", False))
    check("_strip_html_comments leaves a comment-free line untouched",
          _strip_html_comments("plain text", False) == ("plain text", False))
    # The MUTATION CONTROL'S OWN contract. It is written as a state-discarding scan
    # rather than as a copy of the flagged expression, so its fidelity to that
    # expression is pinned here, shape by shape. Each pair is (leading line, does the
    # pre-fix bound still find the `---` beneath it?) — exactly what the shipped
    # regex answered on that shape. If a row here ever moves, the control has stopped
    # reproducing the defect and every mutation arm above is asserting nothing.
    _LEGACY_SHAPES = (
        ("", True),                          # blank line
        ("   ", True),                       # whitespace only
        ("<!-- marker -->", True),           # whole-line comment — the corpus shape
        ("<!-- a --> <!-- b -->", True),     # two adjacent CLOSED comments
        ("<!-- unterminated", False),        # the defect: comment spans the boundary
        ("<!-- a --> trailing", False),      # comment then text
        ("leading <!-- a -->", False),       # text then comment
    )
    for _lead, _finds in _LEGACY_SHAPES:
        check("LEGACY-CONTROL fidelity: %r -> %s"
              % (_lead, "resolves" if _finds else "gives up"),
              (_legacy_line_scoped_frontmatter_bounds(
                  ([_lead] + CLEAN.splitlines())) is not None) == _finds)

    # Delta posture — a finding on an unchanged line is not re-flagged.
    dirty = CLEAN + "\nCommit f0a0516 did it.\n"
    f_all, _ = scan_text("fixture.md", dirty, FIXTURE_HANDLE)
    f_delta, _ = scan_text("fixture.md", dirty, FIXTURE_HANDLE, allowed_lines=set([1]))
    check("added-lines filter suppresses a finding outside the delta",
          len(f_all) == 1 and f_delta == [])

    # Real-tree smoke: the checker resolves the shipped ADR dirs.
    with tempfile.TemporaryDirectory() as tmp:
        os.makedirs(os.path.join(tmp, "core", "ADRs"))
        with open(os.path.join(tmp, "core", "ADRs", "ADR-001-x.md"), "w") as fh:
            fh.write(CLEAN)
        check("collect_adrs finds ADR-shaped files under the ADR dirs",
              len(collect_adrs(tmp, None)) == 1)
        check("collect_adrs ignores non-ADR filenames",
              collect_adrs(tmp, ["core/ADRs/README.md"]) == [])

    # ── R5 STRUCT — delta-scoped structural conformance ──────────────────────────
    # The full §3 set, plus a deliberately-noisy shape: an out-of-position section, an
    # H3 sub-heading beneath a canonical H2, and an EXTRA H2. All three must pass, or
    # R5 is asserting position / heading-count / a closed vocabulary rather than
    # presence — the three things the SCOPE block says it must not assert.
    FULL = (
        "---\n"
        "title: ADR-999 — Fixture\n"
        "status: Accepted\n"
        "---\n"
        "\n# ADR-999 — Fixture\n"
        "\n## Status\n\nAccepted.\n"
        "\n## Context\n\nx\n"
        "\n## Decision\n\nx\n"
        "\n## Consequences\n\nx\n"                    # DELIBERATELY before Alternatives
        "\n## Alternatives Considered\n\nx\n"          # position 5, not 4 — 27 live records
        "\n### Decision 1 alternatives\n\nx\n"         # legitimate H3 beneath the H2
        "\n## Reversibility\n\nCHEAP\n"
        "\n## Related ADRs\n\nnone\n"
        "\n## References\n\n- #999902 — an extra section, legal under §3.1\n"
    )

    def struct_rules(head_text, base_text, is_new):
        f, _ = scan_text("fixture.md", head_text, FIXTURE_HANDLE,
                         struct={"is_new": is_new, "base_text": base_text})
        return sorted(set(r for r, _, _ in f if r.startswith("R5")))

    check("R5 passes a conformant NET-NEW record",
          struct_rules(FULL, None, True) == [])
    check("R5 passes despite an out-of-position section, an H3 sub-heading and an "
          "extra H2 — presence, not position or heading-count",
          struct_rules(FULL, None, True) == [])
    check("R5-NEW fires on a net-new record missing `## Alternatives Considered`",
          struct_rules(FULL.replace("## Alternatives Considered", "## Options considered"),
                       None, True) == ["R5-NEW"])
    check("R5-NEW fires on a net-new record missing `## Reversibility`",
          struct_rules(FULL.replace("## Reversibility", "## Rollback"), None, True)
          == ["R5-NEW"])
    check("R5-NEW does NOT fire on an H3-only section (the H2 string is the assertion)",
          struct_rules(FULL.replace("## Reversibility", "### Reversibility"), None, True)
          == ["R5-NEW"])
    check("R5-NEW does not fire on a section that only appears inside a fence",
          struct_rules(FULL.replace("## Related ADRs\n\nnone\n",
                                    "```\n## Related ADRs\n```\n"), None, True)
          == ["R5-NEW"])
    # THE POPULATION-EMPTINESS ARM. A pre-existing gap on a merely-CHANGED record must
    # stay silent, or the rule re-creates the guarding-before-cleaning hazard that got
    # a whole-corpus structural rule rejected. 29 of 111 live records are in this class.
    GAPPY = FULL.replace("\n## Related ADRs\n\nnone\n", "\n")
    check("R5 stays SILENT on a pre-existing gap in a merely-CHANGED record",
          struct_rules(GAPPY + "\nOne more line.\n", GAPPY, False) == [])
    check("R5-LOST fires when a change REMOVES a section the base carried",
          struct_rules(GAPPY, FULL, False) == ["R5-LOST"])
    check("R5 stays SILENT on a changed record that ADDS a section",
          struct_rules(FULL, GAPPY, False) == [])
    check("R5 is inert without a struct delta (no --diff-base)",
          [r for r in rules(GAPPY) if r.startswith("R5")] == [])
    check("R5 is inert on a FROZEN record — it can never conform, by policy",
          struct_rules(GAPPY.replace("status: Accepted", "status: Superseded by ADR-045"),
                       FULL, False) == [])
    check("R5 is NOT suppressed by the durability override marker (structure is not "
          "durability)",
          struct_rules(GAPPY.replace("# ADR-999 — Fixture",
                                     "<!-- " + OVERRIDE_MARKER + " -->\n# ADR-999 — Fixture"),
                       FULL, False) == ["R5-LOST"])

    # ── REFERENCE_PREFIX_RE word boundary ────────────────────────────────────────
    # The measured recall defect: an unanchored single-letter alternative matched the
    # TAIL of a longer word, silently demoting a live count to an ordinal reference.
    # Both arms, because a suppression guard that suppresses nothing is not a guard.
    # End-to-end: a VERBATIM live-corpus line that the unanchored form suppressed.
    check("R2-COUNT fires on a count preceded by a word ENDING in `g` (the recall gap)",
          rules(CLEAN + "\nThe change would require adding 24 cross-references.\n")
          == ["R2-COUNT"])
    # MUTATION KILL — the case above must be SILENT against the pre-fix predicate, or
    # it is a probe that passes before and after the repair and therefore measures
    # nothing. This is the same broken-probe signature the R2-COUNT and frontmatter
    # arms already guard against.
    check("mutation-kill C: the recall case is SILENT on the unanchored predicate (so "
          "the word boundary is what makes it pass, not the fixture)",
          _mutation_revert_reference_prefix(
              CLEAN + "\nThe change would require adding 24 cross-references.\n", rules)
          == [])

    # Predicate-level, both directions. Prose cases for the `v` arm are contrived —
    # few English words end in v — so the guard is asserted on the predicate itself.
    check("the boundary stops a match on the tail of a word ending in `g`",
          not REFERENCE_PREFIX_RE.search("would require adding "))
    check("the boundary stops a match on the tail of a word ending in `v` (e.g. CSV)",
          not REFERENCE_PREFIX_RE.search("rows in the exported CSV "))
    check("the standalone single-letter reference tokens still suppress",
          bool(REFERENCE_PREFIX_RE.search("see v "))
          and bool(REFERENCE_PREFIX_RE.search("see g ")))
    check("R2-COUNT is still suppressed after a GENUINE standalone reference word",
          rules(CLEAN + "\nSee Stage 6 files and § 9 checks and ADR 12 skills.\n") == [])
    check("the section-symbol arm survives the word-boundary anchor",
          bool(REFERENCE_PREFIX_RE.search("as recorded in § ")))

    # Section-set citation drift — the standard vs. this lint's cited copy. This is the
    # assertion that makes "no drift between the standard and its linter" mechanical:
    # edit §3 without updating DOC_SECTION_SET (or the reverse) and this case fails.
    schema_set = parse_schema_section_set(repo_root_from_file())
    check("DOC_SECTION_SET still equals adr-schema.md §3 (membership AND order)"
          + ("" if schema_set is not None
             else " — SCHEMA DID NOT RESOLVE, citation NOT verified"),
          None if schema_set is None else schema_set == DOC_SECTION_SET)

    failed = [n for n, ok in results if ok is False]
    skipped = [n for n, ok in results if ok is None]
    for name, ok in results:
        print(("  PASS  " if ok is True
               else "  SKIP  " if ok is None
               else "  FAIL  ") + name)
    summary = ("check-adr-durability self-test: %d/%d passed"
               % (len(results) - len(failed) - len(skipped), len(results)))
    if skipped:
        summary += " (%d SKIPPED — visible, not silently green)" % len(skipped)
    print(summary)
    return 1 if failed else 0


# ── main ─────────────────────────────────────────────────────────────────────

def main():
    ap = argparse.ArgumentParser(
        description="ADR durability lint (status enum / SHAs + counts / handle / "
                    "issue refs in identity frontmatter).")
    ap.add_argument("--root", default=".", help="repo root")
    ap.add_argument("--files", nargs="*", default=None,
                    help="explicit ADR paths (default: the whole ADR corpus)")
    ap.add_argument("--handle", default=None,
                    help="operator GitHub handle for R3; derived from the origin remote "
                         "owner when omitted. NEVER hardcoded in this file.")
    ap.add_argument("--diff-base", default=None,
                    help="restrict findings to lines ADDED since this ref (net-new "
                         "posture), and ACTIVATE the delta-scoped structural rule R5. "
                         "Without it R5 reports a visible SKIP rather than reading green.")
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = os.path.abspath(args.root)
    paths = collect_adrs(root, args.files)
    if not paths:
        if args.files:
            # An explicit list with no ADR members is a legitimate empty scan.
            print("SCANNED\t0")
            print("COUNT\t0")
            return 0
        print("ERROR\tno ADR files resolved under %s — the ADR tree may have moved"
              % ", ".join(ADR_DIRS), file=sys.stderr)
        return 3

    out = []
    handle = derive_handle(args.handle)
    if not handle:
        out.append("CONFIG\tR3 SKIPPED — operator handle unresolved (pass --handle or "
                   "run inside a clone with an origin remote); the handle dimension "
                   "scanned nothing")

    delta = added_line_map(args.diff_base, paths, root) if args.diff_base else {}
    base_blobs = base_blob_map(args.diff_base, paths, root) if args.diff_base else None
    if base_blobs is None:
        out.append("CONFIG\tR5 SKIPPED — no --diff-base, so the structural rule has no "
                   "delta to scope to; the structural dimension scanned nothing. R5 is "
                   "delta-only BY DESIGN (see the SCOPE block): a whole-corpus "
                   "structural rule would fire on records the conformance sweep "
                   "deliberately did not reach.")

    findings = []
    for p in paths:
        try:
            with open(p, "r", encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError as exc:
            out.append("CONFIG\tunreadable: %s (%s)" % (p, exc))
            continue
        allowed = delta.get(p) if args.diff_base else None
        struct = None
        if base_blobs is not None:
            is_new, base_text = base_blobs.get(p, (False, None))
            struct = {"is_new": is_new, "base_text": base_text}
        f, exempt = scan_text(p, text, handle, allowed_lines=allowed, struct=struct)
        rel = os.path.relpath(p, root)
        if exempt:
            out.append("EXEMPT\t%s\t%s" % (rel, exempt))
        for rule, lineno, detail in f:
            findings.append((rule, rel, lineno, detail))

    out.insert(0, "SCANNED\t%d" % len(paths))
    for rule, rel, lineno, detail in findings:
        out.append("%s\t%s:%d\t%s" % (rule, rel, lineno, detail))
    out.append("COUNT\t%d" % len(findings))
    print("\n".join(out))
    return 1 if findings else 0


if __name__ == "__main__":
    sys.exit(main())
