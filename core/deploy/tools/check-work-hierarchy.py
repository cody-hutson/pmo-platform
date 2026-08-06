#!/usr/bin/env python3
"""check-work-hierarchy.py — work-hierarchy drift detector (#1039, deploy.sh Check 55).

Asserts two independent invariants that together keep the work hierarchy from
silently re-fragmenting after the T1/T2 SSOT cutover:

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
  EXEMPT    <leg>  <detail>       suppressed by the exemption list
  SKIP      H1  <reason>          a configured scan surface that does not resolve
  SKIP      H2  <reason>          gh unavailable / unauthenticated
  COUNT     <n>                   total non-exempt findings

  exit 0 — clean (no findings)
  exit 1 — findings present
  exit 3 — input failure (SSOT vocabulary unreadable / zero kinds; GraphQL error;
           EVERY configured H1 scan surface unresolved — an empty scan population)

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


def load_licensed_kinds(root):
    """Derive the licensed work-item-kind vocabulary from the pack SSOT."""
    kinds = set()
    packs_dir = os.path.join(root, "core", "packs")
    if not os.path.isdir(packs_dir):
        return kinds
    for entry in sorted(os.listdir(packs_dir)):
        pack_toml = os.path.join(packs_dir, entry, "pack.toml")
        if not os.path.isfile(pack_toml):
            continue
        try:
            with open(pack_toml, "r", encoding="utf-8") as fh:
                text = fh.read()
        except OSError:
            continue
        for m in KIND_ID_RE.finditer(text):
            kinds.add(m.group(1).lower())
    return kinds


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


GRAPHQL_EPIC_PARENTS = """
query($owner:String!,$name:String!,$endCursor:String){
  repository(owner:$owner,name:$name){
    issues(first:100, states:OPEN, labels:["type:epic"], after:$endCursor){
      pageInfo{hasNextPage endCursor}
      nodes{ number parent{ number labels(first:30){nodes{name}} } }
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


# ── self-test ───────────────────────────────────────────────────────────────

SELF_TEST_PACK = 'pack_id = "t"\n[[kinds]]\nkind_id = "epic"\nkind_id = "story"\n'


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

    # PAGINATION: `gh --paginate` concatenates page documents with NO separator.
    # A newline-split parse silently yields ZERO nodes past page 1 — a FALSE-GREEN
    # on a >100-epic repo. Regression guard for that bug.
    concat = '{"a":1}{"a":2}  {"a":3}'
    check("concatenated multi-page JSON parses to all documents",
          [d["a"] for d in iter_json_docs(concat)] == [1, 2, 3])
    check("single-document JSON still parses",
          [d["a"] for d in iter_json_docs('{"a":9}')] == [9])

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
    ap.add_argument("--self-test", action="store_true")
    args = ap.parse_args()

    if args.self_test:
        return self_test()

    root = os.path.abspath(args.root)
    out = []

    kinds = load_licensed_kinds(root)
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
        print("ERROR\tH1 scan population is empty — every configured scan surface "
              "is unresolved: " + ", ".join(unresolved), file=sys.stderr)
        return 3
    for loc, text in h1:
        out.append("H1\t" + loc + "\t" + text)

    h2, h2_ex = [], []
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

    for num, parent in h2:
        out.append("H2\t" + num + "\t" + parent)
    for leg, detail in h1_ex + h2_ex:
        out.append("EXEMPT\t" + leg + "\t" + detail)

    total = len(h1) + len(h2)
    out.append("COUNT\t" + str(total))
    print("\n".join(out))
    return 1 if total else 0


if __name__ == "__main__":
    sys.exit(main())
