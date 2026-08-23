#!/bin/bash
# tests/prime-autonomy-ceiling-cache.test.sh — first test coverage for the SessionStart
# autonomy-ceiling primer, and for the operator.toml reader BOTH ceiling hooks share.
#
# WHY THIS HOOK NEEDS ITS OWN SUITE, stated first because the intuitive priority is the
# other way round. block-autonomy-ceiling.sh is the hook that blocks tool calls, so it
# reads as the higher-risk of the pair — but its ceiling check declares
# MASTER_ENABLE_CLASS="workflow" and therefore goes INERT on the shipped master-OFF
# default. This primer carries NO master gate and runs on EVERY SessionStart. It is the
# always-live path. Before this file existed it had zero tests, and the sibling suite set
# the ceiling only through the cache file — so neither hook's operator.toml reader was
# exercised anywhere.
#
# WHAT IT ASSERTS, in three layers that are deliberately not collapsed:
#   1. STRUCTURAL anti-drift — the resolve_level_direct twin block is byte-identical in
#      the two hooks. Located by its BEGIN/END TWIN markers, never by line number.
#   2. BEHAVIOURAL anti-drift — both extracted twins resolve identically on all 15
#      fixtures. This is the assertion that still holds if someone reformats one copy.
#   3. CACHE-vs-LIVE agreement — the numeric ceiling the real primer WRITES equals the
#      numeric map of what the reader RESOLVES, on every fixture. A divergence here is
#      the failure mode that hardening only one of the two hooks would have created.
#
# THE FIXTURE SET (A-O + absent-file) is the section-awareness matrix. Four inputs
# changed verdict when the readers were hardened, and all four moved fail-OPEN ->
# fail-restrictive:
#   B  exact-name key under another section, sorting BEFORE [automation]
#   C  same-PREFIX key (automation_level_ci_autoresolve) under another section
#   K  dotted subtable header [automation.experimental]
#   O  same-PREFIX key INSIDE [automation], above the real key
# Fixture D is the one that explains why the defect survived so long: the same collision
# sorting AFTER [automation] was already harmless, so the bug was file-ORDER dependent
# and invisible to casual testing.
#
# WHY O IS NOT A DUPLICATE OF C — and why this suite was incomplete without it. The
# hardened reader closes the prefix class with TWO independent mechanisms: section
# awareness, and an "=" terminator on the key match. C exercises only the first. Its
# prefix key sits under [aaa_other], so the section boundary alone already excludes it
# and the terminator is never consulted — meaning the terminator could be deleted and
# every fixture A-N would still resolve exactly as expected. O puts the prefix key
# INSIDE [automation], where section awareness cannot help and ONLY the terminator can
# reject it. Deleting the terminator flips O from off(0) to bounded_auto(2) — the
# fail-OPEN reopened — so the suite now goes RED for a regression it previously could
# not see. A gate that goes green without asserting an invariant it claims is a defect,
# not a pass (core/standards/gate-efficacy-standard.md).
#
# G and H are the deliberate NON-changes: two shapes of VALID in-section TOML (an inline
# trailing comment, an indented key) that both readers mis-parse, identically, onto the
# `recommend` default. Correcting them would RAISE the resolved ceiling for an operator
# who changed nothing — a security-posture widening, which must ship as its own visible
# change and not as a side effect of a hardening patch. They are asserted UNCHANGED so
# that a later permissive "fix" cannot land silently.
#
# NOT VACUOUS BY CONSTRUCTION: the suite reverts the reader to its pre-fix shape in a
# throwaway copy and asserts B / C / K / O flip back to bounded_auto(2). A matrix that cannot
# tell the hardened reader from the broken one is not evidence, and this suite FAILS
# rather than reporting a pass if the mutation changes nothing.
#
# Hermetic: mktemp only. HOME is pinned per fixture, so the operator's real
# ~/.config and ~/.cache are never read or written.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
PRIMER="${HOOK_DIR}/prime-autonomy-ceiling-cache.sh"
BLOCK="${HOOK_DIR}/block-autonomy-ceiling.sh"

PASS=0
FAIL=0
ok()  { PASS=$((PASS + 1)); /usr/bin/printf 'PASS: %s\n' "$1"; }
bad() { FAIL=$((FAIL + 1)); /usr/bin/printf 'FAIL: %s\n' "$1"; }

if [ ! -f "$PRIMER" ]; then echo "FAIL: primer not found at $PRIMER" >&2; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1; fi
if [ ! -f "$BLOCK" ];  then echo "FAIL: block hook not found at $BLOCK" >&2; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1; fi

SBX="$(/usr/bin/mktemp -d)"
trap '/bin/rm -rf "$SBX"' EXIT

# --- twin extraction (by MARKER, never by line number) ------------------------------
extract_twin() { /usr/bin/awk '/^# BEGIN TWIN: resolve_level_direct$/,/^# END TWIN: resolve_level_direct$/' "$1"; }

TWIN_BLOCK="${SBX}/twin-block.txt"
TWIN_PRIMER="${SBX}/twin-primer.txt"
extract_twin "$BLOCK"  > "$TWIN_BLOCK"
extract_twin "$PRIMER" > "$TWIN_PRIMER"

# The extraction must be non-empty, or every assertion below would compare nothing to
# nothing and pass. This is the probe-validity guard, not a formality.
tb_lines="$(/usr/bin/wc -l < "$TWIN_BLOCK" | /usr/bin/tr -d ' ')"
tp_lines="$(/usr/bin/wc -l < "$TWIN_PRIMER" | /usr/bin/tr -d ' ')"
if [ "$tb_lines" -gt 10 ] && [ "$tp_lines" -gt 10 ]; then
  ok "twin markers resolve in both hooks (block=${tb_lines} lines, primer=${tp_lines} lines)"
else
  bad "twin markers did not resolve (block=${tb_lines} lines, primer=${tp_lines}) — the marker was renamed; every assertion below would be vacuous"
  echo "Total: $((PASS + FAIL))  PASS: ${PASS}  FAIL: ${FAIL}"
  exit 1
fi

# --- LAYER 1: structural anti-drift -------------------------------------------------
if /usr/bin/diff -q "$TWIN_BLOCK" "$TWIN_PRIMER" >/dev/null 2>&1; then
  ok "LAYER 1 structural anti-drift: resolve_level_direct is BYTE-IDENTICAL in both hooks"
else
  bad "LAYER 1 structural anti-drift: the two resolve_level_direct copies DIVERGED — edit both or neither"
fi

# --- fixtures -----------------------------------------------------------------------
# mk_toml <id> <body>  — write a fixture operator.toml, echo its path. Body "" => absent.
mk_toml() {
  local d="${SBX}/fx-$1"
  /bin/mkdir -p "$d"
  if [ -n "$2" ]; then /usr/bin/printf '%s\n' "$2" > "${d}/operator.toml"; fi
  /usr/bin/printf '%s' "${d}/operator.toml"
}

FX_ID=(); FX_DESC=(); FX_TOML=(); FX_LEVEL=(); FX_NUM=()
add_fx() { FX_ID+=("$1"); FX_DESC+=("$2"); FX_TOML+=("$(mk_toml "$1" "$3")"); FX_LEVEL+=("$4"); FX_NUM+=("$5"); }

add_fx A "plain in-section read" \
  '[automation]
automation_level = "off"' off 0

add_fx B "exact-name key under ANOTHER section, sorting BEFORE [automation] (was fail-OPEN)" \
  '[aaa_other]
automation_level = "bounded_auto"

[automation]
automation_level = "off"' off 0

add_fx C "same-PREFIX key automation_level_ci_autoresolve under another section (was fail-OPEN)" \
  '[aaa_other]
automation_level_ci_autoresolve = "bounded_auto"

[automation]
automation_level = "off"' off 0

add_fx D "same collision sorting AFTER [automation] — already harmless (why the bug hid)" \
  '[automation]
automation_level = "off"

[zzz_other]
automation_level = "bounded_auto"' off 0

add_fx E "no [automation] section at all" \
  '[identity]
operator_github = "fixture-handle"' recommend 1

add_fx F "[automation] present, automation_level absent" \
  '[automation]
some_other_key = "x"' recommend 1

add_fx G "UNCHANGED: inline trailing comment inside [automation] (mis-parsed, fail-restrictive)" \
  '[automation]
automation_level = "bounded_auto"  # operator note' recommend 1

add_fx H "UNCHANGED: indented key inside [automation] (off the column-0 anchor)" \
  '[automation]
  automation_level = "bounded_auto"' recommend 1

add_fx I "malformed value outside the enum" \
  '[automation]
automation_level = "turbo"' recommend 1

add_fx J "empty value" \
  '[automation]
automation_level =' recommend 1

add_fx K "dotted subtable [automation.experimental] (was fail-OPEN)" \
  '[automation.experimental]
automation_level = "bounded_auto"

[automation]
automation_level = "off"' off 0

add_fx L "duplicate [automation] sections — first match wins, both readers" \
  '[automation]
automation_level = "off"

[automation]
automation_level = "bounded_auto"' off 0

# M is a multi-section operator.toml carrying NO [automation] table. That was the LIVE
# stock shape only until v4.23; since then setup-workspace.sh seeds [automation] with
# automation_level = "recommend", so this body is now the PRE-v4.23 install shape — and
# what remains if an operator deletes the table from a current install. The fallback it
# asserts is unchanged, and is the same value the installer now writes explicitly.
add_fx M "multi-section file with no [automation] table (the pre-v4.23 install shape)" \
  '[meta]
schema_version = 1

[identity]
operator_github = "fixture-handle"

[paths]
workspace = "/fixture/ws"

[platform]
work_board = "github"' recommend 1

add_fx N "NEGATIVE CONTROL: a valid bounded_auto must still resolve bounded_auto(2)" \
  '[automation]
automation_level = "bounded_auto"' bounded_auto 2

# O is the TERMINATOR arm — the only fixture in this set that section-awareness alone
# cannot satisfy. The prefix key is IN the target section and sorts above the real key,
# so the reader reaches it first and must reject it on the "=" terminator or not at all.
add_fx O "same-PREFIX key INSIDE [automation], above the real key — only the \"=\" terminator rejects it" \
  '[automation]
automation_level_ci_autoresolve = "bounded_auto"
automation_level = "off"' off 0

add_fx Z "operator.toml ABSENT entirely" "" recommend 1

DENOM="${#FX_ID[@]}"

# --- runners ------------------------------------------------------------------------
# run_twin <twin-file> <operator.toml path> — execute the extracted reader in isolation.
run_twin() {
  local runner="${SBX}/run-$$.sh"
  { /bin/cat "$1"; /usr/bin/printf 'resolve_level_direct\n'; } > "$runner"
  OPERATOR_TOML="$2" /bin/bash "$runner" 2>/dev/null
  /bin/rm -f "$runner"
}

# run_primer <operator.toml path> — execute the REAL primer end-to-end, echo the cache.
run_primer() {
  local h="${SBX}/home-$$-$RANDOM"
  /bin/mkdir -p "${h}/.config/pmo-platform"
  [ -f "$1" ] && /bin/cp "$1" "${h}/.config/pmo-platform/operator.toml"
  HOME="$h" /bin/bash "$PRIMER" >/dev/null 2>&1
  if [ -r "${h}/.cache/pmo-platform/autonomy-ceiling" ]; then
    /bin/cat "${h}/.cache/pmo-platform/autonomy-ceiling" | /usr/bin/tr -d '[:space:]'
  else
    /usr/bin/printf 'NO-CACHE'
  fi
  /bin/rm -rf "$h"
}

# --- LAYER 2: behavioural anti-drift + the resolved-level matrix ---------------------
echo ""
echo "--- resolved level, both twins, all ${DENOM} fixtures ---"
i=0
while [ "$i" -lt "$DENOM" ]; do
  id="${FX_ID[$i]}"; desc="${FX_DESC[$i]}"; toml="${FX_TOML[$i]}"; want="${FX_LEVEL[$i]}"
  got_b="$(run_twin "$TWIN_BLOCK" "$toml")"
  got_p="$(run_twin "$TWIN_PRIMER" "$toml")"
  if [ "$got_b" = "$want" ]; then
    ok "fixture ${id} — ${desc} => ${want}"
  else
    bad "fixture ${id} — ${desc} — expected [${want}], observed [${got_b}]"
  fi
  if [ "$got_b" = "$got_p" ]; then
    ok "fixture ${id} — LAYER 2 behavioural anti-drift: both twins agree (${got_b})"
  else
    bad "fixture ${id} — LAYER 2 behavioural anti-drift: block=[${got_b}] primer=[${got_p}]"
  fi
  i=$((i + 1))
done

# --- LAYER 3: cache-vs-live agreement (the real primer, end to end) -----------------
echo ""
echo "--- cache written by the REAL primer vs the resolved numeric ceiling ---"
i=0
while [ "$i" -lt "$DENOM" ]; do
  id="${FX_ID[$i]}"; toml="${FX_TOML[$i]}"; wantnum="${FX_NUM[$i]}"
  cached="$(run_primer "$toml")"
  if [ "$cached" = "$wantnum" ]; then
    ok "fixture ${id} — LAYER 3 primer cache = ${wantnum}"
  else
    bad "fixture ${id} — LAYER 3 primer cache — expected [${wantnum}], observed [${cached}]"
  fi
  i=$((i + 1))
done

# --- primer liveness invariants -----------------------------------------------------
# The primer must NEVER block session start. Assert exit 0 and an unwritable cache dir.
unread="${SBX}/unreadable"; /bin/mkdir -p "${unread}/.config/pmo-platform"
/usr/bin/printf '[automation]\nautomation_level = "off"\n' > "${unread}/.config/pmo-platform/operator.toml"
/bin/chmod 000 "${unread}/.config/pmo-platform/operator.toml" 2>/dev/null
ur_exit=0; HOME="$unread" /bin/bash "$PRIMER" >/dev/null 2>&1 || ur_exit=$?
/bin/chmod 644 "${unread}/.config/pmo-platform/operator.toml" 2>/dev/null
if [ "$ur_exit" = 0 ]; then
  ok "primer exits 0 on an UNREADABLE operator.toml (never blocks session start)"
else
  bad "primer exited ${ur_exit} on an unreadable operator.toml — it must never block session start"
fi

ur2="$(run_primer "$(mk_toml UR '[automation]
automation_level = "bounded_auto"')")"
if [ "$ur2" = "2" ]; then
  ok "primer liveness sanity: a readable bounded_auto still caches 2 (the unreadable arm above is discriminating)"
else
  bad "primer liveness sanity: expected cache 2, observed [${ur2}]"
fi

# --- BROKEN-STATE ARM (gate efficacy) -----------------------------------------------
# Revert the reader to its pre-fix shape in a throwaway copy and assert the matrix turns
# red. If the mutation changes nothing, this suite cannot see the defect it guards, and
# saying so is the only honest verdict.
echo ""
echo "--- broken-state arm: the pre-fix section-blind reader must reopen B / C / K / O ---"
PREFIX_TWIN="${SBX}/twin-prefix.txt"
/bin/cat > "$PREFIX_TWIN" <<'PREEOF'
resolve_level_direct() {
  local level="recommend"
  if [ -r "$OPERATOR_TOML" ]; then
    local parsed
    parsed="$(/usr/bin/grep -E '^automation_level' "$OPERATOR_TOML" 2>/dev/null | /usr/bin/head -1 | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}')"
    case "$parsed" in off|recommend|bounded_auto) level="$parsed" ;; esac
  fi
  /usr/bin/printf '%s' "$level"
}
PREEOF

reopened=""
reopened_n=0
unchanged_ok=1
i=0
while [ "$i" -lt "$DENOM" ]; do
  id="${FX_ID[$i]}"; toml="${FX_TOML[$i]}"
  old="$(run_twin "$PREFIX_TWIN" "$toml")"
  new="$(run_twin "$TWIN_BLOCK" "$toml")"
  case "$id" in
    B|C|K|O)
      if [ "$old" = "bounded_auto" ] && [ "$new" != "bounded_auto" ]; then
        reopened="${reopened} ${id}[${old}->${new}]"
        reopened_n=$((reopened_n + 1))
      else
        unchanged_ok=0
        bad "broken-state arm: fixture ${id} did not demonstrate the fail-OPEN closure (pre=[${old}] post=[${new}])"
      fi
      ;;
    *)
      if [ "$old" != "$new" ]; then
        bad "broken-state arm: fixture ${id} changed verdict (pre=[${old}] post=[${new}]) — strict parity claims only B/C/K change"
        unchanged_ok=0
      fi
      ;;
  esac
  i=$((i + 1))
done
if [ "$unchanged_ok" = 1 ] && [ -n "$reopened" ]; then
  ok "broken-state arm: the pre-fix reader resolves bounded_auto on${reopened}; every other fixture is byte-identical (strict parity: ${reopened_n} of ${DENOM} changed, all fail-OPEN -> fail-restrictive)"
fi

# =====================================================================
# Summary
# =====================================================================
echo ""
echo "================================"
/usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
/usr/bin/printf 'denominator: %d fixtures x (level + twin-agreement + primer-cache) + 4 structural/liveness + 1 broken-state arm\n' "$DENOM"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
