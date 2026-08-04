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

SCOPE — WHAT THIS LINT DOES NOT CHECK
-------------------------------------
This lint governs ADR *durability* (the rules above). It does NOT check *structural
section conformance* — whether an ADR carries the required body sections at all. The
canonical section set is DEFINED once, in `core/schemas/adr-schema.md` §3; this file
only CITES it (see DOC_SECTION_SET below) and enforces nothing about it.

Structural conformance is unenforced BY DESIGN, pending the ADR corpus's full
structural-conformance pass. An enforcing structural rule over a corpus that is still
mid-remediation is the same guarding-before-cleaning hazard the WARN-MODE note below
describes, wearing a different hat.

The consequence, stated so that no reader has to infer it: a GREEN run of this lint
does NOT mean the scanned ADRs are structurally conformant. It means they carry no
durability violation. Those are different claims.

`--self-test` asserts that DOC_SECTION_SET still equals the schema's §3 table, so the
citation cannot drift from the standard without a test failing. When the schema does
not resolve (running outside a clone), that case reports a visible SKIP rather than
passing silently — the same "never read green on a scan that examined nothing"
discipline R3 applies to an unresolved handle.

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
     most of the corpus; an earlier line-0-anchored form resolved NOTHING on those
     files, so this exemption silently no-opped on a majority of the corpus and
     reported policy-exempt evidence as a violation. See `source_observation_lines()`.
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

  NOT ADMITTED — three named classes, each a deliberate choice, not an oversight:
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
REFERENCE_PREFIX_RE = re.compile(
    r"(?:§|§§|stage|gate|check|adr|phase|wave|tier|step|rule|section|part|"
    r"chapter|item|option|qc|v|g)\s*$",
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
# Frontmatter parsing. A line that is blank, or is nothing but a whole-line HTML
# comment, may PRECEDE the opening `---`.
FM_SKIP_RE = re.compile(r"^\s*(?:<!--.*?-->)?\s*$")
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


def frontmatter_bounds(lines):
    """(start, end) 0-based indices of the LEADING `---` frontmatter block, or None.

    TOLERATES blank lines and whole-line HTML comments before the opening delimiter.
    That tolerance is load-bearing, not cosmetic: a majority of the shipped ADR corpus
    opens with a durability or repo-integrity marker comment rather than with `---`, so
    a detector that requires line 0 to be `---` silently resolves NOTHING on those
    files — it returns "no frontmatter" instead of "frontmatter I could not parse", and
    a caller cannot tell the two apart.

    This is the SHARED bound: `identity_field_findings()` (R4) and
    `source_observation_lines()` (the R2 provenance exemption) both resolve through it,
    so the two rules can never disagree about where an ADR's frontmatter begins.
    """
    start = None
    for i, line in enumerate(lines):
        if FM_SKIP_RE.match(line):
            continue
        start = i if line.strip() == FM_DELIM else None
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


def scan_text(path, text, handle, allowed_lines=None):
    """Evaluate one ADR's text. Returns (findings, exempt_reason_or_None).

    findings — list of (rule, line_no_1based, detail).
    allowed_lines — when not None, only these 1-based line numbers may yield a
                    finding (the net-new added-lines delta posture).
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
                    help="restrict findings to lines ADDED since this ref (net-new posture)")
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

    findings = []
    for p in paths:
        try:
            with open(p, "r", encoding="utf-8", errors="replace") as fh:
                text = fh.read()
        except OSError as exc:
            out.append("CONFIG\tunreadable: %s (%s)" % (p, exc))
            continue
        allowed = delta.get(p) if args.diff_base else None
        f, exempt = scan_text(p, text, handle, allowed_lines=allowed)
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
