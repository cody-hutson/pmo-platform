#!/usr/bin/env bash
# check-release-body-drift.sh — Release body-source-of-record drift check.
# Per release/references/standards/release-notes-standard.md § 5.1 / § 5.6.
#
# Asserts the §5.1 invariant for ONE release version: the published GitHub
# Release body equals the frontmatter-stripped in-repo source-of-record note —
#
#     gh release view <version> --json body  ==  strip_frontmatter(<note>)
#
# This is the SINGLE source of the body-equality logic. Both callers — the
# deploy.sh standing audit Check and automated-closeout.sh's post-emit
# verification phase — invoke this script rather than re-deriving the compare,
# so the §5.1 transform-equality lives in exactly one place (DRY; mirrors the
# State-1 byte-exact compare already at automated-closeout.sh phase_publish).
#
# DETECTIVE-ONLY. The check FLAGS drift; it NEVER re-emits or edits the Release
# (auto-remediation would raise an autonomy-tier decision — out of scope per the
# accepted Stage-5 design). Remediation is the operator's: re-emit via
# `gh release edit` per §5.6, or release-executor Mode F.
#
# gh-GUARDED. The compare requires a network read (`gh release view`). When gh is
# absent or unauthenticated the check resolves to N/A (exit 2) — NEVER FAIL —
# mirroring deploy.sh Check 32/39's gh-guard SKIP semantics so a disconnected
# `deploy.sh --check` run never red-fails on this check.
#
# The published-body compare normalizes a single trailing newline on both sides
# (GitHub strips a trailing newline from the Release body on round-trip); the
# in-repo note compare is otherwise byte-exact, the same posture as the shipped
# State-1 compare in automated-closeout.sh.
#
# Usage:
#   ./check-release-body-drift.sh <version>            # human result line + exit code
#   ./check-release-body-drift.sh <version> --quiet    # exit code only (no stdout)
#   ./check-release-body-drift.sh --self-test          # validate logic against a gh stub
#   ./check-release-body-drift.sh --help               # this help text
#
# Inputs:
#   <version>   release version key (e.g. v2.37) — resolves the note at
#               release/releases/notes/<version>_RELEASE_NOTES.md and the
#               published Release of the same tag.
#   REPO        optional owner/repo override (else resolved via gh repo view).
#   GH          optional gh path override (else resolved off the pinned PATH).
#
# Exit-code contract (consumed by both callers):
#   0  — MATCH    : published body == frontmatter-stripped note (no drift).
#   1  — DRIFT    : published body != stripped note (the v2.26-class defect: an
#                   ad-hoc / stale Release body diverged from the in-repo note);
#                   a diff-summary is printed to stderr.
#   2  — N/A      : gh absent / unauthenticated — body unreadable (never FAIL).
#   3  — MISSING  : note file absent, OR the published Release does not exist.
#
# Cutover (reflexive-pipeline-loop discipline): the standing deploy.sh Check that
# invokes this script ships warn-mode-initial and does not bind its own
# introducing release; this script itself is version-agnostic — the caller honors
# cutover. v2.37 (the introducing release) closes under pre-merge rules.

set -euo pipefail

# ─── Output helpers ──────────────────────────────────────────────────────────

QUIET=0
warn() { [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$*" >&2; }
say()  { [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$*"; }
die()  { printf 'check-release-body-drift: %s\n' "$*" >&2; exit 3; }

usage() {
  /usr/bin/sed -n '2,52p' "$0" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# ─── Resolve gh off the pinned PATH (mirror compute-release-velocity.sh) ─────
# Empty when not installed — the caller resolves to N/A (exit 2), never FAIL.

find_gh() {
  local c
  for c in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh "$HOME/.local/bin/gh"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  command -v gh 2>/dev/null || true
}

# ─── Transform: strip the YAML frontmatter (the §5.1 deterministic transform) ─
# Identical to the canonical_body derivation in automated-closeout.sh
# phase_publish_github_release: drop the leading `---`-fenced frontmatter block.

strip_frontmatter() {
  /usr/bin/sed '1,/^---$/d; 1,/^---$/d' "$1" 2>/dev/null
}

# ─── Normalize a single trailing newline (GitHub round-trip tolerance) ───────
# printf '%s' drops a trailing newline; we compare the trimmed forms so a lone
# trailing-newline delta does not warn spuriously (accepted-residual AR-1).

trim_trailing_newline() {
  printf '%s' "$1"
}

# ─── Repo + note resolution ──────────────────────────────────────────────────

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || printf '.')"
NOTES_DIR="${REPO_ROOT}/release/releases/notes"

# ─── Self-test (network-free; stubs gh on PATH) ──────────────────────────────

self_test() {
  local tmp failures=0
  tmp="$(/usr/bin/mktemp -d)"
  trap '/bin/rm -rf "$tmp"' EXIT

  # Fixture note (frontmatter + body) under a synthetic version.
  local note="$tmp/notes/v0.00_RELEASE_NOTES.md"
  /bin/mkdir -p "$tmp/notes"
  /bin/cat > "$note" <<'NOTE'
---
version: v0.00
status: test
---
# v0.00 — Self-test release

## 1. Summary
A synthetic note body used by the drift-check self-test.

## 6a. What changed
- **Thing.** It changed. ([example](https://example.com))
NOTE

  local body_expected
  body_expected="$(strip_frontmatter "$note")"

  # Stub gh: emits a canned `--json body` controlled by $STUB_BODY_FILE; honors
  # $STUB_GH_OFFLINE (auth fails) and $STUB_RELEASE_MISSING (view fails).
  local stubdir="$tmp/bin"
  /bin/mkdir -p "$stubdir"
  /bin/cat > "$stubdir/gh" <<'STUB'
#!/usr/bin/env bash
if [[ "${STUB_GH_OFFLINE:-0}" == "1" ]]; then
  # `gh auth status` and any view both fail (offline/unauth).
  exit 1
fi
case "$1 $2" in
  "auth status") exit 0 ;;
  "repo view")   printf 'acme/widget\n'; exit 0 ;;
esac
if [[ "$1" == "release" && "$2" == "view" ]]; then
  if [[ "${STUB_RELEASE_MISSING:-0}" == "1" ]]; then exit 1; fi
  # With --json body --jq .body, emit the staged body file.
  if [[ "${3:-}" == *"--json"* || " $* " == *" --json "* ]]; then
    /bin/cat "${STUB_BODY_FILE:?STUB_BODY_FILE unset}"
    exit 0
  fi
  exit 0   # bare existence probe
fi
exit 0
STUB
  /bin/chmod +x "$stubdir/gh"

  run_case() {
    # run_case <label> <expected-exit> <env-assignments...>
    local label="$1" expect="$2"; shift 2
    local rc=0
    ( export PATH="$stubdir:$PATH" GH="$stubdir/gh" REPO="acme/widget" \
             NOTES_DIR_OVERRIDE="$tmp/notes" "$@"
      exec "$0" v0.00 --quiet ) || rc=$?
    if [[ "$rc" -eq "$expect" ]]; then
      printf '  PASS  %-28s exit %s\n' "$label" "$rc" >&2
    else
      printf '  FAIL  %-28s exit %s (expected %s)\n' "$label" "$rc" "$expect" >&2
      failures=$((failures + 1))
    fi
  }

  # Case A — published body == stripped note → MATCH (exit 0)
  printf '%s' "$body_expected" > "$tmp/match.txt"
  run_case "A match (body==note)" 0 "STUB_BODY_FILE=$tmp/match.txt"

  # Case A2 — body == note but with a trailing newline → still MATCH (exit 0)
  printf '%s\n' "$body_expected" > "$tmp/match_nl.txt"
  run_case "A2 match (trailing \\n)" 0 "STUB_BODY_FILE=$tmp/match_nl.txt"

  # Case B — body has one altered line vs the note → DRIFT (exit 1)
  printf '%s' "$body_expected" | /usr/bin/sed 's/It changed\./It DID NOT change./' > "$tmp/drift.txt"
  run_case "B drift (altered line)" 1 "STUB_BODY_FILE=$tmp/drift.txt"

  # Case C — body is the note WITH frontmatter (transform not applied) → DRIFT (exit 1)
  /bin/cat "$note" > "$tmp/leak.txt"
  run_case "C drift (frontmatter leak)" 1 "STUB_BODY_FILE=$tmp/leak.txt"

  # Case D — gh offline/unauth → N/A (exit 2), never FAIL
  printf '%s' "$body_expected" > "$tmp/na.txt"
  run_case "D N/A (gh offline)" 2 "STUB_BODY_FILE=$tmp/na.txt" "STUB_GH_OFFLINE=1"

  # Case E — published Release missing → MISSING (exit 3)
  run_case "E missing (no Release)" 3 "STUB_BODY_FILE=$tmp/na.txt" "STUB_RELEASE_MISSING=1"

  # Case F — note file absent → MISSING (exit 3)
  ( export PATH="$stubdir:$PATH" GH="$stubdir/gh" REPO="acme/widget" \
           NOTES_DIR_OVERRIDE="$tmp/empty" STUB_BODY_FILE="$tmp/na.txt"
    /bin/mkdir -p "$tmp/empty"
    exec "$0" v0.00 --quiet ) && { printf '  FAIL  %-28s exit 0 (expected 3)\n' "F missing (no note)" >&2; failures=$((failures+1)); } || {
      rc=$?; if [[ "$rc" -eq 3 ]]; then printf '  PASS  %-28s exit 3\n' "F missing (no note)" >&2; else printf '  FAIL  %-28s exit %s (expected 3)\n' "F missing (no note)" "$rc" >&2; failures=$((failures+1)); fi; }

  if [[ "$failures" -eq 0 ]]; then
    printf 'check-release-body-drift self-test: ALL PASS\n' >&2
    exit 0
  fi
  printf 'check-release-body-drift self-test: %s FAILURE(S)\n' "$failures" >&2
  exit 1
}

# ─── Arg parse ───────────────────────────────────────────────────────────────

VERSION=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --self-test) self_test ;;
    --quiet) QUIET=1; shift ;;
    --help|-h) usage ;;
    -*) die "unknown flag: $1 (try --help)" ;;
    *) VERSION="$1"; shift ;;
  esac
done

[[ -n "$VERSION" ]] || die "required: <version> (e.g. v2.37)"

# NOTES_DIR_OVERRIDE is a test seam (self-test points it at a fixture dir).
NOTE_PATH="${NOTES_DIR_OVERRIDE:-$NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"

# ─── Resolve gh; N/A (exit 2) when absent ────────────────────────────────────

GH="${GH:-$(find_gh)}"
if [[ -z "$GH" || ! -x "$GH" ]]; then
  say "N/A: ${VERSION} — gh not on PATH; body-drift check skipped (never FAIL; mirrors Check 32/39 gh-guard)"
  exit 2
fi

# gh present but unauthenticated → N/A (distinguish from a real absent Release).
if ! "$GH" auth status >/dev/null 2>&1; then
  say "N/A: ${VERSION} — gh unauthenticated/offline; body-drift check skipped (never FAIL; mirrors Check 32/39 gh-guard)"
  exit 2
fi

# ─── MISSING (exit 3): note file absent ──────────────────────────────────────

if [[ ! -f "$NOTE_PATH" ]]; then
  die "${VERSION} — in-repo note not found at ${NOTE_PATH} (Stage 13 chore PR may not have landed)"
fi

# ─── Resolve repo (only after gh is confirmed usable) ────────────────────────

REPO="${REPO:-$("$GH" repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"

# ─── MISSING (exit 3): published Release absent ──────────────────────────────
# Distinguish absent-Release from gh-unreachable: auth already confirmed above,
# so a non-zero `release view` here means the Release object does not exist.

if ! "$GH" release view "$VERSION" ${REPO:+--repo "$REPO"} >/dev/null 2>&1; then
  die "${VERSION} — no published GitHub Release for this tag (Surface 1 not emitted; re-emit via Mode F or §5.6)"
fi

# ─── Compute equality: published body vs frontmatter-stripped note ───────────

PUBLISHED_BODY="$("$GH" release view "$VERSION" ${REPO:+--repo "$REPO"} --json body --jq .body 2>/dev/null || true)"
CANONICAL_BODY="$(strip_frontmatter "$NOTE_PATH")"

if [[ "$(trim_trailing_newline "$PUBLISHED_BODY")" == "$(trim_trailing_newline "$CANONICAL_BODY")" ]]; then
  say "OK: ${VERSION} — published Release body matches the frontmatter-stripped in-repo note (§5.1 invariant holds)"
  exit 0
fi

# ─── DRIFT (exit 1): bodies differ — flag, never re-emit ─────────────────────

warn "DRIFT: ${VERSION} — published Release body != frontmatter-stripped in-repo note (release-notes-standard.md §5.1)."
warn "       Detective-only: re-emit per §5.6 (gh release edit) or release-executor Mode F. This check does not re-emit."
if command -v diff >/dev/null 2>&1; then
  warn "       --- in-repo note (stripped) vs published Release body (first 20 diff lines) ---"
  diff <(printf '%s\n' "$CANONICAL_BODY") <(printf '%s\n' "$PUBLISHED_BODY") 2>/dev/null \
    | /usr/bin/head -20 | /usr/bin/sed 's/^/       /' >&2 || true
fi
exit 1
