#!/bin/bash
# command-position-fp-control.test.sh — false-positive CONTROL ARM for the shared
# command-start canonicalizer (lib/command-position.awk, #5644 / #5653 AC4).
#
# WHAT IT ASSERTS
#   Canonicalization newly blocks ZERO legitimate non-destructive commands. That is a
#   ZERO-claim, and a zero is only readable next to a control arm that fires — so this
#   file is built as a differential with a self-arming sentinel, not as a bare scan.
#
# WHY IT READS THE CANONICALIZER BOUNDARY AND NOT A HOOK VERDICT
# --------------------------------------------------------------
# DO NOT "helpfully" convert this into an end-to-end hook test. That change would
# reintroduce the exact vacuity this file exists to avoid, for two independent reasons:
#
#   (1) VACUOUS PASS. The four anchor-carrying hooks sit behind lib/scope-guard.sh. With
#       no workspace root resolvable, the payload cwd falls out of scope and the hook
#       exits BEFORE any rule runs. Every false-positive assertion then passes because
#       nothing was evaluated — "not newly blocked" is trivially true of a guard that
#       never ran. An FP arm that cannot tell "nothing was blocked" from "nothing ran"
#       asserts nothing.
#   (2) A RED BASELINE THIS FILE DOES NOT OWN. In the ONLY configuration where the
#       fs-boundary hook is armed (CLAUDE_WORKSPACE_ROOT set), block-fs-boundary.test.sh
#       reports 42/48 with all six failures being `allowed`-expectation arms — i.e. the
#       false-positive class itself, already red, for allowed-root/environment-resolution
#       reasons tracked separately (#6193). Sourcing an FP verdict from that suite's exit
#       status would grade this control arm on a defect it did not cause.
#
# So the verdict-bearing measurement is taken one layer down, at the canonicalizer
# boundary: each payload is evaluated RAW and CANONICALIZED against the same anchor +
# verb pattern the hooks themselves use. That has NO scope-guard dependency, cannot be
# vacuously greened by #6193, and attributes exactly — a differential across one variable
# isolates THIS change's contribution, which is what "newly blocked" means.
#
# THE FOUR LIMBS (A makes B, C and D readable)
#   A — ARMING SENTINEL. A must-detect payload (a sudo-prefixed recursive-force deletion
#       of an absolute path) must be invisible to the raw anchor and visible after
#       canonicalization. If it is not, the file emits INSTRUMENT-UNARMED and FAILS. It
#       never reports a pass on an instrument that did not demonstrably run. This is also
#       the sensitivity arm on the differential itself: it proves the differential CAN
#       register a change, so a 0 over the corpus is a measured 0 and not a dead probe.
#   B — FP POPULATION. Payloads whose matcher verb is present only as CONTENT (quoted
#       shell text, a sed/grep program, a Python literal, a commit message, a `--rm` flag,
#       a hyphenated substring) plus verb-free payloads must produce ZERO matches after
#       canonicalization. This is the specificity arm: it fails loudly if the pattern
#       degenerates into one that matches everything, which would otherwise make limb C
#       pass vacuously (raw=yes everywhere ⇒ newly=0).
#   C — DIFFERENTIAL. Over EVERY payload, count(match_after AND NOT match_before) == 0.
#       This is the AC4 predicate.
#   D — START LIVENESS. Payloads that legitimately BEGIN with a matcher verb — including
#       the variable-bearing operand shapes across the nine verbs #5555 re-scoped from
#       refused to allowed (cat, cp, tail, head, tee, mv, base64, more, od) — must match
#       RAW. Without this, a corpus entry that matches nothing at all would silently
#       contribute nothing to limb C, and the #5555 population would be decorative rather
#       than measured. Limb D is what makes INT-1 a real assertion.
#
# ORDERING (INT-1). This arm is meaningful only AFTER #5555 lands. #5555 moves roughly
# 4,496 variable-bearing operands across nine verbs from refused to allowed, so those
# shapes ENTER this file's false-positive population. Graded against a pre-#5555 baseline
# the arm would pass without ever testing them.
#
# WHAT IT DOES NOT CLAIM. This measures the POSITIONAL axis — where the anchor believes a
# command starts — not a per-hook end-to-end verdict. Each rule adds its own terminator
# classes and token extractors on top, so per-hook figures differ by construction. A pass
# here is not a hook-level guarantee, and it is not class closure for the residuals the
# canonicalizer declares (nested/deferred program strings, find -exec/-delete, heredoc
# bodies).
#
# Harness contract: named *.test.sh → auto-discovered by test-runner.sh; materialized into
# the CI sandbox by setup-ci-layout.sh (which co-locates lib/command-position.awk). Emits
# the `Total: N  PASS: N  FAIL: N` summary line and exits 1 on any FAIL. Also emits a
# single AC4-TIER1-VERDICT line — read THAT for the AC4 disposition, not the enclosing
# runner's aggregate. bash 3.2-safe (no associative arrays, no arrays).

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
CMDPOS_AWK="${HOOK_DIR}/lib/command-position.awk"

PASS=0
FAIL=0
pass() { /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1)); }
fail() { /usr/bin/printf 'FAIL: %s\n' "$1"; FAIL=$((FAIL + 1)); }

# Verdict accumulators (reported on the AC4-TIER1-VERDICT line).
ARMED="no"
N_CORPUS=0
N_NEWLY=0
N_FPMATCH=0
N_START=0
N_START_LIVE=0
# Informational, not an assertion: payloads the RAW anchor matched and the canonicalized
# form does not. These are pre-existing false positives that quote-neutralisation REMOVES
# (a `|` or `;` inside a quoted sed/grep program is not a command separator). Reported so
# the differential is legible in both directions rather than only the direction AC4 gates
# on — a control arm that can only see one sign of change is half an instrument.
N_FPREMOVED=0
# Declared tightenings (#8314): payloads canonicalization newly matches ON PURPOSE — a
# shape the readiness text declares as a refusal it now adds. Counted here and NOT in
# N_NEWLY, so an intended tightening cannot fail the AC4 predicate; and each one must still
# be newly matched, so a declaration that no longer describes the canonicalizer fails as
# stale instead of excusing nothing.
N_DECLARED=0

verdict_and_exit() {
  echo ""
  echo "--------------------------------"
  if [ "$ARMED" = "yes" ]; then
    /usr/bin/printf 'AC4-TIER1-VERDICT: armed=yes corpus=%d newly-blocked=%d declared=%d fp-matches=%d fp-removed=%d start-live=%d/%d\n' \
      "$N_CORPUS" "$N_NEWLY" "$N_DECLARED" "$N_FPMATCH" "$N_FPREMOVED" "$N_START_LIVE" "$N_START"
  else
    /usr/bin/printf 'AC4-TIER1-VERDICT: INSTRUMENT-UNARMED — no verdict. corpus=%d newly-blocked=%d (UNREADABLE)\n' \
      "$N_CORPUS" "$N_NEWLY"
  fi
  echo "--------------------------------"
  echo ""
  echo "================================"
  /usr/bin/printf 'Total: %d  PASS: %d  FAIL: %d\n' $((PASS + FAIL)) "$PASS" "$FAIL"
  echo "================================"
  if [ "$FAIL" -gt 0 ]; then exit 1; fi
  exit 0
}

echo "================================"
echo "command-position-fp-control.test.sh — canonicalizer false-positive control arm"
echo "hooks dir: $HOOK_DIR"
echo "================================"

# --- (0) TOOLCHAIN + PRIMITIVE PRESENT ------------------------------------------------
# The absolute /usr/bin paths are deliberate. A PATH-resolved `grep` may be a different
# engine (ugrep is a common local shadow) which can REJECT a POSIX-ERE pattern and return
# a plausible zero — the precise failure this file is built to make impossible.
if [ ! -x /usr/bin/grep ] || [ ! -x /usr/bin/awk ]; then
  fail "toolchain missing: /usr/bin/grep and /usr/bin/awk are both required"
  verdict_and_exit
fi
if [ ! -r "$CMDPOS_AWK" ]; then
  fail "canonicalizer missing at lib/command-position.awk (sandbox/layout broken)"
  verdict_and_exit
fi
pass "toolchain present and canonicalizer readable at lib/command-position.awk"

# --- (1) ANCHOR DERIVED FROM THE HOOK SOURCES -----------------------------------------
# Never hardcode the anchor here. A hardcoded copy is how this arm would silently start
# measuring an anchor the hooks no longer use, keep reporting PASS, and stop testing
# anything. Derive it, and assert the hooks agree on one value.
ANCHOR_LINES="$(/usr/bin/sed -nE "s/^readonly ANCHOR_PREFIX_BASH='(.*)'\$/\1/p" "$HOOK_DIR"/block-*.sh 2>/dev/null)"
n_anchor="$(/usr/bin/printf '%s\n' "$ANCHOR_LINES" | /usr/bin/grep -c . || true)"
ANCHOR="$(/usr/bin/printf '%s\n' "$ANCHOR_LINES" | /usr/bin/sort -u | /usr/bin/sed -n '1p')"
n_uniq="$(/usr/bin/printf '%s\n' "$ANCHOR_LINES" | /usr/bin/sort -u | /usr/bin/grep -c . || true)"

if [ -z "$ANCHOR" ]; then
  fail "anchor derivation returned EMPTY — no hook declares ANCHOR_PREFIX_BASH (instrument would match everywhere)"
  verdict_and_exit
fi
if [ "$n_anchor" -ge 4 ]; then
  pass "anchor derived from $n_anchor hook source(s) (no hardcoded copy)"
else
  fail "anchor found in only $n_anchor hook source(s); the four anchor-carrying hooks (block-destructive, block-egress, block-fs-boundary, block-rm-prefer-trash) must each declare it"
fi
if [ "$n_uniq" -eq 1 ]; then
  pass "all anchor-carrying hooks declare a byte-identical anchor"
else
  fail "anchor DIVERGED across hooks ($n_uniq distinct values) — this arm can no longer speak for all four"
fi

# --- (2) MATCHER --------------------------------------------------------------------
# The command-start detection form is the hooks' own:
#     "${ANCHOR_PREFIX_BASH}${verb}([[:space:]]+|$)"
# (block-fs-boundary.sh check_verb; block-rm-prefer-trash.sh rule arms).
#
# The verb set is deliberately the UNION across the anchor-carrying hooks rather than any
# single hook's list: the destructive/trash class, plus the nine verbs #5555 re-scoped.
# A union makes the false-positive assertion STRICTLY HARDER — more ways for a legitimate
# command to be caught — which is the correct direction for a control arm.
#
# The union widens with the canonicalizer's reach (#8314): every verb an anchored rule of the
# four hooks guards behind the newly walked faces — the remaining read verbs of the egress
# and filesystem-boundary rules, the egress transfer verbs, and the deletion hook's Trash
# verbs. A wider union makes the same predicate strictly harder again.
VERBS='rm|rmdir|unlink|shred|dd|cat|cp|tail|head|tee|mv|base64|more|od|less|xxd|hexdump|strings|bat|view|curl|wget|nc|ncat|scp|rsync|ssh|trash|osascript'
MATCH_RE="${ANCHOR}(${VERBS})([[:space:]]+|\$)"

# match_re(command) -> 0 when the verb pattern matches at a recognised command start.
match_re() {
  /usr/bin/grep -qE "$MATCH_RE" <<<"$1"
}

# canonicalize(command) -> the canonicalized text on stdout.
canonicalize() {
  /usr/bin/printf '%s' "$1" | /usr/bin/awk -f "$CMDPOS_AWK" 2>/dev/null
}

# canonicalize_exit(command) -> the canonicalizer's EXIT VIEW on stdout (#8314): the form
# the allow-on-match exits read, which keeps the walk as it stood before the wrapper grammar.
canonicalize_exit() {
  /usr/bin/printf '%s' "$1" | /usr/bin/awk -v CMDPOS_VIEW=exit -f "$CMDPOS_AWK" 2>/dev/null
}

# --- (3) LIMB A — ARMING SENTINEL ------------------------------------------------------
# A sudo-prefixed recursive-force deletion of an absolute path. `sudo` is a bounded prefix
# word, so the verb sits at a genuine command start that the RAW anchor cannot see and the
# canonicalizer promotes. Both halves must hold, or the instrument is not armed.
SENTINEL_CMD='sudo rm -rf /var/tmp/pmo-ac4-sentinel-target'
SENTINEL_CANON="$(canonicalize "$SENTINEL_CMD")"

sent_raw="no"; sent_can="no"
if match_re "$SENTINEL_CMD"; then sent_raw="yes"; fi
if match_re "$SENTINEL_CANON"; then sent_can="yes"; fi

if [ "$SENTINEL_CANON" != "$SENTINEL_CMD" ] && [ -n "$SENTINEL_CANON" ]; then
  pass "[A] canonicalizer is LIVE (sentinel text transformed, not echoed back)"
else
  fail "[A] canonicalizer did NOT transform the sentinel — a silently no-op primitive makes every differential a trivial zero"
fi

if [ "$sent_raw" = "no" ] && [ "$sent_can" = "yes" ]; then
  ARMED="yes"
  pass "[A] ARMING SENTINEL fired: raw=no canonicalized=yes — the differential can register a change"
else
  /usr/bin/printf 'INSTRUMENT-UNARMED: sentinel raw=%s canonicalized=%s (required raw=no, canonicalized=yes)\n' "$sent_raw" "$sent_can"
  /usr/bin/printf 'INSTRUMENT-UNARMED: the false-positive counts below are NOT a pass — they are unreadable.\n'
  fail "[A] INSTRUMENT-UNARMED — arming sentinel did not fire; no AC4 verdict is available from this run"
fi

# Limb A, per face (#8314). The same must-detect deletion behind each face the canonicalizer
# now walks: a wrapper option with its argument, an absolute-path wrapper, a wrapper that
# joined the set, a wrapper flag, and a condition position. Each must be invisible to the
# raw anchor and visible after canonicalization, or the differential cannot register that
# face and a zero below would say nothing about it.
face_sentinel() { # $1 = label  $2 = command
  _fr="no"; _fc="no"
  if match_re "$2"; then _fr="yes"; fi
  if match_re "$(canonicalize "$2")"; then _fc="yes"; fi
  if [ "$_fr" = "no" ] && [ "$_fc" = "yes" ]; then
    pass "[A/face] sentinel fired (raw=no canonicalized=yes): $1"
  else
    fail "[A/face] sentinel did NOT fire (raw=${_fr} canonicalized=${_fc}, required no/yes): $1"
  fi
}
face_sentinel "nice with its adjustment"  'nice -n 10 rm -rf /var/tmp/pmo-ac4-sentinel-target'
face_sentinel "absolute-path env"         '/usr/bin/env rm -rf /var/tmp/pmo-ac4-sentinel-target'
face_sentinel "timeout with its duration" 'timeout 5 rm -rf /var/tmp/pmo-ac4-sentinel-target'
face_sentinel "stdbuf with its option"    'stdbuf -o0 rm -rf /var/tmp/pmo-ac4-sentinel-target'
face_sentinel "sudo with its user"        'sudo -u root rm -rf /var/tmp/pmo-ac4-sentinel-target'
face_sentinel "sudo with a flag"          'sudo -n rm -rf /var/tmp/pmo-ac4-sentinel-target'
face_sentinel "an if condition"           'if rm -rf /var/tmp/pmo-ac4-sentinel-target ; then :; fi'

# --- (4) CORPUS + LIMBS B / C / D ------------------------------------------------------
# check_case <class> <label> <command>
#   CONTENT — a matcher verb is present but only as content / not at a command start.
#   NOVERB  — no matcher verb at all (specificity).
#   START   — a legitimate command that genuinely begins with a matcher verb, including
#             the #5555 variable-bearing operand shapes.
#   NEAR    — a matcher verb one token from a command start that is not one: an option
#             value or positional a wrapper's own grammar consumes, a describe-only
#             option's operand, or an argument of the real command (#8314).
#   DECLARED — a shape the readiness text declares as a refusal canonicalization ADDS
#             (#8314: xargs behind its own option, heredoc-body prose behind a wrapper).
#             It must be newly matched, and is counted apart from limb C's zero.
check_case() {
  _cls="$1"; _lbl="$2"; _cmd="$3"
  N_CORPUS=$((N_CORPUS + 1))

  _raw="no"; _can="no"
  if match_re "$_cmd"; then _raw="yes"; fi
  _canon="$(canonicalize "$_cmd")"
  if match_re "$_canon"; then _can="yes"; fi

  # Limb C — the differential, over EVERY payload. A DECLARED payload is the one class that
  # must be newly matched: it is counted apart, and fails when the match is gone (stale).
  if [ "$_cls" = "DECLARED" ]; then
    if [ "$_can" = "yes" ] && [ "$_raw" = "no" ]; then
      N_DECLARED=$((N_DECLARED + 1))
      pass "[C/DECLARED] declared tightening newly matched, as the readiness text declares: ${_lbl}"
    else
      fail "[C/DECLARED] STALE declaration — not newly matched (raw=${_raw} canon=${_can}): ${_lbl}"
    fi
  elif [ "$_can" = "yes" ] && [ "$_raw" = "no" ]; then
    N_NEWLY=$((N_NEWLY + 1))
    fail "[C/${_cls}] NEWLY BLOCKED by canonicalization: ${_lbl}"
  else
    if [ "$_raw" = "yes" ] && [ "$_can" = "no" ]; then
      N_FPREMOVED=$((N_FPREMOVED + 1))
    fi
    pass "[C/${_cls}] not newly blocked (raw=${_raw} canon=${_can}): ${_lbl}"
  fi

  case "$_cls" in
    CONTENT|NOVERB|NEAR)
      # Limb B — the false-positive population must produce no match at all.
      if [ "$_can" = "yes" ]; then
        N_FPMATCH=$((N_FPMATCH + 1))
        fail "[B/${_cls}] canonicalized command matched the verb anchor: ${_lbl}"
      else
        pass "[B/${_cls}] zero match after canonicalization: ${_lbl}"
      fi
      ;;
    START)
      N_START=$((N_START + 1))
      # Limb D — anti-vacuity: an inert payload contributes nothing to limb C.
      if [ "$_raw" = "yes" ]; then
        N_START_LIVE=$((N_START_LIVE + 1))
        pass "[D/START] live in the matched population (raw=yes): ${_lbl}"
      else
        fail "[D/START] payload INERT — verb not recognised at command start, so it tests nothing: ${_lbl}"
      fi
      ;;
  esac
}

# --- CONTENT: the verb is text, not an action. Writing a shell script, a sed/grep
#     program, or a commit message is ordinary work; a guard that fires on it gets
#     disabled by the operator, which is a worse outcome than the gap it closed. ---
check_case CONTENT "shell text written as file content"        'echo "cleanup() { rm -rf /tmp/x; }" > setup.sh'
check_case CONTENT "sed program containing a verb"             "sed 's/(rm foo)/X/' notes.txt"
check_case CONTENT "grep program containing verbs"             "grep -E '(rm |mv )' report.txt"
check_case CONTENT "verb inside a Python string literal"       "python3 -c 'print(\"mv is safe here\")'"
check_case CONTENT "verb words inside a commit message"        'git commit -m "cat the config and mv the logs"'
check_case CONTENT "verb as a hyphenated flag (docker --rm)"   'docker run --rm alpine echo ok'
check_case CONTENT "verb as a hyphenated substring"            'echo term-rm-suffix'
check_case CONTENT "verb inside a printf format payload"       'printf "%s\n" "mv is a verb" >> notes.md'
check_case CONTENT "verb named in a trailing comment"          'cargo build --release # cp is mentioned here'
check_case CONTENT "brace group with no matcher verb"          '{ echo hi; }'

# --- NOVERB: specificity. These carry no matcher verb at all and must stay silent. A
#     matcher that fires here is matching everything, which would make limb C vacuous. ---
check_case NOVERB  "specificity arm — plain echo"              'echo hello world'
check_case NOVERB  "package script with no matcher verb"       'npm run build'
check_case NOVERB  "read-only git status"                      'git status --short'
check_case NOVERB  "awk program in a quoted brace group"       "awk '{ print \$1 }' data.txt"

# --- START: legitimate commands that genuinely begin with a matcher verb. These are
#     already matched RAW; the assertion is that canonicalization does not CHANGE that.
#     The nine variable-bearing shapes below are drawn from #5555's own measured
#     population (cat 2930, cp 551, tail 493, head 348, tee 204, mv 73, base64 3,
#     more 2, od 1) — the class that moved from refused to allowed and therefore ENTERS
#     this corpus. ---
check_case START   "#5555 variable operand — cat"              'cat "$CONFIG_FILE"'
check_case START   "#5555 variable operand — cp"               'cp "$SRC_PATH" "$DEST_PATH"'
check_case START   "#5555 variable operand — tail"             'tail -n 50 "$LOG_FILE"'
check_case START   "#5555 variable operand — head"             'head -20 "${REPORT_FILE}"'
check_case START   "#5555 variable operand — tee"              'tee "$OUT_FILE"'
check_case START   "#5555 variable operand — mv"               'mv "$TMP_FILE" "$TARGET_FILE"'
check_case START   "#5555 variable operand — base64"           'base64 -i "$IMAGE_FILE"'
check_case START   "#5555 variable operand — more"             'more "$PAGER_FILE"'
check_case START   "#5555 variable operand — od"               'od -c "$BIN_FILE"'
check_case START   "literal operand control (no expansion)"    'cat README.md'
check_case START   "verb after a pipe (already anchored)"      'cat notes.txt | tee summary.txt'

# --- #8314: the faces the canonicalizer now walks, as CONTENT, as near misses, and the
#     two declared tightening classes. Each near miss puts a matcher verb where the wrapper's
#     own grammar consumes it, behind a describe-only option, or after the real command. ---
check_case CONTENT "echoed wrapper-option deletion"            'echo "sudo -u root rm -rf /tmp/x"'
check_case CONTENT "commit message naming wrapped verbs"       'git commit -m "nice -n 10 rm -rf build; timeout 5 cat x"'
check_case CONTENT "printf of an absolute-path wrapper line"   "printf '%s\\n' '/usr/bin/env rm -rf /tmp/x'"
check_case CONTENT "grep alternation of condition shapes"      "grep -E 'if rm |while cat ' notes.txt"
check_case NEAR    "env unsets a variable named like a verb"   'env -u rm printenv HOME'
check_case NEAR    "sudo user named like a verb"               'sudo -u cat id'
check_case NEAR    "describe-only command -v"                  'command -v rm'
check_case NEAR    "describe-only command -V"                  'command -V cat'
check_case NEAR    "describe-only sudo -l"                     'sudo -l rm'
check_case NEAR    "a program whose name begins with env"      '/usr/local/bin/envsubst cat'
check_case NEAR    "echo of a keyword and a verb"              'echo if rm'
check_case NEAR    "timeout running echo"                      'timeout 5 echo rm'
check_case DECLARED "xargs behind its own option feeding cat"  "printf 'a' | xargs -0 cat"
check_case DECLARED "heredoc-body prose behind a wrapper"      "$(/usr/bin/printf '%s\n%s\n%s' "git commit -F - <<'EOF'" 'nice rm stale-cache' 'EOF')"

# --- CANON-FORM (#8314): the canonical form, exact. Each input's default output and exit
#     view are pinned to the strings the walk is specified to emit: the default output
#     reaches the command word behind each face; the exit view keeps the form the walk
#     produced before the wrapper grammar, byte for byte. The default output also marks
#     every assignment the walk skips (transformation (e), #8444), and the exit view marks
#     none, which the two assignment-bearing rows pin. ---
form_case() { # $1 = label  $2 = input  $3 = expected default output  $4 = expected exit view
  _got="$(canonicalize "$2")"
  if [ "$_got" = "$3" ]; then
    pass "[F] canonical form: $1"
  else
    fail "[F] canonical form differs for $1: wanted [$3] got [$_got]"
  fi
  _got="$(canonicalize_exit "$2")"
  if [ "$_got" = "$4" ]; then
    pass "[F/exit] exit view: $1"
  else
    fail "[F/exit] exit view differs for $1: wanted [$4] got [$_got]"
  fi
}
form_case "wrapper option with its argument"   'sudo -u root rm -rf /etc'   'sudo -u root ; rm -rf /etc'   'sudo ; -u root rm -rf /etc'
form_case "wrapper flag"                       'sudo -n rm -rf /etc'        'sudo -n ; rm -rf /etc'        'sudo ; -n rm -rf /etc'
form_case "env option with its argument"       'env -u X cat ~/.ssh/id_rsa' 'env -u X ; cat ~/.ssh/id_rsa' 'env ; -u X cat ~/.ssh/id_rsa'
form_case "xargs option with its argument"     'printf x | xargs -n 1 rm'   'printf x | xargs -n 1 ; rm $XARGS-STDIN' 'printf x | xargs ; -n 1 rm $XARGS-STDIN'
form_case "describe-only option stops the walk" 'command -v rm'             'command ; -v rm'              'command ; -v rm'
form_case "absolute-path wrapper"              '/usr/bin/env rm -rf /etc'   '/usr/bin/env ; rm -rf /etc'   '/usr/bin/env rm -rf /etc'
form_case "nice with its adjustment"           'nice -n 10 rm -rf /etc'     'nice -n 10 ; rm -rf /etc'     'nice -n 10 rm -rf /etc'
form_case "timeout with its duration"          'timeout 5 rm -rf /etc'      'timeout 5 ; rm -rf /etc'      'timeout 5 rm -rf /etc'
form_case "stdbuf with an attached value"      'stdbuf -o0 rm -rf /etc'     'stdbuf -o0 ; rm -rf /etc'     'stdbuf -o0 rm -rf /etc'
form_case "if condition"                       'if rm -rf /etc ; then :; fi' 'if ; rm -rf /etc ; then ; :; ; fi' 'if rm -rf /etc ; then ; :; ; fi'
form_case "assignment after a wrapper"         'env PATH=/x cmd'            'env ; PATH=/x ; cmd'          'env PATH=/x ; cmd'
form_case "escaped wrapper word"               '\sudo rm -rf /etc'          '\sudo ; rm -rf /etc'          'sudo rm -rf /etc'
form_case "quoted wrapper word"                '"sudo" rm -rf /etc'         '"sudo" ; rm -rf /etc'         '"sudo" rm -rf /etc'
form_case "git consumed as a wrapper's user"   'sudo -u git push --force'   'sudo -u git ; push --force'   'sudo ; -u git push --force'
form_case "eleven prefix tokens (the cap)"     'A=1 B=1 C=1 D=1 E=1 F=1 G=1 H=1 I=1 J=1 K=1 rm -rf /etc' 'A=1 ; B=1 ; C=1 ; D=1 ; E=1 ; F=1 ; G=1 ; H=1 ; I=1 ; J=1 ; K=1 rm -rf /etc' 'A=1 B=1 C=1 D=1 E=1 F=1 G=1 H=1 I=1 J=1 ; K=1 rm -rf /etc'
form_case "a line the exit view resolved before" 'sudo git status ; rm -rf /tmp/x' 'sudo ; git status ; ; rm -rf /tmp/x' 'sudo ; git status ; ; rm -rf /tmp/x'

# --- CMDPOS-SINGLE-SOURCE (#8314): one implementation for the four consumers ---
# AC3: every hook that carries the shared anchor resolves command position through this
# one file, and nothing else in the hook directory holds a prefix table. Shown able to fail
# by three sandbox mutants below.
single_source_report() { # $1 = hooks dir -> SS_01, SS_02, SS_03 problem strings (empty = holds)
  local h b anchor_set bind_set
  SS_01=""; SS_02=""; SS_03=""
  anchor_set=" "; bind_set=" "
  for h in "$1"/*.sh; do
    [ -f "$h" ] || continue
    b="${h##*/}"
    if /usr/bin/grep -q '^readonly ANCHOR_PREFIX_BASH=' "$h"; then anchor_set="${anchor_set}${b} "; fi
    if /usr/bin/grep -q -F 'readonly CMDPOS_AWK="${HOOK_DIR}/lib/command-position.awk"' "$h"; then bind_set="${bind_set}${b} "; fi
  done
  if [ "$anchor_set" != "$bind_set" ]; then SS_01="anchor-hooks[${anchor_set}] != bound-hooks[${bind_set}]"; fi
  if [ "$(/usr/bin/printf '%s' "$anchor_set" | /usr/bin/wc -w | /usr/bin/tr -d ' ')" != 4 ]; then SS_01="${SS_01} anchor-hooks-count!=4[${anchor_set}]"; fi
  for b in $bind_set; do
    h="$1/$b"
    # every assignment of COMMAND_CMDPOS reads the shared file, or is the raw fallback
    if /usr/bin/awk '
        /^[ \t]*#/ { next }
        /(^|[^$A-Za-z_])COMMAND_CMDPOS=/ {
          if (index($0, "/usr/bin/awk -f \"$CMDPOS_AWK\"") == 0 && $0 !~ /COMMAND_CMDPOS="\$COMMAND"[ \t]*$/) bad = 1
        }
        END { exit bad ? 0 : 1 }' "$h"; then SS_02="${SS_02} ${b}:assignment"; fi
    # its matches() reads COMMAND_CMDPOS
    if ! /usr/bin/awk '
        /^matches\(\) \{/ { inm = 1; next }
        inm && /^\}/ { inm = 0; next }
        inm && index($0, "\"$COMMAND_CMDPOS\"") > 0 { ok = 1 }
        END { exit ok ? 0 : 1 }' "$h"; then SS_02="${SS_02} ${b}:matches"; fi
  done
  for h in "$1"/*.sh "$1"/lib/*; do
    [ -f "$h" ] || continue
    case "${h##*/}" in command-position.awk) continue ;; esac
    if /usr/bin/grep -q -E '(PREFIX|WROW)\[' "$h"; then SS_03="${SS_03} ${h#"$1"/}"; fi
  done
}
single_source_report "$HOOK_DIR"
if [ -z "$SS_01" ]; then pass "CMDPOS-SINGLE-SOURCE-01 the four hooks that carry the shared anchor are exactly the four that bind lib/command-position.awk"; else fail "CMDPOS-SINGLE-SOURCE-01 ${SS_01}"; fi
if [ -z "$SS_02" ]; then pass "CMDPOS-SINGLE-SOURCE-02 each binding hook assigns its canonical text only from that file, and its matches() reads it"; else fail "CMDPOS-SINGLE-SOURCE-02 ${SS_02}"; fi
if [ -z "$SS_03" ]; then pass "CMDPOS-SINGLE-SOURCE-03 no other hook source or library file holds a prefix-word or wrapper-row table"; else fail "CMDPOS-SINGLE-SOURCE-03 ${SS_03}"; fi

ss_sbx="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "${ss_sbx}/lib"
/bin/cp "$HOOK_DIR"/block-*.sh "${ss_sbx}/" 2>/dev/null || true
/bin/cp "$CMDPOS_AWK" "${ss_sbx}/lib/command-position.awk"
single_source_report "$ss_sbx"
ss_base="${SS_01}${SS_02}${SS_03}"
/usr/bin/sed -e 's#readonly CMDPOS_AWK="${HOOK_DIR}/lib/command-position.awk"#readonly CMDPOS_AWK="${HOOK_DIR}/lib/other-position.awk"#' \
  "$HOOK_DIR/block-egress.sh" > "${ss_sbx}/block-egress.sh"
single_source_report "$ss_sbx"
if [ -z "$ss_base" ] && ! /usr/bin/cmp -s "$HOOK_DIR/block-egress.sh" "${ss_sbx}/block-egress.sh" && [ -n "$SS_01" ]; then
  pass "CMDPOS-SINGLE-SOURCE-M1 a consumer copy that binds another file is reported"
else
  fail "CMDPOS-SINGLE-SOURCE-M1 a consumer copy that binds another file was not reported (sandbox base [${ss_base}], result [${SS_01}])"
fi
/bin/cp "$HOOK_DIR/block-egress.sh" "${ss_sbx}/block-egress.sh"
/bin/cp "$CMDPOS_AWK" "${ss_sbx}/lib/command-position-copy.awk"
single_source_report "$ss_sbx"
if [ -n "$SS_03" ]; then
  pass "CMDPOS-SINGLE-SOURCE-M2 a second canonicalizer copy beside the hooks is reported"
else
  fail "CMDPOS-SINGLE-SOURCE-M2 a second canonicalizer copy beside the hooks was not reported"
fi
/bin/rm -f "${ss_sbx}/lib/command-position-copy.awk"
/usr/bin/sed -e '/^matches() {/,/^}/s/"\$COMMAND_CMDPOS"/"$COMMAND"/' "$HOOK_DIR/block-fs-boundary.sh" > "${ss_sbx}/block-fs-boundary.sh"
single_source_report "$ss_sbx"
if ! /usr/bin/cmp -s "$HOOK_DIR/block-fs-boundary.sh" "${ss_sbx}/block-fs-boundary.sh" && [[ "$SS_02" == *"block-fs-boundary.sh:matches"* ]]; then
  pass "CMDPOS-SINGLE-SOURCE-M3 a consumer whose matches() reads the raw command is reported"
else
  fail "CMDPOS-SINGLE-SOURCE-M3 a consumer whose matches() reads the raw command was not reported (result [${SS_02}])"
fi
/bin/rm -rf "$ss_sbx"

# --- (5) AGGREGATE ASSERTIONS ---------------------------------------------------------
if [ "$N_CORPUS" -ge 15 ]; then
  pass "corpus size $N_CORPUS meets the >=15 floor"
else
  fail "corpus size $N_CORPUS is below the >=15 floor required for the AC4 predicate"
fi

if [ "$N_NEWLY" -eq 0 ]; then
  pass "[C] AC4 PREDICATE: zero legitimate commands newly blocked by canonicalization (0 of $N_CORPUS)"
else
  fail "[C] AC4 PREDICATE VIOLATED: $N_NEWLY of $N_CORPUS legitimate commands newly blocked"
fi

if [ "$N_FPMATCH" -eq 0 ]; then
  pass "[B] specificity holds: no content-only or verb-free payload matched the anchor"
else
  fail "[B] specificity BROKEN: $N_FPMATCH content-only/verb-free payload(s) matched"
fi

if [ "$N_START" -gt 0 ] && [ "$N_START_LIVE" -eq "$N_START" ]; then
  pass "[D] all $N_START command-start payloads are live in the matched population"
else
  fail "[D] only $N_START_LIVE of $N_START command-start payloads are live — the rest test nothing"
fi

verdict_and_exit
