#!/usr/bin/env bash
set -euo pipefail
# verify-release-plan.sh — Plan-driven verification executor for Stage 6/7.
#
# Parses a release plan's Verification Plan (+ Cross-Issue Acceptance Criteria)
# section, dispatches each declared check to a check-family handler, and emits
# the PR-body `### Verification Evidence` block the Engineering self-verification
# step (and Dev Testing re-run) consume — per-issue PASS/FAIL, preserving the
# Gate-6 verification-evidence grep contract.
#
# Design: a THIN dispatcher over a check-family registry. The script owns
# parse + dispatch + emit only. It DELEGATES the surfaces sibling cards own
# rather than re-implementing them:
#   - the sync + regression families shell the deploy source↔deployed check;
#   - the runtime-suite family emits through the pipeline-event test-run writer;
#   - the integration family reads the plan's Cross-Issue Acceptance Criteria
#     section verbatim (the release-planning-stage schema) and runs each entry's
#     declared method — it is the SOLE runner of those methods and the SOLE
#     emitter of their verdicts (the plan-review integration read is downstream
#     and read-only).
# No handler runs `eval` on a plan-derived string; each shells allowlisted
# primitives only.
#
# Usage:
#   ./verify-release-plan.sh [OPTIONS] <release_plan.md>
#
# Exit codes: 0 no check FAILed or ERRORed (PASS / SKIP / UNRUNNABLE only) ·
#             1 internal error · 2 bad plan target · 3 one or more checks FAIL/ERROR.

# ---------------------------------------------------------------------------
# Version metadata (the contract IS the schema, not the implementation).
# SCHEMA_VERSION is authored day-one so any change to the emitted evidence /
# verdict contract that downstream stages consume is a detectable bump, not a
# silent break. Bump SCHEMA_VERSION whenever the evidence-table shape, the
# verdict enum, or the check-record fields change.
# ---------------------------------------------------------------------------
readonly CLI_VERSION="0.3.0"
# 1 -> 2: the `fcm-delivery` check family enters the emitted stream from a THIRD
# record source, so every consumer now sees records it has never seen before.
# That is exactly what this constant exists to make detectable rather than silent.
# 2 -> 3: the `provenance-survival` check family enters the stream from a FOURTH
# record source (PROV-COVERAGE / PROV-PRESENCE / PROV-GRAMMAR / PROV-DELTA), for
# the same reason. No verdict value is added and no record field is renamed, so
# the Gate-6 verification-evidence grep contract is preserved across the bump.
# 3 -> 4: the verdict roll-up gains its DENOMINATOR. The `**Verdict roll-up:**`
# line now carries the per-issue row count (the counters themselves span every
# record in the stream; 4 -> 5 states that population), and the JSON `rollup`
# object gains `per_issue_rows` + `declared_deferred`. Without it, `0 ERROR` over
# a plan carrying NO per-issue table is byte-identical to `0 ERROR` over a plan
# whose rows all classified cleanly. The `fcm-delivery` coverage record
# additionally gains `prose_led=`.
# Both are ADDITIVE: no verdict value is added and no record field is renamed,
# so the Gate-6 verification-evidence grep contract survives this bump too.
# 3 -> 4 (SECOND CONTRIBUTOR TO THE SAME BUMP -- no further bump is owed):
# the per-issue record gains two PARSER-ASSIGNED families, `table-unindexable`
# and `method-cell-empty`, both dispatched as ERROR. A family VALUE is neither
# a new record field nor a new verdict value, and `parity-error` already
# established the parser-assigned-family idiom, so the emitted contract is
# unchanged. Recorded here so the addition is traceable rather than silent.
# The parser->dispatcher record DELIMITER also changed (see REC_FS below);
# that boundary is internal and the emitted `stream` remains TAB-separated,
# so it is likewise invisible to every downstream consumer.
# NO BUMP IS OWED for the FCM path-recognizer repair (`operations` added to the
# first-segment enum; an unrecognized fenced row now reported as `uninterpreted`
# rather than discarded). It adds one `source_form` VALUE,
# `fence-unrecognized-path`, and by the precedent recorded immediately above a
# value in an existing enum field is neither a new record field nor a new verdict
# value. What DOES change is the NUMBERS the coverage record carries on affected
# plans — `declared`, `interpreted` and `uninterpreted` were previously computed
# over a denominator that had silently lost rows. That is the counters becoming
# correct, not the contract changing: every field name, verdict value and record
# shape a consumer reads is untouched.
# 4 -> 5: the verdict roll-up gains a MEASUREMENT STATE. When a dispatch loop
# reads fewer records than the parser produced (the FD-0 completeness tripwire
# below), the `**Verdict roll-up:**` line carries the DEGRADED marker with "read K
# of N", and the run exits EXIT_INTERNAL rather than EXIT_CHECK_FAILED, because
# the verifier lost records and the plan did not fail. The JSON `rollup` object
# gains `stream_state` (`fetched` / `truncated`), `records_parsed` and
# `records_read` on every run, so a consumer can branch on the state before it
# reads a counter. By the precedent of 3 -> 4, an additive roll-up change is a
# bump. Riding it, with no further bump owed by the method-cell-empty precedent
# above: the observed reasons `stdin-reader:<verb>`, `device-operand:<path>` and
# `unmodelled-option:<opt>` on an existing ERROR, and the `stream-truncated`
# family on the completeness record -- VALUES in existing fields. Rows that used
# to vanish after a stdin-reading method cell now appear: that is the counters
# becoming correct, not the contract changing. A later change in the same release
# records itself here as a contributor to 4 -> 5 rather than bumping again.
# NO BUMP IS OWED for retiring the classifier's dormant first argument. It took a
# class value from a plan column and no caller ever supplied one, so removing the
# parameter, its arm and the parser-side value resolution moves no row and adds no
# record field, family value or verdict value: every emitted byte and every exit
# code is unchanged.
# NO BUMP IS OWED for resolving a runnable probe ahead of the prose keyword arms
# (classify_family step 1), or for reading a declared deferral outside every span
# led by an allowlisted verb. Rows move between EXISTING families and verdicts; no
# record field, family value or verdict value is added. A probe that prose used to
# displace now runs: the counters becoming correct, by the precedent above.
# NO BUMP IS OWED for grading a method that names several commands on its designated
# command and naming every other command as not run (METHOD LIMBS below). No record
# field, family value or verdict value is added: such a row takes the can't-run outcome
# the enum already carries (VERDICT_PARTIAL_SLOT) when its designated command passes,
# and the command list rides the existing observed field. Rows move between EXISTING
# verdicts -- a designated-command PASS that was never the whole method's verdict stops
# reading PASS, a comparator written for a later command stops grading the designated
# one, a bare tool name is no longer run as a command, and a comparator whose number
# carries markdown emphasis is read -- which is the counters becoming correct, by the
# precedent above.
# 4 -> 5 (A LATER CONTRIBUTOR TO THE SAME BUMP -- no further bump is owed): the verdict
# enum gains UNRUNNABLE, the can't-run-here slot of the outcome partition -- a command
# the row names that cannot run in this executor (a recognised tool outside
# RUNNABLE_VERBS, a native scope assertion with nothing to grade here), or a designated
# command that ran while another command the row names did not (VERDICT_PARTIAL_SLOT).
# A new VERDICT value is exactly what this constant exists to make detectable, and the
# release's one 4 -> 5 bump carries it. The roll-up gains an UNRUNNABLE counter and the
# JSON `rollup` object an `unrunnable` key, so no such row can fall out of the counts.
# Two family VALUES arrive with it, `scope` and `unrunnable`; by the precedent above a
# family value is not a contract change of its own. The exit rule is unchanged --
# non-zero only on FAIL or ERROR -- and the reason is recorded where the verdict enum
# is declared.
# NO BUMP IS OWED for reaching the deploy-check oracle by declaration only
# (classify_family: a row's designated command must BE `deploy.sh --check`), for
# grading a declared row that names another command by the partial rule, or for
# refusing a designated command that carries shell syntax. Rows move between EXISTING
# families and verdicts -- a row the oracle used to grade by a prose word now takes the
# outcome its own command earns -- and no record field, family value or verdict value
# is added: the counters becoming correct, by the precedent above.
# 4 -> 5 (A LATER CONTRIBUTOR TO THE SAME BUMP -- no further bump is owed): the verdict
# roll-up states the population its counters are taken over, and keeps what the run did
# not grade apart from what it could not evaluate. The counters have always spanned
# EVERY record in the stream -- per-issue rows, cross-issue criteria and the always-on
# families -- and the line now says so; it also names who decided each SKIP
# (declared-deferred / no command in method / other). The JSON `rollup` object gains
# `records`, `cross_issue_records`, `always_on_records`, `no_command` and `skip_other`,
# and `declared_deferred` counts the observed reason rather than the family. Riding it,
# with no further bump owed by the precedents above: a row no family arm claims takes the
# per-issue family and its handler's verdict instead of an unclassified ERROR (a family
# VALUE retired; no field added), and the observed reasons `no-operand:<verb>`,
# `matcher-exit-1` and `no-comparator:<verb>` ride existing ERROR records -- VALUES in
# existing fields. The markdown block renders a record with no issue value under a
# `(plan)` header: a presenter change that moves no stream byte and no JSON value.
# NO BUMP IS OWED for the CIAC authoring lint (--ciac-lint): a separate mode that runs no
# command and emits no Verification Evidence record, so every field, value and exit of a
# normal run is unchanged. The CLI version moves instead, because the mode is new surface.
# NO BUMP IS OWED for reading an unterminated quote in a designated command as ERROR rather
# than UNRUNNABLE, or for reading a span no backtick closes as prose: rows move between
# EXISTING verdicts, and the reason `unterminated-quote:<q>` rides an existing ERROR record --
# a VALUE in an existing field, by the precedents above.
readonly SCHEMA_VERSION="5"

# ---------------------------------------------------------------------------
# REC_FS -- the parser->dispatcher record field separator. ASCII 0x1F (UNIT
# SEPARATOR), the byte whose defined meaning is exactly "separator between
# fields within a record".
#
# DO NOT REVERT THIS TO A TAB, and the reason is not style. Tab is an IFS
# *whitespace* character by POSIX definition, so under `IFS=$'\t' read`
# consecutive tabs COLLAPSE and a leading empty field is stripped. Both states
# are reachable here: `parse_verification_plan` emits an empty `ac` whenever a
# table header carries no `AC` column -- 24 of 42 indexed tables in the plan
# corpus -- and `parse_ciac` writes a literal empty field 2 on its parity-error
# record. Under a tab the record then SHIFTS one position left and the consumer
# reads the *Expected result* cell as the Method: the row is graded on the
# wrong cell while every tally stays arithmetically correct, which is why the
# suite carried 146 green assertions over it. There is no shell switch to
# disable the collapse -- the delimiter itself is the only fix, and populating
# the field instead leaves the format positionally ambiguous for the next
# nullable field.
#
# Verified absent from the corpus this parser reads: 0 occurrences of 0x1F in
# 6,321,036 bytes across 187 plan files (sensitivity arm LF = 47,654).
#
# SCOPE -- parser -> dispatcher ONLY. The emitted `stream` stays TAB-separated
# because `awk -F'\t'` does NOT collapse empty fields and every downstream
# consumer reads it with awk. `parse_fcm_declarations` is deliberately NOT
# converted: all three of its emit sites guard field 2 non-empty (an unreadable
# intent is `next`-ed at the table site and becomes the literal `unknown` at
# the fence site), so that stream carries none of this defect, and six
# `-F'\t'` readers plus a same-path reconciliation would have to move for no
# measured gain.
# ---------------------------------------------------------------------------
readonly REC_FS=$'\037'

# ---------------------------------------------------------------------------
# FD-0 -- nothing this executor spawns may read the record stream it iterates.
#
# Both dispatch loops in main() iterate a here-string on fd 0
# (`done <<< "$records"`), and a child inherits fd 0 unless something rebinds
# it. A plan-authored method is such a child: `grep -c -F "X"` with no file
# operand reads stdin -- the loop's own remaining records -- so the loop's next
# `read` hits EOF and every row after that cell vanishes with no record, while
# the roll-up still reports the parser's full denominator. The cell itself is
# graded on the records it swallowed. Measured over the 215-plan corpus at the
# Stage-4 pin: 45 rows lost across 7 plans (39 per-issue, 6 cross-issue),
# triggered by 9 method cells, 2 of which reported PASS on the swallowed records.
# A stdin-reading child outside the verb route does the same: a deploy --check
# stub that read its stdin left 1 of 4 rows AND a clean exit 0.
#
# THE RULE, STATED ONCE. A loop that iterates a record stream on fd 0 runs its
# BODY with fd 0 on the null device:
#     while IFS=... read -r ...; do {
#       ...
#     } </dev/null; done <<< "$records"
# `read` is then the only reader of the stream, and every child the body spawns
# -- a dispatched verb, the deploy --check child, the event writer, and any child
# a later family adds -- inherits the null device: never the queue, and never the
# caller's own stdin (a terminal on which a reader would block). Keep `do {` and
# `} </dev/null; done` on both loops, and keep each loop's read counter as the
# FIRST statement of its body.
#
# WHY THE BODY, AND NOT THE VERB OR A DEDICATED DESCRIPTOR. Both were measured
# and REJECTED:
#   - `</dev/null` on the verb inside eval_free_run closes one route only; the
#     deploy --check child above is outside it.
#   - moving the stream to its own descriptor (`read -u 3` / `3<<<`) frees fd 0
#     but hands fd 3 to every child: a method reading /dev/fd/3 dropped 3 of 6
#     rows. Closing it at the dispatch call (`3<&-` on a function) does not help
#     -- bash parks the closed descriptor on a saved copy (fd 11 on bash 3.2)
#     that exec'd children still inherit.
# Rebinding fd 0 for the body leaves no inheritable copy of the stream, because
# bash keeps its saved copy of fd 0 close-on-exec. That is a property of the bash
# and not of this file, so it is MEASURED rather than assumed per version: the
# suite's reachability arm runs this loop form on the bash that runs the suite
# (on CI, the runner's) and fails if an exec'd child in the body sees any
# descriptor its baseline does not.
#
# SCOPE -- every loop in this file whose fd 0 is redirected while its body runs,
# whatever the form: here-string, here-document, or file. The two dispatch loops
# take the rule, and so do the five loops that read a method's split spans or its
# commands (extract_command, method_limbs, limbs_are_multi, grade_limbs and
# command_list), the five that read a scope assertion's pathspecs or the
# release diff it grades (scope_path_selected, scope_pathspec_selects, and
# handle_scope's three), and the CIAC authoring lint's two (ciac_lint's declared ids
# and its parsed records): their bodies spawn no child that reads fd 0 today, and the
# body form keeps any child they spawn, now or later, off it. The other five are
# EXEMPT BY MEASUREMENT, because nothing in their bodies can read fd 0:
#   - count_from_output's two here-string loops: builtins only, no child at all.
#   - fcm_match_adds' file-fed loop: builtins only.
#   - handle_fcm_delivery's here-string loop: fixed commands whose input is bound
#     explicitly -- grep on `<<<`, awk on a file operand, sed on a pipe.
#   - emit_md's here-string loop: awk on a file operand or on a pipe.
# A new loop -- or a new child in an exempt one -- that spawns a child with
# unbound input takes the body form.
#
# TWO FURTHER GUARDS MAKE THE RULE HOLD WHERE THE REDIRECT DOES NOT REACH.
#   - reads_stdin_cmd refuses a reader before it runs whenever its input would be
#     stdin, and whenever its closed model cannot show that it would not (an
#     option it does not model; a path under /dev/ or /proc/). The cell is then
#     never graded on the null device either: ERROR, with the refusal named --
#     stdin-reader:<verb>, device-operand:<path> or unmodelled-option:<opt> --
#     and rendered as a refusal rather than as a matcher outcome.
#   - each dispatch loop counts the records it read, and main() emits a
#     stream-truncated ERROR when that count falls short of the parser's. The
#     roll-up then carries the DEGRADED marker with "read K of N", and the run
#     exits EXIT_INTERNAL (1) rather than EXIT_CHECK_FAILED (3): the verifier
#     lost records, the plan did not fail. THE TRIPWIRE'S BOUNDARY, declared: it
#     detects a SHORTENED stream, not a CORRUPTED one. A reader that consumes
#     part of a record -- a byte count, say -- leaves the read count unchanged
#     while the next record is misread, and nothing here catches that.
# ---------------------------------------------------------------------------

# ---------------------------------------------------------------------------
# Pinned PATH for tool discipline (per bypass-mode-readiness.md posture).
# ---------------------------------------------------------------------------
PATH="/usr/bin:/bin:/usr/local/bin:/opt/homebrew/bin"

# ---------------------------------------------------------------------------
# Exit codes
# ---------------------------------------------------------------------------
readonly EXIT_OK=0
readonly EXIT_INTERNAL=1
readonly EXIT_BAD_TARGET=2
readonly EXIT_CHECK_FAILED=3

# ---------------------------------------------------------------------------
# Verdict enum -- FIVE values, one partition, and every reader keys on the value:
#   PASS        the check ran, and what it asserts holds.
#   FAIL        the check ran, and what it asserts does not hold.
#   SKIP        not this runner's job, or nothing to run: the plan declared the row
#               deferred, or its method names no command.
#   UNRUNNABLE  can't run here: the row was read, and a command it names cannot run
#               in this executor -- a recognised tool outside RUNNABLE_VERBS, a
#               designated command carrying a shell operator outside quotes, or a native
#               scope assertion with nothing to grade here -- or its designated command ran
#               while another command it names did not.
#   ERROR       could not read or evaluate: input this parser cannot make sense of -- an
#               unreadable row, or a designated command with an unterminated quote -- or
#               a command that ran and produced no readable result.
# These are this executor's own values, not the Stage-8 per-criterion enum. Stage 9 reads
# each emitted value into that enum through the one reading table in QA Checkpoint 3.5
# (release-process.md), which no other reader restates; the runtime family additionally
# maps the test-run suite-* subtypes onto the values above.
#
# NON-RETROACTIVITY. A row this executor declines by design -- a SKIP, an UNRUNNABLE, and
# any later "cannot run here" value -- stays OUTSIDE the exit-failing set in main() step 4,
# whatever it is renamed to: renaming declined rows must not turn a plan's exit 0 into 3.
# A family that newly EXECUTES a row it used to decline grades PASS or FAIL only where it
# can establish the evaluation context the method presumes, and otherwise emits the
# cannot-run outcome. A decline is weighed at Stage 9, where QA Checkpoint 3.5 reads an
# undeclared one as NOT MET, not at this exit. The suite's group G13 pins it, with a seeded
# failure for each declined value: G13 M1 adds SKIP to the exit predicate, G13 M3 UNRUNNABLE.
#
# WHY UNRUNNABLE IS A VALUE OF ITS OWN. A method needing a tool outside the verb set
# used to read SKIP -- the verdict a plan uses to declare a row another runner's job --
# so a plan whose most rigorous criterion never ran read like one that deferred a
# judgement call, and every reader that keys on the verdict (the exit predicate, the
# Stage-9 reading, the roll-up) could not tell them apart. It is not SKIP, because the
# plan declared nothing; it is not ERROR, because the input WAS read.
#
# WHY IT DOES NOT FAIL THE RUN. main()'s exit predicate names FAIL and ERROR only, and
# UNRUNNABLE stays outside it ON PURPOSE: exit 0 never meant "every check executed",
# and a failing token turns historical plans red by relabel alone -- 8 plans that exit
# 0 would exit 3, measured when this value was introduced. Its visibility is its own
# counter in both roll-ups and a stderr note naming how many rows did not execute; each
# consuming gate decides what it costs there.
# ---------------------------------------------------------------------------
readonly VERDICT_PASS="PASS"
readonly VERDICT_FAIL="FAIL"
readonly VERDICT_SKIP="SKIP"
readonly VERDICT_UNRUNNABLE="UNRUNNABLE"
readonly VERDICT_ERROR="ERROR"

# VERDICT_PARTIAL_SLOT -- the verdict a row takes when its method names a command this
# executor did not run and the command that did run passed: the can't-run-here slot of
# the outcome partition, never PASS and never a value of its own. It is bound to
# UNRUNNABLE, the value that slot carries in this file; a change that gives the slot
# another value re-binds this one line and touches nothing else. KEPT ON ONE LINE ON
# PURPOSE: the suite derives the slot's value from this line by one anchored pattern,
# so its arms follow a re-binding rather than pinning today's value.
readonly VERDICT_PARTIAL_SLOT="$VERDICT_UNRUNNABLE"

# ---------------------------------------------------------------------------
# PER_ISSUE_ROWS — the roll-up denominator: how many rows
# parse_verification_plan actually indexed. Set by main() at the parser
# boundary and read by emit_md / emit_json. Deliberately NOT `local`: the
# emitters run on the right-hand side of a pipeline, which inherits globals.
# ---------------------------------------------------------------------------
PER_ISSUE_ROWS=0

# ---------------------------------------------------------------------------
# STREAM_DEGRADED / STREAM_PARSED / STREAM_READ — the FD-0 completeness
# tripwire's MEASUREMENT STATE (see FD-0). Set by main() once both dispatch loops
# have run, and read by emit_md / emit_json and by main()'s exit, globals for the
# same reason PER_ISSUE_ROWS is. STREAM_DEGRADED stays empty while every loop
# read every record the parser produced; otherwise it carries one "read K of N
# parsed ... records" clause per loop that fell short, and the run is DEGRADED.
# ---------------------------------------------------------------------------
STREAM_DEGRADED=""
STREAM_PARSED=0
STREAM_READ=0

# ---------------------------------------------------------------------------
# Argument-parsing state
# ---------------------------------------------------------------------------
ARG_FORMAT=""
ARG_ROOT=""
ARG_PLAN=""
ARG_NO_COLOR=0
ARG_EMIT_EVENTS=0   # opt-in: actually write test-run events via the event writer
ARG_FCM_MERGE_BASE=""   # explicit base ref for the fcm-delivery diff range
ARG_FCM_HEAD=""         # explicit head ref for the fcm-delivery diff range
ARG_FCM_DIFF_FILE=""    # TEST-ONLY determinism seam; refused against a real plan
ARG_STAGE4_COMMENT=""   # provenance DELTA limb evidence; absent -> NAMED SKIP, never PASS
ARG_CIAC_LINT=0         # Stage-4 authoring mode: lint the CIAC section, run nothing

# Scratch array populated by tokenize_cmd (quote-aware command splitter).
declare -a TOKENS=()

# ---------------------------------------------------------------------------
# Sibling-tool locations (resolved after root resolution). These are the only
# external surfaces the handlers shell; they are DELEGATIONS, not re-implements.
# ---------------------------------------------------------------------------
DEPLOY_CHECK=""          # core/deploy/deploy.sh --check  (sync + regression)
EVENT_WRITER=""          # release/tools/append-pipeline-event.sh  (runtime-suite)
DEPLOY_CHECK_CACHE=""    # per-run memo file for the deploy --check exit code
SCOPE_DIFF_CACHE=""      # per-run memo file for the release diff the scope family grades

# ---------------------------------------------------------------------------
# Color helpers (match the release/tools convention).
# ---------------------------------------------------------------------------
use_color() {
  if [ "$ARG_NO_COLOR" = "1" ]; then return 1; fi
  [ -t 1 ] || return 1
  return 0
}
c_bold()  { if use_color; then printf '\033[1m'; fi; }
c_dim()   { if use_color; then printf '\033[2m'; fi; }
c_red()   { if use_color; then printf '\033[31m'; fi; }
c_green() { if use_color; then printf '\033[32m'; fi; }
c_reset() { if use_color; then printf '\033[0m'; fi; }

err() { printf '%serror:%s %s\n' "$(c_red)" "$(c_reset)" "$*" >&2; }
note() { printf 'note: %s\n' "$*" >&2; }

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------
usage() {
  cat <<EOF
verify-release-plan.sh — Plan-driven verification executor (Stage 6/7)

USAGE
  verify-release-plan.sh [OPTIONS] <release_plan.md>

OPTIONS
  --format=FORMAT   Output presenter: md | json | table
                    Default: md (the PR-body Verification Evidence shape;
                    rows are grouped under their issue, a row that carries
                    no issue value under (plan), so every row the roll-up
                    counts appears in a table)
  --root=PATH       Repo root for resolving relative check paths + sibling tools
                    Default: \$(git rev-parse --show-toplevel)
  --emit-events     Actually write test-run events via the pipeline-event
                    writer for runtime-suite checks (default: describe only,
                    no event log write)
  --merge-base REF  Base ref for the release diff range, which the fcm-delivery
                    and scope families both read
                    Default: \$(git merge-base origin/main HEAD)
  --head REF        Head ref for the release diff range (default: HEAD)
  --fcm-diff-file P TEST-ONLY determinism seam: read the delivered set, for the
                    fcm-delivery and scope families, from a <status>TAB<path>
                    file instead of git. REFUSED (ERROR) when the plan target
                    lives under release/releases/plans/ — a real release must
                    never be graded against an authored diff set.
  --stage4-comment P   Path to a file containing the Stage-4 planning sub-task
                    comment, for the provenance DELTA limb. Absent → the delta
                    limb emits a NAMED SKIP; it never emits PASS.
  --ciac-lint       Stage-4 authoring lint of the Cross-Issue Acceptance Criteria
                    (gate criterion G4-06); runs nothing (see CIAC AUTHORING LINT)
  --no-color        Disable ANSI color in table output
  -h, --help        Show this help and exit
  --version         Show CLI version + schema version and exit

CHECK FAMILIES (dispatched from the Verification method cell alone: a declared deferral, then a runnable probe or a scope assertion, then an integration keyword, then a declared deploy check, else method keyword, else the per-issue handler)
  per-issue      file existence + content assertions  (any runnable probe:
                 -- and the residual: a row no other   ${RUNNABLE_VERBS};
                 family claims is inspected here       a row naming no
                                                       command it runs is
                                                       a named SKIP, and
                                                       only a backticked
                                                       span is a command)
  scope          a confinement assertion over the     (git diff --name-only
                 RELEASE diff — every change the       origin/main...HEAD --
                 release makes, not one card's         <pathspec>... and one
                 commits                               comparator. The SAME
                                                       fixed git call
                                                       fcm-delivery makes; the
                                                       pathspecs are DATA,
                                                       matched in-process, and
                                                       no authored byte reaches
                                                       git)
  unrunnable     a recognised tool command no other   (named, never run: the
                 family claims                         tool is outside the verb
                                                       set above)
  integration    Cross-Issue Acceptance Criteria      (reads the plan's CIAC
                 section; runs each entry's declared method — SOLE runner)
  regression     unchanged-files-intact               (deploy --check byte-diff;
                                                       only a row whose command
                                                       IS deploy.sh --check and
                                                       that names a regression word)
  sync           source <-> deployed                  (deploy --check; only a row
                                                       whose command IS
                                                       deploy.sh --check)
  runtime-suite  behavioral/runtime dispatch          (test-run event via
                 append-pipeline-event.sh)
  fcm-delivery   declared File Change Matrix ADDs     (git diff --name-status;
                 vs the merged diff                    ALWAYS-ON for a plan under
                                                       release/releases/plans/ —
                                                       not plan-declared, so it
                                                       cannot be omitted by not
                                                       being asked for)
  provenance-survival
                 the domain_practice label survived   (absolute PRESENCE + closed
                 Commit-0 transcription                source: GRAMMAR read from
                                                       the plan alone; DELTA vs
                                                       the Stage-4 comment when
                                                       --stage4-comment is given.
                                                       ALSO ALWAYS-ON, same
                                                       rationale as fcm-delivery.
                                                       The absolute limb is what
                                                       makes it non-vacuous when
                                                       BOTH surfaces are empty)

MULTI-COMMAND METHODS
  A method naming two or more commands is graded on its designated command:
  its first allowlisted command that carries an argument, read against the
  comparator that follows that command (at least N, at most N, exactly N,
  expect N; a null is expect 0). Every other command it names is reported as
  did not run, with its reason, and a row with a command that did not run
  never reads PASS: it reads UNRUNNABLE. A bare tool name (grep alone) is
  prose, never a command.

VERDICTS
  PASS        the check ran, and what it asserts holds
  FAIL        the check ran, and what it asserts does not hold
  SKIP        not this runner's job (a declared deferral), or no command to
              run: a named read, a judge-rubric, or prose that merely opens
              with a verb, whether or not a family claimed the row; its
              criterion is graded where the method says
  UNRUNNABLE  can't run here: a command the method names is a tool outside
              the verb set, the designated command carries shell syntax (a
              pipe, a list, a redirect, a substitution), a scope assertion has
              nothing to grade here, or the designated command ran and another
              command did not. Never executed, never a pass, and it does not
              fail the run; the tool named is a tool the method invokes, never
              a label or a file
  ERROR       could not read the row, or tried to evaluate it and could not:
              an unreadable table row, an empty method cell, a command with
              an unterminated quote, a probe whose input could not be read, a
              command naming no operand, or a command with no comparator
              whose exit status is not its claim

READER SEMANTICS (one table, per verb, read by every reader of a result)
  verb  exit 1      operand         count read as          no comparator
  grep  a zero      a pattern       -c: the count field;   exit 0 is PASS
                                    else matching lines
  test  a zero      an expression   (it prints nothing)    exit 0 is PASS
  ls    unreadable  a path          entries (lines)        PASS only as an
                                                           existence check
  head  unreadable  a file          lines                  not graded
  wc    unreadable  a file          its first field        not graded
  cat   unreadable  a file          lines                  not graded
  An unreadable exit 1 reads ERROR matcher-exit-1. A command naming no
  operand -- grep with no pattern, test with no expression or a primary
  with no operand, ls with no path -- is not run: ERROR no-operand:<verb>
  (head, wc and cat with no file read stdin-reader:<verb> first). With no
  comparator, a result the table does not grade -- cat, head, wc, or ls
  listing a directory -- reads ERROR no-comparator:<verb>.

EXIT CODES
  0  no check FAILed or ERRORed (PASS, SKIP and UNRUNNABLE only; every
     UNRUNNABLE row is counted in the roll-up and noted on stderr)
  1  internal error — including a DEGRADED verdict stream: a dispatch loop
     read fewer records than the parser produced, and the roll-up says so
  2  bad plan target (path missing / not a regular file)
  3  one or more checks FAIL or ERROR (with --ciac-lint: one or more CIACs
     flagged)

CIAC AUTHORING LINT (--ciac-lint) - Stage 4, gate criterion G4-06
  Reads the plan's Cross-Issue Acceptance Criteria as grading will -- the same
  parser, the same span splitter, and the readers the cross-issue handler uses
  -- and stops before execution: it runs no command, reads no deploy check,
  writes no event and emits no Verification Evidence record. It is read at
  three points: by the hub at Gate 1, at Stage 6 entry on the committed plan,
  and at Stage 9 Phase A3.6 against the final head. It prints one line per
  CIAC, CIAC-LINT <id> CLEAN|DECLARED|FLAG <flag>, then CIAC-LINT-SET (the
  ids the plan declares) and CIAC-LINT-SUMMARY, and exits 0 when no CIAC is
  flagged, else 3.
  CLEAN     graded as written: one command the executor runs, naming its
            input, with a comparator it reads, or none where the command's
            exit status is the claim (grep, test, an ls naming files); or a
            scope assertion
  DECLARED  written "declared, verification deferred to <evidence>", naming
            a surface: a repository path, a suite arm label, or a criterion
            for each spanned issue (#N AC-k, design #N AC-k or INT-k, plan #N
            AC-k); the Stage 9 operator grades it from that evidence
  FLAG      no permitted party grades it as written. The flag is the first
            the grading path meets, with its remedy:
    ciac-unparsed              the grading parser never reads it: write the id
                               bold, **CIAC-N (...):**, on one line
    parity-error               the table row lacks its header's field count:
                               escape a literal pipe inside the cell
    no-method                  the entry's line carries no method: keep
                               *Method:* on the entry's own line
    method-marker-absent       add a *Method:* marker
    method-clause-displaced    a "method" word earlier on the line opens the
                               clause: reword it
    declared-without-evidence  the declaration names no evidence surface
    evidence-misses-spanned-issue:<#N>
                               a per-issue criterion is named for some spanned
                               issues only: name one for each, or a path or an
                               arm label, which cover the release
    multi-limb                 the method names more than one command and only
                               one runs: keep one; a control goes after *Graded*
    no-runnable-command        nothing the executor runs (a span no backtick
                               closes is prose): write one command in
                               backticks, or declare it
    bare-verb:<verb>           a tool named with no argument is prose
    unbackticked-command       the executor would run the clause's own words
                               as a command: put the command in backticks
    not-runnable:<tool>        a tool outside grep, test, ls, head, wc and cat:
                               probe the label of the suite arm that asserts
                               it, or declare it
    scope-pathspec-placeholder:<p>
                               a placeholder names no path: name the path
    shell-operator:<op>        shell syntax outside quotes: name one command
    unterminated-quote:<q>     the command cannot be split into words: close
                               the quote
    stdin-reader:<verb>        the command names no input file inside its
                               backticks
    device-operand:<input>     the input is a device, not a repository file
    unmodelled-option:<opt>    use an option the executor models
    no-operand:<verb>          grep needs a pattern, test an expression, ls a
                               path
    no-threshold:<verb>        a count with no comparator the grader reads, so
                               its exit status is graded and a zero reads FAIL:
                               write expect N, at least N or at most N
    no-comparator:<verb>       this command's exit status is not its claim:
                               state a comparator
    multi-comparator           comparators that disagree: state one

EXAMPLES
  # Emit the Verification Evidence block for a release plan (markdown to stdout)
  verify-release-plan.sh release/releases/plans/v3.65_RELEASE_PLAN.md

  # JSON verdict array for CI consumption
  verify-release-plan.sh --format=json release/releases/plans/v3.65_RELEASE_PLAN.md

DOCS
  Output shape: the PR-body Verification Evidence section consumed by the
  Engineering self-verification step (Stage 6) and re-run at Dev Testing
  (Stage 7). See release/references/pipeline/stage-06-engineering.md.
EOF
}

# ---------------------------------------------------------------------------
# Argument parser
# ---------------------------------------------------------------------------
parse_args() {
  while [ $# -gt 0 ]; do
    case "$1" in
      -h|--help)      usage; exit "$EXIT_OK" ;;
      --version)      printf 'verify-release-plan %s (schema v%s)\n' "$CLI_VERSION" "$SCHEMA_VERSION"; exit "$EXIT_OK" ;;
      --format=*)     ARG_FORMAT="${1#--format=}" ;;
      --format)       shift; ARG_FORMAT="${1:-}" ;;
      --root=*)       ARG_ROOT="${1#--root=}" ;;
      --root)         shift; ARG_ROOT="${1:-}" ;;
      --emit-events)  ARG_EMIT_EVENTS=1 ;;
      --merge-base=*) ARG_FCM_MERGE_BASE="${1#--merge-base=}" ;;
      --merge-base)   shift; ARG_FCM_MERGE_BASE="${1:-}" ;;
      --head=*)       ARG_FCM_HEAD="${1#--head=}" ;;
      --head)         shift; ARG_FCM_HEAD="${1:-}" ;;
      --fcm-diff-file=*) ARG_FCM_DIFF_FILE="${1#--fcm-diff-file=}" ;;
      --fcm-diff-file)   shift; ARG_FCM_DIFF_FILE="${1:-}" ;;
      --stage4-comment=*) ARG_STAGE4_COMMENT="${1#--stage4-comment=}" ;;
      --stage4-comment)   shift; ARG_STAGE4_COMMENT="${1:-}" ;;
      --no-color)     ARG_NO_COLOR=1 ;;
      --ciac-lint)    ARG_CIAC_LINT=1 ;;
      --)             shift; break ;;
      -*)             err "unknown option: $1"; usage >&2; exit "$EXIT_INTERNAL" ;;
      *)              if [ -z "$ARG_PLAN" ]; then ARG_PLAN="$1"; else err "unexpected extra argument: $1"; exit "$EXIT_INTERNAL"; fi ;;
    esac
    shift
  done
  # Any residual positionals after `--`.
  while [ $# -gt 0 ]; do
    if [ -z "$ARG_PLAN" ]; then ARG_PLAN="$1"; else err "unexpected extra argument: $1"; exit "$EXIT_INTERNAL"; fi
    shift
  done

  if [ -z "$ARG_FORMAT" ]; then ARG_FORMAT="md"; fi
  case "$ARG_FORMAT" in
    md|json|table) : ;;
    *) err "invalid --format value: '$ARG_FORMAT' (must be md | json | table)"; exit "$EXIT_INTERNAL" ;;
  esac
  if [ -z "$ARG_PLAN" ]; then err "missing required <release_plan.md> argument"; usage >&2; exit "$EXIT_INTERNAL"; fi
}

# ---------------------------------------------------------------------------
# Repo-root resolution (mirrors the release/tools convention).
# ---------------------------------------------------------------------------
resolve_root() {
  if [ -n "$ARG_ROOT" ]; then
    if [ ! -d "$ARG_ROOT" ]; then err "--root path is not a directory: $ARG_ROOT"; exit "$EXIT_INTERNAL"; fi
    REPO_ROOT="$(cd "$ARG_ROOT" && pwd -P)"
    return
  fi
  if command -v git >/dev/null 2>&1; then
    local git_root
    if git_root=$(git rev-parse --show-toplevel 2>/dev/null); then REPO_ROOT="$git_root"; return; fi
  fi
  REPO_ROOT="$(pwd -P)"
}

# ---------------------------------------------------------------------------
# Sibling-tool resolution. Absent tools degrade the dependent family to a
# well-formed ERROR verdict (fail loud), never a fabricated PASS.
# ---------------------------------------------------------------------------
resolve_sibling_tools() {
  DEPLOY_CHECK="$REPO_ROOT/core/deploy/deploy.sh"
  EVENT_WRITER="$REPO_ROOT/release/tools/append-pipeline-event.sh"
}

# ---------------------------------------------------------------------------
# Plan-target resolution → absolute path.
# ---------------------------------------------------------------------------
resolve_plan() {
  local input="$ARG_PLAN" abs
  if [ -e "$REPO_ROOT/$input" ]; then abs="$REPO_ROOT/$input"
  elif [ -e "$input" ]; then abs="$(cd "$(dirname "$input")" && pwd -P)/$(basename "$input")"
  else err "plan target does not exist: $input"; exit "$EXIT_BAD_TARGET"; fi
  if [ ! -f "$abs" ]; then err "plan target is not a regular file: $abs"; exit "$EXIT_BAD_TARGET"; fi
  PLAN_ABS="$abs"
}

# ===========================================================================
# Component 1 — parse_verification_plan()
#
# Locates the plan's `## Verification Plan` H2, then extracts each per-issue
# markdown table. Two table shapes are tolerated (m-5):
#   (a) canonical Issue-keyed table: an `Issue` column groups rows per issue;
#   (b) enriched AC-keyed per-issue-subsection form: no `Issue` column, so the
#       enclosing `#N` subsection header (a bold `**#N — …**` heading) supplies
#       the per-issue grouping, keeping the emitted evidence well-formed.
# Each parsed row becomes a check record: issue | ac | family | method | expected.
# Records are emitted as TAB-separated lines on stdout (one per check).
# ===========================================================================

# Extract the body of a section whose heading STARTS WITH the given text. The
# section runs from its heading to the next heading of the same-or-higher level
# (an H2 section ends at the next H2; an H3 section ends at the next H2 or H3).
# Prefix-matching lets a heading carry a parenthetical suffix
# (e.g. "Cross-Issue Acceptance Criteria (dog-food of …)") and still match.
_extract_section() {
  # $1 = plan file, $2 = section-heading prefix (matched after the #… marker)
  local file="$1" heading="$2"
  awk -v want="$heading" '
    function hlevel(s,   k) { k = 0; while (substr(s, k+1, 1) == "#") k++; return k }
    BEGIN { insec = 0; want_level = 0; want_len = length(want) }
    /^#+ / {
      line = $0
      lvl = hlevel(line)
      sub(/^#+[ ]+/, "", line)          # strip the "#… " marker
      if (insec == 1 && lvl <= want_level) { insec = 0 }   # next same/higher heading ends it
      if (insec == 0 && substr(line, 1, want_len) == want) { insec = 1; want_level = lvl; next }
    }
    insec == 1 { print }
  ' "$file"
}

# Classify a check record's family from its Verification method cell ALONE.
# $1 = method string.
#
# THE METHOD CELL IS THE ONLY INPUT, AND THAT IS THE CONTRACT. A row this executor
# is not the runner for is declared IN this cell, in the one declared-deferred form
# step 0 reads — `[DEFERRED — <reason>]`, or "declared, verification deferred to
# <runner>" — and nowhere else. `suite-skip` and `suite-fail` are runtime-suite
# SUBTYPE tokens, for a row that is actually about a suite run; they are not a
# general declaration, because an uppercase FAIL anywhere in such a method routes
# the subtype to FAIL. A plan may carry a Predicate class column as a reader
# annotation; it is not read here. A class hint was once accepted as a first
# argument and never supplied by any caller, so that path was removed rather than
# wired: wired ahead of the keyword arms it sent rows to an oracle that tested none
# of their claims, and it would have let a class cell displace a runnable probe.
#
# WITHIN THE CELL, A RUNNABLE PROBE OUTRANKS PROSE. Step 1 hands a row whose
# designated command is a probe this executor runs to the handler that runs it,
# before any keyword is read; and step 0 reads a declared deferral outside every span
# led by an allowlisted verb, because inside one a phrase is that command's search
# pattern, not a declaration. A row naming both a runnable probe and the
# `deploy.sh --check` span is graded by the probe: the deploy check does not run.
# The deploy-check oracle itself is reached by declaration only: a row goes to it
# only when its designated command IS the backticked invocation.
# {{ADR:a-rows-grading-route-is-declared-in-its-method-cell}} records the first as its
# Decision 6 and the second as its Decision 7.
classify_family() {
  local raw_method="$1" method prose probe cmd
  method="$(printf '%s' "$raw_method" | tr '[:upper:]' '[:lower:]')"

  # 0) Declared-deferred method → the honesty contract routes it to a family-
  #    agnostic SKIP (never a fabricated PASS, never a false ERROR). A method is
  #    deferred when it is bracket-tagged [DEFERRED …] or says "verification
  #    deferred to #<executor>". This precedes family classification because a
  #    deferred check is a SKIP regardless of which family it would run under.
  #    It is read OUTSIDE every span led by an allowlisted verb
  #    (method_outside_verb_spans): inside one, a phrase is that command's own
  #    argument -- its search pattern -- never a declaration. A declaration
  #    outside those spans still wins. The prose line is KEPT ON ONE LINE ON
  #    PURPOSE: the suite's mutation arm G15 M2 reverts it by one substitution.
  prose="$(method_outside_verb_spans "$raw_method" | tr '[:upper:]' '[:lower:]')"
  case "$prose" in
    *"[deferred"*|*declared,\ verification\ deferred*|*verification\ deferred*|*deferred\ to\ #*)
      echo "deferred"; return ;;
  esac

  # 1) A RUNNABLE PROBE IS EXECUTED, NEVER ROUTED BY PROSE.
  #
  # When the command this executor would run for the row -- extract_command's pick,
  # a closed backtick span -- has the shape of a probe it runs (is_runnable_probe:
  # an allowlisted verb, at least one argument, no shell operator outside quotes),
  # the row goes to the per-issue handler ahead of every keyword arm below. Keywords
  # used to decide first, so the word "unchanged" beside a `grep -c` sent the row to
  # the deploy --check oracle, which tests none of its claim and PASSes on a clean
  # workspace: a probe that would FAIL was graded by something else. Measured when
  # this step was written: the keyword arms sent 7 corpus rows carrying such a probe
  # elsewhere -- 2 to regression and 1 to sync, where the probe never ran, 1 to an
  # unclassified ERROR, and 3 relabelled integration with the same probe.
  #
  # THE PRECEDENCE, STATED. A row that names both a runnable probe and the
  # `deploy.sh --check` span is graded by the probe; the deploy check does not run
  # for it, and the handler names it as a command that did not run (outside the verb
  # set), so the row never reads PASS (METHOD LIMBS). A command this executor does
  # not run -- a tool, a pipeline, a bare verb -- keeps the keyword route. The step's
  # test line is KEPT ON ONE LINE ON PURPOSE: the suite's mutation arms G15 M1 and
  # G10 R-M2b remove it by one anchored substitution.
  probe="$(runnable_probe_of "$raw_method")"
  if [ -n "$probe" ]; then echo "per-issue"; return; fi

  # 1b) A NATIVE SCOPE ASSERTION ROUTES BY ITS COMMAND, AHEAD OF PROSE. When the
  #     designated command -- extract_command's pick, here a span invoking a tool --
  #     parses as the scope family's closed grammar (scope_spec_of: `git diff` over
  #     the release range, pathspecs as data, a comparator), the row goes to the
  #     scope family before any keyword is read. No executing row is taken: a row
  #     carrying a runnable probe left at step 1, and extract_command prefers a
  #     runnable span, so this pick is a tool span only when the row has no probe.
  cmd="$(extract_command "$raw_method")"
  if [ -n "$cmd" ] && scope_spec_of "$cmd" "$raw_method" >/dev/null; then echo "scope"; return; fi

  # 2) Keyword-match the method string -- rows with no runnable probe: command-less
  #    prose, and commands this executor does not run. The integration keyword comes
  #    first, ahead of the declared deploy route below.
  case "$method" in
    *cross-issue*|*ciac*|*integration*)                echo "integration";   return ;;
  esac

  # THE DEPLOY-CHECK ORACLE IS REACHED BY DECLARATION, NEVER BY PROSE.
  #
  # handle_deploy_check grades by the exit status of deploy.sh --check alone, which
  # reads nothing a row asserts: the verdict is the row's only when the row's command
  # IS that check (declares_deploy_check: the designated command is the backticked
  # invocation). This arm used to be claimed by *deploy*--check*|*byte-diff*|
  # *byte-equivalent*|*unchanged*, so a prose word chose. Measured when this was
  # written (216 plans): after the runnable-probe step 44 rows reached it and 22 did
  # not designate its invocation -- 10 command-less rows routed by a word such as
  # "unchanged", 4 --check-<mode> runs the glob matched as a prefix, 7 other tools a
  # word or a mention carried here, 1 pipeline. Each took a verdict for a claim the
  # oracle never tested. Such a row now falls to the arms below and takes the outcome
  # its own command earns. The integration arm stays above, so no row moves in. The
  # words keep one job: among DECLARED rows a regression word selects regression, else
  # sync. The declared route's exit status still covers the whole run, and a warn-mode
  # check never fails it, so a row claiming one Check's findings is not graded by it.
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G18 M5 restores the prose
  # route by one substitution.
  if declares_deploy_check "$raw_method"; then case "$method" in *regression*|*unchanged*|*byte-diff*|*byte-equivalent*|*intact*) echo "regression" ;; *) echo "sync" ;; esac; return; fi

  case "$method" in
    *grep*|*"test -f"*|*anchor*|*present*|*"≥"*|*">="*)                     echo "per-issue";     return ;;
    # RUNTIME-SUITE IS REACHED BY DECLARATION, NEVER BY PROSE, AND NEVER
    # AHEAD OF AN EXECUTABLE ROW.
    #
    # This arm used to read
    #   *runtime*suite*|*test-run*|*dispatch*the*runtime*|*suite-*|*exercise*
    # and it sat ABOVE the executable arm, so a bash `case` took it first.
    # Two consequences, both measured over the whole indexed corpus, in which
    # 2 of 2 runtime-suite rows were hijacked executable assertions:
    #   - a runnable method that merely SAID "exercise" was routed away from
    #     the family that would have run it, and
    #   - the family it landed in returned PASS having executed nothing.
    # The same `grep -c` command earned a real PASS bare and a fabricated one
    # prefixed "Exercise the register:". The family had never once graded a
    # legitimate runtime declaration.
    #
    # The surviving tokens are the test-run SUBTYPES themselves - the event
    # schema vocabulary an author writes to DECLARE an outcome, not words that
    # occur in ordinary English about a check. Step 1 resolves every runnable
    # probe before any arm here, so a method carrying one is executed even
    # when it also names a subtype. A method with neither reaches step 3,
    # which names a recognised tool command it carries; one naming no tool
    # either reaches the residual (step 4) and is inspected by the per-issue
    # handler: a runnable command runs, a tool is declined by name, and a
    # method with no command is a named SKIP -- never a PASS without an
    # executed check.
    *suite-skip*|*suite-fail*)                                              echo "runtime-suite"; return ;;
  esac

  # 3) A RECOGNISED TOOL COMMAND THAT NO ARM CLAIMED IS CAN'T-RUN-HERE, NOT
  #    UNCLASSIFIABLE. extract_command returns a span whose leading token is not an
  #    allowlisted verb only when span_invokes_tool names it -- an invocation-shaped
  #    span of a catalogued tool or a script -- so the row WAS read: it names a
  #    command this executor will not run. ERROR means "could not read", so such a
  #    row goes to the unrunnable family, which names the tool. A method with no
  #    such span still reaches step 4. The step's test line is KEPT ON ONE LINE ON
  #    PURPOSE: the suite's mutation arm G17 M1 removes it by one substitution.
  local lead
  lead="$(printf '%s' "$cmd" | awk '{print $1}')"
  if [ -n "$lead" ] && ! is_runnable_verb "$lead"; then echo "unrunnable"; return; fi

  # 4) THE RESIDUAL -- a method no step above claims is INSPECTED, never guessed and
  #    never reported unreadable. The per-issue handler runs a runnable command, declines
  #    a tool by name, or names a method with no command (a named read, a judge-rubric,
  #    prose that merely opens with a verb) -- a named SKIP, graded where its criterion
  #    is graded. A missing keyword no longer changes the verdict. ERROR stays reserved
  #    for a row the executor tried to evaluate and could not, and a family no handler
  #    owns is an internal inconsistency (dispatch_check). The line is KEPT ON ONE LINE
  #    ON PURPOSE: the suite's mutation arm G19 M1 reverts it by one substitution.
  echo "per-issue"   # residual: inspected by the per-issue handler, never guessed
}

# ---------------------------------------------------------------------------
# AWK_HEAL_FIELDS — the markdown table-cell splitter, defined ONCE and consumed
# by both parser sites (parse_verification_plan and parse_ciac's table form).
#
# WHY THIS IS NOT `awk -F'|'`. In GFM a table cell is bounded by an UNESCAPED
# pipe; `\|` renders a LITERAL pipe inside a cell and is the only correct way to
# author one. `awk -F'|'` cannot express that distinction, so an escaped row
# split at NF=7 or NF=8 against a 6-column header, every cell after the escape
# read at a shifted index, the Method cell truncated mid-content, and the orphan
# fragment executed as a bare command. Measured over the corpus: 25 rows across
# the release-plan corpus carry an escaped pipe and every one of them mis-split.
#
# WHY NOT THE PLATFORM'S OWN PRIOR-ART FIX (widening the separator to ' [|] ').
# It was measured and REJECTED, on evidence rather than taste: it scores full
# parity on today's rows but (a) breaks header detection outright, because `$1`
# becomes the leading-pipe fragment `"| Issue"` and the `trim($i) == "issue"`
# test never matches without a new border-strip step, and (b) introduces a
# SILENT-DROP class — an unspaced but perfectly valid GFM table (`|a|b|c|`)
# collapses to NF=1 and every row vanishes. This file's stated doctrine is that
# an unparseable, absent, empty or truncated input must NEVER read as "nothing
# declared, therefore no violations"; that candidate introduces exactly that.
# It is the right fix for a template that GUARANTEES ` | ` around every cell,
# and release-plan tables carry no such guarantee.
#
# WHAT THIS DOES INSTEAD. Split on `|`, then walk the pieces and RE-JOIN any
# piece whose trailing backslash run is ODD — that backslash escaped the pipe
# that split it — substituting the literal `|` the author meant. An EVEN run is
# a real backslash and is left alone. The escape is therefore resolved exactly
# once, at the markdown -> data boundary, which is why the same change also
# fixes the leakage of a raw `\|` into a matcher's regex downstream.
#
# EDITOR NOTE: assigned in SINGLE quotes so `"\\"` reaches awk as one backslash,
# and used as "$AWK_HEAL_FIELDS"'<rest>' so the two halves concatenate into the
# single program argument awk accepts. Keep this body apostrophe-free.
# ---------------------------------------------------------------------------
readonly AWK_HEAL_FIELDS='
function heal_fields(line, F,   raw, m, i, k, cur, pend, bs) {
  m = split(line, raw, "|")
  k = 0; pend = 0; cur = ""
  for (i = 1; i <= m; i++) {
    if (pend) cur = cur "|" raw[i]; else cur = raw[i]
    pend = 0
    bs = 0
    while (substr(cur, length(cur) - bs, 1) == "\\") bs++
    # An odd trailing backslash run escaped the pipe that split here — drop the
    # escaping backslash and keep joining. Never on the LAST piece: there is no
    # following pipe for it to have escaped, so it is a real trailing backslash.
    if (bs % 2 == 1 && i < m) {
      cur = substr(cur, 1, length(cur) - 1)
      pend = 1
      continue
    }
    k++; F[k] = cur
  }
  return k
}
'

# Parse the Verification-Plan per-issue tables into check records.
# Emits TAB-separated: issue \t ac \t family \t method \t expected
parse_verification_plan() {
  local file="$1"
  local body
  body="$(_extract_section "$file" "Verification Plan")"
  if [ -z "$body" ]; then return 0; fi

  printf '%s\n' "$body" | awk -v RFS="$REC_FS" "$AWK_HEAL_FIELDS"'
    function trim(s) { gsub(/^[ \t]+|[ \t]+$/, "", s); return s }
    function lc(s)   { return tolower(s) }
    # THE RECORD SHAPE IS SINGLE-SOURCED HERE. Every emit goes through rec(),
    # so the field count and the separator cannot drift between emit sites --
    # which is how the five-field record acquired a positionally ambiguous
    # member in the first place. RFS is supplied by -v (never as an escape
    # inside a printf format string: BSD and GNU awk differ on octal-escape
    # handling there, and -v has no such variance).
    function rec(a, b, c, d, e) {
      printf "%s%s%s%s%s%s%s%s%s\n", a, RFS, b, RFS, c, RFS, d, RFS, e
    }
    # A table whose header DECLARES verification content but resolves no method
    # column is latched at its header and flushed as ONE record per block --
    # per block, not per row, because the operator needs "this table suppressed
    # N rows", not N identical errors. cur_issue is captured at LATCH time:
    # the flush fires from a rule that may already have moved to the next
    # issue, so reading cur_issue at flush time would misattribute the block.
    function flush_unindexable() {
      if (pend_hdr != "") {
        rec(pend_iss, "TABLE", "table-unindexable", pend_hdr, ("rows=" pend_n))
        pend_hdr = ""; pend_n = 0; pend_iss = ""
      }
    }
    function reset_cols() {
      flush_unindexable()
      have_issue_col = 0; col_issue = 0
      col_ac = 0; col_method = 0; col_expected = 0; hdr_n = 0
      block_row = 0
    }
    BEGIN { cur_issue = ""; reset_cols() }
    # (b) enriched form: a bold per-issue subsection header supplies grouping.
    # Matches a bold per-issue header line like: **#<issue> — <title>**
    /^\*\*#[0-9]+/ {
      line = $0
      match(line, /#[0-9]+/)
      cur_issue = substr(line, RSTART, RLENGTH)
      reset_cols()
      next
    }
    # PER-TABLE-BLOCK COLUMN RESET. A markdown table ends at the first non-table
    # line, so the column map must end with it. Without this the map is STICKY:
    # once a Verification-Plan header sets col_method, every later table in the
    # same section — including a prose evidence table with an entirely different
    # shape — was parsed as check rows at THAT column index. Measured over the
    # corpus, the sticky map produced 53 spurious check records (302 emitted vs
    # 249 real), which surfaced as ERROR and FAIL verdicts on prose. It is the
    # same defect as the escaped-pipe split, one level up: cells read at indices
    # that belong to a different header. Fixing it is also what makes the parity
    # guard below safe — measured against the sticky map the guard fired on 43 of
    # 302 rows; against the reset map it fires on 1 of 249, the single genuinely
    # malformed row in the corpus.
    !/^[ \t]*\|/ { reset_cols(); next }
    {
      # Heal escape-split cells BEFORE anything reads a column (see AWK_HEAL_FIELDS).
      n = heal_fields($0, F)
      block_row++
      # HEADER DETECTION IS STRUCTURAL, NEVER KEYWORD CONTAMINATION OF A DATA ROW.
      #
      # NOTE TO THE NEXT EDITOR: this awk program is a SHELL SINGLE-QUOTED string,
      # so an apostrophe anywhere in it — including in a comment — terminates the
      # string and breaks the script. Write possessives around it, as below.
      #
      # The prior form tested EVERY row and accepted it as a header the moment ANY
      # single cell contained `predicate`, `expected` or `verification method`, or
      # lowercased to exactly `issue` / `ac` / `method`. A data row matching any one
      # of those was consumed as a header and next-ed — no record, no
      # `parity-error`, no ERROR verdict, and the plan still reported all-PASS on
      # whatever survived. That is the SILENT-DROP class the design notes for this
      # tool record rejecting in another candidate (an unparseable, absent, empty or
      # truncated input must NEVER read as "nothing declared, therefore no
      # violations"), reintroduced one level up and pointed at the surface that
      # grades acceptance criteria. It is not hypothetical: two acceptance-criterion
      # rows of a live release plan vanished to it, both because a cell used the
      # word "predicate" — a word an author writing about gate predicates uses
      # constantly. The vocabulary of the schema was a trap for plans written in it.
      #
      # A header is now identified by WHERE IT IS, with a name check only as a
      # secondary filter:
      #   (1) POSITIONAL — it must be the FIRST row of a table block. A markdown
      #       table ends at the first non-table line, and `block_row` is reset with
      #       the column map, so this is exact. Every later row in the block is a
      #       data row, whatever words it contains.
      #   (2) NAME — it must name at least ONE of the schema columns, which is
      #       also what decides whether the table is a per-issue table at all. A
      #       header naming none (the release-scoped check table, whose columns
      #       are deliberately distinct) leaves col_method at 0 and its rows are
      #       skipped, exactly as before.
      # The POSITIONAL clause is the one that closes F-6, and it closes it
      # completely: a data row is never header-eligible, whatever words it
      # contains. A stricter quorum of TWO was tried and REJECTED against the
      # corpus — it silently zeroed five plans whose real headers name only one
      # schema column (`| Card | Check | Method |`), turning a false-drop of two
      # rows into a false-drop of every row in those plans. Measured, not assumed.
      # Each cell maps to at most ONE column (else-if, not independent ifs), so
      # the ordering below is the tie-break for a cell matching two patterns.
      is_header = 0
      if (block_row == 1) {
        h_issue = 0; h_ac = 0; h_pred = 0; h_method = 0; h_expected = 0; h_hits = 0
        for (i = 1; i <= n; i++) {
          c = lc(trim(F[i]))
          if (c == "issue")                                   { h_issue = i;    h_hits++ }
          else if (c == "ac")                                 { h_ac = i;       h_hits++ }
          # WIDENED, AND DELIBERATELY BY CONTAINMENT FOR THE LONG FORMS. Two
          # further spellings account for the entire droppable population --
          # `Method class` (4 plans) and `Command` (3 plans). Tightening the two
          # long forms to full-cell EQUALITY was measured and REJECTED: it gains
          # the same 59 rows but silently de-indexes 20 rows that index today
          # (`Verification method (FMF-1-scoped)` and `Verification method
          # class`), which would ship a fresh instance of the defect this change
          # exists to close. `command` takes EQUALITY instead, because it is a
          # short common English word and containment on it is a false-positive
          # risk. Measured over all 77 corpus blocks: gains 59, loses 0, and
          # swallows 0 of the 27 correct-skip blocks.
          else if (c ~ /verification method/ || c ~ /method class/ ||
                   c == "method" || c == "command")           { h_method = i;   h_hits++ }
          else if (c ~ /expected/)                            { h_expected = i; h_hits++ }
          else if (c ~ /predicate/)                           { h_pred = i;     h_hits++ }
        }
        if (h_hits >= 1) {
          is_header = 1
          have_issue_col = (h_issue > 0) ? 1 : 0
          col_issue = h_issue; col_ac = h_ac
          col_method = h_method; col_expected = h_expected
          hdr_n = n
          # THE RESIDUAL, AND ITS DISCRIMINATOR. This header declares
          # verification content -- it names AC, Expected or Predicate -- yet
          # resolves no method column, so every row beneath it is about to be
          # dropped by the `col_method == 0` guard below. Latch it and ERROR.
          #
          # A header naming ONLY `issue` is deliberately NOT latched, and that
          # is the whole discriminator: sharing one word with the schema is not
          # a verification claim. The looser rule `h_hits >= 1 && col_method ==
          # 0` was measured and REJECTED -- it fires on a live AC-BASELINE table
          # whose own prose reads "the baseline is a pinned measurement and
          # carries no verdict", and ERROR means exit 3, so it would turn a
          # correct shipped plan red. Sensitivity 7 blocks / 59 rows against the
          # pre-widening rule; specificity 0 after it.
          if (h_method == 0 && (h_ac > 0 || h_expected > 0 || h_pred > 0)) {
            pend_hdr = trim(substr($0, 1, 160)); pend_n = 0
            pend_iss = (cur_issue == "" ? "(plan)" : cur_issue)
          }
        }
      }
      if (is_header) next
      # Separator row (|---|---|).
      if ($0 ~ /^[ \t]*\|[ \t:-]+\|/ && $0 ~ /-/) {
        stripped = $0; gsub(/[ \t|:-]/, "", stripped)
        if (stripped == "") next
      }
      # Data row — only emit when we know where method + expected live. A drop
      # under a LATCHED header is counted, so the flush can name its size; a
      # drop under an unlatched one stays silent, which is the correct reading
      # of "this is not a per-issue table at all".
      if (col_method == 0) { if (pend_hdr != "") pend_n++; next }
      # HEADER/ROW FIELD-PARITY GUARD. A row that still does not carry its
      # header field count after healing carries an UNESCAPED bare pipe, which
      # is malformed GFM. Parsing it anyway reads every cell past the break at a
      # shifted index and executes whatever fragment lands in the method slot —
      # which is how this parser produced a silent false FAIL. Emit an
      # attributable ERROR naming the row instead. Fail loud; never mis-index.
      if (hdr_n > 0 && n != hdr_n) {
        rec((cur_issue == "" ? "(plan)" : cur_issue), "ROW", "parity-error", \
            trim(substr($0, 1, 160)), ("fields=" n " header=" hdr_n))
        next
      }
      method   = (col_method   <= n) ? trim(F[col_method])   : ""
      expected = (col_expected <= n && col_expected > 0) ? trim(F[col_expected]) : ""
      # A header cell naming a predicate is a SCHEMA WORD and nothing more: it
      # counts toward header detection and toward the unindexable latch above.
      # Its data cells are never read. A row declares how it is graded in its
      # method cell, so this parser resolves no class value and hands the
      # classifier none - a class column is a reader annotation.
      ac       = (col_ac       <= n && col_ac       > 0) ? trim(F[col_ac])       : ""
      issue    = have_issue_col && (col_issue <= n) ? trim(F[col_issue]) : cur_issue
      if (issue == "") issue = cur_issue
      # An empty Method cell inside an INDEXED table is an unreadable
      # declaration, not an absence: the row asserts a check and names no way
      # to run it. Dropping it silently is the same defect as the unindexable
      # table above, one row down, and the doctrine this file states for both
      # is that an unparseable input must NEVER read as "nothing declared,
      # therefore no violations". ERROR, named, carrying the row text.
      if (method == "") {
        rec((issue == "" ? "(plan)" : issue), (ac == "" ? "ROW" : ac), \
            "method-cell-empty", trim(substr($0, 1, 160)), ("method-col=" col_method))
        next
      }
      # Skip a row whose AC cell is itself the word "AC" (defensive).
      rec(issue, ac, "PENDING", method, expected)
      # family filled in by the shell classifier (awk cannot call it); marker.
    }
    # A table block that runs to end-of-section is flushed here; reset_cols()
    # covers every block that ends at a non-table line.
    END { flush_unindexable() }
  '
}

# ===========================================================================
# Component 2/3/4 — family classifier + dispatch table + handlers.
#
# Each handler is a pure (method, expected) -> verdict function. It prints a
# single line: verdict \t observed. Handlers shell ONLY existing primitives.
# ===========================================================================

# RUNNABLE_VERBS — the read-only query set this executor is permitted to run.
# Deliberately closed. A verification harness driven by an authored artifact must
# not acquire a code-execution channel: "the plan names which tool to run" is not
# a trust boundary when the same pull request can author both. A criterion whose
# substance needs a tool invocation is therefore NOT executed here — it is
# reported UNRUNNABLE, naming the tool (span_invokes_tool), and its mechanical
# guarantee is expected to live in that tool's own CI-invoked self-test, which is
# a gate in its own right.
RUNNABLE_VERBS='grep test ls head wc cat'

is_runnable_verb() {
  case " $RUNNABLE_VERBS " in *" $1 "*) return 0 ;; *) return 1 ;; esac
}

# looks_like_command — TRUE when a token is WORD-SHAPED: a bare word, not a flag, a
# path fragment, a section reference or prose. It recognises a word-shaped
# IDENTIFIER and no longer decides whether a span is a command: that is
# span_invokes_tool's question. extract_command reads a word-shaped span that invokes
# no tool as an identifier -- a label, a file name, a hash -- which is prose about
# that identifier, and never names it as the tool a row needs.
looks_like_command() {
  case "$1" in
    ''|-*|/*|.*|\#*) return 1 ;;
    *) case "$1" in *[!A-Za-z0-9_.-]*) return 1 ;; esac; return 0 ;;
  esac
}

# extract_command — pull the runnable command out of a method string.
#
# It scans EVERY backtick-quoted span and returns the FIRST one whose leading
# token is an allowlisted verb and that carries an argument -- the DESIGNATED
# command; if none is, it returns the first span that INVOKES A TOOL
# (span_invokes_tool) so the caller can report the tool it declined to run. Taking
# the first span unconditionally was a defect: an authored method that mentions a
# flag or a symbol in backticks before its actual probe (*Method:* run
# `--self-test`; then `grep …`) yielded `--self-test` as the "verb" and reported
# ERROR — a malformed-input verdict for a well-formed method. A backticked
# IDENTIFIER — a word-shaped span that invokes no tool: a label, a file name, a hash
# — is prose about that identifier: it is never returned, so no refusal names it as
# the tool a row needs, and it blocks the bare-string path below, so prose that
# merely opens with a verb is never run beside it. Falls back to the bare string when
# it already starts with an allowlisted verb (the shape the CIAC parser hands over,
# having stripped its own backticks). Prints the command or nothing. It reads the
# spans through method_spans, the one backtick splitter (METHOD LIMBS below); a bare
# verb (a tool named in prose, `grep` alone, with no argument) is never the command.
extract_command() {
  local method="$1" rec rest cls tok span fallback="" identifier=0 first T=$'\t'
  while IFS= read -r rec; do {
    [ -n "$rec" ] || continue
    rest="${rec#*"$T"}"; cls="${rest%%"$T"*}"; rest="${rest#*"$T"}"
    tok="${rest%%"$T"*}"; rest="${rest#*"$T"}"; span="${rest#*"$T"}"
    case "$cls" in runnable) printf '%s' "$span"; return ;; bare-verb) continue ;; esac
    if [ -z "$fallback" ]; then
      if [ "$cls" = not-runnable ]; then fallback="$span"
      elif looks_like_command "$tok"; then identifier=1; fi
    fi
  } </dev/null; done <<EOF_SPANS
$(method_spans "$method")
EOF_SPANS
  if [ -n "$fallback" ]; then printf '%s' "$fallback"; return; fi
  # An identifier blocks the bare-string path: prose that opens with a verb beside a
  # backticked label is prose about that label, not a command to run. KEPT ON ONE LINE
  # ON PURPOSE: the suite's mutation arm G17 M3 removes it by one substitution.
  if [ "$identifier" -eq 1 ]; then return; fi
  first="$(printf '%s' "$method" | sed -e 's/^[[:space:]]*//' | awk '{print $1}')"
  if is_runnable_verb "$first"; then
    printf '%s' "$(printf '%s' "$method" | sed -e 's/^[[:space:]]*//')"
  fi
}

# span_shell_operator <span> -- THE quote-aware shell-syntax test, ONE copy for every
# reader that asks whether a span is shell syntax this executor does not run: the
# classifier's probe step here, the handlers' refusal (shell_syntax_refusal, which reads
# an operator as can't-run-here and an unterminated quote as could-not-read), the scope
# step and the CIAC authoring lint. None of them keeps a private operator list.
# eval_free_run runs no shell, so a pipe, a command list, a redirect or a substitution
# would reach the verb as a literal argument -- not the command its author wrote. The
# span is scanned RAW, outside quotes: a quoted '|', '>= 1' or '<!--' is a pattern, and
# tokenize_cmd, which strips the quotes, cannot tell it from an operator. Prints the operator found
# (an unterminated quote counts, and prints its quote character) and returns 0;
# returns 1 when the span carries none.
span_shell_operator() {
  local s="$1" i=0 n=${#1} ch q=""
  case "$s" in *'$('*|*'`'*) printf '%s' '$('; return 0 ;; esac
  while [ "$i" -lt "$n" ]; do
    ch="${s:$i:1}"
    if [ -n "$q" ]; then
      if [ "$ch" = "$q" ]; then q=""; fi
    else
      # The quote arm is KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G15 M5
      # makes the scan quote-blind by one substitution on that line.
      case "$ch" in
        \'|\") q="$ch" ;;
        '|'|'&'|';'|'<'|'>') printf '%s' "$ch"; return 0 ;;
      esac
    fi
    i=$((i + 1))
  done
  if [ -n "$q" ]; then printf '%s' "$q"; return 0; fi
  return 1
}

# is_runnable_probe <span> -- TRUE when a span has the SHAPE of a probe this executor
# runs: its leading token is an allowlisted verb, it names at least one argument, and
# span_shell_operator finds no shell syntax in it. This is a shape test, not a promise
# that the probe runs faithfully. Faithfulness is decided where the span runs, by the
# gates on the dispatch path: eval_free_run refuses a reader whose input is, or cannot
# be shown not to be, stdin (reads_stdin_cmd, status 4), and a command that names no
# operand its verb needs (names_no_operand, status 5); count_from_output reads a
# matcher that could not run, and an exit 1 that is not a zero for its verb, as ERROR
# rather than as a count; and with no comparator, an exit 0 the reader table does not
# make the claim is not a pass (exit_zero_grades). Those operand and exit rules live in
# the one reader table (reader_rule), not here. A bare verb (`grep` alone) names a
# tool in prose and is not a probe.
is_runnable_probe() {
  tokenize_cmd "$1" || return 1
  [ "${#TOKENS[@]}" -ge 2 ] || return 1
  is_runnable_verb "${TOKENS[0]}" || return 1
  if span_shell_operator "$1" >/dev/null; then return 1; fi
  return 0
}

# runnable_probe_of <method> -- prints the probe this executor would run for the row
# -- the span extract_command picks -- when that pick is a closed backtick span and
# is_runnable_probe accepts it, else nothing. Only a backticked span qualifies: prose
# that merely opens with a verb is prose, and so is extract_command's bare-string
# fallback.
runnable_probe_of() {
  local cmd
  case "$1" in *'`'*) ;; *) return 0 ;; esac
  cmd="$(extract_command "$1")"
  [ -n "$cmd" ] || return 0
  case "$1" in *"\`$cmd\`"*) ;; *) return 0 ;; esac
  if is_runnable_probe "$cmd"; then printf '%s' "$cmd"; fi
  return 0
}

# is_deploy_check_invocation <span> -- TRUE when <span> is exactly what the deploy-check
# oracle runs: an optional `bash`, then the oracle's own path -- core/deploy/deploy.sh or
# ./core/deploy/deploy.sh, or the root shim deploy.sh or ./deploy.sh -- and --check as
# the only argument, with no shell operator outside quotes (span_shell_operator). A
# --check-<mode>, a second argument, shell syntax, or any other file that happens to be
# named deploy.sh is a different command: the oracle runs one resolved path, so the
# route is anchored to that path and its shorthands, never to the basename.
is_deploy_check_invocation() {
  local i=0 path arg
  if span_shell_operator "$1" >/dev/null; then return 1; fi
  tokenize_cmd "$1" || return 1
  if [ "${TOKENS[0]:-}" = bash ]; then i=1; fi
  [ "${#TOKENS[@]}" -eq $((i + 2)) ] || return 1
  path="${TOKENS[$i]}"; arg="${TOKENS[$((i + 1))]}"
  case "$path" in core/deploy/deploy.sh|./core/deploy/deploy.sh|deploy.sh|./deploy.sh) : ;; *) return 1 ;; esac
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G18 M7 relaxes it by one substitution.
  [ "$arg" = --check ]
}

# declares_deploy_check <method> -- TRUE when the row's designated command
# (extract_command's pick, the span every handler runs or declines) IS the oracle's
# invocation, written as a backticked span. A mention beside another command, a prose
# spelling, a later span, or a pipeline led by the invocation declares nothing.
declares_deploy_check() {
  local cmd
  cmd="$(extract_command "$1")"
  case "$1" in *"\`$cmd\`"*) : ;; *) return 1 ;; esac
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G18 M6 widens it by one substitution.
  [ -n "$cmd" ] && is_deploy_check_invocation "$cmd"
}

# method_outside_verb_spans <method> -- the method with EVERY backtick span whose
# leading token is an allowlisted verb blanked: the span and its backticks become one
# space. A phrase inside such a span is that command's own argument -- its search
# pattern -- never prose about the row, so every declared-deferral reader
# (classify_family step 0 and both handlers' guards) reads this and never the raw
# cell. The rule follows the span's KIND, not the routing pick, so a later change to
# which span routes a row cannot change which rows are deferred. The spans are the
# ones extract_command reads -- the even pieces of a split on backticks, an unclosed
# last one included -- so the two cannot disagree about where a span is. A
# declaration outside every such span, in prose or in a span led by anything else
# (`[DEFERRED — <reason>]`), is kept. The cell reaches awk through the environment,
# which awk does not escape-process, and awk reads no stdin.
method_outside_verb_spans() {
  case "$1" in *'`'*) ;; *) printf '%s' "$1"; return 0 ;; esac
  VRP_SPAN_CELL="$1" VRP_SPAN_VERBS="$RUNNABLE_VERBS" awk 'BEGIN {
    n = split(ENVIRON["VRP_SPAN_CELL"], p, "`"); out = ""
    for (i = 1; i <= n; i++) {
      if (i % 2 == 1) { out = out p[i]; continue }
      split(p[i], w)
      if (w[1] != "" && index(" " ENVIRON["VRP_SPAN_VERBS"] " ", " " w[1] " ") > 0) { out = out " "; continue }
      out = out "`" p[i] (i < n ? "`" : "")
    }
    printf "%s", out
  }'
}

# extract_threshold — pull a numeric threshold and its COMPARATOR out of a method.
# Prints "<op>\t<n>", or nothing when the method states no threshold.
#
# Four comparators, because "expect zero" is the shape most verification criteria
# actually take and a >=-only parser cannot express it: a `>= 0` assertion passes
# unconditionally, so a criterion meaning "no findings" had to be written as prose
# and fell through to SKIP. That expressiveness gap — not the criteria — is why
# this roll-up read 0 PASS.
#   >= N   "≥ N", ">= N", "at least N"
#   <= N   "≤ N", "<= N", "at most N", "no more than N"
#   == N   "exactly N", "expect N", and "expect zero" / "expect none" as == 0
# N may carry ONE markdown emphasis run between the comparator and the number
# ("expect **0**", "at least __3__"): an author emphasising the number asserted
# otherwise states no comparator at all. The vocabulary widens no further: "= N",
# "→ N" and "returns N" are not read -- real cells use the same forms for a baseline
# ("= 2") or an exit code ("returns 0"), so reading them would grade a count against a
# number that is not one.
# The alternations live ONCE, in the CMP_*_ALT constants below; comparator_phrases
# (METHOD LIMBS) reads the same constants, so the one-command path and the
# designated-command path cannot disagree about what a comparator is.
# NOTE ON THE REGEX DIALECT: every alternation below uses `sed -E` (ERE). BSD sed
# does NOT support `\|` in a basic regular expression, so a BRE alternation here
# silently matches nothing and every threshold reads as "absent" — which presents
# as a rows-pass-on-exit-code roll-up rather than as an error. The original two
# comparators avoided this by using two separate BRE calls; the comparator set is
# wide enough now that ERE is the honest way to write it.
readonly CMP_GE_ALT='≥|>=|at least'
readonly CMP_LE_ALT='≤|<=|at most|no more than'
readonly CMP_EQ_ALT='exactly|expect'
readonly CMP_EMPH_ALT='\*\*|__|\*'
extract_threshold() {
  local method="$1" n
  n="$(printf '%s' "$method" | sed -nE "s/.*(${CMP_GE_ALT})[ ]*(${CMP_EMPH_ALT})?([0-9]+).*/\\3/p" | sed -n '1p')"
  [ -n "$n" ] && { printf '>=\t%s' "$n"; return; }
  n="$(printf '%s' "$method" | sed -nE "s/.*(${CMP_LE_ALT})[ ]*(${CMP_EMPH_ALT})?([0-9]+).*/\\3/p" | sed -n '1p')"
  [ -n "$n" ] && { printf '<=\t%s' "$n"; return; }
  n="$(printf '%s' "$method" | sed -nE "s/.*(${CMP_EQ_ALT})[ ]*(${CMP_EMPH_ALT})?([0-9]+).*/\\3/p" | sed -n '1p')"
  [ -n "$n" ] && { printf '==\t%s' "$n"; return; }
  case "$method" in
    *"expect zero"*|*"expect none"*) printf '==\t0'; return ;;
  esac
}

# compare_threshold — apply a comparator. Prints PASS or FAIL.
compare_threshold() {
  local count="$1" op="$2" want="$3"
  case "$op" in
    '>=') [ "$count" -ge "$want" ] 2>/dev/null && printf 'PASS' || printf 'FAIL' ;;
    '<=') [ "$count" -le "$want" ] 2>/dev/null && printf 'PASS' || printf 'FAIL' ;;
    '==') [ "$count" -eq "$want" ] 2>/dev/null && printf 'PASS' || printf 'FAIL' ;;
    *)    printf 'FAIL' ;;
  esac
}

# ---------------------------------------------------------------------------
# METHOD LIMBS -- a method that names more than one command is graded on its
# DESIGNATED command, and every other command it names is reported as not run.
#
# THE DEFECT THIS CLOSES. The per-issue and integration handlers ran ONE command
# (the first allowlisted backticked span) and read ONE comparator from the whole
# cell (extract_threshold, which prefers >= over <= over == and takes the last
# occurrence of each). A method naming several commands was graded on its first
# command alone and reported as if every command had run: a false second command
# still read PASS, and a comparator written for a later command graded the first
# -- so "`A` expect 0; control: `B` at least 1" graded A against ">= 1" and could
# PASS a violated null.
#
# WHAT RUNS. The designated command -- the span extract_command picks: the first
# allowlisted verb that carries an argument -- runs exactly as a one-command
# method's does, and is graded on ITS OWN comparator: the one stated in the prose
# after it, up to the next command, never inside backticks. A designated command
# that states no comparator keeps the one-command path's exit-status reading, so a
# null needs "expect 0" or "expect zero" (`grep -c` exits 1 on a zero count, which
# that reading takes for a failure); one that states two comparators that disagree
# is an ERROR. A bare verb (`grep` alone) names a tool in prose: it is never the
# command and never a limb.
#
# WHAT DOES NOT RUN. Every other command the method names is reported as "did not
# run (<reason>)", naming the most basic reason: it could not run as written (a
# reader with no input file reads "names no input"; one whose input is a device, or
# an option the reader model does not know, names that refusal), it is a tool
# outside the verb set, or else only the designated command runs. A row with a
# command that did not run NEVER reads PASS. Running the further commands too was
# measured over the 215-plan corpus and NOT TAKEN: it would fully grade 1 corpus
# row, 5 of the 12 commands it would newly run cannot run correctly as written (an
# elided operand; a comparator bound to the wrong command), and no sanctioned
# authoring form asks for a further command with a comparator of its own. Naming
# them needs none of that, and running them later undoes nothing here.
#
# THE VERDICT: FAIL if the designated command failed; else ERROR if it could not be
# read; else the can't-run outcome VERDICT_PARTIAL_SLOT, the observed text naming
# the command that ran and each command that did not. A method naming one command,
# or none, never reaches this path: its grading is the one-command path's.
#
# FD-0: every limb that runs goes through the stdin-isolated dispatch. Only the
# designated command runs, through eval_free_run inside the dispatch loop's body, so
# it keeps the stdin refusal and the null fd 0; no further command is ever spawned,
# so an operand-less one in any position truncates no later row.
# ---------------------------------------------------------------------------

# span_invokes_tool <span> [<whole>] -- prints the tool a span invokes when that
# tool is outside RUNNABLE_VERBS, else nothing. THE one predicate deciding whether a
# backticked span that is not an allowlisted command is a command at all: a span it
# names is a command this executor will not run (UNRUNNABLE, naming the tool), and
# every span it does not name is prose. <whole> is non-empty when the span is the
# method's whole text, which method_spans decides.
#
# NAMED BY SHAPE, NOT BY WORD. A tool word is a command only when the span is
# INVOCATION-SHAPED: it carries two or more tokens, or it is a bare interpreter, or
# it is the whole method. A shell keyword or builtin also needs an argument, whatever
# else holds. So `awk 'END{print NR}' f` and `python3` alone are commands, while a
# backticked `case` arm, a `source` field or a control arm's `script.sh` path
# mentioned in prose are not: naming them "the tool this row needs" was the defect
# the shape test closes. The tool is the span's leading token when it is in the
# closed catalog below, or the basename of a script path (a relative path, `./`
# optional, no `..`, ending .sh .bash .py .pl .rb .js .mjs .ts).
#
# THE CATALOG IS CLOSED, AND ITS BOUNDARY IS STATED. Its words are RECOGNISED BY NAME
# AND NEVER RUN -- RUNNABLE_VERBS stays the only set this executor executes, and a
# name found here widens nothing. A real tool missing from it reads as a method with
# no command until it is added: never a pass, never a failure, and fixed by one word.
# A lexical or PATH-based test was rejected: the first admits English words, and the
# second would make a verdict depend on which tools the grading host has installed.
span_invokes_tool() {
  local t n tools interp words re='^(\./)?([A-Za-z0-9_.-]+/)*[A-Za-z0-9_.-]+\.(sh|bash|py|pl|rb|js|mjs|ts)$'
  local -a w=()
  tools='bash sh zsh dash ksh python python3 perl ruby node source . eval exec env xargs for while until if case time cd export set unset exit return local read git gh awk gawk sed tr cut sort uniq comm diff cmp paste join find jq yq tee printf echo stat file du xxd od base64 tail shasum sha256sum md5 md5sum column realpath readlink basename dirname date curl wget make npm npx pytest shellcheck cp mv rm mkdir touch chmod ln claude sqlite3 openssl osascript'
  interp='bash sh zsh dash ksh python python3 perl ruby node'
  words='source . eval exec for while until if case time cd export set unset exit return local read printf echo'
  read -r -a w <<< "$1" || true
  t="${w[0]:-}"; n=${#w[@]}
  [ -n "$t" ] || return 0
  if is_runnable_verb "$t"; then return 0; fi
  case " $tools " in
    *" $t "*)
      case " $words " in *" $t "*) [ "$n" -ge 2 ] || return 0 ;; esac
      case " $interp " in *" $t "*) : ;; *) [ "$n" -ge 2 ] || [ -n "${2:-}" ] || return 0 ;; esac
      printf '%s' "$t"; return 0 ;;
  esac
  case "$t" in *..*) return 0 ;; esac
  if [[ "$t" =~ $re ]] && { [ "$n" -ge 2 ] || [ -n "${2:-}" ]; }; then printf '%s' "${t##*/}"; fi
  return 0
}

# method_spans <method> -- THE backtick splitter. One record per non-empty backtick
# span, in order:
#   <ordinal> TAB <class> TAB <leading-token> TAB <prose-after> TAB <span>
# class: runnable (an allowlisted verb with at least one argument) · bare-verb (an
# allowlisted verb alone) · not-runnable (a tool span_invokes_tool names) · mention
# (anything else). <prose-after> is the text between this span and the next
# backtick, tabs flattened; <span> is last so it may hold any byte but a newline.
# The spans are the ones a split on backticks yields -- the even pieces, an unclosed
# last one included -- so every reader that asks where a method's spans are asks
# here: extract_command, the limb reader and the CIAC authoring lint split a method
# through this one function, and no two readers can split it two ways. A method
# that is ONE span and nothing else -- whitespace and closing punctuation aside -- is
# that span's whole text, which span_invokes_tool reads as invocation-shaped.
#
# ONLY A CLOSED SPAN IS A COMMAND. The last piece after an odd final backtick is not a
# backticked span, so it is classed mention whatever its first word: a command written
# there runs on no route -- neither handler, the designated command of a method naming
# several, nor the lint -- and no route can pick it, because every pick is made here.
# The probe step and the declared deploy route test the same closure on their own pick.
# The closure line is KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G21 M5
# removes it by one substitution.
method_spans() {
  local method="$1" i=1 n=0 span tok words cls prose whole="" rem T=$'\t'
  local ticks="${method//[!\`]/}"
  local -a seg=() w=()
  IFS='`' read -r -a seg <<< "$method" || true
  rem="${seg[0]:-}${seg[2]:-}"; rem="${rem//[[:space:].;:,]/}"
  if [ "${#seg[@]}" -le 3 ] && [ -z "$rem" ]; then whole=1; fi
  while [ "$i" -lt "${#seg[@]}" ]; do
    span="${seg[$i]}"; prose="${seg[$((i + 1))]:-}"; i=$((i + 2))
    [ -n "$span" ] || continue
    n=$((n + 1))
    w=(); read -r -a w <<< "$span" || true
    tok="${w[0]:-}"; words=${#w[@]}
    if [ "${#ticks}" -le "$((i - 2))" ]; then cls=mention   # unclosed: no backtick after it
    elif is_runnable_verb "$tok"; then
      if [ "$words" -ge 2 ]; then cls=runnable; else cls=bare-verb; fi
    elif [ -n "$(span_invokes_tool "$span" "$whole")" ]; then cls=not-runnable
    else cls=mention; fi
    printf '%s\t%s\t%s\t%s\t%s\n' "$n" "$cls" "$tok" "${prose//$T/ }" "$span"
  done
}

# comparator_phrases <text> -- every comparator phrase in <text>, in order, one per
# line as "<op> TAB <n>", read through the one vocabulary above (the CMP_*_ALT
# constants, with the same emphasis tolerance as extract_threshold). THE shared
# comparator reader: a reader that needs a cell's comparators calls this rather
# than carrying its own copy of the vocabulary.
comparator_phrases() {
  printf '%s' "$1" \
    | sed -E -e "s/(${CMP_GE_ALT})[ ]*(${CMP_EMPH_ALT})?([0-9]+)/@@C>=:\\3@@/g" \
             -e "s/(${CMP_LE_ALT})[ ]*(${CMP_EMPH_ALT})?([0-9]+)/@@C<=:\\3@@/g" \
             -e "s/(${CMP_EQ_ALT})[ ]*(${CMP_EMPH_ALT})?([0-9]+)/@@C==:\\3@@/g" \
             -e 's/expect (zero|none)/@@C==:0@@/g' \
    | { grep -oE '@@C(>=|<=|==):[0-9]+@@' || true; } \
    | sed -e 's/^@@C//' -e 's/@@$//' | tr ':' '\t'
}

# limb_comparator <prose> -- the comparator one command carries: "<op> TAB <n>" when
# <prose> states exactly one (repeats of the same one count once), "ambiguous" when
# it states two that disagree, nothing when it states none.
limb_comparator() {
  local found n
  found="$(comparator_phrases "$1" | sort -u)"
  n="$(printf '%s' "$found" | awk 'NF { c++ } END { print c+0 }')"
  case "$n" in
    0) : ;;
    1) printf '%s' "$found" ;;
    *) printf 'ambiguous' ;;
  esac
}

# method_limbs <method> -- the per-command reading of a method, built on
# method_spans. One record per COMMAND span -- a runnable span, or a tool
# span_invokes_tool names -- in order:
#   <ordinal> TAB <class> TAB <role> TAB <op> TAB <n> TAB <span>
# role -- runs: designated (the span extract_command picks); does not run: stdin (a
# further reader reads_stdin_cmd refuses -- it names no input file, or one the
# model cannot show is a file) · tool (a span span_invokes_tool names) · further
# (any other command). <op> and <n> are the designated command's own comparator,
# read from the prose after it up to the next command ("-" when it states none; "?"
# when it states two that disagree), and "-" on every other record: a command that
# does not run is not graded, so its comparator is not read. A bare verb and a
# mention are prose, never a command: a mention's own text is never read, and the
# prose after it still belongs to the command before it.
method_limbs() {
  local method="$1" designated rec rest ord cls prose span role cmp op n dseen=0 k i T=$'\t'
  local -a L_ord=() L_cls=() L_span=() L_prose=() L_des=()
  designated="$(extract_command "$method")"
  while IFS= read -r rec; do {
    [ -n "$rec" ] || continue
    ord="${rec%%"$T"*}"; rest="${rec#*"$T"}"
    cls="${rest%%"$T"*}"; rest="${rest#*"$T"}"
    rest="${rest#*"$T"}"
    prose="${rest%%"$T"*}"; span="${rest#*"$T"}"
    if [ "$dseen" -eq 0 ] && [ "$cls" = runnable ] && [ "$span" = "$designated" ]; then
      dseen=1; k=${#L_ord[@]}; L_des[$k]=1
    elif [ "$cls" = runnable ] || [ "$cls" = not-runnable ]; then
      k=${#L_ord[@]}; L_des[$k]=0
    else
      if [ "${#L_ord[@]}" -gt 0 ]; then
        k=$(( ${#L_ord[@]} - 1 )); L_prose[$k]="${L_prose[$k]} $prose"
      fi
      continue
    fi
    L_ord[$k]="$ord"; L_cls[$k]="$cls"; L_span[$k]="$span"; L_prose[$k]="$prose"
  } </dev/null; done <<EOF_LIMBS
$(method_spans "$method")
EOF_LIMBS
  i=0
  while [ "$i" -lt "${#L_ord[@]}" ]; do
    op='-'; n='-'
    if [ "${L_des[$i]}" -eq 1 ]; then
      role=designated
      cmp="$(limb_comparator "${L_prose[$i]}")"
      case "$cmp" in
        '') : ;;
        ambiguous) op='?' ;;
        *) op="${cmp%%"$T"*}"; n="${cmp#*"$T"}" ;;
      esac
    elif [ "${L_cls[$i]}" = not-runnable ]; then role=tool
    elif reads_stdin_cmd "${L_span[$i]}" >/dev/null; then role=stdin
    else role=further; fi
    printf '%s\t%s\t%s\t%s\t%s\t%s\n' "${L_ord[$i]}" "${L_cls[$i]}" "$role" "$op" "$n" "${L_span[$i]}"
    i=$((i + 1))
  done
}

# limbs_are_multi <limbs> -- true when the method names two or more commands and one
# of them is the designated command: the only case the limb path grades.
limbs_are_multi() {
  local rec rest n=0 d=0 T=$'\t'
  while IFS= read -r rec; do {
    [ -n "$rec" ] || continue
    n=$((n + 1))
    rest="${rec#*"$T"}"; rest="${rest#*"$T"}"
    case "$rest" in designated"$T"*) d=1 ;; esac
  } </dev/null; done <<< "$1"
  [ "$n" -ge 2 ] && [ "$d" -eq 1 ]
}

# grade_limbs <limbs> -- run the designated command through eval_free_run against its
# own comparator, name every other command as not run with its reason, and reduce
# (METHOD LIMBS). Prints "<verdict> TAB <observed>". The observed text lists every
# command in order after "limbs run 1 of <N>:" -- "limb <k> <verb> <verdict>
# <observed>" for the one that ran, "limb <k> <verb> did not run (<reason>)" for
# each one that did not -- and a can't-run row leads with "partial-execution:". When
# the handlers' refusal stops the designated command itself, the list reads "limbs run
# 0 of <N>:", and the verdict is the refusal's (shell_syntax_refusal).
grade_limbs() {
  local limbs="$1" rec rest span verb why sop ref lv="" lo="" list="" n=0 i out rc cres cstatus cval refused=0 T=$'\t'
  local -a R_role=() R_op=() R_want=() R_span=()
  while IFS= read -r rec; do {
    [ -n "$rec" ] || continue
    rest="${rec#*"$T"}"; rest="${rest#*"$T"}"
    R_role[$n]="${rest%%"$T"*}"; rest="${rest#*"$T"}"
    R_op[$n]="${rest%%"$T"*}"; rest="${rest#*"$T"}"
    R_want[$n]="${rest%%"$T"*}"; R_span[$n]="${rest#*"$T"}"
    n=$((n + 1))
  } </dev/null; done <<EOF_GRADE
$limbs
EOF_GRADE
  i=0
  while [ "$i" -lt "$n" ]; do
    span="${R_span[$i]}"; verb="${span#"${span%%[![:space:]]*}"}"; verb="${verb%% *}"
    case "${R_role[$i]}" in
      designated)
        if [ "${R_op[$i]}" = '?' ]; then
          lv="$VERDICT_ERROR"; lo="comparator-ambiguous (the prose after this command states comparators that disagree)"
        elif sop="$(span_shell_operator "$span")"; then
          # Shell syntax: the designated command is not run either (the handlers'
          # refusal, shell_syntax_refusal), so no command in the method ran.
          ref="$(shell_syntax_refusal "$sop")"; lv="${ref%%"$T"*}"; lo="${ref#*"$T"}"; refused=1
        else
          set +e
          out="$( cd "$REPO_ROOT" && eval_free_run "$span" 2>/dev/null )"
          rc=$?
          set -e
          cres="$(count_from_output "$span" "$out" "$rc")"
          cstatus="${cres%%"$T"*}"; cval="${cres#*"$T"}"
          if [ "$cstatus" != "OK" ]; then
            lv="$VERDICT_ERROR"; lo="$(unreadable_observed "$cval")"
          elif [ "${R_op[$i]}" != '-' ]; then
            if [ "$(compare_threshold "$cval" "${R_op[$i]}" "${R_want[$i]}")" = PASS ]; then
              lv="$VERDICT_PASS"; lo="count=$cval (${R_op[$i]} ${R_want[$i]})"
            else
              lv="$VERDICT_FAIL"; lo="count=$cval (wanted ${R_op[$i]} ${R_want[$i]})"
            fi
          elif [ "$rc" -ne 0 ]; then lv="$VERDICT_FAIL"; lo="command-exit-$rc"
          elif exit_zero_grades "$span"; then lv="$VERDICT_PASS"; lo="command-succeeded"
          else lv="$VERDICT_ERROR"; lo="$(unreadable_observed "no-comparator:$verb")"
          fi
        fi
        list="${list:+$list; }limb $((i + 1)) $verb $lv $lo" ;;
      stdin)
        why="$(reads_stdin_cmd "$span" || true)"
        case "$why" in stdin-reader:*|'') why="names no input" ;; esac
        list="${list:+$list; }limb $((i + 1)) $verb did not run ($why)" ;;
      tool)
        list="${list:+$list; }limb $((i + 1)) $verb did not run (outside the verb set)" ;;
      *)
        list="${list:+$list; }limb $((i + 1)) $verb did not run (only the designated command runs)" ;;
    esac
    i=$((i + 1))
  done
  if [ -z "$lv" ]; then
    printf '%s\t%s\n' "$VERDICT_ERROR" "multi-command-without-designated-command (internal inconsistency: limbs_are_multi admits only a method with one)"
  elif [ "$lv" = "$VERDICT_PASS" ]; then
    printf '%s\t%s\n' "$VERDICT_PARTIAL_SLOT" \
      "partial-execution: limbs run 1 of $n: $list — a command that did not run is not a pass"
  elif [ "$refused" -eq 1 ]; then
    printf '%s\t%s\n' "$lv" "limbs run 0 of $n: $list"
  else
    printf '%s\t%s\n' "$lv" "limbs run 1 of $n: $list"
  fi
}

# command_list <method> <designated> <designated-text> -- the partition's partial rule
# for a family whose designated command is not an allowlisted verb (the scope family's
# assertion; the deploy check). Lists the method's commands in order, as grade_limbs
# names them -- "limb <k> <verb> <designated-text>" for the designated one and "limb
# <k> <verb> did not run (<reason>)" for every other -- and prints "<N> TAB <list>",
# N the number of commands. N below 2 means the row names no command beside the
# designated one. A reason is the most basic one, as in grade_limbs: a tool outside
# the verb set; a reader that names no input; else only the designated command runs.
command_list() {
  local method="$1" designated="$2" dtext="$3" rec rest cls span verb why list="" k=0 dseen=0 T=$'\t'
  while IFS= read -r rec; do {
    [ -n "$rec" ] || continue
    rest="${rec#*"$T"}"; cls="${rest%%"$T"*}"
    rest="${rest#*"$T"}"; rest="${rest#*"$T"}"; span="${rest#*"$T"}"
    case "$cls" in runnable|not-runnable) ;; *) continue ;; esac
    k=$((k + 1))
    verb="${span#"${span%%[![:space:]]*}"}"; verb="${verb%% *}"
    if [ "$dseen" -eq 0 ] && [ "$span" = "$designated" ]; then
      dseen=1; list="${list:+$list; }limb $k $verb $dtext"; continue
    fi
    if [ "$cls" = not-runnable ]; then why="outside the verb set"
    elif why="$(reads_stdin_cmd "$span")"; then
      case "$why" in stdin-reader:*|'') why="names no input" ;; esac
    else why="only the designated command runs"; fi
    list="${list:+$list; }limb $k $verb did not run ($why)"
  } </dev/null; done <<EOF_CMDS
$(method_spans "$method")
EOF_CMDS
  printf '%s\t%s' "$k" "$list"
}

# per_issue_command <method> -- THE PER-ISSUE GUARD: the command the per-issue handler
# may run, which is extract_command's pick only when that pick is a backtick span of the
# method. extract_command falls back to the whole cell when the cell opens with an
# allowlisted verb, because a table-form CIAC cell reaches the cross-issue handler with
# its backticks already stripped (parse_ciac). A per-issue method is never de-backticked,
# so that fallback here would run prose that merely opens with a verb -- "grep the
# criterion in the spec", "test the decision records the chosen branch" -- as a command,
# and grade the matcher's failure on its words. A span never carries a backtick, and the
# whole-cell fallback of a cell that has one always does, so a cell with no backtick, or
# a pick carrying one, names no command here: unbackticked prose never runs. The span
# must also be CLOSED: method_spans never offers the piece after an odd final backtick
# as a command, so a command written there runs on no route. The classifier's probe step
# already reads only a closed backticked span; this is the same rule at the handler,
# which the residual now reaches with rows no keyword claimed.
per_issue_command() {
  local cmd
  case "$1" in *'`'*) ;; *) return 0 ;; esac
  cmd="$(extract_command "$1")"
  case "$cmd" in *'`'*) return 0 ;; esac
  printf '%s' "$cmd"
}

# per-issue: extract a runnable predicate from the method string and run it.
# Supports the two dominant shapes: `grep ... ≥ N` / `grep -c ... N` and
# `test -f <path>`. Anything else with an executable command substring is run
# in a restricted way (command allowlist); a command outside the allowlist is
# UNRUNNABLE, naming the tool; a method with no command is SKIP (honest — no
# fabricated PASS for a check that carries no runnable method). It is also the
# classifier's RESIDUAL: a row no family arm claims is inspected here, so a
# method that names nothing to run reads that SKIP whether or not a keyword
# routed it, and ERROR stays reserved for a row it tried to evaluate and could
# not. It runs only a backtick span (per_issue_command).
handle_per_issue() {
  local method="$1" expected="$2"
  # Honest no-op: a declared-deferred method is a SKIP with a reason. (The
  # classifier already routes most DEFERRED methods to the deferred family; this
  # is the belt-and-suspenders guard for a per-issue-classified deferred row.)
  # Read outside every span led by an allowlisted verb, as classify_family step 0
  # is: a phrase inside the probe is its pattern, not a declaration.
  case "$(method_outside_verb_spans "$method")" in
    *DEFERRED*|*declared,\ verification\ deferred*|*deferred\ to\ #*)
      printf '%s\t%s\n' "$VERDICT_SKIP" "declared-deferred"; return ;;
  esac

  # A method naming two or more commands is graded on its designated command, and
  # every other command is named as not run (METHOD LIMBS).
  local limbs
  limbs="$(method_limbs "$method")"
  if limbs_are_multi "$limbs"; then grade_limbs "$limbs"; return; fi

  # Only a backtick span is a command here (per_issue_command, the per-issue guard).
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G19 M7 removes the guard by
  # one substitution.
  local cmd
  cmd="$(per_issue_command "$method")"
  if [ -z "$cmd" ]; then
    # No runnable command embedded → cannot execute honestly.
    printf '%s\t%s\n' "$VERDICT_SKIP" "no-executable-command-in-method"; return
  fi

  # Allowlist the leading verb. Outside the read-only query set is UNRUNNABLE,
  # naming the tool -- neither ERROR nor SKIP: the executor declining to run a
  # tool is a statement about the executor, not a defect in the method (ERROR is
  # reserved for input this parser cannot make sense of), and the plan declared
  # nothing (SKIP is the plan's declaration). handle_unrunnable is the one
  # decline point every route shares.
  local verb; verb="$(printf '%s' "$cmd" | awk '{print $1}')"
  if ! is_runnable_verb "$verb"; then
    handle_unrunnable "$method"; return
  fi

  # A designated command carrying shell syntax is not run: this executor runs no
  # shell, so an operator outside quotes would reach the verb as a literal argument,
  # and an unterminated quote leaves the command unsplittable into its author's words.
  # The test is span_shell_operator, the one shared quote-aware predicate, and the
  # verdict is shell_syntax_refusal's: UNRUNNABLE for an operator, ERROR for a quote.
  # KEPT ON ONE LINE ON PURPOSE, in both handlers: the suite's mutation arm G18 M8
  # removes the refusal by one substitution.
  local sop
  if sop="$(span_shell_operator "$cmd")"; then shell_syntax_refusal "$sop"; return; fi

  local threshold op want; threshold="$(extract_threshold "$method")"
  op="$(printf '%s' "$threshold" | cut -f1)"; want="$(printf '%s' "$threshold" | cut -f2)"

  # Run the embedded command from REPO_ROOT so relative paths resolve.
  local out rc count
  set +e
  out="$( cd "$REPO_ROOT" && eval_free_run "$cmd" 2>/dev/null )"
  rc=$?
  set -e

  # Read the count through the shared reader. Called UNCONDITIONALLY — including
  # on the threshold-free path — because its exit-status guard is what stops a
  # matcher that could not run from being graded as if it had.
  local cres cstatus cval
  cres="$(count_from_output "$cmd" "$out" "$rc")"
  cstatus="$(printf '%s' "$cres" | cut -f1)"
  cval="$(printf '%s' "$cres" | cut -f2)"
  if [ "$cstatus" != "OK" ]; then
    printf '%s\t%s\n' "$VERDICT_ERROR" "$(unreadable_observed "$cval")"
    return
  fi

  if [ -n "$threshold" ]; then
    count="$cval"
    if [ "$(compare_threshold "$count" "$op" "$want")" = PASS ]; then
      printf '%s\t%s\n' "$VERDICT_PASS" "count=$count ($op $want)"
    else
      printf '%s\t%s\n' "$VERDICT_FAIL" "count=$count (wanted $op $want)"
    fi
    return
  fi

  # No threshold: rc 1 -> FAIL (a legitimate no-match or false: only grep and test
  # reach here with it -- for the other verbs count_from_output read exit 1 as an
  # unreadable operand), and rc >= 2 was already converted to ERROR above. rc 0 is a
  # PASS only where the reader table makes exit 0 the claim (exit_zero_grades): for
  # cat, head, wc and an ls listing a directory it says only that the input could be
  # read, so the claim was not evaluated -- ERROR no-comparator:<verb>.
  if [ "$rc" -ne 0 ]; then
    printf '%s\t%s\n' "$VERDICT_FAIL" "command-exit-$rc"
  elif exit_zero_grades "$cmd"; then
    printf '%s\t%s\n' "$VERDICT_PASS" "command-succeeded"
  else
    printf '%s\t%s\n' "$VERDICT_ERROR" "$(unreadable_observed "no-comparator:$verb")"
  fi
}

# tokenize_cmd — split a command string into words, respecting single- and
# double-quoted spans (so a quoted grep pattern that contains spaces or a `|`
# alternation stays ONE argument). Populates the global array TOKENS[].
# Returns non-zero on an unterminated quote.
tokenize_cmd() {
  local s="$1" i=0 n=${#1} ch cur="" inq="" started=0
  TOKENS=()
  while [ "$i" -lt "$n" ]; do
    ch="${s:$i:1}"
    if [ -n "$inq" ]; then
      if [ "$ch" = "$inq" ]; then inq=""; else cur+="$ch"; fi
    else
      case "$ch" in
        \'|\") inq="$ch"; started=1 ;;
        ' '|$'\t')
          if [ "$started" -eq 1 ]; then TOKENS+=("$cur"); cur=""; started=0; fi ;;
        *) cur+="$ch"; started=1 ;;
      esac
    fi
    i=$((i+1))
  done
  if [ -n "$inq" ]; then return 2; fi          # unterminated quote
  if [ "$started" -eq 1 ]; then TOKENS+=("$cur"); fi
  return 0
}

# stdin_input_refusal <verb> <input> — the ONE input rule reads_stdin_cmd applies
# to everything a command would READ: a file operand, or the value of an option
# that names an input file. Prints the refusal and returns 0 when the input is
# stdin or a device; returns 1 for an ordinary path.
#   `-`                    stdin itself -> stdin-reader:<verb>
#   under /dev/ or /proc/  a device or a descriptor, never a repository file ->
#                          device-operand:<input>. ONE rule for every spelling
#                          of stdin and of a descriptor (/dev/stdin, /dev/fd/N,
#                          /dev//stdin, //dev/fd/0, /proc/self/fd/0) rather than
#                          a list of spellings; repeated slashes are collapsed
#                          before the test, and the input is reported as written.
stdin_input_refusal() {
  local p="$2" two='//' one='/'
  if [ "$p" = "-" ]; then printf 'stdin-reader:%s' "$1"; return 0; fi
  while case "$p" in *//*) true ;; *) false ;; esac; do p="${p//$two/$one}"; done
  case "$p" in /dev|/dev/*|/proc|/proc/*) printf 'device-operand:%s' "$2"; return 0 ;; esac
  return 1
}

# reads_stdin_cmd — TRUE (status 0) when an allowlisted READER verb (grep, head,
# wc, cat) would take its input from stdin — or when this model cannot show that
# it would not. It prints the refusal reason, which count_from_output hands on:
#   stdin-reader:<verb>       no input file is named: no operand at all, the
#                             operand `-`, or (grep) a pattern file given as `-`
#   device-operand:<input>    an input under /dev/ or /proc/ (stdin_input_refusal)
#   unmodelled-option:<opt>   an option this model does not know, so it cannot
#                             tell whether the option takes the next word -- and
#                             a taken word misread as a file operand is exactly how
#                             a stdin reader would pass for a file reader
# Under FD-0 a stdin reader's stdin is the null device, so a count taken there is
# a count over nothing; eval_free_run refuses the command instead (status 4) and
# count_from_output names it. test and ls never read stdin and are not modelled.
#
# THE MODEL IS CLOSED, AND IT KNOWS EACH OPTION'S ARITY, because an option's
# separate argument is not an operand: `grep -m 1 x` names no file, and reading
# `1` or `x` as one would hide exactly the case this exists for.
#   grep  argument-taking letters e f m A B C d D; long options by NAME, in
#         either spelling (--name=value or --name value), except --context,
#         whose separate form takes the next word on one platform and not on
#         another, so only its attached form is modelled. The first operand is
#         the pattern unless -e / -f / --regexp / --file supplied one; with
#         -r / -R, --recursive or -d recurse and no operand it searches the
#         working directory, not stdin; with no pattern at all it fails on usage
#         before it reads anything, so it is no stdin reader: status 2, printing
#         no-operand:grep, which the reader table's operand rule reads
#         (names_no_operand) so that such a grep is refused before it runs.
#   head  argument-taking letters n c; the obsolete -N form is a flag
#   wc    flags c l m w L
#   cat   flags b e n s t u v
# head, wc and cat model only the options every platform's copy shares, and no
# long option at all: an option one platform lacks is a usage error there, and
# those three report a usage error as exit 1, which the count reader takes for a
# legitimate zero. grep reports usage as exit 2, which reads as ERROR, so its
# table can carry either platform's letters.
# Measured over the 454 reader commands the 217-plan corpus dispatched when this
# was written, against a ground truth that ran each one with stdin on the null
# device and on a directory: it refuses all 16 that read stdin and none of the
# other 437 -- 26 of which are a pattern-less grep, which a bare "no operand" rule
# would have refused -- and no corpus command meets the unmodelled or device rule.
# RESIDUAL, declared: the model is LEXICAL. A repository path that reaches a
# device through `..` segments or a committed symlink is not refused; the FD-0
# redirect still keeps that child off the record stream, and the tripwire still
# reports a shortened one.
reads_stdin_cmd() {
  tokenize_cmd "$1" || return 1
  local verb="${TOKENS[0]:-}" n=${#TOKENS[@]} i=1 t c k name val eq want="" opts=1
  local need_pat=0 have_pat=0 files=0 recursive=0 argshort="" flagshort=""
  case "$verb" in
    grep) need_pat=1; argshort="efmABCdD"
          flagshort="abcEFGHhIiJLlMnOoPpqRrSsTUuVvwXxyZz0123456789" ;;
    head) argshort="nc"; flagshort="0123456789" ;;
    wc)   flagshort="clmwL" ;;
    cat)  flagshort="benstuv" ;;
    *)    return 1 ;;
  esac
  while [ "$i" -lt "$n" ]; do
    t="${TOKENS[$i]}"; i=$((i+1))
    if [ -n "$want" ]; then                     # the previous option's separate argument
      case "$want" in
        e) have_pat=1 ;;
        f) have_pat=1; if stdin_input_refusal "$verb" "$t"; then return 0; fi ;;
        F) if stdin_input_refusal "$verb" "$t"; then return 0; fi ;;
        d) if [ "$t" = recurse ]; then recursive=1; fi ;;
      esac
      want=""; continue
    fi
    if [ "$opts" -eq 1 ]; then
      case "$t" in
        --) opts=0; continue ;;
        -)  : ;;                                # the stdin operand: the operand arm below
        --?*)
          name="${t#--}"; name="${name%%=*}"; val=""; eq=""
          case "$t" in *=*) val="${t#*=}"; eq=1 ;; esac
          case "$verb:$name" in
            grep:regexp)       if [ -n "$eq" ]; then have_pat=1; else want=e; fi ;;
            grep:file)         if [ -z "$eq" ]; then want=f
                               else have_pat=1; if stdin_input_refusal "$verb" "$val"; then return 0; fi; fi ;;
            grep:exclude-from) if [ -z "$eq" ]; then want=F
                               elif stdin_input_refusal "$verb" "$val"; then return 0; fi ;;
            grep:directories)  if [ -z "$eq" ]; then want=d
                               elif [ "$val" = recurse ]; then recursive=1; fi ;;
            grep:max-count|grep:after-context|grep:before-context|grep:binary-files|grep:devices|grep:label|grep:include|grep:exclude|grep:exclude-dir|grep:include-dir|grep:group-separator)
                               if [ -z "$eq" ]; then want=x; fi ;;
            grep:context)      if [ -z "$eq" ]; then printf 'unmodelled-option:--%s' "$name"; return 0; fi ;;
            grep:recursive|grep:dereference-recursive) recursive=1 ;;
            grep:count|grep:ignore-case|grep:no-ignore-case|grep:invert-match|grep:word-regexp|grep:line-regexp|grep:files-with-matches|grep:files-without-match|grep:only-matching|grep:quiet|grep:silent|grep:no-messages|grep:byte-offset|grep:line-number|grep:line-buffered|grep:with-filename|grep:no-filename|grep:extended-regexp|grep:fixed-strings|grep:basic-regexp|grep:perl-regexp|grep:text|grep:binary|grep:null|grep:null-data|grep:initial-tab|grep:no-group-separator|grep:color|grep:colour) : ;;
            *) printf 'unmodelled-option:--%s' "$name"; return 0 ;;
          esac
          continue ;;
        -?*)
          k=1
          while [ "$k" -lt "${#t}" ]; do
            c="${t:$k:1}"; k=$((k+1))
            case "$argshort" in
              *"$c"*)                           # takes an argument: the rest of the cluster, else the next word
                if [ "$k" -lt "${#t}" ]; then
                  val="${t:$k}"
                  case "$c" in
                    e) have_pat=1 ;;
                    f) have_pat=1; if stdin_input_refusal "$verb" "$val"; then return 0; fi ;;
                    d) if [ "$val" = recurse ]; then recursive=1; fi ;;
                  esac
                else
                  want="$c"
                fi
                break ;;
            esac
            case "$flagshort" in
              *"$c"*) case "$c" in r|R) recursive=1 ;; esac ;;
              *)      printf 'unmodelled-option:-%s' "$c"; return 0 ;;
            esac
          done
          continue ;;
      esac
    fi
    if [ "$need_pat" -eq 1 ] && [ "$have_pat" -eq 0 ]; then have_pat=1; continue; fi
    if stdin_input_refusal "$verb" "$t"; then return 0; fi
    files=$((files+1))
  done
  if [ "$files" -gt 0 ]; then return 1; fi
  if [ "$need_pat" -eq 1 ] && [ "$have_pat" -eq 0 ]; then printf 'no-operand:%s' "$verb"; return 2; fi
  if [ "$verb" = grep ] && [ "$recursive" -eq 1 ]; then return 1; fi
  printf 'stdin-reader:%s' "$verb"
  return 0
}

# ---------------------------------------------------------------------------
# THE READER-SEMANTICS TABLE -- what each allowlisted verb's exit status and output
# MEAN, stated once, one row per verb. Every reader of a command's result asks it here
# rather than carrying a point rule of its own: eval_free_run (a command naming no
# operand its verb needs is refused before it runs, status 5), count_from_output (what
# exit 1 means; how a count is read) and the handlers' no-comparator reading
# (exit_zero_grades: whether exit 0 is itself the claim).
#
#   verb  exit 1        operand the command must name   a count is read as           no comparator: exit 0
#   grep  a zero        a pattern (a pattern with no    -c / --count: the last ":"   is the claim (a line
#         (no match)    file is stdin-reader:grep)      field, summed; else lines    matched): PASS
#   test  a zero        an expression, and a unary      lines (test prints none)     is the claim (the
#         (false)       primary's operand                                           expression held): PASS
#   ls    unreadable    a path                          lines (one per entry)        is the claim only as an
#         operand                                                                    existence check
#   head  unreadable    a file (else stdin-reader)      lines                        is not the claim
#   wc    unreadable    a file (else stdin-reader)      its first field, on the      is not the claim
#                                                       last line (several files:
#                                                       the total)
#   cat   unreadable    a file (else stdin-reader)      lines                        is not the claim
#
# WHY EACH COLUMN IS NEEDED, measured before this table existed:
#   - exit 1. ls, head, wc and cat exit 1 when an operand cannot be read, and a count
#     of 0 there is exactly the false PASS count_from_output exists to refuse:
#     `head -n 1 <missing>` expect 0 read PASS count=0. Only grep (no match) and test
#     (false) mean a legitimate zero by it. Anything else reads ERROR matcher-exit-1.
#   - operand. A command naming no operand ran on nothing or on usage: `test -d` alone
#     is test's one-argument form, true for any word, so it read PASS on a directory
#     that does not exist; `ls -1` alone lists the working directory; a grep given no
#     pattern fails on usage. Such a command is refused before it runs, and reads
#     ERROR no-operand:<verb>. head, wc and cat with no file are refused first, and more
#     specifically, as stdin readers (reads_stdin_cmd). grep's pattern is found by the
#     one grep option model there, which returns 2 when grep names none.
#   - exit 0 with no comparator. A method that states no comparator is graded on its
#     exit status, and that status is the claim only where the table says so. cat,
#     head and wc exit 0 whenever their input was readable, whatever the method claims
#     about its content (`cat <file>` -- expect `warn` read PASS on a file saying
#     enforce), and ls exits 0 whenever its operands exist, so an ls that lists a
#     directory says nothing about what is in it. Those read ERROR no-comparator:<verb>:
#     the executor tried to evaluate the claim and could not. An ls naming only files,
#     or carrying -d, IS an existence check, and its exit 0 is the claim.
#   - the count. wc prints its count in its first field, so reading its output lines
#     read `wc -l <three-line file>` as count=1; only grep has a count flag, so a -c on
#     head (bytes) or ls (ctime order) is not a count mode.
# A seventh verb, or a flag that changes a verb's reading, is a row or a cell here,
# never a new point rule in a reader. reader_rule prints one cell; it returns 1, and
# prints nothing, for a verb outside the table. Each row is KEPT ON ONE LINE, and every
# reader reads the table through this one function: the suite reads every cell (G19).
# ---------------------------------------------------------------------------
reader_rule() {
  local e1 op cnt e0
  case "$1" in
    grep) e1=zero;       op=pattern;    cnt=count-flag;  e0=claim ;;
    test) e1=zero;       op=expression; cnt=lines;       e0=claim ;;
    ls)   e1=unreadable; op=path;       cnt=lines;       e0=existence ;;
    head) e1=unreadable; op=file;       cnt=lines;       e0=not-the-claim ;;
    wc)   e1=unreadable; op=file;       cnt=first-field; e0=not-the-claim ;;
    cat)  e1=unreadable; op=file;       cnt=lines;       e0=not-the-claim ;;
    *)    return 1 ;;
  esac
  case "$2" in
    exit1)   printf '%s' "$e1" ;;
    operand) printf '%s' "$op" ;;
    count)   printf '%s' "$cnt" ;;
    exit0)   printf '%s' "$e0" ;;
    *)       return 1 ;;
  esac
}

# names_no_operand <cmd> -- the table's operand column: TRUE when the command names no
# operand its verb needs, so eval_free_run refuses it before it runs (status 5) and
# count_from_output reads ERROR no-operand:<verb>. grep: no pattern, as the one grep
# option model reads it (reads_stdin_cmd returns 2). test: no expression at all, or an
# expression ending in a unary primary with no operand (`test -f`, `test ! -d`). ls: no
# path, flags aside. head, wc and cat: never here -- with no file they read stdin, and
# reads_stdin_cmd refuses them first. A test expression that is present but malformed
# is left to test itself, which exits 2 on it: ERROR matcher-exit-2.
names_no_operand() {
  local verb n i=1 t rs=0
  tokenize_cmd "$1" || return 1
  verb="${TOKENS[0]:-}"; n=${#TOKENS[@]}
  case "$(reader_rule "$verb" operand)" in
    pattern)
      reads_stdin_cmd "$1" >/dev/null || rs=$?
      [ "$rs" -eq 2 ] ;;
    expression)
      while [ "$i" -lt "$n" ] && [ "${TOKENS[$i]}" = '!' ]; do i=$((i + 1)); done
      [ "$i" -lt "$n" ] || return 0
      case "${TOKENS[$((n - 1))]}" in -[bcdefghkLnOGNprsStuwxz]) return 0 ;; esac
      return 1 ;;
    path)
      while [ "$i" -lt "$n" ]; do
        t="${TOKENS[$i]}"; i=$((i + 1))
        case "$t" in
          --)  [ "$i" -lt "$n" ] && return 1; return 0 ;;
          -?*) continue ;;
          *)   return 1 ;;
        esac
      done
      return 0 ;;
    *) return 1 ;;
  esac
}

# exit_zero_grades <cmd> -- the table's no-comparator column: TRUE when the exit 0 of a
# command that states no comparator IS its claim, so the row reads PASS. grep (a line
# matched) and test (the expression held) always; ls only as an existence check -- an
# operand that is a directory, with no -d, lists that directory, and its exit 0 says
# only that the directory exists. cat, head and wc never: their exit 0 says only that
# the input could be read. A relative operand is resolved against the repository root,
# where the command ran.
exit_zero_grades() {
  local verb n i=1 t p opts=1 listing=0
  tokenize_cmd "$1" || return 1
  verb="${TOKENS[0]:-}"; n=${#TOKENS[@]}
  case "$(reader_rule "$verb" exit0)" in
    claim) return 0 ;;
    existence)
      while [ "$i" -lt "$n" ]; do
        t="${TOKENS[$i]}"; i=$((i + 1))
        if [ "$opts" -eq 1 ]; then
          case "$t" in
            --)  opts=0; continue ;;
            -?*) case "${t#-}" in *d*) return 0 ;; esac; continue ;;
          esac
        fi
        case "$t" in /*) p="$t" ;; *) p="$REPO_ROOT/$t" ;; esac
        if [ -d "$p" ]; then listing=1; fi
      done
      [ "$listing" -eq 1 ] || return 0 ;;
  esac
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G19 M5 grades every exit 0
  # again by one substitution.
  return 1   # no comparator: this exit 0 is not the claim
}

# eval_free_run — run a whitelisted command WITHOUT the shell `eval` of a
# plan-derived string. The command is quote-aware-tokenized and its tokens are
# passed straight to the binary as separate arguments, so a shell operator
# character inside an argument (a `|` in a grep alternation, a `;`) is a LITERAL
# byte to the tool, never a shell operator — there is no shell to interpret it.
# The verb is allowlisted to a read-only query set; the leading token cannot be
# a path/redirect. Defense-in-depth: reject an argument that embeds a command-
# substitution opener even though, absent eval, it too would be literal.
eval_free_run() {
  local cmd="$1" verb
  if ! tokenize_cmd "$cmd"; then return 3; fi
  [ "${#TOKENS[@]}" -ge 1 ] || return 3
  verb="${TOKENS[0]}"
  # Defense-in-depth guard on every argument (belt-and-suspenders; not load-
  # bearing since tokens bypass the shell).
  local t
  for t in "${TOKENS[@]}"; do
    case "$t" in
      *'$('*|*'`'*) return 3 ;;
    esac
  done
  # A reader whose input is -- or cannot be shown not to be -- stdin is refused
  # before it runs, with its own status, so count_from_output names it instead of
  # grading a count over the null device (FD-0). reads_stdin_cmd re-tokenizes the
  # same string, so TOKENS is unchanged by the call. It precedes `args` because on
  # bash 3.2 a zero-argument verb otherwise aborts in the "${args[@]}" expansion.
  if reads_stdin_cmd "$cmd" >/dev/null; then return 4; fi
  # A command naming no operand its verb needs is refused next, with its own status,
  # so count_from_output names it (no-operand:<verb>) instead of grading a run on
  # nothing or on usage (the reader table's operand column, names_no_operand). It sits
  # after the stdin refusal, so head, wc and cat with no file keep that more specific
  # reason, and before `args`, so no zero-argument verb reaches the expansion either.
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G19 M4 removes it by one
  # substitution.
  if names_no_operand "$cmd"; then return 5; fi
  local args=( "${TOKENS[@]:1}" )
  case "$verb" in
    grep) grep "${args[@]}" ;;
    test) test "${args[@]}" ;;
    ls)   ls "${args[@]}" ;;
    head) head "${args[@]}" ;;
    wc)   wc "${args[@]}" ;;
    cat)  cat "${args[@]}" ;;
    *)    return 3 ;;
  esac
}

# count_mode_cmd — TRUE when the matcher was asked to PRINT A COUNT rather than
# print matching lines. Read from the command's own FLAG tokens, not inferred
# from the output shape: a `grep -n` line whose matched text is itself an integer
# (`42:7`) is genuinely ambiguous under shape inference, and guessing wrong is
# precisely how a row with real hits came to report zero. Covers the long form
# and every short-option cluster carrying `c` (-c, -cE, -rc, -ch). Scanning stops
# at `--`, after which a token is an operand rather than a flag. Only a verb whose
# reader-table count column is its count flag has a count mode (grep): a -c on head
# counts bytes and on ls sorts by time, and neither prints a count.
count_mode_cmd() {
  local cmd="$1" t
  tokenize_cmd "$cmd" || return 1
  [ "${#TOKENS[@]}" -ge 2 ] || return 1
  [ "$(reader_rule "${TOKENS[0]}" count)" = count-flag ] || return 1
  for t in "${TOKENS[@]:1}"; do
    case "$t" in
      --)      return 1 ;;
      --count) return 0 ;;
      --*)     : ;;
      -*)      case "${t#-}" in *c*) return 0 ;; esac ;;
    esac
  done
  return 1
}

# ---------------------------------------------------------------------------
# count_from_output — the SINGLE hit-count reader, shared by the per-issue and
# integration handlers.
#
# WHY IT IS SHARED. Both handlers carried their own copy of
# `awk -F: '{ s += $NF }'`, and that duplication is exactly why one defect
# shipped twice. This file's stated design is a thin dispatcher over shared
# primitives; reading a count is one of those primitives.
#
# THREE DEFECTS IT CLOSES, each of which presented as a confident number:
#
#  1. SUMMING $NF OF COLON-SPLIT OUTPUT IS VALID ONLY IN COUNT MODE. `grep -c`
#     prints `<n>` or `<path>:<n>`, so the last colon field IS the count. Plain
#     `grep` and `grep -n` print matching TEXT, and awk coerces trailing prose to
#     0 — so a row with real hits reported zero. Mode is therefore derived from
#     the command's flags (count_mode_cmd) and match-mode counts non-empty LINES.
#
#  2. A NON-INTEGER COUNT FIELD IS AN ERROR, NEVER A SILENT ZERO. `s += $NF`
#     turns anything unparseable into 0, and 0 is itself a legitimate answer, so
#     the failure was indistinguishable from a real result.
#
#  3. THE EXIT STATUS IS CONSULTED UNCONDITIONALLY — the load-bearing one. The
#     old code discarded rc whenever a threshold was present, so a matcher
#     exiting 2 (bad path, bad regex) yielded empty output, a fabricated count of
#     0, and an "expect zero" criterion rendering PASS. A silent FALSE PASS
#     inside the tool that grades the release's own verification plan. grep's
#     codes discriminate exactly: 0 matched, 1 a LEGITIMATE zero, >= 2 the
#     matcher could not run (as does eval_free_run's own 3 refusal). Status 4
#     is eval_free_run REFUSING a reader before it ran (FD-0, reads_stdin_cmd):
#     it is named by its reason, never numbered, because no matcher ran.
#
# WHAT EACH STATUS AND OUTPUT MEAN PER VERB IS THE READER TABLE'S (reader_rule),
# not this function's: exit 1 is a legitimate zero only where the table says so
# (grep, test) and ERROR matcher-exit-1 elsewhere; status 5 is eval_free_run
# refusing a command that names no operand (no-operand:<verb>); and a count is read
# as the table's count column says -- grep's count flag, wc's first field, or lines.
#
# Prints "OK<TAB><count>" or "ERROR<TAB><reason>". Never returns non-zero.
# ---------------------------------------------------------------------------
count_from_output() {
  local cmd="$1" out="$2" rc="$3" t line count=0 why verb
  verb="${cmd#"${cmd%%[![:space:]]*}"}"; verb="${verb%%[[:space:]]*}"
  case "$rc" in ''|*[!0-9]*) printf 'ERROR\tnon-numeric-exit-status'; return 0 ;; esac
  if [ "$rc" -eq 4 ]; then
    why="$(reads_stdin_cmd "$cmd" || true)"
    printf 'ERROR\t%s' "${why:-matcher-exit-4}"; return 0
  fi
  if [ "$rc" -eq 5 ]; then printf 'ERROR\tno-operand:%s' "$verb"; return 0; fi
  # Exit 1 is a legitimate zero only for the verbs the reader table reads it so. KEPT ON
  # ONE LINE ON PURPOSE: the suite's mutation arm G19 M3 removes it by one substitution.
  if [ "$rc" -eq 1 ] && [ "$(reader_rule "$verb" exit1)" != zero ]; then printf 'ERROR\tmatcher-exit-1'; return 0; fi
  if [ "$rc" -ge 2 ]; then printf 'ERROR\tmatcher-exit-%s' "$rc"; return 0; fi
  # wc prints its count in its first field -- on its last line, the total, when it
  # names several files -- so its output lines are not its count. KEPT ON ONE LINE ON
  # PURPOSE: the suite's mutation arm G19 M6 removes it by one substitution.
  if [ "$(reader_rule "$verb" count)" = first-field ]; then t="${out##*$'\n'}"; t="${t#"${t%%[![:space:]]*}"}"; t="${t%%[[:space:]]*}"; case "$t" in ''|*[!0-9]*) printf 'ERROR\tnon-integer-count-field'; return 0 ;; esac; printf 'OK\t%s' "$t"; return 0; fi
  if count_mode_cmd "$cmd"; then
    while IFS= read -r line; do
      [ -n "$line" ] || continue
      t="${line##*:}"
      case "$t" in
        ''|*[!0-9]*) printf 'ERROR\tnon-integer-count-field'; return 0 ;;
      esac
      count=$(( count + t ))
    done <<<"$out"
    printf 'OK\t%s' "$count"
    return 0
  fi
  while IFS= read -r line; do
    [ -n "$line" ] && count=$(( count + 1 ))
  done <<<"$out"
  printf 'OK\t%s' "$count"
  return 0
}

# unreadable_observed <reason> — the ONE renderer for a count_from_output ERROR,
# shared by both handlers so the two cannot drift. A command that RAN and yielded
# no readable result keeps the matcher-outcome text. A command eval_free_run
# REFUSED before it ran is rendered as the refusal it is, naming the remedy: it
# never ran, so "the matcher produced no readable result" would be false, and
# what the author has to fix is the method, not a matcher. Keep each arm on one
# line: the suite's mutation arm reaches this rendering by one anchored
# substitution.
unreadable_observed() {
  case "$1" in
    stdin-reader:*)
      printf '%s (not run — the method names no input file inside its backticks, so the command would read stdin; a file named only in the prose is not read)' "$1" ;;
    device-operand:*)
      printf '%s (not run — a method reads repository files, and a path under /dev/ or /proc/ is a device or a descriptor)' "$1" ;;
    unmodelled-option:*)
      printf '%s (not run — the executor cannot tell whether this option takes the next word, so it cannot show that the command names an input file; use an option it models)' "$1" ;;
    no-operand:*)
      printf '%s (not run — the command names no operand its verb needs: grep a pattern, test an expression whose primary carries its operand, ls a path; name it inside the backticks)' "$1" ;;
    no-comparator:*)
      printf '%s (ran, but not graded — the method states no comparator, and for this command exit 0 says only that its input could be read, not that the claim holds; state a comparator such as expect N, or write the claim with grep or test)' "$1" ;;
    unterminated-quote:*)
      printf '%s (not run — the command has an unterminated quote, so it cannot be split into the words its author meant; close the quote inside the backticks)' "$1" ;;
    *)
      printf 'count-unreadable:%s (the matcher produced no readable result; this is NOT a zero)' "$1" ;;
  esac
}

# shell_operator_observed <operator> — the ONE rendering of the handlers' refusal of a
# designated command carrying a shell operator outside quotes, shared by both handlers
# and by the designated command of a multi-command method, so the three cannot drift.
# The operator is named as span_shell_operator prints it. That test reports a command
# substitution written either as `$(` or as a backtick as `$(`, and the reason says so
# rather than guessing which spelling the author used. An unterminated quote, which the
# same test reports by its quote character, never reaches here: shell_syntax_refusal
# reads it as input that could not be read.
shell_operator_observed() {
  case "$1" in
    '$(')
      printf 'shell-operator:%s (not run — a command substitution, written as $( or as a backtick: this executor runs no shell, so it would reach the command as a literal argument)' "$1" ;;
    *)
      printf 'shell-operator:%s (not run — this executor runs no shell, so a pipe, a list, a redirect or a substitution would reach the command as a literal argument; name one command, or use the declared-deferred form)' "$1" ;;
  esac
}

# shell_syntax_refusal <what span_shell_operator printed> — THE handlers' refusal of a
# designated command carrying shell syntax, printed "<verdict> TAB <observed>" for both
# handlers and for the designated command of a multi-command method, so the three give a
# reported span the same verdict. The shared predicate reports two different things, and
# they take two different outcomes of the partition:
#   - an operator outside quotes (a pipe, a list, a redirect, a substitution): the command
#     was read, and this executor runs no shell, so it cannot run here -- UNRUNNABLE,
#     shell-operator:<op>, which does not fail the run;
#   - an unterminated quote: the command cannot be split into the words its author
#     meant, which is input the executor could not read -- ERROR, unterminated-quote:<q>,
#     which fails the run like every other could-not-read row.
# The CIAC authoring lint flags each by the same token. The quote arm is KEPT ON ONE LINE
# ON PURPOSE: the suite's mutation arm G21 M6 turns it back into the can't-run reading by
# one substitution.
shell_syntax_refusal() {
  case "$1" in
    \'|\") printf '%s\t%s\n' "$VERDICT_ERROR" "$(unreadable_observed "unterminated-quote:$1")" ;;
    *) printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" "$(shell_operator_observed "$1")" ;;
  esac
}

# integration: run a Cross-Issue AC entry's declared method (SOLE runner — this
# executor is the sole runner of CIAC methods and the sole emitter of their
# verdicts; Stage-9 reads the emitted verdict read-only, never re-running it).
# $1 = full method text parsed from the CIAC entry (command + any ≥N threshold).
handle_integration() {
  local method="$1"
  # Read outside every span led by an allowlisted verb, as classify_family step 0
  # is: a phrase inside a command is its pattern, not a declaration.
  case "$(method_outside_verb_spans "$method")" in
    *DEFERRED*|*declared,\ verification\ deferred*|*deferred\ to\ #*)
      printf '%s\t%s\n' "$VERDICT_SKIP" "declared-deferred"; return ;;
  esac
  # A method naming two or more commands is graded on its designated command, and
  # every other command is named as not run (METHOD LIMBS).
  local limbs
  limbs="$(method_limbs "$method")"
  if limbs_are_multi "$limbs"; then grade_limbs "$limbs"; return; fi
  # A CIAC method is a reproducible command (grep / anchor) OR a prose
  # "confirm the recorded no-overlap decision" fallback.
  local cmd
  cmd="$(extract_command "$method")"
  if [ -z "$cmd" ]; then
    # No runnable command; the entry declares a documented-decision method.
    printf '%s\t%s\n' "$VERDICT_SKIP" "documented-decision-method (no runnable command)"; return
  fi
  local verb; verb="$(printf '%s' "$cmd" | awk '{print $1}')"
  if ! is_runnable_verb "$verb"; then
    handle_unrunnable "$method"; return
  fi
  # A designated command carrying shell syntax is not run (see handle_per_issue).
  local sop
  if sop="$(span_shell_operator "$cmd")"; then shell_syntax_refusal "$sop"; return; fi
  local out rc count threshold op want
  set +e
  out="$( cd "$REPO_ROOT" && eval_free_run "$cmd" 2>/dev/null )"
  rc=$?
  set -e
  threshold="$(extract_threshold "$method")"
  op="$(printf '%s' "$threshold" | cut -f1)"; want="$(printf '%s' "$threshold" | cut -f2)"
  # Same shared reader, same unconditional exit-status guard as handle_per_issue.
  # These two handlers each carried their own copy of the count expression, which
  # is how one defect came to ship twice; there is now one copy.
  local cres cstatus cval
  cres="$(count_from_output "$cmd" "$out" "$rc")"
  cstatus="$(printf '%s' "$cres" | cut -f1)"
  cval="$(printf '%s' "$cres" | cut -f2)"
  if [ "$cstatus" != "OK" ]; then
    printf '%s\t%s\n' "$VERDICT_ERROR" "$(unreadable_observed "$cval")"
    return
  fi
  if [ -n "$threshold" ]; then
    count="$cval"
    if [ "$(compare_threshold "$count" "$op" "$want")" = PASS ]; then
      printf '%s\t%s\n' "$VERDICT_PASS" "co-occurrence count=$count ($op $want)"
    else
      printf '%s\t%s\n' "$VERDICT_FAIL" "co-occurrence count=$count (wanted $op $want)"
    fi
    return
  fi
  # No threshold: the same reading as handle_per_issue -- exit 0 is a PASS only where
  # the reader table makes it the claim (exit_zero_grades).
  if [ "$rc" -ne 0 ]; then printf '%s\t%s\n' "$VERDICT_FAIL" "integration-method-exit-$rc"
  elif exit_zero_grades "$cmd"; then printf '%s\t%s\n' "$VERDICT_PASS" "integration-method-succeeded"
  else printf '%s\t%s\n' "$VERDICT_ERROR" "$(unreadable_observed "no-comparator:$verb")"; fi
}

# deploy_check_exit_code — run deploy --check AT MOST ONCE per executor invocation
# and PRINT its exit code (deploy --check is a heavy full-workspace validation; a
# plan that declares several sync/regression methods must not re-run it per row).
# The result is cached to DEPLOY_CHECK_CACHE (a per-run temp file set in main) so
# the memo survives the command-substitution subshells the handlers run in. It
# prints the code (rather than `return`ing it) so no non-zero return trips the
# caller's errexit; the function itself always succeeds. Changes no output
# contract — it only avoids redundant runs.
deploy_check_exit_code() {
  if [ -n "${DEPLOY_CHECK_CACHE:-}" ] && [ -s "$DEPLOY_CHECK_CACHE" ]; then
    cat "$DEPLOY_CHECK_CACHE"; return 0
  fi
  local rc=0
  ( cd "$REPO_ROOT" && bash "$DEPLOY_CHECK" --check ) >/dev/null 2>&1 || rc=$?
  if [ -n "${DEPLOY_CHECK_CACHE:-}" ]; then printf '%s' "$rc" > "$DEPLOY_CHECK_CACHE"; fi
  printf '%s' "$rc"
  return 0
}

# sync + regression: delegate to deploy --check (source<->deployed byte-diff), for a row
# whose command IS deploy.sh --check (classify_family).
# We do NOT re-implement diffing; the deploy check IS the sync/regression oracle.
# A declared row that ALSO names another command follows the partition's partial rule
# (command_list): when the check passes, the row reads the can't-run slot and names the
# command that did not run; when it fails, FAIL stands and the list still names it.
# $1 = family (sync | regression), $2 = method string.
handle_deploy_check() {
  local family="$1" method="${2:-}" rc verdict obs cmd cl n list T=$'\t'
  if [ ! -x "$DEPLOY_CHECK" ] && [ ! -f "$DEPLOY_CHECK" ]; then
    printf '%s\t%s\n' "$VERDICT_ERROR" "deploy.sh --check not found at $DEPLOY_CHECK"; return 0
  fi
  rc="$(deploy_check_exit_code)"
  # deploy --check exits 0 when source and deployed copies are in sync.
  if [ "$rc" -eq 0 ] 2>/dev/null; then
    verdict="$VERDICT_PASS"; obs="deploy --check clean (in-sync)"
  else
    verdict="$VERDICT_FAIL"; obs="deploy --check non-clean (exit $rc); ${family} — see deploy.sh --check output"
  fi
  n=0
  if [ -n "$method" ]; then
    cmd="$(extract_command "$method")"
    cl="$(command_list "$method" "$cmd" "$verdict $obs")"
    n="${cl%%"$T"*}"; list="${cl#*"$T"}"
  fi
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G18 M9 removes the partial
  # rule by one substitution.
  if [ -n "$method" ] && [ "$n" -ge 2 ]; then
    if [ "$verdict" = "$VERDICT_PASS" ]; then
      printf '%s\t%s\n' "$VERDICT_PARTIAL_SLOT" "partial-execution: limbs run 1 of $n: $list — a command that did not run is not a pass"
    else
      printf '%s\t%s\n' "$verdict" "limbs run 1 of $n: $list"
    fi
    return 0
  fi
  printf '%s\t%s\n' "$verdict" "$obs"
  return 0
}

# resolve_plan_release_key <plan-file> — the release JOIN KEY for this plan.
#
# The key is the milestone SLUG (pipeline-event-log-schema.md § 2a); the shipped
# vX.Y is NOT a key and the event writer rejects it. Resolution order:
#   1. the plan's `**Milestone:** \`<slug>\`` line — authoritative when present
#   2. the plan FILENAME stem, when the plan is still slug-named (pre-claim,
#      `<slug>_RELEASE_PLAN.md`); a claim-time-renamed `vX.Y_RELEASE_PLAN.md`
#      stem is a version, so it is rejected here rather than passed through
#   3. the reserved `(none)` sentinel — never a synthesized placeholder version
resolve_plan_release_key() {
  local plan="$1" key=""
  key="$(grep -m1 -E '^\*\*Milestone:\*\*' "$plan" 2>/dev/null \
         | sed -n 's/^\*\*Milestone:\*\*[[:space:]]*`\([^`]*\)`.*/\1/p')"
  if [ -z "$key" ]; then
    key="$(basename "$plan" | sed -n 's/^\(.*\)_RELEASE_PLAN\.md$/\1/p')"
    # A version-shaped stem is not a key. Match the canonical grammar shape
    # (version-grammar.sh); anything matching it is discarded, not emitted.
    case "$key" in
      v[0-9]*.[0-9]*) printf '%s' "(none)"; return 0 ;;
    esac
  fi
  # A `{{...}}` token means the plan is still holding an unresolved provisional
  # display version — not a key either.
  case "$key" in
    ''|*'{{'*|*'}}'*) printf '%s' "(none)"; return 0 ;;
  esac
  printf '%s' "$key"
}

# runtime-suite: emit a test-run event through the pipeline-event writer.
# Under the map, a check whose deliverable path is unmapped is an honest
# suite-skip. We do not run suites in a novel way; we invoke the same event
# path Engineering self-verification + Dev Testing already use.
#
# THIS FAMILY CANNOT RETURN PASS, AND THAT IS THE CONTRACT.
#
# It performs NO execution. Its only bash invocation is the
# append-pipeline-event emit. It used to take its verdict from a `case` over
# the METHOD TEXT whose catch-all arm assigned `suite-pass` -> VERDICT_PASS,
# so any method not literally carrying a fail-word was reported PASS having
# run nothing. A plan author writing "exercise the suite" earned a green
# verdict for free, and the same words also STOLE the row from the per-issue
# family that would have executed it (see classify_family above).
#
# Giving it a real execution path was considered and REJECTED on two
# independent grounds:
#   (1) it would need `bash` / `python3` in RUNNABLE_VERBS, which breaches the
#       trust boundary stated at that constant - a verification harness driven
#       by an authored artifact must not acquire a code-execution channel; and
#   (2) runtime-suite-selection-map.md keys suite selection on the CHANGED
#       PATH, not on method text, so a method string is structurally the wrong
#       selector, and every runner in that map is a verb this executor refuses
#       by design.
#
# So the verdict is FLOORED. An author recording a KNOWN failure can still
# fail; every other route is a named SKIP citing the map and the gate that
# does own execution. VERDICT_PASS does not appear in this function body, and
# that absence is the mechanically checkable form of "cannot return PASS
# without an executed check".
# $1 = method string, $2 = release join key (slug, for the event --version).
handle_runtime_suite() {
  local method="$1" version="$2" subtype outcome
  # A declared failure stays failable; every other route is an honest no-op.
  case "$method" in
    *suite-fail*|*FAIL*) subtype="suite-fail"; outcome="escalated" ;;
    *)                   subtype="suite-skip"; outcome="resolved" ;;
  esac
  if [ "$ARG_EMIT_EVENTS" -eq 1 ]; then
    if [ ! -x "$EVENT_WRITER" ] && [ ! -f "$EVENT_WRITER" ]; then
      printf '%s\t%s\n' "$VERDICT_ERROR" "append-pipeline-event.sh not found at $EVENT_WRITER"; return
    fi
    set +e
    ( cd "$REPO_ROOT" && bash "$EVENT_WRITER" \
        --version "${version:-(none)}" --stage 6 \
        --event-type test-run --event-subtype "$subtype" \
        --actor "skill:verify-release-plan" --subject "release-plan:verification" \
        --reversibility CHEAP --outcome "$outcome" \
        --payload "runtime-suite family dispatch via verify-release-plan.sh" ) >/dev/null 2>&1
    local rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then printf '%s\t%s\n' "$VERDICT_ERROR" "test-run emit failed (exit $rc)"; return; fi
  fi
  case "$subtype" in
    suite-fail) printf '%s\t%s\n' "$VERDICT_FAIL" "test-run/$subtype" ;;
    # KEPT ON ONE LINE ON PURPOSE: the suite mutation arm raises this floor
    # by a single anchored substitution, and a line-based mutator cannot
    # reach a verdict split across a continuation.
    *)          printf '%s\t%s\n' "$VERDICT_SKIP" "test-run/$subtype (not executed here: runtime-suite selection is keyed on changed path, not method text; execution belongs to Stage 6 C4 / Stage 7 Phase A8)" ;;
  esac
}

# unrunnable: THE one decline point. A row whose command is a recognised tool
# outside RUNNABLE_VERBS reaches here from three routes -- the classifier's residual
# step, and the verb check in handle_per_issue and in handle_integration -- and all
# three emit the same verdict and the same reason, so the three cannot drift. The
# tool is named from the command span (span_invokes_tool: a catalogued tool, or a
# script's basename), never from a label, a file name or a word the method only
# mentions. The reason token is the one the refusal carried when it read SKIP, so a
# reader that matches the reason still matches it; only the verdict changed. A cross-
# issue method whose command is a native scope assertion is graded here rather than
# declined: that method never passes through the classifier, so this is where it
# meets the scope family.
# $1 = method string.
handle_unrunnable() {
  local method="$1" cmd tool
  cmd="$(extract_command "$method")"
  if [ -n "$cmd" ] && scope_spec_of "$cmd" "$method" >/dev/null; then
    handle_scope "$method"; return
  fi
  tool="$(span_invokes_tool "$cmd" whole)"
  if [ -z "$tool" ]; then
    printf '%s\t%s\n' "$VERDICT_ERROR" "decline-without-tool (internal inconsistency: a declined row names no tool the method invokes)"
    return
  fi
  # KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G17 M2 turns the verdict back
  # to SKIP by one anchored substitution, and a line-based mutator cannot reach a verdict
  # split across a continuation.
  printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" "tool-invocation-outside-executor-allowlist:$tool (not executed here; its mechanical guarantee belongs in that tool's own self-test)"
}

# Dispatch: family -> handler. Fail loud on a family no handler owns: classify_family's
# residual always names one, so reaching the `*)` arm is an internal inconsistency, never
# an unreadable row.
dispatch_check() {
  local family="$1" method="$2" expected="$3" version="$4"
  case "$family" in
    deferred)       printf '%s\t%s\n' "$VERDICT_SKIP" "declared-deferred" ;;
    # A row the parser REFUSED to index. It is an ERROR and never a SKIP: a skip
    # says "nothing to assert here", whereas this row declares a check that
    # cannot be read. Carrying the field counts makes it attributable.
    parity-error)   printf '%s\t%s\n' "$VERDICT_ERROR" \
                      "table-row-field-parity ($expected) — row does not carry its header's field count after escape healing; an unescaped bare pipe makes every cell past the break read at a shifted index" ;;
    # A TABLE the parser refused to index: its header declares verification
    # content (it names AC, Expected or Predicate) but resolves no method
    # column, so every row beneath it was dropped. ONE record per block,
    # carrying the header verbatim so the author sees which column is missing.
    table-unindexable)
                    printf '%s\t%s\n' "$VERDICT_ERROR" \
                      "verification-table-unindexable ($expected) — the header declares verification content but names no method column, so its rows cannot be graded: $method" ;;
    # A ROW inside an indexed table whose Method cell is empty. Same doctrine,
    # one level down: a check with no method to run is unreadable, not absent.
    method-cell-empty)
                    printf '%s\t%s\n' "$VERDICT_ERROR" \
                      "method-cell-empty ($expected) — the row declares a check and names no method to run it: $method" ;;
    per-issue)      handle_per_issue "$method" "$expected" ;;
    scope)          handle_scope "$method" ;;
    unrunnable)     handle_unrunnable "$method" ;;
    integration)    handle_integration "$method" ;;
    sync)           handle_deploy_check "sync" "$method" ;;
    regression)     handle_deploy_check "regression" "$method" ;;
    runtime-suite)  handle_runtime_suite "$method" "$version" ;;
    *)              printf '%s\t%s\n' "$VERDICT_ERROR" "unknown-family:$family (internal inconsistency: the classifier returned a family no handler owns)" ;;
  esac
}

# ===========================================================================
# Component 1b — parse the Cross-Issue Acceptance Criteria section into
# integration check records. Reads the release plan's landed Cross-Issue
# Acceptance Criteria section VERBATIM (this script defines no schema of its own).
#
# Two authored shapes are tolerated:
#   (i)  the canonical scaffold bullet:
#          - [ ] **CIAC-N (#X × #Y on `<surface>`):** <predicate>. *Method:* `<cmd>`.
#   (ii) a table row form (Identifier | ... | Method | ...) as some plans author.
# Emits TAB-separated: ciac_id \t issues \t family(integration) \t method \t predicate
# ===========================================================================
parse_ciac() {
  local file="$1" body
  # _extract_section prefix-matches the heading, so a parenthetical suffix
  # ("Cross-Issue Acceptance Criteria (dog-food …)") still resolves.
  body="$(_extract_section "$file" "Cross-Issue Acceptance Criteria")"
  if [ -z "$body" ]; then return 0; fi

  # (i) scaffold-bullet form.
  printf '%s\n' "$body" | awk -v RFS="$REC_FS" '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function rec(a, b, c, d, e) {
      printf "%s%s%s%s%s%s%s%s%s\n", a, RFS, b, RFS, c, RFS, d, RFS, e
    }
    /\*\*CIAC-[0-9]+/ {
      line = $0
      # id
      match(line, /CIAC-[0-9]+/); id = substr(line, RSTART, RLENGTH)
      # issues spanned: capture the #N tokens inside the parenthetical head only
      # (the text up to the ")**" that closes the CIAC identifier), de-duplicated,
      # so #N tokens repeated in the predicate prose do not double-count.
      head = line
      hp = index(head, ")**")
      if (hp > 0) head = substr(head, 1, hp)
      issues = ""
      delete seen_iss
      tmp = head
      while (match(tmp, /#[0-9]+/)) {
        tok = substr(tmp, RSTART, RLENGTH)
        if (!(tok in seen_iss)) { seen_iss[tok] = 1; issues = issues (issues=="" ? "" : ",") tok }
        tmp = substr(tmp, RSTART+RLENGTH)
      }
      # method: capture the FULL clause after *Method:* — backticked command
      # PLUS any trailing "≥ N" threshold that sits outside the backticks — so
      # the shell command/threshold extractors see both. Fall back to the first
      # backticked span on the line if there is no *Method:* marker.
      method = ""
      mstart = 0
      if (match(line, /[Mm]ethod:?\*{0,2}[ ]*/)) {
        mstart = RSTART + RLENGTH
        rest = substr(line, mstart)
        # Trim at the *Graded …* clause marker if present, else at end of line.
        gi = index(rest, "*Graded")
        if (gi > 0) rest = substr(rest, 1, gi - 1)
        method = trim(rest)
        # Drop a trailing period left after trimming the Graded clause.
        sub(/\.[ ]*$/, "", method)
      } else if (match(line, /`[^`]*`/)) {
        method = substr(line, RSTART, RLENGTH)   # keep the backticks
      }
      # DO NOT RESOLVE THE PIPE ESCAPE HERE, and this is load-bearing rather
      # than an omission. The escape is resolved by the SPLITTER, at exactly the
      # point where a split created it — never on a string that was never split.
      #
      # This form is LINE-BASED: a bullet is never divided on pipes, so a `\|`
      # inside it was never a markdown escape. It is verbatim matcher syntax and
      # it belongs to the matcher. Resolving it here was drafted, implemented,
      # and then falsified by measurement against the live corpus: of the 5 CIAC
      # bullet methods carrying `\|`, 4 are BRE patterns (`grep -n "a\|b"`) in
      # which `\|` IS the alternation operator, and the 5th is an ERE pattern
      # deliberately matching a LITERAL pipe (it searches for a shell pipeline).
      # All 5 are correct as authored; a blanket substitution broke all 5, and
      # turned three passing cross-issue criteria on a real plan into failures.
      #
      # The table forms are the opposite case and are healed, correctly: a cell
      # IS split on pipes, so an author who needs a literal pipe there has no
      # choice but to escape it, and the escape is unambiguously markdown.
      # predicate: strip the leading list-marker for a short text.
      pred = line
      sub(/^[-*[ \]]*/, "", pred)
      rec(id, issues, "integration", method, trim(pred))
    }
  '

  # (ii) table-row form: rows whose first cell contains CIAC-N with a Method cell.
  printf '%s\n' "$body" | awk -v RFS="$REC_FS" "$AWK_HEAL_FIELDS"'
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    function rec(a, b, c, d, e) {
      printf "%s%s%s%s%s%s%s%s%s\n", a, RFS, b, RFS, c, RFS, d, RFS, e
    }
    BEGIN { col_method = 0; col_pred = 0; have_header = 0; hdr_n = 0 }
    # Per-table-block reset, for the same reason as parse_verification_plan: a
    # column map that outlives its table indexes later rows against a header
    # that is not theirs.
    !/^[ \t]*\|/ { col_method = 0; col_pred = 0; hdr_n = 0; next }
    {
      # Heal escape-split cells BEFORE any column is read (see AWK_HEAL_FIELDS).
      n = heal_fields($0, F)
      is_header = 0
      for (i=1;i<=n;i++){ c = lc(trim(F[i])); if (c ~ /method/){ col_method = i; is_header=1 } ; if (c ~ /predicate/){ col_pred = i; is_header=1 } }
      if (is_header) { have_header = 1; hdr_n = n; next }
      if ($0 ~ /^[ \t]*\|[ \t:-]+\|/ && $0 ~ /-/) { s=$0; gsub(/[ \t|:-]/,"",s); if (s=="") next }
      # Only treat as CIAC table if a cell names CIAC-N.
      rowline = $0
      if (rowline !~ /CIAC-[0-9]+/) next
      if (col_method == 0) next
      match(rowline, /CIAC-[0-9]+/); id = substr(rowline, RSTART, RLENGTH)
      # HEADER/ROW FIELD-PARITY GUARD — same contract as the Verification-Plan
      # parser. A CIAC row still off its header count after healing carries an
      # unescaped bare pipe; grading it at shifted indices would run whatever
      # fragment landed in the method slot and report the result as a
      # cross-issue verdict. Name the row and ERROR instead.
      if (hdr_n > 0 && n != hdr_n) {
        rec(id, "", "parity-error", trim(substr(rowline, 1, 160)), ("fields=" n " header=" hdr_n))
        next
      }
      issues = ""
      tmp = rowline
      while (match(tmp, /#[0-9]+/)) { issues = issues (issues==""?"":",") substr(tmp,RSTART,RLENGTH); tmp = substr(tmp,RSTART+RLENGTH) }
      method = (col_method<=n)? trim(F[col_method]) : ""
      pred   = (col_pred>0 && col_pred<=n)? trim(F[col_pred]) : ""
      # Pull a backticked command out of the method cell if present.
      m2 = method
      if (match(method, /`[^`]*`/)) { m2 = substr(method, RSTART+1, RLENGTH-2) }
      rec(id, issues, "integration", m2, pred)
    }
  ' | awk -F"$REC_FS" '!seen[$1]++'   # de-dupe: bullet form wins if both matched an id.
  # The -F is LOAD-BEARING, not decoration. This de-dupe keys on $1, and with a
  # tab delimiter it worked only because tab is awk default whitespace. 0x1F is
  # not whitespace, so without -F the key would run to the first SPACE inside
  # the record and the de-dupe would silently stop de-duplicating.
}

# ===========================================================================
# Component 1c — the CIAC authoring lint (--ciac-lint): Stage 4, gate criterion G4-06.
#
# WHY IT EXISTS. This executor is the sole runner of every CIAC method, and Stage 9 reads
# what it emits without running anything. A CIAC this executor cannot grade as written is
# therefore graded by no permitted party, and that used to surface at Stage 9, as a NO-GO
# input on a release whose predicates held. The lint moves the discovery to authoring: it
# reads each CIAC exactly as grading will and names the ones the grader will not grade as
# written.
#
# ITS CLEAN IS THE GRADER'S, STOPPING BEFORE EXECUTION. It reads the section through
# parse_ciac, the grading path's parser, then walks handle_integration's order: the
# declared deferral, read outside every span led by an allowlisted verb
# (method_outside_verb_spans); the command limbs (method_limbs); the designated command
# (extract_command, over method_spans, the one splitter, so a span no backtick closes is
# prose here too); the verb check; span_shell_operator, the shared predicate, with the
# handlers' reading of an operator and of an unterminated quote; reads_stdin_cmd and
# names_no_operand, eval_free_run's two refusals; and the comparator the grader will
# apply (limb_comparator, extract_threshold, count_mode_cmd and exit_zero_grades, over the
# one comparator vocabulary). It stops there: it runs no command, reads no deploy check,
# writes no event and emits no Verification Evidence record. A CIAC it reads CLEAN is one
# the grader grades as written, and each flag is the first the grading path would meet.
#
# A DECLARATION NAMES WHERE ITS GUARANTEE LIVES. A CIAC no command can grade is written in
# the declared form, "declared, verification deferred to <evidence>", and the Stage 9
# operator grades it from that evidence. The lint requires the declaration to name an
# evidence surface: a repository path, a suite arm label, or a namespace-qualified
# criterion -- one for each issue the CIAC spans, because one issue's criterion cannot
# vouch for a predicate over several. A path or an arm label covers the release.
#
# The id scan is deliberately independent of parse_ciac, so an entry the grading parser
# never reads is flagged rather than silently absent, and the lint prints the ids the plan
# declares: a Stage 9 reader needs that set to tell "no CIAC declared" from "no record
# emitted".
# ===========================================================================

# _ciac_lint_say <status> <flag> -- one lint reading, "<status> TAB <flag>".
_ciac_lint_say() { printf '%s\t%s' "$1" "$2"; }

# _ciac_lint_entry <entry> -- the parser hazard a bullet entry's own line carries, or
# nothing. parse_ciac opens the Method clause at the FIRST "method" word on the line, so a
# word ahead of the marker displaces the clause, and an entry with no marker is read from
# its first backticked span. A table row (an entry that is not the bullet's own line) has
# its Method column and carries neither hazard.
_ciac_lint_entry() {
  local a m
  case "$1" in CIAC-[0-9]*) ;; *) return 0 ;; esac
  a="$(awk '{ print (match($0, /[Mm]ethod/) ? RSTART : 0) }' <<<"$1")"
  m="$(awk '{ print (match($0, /[Mm]ethod[*_]*:/) ? RSTART : 0) }' <<<"$1")"
  if [ "$m" -eq 0 ]; then printf 'method-marker-absent'; elif [ "$a" -lt "$m" ]; then printf 'method-clause-displaced'; fi
  return 0
}

# _ciac_lint_evidence <declaration> <issues> -- the flag a declaration earns, or nothing
# when it names an evidence surface. <declaration> is the text after the declared form's
# phrase; <issues> is the comma list of the issues the CIAC spans, as parse_ciac read it.
# A repository path or a suite arm label covers the release. A namespace-qualified
# criterion -- #N AC-k, design #N AC-k, design #N INT-k, plan #N AC-k -- is one issue's
# evidence, so it covers the CIAC only when one is named for each spanned issue. The
# per-issue test is KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G21 M7 removes it
# by one substitution.
_ciac_lint_evidence() {
  local decl="$1" issues="$2" named iss miss="" NL=$'\n'
  local re_path='[A-Za-z0-9_.-]+/[A-Za-z0-9_./-]*\.[A-Za-z0-9]+' re_arm='V[0-9]+-[A-Z]+[0-9]+'
  if [[ "$decl" =~ $re_path ]] || [[ "$decl" =~ $re_arm ]]; then return 0; fi
  named="$(grep -oE '#[0-9]+ (AC|INT)-[0-9]+' <<<"$decl" || true)"
  if [ -z "$named" ]; then printf 'declared-without-evidence'; return 0; fi
  named="$NL$(awk '{ print $1 }' <<<"$named")$NL"
  for iss in ${issues//,/ }; do case "$named" in *"$NL$iss$NL"*) : ;; *) miss="$miss,$iss" ;; esac; done
  [ -z "$miss" ] || { printf 'evidence-misses-spanned-issue:%s' "${miss#,}"; return 0; }
}

# _ciac_lint_one <method> <entry> <issues> -- "<status> TAB <flag>" for one parsed CIAC:
# CLEAN, DECLARED, or FLAG naming the first rule the grading path would meet. Each rule's
# line reads the reader the grader reads. Three are KEPT ON ONE LINE ON PURPOSE: the
# suite's mutation arms G21 M1 (the verb check), M3 (the deferral read) and M4 (the count
# with no comparator) each reach one of them by one substitution.
_ciac_lint_one() {
  local method="$1" entry="$2" issues="$3" hz outside decl ev limbs cmd spans lead tool specs syn why p rs=0 NL=$'\n'
  if [ -z "${method//[[:space:]]/}" ]; then _ciac_lint_say FLAG no-method; return 0; fi
  hz="$(_ciac_lint_entry "$entry")"
  if [ -n "$hz" ]; then _ciac_lint_say FLAG "$hz"; return 0; fi
  outside="$(method_outside_verb_spans "$method")"
  case "$outside" in
    *DEFERRED*|*declared,\ verification\ deferred*|*deferred\ to\ #*)
      case "$outside" in
        *"declared, verification deferred to"*) decl="${outside#*declared, verification deferred to}" ;;
        *DEFERRED*) decl="${outside#*DEFERRED}"; decl="${decl%%]*}" ;;
        *"deferred to #"*) decl="#${outside#*deferred to #}" ;;
        *) decl="" ;;
      esac
      ev="$(_ciac_lint_evidence "$decl" "$issues")"
      if [ -n "$ev" ]; then _ciac_lint_say FLAG "$ev"; else _ciac_lint_say DECLARED -; fi
      return 0 ;;
  esac
  limbs="$(method_limbs "$method")"
  if limbs_are_multi "$limbs"; then _ciac_lint_say FLAG multi-limb; return 0; fi
  cmd="$(extract_command "$method")"; spans="$(method_spans "$method")"
  if [ -z "$cmd" ]; then
    p="$(awk -F'\t' '$2 == "bare-verb" { print $3 }' <<<"$spans")"; p="${p%%"$NL"*}"
    if [ -n "$p" ]; then _ciac_lint_say FLAG "bare-verb:$p"; else _ciac_lint_say FLAG no-runnable-command; fi
    return 0
  fi
  # A bullet whose method carries no span has its command read from the clause's own words
  # (extract_command's bare-string reading, which a table cell stripped of its backticks
  # needs): the grader runs those words.
  case "$entry" in CIAC-[0-9]*) if [ -z "$spans" ]; then _ciac_lint_say FLAG unbackticked-command; return 0; fi ;; esac
  lead="${cmd#"${cmd%%[![:space:]]*}"}"; lead="${lead%%[[:space:]]*}"
  if ! is_runnable_verb "$lead"; then
    if specs="$(scope_spec_of "$cmd" "$method")"; then
      case "$NL$specs" in *"$NL?"*) p="$NL$specs"; p="${p#*"$NL?"}"; _ciac_lint_say FLAG "scope-pathspec-placeholder:${p%%"$NL"*}"; return 0 ;; esac
      if [ "$(limb_comparator "$method")" = ambiguous ]; then _ciac_lint_say FLAG multi-comparator; return 0; fi
      _ciac_lint_say CLEAN -; return 0
    fi
    tool="$(span_invokes_tool "$cmd" whole)"
    _ciac_lint_say FLAG "not-runnable:${tool:-$lead}"; return 0
  fi
  if syn="$(span_shell_operator "$cmd")"; then
    case "$syn" in \'|\") _ciac_lint_say FLAG "unterminated-quote:$syn" ;; *) _ciac_lint_say FLAG "shell-operator:$syn" ;; esac
    return 0
  fi
  why="$(reads_stdin_cmd "$cmd")" || rs=$?
  if [ "$rs" -eq 0 ] || [ "$rs" -eq 2 ]; then _ciac_lint_say FLAG "$why"; return 0; fi
  if names_no_operand "$cmd"; then _ciac_lint_say FLAG "no-operand:$lead"; return 0; fi
  if [ "$(limb_comparator "$method")" = ambiguous ]; then _ciac_lint_say FLAG multi-comparator; return 0; fi
  if [ -z "$(extract_threshold "$method")" ]; then
    if count_mode_cmd "$cmd"; then _ciac_lint_say FLAG "no-threshold:$lead"; return 0; fi
    if ! exit_zero_grades "$cmd"; then _ciac_lint_say FLAG "no-comparator:$lead"; return 0; fi
  fi
  _ciac_lint_say CLEAN -
}

# ciac_lint <plan> -- the mode's entry point: one CIAC-LINT line per CIAC, the plan's
# declared set, and the summary. Returns 0 when no CIAC is flagged. The declared-id scan's
# print is KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G21 M2 blanks it by one
# substitution. Both loops take the FD-0 body form.
ciac_lint() {
  local file="$1" body declared records parsed ids id issues fam method entry res status flag idset=""
  local n_decl=0 n_parsed=0 n_clean=0 n_decld=0 n_flag=0 NL=$'\n' T=$'\t'
  body="$(_extract_section "$file" "Cross-Issue Acceptance Criteria")"
  declared="$(printf '%s\n' "$body" | awk '{ s = $0; sub(/^[ \t]*[-*+][ \t]+/, "", s); sub(/^\[[ xX]\][ \t]+/, "", s); sub(/^\|[ \t]*/, "", s); sub(/^[*_ \t]+/, "", s)
      if (match(s, /^CIAC-[0-9]+/)) print substr(s, RSTART, RLENGTH) }')"
  records="$(parse_ciac "$file" || true)"
  parsed="$(printf '%s\n' "$records" | awk -F"$REC_FS" 'NF { print $1 }')"
  ids="$(printf '%s\n%s\n' "$declared" "$parsed" | awk 'NF' | sort -t- -k2,2n -u)"
  while IFS= read -r id; do {
    [ -n "$id" ] || continue
    n_decl=$((n_decl + 1)); idset="${idset:+$idset }$id"
    case "$NL$parsed$NL" in
      *"$NL$id$NL"*) : ;;
      *) printf 'CIAC-LINT\t%s\tFLAG\tciac-unparsed\n' "$id"; n_flag=$((n_flag + 1)) ;;
    esac
  } </dev/null; done <<< "$ids"
  if [ -n "$records" ]; then
    while IFS="$REC_FS" read -r id issues fam method entry; do {
      [ -n "$id" ] || continue
      n_parsed=$((n_parsed + 1))
      if [ "$fam" = parity-error ]; then res="FLAG${T}parity-error"
      else res="$(_ciac_lint_one "$method" "$entry" "$issues")"; fi
      status="${res%%"$T"*}"; flag="${res#*"$T"}"
      case "$status" in
        CLEAN)    n_clean=$((n_clean + 1)) ;;
        DECLARED) n_decld=$((n_decld + 1)) ;;
        *)        n_flag=$((n_flag + 1)) ;;
      esac
      printf 'CIAC-LINT\t%s\t%s\t%s\n' "$id" "$status" "$flag"
    } </dev/null; done <<< "$records"
  fi
  printf 'CIAC-LINT-SET\t%s\n' "${idset:--}"
  printf 'CIAC-LINT-SUMMARY\tdeclared=%s\tparsed=%s\tclean=%s\tdeclared-deferral=%s\tflagged=%s\n' \
    "$n_decl" "$n_parsed" "$n_clean" "$n_decld" "$n_flag"
  [ "$n_flag" -eq 0 ]
}

# ===========================================================================
# Component 6 — fcm-delivery: the plan's declared File Change Matrix ADDs
# reconciled against the diff that actually merged.
#
# WHY THIS EXISTS. Scope-boundary verification in this pipeline was
# ONE-DIRECTIONAL: Stage 7 DT and Stage 8 QA both ask whether anything OUTSIDE
# the approved matrix was touched, and neither asks whether everything INSIDE it
# landed. A scope-lock-approved ADR therefore vanished between Collective Review
# and merge (v4.03, `2adf533e`) with five verification stages, two operator gates
# and ten review reports passing over it. This family closes the inbound
# direction. The outbound direction ("every delivered add is declared") is a
# real and separate gap and is deliberately NOT solved here.
#
# THE DOMINANT DEFECT CLASS THIS FAMILY MUST NOT REPRODUCE: an unparseable,
# absent, empty or truncated matrix must NEVER read as "no declared ADDs,
# therefore no violations". Every unreadable state below is ERROR or a NAMED
# SKIP carrying its own denominator — never a silent PASS, and never silence.
# ===========================================================================

# --- Extraction -------------------------------------------------------------
#
# _extract_section (:238) is FENCE-BLIND: its `/^#+ /` awk rule fires on any line
# beginning `#`+space, including a `# ── label ──` comment INSIDE a fenced block,
# which terminates the section early. Measured over the 165-file plan corpus:
# 26 of the 117 FCM-bearing plans truncate that way, losing every declaration row
# after the first in-fence comment.
#
# The shared seam is deliberately NOT widened. Making `_extract_section` itself
# fence-aware was measured against both of its live consumers first, and it
# REGRESSES one: `v4.14_RELEASE_PLAN.md` gains 39 spurious `parse_verification_plan`
# records (32 -> 70) because its Verification Plan section carries an in-fence `#`
# line, and the newly-visible prose tables parse as check rows. Trading a silent
# truncation in one family for spurious dispatched checks in another is not a fix.
# So the FCM path gets its own extractor and the shared seam is left byte-identical.
# The `_extract_section` fence-blindness remains a real defect for the other two
# families; it is routed out, not absorbed here.
#
# Fence state is scoped to the SECTION (reset on entry), so a fence opened earlier
# in the file cannot leak in and suppress the terminating heading.
_extract_fcm_section() {
  # $1 = plan file. Prints the File Change Matrix section body.
  local file="$1"
  awk -v want="File Change Matrix" '
    function hlevel(s,   k) { k = 0; while (substr(s, k+1, 1) == "#") k++; return k }
    BEGIN { insec = 0; want_level = 0; want_len = length(want); infence = 0 }
    /^[ \t]*(```|~~~)/ { if (insec == 1) { infence = 1 - infence; print }; next }
    (insec == 0 || infence == 0) && /^#+ / {
      line = $0
      lvl = hlevel(line)
      sub(/^#+[ ]+/, "", line)
      if (insec == 1 && lvl <= want_level) { insec = 0 }
      if (insec == 0 && substr(line, 1, want_len) == want) { insec = 1; want_level = lvl; infence = 0; next }
    }
    insec == 1 { print }
  ' "$file"
}

# Extraction-completeness assertion (PV-3: show the bytes the probe read were not
# truncated). An ODD number of fence markers in the extracted body means a fence
# opened and never closed inside the section — the body is provably incomplete.
# Measured on the corpus this predicate is EXACT: it fires on all 26 truncated
# sections under the fence-blind extractor and on 0 of the other 91 (no misses,
# no false positives), and on 0 of 117 under the extractor above. It is retained
# as a belt-and-suspenders guard so a future authoring shape that defeats the
# fence tracker surfaces as an ERROR rather than as a short, confident row set.
_fcm_body_truncated() {
  # stdin = section body. Exit 0 when the body is UNBALANCED (i.e. truncated).
  awk '
    /^[ \t]*(```|~~~)/ { n++ }
    END { exit (n % 2 == 0) }
  '
}

# --- Declaration parsing ----------------------------------------------------
#
# Emits TAB records:  path \t intent \t conditionality \t source_form \t raw_line
#
# intent        add | edit | delete | rename | read | excluded | unknown | malformed
# conditionality  uncond | cond
# source_form   fence-verb-first | fence-path-first | fence-bare | table | table-pathless
#               A row whose winning verb token is not the FIRST token of its
#               declaration carries the suffix ` prose-led`. It is a
#               DISCLOSURE, not a verdict: the intent is still believed, and
#               the coverage record counts how many rows were read that way.
#
# `unknown` is the deliberate divergence from `bundle-issues-parser.py:218`, which
# defaults a marker-less path to `edit`. That default is safe on an issue body (a
# wrong guess costs one spurious GENERATES edge) and unsafe here, where it would
# convert "intent was never declared" into "no ADDs were declared, therefore no
# violations" — verbatim the vacuity this family exists to close. Same enum,
# different default, and the difference is the whole point. `unknown` rows are
# COUNTED and REPORTED (see the coverage record) rather than silently dropped:
# 962 of the 2,047 declaration rows in the corpus are bare, so dropping them
# silently would be a 47% blind spot presented as full coverage.
parse_fcm_declarations() {
  local body="$1"
  printf '%s\n' "$body" | awk '
    function trim(s){ gsub(/^[ \t]+|[ \t]+$/,"",s); return s }
    function lc(s){ return tolower(s) }
    # FIRST-SEGMENT ENUM. This is a CLOSED list of top-level repository segments,
    # and every omission from it used to be invisible: a row whose first segment is
    # absent here returned "" and left the population BEFORE classification, so it
    # was counted as neither interpreted nor uninterpreted and the coverage record
    # reported full coverage over a short denominator.
    #
    # `operations` was the omission that surfaced it. It is a top-level MODULE of
    # this repository, peer to core / release / docs / packages, and it was never in
    # the list: measured over the 189-plan corpus, 286 declaration rows across 47
    # plans were dropped for that single missing word, including all 7 artifact-shape
    # ADDs of the release whose checker run exposed it (which reported
    # `uninterpreted=0 pathless=0` and FCM-COVERAGE PASS while asserting 2 of 9
    # declared ADDs).
    #
    # ADDING THE WORD IS THE SMALLER HALF OF THE FIX. The drop-to-nowhere behaviour
    # is the reusable defect, and it is closed at the fence arm below, which now
    # routes an unrecognised row into the uninterpreted count instead of discarding
    # it. That is what makes the NEXT omission from this enum a visible non-PASS
    # rather than a silent one, so this list no longer has to be complete to be safe.
    function pathof(s,   t) {
      if (!match(s, /(core|operations|release|docs|packages|projects|roadmaps|\.github|\.claude)\/[^ \t`|,;()]+/)) return ""
      t = substr(s, RSTART, RLENGTH)
      sub(/\*\*$/, "", t); sub(/[.,;:]+$/, "", t); sub(/`+$/, "", t)
      return t
    }
    # A declared path is a COMPARISON KEY only — never interpolated into a command.
    # A row carrying a traversal, an absolute root or a shell metacharacter is
    # reported as malformed rather than normalized into something runnable.
    # `<` and `>` are NOT metacharacters here: the corpus authors placeholder
    # segments as `<slug>`, and rejecting them would classify the single most
    # important row in the originating specimen as malformed. They are safe
    # because a declared path is only ever a `case` glob key and a string compare,
    # never a token in a command line.
    function malformed(p) {
      if (p ~ /\.\./) return 1
      if (substr(p,1,1) == "/") return 1
      if (p ~ /[;&$()]/) return 1
      return 0
    }
    # INTENT IS DECLARED, NOT INFERRED.
    #
    # verbof used to ask "which of these words appears ANYWHERE in the row",
    # resolved by a fixed enum order, and BOTH failure directions were live in
    # the corpus. They are opposites:
    #
    #   EDIT  release/tools/verify-release-plan.sh  # add a new dispatch arm
    #     ADD was tested before EDIT, so a declared EDIT became an
    #     unconditional ADD obligation. The file pre-exists, so the family
    #     emitted FAIL "declared-add-delivered-as-edit ... the ADD declaration
    #     was wrong" and blamed the author for a parser decision. 113 rows.
    #
    #   ADD (engineering commit 0; renamed from the earlier name)
    #     RENAME was tested before ADD, so a declared ADD was classified
    #     rename, counted excluded, and the obligation VANISHED with no
    #     record. That is the vacuity class this tool exists to close,
    #     occurring inside it. 18 rows.
    #
    # THE FIX is the one 94dcadb7 applied to the header detector in this file:
    # identify by WHERE IT IS, not by which keyword is present.
    #   (1) SCOPE. The declared path is removed first. A path segment is not a
    #       declaration: block-skill-direct-edit.sh is not an EDIT, and
    #       ADR-094-extend-before-create.md is not an ADD. This is the same
    #       narrowing isconditional() below already applies, for the reason
    #       recorded there.
    #   (2) POSITION. The FIRST verb token in the remaining declaration wins.
    #       The marker is the token the author put first; every later verb is
    #       annotation prose describing what the change DOES.
    #
    # The recognised vocabulary is UNCHANGED. A token split on /[^A-Z]+/ is
    # presence-equivalent to the retired hasw() helper on this corpus (2568 of
    # 2568 rows), so the only behavioural difference is which of several
    # present verbs is believed.
    #
    # REJECTED, each measured over the 2652-row corpus rather than argued:
    #   - Reorder EDIT ahead of ADD: 123 rows move but 115 obligations are
    #     DELETED, and neither the read/rename vacuity nor the path pollution
    #     is touched. It relocates the loser; it does not stop guessing.
    #   - ERROR on any multi-verb row: 144 rows across 55 plans become ERROR,
    #     including "EDIT (add sourcing step)", which is not ambiguous to a
    #     reader and not ambiguous positionally.
    #
    # 95.3 percent of verb-bearing fence rows and 97.4 percent of table intent
    # cells are marker-led. The residual - a row whose winning verb is NOT its
    # first token - is 7 rows in 2652, and it is DISCLOSED rather than
    # errored: firstverb sets prose_led, which rides the source_form field and
    # is counted in the always-emitted coverage record.
    #
    # EDITOR NOTE: this awk program is a SINGLE-QUOTED shell string. Keep
    # every line above and below apostrophe-free, per the note at
    # isconditional().
    function classof(t) {
      if (t == "READ")                                     return "read"
      if (t == "RENAME" || t == "RENAMED" || t == "MOVE")  return "rename"
      if (t == "ADD" || t == "NEW" || t == "CREATE")       return "add"
      if (t == "DELETE" || t == "REMOVE")                  return "delete"
      if (t == "EDIT" || t == "MODIFY")                    return "edit"
      return ""
    }
    # Sets the program-global prose_led to 1 when the winning verb token is
    # NOT the first non-empty token of the declaration. split() on /[^A-Z]+/
    # yields a leading EMPTY element whenever the string does not start with
    # A-Z, so the ordinal is counted over non-empty tokens only; counting raw
    # indices would mark every indented row prose-led and make the disclosure
    # meaningless.
    function firstverb(u,   n, i, k, a, c) {
      prose_led = 0
      n = split(u, a, /[^A-Z]+/)
      k = 0
      for (i = 1; i <= n; i++) {
        if (a[i] == "") continue
        k++
        c = classof(a[i])
        if (c != "") { if (k > 1) prose_led = 1; return c }
      }
      return ""
    }
    function verbof(u) {
      prose_led = 0
      if (index(u, "NOT EDITED") || index(u, "NOT TOUCHED")) return "excluded"
      return firstverb(u)
    }
    function stripfirst(s, p,   i) {
      i = index(s, p); if (i == 0) return s
      return substr(s, 1, i - 1) substr(s, i + length(p))
    }
    # Conditionality is a MARKER, not a substring — and specifically it is one of
    # the two NORMATIVE marker forms, `CONDITIONAL:<token>` or `CONDITIONAL on
    # <prose>`. A bare occurrence of the word is neither, because in a real matrix
    # it is usually annotation prose.
    #
    # Both narrowings are load-bearing, and each was found by running the check
    # rather than by reading it:
    #   - the declared path is removed before the test, because the originating
    #     specimen declares `release/ADRs/<self-arming-conditional-gate-posture>.md`,
    #     whose own slug contains the word. Matching it classified that row
    #     CONDITIONAL, which downgrades FAIL to a WARN-tier SKIP — the gate would
    #     have let through the very defect it was built for. Found by the historical
    #     replay arm.
    #   - a bare word does not qualify, because a row reading "(promoted from
    #     CONDITIONAL, see D-11)" is an unconditional row whose NOTE mentions the
    #     word. Found by running the check against the in-flight matrix of the
    #     release that ships it.
    # A row-level conditional exemption should cost a deliberate, tokenizable
    # marker; it should not be purchasable by prose.
    #
    # EDITOR NOTE, and it is not decorative: this awk program is a SINGLE-QUOTED
    # shell string. One apostrophe anywhere inside it — including inside a comment
    # like the possessive that used to sit on the line above — closes the quote and
    # takes the whole file out of parse, and the reported error line has no visible
    # relationship to the cause. Keep this body apostrophe-free.
    function isconditional(s, p,   rest) {
      rest = stripfirst(s, p)
      return (match(rest, /(^|[^A-Za-z])CONDITIONAL:/) ||
              match(rest, /(^|[^A-Za-z])CONDITIONAL on /))
    }
    function labelexcludes(l) {
      return (l ~ /non-scope/ || l ~ /not edited/ || l ~ /not touched/ ||
              l ~ /read-only/ || l ~ /read only/ || l ~ /untouched/)
    }
    BEGIN { infence = 0; label = ""; col_intent = 0; col_path = 0 }
    # Fence toggles. An in-fence `#` comment is a LABEL, not a heading.
    /^[ \t]*(```|~~~)/ { infence = 1 - infence; next }
    {
      line  = $0
      strip = line; gsub(/`/, "", strip)
      s     = trim(strip)
      if (s == "") next
    }
    # Sub-heading, bold label, or in-fence `#` comment -> the current block label.
    # The in-fence comment form is load-bearing: it is how the corpus labels its
    # READ-only and non-scope blocks, and it is the same line shape that terminates
    # the section early under the fence-blind shared extractor.
    s ~ /^#/ || (s ~ /^\*\*/ && s ~ /\*\*$/ && pathof(s) == "") {
      l = lc(s); gsub(/[#*_ ]+/, " ", l); label = l
      col_intent = 0; col_path = 0
      next
    }
    # ---- table row ----
    !infence && s ~ /^\|/ {
      n = split(s, cell, "|")
      is_header = 0
      for (i = 1; i <= n; i++) {
        c = lc(trim(cell[i]))
        if (c == "intent" || c == "action" || c == "change" || c == "disposition" ||
            c == "operation" || c == "op" || c == "type") { col_intent = i; is_header = 1 }
        if (c == "path" || c == "file" || c == "file path" || c == "artifact" ||
            c == "added path" || c == "surface") { col_path = i; is_header = 1 }
      }
      if (is_header) next
      if (s ~ /^\|[ \t:|-]+$/) next
      if (col_intent == 0) next
      iv = verbof(toupper(trim(cell[col_intent])))
      tpl = prose_led
      if (iv == "") next
      # FMF-5(c): a MARKED row whose declared path column holds a human label
      # rather than a repository path is a NAMED error, not a silent zero. This is
      # the v4.16 shape, whose `Path` column carries `label grammar` / `ADR-124`.
      p = (col_path > 0 && col_path <= n) ? pathof(trim(cell[col_path])) : ""
      if (p == "") p = pathof(s)
      if (p == "") { printf "%s\t%s\t%s\t%s\t%s\n", "(none)", "pathless", "uncond", "table-pathless", s; next }
      cond = (isconditional(s, p) || label ~ /conditional/) ? "cond" : "uncond"
      if (labelexcludes(label)) iv = "excluded"
      if (malformed(p)) iv = "malformed"
      printf "%s\t%s\t%s\t%s\t%s\n", p, iv, cond, (tpl ? "table prose-led" : "table"), s
      next
    }
    # ---- fenced declaration row ----
    #
    # AN UNRECOGNISED PATH IS REPORTED, NOT DISCARDED.
    #
    # `if (p == "") next` used to sit here, and it is the reusable form of the
    # defect the `operations` omission above merely instantiated. A row it dropped
    # left the population BEFORE classification, so it was counted as neither
    # interpreted nor uninterpreted: `declared` shrank to match, `interpreted`
    # equalled `declared`, and FCM-COVERAGE reported PASS over a denominator that
    # had silently lost rows. That is a coverage verdict about the rows the parser
    # happened to understand, presented as a verdict about the declared population
    # — the exact vacuity this family exists to close, occurring inside it, and it
    # is why the table arm five lines above already reports its own no-path case
    # instead of taking a `next`.
    #
    # The row is emitted as `unknown` (SKIP, a disclosure) rather than `pathless`
    # (ERROR). The table arm can afford ERROR because its row is MARKED: an intent
    # column names a declaration, so a path cell holding a label is an authoring
    # defect. A fenced line carries no such structure, and ERROR over it would
    # redden readable plans for prose.
    #
    # NO PREDICATE IS GUESSED HERE, and that is deliberate: every line reaching
    # this arm has already survived the blank, fence-marker, label and comment
    # tests above, so the control flow has ALREADY decided it is a candidate
    # declaration. Measured over the 189-plan corpus after the enum fix above, the
    # residual is 54 rows across 37 plans, and 52 of the 54 are real declarations
    # the recogniser cannot read — repository-root files carrying no directory
    # segment at all (CHANGELOG.md, install.sh, CLAUDE.md, .gitignore, .version),
    # bare directory rows like `roadmaps/`, and non-file targets such as
    # `required_status_checks (branch protection)`. Two are annotation prose. A
    # disclosure counter that is 96 percent real declarations is worth its noise;
    # a silent drop of the same rows is not.
    #
    # The KEY is the raw row, not a shared sentinel. A single sentinel would let
    # the same-path reconciliation upstream collapse every unrecognised row as soon
    # as ONE of them carried a verb, which would rebuild this blind spot in a new
    # costume. It is emitted before malformed() and labelexcludes() for the same
    # reason: either would reclassify these rows back into `interpreted`.
    infence {
      p = pathof(s)
      if (p == "") {
        key = s; gsub(/\t/, " ", key)
        printf "%s\t%s\t%s\t%s\t%s\n", key, "unknown", "uncond", "fence-unrecognized-path", s
        next
      }
      u  = toupper(stripfirst(s, p))
      iv = verbof(u)
      fpl = prose_led
      lead = toupper(trim(substr(s, 1, index(s " ", " "))))
      form = "fence-path-first"
      if (iv != "" && (lead ~ /^(ADD|EDIT|NEW|MODIFY|DELETE|REMOVE|READ|CREATE|RENAME)$/)) form = "fence-verb-first"
      if (iv == "") { iv = "unknown"; form = "fence-bare" }
      if (fpl) form = form " prose-led"
      cond = (isconditional(s, p) || label ~ /conditional/) ? "cond" : "uncond"
      if (labelexcludes(label)) iv = "excluded"
      if (malformed(p)) iv = "malformed"
      printf "%s\t%s\t%s\t%s\t%s\n", p, iv, cond, form, s
    }
  '
}

# --- Deviation Log ----------------------------------------------------------
#
# AC2's contract: a declared file that legitimately does not ship requires an
# explicit Deviation-Log entry, and the check passes ONLY with that entry present.
# The shipped `## Deviation Log` table is extended; no parallel structure is
# authored. The load-bearing tokens are the literal `NOT DELIVERED` and the
# declared path (or, for a conditional row, its condition token).
parse_deviation_log() {
  local file="$1"
  _extract_section "$file" "Deviation Log" | awk '
    toupper($0) ~ /NOT DELIVERED/ { gsub(/`/, "", $0); print }
  '
}

# --- Path-form taxonomy -----------------------------------------------------
#
# FIVE arms, enumerated against the CORPUS rather than reverse-engineered from the
# one row that failed. Deriving the taxonomy from the specimen is what left globs
# with no arm: 27 glob-bearing path tokens across 15 plans are an established
# authored form, and a taxonomy without an arm for them yields a guaranteed FAIL
# on every plan that uses one — including, before this arm existed, THIS release's
# own scope-lock row.
#
# Placeholder rows are normalized INTO the glob arm rather than resolved to a
# "longest literal ancestor directory". The ancestor-directory rule has no
# specificity floor (a placeholder in the leading segment resolves to the repo
# root, where any addition satisfies the predicate) and it discards the declared
# basename residue. Normalizing `release/ADRs/<self-arming-…>.md` to
# `release/ADRs/*.md` keeps the `.md` and keeps the directory, which is strictly
# more specific and still resolves the row that actually vanished.
fcm_normalize_pattern() {
  # $1 = declared path. Prints the match pattern (a bash `case` glob).
  printf '%s' "$1" | sed -E \
    -e 's/<[^>]*>/*/g' \
    -e 's/\{\{[^}]*\}\}/*/g' \
    -e 's/(^|[^A-Za-z])NNN([^A-Za-z]|$)/\1*\2/g' \
    -e 's/(^|[^A-Za-z])XXX([^A-Za-z]|$)/\1*\2/g' \
    -e 's/(^|[^A-Za-z])X\.Y([^A-Za-z]|$)/\1*\2/g'
}

fcm_path_form() {
  case "$1" in
    */)                 printf 'dir' ;;
    *'<'*|*'{{'*|*NNN*|*XXX*|*X.Y*) printf 'placeholder' ;;
    *'*'*|*'?'*|*'['*)  printf 'glob' ;;
    *)                  printf 'literal' ;;
  esac
}

# Specificity floor. A pattern that keeps no literal directory prefix, or whose
# basename is entirely wildcard, cannot distinguish a delivered obligation from
# any addition at all — so it is ERROR, not a permissive PASS. Measured: 1
# placeholder-leading token corpus-wide, so this is prophylactic and is stated as
# such rather than inflated into a live defect.
fcm_pattern_resolvable() {
  local pat="$1" prefix base
  prefix="${pat%%[*?[]*}"
  case "$prefix" in */*) : ;; *) return 1 ;; esac
  base="${pat##*/}"
  case "$base" in
    ''|'*'|'**'|'?') return 1 ;;
  esac
  return 0
}

# --- Reconciliation ---------------------------------------------------------
#
# The git invocation is a NATIVE code path with a FIXED command. It does not route
# through `eval_free_run`, and `git` MUST NOT be added to RUNNABLE_VERBS — that set
# is closed on purpose (see the RUNNABLE_VERBS doctrine above): a verification harness driven by an authored
# artifact must not acquire a code-execution channel. This family reads authored
# DATA and runs a fixed command; the allowlist governs authored COMMANDS. The
# distinction is precisely why widening the verb set is unnecessary here.
#
# `--no-renames` is deliberate. Under `--find-renames` a declared ADD delivered as
# a move reports `R`, which the arms would grade `declared-add-delivered-as-edit`
# ("the file pre-existed; the declaration was wrong") — factually false for a
# rename. With renames off, a move reports as `A`+`D`, which is exactly FCM ADD
# semantics.
FCM_ADDS_FILE=""
FCM_ANY_FILE=""
FCM_DIFF_STATUS=""

# NOTE FOR THE NEXT EDITOR: this function sets GLOBALS and must be called
# DIRECTLY, never as `x="$(fcm_resolve_diff)"`. A command substitution runs it in
# a subshell, where the two path globals are assigned and then discarded — the
# caller reads empty strings, every declared ADD matches nothing, and the family
# reports a clean-looking "not delivered" for files that were in fact delivered.
# That failure is silent and it is the same defect class this family exists to
# catch, so the status rides in a global too rather than on stdout.
fcm_resolve_diff() {
  FCM_DIFF_STATUS="diff-unresolvable"
  FCM_ADDS_FILE="$(mktemp -t vrp-fcm-adds.XXXXXX)"
  FCM_ANY_FILE="$(mktemp -t vrp-fcm-any.XXXXXX)"
  if [ -n "$ARG_FCM_DIFF_FILE" ]; then
    if [ ! -f "$ARG_FCM_DIFF_FILE" ]; then return 0; fi
    awk -F'\t' 'NF>=2 { print $1 "\t" $2 }' "$ARG_FCM_DIFF_FILE" > "$FCM_ANY_FILE"
  else
    local base head raw rc=0
    head="${ARG_FCM_HEAD:-HEAD}"
    if [ -n "$ARG_FCM_MERGE_BASE" ]; then base="$ARG_FCM_MERGE_BASE"
    else base="$( cd "$REPO_ROOT" && git merge-base origin/main HEAD 2>/dev/null )" || base=""; fi
    if [ -z "$base" ]; then return 0; fi
    set +e
    raw="$( cd "$REPO_ROOT" && git diff --name-status --no-renames "$base..$head" 2>/dev/null )"
    rc=$?
    set -e
    if [ "$rc" -ne 0 ]; then return 0; fi
    printf '%s\n' "$raw" > "$FCM_ANY_FILE"
  fi
  # An EMPTY diff is not the same fact as an unresolvable one, and neither is a
  # licence to pass: an empty delivered set with a non-empty obligation set FAILs
  # every obligation, which is the correct reading.
  awk -F'\t' '$1 ~ /^A/ { print $2 }' "$FCM_ANY_FILE" | sort -u > "$FCM_ADDS_FILE"
  FCM_DIFF_STATUS="ok"
  return 0
}

# Each arm uses a DISTINCT matching mechanism, and that is deliberate. The obvious
# implementation routes every arm through `case "$p" in $pat)`, which glob-matches
# an unquoted pattern — so the "literal" arm silently performs glob matching and
# becomes indistinguishable from the glob arm. A five-arm taxonomy in which two arms
# cannot be told apart is a taxonomy on paper only: deleting the glob arm then
# changes no verdict, which is exactly what the M7 mutation arm reported before this
# was rewritten. Literal compares strings, directory compares a prefix, and only the
# glob/placeholder arms glob.
fcm_match_adds() {
  # $1 = declared path. Prints the number of delivered ADDITIONS it matches,
  # or the literal token UNRESOLVABLE.
  local declared="$1" form pat n=0 p
  form="$(fcm_path_form "$declared")"
  if [ "$form" = "placeholder" ]; then
    pat="$(fcm_normalize_pattern "$declared")"
    if ! fcm_pattern_resolvable "$pat"; then printf 'UNRESOLVABLE'; return 0; fi
  elif [ "$form" = "glob" ]; then
    pat="$declared"
    if ! fcm_pattern_resolvable "$pat"; then printf 'UNRESOLVABLE'; return 0; fi
  fi
  while IFS= read -r p; do
    [ -n "$p" ] || continue
    case "$form" in
      # `if`, not `[ … ] && …`: under errexit a failing AND-list at the end of a
      # case branch takes the whole function down inside its command substitution,
      # and the caller then sees an empty count rather than zero.
      literal)          if [ "$p" = "$declared" ]; then n=$((n+1)); fi ;;
      dir)              case "$p" in "$declared"*) n=$((n+1)) ;; esac ;;
      glob|placeholder) # shellcheck disable=SC2254
                        case "$p" in $pat) n=$((n+1)) ;; esac ;;
    esac
  done < "$FCM_ADDS_FILE"
  printf '%s' "$n"
}

fcm_present_any() {
  local declared="$1"
  awk -F'\t' -v want="$declared" '$2 == want { f=1 } END { exit !f }' "$FCM_ANY_FILE"
}

# --- Handler ----------------------------------------------------------------
#
# Emits FULL stream records (issue \t id \t family \t method \t expected \t
# verdict \t observed), one per obligation PLUS a mandatory coverage record.
#
# The coverage record is not decoration and it is emitted UNCONDITIONALLY on
# every applicable run. A check whose output states only a finding count has not
# shown that it examined anything: a reader cannot distinguish "zero declared ADDs
# were missing" from "no rows were interpreted". Carrying declared / interpreted /
# obligations / excluded / conditional in the record is what makes a vacuous run
# VISIBLE, and a run in which some rows were seen but not understood is a NON-PASS
# regardless of how the understood rows graded.
handle_fcm_delivery() {
  local plan="$1"
  local ISS='FCM (delivery)' FAM='fcm-delivery'
  local method='declared File Change Matrix ADDs vs the merged diff (git diff --name-status --no-renames)'

  emit_fcm() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$ISS" "$1" "$FAM" "$method" "$2" "$3" "$4"; }

  # (1) Applicability. The governed population is the release-plan corpus, defined
  #     by location. A target outside it is a NAMED skip stating exactly why — it
  #     can never hide a real release whose matrix is missing, because a real
  #     release plan lives inside the corpus and takes the ERROR arm below.
  local in_corpus=0
  case "$plan" in */release/releases/plans/*) in_corpus=1 ;; esac
  if [ -n "$ARG_FCM_DIFF_FILE" ] && [ "$in_corpus" -eq 1 ]; then
    # The determinism seam is a TEST seam. Honoring it against a real release plan
    # would let the same actor whose work this audits supply the evidence it is
    # audited against, and the emitted record would be indistinguishable from a
    # live run. That is an off-switch on the control, so it is refused outright
    # rather than stamped and left for a downstream reader to notice.
    emit_fcm "FCM-COVERAGE" "live evidence" "$VERDICT_ERROR" \
      "fcm-fixture-mode-on-live-plan (--fcm-diff-file refused against a plan under release/releases/plans/)"
    return 0
  fi
  if [ -z "$ARG_FCM_DIFF_FILE" ] && [ "$in_corpus" -eq 0 ]; then
    emit_fcm "FCM-COVERAGE" "release-plan target" "$VERDICT_SKIP" \
      "fcm-not-a-release-plan (target outside release/releases/plans/; no FCM obligation)"
    return 0
  fi

  # (2) Extraction, with every unreadable state fail-closed.
  local body; body="$(_extract_fcm_section "$plan")"
  if [ -z "$(printf '%s' "$body" | tr -d '[:space:]')" ]; then
    emit_fcm "FCM-COVERAGE" "a File Change Matrix section" "$VERDICT_ERROR" \
      "fcm-section-absent (no File Change Matrix heading resolves; absent matrix is NOT zero obligations)"
    return 0
  fi
  if printf '%s\n' "$body" | _fcm_body_truncated; then
    emit_fcm "FCM-COVERAGE" "a complete matrix body" "$VERDICT_ERROR" \
      "fcm-section-truncated (unbalanced fence in the extracted body; row set is provably incomplete)"
    return 0
  fi

  local records; records="$(parse_fcm_declarations "$body")"

  # SAME-PATH RECONCILIATION. The dominant authored shape in this corpus is a
  # machine-readable fence of bare paths PLUS a companion table carrying the intent
  # for the same paths — the matrix states each declaration twice, in two forms, on
  # purpose. Counting the bare copy as "uninterpreted" would report a fully-declared
  # matrix as partially-understood, and every plan in that shape (49 of 117) could
  # never reach PASS no matter how carefully it was authored. A matrix is ONE
  # declaration set keyed by path, so a bare row whose path carries a verb ANYWHERE
  # in the same matrix is a second expression of a known declaration, not a gap.
  # Only a path with no marked row anywhere is genuinely intent-undeclared.
  records="$(printf '%s\n' "$records" | awk -F'\t' '
    { line[NR] = $0; pth[NR] = $1; itn[NR] = $2
      if ($2 != "unknown" && $2 != "pathless") marked[$1] = 1 }
    END { for (n = 1; n <= NR; n++) {
            if (itn[n] == "unknown" && (pth[n] in marked)) continue
            print line[n] } }')"

  local declared;      declared="$(printf '%s' "$records"   | grep -c . || true)"
  if [ "$declared" -eq 0 ]; then
    emit_fcm "FCM-COVERAGE" "at least one declared path" "$VERDICT_ERROR" \
      "fcm-empty (matrix section present but carries no path-shaped rows; empty matrix is an authoring defect)"
    return 0
  fi

  # (3) Delivered set. Called DIRECTLY — see the note on fcm_resolve_diff.
  fcm_resolve_diff
  if [ "$FCM_DIFF_STATUS" != "ok" ]; then
    emit_fcm "FCM-COVERAGE" "a resolvable diff range" "$VERDICT_ERROR" \
      "diff-unresolvable (never infer an empty diff from an absent one)"
    return 0
  fi

  local devlog; devlog="$(parse_deviation_log "$plan" || true)"

  local excluded conditional unknown pathless obligations prose_led
  excluded="$(   printf '%s\n' "$records" | awk -F'\t' '$2=="excluded"||$2=="read"||$2=="rename"{c++} END{print c+0}')"
  unknown="$(    printf '%s\n' "$records" | awk -F'\t' '$2=="unknown"{c++}  END{print c+0}')"
  pathless="$(   printf '%s\n' "$records" | awk -F'\t' '$2=="pathless"{c++} END{print c+0}')"
  # prose_led rides the source_form field (see parse_fcm_declarations). It is
  # a disclosure counter, NOT a verdict input: a row read from a weaker signal
  # says so in the record instead of being converted to an ERROR. Converting
  # the 7-row corpus residual to ERROR would redden 55 readable plans.
  prose_led="$( printf '%s\n' "$records" | awk -F'\t' '$4 ~ /prose-led/{c++} END{print c+0}')"
  conditional="$(printf '%s\n' "$records" | awk -F'\t' '$2=="add"&&$3=="cond"{c++} END{print c+0}')"
  obligations="$(printf '%s\n' "$records" | awk -F'\t' '$2=="add"&&$3=="uncond"{c++} END{print c+0}')"
  local interpreted=$(( declared - unknown - pathless ))

  # (4) Coverage record — ALWAYS emitted, so "the family never ran" is not
  #     byte-identical to "the family found nothing".
  local cov_verdict="$VERDICT_PASS" cov_note=""
  if [ "$pathless" -gt 0 ]; then
    cov_verdict="$VERDICT_ERROR"; cov_note=" fcm-row-pathless:$pathless (a MARKED row whose path cell holds no repository path)"
  elif [ "$unknown" -gt 0 ]; then
    cov_verdict="$VERDICT_SKIP";  cov_note=" fcm-rows-uninterpreted:$unknown (declared paths carrying no intent marker; intent undeclared is NOT zero ADDs)"
  elif [ "$obligations" -eq 0 ]; then
    cov_verdict="$VERDICT_SKIP";  cov_note=" fcm-no-unconditional-adds (matrix fully interpreted; nothing for this family to assert)"
  fi
  emit_fcm "FCM-COVERAGE" "full row coverage" "$cov_verdict" \
    "declared=$declared interpreted=$interpreted obligations=$obligations excluded=$excluded conditional=$conditional uninterpreted=$unknown pathless=$pathless prose_led=$prose_led${cov_note}"

  # (5) One record per ADD row. Conditional and unconditional both reported.
  local n=0 path intent cond form _raw
  while IFS=$'\t' read -r path intent cond form _raw; do
    [ "$intent" = "add" ] || continue
    n=$((n+1))
    local hits recorded=0
    hits="$(fcm_match_adds "$path")"
    # SIGPIPE-REWRITE. Was: `printf '%s' "$devlog" | grep -Fq -- "$path"`. Under the
    # `set -o pipefail` at the top of this file that form INVERTS: `grep -Fq` exits on
    # its first match, `printf` fails on the broken pipe, and the pipeline reports the
    # writer's non-zero status — so a path that IS in the Deviation Log reads as not
    # recorded, and a `NOT DELIVERED` row silently stops converting FCM FAIL to PASS.
    # The empty-haystack caveat does not bite: a row whose path cell is empty is
    # emitted upstream as `(none)`/`pathless` and filtered by the `add` test above, so
    # `$path` is never the empty needle here and needs no `[ -n … ]` guard.
    if grep -Fq -- "$path" <<<"$devlog" 2>/dev/null; then recorded=1; fi
    if [ "$hits" = "UNRESOLVABLE" ]; then
      emit_fcm "FCM-$n" "resolvable declared path" "$VERDICT_ERROR" \
        "placeholder-unresolvable:$path (no literal directory prefix or wholly-wildcard basename)"
    elif [ "$cond" = "cond" ]; then
      if [ "$hits" -gt 0 ]; then
        emit_fcm "FCM-$n" "conditional ADD" "$VERDICT_PASS" "conditional-fired:$path ($form)"
      elif [ "$recorded" -eq 1 ]; then
        emit_fcm "FCM-$n" "conditional ADD" "$VERDICT_PASS" "conditional-not-fired (recorded):$path"
      else
        emit_fcm "FCM-$n" "conditional ADD" "$VERDICT_SKIP" \
          "conditional-unrecorded:$path (WARN tier — the gate cannot evaluate a prose condition)"
      fi
    else
      if [ "$hits" -gt 0 ]; then
        emit_fcm "FCM-$n" "delivered as an addition" "$VERDICT_PASS" "declared-add-delivered:$path ($form)"
      elif [ "$recorded" -eq 1 ]; then
        emit_fcm "FCM-$n" "delivered or a Deviation-Log row" "$VERDICT_PASS" "deviation-recorded:$path"
      elif fcm_present_any "$path"; then
        emit_fcm "FCM-$n" "delivered as an addition" "$VERDICT_FAIL" \
          "declared-add-delivered-as-edit:$path (the file pre-existed; the ADD declaration was wrong)"
      else
        emit_fcm "FCM-$n" "delivered as an addition" "$VERDICT_FAIL" "declared-add-not-delivered:$path"
      fi
    fi
  done <<< "$records"

  rm -f "$FCM_ADDS_FILE" "$FCM_ANY_FILE"
  return 0
}

# ===========================================================================
# Component 6b — scope: a confinement assertion graded against the RELEASE diff.
#
# WHY THIS EXISTS. "Changes are confined to <path>" is a recurring, load-bearing
# acceptance criterion, and it had no family: a `git diff` scope assertion reached
# `unclassified` and read ERROR, so a plan's most rigorous row read the same as an
# unreadable one. It is executed through the fcm-delivery family's own FIXED git
# call (fcm_resolve_diff, used unmodified; see its reconciliation note) and never
# through RUNNABLE_VERBS: `git` is not in that set and is not added to it, because
# a verification harness driven by an authored artifact must not acquire a
# code-execution channel. The authored command is read as DATA, in a closed grammar:
#   git diff [--name-only|--name-status|--stat|--no-renames]... <range> [-- <pathspec>...]
# followed by ONE comparator. <range> is the release diff -- `origin/main...HEAD` or
# `origin/main..HEAD`, either end an author's `<placeholder>` -- and it is resolved
# the way fcm-delivery resolves it, whatever the author spelled. The pathspecs are
# matched IN-PROCESS against the delivered set, so no plan-authored byte reaches git:
# `:(top)` is dropped; `:!X`, `:^X` and `:(exclude)X` exclude; any other magic, an
# absolute path, a `..` segment, shell syntax (span_shell_operator, the one shared
# test), a pinned or single revision, another option, or no comparator at all is
# outside the grammar, and such a row keeps the tool decline, UNRUNNABLE naming git.
#
# WHAT IT GRADES: THE RELEASE DIFF, ALL OF IT. The delivered set is every path the
# release changes between its merge base and its head -- every card's commits, not
# only the card whose row it is. A per-card confinement claim written as a scope row
# therefore FAILs when a sibling card touches the path; state such a claim another
# way.
#
# A VACUOUS OR MIS-BOUND INPUT IS NEVER A PASS. Each of these reads UNRUNNABLE, with
# its reason, rather than a verdict: a diff that is absent or cannot be resolved
# here; an empty one; a method whose comparators disagree (limb_comparator, the one
# comparator vocabulary -- a comparator written for something else would otherwise
# grade the assertion); a `<placeholder>` pathspec, which names nothing; and, for an
# `==` or `<=` assertion, an included pathspec that selects no existing and no
# delivered path -- a typo would otherwise make "nothing changed under X" true of a
# path that does not exist. Every graded count carries its denominator, the size of
# the diff it was read over. A method naming another command beside the assertion
# follows the partition's partial rule (command_list): a PASS reads the can't-run
# slot and names the command that did not run; a FAIL stands.
# ===========================================================================

# scope_spec_of <cmd> <method> -- TRUE, printing the pathspecs one per line, when
# <cmd> is a scope assertion in the closed grammar above and <method> states a
# comparator. Each line is `+<pathspec>` (included), `-<pathspec>` (excluded) or
# `?<pathspec>` (a placeholder, which handle_scope refuses by name). The shell-syntax
# test reads the span with each `<placeholder>` token replaced by a plain word, so an
# author's `<base>` or `<skill-dir>` is not read as a redirect; the grammar then
# reads the raw token. The pathspec arms are KEPT ONE PER LINE ON PURPOSE: the
# suite's mutation arm G17 M8 reads a placeholder as a literal path by one
# substitution.
scope_spec_of() {
  local cmd="$1" method="$2" i=2 n t p out="" range="" seen_dd=0
  local rre='^(origin/main|<[A-Za-z0-9_-]+>)[.][.][.]?(HEAD|<[A-Za-z0-9_-]+>)$'
  [ -n "$cmd" ] || return 1
  tokenize_cmd "$cmd" || return 1
  n=${#TOKENS[@]}
  if [ "$n" -lt 3 ] || [ "${TOKENS[0]}" != git ] || [ "${TOKENS[1]}" != diff ]; then return 1; fi
  if span_shell_operator "$(printf '%s' "$cmd" | sed -E 's/<[A-Za-z0-9_-]+>/P/g')" >/dev/null; then return 1; fi
  while [ "$i" -lt "$n" ]; do
    t="${TOKENS[$i]}"; i=$((i + 1))
    if [ "$seen_dd" -eq 0 ]; then
      case "$t" in
        --) seen_dd=1 ;;
        --name-only|--name-status|--stat|--no-renames) : ;;
        *) if [ -z "$range" ] && [[ "$t" =~ $rre ]]; then range="$t"; else return 1; fi ;;
      esac
      continue
    fi
    p="${t#:(top)}"
    case "$p" in
      ''|/*|..|../*|*/../*|*/..) return 1 ;;
      *'<'*|*'>'*)   out="${out}?${p}"$'\n' ;;
      ':!'*|':^'*)   out="${out}-${p#:?}"$'\n' ;;
      ':(exclude)'*) out="${out}-${p#:(exclude)}"$'\n' ;;
      :*)            return 1 ;;
      *)             out="${out}+${p}"$'\n' ;;
    esac
  done
  [ -n "$range" ] || return 1
  [ -n "$(limb_comparator "$method")" ] || return 1
  printf '%s' "$out"
  return 0
}

# scope_pattern_matches <path> <pattern> -- a git pathspec's default reading, in
# process: a pattern carrying a glob character matches as a shell `case` pattern does
# (so `*` crosses `/`, as it does in a git pathspec); any other pattern matches the
# path itself, or anything under it as a directory; `.` or an empty pattern matches
# every path.
scope_pattern_matches() {
  local path="$1" pat="${2#./}"
  case "$pat" in
    ''|.) return 0 ;;
    *'*'*|*'?'*|*'['*)
      # shellcheck disable=SC2254
      case "$path" in $pat) return 0 ;; esac
      return 1 ;;
  esac
  pat="${pat%/}"
  if [ "$path" = "$pat" ]; then return 0; fi
  case "$path" in "$pat"/*) return 0 ;; esac
  return 1
}

# scope_path_selected <path> <specs> -- TRUE when the delivered <path> is selected by
# the pathspec list: excluded by no `-` pathspec, and matched by a `+` one when any is
# given (no `+` pathspec selects every path the exclusions leave). The exclusion arm
# is KEPT ON ONE LINE ON PURPOSE: the suite's mutation arm G17 M5 makes it a no-op.
scope_path_selected() {
  local path="$1" specs="$2" s any_plus=0 plus_hit=0
  while IFS= read -r s; do {
    [ -n "$s" ] || continue
    case "$s" in
      -*) if scope_pattern_matches "$path" "${s#-}"; then return 1; fi ;;
      +*) any_plus=1
          if scope_pattern_matches "$path" "${s#+}"; then plus_hit=1; fi ;;
    esac
  } </dev/null; done <<EOF_SCOPE_SEL
$specs
EOF_SCOPE_SEL
  [ "$any_plus" -eq 0 ] || [ "$plus_hit" -eq 1 ]
}

# scope_pathspec_selects <pathspec> <paths> -- TRUE when an included pathspec selects
# at least one delivered path, or at least one path in the tree: a literal or
# directory pathspec is tested for existence; a glob one against every path under
# the root (find -path, whose `*` crosses `/` as a git pathspec's does).
scope_pathspec_selects() {
  local pat="$1" paths="$2" q
  while IFS= read -r q; do {
    [ -n "$q" ] || continue
    if scope_pattern_matches "$q" "$pat"; then return 0; fi
  } </dev/null; done <<EOF_SCOPE_SELECTS
$paths
EOF_SCOPE_SELECTS
  pat="${pat#./}"
  case "$pat" in
    ''|.) return 0 ;;
    *'*'*|*'?'*|*'['*)
      if [ -n "$( cd "$REPO_ROOT" && find . -path ./.git -prune -o -path "./$pat" -print 2>/dev/null )" ]; then return 0; fi
      return 1 ;;
  esac
  [ -e "$REPO_ROOT/${pat%/}" ]
}

# scope_delivered_set -- print the release diff the scope family grades: a status line
# ("ok", or fcm_resolve_diff's status token), then one delivered path per line. The
# diff is resolved AT MOST ONCE per run and cached in SCOPE_DIFF_CACHE (a per-run file
# set in main), so the result survives the subshells the handlers run in. It calls
# fcm_resolve_diff DIRECTLY -- that function sets globals (see its note) -- and
# removes the two files it creates, as handle_fcm_delivery does.
scope_delivered_set() {
  local st out=""
  if [ -n "${SCOPE_DIFF_CACHE:-}" ] && [ -s "$SCOPE_DIFF_CACHE" ]; then cat "$SCOPE_DIFF_CACHE"; return 0; fi
  fcm_resolve_diff
  st="$FCM_DIFF_STATUS"
  if [ "$st" = ok ]; then
    out="$(awk -F'\t' 'NF >= 2 && $2 != "" { print $2 }' "$FCM_ANY_FILE" | sort -u)"
  fi
  rm -f "$FCM_ADDS_FILE" "$FCM_ANY_FILE"
  if [ -n "${SCOPE_DIFF_CACHE:-}" ]; then printf '%s\n%s' "$st" "$out" > "$SCOPE_DIFF_CACHE"; fi
  printf '%s\n%s' "$st" "$out"
  return 0
}

# scope: grade one scope assertion against the release diff (Component 6b).
# $1 = method string. Prints "<verdict> TAB <observed>". Each guard's refusal and the
# comparator read are KEPT ON ONE LINE ON PURPOSE: the suite's mutation arms G17
# M6-M9 each reach one of them by a single anchored substitution.
handle_scope() {
  local method="$1" cmd specs cmpr op want delivered st paths s p total=0 hits=0 shown="" verdict obs cl n list
  local T=$'\t' NL=$'\n'
  cmd="$(extract_command "$method")"
  if ! specs="$(scope_spec_of "$cmd" "$method")"; then
    printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" \
      "tool-invocation-outside-executor-allowlist:git (not executed here; its mechanical guarantee belongs in that tool's own self-test)"
    return
  fi
  if [ -n "$ARG_FCM_DIFF_FILE" ]; then
    case "$PLAN_ABS" in
      */release/releases/plans/*)
        printf '%s\t%s\n' "$VERDICT_ERROR" "scope-fixture-mode-on-live-plan (--fcm-diff-file refused against a plan under release/releases/plans/)"
        return ;;
    esac
  fi
  cmpr="$(limb_comparator "$method")"
  if [ "$cmpr" = ambiguous ]; then
    printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" "scope-comparator-ambiguous (the method states comparators that disagree; a scope assertion is graded on exactly one, so none of them grades it)"
    return
  fi
  op="${cmpr%%"$T"*}"; want="${cmpr#*"$T"}"
  while IFS= read -r s; do {
    case "$s" in
      '?'*) printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" "scope-pathspec-placeholder:${s#?} (a placeholder names no path, so the assertion is graded on nothing: not a pass)"
            return ;;
    esac
  } </dev/null; done <<EOF_SCOPE_PH
$specs
EOF_SCOPE_PH
  delivered="$(scope_delivered_set)"
  st="${delivered%%"$NL"*}"
  if [ "$st" != ok ]; then
    printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" "scope-diff-unresolvable (the release diff could not be resolved here; an absent diff is never read as an empty one)"
    return
  fi
  case "$delivered" in *"$NL"*) paths="${delivered#*"$NL"}" ;; *) paths="" ;; esac
  while IFS= read -r p; do {
    [ -n "$p" ] || continue
    total=$((total + 1))
    if scope_path_selected "$p" "$specs"; then
      hits=$((hits + 1))
      if [ "$hits" -le 5 ]; then shown="${shown:+$shown, }$p"; fi
    fi
  } </dev/null; done <<EOF_SCOPE_PATHS
$paths
EOF_SCOPE_PATHS
  if [ "$total" -eq 0 ]; then
    printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" "scope-diff-empty (the release diff is empty here, so a scope assertion is vacuous: not a pass)"
    return
  fi
  case "$op" in
    '=='|'<=')
      while IFS= read -r s; do {
        case "$s" in
          +*) if ! scope_pathspec_selects "${s#+}" "$paths"; then
                printf '%s\t%s\n' "$VERDICT_UNRUNNABLE" "scope-pathspec-selects-nothing:${s#+} (no existing and no delivered path matches it, so an assertion that nothing changed there is vacuous: not a pass)"
                return
              fi ;;
        esac
      } </dev/null; done <<EOF_SCOPE_NOTHING
$specs
EOF_SCOPE_NOTHING
      ;;
  esac
  verdict="$(compare_threshold "$hits" "$op" "$want")"
  if [ "$verdict" = PASS ]; then obs="scope count=$hits ($op $want) over $total changed path(s) in the release diff"
  else obs="scope count=$hits (wanted $op $want) over $total changed path(s) in the release diff"; fi
  if [ -n "$shown" ]; then obs="$obs: $shown"; fi
  cl="$(command_list "$method" "$cmd" "$verdict $obs")"
  n="${cl%%"$T"*}"; list="${cl#*"$T"}"
  if [ "$n" -ge 2 ]; then
    if [ "$verdict" = PASS ]; then
      printf '%s\t%s\n' "$VERDICT_PARTIAL_SLOT" "partial-execution: limbs run 1 of $n: $list — a command that did not run is not a pass"
    else
      printf '%s\t%s\n' "$verdict" "limbs run 1 of $n: $list"
    fi
    return
  fi
  printf '%s\t%s\n' "$verdict" "$obs"
}

# ===========================================================================
# Component 7 — provenance-survival: the domain_practice provenance label,
# asserted ABSOLUTELY on the plan file and, when the Stage-4 comment is supplied,
# as a set-difference across the Commit-0 transcription boundary.
#
# WHY THIS EXISTS. The label is determined at Stage 4 (Phase A1.5) and read back
# from the PLAN FILE by four downstream consumers -- the Stage-13 close-class
# resolver at rung 1, the Stage-5 impact-method selector, the design-review guide
# resolution, and Stage-7 Phase A/C. Between those two surfaces sits one manual
# step: the Commit-0 transcription. Nothing asserted that the label survived it,
# so a drop was silent and the close-class resolver fell through to its default
# branch with nobody notified.
#
# WHY THERE IS AN ABSOLUTE LIMB AND NOT ONLY A DELTA. The obvious mechanism is a
# comment-vs-plan set-difference. It is VACUOUS on the shape that actually
# recurred: v4.37 was hub-authored directly, so its Stage-4 sub-task comment
# carried no label EITHER. Comment 0, plan 0, set-difference empty -- a delta-only
# check reports CLEAN on the one release that failed. That is the same defect
# class fcm-delivery names for itself above, one family over. A check that cannot
# fail on the case that motivated it is not a check, so PROV-PRESENCE reads the
# plan ALONE and does not care what the comment said.
#
# WHY THE DELTA SET IS ONLY ROWS 1-5 OF THE SURVIVAL SET. Run by hand end-to-end
# on v4.31 first, both surfaces, before any of this was mechanised: 0 casualties
# across 6 grammar-bearing elements, and the naive token-level probe produced TWO
# false positives (the baseline pin and the version determination) that resolved
# to legitimate re-renderings. Only an element whose serialization is FROZEN by a
# named schema is mechanically comparable; the rest are re-rendered prose, where a
# token comparison manufactures findings instead of finding them. Rows 6-9 are
# reviewer-read by design, and the exclusion is stated in PROV-COVERAGE so the
# limb scope is visible rather than inferred.
#
# WHY --stage4-comment IS NOT REFUSED THE WAY --fcm-diff-file IS. fcm-delivery
# refuses its seam against a live plan because a live git-derived source exists,
# so honoring caller-supplied evidence would be an off-switch on a control that
# can run without it. NO host-reachable source exists for a GitHub comment, so the
# same refusal would not harden this limb -- it would delete it. The
# caller-supplied-evidence risk is neutralized by the DIRECTION OF THE DEFAULT
# instead: absent evidence yields a NAMED SKIP, never PASS, so withholding the
# comment cannot manufacture a pass.
# ===========================================================================

# --- Extraction -------------------------------------------------------------
#
# The presence pattern is the Stage-7 Phase-A pattern reused VERBATIM
# (stage-07-dev-testing.md), so no second rendering set is minted. The {0,24}
# decoration bound and the "content, not typographic setting" tolerance are owned
# by stage-04-planning.md 5.7; this handler CITES that clause and enumerates
# nothing. The discriminator is a schema field INSIDE the brace body, which is why
# a narrative mention carrying no body is not a match.
#
# Extraction is index-based rather than regex-based once the line is known: the
# interval expression lives in `grep -E` (portable on both CI runners) and the body
# carve-out uses index()/substr(), so no awk interval support is assumed.
_prov_label_lines() {
  # $1 = file. Prints  <lineno> TAB <brace-body>  per conformant single-line label.
  grep -nE 'domain_practice[^{]{0,24}\{[^}]*source:' "$1" 2>/dev/null | awk '
    {
      p = index($0, ":")
      if (p == 0) next
      ln = substr($0, 1, p - 1)
      rest = substr($0, p + 1)
      k = index(rest, "domain_practice")
      if (k == 0) next
      tail = substr(rest, k)
      ob = index(tail, "{")
      if (ob == 0) next
      body = substr(tail, ob + 1)
      cb = index(body, "}")
      if (cb > 0) body = substr(body, 1, cb - 1)
      gsub(/\t/, " ", body)
      printf "%s\t%s\n", ln, body
    }'
}

# _prov_field <body> <key> — the value of <key> in a label body, up to the next
# top-level comma. Matches the census extractor the grammar was derived from.
_prov_field() {
  printf '%s' "$1" | awk -v k="$2" '
    {
      key = k ":"
      p = index($0, key)
      if (p == 0) { exit }
      v = substr($0, p + length(key))
      c = index(v, ",")
      if (c > 0) v = substr(v, 1, c - 1)
      gsub(/^[ \t]+|[ \t]+$/, "", v)
      print v
    }'
}

# _prov_normalize_source — trim, then fold any dash used as the N/A separator to a
# single U+2014. Census at introduction: 85 of 85 exemption tokens already use
# U+2014, so the fold is PROPHYLACTIC -- its purpose is that a typographic slip is
# never reported as a semantic finding.
_prov_normalize_source() {
  printf '%s' "$1" | sed -E \
    -e 's/^[[:space:]]+//' \
    -e 's/[[:space:]]+$//' \
    -e 's/^N\/A[[:space:]]*(—|–|--|-)[[:space:]]*/N\/A — /'
}

# _prov_source_form <normalized> — prints A | B | X | NONE.
_prov_source_form() {
  case "$1" in
    'N/A — pipeline-internal release') printf 'X'; return 0 ;;
    'UNSOURCED-DOMAIN')                printf 'B'; return 0 ;;
  esac
  # SIGPIPE-REWRITE, same mechanism and same fix as the fcm-delivery site above —
  # see the note at `recorded=1` for why `writer | grep -q` inverts under this
  # file's `set -o pipefail`. Stated once there, cited here.
  # The writer was `printf` on a variable, which has no status worth preserving, so
  # a here-string is exact: it removes the pipe rather than relocating the hazard.
  # `printf '%s'` emits no trailing newline and `<<<` adds one; grep reads a final
  # incomplete line identically, and on the empty value both forms decline to match
  # (every alternative here requires at least one character).
  if grep -qE '^https?://[^[:space:]]+' <<<"$1"; then printf 'A'; return 0; fi
  if grep -qE '^[A-Za-z0-9._/-]+\.(md|sh|py|toml|json|yml|yaml|txt)([[:space:](].*)?$' <<<"$1"; then printf 'A'; return 0; fi
  printf 'NONE'
}

# _prov_elements_present <file> — one token per Survival-Set row 1..5 element the
# file carries. Rows 6-9 are absent BY CONSTRUCTION; see the header note.
_prov_elements_present() {
  local f="$1"
  if grep -qE 'domain_practice[^{]{0,24}\{[^}]*source:' "$f" 2>/dev/null; then printf 'domain_practice-label\n'; fi
  if grep -qE 'File Change Matrix' "$f" 2>/dev/null;  then printf 'file-change-matrix\n';   fi
  if grep -qE 'CIAC-[0-9]' "$f" 2>/dev/null;          then printf 'ciac\n';                 fi
  if grep -qE 'Verification Plan' "$f" 2>/dev/null;   then printf 'verification-plan\n';    fi
  if grep -qF '{{RELEASE_VERSION}}' "$f" 2>/dev/null; then printf 'release-version-stamp\n'; fi
  return 0
}

handle_provenance_survival() {
  local plan="$1"
  local ISS='PROV (provenance)' FAM='provenance-survival'
  local method='domain_practice provenance label: absolute presence + closed source grammar read from the plan alone, plus a Commit-0 set-difference against the Stage-4 comment when supplied'

  emit_prov() { printf '%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "$ISS" "$1" "$FAM" "$method" "$2" "$3" "$4"; }

  # (1) Applicability. Same corpus gate as fcm-delivery, verbatim: the governed
  #     population is defined by LOCATION. A target outside it is a NAMED skip, and
  #     it can never hide a real release, because a real release plan lives inside
  #     the corpus and takes the graded arms below.
  local in_corpus=0
  case "$plan" in */release/releases/plans/*) in_corpus=1 ;; esac
  if [ "$in_corpus" -eq 0 ]; then
    emit_prov "PROV-COVERAGE" "release-plan target" "$VERDICT_SKIP" \
      "prov-not-a-release-plan (target outside release/releases/plans/; no provenance obligation)"
    return 0
  fi

  # (2) Plan readability — fail closed. An absent or empty plan is NOT zero
  #     obligations; it is an unreadable state, and it says so.
  if [ ! -r "$plan" ] || [ ! -s "$plan" ]; then
    emit_prov "PROV-COVERAGE" "a readable plan file" "$VERDICT_ERROR" \
      "prov-plan-unreadable (plan absent or empty; an unreadable plan is NOT a plan with no obligations)"
    return 0
  fi

  local plan_lines; plan_lines="$(awk 'END{print NR}' "$plan")"

  # (3) Label extraction.
  local hits; hits="$(_prov_label_lines "$plan")"
  local labels_found; labels_found="$(printf '%s' "$hits" | grep -c . || true)"

  # (4) Delta-evidence resolution. Absent evidence is a NAMED SKIP, never PASS.
  local delta_source="absent" comment_state="none"
  if [ -n "$ARG_STAGE4_COMMENT" ]; then
    if [ ! -r "$ARG_STAGE4_COMMENT" ] || [ ! -s "$ARG_STAGE4_COMMENT" ]; then
      comment_state="unreadable"
    else
      comment_state="ok"
      delta_source="$(basename "$ARG_STAGE4_COMMENT")"
    fi
  fi

  # (5) Coverage record — ALWAYS emitted, so "the family never ran" is not
  #     byte-identical to "the family found nothing". Carries its denominators.
  local cov_note=""
  if [ "$labels_found" -gt 1 ]; then
    local lns; lns="$(printf '%s\n' "$hits" | awk -F'\t' 'NF{printf "%s%s", (n++?",":""), $1}')"
    # A plan whose Risk Register QUOTES the label pattern in prose lands here. It is
    # surfaced as a visible ambiguity for the reviewer with its line numbers, rather
    # than resolved silently in either direction.
    cov_note=" prov-multiple-labels:$labels_found at lines $lns (GRAMMAR grades the first)"
  fi
  emit_prov "PROV-COVERAGE" "an examined plan surface" "$VERDICT_PASS" \
    "labels_found=$labels_found plan_lines=$plan_lines delta_source=$delta_source delta_set=survival-rows-1-5-only (rows 6-9 are re-rendered prose and are reviewer-read by design)${cov_note}"

  # (6) PRESENCE — the absolute limb. Reads the plan ALONE. This is the arm that
  #     fires on the v4.37 shape, where the delta limb is genuinely empty.
  if [ "$labels_found" -eq 0 ]; then
    emit_prov "PROV-PRESENCE" "at least one conformant single-line label" "$VERDICT_FAIL" \
      "prov-label-absent (no domain_practice label in the 5.7 schema form on any single line; the Stage-13 close-class rung-1 read has no input)"
  else
    emit_prov "PROV-PRESENCE" "at least one conformant single-line label" "$VERDICT_PASS" \
      "prov-label-present:$labels_found"
  fi

  # (7) GRAMMAR — four limbs on the FIRST conformant label.
  if [ "$labels_found" -eq 0 ]; then
    emit_prov "PROV-GRAMMAR" "date + in-label domain + a Form A/B/X source" "$VERDICT_SKIP" \
      "prov-no-label-to-grade (PROV-PRESENCE FAILed; there is no label to grade)"
  else
    local body; body="$(printf '%s\n' "$hits" | awk -F'\t' 'NR==1{print $2}')"
    local d_val s_val s_norm s_form r_val fail=""
    d_val="$(_prov_field "$body" date)"
    s_val="$(_prov_field "$body" source)"
    r_val="$(_prov_field "$body" rationale)"
    s_norm="$(_prov_normalize_source "$s_val")"
    s_form="$(_prov_source_form "$s_norm")"

    # SIGPIPE-REWRITE ×2 — see the note at `recorded=1` above for the mechanism.
    # These two are the INVERTED (`if ! writer | grep -q`) form, where the failure is
    # worse than a missed finding: a conformant date or domain field is what makes
    # `grep -q` short-circuit, so the writer takes the broken pipe on exactly the
    # inputs that should PASS, and the limb reports a grammar FAIL against a
    # well-formed label. A here-string has no writer to signal.
    if ! grep -qE '^[0-9]{4}-[0-9]{2}-[0-9]{2}$' <<<"$d_val"; then
      fail="limb=date value=[$d_val] (mandatory in BOTH modes so staleness is detectable)"
    elif ! grep -qE '(^|[,{[:space:]])domain:[[:space:]]*[A-Za-z]' <<<"$body"; then
      fail="limb=domain value=[$body] (the mandatory in-label class field is absent, or the body is wrapped across lines so it fell off the matched line)"
    elif [ "$s_form" = "NONE" ]; then
      fail="limb=source value=[$s_norm] (not one of the three codified forms; route it per the 5.7 routing rule rather than minting a fourth)"
    elif [ "$s_form" = "B" ] && [ -z "$r_val" ]; then
      fail="limb=rationale value=[$s_norm] (Form B UNSOURCED-DOMAIN carries no rationale sibling; the flag is the carrier of a genuine gap and must say what the gap is)"
    fi

    if [ -n "$fail" ]; then
      emit_prov "PROV-GRAMMAR" "date + in-label domain + a Form A/B/X source" "$VERDICT_FAIL" \
        "prov-grammar-nonconformant $fail"
    else
      emit_prov "PROV-GRAMMAR" "date + in-label domain + a Form A/B/X source" "$VERDICT_PASS" \
        "prov-grammar-conformant form=$s_form date=$d_val"
    fi
  fi

  # (8) DELTA — the relative limb, over Survival-Set rows 1-5 only.
  if [ "$comment_state" = "unreadable" ]; then
    emit_prov "PROV-DELTA" "a readable Stage-4 comment" "$VERDICT_ERROR" \
      "prov-comment-unreadable (--stage4-comment supplied but the path is missing or empty; never infer an empty comment from an unreadable one)"
  elif [ "$comment_state" = "none" ]; then
    emit_prov "PROV-DELTA" "no survival element lost at transcription" "$VERDICT_SKIP" \
      "prov-no-stage4-comment-supplied (delta limb has no producer surface to compare; it does NOT pass by default)"
  else
    local c_elems p_elems lost
    c_elems="$(_prov_elements_present "$ARG_STAGE4_COMMENT")"
    p_elems="$(_prov_elements_present "$plan")"
    lost="$(printf '%s\n' "$c_elems" | awk -v have="$p_elems" '
      BEGIN { n = split(have, a, "\n"); for (i = 1; i <= n; i++) if (a[i] != "") seen[a[i]] = 1 }
      NF && !(seen[$0]) { printf "%s%s", (m++?",":""), $0 }')"
    local c_n; c_n="$(printf '%s' "$c_elems" | grep -c . || true)"
    if [ -n "$lost" ]; then
      emit_prov "PROV-DELTA" "no survival element lost at transcription" "$VERDICT_FAIL" \
        "prov-elements-lost:$lost (present in the Stage-4 comment, absent from the plan; denominator=$c_n)"
    else
      emit_prov "PROV-DELTA" "no survival element lost at transcription" "$VERDICT_PASS" \
        "prov-no-loss (comment_elements=$c_n all present in the plan)"
    fi
  fi

  return 0
}

# ===========================================================================
# Component 5 — emit_evidence(): render verdict records in the requested format.
# Records arrive on stdin as: issue \t id \t family \t method \t expected \t verdict \t observed
# ===========================================================================

# rollup_counts -- THE roll-up reader, shared by emit_md, emit_json and main()'s note (a
# count computed in two places ships its defect twice). The stream arrives on stdin;
# prints, space-separated: P F S U E (the five verdicts), R (every record -- the
# population P..E span), C A (cross-issue and always-on records), D X O (the SKIPs:
# declared-deferred, no command in method, other; D+X+O == S). THE PARENTHETICAL IS NOT
# A PARTITION BY CONSTRUCTION: R == N + C + A (N the parser's per-issue rows) holds on a
# complete stream, and a table-unindexable block record or a stream-truncated record
# belongs to none of the three -- the DEGRADED clause names the second. A NEW
# no-command reason must join the X pattern, or it counts as other.
rollup_counts() {
  awk -F'\t' '
    NF {
      r++
      if ($1 == "CIAC (integration)") c++
      else if ($3 == "fcm-delivery" || $3 == "provenance-survival") a++
      if      ($6 == "PASS")       p++
      else if ($6 == "FAIL")       f++
      else if ($6 == "UNRUNNABLE") u++
      else if ($6 == "ERROR")      e++
      else if ($6 == "SKIP") {
        s++
        if      ($7 ~ /^declared-deferred/) d++
        else if ($7 ~ /^(no-executable-command-in-method|documented-decision-method)/) x++
        else o++
      }
    }
    END { printf "%d %d %d %d %d %d %d %d %d %d %d\n", p, f, s, u, e, r, c, a, d, x, o }'
}

emit_md() {
  # Group by issue, preserving first-seen issue order. A record that carries no issue
  # value is shown under a `(plan)` header rather than dropped -- the roll-up below
  # counts it, so every counted record appears in a table -- and it shares that
  # bucket with the records the parser already attributes to `(plan)`. The key is KEPT
  # ON ONE LINE ON PURPOSE: the suite's mutation arm G19 M8 reverts it by one
  # substitution.
  local records; records="$(cat)"
  local issues
  issues="$(printf '%s\n' "$records" | awk -F'\t' 'NF{ k = ($1 == "" ? "(plan)" : $1); if(!seen[k]++) print k }')"
  printf '### Verification Evidence\n\n'
  local iss
  while IFS= read -r iss; do
    [ -z "$iss" ] && continue
    local title
    title="$(issue_title "$iss")"
    printf '**%s%s**\n' "$iss" "$title"
    printf '| Check | Family | Method (reproducible) | Expected | Observed | Verdict |\n'
    printf '|---|---|---|---|---|---|\n'
    printf '%s\n' "$records" | awk -F'\t' -v want="$iss" -v dash="-" 'NF && ($1 == "" ? "(plan)" : $1) == want {
      cid=$2; if (cid=="") cid=dash
      fam=$3; meth=$4
      expd=$5; if (expd=="") expd=dash
      verd=$6
      obs=$7; if (obs=="") obs=dash
      gsub(/\|/, "\\|", meth); gsub(/\|/, "\\|", expd); gsub(/\|/, "\\|", obs)
      printf "| %s | %s | %s | %s | %s | %s |\n", cid, fam, meth, expd, obs, verd
    }'
    printf '\n'
  done <<< "$issues"
  # THE ROLL-UP STATES ITS POPULATION, AND KEEPS WHAT THIS RUN DID NOT GRADE APART FROM
  # WHAT IT COULD NOT EVALUATE.
  #
  # `0 ERROR` alone is uninterpretable. A plan carrying NO per-issue verification table
  # scores 0 ERROR and exits 0, byte-identical on a bare counter line to a plan whose 26
  # rows all classified cleanly, so the line names its population: the R records its five
  # counters span (P+F+S+U+E == R, UNRUNNABLE included, so no row falls out of the
  # counts), and within them the N per-issue rows the parser indexed, the C cross-issue
  # criteria and the A always-on records. PER_ISSUE_ROWS is set by main() at the parser
  # boundary -- it cannot be recovered from the stream here, because several families
  # are reachable both from a per-issue row and from a source that is not one. The split
  # then says who decided each SKIP (D declared-deferred, X no command in method, O
  # other) and sets SKIP and UNRUNNABLE -- not graded by this run -- apart from ERROR,
  # the only non-FAIL clause that fails the run.
  local p f s u e r c a d x o deg="" pop split
  read -r p f s u e r c a d x o <<<"$(printf '%s\n' "$records" | rollup_counts)"
  pop="over ${r} record(s) (${PER_ISSUE_ROWS:-0} per-issue row(s), ${c} cross-issue, ${a} always-on)"
  split="not graded by this run: ${s} SKIP (${d} declared-deferred, ${x} no command in method, ${o} other) and ${u} UNRUNNABLE; could not evaluate: ${e} ERROR"
  # A DEGRADED stream ANNOTATES the roll-up rather than completing it (FD-0): the
  # counts are real, but over only the records that reached dispatch. Empty on a
  # complete stream, so every other roll-up line is byte-identical.
  if [ -n "${STREAM_DEGRADED:-}" ]; then
    deg=" — **DEGRADED:** ${STREAM_DEGRADED} (the verdict stream is partial, so the counts above cover only the records that reached dispatch; an absent row is NOT a pass)"
  fi
  if [ "${PER_ISSUE_ROWS:-0}" -eq 0 ]; then
    printf '**Verdict roll-up:** %s PASS / %s FAIL / %s SKIP / %s UNRUNNABLE / %s ERROR %s — **no per-issue verification table found** (0 rows indexed: none of these counts covers a per-issue criterion); %s%s\n' "$p" "$f" "$s" "$u" "$e" "$pop" "$split" "$deg"
  else
    printf '**Verdict roll-up:** %s PASS / %s FAIL / %s SKIP / %s UNRUNNABLE / %s ERROR %s — %s%s\n' "$p" "$f" "$s" "$u" "$e" "$pop" "$split" "$deg"
  fi
}

emit_json() {
  local records; records="$(cat)"
  printf '{\n  "schema_version": "%s",\n  "cli_version": "%s",\n  "checks": [\n' "$SCHEMA_VERSION" "$CLI_VERSION"
  printf '%s\n' "$records" | awk -F'\t' 'NF{
    if (started) printf ",\n"; started=1
    gsub(/"/,"\\\"",$4); gsub(/"/,"\\\"",$7)
    printf "    {\"issue\":\"%s\",\"id\":\"%s\",\"family\":\"%s\",\"method\":\"%s\",\"expected\":\"%s\",\"observed\":\"%s\",\"verdict\":\"%s\"}", $1,$2,$3,$4,$5,$7,$6
  }'
  printf '\n  ],\n'
  # Same population and split as emit_md, through the one reader (rollup_counts):
  # pass + fail + skip + unrunnable + error == records, and declared_deferred +
  # no_command + skip_other == skip. `declared_deferred` counts the observed reason,
  # so a deferral a handler guard declines counts too; it is reported but is NOT an
  # invariant: it moves every time a card renders a deferred AC row executable.
  # `per_issue_rows` is the stable one; bind regression arms to it.
  local p f s u e r c a d x o st="fetched"
  read -r p f s u e r c a d x o <<<"$(printf '%s\n' "$records" | rollup_counts)"
  # The FD-0 measurement state, on EVERY run, so a consumer can branch on it
  # before it reads a counter: `fetched` when both dispatch loops read every
  # record the parser produced, `truncated` when one fell short (see FD-0).
  if [ -n "${STREAM_DEGRADED:-}" ]; then st="truncated"; fi
  printf '  "rollup": {"pass": %s, "fail": %s, "skip": %s, "unrunnable": %s, "error": %s, "records": %s, "per_issue_rows": %s, "cross_issue_records": %s, "always_on_records": %s, "declared_deferred": %s, "no_command": %s, "skip_other": %s, "stream_state": "%s", "records_parsed": %s, "records_read": %s}\n}\n' \
    "$p" "$f" "$s" "$u" "$e" "$r" "${PER_ISSUE_ROWS:-0}" "$c" "$a" "$d" "$x" "$o" "$st" "${STREAM_PARSED:-0}" "${STREAM_READ:-0}"
}

emit_table() {
  local records; records="$(cat)"
  printf '%sVerification Evidence%s\n' "$(c_bold)" "$(c_reset)"
  # The verdict column is as wide as the widest verdict, UNRUNNABLE (10 characters),
  # so every row's method starts in the same column.
  printf '%s\n' "$records" | awk -F'\t' 'NF{ printf "  %-8s %-14s %-10s %s\n", $1, $3, $6, $4 }'
}

# ---------------------------------------------------------------------------
# issue_title / issue_title-cache: best-effort friendly title from the plan's
# per-issue headers (kept purely cosmetic; absence yields an empty suffix).
# ---------------------------------------------------------------------------
issue_title() {
  local iss="$1" raw t
  # Pull the raw header line for this issue (awk stays ASCII-only: it just
  # matches the header and prints from after the issue number to the closing **).
  raw="$(awk -v want="$iss" '
    /^\*\*#[0-9]+/ {
      match($0, /#[0-9]+/); id = substr($0, RSTART, RLENGTH)
      if (id == want) {
        line = $0
        sub(/^\*\*#[0-9]+[ ]*/, "", line)   # drop "**#N " prefix
        sub(/\*\*.*$/, "", line)             # drop trailing "**..."
        print line; exit
      }
    }' "$PLAN_ABS")"
  # Strip a leading dash separator (ASCII "-" or the em-dash) in the shell, so
  # no non-ASCII byte ever appears inside an awk program (BSD awk chokes on it).
  t="$(printf '%s' "$raw" | sed -e 's/^[[:space:]]*//' -e 's/^—[[:space:]]*//' -e 's/^-[[:space:]]*//' -e 's/[[:space:]]*$//')"
  if [ -n "$t" ]; then printf ' - %s' "$t"; fi
}

# ===========================================================================
# Orchestration
# ===========================================================================
main() {
  parse_args "$@"
  resolve_root
  resolve_sibling_tools
  resolve_plan

  # The CIAC authoring lint (Stage 4, gate criterion G4-06) answers here and exits. It
  # reads the plan and runs nothing, so it needs no memo file, no release key and no
  # dispatch, and it emits no Verification Evidence record.
  if [ "$ARG_CIAC_LINT" -eq 1 ]; then
    if ciac_lint "$PLAN_ABS"; then exit "$EXIT_OK"; else exit "$EXIT_CHECK_FAILED"; fi
  fi

  # Per-run memo files for the deploy --check result (so a plan with several
  # sync/regression rows runs the heavy check once) and for the release diff the
  # scope family grades (resolved at most once). Both cleaned on exit.
  DEPLOY_CHECK_CACHE="$(mktemp -t verify-release-plan-deploycheck.XXXXXX)"
  SCOPE_DIFF_CACHE="$(mktemp -t verify-release-plan-scopediff.XXXXXX)"
  # shellcheck disable=SC2064
  trap "rm -f '$DEPLOY_CHECK_CACHE' '$SCOPE_DIFF_CACHE'" EXIT

  # Release join key for the runtime-suite event: the MILESTONE SLUG, per
  # pipeline-event-log-schema.md § 2a. This used to parse `v<maj>.<min>` out of
  # the plan filename and fall back to the literal `v0.0.0` — a synthesized,
  # version-shaped placeholder that sorts into the version space and is
  # indistinguishable from a real release to every consumer. The writer now
  # rejects both forms, so this resolves a slug or the reserved `(none)`.
  local plan_version
  plan_version="$(resolve_plan_release_key "$PLAN_ABS")"

  # 1) Parse per-issue verification-plan check records + CIAC integration records.
  local per_issue_records ciac_records
  per_issue_records="$(parse_verification_plan "$PLAN_ABS" || true)"
  # THE DENOMINATOR IS COUNTED HERE, at the parser boundary, because this is
  # the only point at which the indexed-row population is known. Downstream,
  # every record has been relabelled with a FAMILY, and several families
  # (integration, sync, regression, deferred) are reachable both from a
  # per-issue row and from a source that is not a per-issue row at all.
  # `table-unindexable` is a BLOCK-level diagnostic, not a per-issue row: it
  # grades no row and reports how many a table suppressed. Counting it here would
  # inflate the very denominator the roll-up exists to make honest, so it is
  # excluded. `parity-error` and `method-cell-empty` ARE per-row records and stay
  # counted.
  # KEPT ON ONE LINE ON PURPOSE, for the same reason handle_runtime_suite is:
  # the suite zeroes this counter with a single anchored substitution, and a
  # line-based mutator cannot reach a statement split across a continuation.
  PER_ISSUE_ROWS="$(printf '%s' "$per_issue_records" | awk -F"$REC_FS" 'NF && $3 != "table-unindexable" { n++ } END { print n+0 }')"
  ciac_records="$(parse_ciac "$PLAN_ABS" || true)"

  # 2) Dispatch each record → verdict, building the emit stream:
  #    issue \t id \t family \t method \t expected \t verdict \t observed
  local stream=""
  local issue id family method expected verdict_observed verdict observed

  # Records read per loop, against records parsed -- the FD-0 completeness
  # tripwire. Each counter is the FIRST statement of its loop body, so a record
  # that reached the body is counted before anything in it can skip the record.
  local pi_read=0 pi_total=0 ci_read=0 ci_total=0

  # Per-issue records: fields = issue \t ac \t PENDING \t method \t expected
  if [ -n "$per_issue_records" ]; then
    pi_total="$(printf '%s\n' "$per_issue_records" | awk 'END { print NR }')"
    # FD-0: the body runs on the null device; only `read` consumes the stream.
    while IFS="$REC_FS" read -r issue id _pending method expected; do {
      pi_read=$((pi_read + 1))
      [ -z "$issue$method" ] && continue
      # The parser marks a row it refused to index with an explicit family rather
      # than the PENDING marker, so the shell classifier is never handed cells it
      # would be reading at shifted column indices. That guarantee is now
      # STRUCTURAL rather than aspirational: under REC_FS an empty field no longer
      # collapses, so the marker is read at the position it was written to.
      case "$_pending" in
        parity-error|table-unindexable|method-cell-empty) family="$_pending" ;;
        *) family="$(classify_family "$method")" ;;
      esac
      verdict_observed="$(dispatch_check "$family" "$method" "$expected" "$plan_version")"
      verdict="$(printf '%s' "$verdict_observed" | cut -f1)"
      observed="$(printf '%s' "$verdict_observed" | cut -f2)"
      stream="${stream}${issue}	${id}	${family}	${method}	${expected}	${verdict}	${observed}
"
    } </dev/null; done <<< "$per_issue_records"
  fi
  if [ "$pi_read" -lt "$pi_total" ]; then
    stream="${stream}(plan)	STREAM	stream-truncated	per-issue dispatch loop	read ${pi_total} of ${pi_total}	${VERDICT_ERROR}	verdict-stream-truncated (read ${pi_read} of ${pi_total} parsed per-issue records; every record after record ${pi_read} was lost before dispatch — an absent row is NOT a pass)
"
    STREAM_DEGRADED="read ${pi_read} of ${pi_total} parsed per-issue records"
  fi

  # CIAC records: fields = id \t issues \t integration \t method \t predicate
  if [ -n "$ciac_records" ]; then
    ci_total="$(printf '%s\n' "$ciac_records" | awk 'END { print NR }')"
    # FD-0: the body runs on the null device; only `read` consumes the stream.
    while IFS="$REC_FS" read -r id issue family method expected; do {
      ci_read=$((ci_read + 1))
      [ -z "$id" ] && continue
      # family is "integration", or "parity-error" for a row the parser refused
      # to index; group CIAC rows under an "integration" pseudo-issue label
      # carrying the spanned issues for the evidence table.
      if [ "$family" != "parity-error" ]; then family="integration"; fi
      verdict_observed="$(dispatch_check "$family" "$method" "$expected" "$plan_version")"
      verdict="$(printf '%s' "$verdict_observed" | cut -f1)"
      observed="$(printf '%s' "$verdict_observed" | cut -f2)"
      # Emit under a stable "CIAC (integration)" issue bucket so the evidence
      # section shows cross-issue checks together; the id carries CIAC-N and the
      # spanned issues ride in the Expected column for traceability.
      local span_note="spans ${issue}"
      stream="${stream}CIAC (integration)	${id}	${family}	${method}	${span_note}	${verdict}	${observed}
"
    } </dev/null; done <<< "$ciac_records"
  fi
  if [ "$ci_read" -lt "$ci_total" ]; then
    stream="${stream}CIAC (integration)	CIAC-STREAM	stream-truncated	cross-issue dispatch loop	read ${ci_total} of ${ci_total}	${VERDICT_ERROR}	verdict-stream-truncated (read ${ci_read} of ${ci_total} parsed cross-issue records; every record after record ${ci_read} was lost before dispatch — an absent row is NOT a pass)
"
    STREAM_DEGRADED="${STREAM_DEGRADED:+$STREAM_DEGRADED; }read ${ci_read} of ${ci_total} parsed cross-issue records"
  fi
  STREAM_PARSED=$((pi_total + ci_total))
  STREAM_READ=$((pi_read + ci_read))

  # 2c) fcm-delivery — the THIRD record source.
  #
  # WIRED HERE ON PURPOSE, AND ALWAYS-ON. Every other family reaches dispatch only
  # via a record the plan itself declares, which means a family nothing produces a
  # record for is unreachable and its absence is indistinguishable from a pass. A
  # declared-vs-delivered gate that a release can omit by simply not declaring it
  # would reproduce, one layer up, exactly the defect it exists to catch. So this
  # family is not plan-declared: it fires on every invocation, and when it has
  # nothing to assert it says so in a record rather than by being absent.
  local fcm_records
  fcm_records="$(handle_fcm_delivery "$PLAN_ABS" || true)"
  if [ -n "$fcm_records" ]; then
    stream="${stream}${fcm_records}
"
  fi

  # 2d) provenance-survival — the FOURTH record source.
  #
  # ALWAYS-ON, for the same reason 2c is. A provenance gate a release could omit by
  # simply not declaring it would reproduce, one layer up, the exact defect it exists
  # to catch: the label went missing because nothing was watching, and a plan-declared
  # watcher can go missing the same way. So this family is not plan-declared either —
  # it fires on every invocation, and when it has nothing to assert it says so in a
  # record rather than by being absent.
  local prov_records
  prov_records="$(handle_provenance_survival "$PLAN_ABS" || true)"
  if [ -n "$prov_records" ]; then
    stream="${stream}${prov_records}
"
  fi

  # NO PER-ISSUE ROWS PARSED → not an error, but say so honestly on stderr.
  #
  # This guard used to test `-z "$stream"` and was STRUCTURALLY DEAD.
  # fcm-delivery and provenance-survival are always-on and EVERY code path in
  # both emits a *-COVERAGE record, so the stream is never empty and this
  # warning could never fire. A guard that cannot fire is precisely the defect
  # class this tool exists to name, sitting inside the tool. Re-pointed onto
  # the population it was actually written about.
  if [ "$PER_ISSUE_ROWS" -eq 0 ]; then
    err "no per-issue verification checks parsed from $(basename "$PLAN_ABS") — is the Verification Plan section present and table-shaped? 0 rows were indexed, so no count in the roll-up below covers a per-issue criterion."
  fi

  # The rows this run did not grade are named on stderr as well as counted in the
  # roll-up: a row with no command in its method and no declaration (a named SKIP), and
  # an UNRUNNABLE row. Both are outside the exit predicate below, so a clean exit does not
  # cover them, and the note says so where a reader of the exit status will see it.
  local _p _f _s nu _e _r _c _a _d nx _o
  read -r _p _f _s nu _e _r _c _a _d nx _o <<<"$(printf '%s' "$stream" | rollup_counts)"
  if [ "$nx" -gt 0 ] || [ "$nu" -gt 0 ]; then
    note "$((nx + nu)) check(s) were not graded by this run: $nx with no command in method and no declaration, $nu UNRUNNABLE. This run's exit status covers none of them: a row with no command is graded where its criterion is graded (declare that runner: [DEFERRED — <reason>]), and an UNRUNNABLE row names the tool or the reason it could not run -- its guarantee is carried by the surface it names, or by nothing."
  fi

  # 3) Emit in the requested format.
  case "$ARG_FORMAT" in
    md)    printf '%s' "$stream" | emit_md ;;
    json)  printf '%s' "$stream" | emit_json ;;
    table) printf '%s' "$stream" | emit_table ;;
  esac

  # 4) Exit. A DEGRADED stream is the EXECUTOR's failure, not the plan's: the rows
  #    it lost were never measured, so the run exits EXIT_INTERNAL -- a distinct
  #    code that carries the state across the process boundary -- ahead of the
  #    plan-failure code (see FD-0).
  if [ -n "$STREAM_DEGRADED" ]; then
    err "verdict stream DEGRADED — ${STREAM_DEGRADED}; exit ${EXIT_INTERNAL} (internal): records were lost before dispatch, so this run is not a verdict on the plan"
    exit "$EXIT_INTERNAL"
  fi
  # Otherwise exit non-zero if any FAIL or ERROR verdict is present (CI-consumable).
  # UNRUNNABLE and SKIP are absent from this predicate on purpose (the verdict enum
  # doctrine above): a relabel must not turn a historical plan red.
  if printf '%s' "$stream" | awk -F'\t' '$6=="FAIL"||$6=="ERROR"{found=1} END{exit !found}'; then
    exit "$EXIT_CHECK_FAILED"
  fi
  exit "$EXIT_OK"
}

main "$@"
