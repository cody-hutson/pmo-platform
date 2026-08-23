#!/bin/bash
# tests/git-pre-commit-pii.test.sh — migration-safety fixture for
# core/hooks/git-pre-commit-pii.sh (#3382 E2-b).
#
# WHAT THIS EXISTS TO CATCH. The operator-instance home relocates in this release.
# The hook resolves BOTH the needle file AND its severity dial (`.mode`) from that
# one relocating base, so a flip on an un-migrated instance invalidates the data and
# the dial in the same instant: the instance dir looks ABSENT, the hook classifies a
# configured instance as a fresh clone, and it emits a soft NOTE that can never block
# at any mode. The guard gets QUIETER exactly when it should get louder.
#
# WHY THE `.mode` IS PLACED AT THE LEGACY HOME IN THE UN-MIGRATED ARMS, AND WHY THAT
# IS THE WHOLE POINT. A fixture that places `.mode` in the hooks directory exercises
# the second resolution rung — a rung the field case never uses, because an operator
# hand-creates `.mode` in their instance dir (the file is untracked and has no
# writer, so the instance dir is the only place it is ever authored). Such a fixture
# passes while the field case fails. These arms therefore place `.mode` at the LEGACY
# instance home and nowhere else, so the assertion rides the rung that actually moves.
#
# Arms A1/A2 FAIL against the pre-E2-b hook and pass after it. That is deliberate and
# is the evidence that this fixture is capable of failing.

set -u

SRC_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK_SRC="${SRC_DIR}/git-pre-commit-pii.sh"

[ -r "$HOOK_SRC" ] || { echo "FAIL: hook not readable at $HOOK_SRC" >&2; exit 1; }

PASS=0; FAIL=0
report() { # report <name> <ok:1|0> [detail]
  if [ "$2" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s\n  %s\n' "$1" "${3:-}"; FAIL=$((FAIL+1)); fi
}

SBX="$(mktemp -d 2>/dev/null)"
cleanup() { [ -n "${SBX:-}" ] && /bin/rm -rf "$SBX"; }
trap cleanup EXIT

# --- Build the hook's REAL install geometry, rather than borrowing whatever
#     geometry this test file happens to have been copied into.
#
# This hook is a GIT hook: it is symlinked from .git/hooks/pre-commit back into the
# repo, so at run time it sits at <repo>/core/hooks/ and finds the resolver at its
# own ../deploy/ sibling. That is a different shape from the deployed .claude/hooks/
# posture the PreToolUse hooks run in, where the resolver is co-located as a SIBLING.
# This suite is executed in both places — from source, and from the materialized CI
# layout — and in the materialized one ../deploy/ does not exist, so the hook takes
# its lib-unreachable fallback, every path resolves EMPTY, and every arm that expects
# a block silently stops being able to fail.
#
# So: reconstruct the real geometry in the sandbox from whichever layout we are in,
# and run THAT. The hook and its resolver are the files under test either way.
GEOM="${SBX}/geom"
/bin/mkdir -p "${GEOM}/core/hooks" "${GEOM}/core/deploy"
LIB_SRC=""
for _cand in "${SRC_DIR}/../deploy/lib-instance-path.sh" "${SRC_DIR}/lib-instance-path.sh"; do
  [ -r "$_cand" ] && { LIB_SRC="$_cand"; break; }
done
if [ -z "$LIB_SRC" ]; then
  report "precondition: the resolver lib is findable in this layout" 0 \
    "no lib-instance-path.sh at ${SRC_DIR}/../deploy/ or ${SRC_DIR}/ — cannot build the hook's geometry"
  /usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
  exit 1
fi
report "precondition: the resolver lib is findable in this layout" 1
/bin/cp "$HOOK_SRC" "${GEOM}/core/hooks/git-pre-commit-pii.sh"
/bin/cp "$LIB_SRC" "${GEOM}/core/deploy/lib-instance-path.sh"
HOOK="${GEOM}/core/hooks/git-pre-commit-pii.sh"
STRAY_MODE="${GEOM}/core/hooks/git-pre-commit-pii.mode"

# The hooks-directory rung is the one that can mask every un-migrated arm below.
# If a `.mode` sits there, `needle_mode` resolves from it whenever the instance
# rungs miss, and A1/A2 would report ENFORCE for the wrong reason — a fixture
# passing through the very rung it exists to bypass. The geometry is freshly built
# so this must hold; assert it rather than assume it.
if [ -e "$STRAY_MODE" ]; then
  report "precondition: no stray .mode in the hooks dir (would mask every arm)" 0 \
    "found $STRAY_MODE — these arms cannot be trusted while it exists"
else
  report "precondition: no stray .mode in the hooks dir (would mask every arm)" 1
fi

# run_hook <workspace-root> <staged-line>  -> sets RC and ERR
# Builds a throwaway git repo, stages one added line, and invokes the real hook
# with the given workspace root. PMO_* direct overrides are unset so resolution
# goes through the leaf default, which is what relocates.
RC=0; ERR=""
run_hook() {
  local ws="$1" line="$2"
  local repo="${SBX}/repo"
  /bin/rm -rf "$repo"; /bin/mkdir -p "$repo"
  (
    cd "$repo" || exit 99
    /usr/bin/git init -q . 2>/dev/null
    /usr/bin/printf '%s\n' "$line" > staged.txt
    /usr/bin/git add staged.txt 2>/dev/null
  )
  local tmp; tmp="$(/usr/bin/mktemp)"
  RC=0
  (
    cd "$repo" || exit 99
    unset PMO_INSTANCE_PATH PMO_LOCALIZED_NEEDLES PMO_PEOPLE_ROSTER CLAUDE_HOOK_BYPASS
    export CLAUDE_WORKSPACE_ROOT="$ws"
    /bin/bash "$HOOK"
  ) 2>"$tmp" >/dev/null || RC="$?"
  ERR="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
}

# Workspace-root builders. LEGACY is the pre-relocation home; NEW is the
# post-relocation home. Which one exists is the entire discriminator.
mk_legacy() { # mk_legacy <ws> <mode-or-empty>
  /bin/mkdir -p "$1/personal/pmo-instance"
  [ -n "${2:-}" ] && /usr/bin/printf '%s' "$2" > "$1/personal/pmo-instance/git-pre-commit-pii.mode"
  return 0
}
mk_new() { # mk_new <ws> <mode-or-empty> <needle-or-empty>
  /bin/mkdir -p "$1/pmo-instance"
  [ -n "${2:-}" ] && /usr/bin/printf '%s' "$2" > "$1/pmo-instance/git-pre-commit-pii.mode"
  [ -n "${3:-}" ] && /usr/bin/printf '%s\n' "$3" > "$1/pmo-instance/localized-context-needles.txt"
  return 0
}

# --- PRECONDITION: the resolver actually LOADED ------------------------------
# The hook degrades to inline stubs when it cannot reach lib-instance-path.sh, and
# those stubs resolve every path to the EMPTY string. An empty instance dir fails
# both `-d` tests, so the hook takes the fresh-clone branch and returns 0 — which
# means every arm below that expects a block would silently stop being able to fail,
# and every arm that expects exit 0 would pass for the wrong reason. A green suite
# would then prove nothing at all.
#
# Discriminate positively: with a workspace root set and neither home on disk, a
# LOADED resolver names <ws>/pmo-instance in its NOTE; a stub names the empty string.
# Asserting the path appears is therefore an assertion that the real resolver ran.
WS="${SBX}/wsP"; /bin/mkdir -p "$WS"
run_hook "$WS" "harmless content"
if /usr/bin/grep -qF "${WS}/pmo-instance" <<<"$ERR"; then
  report "precondition: the resolver LOADED (hook names the resolved home, not empty)" 1
else
  report "precondition: the resolver LOADED (hook names the resolved home, not empty)" 0 \
    "the hook did not name ${WS}/pmo-instance — it is running on its lib-unreachable stubs, so no arm below is evidence. stderr: $(/usr/bin/printf '%s' "$ERR" | /usr/bin/tr '\n' '|')"
fi

# =============================================================================
# A — THE UN-MIGRATED FIELD CASE. Legacy home present (carrying the operator's
#     posture), new home absent. This is exactly what deploying the flipped
#     resolver onto an instance whose data has not been copied produces.
# =============================================================================

WS="${SBX}/wsA1"; mk_legacy "$WS" "enforce"
run_hook "$WS" "harmless content"
if [ "$RC" = 1 ]; then
  report "A1: un-migrated + legacy .mode=enforce -> BLOCKS (exit 1)" 1
else
  report "A1: un-migrated + legacy .mode=enforce -> BLOCKS (exit 1)" 0 \
    "exit=$RC (expected 1). The severity dial did not survive the relocation. stderr: $(/usr/bin/printf '%s' "$ERR" | /usr/bin/tr '\n' '|')"
fi

WS="${SBX}/wsA2"; mk_legacy "$WS" "enforce"
run_hook "$WS" "harmless content"
if /usr/bin/grep -q 'BLOCKED' <<<"$ERR"; then
  report "A2: un-migrated -> loud BLOCKED message, not the soft fresh-clone NOTE" 1
else
  report "A2: un-migrated -> loud BLOCKED message, not the soft fresh-clone NOTE" 0 \
    "stderr: $(/usr/bin/printf '%s' "$ERR" | /usr/bin/tr '\n' '|')"
fi

# A3 discriminates "the block was restored" from "everything now blocks": with the
# operator's dial at warn, the message must be loud and the exit must still be 0.
WS="${SBX}/wsA3"; mk_legacy "$WS" "warn"
run_hook "$WS" "harmless content"
if [ "$RC" = 0 ] && /usr/bin/grep -q 'BLOCKED' <<<"$ERR"; then
  report "A3: un-migrated + legacy .mode=warn -> loud but non-blocking (exit 0)" 1
else
  report "A3: un-migrated + legacy .mode=warn -> loud but non-blocking (exit 0)" 0 \
    "exit=$RC (expected 0 with a BLOCKED message)"
fi

# A4: the operator's explicit `off` must still silence the guard through the
# legacy rung — the dial is honoured, not merely defaulted to something louder.
WS="${SBX}/wsA4"; mk_legacy "$WS" "off"
run_hook "$WS" "harmless content"
if [ "$RC" = 0 ] && ! /usr/bin/grep -q 'BLOCKED' <<<"$ERR"; then
  report "A4: un-migrated + legacy .mode=off -> silent (exit 0, no BLOCKED)" 1
else
  report "A4: un-migrated + legacy .mode=off -> silent (exit 0, no BLOCKED)" 0 \
    "exit=$RC stderr: $(/usr/bin/printf '%s' "$ERR" | /usr/bin/tr '\n' '|')"
fi

# =============================================================================
# B — SPECIFICITY. A genuinely fresh clone has NEITHER home. It must stay a soft
#     NOTE at exit 0 even with no dial anywhere, or the fix has converted
#     onboarding into a wall. This arm passes before AND after E2-b; it is what
#     discriminates "un-migrated detected" from "everything now blocks".
# =============================================================================

WS="${SBX}/wsB1"; /bin/mkdir -p "$WS"
run_hook "$WS" "harmless content"
if [ "$RC" = 0 ] && /usr/bin/grep -q 'no operator-instance dir' <<<"$ERR"; then
  report "B1: fresh clone (neither home) -> soft NOTE, exit 0" 1
else
  report "B1: fresh clone (neither home) -> soft NOTE, exit 0" 0 \
    "exit=$RC stderr: $(/usr/bin/printf '%s' "$ERR" | /usr/bin/tr '\n' '|')"
fi

# =============================================================================
# C — MIGRATED. The post-migration steady state must be unchanged by E2-b.
# =============================================================================

WS="${SBX}/wsC1"; mk_new "$WS" "enforce" ""
run_hook "$WS" "harmless content"
if [ "$RC" = 1 ]; then
  report "C1: migrated + needle MISSING + .mode=enforce -> BLOCKS (unchanged)" 1
else
  report "C1: migrated + needle MISSING + .mode=enforce -> BLOCKS (unchanged)" 0 "exit=$RC (expected 1)"
fi

WS="${SBX}/wsC2"; mk_new "$WS" "enforce" "acme-widgets-internal"
run_hook "$WS" "harmless content"
if [ "$RC" = 0 ]; then
  report "C2: migrated + needle FILLED + clean content -> passes (exit 0)" 1
else
  report "C2: migrated + needle FILLED + clean content -> passes (exit 0)" 0 \
    "exit=$RC stderr: $(/usr/bin/printf '%s' "$ERR" | /usr/bin/tr '\n' '|')"
fi

# C3 is the harness's own sensitivity arm: if a real needle hit cannot produce a
# block, every exit-0 above is meaningless because the harness cannot fail.
WS="${SBX}/wsC3"; mk_new "$WS" "enforce" "acme-widgets-internal"
run_hook "$WS" "contact acme-widgets-internal for details"
if [ "$RC" = 1 ]; then
  report "C3 SENSITIVITY: migrated + staged line hits a needle -> BLOCKS (exit 1)" 1
else
  report "C3 SENSITIVITY: migrated + staged line hits a needle -> BLOCKS (exit 1)" 0 \
    "exit=$RC — the harness cannot produce a block, so no exit-0 arm above is evidence"
fi

# =============================================================================
# D — PRECEDENCE. When BOTH homes exist, the migrated home's dial must win, or a
#     stale legacy posture would silently override the operator's current one.
# =============================================================================

WS="${SBX}/wsD1"; mk_legacy "$WS" "enforce"; mk_new "$WS" "off" ""
run_hook "$WS" "harmless content"
if [ "$RC" = 0 ] && ! /usr/bin/grep -q 'BLOCKED' <<<"$ERR"; then
  report "D1: both homes -> the NEW home's .mode wins over the legacy one" 1
else
  report "D1: both homes -> the NEW home's .mode wins over the legacy one" 0 \
    "exit=$RC stderr: $(/usr/bin/printf '%s' "$ERR" | /usr/bin/tr '\n' '|')"
fi

/usr/bin/printf '\nRESIDUAL: these arms exercise the resolution rungs and the branch predicate.\n'
/usr/bin/printf 'RESIDUAL: they do NOT prove an operator copied their data — no in-repo test can.\n'
/usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
