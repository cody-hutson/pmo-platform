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
# ─── NOTE RESOLUTION IS LAYOUT-INDEPENDENT ─────────────────────────────────────
# The note is resolved by FILENAME (<version>_RELEASE_NOTES.md) anywhere under
# release/releases/notes/ — the flat path first, then RECURSIVELY through any
# subfolder. The corpus foldered its notes into major-version buckets
# (notes/v1|v2|v3/… plus _unversioned/) per plans/README.md (#230, v3.54), so a
# flat-path-only resolve reported a FABRICATED "canonical note unreadable" for
# every foldered note. That is exactly what stopped the v4.12 Part A payload: of
# the 29 in-scope versions, 18 are foldered (notes/v1/ ×10, notes/v2/ ×8) and all
# 18 aborted, while the 11 flat v3.* resolved fine.
#
# This resolver is a PORT of the one already shipped in the sibling verifier
# check-release-body-drift.sh (`resolve_note_ref` / `resolve_note_worktree`,
# commit afb651e2) — deliberately the same convention rather than a second one, so
# the emitter and the verifier can never disagree about which file IS the note.
# Discovery keys on the _RELEASE_NOTES.md suffix — the corpus's own type
# discriminator — and NO bucket literal ("v1"/"v2"/"v3"/"_unversioned") appears in
# the pattern, so it holds under any layout and needs no edit as the corpus folds
# further. Resolution is deterministic: the flat path wins, else the
# lexicographically-first recursive hit; an ambiguity is ANNOUNCED on stderr
# rather than silently resolved. A note that exists NOWHERE still aborts — the
# resolver never invents a path.
#
# Usage:
#   ./reemit-release-bodies.sh <capture-dir> <version> [<version> ...]             # dry-run
#   ./reemit-release-bodies.sh --execute <capture-dir> <version> [<version> ...]   # MUTATES
#   ./reemit-release-bodies.sh --self-test                                         # hermetic; no network
#
# Exit codes:
#   0  every requested version ends VERIFIED at MATCH
#   1  at least one version failed (emit error, or still drifted after emit)
#   2  a capability is missing (gh absent/unauthenticated, origin/main unreadable)
#   3  refused — a required pre-overwrite capture is absent or empty
set -uo pipefail

# ─── Config ──────────────────────────────────────────────────────────────────
# NOTES_DIR is the repo-root-relative form (the sibling verifier calls this
# NOTES_REL) — it is what `git show <ref>:<path>` and `git ls-tree` want.
NOTES_DIR="release/releases/notes"

# REPO_ROOT — the ${REPO_ROOT:-…} form is a TEST-ONLY seam AND load-bearing for the
# self-test's process model: --self-test re-execs this script (exec "$0") with
# REPO_ROOT exported to a bare-origin sandbox. An UNCONDITIONAL assignment here
# would clobber that exported value on re-exec. No production caller sets it, so
# it resolves to the repo toplevel in normal use. Mirrors the same seam in
# check-release-body-drift.sh.
REPO_ROOT="${REPO_ROOT:-$(git rev-parse --show-toplevel 2>/dev/null || printf '.')}"

# DRIFT_TOOL — TEST-ONLY override seam (the self-test points it at a stub so the
# suite is hermetic). No production caller sets it; the default is the shipped
# verifier, resolved relative to the invocation cwd as before.
DRIFT_TOOL="${DRIFT_TOOL:-release/tools/check-release-body-drift.sh}"

REF="origin/main"

# ─── Note resolution: flat path first, then ANY subfolder ────────────────────
# PORTED VERBATIM IN SHAPE from check-release-body-drift.sh (commit afb651e2) —
# same precedence, same determinism, same ambiguity handling. See the NOTE
# RESOLUTION IS LAYOUT-INDEPENDENT block in the header for why.
#
# Both print the resolved path on stdout and return 0; they print nothing and
# return 1 when the note exists nowhere — the caller turns THAT into an ABORT, so
# a foldered note can no longer masquerade as an unreadable one.

# Escape the dots in a version key so it cannot regex-match a neighbour
# ("v2.10" must not match "v2X10"). find(1) -name is glob, where "." is already
# literal, so only the grep(1) arm needs this.
_re_escape_version() { printf '%s' "${1//./\\.}"; }

# _warn_ambiguous <version> <chosen> <count> — an ambiguity is ANNOUNCED, never
# silently resolved. Unreachable on today's corpus (one note per version);
# present so a future duplicate surfaces instead of hiding behind the tie-break.
_warn_ambiguous() {
  [[ "$3" -gt 1 ]] || return 0
  printf 'reemit-release-bodies: %s — %s note files match this version; using %s (resolution is lexicographic; the corpus should hold one note per version)\n' \
    "$1" "$3" "$2" >&2
}

# resolve_note_ref <ref> <version> — git-ref surface. Prints the repo-root-relative
# path AT <ref>. REQUIRES a resolvable <ref>: call only AFTER the git-guard, or an
# unresolvable ref would read as an absent note.
resolve_note_ref() {
  local ref="$1" version="$2" flat hits count vesc
  flat="${NOTES_DIR}/${version}_RELEASE_NOTES.md"
  # Brace the ref:path form — an unbraced "$ref:$path" is eaten as a colon
  # modifier by some shells; the rest of this script braces it for the same reason.
  if git -C "$REPO_ROOT" cat-file -e "${ref}:${flat}" 2>/dev/null; then
    printf '%s' "$flat"; return 0
  fi
  vesc="$(_re_escape_version "$version")"
  # `ls-tree -r` walks the notes subtree at the REF (not the working tree). The
  # trailing `|| true` covers grep's rc=1 on no-match, which pipefail would
  # otherwise propagate out of the $().
  hits="$(git -C "$REPO_ROOT" ls-tree -r --name-only "$ref" -- "$NOTES_DIR" 2>/dev/null \
          | /usr/bin/grep -E "/${vesc}_RELEASE_NOTES\.md$" | LC_ALL=C sort || true)"
  [[ -n "$hits" ]] || return 1
  count="$(printf '%s\n' "$hits" | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
  _warn_ambiguous "$version" "$(printf '%s' "$hits" | /usr/bin/head -1)" "$count"
  printf '%s' "$hits" | /usr/bin/head -1
}

# resolve_note_worktree <dir> <version> — filesystem surface. Used ONLY to sharpen
# the ABORT diagnostic: it distinguishes "note is in the working tree but the
# chore PR has not landed on origin/main" from "note exists nowhere". It MUST
# recurse too, or a foldered working-tree-only note reports the wrong diagnosis.
resolve_note_worktree() {
  local dir="$1" version="$2" flat hits count
  flat="${dir}/${version}_RELEASE_NOTES.md"
  if [[ -f "$flat" ]]; then printf '%s' "$flat"; return 0; fi
  [[ -d "$dir" ]] || return 1
  hits="$(/usr/bin/find "$dir" -type f -name "${version}_RELEASE_NOTES.md" 2>/dev/null | LC_ALL=C sort || true)"
  [[ -n "$hits" ]] || return 1
  count="$(printf '%s\n' "$hits" | /usr/bin/wc -l | /usr/bin/tr -d ' ')"
  _warn_ambiguous "$version" "$(printf '%s' "$hits" | /usr/bin/head -1)" "$count"
  printf '%s' "$hits" | /usr/bin/head -1
}

# ─── Self-test (hermetic: stubs gh AND the drift tool; never touches the network) ─
# DRY-RUN ONLY by construction — every case invokes this script WITHOUT --execute,
# so the suite can never mutate a published Release. The drift stub always reports
# DRIFT (exit 1) so control reaches the note-resolution step under test.
#
# Case L is the direct analogue of check-release-body-drift.sh's Case L: the note is
# committed to origin/main ONLY inside a major-version bucket — the shape of all 18
# foldered notes in the live Part A scope.

self_test() {
  local tmp failures=0 GIT=/usr/bin/git
  tmp="$(/usr/bin/mktemp -d)"
  trap '/bin/rm -rf "$tmp"' EXIT

  if [[ ! -x "$GIT" ]]; then
    printf '  SKIP  self-test (git not available)\n' >&2; exit 0
  fi

  # ── Stubs: gh (auth passes; nothing else is reached in dry run) and the drift
  #    tool (always DRIFT ⇒ exit 1 ⇒ "emit required").
  local stubdir="$tmp/bin"
  /bin/mkdir -p "$stubdir"
  /bin/cat > "$stubdir/gh" <<'STUB'
#!/usr/bin/env bash
case "$1 $2" in
  "auth status") exit 0 ;;
  "repo view")   printf 'acme/widget\n'; exit 0 ;;
esac
exit 0
STUB
  /bin/chmod +x "$stubdir/gh"
  /bin/cat > "$tmp/drift-stub.sh" <<'STUB'
#!/usr/bin/env bash
exit 1   # always DRIFT — emit required
STUB
  /bin/chmod +x "$tmp/drift-stub.sh"

  # ── Sandbox repo with a bare origin, so origin/main is a real resolvable ref.
  local work="$tmp/work" origin="$tmp/origin.git" ndir
  /bin/mkdir -p "$work"
  $GIT init --bare -q "$origin" 2>/dev/null
  $GIT init -q -b main "$work" 2>/dev/null || { $GIT init -q "$work"; ( cd "$work" && $GIT checkout -q -b main 2>/dev/null ); }
  ndir="$work/release/releases/notes"
  /bin/mkdir -p "$ndir/v0"

  # Flat note (v0.00) and FOLDERED note (v0.02, present at NO other path).
  /bin/cat > "$ndir/v0.00_RELEASE_NOTES.md" <<'NOTE'
---
version: v0.00
status: test
---
# v0.00 — Self-test release

## 1. Summary
A synthetic note body used by the re-emit self-test.
NOTE
  /usr/bin/sed 's/v0\.00/v0.02/g' "$ndir/v0.00_RELEASE_NOTES.md" > "$ndir/v0/v0.02_RELEASE_NOTES.md"

  ( cd "$work" \
    && $GIT -c user.email=t@t -c user.name=t add -A >/dev/null 2>&1 \
    && $GIT -c user.email=t@t -c user.name=t commit -qm baseline >/dev/null 2>&1 \
    && $GIT remote add origin "$origin" >/dev/null 2>&1 \
    && $GIT push -q origin main >/dev/null 2>&1 \
    && $GIT fetch -q origin >/dev/null 2>&1 ) || true

  # Working-tree-ONLY note (v0.03): never committed, so it is absent on origin/main.
  /usr/bin/sed 's/v0\.00/v0.03/g' "$ndir/v0.00_RELEASE_NOTES.md" > "$ndir/v0/v0.03_RELEASE_NOTES.md"

  # Captures — PRECONDITION 1. Present for every version the cases exercise EXCEPT
  # the one that deliberately tests the refusal.
  local capdir="$tmp/captures" v
  /bin/mkdir -p "$capdir"
  for v in v0.00 v0.02 v0.03 v0.99; do printf 'prior published body for %s\n' "$v" > "$capdir/${v}.published.txt"; done

  # run_case <label> <version> <expected-exit> <grep-must-match> [grep-must-NOT-match]
  run_case() {
    local label="$1" version="$2" expect="$3" must="$4" mustnot="${5:-}" out rc=0
    out="$( ( export PATH="$stubdir:$PATH" REPO_ROOT="$work" DRIFT_TOOL="$tmp/drift-stub.sh"
              exec "$0" "$capdir" "$version" ) 2>&1 )" || rc=$?
    local ok=1
    [[ "$rc" -eq "$expect" ]] || ok=0
    printf '%s' "$out" | /usr/bin/grep -q -- "$must" || ok=0
    if [[ -n "$mustnot" ]] && printf '%s' "$out" | /usr/bin/grep -q -- "$mustnot"; then ok=0; fi
    if [[ "$ok" -eq 1 ]]; then
      printf '  PASS  %-34s exit %s\n' "$label" "$rc" >&2
    else
      printf '  FAIL  %-34s exit %s (expected %s)\n%s\n' "$label" "$rc" "$expect" "$out" >&2
      failures=$((failures + 1))
    fi
  }

  # Case A — FLAT note (regression guard). Must behave exactly as before the port.
  run_case "A flat note (no regression)" v0.00 0 "WOULD RUN" "ABORT"

  # Case L — THE FOLDERED CASE. Mirrors check-release-body-drift.sh Case L.
  #   • FIXED  (recursive ls-tree resolve): note found → body computed → WOULD RUN, exit 0. PASS.
  #   • BROKEN (flat-path only): "ABORT: canonical note unreadable" → exit 1. FAIL.
  # Keyed to v0.02, which exists at NO flat path, so the case cannot pass by
  # accidentally resolving a flat note — it is non-vacuous by construction.
  run_case "L foldered note (bucket)" v0.02 0 "WOULD RUN" "ABORT"

  # Case L2 — the foldered resolve names the BUCKET path, not a fabricated flat one.
  run_case "L2 resolved path is the bucket" v0.02 0 "notes/v0/v0.02_RELEASE_NOTES.md"

  # Case M — SENSITIVITY. No note anywhere (origin/main or working tree) ⇒ still
  # ABORT. The resolver must not invent a path.
  run_case "M absent note still ABORTs" v0.99 1 "ABORT: canonical note unreadable" "WOULD RUN"

  # Case N — working-tree-only note ⇒ ABORT (never emit from the working tree),
  # with the diagnostic that distinguishes it from "exists nowhere".
  run_case "N WT-only note ABORTs w/ hint" v0.03 1 "present in the working tree" "WOULD RUN"

  # Case R — capture precondition still refuses (exit 3) when no capture exists.
  local rc_r=0 out_r
  out_r="$( ( export PATH="$stubdir:$PATH" REPO_ROOT="$work" DRIFT_TOOL="$tmp/drift-stub.sh"
              exec "$0" "$tmp/empty-captures" v0.00 ) 2>&1 )" || rc_r=$?
  if [[ "$rc_r" -eq 3 ]] && printf '%s' "$out_r" | /usr/bin/grep -q "REFUSED"; then
    printf '  PASS  %-34s exit 3\n' "R capture precondition holds" >&2
  else
    printf '  FAIL  %-34s exit %s (expected 3)\n' "R capture precondition holds" "$rc_r" >&2
    failures=$((failures + 1))
  fi

  # Case S — STATIC guard on the emit form: EVERY code line that names the emit
  # command must pass the body as --notes, and NONE may use --notes-file (which
  # publishes the YAML frontmatter as raw text, § 5.1 — the defect that produced
  # two of the bodies this tool exists to repair). Both the real mutation and the
  # dry-run advertisement are covered, so the two can never disagree.
  # The needles are SPLIT across a string concat so this scan cannot match its own
  # source lines — a self-scanning assertion must not count itself.
  # Denominator = code lines that name the emit command AND carry a --notes* flag
  # (a bare mention inside an error string is not an invocation and is excluded).
  # Every one of them must pass the body variable; none may use the file form.
  local _needle="gh release"" edit" _emit _flagged _flag_n _body_n _nf_n
  _emit="$(/usr/bin/grep -n "$_needle" "$0" | /usr/bin/grep -vE '^[0-9]+:[[:space:]]*#' || true)"
  _flagged="$(printf '%s' "$_emit" | /usr/bin/grep -- '--notes' || true)"
  _flag_n="$(printf '%s' "$_flagged" | /usr/bin/grep -c . || true)"
  _body_n="$(printf '%s' "$_flagged" | /usr/bin/grep -c 'BODY' || true)"
  _nf_n="$(printf '%s' "$_flagged" | /usr/bin/grep -c -- "--notes""-file" || true)"
  if [[ "$_flag_n" -ge 1 && "$_body_n" -eq "$_flag_n" && "$_nf_n" -eq 0 ]]; then
    printf '  PASS  %-34s %s/%s emit invocations use --notes "$BODY", 0 use the file form\n' \
      "S emit form is sanctioned" "$_body_n" "$_flag_n" >&2
  else
    printf '  FAIL  %-34s flagged=%s withBODY=%s notesfile=%s\n%s\n' \
      "S emit form is sanctioned" "$_flag_n" "$_body_n" "$_nf_n" "$_flagged" >&2
    failures=$((failures + 1))
  fi

  if [[ "$failures" -eq 0 ]]; then
    printf 'reemit-release-bodies self-test: ALL PASS\n' >&2
    exit 0
  fi
  printf 'reemit-release-bodies self-test: %s FAILURE(S)\n' "$failures" >&2
  exit 1
}

# ─── Arg parse ───────────────────────────────────────────────────────────────
# --self-test is matched FIRST and exits, so it can never fall through into the
# --execute branch.
if [[ "${1:-}" == "--self-test" ]]; then self_test; fi

EXECUTE=0
if [[ "${1:-}" == "--execute" ]]; then EXECUTE=1; shift; fi

CAPTURE_DIR="${1:-}"; shift || true
if [[ -z "$CAPTURE_DIR" || $# -eq 0 ]]; then
  echo "usage: $(basename "$0") [--execute] <capture-dir> <version> [<version> ...]" >&2
  echo "       $(basename "$0") --self-test" >&2
  exit 1
fi

if ! command -v gh >/dev/null 2>&1 || ! gh auth status >/dev/null 2>&1; then
  echo "N/A: gh is absent or unauthenticated." >&2
  exit 2
fi
# git-guard. resolve_note_ref REQUIRES a resolvable ref — this must stay ahead of it.
if ! git -C "$REPO_ROOT" rev-parse --verify "$REF" >/dev/null 2>&1; then
  echo "N/A: $REF is unreadable — run 'git fetch origin main' first." >&2
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

  # ── Resolve the canonical note AT origin/main — flat path first, then any
  #    subfolder bucket. Layout-independent; see the header block.
  NOTE_REL=""
  NOTE_REL="$(resolve_note_ref "$REF" "$V")" || NOTE_REL=""
  if [[ -z "$NOTE_REL" ]]; then
    # Not on the canonical ref. Distinguish "in the working tree, chore PR not
    # landed" from "exists nowhere" — the resolver never invents a path.
    WT_NOTE=""
    WT_NOTE="$(resolve_note_worktree "${REPO_ROOT}/${NOTES_DIR}" "$V")" || WT_NOTE=""
    if [[ -n "$WT_NOTE" ]]; then
      echo "  ABORT: canonical note unreadable — not on ${REF} under ${NOTES_DIR}/, though it is"
      echo "         present in the working tree at ${WT_NOTE} (the Stage 13 chore PR has not"
      echo "         landed). Canonical source is ${REF}."
    else
      echo "  ABORT: canonical note unreadable — no ${V}_RELEASE_NOTES.md on ${REF} under"
      echo "         ${NOTES_DIR}/ or any of its subfolders."
    fi
    rc_final=1
    continue
  fi
  echo "  note:   ${REF}:${NOTE_REL}"

  # ── Compute the §5.1 body. Braced ref (${REF}:path) because a bare "$REF:path"
  #    is mangled by zsh's colon modifier under some invocations.
  RAW="$(git -C "$REPO_ROOT" show "${REF}:${NOTE_REL}" 2>/dev/null)" || RAW=""
  if [[ -z "$RAW" ]]; then
    echo "  ABORT: note resolved to ${REF}:${NOTE_REL} but the content read failed"
    echo "         (corrupt object / partial clone) — refusing to emit."
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
