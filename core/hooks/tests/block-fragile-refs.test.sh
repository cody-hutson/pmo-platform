#!/bin/bash
# tests/block-fragile-refs.test.sh — synthetic Write/Edit payload tests for
# block-fragile-refs.sh (#1477 — restores hook<->test parity: 12 hooks / 12 tests).
#
# Covers the four reference-durability detectors (a positive per class) plus a clean
# negative and the pass-through / mode surfaces:
#   - Class L    (BLOCK-FRAGILE-REF-001): markdown link sequence  ](  on a content line
#   - Class V    (BLOCK-FRAGILE-REF-002): version-cutover apparatus (reflexive-pipeline-loop idiom)
#   - Positional (BLOCK-FRAGILE-REF-003): a bare #N outside a designated reference block
#   - Class U    (BLOCK-FRAGILE-REF-004): a raw github.com/<o>/<r>/{issues,pull,milestone} URL
# Plus: clean-inline pass-through, out-of-scope path pass-through, non-Write/Edit tool
# skip, the per-file allow-link override marker, the CLAUDE_HOOK_BYPASS escape hatch,
# and the warn / enforce / off mode infrastructure.
# Plus payload-size independence — the same verdict at ~1 KB, ~200 KB and above ARG_MAX, a
# findings report larger than ARG_MAX, the bypass audit read — and the instrument-failure arms:
# an input the hook could not read reports INPUT-NOT-EVALUATED (fail-closed in enforce, a WARN
# in warn), for an in-scope and an out-of-scope path alike, and never reports malformed JSON.
#
# Hermetic: runs the REAL hook at its deployed path so its co-located lib/ primitives
# (dep-resolve.sh, positional-issueref.awk) and the reference-durability allowlist
# resolve naturally; the test owns the shared .mode file it toggles and restores it
# (or removes it) on exit.
#
# ON-DISK REQUIREMENT — conditional, and the condition is the tool. For a Write, and for
# every Edit arm that carries its marker inside the fragment, a synthetic durable-corpus
# file_path need not exist on disk: the hook reads content from the payload and uses the
# path only for its scope glob. The MARKER-RESOLUTION arms below are the exception — the
# hook resolves a file-scoped override marker from the TARGET FILE for an Edit, so those
# arms materialize real files under a temp root the cleanup trap removes. Stating this as
# an unconditional invariant would be the same defect class this suite's newest arms exist
# to close: a comment that misdescribes its own file.
# Summary line matches the test-runner contract: "Total: N  PASS: N  FAIL: N".

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-fragile-refs.sh"
MODE_FILE="${HOOK_DIR}/.mode"
JQ="/usr/bin/jq"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK" >&2; exit 1; }

# A synthetic in-scope durable-corpus path (matches the core/standards/*.md scope arm;
# not on the reference-durability allowlist). The file need not exist on disk.
INSCOPE="core/standards/__block-fragile-refs-fixture__.md"
# A path OUTSIDE the hook's durable-corpus scope (core/governance/ is not a scanned
# durable surface) — proves the scope gate lets a non-durable write through untouched.
OUTSCOPE="core/governance/__block-fragile-refs-fixture__.md"
# A path that IS in durable-corpus scope AND carries a path-allowlist entry. The pair
# (ALLOWLISTED, INSCOPE) is the whole point: same fragile content, same scope arm, and
# the ONLY difference is allowlist membership. Asserting the allow arm alone cannot
# distinguish "the exemption fired" from "the hook did nothing", so the two must move
# together. Kept in sync with core/config/allowlists/reference-durability-allowlist.txt.
ALLOWLISTED="core/standards/version-field-semantics.md"

# MARKER-RESOLUTION CORPUS — two real files on disk, differing ONLY in whether they
# declare the per-file override marker. The hook resolves a file-scoped marker from the
# TARGET FILE for an Edit, so these arms cannot use a synthetic path: the whole property
# under test is that a declaration the fragment does not repeat is still seen.
#
# Both sit on an in-scope durable path (the core/standards/*.md scope arm) that carries NO
# path-allowlist entry, so the allowlist cannot be what grants — same discipline as the
# INSCOPE / ALLOWLISTED pair above.
FIXTURE_ROOT="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${FIXTURE_ROOT}/core/standards"
MARKED="${FIXTURE_ROOT}/core/standards/__marker-resolution-marked__.md"
UNMARKED="${FIXTURE_ROOT}/core/standards/__marker-resolution-unmarked__.md"
/bin/cat > "$MARKED" <<'MARKEDEOF'
<!-- reference-durability: allow-link -->
# Marker-resolution fixture

This standard defines durable reference rules; summarize sources inline rather than linking.
MARKEDEOF
/bin/cat > "$UNMARKED" <<'UNMARKEDEOF'
# Marker-resolution fixture

This standard defines durable reference rules; summarize sources inline rather than linking.
UNMARKEDEOF

# Fence-awareness fixtures (#6743). A marker inside a fenced code block ILLUSTRATES the
# syntax; it does not DECLARE the override. FENCED carries the marker ONLY inside a fence
# and must NOT be exempt; FENCED_PLUS declares it outside a fence and additionally shows a
# fenced example, so it must still be exempt. Without the second fixture the first cannot
# distinguish "fenced markers stopped counting" from "markers stopped working".
FENCED="${FIXTURE_ROOT}/core/standards/__marker-resolution-fenced__.md"
FENCED_PLUS="${FIXTURE_ROOT}/core/standards/__marker-resolution-fenced-plus__.md"
/bin/cat > "$FENCED" <<'FENCEDEOF'
# Fence-illustration fixture

The override marker syntax is shown here as an example, not declared:

```
<!-- reference-durability: allow-link -->
```

This standard defines durable reference rules; summarize sources inline rather than linking.
FENCEDEOF
/bin/cat > "$FENCED_PLUS" <<'FENCEDPLUSEOF'
<!-- reference-durability: allow-link -->
# Declaration-plus-illustration fixture

Declared above, outside any fence. The same syntax is illustrated below, inside one:

```
<!-- reference-durability: allow-link -->
```

This standard defines durable reference rules; summarize sources inline rather than linking.
FENCEDPLUSEOF

# INLINE is the limb with observed harm: a decision index exempted itself with markers in
# backticked table cells, and two dead cross-references then passed CI. Its only marker is
# inside an inline code span, so it must NOT be exempt.
INLINE_MARKER="${FIXTURE_ROOT}/core/standards/__marker-resolution-inline__.md"
/bin/cat > "$INLINE_MARKER" <<'INLINEEOF'
# Inline-illustration fixture

To override this class, add `<!-- reference-durability: allow-link -->` to the file.

This standard defines durable reference rules; summarize sources inline rather than linking.
INLINEEOF

# Preserve + restore the shared .mode file so the suite is hermetic regardless of the
# deployed mode; and remove the marker-resolution corpus on the same exit.
ORIGINAL_MODE=""; [ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(/bin/cat "$MODE_FILE")"
cleanup() {
  if [ -n "$ORIGINAL_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"; else /bin/rm -f "$MODE_FILE"; fi
  [ -n "${FIXTURE_ROOT:-}" ] && /bin/rm -rf "$FIXTURE_ROOT"
}
trap cleanup EXIT

set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }

# payload <tool> <file_path> <content>
payload() {
  "$JQ" -n --arg tool "$1" --arg fp "$2" --arg c "$3" \
    '{tool_name:$tool, tool_input:{file_path:$fp, content:$c}}'
}

# edit_payload <file_path> <old_string> <new_string>
# An Edit carries only the replacement fragment, never the whole file — which is the
# asymmetry the marker-resolution arms below exist to exercise.
edit_payload() {
  "$JQ" -n --arg tool Edit --arg fp "$1" --arg o "$2" --arg n "$3" \
    '{tool_name:$tool, tool_input:{file_path:$fp, old_string:$o, new_string:$n}}'
}

PASS=0; FAIL=0

# test_case <name> <payload> <expected_exit> [expected_stderr_pattern]
test_case() {
  local name="$1" pl="$2" expected_exit="$3" pattern="${4:-}"
  local tmp; tmp="$(/usr/bin/mktemp)"; local rc=0
  /usr/bin/printf '%s' "$pl" | /bin/bash "$HOOK" 2>"$tmp" >/dev/null || rc="$?"
  local err; err="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
  local ok=1
  [ "$rc" != "$expected_exit" ] && ok=0
  [ -n "$pattern" ] && ! /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE "$pattern" && ok=0
  if [ "$ok" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s (expected_exit=%s actual=%s)\n  stderr: %s\n' "$name" "$expected_exit" "$rc" "$err"; FAIL=$((FAIL+1)); fi
}

echo "================================"
echo "block-fragile-refs.sh tests"
echo "================================"

# ---------------------------------------------------------------------------
# ENFORCE mode — a fragile reference BLOCKS (exit 2); clean/exempt/out-of-scope ALLOW.
# ---------------------------------------------------------------------------
set_mode enforce

# Positive — one per detector class.
test_case "enforce: Class L markdown link BLOCKED" \
  "$(payload Write "$INSCOPE" 'See [the reference-durability standard](../reference-durability-standard.md) for the rules.')" \
  2 "BLOCK-FRAGILE-REF-001"

test_case "enforce: Class V version-cutover apparatus BLOCKED" \
  "$(payload Write "$INSCOPE" 'This governance clause is keyed on the reflexive-pipeline-loop cutover idiom.')" \
  2 "BLOCK-FRAGILE-REF-002"

test_case "enforce: positional bare issue-ref (no reference block) BLOCKED" \
  "$(payload Write "$INSCOPE" 'This behavior was corrected in #1477 during the last release.')" \
  2 "BLOCK-FRAGILE-REF-003"

test_case "enforce: Class U raw ledger URL BLOCKED" \
  "$(payload Write "$INSCOPE" 'Historical context lives at github.com/example/repo/issues/42 for now.')" \
  2 "BLOCK-FRAGILE-REF-004"

# Negative / pass-through.
test_case "enforce: clean inline prose ALLOWED" \
  "$(payload Write "$INSCOPE" 'This standard defines durable reference rules; summarize sources inline rather than linking.')" \
  0

test_case "enforce: out-of-scope path (fragile content) ALLOWED (scope gate)" \
  "$(payload Write "$OUTSCOPE" 'See [the standard](../x.md) — out of durable scope, so untouched.')" \
  0

test_case "enforce: non-Write/Edit tool ALLOWED (tool gate)" \
  "$(payload Read "$INSCOPE" 'See [the standard](../x.md) here.')" \
  0

test_case "enforce: per-file allow-link override marker ALLOWED" \
  "$(payload Write "$INSCOPE" '<!-- reference-durability: allow-link -->
See [the standard](../x.md) — link class suppressed for this file.')" \
  0

# --- PATH ALLOWLIST: the exemption surface is reachable and actually grants -----------
# Regression arms for the defect where the hook resolved its allowlist beside itself
# (${HOOK_DIR}/) instead of at the workspace .claude/ root (${HOOK_DIR}/..), while the
# surface was also unregistered as a composition surface — so nothing deployed it, the
# existence test was false on every run, and ALL path exemptions were silently inert
# while the hook ran in enforce.
#
# These two arms are a matched pair and must be read together. Identical fragile content
# (a bare positional issue-ref, the class with no per-file override marker), identical
# scope arm (core/standards/*.md), differing ONLY in allowlist membership.
test_case "enforce: allowlisted durable path with fragile content ALLOWED (path allowlist grants)" \
  "$(payload Write "$ALLOWLISTED" 'This behavior was corrected in #9999 during the last release.')" \
  0

test_case "enforce: NON-allowlisted durable path, same content, still BLOCKED (allowlist is not a hook-wide off switch)" \
  "$(payload Write "$INSCOPE" 'This behavior was corrected in #9999 during the last release.')" \
  2 "BLOCK-FRAGILE-REF-003"

# Directory-prefix form (trailing slash in the allowlist) — the release-plans entry is the
# one the v4.34 incident hit, and it exercises a different match branch than the file form
# above, so a regression in either branch is caught.
test_case "enforce: allowlisted DIRECTORY prefix (release plans) ALLOWED" \
  "$(payload Write "release/releases/plans/v9.99_RELEASE_PLAN.md" 'This milestone carries the fix from #9999 into the pipeline.')" \
  0

# --- MARKER RESOLUTION: the override marker is FILE-scoped, so an Edit must see it ------
# Four arms, read as one set. L2-1 is the property; L2-2 is the control WITHOUT which L2-1
# cannot distinguish "the marker was honored" from "the hook stopped working"; L2-3 is the
# boundary (the marker must not leak to the positional rule, which carries no per-file
# override by design); L1-1 asserts that a release plan is spared by the PATH ALLOWLIST
# rather than by the scope gate, which is what the hook's ledger-exemption comment now says.
#
# L2-1 is the falsification arm: it exits 2 against the pre-change hook (which resolved the
# marker from the incoming fragment) and 0 after. L2-2 passes both before and after.
EDIT_LINK_FRAGMENT='See [the standard](../x.md) — link class suppressed for this file.'

test_case "enforce: Edit of a MARKER-BEARING file on a link-bearing line ALLOWED (file-scoped marker resolved from disk)" \
  "$(edit_payload "$MARKED" 'summarize sources inline rather than linking.' "$EDIT_LINK_FRAGMENT")" \
  0

test_case "enforce: Edit of a MARKER-FREE file, identical fragment, still BLOCKED (the marker is not a hook-wide off switch)" \
  "$(edit_payload "$UNMARKED" 'summarize sources inline rather than linking.' "$EDIT_LINK_FRAGMENT")" \
  2 "BLOCK-FRAGILE-REF-001"

# L2-4 / L2-5 — fence awareness (#6743), read as a pair.
# L2-4 is the falsification arm: it exits 0 against the pre-change hook (which resolved a
# fenced marker as a declaration) and 2 after. L2-5 is the control WITHOUT which L2-4 cannot
# distinguish "fenced markers no longer count" from "the fence strip ate every marker".
test_case "enforce: Edit of a file whose ONLY marker is INSIDE a fence is BLOCKED (illustration is not declaration)" \
  "$(edit_payload "$FENCED" 'summarize sources inline rather than linking.' "$EDIT_LINK_FRAGMENT")" \
  2 "BLOCK-FRAGILE-REF-001"

test_case "enforce: Edit of a file declaring the marker OUTSIDE a fence is ALLOWED even though it also shows a fenced example" \
  "$(edit_payload "$FENCED_PLUS" 'summarize sources inline rather than linking.' "$EDIT_LINK_FRAGMENT")" \
  0

# L2-6 — the inline-code-span limb. Same shape as L2-4; L2-5 remains its control.
test_case "enforce: Edit of a file whose ONLY marker is inside an INLINE CODE SPAN is BLOCKED (backticked syntax is not a declaration)" \
  "$(edit_payload "$INLINE_MARKER" 'summarize sources inline rather than linking.' "$EDIT_LINK_FRAGMENT")" \
  2 "BLOCK-FRAGILE-REF-001"

test_case "enforce: Edit of a MARKER-BEARING file, bare issue-ref fragment, still BLOCKED (marker does not leak to the positional rule)" \
  "$(edit_payload "$MARKED" 'summarize sources inline rather than linking.' 'This behavior was corrected in #9999 during the last release.')" \
  2 "BLOCK-FRAGILE-REF-003"

test_case "enforce: allowlisted DIRECTORY prefix (release plans), LINK-bearing content ALLOWED (allowlist grants before class detection)" \
  "$(payload Write "release/releases/plans/v9.99_RELEASE_PLAN.md" 'See [the reference-durability standard](../../standards/reference-durability-standard.md) for the rules.')" \
  0

# CLAUDE_HOOK_BYPASS escape hatch — permits a fragile write even in enforce mode.
BYP_TMP="$(/usr/bin/mktemp)"; BYP_RC=0
/usr/bin/printf '%s' "$(payload Write "$INSCOPE" 'See [x](../y.md) here.')" \
  | /usr/bin/env CLAUDE_HOOK_BYPASS=1 /bin/bash "$HOOK" 2>"$BYP_TMP" >/dev/null || BYP_RC="$?"
/bin/rm -f "$BYP_TMP"
if [ "$BYP_RC" = "0" ]; then echo "PASS: enforce: CLAUDE_HOOK_BYPASS=1 permits fragile write"; PASS=$((PASS+1));
else echo "FAIL: enforce: CLAUDE_HOOK_BYPASS=1 permits fragile write (exit=$BYP_RC expected=0)"; FAIL=$((FAIL+1)); fi

# ---------------------------------------------------------------------------
# PAYLOAD-SIZE INDEPENDENCE + INSTRUMENT FAILURE
# ---------------------------------------------------------------------------
# The hook must give a well-formed payload the same verdict at any size, and must
# report an input it could not read as its own failure, never as malformed JSON.
#
# NOTHING LARGE TRAVELS AS AN ARGUMENT IN THIS SECTION. That is the section's premise,
# not a style choice: test_case above feeds its payload through /usr/bin/printf and
# builds it through `jq --arg`, and both put the payload on an exec'd binary's argument
# list, which is capped per string on Linux (128 KiB) and in total on macOS (ARG_MAX,
# 1 MiB). An arm routed through test_case would fail for the harness's own reason,
# before the fix and after it, and could never go green. Here bodies are written by
# awk redirection, encoded by `jq --rawfile` (jq opens the file), fed to the hook by
# stdin redirection, and the hook's stderr is grepped where it lands.
#
# EVERY FAIL EXCERPT IS BOUNDED (2 KiB). test-runner.sh re-prints this file's whole
# output through /usr/bin/printf, so an unbounded excerpt of a large stderr would hit
# the same argument limit there and turn a readable FAIL into "no summary line".
SIZE_FP="core/standards/__size-independence-fixture__.md"
SIZE_TAIL='See [the durability standard](../reference-durability-standard.md) for the rule.'
SIZE_ARGMAX="$(/usr/bin/getconf ARG_MAX 2>/dev/null || true)"
case "$SIZE_ARGMAX" in ''|*[!0-9]*) SIZE_ARGMAX="" ;; esac
SIZE_DIR="${FIXTURE_ROOT}/size"
/bin/mkdir -p "$SIZE_DIR"
NOT_A_VERDICT='INPUT-INVALID|INPUT-NOT-EVALUATED|HOOK-ERROR'

# size_body <out> <bytes> <clean|tail|amplify|marked> — an inert filler body of about
# <bytes> bytes. `tail` appends one Class L link as the LAST line, past every size limit,
# so a BLOCK verdict proves the detector read the whole payload. `amplify` repeats a line
# three detectors report (Class L, Class U and a bare positional ref), so the findings
# report outgrows the payload that carries it. `marked` opens with a valid file-scoped
# allow-link marker and a link, so the link is exempt ONLY if the marker read succeeds.
size_body() {
  /usr/bin/awk -v n="$2" -v k="$3" -v t="$SIZE_TAIL" 'BEGIN {
    pad = "Filler prose line carrying no fragile reference construct of any kind whatsoever."
    amp = "See [the rule](github.com/example/repo/issues/42) as corrected in #42 during the release."
    if (k == "marked") { print "<!-- reference-durability: allow-link -->"; print t; b = 120 }
    line = (k == "amplify") ? amp : pad
    while (b + length(line) + 1 <= n) { print line; b += length(line) + 1 }
    if (k == "tail") print t
  }' > "$1"
}

# size_payload <out> <Write|Edit> <file_path> <body_file> — jq reads the body as a FILE.
size_payload() {
  local key="content"
  [ "$2" = "Edit" ] && key="new_string"
  "$JQ" -n --arg tool "$2" --arg fp "$3" --arg k "$key" --rawfile c "$4" \
    '{tool_name:$tool, tool_input:({file_path:$fp} + {($k):$c})}' > "$1"
}

# file_bytes <file> — measured, never computed from a line count.
file_bytes() { /usr/bin/wc -c < "$1" | /usr/bin/tr -d ' '; }

# test_case_file <name> <payload_file> <expected_exit> <must_ere|""> <must_not_ere|"">
# stderr lands in one reused file under the fixture root (the EXIT trap removes the root),
# so no arm creates or deletes a temp file of its own.
test_case_file() {
  local name="$1" pf="$2" expected_exit="$3" must="$4" mustnot="$5"
  local errf="${SIZE_DIR}/last-stderr.txt" rc=0 ok=1
  /bin/bash "$HOOK" < "$pf" > /dev/null 2> "$errf" || rc="$?"
  [ "$rc" != "$expected_exit" ] && ok=0
  if [ -n "$must" ] && ! /usr/bin/grep -qE "$must" "$errf"; then ok=0; fi
  if [ -n "$mustnot" ] && /usr/bin/grep -qE "$mustnot" "$errf"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1))
  else
    /usr/bin/printf 'FAIL: %s (expected_exit=%s actual=%s, payload %s bytes)\n  stderr (first 2 KiB):\n' \
      "$name" "$expected_exit" "$rc" "$(file_bytes "$pf")"
    /usr/bin/head -c 2048 "$errf"; /usr/bin/printf '\n'; FAIL=$((FAIL+1))
  fi
}

# arm_invalid <name> <reason> — an arm that cannot establish its own sensitivity FAILS as
# INDETERMINATE. It never passes and never skips: a skipped size arm reads like a pass.
arm_invalid() { /usr/bin/printf 'FAIL: %s (INDETERMINATE: %s)\n' "$1" "$2"; FAIL=$((FAIL+1)); }

# nf_arm <mode> <name> <payload_file> — run the hook with every temp-file write refused: a
# file-size limit of 0 with SIGXFSZ ignored, so a write fails with EFBIG instead of killing
# the process. The payload is larger than a pipe buffer, so bash 5.1+ also takes its
# temp-file path for a here-string; bash 3.2 always does. The posture is mode-coupled
# (ADR-078): enforce fails closed (exit 2, "BLOCKED (fail-closed)") and warn stands down
# (exit 0, "WARN (degraded"). In both, the report names INPUT-NOT-EVALUATED and carries
# PV-7a's clause, in its canonical lowercase form and matched case-sensitively, and nothing
# in it reads as a verdict: not malformed input (INPUT-INVALID), not a finding about the
# write (BLOCK-FRAGILE-REF-), and not a generic rule-evaluation error (HOOK-ERROR), which
# would mean the failure reached the ERR trap instead of the branch that names it. stderr
# travels through a pipe, because the limit would refuse a file.
nf_arm() {
  local m="$1" name="$2" pf="$3" rc=0 ok=1 err want_rc want_state
  if [ "$m" = "enforce" ]; then want_rc=2; want_state='BLOCKED (fail-closed)'
  else want_rc=0; want_state='WARN (degraded'; fi
  set_mode "$m"
  err="$( (trap '' XFSZ; ulimit -f 0; exec /bin/bash "$HOOK" 2>&1 >/dev/null) < "$pf" )" || rc="$?"
  [ "$rc" = "$want_rc" ] || ok=0
  /usr/bin/grep -qF 'INPUT-NOT-EVALUATED' <<<"$err" || ok=0
  /usr/bin/grep -qF "$want_state" <<<"$err" || ok=0
  /usr/bin/grep -qF 'this is not a clean result' <<<"$err" || ok=0
  if /usr/bin/grep -qE 'INPUT-INVALID|HOOK-ERROR|BLOCK-FRAGILE-REF-' <<<"$err"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1))
  else
    /usr/bin/printf 'FAIL: %s (expected_exit=%s actual=%s)\n  stderr (first 2 KiB): %s\n' \
      "$name" "$want_rc" "$rc" "$(/usr/bin/head -c 2048 <<<"$err")"; FAIL=$((FAIL+1))
  fi
}

if [ -z "$SIZE_ARGMAX" ] || [ "$SIZE_ARGMAX" -gt 67108864 ]; then
  arm_invalid "size: all size arms" "getconf ARG_MAX unusable (${SIZE_ARGMAX:-empty}), so no arm can be sized past the argument budget"
else
  SIZE_LARGE=$(( SIZE_ARGMAX + 131072 ))
  set_mode enforce

  # S1-S3 — one body shape at three sizes, link on the LAST line; the verdict must not move.
  size_body "${SIZE_DIR}/tail-small.md" 1024 tail
  size_payload "${SIZE_DIR}/tail-small.json" Write "$SIZE_FP" "${SIZE_DIR}/tail-small.md"
  test_case_file "size: ~1 KB write, link on the last line, BLOCKED on its own rule" \
    "${SIZE_DIR}/tail-small.json" 2 'BLOCK-FRAGILE-REF-001' "$NOT_A_VERDICT"

  size_body "${SIZE_DIR}/tail-mid.md" 204800 tail
  size_payload "${SIZE_DIR}/tail-mid.json" Write "$SIZE_FP" "${SIZE_DIR}/tail-mid.md"
  test_case_file "size: ~200 KB write (past the Linux per-argument cap), same verdict" \
    "${SIZE_DIR}/tail-mid.json" 2 'BLOCK-FRAGILE-REF-001' "$NOT_A_VERDICT"

  size_body "${SIZE_DIR}/tail-large.md" "$SIZE_LARGE" tail
  size_payload "${SIZE_DIR}/tail-large.json" Write "$SIZE_FP" "${SIZE_DIR}/tail-large.md"
  if [ "$(file_bytes "${SIZE_DIR}/tail-large.json")" -gt "$SIZE_ARGMAX" ]; then
    test_case_file "size: write larger than ARG_MAX, same verdict (falsification arm)" \
      "${SIZE_DIR}/tail-large.json" 2 'BLOCK-FRAGILE-REF-001' "$NOT_A_VERDICT"
  else
    arm_invalid "size: write larger than ARG_MAX" "payload $(file_bytes "${SIZE_DIR}/tail-large.json") B does not exceed ARG_MAX ${SIZE_ARGMAX} B"
  fi

  # S4 / S4b — ALLOW above ARG_MAX, in scope and out of scope. Validation runs before the
  # tool and scope gates, so the pre-fix hook refused every large write, durable or not.
  size_body "${SIZE_DIR}/clean-large.md" "$SIZE_LARGE" clean
  size_payload "${SIZE_DIR}/clean-large.json" Write "$SIZE_FP" "${SIZE_DIR}/clean-large.md"
  test_case_file "size: clean write larger than ARG_MAX ALLOWED" \
    "${SIZE_DIR}/clean-large.json" 0 '' "$NOT_A_VERDICT"
  size_payload "${SIZE_DIR}/clean-large-out.json" Write "$OUTSCOPE" "${SIZE_DIR}/clean-large.md"
  test_case_file "size: out-of-scope write larger than ARG_MAX ALLOWED (validation precedes the scope gate)" \
    "${SIZE_DIR}/clean-large-out.json" 0 '' "$NOT_A_VERDICT"

  # S6 — an Edit fragment above ARG_MAX (the new_string branch of the content read).
  size_payload "${SIZE_DIR}/tail-large-edit.json" Edit "$SIZE_FP" "${SIZE_DIR}/tail-large.md"
  test_case_file "size: Edit fragment larger than ARG_MAX, same verdict" \
    "${SIZE_DIR}/tail-large-edit.json" 2 'BLOCK-FRAGILE-REF-001' "$NOT_A_VERDICT"

  # S7 — the bypass audit read above ARG_MAX. The pre-fix read failed and logged "unknown".
  byp_log="${HOOK_DIR}/bypass-log.jsonl"
  byp_before=0
  [ -f "$byp_log" ] && byp_before="$("$JQ" -s 'length' "$byp_log" 2>/dev/null || echo 0)"
  byp_rc=0
  /usr/bin/env CLAUDE_HOOK_BYPASS=1 /bin/bash "$HOOK" < "${SIZE_DIR}/tail-large.json" > /dev/null 2>&1 || byp_rc="$?"
  byp_after="$("$JQ" -s 'length' "$byp_log" 2>/dev/null || echo 0)"
  byp_tool="$("$JQ" -rs 'last | .tool' "$byp_log" 2>/dev/null || echo unreadable)"
  if [ "$byp_rc" = 0 ] && [ "$byp_after" -gt "$byp_before" ] && [ "$byp_tool" = "Write" ]; then
    /usr/bin/printf 'PASS: %s\n' "size: bypass above ARG_MAX logs the real tool name"; PASS=$((PASS+1))
  else
    /usr/bin/printf 'FAIL: %s (rc=%s entries %s->%s tool=%s)\n' "size: bypass above ARG_MAX logs the real tool name" \
      "$byp_rc" "$byp_before" "$byp_after" "$byp_tool"; FAIL=$((FAIL+1))
  fi

  # S5 — warn mode: the payload fits inside ARG_MAX, its findings report does not. This arm
  # isolates the six report emits from the input reads: it stays RED if only the input
  # reads are converted.
  set_mode warn
  size_body "${SIZE_DIR}/amp.md" $(( SIZE_ARGMAX * 55 / 100 )) amplify
  size_payload "${SIZE_DIR}/amp.json" Write "$SIZE_FP" "${SIZE_DIR}/amp.md"
  if [ "$(file_bytes "${SIZE_DIR}/amp.json")" -lt "$SIZE_ARGMAX" ] \
     && [ $(( $(file_bytes "${SIZE_DIR}/amp.md") * 2 )) -gt "$SIZE_ARGMAX" ]; then
    test_case_file "size: warn-mode findings report larger than ARG_MAX still WARNs (report emits)" \
      "${SIZE_DIR}/amp.json" 0 'RULE:WARN' "$NOT_A_VERDICT"
  else
    arm_invalid "size: warn-mode report amplification" "payload must stay under ARG_MAX while its Class L + U lists alone exceed it"
  fi

  # S8 / S8b — instrument failure: bash cannot materialize the input for the validator. The
  # body carries a VALID file-scoped marker and a link, so the pre-fix hook, whose marker
  # read failed the same way, reported the link: an instrument failure rendered as a verdict
  # about the write.
  #
  # S8-out — the same fault on a path OUTSIDE the durable corpus. Validation runs before the
  # tool and scope gates, so the hook cannot yet know the path is out of scope, and this arm
  # asserts that posture instead of leaving it incidental. The pre-fix hook validated through
  # a pipe, read the path and exited 0 at its scope gate. The payload stays below ARG_MAX, so
  # the argument limit cannot be what either arm observes.
  size_body "${SIZE_DIR}/marked.md" 102400 marked
  size_payload "${SIZE_DIR}/marked.json" Write "$SIZE_FP" "${SIZE_DIR}/marked.md"
  size_payload "${SIZE_DIR}/marked-out.json" Write "$OUTSCOPE" "${SIZE_DIR}/marked.md"
  nf_arm enforce "enforce: unreadable input reports INPUT-NOT-EVALUATED, fail-closed" \
    "${SIZE_DIR}/marked.json"
  nf_arm warn "warn: unreadable input reports INPUT-NOT-EVALUATED as a WARN and exits 0" \
    "${SIZE_DIR}/marked.json"
  nf_arm enforce "enforce: unreadable input on an OUT-OF-SCOPE path reports INPUT-NOT-EVALUATED, fail-closed" \
    "${SIZE_DIR}/marked-out.json"
  nf_arm warn "warn: unreadable input on an OUT-OF-SCOPE path reports INPUT-NOT-EVALUATED as a WARN and exits 0" \
    "${SIZE_DIR}/marked-out.json"
fi

# ---------------------------------------------------------------------------
# WARN mode — a fragile reference WARNs (exit 0 + WARN marker), does not block.
# ---------------------------------------------------------------------------
set_mode warn
test_case "warn: Class L link WARNs (not blocking)" \
  "$(payload Write "$INSCOPE" 'See [the standard](../reference-durability-standard.md) for the rules.')" \
  0 "RULE:WARN"

# ---------------------------------------------------------------------------
# OFF mode — no action at all.
# ---------------------------------------------------------------------------
set_mode off
test_case "off: Class L link not flagged" \
  "$(payload Write "$INSCOPE" 'See [the standard](../reference-durability-standard.md) for the rules.')" \
  0

# Summary
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
