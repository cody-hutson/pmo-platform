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
