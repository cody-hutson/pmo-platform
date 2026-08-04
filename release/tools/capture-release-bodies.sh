#!/usr/bin/env bash
# capture-release-bodies.sh — pre-overwrite capture of published GitHub Release bodies.
#
# PURPOSE. Before a Release body is re-emitted (release-notes-standard.md § 5.6),
# the body currently published is captured to a durable, committed artifact. The
# prior public body is NOT recoverable from GitHub after an edit — the platform
# keeps no version history for a Release body — so this capture is the ONLY record
# of what the public surface said before the repair.
#
# READ-ONLY ON GITHUB. This tool issues `gh release view` and nothing else. It
# NEVER calls `gh release edit`, `gh release create`, or `gh release delete`.
#
# ─── THE OVERWRITE REFUSAL IS THE POINT ─────────────────────────────────────────
# Re-running this tool AFTER a re-emit would replace the pre-repair capture with
# the post-repair body, silently destroying the only evidence the capture exists to
# preserve — and leaving an artifact that still LOOKS complete. The tool therefore
# refuses to write over an existing capture at two levels:
#
#   (1) DIRECTORY level — if the destination directory already contains any
#       *.published.txt, the run aborts before contacting GitHub at all.
#   (2) FILE level — each per-version write is guarded by its own existence test,
#       so a partially-populated directory cannot be silently topped up with
#       post-repair content for the versions that are missing.
#
# There is no --force. A genuinely new capture goes in a NEW dated directory; that
# is a one-word change at the call site and it preserves the earlier capture, which
# is always the correct outcome. An operator who believes they need to overwrite a
# capture is, in every case we can construct, actually asking for a second capture.
#
# Usage:
#   ./capture-release-bodies.sh <dest-dir> <version> [<version> ...]
#   ./capture-release-bodies.sh --self-test
#
# Outputs, in <dest-dir>:
#   <version>.published.txt   raw published body, byte-for-byte as GitHub returns it
#   MANIFEST.md              one row per version: SHA-256, byte + line counts, the
#                            drift verdict at capture time, and the Release metadata
#                            (title / createdAt / publishedAt / targetCommitish)
#                            that the re-emit does not touch but cannot restore.
#
# Exit codes:
#   0  all requested versions captured
#   1  refused — destination already holds a capture (nothing written, nothing read)
#   2  a capability is missing (gh absent / unauthenticated)
#   3  one or more versions could not be read from GitHub (partial capture; the
#      MANIFEST records which, and the tool exits non-zero so a caller cannot
#      mistake a partial capture for a complete one)
set -uo pipefail

SELF="$(basename "$0")"

# ─── sha256 shim (macOS shasum vs GNU sha256sum) ────────────────────────────────
_sha256() {
  if command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  elif command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else echo "UNAVAILABLE"; fi
}

# _dest_has_capture <dir> — 0 when the directory already holds a capture.
# Defined BEFORE the self-test, which exercises it directly.
_dest_has_capture() {
  local d="$1"
  [[ -d "$d" ]] || return 1
  compgen -G "$d"/*.published.txt >/dev/null 2>&1
}

# ─── self-test: proves the refusal actually refuses ─────────────────────────────
# Both arms matter. "Populated is refused" alone is satisfiable by a guard that
# refuses EVERYTHING — which would be a tool that never captures anything. The
# empty-directory arm is what separates a working guard from a broken one.
if [[ "${1:-}" == "--self-test" ]]; then
  t="$(mktemp -d)"; rc_all=0
  # Arm 1 (specificity): an empty destination must be ACCEPTED.
  if _dest_has_capture "$t"; then echo "FAIL: guard fired on an empty directory"; rc_all=1
  else echo "PASS: empty destination accepted (guard does not refuse everything)"; fi
  # Arm 2 (sensitivity): a destination already holding a capture must be REFUSED.
  printf 'x' >"$t/v1.00.published.txt"
  if _dest_has_capture "$t"; then echo "PASS: populated destination refused"
  else echo "FAIL: populated destination NOT refused"; rc_all=1; fi
  # Arm 3: end-to-end — the real entry point must exit 1 and write nothing.
  before="$(ls -1 "$t" | wc -l | tr -d ' ')"
  out="$("$0" "$t" v9.99 2>&1)"; e=$?
  after="$(ls -1 "$t" | wc -l | tr -d ' ')"
  if [[ $e -eq 1 && "$before" == "$after" ]]; then
    echo "PASS: end-to-end refusal exits 1 and writes nothing ($before file(s) before and after)"
  else
    echo "FAIL: end-to-end refusal exit=$e, files $before -> $after"; rc_all=1
  fi
  rm -rf "$t"; exit "$rc_all"
fi

DEST="${1:-}"; shift || true
if [[ -z "$DEST" || $# -eq 0 ]]; then
  echo "usage: $SELF <dest-dir> <version> [<version> ...]" >&2
  exit 1
fi

# ── GUARD (1): directory level. Checked BEFORE any network read, so a refused run
#    is inert in every respect.
if _dest_has_capture "$DEST"; then
  {
    echo "REFUSED: $DEST already contains a capture (*.published.txt)."
    echo ""
    echo "Overwriting it would replace the PRE-repair public body with whatever is"
    echo "published now — destroying the only record of the prior public text."
    echo "If you need a second capture, pass a NEW dated directory."
  } >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo "N/A: gh is absent or unauthenticated — cannot read published bodies." >&2
  exit 2
fi

mkdir -p "$DEST"
: >"$DEST/SHA256SUMS"
STAMP="$(date -u '+%Y-%m-%dT%H:%M:%SZ')"
DRIFT_TOOL="release/tools/check-release-body-drift.sh"

MAN="$DEST/MANIFEST.md"
{
  echo "# Release-body pre-capture manifest"
  echo ""
  echo "Captured (UTC): \`$STAMP\`"
  echo ""
  echo "Raw published GitHub Release bodies, captured **before** the § 5.6 re-emit."
  echo "GitHub keeps no version history for a Release body, so after a re-emit these"
  echo "files are the only record of what each public page said beforehand."
  echo ""
  echo "\`<version>.published.txt\` is the body **byte-for-byte as GitHub returned it**"
  echo "(\`gh release view <v> --json body --jq .body\`) — no transform, no trimming."
  echo "Integrity is verified against the companion \`SHA256SUMS\` (see § Verification)."
  echo ""
  echo "The re-emit changes **only** the body. Title / createdAt / publishedAt /"
  echo "target are recorded anyway: they cost nothing now and are unrecoverable later."
  echo ""
  echo "| Version | Bytes | Lines | SHA-256 | Drift at capture | Title | Created (UTC) | Published (UTC) | Target |"
  echo "|---|---:|---:|---|---|---|---|---|---|"
} >"$MAN"

rc_final=0
for V in "$@"; do
  OUT="$DEST/${V}.published.txt"

  # ── GUARD (2): file level.
  if [[ -e "$OUT" ]]; then
    echo "REFUSED: $OUT already exists — refusing to overwrite a capture." >&2
    rc_final=3
    continue
  fi

  if ! gh release view "$V" >/dev/null 2>&1; then
    echo "MISSING: no published Release for $V — nothing to capture." >&2
    printf '| `%s` | — | — | — | NO PUBLISHED RELEASE | — | — | — | — |\n' "$V" >>"$MAN"
    rc_final=3
    continue
  fi

  # Raw body, byte-for-byte. `--jq .body` is the same read the drift tool performs.
  if ! gh release view "$V" --json body --jq .body >"$OUT" 2>/dev/null; then
    echo "ERROR: failed to read the published body for $V." >&2
    rm -f "$OUT"
    printf '| `%s` | — | — | — | READ FAILED | — | — | — | — |\n' "$V" >>"$MAN"
    rc_final=3
    continue
  fi

  BYTES="$(wc -c <"$OUT" | tr -d ' ')"
  LINES="$(wc -l <"$OUT" | tr -d ' ')"
  SHA="$(_sha256 "$OUT")"

  META="$(gh release view "$V" --json name,createdAt,publishedAt,targetCommitish \
            --jq '[.name, .createdAt, .publishedAt, .targetCommitish] | @tsv' 2>/dev/null)"
  NAME="$(printf '%s' "$META" | cut -f1)"
  CREATED="$(printf '%s' "$META" | cut -f2)"
  PUBLISHED="$(printf '%s' "$META" | cut -f3)"
  TARGET="$(printf '%s' "$META" | cut -f4)"
  NAME="${NAME//|/\\|}"

  DRIFT="not evaluated"
  if [[ -x "$DRIFT_TOOL" ]]; then
    d=0; "$DRIFT_TOOL" "$V" --quiet >/dev/null 2>&1 || d=$?
    case "$d" in
      0) DRIFT="MATCH (exit 0)" ;;
      1) DRIFT="**DRIFT** (exit 1)" ;;
      2) DRIFT="N/A (exit 2)" ;;
      3) DRIFT="MISSING (exit 3)" ;;
      *) DRIFT="unexpected exit $d" ;;
    esac
  fi

  printf '| `%s` | %s | %s | `%s` | %s | %s | %s | %s | `%s` |\n' \
    "$V" "$BYTES" "$LINES" "$SHA" "$DRIFT" "$NAME" "$CREATED" "$PUBLISHED" "$TARGET" >>"$MAN"
  # Canonical `<sha>  <filename>` line — consumed directly by `shasum -a 256 -c`.
  printf '%s  %s\n' "$SHA" "${V}.published.txt" >>"$DEST/SHA256SUMS"
  echo "captured $V — $BYTES bytes, $DRIFT"
done

{
  echo ""
  echo "## Verification"
  echo ""
  echo "\`\`\`bash"
  echo "cd $DEST && shasum -a 256 -c SHA256SUMS"
  echo "\`\`\`"
  echo ""
  echo "\`SHA256SUMS\` is emitted in the canonical \`<sha>  <filename>\` format, so"
  echo "verification is a single \`shasum -c\` with no parsing step. (An earlier"
  echo "revision of this tool told the reader to re-derive the digests by"
  echo "field-splitting the table above on backticks; that snippet silently picked"
  echo "up the **Target** column instead of the SHA column and reported spurious"
  echo "mismatches. A verification command that does not verify is worse than none,"
  echo "because it reads as evidence.)"
  echo ""
  echo "## Provenance"
  echo ""
  echo "Written by \`release/tools/capture-release-bodies.sh\`, which **refuses to"
  echo "overwrite an existing capture** at both the directory and the file level."
  echo "A re-run after a re-emit would otherwise replace these pre-repair bodies with"
  echo "post-repair ones and leave an artifact that still looked complete."
} >>"$MAN"

exit "$rc_final"
