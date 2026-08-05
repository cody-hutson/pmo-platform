#!/usr/bin/env bash
# reemit-release-bodies.sh — re-emit published GitHub Release bodies from their
# canonical in-repo notes, per release-notes-standard.md § 5.6 step 2.
#
# ─── THIS TOOL MUTATES PUBLIC CONTENT AND THE MUTATION IS IRREVERSIBLE ──────────
# `gh release edit --notes` overwrites the Release body. GitHub keeps no version
# history for a Release body, so the text that was published before the edit is
# gone the moment the edit lands. That is why:
#
#   * DRY-RUN IS THE DEFAULT. Without --execute this tool contacts GitHub only to
#     READ, and prints exactly what it would do. An accidental invocation cannot
#     mutate anything.
#   * A CAPTURE IS A HARD PRECONDITION. Each version is refused unless
#     <capture-dir>/<version>.published.txt exists and is non-empty. The capture is
#     produced by release/tools/capture-release-bodies.sh and must already be
#     committed and merged to main — a capture living only in a working tree is
#     not durable, and the whole point is durability.
#
# ─── WHY THIS IS SAFE TO RESUME ────────────────────────────────────────────────
# The operation is PER-VERSION ATOMIC. There is no cross-version transaction and
# no ordering dependency between versions, so a failure at version N leaves
# 1..N-1 repaired-and-verified, N failed, and N+1..last untouched. Recovery is
# simply: re-run. No rollback is needed and none is possible.
#
# THE DRIFT CHECK IS THE RESUME LEDGER. Before emitting, each version is tested
# with check-release-body-drift.sh: exit 0 (MATCH) => already repaired, SKIP.
# There is no progress file, so there is no progress file to desync from reality.
#
# ─── THE EMIT INVOCATION ───────────────────────────────────────────────────────
#     gh release edit "$V" --notes "$BODY"
# where BODY is the frontmatter-stripped note. NEVER --notes-file: that publishes
# the YAML frontmatter as raw text (§ 5.1), and it is the defect that produced two
# of the bodies this tool exists to repair.
#
# The note is read from **origin/main**, which is the same ref the verifier reads.
# Emitting from the working tree would let a locally-modified note produce a body
# that the verifier immediately reports as drifted.
#
# Usage:
#   ./reemit-release-bodies.sh <capture-dir> <version> [<version> ...]             # dry-run
#   ./reemit-release-bodies.sh --execute <capture-dir> <version> [<version> ...]   # MUTATES
#
# Exit codes:
#   0  every requested version ends VERIFIED at MATCH
#   1  at least one version failed (emit error, or still drifted after emit)
#   2  a capability is missing (gh absent/unauthenticated, origin/main unreadable)
#   3  refused — a required pre-overwrite capture is absent or empty
set -uo pipefail

EXECUTE=0
if [[ "${1:-}" == "--execute" ]]; then EXECUTE=1; shift; fi

CAPTURE_DIR="${1:-}"; shift || true
if [[ -z "$CAPTURE_DIR" || $# -eq 0 ]]; then
  echo "usage: $(basename "$0") [--execute] <capture-dir> <version> [<version> ...]" >&2
  exit 1
fi

NOTES_DIR="release/releases/notes"
DRIFT_TOOL="release/tools/check-release-body-drift.sh"

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo "N/A: gh is absent or unauthenticated." >&2
  exit 2
fi
if ! git rev-parse --verify origin/main >/dev/null 2>&1; then
  echo "N/A: origin/main is unreadable — run 'git fetch origin main' first." >&2
  exit 2
fi

if [[ $EXECUTE -eq 1 ]]; then
  echo "*** EXECUTE MODE — published Release bodies WILL be overwritten. IRREVERSIBLE. ***"
else
  echo "--- DRY RUN (no --execute) — GitHub is READ but never written. ---"
fi
echo "capture dir: $CAPTURE_DIR"
echo "note source: origin/main:$NOTES_DIR/<version>_RELEASE_NOTES.md"
echo

rc_final=0
for V in "$@"; do
  echo "=== $V ==="

  # ── PRECONDITION 1: the pre-overwrite capture must exist and be non-empty.
  CAP="$CAPTURE_DIR/${V}.published.txt"
  if [[ ! -s "$CAP" ]]; then
    echo "  REFUSED: no non-empty capture at $CAP — refusing to overwrite a public"
    echo "           body whose prior text is not recorded anywhere."
    rc_final=3
    continue
  fi
  echo "  capture: OK ($(wc -c <"$CAP" | tr -d ' ') bytes)"

  # ── PRECONDITION 2: resume ledger. Already MATCH => nothing to do.
  d=0; "$DRIFT_TOOL" "$V" --quiet >/dev/null 2>&1 || d=$?
  case "$d" in
    0) echo "  SKIP: already MATCH (exit 0) — no emit needed."; continue ;;
    1) echo "  state: DRIFT (exit 1) — emit required." ;;
    2) echo "  ABORT: capability N/A (exit 2) — cannot verify, so will not emit."; rc_final=1; continue ;;
    3) echo "  ABORT: note or Release missing (exit 3) — nothing to emit from."; rc_final=1; continue ;;
    *) echo "  ABORT: unexpected drift-tool exit $d."; rc_final=1; continue ;;
  esac

  # ── Compute the §5.1 body from origin/main. Braced ref (${REF}:path) because a
  #    bare "$REF:path" is mangled by zsh's colon modifier under some invocations.
  REF="origin/main"
  RAW="$(git show "${REF}:${NOTES_DIR}/${V}_RELEASE_NOTES.md" 2>/dev/null)" || RAW=""
  if [[ -z "$RAW" ]]; then
    echo "  ABORT: canonical note unreadable at ${REF}:${NOTES_DIR}/${V}_RELEASE_NOTES.md"
    rc_final=1
    continue
  fi
  BODY="$(printf '%s\n' "$RAW" | sed '1,/^---$/d; 1,/^---$/d')"
  if [[ -z "$BODY" ]]; then
    echo "  ABORT: frontmatter strip produced an EMPTY body — refusing to publish nothing."
    rc_final=1
    continue
  fi
  echo "  body:   $(printf '%s' "$BODY" | wc -c | tr -d ' ') bytes after frontmatter strip"

  if [[ $EXECUTE -eq 0 ]]; then
    echo "  WOULD RUN: gh release edit \"$V\" --notes \"\$BODY\"   (dry run — not executed)"
    continue
  fi

  # ── THE MUTATION.
  if ! gh release edit "$V" --notes "$BODY"; then
    echo "  FAIL: gh release edit returned non-zero for $V."
    echo "        Versions before this one are repaired and verified; later versions are"
    echo "        untouched. Re-run this tool to resume — it will skip what is already MATCH."
    rc_final=1
    continue
  fi

  # ── VERIFY AFTER EVERY SINGLE EDIT, not in a batch at the end.
  d2=0; "$DRIFT_TOOL" "$V" --quiet >/dev/null 2>&1 || d2=$?
  if [[ $d2 -eq 0 ]]; then
    echo "  VERIFIED: MATCH (exit 0)."
  else
    echo "  FAIL: still not MATCH after emit (drift-tool exit $d2). STOPPING."
    echo "        Do not continue to later versions until this is understood."
    rc_final=1
    break
  fi
done

echo
if [[ $rc_final -eq 0 ]]; then
  if [[ $EXECUTE -eq 1 ]]; then echo "All requested versions VERIFIED at MATCH."
  else echo "Dry run complete — nothing was written."; fi
else
  echo "Completed with failures (exit $rc_final). Re-run to resume; MATCHed versions are skipped."
fi
exit "$rc_final"
