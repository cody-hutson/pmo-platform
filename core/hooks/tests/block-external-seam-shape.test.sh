#!/bin/bash
# tests/block-external-seam-shape.test.sh — synthetic PreToolUse tests for
# block-external-seam-shape.sh (the external-seam register-shape gate).
#
# Proves, in this order:
#   RED     each shape rule fires ITS OWN rule id, not merely "a" rule
#   RED     FL-1 fail-loud on empty extraction (the CD-3 analogue)
#   GREEN   the SURFACE gate — read-family MCP names never enter scope, and Bash is
#           excluded unconditionally. These are the regression guards for the two
#           defects the adversarial review found in the design, and without them a
#           later widening of the surface key is invisible.
#   GREEN   a structured (rich-text) comment body extracts rather than tripping FL-1
#   CONTROL the detector is REACHABLE — a RED payload at mode=off is silent, and the
#           same payload at warn emits a WARN line. A RED whose control also emitted
#           nothing is a broken probe, not a clean result.
#   CONTROL the AC-2 vendor assertion detects a vendor name (run against a corpus file
#           that names vendors in prose), so its ZERO on the discipline is a real zero
#   PHASE   BLOCK-SEAM-SHAPE-004 never blocks, even at mode=enforce, while a sibling
#           rule on the same payload does — the pair is what makes the per-rule
#           constant observable rather than asserted
#   CLOSED  missing jq / missing dep-helper are mode-coupled fail-closed
#
# HERMETIC: builds a sandbox mirroring the DEPLOYED layout (.claude/hooks/) with a
# sandboxed HOME so operator.toml resolves into the sandbox. The repo hook dir is
# never mutated. Summary line matches the test-runner contract:
#   "Total: N  PASS: N  FAIL: N"   (TWO spaces — test-runner.sh:61 greps for exactly
# that shape, and a suite missing it is counted FAIL even when every assertion passes)

set -u

SRC_HOOK_DIR="$(cd "$(dirname "$0")/.." && pwd -P)"
REPO_ROOT="$(cd "${SRC_HOOK_DIR}/../.." && pwd -P)"
JQ="/usr/bin/jq"

[ -r "${SRC_HOOK_DIR}/block-external-seam-shape.sh" ] || { echo "FAIL: hook not readable"; echo "Total: 1  PASS: 0  FAIL: 1"; exit 1; }

# --- Build the deployed-layout sandbox ---
SB="$(mktemp -d)"
CLAUDE="${SB}/.claude"
HDIR="${CLAUDE}/hooks"
mkdir -p "${HDIR}/lib" "${SB}/.config/pmo-platform"
cp "${SRC_HOOK_DIR}/block-external-seam-shape.sh" "${HDIR}/block-external-seam-shape.sh"
cp "${SRC_HOOK_DIR}/lib/dep-resolve.sh"           "${HDIR}/lib/dep-resolve.sh"
HOOK="${HDIR}/block-external-seam-shape.sh"
MODE_FILE="${HDIR}/.seam-shape-mode"
OPTOML="${SB}/.config/pmo-platform/operator.toml"

cleanup() { [ -n "${SB:-}" ] && /bin/rm -rf "$SB"; }
trap cleanup EXIT

printf '[identity]\noperator_name = "Test Operator"\n' > "$OPTOML"
set_mode() { printf '%s' "$1" > "$MODE_FILE"; }

PASS=0; FAIL=0
p_mcp()  { "$JQ" -n --arg t "$1" --argjson ti "$2" '{tool_name:$t,tool_input:$ti,cwd:"/tmp"}'; }
p_bash() { "$JQ" -n --arg c "$1" '{tool_name:"Bash",tool_input:{command:$c},cwd:"/tmp"}'; }

# run <name> <payload> <mode> <expected_exit> [stderr_pattern] [must_NOT_match_pattern] [extra_env]
run() {
  local name="$1" payload="$2" mode="$3" exp="$4" pat="${5:-}" negpat="${6:-}" xenv="${7:-}"
  set_mode "$mode"
  local rc=0
  printf '%s' "$payload" | env HOME="$SB" PMO_SCOPE_GUARD_ROOT="/" $xenv /bin/bash "$HOOK" >/dev/null 2>"${SB}/err" || rc=$?
  local err; err="$(/bin/cat "${SB}/err")"
  local ok=1
  [ "$rc" != "$exp" ] && ok=0
  # Here-string, not `printf | grep -q`: `-q` closes stdin on its first match, the
  # writer's next write fails on the broken pipe, and under pipefail that non-zero
  # status becomes the pipeline's — so a SUCCESSFUL match can report failure. On a
  # GitHub runner SIGPIPE arrives as SIG_IGN, so the status is 1, indistinguishable
  # from "no match". A here-string has no writer to signal. The `[ -n ... ]` guards
  # are load-bearing for the substitution: `<<<""` feeds ONE empty line where
  # `printf '%s' ""` fed zero, so an empty-pattern arm must not reach the reader.
  if [ -n "$pat" ]; then /usr/bin/grep -qE "$pat" <<<"$err" || ok=0; fi
  if [ -n "$negpat" ]; then /usr/bin/grep -qE "$negpat" <<<"$err" && ok=0; fi
  if [ "$ok" = 1 ]; then printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else printf 'FAIL: %s (exp_exit=%s got=%s pat=[%s] neg=[%s])\n  stderr: %s\n' "$name" "$exp" "$rc" "$pat" "$negpat" "$err"; FAIL=$((FAIL+1)); fi
}

# ==========================================================================
echo "===== RED — each shape rule fires its OWN id (mode=enforce) ====="
# ==========================================================================
run "RED-1 dated log header (ISO, bold-wrapped) → -001" \
  "$(p_mcp 'mcp__srv__createComment' '{"body":"**2026-09-05 — Stage 6 update**\n\nWork proceeded."}')" \
  enforce 2 "BLOCK-SEAM-SHAPE-001"
run "RED-1b dated log header (heading-wrapped, Mon DD) → -001" \
  "$(p_mcp 'mcp__srv__add_comment' '{"comment":"## Sep 5, 2026 status\n\nDetail follows."}')" \
  enforce 2 "BLOCK-SEAM-SHAPE-001"
run "RED-2 provenance narration → -002" \
  "$(p_mcp 'mcp__srv__post_document_thread_comment' '{"text":"Hi Dana — one question on the vendor date. Generated by the release agent, run 2 of 3."}')" \
  enforce 2 "BLOCK-SEAM-SHAPE-002"
run "RED-3 state-change narration → -003" \
  "$(p_mcp 'mcp__srv__createFooterComment' '{"body":"Status changed to In Progress and the assignee was reassigned."}')" \
  enforce 2 "BLOCK-SEAM-SHAPE-003"
run "RED-5 empty extraction on an in-scope surface → -010 (fail-loud)" \
  "$(p_mcp 'mcp__srv__createComment' '{"issueId":"ABC-1"}')" \
  enforce 2 "BLOCK-SEAM-SHAPE-010"

# ==========================================================================
echo "===== RED-4 / PHASE — the budget rule NEVER blocks, even at enforce ====="
# ==========================================================================
# 300 clean words: over the 250 default, and carrying no other rule's signature.
LONG_BODY="Hi Dana, here is the detail you asked for."
i=0; while [ "$i" -lt 300 ]; do LONG_BODY="${LONG_BODY} detail"; i=$((i+1)); done
run "RED-4 over-budget at ENFORCE → advisory WARN, exit 0 (per-rule phase constant)" \
  "$(p_mcp 'mcp__srv__createComment' "$("$JQ" -n --arg b "$LONG_BODY" '{body:$b}')")" \
  enforce 0 "BLOCK-SEAM-SHAPE-004.*never blocks"
# The discriminating pair: a sibling rule on a payload of the same length DOES block
# at enforce, so the -004 exit-0 above is the per-rule constant and not a dead detector.
run "PHASE-PAIR same length + a dated header at ENFORCE → -001 BLOCKS (exit 2)" \
  "$(p_mcp 'mcp__srv__createComment' "$("$JQ" -n --arg b "2026-09-05 — ${LONG_BODY}" '{body:$b}')")" \
  enforce 2 "BLOCK-SEAM-SHAPE-001"

# ==========================================================================
echo "===== GREEN — the SURFACE gate (the two adversarial-review regressions) ====="
# ==========================================================================
# FMF-1 guard. A noun-only surface key would match every one of these read-family
# names, and each carries no content field — so each would reach the fail-loud arm
# and warn on a comment READ, and block one at enforce. Assert BOTH exit 0 and the
# ABSENCE of any hook output: an exit-0-with-a-WARN would still be the defect.
for readtool in \
  'mcp__srv__list_document_thread_comments' \
  'mcp__srv__list_document_threads' \
  'mcp__srv__getConfluencePageFooterComments' \
  'mcp__srv__getConfluencePageInlineComments' \
  'mcp__srv__getConfluenceCommentChildren' \
  'mcp__srv__list_discussions' \
  'mcp__srv__get_discussion' ; do
  run "GREEN read-family out of scope: ${readtool##*__}" \
    "$(p_mcp "$readtool" '{"pageId":"1"}')" enforce 0 "" "CLAUDE-HOOK"
done
# Non-content write verbs carry no authored body; admitting them would send every
# comment DELETE into the fail-loud arm.
run "GREEN delete_comment (write verb, no content) out of scope" \
  "$(p_mcp 'mcp__srv__delete_comment' '{"commentId":"9"}')" enforce 0 "" "CLAUDE-HOOK"
# Bash exclusion — the platform's own tracker. The payload trips EVERY red rule.
run "GREEN-2 Bash + gh issue comment carrying every RED signature → out of scope" \
  "$(p_bash 'gh issue comment 7082 --body "**2026-09-05 — Stage 6** Generated by the release agent, run 2 of 3. Status changed to In Progress."')" \
  enforce 0 "" "CLAUDE-HOOK"
# A warranted comment: addresses a person, carries one ask, short, no register shape.
run "GREEN-1 short comment addressed to a person with one ask → allow" \
  "$(p_mcp 'mcp__srv__createComment' '{"body":"Hi Dana — can you confirm the vendor cutover date before Friday?"}')" \
  enforce 0 "" "CLAUDE-HOOK"
# FMF-2 guard: a structured rich-text body must EXTRACT, not trip FL-1.
run "GREEN-4 structured body extracts (no FL-1) — clean content allowed" \
  "$(p_mcp 'mcp__srv__createComment' '{"content":[{"type":"paragraph","content":[{"type":"text","text":"Hi Dana - can you confirm the vendor cutover date?"}]}]}')" \
  enforce 0 "" "CLAUDE-HOOK"
# ...and the same structural shape carrying a dated header MUST still be seen, which
# is what proves the extraction reached the human text rather than the metadata.
run "GREEN-4b structured body with a dated header → -001 still fires" \
  "$(p_mcp 'mcp__srv__createComment' '{"content":[{"type":"paragraph","content":[{"type":"text","text":"2026-09-05 — Stage 6 update"}]}]}')" \
  enforce 2 "BLOCK-SEAM-SHAPE-001"

# ==========================================================================
echo "===== CONTROL — detector reachability (a zero with a silent control is broken) ====="
# ==========================================================================
RED1_PAYLOAD="$(p_mcp 'mcp__srv__createComment' '{"body":"**2026-09-05 — Stage 6 update**\n\nWork proceeded."}')"
run "CONTROL-1 RED-1 at mode=off → exit 0 AND no output (mode reader is live)" \
  "$RED1_PAYLOAD" off 0 "" "CLAUDE-HOOK"
run "CONTROL-2 RED-1 at mode=warn → exit 0 WITH a WARN line (warn is non-blocking AND the detector reached the payload)" \
  "$RED1_PAYLOAD" warn 0 "WARN .would-block.*BLOCK-SEAM-SHAPE-001|BLOCK-SEAM-SHAPE-001.*WARN"
run "CONTROL-1b bypass=1 on RED-1 → allow" \
  "$RED1_PAYLOAD" enforce 0 "" "" "CLAUDE_HOOK_BYPASS=1"

# ==========================================================================
echo "===== CONTROL-3 — AC-2 vendor assertion, with its own control arm ====="
# ==========================================================================
# Two arms over the discipline artefact: a fixed vendor-token list, and a shape arm
# (MCP tool-namespace token; server-UUID-shaped token). The vendor literals live HERE
# and never in the artefact — a corpus file naming vendors is exactly what the
# artefact must not be. Control: the same two arms against a corpus standard that
# names vendors and tool namespaces in prose MUST return non-zero, or the zero on the
# artefact is a dead probe rather than a clean file.
# CORPUS_ROOT is NOT REPO_ROOT. REPO_ROOT is derived from this test's own location,
# which resolves correctly in a source checkout and INCORRECTLY under the deployed-
# layout sandbox the gating harness builds: there the same walk lands on <sandbox>/,
# which carries a hook runtime and no corpus, so both documents read unreadable and
# vendor_hits returns its -1 sentinel. That is the fail-loud branch reporting a
# RESOLUTION defect, and the repair belongs at the resolution, never at the sentinel.
#
# Ladder, first hit wins. Each rung is a location the corpus genuinely may live at;
# none of them guesses.
#   1. $PMO_SEAM_TEST_CORPUS_ROOT   — explicit operator/CI override
#   2. .source-repo-root            — the pointer setup-ci-layout.sh writes beside
#                                     the materialized tests (the CI sandbox rung)
#   3. REPO_ROOT                    — the source-checkout rung
#   4. walk up from this test        — a relocated checkout still resolves
CORPUS_MARK="core/disciplines/external-seam-conduct.md"
CORPUS_ROOT=""
CORPUS_RUNG=""
_try_root() { # $1 = candidate root, $2 = rung label
  [ -n "$CORPUS_ROOT" ] && return 0
  [ -n "$1" ] || return 0
  [ -r "${1}/${CORPUS_MARK}" ] || return 0
  CORPUS_ROOT="$1"; CORPUS_RUNG="$2"
}
_try_root "${PMO_SEAM_TEST_CORPUS_ROOT:-}" "env PMO_SEAM_TEST_CORPUS_ROOT"
if [ -r "$(dirname "$0")/.source-repo-root" ]; then
  _try_root "$(head -n 1 "$(dirname "$0")/.source-repo-root")" ".source-repo-root marker"
fi
_try_root "$REPO_ROOT" "REPO_ROOT (source checkout)"
_walk="$(cd "$(dirname "$0")" && pwd -P)"
while [ -z "$CORPUS_ROOT" ] && [ "$_walk" != "/" ]; do
  _try_root "$_walk" "ancestor walk-up"
  _walk="$(dirname "$_walk")"
done

# A harness that cannot find the corpus it exists to grade has not "skipped" AC-2 —
# it has failed to establish whether AC-2 holds, which is the same class of defect
# as the -1 sentinel and gets the same loud treatment. Both real runners (a source
# checkout, and the sandbox via rung 2) resolve; an unresolvable root means the
# layout changed and the arms below would otherwise grade nothing while reading green.
if [ -z "$CORPUS_ROOT" ]; then
  printf 'FAIL: CONTROL-3 corpus root UNRESOLVED — every rung missed (env=%s marker=%s REPO_ROOT=%s walk-up from %s); AC-2 was not graded\n' \
    "${PMO_SEAM_TEST_CORPUS_ROOT:-<unset>}" \
    "$(dirname "$0")/.source-repo-root" "$REPO_ROOT" "$(dirname "$0")"
  FAIL=$((FAIL+1))
  CORPUS_ROOT="$REPO_ROOT"   # let the arms below run and report their own verdict
  CORPUS_RUNG="UNRESOLVED"
else
  printf 'PASS: CONTROL-3 corpus root resolved via %s -> %s\n' "$CORPUS_RUNG" "$CORPUS_ROOT"
  PASS=$((PASS+1))
fi

SUBJECT_DOC="${CORPUS_ROOT}/core/disciplines/external-seam-conduct.md"
CONTROL_DOC="${CORPUS_ROOT}/core/standards/c3-external-sync-path-b.md"
vendor_hits() { # $1 = file — echoes a count, never a second line.
  # `grep -c` PRINTS 0 and EXITS 1 on no-match, so a `|| echo 0` fallback emits the
  # count twice and every downstream numeric test then compares against a two-line
  # string. Swallow the status instead of substituting for it.
  [ -r "$1" ] || { echo "-1"; return; }
  /usr/bin/grep -cE '\b(Jira|Confluence|Atlassian|Smartsheet|Linear|Asana|Notion|Monday|ClickUp|ServiceNow|Trello|Zendesk|GitLab|Salesforce|Lucid)\b|mcp__|[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' "$1" 2>/dev/null || true
}
S_HITS="$(vendor_hits "$SUBJECT_DOC")"
C_HITS="$(vendor_hits "$CONTROL_DOC")"
if [ "$C_HITS" -gt 0 ]; then
  printf 'PASS: CONTROL-3a vendor assertion is LIVE (control doc = %s hits)\n' "$C_HITS"; PASS=$((PASS+1))
else
  printf 'FAIL: CONTROL-3a vendor assertion is a BROKEN PROBE (control doc = %s hits; expected non-zero)\n' "$C_HITS"; FAIL=$((FAIL+1))
fi
if [ "$S_HITS" = "0" ]; then
  printf 'PASS: CONTROL-3b AC-2 — discipline artefact names no vendor / namespace / server id (0 hits)\n'; PASS=$((PASS+1))
else
  printf 'FAIL: CONTROL-3b AC-2 — discipline artefact carries %s vendor/namespace hit(s)\n' "$S_HITS"; FAIL=$((FAIL+1))
fi
# Synthetic arm — the UUID and namespace sub-arms return 0 on BOTH real documents for
# the UUID half, so they are proven here against a constructed fixture instead of
# being reported as clean on a population that could never have exercised them.
# The server id below is SYNTHETIC by construction — the all-zero RFC-4122 v4 shape
# (`00000000-…`) used as the fixture id everywhere else in this repo. It satisfies the
# UUID sub-arm's character class while being incapable of naming a real connector, so
# this arm proves the detector without carrying an operator-instance server id into a
# public surface. Never substitute a live id here: the arm grades the SHAPE, so any
# well-formed value exercises it identically and a real one adds only disclosure.
SYNTH="${SB}/synth.md"
printf 'a mcp__aaaaaaaa__tool and 00000000-0000-4000-8000-000000000000\n' > "$SYNTH"
if [ "$(vendor_hits "$SYNTH")" -gt 0 ]; then
  printf 'PASS: CONTROL-3c shape sub-arms (namespace + server-uuid) fire on a constructed fixture\n'; PASS=$((PASS+1))
else
  printf 'FAIL: CONTROL-3c shape sub-arms did NOT fire on a fixture built to trip them\n'; FAIL=$((FAIL+1))
fi

# ==========================================================================
echo "===== FAIL-CLOSED: missing jq / missing dep helper (mode-coupled) ====="
# ==========================================================================
SBX="$(mktemp -d)"
mkdir -p "${SBX}/.claude/hooks/lib" "${SBX}/.config/pmo-platform"
cp "$HOOK" "${SBX}/.claude/hooks/block-external-seam-shape.sh"
cp "$OPTOML" "${SBX}/.config/pmo-platform/operator.toml"
/usr/bin/sed -e 's#/usr/bin/jq#/nonexistent/usr/bin/jq#' \
             -e 's#/opt/homebrew/bin/jq#/nonexistent/opt/homebrew/bin/jq#' \
             -e 's#/usr/local/bin/jq#/nonexistent/usr/local/bin/jq#' \
             "${HDIR}/lib/dep-resolve.sh" > "${SBX}/.claude/hooks/lib/dep-resolve.sh"
SXHOOK="${SBX}/.claude/hooks/block-external-seam-shape.sh"
SXMODE="${SBX}/.claude/hooks/.seam-shape-mode"

sbox_run() { # name mode extra_env expected_exit [pattern]
  local name="$1" mode="$2" xenv="$3" exp="$4" pat="${5:-}"
  printf '%s' "$mode" > "$SXMODE"
  local rc=0
  printf '%s' "$RED1_PAYLOAD" | env HOME="$SBX" PMO_SCOPE_GUARD_ROOT="/" $xenv /bin/bash "$SXHOOK" >/dev/null 2>"${SBX}/err" || rc=$?
  local err; err="$(/bin/cat "${SBX}/err")"
  local ok=1
  [ "$rc" != "$exp" ] && ok=0
  # Here-string rather than `printf | grep -q` — see the note in run() above.
  [ -n "$pat" ] && ! /usr/bin/grep -qE "$pat" <<<"$err" && ok=0
  if [ "$ok" = 1 ]; then printf 'PASS: %s\n' "$name"; PASS=$((PASS+1));
  else printf 'FAIL: %s (exp=%s got=%s)\n  stderr: %s\n' "$name" "$exp" "$rc" "$err"; FAIL=$((FAIL+1)); fi
}
sbox_run "missing-jq enforce → fail CLOSED (exit 2)" enforce "" 2 "DEPENDENCY"
sbox_run "missing-jq warn → degrade (exit 0)"        warn    "" 0 "DEPENDENCY-DEGRADED"
sbox_run "missing-jq + bypass → allow (exit 0)"      enforce "CLAUDE_HOOK_BYPASS=1" 0
/bin/rm -f "${SBX}/.claude/hooks/lib/dep-resolve.sh"
sbox_run "missing-helper enforce → fail CLOSED (exit 2)" enforce "" 2 "LIB-MISSING.*fail-closed"
sbox_run "missing-helper warn → degrade (exit 0)"        warn    "" 0 "LIB-MISSING.*degraded"
sbox_run "missing-helper off → degrade (exit 0)"         off     "" 0 "LIB-MISSING.*degraded"
/bin/rm -rf "$SBX"

printf '\nTotal: %d  PASS: %d  FAIL: %d\n' "$((PASS + FAIL))" "$PASS" "$FAIL"
[ "$FAIL" -eq 0 ] || exit 1
