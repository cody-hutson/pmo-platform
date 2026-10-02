#!/usr/bin/env bash
# compute-cycle-time.sh — Deployment cycle time computation for a release
# Per release/references/standards/deployment-cycle-time.md.
# Reads the operator-instance pipeline event log at
# <OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md
# (canonical default: ${CLAUDE_WORKSPACE_ROOT}/pmo-instance/evals/results/)
# via query-pipeline-event.sh (sibling tool; it resolves the log location).
#
# Per the Stage 5 spec.
#
# Cycle time = T_DEPLOY - T_GO, where:
#   T_GO     = MIN(ts_iso) of the release's Stage-9 GO rows: gate-outcome/
#              plan-review-go events at stage 9 whose actor is operator
#   T_DEPLOY = MAX(ts_iso) of deployment-status/deploy-skill or deploy-harness
#              events for the release THAT CARRY outcome=resolved
# Both anchors source the ts_iso field per pipeline-event-log-schema.md § 2.
#
# WHY T_GO IS SELECTED BY IDENTITY, NOT BY MIN OVER THE SUBTYPE. plan-review-go
# was also written for outcomes that authorize nothing (Stage-7/8 verdicts, Stage-4
# plan approvals, Stage-12 execute authorizations, stage-completion notes), and MIN
# over the subtype anchored T_GO on the earliest: a positive, plausible duration
# every check here passes. The authorization is identified by who rendered it and
# where — actor operator, stage 9. No row of that identity -> N/A with its own
# reason, never a subtype fallback. The writer refuses the subtype elsewhere; older
# rows are historical and inert here.
#
# WHY T_DEPLOY REQUIRES outcome=resolved (#4215). A deploy in which every target
# FAILED is not a deploy. Before this conjunct existed, a release whose deploy rows
# all read outcome=escalated still produced a measured duration — the anchor read the
# subtype and ignored the outcome column entirely — so "Cycle-Time returns a value
# rather than N/A" was satisfiable by total failure and could not distinguish the goal
# being met from the goal being defeated. Restricting the anchor to resolved rows makes
# a failed deploy read N/A, which is the honest answer, and the N/A diagnostic below
# names WHICH kind of N/A it is so the two are never conflated again.
#
# WHY ONLY deploy-skill / deploy-harness ANCHOR T_DEPLOY (#5553) — a DECLARED anchor
# set, and every other subtype is REPORTED BY NAME in the N/A reason, never silently
# dropped. T_DEPLOY marks Stage 12 completion of the release's skill and harness deploys
# (deployment-cycle-time.md § 1); the schema's other three deployment-status subtypes
# are not that completion:
#   deploy-package      a `.skill` package is a distribution artifact. The runtime is
#                       propagated from source by the skill deploy, never from the
#                       package. A package-ONLY deploy IS reachable: deploy.sh's
#                       incremental tag-diff path fills its package set from its own
#                       packages/ diff, independently of skills. (Its full-roster and
#                       named-skill paths couple packages to skills; that one does not.)
#   deploy-rules-mirror the rules-mirror carrier writes one row on EVERY release-stamped
#                       deploy, changed or not, before any argument is validated:
#                       resolved when the mirror copy succeeds, escalated when it fails.
#                       Admitting it would make every stamped content-only release whose
#                       mirror copy succeeded compute, which the content-only exclusion
#                       forbids. The cost is named, not hidden: a release whose change
#                       reached the runtime only through the mirror reads N/A with that
#                       row named.
#   deploy-helper       producer-less and target-less: nothing emits it.
# "The deploy ran and its targets did not succeed" is reserved for the one case where
# it is true: skill/harness rows exist and none reached outcome=resolved.
#
# WHY A RUNG-3 INDETERMINATE NOTICE IS REPEATED ON STDERR (#5467). Both reads go through
# the query tool's --release, whose ladder (pipeline-event-log-schema.md § 2a) also
# matches the release's legacy vX.Y value at rung 3, and one legacy value can carry rows
# of more than one release. The query tool says so on its own stderr — INDETERMINATE:
# ... do not bind them. A read that discarded that stream anchored on such rows without
# a word, so each read repeats the notice on this tool's stderr as one line, labelled
# T_GO or T_DEPLOY. The selection is not changed by it: the anchors are chosen over the
# rows as the query tool returned them, these included, because only the query tool
# knows which rows a legacy value matched. The notice is therefore the only sign that an
# anchor may be another release's, and nothing on stdout depends on it. The query tool's
# other notes — a best-effort legacy match, an in-flight release — are not repeated.
#
# Usage:
#   ./compute-cycle-time.sh <release>           # human-readable: "47m" or "2h17m" or "N/A"
#   ./compute-cycle-time.sh --version <release> # same as positional form
#
# <release> is the MILESTONE SLUG — the release join key per
# pipeline-event-log-schema.md § 2a. Row selection routes through the query
# tool's --release (the § 2a ladder), so a legacy vX.Y still resolves; the slug
# is the canonical form. The flag keeps its --version spelling for caller
# compatibility.
#   ./compute-cycle-time.sh <version> --seconds # integer seconds: "2820" or "N/A"
#   ./compute-cycle-time.sh <version> --iso     # detail: "T_GO=<iso>; T_DEPLOY=<iso>; delta=2820s"
#   ./compute-cycle-time.sh --self-test         # validate logic against synthetic input
#   ./compute-cycle-time.sh --help              # this help text
#
# Cutover: applies to releases entering Stage 12 strictly AFTER the cutover merge SHA.
# The cutover release itself: exempt. This script does not gate by version — caller honors cutover.
#
# Exit codes:
#   0 = success — a value, or N/A with its reason on stderr: a legitimate result
#       when an anchor cannot be resolved (deployment-cycle-time.md § 2.1 for T_GO,
#       § 4 for T_DEPLOY)
#   1 = invalid args / log file missing
#   2 = malformed row (ts_iso parse failure — pipeline-event-log integrity violation,
#       escalate)

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# REPO_ROOT retained for resolution-block parity with the append/query event-log
# tools; this tool delegates all log-path resolution to query-pipeline-event.sh
# (QUERY_TOOL below). Its one reader is self-test arm CR-8, which reads the schema's
# deployment-status enum. Two levels up — NOT three; the prior `../../..`
# mis-anchored above the repo from a worktree (the #430-class bug).
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
QUERY_TOOL="$SCRIPT_DIR/query-pipeline-event.sh"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  # Self-terminating on the header block's real end rather than a fixed window —
  # the shape automated-closeout.sh's usage() uses. A fixed window re-breaks every
  # time the header grows; this one had stopped mid-sentence above the Usage block.
  /usr/bin/awk 'NR < 4 {next} /^#/ {sub(/^# ?/, ""); print; next} {exit}' "${BASH_SOURCE[0]}"
  exit 0
}

# ─── Argument parsing ────────────────────────────────────────────────────────

VERSION=""
OUTPUT_FORMAT="human"   # human | seconds | iso
SELF_TEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --version) VERSION="$2"; shift 2 ;;
    --seconds) OUTPUT_FORMAT="seconds"; shift ;;
    --iso) OUTPUT_FORMAT="iso"; shift ;;
    --self-test) SELF_TEST=true; shift ;;
    --help|-h) usage ;;
    -*) die "Unknown flag: $1" ;;
    *)
      # Positional: first non-flag arg is the version
      if [[ -z "$VERSION" ]]; then
        VERSION="$1"
      else
        die "Unexpected positional arg: $1 (version already set to '$VERSION')"
      fi
      shift
      ;;
  esac
done

# ─── ISO8601 delta helpers ───────────────────────────────────────────────────

# Compute T_DEPLOY - T_GO in integer seconds.
# Input: two ISO8601 UTC timestamps (e.g., 2026-05-15T14:22:01Z).
# Output: integer seconds on stdout, exit 2 on parse failure.
compute_delta_seconds() {
  local t_go="$1"
  local t_deploy="$2"
  /usr/bin/python3 - "$t_go" "$t_deploy" <<'PY' || return 2
import sys
from datetime import datetime
try:
    t_go = datetime.fromisoformat(sys.argv[1].replace("Z", "+00:00"))
    t_deploy = datetime.fromisoformat(sys.argv[2].replace("Z", "+00:00"))
except ValueError as e:
    print(f"ts_iso parse failure: {e}", file=sys.stderr)
    sys.exit(2)
delta = t_deploy - t_go
print(int(delta.total_seconds()))
PY
}

# ─── T_GO anchor selection ───────────────────────────────────────────────────
# The full identity, never the subtype alone: gate-outcome / plan-review-go /
# stage "9" (a STRING — the writer rejects 09 as octal) / actor operator.
# go_anchor_ts keeps the earliest ts_iso (fixed-width UTC, string compare) in one
# awk process. Factored out so group CG grades predicate AND reduction. Field map:
# $3 stage, $4 event_type, $5 event_subtype, $6 actor.
select_go_anchor_rows() {
  /usr/bin/awk -F ' \\| ' '$4 == "gate-outcome" && $5 == "plan-review-go" && $3 == "9" && $6 == "operator" { print }'
}

go_anchor_ts() {
  select_go_anchor_rows | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); if (m == "" || t < m) m = t } END { if (m != "") print m }'
}

# t_go_na_reason <release> — the T_GO half of the N/A diagnostic.
#   Reads the release's gate-outcome rows on stdin (query-pipeline-event.sh layout)
#   and echoes ONE reason, no trailing separator. Called only when go_anchor_ts found
#   no row of the Stage-9 GO identity. Two causes, two distinct reasons:
#     none      no plan-review-go row under this release's join keys: the reason this
#               tool has always printed, kept byte-for-byte;
#     identity  plan-review-go rows exist, and none carries stage 9 and actor operator.
#   The identity miss is worded as what the tool observed under its join keys, never
#   as a cause: a legacy release's Stage-9 GO can sit under a key the schema's § 2a
#   ladder does not reach, so "no row found here carries the identity" is the fact,
#   and "the GO was never rendered" might not be.
#   A reason never contains "; " or a "|" — the caller joins the T_GO and T_DEPLOY
#   halves with "; ", and the close-out carries the line verbatim.
t_go_na_reason() {
  /usr/bin/awk -F ' \\| ' -v rel="$1" '
    /^\| [0-9]/ && $4 == "gate-outcome" && $5 == "plan-review-go" { n++ }
    END {
      if (n == 0) { printf "no gate-outcome/plan-review-go event for %s", rel; exit }
      printf "%d gate-outcome/plan-review-go row(s) exist for %s but NONE is the Stage-9 GO anchor (stage 9, actor operator): of the rows found under the join keys of this release, none was written at stage 9 by operator. A row at another stage or under another actor authorizes no release, and this is NOT the same as no GO row having been emitted", n, rel
    }'
}

# ─── Rung-3 INDETERMINATE notice (#5467) ─────────────────────────────────────
# rung3_notice_lines <anchor> — the query tool's rung-3 INDETERMINATE notice for ONE read.
#   Reads that read's query-tool output on stdin, stderr included, and echoes each
#   INDETERMINATE notice in it as one line that names the read:
#     INDETERMINATE (<anchor> read): <the query tool's words> <what this tool does with the rows>
#   It echoes nothing when the query tool printed no such notice. Only that notice is
#   repeated: the query tool's best-effort rung-3 NOTE and its in-flight NOTE would put a
#   line on every legacy and every in-flight release. The closing clause is true whether
#   or not an anchor is found, so the line never claims the anchor rests on the reported
#   rows — only that they were not excluded. One function, so the two reads share one
#   wording; group RI grades it end to end, through the real query tool.
rung3_notice_lines() {
  /usr/bin/awk -v anchor="$1" '
    index($0, "INDETERMINATE: ") == 1 {
      printf "INDETERMINATE (%s read): %s compute-cycle-time.sh selects %s over the rows as returned, these included.\n", anchor, substr($0, 16), anchor
    }'
}

# ─── T_DEPLOY anchor-row selection (#4215) ───────────────────────────────────
#
# Reads pipe-delimited event rows on stdin, echoes only those eligible to anchor
# T_DEPLOY. Factored out of the main flow so the self-test can grade the PREDICATE
# rather than only the arithmetic around it — an inline filter is unreachable from a
# test, and an untestable filter is exactly the shape of control this release exists to
# eliminate.
#
# Field map under FS=" | ": the row's leading "| " has no preceding space, so it is not
# a delimiter — $1 retains it and reads "| <ts_iso>", $2 is version, $5 is event_subtype
# and $9 is outcome.
select_deploy_anchor_rows() {
  /usr/bin/awk -F ' \\| ' '($5 == "deploy-skill" || $5 == "deploy-harness") && $9 == "resolved" { print }'
}

# ─── T_DEPLOY subtype partition + N/A reason (#5553) ─────────────────────────
#
# Every deployment-status subtype the schema declares sits in exactly ONE of these two
# sets. TD_ANCHOR_SUBTYPES MUST name what select_deploy_anchor_rows admits: self-test
# arm CR-7 fails the moment they disagree, CR-8 fails when the schema's enum and the
# partition differ, and CR-9 fails when compute-dora-metrics.sh anchors its deployment
# occasions on a different set. A subtype in neither set is still reported, as
# unrecognized.
TD_ANCHOR_SUBTYPES="deploy-skill deploy-harness"
TD_EXCLUDED_SUBTYPES="deploy-package deploy-rules-mirror deploy-helper"

# t_deploy_na_reason <release> — the T_DEPLOY half of the N/A diagnostic.
#   Reads the release's deployment-status rows on stdin (query-pipeline-event.sh
#   layout) and echoes ONE reason, no trailing separator. Called only when
#   select_deploy_anchor_rows kept nothing. Every row is accounted for: #5553 was a
#   valid row discarded without a trace, then misreported as a failed target. Three
#   causes, three distinct reasons; collapsing any two recreates a defect:
#     none      no deployment-status row at all;
#     failed    >=1 skill/harness row and none resolved: the ONLY reason that says
#               "did not succeed" (#4215 PRF-1). Excluded rows are listed, and they
#               never rescue it;
#     excluded  rows exist and none is of an anchor subtype.
#   Each non-anchor subtype is named with a tally of its rows: resolved and not
#   resolved, then by producer — "by the deploy emitter" when the payload carries the
#   emitter's mech:deploy.sh --deploy segment, "hand-written" otherwise. The reason
#   states the RULE and the PRODUCER, never what a subtype means: hand-written
#   release-level markers are typed with these subtypes too and record no deploy
#   target, so a per-subtype meaning would describe an act the row does not record.
#   The meaning lives in deployment-cycle-time.md § 2.1, which the reason names.
#   A reason never contains "; " or a "|" — the caller joins the T_GO and T_DEPLOY
#   halves with "; ", and the close-out carries the line verbatim.
t_deploy_na_reason() {
  /usr/bin/awk -F ' \\| ' -v rel="$1" -v anchors="$TD_ANCHOR_SUBTYPES" \
      -v excluded="$TD_EXCLUDED_SUBTYPES" '
    BEGIN {
      na = split(anchors, A, " ")
      for (i = 1; i <= na; i++) {
        isA[A[i]] = 1
        aand = aand (i == 1 ? "" : (i == na ? " and " : ", ")) A[i]
        aslash = aslash (i > 1 ? "/" : "") A[i]
      }
      ne = split(excluded, E, " ")
      for (i = 1; i <= ne; i++) isE[E[i]] = 1
    }
    /^\| [0-9]/ {
      s = $5; o = $9; total++
      if (s in isA) {
        a++
        if (o == "resolved") ar++
        else { if (!(o in ao)) aord[++nao] = o; ao[o]++ }
        next
      }
      if (!(s in cnt)) ord[++n] = s
      cnt[s]++
      if (o == "resolved") res[s]++
      if (index($10, "mech:deploy.sh --deploy") > 0) emi[s]++
    }
    END {
      if (total == 0) { printf "no deployment-status event for %s", rel; exit }
      if (ar > 0) {
        printf "INTERNAL: %d resolved %s row(s) for %s were not selected as the T_DEPLOY anchor - TD_ANCHOR_SUBTYPES and select_deploy_anchor_rows disagree", ar, aslash, rel
        exit
      }
      tally = ""
      for (i = 1; i <= n; i++) {
        s = ord[i]; r = res[s] + 0; nr = cnt[s] - r; e = emi[s] + 0
        t = s " " cnt[s] " (" r " resolved" (nr > 0 ? ", " nr " not resolved" : "") ", " e " by the deploy emitter, " (cnt[s] - e) " hand-written)"
        if (!(s in isE)) t = t ", an unrecognized subtype outside the schema enum"
        tally = tally (tally == "" ? "" : " / ") t
      }
      if (a > 0) {
        br = ""
        for (i = 1; i <= nao; i++) br = br (i > 1 ? ", " : "") aord[i] " " ao[aord[i]]
        printf "%d %s row(s) exist for %s but NONE reached outcome=resolved (%s) — the deploy ran and its targets did not succeed. This is NOT the same as no deploy having occurred", a, aslash, rel, br
        if (tally != "") printf " [also present, never an anchor: %s]", tally
        exit
      }
      printf "%d deployment-status row(s) exist for %s, none of an anchor subtype — T_DEPLOY anchors only on %s, per deployment-cycle-time.md § 2.1, so it is excluded by definition, not by an anchor target failing: %s", total, rel, aand, tally
    }'
}

# Format integer seconds as "47m" or "2h17m".
format_human() {
  local secs="$1"
  if [[ "$secs" -lt 3600 ]]; then
    /usr/bin/printf '%dm\n' "$((secs / 60))"
  else
    /usr/bin/printf '%dh%dm\n' "$((secs / 3600))" "$(((secs % 3600) / 60))"
  fi
}

# ─── Self-test mode ──────────────────────────────────────────────────────────

if [[ "$SELF_TEST" == "true" ]]; then
  # Test 1: ISO8601 delta arithmetic
  RESULT="$(compute_delta_seconds "2026-05-15T14:22:01Z" "2026-05-15T15:09:34Z")" || die "self-test: compute_delta_seconds failed"
  if [[ "$RESULT" != "2853" ]]; then
    die "self-test: delta arithmetic wrong (expected 2853, got $RESULT)"
  fi

  # Test 2: human formatter — sub-hour
  RESULT="$(format_human 2820)"
  if [[ "$RESULT" != "47m" ]]; then
    die "self-test: format_human(2820) wrong (expected '47m', got '$RESULT')"
  fi

  # Test 3: human formatter — over-hour
  RESULT="$(format_human 8220)"
  if [[ "$RESULT" != "2h17m" ]]; then
    die "self-test: format_human(8220) wrong (expected '2h17m', got '$RESULT')"
  fi

  # Test 4: human formatter — exactly one hour
  RESULT="$(format_human 3600)"
  if [[ "$RESULT" != "1h0m" ]]; then
    die "self-test: format_human(3600) wrong (expected '1h0m', got '$RESULT')"
  fi

  # Test 5: human formatter — zero
  RESULT="$(format_human 0)"
  if [[ "$RESULT" != "0m" ]]; then
    die "self-test: format_human(0) wrong (expected '0m', got '$RESULT')"
  fi

  # Test 6: query tool exists and is executable
  [[ -x "$QUERY_TOOL" ]] || die "self-test: query-pipeline-event.sh not executable at $QUERY_TOOL"

  # Test 7: malformed ISO8601 → exit 2
  if compute_delta_seconds "not-a-timestamp" "2026-05-15T15:09:34Z" >/dev/null 2>&1; then
    die "self-test: malformed ts_iso accepted (should exit 2)"
  fi

  # ─── Group CT — T_DEPLOY anchor eligibility (#4215) ────────────────────────
  #
  # The predicate, not the arithmetic. Every arm is paired with the mutation that must
  # turn it red: delete the `&& $9 == "resolved"` conjunct from select_deploy_anchor_rows
  # and CT-2, CT-4 and CT-5 all fail. An arm whose mutation leaves it green is theatre.
  #
  # Fixture rows use the field layout query-pipeline-event.sh emits:
  #   "| ts | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |"
  CT_ROWS="$(/bin/cat <<'ROWS'
| 2026-01-02T10:00:00Z | slug-a | 12 | deployment-status | deploy-skill | hub | skill:a | CHEAP | resolved | p |
| 2026-01-02T10:00:05Z | slug-a | 12 | deployment-status | deploy-harness | hub | harness:h | CHEAP | resolved | p |
| 2026-01-02T11:00:00Z | slug-a | 12 | deployment-status | deploy-skill | hub | skill:b | CHEAP | escalated | p |
| 2026-01-02T11:30:00Z | slug-a | 12 | deployment-status | deploy-package | hub | package:p | CHEAP | resolved | p |
| 2026-01-02T12:00:00Z | slug-a | 12 | deployment-status | deploy-skill | hub | skill:c | CHEAP | pending | p |
ROWS
)"

  # CT-1 — SENSITIVITY. The selector fires at all: the two resolved target rows are kept.
  #        Without this arm, every "excluded" assertion below would also pass on a
  #        selector that returns nothing, which proves nothing.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c . || true)"
  if [[ "$RESULT" != "2" ]]; then
    die "self-test: CT-1 selector must keep the 2 resolved deploy-skill/deploy-harness rows, got $RESULT"
  fi

  # CT-2 — THE PRF-1 ARM. An escalated deploy-skill row must NOT anchor T_DEPLOY. This
  #        is the case that previously produced a measured duration for a deploy in
  #        which nothing deployed.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c 'skill:b' || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-2 an escalated deploy row must NOT be anchor-eligible, got $RESULT"
  fi

  # CT-3 — the DECLARED narrowing: deploy-package is audit-only and never an anchor.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c 'deploy-package' || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-3 deploy-package must NOT be anchor-eligible (declared narrowing), got $RESULT"
  fi

  # CT-3b — CT-3's NEGATIVE CONTROL, and the reason CT-3 is now a demonstration
  #         rather than an assertion. CT-3 alone only ever PASSES: its zero is
  #         equally consistent with a live narrowing and with a selector that
  #         never had `deploy-package` to reject. Stage 8 measured exactly that —
  #         the CT-1 mutation (delete the `resolved` conjunct) moves rows-kept
  #         2 → 4 while CT-3 stays 0 → 0, so CT-3 observed nothing the rest of
  #         the group had not already observed.
  #
  #         This arm removes the observing step and shows the zero move. The
  #         widened selector is DERIVED FROM THE SHIPPED FUNCTION'S OWN SOURCE by
  #         an asserted transform — never transcribed — so it cannot drift into a
  #         shadow copy that keeps passing after the real predicate changes. An
  #         unbitten substitution ABORTS the arm rather than letting it read green
  #         for the wrong reason.
  _ct_src="$(declare -f select_deploy_anchor_rows)"
  _ct_widened="$(/usr/bin/printf '%s\n' "$_ct_src" \
    | /usr/bin/sed -e 's/select_deploy_anchor_rows/_ct_widened_selector/' \
                   -e 's/\$5 == "deploy-harness"/$5 == "deploy-harness" || $5 == "deploy-package"/')"
  if [[ "$_ct_widened" == "$_ct_src" ]] || ! /usr/bin/grep -q 'deploy-package' <<<"$_ct_widened"; then
    die "self-test: CT-3b the widening transform did not bite the shipped selector source — the arm is inert and must be repaired, never silenced"
  fi
  eval "$_ct_widened"
  RESULT="$(printf '%s\n' "$CT_ROWS" | _ct_widened_selector | /usr/bin/grep -c 'deploy-package' || true)"
  if [[ "$RESULT" != "1" ]]; then
    die "self-test: CT-3b NEGATIVE CONTROL — the widened selector must ADMIT the deploy-package row (expected 1, got $RESULT); if it does not, CT-3's zero is uninformative and proves nothing about the narrowing"
  fi
  unset -f _ct_widened_selector

  # CT-4 — outcome=pending is not a terminal success either. The conjunct is an
  #        ALLOWLIST on `resolved`, not a denylist on `escalated`, and this arm is what
  #        makes that difference observable.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows | /usr/bin/grep -c 'skill:c' || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-4 a pending deploy row must NOT be anchor-eligible, got $RESULT"
  fi

  # CT-5 — MAX over the ELIGIBLE set, not over all rows. The escalated row at 11:00 and
  #        the package row at 11:30 are both LATER than the last resolved target row at
  #        10:00:05, so a selector that leaked either would move the anchor forward and
  #        silently inflate every cycle time it reports.
  RESULT="$(printf '%s\n' "$CT_ROWS" | select_deploy_anchor_rows \
            | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); print t }' | /usr/bin/sort | /usr/bin/tail -1)"
  if [[ "$RESULT" != "2026-01-02T10:00:05Z" ]]; then
    die "self-test: CT-5 T_DEPLOY must be the MAX over ELIGIBLE rows (2026-01-02T10:00:05Z), got $RESULT"
  fi

  # CT-6 — SPECIFICITY. A log containing only non-eligible rows yields an empty
  #        selection, so CT-1's non-zero is the selector detecting rather than leaking.
  RESULT="$(printf '%s\n' "$CT_ROWS" | /usr/bin/grep -E 'escalated|pending|deploy-package' | select_deploy_anchor_rows | /usr/bin/grep -c . || true)"
  if [[ "$RESULT" != "0" ]]; then
    die "self-test: CT-6 a population of only non-eligible rows must select nothing, got $RESULT"
  fi

  # ─── Group CR — the T_DEPLOY N/A reason accounts for every row (#5553) ─────
  #
  # A package-only or rules-mirror-only occasion was a valid row discarded without a trace
  # and then misreported as "the deploy ran and its targets did not succeed". The arms grade
  # t_deploy_na_reason, the pure function the main flow calls, over one invocation's rows
  # (mirror, skills, packages). Each arm is paired with the mutation that must turn it red:
  # routing the excluded case into the failed branch turns CR-1, CR-3 and CR-6 red (CR-4, the
  # failed case itself, stays green); dropping the producer tally turns CR-3 and CR-4 red;
  # widening the selector alone turns CR-7 red; a partition that differs from the schema's
  # enum turns CR-8 red; widening TD_ANCHOR_SUBTYPES alone turns CR-1 red first, through the
  # INTERNAL disagreement reason; a DORA anchor tuple that differs turns CR-9 red; swallowing
  # the query tool's failure at both reads turns CR-10 red, and at either read alone CG-12
  # (with one log both reads fail, so the first read's check is the one CR-10 observes). A
  # reason that carried "; " or "|" would split the caller's joined line, so every reason
  # arm asserts neither is present.
  _cr_row() { /usr/bin/printf '| 2026-01-03T09:00:%sZ | slug-x | 12 | deployment-status | %s | hub | x:y | CHEAP | %s | %s |' "$1" "$2" "$3" "${4:-p}"; }
  _cr_emit='target:x; module:core; mech:deploy.sh --deploy; result:SUCCESS; detail:none'
  CR_MIR="$(_cr_row 00 deploy-rules-mirror resolved "$_cr_emit")"; CR_SKL="$(_cr_row 10 deploy-skill resolved "$_cr_emit")"
  CR_SKE="$(_cr_row 10 deploy-skill escalated)";       CR_PKG="$(_cr_row 20 deploy-package resolved)"
  CR_PKE="$(_cr_row 20 deploy-package escalated)";     CR_HLP="$(_cr_row 30 deploy-helper resolved)"
  CR_UNK="$(_cr_row 40 deploy-zzz resolved)"
  _cr_sel()    { /usr/bin/printf '%s\n' "$@" | select_deploy_anchor_rows | /usr/bin/grep -c . || true; }
  _cr_reason() { /usr/bin/printf '%s\n' "$@" | t_deploy_na_reason "slug-x"; }
  _cr_nosep()  { [[ "$1" != *"; "* && "$1" != *"|"* ]] || die "self-test: $2 the reason carries '; ' or '|', which splits the caller's joined N/A line: '$1'"; }

  # CR-1 — AC-3 arm P: a package-only occasion reads N/A naming deploy-package, never "did not succeed".
  RESULT="$(_cr_sel "$CR_PKG")"
  [[ "$RESULT" == "0" ]] || die "self-test: CR-1 a deploy-package row must not anchor T_DEPLOY, got $RESULT kept"
  RESULT="$(_cr_reason "$CR_PKG")"
  [[ "$RESULT" == *"deploy-package 1 (1 resolved, 0 by the deploy emitter, 1 hand-written)"* && "$RESULT" == *"excluded by definition"* && "$RESULT" != *"did not succeed"* ]] \
    || die "self-test: CR-1 a package-only occasion must read N/A naming deploy-package with its tally, never 'did not succeed', got '$RESULT'"
  _cr_nosep "$RESULT" CR-1

  # CR-2 — AC-3 control: a skill-bearing occasion computes T_DEPLOY on its skill row.
  RESULT="$(_cr_sel "$CR_MIR" "$CR_SKL" "$CR_PKG")"
  [[ "$RESULT" == "1" ]] || die "self-test: CR-2 a skill-bearing occasion must keep exactly its skill row, got $RESULT kept"
  RESULT="$(/usr/bin/printf '%s\n' "$CR_MIR" "$CR_SKL" "$CR_PKG" | select_deploy_anchor_rows \
            | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); print t }' | /usr/bin/sort | /usr/bin/tail -1)"
  [[ "$RESULT" == "2026-01-03T09:00:10Z" ]] || die "self-test: CR-2 T_DEPLOY must anchor on the skill row (2026-01-03T09:00:10Z), got '$RESULT'"

  # CR-3 — the content-only stamped deploy: one emitter-written rules-mirror row.
  RESULT="$(_cr_reason "$CR_MIR")"
  [[ "$RESULT" == *"deploy-rules-mirror 1 (1 resolved, 1 by the deploy emitter, 0 hand-written)"* && "$RESULT" != *"did not succeed"* ]] \
    || die "self-test: CR-3 a rules-mirror-only occasion must read N/A naming deploy-rules-mirror with its tally, never 'did not succeed', got '$RESULT'"
  _cr_nosep "$RESULT" CR-3

  # CR-4 — PRF-1 survives (the CIAC-2 control): skill rows none of which resolved still say
  #        "did not succeed", and an excluded row present beside them never rescues it.
  RESULT="$(_cr_reason "$CR_MIR" "$CR_SKE")"
  [[ "$RESULT" == *"NONE reached outcome=resolved (escalated 1)"* && "$RESULT" == *"did not succeed"* && "$RESULT" == *"never an anchor: deploy-rules-mirror 1 (1 resolved, 1 by the deploy emitter, 0 hand-written)"* ]] \
    || die "self-test: CR-4 a skill row that did not resolve must still read 'did not succeed', listing the excluded row beside it, got '$RESULT'"
  _cr_nosep "$RESULT" CR-4

  # CR-5 — no rows at all: the None cause, exactly.
  RESULT="$(/usr/bin/printf '' | t_deploy_na_reason "slug-x")"
  [[ "$RESULT" == "no deployment-status event for slug-x" ]] || die "self-test: CR-5 no rows must read exactly 'no deployment-status event for slug-x', got '$RESULT'"

  # CR-6 — TOTALITY: a failed excluded row, the producer-less subtype and an unknown subtype
  #        are each named with their tally; none of them says "did not succeed".
  RESULT="$(_cr_reason "$CR_PKE" "$CR_HLP" "$CR_UNK")"
  [[ "$RESULT" == *"deploy-package 1 (0 resolved, 1 not resolved, 0 by the deploy emitter, 1 hand-written)"* \
     && "$RESULT" == *"deploy-helper 1 (1 resolved, 0 by the deploy emitter, 1 hand-written)"* \
     && "$RESULT" == *"deploy-zzz 1 (1 resolved, 0 by the deploy emitter, 1 hand-written), an unrecognized subtype"* \
     && "$RESULT" != *"did not succeed"* ]] \
    || die "self-test: CR-6 every non-anchor row must be named with its tally, the unknown subtype as unrecognized, got '$RESULT'"
  _cr_nosep "$RESULT" CR-6

  # CR-7 — PARTITION PARITY: each anchor subtype is kept by the selector, each excluded one is not.
  for _cr_s in $TD_ANCHOR_SUBTYPES; do
    RESULT="$(_cr_sel "$(_cr_row 50 "$_cr_s" resolved)")"
    [[ "$RESULT" == "1" ]] || die "self-test: CR-7 anchor subtype $_cr_s is not admitted by select_deploy_anchor_rows (got $RESULT): the partition and the selector disagree"
  done
  for _cr_s in $TD_EXCLUDED_SUBTYPES; do
    RESULT="$(_cr_sel "$(_cr_row 50 "$_cr_s" resolved)")"
    [[ "$RESULT" == "0" ]] || die "self-test: CR-7 excluded subtype $_cr_s IS admitted by select_deploy_anchor_rows (got $RESULT): move it or narrow the selector"
    [[ " $TD_ANCHOR_SUBTYPES " != *" $_cr_s "* ]] || die "self-test: CR-7 $_cr_s is in both partition sets"
  done
  unset -f _cr_row _cr_sel _cr_reason _cr_nosep

  # CR-8 — TOTALITY: the partition is exactly the schema's deployment-status enum, read with the
  #        writer's rule (col-3 backtick tokens of that row inside "## 3."). An unclassified new
  #        subtype fails here instead of reaching production as an unrecognized row.
  _cr_schema="$REPO_ROOT/release/references/standards/pipeline-event-log-schema.md"
  [[ -r "$_cr_schema" ]] || die "self-test: CR-8 cannot read the schema at $_cr_schema, so partition totality is unestablished"
  _cr_enum="$(/usr/bin/awk -F'|' '/^## 3\./ { s = 1; next } s && /^## / { s = 0 }
      s && $2 ~ /^ *`deployment-status` *$/ { r = $4; while (match(r, /`[a-z0-9.-]+`/)) { print substr(r, RSTART + 1, RLENGTH - 2); r = substr(r, RSTART + RLENGTH) } }' "$_cr_schema" | /usr/bin/sort)"
  _cr_part="$(/usr/bin/printf '%s\n' $TD_ANCHOR_SUBTYPES $TD_EXCLUDED_SUBTYPES | /usr/bin/sort)"
  [[ -n "$_cr_enum" && "$_cr_enum" == "$_cr_part" ]] \
    || die "self-test: CR-8 the partition ($(echo $_cr_part)) is not exactly the schema's deployment-status enum ($(echo $_cr_enum)): classify every subtype"

  # CR-9 — CROSS-READER PARITY: compute-dora-metrics.sh anchors its deployment occasions on
  #        the same set, in its own python (esub in ("deploy-skill", "deploy-harness")). A
  #        change that widened one reader and not the other would land green with T_DEPLOY
  #        and the DORA occasion set silently diverged, so the tuple is read from that tool's
  #        source and must equal TD_ANCHOR_SUBTYPES. A deliberate divergence is declared in
  #        deployment-cycle-time.md § 2.1 and this arm changes with it — never silenced.
  _cr_dora="$SCRIPT_DIR/compute-dora-metrics.sh"
  [[ -r "$_cr_dora" ]] || die "self-test: CR-9 cannot read $_cr_dora, so the DORA anchor-set parity is unestablished"
  _cr_dline="$(/usr/bin/grep -c -F 'etype == "deployment-status" and esub in (' "$_cr_dora" || true)"
  [[ "$_cr_dline" == "1" ]] || die "self-test: CR-9 expected exactly one deployment-status anchor tuple in compute-dora-metrics.sh, found $_cr_dline"
  _cr_dset="$(/usr/bin/grep -F 'etype == "deployment-status" and esub in (' "$_cr_dora" \
      | /usr/bin/sed -e 's/.*esub in (//' -e 's/).*//' | /usr/bin/tr -d ' "' | /usr/bin/tr ',' '\n' | /usr/bin/sort)"
  _cr_aset="$(/usr/bin/printf '%s\n' $TD_ANCHOR_SUBTYPES | /usr/bin/sort)"
  [[ -n "$_cr_dset" && "$_cr_dset" == "$_cr_aset" ]] \
    || die "self-test: CR-9 compute-dora-metrics.sh anchors DORA occasions on ($(echo $_cr_dset)) but TD_ANCHOR_SUBTYPES is ($(echo $_cr_aset)): the two readers of the T_DEPLOY anchor set disagree"

  # CR-10 — A READ THAT NEVER HAPPENED IS NOT A MEASURED ABSENCE. With the event log
  #         missing, query-pipeline-event.sh exits 1. A tool that swallowed that status
  #         published the None cause ("no deployment-status event") at exit 0: the same
  #         text a release with no rows produces, for a fact nobody observed. The tool
  #         runs as a child process against an empty evals directory, and must exit 1
  #         (the header's "log file missing") with no Cycle-Time line.
  _cr_evals="$(/usr/bin/mktemp -d)"
  _cr_rc=0
  _cr_out="$(EVALS_RESULTS_PATH="$_cr_evals" /bin/bash "${BASH_SOURCE[0]}" --version slug-x 2>&1)" || _cr_rc=$?
  /bin/rmdir "$_cr_evals"
  [[ "$_cr_rc" -eq 1 ]] || die "self-test: CR-10 with the event log missing the tool must exit 1 (log file missing), got $_cr_rc: '$_cr_out'"
  [[ "$_cr_out" != *"Cycle-Time: N/A"* ]] || die "self-test: CR-10 a log that was never read was published as a Cycle-Time N/A: '$_cr_out'"

  # U-1 — --help prints the WHOLE header: #4215 grew it by 14 lines past usage()'s fixed window,
  #       so --help cut the premise mid-sentence. Whatever renders it, --help must end on the
  #       header's last comment line, so a regression fails here, in its own commit.
  _u_last="$(/usr/bin/awk 'NR > 1 && !/^#/ { print prev; exit } { prev = $0 }' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//')"
  RESULT="$(usage | /usr/bin/tail -1)"
  [[ -n "$_u_last" && "$RESULT" == "$_u_last" ]] \
    || die "self-test: U-1 --help must end on the header's last comment line ('$_u_last'), got '$RESULT': fix usage()"

  # ─── Group CG — T_GO anchor identity ───────────────────────────────────────
  # Predicate AND reduction via the main flow's go_anchor_ts, then the N/A reason and
  # the read that feeds both. Each arm is paired with the mutation that must turn it
  # red: deleting a term of the identity turns its arm red (CG-4 stage, CG-5 actor,
  # CG-6 subtype) and CG-2 with it; MAX in place of MIN fails CG-2; a reason that
  # collapses the identity miss into the no-rows cause fails CG-9, and one that
  # rewords the no-rows cause fails CG-10; swallowing the query tool's failure at the
  # T_GO read fails CG-11, and at either read fails CG-12.
  CG_ROWS="$(/bin/cat <<'ROWS'
| 2026-01-03T09:00:00Z | slug-g | 7 | gate-outcome | plan-review-go | hub | issue:#1 | CHEAP | resolved | p |
| 2026-01-03T09:30:00Z | slug-g | 4 | gate-outcome | plan-review-go | operator | milestone:#1 | MODERATE | resolved | p |
| 2026-01-03T09:45:00Z | slug-g | 9 | gate-outcome | plan-review-go | hub | milestone:#1 | CHEAP | resolved | p |
| 2026-01-03T09:50:00Z | slug-g | 9 | gate-outcome | goal-conformance | operator | milestone:#1 | MODERATE | resolved | p |
| 2026-01-03T10:00:00Z | slug-g | 9 | gate-outcome | plan-review-go | operator | milestone:#1 | MODERATE | resolved | p |
| 2026-01-03T11:00:00Z | slug-g | 12 | gate-outcome | plan-review-go | operator | milestone:#1 | MODERATE | resolved | p |
| 2026-01-03T12:00:00Z | slug-g | 9 | gate-outcome | plan-review-go | operator | milestone:#1 | MODERATE | resolved | p |
ROWS
)"
  # CG-1 SENSITIVITY: exactly the 2 operator Stage-9 GO rows are kept.
  RESULT="$(printf '%s\n' "$CG_ROWS" | select_go_anchor_rows | /usr/bin/grep -c . || true)"
  [[ "$RESULT" == "2" ]] || die "self-test: CG-1 expected the 2 operator Stage-9 GO rows, got $RESULT"
  # CG-2 THE DEFECT ARM: the earliest row OF THE IDENTITY (10:00) — not the earliest of
  #      the subtype (09:00, a hub Stage-7 verdict), not the latest identity row (12:00).
  RESULT="$(printf '%s\n' "$CG_ROWS" | go_anchor_ts)"
  [[ "$RESULT" == "2026-01-03T10:00:00Z" ]] || die "self-test: CG-2 T_GO must be the earliest identity row (10:00:00Z), got '$RESULT'"
  # CG-3 NEGATIVE CONTROL: a subtype-only selector DERIVED FROM THE SHIPPED SOURCE by an
  #      asserted transform anchors on the hub Stage-7 row, so CG-2's value is the
  #      identity biting. A transform that leaves the stage term in place ABORTS the arm.
  _cg_src="$(declare -f select_go_anchor_rows)"
  _cg_sub="$(/usr/bin/printf '%s\n' "$_cg_src" \
    | /usr/bin/sed -e 's/select_go_anchor_rows/_cg_subtype_only_selector/' \
                   -e 's/\$4 == "gate-outcome" && //' \
                   -e 's/ && \$3 == "9" && \$6 == "operator"//')"
  if [[ "$_cg_sub" == "$_cg_src" ]] || /usr/bin/grep -qF -- '$3 == "9"' <<<"$_cg_sub"; then
    die "self-test: CG-3 transform did not bite the shipped source — repair the arm, never silence it"
  fi
  eval "$_cg_sub"
  RESULT="$(printf '%s\n' "$CG_ROWS" | _cg_subtype_only_selector \
            | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); if (m == "" || t < m) m = t } END { print m }')"
  [[ "$RESULT" == "2026-01-03T09:00:00Z" ]] || die "self-test: CG-3 NEGATIVE CONTROL a subtype-only selector must anchor on the hub Stage-7 row (09:00:00Z), got '$RESULT'"
  unset -f _cg_subtype_only_selector
  # CG-4 STAGE TERM: operator rows at stages 4 and 12 are not anchors.
  RESULT="$(printf '%s\n' "$CG_ROWS" | select_go_anchor_rows | /usr/bin/grep -cF -e ' | 4 | gate-outcome ' -e ' | 12 | gate-outcome ' || true)"
  [[ "$RESULT" == "0" ]] || die "self-test: CG-4 a non-stage-9 row anchored, got $RESULT"
  # CG-5 ACTOR TERM: a hub row at stage 9 is not an anchor.
  RESULT="$(printf '%s\n' "$CG_ROWS" | select_go_anchor_rows | /usr/bin/grep -cF ' | hub | ' || true)"
  [[ "$RESULT" == "0" ]] || die "self-test: CG-5 a hub row anchored, got $RESULT"
  # CG-6 SUBTYPE TERM: another gate-outcome at the same identity is not an anchor.
  RESULT="$(printf '%s\n' "$CG_ROWS" | select_go_anchor_rows | /usr/bin/grep -cF 'goal-conformance' || true)"
  [[ "$RESULT" == "0" ]] || die "self-test: CG-6 another subtype anchored, got $RESULT"
  # CG-7 SPECIFICITY: no identity row -> no T_GO (the main flow then names its N/A).
  RESULT="$(printf '%s\n' "$CG_ROWS" | /usr/bin/grep -vF '| 9 | gate-outcome | plan-review-go | operator |' | go_anchor_ts)"
  [[ -z "$RESULT" ]] || die "self-test: CG-7 no identity row must yield no T_GO, got '$RESULT'"
  # CG-8 CONTROL: a single-row release is unchanged.
  RESULT="$(printf '%s\n' '| 2026-01-04T10:00:00Z | slug-h | 9 | gate-outcome | plan-review-go | operator | milestone:#2 | MODERATE | resolved | p |' | go_anchor_ts)"
  [[ "$RESULT" == "2026-01-04T10:00:00Z" ]] || die "self-test: CG-8 single-row control changed, got '$RESULT'"
  # CG-9 THE IDENTITY MISS HAS ITS OWN REASON: plan-review-go rows exist and none carries
  #      the identity (CG-7's input, 4 GO rows). The reason names the count and the
  #      identity, as observed under the join keys, and differs from the no-rows cause.
  #      It carries neither "; " nor "|", which would split the caller's joined line.
  RESULT="$(printf '%s\n' "$CG_ROWS" | /usr/bin/grep -vF '| 9 | gate-outcome | plan-review-go | operator |' | t_go_na_reason "slug-g")"
  [[ "$RESULT" == "4 gate-outcome/plan-review-go row(s) exist for slug-g but NONE is the Stage-9 GO anchor (stage 9, actor operator)"* \
     && "$RESULT" == *"under the join keys of this release"* ]] \
    || die "self-test: CG-9 an identity miss must name its count and the Stage-9 GO identity, as observed under the join keys, got '$RESULT'"
  [[ "$RESULT" != *"; "* && "$RESULT" != *"|"* && "$RESULT" != *"did not succeed"* ]] \
    || die "self-test: CG-9 the identity-miss reason carries '; ', '|' or 'did not succeed': '$RESULT'"
  # CG-10 THE NO-ROWS CAUSE IS KEPT BYTE-FOR-BYTE: gate-outcome rows of other subtypes
  #       only, and then no rows at all, both read exactly as the reason always has.
  RESULT="$(printf '%s\n' "$CG_ROWS" | /usr/bin/grep -F 'goal-conformance' | t_go_na_reason "slug-g")"
  [[ "$RESULT" == "no gate-outcome/plan-review-go event for slug-g" ]] \
    || die "self-test: CG-10 no plan-review-go row must read exactly 'no gate-outcome/plan-review-go event for slug-g', got '$RESULT'"
  RESULT="$(/usr/bin/printf '' | t_go_na_reason "slug-g")"
  [[ "$RESULT" == "no gate-outcome/plan-review-go event for slug-g" ]] \
    || die "self-test: CG-10 no rows at all must read exactly 'no gate-outcome/plan-review-go event for slug-g', got '$RESULT'"
  # CG-11 THE T_GO READ CHECKS THE QUERY TOOL'S OWN EXIT STATUS: with the event log
  #       missing, the tool runs as a child process against an empty evals directory and
  #       must exit 1 naming the gate-outcome read, with no Cycle-Time line. A read that
  #       swallowed the failure would leave T_GO empty and die later, at the T_DEPLOY
  #       read, naming that read instead.
  _cg_evals="$(/usr/bin/mktemp -d)"
  _cg_rc=0
  _cg_out="$(EVALS_RESULTS_PATH="$_cg_evals" /bin/bash "${BASH_SOURCE[0]}" --version slug-g 2>&1)" || _cg_rc=$?
  /bin/rmdir "$_cg_evals"
  [[ "$_cg_rc" -eq 1 && "$_cg_out" == *"reading the gate-outcome rows"* && "$_cg_out" != *"Cycle-Time: N/A"* ]] \
    || die "self-test: CG-11 with the event log missing the tool must exit 1 at the gate-outcome read, with no Cycle-Time line; got rc $_cg_rc: '$_cg_out'"
  # CG-12 EVERY QUERY-TOOL READ CHECKS ITS EXIT STATUS, read from this file's source:
  #       each main-flow read assignment is followed by the die that names the failure.
  #       CG-11 and CR-10 exercise the reads end to end, but with one log both fail at the
  #       first read, so the later read's check is visible only here. A count under 2
  #       means the probe found neither read, which is a broken probe, not a pass.
  _cg_reads="$(/usr/bin/awk '
      /^[A-Z_]+="\$\("\$QUERY_TOOL" --release / { r++; pend = 1; next }
      pend { if ($0 ~ /^  \|\| die "query-pipeline-event\.sh exited /) g++; pend = 0 }
      END { printf "%d %d", r, g }' "${BASH_SOURCE[0]}")"
  read -r _cg_r _cg_g <<<"$_cg_reads"
  [[ "$_cg_r" -ge 2 ]] || die "self-test: CG-12 found $_cg_r query-tool read(s) in the main flow, expected at least 2 (T_GO and T_DEPLOY): the probe is broken, repair it"
  [[ "$_cg_g" -eq "$_cg_r" ]] || die "self-test: CG-12 $((_cg_r - _cg_g)) of $_cg_r query-tool read(s) do not check the tool's own exit status: a read that never happened would publish as a measured absence"
  # HELP-1: --help carries the T_GO identity contract. U-1 already asserts that --help
  #         renders the whole header, so this arm asserts only the contract's content.
  _help_out="$(usage)"
  [[ "$_help_out" == *"Stage-9 GO rows"* ]] || die "self-test: HELP-1 --help does not carry the T_GO identity contract ('Stage-9 GO rows')"

  # ─── Group RI — the query tool's rung-3 INDETERMINATE notice is surfaced (#5467) ───
  # Both reads go through query-pipeline-event.sh --release, whose § 2a rung 3 also
  # matches the release's legacy vX.Y value. One legacy value can carry rows of more than
  # one release, and the query tool says so on its own stderr: INDETERMINATE, do not bind
  # them. A read that discards that stream anchors on such rows without a word. Every arm
  # runs this tool as a child process over a hermetic fixture — an event log and a
  # RELEASE_LOG binding of its own — and reads its stdout and stderr apart. Each arm is
  # paired with the mutation that must turn it red: discarding the query tool's stderr at
  # the T_GO read, or dropping that read's surfacing step, fails RI-1 and RI-6 and leaves
  # RI-2 passing; the same at the T_DEPLOY read fails RI-2 alone; surfacing every line of
  # the query tool's stderr fails RI-5; a notice folded into the reason line fails RI-6;
  # and a selection that drops the reported rows fails RI-3.
  #   slug-r  v9.93  both reads INDETERMINATE: two milestone subjects under the legacy key
  #   slug-s  v9.94  slug-keyed rows only — no rung-3 match at all
  #   slug-n  v9.95  legacy-keyed, ONE milestone subject — the query tool's best-effort NOTE
  #   slug-q  v9.96  the T_GO read INDETERMINATE and no deploy row — an N/A release
  _ri_tmp="$(/usr/bin/mktemp -d)"
  /bin/mkdir "$_ri_tmp/evals"
  /bin/cat > "$_ri_tmp/RELEASE_LOG.md" <<'RLOG'
| Version | Milestone | Issues | Release PR | Merge SHA | Tag | State | Date |
|---|---|---|---|---|---|---|---|
| v9.93 | slug-r | n/a | n/a | n/a | v9.93 | VERIFIED | 2026-02-01 |
| v9.94 | slug-s | n/a | n/a | n/a | v9.94 | VERIFIED | 2026-02-02 |
| v9.95 | slug-n | n/a | n/a | n/a | v9.95 | VERIFIED | 2026-02-03 |
| v9.96 | slug-q | n/a | n/a | n/a | v9.96 | VERIFIED | 2026-02-04 |
RLOG
  /bin/cat > "$_ri_tmp/evals/pipeline-event-log.md" <<'ROWS'
| ts_iso | version | stage | event_type | event_subtype | actor | subject | reversibility | outcome | payload |
|---|---|---|---|---|---|---|---|---|---|
| 2026-02-01T09:00:00Z | v9.93 | 9 | gate-outcome | plan-review-go | operator | milestone:#11 | MODERATE | resolved | p |
| 2026-02-01T10:00:00Z | v9.93 | 9 | gate-outcome | plan-review-go | operator | milestone:#12 | MODERATE | resolved | p |
| 2026-02-01T12:00:00Z | v9.93 | 12 | deployment-status | deploy-skill | hub | milestone:#11 | CHEAP | resolved | p |
| 2026-02-01T12:30:00Z | v9.93 | 12 | deployment-status | deploy-skill | hub | milestone:#12 | CHEAP | resolved | p |
| 2026-02-02T09:00:00Z | slug-s | 9 | gate-outcome | plan-review-go | operator | milestone:#13 | MODERATE | resolved | p |
| 2026-02-02T09:47:00Z | slug-s | 12 | deployment-status | deploy-skill | hub | skill:s | CHEAP | resolved | p |
| 2026-02-03T09:00:00Z | v9.95 | 9 | gate-outcome | plan-review-go | operator | milestone:#14 | MODERATE | resolved | p |
| 2026-02-03T10:00:00Z | v9.95 | 12 | deployment-status | deploy-skill | hub | milestone:#14 | CHEAP | resolved | p |
| 2026-02-04T09:00:00Z | v9.96 | 9 | gate-outcome | plan-review-go | operator | milestone:#15 | MODERATE | resolved | p |
| 2026-02-04T09:30:00Z | v9.96 | 9 | gate-outcome | plan-review-go | operator | milestone:#16 | MODERATE | resolved | p |
ROWS
  _ri_run() {  # <release> — this tool over the fixture; sets _ri_rc, _ri_out (stdout) and _ri_err (stderr)
    _ri_rc=0
    _ri_out="$(EVALS_RESULTS_PATH="$_ri_tmp/evals" RELEASE_LOG_FILE="$_ri_tmp/RELEASE_LOG.md" /bin/bash "${BASH_SOURCE[0]}" --version "$1" --iso 2>"$_ri_tmp/err")" || _ri_rc=$?
    _ri_err="$(/bin/cat "$_ri_tmp/err")"
  }
  _ri_query() {  # <release> <event type> — what the query tool itself prints on stderr for one read
    # shellcheck disable=SC2069  # deliberate order: stderr into the capture, stdout discarded
    EVALS_RESULTS_PATH="$_ri_tmp/evals" RELEASE_LOG_FILE="$_ri_tmp/RELEASE_LOG.md" "$QUERY_TOOL" --release "$1" --event-type "$2" 2>&1 >/dev/null || true
  }
  _ri_lines() {  # <text> <prefix> — counts the lines of <text> that begin with <prefix>; an empty prefix counts every non-empty line (no regex)
    /usr/bin/awk -v p="$2" '(p == "" && length($0) > 0) || (p != "" && index($0, p) == 1) { n++ } END { print n + 0 }' <<<"$1"
  }
  _ri_run slug-r; _ri_r_rc="$_ri_rc"; _ri_r_out="$_ri_out"; _ri_r_err="$_ri_err"
  _ri_run slug-s; _ri_s_rc="$_ri_rc"; _ri_s_out="$_ri_out"; _ri_s_err="$_ri_err"
  _ri_run slug-n; _ri_n_rc="$_ri_rc"; _ri_n_out="$_ri_out"; _ri_n_err="$_ri_err"
  _ri_run slug-q; _ri_q_rc="$_ri_rc"; _ri_q_out="$_ri_out"; _ri_q_err="$_ri_err"
  _ri_qt_r_go="$(_ri_query slug-r gate-outcome)";  _ri_qt_r_dep="$(_ri_query slug-r deployment-status)"
  _ri_qt_s_go="$(_ri_query slug-s gate-outcome)";  _ri_qt_s_dep="$(_ri_query slug-s deployment-status)"
  _ri_qt_n_go="$(_ri_query slug-n gate-outcome)";  _ri_qt_n_dep="$(_ri_query slug-n deployment-status)"
  _ri_qt_q_go="$(_ri_query slug-q gate-outcome)";  _ri_qt_q_dep="$(_ri_query slug-q deployment-status)"
  /bin/rm -f "$_ri_tmp/err" "$_ri_tmp/evals/pipeline-event-log.md" "$_ri_tmp/RELEASE_LOG.md"
  /bin/rmdir "$_ri_tmp/evals" "$_ri_tmp"
  unset -f _ri_run _ri_query

  # RI-0 ANTI-VACUITY — the fixture is what the arms below take it to be, read from the
  #      query tool itself: INDETERMINATE for both of slug-r's reads and for slug-q's
  #      T_GO read; the best-effort NOTE, never INDETERMINATE, for both of slug-n's; and
  #      nothing at all for slug-s's reads or for slug-q's T_DEPLOY read. A query tool
  #      that stopped reporting any of these would leave the arms below passing or
  #      failing for the wrong reason.
  [[ "$_ri_qt_r_go" == "INDETERMINATE: "*"'v9.93'"*"'slug-r'"* && "$_ri_qt_r_dep" == "INDETERMINATE: "*"'v9.93'"*"'slug-r'"* && "$_ri_qt_q_go" == "INDETERMINATE: "*"'v9.96'"*"'slug-q'"* ]] \
    || die "self-test: RI-0 the fixture must make the query tool report INDETERMINATE for slug-r's two reads and slug-q's T_GO read; got '$_ri_qt_r_go' / '$_ri_qt_r_dep' / '$_ri_qt_q_go'"
  [[ "$_ri_qt_n_go" == "NOTE: "*"'v9.95'"* && "$_ri_qt_n_dep" == "NOTE: "*"'v9.95'"* && "$_ri_qt_n_go$_ri_qt_n_dep" != *"INDETERMINATE"* ]] \
    || die "self-test: RI-0 the near-miss fixture must make the query tool print its best-effort NOTE, never INDETERMINATE, for slug-n's two reads; got '$_ri_qt_n_go' / '$_ri_qt_n_dep'"
  [[ -z "$_ri_qt_s_go$_ri_qt_s_dep$_ri_qt_q_dep" ]] \
    || die "self-test: RI-0 the query tool must print nothing on stderr for slug-s's reads or slug-q's T_DEPLOY read; got '$_ri_qt_s_go' / '$_ri_qt_s_dep' / '$_ri_qt_q_dep'"

  # RI-1, RI-2, RI-6 SENSITIVITY — each release-INDETERMINATE read's notice reaches this
  #      tool's stderr as ONE line that names the read and carries the query tool's own
  #      words: RI-1 the T_GO read and RI-2 the T_DEPLOY read of slug-r, a release that
  #      computes a value; RI-6 the T_GO read of slug-q, a release that reads N/A. The
  #      three are graded together and reported by name, so one run shows every read
  #      that stayed silent.
  _ri_miss=""
  [[ "$(_ri_lines "$_ri_r_err" 'INDETERMINATE (T_GO read): ')" == "1" && "$_ri_r_err" == *"INDETERMINATE (T_GO read): ${_ri_qt_r_go#INDETERMINATE: }"* ]] \
    || _ri_miss="${_ri_miss} RI-1 (slug-r, the T_GO read)"
  [[ "$(_ri_lines "$_ri_r_err" 'INDETERMINATE (T_DEPLOY read): ')" == "1" && "$_ri_r_err" == *"INDETERMINATE (T_DEPLOY read): ${_ri_qt_r_dep#INDETERMINATE: }"* ]] \
    || _ri_miss="${_ri_miss} RI-2 (slug-r, the T_DEPLOY read)"
  [[ "$(_ri_lines "$_ri_q_err" 'INDETERMINATE (T_GO read): ')" == "1" && "$_ri_q_err" == *"INDETERMINATE (T_GO read): ${_ri_qt_q_go#INDETERMINATE: }"* ]] \
    || _ri_miss="${_ri_miss} RI-6 (slug-q, the T_GO read)"
  [[ -z "$_ri_miss" ]] \
    || die "self-test:${_ri_miss} — the query tool reported this read's rows release-INDETERMINATE and the notice did not reach stderr as one line naming the read: the rows were bound without a word. stderr was '$_ri_r_err' (slug-r) and '$_ri_q_err' (slug-q)"

  # RI-3 NO VALUE MOVES — slug-r still computes, and on the same anchors: the notice is
  #      reported beside the value, and the selection runs over the rows as returned.
  #      stderr carries the two notice lines and nothing else.
  [[ "$_ri_r_rc" -eq 0 && "$_ri_r_out" == "T_GO=2026-02-01T09:00:00Z; T_DEPLOY=2026-02-01T12:30:00Z; delta=12600s" ]] \
    || die "self-test: RI-3 a release-INDETERMINATE read must not move the value: expected rc 0 and 'T_GO=2026-02-01T09:00:00Z; T_DEPLOY=2026-02-01T12:30:00Z; delta=12600s', got rc $_ri_r_rc and '$_ri_r_out'"
  [[ "$(_ri_lines "$_ri_r_err" '')" == "2" ]] \
    || die "self-test: RI-3 slug-r's stderr must carry its two notice lines and nothing else, got '$_ri_r_err'"

  # RI-4 CONTROL — a slug-keyed release with no rung-3 match: the value, and a silent stderr.
  [[ "$_ri_s_rc" -eq 0 && "$_ri_s_out" == "T_GO=2026-02-02T09:00:00Z; T_DEPLOY=2026-02-02T09:47:00Z; delta=2820s" && -z "$_ri_s_err" ]] \
    || die "self-test: RI-4 CONTROL a slug-keyed release must print its value and nothing on stderr, got rc $_ri_s_rc, '$_ri_s_out' and '$_ri_s_err'"

  # RI-5 SPECIFICITY — the near-miss. slug-n's rows are matched by the legacy value too,
  #      but under ONE milestone subject, so the query tool prints its best-effort NOTE
  #      (RI-0 shows it does). That line is not an INDETERMINATE notice and stays off
  #      this tool's stderr: surfacing it would put a line on every legacy release.
  [[ "$_ri_n_rc" -eq 0 && "$_ri_n_out" == "T_GO=2026-02-03T09:00:00Z; T_DEPLOY=2026-02-03T10:00:00Z; delta=3600s" && -z "$_ri_n_err" ]] \
    || die "self-test: RI-5 SPECIFICITY the query tool's best-effort NOTE must not be surfaced: expected the value and a silent stderr, got rc $_ri_n_rc, '$_ri_n_out' and '$_ri_n_err'"

  # RI-6 THE N/A SHAPE — the notice is its own line and never part of the reason. slug-q
  #      reads N/A for its missing T_DEPLOY, in exactly one reason line that is
  #      byte-for-byte the reason a release with no notice prints; the close-out lifts
  #      that line by its prefix. No T_DEPLOY-read line appears, because that read
  #      matched no legacy row.
  [[ "$_ri_q_rc" -eq 0 && "$_ri_q_out" == "T_GO=2026-02-04T09:00:00Z; T_DEPLOY=N/A; delta=N/A" ]] \
    || die "self-test: RI-6 slug-q must read N/A on its T_DEPLOY alone, got rc $_ri_q_rc and '$_ri_q_out'"
  [[ "$(_ri_lines "$_ri_q_err" 'Cycle-Time: N/A (')" == "1" && "$_ri_q_err" == *$'\n'"Cycle-Time: N/A (no deployment-status event for slug-q)" ]] \
    || die "self-test: RI-6 the N/A reason must stay one line, unchanged and last, beside the notice; got '$_ri_q_err'"
  [[ "$(_ri_lines "$_ri_q_err" 'INDETERMINATE (T_DEPLOY read): ')" == "0" && "$(_ri_lines "$_ri_q_err" '')" == "2" ]] \
    || die "self-test: RI-6 slug-q's T_DEPLOY read matched no legacy row, so its stderr is the T_GO notice and the reason line only; got '$_ri_q_err'"
  unset -f _ri_lines

  echo "self-test: PASS"
  echo "  ISO8601 delta arithmetic validated"
  echo "  human formatter validated (sub-hour, over-hour, exact-hour, zero)"
  echo "  malformed-input rejection validated"
  echo "  query-pipeline-event.sh dependency validated"
  echo "  T_DEPLOY anchor eligibility validated (#4215, group CT):"
  echo "    CT-1 SENSITIVITY the selector keeps 2 resolved target rows / CT-2 an escalated deploy row is NOT an anchor (the defect: a totally-failed deploy used to yield a measured duration) / CT-3 deploy-package is audit-only, never an anchor (declared narrowing) / CT-3b NEGATIVE CONTROL a selector widened to admit deploy-package — derived from the shipped source by an asserted transform, never transcribed — DOES keep that row, so CT-3's zero is the narrowing biting rather than an inert probe / CT-4 outcome=pending is excluded — the conjunct is an allowlist on resolved, not a denylist on escalated / CT-5 MAX is taken over the ELIGIBLE set, so a later ineligible row cannot move the anchor forward / CT-6 SPECIFICITY a non-eligible-only population selects nothing"
  echo "  T_DEPLOY N/A reason accounts for every row (#5553, group CR): CR-1..CR-6 package-only / skill-bearing control / rules-mirror-only / PRF-1 survives / no rows / totality, each non-anchor subtype named with its outcome and producer tally (deploy emitter or hand-written) and no reason carrying '; ' or '|'; CR-7 partition = selector; CR-8 partition = schema enum; CR-9 partition = the DORA read-model's anchor tuple; CR-10 an unreadable event log exits 1, never a published N/A"
  echo "  --help prints the whole header (U-1)"
  echo "  T_GO anchor identity validated (group CG): CG-1 SENSITIVITY the 2 operator Stage-9 GO rows are kept / CG-2 T_GO = the earliest row OF THE IDENTITY / CG-3 NEGATIVE CONTROL a subtype-only selector derived from the shipped source anchors on the hub Stage-7 row / CG-4 stage / CG-5 actor / CG-6 subtype term / CG-7 SPECIFICITY no identity row, no T_GO / CG-8 CONTROL a single-row release is unchanged / CG-9 an identity miss names its count and the identity as observed under the join keys / CG-10 the no-rows reason is kept byte-for-byte / CG-11 an unreadable log exits 1 at the T_GO read / CG-12 every query-tool read checks the tool's own exit status; HELP-1 --help carries the T_GO identity contract"
  echo "  the query tool's rung-3 INDETERMINATE notice is surfaced (#5467, group RI): RI-0 ANTI-VACUITY the fixture makes the query tool itself report INDETERMINATE for three reads, its best-effort NOTE for two and nothing for three / RI-1 SENSITIVITY the T_GO read's notice reaches stderr as one line naming the read and carrying the query tool's words / RI-2 SENSITIVITY the T_DEPLOY read's notice does too / RI-3 no value moves: the release still computes on the same anchors, and stderr carries the two notice lines and nothing else / RI-4 CONTROL a slug-keyed release prints its value and a silent stderr / RI-5 SPECIFICITY the query tool's best-effort NOTE is not surfaced / RI-6 on an N/A release the notice is its own line beside one unchanged reason line, and a read that matched no legacy row surfaces nothing"
  exit 0
fi

# ─── Required-field validation ───────────────────────────────────────────────

[[ -z "$VERSION" ]] && die "Required: <version> (positional or --version)"

# Query tool must exist
[[ -x "$QUERY_TOOL" ]] || die "query-pipeline-event.sh missing or not executable at $QUERY_TOOL"

# ─── Extract T_GO (the operator's Stage-9 GO: earliest row of that identity) ──

# The query tool can filter the subtype, but the identity predicate stays in
# go_anchor_ts so the self-test grades it.
# Output schema (from query-pipeline-event.sh): header rows then data rows.
# Data row: "| ts_iso | version | stage | event_type | event_subtype | ..."
# --release, NOT --version. The release join key is the milestone SLUG
# (pipeline-event-log-schema.md § 2a); a raw --version filter carrying a vX.Y
# matches ZERO slug-keyed rows, and this tool's `|| true` + empty-guard would
# then report N/A rather than erroring — a silent zero on the very metric the
# tool exists to produce. --release resolves through the § 2a ladder and
# accepts either form, so a legacy vX.Y argument still resolves.
# The query tool's OWN exit status is checked here as at the T_DEPLOY read below: a
# read that never happened is not a measured absence, and publishing the no-rows
# reason for it would state a fact nobody observed (exit 1 is the header's "log file
# missing").
GO_QUERY_OUT="$("$QUERY_TOOL" --release "$VERSION" --event-type gate-outcome 2>&1)" \
  || die "query-pipeline-event.sh exited $? reading the gate-outcome rows for $VERSION — the event log could not be read, so T_GO is not evaluated (run the query tool directly to see why)"
GATE_ROWS="$(/usr/bin/printf '%s\n' "$GO_QUERY_OUT" | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
# The query tool's stderr is captured with its rows (2>&1), never discarded. The row
# filter above keeps only lines shaped like a data row, so a notice never becomes a row;
# a failed read still dies above with the same message; and a rung-3 INDETERMINATE notice
# is repeated here, on this tool's stderr, naming the read (rung3_notice_lines).
/usr/bin/printf '%s\n' "$GO_QUERY_OUT" | rung3_notice_lines T_GO >&2
T_GO=""
if [[ -n "$GATE_ROWS" ]]; then
  # ts_iso is $1, NOT $2. FS is " | " (space-pipe-space) and the row's leading
  # "| " has no preceding space, so it is not a delimiter: $1 retains it and
  # reads "| <ts_iso>", $2 is the VERSION column. Strip the leading "| " and
  # take $1. (go_anchor_ts does both, and its identity terms read $3 to $6 under
  # this map.)
  T_GO="$(/usr/bin/printf '%s\n' "$GATE_ROWS" | go_anchor_ts)"
fi

# ─── Extract T_DEPLOY (latest deploy-skill OR deploy-harness event) ──────────

# The query tool's OWN exit status is checked, never the pipeline's: grep exits 1 on a
# legitimate zero-row release, while the query tool exits non-zero only when it could
# not read the log. A read that never happened is not a measured absence, and reporting
# it as "no deployment-status event" would state a fact nobody observed (exit 1 is the
# header's "log file missing").
DEPLOY_QUERY_OUT="$("$QUERY_TOOL" --release "$VERSION" --event-type deployment-status 2>&1)" \
  || die "query-pipeline-event.sh exited $? reading the deployment-status rows for $VERSION — the event log could not be read, so T_DEPLOY is not evaluated (run the query tool directly to see why)"
DEPLOY_ROWS="$(/usr/bin/printf '%s\n' "$DEPLOY_QUERY_OUT" | /usr/bin/grep -E '^\| [0-9]{4}-' || true)"
# This read's rung-3 INDETERMINATE notice, repeated as at the T_GO read above.
/usr/bin/printf '%s\n' "$DEPLOY_QUERY_OUT" | rung3_notice_lines T_DEPLOY >&2
T_DEPLOY=""
DEPLOY_TARGET_ROWS=""
if [[ -n "$DEPLOY_ROWS" ]]; then
  # Anchor-eligible rows only: deploy-skill|deploy-harness AND outcome=resolved.
  DEPLOY_TARGET_ROWS="$(echo "$DEPLOY_ROWS" | select_deploy_anchor_rows)"
  if [[ -n "$DEPLOY_TARGET_ROWS" ]]; then
    # ts_iso is $1 minus the leading "| " — see the T_GO note above.
    T_DEPLOY="$(echo "$DEPLOY_TARGET_ROWS" | /usr/bin/awk -F ' \\| ' '{ t = $1; sub(/^\| /, "", t); print t }' | /usr/bin/sort | /usr/bin/tail -1)"
  fi
fi

# ─── N/A determination + emission ────────────────────────────────────────────

if [[ -z "$T_GO" || -z "$T_DEPLOY" ]]; then
  # N/A — emit reason on stderr so the operator / caller can diagnose
  # Each N/A cause is a DIFFERENT FACT and is reported as such, in exactly one reason.
  # Collapsing any two would recreate, one layer up, an ambiguity already paid for:
  # "no deploy happened" vs "every deploy target failed" (#4215), and "every target
  # failed" vs "the only rows are of subtypes that never anchor" (#5553). The T_GO
  # causes live in t_go_na_reason and the T_DEPLOY causes in t_deploy_na_reason, each
  # accounting for every row it is handed.
  MISSING=""
  if [[ -z "$T_GO" ]]; then
    MISSING="${MISSING}$(/usr/bin/printf '%s\n' "$GATE_ROWS" | t_go_na_reason "$VERSION"); "
  fi
  if [[ -z "$T_DEPLOY" ]]; then
    MISSING="${MISSING}$(/usr/bin/printf '%s\n' "$DEPLOY_ROWS" | t_deploy_na_reason "$VERSION"); "
  fi
  echo "Cycle-Time: N/A (${MISSING%; })" >&2
  case "$OUTPUT_FORMAT" in
    seconds) echo "N/A" ;;
    iso) echo "T_GO=${T_GO:-N/A}; T_DEPLOY=${T_DEPLOY:-N/A}; delta=N/A" ;;
    human|*) echo "N/A" ;;
  esac
  exit 0
fi

# ─── Compute delta + format ──────────────────────────────────────────────────

DELTA_SECONDS="$(compute_delta_seconds "$T_GO" "$T_DEPLOY")" || die "ts_iso parse failure on ($T_GO, $T_DEPLOY)" 2

# Negative delta = pipeline-event-log integrity issue (T_DEPLOY before T_GO).
if [[ "$DELTA_SECONDS" -lt 0 ]]; then
  echo "WARNING: negative cycle-time ($DELTA_SECONDS s); T_DEPLOY=$T_DEPLOY before T_GO=$T_GO — pipeline-event-log integrity issue" >&2
fi

case "$OUTPUT_FORMAT" in
  seconds) echo "$DELTA_SECONDS" ;;
  iso) echo "T_GO=$T_GO; T_DEPLOY=$T_DEPLOY; delta=${DELTA_SECONDS}s" ;;
  human|*) format_human "$DELTA_SECONDS" ;;
esac
