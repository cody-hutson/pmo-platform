#!/usr/bin/env bash
# fitness-audit-search-primitives.sh — pmo-qa-auditor Mode F search + evidence primitives
#
# Read-only bash over gh / jq / grep / git. Spec: ../references/fitness-audit-mode-spec.md
# §3 (subcommands + inline equivalents) and §4 (evidence bar). A convenience bundle:
# when this script is unreachable (deployed contexts), Mode F runs the documented
# inline equivalents directly — the search discipline (3 variants; dataset-size-verified
# --limit per core/rules/git-workflow.md § Batch CLI Query Limits) binds either way.
#
# Subcommands:
#   search "<v1>" "<v2>" "<v3>"        3-variant backlog search (foreground, no
#                                      per-item gh-in-loop); dataset-size check
#                                      before --limit; JSON out with per-variant
#                                      counts + deduped candidate union + the
#                                      size-verification record + truncation flag.
#   validate-evidence <file> [--seed S] deterministic evidence-bar checks (mode-spec
#                                      §4) over citation tokens extracted from the
#                                      file; seeded sample (default seed = UTC date
#                                      digits); exit 1 on any sampled FAIL.
#   --self-test                        runs the deterministic fixture families
#                                      (evidence-bar + banding boundary) parsed from
#                                      ../evals/fitness-audit-characterization-fixtures.md
#                                      against the banding SSOT in
#                                      ../references/fitness-audit-dimension-rubric.md §3;
#                                      exit 1 on any mismatch.
#
# Read-only guarantee: this script mutates nothing — gh list/view reads, git
# plumbing reads, file reads only. Registered on the script-execution allowlist
# (core/config/allowlists/script-execution-allowlist.txt) for BLOCK-DESTRUCTIVE-022.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd -P)"
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd -P)"
FIXTURES="${SKILL_DIR}/evals/fitness-audit-characterization-fixtures.md"
RUBRIC="${SKILL_DIR}/references/fitness-audit-dimension-rubric.md"

log() { printf '%s\n' "$*" >&2; }
die() { log "fitness-audit-search-primitives: ERROR: $*"; exit 64; }

repo_root() {
  git -C "${SCRIPT_DIR}" rev-parse --show-toplevel 2>/dev/null || true
}

usage() {
  grep '^#' "$0" | sed -n '2,28p' | sed 's/^# \{0,1\}//' >&2
  exit 64
}

# ---------------------------------------------------------------------------
# search "<v1>" "<v2>" "<v3>"
# ---------------------------------------------------------------------------
cmd_search() {
  [ "$#" -eq 3 ] || die "search requires exactly 3 query variants (Mode F search discipline: terms / synonyms / mechanism rephrase)"
  command -v gh >/dev/null 2>&1 || die "gh CLI required for backlog search (inline equivalents: mode-spec §3)"
  command -v jq >/dev/null 2>&1 || die "jq required"

  # Dataset-size check BEFORE --limit (git-workflow § Batch CLI Query Limits):
  # the highest issue number bounds the dataset size from above.
  local bound limit
  bound="$(gh issue list --state all --limit 1 --json number -q '.[0].number' 2>/dev/null)" \
    || die "dataset-size check failed — gh cannot read the repo (set GH_REPO or run from the platform repo)"
  case "${bound}" in (''|*[!0-9]*) die "dataset-size check returned non-numeric: '${bound}'";; esac
  limit="${bound}"
  [ "${limit}" -lt 1000 ] && limit=1000

  # Three FOREGROUND variant searches (sequential; never per-item gh-in-loop).
  local r1 r2 r3
  r1="$(gh issue list --state all --search "$1" --limit "${limit}" --json number,title,state,labels)"
  r2="$(gh issue list --state all --search "$2" --limit "${limit}" --json number,title,state,labels)"
  r3="$(gh issue list --state all --search "$3" --limit "${limit}" --json number,title,state,labels)"

  jq -n \
    --argjson a "${r1}" --argjson b "${r2}" --argjson c "${r3}" \
    --arg q1 "$1" --arg q2 "$2" --arg q3 "$3" \
    --argjson bound "${bound}" --argjson limit "${limit}" '
    def truncated(x): (x | length) >= $limit;
    { dataset_bound: $bound,
      limit_used: $limit,
      size_verification: "limit >= highest issue number (upper bound on dataset size)",
      truncation_suspected: (truncated($a) or truncated($b) or truncated($c)),
      variants: [ {query:$q1, count:($a|length)},
                  {query:$q2, count:($b|length)},
                  {query:$q3, count:($c|length)} ],
      candidates: ([ $a[], $b[], $c[] ] | unique_by(.number) | sort_by(.number)) }'
}

# ---------------------------------------------------------------------------
# Evidence-bar deterministic checks (mode-spec §4)
# ---------------------------------------------------------------------------
CF1_RE='[A-Za-z0-9_./-]+\.(md|sh|py|yml|yaml|toml|json):[0-9]+'
CF2_CMD_RE='(grep|git|gh|ls|find|wc)[^`]*'
CF3_ISSUE_RE='#[0-9]+'
CF3_VER_RE='v[0-9]+\.[0-9]+(\.[0-9]+)?'
CF4_RE='\b[0-9a-f]{7,40}\b'

# check_cf1 <path:line> <root> -> PASS/FAIL
check_cf1() {
  local tok="$1" root="$2" path line len
  path="${tok%:*}"; line="${tok##*:}"
  [ -f "${root}/${path}" ] || { printf 'FAIL'; return; }
  len="$(wc -l < "${root}/${path}" | tr -d ' ')"
  if [ "${line}" -le "${len}" ] 2>/dev/null; then printf 'PASS'; else printf 'FAIL'; fi
}

# check_cf2 <line> -> PASS/FAIL  (form: read-only command word + output marker)
check_cf2() {
  local s="$1"
  if grep -qE "${CF2_CMD_RE}" <<<"${s}" && grep -q '→' <<<"${s}"; then
    printf 'PASS'
  else
    printf 'FAIL'
  fi
}

# check_cf3 <token> -> PASS/FAIL/SKIP
check_cf3() {
  local tok="$1" n
  if grep -qE "^${CF3_ISSUE_RE}\$" <<<"${tok}"; then
    command -v gh >/dev/null 2>&1 || { printf 'SKIP'; return; }
    n="${tok#\#}"
    if gh issue view "${n}" --json number >/dev/null 2>&1 || gh pr view "${n}" --json number >/dev/null 2>&1; then
      printf 'PASS'
    else
      printf 'FAIL'
    fi
  elif grep -qE "^${CF3_VER_RE}\$" <<<"${tok}"; then
    if [ -n "$(git -C "${SCRIPT_DIR}" tag -l "${tok}" 2>/dev/null)" ]; then printf 'PASS'; return; fi
    command -v gh >/dev/null 2>&1 || { printf 'SKIP'; return; }
    if gh release view "${tok}" --json tagName >/dev/null 2>&1; then printf 'PASS'; else printf 'FAIL'; fi
  else
    printf 'FAIL'
  fi
}

# check_cf4 <sha> -> PASS/FAIL
check_cf4() {
  local sha="$1"
  if git -C "${SCRIPT_DIR}" cat-file -e "${sha}" 2>/dev/null; then printf 'PASS'; else printf 'FAIL'; fi
}

# matches_any_form <string> -> 0 if any CF regex matches, 1 otherwise
matches_any_form() {
  local s="$1"
  grep -qE "${CF1_RE}" <<<"${s}" && return 0
  { grep -qE "${CF2_CMD_RE}" <<<"${s}" && grep -q '→' <<<"${s}"; } && return 0
  grep -qE "${CF3_ISSUE_RE}" <<<"${s}" && return 0
  grep -qE "${CF3_VER_RE}" <<<"${s}" && return 0
  { grep -qE "${CF4_RE}" <<<"${s}" && grep -qE '[a-f]' <<<"${s}" ; } && return 0
  return 1
}

# ---------------------------------------------------------------------------
# validate-evidence <file> [--seed S]
# ---------------------------------------------------------------------------
cmd_validate_evidence() {
  local file="" seed=""
  while [ "$#" -gt 0 ]; do
    case "$1" in
      --seed) seed="$2"; shift 2 ;;
      *) [ -z "${file}" ] && file="$1" || die "unexpected argument: $1"; shift ;;
    esac
  done
  [ -n "${file}" ] || die "validate-evidence requires a file argument"
  [ -f "${file}" ] || die "no such file: ${file}"
  [ -n "${seed}" ] || seed="$(date -u +%Y%m%d)"
  local root; root="$(repo_root)"; [ -n "${root}" ] || die "not inside a git repo — CF-1/CF-4 resolution needs the platform repo"

  # Extract citation candidates (form-tagged, TAB-separated). CF-4 heuristic:
  # require >=1 hex letter to avoid pure-number false positives.
  local candidates
  candidates="$( {
    grep -oE "${CF1_RE}" "${file}" | sed 's/^/CF-1\t/' || true
    grep -oE "${CF3_ISSUE_RE}" "${file}" | sed 's/^/CF-3\t/' || true
    grep -oE "${CF3_VER_RE}" "${file}" | sed 's/^/CF-3\t/' || true
    grep -oE "${CF4_RE}" "${file}" | grep -E '[a-f]' | grep -E '[0-9]' | sed 's/^/CF-4\t/' || true
    grep -nE "${CF2_CMD_RE}" "${file}" | grep '→' | sed 's/^/CF-2\t/' || true
  } | sort -u )"

  local total; total="$(printf '%s\n' "${candidates}" | grep -c . || true)"
  if [ "${total}" -eq 0 ]; then
    log "validate-evidence: no citation candidates found in ${file}"
    printf '{"file":"%s","candidates":0,"sampled":0,"pass":0,"fail":0,"skip":0}\n' "${file}"
    return 0
  fi

  # Seeded sample: N = 10 or all when fewer (mode-spec §4).
  local n=10; [ "${total}" -lt 10 ] && n="${total}"
  local sample
  sample="$(printf '%s\n' "${candidates}" | awk -v seed="${seed}" 'BEGIN{srand(seed)} {printf "%.9f\t%s\n", rand(), $0}' | sort -n | head -n "${n}" | cut -f2-)"

  local pass=0 fail=0 skip=0 form tok verdict
  while IFS="$(printf '\t')" read -r form tok; do
    [ -n "${form}" ] || continue
    case "${form}" in
      CF-1) verdict="$(check_cf1 "${tok}" "${root}")" ;;
      CF-2) verdict="$(check_cf2 "${tok#*:}")" ;;   # strip grep -n line prefix
      CF-3) verdict="$(check_cf3 "${tok}")" ;;
      CF-4) verdict="$(check_cf4 "${tok}")" ;;
      *)    verdict="SKIP" ;;
    esac
    case "${verdict}" in
      PASS) pass=$((pass+1)) ;;
      FAIL) fail=$((fail+1)); log "  FAIL: ${form} ${tok}" ;;
      SKIP) skip=$((skip+1)); log "  SKIP: ${form} ${tok} (resolver unavailable)" ;;
    esac
  done <<EOF
${sample}
EOF

  printf '{"file":"%s","seed":"%s","candidates":%s,"sampled":%s,"pass":%s,"fail":%s,"skip":%s}\n' \
    "${file}" "${seed}" "${total}" "${n}" "${pass}" "${fail}" "${skip}"
  [ "${fail}" -eq 0 ] || exit 1
}

# ---------------------------------------------------------------------------
# --self-test : deterministic fixture families (evidence-bar + banding)
# ---------------------------------------------------------------------------
resolve_live() {
  case "$1" in
    LIVE:highest-issue)
      command -v gh >/dev/null 2>&1 || { printf 'SKIP'; return; }
      local n; n="$(gh issue list --state all --limit 1 --json number -q '.[0].number' 2>/dev/null || true)"
      case "${n}" in (''|*[!0-9]*) printf 'SKIP';; (*) printf '#%s' "${n}";; esac ;;
    LIVE:latest-release)
      command -v gh >/dev/null 2>&1 || { printf 'SKIP'; return; }
      local t; t="$(gh release list --limit 1 --json tagName -q '.[0].tagName' 2>/dev/null || true)"
      case "${t}" in (v[0-9]*) printf '%s' "${t}";; (*) printf 'SKIP';; esac ;;
    LIVE:head-sha) git -C "${SCRIPT_DIR}" rev-parse --short HEAD 2>/dev/null || printf 'SKIP' ;;
    LIVE:root-sha) git -C "${SCRIPT_DIR}" rev-list --max-parents=0 -n 1 HEAD 2>/dev/null | cut -c1-12 || printf 'SKIP' ;;
    *) printf '%s' "$1" ;;
  esac
}

cmd_self_test() {
  [ -f "${FIXTURES}" ] || die "fixtures file missing: ${FIXTURES}"
  [ -f "${RUBRIC}" ]   || die "rubric file missing: ${RUBRIC}"
  local root; root="$(repo_root)"; [ -n "${root}" ] || die "not inside a git repo"
  local tested=0 passed=0 failed=0 skipped=0

  # --- Family 3: evidence-bar ---
  log "self-test: Family 3 — evidence-bar"
  while IFS='|' read -r _ fid form input expected _; do
    fid="$(printf '%s' "${fid}" | sed 's/^ *//;s/ *$//')"
    form="$(printf '%s' "${form}" | sed 's/^ *//;s/ *$//')"
    input="$(printf '%s' "${input}" | sed 's/^ *//;s/ *$//')"
    expected="$(printf '%s' "${expected}" | sed 's/^ *//;s/ *$//')"
    [ -n "${fid}" ] || continue
    local resolved verdict
    resolved="$(resolve_live "${input}")"
    if [ "${resolved}" = "SKIP" ]; then
      skipped=$((skipped+1)); log "  SKIP ${fid} (live resolver unavailable)"; continue
    fi
    tested=$((tested+1))
    case "${form}" in
      CF-1) verdict="$(check_cf1 "${resolved}" "${root}")" ;;
      CF-2) verdict="$(check_cf2 "${resolved#CMD:}")" ;;
      CF-3) verdict="$(check_cf3 "${resolved}")" ;;
      CF-4) verdict="$(check_cf4 "${resolved}")" ;;
      NONE) if matches_any_form "${resolved}"; then verdict='PASS'; else verdict='FAIL'; fi ;;
      *)    verdict='FAIL' ;;
    esac
    if [ "${verdict}" = "SKIP" ]; then
      tested=$((tested-1)); skipped=$((skipped+1)); log "  SKIP ${fid} (resolver unavailable)"; continue
    fi
    if [ "${verdict}" = "${expected}" ]; then
      passed=$((passed+1)); log "  ok   ${fid} (${form} -> ${verdict})"
    else
      failed=$((failed+1)); log "  FAIL ${fid}: expected ${expected}, got ${verdict} (input: ${resolved})"
    fi
  done <<EOF
$(grep -E '^\| EB-[0-9]+ \|' "${FIXTURES}")
EOF

  # --- Family 4: banding boundary (bands parsed from the rubric §3 SSOT) ---
  log "self-test: Family 4 — banding boundary (rubric §3 SSOT + interval-closure rule)"
  local bands
  bands="$(awk '/^## 3\. Banding/,/^## 4\./' "${RUBRIC}" | grep -E '^\| [0-9]' )"
  [ -n "${bands}" ] || die "could not parse the Banding table from rubric §3"
  while IFS='|' read -r _ bid pct eband eclass edeep _; do
    bid="$(printf '%s' "${bid}" | sed 's/^ *//;s/ *$//')"
    pct="$(printf '%s' "${pct}" | sed 's/^ *//;s/ *$//')"
    eband="$(printf '%s' "${eband}" | sed 's/^ *//;s/ *$//')"
    eclass="$(printf '%s' "${eclass}" | sed 's/^ *//;s/ *$//')"
    edeep="$(printf '%s' "${edeep}" | sed 's/^ *//;s/ *$//')"
    [ -n "${bid}" ] || continue
    tested=$((tested+1))
    # Find the matching band row: [lower, upper) with the final band closed.
    local gband="" gclass="" gdeep=""
    while IFS='|' read -r _ brange bclass bdeep _; do
      brange="$(printf '%s' "${brange}" | sed 's/^ *//;s/ *$//')"
      bclass="$(printf '%s' "${bclass}" | sed 's/^ *//;s/ *$//' | sed 's/\*\*//g')"
      bdeep="$(printf '%s' "${bdeep}" | sed 's/^ *//;s/ *$//' | sed 's/\*\*//g')"
      [ -n "${brange}" ] || continue
      local lo hi
      # sigpipe-idiom: allow — `grep -o` emits N matches per LINE, so `-m1` (which counts LINES) would keep both bounds; `head -1` must stay. Writer converted to a here-string.
      lo="$(grep -oE '[0-9]+' <<<"${brange}" | head -1)"
      hi="$(printf '%s' "${brange}" | grep -oE '[0-9]+' | tail -1)"
      if [ "${pct}" -ge "${lo}" ] && { [ "${pct}" -lt "${hi}" ] || { [ "${hi}" -eq 100 ] && [ "${pct}" -le 100 ]; }; }; then
        gband="${brange}"; gclass="${bclass}"; gdeep="${bdeep}"; break
      fi
    done <<EOF2
${bands}
EOF2
    if [ "${gband}" = "${eband}" ] && [ "${gclass}" = "${eclass}" ] && [ "${gdeep}" = "${edeep}" ]; then
      passed=$((passed+1)); log "  ok   ${bid} (${pct}% -> ${gband} / ${gclass} / deep_dive=${gdeep})"
    else
      failed=$((failed+1)); log "  FAIL ${bid}: ${pct}% -> got (${gband} / ${gclass} / ${gdeep}), expected (${eband} / ${eclass} / ${edeep})"
    fi
  done <<EOF
$(grep -E '^\| BND-[0-9]+ \|' "${FIXTURES}")
EOF

  log "self-test: tested=${tested} passed=${passed} failed=${failed} skipped=${skipped}"
  printf '{"tested":%s,"passed":%s,"failed":%s,"skipped":%s}\n' "${tested}" "${passed}" "${failed}" "${skipped}"
  [ "${failed}" -eq 0 ] || exit 1
}

# ---------------------------------------------------------------------------
case "${1:-}" in
  search)            shift; cmd_search "$@" ;;
  validate-evidence) shift; cmd_validate_evidence "$@" ;;
  --self-test|self-test) cmd_self_test ;;
  *) usage ;;
esac
