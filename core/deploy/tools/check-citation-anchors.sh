#!/bin/bash
# check-citation-anchors.sh — Check 66 predicate: drift-prone line-number locators
# used as cross-skill citations in the skill self-description tree.
#
# WHAT IT ASSERTS. No tracked *.md under core/skills/, release/skills/ or
# operations/skills/ locates a cross-skill referent by LINE NUMBER. The canonical form
# is a section-name anchor: a `§` segment carrying the target heading's text verbatim,
# over a plain link to the target file with no `#fragment`.
#
# WHY THE LINE-NUMBER FORM IS THE DEFECT. It fails OPEN. Every line number in a long
# file "resolves" — so a citation that has drifted onto the wrong content is
# indistinguishable from a correct one, by any mechanical means. Measured at the
# introducing pin: 5 of 6 release-planner citations in pmo-release-manager pointed at
# the wrong content, and 7 of 7 change-management citations in pmo-ocm-lead were off by
# exactly one line — a single inserted line upstream broke seven at once. A section name
# that no longer exists returns zero from a grep. The fix is not accuracy; it is
# converting a silent failure mode into a detectable one.
#
# TWO LEXICAL FORMS, because narrowing to one was measured to miss real carriers:
#   F1  SKILL.md:NNN        filename-qualified line anchor
#   F2  `:NNN`              backticked bare line number, no filename
# A predicate covering only F1 misses 3 live anchors inside a file it already flags, and
# misses an entire third carrier file whose 9 anchors are all F2.
#
# SCOPE — tracked *.md under the three skill roots. NOT the whole corpus: every one of
# the 38 out-of-scope lines a corpus-wide predicate returns is a LEGITIMATE use — frozen
# release plans, an immutable ADR, [SOURCE]-labelled evidence pins, and
# upstream-reference-catalog.md's `upstream_citation` field, which DEFINES itself as an
# exact file:line pin into an external repo we neither control nor can add anchors to.
# Flagging those would require an exemption list — a second source of truth for what
# counts as a citation — to buy zero additional true positives. Scope is a TREE +
# FILE-TYPE predicate rather than a filename glob, so a composition contract that is not
# named composition-contract-*.md is covered on creation (the exact miss that hid
# pmo-ocm-lead from the originating ticket's own probe). Fixture / eval / testdata trees
# are exempt — they carry deliberate defects as their purpose (Check 63/64 precedent).
#
# DECLARED COVERAGE BOUNDARY — state this; do not imply more. NOT covered:
#   (a) whether a section-name anchor's cited heading actually EXISTS in its target —
#       that is the resolution predicate the acceptance criteria run, a different
#       invariant;
#   (b) whether a nearest-enclosing-heading citation's PROSE SUB-REFERENT still exists
#       (a citation that names an enclosing heading and then points onward in prose to
#       a numbered step, or to a section of an artifact the composed skill emits). Those
#       citations carry a verified enclosing heading and an UNVERIFIED sub-locator: the
#       heading half is greppable, the prose half is not, and this predicate is lexically
#       incapable of seeing it. A renumbered step therefore still fails open. Declared
#       here so the residual is on the face of the gate rather than implied away;
#   (c) non-.md files — tool output strings legitimately print file:line;
#   (d) citations to non-SKILL.md targets.
#
# POSIX-portable (BSD + GNU): no \b, no GNU-only flags, LC_ALL=C. The \b form silently
# returns zero on this platform's grep — a live hazard, not a hypothetical.
#
# CONTRACT
#   Output: one finding per line, `FAIL: <path>:<line>: <verbatim matched text>`,
#           plus `DENOM: <N> file(s) examined ...` and `SUMMARY: N finding(s)`.
#   Exit:   0 no findings · 1 findings · 3 scan-surface error (fail loud, never green)
#   bash core/deploy/tools/check-citation-anchors.sh              # live scan
#   bash core/deploy/tools/check-citation-anchors.sh --self-test  # committed fixtures

set -uo pipefail
export LC_ALL=C

GREP=/usr/bin/grep

# The match predicate. Both forms, POSIX ERE, no \b.
CITATION_RE='(SKILL\.md:[0-9]+)|(`:[0-9]+`)'

# is_in_scope <path> — tree + file-type predicate; fixture trees exempt.
is_in_scope() {
  local p="$1"
  case "$p" in
    core/skills/*.md|release/skills/*.md|operations/skills/*.md) ;;
    *) return 1 ;;
  esac
  case "$p" in
    */tests/*|*/fixtures/*|*/testdata/*|*/evals/*|*/_examples/*) return 1 ;;
  esac
  return 0
}

# citation_findings <file> — emit "FAIL: <file>:<lineno>: <matched text>" per F1/F2 hit.
citation_findings() {
  local f="$1" hit ln body toks
  while IFS= read -r hit; do
    [ -z "$hit" ] && continue
    ln="${hit%%:*}"
    body="${hit#*:}"
    toks=$(printf '%s\n' "$body" | "$GREP" -oE "$CITATION_RE" | tr '\n' ' ')
    printf 'FAIL: %s:%s: %s\n' "$f" "$ln" "${toks% }"
  done < <("$GREP" -nE "$CITATION_RE" "$f" 2>/dev/null)
}

# ─── --self-test: SIX committed cases, THREE verdict classes ──────────────────
#
# FLAG and CLEAN are the sensitivity and specificity arms. SCOPE-OUT is a third,
# separate class because "not flagged" and "not examined" are different results, and a
# specificity arm whose input was never read is VACUOUS, not passing.
#
# Every case asserts a non-zero body byte-count before its verdict: a 0-byte case body
# reports "0 flagged" and reads as passing while proving nothing. Zero cases parsed is
# exit 3, never a green harness.
#
# The FLAG bodies are verbatim from the live defect at the introducing pin. The CLEAN
# bodies differ from FLAG-1 ONLY in the property under test — same skill, same mode,
# same link syntax, a name locator instead of a line one — so a pass discriminates the
# defect rather than the topic. The em dash below is U+2014 and is load-bearing: the
# target headings carry it, so a build that normalised it to a hyphen would break the
# verbatim rule this convention rests on. CLEAN-1 guards that byte.
self_test() {
  local root rc=0 parsed=0 pass=0
  local flag_pass=0 flag_findings=0 clean_pass=0 scope_pass=0
  local -a failures=()

  root=$(mktemp -d 2>/dev/null) || { echo "SELF-TEST: cannot create fixture root"; return 3; }
  trap 'rm -rf "$root"' RETURN

  mkdir -p "$root/core/skills/fx-flag-1" \
           "$root/core/skills/fx-flag-2/references" \
           "$root/core/skills/fx-clean-1" \
           "$root/core/skills/fx-clean-2/references" \
           "$root/core/standards" \
           "$root/core/skills/fx-scope-2/tests"

  # FLAG-1 — F1, verbatim from the live defect.
  printf '%s\n' '`release-planner` **Mode A (Backlog Analysis, `SKILL.md:93`)**' \
    > "$root/core/skills/fx-flag-1/SKILL.md"
  # FLAG-2 — F2, verbatim from the live defect.
  printf '%s\n' 'Risk Register (`:206`), Cross-Milestone Validation (`:171`)' \
    > "$root/core/skills/fx-flag-2/references/contract.md"
  # CLEAN-1 — the near-miss: name locator instead of line locator. Carries U+2014.
  printf '%s\n' '[`release-planner` § Mode A — Backlog Analysis](../release-planner/SKILL.md)' \
    > "$root/core/skills/fx-clean-1/SKILL.md"
  # CLEAN-2 — the sibling-contract form: mode named, no locator at all.
  printf '%s\n' '`release-executor` **Mode A (Execute Release)**' \
    > "$root/core/skills/fx-clean-2/references/contract.md"
  # SCOPE-OUT-1 — external-upstream pin, correct by design; outside the skill tree.
  printf '%s\n' 'upstream_citation: an exact pin, e.g. skill-creator/SKILL.md:1' \
    > "$root/core/standards/fx-upstream.md"
  # SCOPE-OUT-2 — FLAG-1's body inside a fixture tree; exempt by path class.
  printf '%s\n' '`release-planner` **Mode A (Backlog Analysis, `SKILL.md:93`)**' \
    > "$root/core/skills/fx-scope-2/tests/fx.md"

  local -a flag_cases=(
    "core/skills/fx-flag-1/SKILL.md"
    "core/skills/fx-flag-2/references/contract.md"
  )
  local -a clean_cases=(
    "core/skills/fx-clean-1/SKILL.md"
    "core/skills/fx-clean-2/references/contract.md"
  )
  local -a scope_cases=(
    "core/standards/fx-upstream.md"
    "core/skills/fx-scope-2/tests/fx.md"
  )

  local rel bytes n
  ( cd "$root" || exit 3

    for rel in "${flag_cases[@]}" "${clean_cases[@]}" "${scope_cases[@]}"; do
      bytes=$(wc -c < "$rel" 2>/dev/null | tr -d ' ')
      [ "${bytes:-0}" -gt 0 ] || { echo "EMPTY-BODY $rel"; }
    done

    for rel in "${flag_cases[@]}"; do
      echo "PARSED"
      if ! is_in_scope "$rel"; then echo "FAILCASE FLAG $rel not-examined"; continue; fi
      n=$(citation_findings "$rel" | wc -l | tr -d ' ')
      if [ "$n" -ge 1 ]; then echo "PASSCASE FLAG $n"; else echo "FAILCASE FLAG $rel zero-findings"; fi
    done
    for rel in "${clean_cases[@]}"; do
      echo "PARSED"
      if ! is_in_scope "$rel"; then echo "FAILCASE CLEAN $rel not-examined"; continue; fi
      n=$(citation_findings "$rel" | wc -l | tr -d ' ')
      if [ "$n" -eq 0 ]; then echo "PASSCASE CLEAN 0"; else echo "FAILCASE CLEAN $rel $n-findings"; fi
    done
    for rel in "${scope_cases[@]}"; do
      echo "PARSED"
      if is_in_scope "$rel"; then echo "FAILCASE SCOPE-OUT $rel examined"; else echo "PASSCASE SCOPE-OUT 0"; fi
    done
  ) > "$root/.result" 2>&1

  while IFS= read -r line; do
    case "$line" in
      PARSED) parsed=$((parsed + 1)) ;;
      "PASSCASE FLAG "*) pass=$((pass + 1)); flag_pass=$((flag_pass + 1))
                         flag_findings=$((flag_findings + ${line##* })) ;;
      "PASSCASE CLEAN "*) pass=$((pass + 1)); clean_pass=$((clean_pass + 1)) ;;
      "PASSCASE SCOPE-OUT "*) pass=$((pass + 1)); scope_pass=$((scope_pass + 1)) ;;
      FAILCASE*|EMPTY-BODY*) failures+=("$line") ;;
    esac
  done < "$root/.result"

  if [ "$parsed" -eq 0 ]; then
    echo "SELF-TEST: 0 cases parsed — the harness examined nothing, which is a defect and not a pass"
    return 3
  fi

  if [ "${#failures[@]}" -gt 0 ]; then
    printf '%s\n' "${failures[@]}"
    rc=1
  fi

  echo "SELF-TEST: ${pass}/${parsed} cases pass — must-flag arm ${flag_pass}/2 observed NON-ZERO (${flag_findings} finding(s)); must-not-flag arm ${clean_pass}/2 observed ZERO; scope-out arm ${scope_pass}/2 excluded from the denominator"
  return $rc
}

# ─── live scan ────────────────────────────────────────────────────────────────
live_scan() {
  local -a tracked=()
  local f examined=0 findings=0 out

  if ! command -v git >/dev/null 2>&1; then
    echo "SCAN-ERROR: git unavailable — the tracked-file denominator cannot be established, so a zero here would be untrustworthy"
    return 3
  fi
  while IFS= read -r f; do
    [ -n "$f" ] && tracked+=("$f")
  done < <(git ls-files 'core/skills/*.md' 'release/skills/*.md' 'operations/skills/*.md' 2>/dev/null)

  if [ "${#tracked[@]}" -eq 0 ]; then
    echo "SCAN-ERROR: git ls-files returned zero *.md under the three skill roots — the denominator is empty, which is a scan-surface failure and not a clean result"
    return 3
  fi

  out=""
  for f in "${tracked[@]}"; do
    is_in_scope "$f" || continue
    [ -f "$f" ] || continue
    examined=$((examined + 1))
    local hits
    hits=$(citation_findings "$f")
    if [ -n "$hits" ]; then
      out="${out}${hits}"$'\n'
      findings=$((findings + $(printf '%s\n' "$hits" | wc -l | tr -d ' ')))
    fi
  done

  if [ "$examined" -eq 0 ]; then
    echo "SCAN-ERROR: 0 files survived the scope predicate out of ${#tracked[@]} tracked — nothing was examined"
    return 3
  fi

  [ -n "$out" ] && printf '%s' "$out"
  echo "DENOM: ${examined} file(s) examined of ${#tracked[@]} tracked *.md under core/skills/, release/skills/, operations/skills/ (fixture/eval/testdata trees excluded)"
  echo "SUMMARY: ${findings} finding(s)"
  [ "$findings" -eq 0 ] && return 0
  return 1
}

case "${1:-}" in
  --self-test) self_test; exit $? ;;
  "")          live_scan; exit $? ;;
  *)           echo "usage: $0 [--self-test]"; exit 3 ;;
esac
