#!/usr/bin/env bash
set -euo pipefail
# test_structural_blast_radius.sh — tests for the structural/path-move mode of
# blast-radius.sh (--mode=structural), the consumer class the default doc-reference
# tracer and the software import-graph tracer are both blind to (#3120).
#
# Five groups:
#   (S1) FIXTURE REPRODUCTION — the committed fixture asset under
#        fixtures/structural-move/ reproduces the #230 -> RCA #3118 notes-folder-move
#        miss: for OLD path 'release/releases/notes', the structural mode's consumer
#        list MUST include automated-closeout.sh (RELEASE_NOTES_DIR), deploy.sh
#        (Check 47), and check-release-body-drift.sh (NOTES_DIR/NOTES_REL), and MUST
#        NOT include the negative-control unrelated.sh.
#   (S2) FIELD SEMANTICS — assert what the fields MEAN for structural output:
#        reference_count is a hard-coded-reference hit count; is_mirror is the constant
#        false; second_order is scoped out ([] + count 0); the full schema-v1 envelope
#        keys are present.
#   (S3) REAL-REPO #3118 REPRODUCTION — run against the live repo (subset containment,
#        robust to unrelated extra consumers): the three REAL consumers at their real
#        paths are flagged, proving the mode catches the actual historical miss.
#   (S4) MODE CONTRACT — invalid --mode exits 1; a non-existent OLD path still succeeds
#        (exit 0 — the point of the sweep is a moved-away path); the default doc tracer
#        path is unchanged (non-regression: still emits a schema-v1 envelope).
#   (S5) CIAC-4 — every sort in blast-radius.sh executes under the script-level
#        LC_ALL=C export (no locale-exposed sort remains after #3120's mode was added).
#
# Offline + deterministic: S1/S2/S4 scan isolated trees via --root; S3 is a live-repo
# subset assertion (containment only). No network / gh / git-remote.
#
# Run:  bash release/tools/tests/test_structural_blast_radius.sh
# Exit: 0 = all groups pass, 1 = one or more assertions failed.

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS_DIR="$(cd "$HERE/.." && pwd -P)"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd -P)"
BLAST_RADIUS="$TOOLS_DIR/blast-radius.sh"
FIXTURE_DIR="$HERE/fixtures/structural-move"

OLD_PATH="release/releases/notes"

PASS=0
FAIL=0
FAILURES=()
ok()  { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    echo "SKIP: jq not on PATH — cannot run schema-v1 tests" >&2
    exit 0
  fi
}

# ---------------------------------------------------------------------------
# Group S1 — committed fixture reproduces the #230 -> #3118 miss (isolated tree).
# ---------------------------------------------------------------------------
test_s1_fixture_reproduction() {
  echo "[S1] fixture reproduction — the three #3118 consumers are flagged"
  if [ ! -d "$FIXTURE_DIR" ]; then
    bad "S1: fixture dir missing: $FIXTURE_DIR"
    return
  fi
  local out
  out="$("$BLAST_RADIUS" --mode=structural --format=json --root="$FIXTURE_DIR" "$OLD_PATH" 2>/dev/null || true)"
  if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    bad "S1: --mode=structural produced no parseable JSON on the fixture"
    return
  fi

  local need="automated-closeout.sh deploy.sh check-release-body-drift.sh"
  local n missing=""
  for n in $need; do
    if ! printf '%s' "$out" | jq -e --arg p "$n" '[.first_order[].path] | index($p)' >/dev/null 2>&1; then
      missing="$missing $n"
    fi
  done
  if [ -z "$missing" ]; then
    ok "S1: all three #3118 consumers flagged (automated-closeout.sh / deploy.sh / check-release-body-drift.sh)"
  else
    bad "S1: missing consumer(s):$missing"
  fi

  # Negative control: unrelated.sh must NOT be flagged.
  if printf '%s' "$out" | jq -e '[.first_order[].path] | index("unrelated.sh")' >/dev/null 2>&1; then
    bad "S1: unrelated.sh wrongly flagged (false positive on the negative control)"
  else
    ok "S1: unrelated.sh correctly NOT flagged (no false positive)"
  fi
}

# ---------------------------------------------------------------------------
# Group S2 — structural-mode field semantics (not just key presence).
# ---------------------------------------------------------------------------
test_s2_field_semantics() {
  echo "[S2] structural-mode field semantics"
  local out
  out="$("$BLAST_RADIUS" --mode=structural --format=json --root="$FIXTURE_DIR" "$OLD_PATH" 2>/dev/null || true)"
  if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    bad "S2: no parseable JSON to assert semantics on"
    return
  fi

  # (1) Full schema-v1 envelope keys present.
  local missing
  missing="$(printf '%s' "$out" | jq -r '
    [ "schema_version","cli_version","target","scanned_at","scan_root","depth",
      "include_mirrors","stats","first_order","second_order","filtered_mirrors_detail" ]
    - (. | keys) | join(",")')"
  if [ -z "$missing" ]; then ok "S2: full schema-v1 top-level envelope present"; else bad "S2: missing envelope keys: $missing"; fi

  # (2) schema_version == "1".
  if [ "$(printf '%s' "$out" | jq -r '.schema_version')" = "1" ]; then ok "S2: schema_version == \"1\""; else bad "S2: schema_version != \"1\""; fi

  # (3) reference_count SEMANTICS: check-release-body-drift.sh has TWO hard-coded refs => 2.
  local rc
  rc="$(printf '%s' "$out" | jq -r '.first_order[] | select(.path=="check-release-body-drift.sh") | .reference_count')"
  if [ "$rc" = "2" ]; then
    ok "S2: reference_count is a hard-coded-reference hit count (check-release-body-drift.sh: 2)"
  else
    bad "S2: check-release-body-drift.sh reference_count=$rc, expected 2 (NOTES_DIR + NOTES_REL)"
  fi

  # (3b) automated-closeout.sh: single reference => 1.
  local rc1
  rc1="$(printf '%s' "$out" | jq -r '.first_order[] | select(.path=="automated-closeout.sh") | .reference_count')"
  if [ "$rc1" = "1" ]; then ok "S2: automated-closeout.sh reference_count == 1 (single reference)"; else bad "S2: automated-closeout.sh reference_count=$rc1, expected 1"; fi

  # (4) is_mirror is the constant false for every structural entry.
  local any_true
  any_true="$(printf '%s' "$out" | jq -r '[.first_order[].is_mirror] | any(. == true)')"
  if [ "$any_true" = "false" ]; then ok "S2: is_mirror is constant false (no mirror concept for a path sweep)"; else bad "S2: an is_mirror==true appeared (should always be false)"; fi

  # (5) second_order scoped OUT: empty array AND count 0.
  local so_len so_count
  so_len="$(printf '%s' "$out" | jq -r '.second_order | length')"
  so_count="$(printf '%s' "$out" | jq -r '.stats.second_order_count')"
  if [ "$so_len" = "0" ] && [ "$so_count" = "0" ]; then ok "S2: second_order scoped out ([] + count 0)"; else bad "S2: second_order not scoped out (length=$so_len, count=$so_count)"; fi

  # (6) matches[] snippet carries the actual hard-coded reference text.
  local snip
  snip="$(printf '%s' "$out" | jq -r '.first_order[] | select(.path=="automated-closeout.sh") | .matches[0].snippet')"
  case "$snip" in
    *"release/releases/notes"*) ok "S2: matches[].snippet carries the hard-coded reference text" ;;
    *) bad "S2: automated-closeout.sh first match snippet unexpected: '$snip'" ;;
  esac
}

# ---------------------------------------------------------------------------
# Group S3 — real-repo #3118 reproduction (subset containment).
# ---------------------------------------------------------------------------
test_s3_real_repo_reproduction() {
  echo "[S3] real-repo reproduction — the actual three #3118 consumers are flagged"
  local out
  out="$("$BLAST_RADIUS" --mode=structural --format=json --root="$REPO_ROOT" "$OLD_PATH" 2>/dev/null || true)"
  if [ -z "$out" ] || ! printf '%s' "$out" | jq -e . >/dev/null 2>&1; then
    bad "S3: --mode=structural produced no parseable JSON against the real repo"
    return
  fi

  # Subset containment (⊇) — robust to unrelated extra consumers.
  local need="release/tools/automated-closeout.sh core/deploy/deploy.sh release/tools/check-release-body-drift.sh"
  local n missing=""
  for n in $need; do
    if ! printf '%s' "$out" | jq -e --arg p "$n" '[.first_order[].path] | index($p)' >/dev/null 2>&1; then
      missing="$missing $n"
    fi
  done
  if [ -z "$missing" ]; then
    ok "S3: real repo flags all three actual #3118 consumers (the miss is now caught at review time)"
  else
    bad "S3: real repo did NOT flag:$missing (consumer moved/renamed, or scan regressed)"
  fi
}

# ---------------------------------------------------------------------------
# Group S4 — mode contract + default-path non-regression.
# ---------------------------------------------------------------------------
test_s4_mode_contract() {
  echo "[S4] mode contract + default-path non-regression"
  local rc

  # invalid --mode => exit 1
  "$BLAST_RADIUS" --mode=bogus "$BLAST_RADIUS" >/dev/null 2>&1 && rc=0 || rc=$?
  if [ "$rc" = "1" ]; then ok "S4: --mode=bogus -> exit 1 (invalid mode rejected)"; else bad "S4: --mode=bogus exit=$rc, expected 1"; fi

  # non-existent OLD path still succeeds (exit 0) — the whole point of the sweep.
  local fx; fx="$(cd "$(mktemp -d)" && pwd -P)"
  printf 'hardcodes legacy/moved/dir here\n' > "$fx/consumer.sh"
  "$BLAST_RADIUS" --mode=structural --format=json --root="$fx" "legacy/moved/dir" >/dev/null 2>&1 && rc=0 || rc=$?
  if [ "$rc" = "0" ]; then ok "S4: non-existent (moved-away) OLD path -> exit 0 (no bad-target rejection)"; else bad "S4: moved-away path exit=$rc, expected 0"; fi

  # default doc tracer path unchanged: still emits a schema-v1 envelope on a doc target.
  mkdir -p "$fx/docs"
  printf '# t\n' > "$fx/docs/target.md"
  printf 'see docs/target.md\nand docs/target.md again\n' > "$fx/ref.md"
  local dout dfo
  dout="$("$BLAST_RADIUS" --format=json --depth=1 --root="$fx" "docs/target.md" 2>/dev/null || true)"
  if printf '%s' "$dout" | jq -e '.schema_version=="1" and (.first_order|type=="array")' >/dev/null 2>&1; then
    dfo="$(printf '%s' "$dout" | jq -r '.stats.first_order_count')"
    if [ "$dfo" -ge 1 ]; then
      ok "S4: default doc tracer path unchanged (schema-v1 envelope, first_order_count=$dfo)"
    else
      bad "S4: default doc tracer produced first_order_count=$dfo (<1) — regression?"
    fi
  else
    bad "S4: default doc tracer did not emit a valid schema-v1 envelope — regression"
  fi
  rm -rf "$fx"
}

# ---------------------------------------------------------------------------
# Group S5 — CIAC-4: every sort under the script-level LC_ALL=C export (#675),
# including any the #3120 mode added; no bare sort precedes the export.
# ---------------------------------------------------------------------------
test_s5_lc_all_coverage() {
  echo "[S5] CIAC-4 — every sort under the script-level LC_ALL=C export"
  local export_line first_sort_line
  export_line="$(grep -n '^export LC_ALL=C' "$BLAST_RADIUS" | head -1 | cut -d: -f1)"
  first_sort_line="$(grep -nE '[^_-]sort ' "$BLAST_RADIUS" | grep -v '# ' | head -1 | cut -d: -f1 || true)"
  if [ -z "$export_line" ]; then
    bad "S5: no 'export LC_ALL=C' found in blast-radius.sh"
    return
  fi
  ok "S5: 'export LC_ALL=C' present (line $export_line)"
  if [ -n "$first_sort_line" ] && [ "$first_sort_line" -gt "$export_line" ]; then
    ok "S5: first sort invocation (line $first_sort_line) is after the export (line $export_line)"
  elif [ -z "$first_sort_line" ]; then
    ok "S5: no bare sort invocation detected before the export"
  else
    bad "S5: a sort at line $first_sort_line precedes the export at line $export_line"
  fi
}

main() {
  require_jq
  echo "=== test_structural_blast_radius.sh ==="
  echo "repo root: $REPO_ROOT"
  echo

  test_s1_fixture_reproduction; echo
  test_s2_field_semantics; echo
  test_s3_real_repo_reproduction; echo
  test_s4_mode_contract; echo
  test_s5_lc_all_coverage; echo

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
