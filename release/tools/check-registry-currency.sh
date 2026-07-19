#!/bin/bash
# Check 5(d) row-layer (registry-currency) predicate — CI MIRROR.
#
# This is the PR-time CI mirror of deploy.sh Check 5(d)'s ROW layer (#1811):
# it asserts core/skills/registry.md's `## Configuration Items` rows are CURRENT
# against the deploy.sh-declared skill roster. Both surfaces read the SAME roster
# authority (the deploy.sh per-module arrays) so the deploy-time check and this
# mirror cannot disagree on what "rostered" means:
#
#   1. core/deploy/deploy.sh  Check 5(d)  (deploy-time, operator-machine safety net)
#   2. .github/workflows/skill-registry-currency-check.yml  (PR-time gate)
#
# Per core/standards/gate-efficacy-standard.md Requirement (b'): a `required` gate
# must be CI-enforced, not deploy-time-only. deploy.sh --check is never invoked in
# CI, so Check 5(d)'s row layer had no automatic run surface — this workflow is it.
#
# Invariant asserted (the row layer #1811 only — the #1658 FIELD layer is NOT
# mirrored: it resolves its mode from an operator-instance file CI never has, so a
# CI mirror of it is a guaranteed no-op — out of scope, and out of #2540's AC):
#
#   ROSTER ≝ OPERATIONS_SKILLS + RELEASE_SKILLS + CORE_SKILLS  (canary EXCLUDED)
#   ROWS   ≝ every `## Configuration Items` row name in registry.md
#     (i)   every registry ROW name ∈ ROSTER
#     (ii)  every ROSTER member ∈ ROWS       (FAIL on asymmetry, BOTH directions)
#     (iii) every registry ROW name → a live SKILL.md under {operations,release,core}
#
# Canary exclusion (ADR-04 / source-only canary; registry § Configuration Items
# states the source-only canary is NOT a CI): the roster for 5(d) is
# OPERATIONS_SKILLS + RELEASE_SKILLS + CORE_SKILLS ONLY — CANARY_SKILLS is NOT
# unioned in. The canary has a source dir but no registry row, so including it
# would false-FAIL "roster member has no registry row" (deploy.sh:2274 —
# "DO NOT 'fix' this by adding the canary").
#
# ROSTER AUTHORITY = deploy.sh arrays, extracted at runtime (never a hardcoded
# name list here). This is the operator-settled ruling on #2540 (G-PL1 reversal,
# 2026-07-17): array authority is pre-ratified by ADR-008 (deploy.sh = single
# roster source of truth), ADR-038 §Decision 1 (CI population ≝ the deploy.sh
# array members; the canary is NOT a CI), and registry.md § Sources of truth. A
# filesystem-derived roster is empirically wrong today (it sweeps _shared +
# _templates + the canary as skills, 55 vs the true 52) — the generalizable rule:
# duplicate a PARSE (fails loud), never a POLICY (drifts silent).
#
# Usage:
#   bash release/tools/check-registry-currency.sh            # scan the live roster
#   bash release/tools/check-registry-currency.sh --self-test
#
# Output: one OK/FAIL line per finding on stdout; a trailing SUMMARY line.
# Exit codes (mirror the sibling detectors):
#   0 — registry catalog is current (rows ≡ roster, every row resolves)
#   1 — one or more registry-currency FINDINGS (the count is in the SUMMARY line)
#   2 — usage error
#   3 — scan-surface error: could not extract the roster from deploy.sh (empty or
#       SHAPE-INVALID extraction), registry.md is absent, or 0 rows were parsed.
#       ALWAYS hard-fail regardless of enforce/warn posture — a relocated/reformatted
#       source tree means the gate ran against nothing and must not read green.
#
# Two deliberate, documented divergences from deploy.sh Check 5(d), BOTH in the
# detector-broken direction only (never the findings direction — so this mirror can
# never manufacture a CI-red/deploy-green disagreement on a real finding):
#   • ABSENT registry.md ⇒ exit 3 (deploy.sh:2297-2299 gracefully skips + WARNs;
#     correct for a partial operator checkout, WRONG for CI where the file is always
#     expected — a "graceful skip" would read green on the very PR that deleted or
#     moved it).
#   • 0 rows parsed ⇒ exit 3 (deploy.sh:2378-2381 flags a finding + skips the diff;
#     the mirror hard-fails — an empty parse means the registry format broke).
#
# One MIRROR-ONLY guard with no deploy.sh counterpart (deploy.sh reads the live
# bash arrays directly and never parses them, so it has zero extraction fragility;
# this mirror extracts, so it must guard the extraction):
#   • SHAPE GUARD (CD-3 / FM-1): every extracted roster member must match a valid
#     skill-name shape. A deploy.sh array reformatted to the one-line form
#     `NAME=(a b c)` makes the awk extractor drop the members and capture unrelated
#     following lines — a NON-EMPTY garbage result the empty-roster guard cannot
#     catch. Any malformed member ⇒ exit 3 (scan-surface error), not a finding-storm
#     that enforce-mode would surface as ~54 spurious FAILs.

set -uo pipefail

# Run from repo root regardless of cwd. This script lives in release/tools/, so the
# repo root is two levels up (contrast the core/deploy/tools/ siblings at three).
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# Valid skill-name shape (the SHAPE GUARD, CD-3). Every live roster name conforms
# (verified: 52/52 match, 0 non-conforming at the release baseline); the one-line-
# form garbage token `CORE_SKILLS=(` does not. Kept intentionally strict: a real
# skill name is lowercase-alnum-and-hyphen, first char a letter.
SKILL_NAME_RE='^[a-z][a-z0-9-]*$'

# extract_roster_array — pull a named bash array literal out of deploy.sh at
# runtime and print one element per line. Copied VERBATIM from
# core/deploy/tools/check-canonical-structure.sh:115-127 (the Check-6 mirror) so
# the two mirrors extract the roster byte-identically — a bash re-implementation
# in a second language is the exact drift class that cost check-skill-count-imp.py
# its correctness. The one-line-form fragility this import carries is closed by the
# SHAPE GUARD in run_check (the sibling's own exit-3 backstop is incidental —
# it opens each skill's file; a pure set-membership check never does).
#   $1 — array name (e.g. OPERATIONS_SKILLS)
#   $2 — path to deploy.sh
extract_roster_array() {
  local array_name="$1" deploy_sh="$2"
  awk -v name="$array_name" '
    $0 ~ ("^" name "=\\(") { capture=1; next }
    capture && /^\)/        { capture=0 }
    capture {
      line=$0
      sub(/#.*/, "", line)                       # strip trailing comments
      gsub(/[[:space:]]/, "", line)              # strip whitespace
      if (line != "") print line
    }
  ' "$deploy_sh"
}

# parse_registry_rows — extract every `## Configuration Items` row name from
# registry.md. BYTE-IDENTICAL to deploy.sh:2369-2370: each CI row is
# `| [`<name>`](<relpath>) | ...`, and the first backtick-wrapped token in cell 1
# is the name. Deliberately NOT `sort -u`'d — deploy.sh 5(d) does not de-dup the
# rows (a duplicated registry row is a known 5(d) FN, kept for mirror FIDELITY;
# adding a duplicate-row check here would make the mirror stricter than the check
# it mirrors).
#   $1 — path to registry.md
parse_registry_rows() {
  local registry_md="$1"
  # shellcheck disable=SC2016  # `\1` is a sed backreference, not a shell expansion
  grep -E '^\| \[' "$registry_md" 2>/dev/null \
    | sed -E 's/^\| \[`([^`]+)`\].*/\1/' || true
}

# run_check — assert registry-currency against the given scan surfaces. Taking the
# surfaces as PARAMETERS is what makes the self-test hermetic (it points these at a
# mktemp fixture — never the live checkout, no network, no gh).
#   $1 — repo root (so the self-test can point at a fixture tree)
#   $2 — path to deploy.sh (roster authority)
#   $3 — path to registry.md (the catalog under test)
run_check() {
  local repo_root="$1" deploy_sh="$2" registry_md="$3"

  if [[ ! -f "$deploy_sh" ]]; then
    echo "FAIL:  scan-surface error — roster source not found: $deploy_sh" >&2
    return 3
  fi
  # DIVERGENCE (documented): absent registry.md is exit 3 in CI, not deploy.sh's
  # graceful skip. In CI the file is always expected; its absence means the PR
  # moved or deleted it — a skip would read green on exactly that change.
  if [[ ! -f "$registry_md" ]]; then
    echo "FAIL:  scan-surface error — registry catalog not found: $registry_md (CI expects it present; a moved/deleted catalog must fail loud, not skip)" >&2
    return 3
  fi

  # ── Extract the deployed roster: OPERATIONS + RELEASE + CORE, canary EXCLUDED,
  # sort -u (matches deploy.sh:2352-2361). Bash 3.2-safe: while-read into an array,
  # no mapfile.
  local -a DEPLOYED_ROSTER=()
  local _line
  while IFS= read -r _line; do
    [[ -n "$_line" ]] && DEPLOYED_ROSTER+=("$_line")
  done < <(
    {
      extract_roster_array OPERATIONS_SKILLS "$deploy_sh"
      extract_roster_array RELEASE_SKILLS    "$deploy_sh"
      extract_roster_array CORE_SKILLS       "$deploy_sh"
    } | sort -u
  )

  # Empty-roster guard (a relocated/restructured deploy.sh must not read green).
  if [[ ${#DEPLOYED_ROSTER[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — extracted an EMPTY roster from $deploy_sh (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS). A relocated or restructured deploy.sh must not read green." >&2
    return 3
  fi

  # ── SHAPE GUARD (CD-3 / FM-1) — runs BEFORE the membership diff so a garbage
  # roster is a scan-surface error, never a finding-storm. The one-line array form
  # `NAME=(a b c)` makes extract_roster_array return NON-EMPTY garbage (it skips the
  # members' own line via awk `next`, then captures unrelated following lines), which
  # the empty-roster guard above cannot catch. Every member must be a valid skill-
  # name shape; any miss ⇒ exit 3.
  local _member
  for _member in "${DEPLOYED_ROSTER[@]}"; do
    if [[ ! "$_member" =~ $SKILL_NAME_RE ]]; then
      echo "FAIL:  scan-surface error — extracted roster member '$_member' is not a valid skill-name shape (${SKILL_NAME_RE}). A deploy.sh array reformat (e.g. the one-line NAME=(a b) form) yields non-empty garbage the empty-roster guard cannot catch; failing loud rather than reporting spurious findings." >&2
      return 3
    fi
  done

  # ── Parse the registry rows.
  local -a REGISTRY_ROWS=()
  local _rr
  while IFS= read -r _rr; do
    [[ -n "$_rr" ]] && REGISTRY_ROWS+=("$_rr")
  done < <(parse_registry_rows "$registry_md")

  # Audit-baseline guard (deploy.sh:2372-2381): an empty parse is itself suspect —
  # a registry reformat or a moved file would silently break the row parse and
  # produce a false "every roster member has no row" storm. 0 rows ⇒ exit 3
  # (DIVERGENCE, documented: deploy.sh flags a finding + skips; CI hard-fails).
  if [[ ${#REGISTRY_ROWS[@]} -eq 0 ]]; then
    echo "FAIL:  scan-surface error — parsed 0 rows from $registry_md (expected >=1; the row parse broke or the catalog moved). Not running the membership diff." >&2
    return 3
  fi

  # ── The three row-level assertions (#1811). Each divergence is a FINDING.
  local findings=0

  # (i) every registry row name must be a deployed-roster member.
  local _row _found _rs
  for _row in "${REGISTRY_ROWS[@]}"; do
    _found=false
    for _rs in "${DEPLOYED_ROSTER[@]}"; do
      [[ "$_row" == "$_rs" ]] && { _found=true; break; }
    done
    if [[ "$_found" == "false" ]]; then
      echo "FAIL:  registry-currency — registry row '$_row' has no roster member (OPERATIONS_SKILLS/RELEASE_SKILLS/CORE_SKILLS). Add the skill to deploy.sh or remove the registry row."
      findings=$((findings + 1))
    fi
  done

  # (ii) every deployed-roster member must have a registry row (asymmetry FAILs).
  #      This is where #2540's AC-1 lives (roster a skill without a registry row).
  local _rw
  for _member in "${DEPLOYED_ROSTER[@]}"; do
    _found=false
    for _rw in "${REGISTRY_ROWS[@]}"; do
      [[ "$_member" == "$_rw" ]] && { _found=true; break; }
    done
    if [[ "$_found" == "false" ]]; then
      echo "FAIL:  registry-currency — roster member '$_member' has no registry row in $registry_md. Add a Configuration-Item row or remove the skill from deploy.sh."
      findings=$((findings + 1))
    fi
  done

  # (iii) every registry row name must resolve to a live SKILL.md.
  local _mod _skill_md
  for _row in "${REGISTRY_ROWS[@]}"; do
    _skill_md=""
    for _mod in operations release core; do
      if [[ -f "$repo_root/$_mod/skills/$_row/SKILL.md" ]]; then
        _skill_md="$repo_root/$_mod/skills/$_row/SKILL.md"
        break
      fi
    done
    if [[ -z "$_skill_md" ]]; then
      echo "FAIL:  registry-currency — registry row '$_row' resolves to no live SKILL.md under operations/|release/|core/skills/. Fix the row name or create the skill."
      findings=$((findings + 1))
    fi
  done

  if [[ $findings -gt 0 ]]; then
    echo "SUMMARY: ${#DEPLOYED_ROSTER[@]} rostered skills, ${#REGISTRY_ROWS[@]} registry rows; $findings FAIL"
    return 1
  fi
  echo "SUMMARY: ${#DEPLOYED_ROSTER[@]} rostered skills, ${#REGISTRY_ROWS[@]} registry rows; 0 FAIL (registry catalog current — rows <-> roster symmetric, canary excluded, every row resolves to a live SKILL.md)"
  return 0
}

# ─── Self-test ────────────────────────────────────────────────────────────────
# A warn-mode scan is blind to a detector regression, so the CI step hard-fails on
# a self-test miss independent of posture. Builds a throwaway mktemp fixture tree
# (stub deploy.sh roster + fixture registry.md + fixture SKILL.md tree) and asserts
# each predicate branch flips as designed. Hermetic: offline, credential-free.
self_test() {
  local tmp pass=0
  tmp="$(mktemp -d)"
  trap 'rm -rf "$tmp"' RETURN

  # A well-formed stub deploy.sh: three rostered skills (one per module) + a canary.
  _write_good_deploy() {
    cat > "$tmp/deploy.sh" <<'STUB'
OPERATIONS_SKILLS=(
  alpha-ops
)
RELEASE_SKILLS=(
  beta-rel
)
CORE_SKILLS=(
  gamma-core
)
CANARY_SKILLS=(
  delta-canary
)
STUB
  }

  # A registry.md fixture. Each row is byte-shaped like the live catalog. The
  # `names` arg is a space-separated list of row names to emit.
  _write_registry() {
    {
      echo "# Skill Registry"
      echo ""
      echo "## Configuration Items"
      echo ""
      echo "| Skill | kind | module |"
      echo "|---|---|---|"
      local _n
      for _n in $1; do
        echo "| [\`$_n\`](../$_n/SKILL.md) | function-skill | operations |"
      done
    } > "$tmp/registry.md"
  }

  # Create SKILL.md files for the given "<module>/<name>" pairs.
  _make_skill() {
    mkdir -p "$tmp/$1/skills/$2"
    printf '%s\n' "---" "name: $2" "description: fixture" "version: v1.00" "---" "# $2" > "$tmp/$1/skills/$2/SKILL.md"
  }

  # Baseline good tree: 3 rostered skills, 3 matching rows, all resolve.
  _seed_clean() {
    _write_good_deploy
    _make_skill operations alpha-ops
    _make_skill release    beta-rel
    _make_skill core       gamma-core
    _write_registry "alpha-ops beta-rel gamma-core"
  }

  local rc
  _assert_exit() {  # $1=expected-exit  $2=label
    local want="$1" label="$2"
    run_check "$tmp" "$tmp/deploy.sh" "$tmp/registry.md" >/dev/null 2>&1
    rc=$?
    if [[ $rc -eq $want ]]; then
      pass=$((pass + 1))
    else
      echo "self-test FAIL: $label — expected exit $want, got $rc" >&2
      return 1
    fi
  }

  # A1: clean fixture ⇒ exit 0.
  _seed_clean
  _assert_exit 0 "clean fixture (rows ≡ roster, all resolve)" || return 1

  # A2: roster member with NO registry row ⇒ exit 1 (assertion ii — #2540 AC-1).
  _seed_clean
  _write_registry "alpha-ops gamma-core"          # drop beta-rel's row; keep it rostered
  _assert_exit 1 "rostered skill without a registry row (AC-1, assertion ii)" || return 1

  # A3: registry row with NO roster member ⇒ exit 1 (assertion i).
  _seed_clean
  _make_skill operations zeta-extra               # give the stray row a live SKILL.md so only (i) fires
  _write_registry "alpha-ops beta-rel gamma-core zeta-extra"
  _assert_exit 1 "registry row with no roster member (assertion i)" || return 1

  # A4: registry row that resolves to NO SKILL.md ⇒ exit 1 (assertion iii).
  #     (rostered so (i)/(ii) pass; SKILL.md absent so (iii) fires.)
  _write_good_deploy
  cat > "$tmp/deploy.sh" <<'STUB'
OPERATIONS_SKILLS=(
  alpha-ops
  orphan-row
)
RELEASE_SKILLS=(
  beta-rel
)
CORE_SKILLS=(
  gamma-core
)
STUB
  _make_skill operations alpha-ops
  _make_skill release    beta-rel
  _make_skill core       gamma-core
  # deliberately do NOT create operations/skills/orphan-row/SKILL.md
  _write_registry "alpha-ops beta-rel gamma-core orphan-row"
  _assert_exit 1 "registry row resolving to no live SKILL.md (assertion iii)" || return 1

  # A5: CANARY member is EXCLUDED — a canary with no registry row must NOT fail
  #     (ADR-04). The clean tree already lists delta-canary in CANARY_SKILLS with
  #     no row and no SKILL.md; a clean exit proves the canary is not unioned.
  _seed_clean
  _assert_exit 0 "canary excluded from the roster (ADR-04) — no false FAIL" || return 1

  # A6: EMPTY roster extraction ⇒ exit 3 (scan-surface error).
  cat > "$tmp/deploy.sh" <<'STUB'
OPERATIONS_SKILLS=(
)
RELEASE_SKILLS=(
)
CORE_SKILLS=(
)
STUB
  _write_registry "alpha-ops"
  _assert_exit 3 "empty roster extraction (scan-surface error)" || return 1

  # A7: ABSENT registry.md ⇒ exit 3 (documented divergence from deploy.sh's skip).
  _write_good_deploy
  rm -f "$tmp/registry.md"
  run_check "$tmp" "$tmp/deploy.sh" "$tmp/registry.md" >/dev/null 2>&1
  rc=$?
  if [[ $rc -eq 3 ]]; then pass=$((pass + 1)); else
    echo "self-test FAIL: absent registry.md — expected exit 3, got $rc" >&2; return 1
  fi

  # A8: registry present but 0 CI rows parsed ⇒ exit 3 (audit-baseline guard).
  _write_good_deploy
  printf '%s\n' "# Skill Registry" "" "## Configuration Items" "" "_(no rows yet)_" > "$tmp/registry.md"
  _assert_exit 3 "zero registry rows parsed (audit-baseline guard)" || return 1

  # A9: SHAPE GUARD (CD-3 / FM-1) — the one-line array form yields NON-EMPTY garbage
  #     that the empty-roster guard cannot catch; the shape guard rejects it ⇒ exit 3.
  #     `OPERATIONS_SKILLS=(alpha beta)` on one line: awk skips the members' own line
  #     (`next`) then captures the following `RELEASE_SKILLS=(` token as a bogus
  #     member. The roster is therefore NON-empty (A6's guard would pass it) but
  #     shape-invalid.
  cat > "$tmp/deploy.sh" <<'STUB'
OPERATIONS_SKILLS=(alpha beta)
RELEASE_SKILLS=(
)
CORE_SKILLS=(
)
STUB
  _write_registry "alpha-ops"
  _assert_exit 3 "one-line array garbage rejected by the shape guard (CD-3/FM-1)" || return 1

  echo "self-test OK ($pass assertions passed)"
  return 0
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────
main() {
  case "${1:-}" in
    --self-test)
      self_test
      exit $?
      ;;
    "")
      run_check "$REPO_ROOT" "$REPO_ROOT/core/deploy/deploy.sh" "$REPO_ROOT/core/skills/registry.md"
      exit $?
      ;;
    *)
      echo "Usage: bash release/tools/check-registry-currency.sh [--self-test]" >&2
      exit 2
      ;;
  esac
}

main "$@"
