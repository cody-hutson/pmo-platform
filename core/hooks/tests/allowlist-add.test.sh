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

# ---------------------------------------------------------------------------
# T-9  Region SELECTION — the axis T-8 does not test.
#
# T-8 varies the marker SPELLING and uses ONE pair per fixture, so it can only
# ever assert that the two readers agree about what a marker LOOKS like. It
# cannot see the other axis: with SEVERAL candidate pairs in one file, WHICH
# pair each reader binds. The two readers select differently, and the asymmetry
# is BEGIN-only:
#
#   compose.py binds with an UNANCHORED re.search over the whole text, so its
#   BEGIN can match mid-line — a junk-prefixed marker still binds. Its END is
#   effectively line-anchored anyway, because the pattern is
#   BEGIN + "\n(.*?)\n" + END, and that literal \n forces END to start a line.
#
#   The helper's awk is ^-anchored on BOTH, so a junk-prefixed BEGIN is skipped
#   and it binds the first CLEAN pair.
#
# Consequence, and it is the reason this arm exists: when compose.py binds an
# EARLIER begin than the awk and a line-start END falls between them,
# compose.py's region CLOSES before the helper's insert point. The helper still
# took the INSERT branch, so T-6's warning is suppressed — the entry is dropped
# at the next regeneration with no signal at all. That is the fail-SILENT class
# T-8's P1 exists to catch, reached by an input shape T-8 cannot construct.
#
# These arms assert the OBSERVED behaviour, not the desired behaviour. The
# divergence is NOT reachable on any compose-generated allowlist (compose writes
# exactly one well-formed pair) and is NOT a regression (the pre-fix EOF append
# was outside the region too), so it is characterized here rather than fixed.
# If either reader is ever changed — anchoring compose.py, or loosening the awk
# — these arms go red and the claim in allowlist-add.sh must be re-derived.
#
# Fixture A is the shape the finding was first described as, and it SURVIVES:
# a junk-prefixed PAIR is skipped by compose.py at its END too, so compose binds
# a SUPERSET that swallows the clean pair. Recording A alongside B is what keeps
# the arm honest about which shape actually loses data.
# ---------------------------------------------------------------------------
echo ""
echo "T-9 region selection (multi-pair — the axis T-8 cannot reach)"
echo "---"
if [ "$HAVE_COMPOSE" = 1 ]; then
  # name | expect_survived | expect_warned | fixture lines (\n-separated)
  t9_run() { # $1=name $2=expect_survived $3=expect_warned $4=fixture
    local name="$1" exp_s="$2" exp_w="$3"
    /usr/bin/printf '%b\n' "$4" > "$ALLOWLIST"
    local err x survived appended warned
    err="$("$HELPER" "$ALLOWLIST" 'mcp__t9__createOmega' 2>&1 >/dev/null)"
    x="$(extract "$ALLOWLIST")"
    survived=0; case "$x" in *mcp__t9__createOmega*) survived=1 ;; esac
    warned=0; [ -n "$err" ] && warned=1
    chk "$([ "$survived" = "$exp_s" ] && [ "$warned" = "$exp_w" ] && echo 1 || echo 0)" \
      "T-9 [${name}] survived=${survived} warned=${warned} — matches the characterized behaviour" \
      "T-9 [${name}] survived=${survived} warned=${warned}, expected survived=${exp_s} warned=${exp_w} — a reader's region selection changed; re-derive the strict-subset claim in allowlist-add.sh"
  }

  # A — junk-prefixed PAIR before a clean pair. compose.py skips the junk END
  #     (line-anchored) and binds a SUPERSET spanning both pairs, so the entry
  #     lands inside it and survives. No data loss on this shape.
  t9_run "junk PAIR then clean pair -> superset, survives" 1 0 \
'# Test allowlist\nxxx# === BEGIN OPERATOR ADDITIONS ===\njunk-region-content\nxxx# === END OPERATOR ADDITIONS ===\n# === BEGIN OPERATOR ADDITIONS ===\nplaceholder\n# === END OPERATOR ADDITIONS ===\nmcp__seed__tail'

  # B — junk-prefixed BEGIN with a CLEAN END, before a clean pair. THIS is the
  #     silent-loss shape: compose.py binds the mid-line BEGIN, closes at the
  #     clean END above the helper's region, and the entry falls outside.
  t9_run "junk BEGIN + clean END then clean pair -> SILENT LOSS" 0 0 \
'# Test allowlist\nxxx# === BEGIN OPERATOR ADDITIONS ===\njunk-region-content\n# === END OPERATOR ADDITIONS ===\n# === BEGIN OPERATOR ADDITIONS ===\nplaceholder\n# === END OPERATOR ADDITIONS ===\nmcp__seed__tail'

  # C — CONTROL. A single clean pair, the production shape. Without it, arm B's
  #     survived=0 could be a dead extractor rather than a selection divergence,
  #     and the whole T-9 block would prove nothing.
  t9_run "CONTROL single clean pair (production shape) -> survives" 1 0 \
'# Test allowlist\n# === BEGIN OPERATOR ADDITIONS ===\nplaceholder\n# === END OPERATOR ADDITIONS ===\nmcp__seed__tail'
else
  RESIDUALS="${RESIDUALS}RESIDUAL: T-9 region-selection arms SKIPPED — compose.py not resolvable from ${HOOK_DIR}.\n"
fi

# ---------------------------------------------------------------------------
# T-10..T-19  --scope on the egress allowlist (the row-scope directive).
#
# egress-allowlist.txt serves two match domains, and a row is confined to one by a
# `# egress-scope: host|gh-api-path` directive on the line DIRECTLY above it (the
# allowlist's own header states the grammar). A row with no directive is matched in
# both. These arms run in their OWN sandbox: a copy of the helper at
# <sbx>/.claude/hooks/, so its known-allowlist set resolves to <sbx>/.claude/*.txt and
# the ambient allowlist the arms above use is never touched.
#
# Upgrade in place is the property the helper's own notice promises: after a bare add,
# re-running with --scope must leave ONE row, now declared — never a declared twin
# beside a bare row that is still matched in both domains. It edits only inside the
# OPERATOR ADDITIONS region (T-18): the managed section belongs to the composer, and an
# edit there is tampering the next update detects.
# ---------------------------------------------------------------------------
echo ""
echo "T-10..T-19 --scope on the egress allowlist"
echo "---"
SC_ROOT="$(/usr/bin/mktemp -d)"
SC_HOOKS="${SC_ROOT}/.claude/hooks"
/bin/mkdir -p "$SC_HOOKS"
/bin/cp "$HELPER" "${SC_HOOKS}/allowlist-add.sh"
/bin/chmod +x "${SC_HOOKS}/allowlist-add.sh"
SC_HELPER="${SC_HOOKS}/allowlist-add.sh"
SC_EGRESS="${SC_ROOT}/.claude/egress-allowlist.txt"
SC_MCP="${SC_ROOT}/.claude/mcp-write-allowlist.txt"
SC_LOG="${SC_HOOKS}/allowlist-additions.log"

# The production region shape: a declared managed row, then BEGIN / placeholder / END.
seed_egress() {
  /usr/bin/printf '# Test egress allowlist\n# egress-scope: host\napi.example.test\n%s\n%s\n%s\n' \
    "$BEGIN_M" "$PLACEHOLDER" "$END_M" > "$SC_EGRESS"
}
# The line directly above the first line equal to $1 (empty when none), and line $1.
above_of() { _S="$1" /usr/bin/awk '$0 == ENVIRON["_S"] { print prev; exit } { prev = $0 }' "$2"; }
line_at()  { _N="$1" /usr/bin/awk 'NR == ENVIRON["_N"] + 0 { print; exit }' "$2"; }

# T-10 — a declared add writes the directive and the entry as an adjacent pair, directly
# above END, and the pair survives the authoritative extractor.
seed_egress
t10_rc=0
"$SC_HELPER" "$SC_EGRESS" 'repos/t10-org/*' --scope gh-api-path >/dev/null 2>&1 || t10_rc="$?"
t10_x="$(line_of 'repos/t10-org/*' "$SC_EGRESS")"
t10_e="$(line_of "$END_M" "$SC_EGRESS")"
t10_a="$(above_of 'repos/t10-org/*' "$SC_EGRESS")"
chk "$([ "$t10_rc" = 0 ] && [ -n "$t10_x" ] && [ "$t10_a" = '# egress-scope: gh-api-path' ] && [ "$t10_x" = "$((t10_e - 1))" ] && echo 1 || echo 0)" \
  "T-10 --scope gh-api-path writes '# egress-scope: gh-api-path' then the entry, directly above END" \
  "T-10 expected rc 0 and the adjacent pair above END; got rc=${t10_rc} entry-line='${t10_x}' END=${t10_e} line-above='${t10_a}'"
if [ "$HAVE_COMPOSE" = 1 ]; then
  t10_xt="$(extract "$SC_EGRESS")"
  case "$t10_xt" in
    *'# egress-scope: gh-api-path'*'repos/t10-org/*'*) ok "T-10 the directive and the entry both survive compose.py extract" ;;
    *) bad "T-10 the pair did not survive extraction; extractor returned: ${t10_xt}" ;;
  esac
else
  RESIDUALS="${RESIDUALS}RESIDUAL: T-10 end-to-end extraction arm SKIPPED — compose.py not resolvable from ${HOOK_DIR}.\n"
fi

# T-11 — re-adding the same declared pair is a no-op that exits 0.
t11_rc=0
"$SC_HELPER" "$SC_EGRESS" 'repos/t10-org/*' --scope gh-api-path >/dev/null 2>&1 || t11_rc="$?"
chk "$([ "$t11_rc" = 0 ] && [ "$(count_of 'repos/t10-org/*' "$SC_EGRESS")" = 1 ] && [ "$(count_of '# egress-scope: gh-api-path' "$SC_EGRESS")" = 1 ] && echo 1 || echo 0)" \
  "T-11 re-adding the same declared pair is idempotent (one entry, one directive, exit 0)" \
  "T-11 re-add gave rc=${t11_rc}, $(count_of 'repos/t10-org/*' "$SC_EGRESS") entries and $(count_of '# egress-scope: gh-api-path' "$SC_EGRESS") directives"

# T-12 — an undeclared add still lands above END, carries no directive, and the helper
# says on stderr how the row will be matched.
seed_egress
t12_rc=0
t12_err="$("$SC_HELPER" "$SC_EGRESS" 'bare-t12.example.test' 2>&1 >/dev/null)" || t12_rc="$?"
t12_x="$(line_of 'bare-t12.example.test' "$SC_EGRESS")"
t12_e="$(line_of "$END_M" "$SC_EGRESS")"
t12_a="$(above_of 'bare-t12.example.test' "$SC_EGRESS")"
case "$t12_a" in '# egress-scope:'*) t12_decl=1 ;; *) t12_decl=0 ;; esac
case "$t12_err" in *NOTICE:*--scope*) t12_note=1 ;; *) t12_note=0 ;; esac
chk "$([ "$t12_rc" = 0 ] && [ -n "$t12_x" ] && [ "$t12_x" = "$((t12_e - 1))" ] && [ "$t12_decl" = 0 ] && [ "$t12_note" = 1 ] && echo 1 || echo 0)" \
  "T-12 an add with no --scope is written undeclared above END, with a NOTICE naming --scope" \
  "T-12 expected rc 0, an undeclared entry above END and a NOTICE; got rc=${t12_rc} line-above='${t12_a}' stderr='${t12_err}'"

# T-13 — an unknown scope value is refused and the file is untouched.
seed_egress
/bin/cp "$SC_EGRESS" "${SC_ROOT}/t13.before"
t13_rc=0
"$SC_HELPER" "$SC_EGRESS" 'bogus-t13.example.test' --scope bogus >/dev/null 2>&1 || t13_rc="$?"
chk "$([ "$t13_rc" = 1 ] && /usr/bin/cmp -s "${SC_ROOT}/t13.before" "$SC_EGRESS" && echo 1 || echo 0)" \
  "T-13 --scope bogus exits 1 and leaves the file byte-identical" \
  "T-13 expected rc 1 and an unchanged file; got rc=${t13_rc}"

# T-14 — --scope is an egress-allowlist flag; against any other allowlist it is refused.
/usr/bin/printf '# Test mcp allowlist\nmcp__t14__one\n' > "$SC_MCP"
/bin/cp "$SC_MCP" "${SC_ROOT}/t14.before"
t14_rc=0
"$SC_HELPER" "$SC_MCP" 'mcp__t14__two' --scope host >/dev/null 2>&1 || t14_rc="$?"
chk "$([ "$t14_rc" = 1 ] && /usr/bin/cmp -s "${SC_ROOT}/t14.before" "$SC_MCP" && echo 1 || echo 0)" \
  "T-14 --scope against a non-egress allowlist exits 1 and leaves that file byte-identical" \
  "T-14 expected rc 1 and an unchanged file; got rc=${t14_rc}"

# T-15 — --reason and --scope parse in either order, and the additions log records both.
seed_egress
"$SC_HELPER" "$SC_EGRESS" 't15a.example.test' --reason why --scope host >/dev/null 2>&1 || true
t15a_log="$(/usr/bin/tail -n 1 "$SC_LOG" 2>/dev/null || true)"
t15a_a="$(above_of 't15a.example.test' "$SC_EGRESS")"
"$SC_HELPER" "$SC_EGRESS" 't15b.example.test' --scope host --reason why >/dev/null 2>&1 || true
t15b_log="$(/usr/bin/tail -n 1 "$SC_LOG" 2>/dev/null || true)"
t15b_a="$(above_of 't15b.example.test' "$SC_EGRESS")"
t15_ok=1
case "$t15a_log" in *t15a.example.test*why*scope=host*) ;; *) t15_ok=0 ;; esac
case "$t15b_log" in *t15b.example.test*why*scope=host*) ;; *) t15_ok=0 ;; esac
[ "$t15a_a" = '# egress-scope: host' ] || t15_ok=0
[ "$t15b_a" = '# egress-scope: host' ] || t15_ok=0
chk "$t15_ok" \
  "T-15 --reason/--scope parse in either order; the log line carries the reason and scope=host" \
  "T-15 order-independence failed; logs: '${t15a_log}' / '${t15b_log}'; lines above: '${t15a_a}' / '${t15b_a}'"

# T-16 — when a directive dangles directly above the insertion point, an undeclared add
# writes a blank line first, so the new row stays undeclared as the notice says.
/usr/bin/printf '# Test egress allowlist\n%s\n# egress-scope: host\n%s\n' "$BEGIN_M" "$END_M" > "$SC_EGRESS"
"$SC_HELPER" "$SC_EGRESS" 't16.example.test' >/dev/null 2>&1 || true
t16_x="$(line_of 't16.example.test' "$SC_EGRESS")"
t16_a1="$(line_at "$(( ${t16_x:-0} - 1 ))" "$SC_EGRESS")"
t16_a2="$(line_at "$(( ${t16_x:-0} - 2 ))" "$SC_EGRESS")"
chk "$([ -n "$t16_x" ] && [ "$t16_x" -gt 2 ] && [ -z "$t16_a1" ] && [ "$t16_a2" = '# egress-scope: host' ] && echo 1 || echo 0)" \
  "T-16 a dangling directive above the insertion point is separated from the new row by a blank line" \
  "T-16 expected the new row, a blank line above it, and the dangling directive above that; got entry-line='${t16_x}' above='${t16_a1}' two-above='${t16_a2}'"

# T-17 — upgrade in place: a --scope re-add of an existing BARE row declares that row
# rather than adding a second one.
seed_egress
"$SC_HELPER" "$SC_EGRESS" 'repos/t17-org/*' >/dev/null 2>&1 || true
t17_rc=0
"$SC_HELPER" "$SC_EGRESS" 'repos/t17-org/*' --scope gh-api-path >/dev/null 2>&1 || t17_rc="$?"
t17_a="$(above_of 'repos/t17-org/*' "$SC_EGRESS")"
t17_x="$(line_of 'repos/t17-org/*' "$SC_EGRESS")"
t17_b="$(line_of "$BEGIN_M" "$SC_EGRESS")"
t17_e="$(line_of "$END_M" "$SC_EGRESS")"
chk "$([ "$t17_rc" = 0 ] && [ "$(count_of 'repos/t17-org/*' "$SC_EGRESS")" = 1 ] && [ "$t17_a" = '# egress-scope: gh-api-path' ] && [ -n "$t17_x" ] && [ "$t17_x" -gt "$t17_b" ] && [ "$t17_x" -lt "$t17_e" ] && echo 1 || echo 0)" \
  "T-17 a --scope re-add upgrades the bare row in place: one row, now declared, still inside the region" \
  "T-17 expected one declared row inside the region; got rc=${t17_rc} rows=$(count_of 'repos/t17-org/*' "$SC_EGRESS") line-above='${t17_a}'"

# T-18 — the upgrade never edits OUTSIDE the OPERATOR ADDITIONS region. A bare row in the
# managed section is left exactly as it was; the declared pair lands in the region.
/usr/bin/printf '# Test egress allowlist\nsvc-t18.example.test\n%s\n%s\n%s\n' \
  "$BEGIN_M" "$PLACEHOLDER" "$END_M" > "$SC_EGRESS"
/usr/bin/awk -v b="$BEGIN_M" '$0 == b { exit } { print }' "$SC_EGRESS" > "${SC_ROOT}/t18.managed.before"
"$SC_HELPER" "$SC_EGRESS" 'svc-t18.example.test' --scope host >/dev/null 2>&1 || true
/usr/bin/awk -v b="$BEGIN_M" '$0 == b { exit } { print }' "$SC_EGRESS" > "${SC_ROOT}/t18.managed.after"
t18_region="$(/usr/bin/awk -v b="$BEGIN_M" -v e="$END_M" '
  $0 == b { inr = 1; next } $0 == e { inr = 0 }
  inr && prev == "# egress-scope: host" && $0 == "svc-t18.example.test" { n++ }
  { prev = $0 } END { print n + 0 }' "$SC_EGRESS")"
chk "$(/usr/bin/cmp -s "${SC_ROOT}/t18.managed.before" "${SC_ROOT}/t18.managed.after" && [ "$t18_region" = 1 ] && echo 1 || echo 0)" \
  "T-18 upgrade in place is confined to the region: the managed section is byte-identical and the declared pair lands in the region" \
  "T-18 the managed section changed or no declared pair landed in the region (declared pairs in region: ${t18_region})"

# T-19 — on a marker-less egress file (no region, so no managed section either) the
# whole file is the helper's to edit, and the bare row is upgraded where it sits.
/usr/bin/printf '# Test egress allowlist\nsvc-t19.example.test\nother-t19.example.test\n' > "$SC_EGRESS"
t19_rc=0
"$SC_HELPER" "$SC_EGRESS" 'svc-t19.example.test' --scope host >/dev/null 2>&1 || t19_rc="$?"
chk "$([ "$t19_rc" = 0 ] && [ "$(count_of 'svc-t19.example.test' "$SC_EGRESS")" = 1 ] && [ "$(above_of 'svc-t19.example.test' "$SC_EGRESS")" = '# egress-scope: host' ] && [ "$(above_of 'other-t19.example.test' "$SC_EGRESS")" = 'svc-t19.example.test' ] && echo 1 || echo 0)" \
  "T-19 on a marker-less egress file the bare row is declared where it sits" \
  "T-19 expected one declared row in place; got rc=${t19_rc} rows=$(count_of 'svc-t19.example.test' "$SC_EGRESS") line-above='$(above_of 'svc-t19.example.test' "$SC_EGRESS")'"

/bin/rm -rf "$SC_ROOT"

# ----- Summary -----

echo ""
if [ -n "$RESIDUALS" ]; then /usr/bin/printf "$RESIDUALS"; fi
echo "===================================="
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
echo "===================================="
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
