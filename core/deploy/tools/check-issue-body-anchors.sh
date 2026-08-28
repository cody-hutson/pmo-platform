#!/usr/bin/env bash
# =============================================================================
# check-issue-body-anchors.sh — Check 71 predicate: section-anchor citations in
# OPEN issue bodies, resolved against the actual headings of the file they name.
#
# WHAT THIS ASSERTS. A precondition that cites a file plus a numbered section
# anchor cites a section that EXISTS in that file. The defect it catches is a
# citation whose section number is correct for some OTHER file, or whose target
# has been restructured since the citing issue was written — a citation that
# "looks precise" and resolves to nothing. Nothing else in the repository asks
# this question: check-issue-ref-validity.sh scans changed repo markdown and
# resolves #N against GitHub issues (this tool is the inverse on BOTH axes), and
# check-citation-anchors.sh (Check 66) names this predicate in its own declared
# coverage boundary as one it does NOT run.
#
# WHY ADVISORY, PERMANENTLY. The residual below is structural, not a threshold
# to tune: the corpus labels sections in conventions this predicate cannot
# enumerate, so a citation naming a real-but-unmodelled label is
# indistinguishable from a citation naming nothing. A false positive in a gate
# costs far more than a missed anchor, so this surface SURFACES and never
# verdicts. There is no enforce flip and none is planned.
#
# -----------------------------------------------------------------------------
# DECLARED SCOPE AND COVERAGE BOUNDARY (CIAC-4)
#
# Every count below is MEASURED at the baseline pin recorded in BASELINE_PIN,
# over the population named in it. They are a reproduction anchor, not a
# guarantee: the population is live. Re-measure with --census before relying on
# any of them (audit-baseline discipline).
#
#   POPULATION      OPEN issues in the repository, bodies only.
#   TARGET CLASS    Files TRACKED IN GIT (`git ls-files`), and — for a verdict —
#                   markdown ones. Tracked, not filesystem-present: a CI or
#                   fresh-clone checkout carries only tracked files, so a
#                   filesystem predicate would make the same citation resolve
#                   here and read unreadable there.
#   ANCHOR FORM     NUMERIC only, behind one of five modelled prefixes: the
#                   section glyph, or Section / Part / Appendix / Phase
#                   (case-insensitive on the citation side only).
#
#   WHAT IS COVERED, measured at the pin:
#     242 citations are in-grammar numeric AND bound to a path (223 glyph-form,
#     19 word-prefixed). Of those: 204 resolve, 2 are UNRESOLVED findings, 27
#     degrade (19 target-not-tracked, 8 basename-ambiguous), and 9 are out of
#     model on the target side (7 non-markdown, 2 unnumbered).
#
#   NOT COVERED — each class is COUNTED and reported, never silently dropped.
#   Every count here was TAKEN, not estimated; --census reproduces them:
#     (a) NAMED anchors — a section named by its heading text rather than by a
#         number. Prose carries no closing delimiter, so a named anchor's EXTENT
#         is not lexically determinable; the most conservative matcher built for
#         this still produced roughly 30 false positives across 121 sites.
#         MEASURED: 211 sites. Reported as `not-run: named arm`.
#     (b) Anchors behind a prefix OUTSIDE the modelled five.
#         MEASURED: 181 bound sites, of which 54 name a REAL ATX heading in the
#         tracked markdown file they cite — so this is not a definitional
#         quibble, it is the largest genuinely-uncovered class. Its two dominant
#         members are Procedure (36 sites, mostly into one how-to) and Step (14).
#         Reported as `not-run: prefix out of model`; --census breaks it down.
#         NOTE the asymmetry this leaves, stated rather than glossed: admitting
#         these prefixes to the CITATION side alone would flag correct citations,
#         because the target-side extractor does not model them either. Closing
#         the class means widening BOTH grammars together, which is a larger
#         move than this check's mandate. Declared here at its true size so the
#         decision is made on the number rather than on an impression.
#     (c) Non-heading STRUCTURAL LABELS — a template section label appearing in
#         prose or in an agent comment but never as a heading. Indistinguishable
#         from (b) at the citation site; separated only by the target-side
#         census, which is why (b)'s "54 of 181" split is reported at all.
#     (d) Targets carrying NO numbered headings: an anchor into one has no basis
#         to be evaluated, so calling it unresolved would be a guess.
#         MEASURED: 2 sites. Reported as
#         `not-run: out-of-model — target carries no numbered headings`.
#     (e) NON-MARKDOWN targets. The heading model is ATX-only, and in a shell or
#         Python file every `# ` comment line is syntactically ATX (one tracked
#         script carries 1,944 of them), so the existing-sections payload would
#         become comment prose. MEASURED: 7 sites. Reported as
#         `not-run: out-of-model — target is not a markdown heading corpus`.
#     (f) Anchors bound to NO path — the citation names a section but no file on
#         the same line satisfies the B1 head rule. MEASURED: 216 sites.
#         Reported as `not-run: anchor bound to no path`.
#     (g) Targets named but NOT TRACKED (MEASURED: 19), and bare basenames
#         matching MORE THAN ONE tracked path (MEASURED: 8). Both are
#         measurement degradations, not verdicts; no guess is made. Reported as
#         `degraded`, and they are 27 of the 242 in-grammar bound citations —
#         11%, large enough that any accounting that omits them is wrong.
#
#   Total citation sites entering some Register A member at the pin: 850.
#
# The declared-vs-actual obligation is the whole point of this block: a boundary
# item declared without a count behind it is the defect this check exists to
# catch, arriving through the front door.
# -----------------------------------------------------------------------------
#
# REGISTER A (review-discipline-principles.md § 8.1 PV-7a) — status is emitted
# BEFORE any verdict and a consumer MUST branch on it before reading a counter.
# The tokens are adopted VERBATIM; there is no third spelling.
#   fetched    target resolved to exactly one tracked markdown file, read in
#              full, carrying >=1 numbered heading  -> a verdict is emitted
#   degraded   target not tracked | basename ambiguous | read failed -> NO verdict
#   not-run    anchor NAMED, prefix out of model, bound to no path, target
#              non-markdown, or target unnumbered                    -> NO verdict
#              Each of those five is its own COUNTED row, because collapsing
#              them would hide which coverage boundary a citation fell off.
#   truncated  the issue enumeration hit a page ceiling              -> NO verdict
#              EMITTED BY: fetch_bodies, when the single-page `gh issue list`
#              returns at or above PAGE_LIMIT. Routed through the outage emitter,
#              so the counters are ABSENT rather than computed over a cut
#              population. `--issues` is exempt: it has no page to fill.
#   fixture    --resolver fixture                          -> verdict, marked
#              EMITTED BY: the run_scan emit block, as the FIRST row/field on
#              both faces. The verdict is real; the mark is what stops a fixture
#              result being read as a corpus one.
#
# EVERY TOKEN ABOVE HAS AN EMITTER, and each names it. Two of them did not: a
# declared status no code path can produce is unfalsifiable — it reads as
# coverage, is asserted by nothing, and cannot be distinguished from a status
# that simply never fired. Adding a token here obliges adding the emitter and an
# assertion in --self-test in the same commit.
# On any non-measuring status the counters are ABSENT, not zero (PV-7b).
#
# PV-7c. A genuine OUTAGE — the gh fetch fails, git ls-files returns nothing, or
# a built-in control arm returns zero — exits 3, which the caller routes to a
# non-escalating emitter. ONE root cause never becomes one finding per issue.
#
# EXIT CODES
#   0  no findings                1  findings
#   3  input/config failure, resolver outage, or a control arm returned zero
#
# Bash 3.2 (stock macOS shell): no mapfile, no associative arrays. The grammar
# core is awk, which every deploy.sh check already depends on.
# =============================================================================

set -uo pipefail

# ── LOCALE PIN. NOT COSMETIC; DO NOT REMOVE. ─────────────────────────────────
# Both awk programs below address the section glyph as its UTF-8 BYTES
# (\302\247), and the rest of the grammar — PATHREF, NUMRUN, the word-boundary
# checks — is byte-oriented ASCII. Under a UTF-8 locale awk matches by
# CHARACTER, the two-byte escape stops matching the one-character glyph, and the
# heading extractor silently returns a SHORT number set instead of erroring.
# A short set does not read as a failure: it makes real sections invisible, so
# correct citations into them are reported UNRESOLVED. Measured while building
# this tool, on one tracked file: LC_ALL=C extracted 18 section numbers,
# LC_ALL=en_US.UTF-8 extracted 2 from the same file — and the difference would
# have surfaced as false findings, not as an error. Pinning to C makes the byte
# semantics deterministic regardless of the operator's or CI's environment.
export LC_ALL=C
export LANG=C

# The baseline pin every count in the header block above was measured at.
BASELINE_PIN="457 open issues / 1,769,763 body bytes, 2026-08-25"

SELF_NAME="check-issue-body-anchors.sh"

# ── Register B terminal token. Check 69 asserts ONE sanctioned spelling of the
# degraded-state terminal token across the tracked corpus; this tool is tracked
# corpus, so it uses the hyphenated form and no other.
NOT_EVAL_TOKEN="NOT-EVALUATED"

STATE="open"
# The enumeration is a SINGLE page with a hard ceiling. It has ONE home so the
# `truncated` detection below and the request that can hit it cannot drift apart.
PAGE_LIMIT=900
ISSUES_ARG=""
MILESTONE=""
REPO=""
ROOT=""
RESOLVER="gh"
FIXTURE_DIR=""
OUT_FMT="tsv"
DO_SELFTEST=0
DO_CENSUS=0

die3() { echo "INPUT-FAILURE: $*" >&2; exit 3; }

# outage — the PV-7c emit. ONE line naming ONE root cause, carrying the Register
# B terminal token so a consumer greping for it finds this run, and carrying the
# mandated discriminator clause so the line cannot be read as a clean zero. The
# caller routes the resulting exit 3 to a non-escalating emitter; this function's
# job is to make sure the REASON survives that hop.
outage() {
  echo "${NOT_EVAL_TOKEN}: $* — the measurement did not run, so every per-item" \
       "verdict is withheld and no counter was emitted; this is not a clean result." >&2
  return 1
}

usage() {
  # Print the leading comment banner, however long it grows. A fixed line range
  # here would silently truncate the declared coverage boundary the moment the
  # header changed — and this file's whole subject is a declaration drifting
  # from the thing it declares.
  awk 'NR==1 { next } /^#/ { sub(/^# ?/, ""); print; next } { exit }' "$0"
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --state)         STATE="${2:-}"; shift 2 ;;
    --issues)        ISSUES_ARG="${2:-}"; shift 2 ;;
    --milestone)     MILESTONE="${2:-}"; shift 2 ;;
    --repo)          REPO="${2:-}"; shift 2 ;;
    --root)          ROOT="${2:-}"; shift 2 ;;
    --resolver)      RESOLVER="${2:-}"; shift 2 ;;
    --fixture-dir)   FIXTURE_DIR="${2:-}"; shift 2 ;;
    --output-format) OUT_FMT="${2:-}"; shift 2 ;;
    --self-test)     DO_SELFTEST=1; shift ;;
    --census)        DO_CENSUS=1; shift ;;
    -h|--help)       usage; exit 0 ;;
    *)               die3 "unknown argument: $1" ;;
  esac
done

case "$RESOLVER" in gh|fixture) ;; *) die3 "--resolver must be gh or fixture (got '$RESOLVER')" ;; esac
case "$OUT_FMT" in tsv|json) ;; *) die3 "--output-format must be tsv or json (got '$OUT_FMT')" ;; esac
# --state was UNVALIDATED, and it is the flag that reaches the page ceiling: the
# declared population is OPEN issues, and `--state all` returns several thousand
# against a --limit of PAGE_LIMIT. An unvalidated value is also handed straight
# to gh, so a typo became a gh-side error reported as a resolver outage rather
# than as the input failure it is. Validated to the three values gh accepts.
case "$STATE" in open|closed|all) ;; *) die3 "--state must be open, closed, or all (got '$STATE')" ;; esac

if [[ -z "$ROOT" ]]; then
  ROOT="$(git rev-parse --show-toplevel 2>/dev/null || true)"
  [[ -n "$ROOT" ]] || die3 "not inside a git work tree and no --root given"
fi
[[ -d "$ROOT" ]] || die3 "--root is not a directory: $ROOT"

WORK="$(mktemp -d -t issuebodyanchors.XXXXXX)" || die3 "cannot create work directory"
cleanup() { [[ -n "${WORK:-}" && -d "$WORK" ]] && rm -rf "$WORK"; }
trap cleanup EXIT

# =============================================================================
# THE GRAMMAR CORE (§ E2)
#
# Reads a TSV of <issue>\t<line-no>\t<line-text> and emits one row per BOUND
# citation plus one row per unbound anchor. Positional, because the binding
# rules are positional: an anchor binds to the nearest preceding PATHREF ON THE
# SAME LINE when the text between them is connective-only.
#
# WORD-BOUNDARY PLACEMENT IS LOAD-BEARING AND ASYMMETRIC (binding constraint
# 10). The word-prefix branch carries a LEFT word boundary — it begins with a
# word character, so the boundary is meaningful and it is what stops
# "Subsection" matching "Section". The glyph branch carries NONE: a boundary
# assertion in front of a non-word character does not do what it looks like it
# does, and under some engines returns zero against a demonstrably non-empty
# population. Do not "tidy" these into symmetry. A detector for section
# citations that silently returns zero is this check's own failure mode.
# =============================================================================
GRAMMAR_AWK="$WORK/grammar.awk"
cat > "$GRAMMAR_AWK" <<'AWKEOF'
BEGIN {
  FS = "\t"; OFS = "\t"
  GLYPH = "\302\247"                      # the section glyph, as its UTF-8 bytes
  NUMRUN = "[0-9]{1,2}[a-z]?(\\.[0-9]{1,3}[a-z]?)*"
  # `]` must come FIRST inside a POSIX bracket expression to be a literal, and
  # `-` must come LAST. Getting either wrong silently changes the character set
  # rather than erroring — the exact silent-zero class this check is about.
  PCHAR  = "[]A-Za-z0-9_.<>[-]"
  PATHRE = "(" PCHAR "+/)*" PCHAR "+\\.(md|sh|py|yml|yaml|toml|txt|json)"
  WORDPFX = "^(section|part|appendix|phase)$"
}

# is c a word character (for the manual left-boundary check awk's ERE lacks)
function isword(c) { return (c ~ /[A-Za-z0-9_]/) }

# collect every PATHREF occurrence on the line into pstart[]/plen[]/ptext[]
function scan_paths(s,   n, off, m, rest) {
  n = 0; off = 0; rest = s
  while (match(rest, PATHRE)) {
    n++
    pstart[n] = off + RSTART
    plen[n]   = RLENGTH
    ptext[n]  = substr(rest, RSTART, RLENGTH)
    off += RSTART + RLENGTH - 1
    rest = substr(rest, RSTART + RLENGTH)
  }
  return n
}

# collect every ANCHOR occurrence: both branches, recorded with their kind
function scan_anchors(s,   n, off, rest, m, gpos, glen, wpos, wlen, cand, before, tail, nx) {
  n = 0; off = 0; rest = s
  while (1) {
    gpos = 0; wpos = 0
    # --- glyph branch: NO left word boundary, by design ---
    # Matches a glyph anchor of EITHER form, numeric or named, so the named arm
    # is COUNTED rather than invisible. D-4931-Scope ships the arm that measures
    # and counts the arm that does not; an uncovered class that emits no state
    # is not a declared boundary, it is a blind spot with a paragraph about it.
    if (match(rest, GLYPH " {0,2}[0-9A-Za-z]")) { gpos = RSTART; glen = RLENGTH }
    # --- word branch: left word boundary enforced manually below ---
    if (match(rest, "[A-Za-z]+ {1,2}" NUMRUN)) { wpos = RSTART; wlen = RLENGTH }
    if (gpos == 0 && wpos == 0) break
    if (gpos != 0 && (wpos == 0 || gpos <= wpos)) {
      # Re-anchor at the glyph and decide the arm by what actually follows it.
      tail = substr(rest, gpos)
      if (match(tail, "^" GLYPH " {0,2}" NUMRUN)) {
        cand = substr(tail, 1, RLENGTH)
        # Termination guard (§ E2): the anchor ends at the first character that
        # is NOT a digit, a letter, or a `.` immediately followed by a digit.
        # The greedy NUMRUN already consumes `.N`, so the residual obligation is
        # that the next character is not alphanumeric — otherwise the citation
        # ran past the model (`4.1abc`) and is not section `4.1a`.
        nx = substr(tail, RLENGTH + 1, 1)
        if (nx == "" || nx !~ /[A-Za-z0-9]/) {
          n++
          astart[n] = off + gpos; alen[n] = length(cand)
          atext[n] = cand; akind[n] = "glyph"; apfx[n] = "glyph"
        }
        glen = length(cand)
      } else {
        # A glyph followed by prose is a NAMED anchor: out of the v1 model,
        # counted, never verdicted. Its extent is not lexically determinable —
        # prose carries no closing delimiter — which is why it is not resolved.
        n++
        astart[n] = off + gpos; alen[n] = glen
        atext[n] = substr(tail, 1, glen); akind[n] = "named"; apfx[n] = "named"
      }
      off += gpos + glen - 1
      rest = substr(rest, gpos + glen)
    } else {
      cand = substr(rest, wpos, wlen)
      match(cand, /^[A-Za-z]+/); m = tolower(substr(cand, RSTART, RLENGTH))
      before = (off + wpos - 1 >= 1) ? substr(FULL, off + wpos - 1, 1) : ""
      nx = substr(rest, wpos + wlen, 1)
      if ((before == "" || !isword(before)) && (nx == "" || nx !~ /[A-Za-z0-9]/)) {
        n++
        astart[n] = off + wpos; alen[n] = wlen
        atext[n] = cand
        akind[n] = (m ~ WORDPFX) ? "word" : "outofmodel"
        apfx[n]  = m
      }
      off += wpos + wlen - 1
      rest = substr(rest, wpos + wlen)
    }
  }
  return n
}

function numpart(t,   c) { c = t; sub(/^[^0-9]*/, "", c); return c }

{
  issue = $1; lineno = $2
  line = $0
  sub(/^[^\t]*\t[^\t]*\t/, "", line)
  FULL = line
  np = scan_paths(line)
  na = scan_anchors(line)
  lastbound = 0; lastpath = 0
  for (i = 1; i <= na; i++) {
    bound = 0; bpath = ""
    # ---- B1 (head): nearest preceding PATHREF, connective-only gap ----
    best = 0
    for (j = 1; j <= np; j++) if (pstart[j] + plen[j] <= astart[i]) best = j
    if (best > 0) {
      gs = pstart[best] + plen[best]
      gap = substr(line, gs, astart[i] - gs)
      # B1 is stated in § E2 as its OPERATIVE test — the gap is connective-only,
      # i.e. it "contains no word characters". Implemented as that test directly
      # rather than as an enumerated punctuation class, because an enumeration
      # would silently drift from the rule it is supposed to encode.
      if (gap !~ /[A-Za-z0-9_]/) { bound = 1; bpath = ptext[best] }
    }
    # ---- B2 (continuation): same PATHREF as a previously-bound anchor ----
    if (!bound && lastbound > 0) {
      gs = astart[lastbound] + alen[lastbound]
      gap = substr(line, gs, astart[i] - gs)
      ok = (length(gap) <= 18)
      if (ok) for (j = 1; j <= np; j++) if (pstart[j] >= gs && pstart[j] < astart[i]) ok = 0
      if (ok && gap ~ /[.!?][ \t]/) ok = 0
      if (ok) { runs = 0; tmp = gap
                while (match(tmp, /[A-Za-z]{3,}/)) { runs++; tmp = substr(tmp, RSTART + RLENGTH) }
                if (runs > 1) ok = 0 }
      if (ok) { bound = 1; bpath = lastpath }
    }
    if (bound) { lastbound = i; lastpath = bpath }
    # THE UNBOUND PATH IS EMITTED AS A SENTINEL, NEVER AS AN EMPTY FIELD.
    # The consumer reads these rows with `IFS=<tab> read`, and a tab is an IFS
    # WHITESPACE character: bash collapses runs of it, so two adjacent tabs
    # become one delimiter and every field after the gap shifts LEFT. An unbound
    # anchor would arrive with its section NUMBER sitting in the path slot,
    # "resolve" that number as a filename, and land in `degraded: target not
    # tracked` instead of `not-run: anchor bound to no path`. Measured: that is
    # 216 citations mis-partitioned at the introducing baseline — the single
    # largest not-run class silently recoded as a degraded one. Verified both
    # ways: `printf 'a\tb\t\tc'` reads as (a,b,c,) while `printf 'a\tb\t-\tc'`
    # reads as (a,b,-,c).
    print issue, lineno, akind[i], apfx[i], (bound ? bpath : "-"), numpart(atext[i]), atext[i]
  }
}
AWKEOF

# =============================================================================
# HEADING-NUMBER EXTRACTION (§ E4)
#
# ATX headings only, fenced blocks stripped. All five prefixes are MEASURED, not
# speculative — omitting any one manufactures false positives (a bare-digit-only
# extractor flags "Section 3 — The Method" as unresolved when § 3 plainly
# exists). The citation side is case-insensitive; this side is deliberately NOT,
# because corpus ATX headings are Title-case and the asymmetry is what keeps the
# target side precise.
# =============================================================================
HEADINGS_AWK="$WORK/headings.awk"
cat > "$HEADINGS_AWK" <<'AWKEOF'
BEGIN { infence = 0; GLYPH = "\302\247" }
/^[ \t]*(```|~~~)/ { infence = !infence; next }
infence { next }
/^#{1,6}[ \t]+/ {
  h = $0
  sub(/^#{1,6}[ \t]+/, "", h)
  sub(/^(\302\247[ ]?|[Ss]ection[ ]+|[Pp]art[ ]+|[Aa]ppendix[ ]+|[Pp]hase[ ]+)/, "", h)
  if (match(h, /^[0-9]{1,2}[a-z]?(\.[0-9]{1,3}[a-z]?)*/)) {
    n = substr(h, RSTART, RLENGTH)
    tail = substr(h, RSTART + RLENGTH, 1)
    if (tail == "" || tail ~ /[ .):—–]/) print n
  }
}
AWKEOF

# ── anchor-number ordering (§ E3) ────────────────────────────────────────────
# Reads extracted heading numbers on stdin; emits them DE-DUPLICATED and in
# dotted-numeric order. The de-duplication is a WHOLE-LINE operation and is
# deliberately separated from the ordering keys.
#
# WHY NOT `sort -u -t. -k1,1n -k2,2n -k3,3n`, which is what this was.
# `-u` suppresses lines whose KEYS compare equal, and the last-resort whole-line
# comparison is NOT applied under -u. A letter-suffixed sibling carries the same
# NUMERIC key as its stem in every field — `-k1,1n` reads "2c" as 2, exactly as
# it reads "2" — so `2 2c 2d 3 3a` came back as `2 3`. Real headings vanished
# from the set, and the consequence was not a missing row: correct citations
# INTO those headings were reported UNRESOLVED, and the finding payload then
# published the short set as the file's full heading inventory. Two of the four
# live findings the tool reported were this defect, not a real drift.
#
# This is the THIRD silent short-set in this one file by a third mechanism (the
# IFS tab-collapse, fixed by a sentinel; locale-dependent byte matching, fixed
# by the LC_ALL=C pin above; now sort-key collapse). The existing LOCALE ARM
# CANNOT see this one — it calls the extractor directly, without any sort, and
# its expected set carries no letter-suffixed sibling — so a dedicated COLLAPSE
# ARM guards this function in --self-test. A fix whose regression no arm can
# catch is half a fix.
#
# The ordering keys stay numeric so the payload reads 2, 2.1, 2.2, 2.10, 10
# rather than lexically; the trailing LEXICAL keys make the order among numeric
# ties determined rather than dependent on sort stability; and the whole-line
# de-dupe runs afterwards, where it cannot collapse two distinct anchors.
sort_anchor_nums() {
  sort -t. -k1,1n -k2,2n -k3,3n -k1,1 -k2,2 -k3,3 | awk '!seen[$0]++'
}

# ── target resolution index: basename -> tracked paths ───────────────────────
build_index() {
  ( cd "$ROOT" && git ls-files ) > "$WORK/tracked.txt" 2>/dev/null || true
  if [[ ! -s "$WORK/tracked.txt" ]]; then
    outage "git ls-files returned nothing under $ROOT (the target side is unreadable)"
    return 1
  fi
  awk -F/ '{ print $NF "\t" $0 }' "$WORK/tracked.txt" | sort > "$WORK/bybase.tsv"
  return 0
}

# resolve <pathref> -> "<status>\t<path>"
#   tracked <path> | untracked | ambiguous <n>
resolve_target() {
  local ref="$1" base hits n
  if grep -qxF "$ref" "$WORK/tracked.txt" 2>/dev/null; then
    printf 'tracked\t%s\n' "$ref"; return
  fi
  case "$ref" in */*) printf 'untracked\t%s\n' "$ref"; return ;; esac
  base="$ref"
  hits="$(awk -F'\t' -v b="$base" '$1==b{print $2}' "$WORK/bybase.tsv")"
  n="$(printf '%s\n' "$hits" | grep -c . || true)"
  if [[ "$n" -eq 0 ]]; then printf 'untracked\t%s\n' "$ref"
  elif [[ "$n" -eq 1 ]]; then printf 'tracked\t%s\n' "$hits"
  else printf 'ambiguous\t%s\n' "$n"
  fi
}

# ── body acquisition ─────────────────────────────────────────────────────────
fetch_bodies() {
  local out="$WORK/bodies.tsv"
  : > "$out"
  if [[ "$RESOLVER" == "fixture" ]]; then
    [[ -n "$FIXTURE_DIR" && -d "$FIXTURE_DIR" ]] || die3 "--resolver fixture needs a readable --fixture-dir"
    local f n
    for f in "$FIXTURE_DIR"/bodies/*.txt; do
      [[ -e "$f" ]] || continue
      n="$(basename "$f" .txt)"
      # Sentinel expansion: tracked fixtures carry @@SEC@@ rather than the glyph
      # itself, so the fixture corpus does not trip a corpus-wide scanner.
      sed "s/@@SEC@@/$(printf '\302\247')/g" "$f" \
        | awk -v i="$n" '{ print i "\t" NR "\t" $0 }' >> "$out"
    done
    [[ -s "$out" ]] || die3 "fixture corpus produced no body lines"
    return 0
  fi

  command -v gh >/dev/null 2>&1 || { outage "gh is not on PATH"; return 1; }
  # shellcheck disable=SC2054  # `number,body` is ONE argument to gh's --json
  # flag, not two array elements; splitting on the comma breaks the call.
  local args=(issue list --state "$STATE" --limit "$PAGE_LIMIT" --json number,body)
  [[ -n "$REPO" ]] && args+=(--repo "$REPO")
  [[ -n "$MILESTONE" ]] && args+=(--milestone "$MILESTONE")
  if [[ -n "$ISSUES_ARG" ]]; then
    : > "$WORK/raw.json"
    echo "[" > "$WORK/raw.json"
    local first=1 num
    for num in $(printf '%s' "$ISSUES_ARG" | tr ',' ' '); do
      local one
      one="$(gh issue view "$num" ${REPO:+--repo "$REPO"} --json number,body 2>/dev/null)" || {
        outage "gh issue view $num failed"; return 1; }
      [[ $first -eq 1 ]] || echo "," >> "$WORK/raw.json"
      first=0
      printf '%s' "$one" >> "$WORK/raw.json"
    done
    echo "]" >> "$WORK/raw.json"
  else
    gh "${args[@]}" > "$WORK/raw.json" 2>/dev/null || {
      outage "gh issue list failed (network, auth, or rate limit)"; return 1; }
  fi
  [[ -s "$WORK/raw.json" ]] || { outage "issue enumeration returned an empty document"; return 1; }

  # ── REGISTER A `truncated` (§ E1). The enumeration is a SINGLE page with a
  # hard ceiling, so a return AT the ceiling may have been cut — and the tool
  # cannot know WHICH issues it did not see, which is exactly what makes the
  # remainder unverdictable. A partial scan reporting "0 unresolved anchors"
  # would be a silent short-set over an unstated population: this check's own
  # subject matter, arriving through its own front door.
  #
  # So the status is EMITTED and the verdict is WITHHELD — counters absent,
  # never zero (PV-7b) — through the same one-root-cause outage emitter the
  # other non-measuring paths use (PV-7c). This token was declared in Register A
  # from the start with NO emitter and no detection mechanism behind it; the
  # declaration is what is being made true here.
  #
  # The `--issues` path is exempt: it enumerates an explicit list one call at a
  # time, so it has no page ceiling to hit.
  local n_recs
  n_recs="$(/usr/bin/python3 -c 'import json,sys; print(len(json.load(open(sys.argv[1]))))' \
             "$WORK/raw.json" 2>/dev/null)" || n_recs=""
  if [[ -z "$n_recs" ]]; then
    outage "issue enumeration did not parse as JSON, so its completeness is unknowable"
    return 1
  fi
  if [[ -z "$ISSUES_ARG" && "$n_recs" -ge "$PAGE_LIMIT" ]]; then
    printf 'STATUS\ttruncated\t%s\n' "$n_recs"
    outage "issue enumeration returned $n_recs record(s) at the --limit $PAGE_LIMIT page ceiling (--state $STATE) — the population may be cut and the unseen issues are not identifiable from here, so no citation was verdicted"
    return 1
  fi

  # Fenced code blocks are stripped before scanning (§ E2).
  /usr/bin/python3 - "$WORK/raw.json" "$out" <<'PYEOF'
import json, sys, re
recs = json.load(open(sys.argv[1]))
fence = re.compile(r"^[ \t]*(```|~~~)")
with open(sys.argv[2], "w") as fh:
    for r in recs:
        body = r.get("body") or ""
        infence = False
        for i, line in enumerate(body.split("\n"), 1):
            if fence.match(line):
                infence = not infence
                continue
            if infence:
                continue
            fh.write("%s\t%d\t%s\n" % (r["number"], i, line.replace("\t", " ")))
PYEOF
  [[ -s "$out" ]] || { outage "body extraction produced no lines"; return 1; }
  return 0
}

# ── the scan ─────────────────────────────────────────────────────────────────
run_scan() {
  local citations="$WORK/citations.tsv"
  awk -f "$GRAMMAR_AWK" "$WORK/bodies.tsv" > "$citations" || return 1

  local n_named=0 n_nopath=0 n_prefix=0
  local n_untracked=0 n_ambiguous=0 n_nonmd=0 n_unnumbered=0
  local n_resolved=0 n_unresolved=0 n_total=0
  : > "$WORK/findings.tsv"
  : > "$WORK/census.tsv"

  local issue lineno kind pfx path num raw
  while IFS=$'\t' read -r issue lineno kind pfx path num raw; do
    [[ -z "${issue:-}" ]] && continue
    # CLASSIFICATION ORDER IS LOAD-BEARING — binding is tested BEFORE the prefix
    # model. An out-of-model word prefix that binds NO path is not a citation at
    # all, it is ordinary prose ("the 1", "returns 2", "across 5"): the grammar
    # sees ~2,600 of them in a 457-issue population, and counting those as a
    # residual would swamp the declared boundary count with noise and make the
    # header's number meaningless. Only a prefix that actually BINDS A PATH is a
    # citation this predicate declined to model.
    # "-" is the unbound sentinel the grammar emits; see the note at its print
    # statement for why an empty field cannot be used here.
    [[ "$path" == "-" ]] && path=""
    if [[ "$kind" == "outofmodel" && -z "$path" ]]; then continue; fi
    n_total=$((n_total + 1))
    printf '%s\t%s\n' "$kind" "$pfx" >> "$WORK/census.tsv"
    # A NAMED anchor is a real anchor the v1 model does not resolve, bound or
    # not, so it is counted on its own row rather than folded into the
    # bound-to-no-path class. This is the coverage boundary on the gate's face.
    if [[ "$kind" == "named" ]]; then n_named=$((n_named + 1)); continue; fi
    if [[ -z "$path" ]]; then n_nopath=$((n_nopath + 1)); continue; fi
    if [[ "$kind" == "outofmodel" ]]; then n_prefix=$((n_prefix + 1)); continue; fi

    local rs status target
    rs="$(resolve_target "$path")"
    status="${rs%%$'\t'*}"; target="${rs#*$'\t'}"
    case "$status" in
      untracked) n_untracked=$((n_untracked + 1)); continue ;;
      ambiguous) n_ambiguous=$((n_ambiguous + 1)); continue ;;
    esac
    case "$target" in
      *.md) ;;
      *) n_nonmd=$((n_nonmd + 1)); continue ;;
    esac
    [[ -f "$ROOT/$target" ]] || { n_untracked=$((n_untracked + 1)); continue; }

    local nums
    nums="$(awk -f "$HEADINGS_AWK" "$ROOT/$target" | sort_anchor_nums | paste -sd, -)"
    if [[ -z "$nums" ]]; then n_unnumbered=$((n_unnumbered + 1)); continue; fi
    # SIGPIPE-REWRITE. Was: `printf '%s' ",$nums," | grep -qF ",$num,"`. This
    # file sets `pipefail`, so the broken-pipe status is load-bearing: `grep -q`
    # exits at its first match and closes the pipe, `printf` then takes SIGPIPE
    # (141), and pipefail promotes that to the pipeline's status — so the `if`
    # reads a MATCH as a non-match and books a resolving anchor as an unresolved
    # FINDING. The here-string has no writer process to signal, which removes the
    # hazard rather than narrowing it. The one documented caveat does not apply:
    # `<<<""` would emit one empty line where `printf '%s' ""` emits none, but
    # `$nums` is guaranteed non-empty by the `[[ -z "$nums" ]]` guard on the line
    # above, and the needle is comma-delimited so it cannot match an empty line.
    if grep -qF ",$num," <<<",$nums,"; then
      n_resolved=$((n_resolved + 1))
    else
      n_unresolved=$((n_unresolved + 1))
      printf 'FINDING\t%s\t%s\t%s\t%s\t%s\t%s\n' \
        "$issue" "$lineno" "$target" "$num" "$raw" "$nums" >> "$WORK/findings.tsv"
    fi
  done < "$citations"

  # ── emit. The not-run and degraded counts are emitted on EVERY evaluated run,
  # finding or not, so a leg that did not measure can never read as a clean one.
  local verdicted=$((n_resolved + n_unresolved))
  if [[ "$OUT_FMT" == "tsv" ]]; then
    # The header block's declared counts were taken at BASELINE_PIN. Emitting it
    # beside the live numbers is what makes the two comparable: a reader can see
    # at a glance whether the declaration is still describing this population.
    # REGISTER A `fixture` (§ E1): a fixture-resolver run DOES emit a verdict,
    # but the register declares that verdict "marked" — and nothing marked it.
    # An unmarked fixture verdict is indistinguishable from a live one in the
    # output, which is how a self-test result gets read as a corpus result. The
    # mark is emitted FIRST, with the status rows, because a consumer must be
    # able to branch on it before reading a counter.
    [[ "$RESOLVER" == "fixture" ]] && printf 'STATUS\tfixture\t%s\n' "$FIXTURE_DIR"
    printf 'BASELINE\theader_counts_measured_at\t%s\n' "$BASELINE_PIN"
    printf 'DENOM\tcitations_bound_or_seen\t%s\n' "$n_total"
    printf 'STATUS\tfetched_resolved\t%s\n' "$n_resolved"
    printf 'STATUS\tfetched_unresolved\t%s\n' "$n_unresolved"
    printf 'STATUS\tdegraded_target_not_tracked\t%s\n' "$n_untracked"
    printf 'STATUS\tdegraded_basename_ambiguous\t%s\n' "$n_ambiguous"
    printf 'STATUS\tnot_run_out_of_model_non_markdown\t%s\n' "$n_nonmd"
    printf 'STATUS\tnot_run_out_of_model_unnumbered\t%s\n' "$n_unnumbered"
    printf 'STATUS\tnot_run_prefix_out_of_model\t%s\n' "$n_prefix"
    printf 'STATUS\tnot_run_named_arm\t%s\n' "$n_named"
    printf 'STATUS\tnot_run_bound_to_no_path\t%s\n' "$n_nopath"
    printf 'STATUS\tverdicted\t%s\n' "$verdicted"
    while IFS=$'\t' read -r _t issue lno target num raw nums; do
      [[ -z "${issue:-}" ]] && continue
      # AC-2 payload: the file, the cited anchor, and the FULL sorted set of
      # numbers that do exist — plus the body line, so adjudication is one
      # glance rather than a file open followed by a search.
      printf 'UNRESOLVED\t%s\t%s\t%s\t%s\t%s\t%s\n' "$issue" "$lno" "$target" "$num" "$raw" "$nums"
    done < "$WORK/findings.tsv"
  else
    printf '{'
    # The same Register A `fixture` mark on the machine-readable face, first
    # field, for the same reason it is the first row on the TSV face.
    [[ "$RESOLVER" == "fixture" ]] && printf '"fixture":"%s",' "$FIXTURE_DIR"
    printf '"denominator":%s,"verdicted":%s,' "$n_total" "$verdicted"
    printf '"status":{"fetched_resolved":%s,"fetched_unresolved":%s,' "$n_resolved" "$n_unresolved"
    printf '"degraded_target_not_tracked":%s,"degraded_basename_ambiguous":%s,' "$n_untracked" "$n_ambiguous"
    printf '"not_run_out_of_model_non_markdown":%s,"not_run_out_of_model_unnumbered":%s,' "$n_nonmd" "$n_unnumbered"
    printf '"not_run_prefix_out_of_model":%s,"not_run_named_arm":%s,' "$n_prefix" "$n_named"
    printf '"not_run_bound_to_no_path":%s},' "$n_nopath"
    printf '"findings":['
    local first=1
    while IFS=$'\t' read -r _t issue lno target num raw nums; do
      [[ -z "${issue:-}" ]] && continue
      [[ $first -eq 1 ]] || printf ','
      first=0
      printf '{"issue":%s,"body_line":%s,"target":"%s","anchor":"%s","existing":"%s"}' \
        "$issue" "$lno" "$target" "$num" "$nums"
    done < "$WORK/findings.tsv"
    printf ']}\n'
  fi

  if [[ "$DO_CENSUS" -eq 1 ]]; then
    printf '# --census: the out-of-model prefix residual, per prefix\n' >&2
    awk -F'\t' '$1=="outofmodel"{c[$2]++} END{for(p in c) print c[p]"\t"p}' "$WORK/census.tsv" \
      | sort -rn >&2
  fi

  [[ "$n_unresolved" -gt 0 ]] && return 1
  return 0
}

# =============================================================================
# --self-test (§ E7)
#
# BOTH CONTROL ARMS ARE INSIDE THE VERDICT, not bolted beside it. A run whose
# SENSITIVITY arm returns zero EXITS 3 rather than reporting a clean zero: a
# detector that cannot be shown to fire proves nothing, and the silent-zero
# failure is this check's own subject matter.
# =============================================================================
selftest() {
  local fx="${FIXTURE_DIR:-$ROOT/core/deploy/tools/fixtures/issue-body-anchors}"
  [[ -d "$fx" ]] || die3 "self-test needs the fixture corpus at $fx"
  build_index || die3 "self-test cannot build the target index"

  RESOLVER="fixture"; FIXTURE_DIR="$fx"; OUT_FMT="tsv"
  fetch_bodies || die3 "self-test could not read the fixture corpus"
  # run_scan returns 1 when it finds UNRESOLVED anchors, and the fixture corpus
  # is BUILT to contain some — that is the sensitivity arm. So a non-zero here
  # is the expected result, not a failure, and the exit code is deliberately not
  # consulted: what the self-test asserts is the per-class COUNTS below.
  local out
  out="$(run_scan)" || true

  local fails=0 checks=0
  assert_row() {
    local key="$1" want="$2" got
    got="$(printf '%s\n' "$out" | awk -F'\t' -v k="$key" '$2==k{print $3}')"
    checks=$((checks + 1))
    if [[ "${got:-}" != "$want" ]]; then
      echo "  FAIL: $key expected $want, got ${got:-<absent>}"
      fails=$((fails + 1))
    fi
  }

  # ── SENSITIVITY ARM (must FIRE) ────────────────────────────────────────────
  local sens
  sens="$(printf '%s\n' "$out" | awk -F'\t' '$2=="fetched_unresolved"{print $3}')"
  echo "  CTRL sensitivity: fetched_unresolved = ${sens:-0}"
  if [[ "${sens:-0}" -eq 0 ]]; then
    echo "  CONTROL ARM RETURNED ZERO — the detector cannot be shown to fire." >&2
    echo "  This is a BROKEN PROBE, not a clean result. Exiting 3." >&2
    exit 3
  fi
  # ── SPECIFICITY ARM (must be clean on the near-miss corpus) ────────────────
  local spec
  spec="$(printf '%s\n' "$out" | awk -F'\t' '$2=="fetched_resolved"{print $3}')"
  echo "  CTRL specificity: fetched_resolved = ${spec:-0} (near-misses must NOT flag)"
  if [[ "${spec:-0}" -eq 0 ]]; then
    echo "  SPECIFICITY ARM RETURNED ZERO — the corpus cannot discriminate. Exiting 3." >&2
    exit 3
  fi

  # ── LOCALE ARM. Guards the LC_ALL=C pin at the top of this file. The glyph is
  # addressed as its UTF-8 bytes, so under a character-oriented locale the
  # extractor returns a SHORT number set rather than an error — real sections go
  # invisible and correct citations into them report UNRESOLVED. fx-alpha.md
  # carries glyph-prefixed headings precisely so this arm can see that.
  local loc_nums
  loc_nums="$(awk -f "$HEADINGS_AWK" "$fx/targets/fx-alpha.md" | paste -sd, -)"
  echo "  CTRL locale:      fx-alpha.md glyph headings -> ${loc_nums:-<none>}"
  if [[ "$loc_nums" != "1,2,2.1,3" ]]; then
    echo "  LOCALE ARM FAILED — glyph-prefixed headings did not extract as 1,2,2.1,3." >&2
    echo "  The LC_ALL=C pin is the guard for this; a short set is a SILENT" >&2
    echo "  under-extraction, not an error. Exiting 3." >&2
    exit 3
  fi

  # ── COLLAPSE ARM. Guards sort_anchor_nums — the de-duplication of the heading
  # set, which is a DIFFERENT silent short-set from the one the locale arm
  # covers, by a different mechanism, and the locale arm STRUCTURALLY CANNOT SEE
  # IT: that arm calls the extractor directly with no sort in the pipeline, and
  # its expected set carries no letter-suffixed sibling. A key-collapsing sort
  # passes every other assertion in this file while dropping real headings.
  #
  # The arm drives the REAL function, not a copy of it — a control arm that
  # exercises a transcription of the code under test cannot catch that code
  # regressing. It asserts the SET (membership, against a plain `sort -u`
  # control) and the ORDER (the dotted-numeric contract the finding payload
  # depends on) separately, because they fail independently.
  local cin cget cset cctl cdefect
  cin='2
2c
2d
3
3a
2c
10
2.10
2.2'
  cget="$(printf '%s\n' "$cin" | sort_anchor_nums | paste -sd, -)"
  cset="$(printf '%s\n' "$cin" | sort_anchor_nums | sort | paste -sd, -)"
  cctl="$(printf '%s\n' "$cin" | sort -u | paste -sd, -)"
  echo "  CTRL collapse:    9 numbers in, 8 distinct -> ${cget:-<none>}"
  if [[ "$cset" != "$cctl" ]]; then
    echo "  COLLAPSE ARM FAILED — the ordering function's output SET does not match" >&2
    echo "  a plain \`sort -u\` over the same input." >&2
    echo "    got:     $cset" >&2
    echo "    control: $cctl" >&2
    echo "  Letter-suffixed siblings are being dropped: real headings go invisible" >&2
    echo "  and CORRECT citations into them are reported UNRESOLVED. Exiting 3." >&2
    exit 3
  fi
  if [[ "$cget" != "2,2c,2d,2.2,2.10,3,3a,10" ]]; then
    echo "  COLLAPSE ARM FAILED — the set is right but the dotted-numeric ORDER is" >&2
    echo "  not: got '$cget'. The finding payload publishes this sequence as the" >&2
    echo "  file's heading inventory, so its order is part of the contract. Exiting 3." >&2
    exit 3
  fi
  # The arm's OWN discrimination check. A probe that cannot go red proves
  # nothing, so the DEFECTIVE form is run against the same fixture and must
  # disagree with the control. If it ever agrees, this fixture has stopped being
  # able to see the failure and the arm is decorative — which is reported as a
  # broken probe rather than passed over.
  cdefect="$(printf '%s\n' "$cin" | sort -u -t. -k1,1n -k2,2n -k3,3n | sort | paste -sd, -)"
  if [[ "$cdefect" == "$cctl" ]]; then
    echo "  COLLAPSE ARM CANNOT DISCRIMINATE — the key-collapsing sort this arm" >&2
    echo "  exists to catch produced the SAME set as the control on this fixture," >&2
    echo "  so a pass here would mean nothing. BROKEN PROBE. Exiting 3." >&2
    exit 3
  fi
  echo "  CTRL collapse-neg: defective key-sort yields ${cdefect} (must differ from control)"

  # ── the fixture matrix (§ E7) ──────────────────────────────────────────────
  # ALL NINE Register A partition members are asserted, not six. The emit block
  # publishes a nine-member partition; asserting six of them left three rows
  # ungoverned, so a change that started routing citations INTO one of the three
  # would move a count nothing was watching. Misclassification is the failure
  # mode here, and it is invisible to a total: a partition can re-file records
  # into the wrong member and still sum correctly. So the members are pinned
  # INDIVIDUALLY, and the sum is asserted separately below — the two catch
  # different faults and neither substitutes for the other.
  assert_row "fetched_resolved"                    "4"
  assert_row "fetched_unresolved"                  "2"
  assert_row "degraded_target_not_tracked"         "1"
  assert_row "not_run_out_of_model_non_markdown"   "1"
  assert_row "not_run_prefix_out_of_model"         "1"
  assert_row "not_run_bound_to_no_path"            "1"
  # The three that were unasserted. Their fixture value is 0, and the ZERO IS
  # DECLARED RATHER THAN IMPLIED: the corpus carries no named anchor, no
  # ambiguous bare basename, and no unnumbered markdown target, so these three
  # rows pin the partition's SHAPE but do NOT demonstrate that their class can
  # fire. That residual is stated here rather than left for a reader to infer
  # from a passing test — a zero whose class was never exercised is not evidence
  # the class works, and `not_run_named_arm` is the LARGEST class in the live
  # population (211 sites at the baseline pin) while being 0 here.
  assert_row "degraded_basename_ambiguous"         "0"
  assert_row "not_run_out_of_model_unnumbered"     "0"
  assert_row "not_run_named_arm"                   "0"
  # Register A `fixture`: the mark the register declares must actually be on the
  # output. Asserted, because an unmarked fixture verdict reads exactly like a
  # live one and this run IS a fixture run.
  assert_row "fixture"                             "$fx"

  # ── PARTITION CLOSURE. The nine members must ACCOUNT FOR the denominator. A
  # member silently dropped from the emit, or a citation counted into no member
  # at all, leaves the sum short while every individual assertion above still
  # passes. This is the complement of those assertions, not a restatement: they
  # catch a record filed in the wrong member, this catches a record filed in no
  # member. Both are needed because a reconciling total is not evidence of
  # correct classification, and correct per-class counts are not evidence the
  # classes are exhaustive.
  local part_sum part_denom part_verdicted
  part_sum="$(printf '%s\n' "$out" | awk -F'\t' '
    $1=="STATUS" && $2!="verdicted" && $2!="fixture" && $2!="truncated" { s += $3 }
    END { print s+0 }')"
  part_denom="$(printf '%s\n' "$out" | awk -F'\t' '$1=="DENOM"{print $3}')"
  part_verdicted="$(printf '%s\n' "$out" | awk -F'\t' '$2=="verdicted"{print $3}')"
  checks=$((checks + 1))
  if [[ "$part_sum" != "$part_denom" ]]; then
    echo "  FAIL: partition closure — the nine status members sum to $part_sum but the"
    echo "        denominator is ${part_denom:-<absent>}; some citation was counted into no member"
    fails=$((fails + 1))
  fi
  checks=$((checks + 1))
  if [[ "$part_verdicted" != "6" ]]; then
    echo "  FAIL: verdicted expected 6 (resolved 4 + unresolved 2), got ${part_verdicted:-<absent>}"
    fails=$((fails + 1))
  fi
  echo "  CTRL partition:   9 members sum to $part_sum = denominator $part_denom; verdicted $part_verdicted"

  echo "  self-test: $checks assertion(s), $fails failure(s)"
  [[ $fails -eq 0 ]] || return 1
  return 0
}

# ── main ─────────────────────────────────────────────────────────────────────
if [[ "$DO_SELFTEST" -eq 1 ]]; then
  echo "self-test: $SELF_NAME (fixture matrix + both control arms)"
  selftest || exit 1
  echo "self-test: PASS"
  exit 0
fi

build_index || exit 3
fetch_bodies || exit 3
run_scan
exit $?
