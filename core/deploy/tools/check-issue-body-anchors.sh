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
#   fixture    --resolver fixture                          -> verdict, marked
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
    print issue, lineno, akind[i], apfx[i], (bound ? bpath : ""), numpart(atext[i]), atext[i]
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
  local args=(issue list --state "$STATE" --limit 900 --json number,body)
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
    nums="$(awk -f "$HEADINGS_AWK" "$ROOT/$target" | sort -u -t. -k1,1n -k2,2n -k3,3n | paste -sd, -)"
    if [[ -z "$nums" ]]; then n_unnumbered=$((n_unnumbered + 1)); continue; fi
    if printf '%s' ",$nums," | grep -qF ",$num,"; then
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
    printf '{"denominator":%s,"verdicted":%s,' "$n_total" "$verdicted"
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

  # ── the fixture matrix (§ E7) ──────────────────────────────────────────────
  assert_row "fetched_resolved"                    "4"
  assert_row "fetched_unresolved"                  "2"
  assert_row "not_run_out_of_model_non_markdown"   "1"
  assert_row "not_run_prefix_out_of_model"         "1"
  assert_row "degraded_target_not_tracked"         "1"
  assert_row "not_run_bound_to_no_path"            "1"

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
