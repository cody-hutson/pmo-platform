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

# path_leak_scan_file <path> → 0 clean · 1 at least one non-exempt leak · 2 unreadable.
# Whole-file arm over path_leak_scan_line, for a caller holding a rendered artifact
# rather than a stream of lines — the release-hub pre-spawn brief scan is the first.
# Every hit is printed (<path>:<line>: <first 100 chars>), not just the first: a caller
# repairing a rendered brief should not have to re-scan once per leak.
#
# Three exit values, not two, and the third is the load-bearing one. A scanner that
# reports CLEAN on a file it could not read is the broken-probe shape this platform
# rejects — failure-to-run and pass must never return the same code. Unreadable is
# therefore exit 2, distinct from both clean (0) and dirty (1).
path_leak_scan_file() {
  local f="${1:-}" n=0 hits=0 line
  if [ -z "$f" ] || [ ! -f "$f" ] || [ ! -r "$f" ]; then
    printf 'path-leak-patterns.sh: cannot read file for scan: %s\n' "${f:-<no path given>}" >&2
    return 2
  fi
  while IFS= read -r line || [ -n "$line" ]; do
    n=$((n+1))
    if path_leak_scan_line "$line"; then
      printf '%s:%s: %s\n' "$f" "$n" "$(printf '%s' "$line" | sed 's/^[[:space:]]*//' | cut -c1-100)"
      hits=$((hits+1))
    fi
  done < "$f"
  [ "$hits" -eq 0 ] && return 0
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

  # expect_scan <desc> <expected-rc> <file>
  expect_scan() {
    n=$((n+1)); local rc=0
    path_leak_scan_file "$3" >/dev/null 2>&1 || rc=$?
    if [ "$rc" = "$2" ]; then echo "  ✓ rc=$rc: $1"
    else echo "  ✗ rc=$rc (expected $2): $1"; fails=$((fails+1)); fi
  }
  echo "SCAN-FILE (whole-file arm; three distinct exit values):"
  local _sf; _sf="$(mktemp -d)"
  printf 'see core/hooks/block-gh-path-leak.sh\np="$HOME/Claude/pmo-platform"\n' > "${_sf}/clean.txt"
  printf 'context\nref /Users/operator/Claude/notes.md\n'                        > "${_sf}/dirty.txt"
  expect_scan "clean file -> 0"                 0 "${_sf}/clean.txt"
  expect_scan "dirty file -> 1"                 1 "${_sf}/dirty.txt"
  expect_scan "missing file -> 2 (never 0)"     2 "${_sf}/does-not-exist.txt"
  rm -rf "$_sf"

  echo ""
  if [ "$fails" -eq 0 ]; then echo "SELF-TEST PASS ($n cases)"; return 0; else echo "SELF-TEST FAIL ($fails/$n)"; return 1; fi
}

if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
  case "${1:-}" in
    --self-test)  _path_leak_self_test ;;
    --scan-file)  path_leak_scan_file "${2:-}" ;;
    "")           echo "path-leak-patterns.sh — source me, or run --self-test / --scan-file <path>"; exit 0 ;;
    # An UNKNOWN flag exits 2, never 0. A caller invoking --scan-file against a copy
    # predating that arm would otherwise get exit 0 — indistinguishable from a clean
    # scan (verified: the pre-change default arm returned 0 on a genuinely dirty file).
    # This closes the hazard for every copy at or after this version; it CANNOT repair
    # a copy that predates it, so a caller must also assert the arm exists before
    # trusting a verdict from a copy it did not ship with.
    *)            echo "path-leak-patterns.sh: unknown flag '$1' — expected --self-test or --scan-file <path>." >&2
                  echo "  A copy that does not recognize a flag is OLDER than its caller expects; treat its result as UNKNOWN, never as clean." >&2
                  exit 2 ;;
  esac
fi
