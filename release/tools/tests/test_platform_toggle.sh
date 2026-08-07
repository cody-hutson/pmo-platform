#!/usr/bin/env bash
# test_platform_toggle.sh — truth table for release/tools/lib/platform-toggle.sh.
#
# WHAT IT ASSERTS. The resolver's no-op default is a TERMINAL IN-CODE CONSTANT, not a
# value read from a config file, and its reader is SECTION-AWARE with an `=` terminator.
# Thirteen arms drive every path into the default and every path out of it.
#
# THE LOAD-BEARING PROPERTY, asserted directly rather than implied by the arms:
#   an install that never receives a platform-config.toml,
#   a fresh install carrying only the shipped template default,
#   and an install whose XDG file sets the key explicitly false
# must be BEHAVIOURALLY INDISTINGUISHABLE. Arms 1, 2 and 12 are that proof.
#
# WHY IT CARRIES ITS OWN BROKEN-STATE ARMS. A truth table over a correct implementation
# is consistent with a probe that returns "off" unconditionally — every subject arm would
# still pass. So the suite mutates the library into each of the two shapes it exists to
# rule out and asserts the table turns RED:
#   M1  section-blind, unterminated reader (the shape the pre-fix ceiling readers carry)
#       -> arms 10 / 11 / 13 must flip to `on`
#   M2  terminal default flipped from off to on
#       -> arms 1-7 must flip to `on`
# If a mutation changes nothing, the suite FAILS on that fact alone — a table that cannot
# distinguish a broken resolver from a working one is not evidence, and reporting it as a
# pass is the false-confidence failure the gate-efficacy standard names.
#
# Hermetic: mktemp only. No network, no gh, no git, no write to the checkout, and no read
# of the operator's real ~/.config (PMO_PLATFORM_CONFIG_ROOT is set on every invocation,
# so $HOME is never consulted). Bash 3.2 compatible.

set -uo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$HERE/../../.." && pwd)"
LIB="${PLATFORM_TOGGLE_LIB_UNDER_TEST:-$ROOT/release/tools/lib/platform-toggle.sh}"

SECTION="git_release_automation"
KEY="ci_auto_resolve"

PASS=0; FAIL=0
ok()  { PASS=$((PASS+1)); printf '  PASS  %s\n' "$1"; }
bad() { FAIL=$((FAIL+1)); printf '  FAIL  %s\n' "$1"; }

[ -f "$LIB" ] || { echo "FATAL: library not found at $LIB"; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1; }

TMPROOT="$(mktemp -d)"
trap 'rm -rf "$TMPROOT"' EXIT

# --- fixture builders --------------------------------------------------------------
# mk_src <name> [template-body]  — build a rung-1 src root. No body => no template file.
mk_src() {
  local d="$TMPROOT/src-$1"
  mkdir -p "$d/core/config"
  if [ "$#" -gt 1 ]; then printf '%s\n' "$2" > "$d/core/config/platform-config.toml.template"; fi
  printf '%s' "$d"
}
# mk_cfg <name> [file-body]  — build a rung-5 XDG root. No body => the file is absent.
mk_cfg() {
  local d="$TMPROOT/cfg-$1"
  mkdir -p "$d"
  if [ "$#" -gt 1 ]; then printf '%s\n' "$2" > "$d/platform-config.toml"; fi
  printf '%s' "$d"
}

# resolve <lib> <src_root> <cfg_root>  — one invocation of platform_toggle_state.
resolve() {
  PMO_SRC_ROOT="$2" PMO_PLATFORM_CONFIG_ROOT="$3" \
    /bin/bash -c '. "$1" || exit 9; platform_toggle_state "$2" "$3"' _ "$1" "$SECTION" "$KEY" 2>/dev/null
}

# --- fixture bodies ----------------------------------------------------------------
T_FALSE="[git_release_automation]
review_process_integration = false
ci_auto_resolve = false
comment_auto_resolution = false"
T_TRUE="[git_release_automation]
ci_auto_resolve = true"
T_NOSECTION="[security_hooks]
master_enabled = false"
T_NOKEY="[git_release_automation]
review_process_integration = false
comment_auto_resolution = false"
T_EMPTY="[git_release_automation]
ci_auto_resolve ="
T_YES="[git_release_automation]
ci_auto_resolve = \"yes\""
T_ONE="[git_release_automation]
ci_auto_resolve = 1"
X_TRUE="[git_release_automation]
ci_auto_resolve = true"
X_FALSE="[git_release_automation]
ci_auto_resolve = false"
X_WRONGSECT="[some_other_section]
ci_auto_resolve = true"
X_PREFIX="[git_release_automation]
ci_auto_resolve_extra = true"
X_DOTTED="[git_release_automation.experimental]
ci_auto_resolve = true"

# --- the table: id | description | src fixture | cfg fixture | expected --------------
# Held as parallel arrays (bash 3.2: no associative arrays).
ARM_ID=();  ARM_DESC=(); ARM_SRC=(); ARM_CFG=(); ARM_EXP=()
add_arm() { ARM_ID+=("$1"); ARM_DESC+=("$2"); ARM_SRC+=("$3"); ARM_CFG+=("$4"); ARM_EXP+=("$5"); }

add_arm 1  "no template AND no XDG file (never-received-the-file install)" \
           "$(mk_src a1)"            "$(mk_cfg a1)"            off
add_arm 2  "template false, XDG absent (THE STOCK-INSTANCE STATE)" \
           "$(mk_src a2 "$T_FALSE")" "$(mk_cfg a2)"            off
add_arm 3  "section absent from the template" \
           "$(mk_src a3 "$T_NOSECTION")" "$(mk_cfg a3)"        off
add_arm 4  "section present, key absent" \
           "$(mk_src a4 "$T_NOKEY")" "$(mk_cfg a4)"            off
add_arm 5  "key present with an EMPTY value" \
           "$(mk_src a5 "$T_EMPTY")" "$(mk_cfg a5)"            off
add_arm 6  "malformed value \"yes\"" \
           "$(mk_src a6 "$T_YES")"   "$(mk_cfg a6)"            off
add_arm 7  "malformed value 1" \
           "$(mk_src a7 "$T_ONE")"   "$(mk_cfg a7)"            off
add_arm 8  "SENSITIVITY: template true, XDG absent" \
           "$(mk_src a8 "$T_TRUE")"  "$(mk_cfg a8)"            on
add_arm 9  "SENSITIVITY: template false + XDG true (rung 5 wins upward)" \
           "$(mk_src a9 "$T_FALSE")" "$(mk_cfg a9 "$X_TRUE")"  on
add_arm 10 "SPECIFICITY: XDG true under a DIFFERENT section" \
           "$(mk_src a10 "$T_FALSE")" "$(mk_cfg a10 "$X_WRONGSECT")" off
add_arm 11 "SPECIFICITY: XDG same-PREFIX key ci_auto_resolve_extra = true" \
           "$(mk_src a11 "$T_FALSE")" "$(mk_cfg a11 "$X_PREFIX")"    off
add_arm 12 "template true + XDG false (rung 5 wins downward)" \
           "$(mk_src a12 "$T_TRUE")"  "$(mk_cfg a12 "$X_FALSE")"     off
add_arm 13 "SPECIFICITY: XDG true under the DOTTED SUBTABLE [section.experimental]" \
           "$(mk_src a13 "$T_FALSE")" "$(mk_cfg a13 "$X_DOTTED")"    off

DENOM="${#ARM_ID[@]}"

# run_table <lib> — echo one "id:observed" token per arm, space-separated.
run_table() {
  local i out=""
  for i in $(seq 0 $((DENOM - 1))); do
    out="$out ${ARM_ID[$i]}:$(resolve "$1" "${ARM_SRC[$i]}" "${ARM_CFG[$i]}")"
  done
  printf '%s' "${out# }"
}

echo "=== Subject: the shipped resolver ($LIB) ==="
BASELINE="$(run_table "$LIB")"
for i in $(seq 0 $((DENOM - 1))); do
  observed="$(resolve "$LIB" "${ARM_SRC[$i]}" "${ARM_CFG[$i]}")"
  if [ "$observed" = "${ARM_EXP[$i]}" ]; then
    ok "arm ${ARM_ID[$i]} — ${ARM_DESC[$i]} (= ${ARM_EXP[$i]})"
  else
    bad "arm ${ARM_ID[$i]} — ${ARM_DESC[$i]} — expected [${ARM_EXP[$i]}], observed [$observed]"
  fi
done

echo
echo "=== Behavioural-identity property (arms 1 / 2 / 12) ==="
i1="$(resolve "$LIB" "$(mk_src a1)"            "$(mk_cfg a1)")"
i2="$(resolve "$LIB" "$(mk_src a2 "$T_FALSE")" "$(mk_cfg a2)")"
i12="$(resolve "$LIB" "$(mk_src a12 "$T_TRUE")" "$(mk_cfg a12 "$X_FALSE")")"
if [ "$i1" = "$i2" ] && [ "$i2" = "$i12" ] && [ "$i1" = "off" ]; then
  ok "never-received-the-file == fresh-install == explicitly-false (all '$i1')"
else
  bad "behavioural identity broken — never-received=[$i1] fresh=[$i2] explicit-false=[$i12]"
fi

# --- broken-state arms (gate efficacy) ----------------------------------------------
# Each mutation is applied to a COPY. The checkout is never modified.
echo
echo "=== Broken-state arms — the table must turn RED on each mutation ==="

# M1 — the reader regressed to the pre-fix shape. Expressed as a SHIM that sources the
# real library and then overrides _pt_read_field, rather than as sed surgery on a
# multi-line awk program: a textual patch that silently fails to apply produces a mutant
# identical to the subject, and "the mutation did nothing" reads exactly like "the
# resolver is fine". The override body is the reader block verbatim as the two ceiling
# hooks carried it before this change — section-blind, and with NO `=` terminator, so it
# matches the whole key-name PREFIX class.
M1="$TMPROOT/m1-section-blind.sh"
cat > "$M1" <<M1EOF
. "$LIB"
_pt_read_field() {
  local _pt_file="\$1"; local _pt_sect="\$2"; local _pt_key="\$3"
  [ -n "\$_pt_file" ] && [ -r "\$_pt_file" ] || return 0
  /usr/bin/grep -E "^\${_pt_key}" "\$_pt_file" 2>/dev/null \\
    | /usr/bin/head -1 \\
    | /usr/bin/awk -F= '{gsub(/[" ]/,"",\$2); print \$2}'
}
M1EOF

# M2 — the terminal default flipped. This one IS a textual patch of the real file, because
# the target is a single line and patching the shipped code is the more faithful mutant;
# the applied-check below is what keeps a silent no-op patch from reading as a pass.
M2="$TMPROOT/m2-default-flipped.sh"
/usr/bin/sed -e "s|^    \*)              printf 'off' ;;$|    *)              printf 'on' ;;|" "$LIB" > "$M2"
if /usr/bin/cmp -s "$LIB" "$M2"; then
  bad "M2 recipe — the sed patch applied NOTHING (the terminal-default line moved or changed shape); mutant == subject"
fi

# assert_mutation <label> <mutant> <arm ids that MUST change> ...
assert_mutation() {
  local label="$1"; local mutant="$2"; shift 2
  if ! /bin/bash -n "$mutant" 2>/dev/null; then
    bad "$label — mutant does not parse; the mutation recipe is broken, not the resolver"
    return
  fi
  local mtable; mtable="$(run_table "$mutant")"
  if [ "$mtable" = "$BASELINE" ]; then
    bad "$label — mutant table is IDENTICAL to baseline; this suite cannot see the defect it claims to guard"
    return
  fi
  local id changed_all=1 detail=""
  for id in "$@"; do
    local b m
    b="$(printf '%s' "$BASELINE" | /usr/bin/tr ' ' '\n' | /usr/bin/grep "^${id}:" | /usr/bin/cut -d: -f2)"
    m="$(printf '%s' "$mtable"   | /usr/bin/tr ' ' '\n' | /usr/bin/grep "^${id}:" | /usr/bin/cut -d: -f2)"
    detail="$detail arm${id}[$b->$m]"
    [ "$b" = "$m" ] && changed_all=0
  done
  if [ "$changed_all" = 1 ]; then
    ok "$label — every named arm flips under the mutation:$detail"
  else
    bad "$label — a named arm did NOT flip:$detail"
  fi
}

assert_mutation "M1 section-blind + unterminated reader" "$M1" 10 11 13
assert_mutation "M2 terminal default flipped off->on"    "$M2" 1 2 3 4 5 6 7

echo
echo "================================"
printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
printf 'denominator: %d truth-table arms + 1 identity property + 2 broken-state mutations\n' "$DENOM"
echo "================================"
if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
