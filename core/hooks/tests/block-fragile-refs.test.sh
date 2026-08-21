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
#
# Hermetic: runs the REAL hook at its deployed path so its co-located lib/ primitives
# (dep-resolve.sh, positional-issueref.awk) and the reference-durability allowlist
# resolve naturally; the test owns the shared .mode file it toggles and restores it
# (or removes it) on exit. Synthetic durable-corpus file_paths need not exist on disk —
# the hook reads content from the payload and uses the path only for its scope glob.
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

# Preserve + restore the shared .mode file so the suite is hermetic regardless of the
# deployed mode.
ORIGINAL_MODE=""; [ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(/bin/cat "$MODE_FILE")"
cleanup() {
  if [ -n "$ORIGINAL_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"; else /bin/rm -f "$MODE_FILE"; fi
}
trap cleanup EXIT

set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }

# payload <tool> <file_path> <content>
payload() {
  "$JQ" -n --arg tool "$1" --arg fp "$2" --arg c "$3" \
    '{tool_name:$tool, tool_input:{file_path:$fp, content:$c}}'
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

# CLAUDE_HOOK_BYPASS escape hatch — permits a fragile write even in enforce mode.
BYP_TMP="$(/usr/bin/mktemp)"; BYP_RC=0
/usr/bin/printf '%s' "$(payload Write "$INSCOPE" 'See [x](../y.md) here.')" \
  | /usr/bin/env CLAUDE_HOOK_BYPASS=1 /bin/bash "$HOOK" 2>"$BYP_TMP" >/dev/null || BYP_RC="$?"
/bin/rm -f "$BYP_TMP"
if [ "$BYP_RC" = "0" ]; then echo "PASS: enforce: CLAUDE_HOOK_BYPASS=1 permits fragile write"; PASS=$((PASS+1));
else echo "FAIL: enforce: CLAUDE_HOOK_BYPASS=1 permits fragile write (exit=$BYP_RC expected=0)"; FAIL=$((FAIL+1)); fi

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
