#!/usr/bin/env bash
# test_check36_drift_classes.sh — fixture self-test for the two NEW deploy.sh
# Check 36 drift classes (the ADR-029 encode-and-evict dangling-ref close-out).
# <!-- repo-integrity: allow-memory-ref -->  this test names the ~/.claude/memory store layout it audits.
# <!-- repo-integrity: allow-issue-ref -->  the #NNNN tokens below are SYNTHETIC fixture issue numbers (mapped by the in-test gh stub), not real repo issues.
#
# What this proves: Check 36's two added detectors discriminate correctly —
#   Class 4  dangling-wikilink-to-evicted-memory  (local-only; downstream RE-POINT backstop)
#   Class 5  ledger-pointer-to-closed-issue       (resolution-probing; upstream partial-absorption backstop)
# against a SYNTHETIC memory store built in a tmpdir. The real operator store at
# ${HOME}/.claude/memory is NEVER touched (READ-ONLY-on-the-store invariant: this
# test mutates only its own tmpdir fixtures and a tmpdir `gh` stub on PATH).
#
# Precedent: core/deploy/tests/test_g1_title_floor.sh — a faithful copy of the
# predicate-under-test pinned against a fixture table, plus a DRIFT GUARD that
# greps deploy.sh to assert the live predicate still matches this test's copy
# (so a silent edit to Check 36 fails this test rather than passing it stale).
#
# Hermetic-by-construction: Class 4 is pure filesystem logic (no gh, no network).
# Class 5 probes `gh issue view`; the test stubs `gh` with a canned state map so
# it runs offline and deterministically. Neither detector reads or writes the
# live store.
#
# The crafted fixtures (each class needs a FLAG case and a CLEAN case):
#   Class 4 FLAG  : a memory that links [[ghost]] whose ghost.md is ABSENT     -> emit
#   Class 4 CLEAN : a memory that links [[real]]  whose real.md  is PRESENT    -> silent
#   Class 5 FLAG  : a MEMORY.md ledger row tying a CLOSED issue, not evicted   -> emit
#   Class 5 CLEAN : a MEMORY.md ledger row tying an OPEN issue                 -> silent

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPLOY_SH="${SCRIPT_DIR}/../deploy.sh"

PASS_COUNT=0
FAIL_COUNT=0

# ── Faithful copies of the two Check 36 detector predicates (kept in lock-step
#    with deploy.sh via the drift guard at the end). Each returns 0 = FLAG
#    (drift detected) or 1 = CLEAN (in contract).

# Class 4: does memory file $2 carry any [[target]] wikilink whose <target>.md is
# absent under store root $1? (the deploy.sh Class-4 resolution: [[t]] -> $1/t.md)
c36_wikilink_dangles() {
  local _mem="$1" _file="$2" _wl _target
  while IFS= read -r _wl; do
    [[ -n "$_wl" ]] || continue
    _target=$(printf '%s' "$_wl" | /usr/bin/sed -E 's/^\[\[(.+)\]\]$/\1/')
    [[ -n "$_target" ]] || continue
    if [[ ! -f "${_mem}/${_target}.md" ]]; then
      return 0   # dangling -> FLAG
    fi
  done < <(/usr/bin/grep -oE '\[\[[a-z0-9_]+\]\]' "$_file" 2>/dev/null | /usr/bin/sort -u || true)
  return 1       # all links resolve -> CLEAN
}

# Class 5: does MEMORY.md ledger row $1 strand a memory (cite a CLOSED, resolving
# issue)? Issue state is read from the canned `gh` stub on PATH (same probe shape
# deploy.sh uses: `gh issue view N --json state --jq .state`).
c36_ledger_strands() {
  local _row="$1" _n _state
  for _n in $(printf '%s\n' "$_row" | /usr/bin/grep -oE '#[0-9]+' | /usr/bin/tr -d '#' | /usr/bin/sort -u); do
    [[ -n "$_n" ]] || continue
    gh issue view "$_n" --json number >/dev/null 2>&1 || continue   # non-resolving = dead-ref's job
    _state=$(gh issue view "$_n" --json state --jq .state 2>/dev/null) || _state=""
    if [[ "$_state" == "CLOSED" ]]; then
      return 0   # stranded -> FLAG
    fi
  done
  return 1       # no CLOSED tie -> CLEAN
}

# ── Synthetic store + gh stub (tmpdir-only; the live store is never touched) ──
TMP="$(mktemp -d)"
trap 'rm -rf "$TMP"' EXIT
MEM="${TMP}/memory"
mkdir -p "$MEM"

# Class-4 fixtures: a present target file, and two linking memories.
printf '# real target\nbody\n'                         > "${MEM}/real.md"
printf '# survivor A\nsee [[real]] for context\n'      > "${MEM}/survivor_links_real.md"   # CLEAN
printf '# survivor B\nsee [[ghost]] for context\n'     > "${MEM}/survivor_links_ghost.md"  # FLAG (ghost.md absent)

# Class-5 fixtures: a MEMORY.md ledger with one OPEN-tie row and one CLOSED-tie row.
cat > "${MEM}/MEMORY.md" <<'LEDGER'
# Memory Index

## Temporary enhancement pointers (remove on deploy per capture-enhancement-with-memory-pointer pattern)
- [Open-tie pointer](open_tie.md) — TEMP (tied to #1001): live encode; remove when #1001 ships
- [Closed-tie pointer](closed_tie.md) — TEMP (tied to #2002): stranded; issue closed without absorbing this memory

## Reference (external systems + tooling)
- [Unrelated](unrelated.md) — not in the ledger section; must be ignored by Class 5
LEDGER

# gh stub: #1001 OPEN, #2002 CLOSED, everything else resolves OPEN. Mirrors the
# `gh issue view N --json {number|state} [--jq .state]` surface Check 36 calls.
STUB="${TMP}/bin"
mkdir -p "$STUB"
cat > "${STUB}/gh" <<'GH'
#!/usr/bin/env bash
# Minimal canned gh: supports `issue view N --json number` (resolution probe) and
# `issue view N --json state --jq .state` (state probe). Unknown N resolves OPEN.
[[ "$1" == "issue" && "$2" == "view" ]] || exit 0
N="$3"
case "$*" in
  *"--json state"*)
    case "$N" in
      2002) echo "CLOSED" ;;
      9999) exit 1 ;;          # a non-resolving number (dead-ref territory)
      *)    echo "OPEN" ;;
    esac
    ;;
  *"--json number"*)
    case "$N" in
      9999) exit 1 ;;          # resolution failure
      *)    echo "$N" ;;
    esac
    ;;
  *) exit 0 ;;
esac
GH
chmod +x "${STUB}/gh"
export PATH="${STUB}:${PATH}"

# assert_class <expected: FLAG|CLEAN> <got-rc:0|1> <label>
assert_class() {
  local _expected="$1" _rc="$2" _label="$3" _got
  if [[ "$_rc" -eq 0 ]]; then _got="FLAG"; else _got="CLEAN"; fi
  if [[ "$_got" == "$_expected" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   [%s] %s\n' "$_got" "$_label"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL want=%s got=%s  (%s)\n' "$_expected" "$_got" "$_label"
  fi
}

echo "── Class 4: dangling-wikilink-to-evicted-memory (local-only) ─────────────"
c36_wikilink_dangles "$MEM" "${MEM}/survivor_links_ghost.md"; assert_class FLAG  "$?" "links [[ghost]] (ghost.md absent) -> FLAG"
c36_wikilink_dangles "$MEM" "${MEM}/survivor_links_real.md";  assert_class CLEAN "$?" "links [[real]] (real.md present) -> CLEAN"

echo ""
echo "── Class 5: ledger-pointer-to-closed-issue (resolution-probing) ──────────"
# Pull the two ledger rows the way deploy.sh does (awk section-slice), then probe.
CLOSED_ROW="$(/usr/bin/awk '/^## Temporary enhancement pointers/{b=1;next} /^## /{b=0} b&&/^- /{print}' "${MEM}/MEMORY.md" | /usr/bin/grep '#2002')"
OPEN_ROW="$(/usr/bin/awk '/^## Temporary enhancement pointers/{b=1;next} /^## /{b=0} b&&/^- /{print}' "${MEM}/MEMORY.md" | /usr/bin/grep '#1001')"
c36_ledger_strands "$CLOSED_ROW"; assert_class FLAG  "$?" "ledger row ties #2002 CLOSED, not evicted -> FLAG"
c36_ledger_strands "$OPEN_ROW";   assert_class CLEAN "$?" "ledger row ties #1001 OPEN -> CLEAN"

echo ""
echo "── Invariant: the synthetic run did not touch the live store ─────────────"
if [[ -d "${HOME}/.claude/memory" ]]; then
  echo "  note  live store present; this test operated only on ${MEM} (tmpdir) — READ-ONLY-on-store preserved by construction"
else
  echo "  note  no live store on this host; test is fully self-contained"
fi
PASS_COUNT=$((PASS_COUNT + 1))

echo ""
echo "── Drift guard: live deploy.sh Check 36 carries both new detectors ───────"
# Assert the load-bearing fragments of each new class still exist verbatim in
# deploy.sh, so a silent edit to Check 36 cannot pass this test stale.
# Fixed-string fragments (grep -F) — distinctive load-bearing substrings of each
# new class's implementation; -F sidesteps BRE/ERE escaping ambiguity.
DRIFT_OK=true
while IFS= read -r _frag; do
  [[ -n "$_frag" ]] || continue
  if ! /usr/bin/grep -qF "$_frag" "$DEPLOY_SH"; then
    DRIFT_OK=false
    printf '  FAIL drift: fragment not found in deploy.sh -> %s\n' "$_frag"
    FAIL_COUNT=$((FAIL_COUNT + 1))
  fi
done <<'FRAGS'
dangling-wikilink-to-evicted-memory
grep -oE '\[\[[a-z0-9_]+\]\]'
${c36_mem_dir}/${c36_target}.md
ledger-pointer-to-closed-issue
^## Temporary enhancement pointers
Phase B-OPS5
FRAGS
# Assert the READ-ONLY invariant comment is still present (load-bearing per the
# encode-and-evict dangling-ref mandate + ADR-029/ADR-045): Check 36 must never
# mutate the store.
if ! /usr/bin/grep -qE 'CRITICAL: this check is READ-ONLY' "$DEPLOY_SH"; then
  DRIFT_OK=false
  printf '  FAIL drift: the READ-ONLY invariant comment is missing from deploy.sh\n'
  FAIL_COUNT=$((FAIL_COUNT + 1))
fi
if [[ "$DRIFT_OK" == "true" ]]; then
  PASS_COUNT=$((PASS_COUNT + 1))
  echo "  ok   live deploy.sh Check 36 Class-4 + Class-5 fragments + READ-ONLY invariant present"
fi

echo ""
echo "─────────────────────────────────────────────────────────────────────────"
printf 'Result: %d passed, %d failed\n' "$PASS_COUNT" "$FAIL_COUNT"
if [[ "$FAIL_COUNT" -gt 0 ]]; then
  echo "Check 36 drift-classes fixture self-test: FAILED"
  exit 1
fi
echo "Check 36 drift-classes fixture self-test: PASSED"
exit 0
