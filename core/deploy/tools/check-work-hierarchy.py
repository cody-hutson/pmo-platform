#!/usr/bin/env python3
"""check-work-hierarchy.py — work-hierarchy drift detector (#1039, deploy.sh Check 55).

Asserts three invariants that together keep the work hierarchy from silently
re-fragmenting after the T1/T2 SSOT cutover:

  H1 — DOC invariant (offline; always runs)
       No normative governance doc ASSERTS a work-item parent tier naming a token
       outside the licensed work-item-kind vocabulary. The licensed vocabulary is
       DERIVED from the SSOT (`core/packs/*/pack.toml` `kind_id` rows) — it is never
       hardcoded here. The concrete class #1039 names is `Initiative`/`Roadmap`
       asserted as the parent of `Epic`.

  H2 — BACKLOG invariant (needs `gh`; SKIPs offline)
       No open `type:epic` issue has a `type:epic` parent (the epic-under-epic edge).
       Resolved via ONE batched+paginated GraphQL query over the native sub-issue
       `parent` edge — never an N+1 per-epic loop (with ~39 open epics an N+1 shape
       would materially slow `deploy.sh --check`).

  H3 — INITIATIVE-COEXTENSION invariant (ADVISORY; rides H2's fetch)
       No open `type:epic` issue is really an INITIATIVE CONTAINER — an issue whose
       scope is coextensive with a whole `project:` family rather than with one
       thrust inside it. An initiative is a `project:` LABEL plus an operator-local
       roadmap, never a standalone issue (ADR-049; label-taxonomy.md § Initiative
       Labels), so a container materialized as an epic has no correct tier to sit at.
       H2 cannot see this class: these containers carry NO epic-parent edge — that
       is exactly why they were never caught.

       REPORT-ONLY, ALWAYS. H3 findings are EXCLUDED from the exit-code total and
       can never fail `deploy.sh --check` in any mode. See ADR-132.

WHY H3 IS A CONJUNCTION, AND WHY NO LIMB MAY BE DROPPED
------------------------------------------------------
The obvious predicate — "an epic sharing a `project:` label with N other open epics
that are not its children" — was implemented and MEASURED against the live tracker:
it flags 39 of 42 open epics (92.9%). The reason is structural, not a threshold to
tune: the family shape is SYMMETRIC. A leaf epic inside a family shares its label
with the same non-children the container does, so every leaf is a false positive by
construction. Raising N cannot fix a symmetric predicate.

H3 is therefore a three-way conjunction over that family shape:

  C3 family     |F| >= 2, where F = { OPEN type:epic carrying the same `project:` P }
                minus E itself minus E's native sub-issue children.
  C4 coextension  every token of P's slug appears in E's normalized TITLE HEAD
                (lowercased, a leading `[Epic]` stripped, truncated at the first
                em-dash or ` - `, tokenized on non-alphanumerics). A container names
                the whole domain; a thrust names its own thrust.
  C5 fan-out    E's BODY references at least 2 distinct members of F. A container
                enumerates its family; a sibling cites one or two neighbours.

Measured on the live population at design time: C3 alone 39 flagged, C4 alone 4,
C5 alone 6 — the conjunction, 2, with ZERO false positives across seven named
near-miss classes. No limb is decorative; dropping any one restores an over-fire.

THE LEXICAL LIMB IS A KNOWN, CONTAINED EXCEPTION
------------------------------------------------
C4 is LEXICAL, which is a partial exception to this file's stated predicate-design
principle below ("structural membership, not prose similarity"). It was accepted
deliberately, on three containments that are part of the decision and must not be
removed independently of it:
  (i)   the leg is ADVISORY — it cannot gate, in warn OR enforce mode;
  (ii)  the exemption file takes an H3 entry form (`#<issue> initiative-coextension`);
  (iii) every H3 row EMITS ITS OWN EVIDENCE — the matched slug tokens and the
        in-family references — so an operator can falsify a finding in one read.
Renaming an epic changes C4's verdict, and a single-token slug weakens it. Both are
tolerable precisely because the leg reports and never blocks.

PREDICATE DESIGN (why this shape, not prose similarity)
------------------------------------------------------
H1 asserts CLOSED-VOCABULARY MEMBERSHIP inside a STRUCTURAL hierarchy expression,
not NLP-shaped prose similarity. A finding requires an actual arrow-chain
(`Parent → Child`) whose RIGHT side is a licensed kind and whose LEFT side is a
BANNED TIER TOKEN. That is falsifiable, has no paraphrase false-positive tail, and
degrades to ZERO findings (never garbage) if the SSOT vocabulary is unreadable — in
which case the check FAILS LOUD (exit 3) rather than reading green.

WHY A CLOSED BANNED-SET, NOT "ANY TOKEN OUTSIDE THE KIND VOCABULARY"
--------------------------------------------------------------------
The broader form ("flag any unlicensed token in parent position") was implemented
first and measured against the live corpus: it produced 8 findings, ALL 8 false
positives. The corpus legitimately carries several NON-work-item ladders whose
child rung is a licensed kind name:

  * the KM **altitude ladder** `Unit -> Task -> Workstream -> ...`
    (knowledge-architecture.md — an explicitly ALIASED vocabulary, reconciled on
    purpose, and the doc at :325 is the record of that reconciliation);
  * the **SAFe row** of the Layer-2 hierarchy-by-methodology map
    `Capability -> Feature -> Story / Enabler` (work-organization-mapping-framework.md
    — the SSOT surface itself, where non-canonical tier names are the POINT);
  * the ADR-018 **methodology->kind projection** `Issue -> Story / Task`.

Flagging the SSOT map for containing methodology tier names is incoherent. The
predicate is therefore narrowed to the exact class #1039 names — `Initiative` /
`Roadmap` asserted as a parent tier — which is a CLOSED, ADR-RECORDED set (below).

CASE SENSITIVITY IS LOAD-BEARING
--------------------------------
Matching is CASE-SENSITIVE Title-Case on both sides. The corpus Title-Cases
hierarchy TIER names (`Initiative -> Epic`) and lowercases LABEL-NAMESPACE tokens
(`initiative->epic`, the ADR-049 label mapping). Without case sensitivity the
check flags ADR-049's own title — an ADR about label mapping — as a hierarchy
violation. Three of the eight measured false positives were exactly that.

CITATION GUARD (structural, not semantic)
-----------------------------------------
A hierarchy chain enclosed in quotes or backticks is being CITED or NEGATED, not
asserted. The live corpus contains exactly this case:

    architecture-evaluative-lens.md:45
    It does **not** use the shorthand "Roadmap -> Epic -> Story/Task -> Subtask"

That sentence states the rule CORRECTLY — flagging it would be a false positive on
the very doc that most clearly asserts the canonical ladder. The guard is a LEXICAL
test (is the match inside a quoted span on its line?), deliberately NOT a negation
parser: negation detection is the NLP-shaped predicate this design rejects.

EXEMPTION
---------
`.claude/work-hierarchy-exemption-list.txt` — one entry per line, mirroring
Check 16's `exempt_pair` shape. Operator escape hatch for anything the citation
guard does not cover (e.g. a superseded ADR narrating an old hierarchy), and
#1039's "allowlist-able during cutover" requirement.

  H1   <path> <token>         e.g. `core/disciplines/foo.md initiative`
  H2   #<issue> <token>       e.g. `#242 type:epic`   (bare `242 type:epic`
                              is accepted too — both normalize to one key)
  H3   #<issue> initiative-coextension
                              e.g. `#160 initiative-coextension` — the operator's
                              "reviewed, this container is intentional" record. The
                              token is FIXED (not the issue's `project:` label), so
                              an exemption survives a relabel; the bare form
                              normalizes identically to H2's.

`#` still starts a comment EXCEPT when it is immediately followed by digits and
then whitespace, which is the H2 entry shape. Both must hold: with a blanket
comment filter the documented H2 form is swallowed as a comment, and without key
normalization the bare form loads under a key the lookup never produces — that
combination shipped once and made the H2 escape hatch unreachable by ANY string
while its self-test still read green. The self-test now round-trips a real file
through load_exemptions (with negative cases), so a regression here fails.

OUTPUT (TSV) / EXIT CODES
-------------------------
  VOCAB     <comma-list>          the licensed kinds derived from the SSOT
  SCANNED   <n>                   normative .md files scanned by H1
  H1        <path>:<line>  <text> a doc asserting an unlicensed parent tier
  H2        <issue>  <parent>     an epic whose parent is also an epic
  H3        <issue>  <project-label>  <slug-tokens>  <refs-into-family>
                                  an epic reading as an initiative container, WITH
                                  the evidence that fired it (advisory)
  EXEMPT    <leg>  <detail>       suppressed by the exemption list
  SKIP      H1  <reason>          a configured scan surface that does not resolve
  SKIP      H2  <reason>          gh unavailable / unauthenticated
  SKIP      H3  <reason>          the coextension leg was not evaluated
  COUNT_H3  <n>                   H3 findings — emitted ONLY when the leg actually
                                  ran, and DELIBERATELY separate from COUNT. A
                                  skipped leg emits `SKIP H3` and NO COUNT_H3 row,
                                  so "not evaluated" can never be read as "zero".
  COUNT     <n>                   total non-exempt findings — H1 + H2 ONLY. H3 is
                                  excluded BY CONSTRUCTION: an advisory leg that
                                  moved the exit code would gate.

  exit 0 — clean (no H1/H2 findings; H3 findings may still be present and reported)
  exit 1 — H1/H2 findings present
  exit 3 — input failure (SSOT vocabulary unreadable / zero kinds / PARTIALLY parsed
           — fewer kind_id rows read than the packs declare; GraphQL error;
           EVERY configured H1 scan surface unresolved — an empty scan population;
           an epic node set that lacks H3's field triple — see below)

THE H3 ANTI-VACUITY CONTROL (why a missing field is exit 3, not zero findings)
-----------------------------------------------------------------------------
H2 reads only `node["parent"]`, so a `--fixture-parent-map` file written for H2
legitimately carries nothing else. H3 reads `labels`, `title` and `body`. Run H3
against such a fixture and its population is STRUCTURALLY EMPTY: every specificity
assertion returns a VACUOUS zero and passes for the wrong reason — the same shape as
a scan whose baseline silently resolved to `{}`. So a node set missing the H3 field
triple is an INPUT FAILURE (exit 3) with the missing fields named, never `COUNT_H3 0`.
A genuinely EMPTY node set is different — a repo may legitimately have no open epics
— and emits `SKIP H3` rather than a zero, for the same reason.

Python 3.9-compatible (no tomllib, no 3.10+ syntax) — matches /usr/bin/python3 on
the operator baseline.
"""

import argparse
import json
import os
import re
import subprocess
import sys
import tempfile

# ── SSOT: licensed work-item-kind vocabulary ────────────────────────────────
# Derived from core/packs/*/pack.toml `kind_id` rows. Regex-parsed rather than
# tomllib-parsed: the operator baseline is Python 3.9 (tomllib is 3.11+).
KIND_ID_RE = re.compile(r'^\s*kind_id\s*=\s*"([a-z0-9][a-z0-9_-]*)"\s*$', re.M)

# STRUCTURAL CONTROL on the regex parse above — the pack file's own shape used as
# the check on how much of it was read. `KIND_ID_RE` is line-anchored, double-quote
# only, and permits no trailing content (deliberately: there is no TOML parser
# behind it, because the operator baseline is Python 3.9). Every one of those
# constraints is a way for a VALID pack file to be under-read, and under-reading
# was silent: the only alarm was the empty-set guard, which fires at zero and
# nowhere else. Measured degraded arms, all returning exit 0 before this control
# existed: an unreadable `scrum/pack.toml` yielded `['card']` (3 of 4 kinds lost);
# `kind_id = "story"  # comment` — valid TOML — dropped `story`; `kind_id = 'epic'`
# — valid TOML — dropped `epic`. One pack declares 3 of the 4 live kinds, so a
# single file loss removes 75% of the vocabulary while the resolver reports success.
#
# Each `[[kinds]]` array-of-tables header declares exactly one kind, so the header
# count is the expected `kind_id` count for that file. A SHORTFALL (fewer rows
# parsed than tables declared) is therefore positive evidence of a partial parse,
# and it needs no TOML parser to compute. The test is deliberately one-sided:
# a surplus means a `kind_id` outside a `[[kinds]]` table, which is a different
# anomaly and never a dropped kind, so it does not trip the fail-loud arm.
KINDS_TABLE_RE = re.compile(r'^[ \t]*\[\[kinds\]\][ \t]*$', re.M)

# A hierarchy arrow: →, ->, >, » (the shapes the corpus actually uses).
ARROW = r'(?:→|->|>|»)'

# BANNED PARENT TIERS — the closed set of tokens that must never appear as a
# work-item parent tier. This is a GOVERNANCE DECISION, cited not re-derived:
#
#   ADR-049 §Decision 1 — "Canonical `Initiative` = a multi-milestone grouping
#   theme; NOT a hierarchy level ... never a container tier or a `parent_ref`
#   target." Its Context records the work-hierarchy SSOT levels (Portfolio →
#   Program → Project → Milestone/Workstream → Work Item) and states they
#   "exclude Initiative as a level".
#   ADR-049 §Decision 2 — `Roadmap` = "an architected path across milestones",
#   a Program-altitude projection, likewise not a container tier.
#
# Deliberately DECLARED here rather than parsed from ADR prose: the banned set is
# a stable, ADR-recorded decision (prose-parsing it would be the NLP-shaped
# predicate this design rejects), whereas the LICENSED KIND vocabulary churns with
# the packs and IS derived from the SSOT at runtime. Extend this set only when a
# new ADR bans a further tier token.
BANNED_PARENT_TIERS = ("Initiative", "Roadmap")

# Quoted / code spans on a line — a chain inside one of these is CITED, not asserted.
#
# The straight-apostrophe alternation is BOUNDARY-ANCHORED. An unanchored
# `'[^']*'` makes a POSSESSIVE open a span: `The platform's hierarchy is
# Initiative -> Epic and that's wrong` yields one 44-char "quote" that swallows the
# whole assertion, so H1 never evaluates it. Measured on this corpus when the fix
# landed, the unanchored form masked 299,294 characters across 1,659 lines —
# 15.1% of the guard's ENTIRE suppression surface — because 11,665 word-position
# apostrophes appear across 637 of the 727 scanned files. That is the default
# English sentence, not an exotic shape.
#
# The lookaround pair requires a NON-alphanumeric on each outer side, which a
# possessive or a contraction never has. The inner `'(?=[0-9A-Za-z])` allowance
# lets a contraction sit INSIDE a genuine quoted span (`'Don't be too verbose'`)
# without ending it. The two inner branches are mutually exclusive on their first
# character, so the star is deterministic — no backtracking blowup (measured
# 0.0002s on a 4KB unterminated-quote line).
#
# Do NOT "simplify" this by deleting the alternation: 621 genuine single-quoted
# spans in this corpus (shell/regex/glob literals — `'*.json'`, `'s/^# //'`) depend
# on it, and dropping it scores no better than the unanchored form it replaces
# (both 8/12 on the self-test's recall/precision matrix; this form scores 12/12).
# Do NOT add a smart-single-quote alternation: U+2019 IS the typographic
# apostrophe, so it would reintroduce this exact bug.
QUOTE_SPAN_RE = re.compile(
    r'"[^"]*"'
    r'|“[^”]*”'
    r'|`[^`]*`'
    r"|(?<![0-9A-Za-z])'(?:[^']|'(?=[0-9A-Za-z]))*'(?![0-9A-Za-z])"
)

# Normative surfaces H1 scans — all three platform modules. release/releases/ is
# EXCLUDED: it is the archival + generated release corpus (plans, notes, logs),
# which legitimately narrates historical hierarchies and is not a normative
# assertion surface. `operations/` carries NO such archival subtree — its .md files
# are skill definitions, references, and templates, every one of them a normative
# agent-facing surface, so a hierarchy restatement there binds agent behavior
# exactly as one in `core/` does. It is scanned.
DEFAULT_SCAN_ROOTS = ("core", "release", "operations")
EXCLUDED_PREFIXES = (os.path.join("release", "releases"),)
# The repo root carries NO CLAUDE.md — the governed surface is the TEMPLATE that
# deploys to it. The tree walk cannot reach it: its filter is `fn.endswith(".md")`
# and `.md.template` fails that test, so before this entry the CLAUDE surface was
# scanned ZERO times, not incidentally. EXTRA_SCAN_FILES bypasses the suffix filter
# by design (it yields an explicit path), which is why naming it here works.
EXTRA_SCAN_FILES = (os.path.join("core", "CLAUDE.md.template"),)

EXEMPT_FILE_DEFAULT = os.path.join(".claude", "work-hierarchy-exemption-list.txt")

# ── H3: initiative-coextension ──────────────────────────────────────────────
# The initiative namespace. `epic:*` is DELIBERATELY not included: per
# label-taxonomy.md § Initiative Labels it groups thrusts *inside* one project
# family, so an `epic:` label is evidence of the leaf tier this leg must not flag.
PROJECT_LABEL_RE = re.compile(r'^project:(.+)$')

# A body reference. Deliberately the same bare `#\d+` shape the corpus writes —
# H3 intersects these against the family set, so a reference to anything outside
# the family (a PR, an unrelated issue, a closed one) is discarded by the
# intersection and never needs to be recognised as such here.
ISSUE_REF_BODY_RE = re.compile(r'#(\d+)')

# TITLE HEAD normalization, in the order it is applied.
# `[Epic]` / `[Epic]:` is a corpus title prefix, not scope, so it is stripped
# before tokenizing. The head is the segment BEFORE the first em-dash or ` - `:
# corpus titles put the subject first and the elaboration after the dash, and
# including the elaboration would let an incidental word satisfy C4.
H3_EPIC_PREFIX_RE = re.compile(r'^\s*\[epic\]\s*:?\s*')
H3_HEAD_SPLIT_RE = re.compile(r'—| - ')
H3_TOKEN_RE = re.compile(r'[^a-z0-9]+')

# The FIXED exemption token for H3. Fixed rather than the issue's `project:` label
# so an exemption survives a relabel — the operator's judgment was about the ISSUE,
# not about which family it was in that week.
H3_EXEMPT_TOKEN = "initiative-coextension"

# The node fields H3 requires. H2 needs only `parent`, so this triple is exactly
# the set a fixture written for H2 will lack — which is why its absence is an
# input failure rather than a finding of zero. See the module docstring.
H3_REQUIRED_FIELDS = ("labels", "title", "body")

# C3 / C5 thresholds. Both are 2 and both are the SAME kind of claim — "more than
# one other" — but they count different things (family members; in-family
# references), so they are named separately rather than shared.
H3_MIN_FAMILY = 2
H3_MIN_FAN_OUT = 2


def load_licensed_kinds_checked(root):
    """(kinds, degradations) — the pack-union vocabulary PLUS evidence the parse was partial.

    `degradations` is a list of `(pack path, reason)` pairs, empty when the parse is
    whole. Two reasons are recorded, and they are the two ways a present pack can
    contribute fewer kinds than it declares:

      * unreadable — the file exists but could not be opened. The previous `except
        OSError: continue` swallowed this, so a permissions or I/O fault removed a
        pack's whole contribution with no signal anywhere.
      * shortfall — the file read cleanly but yielded fewer `kind_id` rows than it
        declared `[[kinds]]` tables, i.e. `KIND_ID_RE` did not match a row the file
        does carry.

    An ABSENT pack (no directory, or no `pack.toml` inside it) is NOT a degradation:
    which packs a deployment licenses is a configuration choice, and treating a
    deselected pack as a fault would fail loud on a correct instance. The distinction
    is exactly the point — this function separates *not licensed* from *not read*.
    """
    kinds = set()
    degraded = []
    packs_dir = os.path.join(root, "core", "packs")
    if not os.path.isdir(packs_dir):
        return kinds, degraded
    for entry in sorted(os.listdir(packs_dir)):
        pack_toml = os.path.join(packs_dir, entry, "pack.toml")
        if not os.path.isfile(pack_toml):
            continue
        rel = os.path.join("core", "packs", entry, "pack.toml")
        try:
            with open(pack_toml, "r", encoding="utf-8") as fh:
                text = fh.read()
        except OSError as exc:
            degraded.append((rel, "unreadable (%s)" % exc.__class__.__name__))
            continue
        matched = KIND_ID_RE.findall(text)
        declared = KINDS_TABLE_RE.findall(text)
        if len(matched) < len(declared):
            degraded.append((rel, "%d [[kinds]] table(s) declared, %d kind_id row(s) parsed"
                                  % (len(declared), len(matched))))
        for kid in matched:
            kinds.add(kid.lower())
    return kinds, degraded


def load_licensed_kinds(root):
    """Derive the licensed work-item-kind vocabulary from the pack SSOT.

    Signature and return value are unchanged (a set of kind ids) — every existing
    caller keeps working byte-for-byte. A caller that must distinguish a whole parse
    from a partial one calls `load_licensed_kinds_checked` instead.
    """
    return load_licensed_kinds_checked(root)[0]


def _degradation_line(degraded):
    """One-line diagnostic for a partial SSOT parse.

    Single line on purpose: `deploy.sh` captures this stream with `2>&1` and surfaces
    one line on exit 3, so a multi-line message loses the part that names the cause.
    """
    return ("SSOT vocabulary parse is PARTIAL — the licensed kind set is missing "
            "row(s) the packs declare: "
            + "; ".join("%s: %s" % (path, why) for path, why in degraded))


def emit_kinds(root):
    """`--emit-kinds`: the pack-union licensed kind vocabulary, one kind id per line.

    The shell-consumable projection of the SSOT reader, so a consumer that needs the
    live kind set (a gate resolving whether an issue carries a pack-declared kind
    label) reads THIS vocabulary rather than authoring a second one. It inherits the
    fail-loud contract in both directions: a partial parse and an empty set each
    exit 3 with the cause on stderr, so a consumer can never mistake a degraded read
    for a small vocabulary.
    """
    kinds, degraded = load_licensed_kinds_checked(root)
    if degraded:
        print("ERROR\t" + _degradation_line(degraded), file=sys.stderr)
        return 3
    if not kinds:
        print("ERROR\tSSOT vocabulary resolved to zero kinds "
              "(core/packs/*/pack.toml unreadable or kind_id-less)", file=sys.stderr)
        return 3
    print("\n".join(sorted(kinds)))
    return 0


# An H2 exemption entry is `#<issue> <token>` — a '#' immediately followed by
# digits and then whitespace. A blanket `startswith("#")` comment filter eats the
# feature's OWN documented syntax, which is how the escape hatch shipped 100%
# dead: `#242 type:epic` was swallowed as a comment, and the near-miss `242
# type:epic` loaded under a key the `"#" + num` lookup never produced. NO string
# worked. This pattern is deliberately tight — `#` + digits + whitespace + a
# token — so ordinary comments keep working, including date-shaped ones
# (`#2026-07-22 note` has `-` after the digits, not whitespace, so it stays a
# comment).
H2_EXEMPT_LINE_RE = re.compile(r"^#\d+\s+\S")

# An exemption's first field is either an H2 issue ref or an H1 repo path. Issue
# refs normalize to BARE digits so `#242` and `242` are ONE key: the operator may
# write either and the lookup side has exactly one form to compare against.
# A path is never all-digits, so H1 keys pass through verbatim.
ISSUE_REF_RE = re.compile(r"^#?(\d+)$")


def is_exemption_comment(line):
    """True when a stripped exemption line is a comment rather than an entry."""
    return line.startswith("#") and not H2_EXEMPT_LINE_RE.match(line)


def normalize_exempt_key(field):
    """Canonicalize an exemption's first field (issue ref → bare digits)."""
    m = ISSUE_REF_RE.match(field)
    return m.group(1) if m else field


def load_exemptions(root, exempt_path):
    """Parse `<path> <token>` (H1) / `#<issue> <token>` (H2) exemption lines.

    Absent file → empty set. Issue-ref first fields are normalized to bare digits
    (see normalize_exempt_key) so both documented and near-miss forms resolve to
    the same key; run_h2 looks up the same normalized form.
    """
    pairs = set()
    full = os.path.join(root, exempt_path)
    if not os.path.isfile(full):
        return pairs
    try:
        with open(full, "r", encoding="utf-8") as fh:
            for line in fh:
                line = line.strip()
                if not line or is_exemption_comment(line):
                    continue
                parts = line.split()
                if len(parts) >= 2:
                    pairs.add((normalize_exempt_key(parts[0]), parts[1].lower()))
    except OSError:
        pass
    return pairs


def build_chain_re(kinds):
    """`<BannedTier> <arrow> <LicensedKind>` — the H1 predicate.

    CASE-SENSITIVE by design (see module docstring): Title-Case = hierarchy tier,
    lowercase = label namespace. The licensed-kind alternation is Title-Cased from
    the SSOT-derived kind ids so `Initiative -> Epic` matches while the ADR-049
    label mapping `initiative->epic` does not.
    """
    kind_alt = "|".join(
        sorted((re.escape(k.capitalize()) for k in kinds), key=len, reverse=True)
    )
    banned_alt = "|".join(re.escape(t) for t in BANNED_PARENT_TIERS)
    return re.compile(
        r'\b(?P<parent>(?:' + banned_alt + r'))s?\s*' + ARROW + r'\s*'
        r'(?P<child>(?:' + kind_alt + r'))(?:s|es)?\b'
    )


def in_quoted_span(line, start, end):
    """True if [start,end) falls inside a quoted/code span — i.e. CITED, not asserted."""
    for m in QUOTE_SPAN_RE.finditer(line):
        if m.start() <= start and end <= m.end():
            return True
    return False


def iter_scan_files(root, scan_roots, extra_files):
    for scan_root in scan_roots:
        base = os.path.join(root, scan_root)
        if not os.path.isdir(base):
            continue
        for dirpath, dirnames, filenames in os.walk(base):
            dirnames[:] = [d for d in dirnames if not d.startswith(".")]
            rel_dir = os.path.relpath(dirpath, root)
            if any(rel_dir == p or rel_dir.startswith(p + os.sep) for p in EXCLUDED_PREFIXES):
                continue
            for fn in sorted(filenames):
                if fn.endswith(".md"):
                    yield os.path.join(dirpath, fn)
    for extra in extra_files:
        full = os.path.join(root, extra)
        if os.path.isfile(full):
            yield full


def unresolved_surfaces(root, scan_roots, extra_files):
    """Configured H1 scan surfaces that do not resolve on disk.

    A configured-but-absent surface contributes ZERO files and is otherwise
    INDISTINGUISHABLE from a surface that is present and clean — both read as
    silence. That silence is how `EXTRA_SCAN_FILES = ("CLAUDE.md",)` shipped
    naming a path this repo has never had, contributing nothing while the check
    read green. Reported, never swallowed.

    Pure and side-effect-free: a sibling of iter_scan_files over the SAME
    configuration triple, so the two cannot disagree about what was configured.
    """
    missing = []
    for scan_root in scan_roots:
        if not os.path.isdir(os.path.join(root, scan_root)):
            missing.append("root:" + scan_root)
    for extra in extra_files:
        if not os.path.isfile(os.path.join(root, extra)):
            missing.append("file:" + extra)
    return missing


def run_h1(root, kinds, exemptions, scan_roots, extra_files):
    """Doc invariant. Returns (findings, exempted, scanned_count)."""
    chain_re = build_chain_re(kinds)
    findings, exempted, scanned = [], [], 0
    for path in iter_scan_files(root, scan_roots, extra_files):
        scanned += 1
        rel = os.path.relpath(path, root)
        try:
            with open(path, "r", encoding="utf-8", errors="replace") as fh:
                lines = fh.readlines()
        except OSError:
            continue
        for lineno, line in enumerate(lines, 1):
            for m in chain_re.finditer(line):
                parent = m.group("parent")
                if in_quoted_span(line, m.start(), m.end()):
                    continue  # cited / negated, not asserted
                if (rel, parent.lower()) in exemptions:
                    exempted.append(("H1", rel + ":" + str(lineno) + " " + parent))
                    continue
                findings.append((rel + ":" + str(lineno), m.group(0).strip()))
    return findings, exempted, scanned


# ONE query serves BOTH backlog legs. H3's fields (`title`, `body`, the node's own
# `labels`) are ADDED TO THE EXISTING SELECTION SET rather than fetched by a second
# call — the no-N+1 contract in the H2 note above is a property of this query, and
# a separate H3 fetch would double the call count to gain nothing.
#
# H3's family exclusion needs no extra field either: E's native children WITHIN the
# open-epic population are exactly the nodes whose own `parent.number` is E's, and
# `parent{number}` is already selected for H2.
GRAPHQL_EPIC_PARENTS = """
query($owner:String!,$name:String!,$endCursor:String){
  repository(owner:$owner,name:$name){
    issues(first:100, states:OPEN, labels:["type:epic"], after:$endCursor){
      pageInfo{hasNextPage endCursor}
      nodes{
        number
        title
        body
        labels(first:30){nodes{name}}
        parent{ number labels(first:30){nodes{name}} }
      }
    }
  }
}
"""


def iter_json_docs(text):
    """Yield each JSON document from a CONCATENATED stream.

    `gh api graphql --paginate` emits one JSON document per page with NO separator
    between them — not newline-delimited JSON. Splitting on newlines therefore
    yields a single unparseable blob the moment a query spans >1 page, and the
    result silently reads as zero nodes (a false-green). raw_decode walks the
    concatenation correctly regardless of page count.
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


def fetch_epic_parent_map(repo):
    """ONE batched+paginated GraphQL call — never an N+1 per-epic loop."""
    owner, _, name = repo.partition("/")
    proc = subprocess.run(
        ["gh", "api", "graphql", "--paginate",
         "-f", "query=" + GRAPHQL_EPIC_PARENTS,
         "-F", "owner=" + owner, "-F", "name=" + name],
        capture_output=True, text=True,
    )
    if proc.returncode != 0:
        raise RuntimeError((proc.stderr or "graphql call failed").strip().splitlines()[0])
    nodes = []
    try:
        for payload in iter_json_docs(proc.stdout):
            nodes.extend(payload["data"]["repository"]["issues"]["nodes"])
    except (KeyError, TypeError, ValueError):
        raise RuntimeError("unexpected GraphQL payload shape")
    return nodes


def run_h2(nodes, exemptions):
    """Backlog invariant: flag any epic whose parent also carries type:epic."""
    findings, exempted = [], []
    for node in nodes:
        parent = node.get("parent")
        if not parent:
            continue
        labels = [n.get("name", "") for n in parent.get("labels", {}).get("nodes", [])]
        if "type:epic" not in labels:
            continue
        num = str(node.get("number"))
        # Look up the NORMALIZED key (bare digits — see normalize_exempt_key), so
        # both `#242 type:epic` and `242 type:epic` in the exemption file resolve
        # here. The EXEMPT output row keeps the `#`-prefixed display form.
        if (num, "type:epic") in exemptions:
            exempted.append(("H2", "#" + num))
            continue
        findings.append((num, str(parent.get("number"))))
    return findings, exempted


def node_labels(node):
    """Label names on a node, tolerant of GraphQL's null-vs-absent distinction."""
    return [n.get("name", "") for n in (node.get("labels") or {}).get("nodes", [])]


def title_head_tokens(title):
    """C4's `head()` — the token set of a title's SUBJECT segment.

    Lowercase, strip a leading `[Epic]`/`[Epic]:`, truncate at the first em-dash or
    ` - `, tokenize on non-alphanumerics. Returned as a set: C4 asks whether each
    slug token is PRESENT, never in what order or how often.
    """
    text = H3_EPIC_PREFIX_RE.sub("", (title or "").lower())
    head = H3_HEAD_SPLIT_RE.split(text)[0]
    return set(tok for tok in H3_TOKEN_RE.split(head) if tok)


def h3_missing_fields(nodes):
    """Which of H3's required fields the node set does not carry.

    Returns a sorted list; empty means the population is evaluable. This is the
    ANTI-VACUITY control, not a convenience: a node set missing these fields yields
    zero H3 findings BY CONSTRUCTION, which is indistinguishable from a clean
    result. Its caller turns a non-empty return into exit 3.

    An EMPTY node set returns empty here — it is not field-deficient, it is simply
    an empty population, and the caller reports that as `SKIP H3`. The two are
    different failures and are deliberately not collapsed.
    """
    missing = set()
    for node in nodes:
        for field in H3_REQUIRED_FIELDS:
            if field not in node:
                missing.add(field)
    return sorted(missing)


def run_h3(nodes, exemptions):
    """Advisory invariant: an open epic that is really an INITIATIVE CONTAINER.

    Returns (findings, exempted). A finding is
    `(issue, project-label, matched-slug-tokens, in-family-refs)` — the evidence
    travels WITH the finding, because C4 is lexical and an operator must be able to
    falsify a row without re-deriving the predicate.

    The three conjuncts (C3 family / C4 coextension / C5 fan-out) are documented in
    the module docstring together with the measurement that made each of them
    load-bearing. Read that before deleting one for simplicity.
    """
    # E's native children WITHIN this population — derived from the parent edges the
    # H2 leg already needs, so C3's "not its native children" costs no extra fetch.
    children = {}
    for node in nodes:
        parent = node.get("parent")
        if parent and parent.get("number") is not None:
            children.setdefault(str(parent["number"]), set()).add(str(node.get("number")))

    # project-label -> the whole open-epic membership of that family.
    families = {}
    for node in nodes:
        num = str(node.get("number"))
        for label in node_labels(node):
            if PROJECT_LABEL_RE.match(label):
                families.setdefault(label, set()).add(num)

    findings, exempted = [], []
    for node in nodes:
        num = str(node.get("number"))
        head_tokens = title_head_tokens(node.get("title"))
        body_refs = set(ISSUE_REF_BODY_RE.findall(node.get("body") or ""))
        own_children = children.get(num, set())

        hit = None
        # Sorted so a multi-`project:` issue resolves to the same family on every
        # run — an unordered "first match" would make the emitted evidence vary
        # between runs on identical input.
        for label in sorted(node_labels(node)):
            m = PROJECT_LABEL_RE.match(label)
            if not m:
                continue
            family = families.get(label, set()) - {num} - own_children
            if len(family) < H3_MIN_FAMILY:                       # C3
                continue
            slug_tokens = [t for t in H3_TOKEN_RE.split(m.group(1).lower()) if t]
            if not slug_tokens:
                continue
            if not all(t in head_tokens for t in slug_tokens):    # C4
                continue
            in_family = sorted(body_refs & family, key=int)       # C5
            if len(in_family) < H3_MIN_FAN_OUT:
                continue
            hit = (label, slug_tokens, in_family)
            break

        if hit is None:
            continue
        # Exempted AFTER the predicate, never before: the exemption suppresses a
        # REPORT, and a check that skipped the evaluation could not tell an
        # exemption that is still needed from one that has gone stale.
        if (num, H3_EXEMPT_TOKEN) in exemptions:
            exempted.append(("H3", "#" + num))
            continue
        label, slug_tokens, in_family = hit
        findings.append((num, label, ",".join(slug_tokens),
                         ",".join("#" + n for n in in_family)))
    return findings, exempted


# ── self-test ───────────────────────────────────────────────────────────────

# One `[[kinds]]` table per kind — the shape the live packs actually use, and the
# shape the KINDS_TABLE_RE structural control counts against. The earlier fixture
# stacked both `kind_id` rows under a single table header; that is not valid TOML
# (the second key would overwrite the first) and it made the fixture unable to
# exercise the shortfall control at all. Kind set is unchanged, so every H1 case
# below is unaffected.
SELF_TEST_PACK = ('pack_id = "t"\n'
                  '[[kinds]]\nkind_id = "epic"\n'
                  '[[kinds]]\nkind_id = "story"\n')


def _mkroot(tmp, doc_body):
    os.makedirs(os.path.join(tmp, "core", "packs", "t"), exist_ok=True)
    with open(os.path.join(tmp, "core", "packs", "t", "pack.toml"), "w") as fh:
        fh.write(SELF_TEST_PACK)
    with open(os.path.join(tmp, "core", "doc.md"), "w") as fh:
        fh.write(doc_body)
    return tmp


def self_test():
    """Synthetic-fixture drive for both legs — no live state, no network."""
    results = []

    def check(name, ok):
        results.append((name, ok))

    # H1-a: an ASSERTED unlicensed parent tier → must FAIL.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "The hierarchy is Initiative -> Epic -> Story.\n")
        kinds = load_licensed_kinds(root)
        f, _, _ = run_h1(root, kinds, set(), ("core",), ())
        check("H1 fires on asserted 'Initiative -> Epic'", len(f) == 1)

    # H1-b: the SAME chain, QUOTED (cited/negated) → must NOT fire.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, 'It does not use the shorthand "Initiative -> Epic -> Story".\n')
        kinds = load_licensed_kinds(root)
        f, _, _ = run_h1(root, kinds, set(), ("core",), ())
        check("H1 citation-guard suppresses quoted chain", len(f) == 0)

    # H1-c: a LICENSED parent (Epic -> Story) → must NOT fire.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "Decomposition runs Epic -> Story.\n")
        kinds = load_licensed_kinds(root)
        f, _, _ = run_h1(root, kinds, set(), ("core",), ())
        check("H1 ignores licensed parent 'Epic -> Story'", len(f) == 0)

    # H1-c2: LOWERCASE label-mapping notation (the ADR-049 title shape) → must
    # NOT fire. Regression guard for the measured false positive.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "Canonical vocabulary + initiative->epic/project label mapping\n")
        kinds = load_licensed_kinds(root)
        f, _, _ = run_h1(root, kinds, set(), ("core",), ())
        check("H1 ignores lowercase label mapping 'initiative->epic'", len(f) == 0)

    # H1-c3: a non-work-item ALTITUDE ladder whose child rung is a licensed kind
    # name → must NOT fire (the KM `Unit -> Task` aliased ladder).
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "the altitude ladder (Unit -> Task -> Workstream -> Project)\n")
        kinds = load_licensed_kinds(root)
        f, _, _ = run_h1(root, kinds, set(), ("core",), ())
        check("H1 ignores non-work-item altitude ladder 'Unit -> Task'", len(f) == 0)

    # H1-c4: the SAFe row of the Layer-2 methodology map → must NOT fire.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "| **SAFe** | Capability -> Feature -> Story / Enabler |\n")
        kinds = load_licensed_kinds(root)
        f, _, _ = run_h1(root, kinds, set(), ("core",), ())
        check("H1 ignores SAFe methodology map 'Feature -> Story'", len(f) == 0)

    # H1-f: `Roadmap` is banned too, not just `Initiative`.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "The chain is Roadmap -> Epic -> Story.\n")
        kinds = load_licensed_kinds(root)
        f, _, _ = run_h1(root, kinds, set(), ("core",), ())
        check("H1 fires on banned tier 'Roadmap -> Epic'", len(f) == 1)

    # H1-d: exemption list suppresses a genuine hit.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "The hierarchy is Initiative -> Epic.\n")
        kinds = load_licensed_kinds(root)
        f, ex, _ = run_h1(root, kinds, {(os.path.join("core", "doc.md"), "initiative")},
                          ("core",), ())
        check("H1 exemption suppresses hit", len(f) == 0 and len(ex) == 1)

    # H1-e: unreadable SSOT → zero kinds → caller must fail loud (never green).
    with tempfile.TemporaryDirectory() as tmp:
        check("H1 empty SSOT yields zero kinds (fail-loud input)",
              len(load_licensed_kinds(tmp)) == 0)

    # ── R1–R14: RECALL cases ────────────────────────────────────────────────
    # Everything above tests PRECISION — that H1 does not fire where it should
    # not. None of it could detect the opposite failure: an assertion H1 never
    # EVALUATED. Two such blind spots shipped together.
    #
    #   R1–R9  the citation guard treated a POSSESSIVE as a quote delimiter, so
    #          any assertion between two apostrophes on one line was masked out
    #          before the predicate ran.
    #   R10–R14 two configured scan surfaces resolved to nothing — `operations/`
    #          was never in the roots, and the named extra file did not exist —
    #          each contributing a SILENT zero indistinguishable from "clean".
    #
    # A check that reads `COUNT 0` without establishing recall has measured
    # nothing. These cases are that establishment.

    # R1: the reproduction line from the card. Returns 0 against the pre-fix
    # predicate — the apostrophes swallow the whole assertion.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "The platform's hierarchy is Initiative -> Epic and that's wrong.\n")
        f, _, _ = run_h1(root, load_licensed_kinds(root), set(), ("core",), ())
        check("R1 H1 fires on an assertion between two possessive apostrophes", len(f) == 1)

    # R2: the STRUCTURAL proof, independent of run_h1 — a possessive pair must not
    # form a span AT ALL. Fails by construction against the pre-fix pattern, so
    # this regression can never be greened by tuning the H1 predicate instead.
    check("R2 a possessive pair does not open a quote span",
          QUOTE_SPAN_RE.search("The platform's ladder and that's it") is None)

    # R3-R5: PRECISION MUST SURVIVE. The same chain inside each genuine delimiter,
    # on a line that ALSO carries apostrophes — the fix must not trade recall for
    # precision. R5 pins the smart-quote alternation, which the live corpus
    # exercises ZERO times, so only this case stands between it and a future
    # "unused alternation" pruning.
    for tag, body in (
        ("double quotes", 'The team\'s note says "Initiative -> Epic" is wrong.\n'),
        ("backticks", "The team's note says `Initiative -> Epic` is wrong.\n"),
        ("smart quotes", "The team's note says “Initiative -> Epic” is wrong.\n"),
    ):
        with tempfile.TemporaryDirectory() as tmp:
            root = _mkroot(tmp, body)
            f, _, _ = run_h1(root, load_licensed_kinds(root), set(), ("core",), ())
            check("R3-5 citation guard still suppresses a chain in " + tag, len(f) == 0)

    # R6-R8: the SINGLE-QUOTE delimiter stays live. Deleting the alternation
    # outright — the obvious "simplification", and the one the card's own Expected
    # Behavior invites — would fire on all three of these. R8 is the largest class
    # in this corpus (shell/regex/glob literals); R7 is suppressed only by the
    # inner-contraction allowance, so it also guards a revert to the simpler
    # boundary-anchored form.
    for tag, body in (
        ("a quoted citation", "It does not use 'Initiative -> Epic'.\n"),
        ("a quote containing a contraction",
         "It avoids 'the platform's Initiative -> Epic ladder'.\n"),
        ("a code literal", "    HIERARCHY = 'Initiative -> Epic'\n"),
    ):
        with tempfile.TemporaryDirectory() as tmp:
            root = _mkroot(tmp, body)
            f, _, _ = run_h1(root, load_licensed_kinds(root), set(), ("core",), ())
            check("R6-8 single-quoted span still suppresses " + tag, len(f) == 0)

    # R9: PLURAL possessives — a trailing apostrophe with no following letter. The
    # boundary anchor must key on the character AFTER the quote, not merely before.
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "The teams' ladder is Roadmap -> Story and the groups' view.\n")
        f, _, _ = run_h1(root, load_licensed_kinds(root), set(), ("core",), ())
        check("R9 H1 fires between two plural possessives", len(f) == 1)

    # R10: SENSITIVITY — an absent configured surface is reported, by kind.
    with tempfile.TemporaryDirectory() as tmp:
        os.makedirs(os.path.join(tmp, "core"), exist_ok=True)
        check("R10 unresolved_surfaces names an absent root and an absent file",
              unresolved_surfaces(tmp, ("core", "nope"), ("nope.md",))
              == ["root:nope", "file:nope.md"])

    # R11: SPECIFICITY — a fully resolvable configuration reports NOTHING (a probe
    # that flags everything proves nothing), and the configured extra file is
    # actually SCANNED. Driven through the SHIPPED constants over a mirrored tree:
    # the tree walk filters on `.md`, so an extra entry naming a `.md.template`
    # reaches H1 ONLY via this bypass. Repoint it at a path nothing resolves and
    # this case fails rather than contributing a silent zero.
    with tempfile.TemporaryDirectory() as tmp:
        for scan_root in DEFAULT_SCAN_ROOTS:
            os.makedirs(os.path.join(tmp, scan_root), exist_ok=True)
        for extra in EXTRA_SCAN_FILES:
            full = os.path.join(tmp, extra)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            with open(full, "w", encoding="utf-8") as fh:
                fh.write("The hierarchy is Initiative -> Epic.\n")
        f, _, scanned = run_h1(tmp, {"epic"}, set(), DEFAULT_SCAN_ROOTS, EXTRA_SCAN_FILES)
        check("R11 a resolvable config reports nothing and scans its extra file",
              unresolved_surfaces(tmp, DEFAULT_SCAN_ROOTS, EXTRA_SCAN_FILES) == []
              and scanned == len(EXTRA_SCAN_FILES) and len(f) == 1)

    # ── R12: THE CONJUNCTION PROOF — the two legs are NOT independent ────────
    # A possessive-bearing assertion seeded in operations/ is found by NEITHER leg
    # alone: widening the roots without narrowing the quote span still yields 0
    # (the apostrophes mask it), and narrowing the quote span without widening the
    # roots never reads the file. ONLY BOTH TOGETHER surface it — so a half
    # implementation reads green and looks done.
    #
    # Asserted through the SHIPPED DEFAULT_SCAN_ROOTS rather than a hand-passed
    # tuple, which is what makes it load-bearing: dropping `operations` from the
    # constant fails here even though the regex is correct. The narrowed arm is
    # the control — it proves the widening is what moved the result, not the
    # regex alone.
    with tempfile.TemporaryDirectory() as tmp:
        _mkroot(tmp, "nothing is asserted on this line\n")
        skill_dir = os.path.join(tmp, "operations", "skills", "x")
        os.makedirs(skill_dir, exist_ok=True)
        with open(os.path.join(skill_dir, "SKILL.md"), "w", encoding="utf-8") as fh:
            fh.write("The team's ladder is Initiative -> Epic and that's the model.\n")
        kinds = load_licensed_kinds(tmp)
        shipped, _, _ = run_h1(tmp, kinds, set(), DEFAULT_SCAN_ROOTS, ())
        narrowed, _, _ = run_h1(tmp, kinds, set(), ("core", "release"), ())
        check("R12 a seeded operations/ assertion needs BOTH legs to surface",
              len(shipped) == 1 and len(narrowed) == 0)

    # R13: the input to main()'s exit-3 arm. A scan over an EMPTY population finds
    # nothing by construction and would otherwise read green — the same failure
    # this whole check exists to detect, one level up.
    with tempfile.TemporaryDirectory() as tmp:
        _, _, scanned = run_h1(tmp, {"epic"}, set(), DEFAULT_SCAN_ROOTS, EXTRA_SCAN_FILES)
        missing = unresolved_surfaces(tmp, DEFAULT_SCAN_ROOTS, EXTRA_SCAN_FILES)
        check("R13 an empty population scans 0 and names every unresolved surface",
              scanned == 0
              and len(missing) == len(DEFAULT_SCAN_ROOTS) + len(EXTRA_SCAN_FILES))

    # R14: the shipped configuration must resolve against THIS repo, not merely
    # against a synthetic tree. Every case above builds whatever the constants
    # happen to name, so all of them pass just as well when an entry points at a
    # path that does not exist — which is precisely how `EXTRA_SCAN_FILES =
    # ("CLAUDE.md",)` shipped dead. Measured: reverting that repoint leaves the
    # other 34 cases green. Only an assertion against a REAL checkout catches it.
    #
    # The root is derived from this module's own location rather than the process
    # cwd, so the case is invariant to where the runner invokes it from. Copy this
    # tool outside the repo and the case goes RED — correctly: from there the
    # configured surfaces genuinely do not resolve. A loud failure is recoverable;
    # the silent pass it replaces was not. The SSOT-marker conjunct is the
    # sensitivity arm — it fails if the path derivation itself drifts, so an
    # unresolvable root can never be mistaken for a clean one.
    repo_root = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", "..", ".."))
    check("R14 every shipped scan surface resolves in this checkout",
          os.path.isdir(os.path.join(repo_root, "core", "packs"))
          and unresolved_surfaces(repo_root, DEFAULT_SCAN_ROOTS, EXTRA_SCAN_FILES) == [])

    # H2-a: synthetic epic-under-epic parent map → must FAIL.
    nodes = [{"number": 11, "parent": {"number": 22,
              "labels": {"nodes": [{"name": "type:epic"}]}}}]
    f, _ = run_h2(nodes, set())
    check("H2 fires on epic-under-epic edge", f == [("11", "22")])

    # H2-b: parent is NOT an epic → must NOT fire.
    nodes = [{"number": 11, "parent": {"number": 22,
              "labels": {"nodes": [{"name": "type:story"}]}}}]
    f, _ = run_h2(nodes, set())
    check("H2 ignores non-epic parent", len(f) == 0)

    # H2-c: no parent at all → must NOT fire.
    f, _ = run_h2([{"number": 11, "parent": None}], set())
    check("H2 ignores parentless epic", len(f) == 0)

    # ── H2-d: the exemption ROUND-TRIP, end to end through load_exemptions ──
    # The previous version of this test handed run_h2 a hand-built tuple, so it
    # never touched load_exemptions and would have passed unchanged if that
    # function were DELETED — which is why the escape hatch shipped structurally
    # unreachable with a green self-test. These cases write a REAL exemption file,
    # parse it with the REAL loader, and assert on the live finding shape
    # (an epic parented to an epic, both carrying type:epic).
    LIVE_CHILD, LIVE_PARENT = "242", "1153"
    live_nodes = [{"number": int(LIVE_CHILD),
                   "parent": {"number": int(LIVE_PARENT),
                              "labels": {"nodes": [{"name": "type:epic"}]}}}]

    def _h2_via_file(body):
        """Write `body` as the exemption file, load it, run H2 over live_nodes."""
        with tempfile.TemporaryDirectory() as tmp:
            name = "work-hierarchy-exemption-list.txt"
            with open(os.path.join(tmp, name), "w", encoding="utf-8") as fh:
                fh.write(body)
            return run_h2(live_nodes, load_exemptions(tmp, name))

    # Control: with NO exemption file the finding must fire, or every suppression
    # assertion below would be vacuously true.
    f, ex = run_h2(live_nodes, load_exemptions("/nonexistent-root", "nope.txt"))
    check("H2 control: unexempted live edge fires",
          f == [(LIVE_CHILD, LIVE_PARENT)] and len(ex) == 0)

    # The DOCUMENTED format must work end to end. This is the case that was dead.
    f, ex = _h2_via_file("# operator notes\n#" + LIVE_CHILD + " type:epic\n")
    check("H2 documented `#<issue> type:epic` suppresses via load_exemptions",
          len(f) == 0 and ex == [("H2", "#" + LIVE_CHILD)])

    # The near-miss bare form an operator reaches for when the documented one
    # appears to do nothing must ALSO work, rather than silently failing twice.
    f, ex = _h2_via_file(LIVE_CHILD + " type:epic\n")
    check("H2 bare `<issue> type:epic` suppresses via load_exemptions",
          len(f) == 0 and ex == [("H2", "#" + LIVE_CHILD)])

    # NEGATIVE: an exemption for a DIFFERENT issue must not suppress this one.
    # Without this, a loader that returned a match-everything set would pass.
    f, ex = _h2_via_file("#999999 type:epic\n")
    check("H2 non-matching issue exemption does NOT suppress",
          f == [(LIVE_CHILD, LIVE_PARENT)] and len(ex) == 0)

    # NEGATIVE: right issue, wrong token — the pair is the key, not the number.
    f, ex = _h2_via_file("#" + LIVE_CHILD + " type:story\n")
    check("H2 non-matching token exemption does NOT suppress",
          f == [(LIVE_CHILD, LIVE_PARENT)] and len(ex) == 0)

    # Ordinary comments still comment. `#` + digits is an entry ONLY when
    # whitespace follows the digits, so a date-shaped comment stays a comment.
    f, ex = _h2_via_file("# " + LIVE_CHILD + " type:epic\n"
                         "#2026-07-22 reviewed, left in place\n")
    check("H2 comment lines are still comments (no accidental exemption)",
          f == [(LIVE_CHILD, LIVE_PARENT)] and len(ex) == 0)

    # The H1 leg shares the loader — a path key must survive normalization.
    with tempfile.TemporaryDirectory() as tmp:
        name = "exempt.txt"
        with open(os.path.join(tmp, name), "w", encoding="utf-8") as fh:
            fh.write("# a comment\ncore/doc.md initiative\n#" + LIVE_CHILD + " type:epic\n")
        loaded = load_exemptions(tmp, name)
        check("loader keeps H1 path keys verbatim alongside H2 issue keys",
              loaded == {("core/doc.md", "initiative"), (LIVE_CHILD, "type:epic")})

    # ── H3: initiative-coextension ──────────────────────────────────────────
    # ONE fixture population drives every H3 arm below, because the discrimination
    # claim is about a POPULATION, not about isolated inputs: each near-miss must
    # stay unflagged while sitting in the SAME family as a true positive. Seven
    # near-miss classes, each failing EXACTLY ONE conjunct — that is what makes
    # them near-misses rather than unrelated negatives.
    #
    #   900 TRUE POSITIVE   family 3, title coextensive, 2 in-family refs
    #   901 SP-1  sibling leaf epic in the family      → fails C4 (coextension)
    #   902 SP-2  title carries the slug, 1 ref only   → fails C5 (fan-out)
    #   903 SP-3  2 in-family refs, unrelated title    → fails C4 (coextension)
    #   910 TRUE POSITIVE #2 — a SECOND family, so the exemption arm can show that
    #                          exempting one finding does not mute the other
    #   911 filler leaf                                 → fails C4
    #   912 SP-4  coextensive title, no refs at all     → fails C5
    #   920 SP-5  sole member of its family             → fails C3 (family size)
    #   930 SP-6  no `project:` label at all            → fails C2 (population)
    #   940 SP-8  container whose family members ARE its native children → fails C3
    #   941,942   those native children                 → fail C4
    #
    # SP-7 (a CLOSED epic that would otherwise match) cannot be expressed as a node,
    # because closed issues never enter the population — it is asserted structurally
    # against the query itself, below.
    h3_nodes = [
        {"number": 900, "title": "Widget Forge — the umbrella", "parent": None,
         "body": "Decomposed into #901 and #902.",
         "labels": {"nodes": [{"name": "type:epic"}, {"name": "project:widget-forge"}]}},
        {"number": 901, "title": "Forge CI drift detection", "parent": None,
         "body": "Related: #902, #903.",
         "labels": {"nodes": [{"name": "type:epic"}, {"name": "project:widget-forge"}]}},
        {"number": 902, "title": "Widget Forge packaging", "parent": None,
         "body": "Follows #903.",
         "labels": {"nodes": [{"name": "type:epic"}, {"name": "project:widget-forge"}]}},
        {"number": 903, "title": "Anvil hardening", "parent": None,
         "body": "Blocked by #900 and #901.",
         "labels": {"nodes": [{"name": "type:epic"}, {"name": "project:widget-forge"}]}},
        {"number": 910, "title": "Anvil Line — the programme", "parent": None,
         "body": "Covers #911 and #912.",
         "labels": {"nodes": [{"name": "type:epic"}, {"name": "project:anvil-line"}]}},
        {"number": 911, "title": "Throughput instrumentation", "parent": None,
         "body": "", "labels": {"nodes": [{"name": "type:epic"},
                                          {"name": "project:anvil-line"}]}},
        {"number": 912, "title": "Anvil Line tooling", "parent": None,
         "body": "", "labels": {"nodes": [{"name": "type:epic"},
                                          {"name": "project:anvil-line"}]}},
        {"number": 920, "title": "Solo Shop — everything", "parent": None,
         "body": "See #900 and #901.",
         "labels": {"nodes": [{"name": "type:epic"}, {"name": "project:solo-shop"}]}},
        {"number": 930, "title": "Widget Forge — unlabelled twin", "parent": None,
         "body": "Covers #901 and #902.",
         "labels": {"nodes": [{"name": "type:epic"}]}},
        {"number": 940, "title": "Kiln Run", "parent": None,
         "body": "Covers #941 and #942.",
         "labels": {"nodes": [{"name": "type:epic"}, {"name": "project:kiln-run"}]}},
        {"number": 941, "title": "Firing schedule", "parent": {"number": 940},
         "body": "", "labels": {"nodes": [{"name": "type:epic"},
                                          {"name": "project:kiln-run"}]}},
        {"number": 942, "title": "Kiln maintenance", "parent": {"number": 940},
         "body": "", "labels": {"nodes": [{"name": "type:epic"},
                                          {"name": "project:kiln-run"}]}},
    ]

    # SENSITIVITY. Without this the specificity assertions below would all be
    # vacuously true against a predicate that flags nothing.
    f, ex = run_h3(h3_nodes, set())
    check("H3 fires on both seeded initiative containers",
          [row[0] for row in f] == ["900", "910"] and len(ex) == 0)

    # The row carries ITS OWN EVIDENCE — the matched slug tokens and the in-family
    # references. C4 is lexical, so a finding an operator cannot falsify in one read
    # would be an accusation rather than a signal.
    check("H3 row emits the project label, matched slug tokens and in-family refs",
          f[0] == ("900", "project:widget-forge", "widget,forge", "#901,#902"))

    # SPECIFICITY, one arm per near-miss class. Asserted INDIVIDUALLY rather than as
    # one aggregate count so a failure names the class that broke.
    flagged = {row[0] for row in f}
    for tag, num in (
        ("SP-1 sibling leaf epic (fails coextension)", "901"),
        ("SP-2 slug in title but no fan-out (fails fan-out)", "902"),
        ("SP-3 fan-out without coextension (fails coextension)", "903"),
        ("SP-4 coextensive title with no in-family refs (fails fan-out)", "912"),
        ("SP-5 sole member of its family (fails family size)", "920"),
        ("SP-6 no project: label (outside the population)", "930"),
        ("SP-8 container whose family IS its native children (fails family size)", "940"),
    ):
        check("H3 does NOT flag " + tag, num not in flagged)

    # SP-7 — a CLOSED epic that WOULD match. Not expressible as a node, because the
    # population is scoped by the query. Asserted there instead: without OPEN
    # scoping H3 would resurrect every container a grooming sweep already resolved
    # by closing it. This is the arm that fails if someone widens the query.
    check("SP-7 the epic population is OPEN-scoped in the query itself",
          "states:OPEN" in GRAPHQL_EPIC_PARENTS)

    # THE CONJUNCTION PROOF — the family conjunct ALONE over-fires on this very
    # fixture. This is the measured defect the card's literal predicate carried
    # (39 of 42 open epics), reproduced in miniature so a future "simplify H3 to
    # the family shape" edit fails here instead of shipping.
    c3_alone = set()
    for node in h3_nodes:
        num = str(node["number"])
        kids = set(str(n["number"]) for n in h3_nodes
                   if (n.get("parent") or {}).get("number") == node["number"])
        for label in node_labels(node):
            if not PROJECT_LABEL_RE.match(label):
                continue
            fam = set(str(n["number"]) for n in h3_nodes
                      if label in node_labels(n)) - set([num]) - kids
            if len(fam) >= H3_MIN_FAMILY:
                c3_alone.add(num)
    check("H3 the family conjunct ALONE over-fires (the conjunction discriminates)",
          len(c3_alone) > len(flagged) and flagged < c3_alone)

    # Exemption: suppresses the named finding ONLY. A blanket mute would pass a
    # "the exemption worked" assertion just as well, which is why the second
    # container must still fire here.
    f, ex = run_h3(h3_nodes, set([("900", H3_EXEMPT_TOKEN)]))
    check("H3 exemption suppresses only the exempted container",
          [row[0] for row in f] == ["910"] and ex == [("H3", "#900")])

    # NEGATIVE: the H2 token must not suppress an H3 finding. The two legs share one
    # exemption file, and a loader that ignored the token would make every H2
    # exemption silently mute H3 as well.
    f, ex = run_h3(h3_nodes, set([("900", "type:epic")]))
    check("H3 is not suppressed by an H2-token exemption on the same issue",
          [row[0] for row in f] == ["900", "910"] and len(ex) == 0)

    # Title-head normalization, asserted directly — C4's verdict turns on it.
    check("H3 title head strips an [Epic] prefix and truncates at the dash",
          title_head_tokens("[Epic]: Widget Forge — packaging and release")
          == set(["widget", "forge"]))
    check("H3 title head truncates at a spaced hyphen too",
          title_head_tokens("Anvil Line - the programme") == set(["anvil", "line"]))

    # ── THE ANTI-VACUITY CONTROL ────────────────────────────────────────────
    # An H2-era node set carries `parent` and nothing else. Run H3 over it and every
    # specificity arm above returns ZERO — passing for the wrong reason. That is the
    # `--fixture × --skip` combination trap, and it is why a missing field triple is
    # an INPUT FAILURE rather than a clean result.
    check("H3 names every missing field on an H2-era node set",
          h3_missing_fields([{"number": 11, "parent": None}])
          == ["body", "labels", "title"])
    check("H3 reports no missing field on a complete node set",
          h3_missing_fields(h3_nodes) == [])
    # An EMPTY population is NOT field-deficient — a different failure, handled by
    # main() as a SKIP. Collapsing the two would fail loud on a legitimately
    # epic-less repo.
    check("H3 treats an empty population as evaluable, not field-deficient",
          h3_missing_fields([]) == [])

    # ── H3 THROUGH THE CLI, at every invocation form that narrows the population ──
    # The arms above drive the library. These drive the SHIPPED command line — the
    # surface deploy.sh actually executes — because the field-deficiency guard, the
    # SKIP rows and the COUNT_H3 emission all live in main(), not in run_h3.
    def _h3_cli(root_dir, extra_args):
        cp = subprocess.run([sys.executable, os.path.abspath(__file__),
                             "--root", root_dir] + list(extra_args),
                            capture_output=True, text=True)
        return cp.returncode, cp.stdout, cp.stderr

    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "nothing is asserted on this line\n")
        full_fixture = os.path.join(tmp, "h3-nodes.json")
        with open(full_fixture, "w", encoding="utf-8") as fh:
            json.dump(h3_nodes, fh)
        h2_era_fixture = os.path.join(tmp, "h2-era-nodes.json")
        with open(h2_era_fixture, "w", encoding="utf-8") as fh:
            json.dump([{"number": 11, "parent": None}], fh)
        exempt_file = "h3-exempt.txt"
        with open(os.path.join(tmp, exempt_file), "w", encoding="utf-8") as fh:
            fh.write("#900 " + H3_EXEMPT_TOKEN + "\n")

        # F2 — the fixture form. Both containers reported, no near-miss reported,
        # and the count is a MEASURED 2.
        rc, out_s, _err = _h3_cli(root, ("--fixture-parent-map", full_fixture))
        h3_rows = [ln for ln in out_s.split("\n") if ln.startswith("H3\t")]
        check("F2 fixture form reports exactly the two containers, COUNT_H3 2",
              rc == 0
              and [ln.split("\t")[1] for ln in h3_rows] == ["900", "910"]
              and "COUNT_H3\t2" in out_s)
        check("F2 fixture form reports ZERO of the seven near-miss classes",
              not any(ln.split("\t")[1] in ("901", "902", "903", "912",
                                            "920", "930", "940")
                      for ln in h3_rows))

        # F2-neg — THE cell that matters. A field-deficient fixture must exit 3 and
        # must NOT emit a zero. Both halves are asserted: an exit-3 that still
        # printed `COUNT_H3 0` would leave the vacuous zero in the operator's output.
        rc, out_s, err_s = _h3_cli(root, ("--fixture-parent-map", h2_era_fixture))
        check("F2-neg field-deficient fixture exits 3 and emits NO COUNT_H3",
              rc == 3 and "COUNT_H3" not in out_s and "H3 population lacks" in err_s)

        # F3 — `--skip-backlog`. A skipped leg says so; it never reports a zero.
        rc, out_s, _err = _h3_cli(root, ("--skip-backlog",))
        check("F3 --skip-backlog emits SKIP H3 and NO COUNT_H3",
              rc == 0 and "SKIP\tH3\t" in out_s and "COUNT_H3" not in out_s)

        # F5 — the exemption file, end to end through the real loader. The
        # unexempted container must still fire, or a blanket mute would pass.
        rc, out_s, _err = _h3_cli(root, ("--fixture-parent-map", full_fixture,
                                         "--exempt-file", exempt_file))
        check("F5 exemption file suppresses one container and keeps the other",
              "EXEMPT\tH3\t#900" in out_s and "COUNT_H3\t1" in out_s
              and [ln.split("\t")[1] for ln in out_s.split("\n")
                   if ln.startswith("H3\t")] == ["910"])

        # THE ADVISORY CONTRACT, asserted on the observable deploy.sh reads. Two
        # containers are reported and the process STILL exits 0 — H3 cannot move
        # the exit code, and therefore cannot gate, in any mode.
        rc, out_s, _err = _h3_cli(root, ("--fixture-parent-map", full_fixture))
        check("H3 findings do NOT move the exit code (the advisory contract)",
              rc == 0 and "COUNT\t0" in out_s and "COUNT_H3\t2" in out_s)

    # PAGINATION: `gh --paginate` concatenates page documents with NO separator.
    # A newline-split parse silently yields ZERO nodes past page 1 — a FALSE-GREEN
    # on a >100-epic repo. Regression guard for that bug.
    concat = '{"a":1}{"a":2}  {"a":3}'
    check("concatenated multi-page JSON parses to all documents",
          [d["a"] for d in iter_json_docs(concat)] == [1, 2, 3])
    check("single-document JSON still parses",
          [d["a"] for d in iter_json_docs('{"a":9}')] == [9])

    # ── SSOT vocabulary: partial-parse detection + the --emit-kinds CLI ──────
    # These arms exist because the vocabulary reader's ONLY alarm used to fire at
    # the empty set, so every partial degradation returned a non-empty subset with
    # exit 0 and no stderr. Each arm below returns a NON-EMPTY subset, which is
    # precisely the state the old guard called healthy.

    def _emit_kinds_cli(root_dir):
        """Run the tool's own --emit-kinds CLI — the glue a shell consumer executes,
        not just the library behind it."""
        cp = subprocess.run([sys.executable, os.path.abspath(__file__),
                             "--root", root_dir, "--emit-kinds"],
                            capture_output=True, text=True)
        return cp.returncode, cp.stdout.strip(), cp.stderr.strip()

    def _pack_root(tmp, text):
        os.makedirs(os.path.join(tmp, "core", "packs", "t"), exist_ok=True)
        p = os.path.join(tmp, "core", "packs", "t", "pack.toml")
        with open(p, "w", encoding="utf-8") as fh:
            fh.write(text)
        return tmp, p

    # CONTROL (sensitivity): the healthy fixture must parse WHOLE and emit cleanly.
    # Without this, every "degraded ⇒ exit 3" assertion below could pass on a
    # function that returns exit 3 unconditionally.
    with tempfile.TemporaryDirectory() as tmp:
        root, _ = _pack_root(tmp, SELF_TEST_PACK)
        kinds, degraded = load_licensed_kinds_checked(root)
        rc, out, _err = _emit_kinds_cli(root)
        check("SSOT control: whole parse reports no degradation",
              kinds == {"epic", "story"} and degraded == [])
        check("SSOT control: --emit-kinds emits the vocabulary, exit 0",
              rc == 0 and out.split("\n") == ["epic", "story"])

    # The legacy signature is preserved verbatim — existing callers get a bare set.
    with tempfile.TemporaryDirectory() as tmp:
        root, _ = _pack_root(tmp, SELF_TEST_PACK)
        check("load_licensed_kinds still returns a bare set (caller contract intact)",
              load_licensed_kinds(root) == {"epic", "story"})

    # SHORTFALL a — VALID TOML the line-anchored regex cannot match: trailing comment.
    with tempfile.TemporaryDirectory() as tmp:
        root, _ = _pack_root(tmp, SELF_TEST_PACK.replace(
            'kind_id = "story"', 'kind_id = "story"  # the story kind'))
        kinds, degraded = load_licensed_kinds_checked(root)
        rc, _out, err = _emit_kinds_cli(root)
        check("SSOT shortfall (trailing comment) detected on a NON-EMPTY subset",
              kinds == {"epic"} and len(degraded) == 1)
        check("SSOT shortfall (trailing comment) exits 3 with a one-line cause",
              rc == 3 and "PARTIAL" in err and len(err.split("\n")) == 1)

    # SHORTFALL b — VALID TOML, single-quoted literal string.
    with tempfile.TemporaryDirectory() as tmp:
        root, _ = _pack_root(tmp, SELF_TEST_PACK.replace(
            'kind_id = "epic"', "kind_id = 'epic'"))
        kinds, degraded = load_licensed_kinds_checked(root)
        rc, _out, _err = _emit_kinds_cli(root)
        check("SSOT shortfall (single-quoted literal) detected, exits 3",
              kinds == {"story"} and len(degraded) == 1 and rc == 3)

    # UNREADABLE — the arm the old `except OSError: continue` swallowed whole.
    # A second pack keeps the result NON-EMPTY, so the empty-set guard cannot be
    # what catches it.
    with tempfile.TemporaryDirectory() as tmp:
        root, blocked = _pack_root(tmp, SELF_TEST_PACK)
        os.makedirs(os.path.join(tmp, "core", "packs", "u"), exist_ok=True)
        with open(os.path.join(tmp, "core", "packs", "u", "pack.toml"), "w") as fh:
            fh.write('pack_id = "u"\n[[kinds]]\nkind_id = "card"\n')
        os.chmod(blocked, 0o000)
        try:
            kinds, degraded = load_licensed_kinds_checked(root)
            rc, _out, err = _emit_kinds_cli(root)
            check("SSOT unreadable pack detected despite a non-empty result",
                  kinds == {"card"} and len(degraded) == 1
                  and "unreadable" in degraded[0][1])
            check("SSOT unreadable pack exits 3 rather than reading a short vocabulary",
                  rc == 3 and "PARTIAL" in err)
        finally:
            os.chmod(blocked, 0o644)

    # SPECIFICITY — a DESELECTED pack is configuration, never degradation. Without
    # this arm the control above could be satisfied by flagging any absent pack,
    # which would fail loud on every correctly-configured instance.
    with tempfile.TemporaryDirectory() as tmp:
        root, _ = _pack_root(tmp, SELF_TEST_PACK)
        os.makedirs(os.path.join(tmp, "core", "packs", "deselected"), exist_ok=True)
        kinds, degraded = load_licensed_kinds_checked(root)
        rc, _out, _err = _emit_kinds_cli(root)
        check("SSOT deselected pack (no pack.toml) is NOT a degradation",
              kinds == {"epic", "story"} and degraded == [] and rc == 0)

    # SPECIFICITY — the pre-existing empty-set guard still fires, and reports the
    # empty-set cause rather than the partial-parse one.
    with tempfile.TemporaryDirectory() as tmp:
        rc, _out, err = _emit_kinds_cli(tmp)
        check("SSOT empty vocabulary still exits 3 with the zero-kinds cause",
              rc == 3 and "zero kinds" in err and "PARTIAL" not in err)

    # ── G1-G2: main()'s H1-SIDE EMISSIONS, driven through the shipped CLI ────
    # The R-series drives the LIBRARY — `unresolved_surfaces` (R10, R11, R13) and
    # `run_h1`. Neither the `SKIP H1` row nor the `scanned == 0` fail-loud arm
    # lives there: BOTH live in main(), and both were previously deletable with
    # the whole suite still green. R13's own comment says it covers the INPUT to
    # the exit-3 arm; nothing covered the arm. These two cases cover the arms.
    #
    # `_h3_cli` above is the generic CLI driver despite its H3-flavoured name — it
    # runs this tool's shipped command line, which is the only surface these two
    # emissions have. `--skip-backlog` keeps both arms offline.
    #
    # The two are INDEPENDENT by construction, so each attributes to its own
    # subject: G1 scans a NON-empty population (the exit-3 arm never fires there),
    # and G2 asserts on stderr and on the absence of the TSV, neither of which the
    # G1 loop writes. Deleting either subject reddens exactly one of them.

    # G1: an unresolved CONFIGURED surface must be NAMED on stdout rather than
    # swallowed. The fixture builds every shipped scan root EXCEPT one, plus every
    # extra file, so the expected output is exactly ONE row. That exactness is the
    # specificity arm: a loop emitting a row per CONFIGURED surface rather than per
    # UNRESOLVED one reports four rows and fails here, and a deleted loop reports
    # none and fails here. Asserted through the SHIPPED constants, so dropping this
    # root from DEFAULT_SCAN_ROOTS reddens the case too — correctly, since it would
    # then be asserting about a surface nothing configures.
    ABSENT_ROOT = "operations"
    with tempfile.TemporaryDirectory() as tmp:
        root = _mkroot(tmp, "nothing is asserted on this line\n")
        for scan_root in DEFAULT_SCAN_ROOTS:
            if scan_root != ABSENT_ROOT:
                os.makedirs(os.path.join(tmp, scan_root), exist_ok=True)
        for extra in EXTRA_SCAN_FILES:
            full = os.path.join(tmp, extra)
            os.makedirs(os.path.dirname(full), exist_ok=True)
            with open(full, "w", encoding="utf-8") as fh:
                fh.write("nothing is asserted here either\n")
        rc, out_s, _err = _h3_cli(root, ("--skip-backlog",))
        skips = [ln for ln in out_s.split("\n") if ln.startswith("SKIP\tH1\t")]
        check("G1 main() emits one SKIP H1 row naming the unresolved surface",
              rc == 0
              and skips == ["SKIP\tH1\tunresolved scan surface: root:" + ABSENT_ROOT])

    # G2: main()'s `scanned == 0` fail-loud arm — the guard that stops an H1 scan
    # over an EMPTY population from reading green, which is this check's OWN
    # failure shape one level up. A pack-only tree resolves a vocabulary but holds
    # no scannable file, so the population is empty by construction while the run
    # still gets far enough to reach the guard.
    #
    # Four conjuncts, each pinning a distinct property the guard's own comment
    # claims: it exits 3; the cause is SELF-CONTAINED on the FIRST line (deploy.sh
    # captures this run with 2>&1 and reports `head -1`, so a later line would not
    # survive the trip); the TSV is NOT printed ahead of it (which would hand the
    # operator `VOCAB ...` as the diagnosis); and it names only the surfaces that
    # actually failed to resolve rather than every configured one — the partial
    # case the DERIVED wording exists to report correctly. `core` resolves in this
    # fixture and must therefore not be named.
    with tempfile.TemporaryDirectory() as tmp:
        root, _ = _pack_root(tmp, SELF_TEST_PACK)
        rc, out_s, err_s = _h3_cli(root, ("--skip-backlog",))
        first = err_s.split("\n")[0]
        configured = len(DEFAULT_SCAN_ROOTS) + len(EXTRA_SCAN_FILES)
        # _pack_root creates exactly ONE configured surface (`core`), so every
        # other configured surface is unresolved.
        check("G2 an empty H1 population exits 3, self-contained on line 1",
              rc == 3
              and first.startswith("ERROR\tH1 scan population is empty")
              and ("%d of %d configured scan surfaces unresolved"
                   % (configured - 1, configured)) in first
              and "root:core" not in first
              and "VOCAB" not in out_s)

    failed = [n for n, ok in results if not ok]
    for name, ok in results:
        print(("  PASS  " if ok else "  FAIL  ") + name)
    print("self-test: %d/%d passed" % (len(results) - len(failed), len(results)))
    return 1 if failed else 0


def _derive_repo(explicit):
    """owner/name of the running clone's origin (fork-correct); never hardcode the
    operator handle (depersonalization gate). Returns None if unset and unresolved."""
    if explicit:
        return explicit
    try:
        url = subprocess.run(["git", "config", "--get", "remote.origin.url"],
                             capture_output=True, text=True).stdout.strip()
        m = re.search(r"[:/]([^/]+/[^/]+?)(?:\.git)?$", url)
        if m:
            return m.group(1)
    except Exception:
        pass
    return None


def main():
    ap = argparse.ArgumentParser(description="Work-hierarchy drift detector.")
    ap.add_argument("--root", default=".", help="repo root to scan")
    ap.add_argument("--repo", default=None,
                    help="owner/name for H2; derived from git remote origin when omitted")
    ap.add_argument("--exempt-file", default=EXEMPT_FILE_DEFAULT)
    ap.add_argument("--output-format", choices=("tsv",), default="tsv")
    ap.add_argument("--skip-backlog", action="store_true",
                    help="run H1 only (offline / doc-invariant only)")
    ap.add_argument("--fixture-parent-map",
                    help="JSON file of GraphQL-shaped epic nodes — drives H2 offline")
    ap.add_argument("--emit-kinds", action="store_true",
                    help="print the pack-union licensed kind vocabulary (one id per line) and "
                         "exit; exits 3 on an empty OR partially-parsed SSOT")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = os.path.abspath(args.root)

    if args.emit_kinds:
        # Vocabulary-only mode: filesystem-reading, offline, and it runs BEFORE the
        # H1/H2 legs so a consumer that needs only the kind set pays for nothing else.
        return emit_kinds(root)

    out = []

    kinds, kinds_degraded = load_licensed_kinds_checked(root)
    if kinds_degraded:
        # Fail loud on a PARTIAL parse, checked BEFORE the empty-set guard below —
        # a non-empty subset is the likelier degradation and was previously silent,
        # and when a degraded read also lands on empty this names the actual cause
        # rather than the symptom.
        print("ERROR\t" + _degradation_line(kinds_degraded), file=sys.stderr)
        return 3
    if not kinds:
        # Fail loud — an unreadable SSOT must never read green (the --require-targets
        # discipline). A silent zero-vocabulary scan would find nothing by construction.
        print("ERROR\tSSOT vocabulary resolved to zero kinds "
              "(core/packs/*/pack.toml unreadable or kind_id-less)", file=sys.stderr)
        return 3
    out.append("VOCAB\t" + ",".join(sorted(kinds)))

    exemptions = load_exemptions(root, args.exempt_file)

    h1, h1_ex, scanned = run_h1(root, kinds, exemptions, DEFAULT_SCAN_ROOTS, EXTRA_SCAN_FILES)
    out.append("SCANNED\t" + str(scanned))
    unresolved = unresolved_surfaces(root, DEFAULT_SCAN_ROOTS, EXTRA_SCAN_FILES)
    for surface in unresolved:
        out.append("SKIP\tH1\tunresolved scan surface: " + surface)
    if scanned == 0:
        # Fail loud — the same discipline as the zero-kind SSOT guard above. A scan
        # over an EMPTY population finds nothing BY CONSTRUCTION and would read
        # green, which is the exact failure this check exists to detect one level up.
        #
        # The unresolved surfaces are named INLINE rather than left to the SKIP rows
        # because the rows would not survive the trip: deploy.sh captures this run
        # with 2>&1 and reports `head -1` on exit 3, so every other exit-3 path puts
        # its ERROR on the first line and this one must too. Printing the TSV first
        # would hand the operator `VOCAB ...` as the diagnosis. Named inline, the
        # message is self-contained on the one line the consumer reads.
        #
        # The wording is DERIVED rather than asserted, because an empty population
        # does not imply that every surface failed to resolve: a surface that
        # resolves but holds no scannable file produces the same zero. Hardcoding
        # "every configured scan surface is unresolved" misreports the partial case
        # (3 of 4 resolving still yields that sentence), and joining an EMPTY
        # unresolved list yields an error naming no subject at all — both on the one
        # line the operator gets. The count carries the distinction the prose cannot.
        configured = len(DEFAULT_SCAN_ROOTS) + len(EXTRA_SCAN_FILES)
        if unresolved:
            detail = ("%d of %d configured scan surfaces unresolved: %s"
                      % (len(unresolved), configured, ", ".join(unresolved)))
        else:
            detail = ("all %d configured scan surfaces resolved but yielded no "
                      "scannable file" % configured)
        print("ERROR\tH1 scan population is empty — " + detail, file=sys.stderr)
        return 3
    for loc, text in h1:
        out.append("H1\t" + loc + "\t" + text)

    h2, h2_ex = [], []
    h3, h3_ex = [], []
    h3_ran = False
    nodes = None
    if args.fixture_parent_map:
        try:
            with open(args.fixture_parent_map, "r", encoding="utf-8") as fh:
                nodes = json.load(fh)
        except (OSError, ValueError) as exc:
            print("ERROR\tfixture parent-map unreadable: " + str(exc), file=sys.stderr)
            return 3
        h2, h2_ex = run_h2(nodes, exemptions)
    elif args.skip_backlog:
        out.append("SKIP\tH2\tbacklog leg skipped by request")
        # H3 rides H2's node set, so skipping the backlog skips it too — and it says
        # so EXPLICITLY. Falling through to `COUNT_H3 0` would report an unevaluated
        # leg as a clean one, which is the failure this file exists to detect.
        out.append("SKIP\tH3\tbacklog leg skipped by request — the coextension "
                   "advisory rides the same fetch and was not evaluated")
    else:
        repo = _derive_repo(args.repo)
        if not repo:
            print("ERROR\t--repo not supplied and git remote origin unresolved",
                  file=sys.stderr)
            return 3
        try:
            nodes = fetch_epic_parent_map(repo)
        except RuntimeError as exc:
            print("ERROR\tH2 GraphQL failure: " + str(exc), file=sys.stderr)
            return 3
        h2, h2_ex = run_h2(nodes, exemptions)

    if nodes is not None:
        missing = h3_missing_fields(nodes)
        if missing:
            # FAIL LOUD. See the module docstring's anti-vacuity note: H3 over a
            # field-deficient node set finds nothing BY CONSTRUCTION, so reporting
            # zero here would pass for the wrong reason. Named inline on ONE line
            # because deploy.sh reports `head -1` of this stream on exit 3.
            print("ERROR\tH3 population lacks the required field(s) "
                  + ", ".join(missing)
                  + " — an H2-era node set cannot evaluate the coextension leg; "
                    "a zero here would be vacuous. Extend the fixture or drop "
                    "--fixture-parent-map.", file=sys.stderr)
            return 3
        if not nodes:
            out.append("SKIP\tH3\tempty epic population — the coextension advisory "
                       "had nothing to evaluate")
        else:
            h3, h3_ex = run_h3(nodes, exemptions)
            h3_ran = True

    for num, parent in h2:
        out.append("H2\t" + num + "\t" + parent)
    for num, label, slug_tokens, refs in h3:
        out.append("H3\t" + num + "\t" + label + "\t" + slug_tokens + "\t" + refs)
    for leg, detail in h1_ex + h2_ex + h3_ex:
        out.append("EXEMPT\t" + leg + "\t" + detail)

    # COUNT_H3 is emitted ONLY when the leg ran. Its presence is the consumer's
    # signal that the zero it may carry is a MEASURED zero; its absence (paired
    # with a SKIP H3 row) is the signal that nothing was measured at all.
    if h3_ran:
        out.append("COUNT_H3\t" + str(len(h3)))

    # H3 IS DELIBERATELY ABSENT FROM THIS TOTAL, and from the return below. The
    # advisory contract is a property of this arithmetic — not of a default some
    # later edit could flip — so an H3-only run exits 0 and `deploy.sh --check`
    # is byte-unchanged by it in warn AND enforce mode. See ADR-132.
    total = len(h1) + len(h2)
    out.append("COUNT\t" + str(total))
    print("\n".join(out))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
