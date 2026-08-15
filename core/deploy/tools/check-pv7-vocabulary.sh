#!/bin/bash
# check-pv7-vocabulary.sh — Check 69 predicate: the PV-7a Register B terminal token
# is spelled the ONE sanctioned way, everywhere in the tracked corpus.
#
# WHAT IT ASSERTS. review-discipline-principles.md § 8.1 PV-7a freezes Register B —
# the human-readable degraded-state token — at two members and adds "No third
# spelling." ADR-133 D2 reconciles every divergent rendering of the TERMINAL member
# to the hyphenated form. This gate asserts that reconciliation holds: an all-caps
# rendering of the terminal token separated by anything OTHER than a single hyphen
# is an unsanctioned third spelling and FAILs.
#
# WHY THIS GATE EXISTS, CONCRETELY. The convention shipped with citations and no
# predicate. The first merge after it shipped reintroduced four space-separated
# emits into a check leg of core/deploy/deploy.sh, and CI passed green, because
# nothing in the repository could tell the two spellings apart. That is the
# convention's own defect class arriving through the front door, undetected. A rule
# with no falsifier is a comment.
#
# WHY ALL-CAPS IS THE DISCRIMINATOR, AND WHY THAT IS THE WHOLE POINT. ADR-133 D2
# chose the hyphenated form for one stated reason: the space-separated variant "is
# not a greppable token: it matches ordinary prose, and the grading probe for this
# convention is a grep." That is measurably true here — the corpus carries ~30
# legitimate lowercase prose uses ("the DEPLOYED arm was not evaluated") and
# snake_case identifiers (`flag_not_evaluated`, `arm_not_evaluated`, `NOTEVAL_COUNT`)
# which are correct and must never be flagged. Case-sensitivity is what separates the
# TOKEN from the PROSE. A case-insensitive predicate here would be unusable rather
# than merely noisy, and this gate would have to be withdrawn.
#
# THE CONTROL ARM IS BUILT INTO THE VERDICT, NOT BOLTED BESIDE IT. Every run counts
# the SANCTIONED occurrences as well as the violations. If the sanctioned count is
# ZERO the extraction is not reaching the corpus, and this tool exits 3 rather than
# reporting a clean zero — a zero whose control arm also returned zero is a broken
# probe, never an empty population (PV-1 / PV-2). This is the single most likely way
# for this gate to rot: a future refactor moves the token behind a variable, the
# extractor silently matches nothing, and the gate goes permanently, vacuously green.
# It cannot: the control arm fails loud first.
#
# SCOPE — tracked files only, via `git ls-files`. Untracked and git-ignored content
# is deliberately out of scope: the operations workspace (projects/) and the
# operator-local analysis workspace are git-ignored, operator-owned, and must never
# be scanned by a platform gate. A root that is not a git work tree is a SCAN-ERROR
# (exit 3), never an empty population.
#
# EXEMPTIONS (three prefixes, each with a stated reason, each measurable via
# --no-exempt so the exemption's cost is never a claim taken on faith):
#   core/deploy/tests/fixtures/  fixture trees carry deliberate defects as their
#   core/hooks/testdata/         whole purpose — counting them makes the gate red by
#                                construction (the Check 63 / Check 64 exemption,
#                                for the identical reason)
#   release/releases/            frozen artifacts describe the corpus AS IT WAS;
#                                "fixing" a token inside a shipped release plan or
#                                note rewrites a historical record (Check 63's
#                                frozen-artifact exemption)
# MEASURED at this pin: lifting all three exemptions changes the finding count by
# ZERO (0 exempted violations). The exemptions are forward-looking insurance, not
# load-bearing suppression — stated as a measurement, not as an assurance.
#
# DECLARED COVERAGE BOUNDARY — state this, do not imply more. This gate reads the
# SPELLING of the terminal token in file text. It does NOT assert:
#   * that a degraded emit routes through a non-escalating emitter (PV-7c's
#     structural obligation — that is the emitter-class concern, and the emitter
#     family is where it lives);
#   * that a NOT-EVALUATED emit carries the mandated "this is not a clean result"
#     clause (PV-7a's discriminator obligation — a content check, not a spelling one);
#   * that counters are absent rather than zero on a non-measuring status (PV-7b);
#   * a token assembled at run time by string concatenation or held in a variable,
#     which has no literal in the source to read;
#   * the Register A machine-readable status values, which are frozen with zero
#     renames and are lowercase identifiers, not this register.
# Those are four separate invariants. This one is the spelling, which is the one the
# merge broke, and it is asserted rather than assumed.
#
# EXIT CODES (the corpus's three-value contract; no fourth member — roughly thirty
# call sites branch on three, and ADR-133 rejected widening it):
#   0  clean — every all-caps rendering is the sanctioned spelling
#   1  one or more unsanctioned spellings (one FAIL line each)
#   3  input failure / broken probe — not a git work tree, zero files enumerated,
#      or the control arm returned zero. NEVER a clean zero.
#
# USAGE
#   bash core/deploy/tools/check-pv7-vocabulary.sh                # scan the corpus
#   bash core/deploy/tools/check-pv7-vocabulary.sh --no-exempt    # measure exemption cost
#   bash core/deploy/tools/check-pv7-vocabulary.sh --root <dir>   # scan another work tree
#   bash core/deploy/tools/check-pv7-vocabulary.sh --self-test    # committed fixtures
#
# Output: `FAIL: <file>:<line> — <detail>` per finding, one `DENOM: …` record line,
# and `SCAN-ERROR: …` on a fail-loud condition.
#
# NOTE ON THIS FILE'S OWN TEXT. Every fixture string in --self-test below is
# ASSEMBLED at run time from fragments, so this source carries NO literal instance of
# an unsanctioned spelling and is clean under its own predicate. A gate whose fixture
# corpus trips the gate teaches the next author to widen the exemption list.

set -uo pipefail

# The one sanctioned spelling of the Register B terminal member (PV-7a).
PV7_SANCTIONED="NOT-EVALUATED"

# Exempt path PREFIXES. Kept as a newline-delimited string (bash 3.2 compatible —
# deploy.sh's floor, and this tool is invoked from it).
PV7_EXEMPT_PREFIXES='core/deploy/tests/fixtures/
core/hooks/testdata/
release/releases/'

# ─── the classifier ───────────────────────────────────────────────────────────
# Emits one record per all-caps token rendering:
#   <file>:<line>:<VIOLATION|SANCTIONED>:<the separator, rendered>
# The separator run can only be punctuation/whitespace: a letter or digit between
# NOT and EVALUATED breaks the match, which is what keeps `CANNOT` and ordinary
# prose out of the population. Interval expressions ({n,m}) are deliberately not
# used — the macOS awk this runs under does not support them, and a regex that
# silently fails to compile is a gate that silently passes.
pv7_classify_awk() {
  cat <<'AWK'
{
  line = $0
  while (match(line, /NOT[^A-Za-z0-9_]*EVALUATED/)) {
    tok  = substr(line, RSTART, RLENGTH)
    pre  = (RSTART > 1) ? substr(line, RSTART - 1, 1) : ""
    post = substr(line, RSTART + RLENGTH, 1)
    # Word boundaries: an adjacent alphanumeric means this is part of a longer
    # identifier (CANNOTEVALUATED, NOT-EVALUATEDLY), not the token.
    if (pre !~ /[A-Za-z0-9_]/ && post !~ /[A-Za-z0-9_]/) {
      sep = substr(tok, 4, length(tok) - 3 - 9)
      if (tok == SANCTIONED) {
        printf "%s:%d:SANCTIONED:\n", FILENAME, FNR
      } else {
        label = (sep == "") ? "no separator" : "separator " length(sep) " char(s)"
        if (sep ~ /^ +$/) label = "space-separated (" length(sep) " space(s))"
        else if (sep == "_") label = "underscore-separated"
        printf "%s:%d:VIOLATION:%s\n", FILENAME, FNR, label
      }
    }
    line = substr(line, RSTART + RLENGTH)
  }
}
AWK
}

pv7_is_exempt() {
  local path="$1" prefix
  while IFS= read -r prefix; do
    [ -z "$prefix" ] && continue
    case "$path" in "$prefix"*) return 0 ;; esac
  done <<EOF
$PV7_EXEMPT_PREFIXES
EOF
  return 1
}

# ─── the scan ─────────────────────────────────────────────────────────────────
# Returns 0 clean / 1 findings / 3 fail-loud. Prints FAIL lines, then DENOM.
pv7_scan() {
  local root="$1" apply_exemptions="$2"
  local tracked_n=0 candidates=0 sanctioned=0 violations=0 exempted=0

  if ! git -C "$root" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "SCAN-ERROR: $root is not a git work tree — the tracked-file denominator cannot be established, so a zero here would be untrustworthy"
    return 3
  fi

  tracked_n=$(git -C "$root" ls-files | wc -l | tr -d ' ')
  if [ "$tracked_n" -eq 0 ]; then
    echo "SCAN-ERROR: $root enumerates zero tracked files — nothing was examined; this is a broken probe, not a clean corpus"
    return 3
  fi

  # Candidate files first (fast, binary-safe, tracked-only), then classify.
  local cand_list
  cand_list=$(git -C "$root" grep -l -I -E 'NOT[^A-Za-z0-9_]*EVALUATED' -- . 2>/dev/null || true)

  local f findings=""
  while IFS= read -r f; do
    [ -z "$f" ] && continue
    if [ "$apply_exemptions" = "yes" ] && pv7_is_exempt "$f"; then
      local ex_hits
      ex_hits=$(awk -v SANCTIONED="$PV7_SANCTIONED" "$(pv7_classify_awk)" "$root/$f" 2>/dev/null | grep -c ':VIOLATION:' || true)
      exempted=$((exempted + ex_hits))
      continue
    fi
    candidates=$((candidates + 1))
    local rec
    rec=$(awk -v SANCTIONED="$PV7_SANCTIONED" "$(pv7_classify_awk)" "$root/$f" 2>/dev/null || true)
    [ -z "$rec" ] && continue
    local s_hits v_lines
    s_hits=$(printf '%s\n' "$rec" | grep -c ':SANCTIONED:' || true)
    sanctioned=$((sanctioned + s_hits))
    v_lines=$(printf '%s\n' "$rec" | grep ':VIOLATION:' || true)
    if [ -n "$v_lines" ]; then
      local vl ln detail
      while IFS= read -r vl; do
        [ -z "$vl" ] && continue
        ln=$(printf '%s' "$vl" | awk -F: '{print $(NF-2)}')
        detail=$(printf '%s' "$vl" | sed 's/.*:VIOLATION://')
        violations=$((violations + 1))
        findings="${findings}FAIL: ${f}:${ln} — unsanctioned spelling of the PV-7a Register B terminal token (${detail}). Reconcile to ${PV7_SANCTIONED} (review-discipline-principles.md § 8.1 PV-7a; ADR-133 D2). No third spelling.
"
      done <<EOF
$v_lines
EOF
    fi
  done <<EOF
$cand_list
EOF

  # ── CONTROL ARM, evaluated BEFORE the verdict. A zero-violation result is only
  #    readable if the extractor demonstrably reaches the token at all. ──────────
  if [ "$sanctioned" -eq 0 ]; then
    echo "SCAN-ERROR: the control arm returned ZERO sanctioned occurrences across ${candidates} candidate file(s) of ${tracked_n} tracked — the extractor is not reaching the token, so the violation count is unreadable. A zero whose control arm also returned zero is a broken probe, not an empty population."
    return 3
  fi

  [ -n "$findings" ] && printf '%s' "$findings"

  local exempt_note=""
  if [ "$apply_exemptions" = "yes" ]; then
    exempt_note="; ${exempted} violation(s) under the 3 exempt prefixes (re-run --no-exempt to price the exemption)"
  else
    exempt_note="; exemptions LIFTED (all tracked paths in scope)"
  fi
  echo "DENOM: ${tracked_n} tracked file(s) enumerated, ${candidates} carrying a token rendering; CONTROL ${sanctioned} sanctioned occurrence(s) observed (non-zero, so the zero below is readable); ${violations} unsanctioned${exempt_note}"

  [ "$violations" -gt 0 ] && return 1
  return 0
}

# ─── --self-test: FIVE committed cases, FOUR verdict classes ──────────────────
# Every fixture string is ASSEMBLED from fragments at run time, so this file
# contains no literal unsanctioned spelling and stays clean under its own gate.
# The fixture roots are real git work trees with the fixture files staged, so the
# self-test exercises the SAME `git ls-files` / `git grep` enumeration the corpus
# scan uses — not a parallel test-only path that could pass while production rots.
pv7_self_test() {
  local tmp pass=0 total=0
  tmp=$(mktemp -d "${TMPDIR:-/tmp}/pv7-selftest-XXXXXX") || { echo "SCAN-ERROR: cannot create fixture root"; return 3; }
  # shellcheck disable=SC2064
  trap "rm -rf '$tmp'" EXIT

  local N="NOT" E="EVALUATED" SP=" " US="_"
  local ok_form="${N}-${E}"
  local bad_space="${N}${SP}${E}"
  local bad_under="${N}${US}${E}"

  _mkrepo() {
    local d="$1"; shift
    mkdir -p "$d" || return 3
    git -C "$d" init -q >/dev/null 2>&1 || return 3
    return 0
  }
  _stage() { git -C "$1" add -- "$2" >/dev/null 2>&1; }

  _arm() {
    local name="$1" root="$2" want_rc="$3" want_grep="$4"
    local out rc=0
    out=$(pv7_scan "$root" yes) || rc=$?
    total=$((total + 1))
    if [ "$rc" -eq "$want_rc" ] && { [ -z "$want_grep" ] || printf '%s' "$out" | grep -q "$want_grep"; }; then
      pass=$((pass + 1)); echo "  PASS  ${name}"
    else
      echo "  FAIL  ${name} (rc=${rc}, expected ${want_rc})"
      printf '%s\n' "$out" | sed 's/^/        /'
    fi
  }

  # A — SENSITIVITY: a space-separated rendering MUST be caught (rc 1).
  local a="$tmp/a"; _mkrepo "$a" || return 3
  printf 'emit "leg %s across N item(s)"\n' "$bad_space" > "$a/emit.sh"
  printf 'a clean line reading %s here\n' "$ok_form" > "$a/ok.md"
  _stage "$a" emit.sh; _stage "$a" ok.md
  _arm "A SENSITIVITY — a space-separated rendering is caught" "$a" 1 "emit.sh:1"

  # B — SENSITIVITY: an underscore rendering MUST be caught too (rc 1).
  local b="$tmp/b"; _mkrepo "$b" || return 3
  printf 'STATE=%s\n' "$bad_under" > "$b/state.sh"
  printf 'the sanctioned form is %s\n' "$ok_form" > "$b/ok.md"
  _stage "$b" state.sh; _stage "$b" ok.md
  _arm "B SENSITIVITY — an underscore rendering is caught" "$b" 1 "underscore-separated"

  # C — SPECIFICITY: the sanctioned form alone MUST return a clean zero (rc 0).
  local c="$tmp/c"; _mkrepo "$c" || return 3
  printf 'log "  %s: check — detail"\n' "$ok_form" > "$c/clean.sh"
  _stage "$c" clean.sh
  _arm "C SPECIFICITY — the sanctioned form alone is clean" "$c" 0 "0 unsanctioned"

  # D — SPECIFICITY / PROSE: lowercase prose and snake_case identifiers are NOT
  #     tokens and must never be flagged. This is the arm that would fail first if
  #     someone "helpfully" made the predicate case-insensitive.
  local d="$tmp/d"; _mkrepo "$d" || return 3
  {
    printf 'the DEPLOYED arm was not evaluated; see stderr\n'
    printf 'flag_not_evaluated "check" "detail"\n'
    printf 'NOTEVAL_COUNT=0\n'
    printf 'sanctioned %s\n' "$ok_form"
  } > "$d/prose.sh"
  _stage "$d" prose.sh
  _arm "D SPECIFICITY — lowercase prose and snake_case identifiers are not tokens" "$d" 0 "0 unsanctioned"

  # E — FAIL-LOUD: a corpus with NO sanctioned occurrence must exit 3, never 0.
  #     This is the control arm proving the control arm works.
  local e="$tmp/e"; _mkrepo "$e" || return 3
  printf 'nothing relevant here at all\n' > "$e/empty.md"
  _stage "$e" empty.md
  _arm "E FAIL-LOUD — a dead control arm exits 3 rather than reporting a clean zero" "$e" 3 "broken probe"

  echo "SELF-TEST: ${pass}/${total} cases pass — sensitivity arm 2/2 observed NON-ZERO findings (space + underscore); specificity arm 2/2 observed ZERO (sanctioned-only, and prose/identifier); fail-loud arm 1/1 returned exit 3 rather than a clean zero"
  [ "$pass" -eq "$total" ] || return 1
  return 0
}

case "${1:-}" in
  --self-test) pv7_self_test; exit $? ;;
  --no-exempt) pv7_scan "." no; exit $? ;;
  --root)      pv7_scan "${2:-.}" yes; exit $? ;;
  "")          pv7_scan "." yes; exit $? ;;
  *)           echo "usage: $0 [--self-test | --no-exempt | --root <dir>]"; exit 3 ;;
esac
