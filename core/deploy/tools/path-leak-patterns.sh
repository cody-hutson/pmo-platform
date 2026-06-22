#!/usr/bin/env bash
# path-leak-patterns.sh — shared path-leak detection primitive (#529).
#
# Sourced by:
#   - core/deploy/deploy.sh Check 43 (path-portability) — the tracked-file surface.
#   - core/hooks/block-gh-path-leak.sh (#1137) — the gh issue/PR-ops surface.
#
# Seam contract (per the Stage-5 + adversarial review): the regex CONSTANTS and the
# path_leak_line_is_exempt() PREDICATE are SHARED across both surfaces. Each consumer
# supplies its OWN corpus (which lines to scan) and its OWN file-/surface-allowlist.
#
# Three leak classes (the path-portability family; host-axis sibling = the
# host-binding-leak class, knowledge-architecture.md §4.1):
#   MACHINE      — an absolute machine path carrying a username segment
#                  (/Users/<u>, /home/<u>) — a non-portable local path.
#   RAWROOT      — a raw workspace root ($HOME/Claude, ${HOME}/Claude, ~/Claude) used
#                  OUTSIDE the sanctioned ${VAR:-$HOME/Claude...} default-expansion.
#   INSTANCE_REL — a BARE relative operator-instance path (personal/pmo-instance/...,
#                  personal/analysis/..., personal/harness/...) with no $HOME/~//Users
#                  prefix. This is the #1105–1108 originating-leak class that the
#                  MACHINE/RAWROOT patterns miss; promoted into the shared primitive
#                  per the operator's scope-lock so BOTH surfaces catch it.
#
# Run directly with --self-test to verify the patterns + predicate.

# Absolute machine path with a username segment. Synthetic fixture usernames are
# subtracted by the predicate (so deploy/hook test fixtures do not self-trip).
PATH_LEAK_RE_MACHINE='(/Users/|/home/)[a-z][a-z0-9._-]+'

# Raw workspace-root form ($HOME/Claude, ~/Claude). DEFINED for reference but NOT in
# the active scan (see path_leak_scan_line) — $HOME/Claude is the portable canonical
# default (resolves per-user), not a machine-specific leak.
PATH_LEAK_RE_RAWROOT='(\$HOME|\$\{HOME\}|~)/Claude'

# Bare relative operator-instance path (no leading $HOME / ~ / /). Word-boundary
# anchored: it requires the literal 'personal/pmo-instance' (etc.), so
# 'personal opinion' / 'personalization' never match.
PATH_LEAK_RE_INSTANCE_REL='(^|[^A-Za-z0-9._/-])(personal/pmo-instance|personal/analysis|personal/harness)(/|[^A-Za-z]|$)'

# Synthetic fixture usernames that must NOT trip MACHINE (deploy.sh + hook fixtures).
PATH_LEAK_FIXTURE_USERS='testuser|otheruser|someuser|foo|bar|baz|user|alice|bob|jane-doe'

# path_leak_line_is_exempt <line> → 0 (exempt) / 1 (a real leak).
# Shared exemptions: an explicit 'path-leak: allow' marker; the sanctioned
# ${VAR:-$HOME/Claude...} default-expansion; a ${PARAM} reference; a synthetic
# fixture username in a machine path. Per-surface corpus/file allowlists are the
# consumer's job (NOT here).
path_leak_line_is_exempt() {
  local line="$1"
  case "$line" in
    *'path-leak: allow'*)                  return 0 ;;  # explicit per-line marker
    *'${'*':-'*'$HOME/Claude'*'}'*)        return 0 ;;  # sanctioned default-expansion
    *'${'*':-'*'${HOME}/Claude'*'}'*)      return 0 ;;
  esac
  # A synthetic fixture username in a /Users//home path is not a real leak.
  if printf '%s' "$line" | grep -qE "(/Users/|/home/)(${PATH_LEAK_FIXTURE_USERS})([^A-Za-z0-9]|$)"; then
    return 0
  fi
  return 1
}

# path_leak_scan_line <line> → 0 if the line carries a NON-EXEMPT leak, else 1.
# The single entry point both consumers call (so the match-then-exempt orchestration
# lives in one place, per the adversarial CD-2 simplification).
#
# ACTIVE classes: MACHINE + INSTANCE_REL — the machine-specific leak classes.
# RAWROOT ($HOME/Claude, ~/Claude) is intentionally EXCLUDED from the active scan:
# verified at Engineering (DevTest over the live script surface), $HOME/Claude is the
# PORTABLE canonical default — it resolves per-user, and appears legitimately in
# default-definitions (DEFAULT_WORKSPACE_ROOT="${HOME}/Claude"), --help text, and
# comments. Flagging it produces false positives, not leaks. The constant stays
# defined for a surface that explicitly opts to flag raw-root usage.
path_leak_scan_line() {
  local line="$1"
  if printf '%s' "$line" | grep -qE "${PATH_LEAK_RE_MACHINE}|${PATH_LEAK_RE_INSTANCE_REL}"; then
    path_leak_line_is_exempt "$line" && return 1
    return 0
  fi
  return 1
}

# --- self-test (run directly; not executed when sourced) ---
_path_leak_self_test() {
  local fails=0 n=0
  # expect_leak <desc> <line>
  expect_leak() { n=$((n+1)); if path_leak_scan_line "$2"; then echo "  ✓ FLAG: $1"; else echo "  ✗ MISS (should flag): $1 — [$2]"; fails=$((fails+1)); fi; }
  expect_clean() { n=$((n+1)); if path_leak_scan_line "$2"; then echo "  ✗ FALSE-POSITIVE (should pass): $1 — [$2]"; fails=$((fails+1)); else echo "  ✓ PASS: $1"; fi; }

  echo "MACHINE:"
  expect_leak  "real /Users/<op> path"            'see /Users/operator/Claude/x.md'
  expect_leak  "real /home/<op> path"             'cd /home/operator/work'
  expect_clean "fixture /Users/testuser"          'export H=/Users/testuser/Claude'
  expect_clean "fixture /Users/foo"               'p=/Users/foo/bar'
  expect_clean "fixture /home/user"               'd=/home/user/x'
  echo "RAWROOT (portable — NOT flagged; \$HOME/Claude is the canonical per-user default):"
  expect_clean "raw \$HOME/Claude (portable default)" 'p="$HOME/Claude/notes.md"'
  expect_clean "raw ~/Claude (portable)"              'see ~/Claude/notes'
  expect_clean "default-definition assignment"        'readonly DEFAULT_WORKSPACE_ROOT="${HOME}/Claude"'
  expect_clean "sanctioned \${VAR:-\$HOME/Claude}"    'f="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/x"'
  echo "INSTANCE_REL:"
  expect_leak  "bare personal/pmo-instance/"      'lives at personal/pmo-instance/roadmaps/skill-suite.md'
  expect_leak  "bare personal/analysis/"          'output to personal/analysis/run.md'
  expect_clean "personal opinion (near-miss)"     'in my personal opinion this is fine'
  expect_clean "personalization (near-miss)"      'see personalization settings'
  expect_clean "rooted /…/personal/pmo-instance"  'f="${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance"'
  echo "MARKER:"
  expect_clean "path-leak: allow marker"          'see /Users/operator/x  # path-leak: allow'
  echo ""
  if [ "$fails" -eq 0 ]; then echo "SELF-TEST PASS ($n cases)"; return 0; else echo "SELF-TEST FAIL ($fails/$n)"; return 1; fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-}" in
    --self-test) _path_leak_self_test ;;
    *) echo "path-leak-patterns.sh — source me, or run --self-test"; exit 0 ;;
  esac
fi
