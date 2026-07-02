#!/usr/bin/env bash
set -euo pipefail
# test_domain_blast_radius.sh — tests for the domain-fan-out impact-analysis
# instrument (domain-blast-radius.sh) and the shared schema-v1 library it extracts.
#
# Three groups, matching the Stage-5 design + the A6.5 build conditions:
#   (F1) DEFAULT-PATH REGRESSION — blast-radius.sh output is byte-identical, under a
#        NORMALIZED diff, before vs after the shared-lib refactor. The diff strips the
#        three non-deterministic fields (scanned_at / scan_root / stats.elapsed_seconds)
#        with `jq 'del(...)'` on BOTH sides — NOT a byte-match golden (those fields make
#        a byte-match fail 100% and be non-portable). This proves D3 (sourcing the shared
#        lib) is a behavior-preserving no-op on the doc corpus.
#   (AC#3) SOFTWARE IMPORT-GRAPH — domain-blast-radius.sh --domain=software on a code
#        fixture yields a NON-EMPTY schema-v1 first_order[] (the A3.1 code/software row's
#        method has a runnable counterpart).
#   (F4) FIELD SEMANTICS — assert what the fields MEAN for the software domain, not just
#        that the keys exist: reference_count is an IMPORT-STATEMENT count (a comment-only
#        mention is NOT counted); is_mirror is the constant false; second_order is scoped
#        out ([] + count 0); total_files_scanned is the code-file denominator; the full
#        schema-v1 envelope keys are present.
#
# Offline + deterministic: all fixtures live in isolated mktemp trees scanned via
# --root, so counts never depend on the surrounding repo. No network / gh / git-remote.
#
# Run:  bash release/tools/tests/test_domain_blast_radius.sh
# Exit: 0 = all groups pass, 1 = one or more assertions failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS_DIR="$(cd "$HERE/.." && pwd -P)"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd -P)"
BLAST_RADIUS="$TOOLS_DIR/blast-radius.sh"
DOMAIN_BLAST_RADIUS="$TOOLS_DIR/domain-blast-radius.sh"

PASS=0
FAIL=0
FAILURES=()

ok()   { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }

# Strip the three non-deterministic fields for a normalized, portable comparison.
normalize() { jq -S 'del(.scanned_at, .scan_root, .stats.elapsed_seconds)'; }

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not on PATH — cannot run schema-v1 tests" >&2
    exit 0
  fi
}

# ---------------------------------------------------------------------------
# Group F1 — default-path regression under a NORMALIZED diff.
#
# Compare the CURRENT (refactored, shared-lib-sourcing) blast-radius.sh against the
# pre-refactor version recovered from git, on the SAME doc fixture. Both outputs are
# normalized (the 3 non-deterministic fields deleted) before diff. The pre-refactor
# version is whatever blast-radius.sh looked like at origin/main HEAD before this
# branch's refactor; we recover it and, crucially, run it against a self-contained
# doc fixture so the comparison does not depend on the live corpus.
# ---------------------------------------------------------------------------
test_f1_default_path_regression() {
  echo "[F1] default-path regression (normalized diff, doc corpus)"

  local fx; fx="$(cd "$(mktemp -d)" && pwd -P)"
  # trap-scoped cleanup for this fixture
  # A tiny doc corpus: a.md and b.md both reference target.md by path.
  mkdir -p "$fx/docs"
  printf '# target\ncanonical content\n' > "$fx/docs/target.md"
  printf '# a\nsee [t](docs/target.md) and docs/target.md again\n' > "$fx/docs/a.md"
  printf '# b\nreference to docs/target.md\n' > "$fx/b.md"

  # The pre-refactor blast-radius.sh: recover the version from the merge-base with
  # origin/main (the state before this branch touched it). If unavailable (detached
  # CI checkout), fall back to comparing the tool against ITSELF re-run — a weaker
  # but still-valid determinism check (same input => same normalized output).
  local pre_ref_script="$fx/blast-radius.prerefactor.sh"
  local base_rev=""
  if base_rev="$(git -C "$REPO_ROOT" merge-base HEAD origin/main 2>/dev/null)" && [ -n "$base_rev" ]; then
    if git -C "$REPO_ROOT" show "${base_rev}:release/tools/blast-radius.sh" > "$pre_ref_script" 2>/dev/null && [ -s "$pre_ref_script" ]; then
      :
    else
      pre_ref_script=""
    fi
  else
    pre_ref_script=""
  fi

  local cur_out norm_cur
  cur_out="$("$BLAST_RADIUS" --format=json --depth=2 --root="$fx" "docs/target.md" 2>/dev/null || true)"
  norm_cur="$(printf '%s' "$cur_out" | normalize 2>/dev/null || true)"

  if [ -z "$norm_cur" ]; then
    bad "F1: current blast-radius.sh produced no parseable JSON on the doc fixture"
    rm -rf "$fx"; return
  fi

  if [ -n "$pre_ref_script" ]; then
    # The pre-refactor script does NOT source the shared lib — run it directly.
    local pre_out norm_pre
    pre_out="$(bash "$pre_ref_script" --format=json --depth=2 --root="$fx" "docs/target.md" 2>/dev/null || true)"
    norm_pre="$(printf '%s' "$pre_out" | normalize 2>/dev/null || true)"
    if [ -z "$norm_pre" ]; then
      bad "F1: pre-refactor blast-radius.sh produced no parseable JSON (recovery ran but output empty)"
    elif [ "$norm_pre" = "$norm_cur" ]; then
      ok "F1: refactored output == pre-refactor output (normalized) — shared-lib refactor is a no-op"
    else
      bad "F1: NORMALIZED DIFF between pre-refactor and refactored blast-radius.sh:
$(diff <(printf '%s' "$norm_pre") <(printf '%s' "$norm_cur") | head -30)"
    fi
  else
    # Fallback: determinism check — re-run the current tool, assert identical normalized output.
    local cur_out2 norm_cur2
    cur_out2="$("$BLAST_RADIUS" --format=json --depth=2 --root="$fx" "docs/target.md" 2>/dev/null || true)"
    norm_cur2="$(printf '%s' "$cur_out2" | normalize 2>/dev/null || true)"
    if [ "$norm_cur" = "$norm_cur2" ]; then
      ok "F1 (fallback — no git base available): blast-radius.sh is deterministic under normalized diff"
    else
      bad "F1 (fallback): blast-radius.sh normalized output is non-deterministic across two runs"
    fi
  fi

  # Assert the doc fixture actually produced referrers (guards a vacuous PASS on empty output).
  local fo
  fo="$(printf '%s' "$norm_cur" | jq -r '.stats.first_order_count')"
  if [ "$fo" -ge 2 ]; then
    ok "F1: doc fixture is non-vacuous (first_order_count=$fo >= 2 referrers)"
  else
    bad "F1: doc fixture produced first_order_count=$fo (<2) — regression check would be vacuous"
  fi

  rm -rf "$fx"
}

# ---------------------------------------------------------------------------
# Group AC#3 — software import-graph produces a non-empty schema-v1 result.
# ---------------------------------------------------------------------------
build_software_fixture() {
  # Echoes the canonical fixture root (already pwd -P'd so absolute targets resolve).
  local fx; fx="$(cd "$(mktemp -d)" && pwd -P)"
  mkdir -p "$fx/pkg"
  printf 'def parse_skill_md(path):\n    return {}\n' > "$fx/pkg/utils.py"
  # run_eval.py imports utils once.
  printf 'from pkg.utils import parse_skill_md\nx = parse_skill_md("a")\n' > "$fx/run_eval.py"
  # run_loop.py imports utils twice (import + from-import) => reference_count 2.
  printf 'import pkg.utils\nfrom pkg.utils import parse_skill_md\n' > "$fx/run_loop.py"
  # unrelated.py MENTIONS pkg.utils in a comment ONLY (no import keyword) => must NOT count.
  printf '# see pkg.utils for the parser\n# pkg.utils is where parse_skill_md lives\ny = 1\n' > "$fx/unrelated.py"
  printf '%s' "$fx"
}

test_ac3_software_nonempty() {
  echo "[AC#3] software import-graph — non-empty schema-v1 result on a code fixture"
  local fx; fx="$(build_software_fixture)"

  local out
  out="$("$DOMAIN_BLAST_RADIUS" --domain=software --format=json --root="$fx" "pkg/utils.py" 2>/dev/null || true)"
  if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    bad "AC#3: --domain=software produced no parseable JSON"
    rm -rf "$fx"; return
  fi

  local fo_count
  fo_count="$(printf '%s' "$out" | jq -r '.stats.first_order_count')"
  if [ "$fo_count" -ge 1 ]; then
    ok "AC#3: software fan-out non-empty (first_order_count=$fo_count)"
  else
    bad "AC#3: software fan-out empty (first_order_count=$fo_count) — expected >= 1 importer"
  fi

  # Exactly the two real importers (run_eval, run_loop) — unrelated.py excluded.
  if [ "$fo_count" -eq 2 ]; then
    ok "AC#3: exactly 2 importers detected (comment-only mention correctly excluded)"
  else
    bad "AC#3: expected 2 importers, got $fo_count (import-vs-mention discrimination broken?)"
  fi

  rm -rf "$fx"
}

# ---------------------------------------------------------------------------
# Group F4 — field SEMANTICS (not just key presence) for the software domain.
# ---------------------------------------------------------------------------
test_f4_field_semantics() {
  echo "[F4] software-domain field semantics"
  local fx; fx="$(build_software_fixture)"
  local out
  out="$("$DOMAIN_BLAST_RADIUS" --domain=software --format=json --root="$fx" "pkg/utils.py" 2>/dev/null || true)"
  if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    bad "F4: no parseable JSON to assert semantics on"
    rm -rf "$fx"; return
  fi

  # (1) Full schema-v1 envelope keys present.
  local missing
  missing="$(printf '%s' "$out" | jq -r '
    [ "schema_version","cli_version","target","scanned_at","scan_root","depth",
      "include_mirrors","stats","first_order","second_order","filtered_mirrors_detail" ]
    - (. | keys) | join(",")')"
  if [ -z "$missing" ]; then ok "F4: full schema-v1 top-level envelope present"; else bad "F4: missing envelope keys: $missing"; fi

  local stats_missing
  stats_missing="$(printf '%s' "$out" | jq -r '
    [ "total_files_scanned","first_order_count","second_order_count","filtered_mirrors","elapsed_seconds" ]
    - (.stats | keys) | join(",")')"
  if [ -z "$stats_missing" ]; then ok "F4: full stats{} keys present"; else bad "F4: missing stats keys: $stats_missing"; fi

  # (2) schema_version is the string "1".
  if [ "$(printf '%s' "$out" | jq -r '.schema_version')" = "1" ]; then ok "F4: schema_version == \"1\""; else bad "F4: schema_version != \"1\""; fi

  # (3) reference_count SEMANTICS: run_loop.py has TWO import statements => reference_count 2.
  local rc_runloop
  rc_runloop="$(printf '%s' "$out" | jq -r '.first_order[] | select(.path=="run_loop.py") | .reference_count')"
  if [ "$rc_runloop" = "2" ]; then
    ok "F4: reference_count is an IMPORT-STATEMENT count (run_loop.py: 2 statements => 2)"
  else
    bad "F4: run_loop.py reference_count=$rc_runloop, expected 2 (import-statement unit)"
  fi

  # (3b) run_eval.py: single import statement => reference_count 1.
  local rc_runeval
  rc_runeval="$(printf '%s' "$out" | jq -r '.first_order[] | select(.path=="run_eval.py") | .reference_count')"
  if [ "$rc_runeval" = "1" ]; then ok "F4: run_eval.py reference_count == 1 (single import)"; else bad "F4: run_eval.py reference_count=$rc_runeval, expected 1"; fi

  # (3c) unrelated.py (comment-only mention) is ABSENT from first_order[].
  local has_unrelated
  has_unrelated="$(printf '%s' "$out" | jq -r '[.first_order[].path] | index("unrelated.py") // "absent"')"
  if [ "$has_unrelated" = "absent" ]; then
    ok "F4: comment-only mention (unrelated.py) NOT counted as an import edge"
  else
    bad "F4: unrelated.py appeared in first_order[] — a doc mention was mis-counted as an import"
  fi

  # (4) is_mirror is the constant false for EVERY software first-order entry.
  local any_true
  any_true="$(printf '%s' "$out" | jq -r '[.first_order[].is_mirror] | any(. == true)')"
  if [ "$any_true" = "false" ]; then
    ok "F4: is_mirror is constant false for the software domain (no mirror concept)"
  else
    bad "F4: an is_mirror==true appeared for the software domain (should always be false)"
  fi

  # (5) second_order scoped OUT: empty array AND count 0.
  local so_len so_count
  so_len="$(printf '%s' "$out" | jq -r '.second_order | length')"
  so_count="$(printf '%s' "$out" | jq -r '.stats.second_order_count')"
  if [ "$so_len" = "0" ] && [ "$so_count" = "0" ]; then
    ok "F4: second_order scoped out (empty array + second_order_count 0)"
  else
    bad "F4: second_order not scoped out (length=$so_len, count=$so_count) — envelope over-claim"
  fi

  # (6) total_files_scanned is the CODE-file denominator: the 4 fixture .py files.
  local tfs
  tfs="$(printf '%s' "$out" | jq -r '.stats.total_files_scanned')"
  if [ "$tfs" = "4" ]; then
    ok "F4: total_files_scanned == code-file count (4 fixture .py files)"
  else
    bad "F4: total_files_scanned=$tfs, expected 4 (code-file denominator semantics)"
  fi

  # (7) filtered_mirrors == 0 for the software domain.
  if [ "$(printf '%s' "$out" | jq -r '.stats.filtered_mirrors')" = "0" ]; then
    ok "F4: filtered_mirrors == 0 for the software domain"
  else
    bad "F4: filtered_mirrors != 0 for the software domain"
  fi

  # (8) matches[] snippet carries the actual import statement text.
  local snip
  snip="$(printf '%s' "$out" | jq -r '.first_order[] | select(.path=="run_eval.py") | .matches[0].snippet')"
  case "$snip" in
    *"from pkg.utils import"*) ok "F4: matches[].snippet carries the import statement text" ;;
    *) bad "F4: run_eval.py first match snippet unexpected: '$snip'" ;;
  esac

  rm -rf "$fx"
}

# ---------------------------------------------------------------------------
# Group: dispatch / exit-code contract (plug-model visibility).
# ---------------------------------------------------------------------------
test_dispatch_contract() {
  echo "[dispatch] plug-model exit-code contract"
  local rc
  # web stub => exit 5
  "$DOMAIN_BLAST_RADIUS" --domain=web "$BLAST_RADIUS" >/dev/null 2>&1 && rc=0 || rc=$?
  if [ "$rc" = "5" ]; then ok "dispatch: --domain=web -> exit 5 (scanner not implemented)"; else bad "dispatch: --domain=web exit=$rc, expected 5"; fi
  # enterprise-platform stub => exit 5
  "$DOMAIN_BLAST_RADIUS" --domain=enterprise-platform "$BLAST_RADIUS" >/dev/null 2>&1 && rc=0 || rc=$?
  if [ "$rc" = "5" ]; then ok "dispatch: --domain=enterprise-platform -> exit 5"; else bad "dispatch: enterprise-platform exit=$rc, expected 5"; fi
  # invalid domain => exit 1
  "$DOMAIN_BLAST_RADIUS" --domain=bogus "$BLAST_RADIUS" >/dev/null 2>&1 && rc=0 || rc=$?
  if [ "$rc" = "1" ]; then ok "dispatch: --domain=bogus -> exit 1 (invalid domain)"; else bad "dispatch: bogus exit=$rc, expected 1"; fi
  # missing --domain => exit 1
  "$DOMAIN_BLAST_RADIUS" "$BLAST_RADIUS" >/dev/null 2>&1 && rc=0 || rc=$?
  if [ "$rc" = "1" ]; then ok "dispatch: missing --domain -> exit 1"; else bad "dispatch: missing --domain exit=$rc, expected 1"; fi
}

main() {
  require_jq
  echo "=== test_domain_blast_radius.sh ==="
  echo "repo root: $REPO_ROOT"
  echo

  test_f1_default_path_regression; echo
  test_ac3_software_nonempty; echo
  test_f4_field_semantics; echo
  test_dispatch_contract; echo

  echo "=== summary: $PASS passed, $FAIL failed ==="
  if [ "$FAIL" -gt 0 ]; then
    printf 'FAILURES:\n'
    local f
    for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
    exit 1
  fi
  exit 0
}

main "$@"
