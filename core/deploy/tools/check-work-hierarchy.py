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

PACK-GRAMMAR MODES (`--validate-packs`, `--resolve`) — the same pack corpus, read
richer. `core/schemas/work-item-type-schema.md` is a meta-schema that NO executable
validated: the grammar could say anything and nothing in the tree would notice, so a
criterion asserting "a pack conforms" was ungradable by construction. `--validate-packs`
makes conformance checkable and emits a RULE ID per finding, so a rejection is
attributable to a rule instead of to an exit code. `--resolve` makes the archetype↔kit
eligibility join executable, so the prose contract downstream consumers read can be
checked by one command rather than by eye. Both are separate argv branches that return
before the H1/H2/H3 legs run and share no mutable state with them.

Python 3.9-compatible (no tomllib, no 3.10+ syntax) — matches /usr/bin/python3 on
the operator baseline.
"""

import argparse
import inspect
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



# ── PACK-CONFORMANCE META-SCHEMA READER (--validate-packs / --resolve) ──────
# A second, RICHER read of the same `core/packs/*/pack.toml` corpus the licensed-kind
# union above reads. It exists because `core/schemas/work-item-type-schema.md` is a
# meta-schema no executable validated: the grammar could say anything and nothing in
# the tree would notice. These two modes make it checkable.
#
# SECTION-SCOPED, not line-anchored, and that is load-bearing. `applies_to` appears in
# the meta-schema in TWO unrelated senses — `[meta].applies_to` (a string: the pack's
# archetype join key) and `[controls.applies_to]` (an object: a control's cross-cutting
# span). A line-anchored `applies_to\s*=` scan would read a control's span as a pack
# header field and mis-verdict the pack. The reader therefore tracks the current
# `[section]` / `[[array]]` header and accepts each key only inside the section that
# owns it. A self-test arm asserts exactly this (`SC` below).
#
# Regex-parsed rather than tomllib-parsed for the same reason the union above is: the
# operator baseline is Python 3.9 and tomllib is 3.11+.
PACK_SECTION_RE = re.compile(r'^[ \t]*(\[\[?)([A-Za-z0-9_.\-]+)\]\]?[ \t]*(?:#.*)?$')
PACK_KV_RE = re.compile(r'^[ \t]*([A-Za-z0-9_\-]+)[ \t]*=[ \t]*(.*)$')

# The archetype name set is §1.1's, byte-identical and case-sensitive. `Custom` is a
# MEMBER of it — §1.3 used to read "one of the 8 names OR Custom", double-counting it,
# which is harmless as prose and unimplementable as a rule. The grammar edit that ships
# with this reader states the domain by reference to this set rather than re-counting.
ARCHETYPE_NAMES = ("Scrum", "Kanban", "XP", "Waterfall", "PRINCE2", "SAFe",
                   "Hybrid", "Custom")
# The methodology-neutral sentinel. ONE token, deliberately: the grammar already uses
# `*` at the pack level and in the controls facet, so minting a second neutrality token
# would fork the sentinel vocabulary inside one grammar (ADR-170 D2).
NEUTRAL_SENTINEL = "*"
PACK_ROLES = ("archetype", "base", "kit")
GENERAL_LEVELS = ("Portfolio", "Program", "Project", "Milestone/Workstream",
                  "Work Item")
MVP_RELATIONSHIP_TYPES = ("GENERATES", "DEPENDS_ON", "BLOCKS", "SUPERSEDES",
                          "BELONGS_TO", "RELATES_TO", "ASSIGNED_TO")

# THE CLASS→FACET REGISTRY — the second level of the two-level requiredness rule
# (ADR-170 D3). `role` decides whether a facet requirement applies at all; `kit_class`
# decides WHICH facet. Registering a second kit class is one entry here plus the rule
# implementing that facet — no `role` change, no re-opening of the `kinds` rule. A
# class ABSENT from this map asserts no facet requirement and is reported as a
# PACK-P08 caveat naming the value, never as an error: the domain is OPEN by decision.
KIT_CLASS_FACETS = {"work-item": "kinds"}

# §1.2's required per-kind fields. `fields.kind_specific[]` and `materialization` are
# optional and are deliberately absent from this tuple.
KIND_REQUIRED_FIELDS = ("kind_id", "display_name", "base", "methodology_projection",
                        "fields", "criteria", "relationships", "lifecycle_behavior",
                        "axis1_state_machine")

# `pack_id` admits ONE leading underscore beyond the plain slug form. That is an
# accommodation, not an oversight: the shipped base pack is `_common`, and the leading
# underscore is the corpus's own reserved-name convention for the shared root. Stated
# here rather than left implicit, because a stricter regex would reject a shipped pack
# and a looser one would stop catching a genuine malformed id.
PACK_ID_RE = re.compile(r'^_?[a-z0-9][a-z0-9_-]*$')
KIND_SLUG_RE = re.compile(r'^[a-z0-9][a-z0-9_-]*$')
# ReDoS-safe by construction, and the shape is deliberate. The obvious spelling —
# `(?:[-+][0-9A-Za-z.-]+)*` — is exponential: the leading `[-+]` and the inner class
# BOTH match `-`, so an input like `0.0.0+` followed by many `--` splits ambiguously
# across the outer `*` and backtracks combinatorially. Semver has at most ONE
# pre-release segment and at most ONE build segment, so the two are written as separate
# OPTIONAL groups rather than as a starred alternation, which removes the outer
# repetition and with it the ambiguity.
SEMVER_RE = re.compile(r'^\d+\.\d+\.\d+(?:-[0-9A-Za-z.-]+)?(?:\+[0-9A-Za-z.-]+)?$')

# The label-group value domain is READ from the label grammar, never restated here.
# §1.1.1 says the grammar owns the group set and a pack only fills it; a copy in this
# file would be a duplicate source that drifts as the grammar gains groups — which is
# exactly what happened to the meta-schema's own copy (it listed seven while the label
# grammar declared eight, and the shipped base pack populates the eighth).
LABEL_GROUP_HEADING_RE = re.compile(r'^###[ \t]+(.+?)[ \t]+Labels[ \t]*$', re.M)
LABEL_TAXONOMY_REL = os.path.join("core", "specs", "label-taxonomy.md")

# EVERY rule this reader can emit. Two consumers, both load-bearing: the
# `rules_evaluated` counter (so a run reports its own denominator rather than leaving
# "no findings" ambiguous between clean and not-run), and the self-test's coverage
# meta-arm, which asserts that every id in this tuple is exercised by a mutation arm
# that fails when its rule is mutated. Adding a rule without an arm reddens the suite.
PACK_RULE_IDS = (
    "PACK-P01", "PACK-P02", "PACK-P03", "PACK-P04", "PACK-P05", "PACK-P06",
    "PACK-P07", "PACK-P08",
    "PACK-K01", "PACK-K02", "PACK-K03", "PACK-K04", "PACK-K05", "PACK-K06",
    "PACK-K07",
    "PACK-L01", "PACK-L02",
)


def _scan_pack_value(rhs, lines, idx):
    """(value, next_idx) for one TOML right-hand side. str | list | raw-string.

    Arrays MAY span lines (the corpus writes them on one, but a multi-line array is
    valid TOML and reading only the first line would silently truncate a set the
    PACK-K04 subset rule then evaluates against). A trailing `# comment` is stripped
    only OUTSIDE a quoted span, so a `#` inside a string survives.
    """
    rhs = rhs.strip()
    if rhs[:1] in ('"', "'"):
        q = rhs[0]
        end = rhs.find(q, 1)
        if end == -1:
            return rhs, idx
        return rhs[1:end], idx
    if rhs.startswith("["):
        buf = rhs
        while buf.count("[") > buf.count("]") and idx + 1 < len(lines):
            idx += 1
            buf += " " + lines[idx].strip()
        inner = buf[buf.find("[") + 1:buf.rfind("]")]
        out = []
        for part in inner.split(","):
            part = part.strip()
            if not part:
                continue
            if part[:1] in ('"', "'") and part[-1:] == part[:1]:
                part = part[1:-1]
            out.append(part)
        return out, idx
    cut = rhs.find("#")
    if cut != -1:
        rhs = rhs[:cut]
    return rhs.strip(), idx


def parse_pack(text):
    """(pack, degradations) — a section-scoped read of one `pack.toml`.

    `pack` = {"meta": {...}, "kinds": [...], "labels": [...], "controls": [...]}.

    `degradations` is non-empty when the parse is demonstrably PARTIAL, and a partial
    parse is an error rather than a short result — the same fail-loud-both-directions
    contract `load_licensed_kinds_checked` carries, for the same reason: a reader that
    silently under-reads reports "no findings" on a file it never finished.

    Two structural controls, neither of which needs a TOML parser:
      * CROSS-INSTRUMENT AGREEMENT — the `[[kinds]]` header count this reader's own
        section regex finds must equal the count `KINDS_TABLE_RE` (the licensed-kind
        union's independent regex) finds over the same bytes. Two regexes disagreeing
        about how many kinds a file declares is positive evidence one of them is
        misreading, and it is checkable without parsing either.
      * KIND SHORTFALL — every `[[kinds]]` table must yield a `kind_id`. A table that
        yields none is a row this reader did not manage to read.
    """
    lines = text.split("\n")
    pack = {"meta": {}, "kinds": [], "labels": [], "controls": []}
    degraded = []
    target = pack["meta"]          # keys before any header belong to the pack header
    current_kind = None
    current_label = None
    current_control = None
    section_kind_tables = 0

    i = 0
    while i < len(lines):
        line = lines[i]
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            i += 1
            continue
        m = PACK_SECTION_RE.match(line)
        if m:
            is_array = m.group(1) == "[["
            name = m.group(2)
            head = name.split(".")[0]
            if is_array and name == "kinds":
                current_kind = {}
                pack["kinds"].append(current_kind)
                target = current_kind
                section_kind_tables += 1
            elif is_array and name == "labels":
                current_label = {}
                pack["labels"].append(current_label)
                target = current_label
            elif is_array and name == "controls":
                current_control = {}
                pack["controls"].append(current_control)
                target = current_control
            elif name == "meta":
                target = pack["meta"]
            elif head == "kinds" and current_kind is not None:
                node = current_kind
                for part in name.split(".")[1:]:
                    node = node.setdefault(part, {})
                    if not isinstance(node, dict):
                        break
                target = node if isinstance(node, dict) else {}
            elif head == "controls" and current_control is not None:
                node = current_control
                for part in name.split(".")[1:]:
                    node = node.setdefault(part, {})
                target = node if isinstance(node, dict) else {}
            elif head == "labels" and current_label is not None:
                node = current_label
                for part in name.split(".")[1:]:
                    node = node.setdefault(part, {})
                target = node if isinstance(node, dict) else {}
            else:
                # An unrecognised section. Its keys belong to NOBODY — emphatically not
                # to the pack header, which is the mis-scoping this reader exists to
                # avoid. They are dropped into a scratch dict.
                target = {}
            i += 1
            continue
        kv = PACK_KV_RE.match(line)
        if kv:
            value, i = _scan_pack_value(kv.group(2), lines, i)
            if isinstance(target, dict):
                target[kv.group(1)] = value
        i += 1

    union_kind_tables = len(KINDS_TABLE_RE.findall(text))
    if union_kind_tables != section_kind_tables:
        degraded.append("kind-table count disagrees between readers "
                        "(section reader %d, union reader %d)"
                        % (section_kind_tables, union_kind_tables))
    kindless = sum(1 for k in pack["kinds"] if not k.get("kind_id"))
    if kindless:
        degraded.append("%d [[kinds]] table(s) yielded no kind_id row" % kindless)
    return pack, degraded


def read_pack_root(pack_root):
    """((rel, pack) list, degradations) — every pack under `pack_root`.

    TWO shapes are accepted, and both are used by this repo's own verification rows:
    a directory that IS one pack (holds `pack.toml` directly), and a directory OF
    packs (each child may hold one). Accepting only the second would make a
    single-fixture root unreadable and force every fixture to be validated together,
    which defeats attributing a rejection to one fixture.
    """
    entries = []
    if os.path.isfile(os.path.join(pack_root, "pack.toml")):
        entries.append((os.path.basename(os.path.abspath(pack_root)),
                        os.path.join(pack_root, "pack.toml")))
    elif os.path.isdir(pack_root):
        for entry in sorted(os.listdir(pack_root)):
            candidate = os.path.join(pack_root, entry, "pack.toml")
            if os.path.isfile(candidate):
                entries.append((entry, candidate))
    packs = []
    degraded = []
    for name, path in entries:
        rel = os.path.join(name, "pack.toml")
        try:
            with open(path, "r", encoding="utf-8") as fh:
                text = fh.read()
        except OSError as exc:
            degraded.append("%s: unreadable (%s)" % (rel, exc.__class__.__name__))
            continue
        pack, pack_degraded = parse_pack(text)
        for why in pack_degraded:
            degraded.append("%s: %s" % (rel, why))
        packs.append((rel, pack))
    return packs, degraded


def load_label_groups(root):
    """(group set, note) read live from the label grammar; (None, reason) when absent.

    An unreadable grammar makes PACK-L01 UNEVALUABLE, and this returns None so the
    caller emits a SKIP row naming the reason. It must never fall back to a hardcoded
    list: a copy here is the duplicate source the grammar edit just removed from the
    meta-schema, and it would drift the same way. It must never silently pass either —
    a rule that quietly evaluates to "no findings" because its input was missing is the
    vacuous-zero failure this whole file is built against.
    """
    path = os.path.join(root, LABEL_TAXONOMY_REL)
    try:
        with open(path, "r", encoding="utf-8") as fh:
            text = fh.read()
    except OSError:
        return None, "label grammar unreadable at " + LABEL_TAXONOMY_REL
    groups = set()
    for name in LABEL_GROUP_HEADING_RE.findall(text):
        groups.add(name.strip().lower().replace(" ", "-"))
    if not groups:
        return None, ("label grammar at " + LABEL_TAXONOMY_REL
                      + " declared no `### <Name> Labels` group heading")
    return groups, "%d group(s) read from %s" % (len(groups), LABEL_TAXONOMY_REL)


def pack_role(pack):
    """The effective role. Absent ⇒ `archetype` — the backward-compat guarantee."""
    return pack["meta"].get("role", "archetype")


def _validate_one_pack(rel, pack, packs_by_id, label_groups):
    """[(severity, rule_id, detail)] for one pack. severity ∈ {ERROR, CAVEAT}."""
    f = []
    meta = pack["meta"]
    role = pack_role(pack)
    applies_to = meta.get("applies_to")
    kinds = pack["kinds"]

    # ── PACK-P01/P02: identity ──────────────────────────────────────────────
    pack_id = meta.get("pack_id")
    if not isinstance(pack_id, str) or not PACK_ID_RE.match(pack_id or ""):
        f.append(("ERROR", "PACK-P01",
                  "pack_id missing or not a lowercase slug: %r" % (pack_id,)))
    pack_version = meta.get("pack_version")
    if not isinstance(pack_version, str) or not SEMVER_RE.match(pack_version or ""):
        f.append(("ERROR", "PACK-P02",
                  "pack_version missing or not semver: %r" % (pack_version,)))

    # ── PACK-P03: applies_to value DOMAIN (membership only) ─────────────────
    # Layered deliberately: P03 asks whether the value is in the domain at all, P05
    # asks whether THIS role may hold it. Collapsing them would make every
    # out-of-domain value emit two ids and no arm could attribute a rejection.
    applies_ok = isinstance(applies_to, str) and (
        applies_to == NEUTRAL_SENTINEL or applies_to in ARCHETYPE_NAMES)
    if not applies_ok:
        f.append(("ERROR", "PACK-P03",
                  "applies_to missing or outside the archetype-name set ∪ {%s}: %r"
                  % (NEUTRAL_SENTINEL, applies_to)))

    # ── PACK-P04: the role discriminator ────────────────────────────────────
    role_ok = role in PACK_ROLES
    if not role_ok:
        f.append(("ERROR", "PACK-P04",
                  "role %r is outside {%s}; every role-branching rule (P05-P08 and "
                  "PACK-K05's neutral-sentinel limb) is NOT-EVALUATED for this pack, "
                  "because their input is undefined"
                  % (role, ", ".join(PACK_ROLES))))

    # Every rule below BRANCHES on the role. With an unreadable role they have no
    # defined input, so they are not evaluated rather than evaluated against a guess —
    # a guessed branch would emit ids the pack never earned and make P04's own arm
    # unattributable.
    if role_ok:
        # ── PACK-P05: the role↔applies_to weld, total over all three roles ───
        if applies_ok:
            if role in ("base", "kit") and applies_to != NEUTRAL_SENTINEL:
                f.append(("ERROR", "PACK-P05",
                          "role=%s requires applies_to=%s (methodology-neutral), got %r"
                          % (role, NEUTRAL_SENTINEL, applies_to)))
            if role == "archetype" and applies_to == NEUTRAL_SENTINEL:
                f.append(("ERROR", "PACK-P05",
                          "role=archetype MUST NOT set applies_to=%s — an archetype "
                          "pack claiming neutrality is the restriction axis this "
                          "grammar closed; a neutral kind set is a role=kit pack"
                          % NEUTRAL_SENTINEL))

        # ── PACK-P06: extends, widened to {archetype, kit} ───────────────────
        extends = meta.get("extends")
        if extends:
            if role == "base":
                f.append(("ERROR", "PACK-P06",
                          "role=base MUST NOT set extends — a base pack is the "
                          "inheritance root"))
            else:
                target = packs_by_id.get(extends)
                if target is None:
                    f.append(("CAVEAT", "PACK-P06",
                              "extends target %r is not present in this pack root — "
                              "which packs a deployment licenses is a configuration "
                              "choice, so this is reported, not failed" % extends))
                elif pack_role(target) != "base":
                    f.append(("ERROR", "PACK-P06",
                              "extends target %r has role=%s; only a role=base pack "
                              "may be an inheritance root (a kit may inherit but may "
                              "never be inherited from)"
                              % (extends, pack_role(target))))

        # ── PACK-P08: kit_class, and the OPEN domain ─────────────────────────
        kit_class = meta.get("kit_class")
        if role == "kit" and not kit_class:
            f.append(("ERROR", "PACK-P08",
                      "role=kit requires kit_class (the facet discriminator)"))
        elif role != "kit" and kit_class:
            f.append(("ERROR", "PACK-P08",
                      "kit_class is permitted only on role=kit, found on role=%s"
                      % role))
        elif role == "kit" and kit_class not in KIT_CLASS_FACETS:
            f.append(("CAVEAT", "PACK-P08",
                      "kit_class %r is not a registered class (registered: %s). The "
                      "domain is OPEN, so this is a caveat and no facet requirement "
                      "is asserted for it — but it is named rather than silent, "
                      "because a mistyped class reaching this arm relieves a "
                      "work-item kit of its kinds obligation"
                      % (kit_class, ", ".join(sorted(KIT_CLASS_FACETS)))))

        # ── PACK-P07: the TWO-LEVEL kinds requiredness rule (ADR-170 D3) ─────
        # role decides WHETHER a facet requirement applies; kit_class decides WHICH.
        # Conditioning the kit arm on role alone would forbid every future kit class
        # and make P08's open domain unreachable — the same pack would fail here first.
        if role == "base":
            if kinds:
                f.append(("ERROR", "PACK-P07",
                          "role=base MUST NOT declare kinds (%d declared)"
                          % len(kinds)))
        elif role == "archetype":
            if not kinds:
                f.append(("ERROR", "PACK-P07",
                          "role=archetype requires at least one kind"))
        elif role == "kit":
            facet = KIT_CLASS_FACETS.get(kit_class)
            if facet == "kinds" and not kinds:
                f.append(("ERROR", "PACK-P07",
                          "kit_class=%r requires at least one kind (its facet is the "
                          "kind set)" % kit_class))
            # An unregistered or absent class asserts NO facet requirement. That
            # silence is the decision, not an omission: PACK-P08 above already named
            # the value, and requiring a facet here would re-close the open domain.

    # ── PACK-K01..K07: the per-kind rules ───────────────────────────────────
    seen_kind_ids = set()
    for kind in kinds:
        kid = kind.get("kind_id")
        label = kid if isinstance(kid, str) else "<kind_id absent>"
        missing = [name for name in KIND_REQUIRED_FIELDS if not kind.get(name)]
        if missing:
            f.append(("ERROR", "PACK-K01",
                      "kind %s is missing required field(s): %s"
                      % (label, ", ".join(missing))))
        if isinstance(kid, str) and kid:
            if not KIND_SLUG_RE.match(kid):
                f.append(("ERROR", "PACK-K02",
                          "kind_id %r is not a lowercase slug" % kid))
            elif kid in seen_kind_ids:
                f.append(("ERROR", "PACK-K02",
                          "kind_id %r is declared more than once in this pack" % kid))
            seen_kind_ids.add(kid)
        base_value = kind.get("base")
        if base_value is not None and base_value != "Work Item":
            f.append(("ERROR", "PACK-K03",
                      "kind %s declares base=%r; the base is the const \"Work Item\" "
                      "and no other base is permitted — a kind is a projection of the "
                      "one Work Item entity, never a new entity node"
                      % (label, base_value)))
        rels = kind.get("relationships")
        if isinstance(rels, dict):
            allowed = rels.get("allowed_types")
            if isinstance(allowed, list):
                stray = [a for a in allowed if a not in MVP_RELATIONSHIP_TYPES]
                if stray:
                    f.append(("ERROR", "PACK-K04",
                              "kind %s names relationship type(s) outside the 7 MVP "
                              "types: %s" % (label, ", ".join(stray))))
        proj = kind.get("methodology_projection")
        if isinstance(proj, dict):
            # ── PACK-K05 — THE CAPABILITY-BEARING RULE ───────────────────────
            # This is the rule the kit unit exists for. A grammar change that
            # relaxed only the pack-level applies_to would leave every kind
            # archetype-welded: the pack would validate, every gate would pass, and
            # the capability would be absent. That is why the deliberately
            # nonconforming fixture is a neutral kind inside a NON-kit pack rather
            # than a trivially malformed file.
            arch = proj.get("archetype")
            if arch == NEUTRAL_SENTINEL and not role_ok:
                pass
            elif arch == NEUTRAL_SENTINEL:
                if role != "kit":
                    f.append(("ERROR", "PACK-K05",
                              "kind %s sets methodology_projection.archetype=%s inside "
                              "a role=%s pack; the neutral sentinel is permitted ONLY "
                              "on a kind declared inside a role=kit pack"
                              % (label, NEUTRAL_SENTINEL, role)))
            elif arch not in ARCHETYPE_NAMES:
                f.append(("ERROR", "PACK-K05",
                          "kind %s sets methodology_projection.archetype=%r, which is "
                          "outside the archetype-name set (and %s is admissible only "
                          "inside a role=kit pack)"
                          % (label, arch, NEUTRAL_SENTINEL)))
            level = proj.get("general_level")
            if level not in GENERAL_LEVELS:
                f.append(("ERROR", "PACK-K06",
                          "kind %s sets general_level=%r, outside the Layer-1 level "
                          "taxonomy" % (label, level)))
            if not proj.get("projects_as"):
                f.append(("ERROR", "PACK-K07",
                          "kind %s is missing methodology_projection.projects_as"
                          % label))

    # ── PACK-L01/L02: the label contribution facet ──────────────────────────
    for row in pack["labels"]:
        group = row.get("group")
        if label_groups is not None and group not in label_groups:
            f.append(("ERROR", "PACK-L01",
                      "label group %r is not declared by the label grammar (declared: "
                      "%s)" % (group, ", ".join(sorted(label_groups)))))
        name = row.get("name")
        if isinstance(name, str) and name.startswith("type:"):
            projects_kind = row.get("projects_kind")
            if not projects_kind:
                f.append(("ERROR", "PACK-L02",
                          "label %r is a type:* row and MUST carry projects_kind"
                          % name))
            elif projects_kind not in seen_kind_ids:
                f.append(("ERROR", "PACK-L02",
                          "label %r has projects_kind=%r, which does not resolve into "
                          "this pack's kinds[]" % (name, projects_kind)))
    return f


def validate_packs(root, pack_root):
    """`--validate-packs`: conformance of a pack root against the meta-schema.

    Emits one row per finding, EACH CARRYING ITS RULE ID, so a rejection is
    attributable to a rule rather than to a bare exit code. That property is the whole
    point: a suite whose arms assert only "exit non-zero" greens on any single working
    rule and cannot tell a live rule from a dead one.

    Fail-loud in BOTH directions, inherited verbatim from the union reader above: a
    degraded parse and an empty pack root each exit 3. `packs_read=0` is an ERROR, not
    a clean pass — a mistyped `--pack-root` must never read as "no findings".
    """
    packs, degraded = read_pack_root(pack_root)
    if degraded:
        print("ERROR\tpack read is PARTIAL — " + "; ".join(degraded), file=sys.stderr)
        return 3
    if not packs:
        print("ERROR\tno pack.toml found under %s — a pack root that resolves to zero "
              "packs finds no violation BY CONSTRUCTION and must never read clean"
              % pack_root, file=sys.stderr)
        return 3

    label_groups, group_note = load_label_groups(root)
    packs_by_id = {}
    for _rel, pack in packs:
        pid = pack["meta"].get("pack_id")
        if isinstance(pid, str) and pid:
            packs_by_id[pid] = pack

    out = []
    kinds_read = sum(len(p["kinds"]) for _rel, p in packs)
    rules_evaluated = len(PACK_RULE_IDS) - (1 if label_groups is None else 0)
    out.append("PACKS\tpacks_read=%d kinds_read=%d rules_evaluated=%d"
               % (len(packs), kinds_read, rules_evaluated))
    if label_groups is None:
        out.append("SKIP\tPACK-L01\t" + group_note
                   + " — the rule was NOT evaluated (a hardcoded fallback list here "
                     "would be the duplicate source the grammar removed)")
    else:
        out.append("CTRL\tPACK-L01\t" + group_note)

    errors = 0
    for rel, pack in packs:
        for severity, rule_id, detail in _validate_one_pack(rel, pack, packs_by_id,
                                                            label_groups):
            out.append("%s\t%s\t%s\t%s" % (
                "FINDING" if severity == "ERROR" else "CAVEAT", rule_id, rel, detail))
            if severity == "ERROR":
                errors += 1
    out.append("COUNT\t%d" % errors)
    print("\n".join(out))
    return 1 if errors else 0


# Composition rank. The order is a property of the pack's ROLE and of the SELECTION
# SLOT it was named in — never of the configuration rung a pack was selected at, and
# never of its directory name. Later in this order wins a kind_id collision.
#
# WHY K4 IS AN ARGUMENT AND NOT AN INFERENCE. A K4 project override is an ordinary
# pack whose K4-ness is its LOCATION (Layer 2, projects/), and --pack-root reads one
# flat directory that carries no location signal. A rank derived from the pack file
# alone therefore cannot compute this position at all: it would silently rank a K4
# override as an archetype pack and let the kit beat it, which is the inverse of the
# documented precedence. So the caller passes the already-resolved override by name,
# exactly as it passes the already-resolved archetype and kit. Every rank below is
# supplied by an argument or by the role, so every rank is reachable and testable.
COMPOSITION_RANK = {"base": 0, "archetype": 1, "kit": 2, "k4": 3}


def resolve_archetype(root, pack_root, archetype, kit=None, k4=None):
    """`--resolve <archetype> [--kit <pack_id>] [--k4 <pack_id>]`: the eligible pack
    set and the kind union, by role, with per-kind provenance.

    This makes the grammar-side join EXECUTABLE. The kind-derivation contract the
    intake desk reads states the eligibility predicate in prose; before this mode
    nothing could run it, so prose-vs-behaviour drift was only findable by eye.

    ELIGIBILITY IS A TWO-LIMB MATCH, and both limbs are load-bearing:
        (a) applies_to == <archetype>                        — the archetype join, OR
        (b) applies_to == "*" AND role == "kit"              — the kit join.
    Limb (b) without its `role` conjunct would also admit the shared base pack (which
    bears no kinds) and a role=archetype pack claiming neutrality (a shape the grammar
    now forbids). A self-test arm proves that conjunct does observable work: the same
    file, with the same `applies_to = "*"`, is eligible as a kit and NOT eligible as an
    archetype pack.

    SELECTION NARROWS ELIGIBILITY; IT NEVER GRANTS IT. Without `--kit`, EVERY kit in
    the root is eligible for EVERY archetype — that is the point of limb (b), and it is
    why a selection is UNOBSERVABLE over a multi-kit root until it is named. With
    `--kit`, the eligible set is {packs whose applies_to == archetype} INTERSECTED with
    {the archetype packs} ∪ {the named kit}: every unselected kit is EXCLUDED naming the
    selection, and the selected kit still has to satisfy a limb on its own.

    THAT DISTINCTION IS LOAD-BEARING AND WAS FOUND BY RUNNING IT. An earlier form of
    this branch admitted the named kit unconditionally, on the reading that naming a
    kit selects it. The consequence is that a kit welded to one archetype at its header
    would be admitted under EVERY archetype, so the kit-eligible set would be invariant
    by construction and an orthogonality arm built on it could never fail — the
    gate-that-cannot-fail class, reproduced at the exact place this card was told to
    prove it had closed. Selection chooses AMONG eligible kits; the two-limb match
    stays the eligibility authority.

    SEL-RESOLVE — A SELECTION RESOLVES, OR IT FAILS LOUDLY. A `--kit` naming a pack
    absent from the root, or present but not role="kit", is exit 3 naming the pack and
    its actual role. It is NEVER a fall-through to "no kit selected". This is the whole
    replacement for the retired empty-vocabulary constraint: the hazard selection
    introduces is not emptiness (a conforming kit is mandatorily kind-bearing, so
    selecting one cannot empty the vocabulary) but that a FAILED selection and an
    ABSENT selection produce the SAME observation — a union with no kit-attributed
    rows. Making them different observations is the constraint.

    SCOPE BOUNDARY, stated rather than implied. This mode resolves ELIGIBILITY, the
    UNION and per-kind PROVENANCE. It does NOT validate pack conformance — a pack
    malformed as a kit is `--validate-packs`'s business (PACK-P05, PACK-K05); two
    modes, two jobs. And it asserts NO constraint about an empty union: an empty
    resolution is reported as a measured zero at exit 0.

    PROVENANCE IS DECLARATION-LEVEL, NOT FIELD-LEVEL. Each kind_id reports the pack
    whose declaration won. It does NOT prove the two declarations merged correctly
    field by field — record-level merge needs a real TOML parser, which the 3.9
    operator baseline lacks. Declaration-level precedence is executable here;
    field-level merge stays prose-governed in the meta-schema.
    """
    if archetype not in ARCHETYPE_NAMES:
        print("ERROR\t--resolve %r is not one of the archetype names (%s)"
              % (archetype, ", ".join(ARCHETYPE_NAMES)), file=sys.stderr)
        return 3
    packs, degraded = read_pack_root(pack_root)
    if degraded:
        print("ERROR\tpack read is PARTIAL — " + "; ".join(degraded), file=sys.stderr)
        return 3
    if not packs:
        print("ERROR\tno pack.toml found under %s — an empty pack root resolves an "
              "empty vocabulary BY CONSTRUCTION and must never read as a resolution"
              % pack_root, file=sys.stderr)
        return 3

    by_id = {}
    for rel, pack in packs:
        by_id[pack["meta"].get("pack_id") or rel] = pack

    # ── SEL-RESOLVE, enforced before anything is reported ────────────────────
    if kit is not None:
        if kit not in by_id:
            print("ERROR\t--kit %r names no pack under %s. A selection that cannot be "
                  "resolved is an ERROR, never a silent fall-through to 'no kit "
                  "selected': the legal state and the failure state must not produce "
                  "the same observation" % (kit, pack_root), file=sys.stderr)
            return 3
        kit_role = pack_role(by_id[kit])
        if kit_role != "kit":
            print("ERROR\t--kit %r names a pack whose role is %r, not 'kit'. Selecting "
                  "a non-kit pack as the kit is a failed selection, not an empty one, "
                  "and is reported rather than degraded to 'no kit selected'"
                  % (kit, kit_role), file=sys.stderr)
            return 3
    if k4 is not None and k4 not in by_id:
        # No role constraint: K4-ness is POSITIONAL, so a project's own override may
        # take any pack shape. Presence is the whole requirement, and its absence is
        # the same failed-selection class as --kit's.
        print("ERROR\t--k4 %r names no pack under %s. A selection that cannot be "
              "resolved is an ERROR, never a silent fall-through to 'no override'"
              % (k4, pack_root), file=sys.stderr)
        return 3

    # The slot column is emitted ONLY under a selection, and it earns its place
    # exactly there: with no selection every slot is derivable from the role, while a
    # --k4 pack's slot is NOT (its role may legitimately be `archetype`). Keeping it
    # off the unselected path is also what makes the plain `--resolve` output
    # byte-identical to its pre-change shape.
    selecting = kit is not None or k4 is not None

    header = ["RESOLVE", "archetype=%s" % archetype]
    if kit is not None:
        header.append("kit=%s" % kit)
    if k4 is not None:
        header.append("k4=%s" % k4)
    header += ["pack_root=%s" % pack_root, "packs_read=%d" % len(packs)]
    out = ["\t".join(header)]

    eligible = []
    for rel, pack in packs:
        role = pack_role(pack)
        applies_to = pack["meta"].get("applies_to")
        pid = pack["meta"].get("pack_id") or rel

        if k4 is not None and pid == k4:
            eligible.append((COMPOSITION_RANK["k4"], "k4", pid, role, pack))
            out.append("ELIGIBLE\t%s\trole=%s\tapplies_to=%s\tlimb=k4-selection"
                       % (pid, role, applies_to))
            continue
        if role == "base":
            out.append("BASE\t%s\trole=base\tapplies_to=%s\tinheritance root; "
                       "contributes no kinds" % (pid, applies_to))
            continue
        if role == "kit" and kit is not None and pid != kit:
            out.append("EXCLUDED\t%s\trole=kit\tapplies_to=%s\teligible by the kit "
                       "join, but %r is the selected kit" % (pid, applies_to, kit))
            continue

        limb_a = applies_to == archetype
        limb_b = applies_to == NEUTRAL_SENTINEL and role == "kit"
        if limb_a or limb_b:
            slot = "kit" if role == "kit" else "archetype"
            eligible.append((COMPOSITION_RANK[slot], slot, pid, role, pack))
            out.append("ELIGIBLE\t%s\trole=%s\tapplies_to=%s\tlimb=%s"
                       % (pid, role, applies_to,
                          "archetype-join" if limb_a else "kit-join"))
        else:
            out.append("EXCLUDED\t%s\trole=%s\tapplies_to=%s\tneither limb holds "
                       "for %s" % (pid, role, applies_to, archetype))

    # Later in the composition order wins on a colliding kind_id. `sorted` is on the
    # RANK only and is stable, so directory order is preserved WITHIN a rank and never
    # decides ACROSS one — a root whose directory names invert alphabetical order
    # resolves identically, which a self-test arm asserts.
    union = {}
    for rank, slot, pid, role, pack in sorted(eligible, key=lambda e: e[0]):
        for kind in pack["kinds"]:
            kid = kind.get("kind_id")
            if kid:
                union[kid] = (pid, role, slot)
    for kid in sorted(union):
        pid, role, slot = union[kid]
        row = "KIND\t%s\t%s\trole=%s" % (kid, pid, role)
        if selecting:
            row += "\tslot=%s" % slot
        out.append(row)
    out.append("COUNT\t%d" % len(union))
    if not union:
        out.append("NOTE\tthe eligible set contributed no kinds. This is a measured "
                   "zero, not an error: this mode asserts no constraint about an "
                   "empty vocabulary — that constraint belongs to the selection "
                   "surface, which owns what a deployment's selection may leave empty")
    print("\n".join(out))
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


    # ── PACK-CONFORMANCE ARMS (--validate-packs / --resolve) ────────────────
    # AUTHORED AGAINST A NAMED DEFECT, not merely alongside the feature. A sibling
    # self-test in this repo returned an identical pass count both patched and
    # unpatched: every arm asserted an exit code, so any one working rule greened all
    # of them and a dead rule was indistinguishable from a live one.
    #
    # The property that fixes it, and the rule every arm below obeys: an arm asserts
    # THE EXPECTED RULE ID **AND THE ABSENCE OF EVERY OTHER**. A dead rule fails its
    # own arm (its id goes missing); a rule that fires on everything fails every other
    # arm (its id intrudes). Neither failure is reachable by an exit-code assertion.
    #
    # Three further structural guards:
    #   * each conforming template is asserted CLEAN first, so "exactly this id" can
    #     never be satisfied by a template that was already dirty;
    #   * `_pc_exercised` accumulates every id any arm asserts, and the coverage arm at
    #     the end asserts it equals PACK_RULE_IDS — adding a rule without an arm
    #     reddens the suite rather than riding it;
    #   * the on-disk fixture arms run the SHIPPED fixtures through the SHIPPED CLI,
    #     and assert the fixture files are non-empty first, so a deleted fixture is a
    #     failure rather than a vacuous pass.

    _PC_TAXONOMY = ("# Labels\n\n## Label Groups\n\n"
                    "### Category Labels\nrows\n\n"
                    "### Status Labels\nrows\n")

    _PC_KIND_BODY = ('display_name = "Deliverable"\n'
                     'base = "Work Item"\n'
                     'axis1_state_machine = "inherit"\n'
                     '[kinds.methodology_projection]\n'
                     'archetype = "*"\n'
                     'general_level = "Work Item"\n'
                     'projects_as = "Deliverable"\n'
                     '[kinds.fields]\n'
                     'core = "inherit"\n'
                     '[kinds.criteria.readiness]\n'
                     'criteria_version = "0.1.0"\n'
                     '[kinds.criteria.done]\n'
                     'criteria_version = "0.1.0"\n'
                     '[kinds.criteria.gate]\n'
                     'criteria_version = "0.1.0"\n'
                     '[kinds.relationships]\n'
                     'allowed_types = ["BELONGS_TO", "RELATES_TO"]\n'
                     '[kinds.lifecycle_behavior]\n'
                     'timeboxed = "gate"\n')

    # A conforming KIT: neutral at the pack level AND at the kind level, kit_class
    # registered, one kind, one type:* label row joining back to it.
    _PC_KIT = ('[meta]\n'
               'pack_id = "t-kit"\n'
               'pack_version = "0.1.0"\n'
               'applies_to = "*"\n'
               'role = "kit"\n'
               'kit_class = "work-item"\n\n'
               '[[kinds]]\n'
               'kind_id = "deliverable"\n'
               + _PC_KIND_BODY
               + '\n[[labels]]\n'
                 'group = "category"\n'
                 'name = "type:deliverable"\n'
                 'projects_kind = "deliverable"\n')
    # The same kit with no label facet — used by the arms whose single mutation would
    # otherwise ALSO break the label join and emit a second id.
    _PC_KIT_NL = _PC_KIT[:_PC_KIT.index("\n[[labels]]")] + "\n"

    _PC_ARCH = ('[meta]\n'
                'pack_id = "t-arch"\n'
                'pack_version = "0.1.0"\n'
                'applies_to = "Scrum"\n'
                'role = "archetype"\n\n'
                '[[kinds]]\n'
                'kind_id = "story"\n'
                + _PC_KIND_BODY.replace('archetype = "*"', 'archetype = "Scrum"')
                               .replace('"Deliverable"', '"Story"'))

    _PC_BASE = ('[meta]\n'
                'pack_id = "t-base"\n'
                'pack_version = "0.1.0"\n'
                'applies_to = "*"\n'
                'role = "base"\n')

    def _pc_root(tmp, packs, taxonomy=None):
        """(root, pack_root). `--root` carries repo context (the label grammar);
        `--pack-root` selects which pack tree to read. Separating them is what lets a
        fixture tree be validated against the real label grammar."""
        pack_root = os.path.join(tmp, "fixtures")
        for name, text in packs.items():
            d = os.path.join(pack_root, name)
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "pack.toml"), "w", encoding="utf-8") as fh:
                fh.write(text)
        if taxonomy is not None:
            d = os.path.join(tmp, "core", "specs")
            os.makedirs(d, exist_ok=True)
            with open(os.path.join(d, "label-taxonomy.md"), "w",
                      encoding="utf-8") as fh:
                fh.write(taxonomy)
        return tmp, pack_root

    def _pc_cli(root, args):
        cp = subprocess.run([sys.executable, os.path.abspath(__file__),
                             "--root", root] + list(args),
                            capture_output=True, text=True)
        return cp.returncode, cp.stdout, cp.stderr

    def _pc_rows(stdout, tag):
        return [ln.split("\t") for ln in stdout.split("\n") if ln.startswith(tag + "\t")]

    def _pc_ids(stdout):
        return set(r[1] for r in _pc_rows(stdout, "FINDING"))

    def _pc_caveat_ids(stdout):
        return set(r[1] for r in _pc_rows(stdout, "CAVEAT"))

    _pc_exercised = set()

    def _pc_arm(name, packs, expect_ids, taxonomy=None, expect_caveats=(),
                expect_rc=None):
        with tempfile.TemporaryDirectory() as tmp:
            root, pack_root = _pc_root(tmp, packs, taxonomy)
            rc, out, _err = _pc_cli(root, ("--validate-packs",
                                           "--pack-root", pack_root))
            got, cav = _pc_ids(out), _pc_caveat_ids(out)
            want = set(expect_ids)
            want_cav = set(expect_caveats)
            want_rc = expect_rc if expect_rc is not None else (1 if want else 0)
            check(name, got == want and cav == want_cav and rc == want_rc)
        _pc_exercised.update(want)
        _pc_exercised.update(want_cav)

    # ── CONTROLS: each conforming template must be CLEAN ─────────────────────
    _pc_arm("PC control: a conforming kit validates clean", {"k": _PC_KIT}, ())
    _pc_arm("PC control: a conforming archetype pack validates clean",
            {"a": _PC_ARCH}, ())
    _pc_arm("PC control: a conforming base pack validates clean", {"b": _PC_BASE}, ())
    # The RELAXATION, as an accepted shape: a kit MAY extend the base pack.
    _pc_arm("PC control: a kit extending the base pack is accepted (the relaxation)",
            {"b": _PC_BASE,
             "k": _PC_KIT.replace('kit_class = "work-item"',
                                  'kit_class = "work-item"\nextends = "t-base"')}, ())

    # ── ONE SINGLE-FIELD MUTATION PER RULE ───────────────────────────────────
    _pc_arm("PC PACK-P01 fires alone on a malformed pack_id",
            {"k": _PC_KIT.replace('pack_id = "t-kit"', 'pack_id = "T Kit"')},
            ("PACK-P01",))
    _pc_arm("PC PACK-P02 fires alone on a non-semver pack_version",
            {"k": _PC_KIT.replace('pack_version = "0.1.0"', 'pack_version = "0.1"')},
            ("PACK-P02",))
    # P03 is DOMAIN membership; P05 is the role weld given a legal value. Layered so
    # each has a mutation that emits it alone.
    _pc_arm("PC PACK-P03 fires alone on an out-of-domain applies_to",
            {"a": _PC_ARCH.replace('applies_to = "Scrum"', 'applies_to = "Agile"')},
            ("PACK-P03",))
    _pc_arm("PC PACK-P04 fires alone on an unknown role, and the role-branching "
            "rules stay silent",
            {"k": _PC_KIT.replace('role = "kit"', 'role = "kitt"')},
            ("PACK-P04",))
    _pc_arm("PC PACK-P05 fires alone when an archetype pack claims neutrality "
            "(the restriction axis)",
            {"a": _PC_ARCH.replace('applies_to = "Scrum"', 'applies_to = "*"')},
            ("PACK-P05",))
    _pc_arm("PC PACK-P06 fires alone when a base pack declares extends",
            {"b": _PC_BASE + 'extends = "t-x"\n'}, ("PACK-P06",))
    _pc_arm("PC PACK-P06 fires alone when a kit is named as an extends target",
            {"k": _PC_KIT,
             "a": _PC_ARCH.replace('role = "archetype"',
                                   'role = "archetype"\nextends = "t-kit"')},
            ("PACK-P06",))
    _pc_arm("PC PACK-P06 an ABSENT extends target is a caveat, never an error "
            "(a deselected pack is configuration)",
            {"a": _PC_ARCH.replace('role = "archetype"',
                                   'role = "archetype"\nextends = "t-nowhere"')},
            (), expect_caveats=("PACK-P06",), expect_rc=0)

    # ── PACK-P07, THE TWO-LEVEL RULE — all four limbs ────────────────────────
    _pc_arm("PC PACK-P07 fires alone when a base pack declares kinds (D7)",
            {"b": _PC_BASE + '\n[[kinds]]\nkind_id = "deliverable"\n' + _PC_KIND_BODY
                             .replace('archetype = "*"', 'archetype = "Scrum"')},
            ("PACK-P07",))
    _pc_arm("PC PACK-P07 fires alone when an archetype pack declares no kinds",
            {"a": _PC_ARCH[:_PC_ARCH.index("\n[[kinds]]")] + "\n"}, ("PACK-P07",))
    _pc_arm("PC PACK-P07 fires alone when a work-item kit declares no kinds",
            {"k": _PC_KIT_NL[:_PC_KIT_NL.index("\n[[kinds]]")] + "\n"}, ("PACK-P07",))
    # THE LIMB THAT PROVES THE RULE IS TWO-LEVEL, and the reason the correction was
    # carried. Requiredness is selected by kit_class, NOT by role: an unregistered
    # class asserts no facet requirement, so a kindless kit of that class is a CAVEAT
    # naming the class and NOT a PACK-P07 rejection. Under a role-conditioned rule
    # this arm would emit PACK-P07, every future kit class would be hard-rejected on
    # that row, and PACK-P08's open domain would be unreachable.
    _pc_arm("PC PACK-P07 does NOT fire for an unregistered kit_class with no kinds "
            "— requiredness is selected by kit_class, not by role",
            {"k": (_PC_KIT_NL[:_PC_KIT_NL.index("\n[[kinds]]")] + "\n")
                  .replace('kit_class = "work-item"', 'kit_class = "field"')},
            (), expect_caveats=("PACK-P08",), expect_rc=0)

    _pc_arm("PC PACK-P08 fires alone when a kit omits kit_class",
            {"k": _PC_KIT.replace('kit_class = "work-item"\n', "")}, ("PACK-P08",))
    _pc_arm("PC PACK-P08 fires alone when a non-kit pack sets kit_class",
            {"a": _PC_ARCH.replace('role = "archetype"',
                                   'role = "archetype"\nkit_class = "work-item"')},
            ("PACK-P08",))

    # ── The per-kind rules ───────────────────────────────────────────────────
    _pc_arm("PC PACK-K01 fires alone on a kind missing a required field",
            {"k": _PC_KIT.replace('display_name = "Deliverable"\n', "")},
            ("PACK-K01",))
    _pc_arm("PC PACK-K02 fires alone on a non-slug kind_id",
            {"k": _PC_KIT_NL.replace('kind_id = "deliverable"',
                                     'kind_id = "Deliverable"')},
            ("PACK-K02",))
    _pc_arm("PC PACK-K03 fires alone on a base other than the const Work Item",
            {"k": _PC_KIT.replace('base = "Work Item"', 'base = "Epic"')},
            ("PACK-K03",))
    _pc_arm("PC PACK-K04 fires alone on a relationship type outside the 7 MVP types",
            {"k": _PC_KIT.replace('allowed_types = ["BELONGS_TO", "RELATES_TO"]',
                                  'allowed_types = ["BELONGS_TO", "OWNS"]')},
            ("PACK-K04",))
    # THE CAPABILITY-BEARING RULE. This is the exact shape that would make the kit
    # unit appear to land while delivering nothing: kind-level neutrality asserted
    # OUTSIDE a kit pack.
    _pc_arm("PC PACK-K05 fires alone on a neutral kind inside a non-kit pack "
            "(the capability-bearing rule)",
            {"a": _PC_ARCH.replace('archetype = "Scrum"\ngeneral_level',
                                   'archetype = "*"\ngeneral_level')},
            ("PACK-K05",))
    _pc_arm("PC PACK-K05 fires alone on an archetype value outside the name set",
            {"a": _PC_ARCH.replace('archetype = "Scrum"\ngeneral_level',
                                   'archetype = "Agile"\ngeneral_level')},
            ("PACK-K05",))
    _pc_arm("PC PACK-K06 fires alone on a general_level outside the taxonomy",
            {"k": _PC_KIT.replace('general_level = "Work Item"',
                                  'general_level = "Sprint"')},
            ("PACK-K06",))
    _pc_arm("PC PACK-K07 fires alone on a kind missing projects_as",
            {"k": _PC_KIT.replace('projects_as = "Deliverable"\n', "")},
            ("PACK-K07",))

    # ── The label facet ──────────────────────────────────────────────────────
    _pc_arm("PC PACK-L01 fires alone on a group the label grammar does not declare",
            {"k": _PC_KIT.replace('group = "category"', 'group = "colour"')},
            ("PACK-L01",), taxonomy=_PC_TAXONOMY)
    _pc_arm("PC PACK-L01 control: a declared group is accepted from the SAME grammar",
            {"k": _PC_KIT}, (), taxonomy=_PC_TAXONOMY)
    _pc_arm("PC PACK-L02 fires alone when projects_kind does not resolve",
            {"k": _PC_KIT.replace('projects_kind = "deliverable"',
                                  'projects_kind = "no-such-kind"')},
            ("PACK-L02",))
    _pc_arm("PC PACK-L02 fires alone when a type:* row omits projects_kind",
            {"k": _PC_KIT.replace('projects_kind = "deliverable"\n', "")},
            ("PACK-L02",))

    # ── PACK-L01 is NOT-EVALUATED, not silently passed, without its grammar ──
    with tempfile.TemporaryDirectory() as tmp:
        root, pack_root = _pc_root(tmp, {"k": _PC_KIT.replace('group = "category"',
                                                              'group = "colour"')})
        rc, out, _err = _pc_cli(root, ("--validate-packs", "--pack-root", pack_root))
        check("PC PACK-L01 emits SKIP (not a silent pass) when the label grammar is "
              "unreadable",
              rc == 0
              and any(r[1] == "PACK-L01" for r in _pc_rows(out, "SKIP"))
              and "PACK-L01" not in _pc_ids(out)
              and "rules_evaluated=%d" % (len(PACK_RULE_IDS) - 1) in out)

    # ── DK-8: SECTION SCOPING. A control's own `applies_to` must not be read as
    # the pack header's. The mutation is chosen so a line-anchored reader would
    # MIS-VERDICT: it would see `applies_to = "*"` on a role=archetype pack and
    # emit PACK-P05. A section-scoped reader emits nothing.
    _pc_arm("PC section scoping: a [[controls]] applies_to does not reach the pack "
            "header verdict",
            {"a": _PC_ARCH + ('\n[[controls]]\n'
                              'control_id = "arch-review"\n'
                              'display_name = "Architecture Review"\n'
                              'applies_to = "*"\n'
                              '[controls.applies_to]\n'
                              'levels = ["Work Item"]\n'
                              'kinds = ["*"]\n')},
            ())

    # ── NON-VACUITY: fail loud in BOTH directions ────────────────────────────
    with tempfile.TemporaryDirectory() as tmp:
        empty_root = os.path.join(tmp, "fixtures")
        os.makedirs(empty_root, exist_ok=True)
        rc, out, err = _pc_cli(tmp, ("--validate-packs", "--pack-root", empty_root))
        check("PC an empty pack root EXITS 3 rather than reporting a clean zero",
              rc == 3 and "no pack.toml found" in err and "COUNT" not in out)

    with tempfile.TemporaryDirectory() as tmp:
        root, pack_root = _pc_root(tmp, {"k": _PC_KIT.replace(
            'kind_id = "deliverable"\n', "")})
        rc, _out, err = _pc_cli(root, ("--validate-packs", "--pack-root", pack_root))
        check("PC a [[kinds]] table yielding no kind_id is a PARTIAL read, exit 3",
              rc == 3 and "PARTIAL" in err)

    # ── --resolve: THE TWO-LIMB MATCH, with the discriminating RED arm ───────
    _PC_NEUTRAL_ARCH = _PC_KIT_NL.replace('role = "kit"', 'role = "archetype"') \
                                 .replace('kit_class = "work-item"\n', "")
    with tempfile.TemporaryDirectory() as tmp:
        root, pack_root = _pc_root(tmp, {"a": _PC_ARCH, "k": _PC_KIT_NL})
        rc, out, _err = _pc_cli(root, ("--resolve", "Scrum", "--pack-root", pack_root))
        kinds = set(r[1] for r in _pc_rows(out, "KIND"))
        limbs = set(r[4] for r in _pc_rows(out, "ELIGIBLE"))
        check("PC --resolve GREEN: the archetype join and the kit join both "
              "contribute, and each row names its limb",
              rc == 0 and kinds == {"story", "deliverable"}
              and limbs == {"limb=archetype-join", "limb=kit-join"})

    with tempfile.TemporaryDirectory() as tmp:
        # THE RED ARM, and it is executed rather than hypothetical. The second pack is
        # byte-for-byte the kit except for its `role`: same `applies_to = "*"`, same
        # kind. Under a one-limb rule keyed on `applies_to` alone it would be eligible
        # and `deliverable` would appear. It must not.
        root, pack_root = _pc_root(tmp, {"a": _PC_ARCH, "k": _PC_NEUTRAL_ARCH})
        rc, out, _err = _pc_cli(root, ("--resolve", "Scrum", "--pack-root", pack_root))
        kinds = set(r[1] for r in _pc_rows(out, "KIND"))
        check("PC --resolve RED: a neutral pack whose role is NOT kit is EXCLUDED — "
              "the role conjunct does observable work",
              rc == 0 and kinds == {"story"}
              and any(r[1] == "t-kit" for r in _pc_rows(out, "EXCLUDED")))

    with tempfile.TemporaryDirectory() as tmp:
        root, pack_root = _pc_root(tmp, {"a": _PC_ARCH, "k": _PC_KIT_NL,
                                         "b": _PC_BASE})
        rc, out, _err = _pc_cli(root, ("--resolve", "Kanban",
                                       "--pack-root", pack_root))
        kinds = set(r[1] for r in _pc_rows(out, "KIND"))
        check("PC --resolve SPECIFICITY: the kit joins every archetype, the Scrum "
              "pack joins only Scrum, and the base pack contributes no kinds",
              rc == 0 and kinds == {"deliverable"}
              and any(r[1] == "t-base" for r in _pc_rows(out, "BASE")))

    with tempfile.TemporaryDirectory() as tmp:
        empty_root = os.path.join(tmp, "fixtures")
        os.makedirs(empty_root, exist_ok=True)
        rc, _out, err = _pc_cli(tmp, ("--resolve", "Scrum", "--pack-root", empty_root))
        check("PC --resolve over an empty pack root EXITS 3, never an empty resolution",
              rc == 3 and "empty pack root" in err)

    with tempfile.TemporaryDirectory() as tmp:
        root, pack_root = _pc_root(tmp, {"a": _PC_ARCH})
        rc, _out, err = _pc_cli(root, ("--resolve", "Agile", "--pack-root", pack_root))
        check("PC --resolve rejects an archetype outside the name set, exit 3",
              rc == 3 and "not one of the archetype names" in err)

    # ── THE SHIPPED FIXTURES AND THE SHIPPED PACKS, through the shipped CLI ──
    _pc_repo = os.path.dirname(os.path.dirname(os.path.dirname(
        os.path.dirname(os.path.abspath(__file__)))))
    _pc_fx = os.path.join(_pc_repo, "core", "deploy", "tests", "fixtures", "packs")
    _pc_ok = os.path.join(_pc_fx, "conforming-kit", "pack.toml")
    _pc_bad = os.path.join(_pc_fx, "nonconforming-kit", "pack.toml")
    # NON-VACUITY FIRST: a deleted or truncated fixture must fail here rather than
    # let the two arms below pass on nothing.
    check("PC fixture control: both shipped fixtures exist and are non-empty",
          os.path.isfile(_pc_ok) and os.path.getsize(_pc_ok) > 0
          and os.path.isfile(_pc_bad) and os.path.getsize(_pc_bad) > 0)

    rc, out, _err = _pc_cli(_pc_repo, ("--validate-packs", "--pack-root",
                                       os.path.join(_pc_fx, "conforming-kit")))
    check("PC ACCEPTS the shipped conforming kit fixture (exit 0, no finding)",
          rc == 0 and _pc_ids(out) == set() and "packs_read=1" in out)

    rc, out, _err = _pc_cli(_pc_repo, ("--validate-packs", "--pack-root",
                                       os.path.join(_pc_fx, "nonconforming-kit")))
    check("PC REJECTS the shipped nonconforming fixture under PACK-K05 and no other "
          "rule", rc == 1 and _pc_ids(out) == {"PACK-K05"})

    rc, out, _err = _pc_cli(_pc_repo, ("--validate-packs", "--pack-root",
                                       os.path.join(_pc_repo, "core", "packs")))
    check("PC the three shipped packs validate clean against the widened grammar",
          rc == 0 and _pc_ids(out) == set() and "packs_read=3" in out)

    # R-6 GUARD, EXECUTED: the licensed-kind union walks every directory under
    # core/packs/ with no allowlist and no naming filter, so a fixture placed there
    # would silently join the live gate's vocabulary. This asserts the fixture home
    # held — the union is exactly the shipped packs' kinds and carries none of the
    # fixture kinds.
    rc, out, _err = _pc_cli(_pc_repo, ("--emit-kinds",))
    _pc_vocab = set(out.split())
    check("PC fixture-home guard: the licensed-kind union carries no fixture kind",
          rc == 0 and _pc_vocab and "deliverable" not in _pc_vocab
          and "story" in _pc_vocab)

    # ── SEL-*: SELECTION, over the shipped two-axis fixture root ─────────────
    # WHY A DEDICATED ROOT. These arms read `fixtures/packs/selection/`, not the
    # shared `fixtures/packs/` parent. The parent is a denominator THREE cards write
    # into, so an arm reading it would have a population a sibling card can change —
    # its verdict would then move for reasons that are not this card's behaviour. The
    # subdirectory keeps the single fixture home while giving these arms a population
    # only this card owns.
    _sel_root = os.path.join(_pc_repo, "core", "deploy", "tests", "fixtures",
                             "packs", "selection")

    def _sel(archetype, kit=None, k4=None, root=None):
        args = ["--resolve", archetype, "--pack-root", root or _sel_root]
        if kit:
            args += ["--kit", kit]
        if k4:
            args += ["--k4", k4]
        return _pc_cli(_pc_repo, tuple(args))

    def _sel_elig(out, role):
        """{pack_id} of ELIGIBLE packs with the given role — the ELIGIBILITY set.

        ORTHOGONALITY IS A PROPERTY OF ELIGIBILITY, NOT OF THE UNION, and reading the
        wrong one is a mistake this suite made before it was corrected by running it.
        The kind UNION legitimately moves when either axis changes, because COMPOSITION
        resolves collisions and that is a different operation from SELECTION: when the
        selected kit stops declaring a colliding kind_id, an archetype pack's own
        declaration of that kind stops being masked and surfaces. A union-level
        predicate therefore reports non-orthogonality for a reason that is correct
        precedence behaviour. What must be invariant is WHICH PACKS EACH AXIS MAKES
        ELIGIBLE, and that is what these arms compare."""
        return set(r[1] for r in _pc_rows(out, "ELIGIBLE") if r[2] == "role=" + role)

    def _sel_slots(out, slot):
        """{pack_id} of KIND provenance rows whose composition slot is `slot`."""
        return set(r[2] for r in _pc_rows(out, "KIND")
                   if len(r) > 4 and r[4] == "slot=" + slot)

    def _sel_kinds(out, slot=None):
        return set(r[1] for r in _pc_rows(out, "KIND")
                   if slot is None or r[4] == "slot=" + slot)

    # NON-VACUITY FIRST. Every arm below reads seven tracked fixture packs; a deleted
    # or renamed fixture must fail HERE, naming the cause, rather than silently
    # shrinking every population downstream into a set of vacuous passes.
    _sel_expect = ("sel-common", "sel-scrum", "sel-kanban", "sel-kit-alpha",
                   "sel-kit-beta", "sel-kit-gamma", "sel-k4-override")
    check("SEL-00 non-vacuity: all 7 selection fixtures are present and readable",
          os.path.isdir(_sel_root)
          and all(os.path.isfile(os.path.join(_sel_root, d, "pack.toml"))
                  for d in _sel_expect))

    # SEL-E01/E02/E03 — SEL-RESOLVE, the constraint that REPLACES the retired
    # empty-vocabulary rule. A selection resolves or it fails loudly; a failed
    # selection and an absent selection must never be the same observation.
    rc, out, err = _sel("Scrum", kit="sel-kit-nonexistent")
    check("SEL-E01 --kit naming a pack absent from the root EXITS 3 — never a silent "
          "fall-through to 'no kit selected'",
          rc == 3 and "names no pack under" in err and "sel-kit-nonexistent" in err)

    rc, out, err = _sel("Scrum", kit="sel-scrum")
    check("SEL-E02 --kit naming a present pack whose role is NOT kit EXITS 3, naming "
          "the role it actually has",
          rc == 3 and "not 'kit'" in err and "'archetype'" in err)

    rc, out, err = _sel("Scrum", k4="sel-k4-nonexistent")
    check("SEL-E03 --k4 naming a pack absent from the root EXITS 3 — the same "
          "failed-selection class as --kit's",
          rc == 3 and "names no pack under" in err and "sel-k4-nonexistent" in err)

    # THE DISCRIMINATING PAIR for E01/E02: the legal state must be exit 0. Without
    # this, an unconditional exit 3 would satisfy all three arms above.
    rc, out, _e = _sel("Scrum")
    check("SEL-E0x NO selection at all is exit 0 with a real union — the legal state "
          "and the failure state are different observations",
          rc == 0 and len(_sel_kinds(out)) > 0)

    # SEL-03 — the AC-3 assertion, made mechanically checkable: the selection path
    # consumes ALREADY-RESOLVED values and reads no configuration file, so it is not a
    # second resolver. Asserted over the function source, with a live control arm.
    _sel_src = inspect.getsource(resolve_archetype)
    _sel_cfg_tokens = ("operator.toml", "platform-config.toml", "PROJECT.md",
                       "PORTFOLIO.md", "program-config.toml")
    check("SEL-03 the --resolve/--kit/--k4 code path names NO configuration file — it "
          "consumes resolved inputs and introduces no parallel resolver",
          not any(t in _sel_src for t in _sel_cfg_tokens)
          # control arm: the tokens ARE findable by this reader elsewhere in the tool,
          # so the zero above is a measured absence and not a dead search.
          and any(t in open(os.path.abspath(__file__), encoding="utf-8").read()
                  for t in _sel_cfg_tokens))

    # SEL-04a / SEL-04b — ORTHOGONALITY, asserted at the level where it is actually a
    # structural property: ELIGIBILITY. The kind UNION legitimately changes when either
    # axis moves (composition resolves collisions, and that is a different operation
    # from selection), so a union-level predicate would fail for the wrong reason.
    _, out_s_a, _e = _sel("Scrum", kit="sel-kit-alpha")
    _, out_k_a, _e = _sel("Kanban", kit="sel-kit-alpha")
    check("SEL-04a vary the ARCHETYPE with the kit fixed — the KIT-eligible set is "
          "unchanged; the kit join does not read the archetype",
          _sel_elig(out_s_a, "kit") == _sel_elig(out_k_a, "kit") == {"sel-kit-alpha"}
          # control: the ARCHETYPE-eligible half must genuinely differ, or the
          # comparison above is between two constants and proves nothing.
          and _sel_elig(out_s_a, "archetype") != _sel_elig(out_k_a, "archetype"))

    _, out_s_b, _e = _sel("Scrum", kit="sel-kit-beta")
    check("SEL-04b vary the KIT with the archetype fixed — the ARCHETYPE-eligible set "
          "is unchanged; the archetype join does not read the kit",
          _sel_elig(out_s_a, "archetype") == _sel_elig(out_s_b, "archetype")
          and len(_sel_elig(out_s_a, "archetype")) > 0
          # control: the KIT-eligible half must genuinely differ.
          and _sel_elig(out_s_a, "kit") != _sel_elig(out_s_b, "kit"))

    # SEL-04x — THE FAIL-CAPABILITY ARM. sel-kit-gamma is a kit welded to one archetype
    # at its HEADER, so it satisfies the kit join under Scrum only. Running SEL-04a's
    # own predicate over it must therefore FAIL. An orthogonality check that cannot
    # produce a non-orthogonal verdict is not a check, and this arm is what proves it
    # can. NOTE the weld is at the header deliberately: a kit welded only at its KINDS
    # still satisfies the kit join under every archetype, so its contribution is
    # invariant by construction and no arm built on it could ever fail.
    _, out_s_g, _e = _sel("Scrum", kit="sel-kit-gamma")
    _, out_k_g, _e = _sel("Kanban", kit="sel-kit-gamma")
    check("SEL-04x the SAME orthogonality predicate over an archetype-welded kit FAILS "
          "— the check can render a non-orthogonal verdict",
          _sel_elig(out_s_g, "kit") == {"sel-kit-gamma"}
          and _sel_elig(out_k_g, "kit") == set()
          # i.e. SEL-04a's predicate, evaluated here, is FALSE — which is the point.
          and _sel_elig(out_s_g, "kit") != _sel_elig(out_k_g, "kit"))

    # SEL-05a / SEL-05b — PRECEDENCE. Same root, same packs; ONLY the K4 naming moves,
    # and the winner of the colliding kind_id flips with it.
    _, out_nok4, _e = _sel("Scrum", kit="sel-kit-alpha")
    _, out_k4, _e = _sel("Scrum", kit="sel-kit-alpha", k4="sel-k4-override")

    def _owner(out, kid):
        """(pack_id, slot) for a kind_id. The slot column is present only under a
        selection, so it is read defensively — an arm that ran without --kit/--k4
        must still be able to name the winning pack."""
        for r in _pc_rows(out, "KIND"):
            if r[1] == kid:
                return r[2], (r[4] if len(r) > 4 else None)
        return (None, None)

    check("SEL-05a a K4 project override BEATS the selected kit on a colliding "
          "kind_id — and the same root resolves to the kit when it is not named",
          _owner(out_nok4, "sel-shared") == ("sel-kit-alpha", "slot=kit")
          and _owner(out_k4, "sel-shared") == ("sel-k4-override", "slot=k4"))

    check("SEL-05b precedence is per-kind, not wholesale replacement — a kind only the "
          "kit declares still resolves to the kit under a K4 override",
          _owner(out_k4, "sel-alpha-only") == ("sel-kit-alpha", "slot=kit"))

    # SEL-05c — the slot column earns its place. The K4 pack's ROLE is `archetype`, so
    # role alone cannot express that it composed at the K4 position; without the slot
    # the winning row would be indistinguishable from an ordinary archetype win.
    check("SEL-05c the K4 winner reports role=archetype AND slot=k4 — K4-ness is "
          "positional and is not derivable from the role",
          _owner(out_k4, "sel-shared") == ("sel-k4-override", "slot=k4")
          and any(r[1] == "sel-k4-override" and r[2] == "role=archetype"
                  and r[4] == "limb=k4-selection"
                  for r in _pc_rows(out_k4, "ELIGIBLE")))

    # SEL-05x — RANK, NOT NAME, decides. Two roots identical in content whose directory
    # names INVERT the alphabetical order of their composition ranks must resolve to
    # identical provenance. Under `sorted(os.listdir())` with no rank the winner would
    # follow the directory name.
    _sel_kit_txt = ('[meta]\npack_id = "z-kit"\npack_version = "0.1.0"\n'
                    'applies_to = "*"\nrole = "kit"\nkit_class = "work-item"\n\n'
                    '[[kinds]]\nkind_id = "collide"\n' + _PC_KIND_BODY)
    _sel_arch_txt = ('[meta]\npack_id = "a-arch"\npack_version = "0.1.0"\n'
                     'applies_to = "Scrum"\nrole = "archetype"\n\n'
                     '[[kinds]]\nkind_id = "collide"\n'
                     + _PC_KIND_BODY.replace('archetype = "*"', 'archetype = "Scrum"'))
    with tempfile.TemporaryDirectory() as tmp:
        # Directory names chosen so alphabetical order and rank order DISAGREE.
        root, pack_root = _pc_root(tmp, {"zzz-the-kit": _sel_kit_txt,
                                         "aaa-the-archetype": _sel_arch_txt})
        _rc1, o1, _e = _pc_cli(root, ("--resolve", "Scrum", "--pack-root", pack_root))
    with tempfile.TemporaryDirectory() as tmp:
        root, pack_root = _pc_root(tmp, {"aaa-the-kit": _sel_kit_txt,
                                         "zzz-the-archetype": _sel_arch_txt})
        _rc2, o2, _e = _pc_cli(root, ("--resolve", "Scrum", "--pack-root", pack_root))
    check("SEL-05x name-inverted roots resolve to IDENTICAL provenance — composition "
          "rank decides a collision, never the directory name",
          _owner(o1, "collide") == _owner(o2, "collide") == ("z-kit", None)
          or (_owner(o1, "collide")[0] == _owner(o2, "collide")[0] == "z-kit"))

    # SEL-R01 — the extension is confined to the selection invocation. `--resolve`
    # WITHOUT a selection flag must be unchanged, and the slot column must be absent.
    _, out_plain, _e = _sel("Scrum")
    check("SEL-R01 --resolve without --kit/--k4 emits NO slot column — the extension "
          "does not perturb the incumbent output shape",
          all(len(r) == 4 for r in _pc_rows(out_plain, "KIND"))
          # control: with a selection the column IS present, so the absence above is a
          # measured absence rather than a reader that never finds the field.
          and all(len(r) == 5 for r in _pc_rows(out_k4, "KIND")))

    # SEL-R02 — a selection flag with no --resolve is LOUD. Dropping it silently would
    # be the same silent-drop class SEL-RESOLVE exists to close, and worse, because the
    # caller would believe a selection had been applied.
    rc, _o, err = _pc_cli(_pc_repo, ("--kit", "sel-kit-alpha", "--skip-backlog"))
    check("SEL-R02 --kit passed without --resolve EXITS 3 rather than being ignored",
          rc == 3 and "modifiers on --resolve" in err)

    # ── COVERAGE META-ARM ────────────────────────────────────────────────────
    # Every rule the reader can emit is exercised by an arm that fails when its rule
    # is mutated. A rule added without an arm reddens THIS case rather than riding a
    # green suite — which is the failure mode the whole block is written against.
    check("PC coverage: every PACK-* rule id is exercised by a mutation arm",
          _pc_exercised == set(PACK_RULE_IDS))

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
    ap.add_argument("--validate-packs", action="store_true",
                    help="validate a pack root against the work-item type-pack "
                         "meta-schema; emits one row per finding CARRYING ITS RULE ID, "
                         "so a rejection is attributable to a rule rather than to an "
                         "exit code. Exits 3 on a partial read or an empty pack root")
    ap.add_argument("--resolve", metavar="ARCHETYPE",
                    help="print the packs eligible for ARCHETYPE and the kind union, "
                         "each row tagged by role. Eligibility is the two-limb match: "
                         "applies_to == ARCHETYPE, OR applies_to == '*' AND "
                         "role == 'kit'. Resolves eligibility and the union only — "
                         "WHICH kit a deployment selected is a configuration-axis "
                         "question upstream of this mode")
    ap.add_argument("--kit", metavar="PACK_ID", default=None,
                    help="the ALREADY-RESOLVED work-item kit selection, for --resolve. "
                         "Narrows the eligible set to the archetype's packs plus this "
                         "kit; every other kit is EXCLUDED naming the selection. Takes "
                         "a resolved value and reads no configuration file, exactly as "
                         "--resolve takes a resolved archetype. A PACK_ID absent from "
                         "the root, or present but not role='kit', is exit 3 — never a "
                         "silent fall-through to 'no kit selected'")
    ap.add_argument("--k4", metavar="PACK_ID", default=None,
                    help="the ALREADY-RESOLVED project-level (K4) override pack, for "
                         "--resolve. Composes LAST, so it wins a kind_id collision "
                         "against the kit. Passed by name because K4-ness is positional "
                         "(Layer 2) and a flat pack root carries no location signal. No "
                         "role constraint; absence from the root is exit 3")
    ap.add_argument("--pack-root", default=None,
                    help="pack tree for --validate-packs / --resolve. Accepts either a "
                         "directory holding pack.toml directly, or a directory of pack "
                         "directories. Defaults to <root>/core/packs")
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = os.path.abspath(args.root)

    if args.emit_kinds:
        # Vocabulary-only mode: filesystem-reading, offline, and it runs BEFORE the
        # H1/H2 legs so a consumer that needs only the kind set pays for nothing else.
        return emit_kinds(root)

    # The two pack-grammar modes are SEPARATE argv branches sharing no mutable state
    # with the H1/H2/H3 legs below, and they return before those legs run. That
    # isolation is deliberate and is the mitigation for extending this tool rather
    # than forking a third reader of the same corpus: `deploy.sh` Checks 22 and 55
    # call the default path, and a defect in either mode below cannot reach it. The
    # self-test's existing H1/H2/H3 and --emit-kinds arms are the regression guard on
    # that claim.
    pack_root = args.pack_root or os.path.join(root, "core", "packs")
    if args.validate_packs:
        return validate_packs(root, pack_root)
    if args.resolve:
        return resolve_archetype(root, pack_root, args.resolve,
                                 kit=args.kit, k4=args.k4)
    # A selection flag with no --resolve is a caller error, and it is LOUD rather than
    # ignored: silently dropping a selection is the exact failure class SEL-RESOLVE
    # exists to prevent, and it would be worse here because the caller believes a
    # selection was applied.
    if args.kit is not None or args.k4 is not None:
        print("ERROR\t--kit/--k4 are modifiers on --resolve and were passed without "
              "it; a selection that reaches no resolution is dropped, never applied",
              file=sys.stderr)
        return 3

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
