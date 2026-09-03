#!/bin/bash
# tests/block-draft-files.test.sh — synthetic PreToolUse payload tests for
# block-draft-files.sh (#411b). Covers: draft-shape + outside-governed flagging,
# the git-ignored sanctioned-scratch allow (incl. the adversarial PR-1 cases:
# steering-committee/ + */governance/roadmaps/), normal-governed allow, and the
# warn / enforce / off mode infrastructure.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-draft-files.sh"
MODE_FILE="${HOOK_DIR}/.mode"

[ -x "$HOOK" ] || { echo "FAIL: hook not executable at $HOOK" >&2; exit 1; }

# Hermetic git fixture. The hook classifies via `git check-ignore` against the repo
# that contains the payload's cwd, so the test must OWN a real git repo carrying the
# sanctioned-scratch .gitignore patterns — depending on the ambient checkout makes the
# test pass locally but fail in CI's materialized-layout sandbox (a bare mktemp dir
# with no git context → the hook fail-opens and every BLOCK case regresses; this was
# the #1847 CI miss). The .gitignore mirrors the real repo: personal/,
# steering-committee/, and <root>/governance/roadmaps/ per governed root.
REPO="$(mktemp -d 2>/dev/null)"
(
  cd "$REPO" && /usr/bin/git init -q && /usr/bin/printf '%s\n' \
    'personal/' 'steering-committee/' \
    'core/governance/roadmaps/' 'release/governance/roadmaps/' 'operations/governance/roadmaps/' \
    > .gitignore
)
REPO="$(cd "$REPO" && pwd -P)"   # canonicalize (macOS mktemp returns a /private symlink) to match `git rev-parse --show-toplevel`

ORIGINAL_MODE=""; [ -f "$MODE_FILE" ] && ORIGINAL_MODE="$(cat "$MODE_FILE")"
cleanup() {
  if [ -n "$ORIGINAL_MODE" ]; then /usr/bin/printf '%s' "$ORIGINAL_MODE" > "$MODE_FILE"; else /bin/rm -f "$MODE_FILE"; fi
  [ -n "${REPO:-}" ] && /bin/rm -rf "$REPO"
}
trap cleanup EXIT

set_mode() { /usr/bin/printf '%s' "$1" > "$MODE_FILE"; }

PASS=0; FAIL=0
# test_case <name> <repo-relative-path> <expected_exit> [expected_stderr_pattern]
test_case() {
  local name="$1" rel="$2" expected_exit="$3" pattern="${4:-}"
  local payload; payload="$(/usr/bin/printf '{"tool_name":"Write","cwd":"%s","tool_input":{"file_path":"%s/%s"}}' "$REPO" "$REPO" "$rel")"
  local tmp; tmp="$(/usr/bin/mktemp)"; local rc=0
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp" >/dev/null || rc="$?"
  local err; err="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
  local ok=1
  [ "$rc" != "$expected_exit" ] && ok=0
  [ -n "$pattern" ] && ! /usr/bin/printf '%s' "$err" | /usr/bin/grep -qE "$pattern" && ok=0
  if [ "$ok" = 1 ]; then /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s (expected_exit=%s actual=%s)\n  stderr: %s\n' "$name" "$expected_exit" "$rc" "$err"; FAIL=$((FAIL+1)); fi
}

# --- ENFORCE mode: flags BLOCK (exit 2), allows pass (exit 0) ---
set_mode enforce
test_case "enforce: docs/proposals/ draft (the incident) BLOCKED" "docs/proposals/enhancement.md" 2 "BLOCK-DRAFT-001"
test_case "enforce: draft segment under governed root BLOCKED"     "core/scratch/wip.md"           2 "BLOCK-DRAFT-001"
test_case "enforce: stray top-level file BLOCKED"                  "random-idea.md"                2 "outside the governed"
test_case "enforce: normal governed write ALLOWED"                "core/standards/new.md"          0
test_case "enforce: release/ governed write ALLOWED"              "release/references/how-to/g.md" 0
test_case "enforce: tracked top-level (README) ALLOWED"          "README.md"                       0
test_case "enforce: git-ignored personal/ ALLOWED"              "personal/notes.md"               0
test_case "enforce: git-ignored governance/roadmaps (PR-1) ALLOWED" "core/governance/roadmaps/r.md" 0
test_case "enforce: git-ignored steering-committee (PR-1) ALLOWED"  "steering-committee/notes.md"   0

# --- WARN mode: flags WARN (exit 0 + message), allows silent ---
set_mode warn
test_case "warn: draft WARNs not blocks" "docs/proposals/x.md" 0 "WARN \\(would-block"
test_case "warn: governed write silent"  "core/standards/y.md" 0

# --- OFF mode: no action ---
set_mode off
test_case "off: draft not flagged" "docs/proposals/z.md" 0

# =====================================================================================
# #6115 — REPO IDENTITY: the rule applies only to the repository whose layout it describes
# =====================================================================================
#
# WHY EVERY ARM BELOW CARRIES ITS OWN ARMING PROOF.
# The 12 cases above assert an exit code against a fixture repo built by `mktemp -d`, which
# is under neither the governed workspace root nor any platform checkout. They are readable
# only because test-runner.sh exports PMO_SCOPE_GUARD_ROOT="/" for the whole harness. Run
# this file WITHOUT the runner and the hook exits at layer 3 for every case: the three
# expected_exit=2 arms fail, and the six expected_exit=0 arms PASS VACUOUSLY against a hook
# that never evaluated a rule. An arm that cannot distinguish "the rule ran and allowed"
# from "the hook was never armed" is not an arm — and the arms below are all must-ALLOW
# arms, which is exactly the shape that failure mode makes unreadable.
#
# So each case ships as a BOUND PAIR evaluated in ONE configuration: a must-allow SUBJECT and
# a must-block TWIN. The pair is reported PASS only when the twin actually emitted
# BLOCK-DRAFT-001 — the twin IS the control arm, and its firing is the observation that makes
# the subject's silence mean something. If the twin is silent the pair reports UNUSABLE
# rather than PASS, because under an inert hook both halves exit 0.
#
# These arms are additive. They do not repair, mask, or depend on the pre-existing baseline
# above, whose fixture-root fault is owned elsewhere.

# --- Fixture: a governed workspace root holding TWO repositories ---------------------
# <ws>/pmo-platform  — the repo-identity anchor the hook derives from scope_guard_root()
# <ws>/product-repo  — a SECOND, non-platform repository beside it (the card's shape)
# The workspace root itself is NOT a git repo, mirroring a real install. Both overrides used
# below are the sandbox overrides the corpus already documents for this purpose:
# PMO_SCOPE_GUARD_ROOT (lib/scope-guard.sh, "integration tests / sandboxed runs") and
# PMO_PLATFORM_CONFIG_ROOT (lib/master-enable.sh, same clause). Pinning master ON per case
# makes these arms readable under a direct invocation too, instead of only under the runner.
ID_WS="$(mktemp -d 2>/dev/null)"; ID_WS="$(cd "$ID_WS" && pwd -P)"
ID_PLAT="${ID_WS}/pmo-platform"
ID_FOREIGN="${ID_WS}/product-repo"
ID_CFG="${ID_WS}/config"
/bin/mkdir -p "$ID_PLAT" "$ID_FOREIGN" "$ID_CFG"
for _idrepo in "$ID_PLAT" "$ID_FOREIGN"; do
  (
    cd "$_idrepo" && /usr/bin/git init -q && /usr/bin/printf '%s\n' \
      'personal/' 'steering-committee/' 'core/governance/roadmaps/' > .gitignore
  )
done
/usr/bin/printf '[security_hooks]\nmaster_enabled = true\n' > "${ID_CFG}/platform-config.toml"
_id_cleanup() { [ -n "${ID_WS:-}" ] && /bin/rm -rf "$ID_WS"; }

# id_run <tool> <cwd-repo> <repo-relative-path> — invoke the hook; set ID_RC and ID_ERR.
# Kept as globals rather than a packed string because stderr carries newlines.
ID_RC=""; ID_ERR=""
id_run() {
  local tool="$1" repo="$2" rel="$3" payload tmp
  payload="$(/usr/bin/printf '{"tool_name":"%s","cwd":"%s","tool_input":{"file_path":"%s/%s"}}' "$tool" "$repo" "$repo" "$rel")"
  tmp="$(/usr/bin/mktemp)"; ID_RC=0
  /usr/bin/printf '%s' "$payload" \
    | /usr/bin/env "PMO_SCOPE_GUARD_ROOT=${ID_WS}" "PMO_PLATFORM_CONFIG_ROOT=${ID_CFG}" \
        /bin/bash "$HOOK" 2>"$tmp" >/dev/null || ID_RC="$?"
  ID_ERR="$(/bin/cat "$tmp")"; /bin/rm -f "$tmp"
}

# id_pair <name> <tool> <twin_expected_rc> <subject-repo> <subject-rel> <twin-repo> <twin-rel>
#   PASS iff  (a) the TWIN emitted BLOCK-DRAFT-001 at the expected exit code — the arming
#                 proof, evaluated FIRST so a dead hook can never be reported as a pass; and
#             (b) the SUBJECT exited 0 with EMPTY stderr.
#   Asserting stderr emptiness (not just exit 0) is load-bearing: under .mode=warn every
#   exit code is 0, so the exit code alone does not discriminate there.
id_pair() {
  local name="$1" tool="$2" twin_rc="$3" srepo="$4" srel="$5" trepo="$6" trel="$7"
  local brc berr
  id_run "$tool" "$trepo" "$trel"; brc="$ID_RC"; berr="$ID_ERR"
  if [ "$brc" != "$twin_rc" ] || ! /usr/bin/printf '%s' "$berr" | /usr/bin/grep -q 'BLOCK-DRAFT-001'; then
    /usr/bin/printf 'FAIL: %s (UNUSABLE — arming proof failed: twin %s expected exit=%s + BLOCK-DRAFT-001, got exit=%s stderr: %s)\n' \
      "$name" "$trel" "$twin_rc" "$brc" "$berr"; FAIL=$((FAIL+1)); return
  fi
  id_run "$tool" "$srepo" "$srel"
  if [ "$ID_RC" != "0" ] || [ -n "$ID_ERR" ]; then
    /usr/bin/printf 'FAIL: %s (subject %s expected exit 0 + empty stderr; got exit=%s stderr: %s)\n' \
      "$name" "$srel" "$ID_RC" "$ID_ERR"; FAIL=$((FAIL+1)); return
  fi
  /usr/bin/printf 'PASS: %s (armed: twin exit=%s)\n' "$name" "$brc"; PASS=$((PASS+1))
}

# id_ok <name> <condition-result> <detail> — a plain structural assertion.
id_ok() {
  if [ "$2" = "0" ]; then /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS+1));
  else /usr/bin/printf 'FAIL: %s (%s)\n' "$1" "$3"; FAIL=$((FAIL+1)); fi
}

# --- AC6: every fixture cwd is inside a real git repository -------------------------
# The card records that a cwd which is NOT in a repo fail-opens at `[ -z "$REPO" ] && exit 0`
# BEFORE the rule is reached, so an arm issued from there measures nothing and reads as a
# false pass. Assert the precondition rather than assume it, and prove the false-pass path is
# real by exercising it deliberately.
_id_top_plat="$(cd "$ID_PLAT" && /usr/bin/git rev-parse --show-toplevel 2>/dev/null || echo "")"
_id_top_frgn="$(cd "$ID_FOREIGN" && /usr/bin/git rev-parse --show-toplevel 2>/dev/null || echo "")"
_id_top_ws="$(cd "$ID_WS" && /usr/bin/git rev-parse --show-toplevel 2>/dev/null || echo "")"
id_ok "AC6: platform fixture cwd is inside a git repo" \
  "$([ -n "$_id_top_plat" ] && echo 0 || echo 1)" "show-toplevel empty at $ID_PLAT"
id_ok "AC6: nested-repo fixture cwd is inside a git repo" \
  "$([ -n "$_id_top_frgn" ] && echo 0 || echo 1)" "show-toplevel empty at $ID_FOREIGN"
id_ok "AC6 control: workspace root is NOT a repo (the fail-open path is real)" \
  "$([ -z "$_id_top_ws" ] && echo 0 || echo 1)" "show-toplevel unexpectedly non-empty: $_id_top_ws"
set_mode enforce
id_run "Write" "$ID_WS" "anything.md"
id_ok "AC6 control: non-repo cwd exits 0 via the line-81 fail-open (measures nothing)" \
  "$([ "$ID_RC" = "0" ] && [ -z "$ID_ERR" ] && echo 0 || echo 1)" "exit=$ID_RC stderr=$ID_ERR"

# --- AC1: the nested non-platform repository is no longer judged by this layout ------
# Each subject is a path that is legitimate for THAT repo and has no counterpart in this
# platform's directory allowlist. The twin is the SAME relative path inside the platform
# checkout, which must still be refused — that is what proves the rule was reachable.
set_mode enforce
id_pair "AC1 enforce: nested repo .claude/commands/ Write ALLOWED" \
  "Write" 2 "$ID_FOREIGN" ".claude/commands/deploy.md" "$ID_PLAT" ".claude/commands/deploy.md"
id_pair "AC1 enforce: nested repo root-level doc Edit ALLOWED" \
  "Edit" 2 "$ID_FOREIGN" "CONTRIBUTORS.md" "$ID_PLAT" "CONTRIBUTORS.md"
id_pair "AC1 enforce: nested repo ordinary source file ALLOWED" \
  "Write" 2 "$ID_FOREIGN" "src/index.js" "$ID_PLAT" "src/index.js"
id_pair "AC1 enforce: nested repo MultiEdit ALLOWED" \
  "MultiEdit" 2 "$ID_FOREIGN" "lib/util.ts" "$ID_PLAT" "lib/util.ts"

# The deployed posture is .mode=warn, where EVERY exit code is 0 and only the emitted line
# discriminates. Re-run the subject there: the twin must still emit BLOCK-DRAFT-001 at exit 0.
set_mode warn
id_pair "AC1 warn: nested repo .claude/commands/ Write SILENT" \
  "Write" 0 "$ID_FOREIGN" ".claude/commands/deploy.md" "$ID_PLAT" ".claude/commands/deploy.md"
id_pair "AC1 warn: nested repo ordinary source file SILENT" \
  "Write" 0 "$ID_FOREIGN" "src/index.js" "$ID_PLAT" "src/index.js"

# --- AC2: enforcement INSIDE the platform repo is unchanged -------------------------
# All three incident shapes still flag. Here subject and twin share ONE cwd and differ only
# in target path, so the pair also proves the matcher itself discriminates rather than the
# hook merely being on.
set_mode enforce
id_pair "AC2: docs/proposals draft still BLOCKED (control: governed path allowed)" \
  "Write" 2 "$ID_PLAT" "core/rules/git-workflow.md" "$ID_PLAT" "docs/proposals/enhancement.md"
id_pair "AC2: draft segment under a governed root still BLOCKED" \
  "Write" 2 "$ID_PLAT" "core/rules/git-workflow.md" "$ID_PLAT" "core/scratch/wip.md"
id_pair "AC2: stray new top-level file still BLOCKED" \
  "Write" 2 "$ID_PLAT" "README.md" "$ID_PLAT" "random-idea.md"

# --- Membership, not path shape: a platform WORKTREE is still the platform ----------
# This is WHY the predicate compares --git-common-dir and not --show-toplevel. A linked
# worktree reports a DIFFERENT toplevel but the SAME common dir. The worktree below sits
# beside the checkout under the same governed root, so it is in workspace scope and layer 4
# is the only thing deciding: a toplevel-based predicate would read it as a foreign repo and
# silently stop enforcing there, while the shipped predicate keeps enforcing. The twin here
# is the WORKTREE, so its firing is what proves membership was recognized.
_id_wt="${ID_WS}/platform-worktree"
_id_wt_made=1
(
  cd "$ID_PLAT" \
    && /usr/bin/printf 'seed\n' > README.md \
    && /usr/bin/git -c user.email=t@example.invalid -c user.name=t add README.md \
    && /usr/bin/git -c user.email=t@example.invalid -c user.name=t commit -qm seed \
    && /usr/bin/git worktree add -q --detach "$_id_wt"
) >/dev/null 2>&1 && _id_wt_made=0
if [ "$_id_wt_made" = "0" ] && [ -d "$_id_wt" ]; then
  # Guard the premise: the worktree must genuinely report a different toplevel, or the arm
  # proves nothing about common-dir-vs-toplevel.
  _id_wt_top="$(cd "$_id_wt" && /usr/bin/git rev-parse --show-toplevel 2>/dev/null || echo "")"
  id_ok "membership premise: worktree toplevel differs from the checkout's" \
    "$([ -n "$_id_wt_top" ] && [ "$_id_wt_top" != "$ID_PLAT" ] && echo 0 || echo 1)" \
    "worktree toplevel='$_id_wt_top' checkout='$ID_PLAT'"
  set_mode enforce
  id_pair "membership: platform worktree (different toplevel, same common dir) still enforced" \
    "Write" 2 "$ID_FOREIGN" "src/index.js" "$_id_wt" "docs/proposals/enhancement.md"
else
  /usr/bin/printf 'FAIL: membership: platform worktree fixture could not be created (arm unusable)\n'
  FAIL=$((FAIL+1))
fi

# --- The relative-path trap the normalization exists for --------------------------
# git reports --git-common-dir RELATIVE when the invocation is inside the repository, so
# from a SUBDIRECTORY of the checkout the raw value is "../.git" rather than an absolute
# path. A predicate that string-compared the raw values would classify the platform's own
# subdirectories as a foreign repo and silently stop enforcing there — the exact failure
# git-post-merge-deploy.sh's Guard A documents. Enforcement from a subdirectory is
# therefore its own arm, not an assumed consequence of the checkout-root arm above.
/bin/mkdir -p "${ID_PLAT}/core/rules"
_id_raw_sub="$(cd "${ID_PLAT}/core/rules" && /usr/bin/git rev-parse --git-common-dir 2>/dev/null || echo "")"
# Computed with a plain case rather than inside $( ), where the first ")" would close the
# command substitution before the pattern list ended.
_id_rel_ok=1
case "$_id_raw_sub" in
  /*) _id_rel_ok=1 ;;   # absolute: the trap is not reproduced on this git, so do not claim it
  ?*) _id_rel_ok=0 ;;   # non-empty and not absolute -> relative, as the design assumes
esac
id_ok "relative-path premise: --git-common-dir is RELATIVE from a subdirectory" \
  "$_id_rel_ok" "expected a relative value, got '$_id_raw_sub'"
set_mode enforce
id_pair "relative-path trap: enforcement from a platform SUBDIRECTORY is unchanged" \
  "Write" 2 "${ID_PLAT}/core/rules" "core/rules/git-workflow.md" "${ID_PLAT}/core/rules" "docs/proposals/enhancement.md"

# --- Nearest tree wins: a foreign repo INSIDE the checkout is still foreign ---------
# The predicate resolves the common dir of the repository containing $CWD, and git stops at
# the nearest .git. A repo vendored inside the platform checkout therefore resolves to its
# OWN administrative directory and is correctly not-platform — the containing path does not
# confer identity. Asserted because the gate's comment claims it.
/bin/mkdir -p "${ID_PLAT}/vendor/inner-repo"
( cd "${ID_PLAT}/vendor/inner-repo" && /usr/bin/git init -q ) >/dev/null 2>&1
id_pair "nearest tree wins: foreign repo nested INSIDE the checkout is not the platform" \
  "Write" 2 "${ID_PLAT}/vendor/inner-repo" "src/index.js" "$ID_PLAT" "docs/proposals/enhancement.md"

# --- Anchor axis: an unresolvable anchor ABSTAINS, it never becomes a kill switch ----
# A SECOND governed root that holds a repository but NO pmo-platform checkout. The cwd is in
# scope, so layer 3 passes and layer 4 is what decides; the anchor cannot be resolved, so the
# gate must fall through to the rule — NOT go inert. Were this axis inverted, a single
# `rm -rf` of the platform checkout would silently disable BLOCK-DRAFT-001 machine-wide,
# which is the kill-switch shape lib/scope-guard.sh clause 2 exists to forbid.
ID_WS2="$(mktemp -d 2>/dev/null)"; ID_WS2="$(cd "$ID_WS2" && pwd -P)"
/bin/mkdir -p "${ID_WS2}/some-repo"
( cd "${ID_WS2}/some-repo" && /usr/bin/git init -q ) >/dev/null 2>&1
id_ok "anchor-axis premise: the second root holds no pmo-platform checkout" \
  "$([ ! -d "${ID_WS2}/pmo-platform" ] && echo 0 || echo 1)" "anchor unexpectedly present"
set_mode enforce
_id_norc=0
/usr/bin/printf '{"tool_name":"Write","cwd":"%s/some-repo","tool_input":{"file_path":"%s/some-repo/docs/proposals/enhancement.md"}}' "$ID_WS2" "$ID_WS2" \
  | /usr/bin/env "PMO_SCOPE_GUARD_ROOT=${ID_WS2}" "PMO_PLATFORM_CONFIG_ROOT=${ID_CFG}" \
      /bin/bash "$HOOK" >/dev/null 2>&1 || _id_norc="$?"
id_ok "anchor axis: unresolvable anchor ABSTAINS (rule still enforced, no kill switch)" \
  "$([ "$_id_norc" = "2" ] && echo 0 || echo 1)" "expected exit 2, got $_id_norc"

_id_cleanup
[ -n "${ID_WS2:-}" ] && /bin/rm -rf "$ID_WS2"

/usr/bin/printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
