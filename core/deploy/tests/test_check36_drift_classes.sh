#!/usr/bin/env bash
# test_check36_drift_classes.sh — fixture self-test for the deploy.sh Check 36
# drift classes that carry fixtures.
# <!-- repo-integrity: allow-memory-ref -->  this test names the ~/.claude/memory store layout it audits.
# <!-- repo-integrity: allow-issue-ref -->  the #NNNN tokens below are SYNTHETIC fixture issue numbers (mapped by the in-test gh stub), not real repo issues.
#
# What this proves: each covered Check 36 detector discriminates correctly —
#   Class 4  dangling-wikilink-to-evicted-memory  (local-only; downstream RE-POINT backstop)
#   Class 5  ledger-pointer-to-closed-issue       (resolution-probing; upstream partial-absorption backstop)
#   Class 6  external-target-referent-stored      (local-only; the ADR-109 §7.1 external-target backstop)
# against a SYNTHETIC memory store and a SYNTHETIC operator.toml built in a
# tmpdir. The real operator store at ${HOME}/.claude/memory and the real
# operator.toml are NEVER touched (READ-ONLY-on-the-store invariant: this test
# mutates only its own tmpdir fixtures and a tmpdir `gh` stub on PATH).
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
#   Class 6 arm-1 FLAG  : the OBSERVED VIOLATION in its PRE-RECONCILIATION form — a
#                         memory declaring the live-read obligation with an enumerated
#                         kind list, and holding those same kinds as values     -> emit
#   Class 6 arm-1 CLEAN : the same note RECONCILED — declaration and kind list still
#                         present, no kind in value position, but incidental
#                         digit-bearing practice tokens present. This is the false
#                         positive a naive "declaration + any value-shaped line"
#                         predicate produces, and flagging the FIX would be worse
#                         than flagging nothing                                 -> silent
#   Class 6 arm-1 CLEAN : an operator-side practice statement that merely NAMES a
#                         target and carries no live-read declaration — not in the
#                         population at all                                     -> silent
#   Class 6 arm-2 FLAG  : a [trackers.<id>] subtable carrying a key outside the
#                         closed schema (ADR-109 Alternative C's relocated cache) -> emit
#   Class 6 arm-2 CLEAN : a [trackers.<id>] carrying ONLY {id, platform, identifier,
#                         scope}. The sanctioned `identifier` address must NOT flag —
#                         it is ON the whitelist, a positive structural exemption   -> silent

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

# Class 6 arm 1: does memory file $1 declare a live-read obligation AND hold one
# of the referent kinds its own declaration enumerates in a value-bearing
# position? (the deploy.sh Arm-1 predicate: declaration-scoped, never
# content-scoped — the check verifies a decomposition the AUTHOR declared, it
# never decides whether something is a target fact).
#
# Output contract, four DISTINGUISHABLE branches (mirrors deploy.sh verbatim):
#   (empty)              the file carries no live-read declaration — NOT in the population
#   UNSCOPED             declared, but the declaration yields no kind list — not evaluated
#   CLEAN                declared, kinds extracted, no kind in value position
#   "<lineno> <kind>"…   one row per violation
# The CLEAN token is load-bearing: without it, "not in the population" and
# "evaluated and held" are the same silence, and the coverage-bound tally in
# deploy.sh reads zero on a store whose declaring files are all in contract.
c36_declared_value_stored() {
  /usr/bin/awk '
    function strip(t) {
      gsub(/^[ \t*_`"\-]+/, "", t); gsub(/[ \t*_`".:;|]+$/, "", t); return t
    }
    function has_literal(s) {
      if (s ~ /[0-9]/) return 1
      if (s ~ /"/) return 1
      if (s ~ /[A-Za-z0-9_-]+:[A-Za-z0-9_-]+/) return 1
      return 0
    }
    { line[NR] = $0 }
    END {
      decl = 0
      for (i = 1; i <= NR && decl == 0; i++) if (line[i] ~ /ADR-109/) decl = i
      if (decl == 0) {
        for (i = 1; i <= NR && decl == 0; i++) {
          l = tolower(line[i])
          if (l ~ /read (it )?live/ || l ~ /live read/ || l ~ /derive live/ ||
              l ~ /do not cache/ || l ~ /never cache/ || l ~ /not be cached/) decl = i
        }
      }
      if (decl == 0) exit 0
      win = line[decl]; wend = decl
      for (i = decl + 1; i <= NR && i <= decl + 2; i++) { win = win " " line[i]; wend = i }
      nk = 0; off = 0
      while (nk == 0) {
        p = index(substr(win, off + 1), "(")
        if (p == 0) break
        p = off + p
        rest = substr(win, p + 1); q = index(rest, ")")
        if (q == 0) break
        off = p + q
        if (p > 1 && substr(win, p - 1, 1) == "]") continue
        inner = substr(rest, 1, q - 1)
        gsub(/·/, ",", inner); gsub(/;/, ",", inner); gsub(/\//, ",", inner)
        n = split(inner, a, ",")
        for (k = 1; k <= n; k++) {
          t = strip(a[k])
          if (length(t) >= 4 && t !~ /[0-9]/ && t !~ /\.(md|sh|py|toml|txt|ya?ml)$/) {
            nk++; kind[nk] = t
          }
        }
      }
      if (nk == 0) { print "UNSCOPED"; exit 0 }
      for (k = 1; k <= nk; k++) {
        kk = tolower(kind[k]); hitline = 0
        for (i = 1; i <= NR && hitline == 0; i++) {
          if (i >= decl && i <= wend) continue
          ll = tolower(line[i])
          pos = index(ll, kk)
          if (pos == 0) continue
          tail = substr(ll, pos + length(kk))
          conn = substr(tail, 1, 6)
          if (conn ~ /^[ \t]*[:=]/ || conn ~ /^[ \t]*-[ \t]/ ||
              conn ~ /^[ \t]*—/ || conn ~ /^[ \t]*→/) {
            if (has_literal(substr(tail, 1, 100))) hitline = i
          }
          if (hitline == 0 && substr(ll, 1, 1) == "|") {
            nc = split(ll, cells, "|")
            for (c = 1; c <= nc && hitline == 0; c++)
              if (index(cells[c], kk) == 0 && has_literal(cells[c])) hitline = i
          }
        }
        if (hitline > 0) { print hitline " " kind[k]; hits++ }
      }
      if (hits == 0) print "CLEAN"
    }
  ' "$1" 2>/dev/null || true
}

# Class 6 arm 2: does operator.toml $1 carry a key in a [trackers.<id>] subtable
# outside the closed {id, platform, identifier, scope} schema? (the deploy.sh
# Arm-2 predicate). The sanctioned `identifier` is ON the whitelist, so it cannot
# flag — a positive structural exemption, not a heuristic carve-out.
c36_unsanctioned_tracker_key() {
  /usr/bin/awk '
    /^[ \t]*#/ { next }
    /^[ \t]*\[trackers\][ \t]*$/ { sec = "trackers"; next }
    /^[ \t]*\[trackers\.[^]]+\][ \t]*$/ {
      sec = $0; sub(/^[ \t]*\[/, "", sec); sub(/\][ \t]*$/, "", sec); next
    }
    /^[ \t]*\[/ { sec = ""; next }
    sec != "" {
      if (match($0, /^[ \t]*[A-Za-z0-9_.-]+[ \t]*=/)) {
        key = substr($0, RSTART, RLENGTH)
        sub(/[ \t]*=$/, "", key); gsub(/^[ \t]+/, "", key)
        if (sec == "trackers") { if (key != "default_id") print NR " " sec " " key }
        else if (key != "id" && key != "platform" && key != "identifier" && key != "scope")
          print NR " " sec " " key
      }
    }
  ' "$1" 2>/dev/null || true
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

# Class-6 arm-1 fixtures. The FLAG case is the OBSERVED VIOLATION in its
# PRE-RECONCILIATION form (AC-6): a note about an external target that declares
# the live-read obligation and, in the same file, holds the very referent kinds
# its declaration enumerates. The note was self-contradictory on its face and
# still went undetected for 19 days — that is the case this class exists to catch.
cat > "${MEM}/c6_flag_pre_reconciliation.md" <<'C6FLAG'
# External-target release model

Runs releases through this platform's release hub. Derive live state on demand — do NOT
cache it here (labels, point scale, size band, close-out DoD).

## Conventions
- point scale: size:S = 1 point, size:M = 3 points, size:L = 5 points
- size band = 18-25 points per release across the three shipped so far
- close-out DoD — "notes published, tag pushed, board column cleared"
C6FLAG

# The RECONCILED form of the SAME note. Declaration present, kind list present,
# no kind in value position — but incidental digit-bearing operator-practice
# tokens present (step numbers, a threshold). A naive "declaration + any
# value-shaped line" predicate flags this, i.e. it flags the FIX. Scoping the
# value probe to the kinds the declaration itself enumerates is what removes it.
cat > "${MEM}/c6_clean_reconciled.md" <<'C6CLEAN1'
# External-target release model

Runs releases through this platform's release hub; that BINDING is all that is stored.
ADR-109: NO target-side fact may be cached (labels, point scale, size band, close-out DoD)
— read live every time.

Run the bundle-composition doctrine's 7 steps (Step 3 dep walk, Step 5 split at the band).
C6CLEAN1

# An operator-side practice statement that merely NAMES a target and declares
# nothing. Not in the population at all — this is the permitted case ADR-109 §1
# distinguishes, and the class that a content-classifying scan would flood.
cat > "${MEM}/c6_clean_practice_only.md" <<'C6CLEAN2'
# Working with the external target repo

I prefer to batch its release work on Fridays and to review 3 PRs at a time.
Its labels and point scale are its own business; I read them when I need them.
C6CLEAN2

# Class-6 arm-2 fixtures: two synthetic operator.toml files in the tmpdir. The
# real operator.toml is never read.
cat > "${TMP}/operator_clean.toml" <<'TOMLCLEAN'
[adapters]
ticketing = "github-issues"

[trackers.personal]
id         = "personal"
platform   = "github-issues"
identifier = "owner/public-repo"
scope      = "public"

[trackers]
default_id = "personal"

# [trackers.commented_out]
# point_scale = "S=1"
TOMLCLEAN

cat > "${TMP}/operator_flag.toml" <<'TOMLFLAG'
[trackers.work]
id          = "work"
platform    = "jira"
identifier  = "PROJ"
scope       = "private"
point_scale = "S=1, M=3, L=5"
size_band   = "18-25"
TOMLFLAG

# CONTROL for the arm-1 CLEAN cases. A CLEAN verdict is evidence only if the
# instrument was live on that exact file shape; otherwise "no declaration found"
# and "declaration held" are indistinguishable. This is the reconciled note with
# ONE declared kind moved back into value position — it MUST flag. If it does
# not, the CLEAN verdicts above are vacuous and this test says so.
cp "${MEM}/c6_clean_reconciled.md" "${MEM}/c6_control_reconciled_mutated.md"
printf -- '- point scale: size:S = 1 point, size:M = 3 points\n' >> "${MEM}/c6_control_reconciled_mutated.md"

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
echo "── Class 6: external-target-referent-stored (local-only, two arms) ───────"
# assert_emits <expected: FLAG|CLEAN|UNSCOPED|NOTINPOP> <predicate output> <label>
# Four expectations, not two. Distinguishing CLEAN from NOTINPOP is the point:
# a predicate that never found any declaration would pass a two-valued
# assertion vacuously on every clean arm.
assert_emits() {
  local _expected="$1" _out="$2" _label="$3" _got
  if   [[ -z "$_out" ]];              then _got="NOTINPOP"
  elif [[ "$_out" == "UNSCOPED" ]];   then _got="UNSCOPED"
  elif [[ "$_out" == "CLEAN" ]];      then _got="CLEAN"
  else                                     _got="FLAG"
  fi
  if [[ "$_got" == "$_expected" ]]; then
    PASS_COUNT=$((PASS_COUNT + 1))
    printf '  ok   [%s] %s\n' "$_got" "$_label"
  else
    FAIL_COUNT=$((FAIL_COUNT + 1))
    printf '  FAIL want=%s got=%s  (%s)\n' "$_expected" "$_got" "$_label"
    [[ -n "$_out" ]] && printf '       output: %s\n' "$_out"
  fi
}

assert_emits FLAG     "$(c36_declared_value_stored "${MEM}/c6_flag_pre_reconciliation.md")" \
  "arm 1: declares live-read over (labels, point scale, size band, close-out DoD) and holds them as values -> FLAG"
assert_emits CLEAN    "$(c36_declared_value_stored "${MEM}/c6_clean_reconciled.md")" \
  "arm 1: same note RECONCILED — declared + kinds extracted, only incidental practice digits -> CLEAN (evaluated, not skipped)"
assert_emits NOTINPOP "$(c36_declared_value_stored "${MEM}/c6_clean_practice_only.md")" \
  "arm 1: practice statement naming a target, no live-read declaration -> NOT IN POPULATION"
assert_emits FLAG     "$(c36_declared_value_stored "${MEM}/c6_control_reconciled_mutated.md")" \
  "arm 1 CONTROL (must trip): reconciled note + one declared kind in value position -> FLAG"
# Arm 2 is two-valued (a key is either on the closed whitelist or it is not), so
# it emits rows or nothing; NOTINPOP is its silent/clean verdict.
assert_emits FLAG     "$(c36_unsanctioned_tracker_key "${TMP}/operator_flag.toml")" \
  "arm 2: [trackers.work] carries point_scale + size_band outside the closed schema -> FLAG"
assert_emits NOTINPOP "$(c36_unsanctioned_tracker_key "${TMP}/operator_clean.toml")" \
  "arm 2: [trackers.personal] carries only {id, platform, identifier, scope} -> silent (the sanctioned identifier must NOT flag)"

echo ""
echo "── Invariant: the synthetic run did not touch the live store ─────────────"
if [[ -d "${HOME}/.claude/memory" ]]; then
  echo "  note  live store present; this test operated only on ${MEM} (tmpdir) — READ-ONLY-on-store preserved by construction"
else
  echo "  note  no live store on this host; test is fully self-contained"
fi
PASS_COUNT=$((PASS_COUNT + 1))

echo ""
echo "── Drift guard: live deploy.sh Check 36 carries every covered detector ───"
# Assert the load-bearing fragments of each covered class still exist verbatim in
# deploy.sh, so a silent edit to Check 36 cannot pass this test stale.
# Fixed-string fragments (grep -F) — distinctive load-bearing substrings of each
# class's implementation; -F sidesteps BRE/ERE escaping ambiguity.
#
# PRESENCE-ONLY IS NOT ENOUGH ON ITS OWN, and the CARDINALITY assertion below is
# what closes that. A presence-only guard is blind to an ADDITIVE edit: adding a
# seventh class preserves every fragment named here, so the guard would pass
# while the newest and least-exercised class shipped unfixtured. That is exactly
# what happened when the sixth class was added — the guard was believed to force
# a fixture update and did not. The cardinality assertion makes the guard fail
# when deploy.sh enumerates a class count this test does not cover, so adding a
# class REQUIRES touching this file.
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
external-target-referent-stored (declared-live-read-with-stored-value)
external-target-referent-stored (unsanctioned-tracker-key)
do not cache
key != "identifier"
FRAGS

# ── Cardinality assertion (the forcing function) ──────────────────────────────
# deploy.sh states its own class count in the Check 36 header enumeration. This
# test declares how many classes it covers. When the two disagree, a class was
# added or removed in deploy.sh without this fixture file being updated — fail,
# and say which side moved. Fail-closed: an unreadable or unmatched header is a
# FAILURE, never a silent pass.
C36_CLASSES_COVERED=6
_c36_declared_word="$(/usr/bin/awk '
  match($0, /^[ \t]*#[ \t]*(Five|Six|Seven|Eight|Nine|Ten) drift classes/) {
    n = split($0, w, " "); for (i = 1; i <= n; i++) if (w[i] ~ /^(Five|Six|Seven|Eight|Nine|Ten)$/) { print tolower(w[i]); exit }
  }' "$DEPLOY_SH")"
case "$_c36_declared_word" in
  five) _c36_declared=5 ;; six) _c36_declared=6 ;; seven) _c36_declared=7 ;;
  eight) _c36_declared=8 ;; nine) _c36_declared=9 ;; ten) _c36_declared=10 ;;
  *)    _c36_declared=0 ;;
esac
if [[ "$_c36_declared" -eq 0 ]]; then
  DRIFT_OK=false
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  FAIL drift: could not read the Check 36 class-count enumeration from deploy.sh\n'
  printf '              (expected a "# <N> drift classes" header line; fail-closed, never a silent pass)\n'
elif [[ "$_c36_declared" -ne "$C36_CLASSES_COVERED" ]]; then
  DRIFT_OK=false
  FAIL_COUNT=$((FAIL_COUNT + 1))
  printf '  FAIL drift: deploy.sh Check 36 enumerates %d drift classes; this fixture covers %d.\n' \
    "$_c36_declared" "$C36_CLASSES_COVERED"
  printf '              A class was added or removed without updating this file. Add its FLAG and\n'
  printf '              CLEAN fixtures, its predicate copy, its FRAGS entries, and bump\n'
  printf '              C36_CLASSES_COVERED.\n'
else
  PASS_COUNT=$((PASS_COUNT + 1))
  printf '  ok   cardinality: deploy.sh enumerates %d drift classes and this fixture covers %d\n' \
    "$_c36_declared" "$C36_CLASSES_COVERED"
fi
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
  echo "  ok   live deploy.sh Check 36 Class-4 + Class-5 + Class-6 fragments + READ-ONLY invariant present"
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
