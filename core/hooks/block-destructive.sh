#!/bin/bash
# block-destructive.sh — PreToolUse hook blocking destructive operations
#
# - correct shell semantics (printf, BSD-grep regex, payload cwd, fail-open on missing jq)
# - git plumbing coverage, primary-write guard, tamper resistance, subprocess script ban
#
# Matcher scope: Bash, Write, Edit (the single hook branches by tool_name)
#
# Rule ID range: BLOCK-DESTRUCTIVE-001..099
#
# Part of: the bypass-permissions-readiness release

set -euo pipefail

# --- PATH PINNING (tamper resistance; blocks PATH-stub attacks per Red Team H2) ---
export PATH="/usr/bin:/bin"

# Absolute tool paths (all in /usr/bin, root-owned on macOS — not user-writable)
readonly GREP="/usr/bin/grep"
readonly JQ="/usr/bin/jq"
readonly PRINTF="/usr/bin/printf"
readonly PYTHON3="/usr/bin/python3"

# --- METADATA ---
readonly HOOK_NAME="block-destructive"
readonly HOOK_DIR="$(cd "$(dirname "$0")" && pwd -P)"
readonly ERROR_LOG="${HOOK_DIR}/hook-errors.log"
readonly BLOCK_LOG="${HOOK_DIR}/block-log.jsonl"
readonly BYPASS_LOG="${HOOK_DIR}/bypass-log.jsonl"
readonly PRIMARY_ROOT="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}"
readonly SCRIPT_ALLOWLIST="${HOOK_DIR}/../script-execution-allowlist.txt"

# --- ABSOLUTE-PATH-AWARE ANCHORS ---
# Two anchor variants capture the 5 canonical macOS/Linux absolute-path
# prefixes (/bin/, /usr/bin/, /usr/local/bin/, /opt/homebrew/bin/,
# /opt/local/bin/) in a single optional capture group. Backward-
# compatible: when the prefix group is absent, the regex degenerates
# to the original anchor pattern, so every existing fixture continues
# to pass unchanged.
#
# POSIX-ERE compliant (no Perl extensions). Tested against BSD grep.
# Pattern is duplicated across the 3 regex-based PreToolUse hooks
# (block-destructive.sh, block-egress.sh, block-rm-prefer-trash.sh) —
# extracted as a per-hook constant to surface the convention and keep
# each hook file-local-self-contained per the existing posture.
#
# - ANCHOR_PREFIX_BASH: line-start OR command-separator anchor; used
#   for verbs invoked at command position (rm, curl, ssh, alias,
#   PATH=, CLAUDE_HOOK_BYPASS=, etc.).
# - ANCHOR_PREFIX_GIT: non-alphanumeric-boundary anchor; used for the
#   `git` token specifically. Pre-existing pattern recognizes that git
#   subcommand detection must NOT match inside identifiers (e.g.,
#   `mygit_subcommand`). The optional path-prefix group composes here
#   to also detect `/usr/bin/git push --force`, which the prior
#   bare-token anchor evaded under BLOCK-DESTRUCTIVE-001.
readonly ANCHOR_PREFIX_BASH='(^|[;&|])[[:space:]]*(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'
readonly ANCHOR_PREFIX_GIT='(^|[^[:alnum:]_-])(/(usr/(local/)?|opt/(homebrew|local)/)?bin/)?'

# --- ERROR HANDLERS ---
log_error() {
  local ts
  ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo 'unknown')"
  "$PRINTF" '%s [%s] %s\n' "$ts" "$HOOK_NAME" "$1" >> "$ERROR_LOG" 2>/dev/null || true
}

# Fail-CLOSED on rule-evaluation error (exit 2 blocks the tool call)
trap 'rc=$?; log_error "RULE-EVAL-ERROR at line $LINENO (exit $rc)"; "$PRINTF" "[CLAUDE-HOOK:%s:HOOK-ERROR] BLOCKED: rule-evaluation error at line %s (exit %s). See %s.\n" "$HOOK_NAME" "$LINENO" "$rc" "$ERROR_LOG" >&2; exit 2' ERR

# --- DEPENDENCY CHECK (jq required for JSON parsing) ---
# Fail-OPEN on missing jq with loud warning (per D5 refinement: dep failure != rule error; SRE cascade-lockout concern)
if [ ! -x "$JQ" ] && ! command -v jq >/dev/null 2>&1; then
  log_error "DEPENDENCY-MISSING: jq not found (tried $JQ and PATH=$PATH)"
  "$PRINTF" '[CLAUDE-HOOK:%s:DEPENDENCY-WARN] jq not found. Security hook DEGRADED (fail-open). Install: brew install jq (or ensure /usr/bin/jq exists).\n' "$HOOK_NAME" >&2
  exit 0
fi

# --- READ & VALIDATE INPUT ---
INPUT="$(cat)"

# Validate JSON structure (fail-CLOSED if malformed — indicates hook/harness issue)
if ! "$PRINTF" '%s' "$INPUT" | "$JQ" -e . >/dev/null 2>&1; then
  log_error "INVALID-INPUT: malformed JSON on stdin"
  "$PRINTF" '[CLAUDE-HOOK:%s:INPUT-INVALID] BLOCKED: malformed hook input JSON.\n' "$HOOK_NAME" >&2
  exit 2
fi

TOOL_NAME="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_name // empty')"
CWD="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.cwd // empty')"

# --- CLAUDE_HOOK_BYPASS escape hatch (NEW-E D8) ---
# Operator-only override: set the env var BEFORE launching claude (e.g., CLAUDE_HOOK_BYPASS=1 claude).
# Mid-session Bash attempts to set this var are denied by BLOCK-DESTRUCTIVE-023 below (anti-injection).
if [ "${CLAUDE_HOOK_BYPASS:-}" = "1" ]; then
  ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg tool "$TOOL_NAME" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, tool:$tool, cwd:$cwd, action:"bypass"}' \
    >> "$BYPASS_LOG" 2>/dev/null || true
  exit 0
fi

# --- HELPERS ---

# sha256 digest helper (16 chars) for block-log evidence — avoids logging raw tool_input
digest() {
  "$PRINTF" '%s' "$1" | /usr/bin/shasum -a 256 | "$GREP" -oE '^[a-f0-9]+' | /usr/bin/head -c 16
}

# Log a block event to block-log.jsonl (append-only, JSON per line)
log_block() {
  local rule_id="$1"
  local ts; ts="$(/bin/date -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || echo unknown)"
  local tool_input; tool_input="$("$PRINTF" '%s' "$INPUT" | "$JQ" -c '.tool_input // {}')"
  local input_digest; input_digest="$(digest "$tool_input")"
  "$JQ" -n --arg ts "$ts" --arg hook "$HOOK_NAME" --arg rule "$rule_id" \
    --arg tool "$TOOL_NAME" --arg digest "$input_digest" --arg cwd "$CWD" \
    '{ts:$ts, hook:$hook, rule:$rule, tool:$tool, input_digest:$digest, cwd:$cwd}' \
    >> "$BLOCK_LOG" 2>/dev/null || true
}

# Emit structured block message + log + exit 2
block() {
  local rule_id="$1"
  local reason="$2"
  local override="$3"
  log_block "$rule_id"
  "$PRINTF" '[CLAUDE-HOOK:%s:%s] BLOCKED: %s\nOverride: %s\n' "$HOOK_NAME" "$rule_id" "$reason" "$override" >&2
  exit 2
}

# Pattern match against $COMMAND (single-string scan via printf — preserves newlines, avoids IFS splitting)
matches() {
  local pattern="$1"
  "$PRINTF" '%s' "$COMMAND" | "$GREP" -qE "$pattern"
}

# Check if a path matches any glob pattern in the script-execution allowlist
# Uses shell case globbing (bash glob), NOT regex — allowlist entries are bash glob patterns
is_script_allowlisted() {
  local path="$1"
  [ -f "$SCRIPT_ALLOWLIST" ] || return 1
  local pattern
  while IFS= read -r pattern || [ -n "$pattern" ]; do
    # Skip comments and blank lines
    case "$pattern" in
      ''|'#'*) continue;;
    esac
    # shellcheck disable=SC2254
    case "$path" in
      $pattern) return 0;;
    esac
  done < "$SCRIPT_ALLOWLIST"
  return 1
}

# ==========================================================================
# BRANCH BY TOOL NAME
# ==========================================================================

case "$TOOL_NAME" in
  Bash)
    # ---- Bash branch — destructive command patterns ----
    COMMAND="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.command // empty')"
    [ -z "$COMMAND" ] && exit 0

    # ----- NEW-A: destructive rule set (shell-semantics rewrite + catastrophic paths) -----

    # BLOCK-DESTRUCTIVE-001 — git push --force / -f (explicit allow: --force-with-lease, --force-if-includes)
    # Absolute-path-aware: also detects /usr/bin/git push --force, etc.
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+push[[:space:]]+[^;&|]*(-f|--force)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-001" \
        "git push --force is denied (rewrites remote history, coordinates poorly with teammates)." \
        "use 'git push --force-with-lease' (safer variant), or set CLAUDE_HOOK_BYPASS=1 before launching claude"
    fi

    # BLOCK-DESTRUCTIVE-002 — git reset --hard
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+reset[[:space:]]+[^;&|]*--hard([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-002" \
        "git reset --hard is denied (discards uncommitted work irreversibly)." \
        "use 'git reset' (soft/mixed) or 'git stash' first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-003 — git clean -f / -fd / --force
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+clean[[:space:]]+[^;&|]*(-[a-zA-Z]*f[a-zA-Z]*|--force)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-003" \
        "git clean -f is denied (irreversible deletion of untracked files)." \
        "use 'git clean -n' (dry run) to inspect first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-004 — rm on catastrophic system paths
    # Absolute-path-aware: also detects /bin/rm -rf /, /usr/bin/rm -rf /, etc.
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?(/|/Users|/Applications|/Library|/System|/bin|/sbin|/usr|/etc|/var)([[:space:]]|$|/\*)'; then
      block "BLOCK-DESTRUCTIVE-004" \
        "rm on catastrophic system path denied (/, /Users, /Applications, /Library, /System, /bin, /sbin, /usr, /etc, /var)." \
        "scope the rm to a specific subdirectory, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-005 — rm -rf $HOME bare
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?\$HOME/?([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-005" \
        "rm -rf \$HOME (bare) denied (would wipe user home directory on shell expansion)." \
        "scope the rm to a specific subdirectory under \$HOME (e.g., \$HOME/Downloads/temp), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-006 — rm -rf .git
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?\.git([[:space:]]|$|/)'; then
      block "BLOCK-DESTRUCTIVE-006" \
        "rm on .git denied (destroys local git history and metadata)." \
        "back up repo first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-007 — rm -rf Projects/ (legacy uppercase)
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?Projects/'; then
      block "BLOCK-DESTRUCTIVE-007" \
        "rm on Projects/ denied (legacy uppercase project directory; data loss risk)." \
        "rm specific files or subdirectories, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-008 — rm -rf projects/ (Layer 2 Cowork)
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?projects/'; then
      block "BLOCK-DESTRUCTIVE-008" \
        "rm on projects/ denied (Layer 2 Cowork-owned operational data; data loss risk)." \
        "rm specific files or subdirectories, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-009 — rm -rf pmo-platform/ (Layer 1 source tree)
    if matches "${ANCHOR_PREFIX_BASH}"'rm[[:space:]]+([^[:space:]]+[[:space:]]+)*(--[[:space:]]+)?pmo-platform/'; then
      block "BLOCK-DESTRUCTIVE-009" \
        "rm on pmo-platform/ denied (Layer 1 source tree; use git to remove tracked files instead)." \
        "rm specific files or subdirectories, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # ----- NEW-B: git plumbing coverage -----

    # BLOCK-DESTRUCTIVE-010 — git update-ref on dangerous refs (main, master, HEAD)
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+update-ref[[:space:]]+(-d[[:space:]]+)?(refs/heads/(main|master)|HEAD)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-010" \
        "git update-ref on main/master/HEAD denied (low-level ref manipulation rewrites history)." \
        "use standard git commands (commit, merge, rebase), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-011 — git symbolic-ref HEAD to main/master
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+symbolic-ref[[:space:]]+HEAD[[:space:]]+refs/heads/(main|master)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-011" \
        "git symbolic-ref HEAD to main/master denied (can abandon commits, corrupt branch state)." \
        "use standard git commands (checkout, switch), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-012 — git push with plus-refspec (force push via +<refspec>)
    # Matches: git push <remote> +main, +master, +refs/heads/main:<dst>, etc.
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+push[[:space:]]+[^;&|]*\+([^[:space:];&|]*:)?(main|master|refs/heads/(main|master))([[:space:]]|:|$)'; then
      block "BLOCK-DESTRUCTIVE-012" \
        "git push with plus-refspec (+main/+master/+refs/heads/main) denied (bypasses --force detection, still rewrites history)." \
        "use 'git push --force-with-lease' or branch-specific pushes, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-013 — git reflog expire / delete
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+reflog[[:space:]]+(expire|delete)([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-013" \
        "git reflog expire/delete denied (removes recovery safety net for recent ref changes)." \
        "only needed for disk space; set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-DESTRUCTIVE-014 — git filter-branch
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+filter-branch([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-014" \
        "git filter-branch denied (rewrites entire history; forces coordinated pushes)." \
        "use 'git filter-repo' with caution (still blocked — see BLOCK-DESTRUCTIVE-015) or set CLAUDE_HOOK_BYPASS=1"
    fi

    # BLOCK-DESTRUCTIVE-015 — git filter-repo
    if matches "${ANCHOR_PREFIX_GIT}"'git[[:space:]]+filter-repo([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-015" \
        "git filter-repo denied (rewrites entire history; forces coordinated pushes)." \
        "coordinate with team first, or set CLAUDE_HOOK_BYPASS=1"
    fi

    # ----- NEW-B: tamper resistance (PATH / alias / function / unset) -----

    # BLOCK-DESTRUCTIVE-020 — PATH assignment (export PATH=, PATH=<value>, unset PATH)
    # Blocks both plain assignment and command-prefix assignment (PATH=/tmp:$PATH cmd)
    # Note: shell-assignment rules (PATH=, export, unset) are NOT verb-invocations and
    # the absolute-path prefix is structurally inapplicable — these forms cannot be
    # invoked via /usr/bin/PATH=... However, ANCHOR_PREFIX_BASH is applied uniformly
    # per Stage 5 Spec A4.2 (mechanical uniform anchor transformation). The
    # optional prefix group degenerates to the existing pattern for these rules.
    if matches "${ANCHOR_PREFIX_BASH}"'(export[[:space:]]+)?PATH='; then
      block "BLOCK-DESTRUCTIVE-020" \
        "PATH manipulation denied (enables hook-tool substitution attacks per Red Team H2)." \
        "if you need a modified PATH, set it in your shell before launching claude, or set CLAUDE_HOOK_BYPASS=1"
    fi
    if matches "${ANCHOR_PREFIX_BASH}"'unset[[:space:]]+([^;&|]*[[:space:]])?PATH([[:space:]]|$)'; then
      block "BLOCK-DESTRUCTIVE-020" \
        "unset PATH denied (would defeat absolute-tool-path resolution in hooks)." \
        "PATH is required for hook integrity; set CLAUDE_HOOK_BYPASS=1 only if absolutely needed"
    fi

    # BLOCK-DESTRUCTIVE-021 — alias / function override of critical tools (grep, jq)
    if matches "${ANCHOR_PREFIX_BASH}"'alias[[:space:]]+(grep|jq|bash|sh|printf)='; then
      block "BLOCK-DESTRUCTIVE-021" \
        "alias override of critical tool (grep/jq/bash/sh/printf) denied (tamper attempt)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi
    if matches "${ANCHOR_PREFIX_BASH}"'function[[:space:]]+(grep|jq|bash|sh|printf)[[:space:]]*(\(|\{)'; then
      block "BLOCK-DESTRUCTIVE-021" \
        "function override of critical tool (grep/jq/bash/sh/printf) denied (tamper attempt)." \
        "set CLAUDE_HOOK_BYPASS=1 if intentional"
    fi

    # BLOCK-DESTRUCTIVE-023 — anti-injection: deny mid-session setting of CLAUDE_HOOK_BYPASS
    # The escape hatch must be operator-only (set BEFORE claude launch), not accessible to
    # Claude via prompt injection. This rule enforces the asymmetry.
    if matches "${ANCHOR_PREFIX_BASH}"'(export[[:space:]]+)?CLAUDE_HOOK_BYPASS='; then
      block "BLOCK-DESTRUCTIVE-023" \
        "CLAUDE_HOOK_BYPASS cannot be set mid-session (defeats the operator-only escape-hatch design)." \
        "to bypass hooks, exit claude and relaunch with: CLAUDE_HOOK_BYPASS=1 claude"
    fi
    if matches "${ANCHOR_PREFIX_BASH}"'CLAUDE_HOOK_BYPASS='; then
      block "BLOCK-DESTRUCTIVE-023" \
        "CLAUDE_HOOK_BYPASS command-prefix assignment denied (injection-attack vector)." \
        "to bypass hooks, exit claude and relaunch with: CLAUDE_HOOK_BYPASS=1 claude"
    fi

    # ----- NEW-B: subprocess script ban (closes Red Team C1 — script laundering) -----

    # BLOCK-DESTRUCTIVE-022 — bash/sh/zsh <path.sh> or source/. <path> not in allowlist
    # Detect script invocations and check allowlist
    # Strategy: find the first token after bash|sh|zsh that looks like a script path (ends in .sh, or preceded by source/.)
    script_invocation="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE "${ANCHOR_PREFIX_BASH}"'(bash|sh|zsh)[[:space:]]+([^[:space:]]+[[:space:]]+)*[^[:space:];&|]+\.sh([[:space:]]|$|\b)' | head -1 || true)"
    if [ -n "$script_invocation" ]; then
      # Extract the script path (the .sh argument)
      script_path="$("$PRINTF" '%s' "$script_invocation" | "$GREP" -oE '[^[:space:]]+\.sh' | tail -1 || true)"
      if [ -n "$script_path" ] && ! is_script_allowlisted "$script_path"; then
        block "BLOCK-DESTRUCTIVE-022" \
          "subprocess script execution not in allowlist: $script_path (Red Team C1 — script-laundering mitigation)." \
          "add to .claude/script-execution-allowlist.txt (glob patterns supported), or set CLAUDE_HOOK_BYPASS=1"
      fi
    fi

    # Also detect source/. with explicit file argument
    source_invocation="$("$PRINTF" '%s' "$COMMAND" | "$GREP" -oE "${ANCHOR_PREFIX_BASH}"'(source|\.)[[:space:]]+[^[:space:];&|]+' | head -1 || true)"
    if [ -n "$source_invocation" ]; then
      sourced_path="$("$PRINTF" '%s' "$source_invocation" | "$GREP" -oE '[^[:space:]]+$' || true)"
      # Only block paths that look like files (contain / or start with ~ or end with common extensions)
      case "$sourced_path" in
        /*|./*|../*|~/*|*.sh|*.bash)
          if ! is_script_allowlisted "$sourced_path"; then
            block "BLOCK-DESTRUCTIVE-022" \
              "source/. of script not in allowlist: $sourced_path" \
              "add to .claude/script-execution-allowlist.txt, or set CLAUDE_HOOK_BYPASS=1"
          fi
          ;;
      esac
    fi

    # No Bash rule matched — allow
    exit 0
    ;;

  Write|Edit)
    # ---- Write/Edit branch — .git metadata + primary-write guard ----
    FILE_PATH="$("$PRINTF" '%s' "$INPUT" | "$JQ" -r '.tool_input.file_path // empty')"
    # CWD already extracted above

    if [ -z "$FILE_PATH" ]; then
      exit 0
    fi

    # Normalize to absolute path.
    # Note: path may not exist yet (Write creates new files); resolve parent dir symlinks.
    #
    # Path normalization uses Python os.path.realpath via /usr/bin/python3 (Python
    # 3.9+, system-default on macOS 12+). Stage 5 spec referenced GNU realpath -m,
    # but /usr/bin/realpath does not exist on macOS and /bin/realpath is BSD-only
    # without the -m flag. Python os.path.realpath is the portable equivalent:
    # collapses ../ and ./, does not require path existence, follows symlinks
    # (intentional — same semantics as block-rm-prefer-trash.sh).
    # Hook degrades gracefully if /usr/bin/python3 is somehow absent — falls
    # back to the original FILE_PATH string, which still catches absolute-path
    # cases via the existing prefix-match rules but misses the ../-escape
    # edge case.
    abs_target=""
    if [ -e "$FILE_PATH" ] && [ -x "$PYTHON3" ]; then
      abs_target="$("$PYTHON3" -c 'import os, sys; print(os.path.realpath(sys.argv[1]))' "$FILE_PATH" 2>/dev/null || echo "$FILE_PATH")"
    elif [ -e "$FILE_PATH" ]; then
      # Python somehow unavailable — degrade gracefully to un-normalized path
      abs_target="$FILE_PATH"
    else
      parent_dir="$(/usr/bin/dirname "$FILE_PATH")"
      if [ -d "$parent_dir" ]; then
        parent_abs="$(cd "$parent_dir" 2>/dev/null && pwd -P)"
        abs_target="${parent_abs}/$(/usr/bin/basename "$FILE_PATH")"
      else
        abs_target="$FILE_PATH"
      fi
    fi

    # BLOCK-DESTRUCTIVE-016 — .git metadata writes (config, hooks, info) — block in any cwd
    case "$abs_target" in
      */.git/config|*/.git/hooks/*|*/.git/info/*)
        block "BLOCK-DESTRUCTIVE-016" \
          "Write/Edit to .git metadata denied (config/hooks/info are security-critical — local hooks can execute arbitrary code)." \
          "use 'git config' subcommands, commit hooks via shared scripts, or set CLAUDE_HOOK_BYPASS=1"
        ;;
    esac

    # Explicit allows (deploy targets / Layer 2)
    case "$abs_target" in
      "${PRIMARY_ROOT}/.claude/skills/"*)
        exit 0  # deploy.sh target — Layer 2
        ;;
      "${PRIMARY_ROOT}/.claude/settings.local.json")
        exit 0  # Layer 2 Cowork-owned local overrides
        ;;
    esac

    # BLOCK-DESTRUCTIVE-019 — Layer 1 primary writes when cwd is NOT under a worktree
    is_layer1=""
    case "$abs_target" in
      "${PRIMARY_ROOT}/CLAUDE.md")
        is_layer1="CLAUDE.md (root governance)"
        ;;
      "${PRIMARY_ROOT}/pmo-platform/"*)
        is_layer1="pmo-platform/** (Layer 1 source)"
        ;;
      "${PRIMARY_ROOT}/.claude/settings.json")
        is_layer1=".claude/settings.json (security settings)"
        ;;
      "${PRIMARY_ROOT}/.claude/hooks/"*)
        is_layer1=".claude/hooks/* (security hooks)"
        ;;
      "${PRIMARY_ROOT}/.claude/rules/"*)
        is_layer1=".claude/rules/* (governance rules)"
        ;;
    esac

    if [ -n "$is_layer1" ]; then
      # Cwd under a worktree allows the write (per AC — worktree context permits Layer 1 edits)
      case "$CWD" in
        "${PRIMARY_ROOT}/.claude/worktrees/"*)
          exit 0
          ;;
      esac
      block "BLOCK-DESTRUCTIVE-019" \
        "Write/Edit to Layer 1 primary path denied: ${is_layer1}. cwd=${CWD} is not under .claude/worktrees/" \
        "work from a git worktree (git worktree add), or set CLAUDE_HOOK_BYPASS=1"
    fi

    # No Write/Edit rule matched — allow
    exit 0
    ;;

  *)
    # Other tools (Read, MCP, WebFetch, etc.) — not handled by this hook; allow
    exit 0
    ;;
esac
