#!/usr/bin/env bash
set -euo pipefail
# test_domain_blast_radius.sh — tests for the domain-fan-out impact-analysis
# instrument (domain-blast-radius.sh) and the shared schema-v1 library it extracts.
#
# Three groups, matching the Stage-5 design + the A6.5 build conditions:
#   (F1) DEFAULT-PATH REGRESSION — blast-radius.sh output on a FROZEN 3-file doc corpus
#        matches a COMMITTED normalized golden. The golden is the pre-shared-lib-refactor
#        tool's output on that corpus, so a match proves the refactor remains a
#        behavior-preserving no-op. normalize() strips four fields that are not the
#        subject of the assertion — three non-deterministic (scanned_at / scan_root /
#        stats.elapsed_seconds) plus cli_version, a tool-identity label whose bump is not
#        a behaviour change. Fixture + spec constants + regeneration protocol live in
#        release/tools/tests/fixtures/blast-radius-f1/README.md.
#
#        F1 previously reconstructed the pre-refactor script from git history at run
#        time. That path is deleted. It could not run in a shallow checkout; its
#        classifier (`git show <sha>:… | grep -q` under `set -o pipefail`) misread a
#        SIGPIPE from the early-exiting `grep -q` as "token absent" and classified a
#        POST-refactor blob as pre-refactor; and the misclassified blob then died with
#        empty output — which the old code reported as a PASS. This suite now makes ZERO
#        git HISTORY reads (no `git log`, no `git show`). Stated precisely because it is
#        checkable: a GIT_TRACE run still shows `git rev-parse --show-toplevel` calls,
#        but those come from domain-blast-radius.sh resolving its own scan root in the
#        dispatch group, which passes no --root. They are not history reads and resolve
#        fine in a shallow clone.
#   (AC#3) SOFTWARE IMPORT-GRAPH — domain-blast-radius.sh --domain=software on a code
#        fixture yields a NON-EMPTY schema-v1 first_order[] (the A3.1 code/software row's
#        method has a runnable counterpart).
#   (F4) FIELD SEMANTICS — assert what the fields MEAN for the software domain, not just
#        that the keys exist: reference_count is an IMPORT-STATEMENT count (a comment-only
#        mention is NOT counted); is_mirror is the constant false; second_order is scoped
#        out ([] + count 0); total_files_scanned is the code-file denominator; the full
#        schema-v1 envelope keys are present.
#
# Offline + deterministic: every scan runs against an isolated mktemp tree via --root, so
# counts never depend on the surrounding repo. The AC#3 / F4 fixtures are built in mktemp;
# F1's is a COMMITTED fixture copied to mktemp and scanned there, so the checkout is never
# mutated and nothing is ever written into a scanned root at run time.
# No network / gh / git-remote / git-history read.
#
# Run:  bash release/tools/tests/test_domain_blast_radius.sh
#       BLAST_RADIUS_TESTS_STRICT=1 …    — CI mode: a SKIP is RED
#       … --regenerate-golden            — move the F1 golden (requires a written reason)
# Exit: 0 = all groups pass, 1 = an assertion failed (or, under STRICT, was skipped).

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
TOOLS_DIR="$(cd "$HERE/.." && pwd -P)"
REPO_ROOT="$(cd "$TOOLS_DIR/../.." && pwd -P)"
BLAST_RADIUS="$TOOLS_DIR/blast-radius.sh"
DOMAIN_BLAST_RADIUS="$TOOLS_DIR/domain-blast-radius.sh"
FIXTURES="$HERE/fixtures"
F1_FIXTURE="$FIXTURES/blast-radius-f1"
F1_GOLDEN="$F1_FIXTURE/normalized-golden.json"

PASS=0
FAIL=0
SKIP=0
FAILURES=()
SKIPS=()

# STRICT: in CI a SKIP is a DEFECT, not an environment condition. Every skip predicate in
# this suite is unreachable in a well-formed checkout — the golden fixture is a committed
# file and jq is on the runner image — so a skip here means the harness or the fixture is
# broken. Set on the CI step only; locally a skip stays advisory so a developer without jq
# is not blocked. The strict/non-strict split is what lets the same predicate be advisory
# to a human and fatal to a machine reading the exit code. See report_and_exit().
STRICT="${BLAST_RADIUS_TESTS_STRICT:-0}"

ok()   { PASS=$((PASS+1)); printf '  ok   — %s\n' "$1"; }
bad()  { FAIL=$((FAIL+1)); FAILURES+=("$1"); printf '  FAIL — %s\n' "$1"; }
# A SKIP means the assertion's SUBJECT COULD NOT BE EVALUATED. It is never a PASS.
# It always carries a reason, and it always annotates in CI.
skip() {
  SKIP=$((SKIP+1)); SKIPS+=("$1")
  printf '  SKIP — %s\n' "$1"
  printf '::warning title=blast-radius suite skipped an assertion::%s\n' "$1"
}

# Strip the fields that are NOT the subject of this assertion:
#   scanned_at / scan_root / stats.elapsed_seconds — non-deterministic
#   cli_version                                    — a tool-identity label, not behaviour.
#     A CLI_VERSION bump is not a doc-fan-out change; freezing it inside the compared
#     surface would red F1 on a no-op and make golden regeneration routine, which is the
#     very reflex the regeneration protocol exists to prevent. Its PRESENCE in the
#     envelope is still asserted — that guarantee moved to the S6 raw-skeleton guard.
normalize() { jq -S 'del(.scanned_at, .scan_root, .stats.elapsed_seconds, .cli_version)'; }

# Keep in sync with normalize() above. S6 asserts live-minus-golden equals EXACTLY this
# set, so widening normalize() without widening this list fails the guard by design.
F1_DELSET='["cli_version","scan_root","scanned_at","stats.elapsed_seconds"]'

require_jq() {
  if ! command -v jq >/dev/null 2>&1; then
    skip "jq not on PATH — EVERY schema-v1 assertion in this suite is UNEVALUATED"
    report_and_exit
  fi
}

# Shared tail, extracted from main() so require_jq's early exit honors STRICT too.
# A suite that skipped an assertion must not hand a clean exit 0 to a caller that only
# reads the exit code — that is the defect this suite was rewritten to remove.
report_and_exit() {
  echo "=== summary: $PASS passed, $FAIL failed, $SKIP skipped ==="
  if [ "$SKIP" -gt 0 ]; then
    printf 'SKIPPED (assertion subject not evaluated):\n'
    local s; for s in "${SKIPS[@]}"; do printf '  - %s\n' "$s"; done
  fi
  if [ "$FAIL" -gt 0 ]; then
    printf 'FAILURES:\n'
    local f; for f in "${FAILURES[@]}"; do printf '  - %s\n' "$f"; done
    exit 1
  fi
  if [ "$STRICT" = "1" ] && [ "$SKIP" -gt 0 ]; then
    echo "::error title=blast-radius suite reported PASS without running an assertion::STRICT mode: ${SKIP} assertion(s) SKIPPED. Every skip predicate in this suite is unreachable in a well-formed checkout (the golden fixture is a committed file and jq is on the runner image), so a SKIP here is a defect in the harness or the fixture, not an environment condition."
    exit 1
  fi
  exit 0
}

# ---------------------------------------------------------------------------
# Group F1 — default-path regression against a COMMITTED normalized golden.
#
# The golden is the pre-shared-lib-refactor tool's normalized output on a frozen 3-file
# doc corpus, checked in under fixtures/blast-radius-f1/. Comparing current output to it
# is the same assertion the old git-history recovery made — `normalize(pre) ==
# normalize(cur)` — with a deterministic left-hand side instead of one reconstructed at
# run time. F1 itself now invokes git zero times; see the file header for the precise
# GIT_TRACE accounting of the whole suite.
#
# Guard order is load-bearing: S1 (is the golden itself readable) -> S2' (is the scan
# INPUT the frozen tree) -> S6 (is the RAW envelope's shape intact) -> the value diff.
# S2' runs BEFORE the tool so corpus drift can never be misread as a tool regression.
# ---------------------------------------------------------------------------
test_f1_default_path_regression() {
  echo "[F1] default-path regression (normalized diff vs committed golden)"

  # ---- SKIP gate. The golden is a committed file, so in a well-formed checkout this
  # predicate is unreachable; under STRICT a skip here is RED. It is never a PASS.
  if [ ! -s "$F1_GOLDEN" ]; then
    skip "F1 strong arm did not run — golden fixture missing or empty at ${F1_GOLDEN#"$REPO_ROOT"/}"
    return
  fi

  # ---- S1 — ATTRIBUTION, not a detector. A corrupt golden already reds via the diff;
  # this guard adds ZERO unique detection and is kept only because it converts an
  # unreadable 40-line JSON diff into one sentence naming the fixture. Labelled honestly
  # so nobody counts it as coverage.
  if ! jq -e . "$F1_GOLDEN" >/dev/null 2>&1; then
    bad "F1 (S1 attribution): the committed golden is not parseable JSON — regenerate per fixtures/blast-radius-f1/README.md"
    return
  fi
  local g_schema g_fo
  g_schema="$(jq -r '.schema_version' "$F1_GOLDEN")"
  g_fo="$(jq -r '.stats.first_order_count' "$F1_GOLDEN")"
  if [ "$g_schema" != "1" ] || [ "$g_fo" -lt 2 ]; then
    bad "F1 (S1 attribution): the committed golden is vacuous or mislabeled (schema_version=$g_schema, first_order_count=$g_fo) — regenerate per fixtures/blast-radius-f1/README.md"
    return
  fi
  ok "F1 (S1): committed golden is readable, schema-v1, non-vacuous (first_order_count=$g_fo)"

  # Copy the frozen corpus to a working dir and scan the COPY, so the checkout is never
  # mutated and nothing is ever written into a scanned root at run time.
  local fxwork; fxwork="$(cd "$(mktemp -d)" && pwd -P)"
  cp -R "$F1_FIXTURE/corpus" "$fxwork/corpus"

  # ---- S2' — the SCAN INPUT is exactly the frozen fixture. Runs on the input, before
  # the tool, so it is independent of the compared surface and cannot be read as a tool
  # regression. It catches stray files the tracer never scans (.DS_Store, *.bak) — which
  # stats.total_files_scanned is BLIND to, because that count is filtered through
  # SCANNED_TYPES before it is emitted. That blindness is why the old
  # `total_files_scanned == 3` predicate was replaced rather than kept.
  local want_manifest='b.md
docs/a.md
docs/target.md'
  local got_manifest
  got_manifest="$(cd "$fxwork/corpus" && find . -type f | sed 's|^\./||' | LC_ALL=C sort)"
  if [ "$got_manifest" != "$want_manifest" ]; then
    bad "F1 (S2'): fixture corpus drifted — the scan input is not the frozen 3-file tree.
$(diff <(printf '%s\n' "$want_manifest") <(printf '%s\n' "$got_manifest"))"
    rm -rf "$fxwork"; return
  fi
  ok "F1 (S2'): scan input is exactly the frozen 3-file corpus"

  # ---- Run the tool under test. Capture stderr rather than discarding it: the old code
  # ran this arm under 2>/dev/null, which is why neither silent CI run could be diagnosed
  # after the fact.
  local cur_err="$fxwork/cur.err" cur_out norm_cur
  cur_out="$("$BLAST_RADIUS" --format=json --depth=2 --root="$fxwork/corpus" "docs/target.md" 2>"$cur_err" || true)"
  if [ -z "$cur_out" ] || ! printf '%s' "$cur_out" | jq -e . >/dev/null 2>&1; then
    bad "F1: current blast-radius.sh produced no parseable JSON on the frozen corpus — stderr: $(tr '\n' ' ' < "$cur_err" | head -c 200)"
    rm -rf "$fxwork"; return
  fi

  # ---- S6 — RAW envelope skeleton. live_paths - golden_paths must be EXACTLY the
  # normalize() deletion set, and golden_paths - live_paths must be empty.
  #
  # This is the guard that recovers what normalizing cli_version away gave up, and it
  # closes a hole the value diff cannot see: `jq del()` on a MISSING key is a silent
  # no-op, so a field vanishing from the envelope is invisible to both the value diff
  # and to any key-set guard on the NORMALIZED surface — the normalized-away fields are
  # precisely the ones both surfaces are blind to. Only a raw-surface guard sees it.
  # Self-maintaining: widening normalize() without widening F1_DELSET fails here.
  local SKEL='[paths | map(if type=="number" then "[]" else tostring end) | join(".")] | unique'
  local g_skel extra missing
  g_skel="$(jq -c "$SKEL" "$F1_GOLDEN")"
  extra="$(printf '%s' "$cur_out"   | jq -c --argjson g "$g_skel" "$SKEL as \$l | \$l - \$g")"
  missing="$(printf '%s' "$cur_out" | jq -c --argjson g "$g_skel" "$SKEL as \$l | \$g - \$l")"
  if [ "$extra" != "$F1_DELSET" ] || [ "$missing" != "[]" ]; then
    bad "F1 (S6): schema-v1 envelope skeleton drift.
  live-only keys  : $extra   (must equal the normalize() deletion set $F1_DELSET)
  golden-only keys: $missing (must be [])
  A SHORT live-only list means a field VANISHED from the envelope — a schema-v1 contract
  break the value diff structurally cannot see. A LONGER one means a field was added.
  See ADR-068 and fixtures/blast-radius-f1/README.md."
  else
    ok "F1 (S6): raw schema-v1 envelope skeleton intact (live-minus-golden == normalize() deletion set)"
  fi

  # ---- The assertion itself.
  norm_cur="$(printf '%s' "$cur_out" | normalize)"
  if [ "$norm_cur" = "$(cat "$F1_GOLDEN")" ]; then
    ok "F1: current output == committed pre-refactor golden (normalized) — shared-lib refactor remains a no-op"
  else
    bad "F1: NORMALIZED DIFF vs golden.
  If .stats.total_files_scanned moved and the S2' manifest passed, the cause is a
  SCANNED_TYPES change in blast-radius.sh — a TOOL change, not fixture drift.
  If this is a DELIBERATE output change, regenerate per fixtures/blast-radius-f1/README.md;
  do not edit the golden by hand.
$(diff "$F1_GOLDEN" <(printf '%s\n' "$norm_cur") | head -30)"
  fi

  # Non-vacuity of the LIVE output (the golden's own non-vacuity is S1's job).
  local fo
  fo="$(printf '%s' "$norm_cur" | jq -r '.stats.first_order_count')"
  if [ "$fo" -ge 2 ]; then
    ok "F1: doc fixture is non-vacuous (first_order_count=$fo >= 2 referrers)"
  else
    bad "F1: doc fixture produced first_order_count=$fo (<2) — regression check would be vacuous"
  fi

  rm -rf "$fxwork"
}

# ---------------------------------------------------------------------------
# --regenerate-golden — the ONLY sanctioned way to move the committed golden.
#
# Never automatic, never silent. It exists for exactly one case: a DELIBERATE change to
# blast-radius.sh's doc-corpus output where the new output is correct and the golden is
# the stale side. Building the fixture for the first time is NOT that case, and neither
# is "the digest did not match, so the constant must be a typo" — that is the re-bless
# this door exists to keep out of the diff-by-accident path.
# ---------------------------------------------------------------------------
regenerate_golden() {
  require_jq
  local reason="${BLAST_RADIUS_GOLDEN_REGEN_REASON:-}"
  if [ -z "$reason" ]; then
    echo "REFUSING: --regenerate-golden requires BLAST_RADIUS_GOLDEN_REGEN_REASON." >&2
    echo "  A golden may only move for a stated, reviewable reason. Example:" >&2
    echo '    BLAST_RADIUS_GOLDEN_REGEN_REASON="#NNNN — <what changed and why the new output is correct>" \' >&2
    echo "      bash release/tools/tests/test_domain_blast_radius.sh --regenerate-golden" >&2
    exit 2
  fi
  local work; work="$(cd "$(mktemp -d)" && pwd -P)"
  cp -R "$F1_FIXTURE/corpus" "$work/corpus"
  "$BLAST_RADIUS" --format=json --depth=2 --root="$work/corpus" "docs/target.md" \
    | normalize > "$work/normalized-golden.json"
  if [ ! -s "$work/normalized-golden.json" ]; then
    echo "REFUSING: regeneration produced empty output — refusing to write an empty golden." >&2
    rm -rf "$work"; exit 1
  fi
  mv "$work/normalized-golden.json" "$F1_GOLDEN"
  local bytes sha
  bytes="$(wc -c < "$F1_GOLDEN" | tr -d ' ')"
  sha="$(shasum -a 256 "$F1_GOLDEN" | cut -d' ' -f1)"
  printf '| %s | %s | %s | %s | `%s` |\n' \
    "$(date -u +%Y-%m-%d)" "$reason" "$(git -C "$REPO_ROOT" rev-parse --short HEAD 2>/dev/null || echo 'unknown')" \
    "$bytes" "${sha:0:16}" >> "$F1_FIXTURE/README.md"
  echo "Regenerated $F1_GOLDEN"
  echo "  bytes : $bytes"
  echo "  sha256: $sha"
  echo "  Regeneration Log row appended to fixtures/blast-radius-f1/README.md."
  echo "  BOTH the golden diff and the log row must appear in the PR diff."
  rm -rf "$work"
  exit 0
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
  case "${1:-}" in
    --regenerate-golden) regenerate_golden ;;
    "") : ;;
    *) echo "unknown argument: $1 (expected none, or --regenerate-golden)" >&2; exit 2 ;;
  esac

  require_jq
  echo "=== test_domain_blast_radius.sh ==="
  echo "repo root: $REPO_ROOT"
  [ "$STRICT" = "1" ] && echo "STRICT mode: a SKIP is a defect and exits non-zero"
  echo

  test_f1_default_path_regression; echo
  test_ac3_software_nonempty; echo
  test_f4_field_semantics; echo
  test_dispatch_contract; echo

  report_and_exit
}

main "$@"
