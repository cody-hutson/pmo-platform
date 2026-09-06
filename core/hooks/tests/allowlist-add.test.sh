#!/bin/bash
# tests/allowlist-add.test.sh — marker-region placement tests for allowlist-add.sh
#
# The property under test is NOT "the entry landed on a particular line". It is
# "the entry SURVIVES core/deploy/compose.py::extract_operator_additions()" —
# the reader that decides what the update path preserves across a regeneration.
# A line-position assertion is a proxy; the extractor is the thing itself.
#
# STRUCTURAL CONTRACT (get this wrong and the suite fails while every assertion
# passes): test-runner.sh:61 greps this file's output for the literal pattern
#   ^Total: [0-9]+  PASS: [0-9]+  FAIL: [0-9]+
# — TWO spaces between fields — and counts a suite that emits no such line as a
# FAIL regardless of its assertions. The summary block at the bottom and the
# non-zero exit on failure are copied from block-mcp-writes.test.sh for that
# reason. Failure lines start at column 0 with "FAIL" so test-runner.sh:96
# forwards them; the RESIDUAL disclosure below is forwarded by test-runner.sh:86.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HELPER="${HOOK_DIR}/allowlist-add.sh"
# The one known allowlist present in BOTH the source-checkout layout
# (core/mcp-write-allowlist.txt) and the CI sandbox that setup-ci-layout.sh
# materializes (<sandbox>/.claude/mcp-write-allowlist.txt). In BOTH layouts it is
# marker-LESS, so every arm below seeds its own marker state explicitly and never
# assumes the ambient file has one.
ALLOWLIST="${HOOK_DIR}/../mcp-write-allowlist.txt"

if [ ! -x "$HELPER" ]; then echo "FAIL: helper not executable at $HELPER" >&2; exit 1; fi

PASS=0
FAIL=0
RESIDUALS=""

# ---------------------------------------------------------------------------
# Byte-faithful save + restore. NOT a "$(cat)" round-trip: command substitution
# strips trailing newlines, and the committed fixture has no trailing newline on
# its last line — so a printf-based restore would silently rewrite a tracked file.
# ---------------------------------------------------------------------------
BACKUP_DIR="$(/usr/bin/mktemp -d)"
BACKUP="${BACKUP_DIR}/allowlist.orig"
HAD_ALLOWLIST=0
if [ -f "$ALLOWLIST" ]; then HAD_ALLOWLIST=1; /bin/cp -p "$ALLOWLIST" "$BACKUP"; fi

restore_state() {
  if [ "$HAD_ALLOWLIST" = 1 ]; then
    /bin/cp -p "$BACKUP" "$ALLOWLIST"
  else
    /bin/rm -f "$ALLOWLIST"
  fi
  /bin/rm -rf "$BACKUP_DIR"
}
trap restore_state EXIT

ok()  { /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
bad() { /usr/bin/printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }
chk() { if [ "$1" = 1 ]; then ok "$2"; else bad "$3"; fi }

# Exact-string lookups — awk, not grep, because an exact compare has no pattern
# to reject and so cannot return a plausible zero from a regex the engine refused.
#
# The needle travels through ENVIRON, never `awk -v`, for the SAME reason the
# helper's insert does: `awk -v` interprets escape sequences in the assigned
# value, so a needle containing a backslash arrives as something else. Measured
# here, not assumed: with `awk -v s='core/**/\t*.sh'` this comparator returns 0
# against a file that byte-faithfully contains that entry, and returns 1 via
# ENVIRON. The first draft of this file used `-v` and the backslash arm failed —
# a comparator committing the exact defect it exists to detect would have
# reported the helper broken while the helper was correct.
line_of()  { _S="$1" /usr/bin/awk '$0 == ENVIRON["_S"] { print NR; exit }' "$2"; }
count_of() { _S="$1" /usr/bin/awk '$0 == ENVIRON["_S"] { n++ } END { print n + 0 }' "$2"; }
nlines()   { /usr/bin/awk 'END { print NR + 0 }' "$1"; }

BEGIN_M='# === BEGIN OPERATOR ADDITIONS ==='
END_M='# === END OPERATOR ADDITIONS ==='
PLACEHOLDER='# Add custom entries below. update.sh never touches this section.'

# Seed the PRODUCTION shape: BEGIN + compose.py's placeholder + END. Measured on
# the deployed allowlists, 8 of 9 marker-bearing files are in exactly this shape
# and 0 of 9 have an adjacent pair — because compose.py:367 substitutes the
# placeholder whenever the preserved body is empty, so a composed region is never
# empty. An adjacent-pair-only fixture would never exercise the real shape.
seed_region() {
  /usr/bin/printf '# Test allowlist\nmcp__seed__one\n%s\n%s\n%s\nmcp__seed__tail\n' \
    "$BEGIN_M" "$PLACEHOLDER" "$END_M" > "$ALLOWLIST"
}
seed_adjacent() {
  /usr/bin/printf '# Test allowlist\n%s\n%s\n' "$BEGIN_M" "$END_M" > "$ALLOWLIST"
}
seed_markerless() {
  /usr/bin/printf '# Test allowlist\nmcp__a__one\nmcp__b__two\nmcp__c__three\n' > "$ALLOWLIST"
}

# --- compose.py resolution -------------------------------------------------
# The end-to-end arms need the AUTHORITATIVE reader. Re-implementing its regex
# here would test this file against itself, which is the exact defect these arms
# exist to catch, so the arms are SKIPPED-AND-DISCLOSED rather than faked when
# compose.py cannot be found.
COMPOSE=""
for _c in \
  "${PMO_COMPOSE_PY:-}" \
  "${HOOK_DIR}/../../core/deploy/compose.py" \
  "${GITHUB_WORKSPACE:-}/core/deploy/compose.py"
do
  if [ -n "$_c" ] && [ -f "$_c" ]; then COMPOSE="$_c"; break; fi
done
if [ -z "$COMPOSE" ]; then
  _top="$(cd "$HOOK_DIR" 2>/dev/null && /usr/bin/git rev-parse --show-toplevel 2>/dev/null || true)"
  if [ -n "$_top" ] && [ -f "${_top}/core/deploy/compose.py" ]; then COMPOSE="${_top}/core/deploy/compose.py"; fi
fi
PY=""
for _p in /usr/bin/python3 /opt/homebrew/bin/python3 /usr/local/bin/python3; do
  if [ -x "$_p" ]; then PY="$_p"; break; fi
done
HAVE_COMPOSE=0
if [ -n "$COMPOSE" ] && [ -n "$PY" ]; then HAVE_COMPOSE=1; fi

extract() { "$PY" "$COMPOSE" extract --target "$1" 2>/dev/null; }

echo "===================================="
echo "allowlist-add.sh — marker-region placement"
echo "target: $ALLOWLIST"
if [ "$HAVE_COMPOSE" = 1 ]; then
  echo "authoritative extractor: $COMPOSE"
else
  echo "authoritative extractor: NOT RESOLVED — end-to-end arms skipped"
fi
echo "===================================="

# ---------------------------------------------------------------------------
# T-5  CONTROL — detector reachability.
# Runs FIRST and deliberately so. Without it, T-1's "entry line is between the
# marker lines" comparison could pass vacuously against two zeros from a marker
# scan that never fired, and T-2's extraction could pass on a stale file. This
# arm establishes that the markers ARE locatable and the entry is ABSENT before
# any helper invocation — i.e. that the later PASS is a state CHANGE.
# ---------------------------------------------------------------------------
echo ""
echo "T-5 CONTROL — detector reachability"
echo "---"
seed_region
c5_b="$(line_of "$BEGIN_M" "$ALLOWLIST")"
c5_e="$(line_of "$END_M" "$ALLOWLIST")"
c5_pre="$(count_of 'mcp__t1__createAlpha' "$ALLOWLIST")"
chk "$([ -n "$c5_b" ] && [ -n "$c5_e" ] && [ "$c5_b" -lt "$c5_e" ] && [ "$c5_pre" = 0 ] && echo 1 || echo 0)" \
  "control: markers located (BEGIN=${c5_b} END=${c5_e}) and subject entry absent pre-run (count=${c5_pre})" \
  "control: marker scan or pre-state is dead (BEGIN='${c5_b}' END='${c5_e}' pre-count='${c5_pre}') — every position arm below would be vacuous"

if [ "$HAVE_COMPOSE" = 1 ]; then
  c5_x="$(extract "$ALLOWLIST")"
  chk "$([ "$c5_x" = "$PLACEHOLDER" ] && echo 1 || echo 0)" \
    "control: extractor is live on the seeded region (returned the placeholder verbatim)" \
    "control: extractor returned '${c5_x}' on a well-formed region — a dead reader makes every T-2/T-3 result meaningless"
fi

# ---------------------------------------------------------------------------
# T-1  GREEN subject — the entry lands INSIDE the region (production shape).
# ---------------------------------------------------------------------------
echo ""
echo "T-1 GREEN — insert lands between BEGIN and END (production shape)"
echo "---"
t1_rc=0
"$HELPER" "$ALLOWLIST" 'mcp__t1__createAlpha' >/dev/null 2>&1 || t1_rc="$?"
t1_b="$(line_of "$BEGIN_M" "$ALLOWLIST")"
t1_e="$(line_of "$END_M" "$ALLOWLIST")"
t1_x="$(line_of 'mcp__t1__createAlpha' "$ALLOWLIST")"
chk "$([ -n "$t1_x" ] && [ "$t1_x" -gt "$t1_b" ] && [ "$t1_x" -lt "$t1_e" ] && echo 1 || echo 0)" \
  "T-1 entry at line ${t1_x} sits inside the region (BEGIN=${t1_b} END=${t1_e})" \
  "T-1 entry at line '${t1_x}' is NOT inside the region (BEGIN=${t1_b} END=${t1_e})"

# FMF-1 regression witness. The Stage-5 design cited the edit block as lines
# 112-119; the ts= assignment is at :119 and set -euo pipefail at :15, so a
# literal implementation of that range leaves :120 dereferencing an unset
# variable and EVERY successful add exits non-zero AFTER a successful mv. The
# entry would look correct and the exit code would be wrong. Assert the code.
chk "$([ "$t1_rc" = 0 ] && echo 1 || echo 0)" \
  "T-1 successful add exits 0 (regression witness for a truncated edit block)" \
  "T-1 successful add exited ${t1_rc} — the entry may be placed correctly while the script still fails; check that ts= survived the edit"

chk "$([ "$(count_of "$PLACEHOLDER" "$ALLOWLIST")" = 1 ] && echo 1 || echo 0)" \
  "T-1 compose.py placeholder line preserved" \
  "T-1 placeholder line was lost or duplicated"

# ---------------------------------------------------------------------------
# T-2  GREEN end-to-end — the entry survives the AUTHORITATIVE extractor.
# This is the property the card is actually about.
# ---------------------------------------------------------------------------
echo ""
echo "T-2 GREEN — entry survives compose.py::extract_operator_additions()"
echo "---"
if [ "$HAVE_COMPOSE" = 1 ]; then
  t2_x="$(extract "$ALLOWLIST")"
  case "$t2_x" in
    *mcp__t1__createAlpha*) ok "T-2 extractor returns the entry (survives regeneration)" ;;
    *) bad "T-2 extractor did NOT return the entry; got: ${t2_x}" ;;
  esac
else
  RESIDUALS="${RESIDUALS}RESIDUAL: T-2/T-3/T-8 end-to-end arms SKIPPED — compose.py not resolvable from ${HOOK_DIR}; only line-position arms ran.\n"
fi

# ---------------------------------------------------------------------------
# T-3  RED regression witness — the PRE-FIX output shape must NOT extract.
# Without this, T-2 could pass against a reader that returns everything, and the
# RED->GREEN pair would be a bare positive.
# ---------------------------------------------------------------------------
echo ""
echo "T-3 RED — an entry BELOW the END marker does not survive extraction"
echo "---"
if [ "$HAVE_COMPOSE" = 1 ]; then
  /usr/bin/printf '# Test allowlist\n%s\n%s\n%s\nmcp__t3__belowEnd\n' \
    "$BEGIN_M" "$PLACEHOLDER" "$END_M" > "$ALLOWLIST"
  t3_x="$(extract "$ALLOWLIST")"
  case "$t3_x" in
    *mcp__t3__belowEnd*) bad "T-3 extractor returned an entry that sits BELOW END — the discriminator is broken, so T-2 proves nothing" ;;
    *) ok "T-3 below-END entry is dropped by the extractor (T-2's assertion discriminates)" ;;
  esac
fi

# ---------------------------------------------------------------------------
# T-4  Marker-less target — unchanged historical behavior, and SILENT.
# This is the committed shape of core/mcp-write-allowlist.txt and of the
# CI-materialized sandbox copy. block-mcp-writes.test.sh:169 already invokes the
# helper against it, so a fix that stopped appending here would turn that suite
# red.
# ---------------------------------------------------------------------------
echo ""
echo "T-4 marker-less target — EOF append, no warning"
echo "---"
seed_markerless
t4_pre="$(nlines "$ALLOWLIST")"
t4_err="$("$HELPER" "$ALLOWLIST" 'mcp__t4__createBeta' 2>&1 >/dev/null)"
t4_rc=$?
t4_post="$(nlines "$ALLOWLIST")"
t4_last="$(/usr/bin/tail -n 1 "$ALLOWLIST")"
chk "$([ "$t4_rc" = 0 ] && [ "$t4_last" = 'mcp__t4__createBeta' ] && [ "$t4_post" = "$((t4_pre + 1))" ] && echo 1 || echo 0)" \
  "T-4 appended at EOF, exit 0, ${t4_pre} -> ${t4_post} lines" \
  "T-4 expected exit 0 / last line = entry / ${t4_pre}+1 lines; got rc=${t4_rc} last='${t4_last}' lines=${t4_post}"
chk "$([ -z "$t4_err" ] && echo 1 || echo 0)" \
  "T-4 no warning on a genuinely marker-less target (the normal path stays quiet)" \
  "T-4 emitted a warning on a marker-less target — this would fire on every ordinary local and CI run: ${t4_err}"
for _pre in mcp__a__one mcp__b__two mcp__c__three; do
  chk "$([ "$(count_of "$_pre" "$ALLOWLIST")" = 1 ] && echo 1 || echo 0)" \
    "T-4 pre-existing entry ${_pre} preserved" "T-4 pre-existing entry ${_pre} was lost or duplicated"
done

# ---------------------------------------------------------------------------
# T-6  Malformed target — append AND warn.
# The warning's truth condition is compose.py's verdict, not a loose reader's: it
# fires exactly when the file carries marker text that compose.py will not honour.
# ---------------------------------------------------------------------------
echo ""
echo "T-6 malformed target — EOF append plus a warning"
echo "---"
/usr/bin/printf '# Test allowlist\n%s\nmcp__seed__x\n' "$BEGIN_M" > "$ALLOWLIST"
t6_err="$("$HELPER" "$ALLOWLIST" 'mcp__t6__createGamma' 2>&1 >/dev/null)"
t6_rc=$?
t6_last="$(/usr/bin/tail -n 1 "$ALLOWLIST")"
chk "$([ "$t6_rc" = 0 ] && [ "$t6_last" = 'mcp__t6__createGamma' ] && echo 1 || echo 0)" \
  "T-6 BEGIN-without-END: appended at EOF, exit 0 (fail-open, not a refused grant)" \
  "T-6 expected exit 0 and an EOF append; got rc=${t6_rc} last='${t6_last}'"
# The helper prints the RESOLVED absolute path, while $ALLOWLIST still carries the
# unresolved "/../" segment it was built from — so match on the basename, not on
# the variable. Matching the variable made this arm fail against a warning that
# was entirely correct.
ALLOWLIST_BASE="$(/usr/bin/basename "$ALLOWLIST")"
case "$t6_err" in
  *"$ALLOWLIST_BASE"*NOT*survive*) ok "T-6 warning names the file and says the entry will not survive" ;;
  *) bad "T-6 warning missing or unnamed; stderr was: ${t6_err}" ;;
esac

# END without a preceding BEGIN is the same class of broken fence and must be
# equally loud — an entry appended there is dropped by the extractor too.
/usr/bin/printf '# Test allowlist\n%s\nmcp__seed__y\n' "$END_M" > "$ALLOWLIST"
t6b_err="$("$HELPER" "$ALLOWLIST" 'mcp__t6b__createDelta' 2>&1 >/dev/null)"
case "$t6b_err" in
  *NOT*survive*) ok "T-6b END-without-BEGIN also warns" ;;
  *) bad "T-6b END-without-BEGIN appended silently; stderr was: ${t6b_err}" ;;
esac

# ---------------------------------------------------------------------------
# T-7  Preserved behavior — the CLI contract is byte-identical to pre-fix.
# ---------------------------------------------------------------------------
echo ""
echo "T-7 preserved behavior"
echo "---"
seed_region
"$HELPER" "$ALLOWLIST" 'mcp__t7__createEps' >/dev/null 2>&1
t7_rc=0
"$HELPER" "$ALLOWLIST" 'mcp__t7__createEps' >/dev/null 2>&1 || t7_rc="$?"
chk "$([ "$t7_rc" = 0 ] && [ "$(count_of 'mcp__t7__createEps' "$ALLOWLIST")" = 1 ] && echo 1 || echo 0)" \
  "T-7 re-adding an existing entry is idempotent and exits 0" \
  "T-7 re-add produced rc=${t7_rc} and $(count_of 'mcp__t7__createEps' "$ALLOWLIST") copies"

if "$HELPER" /tmp/evil.txt 'mcp__attacker__createSecret' >/dev/null 2>&1; then
  bad "T-7 helper accepted a target outside the known-allowlist set"
else
  ok "T-7 helper rejects a target outside the known-allowlist set"
fi

# A backslash-bearing entry must round-trip byte-for-byte. awk -v interprets
# escape sequences in an assigned value and would silently mangle a glob from
# shell-injection-allowlist.txt or a path from fs-boundary-allowlist.txt;
# ENVIRON does not. This arm is what keeps that choice from regressing.
seed_region
BS_ENTRY='core/**/\t*.sh'
"$HELPER" "$ALLOWLIST" "$BS_ENTRY" >/dev/null 2>&1
chk "$([ "$(count_of "$BS_ENTRY" "$ALLOWLIST")" = 1 ] && echo 1 || echo 0)" \
  "T-7 backslash-bearing entry round-trips byte-for-byte" \
  "T-7 backslash-bearing entry was mangled — check that the insert uses ENVIRON, not awk -v"

# ---------------------------------------------------------------------------
# T-8  Marker-spelling agreement (the PRF-2 arm).
#
# Two properties, over a matrix of marker spellings:
#   P1  the helper inserted "inside"  =>  the extractor returns the entry.
#       A violation is the fail-SILENT defect: the helper finds a region the
#       authoritative reader rejects, reports success, and suppresses T-6's
#       warning, so the entry vanishes at the next regeneration.
#   P2  the file carries marker text and the entry did NOT survive
#       =>  the helper WARNED.
#       A violation is silent loss on a composition target with a broken fence.
#
# Stated behaviorally on purpose: this asserts the READERS AGREE, rather than
# asserting a regex about a regex. The design claimed agreement "by construction"
# and the claim was false in the unsafe direction on 5 of 9 measured spellings.
# ---------------------------------------------------------------------------
echo ""
echo "T-8 marker-spelling agreement (strict-subset + warn coverage)"
echo "---"
if [ "$HAVE_COMPOSE" = 1 ]; then
  t8_viol=0
  t8_inside=0
  t8_warned=0
  t8_n=0
  while IFS='|' read -r sname sbegin send; do
    [ -n "$sname" ] || continue
    t8_n=$((t8_n + 1))
    /usr/bin/printf '# Test allowlist\n%s\n%s\n%s\nmcp__seed__tail\n' \
      "$sbegin" "$PLACEHOLDER" "$send" > "$ALLOWLIST"
    _err="$("$HELPER" "$ALLOWLIST" 'mcp__t8__createZeta' 2>&1 >/dev/null)"
    _x="$(extract "$ALLOWLIST")"
    _last="$(/usr/bin/tail -n 1 "$ALLOWLIST")"
    _survived=0
    case "$_x" in *mcp__t8__createZeta*) _survived=1 ;; esac
    _appended=0
    [ "$_last" = 'mcp__t8__createZeta' ] && _appended=1
    _warned=0
    [ -n "$_err" ] && _warned=1

    if [ "$_survived" = 1 ]; then
      t8_inside=$((t8_inside + 1))
    elif [ "$_appended" = 1 ] && [ "$_warned" = 1 ]; then
      t8_warned=$((t8_warned + 1))
    else
      t8_viol=$((t8_viol + 1))
      /usr/bin/printf 'FAIL: T-8 [%s] entry neither survived extraction nor was appended-with-warning (survived=%s appended=%s warned=%s)\n' \
        "$sname" "$_survived" "$_appended" "$_warned"
    fi
  done <<'SPELLINGS'
canonical plain|# === BEGIN OPERATOR ADDITIONS ===|# === END OPERATOR ADDITIONS ===
markdown|<!-- === BEGIN OPERATOR ADDITIONS === -->|<!-- === END OPERATOR ADDITIONS === -->
parenthetical|# === BEGIN OPERATOR ADDITIONS (preserved across updates) ===|# === END OPERATOR ADDITIONS (preserved across updates) ===
no space around ===|#=== BEGIN OPERATOR ADDITIONS ===|#=== END OPERATOR ADDITIONS ===
leading whitespace|   # === BEGIN OPERATOR ADDITIONS ===|   # === END OPERATOR ADDITIONS ===
no trailing ===|# === BEGIN OPERATOR ADDITIONS|# === END OPERATOR ADDITIONS
junk before ===|# === BEGIN OPERATOR ADDITIONS junk ===|# === END OPERATOR ADDITIONS junk ===
truncated close|# === BEGIN OPERATOR ADDITIONS ==|# === END OPERATOR ADDITIONS ==
unfenced label only|# BEGIN OPERATOR ADDITIONS|# END OPERATOR ADDITIONS
SPELLINGS

  chk "$([ "$t8_viol" = 0 ] && echo 1 || echo 0)" \
    "T-8 ${t8_n} spellings: ${t8_inside} inserted-and-survived, ${t8_warned} appended-with-warning, 0 violations" \
    "T-8 ${t8_viol} of ${t8_n} spellings violated the agreement (see the FAIL lines above)"
  # Both buckets must be non-empty, or the zero-violation result is vacuous: an
  # all-warn run would mean the helper never inserts, and an all-insert run would
  # mean the warn path is unreachable.
  chk "$([ "$t8_inside" -gt 0 ] && [ "$t8_warned" -gt 0 ] && echo 1 || echo 0)" \
    "T-8 both outcome buckets are populated (insert=${t8_inside}, warn=${t8_warned}) — the zero-violation result is not vacuous" \
    "T-8 an outcome bucket is empty (insert=${t8_inside}, warn=${t8_warned}) — the agreement result proves nothing"
fi

# ----- Summary -----

echo ""
if [ -n "$RESIDUALS" ]; then /usr/bin/printf "$RESIDUALS"; fi
echo "===================================="
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "===================================="
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
