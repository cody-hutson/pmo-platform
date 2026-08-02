#!/bin/bash
# tests/ghsa-g9g6-primitive-fail-closed.test.sh — regression for GHSA-g9g6-28c9-vrx5.
#
# GHSA-g9g6: warn/enforce security hooks fail OPEN when a co-shipped INTERNAL primitive
# is absent — block-gh-path-leak.sh (path-leak-patterns.sh) and block-fragile-refs.sh
# (positional-issueref.awk) skipped their check on a missing primitive regardless of
# .mode, including enforce. The fix extends the GHSA-9cjm mode-coupled posture to the
# internal primitives: enforce fails CLOSED (exit 2), warn/off degrade (exit 0), and a
# missing/stale/corrupt dep-resolve.sh fails closed at the readability+bash -n guard.
#
# PreToolUse exit contract: 2 = BLOCK (fail-closed) · 0 = allow · anything else = NON-
# blocking (fail-OPEN). Every "fail-closed" assertion below therefore demands EXACTLY 2.
#
# COORDINATION (milestone #271, separate release hub — do not duplicate here):
#   #3407 adds the comprehensive glob-derived fail-closed negative-dependency test across
#         ALL hooks; this file is the focused internal-primitive slice it should absorb.
#   #3410 extends the hook-registry check to a sourced-lib deploy-completeness closure +
#         a LIB-MISSING fail-closed test. This file asserts runtime behavior, not the
#         deploy-completeness gate — the two are complementary.
#
# Self-contained: builds its own throwaway HOOK_DIR per case (never touches the shared
# sandbox / live ~/Claude/.claude), so it runs identically in the source checkout and in
# the setup-ci-layout.sh deployed sandbox. bash 3.2-safe.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
JQ=/usr/bin/jq
PASS=0
FAIL=0

# Resolve the source files we materialize into each throwaway layout. The primitive
# resolves co-located first (deployed/sandbox), then the source-repo fallback — the SAME
# resolution order block-gh-path-leak.sh itself uses, so this test works in both layouts.
SRC_FRAG="${HOOK_DIR}/block-fragile-refs.sh"
SRC_GHPL="${HOOK_DIR}/block-gh-path-leak.sh"
SRC_DEPLIB="${HOOK_DIR}/lib/dep-resolve.sh"
SRC_AWK="${HOOK_DIR}/lib/positional-issueref.awk"
SRC_PATTERNS="${HOOK_DIR}/lib/fragile-ref-patterns.sh"
SRC_PRIM="${HOOK_DIR}/path-leak-patterns.sh"
[ -f "$SRC_PRIM" ] || SRC_PRIM="${HOOK_DIR}/../deploy/tools/path-leak-patterns.sh"

for req in "$SRC_FRAG" "$SRC_GHPL" "$SRC_DEPLIB" "$SRC_AWK" "$SRC_PATTERNS" "$SRC_PRIM"; do
  if [ ! -f "$req" ]; then
    echo "FAIL: required source missing: $req" >&2
    echo "Total: 1  PASS: 0  FAIL: 1"
    exit 1
  fi
done

# build_layout <dir> <mode> <awk:0|1|empty|trunc> <primitive:0|1|empty> <deplib: ok|stale|trunc|noop>
#              [patterns: 1|0|empty|trunc]   (default 1 = present and valid)
# The 6th argument is the co-shipped detector-constant lib (lib/fragile-ref-patterns.sh).
# It defaults to PRESENT so every pre-existing case keeps testing the primitive it names —
# a case that omitted it would fail closed at the constants gate and pass for the wrong
# reason, which is the vacuous-control failure this suite exists to prevent.
build_layout() {
  local d="$1" mode="$2" awk="$3" prim="$4" deplib="$5" patterns="${6:-1}"
  rm -rf "$d"; mkdir -p "$d/lib"
  cp "$SRC_FRAG" "$SRC_GHPL" "$d/"
  case "$patterns" in
    1)     cp "$SRC_PATTERNS" "$d/lib/fragile-ref-patterns.sh" ;;
    empty) : > "$d/lib/fragile-ref-patterns.sh" ;;                       # present-but-empty (constants unset)
    trunc) head -c 200 "$SRC_PATTERNS" > "$d/lib/fragile-ref-patterns.sh" ;;  # truncated mid-comment
    badsyntax) printf "LINK_RE='unterminated\n" > "$d/lib/fragile-ref-patterns.sh" ;;  # parse error
    # 0 = absent
  esac
  case "$deplib" in
    ok)    cp "$SRC_DEPLIB" "$d/lib/dep-resolve.sh" ;;
    stale) # valid lib WITHOUT deny_missing_primitive (a pre-fix / out-of-sync lib)
           /usr/bin/awk 'BEGIN{skip=0}
             /^deny_missing_primitive\(\) \{/{skip=1}
             skip==0{print}
             skip==1 && /^\}/{skip=0}' "$SRC_DEPLIB" > "$d/lib/dep-resolve.sh" ;;
    trunc) head -c 220 "$SRC_DEPLIB" > "$d/lib/dep-resolve.sh" ;;  # parse error
    noop)  cat > "$d/lib/dep-resolve.sh" <<'NOOP'
resolve_jq() { printf '%s' /usr/bin/jq; }
resolve_python3() { :; }
deny_missing_dep() { :; }
deny_missing_primitive() { :; }
NOOP
           ;;  # valid lib whose deny_ fns are silent no-ops (corrupt-lib shape)
  esac
  case "$awk" in
    1)     cp "$SRC_AWK" "$d/lib/positional-issueref.awk" ;;
    empty) : > "$d/lib/positional-issueref.awk" ;;           # present-but-empty (valid-no-op)
    trunc) head -20 "$SRC_AWK" > "$d/lib/positional-issueref.awk" ;;  # truncated
    # 0 = absent
  esac
  case "$prim" in
    1)     cp "$SRC_PRIM" "$d/path-leak-patterns.sh" ;;
    empty) : > "$d/path-leak-patterns.sh" ;;                 # present-but-empty (sources to nothing)
    # 0 = absent
  esac
  printf '%s\n' "$mode" > "$d/.mode"
}

# assert <desc> <expected_exit> <hook_basename> <layout_dir> <json>
assert() {
  local desc="$1" exp="$2" hook="$3" d="$4" json="$5" rc
  printf '%s' "$json" | /bin/bash "$d/$hook" >/dev/null 2>"$d/_err"; rc=$?
  if [ "$rc" = "$exp" ]; then
    printf 'PASS: %s [exit %s]\n' "$desc" "$rc"; PASS=$((PASS + 1))
  else
    printf 'FAIL: %s [exit %s, want %s]\n  stderr: %s\n' "$desc" "$rc" "$exp" "$(head -1 "$d/_err")"; FAIL=$((FAIL + 1))
  fi
}

frag_json() { "$JQ" -nc --arg fp "/repo/core/standards/x.md" --arg c "$1" \
  '{tool_name:"Write",tool_input:{file_path:$fp,content:$c}}'; }
gh_json()   { "$JQ" -nc --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c}}'; }

FRAGILE=$'# T\n\nWe fixed it in #42 last sprint.\n'   # bare positional #N, no L/V/U triggers
CLEAN=$'# T\n\nA clean durable doc, no fragile references.\n'
GHLEAK='gh issue create --title x --body "see /Users/victim/private/secret.md"'
NONGH='ls -la /tmp'

WORK="$(mktemp -d -t g9g6-fc.XXXXXX)"
trap 'rm -rf "$WORK"' EXIT
D="$WORK/hd"

echo "----- block-fragile-refs.sh (positional-issueref.awk) -----"
build_layout "$D" enforce 0 1 ok;    assert "enforce+classifier-absent+fragile -> FAIL-CLOSED"      2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 0 1 ok;    assert "enforce+classifier-absent+CLEAN -> FAIL-CLOSED"         2 block-fragile-refs.sh "$D" "$(frag_json "$CLEAN")"
build_layout "$D" warn    0 1 ok;    assert "warn+classifier-absent+fragile -> DEGRADE"              0 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" off     0 1 ok;    assert "off+classifier-absent+fragile -> STAND DOWN"            0 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 1 1 ok;    assert "enforce+classifier-present+fragile -> BLOCK (control)"  2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 1 1 ok;    assert "enforce+classifier-present+CLEAN -> ALLOW (no false-pos)" 0 block-fragile-refs.sh "$D" "$(frag_json "$CLEAN")"
build_layout "$D" enforce 1 1 stale; assert "enforce+STALE-lib(no helper) -> FAIL-CLOSED at guard"   2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 1 1 trunc; assert "enforce+TRUNCATED-lib -> FAIL-CLOSED at guard"          2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
# GHSA-g9g6 adversarial-review hardening: a PRESENT-but-empty/truncated classifier must not
# silently no-op (sources/runs to nothing) — it must fail closed in enforce like a missing one.
build_layout "$D" enforce empty 1 ok; assert "enforce+classifier-EMPTY(present) -> FAIL-CLOSED"       2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce trunc 1 ok; assert "enforce+classifier-TRUNCATED(present) -> FAIL-CLOSED"   2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" warn    empty 1 ok; assert "warn+classifier-EMPTY -> DEGRADE"                       0 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
# A stale lib fails CLOSED at the guard regardless of mode (established GHSA-9cjm / ADR-078
# D4 posture — a broken security-infra lib denies; recover by reinstalling). Off is no escape.
build_layout "$D" off     1 1 stale;  assert "off+STALE-lib -> FAIL-CLOSED at guard (D4 posture)"     2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
# Caller-owns-exit: a lib whose deny_ fns are silent no-ops (corrupt-lib shape) must still
# fail closed in enforce — the exit-2 lives at the call site, not only inside the callee.
build_layout "$D" enforce 0 1 noop;   assert "enforce+NO-OP-deny lib+classifier-absent -> FAIL-CLOSED" 2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"

echo "----- block-fragile-refs.sh (fragile-ref-patterns.sh) -----"
# The detector constants are a co-shipped primitive with the same D6 posture as the
# classifier above, and a STRICTER warn/off behavior: every class reads its pattern from
# this lib, so there is no partial degrade to fall back to. An unset pattern is an EMPTY
# ERE, which matches every line — a broken constants lib inverts the detector rather than
# disabling it, so warn/off must stand the hook down entirely rather than let it run.
build_layout "$D" enforce 1 1 ok 0;    assert "enforce+constants-absent+fragile -> FAIL-CLOSED"        2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 1 1 ok 0;    assert "enforce+constants-absent+CLEAN -> FAIL-CLOSED"          2 block-fragile-refs.sh "$D" "$(frag_json "$CLEAN")"
build_layout "$D" warn    1 1 ok 0;    assert "warn+constants-absent -> STAND DOWN (no empty-ERE run)" 0 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" off     1 1 ok 0;    assert "off+constants-absent -> STAND DOWN"                     0 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
# PRESENT-but-unusable variants. `empty` and `trunc` both PARSE cleanly (the lib's head is
# all comments) and source to nothing, so they are caught by the constants-non-empty gate,
# not by `bash -n`. `badsyntax` is the complementary arm caught by `bash -n` before sourcing.
build_layout "$D" enforce 1 1 ok empty;     assert "enforce+constants-EMPTY(present) -> FAIL-CLOSED"     2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 1 1 ok trunc;     assert "enforce+constants-TRUNCATED(present) -> FAIL-CLOSED" 2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 1 1 ok badsyntax; assert "enforce+constants-PARSE-ERROR -> FAIL-CLOSED at bash -n" 2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" warn    1 1 ok empty;     assert "warn+constants-EMPTY -> STAND DOWN"                  0 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
# CONTROL (specificity): the same layout with a VALID constants lib must reach the real
# detectors — BLOCK on a fragile payload, ALLOW on a clean one. Without this pair the cases
# above would pass for any hook that always exits 2.
build_layout "$D" enforce 1 1 ok 1;    assert "enforce+constants-present+fragile -> BLOCK (control)"    2 block-fragile-refs.sh "$D" "$(frag_json "$FRAGILE")"
build_layout "$D" enforce 1 1 ok 1;    assert "enforce+constants-present+CLEAN -> ALLOW (control)"      0 block-fragile-refs.sh "$D" "$(frag_json "$CLEAN")"

echo "----- block-gh-path-leak.sh (path-leak-patterns.sh) -----"
build_layout "$D" enforce 1 0 ok;    assert "enforce+primitive-absent+gh-write-leak -> FAIL-CLOSED"  2 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"
build_layout "$D" warn    1 0 ok;    assert "warn+primitive-absent+gh-write-leak -> DEGRADE"         0 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"
build_layout "$D" off     1 0 ok;    assert "off+primitive-absent+gh-write-leak -> STAND DOWN"       0 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"
build_layout "$D" enforce 1 0 ok;    assert "enforce+primitive-absent+NON-gh -> ALLOW (no over-block)" 0 block-gh-path-leak.sh "$D" "$(gh_json "$NONGH")"
build_layout "$D" enforce 1 1 ok;    assert "enforce+primitive-present+gh-write-leak -> BLOCK (control)" 2 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"
build_layout "$D" enforce 1 1 ok;    assert "enforce+primitive-present+gh-read -> ALLOW (control)"    0 block-gh-path-leak.sh "$D" "$(gh_json 'gh issue list')"
build_layout "$D" enforce 1 1 trunc; assert "enforce+TRUNCATED-lib(gh hook) -> FAIL-CLOSED at guard"  2 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"
# PRESENT-but-empty primitive (sources to nothing, path_leak_scan_line undefined) must fail
# closed in enforce — not swallow the 127 in the `if path_leak_scan_line` condition.
build_layout "$D" enforce 1 empty ok; assert "enforce+primitive-EMPTY(present) -> FAIL-CLOSED"        2 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"
build_layout "$D" warn    1 empty ok; assert "warn+primitive-EMPTY -> DEGRADE"                        0 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"
build_layout "$D" enforce 1 0 noop;   assert "enforce+NO-OP-deny lib+primitive-absent -> FAIL-CLOSED" 2 block-gh-path-leak.sh "$D" "$(gh_json "$GHLEAK")"

echo ""
echo "================================"
printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
[ "$FAIL" -gt 0 ] && exit 1
exit 0
