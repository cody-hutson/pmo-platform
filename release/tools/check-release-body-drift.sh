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
# CAPABILITY-GUARDED. The compare needs TWO capabilities: a network read
# (`gh release view` for the published body) and a git read (`git show
# origin/main:<note>` for the canonical note). When EITHER is absent — gh
# absent/unauthenticated, OR git unusable / origin/main unresolvable / a corrupt
# object — the check resolves to N/A (exit 2) — NEVER FAIL — mirroring deploy.sh
# Check 32/39's gh-guard SKIP semantics so a disconnected `deploy.sh --check` run
# never red-fails on this check. The N/A reason names the actual failing subsystem
# (gh vs git) on stderr UNCONDITIONALLY (survives --quiet), so a caller capturing
# 2>&1 never mis-reports a git failure as "gh offline".
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
# Exit-code contract (consumed by all callers):
#   0  — MATCH    : published body == frontmatter-stripped note (no drift).
#   1  — DRIFT    : published body != stripped note (the v2.26-class defect: an
#                   ad-hoc / stale Release body diverged from the in-repo note);
#                   a diff-summary is printed to stderr.
#   2  — N/A      : a CAPABILITY needed to compare is absent (never FAIL) — gh
#                   absent/unauthenticated (published body unreadable) OR git
#                   unusable / origin/main unresolvable / a corrupt object (the
#                   canonical note unreadable). The enum value is unchanged, but its
#                   MEANING now spans gh AND git; the N/A message names the failing
#                   subsystem on stderr unconditionally (see CAPABILITY-GUARDED).
#   3  — MISSING  : the note is absent at the canonical location (origin/main), OR
#                   the published Release does not exist. The exit-3 message
#                   distinguishes "not on origin/main but present in the working
#                   tree (Stage 13 chore PR has not landed)" from "not found
#                   anywhere".
#
# Canonical source of the note: origin/main. The compare reads the canonical note
# from origin/main (not the working tree) via
#   git -C "$REPO_ROOT" show "origin/main:release/releases/notes/<v>_RELEASE_NOTES.md"
# reusing the shipped origin/main note-read idiom in automated-closeout.sh. Basis:
# the operator-set acceptance criterion requires the compare read the canonical
# note from origin/main; release-notes-standard.md §5.1 establishes the in-repo
# source-of-record note as what the Release page is the rendered copy of.
# origin/main FRESHNESS is the CALLER's contract (accepted residual, and SHARPER
# now that both callers gate on this script's verdict): origin/main is a local
# cache, only as fresh as the last fetch. automated-closeout.sh's live post-emit
# consumer proves the note present on origin/main in an earlier phase on the
# idempotent-re-run path (so an absent note cannot fire there), but a present-but-
# content-stale origin/main can still yield a false DRIFT — and a false DRIFT is no
# longer a harmless warning: the standing deploy.sh Check now FAILS on it and the
# close phase BLOCKS on it. deploy.sh Check 47 still performs no fetch, by design.
# A self-fetch here would violate the detective-only posture (this script reads and
# reports; it does not mutate refs), so freshness remains the caller's
# responsibility: fetch origin immediately before an enforcing check run.
#
# Cutover: this script is version-agnostic and always reports the same verdict for
# the same inputs — the CALLER owns cutover scoping. Both callers now share one
# cutoff variable (RELEASE_BODY_DRIFT_CHECK_CUTOFF) with a committed default, so
# the standing check and the close-path phase cannot disagree about which releases
# the verdict is allowed to gate. This script's posture is unchanged by that: it
# still FLAGS and never re-emits, and it never decides whether a flag blocks.

set -euo pipefail

# ─── Output helpers ──────────────────────────────────────────────────────────

QUIET=0
warn() { [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$*" >&2; }
say()  { [[ "$QUIET" -eq 1 ]] || printf '%s\n' "$*"; }
die()  { printf 'check-release-body-drift: %s\n' "$*" >&2; exit 3; }
# na(): exit 2 (N/A — capability absent). Writes to stderr UNCONDITIONALLY (like
# die, NOT say) so the reason survives --quiet and reaches a caller's 2>&1 capture —
# the mechanism that lets a consumer report the real failing subsystem (gh vs git)
# instead of a hard-coded "gh offline".
na()   { printf 'check-release-body-drift: %s\n' "$*" >&2; exit 2; }

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

# "$@" (not "$1") so ONE transform serves both a file arg (fixture mode) and a
# stream (`git show … | strip_frontmatter`, canonical mode). With zero args sed
# reads stdin; safe under set -u. Keeps the §5.1 body-equality logic in one place.
strip_frontmatter() {
  /usr/bin/sed '1,/^---$/d; 1,/^---$/d' "$@" 2>/dev/null
}

# ─── Normalize a single trailing newline (GitHub round-trip tolerance) ───────
# printf '%s' drops a trailing newline; we compare the trimmed forms so a lone
# trailing-newline delta does not warn spuriously (accepted-residual AR-1).

trim_trailing_newline() {
  printf '%s' "$1"
}

# ─── Repo + note resolution ──────────────────────────────────────────────────
# REPO_ROOT — the ${REPO_ROOT:-…} form is a TEST-ONLY seam AND load-bearing for the
# self-test's process model: --self-test re-execs this script (exec "$0"), and the
# canonical-mode cases export REPO_ROOT to point at a bare-origin sandbox. An
# UNCONDITIONAL assignment here would clobber that exported value on re-exec,
# defeating the sandbox (and the case-H falsification). No production caller sets
# REPO_ROOT, so this resolves to the repo toplevel in normal use.
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || printf '.')}"
NOTES_DIR="${REPO_ROOT}/release/releases/notes"
NOTES_REL="release/releases/notes"   # repo-root-relative form, for `git show <ref>:<path>`
CANONICAL_REF="origin/main"          # the committed canonical note lives here (AC)

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

  # ── Canonical-mode cases (G/H/I + N1/N2 + git-guard) — the compare reads the note
  #    from origin/main, NOT the working tree. Hermetic via a bare-origin sandbox
  #    (the automated-closeout.sh Test 4g precedent). Cases A–F above stay fixture-
  #    mode (NOTES_DIR_OVERRIDE set) and byte-unchanged. git is REQUIRED here — the
  #    block self-skips when git is absent (mirrors Test 4g). ──
  local GIT=/usr/bin/git
  if [[ -x "$GIT" ]]; then
    local sbx="$tmp/sandbox" origin work cnote
    origin="$sbx/origin.git"; work="$sbx/work"
    /bin/mkdir -p "$work"
    $GIT init --bare -q "$origin" 2>/dev/null
    $GIT init -q -b main "$work" 2>/dev/null || { $GIT init -q "$work"; ( cd "$work" && $GIT checkout -q -b main 2>/dev/null ); }
    /bin/mkdir -p "$work/release/releases/notes"
    cnote="$work/release/releases/notes/v0.00_RELEASE_NOTES.md"
    /bin/cp "$note" "$cnote"                    # committed body == $body_expected == $tmp/match.txt
    ( cd "$work" \
      && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
      && $GIT -c user.email=t@t -c user.name=t commit -qm baseline >/dev/null 2>&1 \
      && $GIT remote add origin "$origin" >/dev/null 2>&1 \
      && $GIT push -q origin main >/dev/null 2>&1 \
      && $GIT fetch -q origin >/dev/null 2>&1 \
      && $GIT branch -q --set-upstream-to=origin/main main >/dev/null 2>&1 ) || true

    run_canon() {
      # run_canon <label> <expected-exit> <env...> — canonical mode (NO NOTES_DIR_OVERRIDE).
      local label="$1" expect="$2"; shift 2
      local rc=0
      ( unset NOTES_DIR_OVERRIDE
        export PATH="$stubdir:$PATH" GH="$stubdir/gh" REPO="acme/widget" "$@"
        exec "$0" v0.00 --quiet ) || rc=$?
      if [[ "$rc" -eq "$expect" ]]; then
        printf '  PASS  %-28s exit %s\n' "$label" "$rc" >&2
      else
        printf '  FAIL  %-28s exit %s (expected %s)\n' "$label" "$rc" "$expect" >&2
        failures=$((failures + 1))
      fi
    }

    # Case G — canonical MATCH: published == origin/main note, working tree clean.
    #   Doubles as a REPO_ROOT-seam integrity check: had the exported REPO_ROOT NOT
    #   survived the re-exec, the tool would read the REAL repo (no v0.00 note) and
    #   return 3, not 0 — so G passing proves the seam holds across `exec "$0"`.
    run_canon "G canon match (origin/main)" 0 "REPO_ROOT=$work" "STUB_BODY_FILE=$tmp/match.txt"

    # Case H — THE FALSIFICATION CASE. Edit the WORKING-TREE note so it diverges from
    # origin/main; keep the published body == the committed (origin/main) body.
    #   • FIXED  (reads origin/main): committed == published → MATCH (0). PASS.
    #   • BROKEN (reads the working tree): edited != published → DRIFT (1). FAIL.
    # The ONLY case that distinguishes the fix from the pre-fix working-tree read —
    # it FAILS against the pre-fix code and PASSES against this one.
    /usr/bin/sed -i.bak 's/It changed\./It WAS EDITED IN THE WORKING TREE./' "$cnote" 2>/dev/null; /bin/rm -f "$cnote.bak"
    run_canon "H reads origin/main not WT" 0 "REPO_ROOT=$work" "STUB_BODY_FILE=$tmp/match.txt"
    ( cd "$work" && $GIT checkout -q -- . 2>/dev/null )   # restore the working tree

    # Case I — canonical DRIFT: published != origin/main note (working tree clean).
    run_canon "I canon drift (vs origin/main)" 1 "REPO_ROOT=$work" "STUB_BODY_FILE=$tmp/drift.txt"

    # ── N1/N2: note absent from origin/main. Second sandbox — origin/main holds a
    #    placeholder but NO v0.00 note. ──
    local work2="$sbx/work2" origin2="$sbx/origin2.git" n2note
    /bin/mkdir -p "$work2"
    $GIT init --bare -q "$origin2" 2>/dev/null
    $GIT init -q -b main "$work2" 2>/dev/null || { $GIT init -q "$work2"; ( cd "$work2" && $GIT checkout -q -b main 2>/dev/null ); }
    /bin/mkdir -p "$work2/release/releases/notes"
    /usr/bin/printf 'placeholder\n' > "$work2/README.md"
    ( cd "$work2" \
      && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
      && $GIT -c user.email=t@t -c user.name=t commit -qm base >/dev/null 2>&1 \
      && $GIT remote add origin "$origin2" >/dev/null 2>&1 \
      && $GIT push -q origin main >/dev/null 2>&1 \
      && $GIT fetch -q origin >/dev/null 2>&1 \
      && $GIT branch -q --set-upstream-to=origin/main main >/dev/null 2>&1 ) || true

    # Case N1 — note absent from origin/main AND the working tree → MISSING (exit 3).
    run_canon "N1 missing (origin+WT)" 3 "REPO_ROOT=$work2" "STUB_BODY_FILE=$tmp/match.txt"

    # Case N2 — note present in the WORKING TREE but not on origin/main (chore PR not
    # landed) → MISSING (exit 3), with a message that distinguishes it from N1.
    n2note="$work2/release/releases/notes/v0.00_RELEASE_NOTES.md"
    /bin/cp "$note" "$n2note"                   # uncommitted — in WT, absent on origin/main
    run_canon "N2 missing (WT-only note)" 3 "REPO_ROOT=$work2" "STUB_BODY_FILE=$tmp/match.txt"
    local _n2_out
    _n2_out="$( ( unset NOTES_DIR_OVERRIDE; export PATH="$stubdir:$PATH" GH="$stubdir/gh" REPO="acme/widget" REPO_ROOT="$work2" STUB_BODY_FILE="$tmp/match.txt"; exec "$0" v0.00 --quiet ) 2>&1 || true )"
    if printf '%s' "$_n2_out" | /usr/bin/grep -q "present in the working tree"; then
      printf '  PASS  %-28s N2 message distinguishes N1\n' "N2 message" >&2
    else
      printf '  FAIL  %-28s N2 lacks WT hint: %s\n' "N2 message" "$_n2_out" >&2; failures=$((failures + 1))
    fi

    # Case K — git-guard: REPO_ROOT at a repo with NO origin/main ref (remote-less)
    # → N/A (exit 2), and the reason names git/origin-main, NOT "gh offline". Proves
    # a git capability absence is not mis-reported as a gh failure — and that no
    # DRIFT_CANONICAL_REF knob is needed to exercise the guard (a remote-less repo is
    # the fixture). gh is confirmed up (the stub's auth passes).
    local norepo="$sbx/norepo"
    /bin/mkdir -p "$norepo"; $GIT init -q "$norepo" 2>/dev/null
    run_canon "K git-guard (no origin/main)" 2 "REPO_ROOT=$norepo" "STUB_BODY_FILE=$tmp/match.txt"
    local _k_out
    _k_out="$( ( unset NOTES_DIR_OVERRIDE; export PATH="$stubdir:$PATH" GH="$stubdir/gh" REPO="acme/widget" REPO_ROOT="$norepo" STUB_BODY_FILE="$tmp/match.txt"; exec "$0" v0.00 --quiet ) 2>&1 || true )"
    if printf '%s' "$_k_out" | /usr/bin/grep -qi "origin/main" && ! printf '%s' "$_k_out" | /usr/bin/grep -qiE "gh offline|gh unauth"; then
      printf '  PASS  %-28s git N/A names git, not gh\n' "K diagnosis" >&2
    else
      printf '  FAIL  %-28s git-guard mis-diagnoses: %s\n' "K diagnosis" "$_k_out" >&2; failures=$((failures + 1))
    fi
  else
    printf '  SKIP  %-28s (git not available)\n' "G-K canonical-mode cases" >&2
  fi

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

# NOTES_DIR_OVERRIDE is a fixture-mode test seam (self-test points it at a fixture
# dir; setting it bypasses the origin/main canonical read). NO production caller
# sets it. NOTE_PATH is the working-tree path (fixture read + the N2 "present in
# working tree" probe); NOTE_REL is the repo-root-relative path for `git show`.
NOTE_PATH="${NOTES_DIR_OVERRIDE:-$NOTES_DIR}/${VERSION}_RELEASE_NOTES.md"
NOTE_REL="${NOTES_REL}/${VERSION}_RELEASE_NOTES.md"

# ─── Resolve gh; N/A (exit 2) when absent ────────────────────────────────────

GH="${GH:-$(find_gh)}"
if [[ -z "$GH" || ! -x "$GH" ]]; then
  na "N/A: ${VERSION} — gh not on PATH; body-drift check skipped (never FAIL; mirrors Check 32/39 gh-guard)"
fi

# gh present but unauthenticated → N/A (distinguish from a real absent Release).
if ! "$GH" auth status >/dev/null 2>&1; then
  na "N/A: ${VERSION} — gh unauthenticated/offline; body-drift check skipped (never FAIL; mirrors Check 32/39 gh-guard)"
fi

# ─── Resolve the canonical note body (fixture mode | origin/main) ────────────
# Ordering is load-bearing: fixture-mode → git-guard → note-existence → content.

if [[ -n "${NOTES_DIR_OVERRIDE:-}" ]]; then
  # ── Fixture mode (TEST ONLY): filesystem read — byte-identical to pre-change. ──
  if [[ ! -f "$NOTE_PATH" ]]; then
    die "${VERSION} — in-repo note not found at ${NOTE_PATH} (Stage 13 chore PR may not have landed)"
  fi
  CANONICAL_BODY="$(strip_frontmatter "$NOTE_PATH")"
else
  # ── Canonical mode: read the committed note from origin/main (AC; §5.1). ──
  # git-guard (mirrors the gh-guard): git unusable / the ref unresolvable is a
  # CAPABILITY absence, not an artifact absence ⇒ N/A (exit 2), never FAIL. This
  # probe is REQUIRED because `git show`/`cat-file -e` return 128 for BOTH an
  # absent ref AND an absent path — without a separate rev-parse the "no remote"
  # case (N3) would masquerade as a missing note (N2).
  if ! command -v git >/dev/null 2>&1 \
     || ! git -C "$REPO_ROOT" rev-parse --verify --quiet "$CANONICAL_REF" >/dev/null 2>&1; then
    na "${VERSION} — ${CANONICAL_REF} unresolvable (no git / no remote-tracking ref); canonical note unreadable at tool layer — N/A (never FAIL; a git capability absence, NOT gh)"
  fi

  # MISSING (exit 3): note absent AT origin/main. The ref resolved just above, so a
  # non-zero cat-file -e here is a genuinely-absent note (not an absent ref).
  # Distinguish N2 (present in the working tree — chore PR not landed) from N1.
  if ! git -C "$REPO_ROOT" cat-file -e "${CANONICAL_REF}:${NOTE_REL}" 2>/dev/null; then
    if [[ -f "$NOTE_PATH" ]]; then
      die "${VERSION} — note not on ${CANONICAL_REF} at ${NOTE_REL} (present in the working tree; the Stage 13 chore PR has not landed). Canonical source is ${CANONICAL_REF}."
    fi
    die "${VERSION} — note not found on ${CANONICAL_REF} or in the working tree at ${NOTE_REL}"
  fi

  # Content read — rc-GUARDED. An unguarded `git show` in $() aborts the whole
  # script under `set -euo pipefail` (rc=128 propagates through the pipe via
  # pipefail), which would fall through to every consumer's `*`→finding branch.
  # After a confirmed existence, a non-zero here means a corrupt object / partial
  # clone ⇒ N/A (never a false OK).
  _cbody_rc=0
  CANONICAL_BODY="$(git -C "$REPO_ROOT" show "${CANONICAL_REF}:${NOTE_REL}" 2>/dev/null | strip_frontmatter)" || _cbody_rc=$?
  if [[ "$_cbody_rc" -ne 0 ]]; then
    na "${VERSION} — reading ${CANONICAL_REF}:${NOTE_REL} failed (rc=${_cbody_rc}; corrupt object / partial clone); canonical note unreadable at tool layer — N/A (never FAIL; a git capability absence, NOT gh)"
  fi
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
# CANONICAL_BODY was resolved above (origin/main in canonical mode, fixture file in
# fixture mode) — do not re-read the working tree here.

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
