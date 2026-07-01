#!/bin/bash
# context-budget-auditor — Measure-mode scanner.
#
# Estimates per-component token cost across the pmo-platform loadable-component
# surface and prints a per-component table + total + a flagged-bloat section with
# the applied thresholds stated inline. Read-only: measures cost, mutates nothing.
#
# Estimation method (DECLARED — printed in the report header):
#   tokens ≈ ceil(words / 0.75)   (~0.75 words per token, English prose)
# The heuristic is the primary estimator by design — it is byte-stable and
# portable across model versions, so trend-over-time is interpretable even
# though the absolute is approximate. tiktoken is an OPTIONAL opt-in refinement
# (not used here); wiring it in would add a separate, clearly-labeled exact
# column for a named model, never silently replace the heuristic.
#
# Roster source of truth: the SKILL.md roster is extracted from the deploy.sh
# per-module arrays (OPERATIONS_SKILLS / RELEASE_SKILLS / CORE_SKILLS) at runtime
# — NEVER a hardcoded count (CLAUDE.md "Parameterize over hardcode"). This mirrors
# the awk-window idiom check-canonical-structure.sh uses.
#
# Bloat thresholds (STATED inline in the flagged section):
#   • absolute soft-ceiling — a single SKILL.md whose `wc -c` > 25600 bytes (25 KB),
#     the canonical value REUSED from core/standards/canonical-skill-structure.md §5
#     (not a new magic number).
#   • relative band — a component class in the top decile of per-component cost
#     (computed by the skill from the per-class shares; this script emits the raw
#     per-class figures the skill ranks).
#
# Usage:
#   bash core/skills/context-budget-auditor/scripts/measure-context-budget.sh
#   bash core/skills/context-budget-auditor/scripts/measure-context-budget.sh --self-test
#
# Exit codes: 0 ok · 2 usage error · 3 scan-surface error (roster unreadable).

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# Canonical single-file soft-ceiling, reused from canonical-skill-structure.md §5.
SKILL_SOFT_CEILING_BYTES=25600
# Documented word→token multiplier (declared in the report header).
WORD_PER_TOKEN="0.75"

# est_tokens_from_words — ceil(words / 0.75), integer arithmetic (bash 3.2).
est_tokens_from_words() {
  local words="$1"
  # ceil(w / 0.75) == ceil(4w / 3) == (4w + 2) / 3   (integer division)
  echo $(( (4 * words + 2) / 3 ))
}

# extract_roster_array — pull a named bash array literal out of deploy.sh at
# runtime, one element per line (single source of truth for the roster).
extract_roster_array() {
  local array_name="$1" deploy_sh="$2"
  awk -v name="$array_name" '
    $0 ~ ("^" name "=\\(") { capture=1; next }
    capture && /^\)/        { capture=0 }
    capture {
      line=$0; sub(/#.*/, "", line); gsub(/[[:space:]]/, "", line)
      if (line != "") print line
    }
  ' "$deploy_sh"
}

# measure_files — given a list of file paths on stdin, print
# "<count> <total_words> <total_bytes> <est_tokens>" for the set.
measure_files() {
  local count=0 words=0 bytes=0 f w b
  while IFS= read -r f; do
    [[ -f "$f" ]] || continue
    w=$(wc -w < "$f" | tr -d ' '); b=$(wc -c < "$f" | tr -d ' ')
    count=$((count + 1)); words=$((words + w)); bytes=$((bytes + b))
  done
  echo "$count $words $bytes $(est_tokens_from_words "$words")"
}

run_scan() {
  local repo_root="$1"; REPO_ROOT="$repo_root"
  local deploy_sh="$repo_root/core/deploy/deploy.sh"

  if [[ ! -f "$deploy_sh" ]]; then
    echo "FAIL: scan-surface error — roster source not found: $deploy_sh" >&2
    return 3
  fi

  # --- Resolve the SKILL.md roster from the deploy.sh arrays (parameterized). ---
  local -a skill_files=()
  local arr name
  for arr in OPERATIONS_SKILLS RELEASE_SKILLS CORE_SKILLS; do
    while IFS= read -r name; do
      [[ -n "$name" ]] || continue
      # module = lowercased array prefix
      case "$arr" in
        OPERATIONS_SKILLS) skill_files+=("$repo_root/operations/skills/$name/SKILL.md") ;;
        RELEASE_SKILLS)    skill_files+=("$repo_root/release/skills/$name/SKILL.md") ;;
        CORE_SKILLS)       skill_files+=("$repo_root/core/skills/$name/SKILL.md") ;;
      esac
    done < <(extract_roster_array "$arr" "$deploy_sh")
  done

  if [[ ${#skill_files[@]} -eq 0 ]]; then
    echo "FAIL: scan-surface error — extracted an EMPTY skill roster from $deploy_sh" >&2
    return 3
  fi

  # --- Report header (declares the estimation method + roster provenance). ---
  echo "# Context Budget Report"
  echo
  echo "- Estimation method: word-count heuristic — tokens ≈ ceil(words / ${WORD_PER_TOKEN}) [INFERRED]. tiktoken not applied (optional opt-in refinement)."
  echo "- Roster provenance: SKILL.md count sourced from deploy.sh per-module arrays (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS) — not a hardcoded literal [SOURCE]."
  echo "- Survey: $(cd "$repo_root" && git rev-parse --short HEAD 2>/dev/null || echo '(no git)') · $(date -u +%Y-%m-%dT%H:%MZ)"
  echo
  echo "## Per-component token estimate"
  echo
  echo "| Component class | files | est. tokens | bytes |"
  echo "|---|---|---|---|"

  local total_tokens=0

  emit_row() {
    local label="$1" listing="$2"
    local m; m=$(printf '%s\n' "$listing" | measure_files)
    local c w b t; read -r c w b t <<<"$m"
    printf "| %s | %s | %s | %s |\n" "$label" "$c" "$t" "$b"
    total_tokens=$((total_tokens + t))
  }

  emit_row "SKILL.md catalog (deploy.sh roster)" "$(printf '%s\n' "${skill_files[@]}")"
  emit_row "core/rules/"        "$(find "$repo_root/core/rules"        -maxdepth 1 -name '*.md' -type f 2>/dev/null)"
  emit_row "core/standards/"    "$(find "$repo_root/core/standards"    -name '*.md' -type f 2>/dev/null)"
  emit_row "core/schemas/"      "$(find "$repo_root/core/schemas"      -name '*.md' -type f 2>/dev/null)"
  emit_row "core/specs/"        "$(find "$repo_root/core/specs"        -name '*.md' -type f 2>/dev/null)"
  emit_row "core/disciplines/"  "$(find "$repo_root/core/disciplines"  -name '*.md' -type f 2>/dev/null)"
  emit_row "agents"             "$(find "$repo_root" -path '*/skills/*/agents/*.md' -type f 2>/dev/null)"
  emit_row "hooks (.claude/hooks/)" "$(find "$repo_root/.claude/hooks" -maxdepth 1 -name '*.sh' -type f 2>/dev/null)"
  # CLAUDE.md lives at the workspace root, which is the repo root on a canonical
  # install but one level up on a nested install; try both (graceful degradation —
  # measure_files skips whichever is absent). OPERATIONS.md is always in-repo.
  local claude_md="$repo_root/CLAUDE.md"; [[ -f "$claude_md" ]] || claude_md="$repo_root/../CLAUDE.md"
  emit_row "CLAUDE.md chain"    "$(printf '%s\n' "$claude_md" "$repo_root/core/governance/OPERATIONS.md")"

  echo
  echo "**Total estimated loaded tokens: ~${total_tokens}** [INFERRED — word-count heuristic]"
  echo
  echo "## Flagged bloat candidates"
  echo
  echo "Applied thresholds (stated inline): (a) **absolute soft-ceiling** — a single SKILL.md whose \`wc -c\` > ${SKILL_SOFT_CEILING_BYTES} bytes (25 KB), the canonical value reused from canonical-skill-structure.md §5; (b) **relative band** — a component in the top decile of per-component cost (ranked by the skill)."
  echo

  # Absolute soft-ceiling pass over the SKILL.md roster.
  local flagged=0 f b
  for f in "${skill_files[@]}"; do
    [[ -f "$f" ]] || continue
    b=$(wc -c < "$f" | tr -d ' ')
    if [[ $b -gt $SKILL_SOFT_CEILING_BYTES ]]; then
      printf -- "- %s — %s bytes > %s soft-ceiling [RECOMMENDED: candidate to move detail to references/ per knowledge-architecture.md §3]\n" \
        "${f#$repo_root/}" "$b" "$SKILL_SOFT_CEILING_BYTES"
      flagged=$((flagged + 1))
    fi
  done
  [[ $flagged -eq 0 ]] && echo "- none crossed the stated 25 KB single-file soft-ceiling this run (relative-band ranking is applied by the skill over the per-class table above)."

  return 0
}

self_test() {
  local pass=0
  # est_tokens_from_words: ceil(3/0.75)=4; ceil(1/0.75)=2; ceil(0)=0.
  [[ "$(est_tokens_from_words 3)" == "4" ]] && pass=$((pass+1)) || { echo "self-test FAIL: est(3) != 4" >&2; return 1; }
  [[ "$(est_tokens_from_words 1)" == "2" ]] && pass=$((pass+1)) || { echo "self-test FAIL: est(1) != 2" >&2; return 1; }
  [[ "$(est_tokens_from_words 0)" == "0" ]] && pass=$((pass+1)) || { echo "self-test FAIL: est(0) != 0" >&2; return 1; }
  [[ "$(est_tokens_from_words 750)" == "1000" ]] && pass=$((pass+1)) || { echo "self-test FAIL: est(750) != 1000" >&2; return 1; }
  # extract_roster_array against a stub deploy.sh.
  local tmp; tmp="$(mktemp -d)"; trap 'rm -rf "$tmp"' RETURN
  cat > "$tmp/deploy.sh" <<'STUB'
CORE_SKILLS=(
  alpha
  beta
)
STUB
  local got; got="$(extract_roster_array CORE_SKILLS "$tmp/deploy.sh" | tr '\n' ',')"
  [[ "$got" == "alpha,beta," ]] && pass=$((pass+1)) || { echo "self-test FAIL: roster extract got '$got'" >&2; return 1; }
  echo "self-test OK ($pass assertions passed)"
  return 0
}

main() {
  case "${1:-}" in
    --self-test) self_test; exit $? ;;
    "")          run_scan "$REPO_ROOT"; exit $? ;;
    *)           echo "Usage: bash measure-context-budget.sh [--self-test]" >&2; exit 2 ;;
  esac
}

main "$@"
