#!/bin/bash
# hook-fail-closed.test.sh — glob-derived fail-closed meta-test for the PreToolUse
# security hooks (GHSA-9cjm-v22x-4x33 regression lock; v3.74 build-security-hardening).
#
# WHY THIS EXISTS (the gap the shipped fix 586b968 left)
# ------------------------------------------------------
# The per-hook fail-closed tests (e.g. block-credential-reads.test.sh) are
# NAME-SCOPED: each asserts one named hook. A NEW jq-dependent block-*.sh added
# without its own test would silently escape — the exact "point-fix-leaves-the-rest-
# open" failure GHSA-9cjm was, one level up. This meta-test closes that gap by
# ENUMERATING the class from a glob over core/hooks/block-*.sh (never a hardcoded
# name-list) and asserting the fail-closed invariant on every jq-using hook by
# construction, so a future 13th hook is covered automatically.
#
# WHAT IT ASSERTS
#   (1) The block-*.sh glob is non-empty (empty set → the glob broke / hooks moved).
#   (2) Every hook is classified jq-using vs control FROM ITS OWN SOURCE (grep
#       resolve_jq + dep-resolve.sh), not a name-list — so coverage is structural.
#   (3) For every jq-using hook, with jq rendered unresolvable at ALL THREE resolver
#       abs paths (/usr/bin, /opt/homebrew/bin, /usr/local/bin — the post-fix
#       dep-resolve.sh list) and an ANTI-VACUOUS precondition proving genuine
#       unresolvability, in enforce mode: exit 2 + a deny marker + NO fail-open
#       string. (PATH-stripping alone is inert — the hooks re-export PATH internally;
#       the sed of the resolver copy is what makes jq genuinely unreachable.)
#   (4) The non-jq control hook(s) are correctly excluded from the jq-deny assertion.
#   (5) A BEHAVIORAL python3-absent case for the path-normalizing hook(s)
#       (block-fs-boundary): a symlink-escape token (no literal `..`, so it passes the
#       Step-5 guard and reaches the Step-6 python3 normalizer) fails CLOSED (exit 2 +
#       BLOCK-FS-BOUNDARY-003) when python3 is unresolvable — a bare exit-code check
#       against a `..` payload would miss this fail-open (the pre-fix `|| echo` fallback
#       let an un-normalized traversal prefix-match an allowed root).
#
# Payloads are STATIC printf/heredoc JSON literals (never built with jq): the jq
# dependency gate fires BEFORE tool-name discrimination in every hook, so a
# matcher-appropriate literal is sufficient.
#
# CATCHING MECHANISM: against the pre-fix tree the jq-missing branch returns 0
# (fail-open), so the exit-2 assertion goes RED at introduction and blocks the merge.
# This is the ONLY mechanism that directly catches GHSA-9cjm — shellcheck, bandit,
# CodeQL, actionlint, and gitleaks do not evaluate shell exit codes. Complementary to
# check-hook-dep-hardening.sh (a static grep guard): static catches source drift,
# this behavioral test catches the runtime semantic regression.
#
# Harness contract: named *.test.sh → auto-discovered by test-runner.sh; materialized
# into the CI sandbox by setup-ci-layout.sh (which co-locates lib/dep-resolve.sh and
# all block-*.sh). Emits the `Total: N  PASS: N  FAIL: N` summary line and exits 1 on
# any FAIL. bash 3.2-safe (no arrays; space-joined path lists over no-space paths).

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
DEP_LIB="${HOOK_DIR}/lib/dep-resolve.sh"

PASS=0
FAIL=0
pass() { /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { /usr/bin/printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
summary_and_exit() {
  echo ""
  echo "================================"
  /usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
  echo "================================"
  if [ "$FAIL" -gt 0 ]; then exit 1; fi
  exit 0
}

# Static-literal payloads (built WITHOUT jq).
READ_PAYLOAD='{"tool_name":"Read","tool_input":{"file_path":"/tmp/x"},"cwd":"/tmp"}'
BASH_PAYLOAD='{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"/tmp"}'

echo "================================"
echo "hook-fail-closed.test.sh — glob-derived jq/python3 fail-closed meta-test"
echo "hooks dir: $HOOK_DIR"
echo "================================"

# --- (0) resolver present (sandbox/layout sanity) ---
if [ ! -r "$DEP_LIB" ]; then
  fail "dependency resolver missing at lib/dep-resolve.sh (sandbox/layout broken)"
  summary_and_exit
fi

# --- (1) GLOB ENUMERATION + empty-set guard ---
HOOKS=""
n_hooks=0
for h in "$HOOK_DIR"/block-*.sh; do
  [ -f "$h" ] || continue
  HOOKS="$HOOKS $h"
  n_hooks=$((n_hooks + 1))
done
if [ "$n_hooks" -ge 1 ]; then
  pass "glob enumerated $n_hooks block-*.sh hook(s) (no hardcoded name-list)"
else
  fail "empty hook set (glob broken / hooks moved)"
  summary_and_exit
fi

# --- (2) CLASSIFY jq-using vs control FROM SOURCE (not a name-list) ---
JQ_HOOKS=""
CONTROL_HOOKS=""
n_jq=0
n_ctrl=0
for h in $HOOKS; do
  if /usr/bin/grep -qE '\bresolve_jq\b' "$h" && /usr/bin/grep -qE 'dep-resolve\.sh' "$h"; then
    JQ_HOOKS="$JQ_HOOKS $h"; n_jq=$((n_jq + 1))
  else
    CONTROL_HOOKS="$CONTROL_HOOKS $h"; n_ctrl=$((n_ctrl + 1))
  fi
done
if [ "$n_jq" -ge 1 ]; then
  pass "classified $n_jq jq-hook(s) + $n_ctrl control(s) from source — every jq hook is asserted by construction"
else
  fail "no jq-hook enumerated (classifier broke)"
  summary_and_exit
fi

# --- (3) PER jq-HOOK fail-closed assertion (jq unresolvable at all 3 abs paths) ---
echo ""
echo "jq-unresolvable fail-closed (enforce mode) — per jq-hook"
echo "---"
for h in $JQ_HOOKS; do
  base="$(/usr/bin/basename "$h")"
  sbox="$(/usr/bin/mktemp -d)"; /bin/mkdir -p "$sbox/lib"
  /bin/cp "$h" "$sbox/$base"
  # Render jq unresolvable at ALL 3 resolver abs paths (sed the resolver copy).
  /usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/jq-a#g' \
               -e 's#/opt/homebrew/bin/jq#/nonexistent/jq-b#g' \
               -e 's#/usr/local/bin/jq#/nonexistent/jq-c#g' \
               "$DEP_LIB" > "$sbox/lib/dep-resolve.sh"
  # Drive shared-.mode AND every own-mode-file hook to enforce (no per-hook knowledge;
  # a hook reads whichever file it uses, the others are inert). Own-mode files:
  # .autonomy-mode (block-autonomy-ceiling), .scope-segregation-mode (block-scope-segregation).
  /usr/bin/printf 'enforce' > "$sbox/.mode"
  /usr/bin/printf 'enforce' > "$sbox/.autonomy-mode"
  /usr/bin/printf 'enforce' > "$sbox/.scope-segregation-mode"

  # (3a) ANTI-VACUOUS PRECONDITION — prove genuine unresolvability via the REAL resolver.
  got="$(PATH=/usr/bin:/bin /bin/bash -c ". '$sbox/lib/dep-resolve.sh' 2>/dev/null; resolve_jq" 2>/dev/null)"
  if [ -n "$got" ]; then
    fail "$base anti-vacuous: resolve_jq still returns '$got' after the 3-path sed (4th resolver path added without updating this test?)"
    /bin/rm -rf "$sbox"; continue
  fi

  # (3b) Matcher-appropriate STATIC-LITERAL payload (built without jq). Read-only-matcher
  # hooks get the Read payload; every Bash/Write/Edit/mcp matcher gets the Bash payload.
  # Derived from the hook's own `# Matcher scope:` comment — matcher-shape, not a name-list.
  matcher="$(/usr/bin/grep -iE '^#[[:space:]]*Matcher scope:' "$h" | /usr/bin/head -1)"
  if /usr/bin/printf '%s' "$matcher" | /usr/bin/grep -qiE 'Read' \
     && ! /usr/bin/printf '%s' "$matcher" | /usr/bin/grep -qiE 'Bash|Write|Edit|mcp'; then
    payload="$READ_PAYLOAD"
  else
    payload="$BASH_PAYLOAD"
  fi

  # (3c) Run + assert fail-closed: exit 2 + deny marker + NO fail-open string.
  rc=0
  err="$(/usr/bin/printf '%s' "$payload" | /bin/bash "$sbox/$base" 2>&1 >/dev/null)" || rc=$?
  /bin/rm -rf "$sbox"
  ok=1
  [ "$rc" = 2 ] || ok=0
  /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE 'DEPENDENCY-MISSING|BLOCKED \(fail-closed\)' || ok=0
  if /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE 'DEPENDENCY-WARN|DEGRADED \(fail-open\)'; then ok=0; fi
  if [ "$ok" = 1 ]; then
    pass "$base: jq-unresolvable + enforce → exit 2 + deny marker, no fail-open string"
  else
    /usr/bin/printf 'FAIL: %s: expected exit 2 + deny marker + no fail-open string (got exit=%s)\n  stderr: %s\n' "$base" "$rc" "$err"
    FAIL=$((FAIL + 1))
  fi
done

# --- (4) NEGATIVE CONTROL — non-jq hook(s) are not mis-asserted as jq hooks ---
echo ""
echo "negative control (non-jq hooks excluded from the jq-deny assertion)"
echo "---"
ctrl_ok=1
ctrl_names=""
for c in $CONTROL_HOOKS; do
  ctrl_names="$ctrl_names $(/usr/bin/basename "$c")"
  # A control classified as non-jq must genuinely not resolve jq via the helper — else
  # the classifier under-counted the jq class (a jq hook would escape the assertion).
  if /usr/bin/grep -qE '\bresolve_jq\b' "$c" && /usr/bin/grep -qE 'dep-resolve\.sh' "$c"; then
    ctrl_ok=0
  fi
done
if [ "$n_ctrl" -eq 0 ]; then
  pass "no non-jq control hook present (every block-*.sh resolves jq)"
elif [ "$ctrl_ok" = 1 ]; then
  pass "control hook(s) correctly excluded (not jq-resolving):$ctrl_names"
else
  fail "a control hook resolves jq but was classified non-jq — classifier under-counted the jq class:$ctrl_names"
fi

# --- (5) BEHAVIORAL python3-absent case for the path-normalizing hook(s) ---
echo ""
echo "python3-unresolvable traversal fail-closed (enforce mode) — symlink-escape fixture"
echo "---"
PY_HOOKS=""
for h in $JQ_HOOKS; do
  if /usr/bin/grep -qE '\bresolve_python3\b' "$h"; then PY_HOOKS="$PY_HOOKS $h"; fi
done
if [ -z "$PY_HOOKS" ]; then
  pass "no resolve_python3-using hook enumerated (nothing to path-normalize) — case N/A"
fi
for h in $PY_HOOKS; do
  base="$(/usr/bin/basename "$h")"
  sbox="$(/usr/bin/mktemp -d)"
  /bin/mkdir -p "$sbox/.claude/hooks/lib"
  /bin/cp "$h" "$sbox/.claude/hooks/$base"
  # jq STAYS resolvable; shadow python3 at all 3 resolver paths.
  /usr/bin/sed -e 's#/usr/bin/python3#/nonexistent/py-a#g' \
               -e 's#/opt/homebrew/bin/python3#/nonexistent/py-b#g' \
               -e 's#/usr/local/bin/python3#/nonexistent/py-c#g' \
               "$DEP_LIB" > "$sbox/.claude/hooks/lib/dep-resolve.sh"
  /usr/bin/printf 'enforce' > "$sbox/.claude/hooks/.mode"
  allowed="$sbox/allowed"; /bin/mkdir -p "$allowed"
  /bin/ln -s /etc "$allowed/link"   # symlink INSIDE the allowed root → outside (no literal '..')
  /usr/bin/printf '%s\n' "$allowed" > "$sbox/.claude/fs-boundary-allowlist.txt"

  # Anti-vacuous: python3 unresolvable AND jq resolvable via the sandbox resolver.
  pygot="$(PATH=/usr/bin:/bin /bin/bash -c ". '$sbox/.claude/hooks/lib/dep-resolve.sh' 2>/dev/null; resolve_python3" 2>/dev/null)"
  jqgot="$(PATH=/usr/bin:/bin /bin/bash -c ". '$sbox/.claude/hooks/lib/dep-resolve.sh' 2>/dev/null; resolve_jq" 2>/dev/null)"
  if [ -n "$pygot" ] || [ -z "$jqgot" ]; then
    fail "$base python3-absent anti-vacuous: want python3 unresolvable + jq resolvable (py='$pygot' jq='$jqgot')"
    /bin/rm -rf "$sbox"; continue
  fi

  # Static-literal payload (printf, not jq): a symlink-escape target with NO literal `..`,
  # so it passes the Step-5 guard and reaches the Step-6 python3 normalizer.
  payload="$(/usr/bin/printf '{"tool_name":"Bash","tool_input":{"command":"cat %s/link/passwd"},"cwd":"/tmp"}' "$allowed")"
  rc=0
  err="$(/usr/bin/printf '%s' "$payload" | /bin/bash "$sbox/.claude/hooks/$base" 2>&1 >/dev/null)" || rc=$?
  /bin/rm -rf "$sbox"
  ok=1
  [ "$rc" = 2 ] || ok=0
  /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE 'BLOCK-FS-BOUNDARY-003' || ok=0
  if /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE 'DEPENDENCY-DEGRADED:WARN|DEGRADED \(fail-open\)'; then ok=0; fi
  if [ "$ok" = 1 ]; then
    pass "$base: python3-unresolvable + symlink-escape + enforce → exit 2 + BLOCK-FS-BOUNDARY-003 (traversal fails closed)"
  else
    /usr/bin/printf 'FAIL: %s: python3-absent expected exit 2 + BLOCK-FS-BOUNDARY-003 (got exit=%s)\n  stderr: %s\n' "$base" "$rc" "$err"
    FAIL=$((FAIL + 1))
  fi
done

# --- (6) LIB-MISSING x MODE MATRIX — the dependency-guard posture, per hook ----------
#
# Section (3) asserts the jq gate. This section asserts the gate ABOVE it: what a hook
# does when lib/dep-resolve.sh itself is unusable. Different control, different fail
# direction, and only this one is mode-coupled.
#
# Classification is from source, never a name-list, so a tenth mode-capable hook is
# covered the day it lands:
#   mode-capable   = declares MODE_FILE  AND carries a LIB-MISSING guard
#   always-enforce = carries a LIB-MISSING guard, declares NO MODE_FILE
#
# Asserted:
#   mode-capable, lib absent:  enforce -> exit 2 + BLOCKED (fail-closed)
#                              warn    -> exit 0 + LIB-MISSING + NON-EMPTY stderr
#                              off     -> exit 0 + LIB-MISSING + NON-EMPTY stderr
#     The enforce arm is the load-bearing one: a matrix that only proves the permissive
#     arm has verified the regression, not the invariant. Non-empty stderr in BOTH warn
#     and off is a requirement, not a nicety — a silent degrade leaves an operator
#     nothing to notice and nothing to report.
#   always-enforce, lib absent / truncated: exit 2, with ALL THREE mode files PRESENT
#     and set to `off`. Present-and-off rather than absent, so the assertion proves
#     mode-INDEPENDENCE instead of accidentally re-testing an enforce absent-file
#     default. This is the arm that covers block-credential-reads and
#     block-rm-prefer-trash, which carried no LIB-MISSING coverage at all before this.
#
# NOT asserted, and stated rather than omitted — see the RESIDUAL probe below. A
# syntactically-valid lib whose top level runs `exit 0` makes the floor hooks exit 0
# silently: `.` executes the file in the hook's own shell from inside the guard's `if`
# condition, so a top-level exit terminates the hook before the guard can rule, and
# `bash -n` cannot catch it because that is a syntax check and the syntax is valid.
# Pre-existing, tracked as its own defect, and deliberately out of scope for the
# mode-coupling work, which leaves these three hooks untouched. The probe RUNS every
# invocation and PRINTS what it observes, so a green suite can never be read as proof
# that the floor denies under every lib state.
echo ""
echo "LIB-MISSING x mode matrix — dependency-guard posture per hook"
echo "---"
MODE_HOOKS=""
FLOOR_HOOKS=""
for h in $HOOKS; do
  /usr/bin/grep -qE 'LIB-MISSING' "$h" || continue
  if /usr/bin/grep -qE '^readonly MODE_FILE=' "$h"; then
    MODE_HOOKS="$MODE_HOOKS $h"
  else
    FLOOR_HOOKS="$FLOOR_HOOKS $h"
  fi
done

# lib_sandbox HOOK MODE LIBSTATE — materialize a sandbox, echo its path.
lib_sandbox() {
  _lsb="$(/usr/bin/mktemp -d)"; /bin/mkdir -p "$_lsb/lib"
  /bin/cp "$1" "$_lsb/$(/usr/bin/basename "$1")"
  /usr/bin/printf '%s' "$2" > "$_lsb/.mode"
  /usr/bin/printf '%s' "$2" > "$_lsb/.autonomy-mode"
  /usr/bin/printf '%s' "$2" > "$_lsb/.scope-segregation-mode"
  case "$3" in
    absent)    : ;;                                                   # no lib written
    truncated) /usr/bin/head -40 "$DEP_LIB" > "$_lsb/lib/dep-resolve.sh" ;;
    selfexit)  /usr/bin/printf 'exit 0\n' > "$_lsb/lib/dep-resolve.sh" ;;
    good)      /bin/cp "$DEP_LIB" "$_lsb/lib/dep-resolve.sh" ;;
  esac
  /usr/bin/printf '%s' "$_lsb"
}

# The workspace-scope layer runs after the payload parse and exits 0 when the cwd is
# outside the workspace root. Pin the root to each sandbox so it never renders a hook
# inert and silently vacuates an arm below.
export PMO_SCOPE_GUARD_ROOT

for h in $MODE_HOOKS; do
  base="$(/usr/bin/basename "$h")"
  for m in enforce warn off; do
    sbox="$(lib_sandbox "$h" "$m" absent)"
    PMO_SCOPE_GUARD_ROOT="$sbox"
    payload="$(/usr/bin/printf '{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"%s"}' "$sbox")"
    rc=0
    err="$(/usr/bin/printf '%s' "$payload" | /bin/bash "$sbox/$base" 2>&1 >/dev/null)" || rc=$?
    /bin/rm -rf "$sbox"
    ok=1
    /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE 'LIB-MISSING' || ok=0
    if [ "$m" = enforce ]; then
      [ "$rc" = 2 ] || ok=0
      /usr/bin/printf '%s' "$err" | /usr/bin/grep -qF 'BLOCKED (fail-closed)' || ok=0
    else
      [ "$rc" = 0 ] || ok=0
      [ -n "$err" ] || ok=0
      /usr/bin/printf '%s' "$err" | /usr/bin/grep -qF 'WARN (degraded' || ok=0
    fi
    if [ "$ok" = 1 ] && [ "$m" = enforce ]; then
      pass "$base [$m]: lib absent -> exit 2 + BLOCKED (fail-closed)"
    elif [ "$ok" = 1 ]; then
      pass "$base [$m]: lib absent -> exit 0 + LIB-MISSING degrade notice on stderr"
    else
      /usr/bin/printf 'FAIL: %s [%s]: lib absent -> unexpected posture (exit=%s)\n  stderr: %s\n' "$base" "$m" "$rc" "$err"
      FAIL=$((FAIL + 1))
    fi
  done
done

echo ""
echo "always-enforce floor — mode-INDEPENDENT deny (every mode file present and set off)"
echo "---"
for h in $FLOOR_HOOKS; do
  base="$(/usr/bin/basename "$h")"
  for st in absent truncated; do
    sbox="$(lib_sandbox "$h" off "$st")"
    PMO_SCOPE_GUARD_ROOT="$sbox"
    payload="$(/usr/bin/printf '{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"%s"}' "$sbox")"
    rc=0
    err="$(/usr/bin/printf '%s' "$payload" | /bin/bash "$sbox/$base" 2>&1 >/dev/null)" || rc=$?
    /bin/rm -rf "$sbox"
    if [ "$rc" = 2 ]; then
      pass "$base [every mode file = off]: lib $st -> exit 2 (deny is mode-independent)"
    else
      /usr/bin/printf 'FAIL: %s: lib %s with every mode file set off -> expected exit 2, got %s. The mode-capable cohort is allowed to degrade only because this floor still denies.\n  stderr: %s\n' "$base" "$st" "$rc" "$err"
      FAIL=$((FAIL + 1))
    fi
  done
done

echo ""
echo "RESIDUAL probe — corrupt-but-valid lib against the always-enforce floor"
echo "---"
echo "Not an assertion. Printed every run so a green suite is never mistaken for proof"
echo "that the floor denies under every lib state. Tracked as a separate defect."
for h in $FLOOR_HOOKS; do
  base="$(/usr/bin/basename "$h")"
  sbox="$(lib_sandbox "$h" off selfexit)"
  PMO_SCOPE_GUARD_ROOT="$sbox"
  payload="$(/usr/bin/printf '{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"%s"}' "$sbox")"
  rc=0
  err="$(/usr/bin/printf '%s' "$payload" | /bin/bash "$sbox/$base" 2>&1 >/dev/null)" || rc=$?
  /bin/rm -rf "$sbox"
  mark="$(/usr/bin/printf '%s' "$err" | /usr/bin/grep -oE 'CLAUDE-HOOK:[a-z-]+:[A-Z0-9-]+' | /usr/bin/head -1)"
  /usr/bin/printf 'RESIDUAL: %s: lib = single line "exit 0" (passes bash -n) -> exit=%s marker=%s\n' \
    "$base" "$rc" "${mark:-<none>}"
done

summary_and_exit
