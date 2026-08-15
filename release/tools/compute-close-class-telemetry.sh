#!/usr/bin/env bash
# compute-close-class-telemetry.sh — Close-class telemetry for a release.
# Per release/references/standards/close-class-telemetry.md.
# Sibling to compute-release-velocity.sh — same form factor, same exit-code contract.
#
# Emits the **Close-Class-Telemetry:** field content for the visible-H4 Deployment
# Log block in RELEASE_LOG.md. The field is a Stage-13 field (the registers,
# carry-forward closure, and close-gate are authoritative only at close),
# forward-only / grandfathered — see the standard § Cutover.
#
# MECHANICAL-SOURCE (filesystem registers + gh state), NOT the event log — this is
# the deliberate boundary distinguishing it from the cycle-time / DORA read-models
# (the standard § 8). It computes:
#   Indicator 1 retro-conformance     : conformant canonical-form section markers
#                                        present / expected, grepping the operator-
#                                        instance retro register (verbatim Kerth +
#                                        PMBOK 7 headers per release-learnings-
#                                        register-template.md).
#   Indicator 2 lessons-population     : populated lessons/actions rows / template-
#                                        prompted rows in the lessons register.
#   Indicator 3 carry-forward-closure  : closed `status: deferred` issues / raised,
#                                        over the milestone (per deferred-item-
#                                        tracking.md).
#   Indicator 4 pattern-emergence      : POINTER ONLY — deferred-to-aggregate; the
#                                        rate is owned by synthesize-release-
#                                        learnings.sh and never recomputed here.
#   Indicator 5 rollup-presence        : present|absent|N/A — the Stage-13 A7.1
#                                        recommendation<->choice roll-up, read from the
#                                        retro / lessons register (the rate is DEFERRED,
#                                        denominator undefined). MEASURED HERE, never
#                                        supplied by the caller — see the note below.
#   Indicator 6 evidence-preservation  : <P>/<S> (<ratio>) — phase-completion evidence
#                                        preservation read-model over the hub-spoke
#                                        sub-task `gh` state (NO net-new store): CLOSED
#                                        stage sub-tasks carrying >=1 trusted-authored
#                                        output/skip-closure comment (P) / MEASURABLE
#                                        stage sub-tasks scaffolded for the release (S —
#                                        terminal stages 12/13 EXCLUDED, since capture
#                                        happens during them; see count_subtask_evidence).
#                                        The single Stage-13 G-CL4 close-gate boolean is
#                                        RETAINED as evidence-close-gate (pass|fail|N/A).
#                                        Mechanical gh-state read — honors the § 8
#                                        boundary (NOT the event log).
#
# Ratio rounding mode is round-half-up, taken by reference from
# bundle-composition-doctrine.md § 3 Step 5 (the single definitional home) — NOT
# re-derived here.
#
# INDICATOR 5 MEASURES THE ROLL-UP LIMB ONLY, and that is deliberate.
# close-class-telemetry.md defines Indicator 5 as a CONJUNCTION: the release-level
# `Outcome:` field AND the Stage-13 A7.1 recommendation<->choice roll-up. Conjunct A —
# the `Outcome:` field — is written by the close-out run itself (phase 6.5 injects it, or
# SKIPs because it is already present; the only other exit aborts the run before this
# field is ever composed). Probing something the same run just wrote is not a measurement:
# it returns "present" on every apply-mode run, and publishing that under a
# `mechanism: compute-close-class-telemetry.sh` label asserts a tool measured what the run
# authored. A conjunction A AND B whose A is true BY CONSTRUCTION reduces to B, so this
# tool measures B — the roll-up limb, which is operator-authored in a register no close-out
# phase writes — and discharges A as a documented construction invariant rather than a
# fabricated reading. Value domain: present | absent | N/A — no retro register found.
# The eight-slot grammar is untouched; only this slot's value domain widens (the standard
# already permits `N/A (reason)` in any slot).
#
# Usage:
#   ./compute-close-class-telemetry.sh <version> --milestone <N> [--retro <path>] [--lessons <path>]
#                                               # the **Close-Class-Telemetry:** field value
#   ./compute-close-class-telemetry.sh <version> --milestone <N> --json
#                                               # machine detail: JSON of all indicators
#   ./compute-close-class-telemetry.sh --self-test   # validate logic against synthetic input
#   ./compute-close-class-telemetry.sh --help        # this help text
#
# Inputs:
#   <version>          release version key (e.g. v1.00) — for the field label + register resolution.
#   --milestone <N>    GitHub milestone NUMBER whose `status: deferred` membership is the
#                      carry-forward-closure population (Indicator 3).
#   --retro <path>     OPTIONAL explicit path to the version's retro register (Indicator 1).
#                      When omitted, resolves the operator-instance register path by convention;
#                      absent register -> Indicator 1 N/A.
#   --lessons <path>   OPTIONAL explicit path to the version's lessons register (Indicator 2).
#                      Defaults to --retro's path (the template carries both blocks in one file);
#                      absent -> Indicator 2 N/A.
#   --outcome-present <any>   DEPRECATED, ACCEPTED-AND-IGNORED. It was a caller-supplied
#                      Indicator-5 override; Indicator 5 is now measured here from the retro
#                      register (see the note above), so a caller-supplied value would only
#                      re-open the fabrication path it was retired to close. Passing it emits
#                      a one-line stderr deprecation notice and changes nothing. It is
#                      tolerated for one release so an existing caller does not hard-fail on
#                      an unknown flag, then removed. Its value is no longer domain-checked.
#   --close-gate {pass|fail|na}  OPTIONAL Indicator-6 G-CL4 close-gate verdict — the
#                      RETAINED secondary sub-signal alongside the phase-evidence rate
#                      (the rate is primary; the boolean loses no signal). Default: na.
#
# Cutover: applies to releases entering Stage 13 strictly AFTER this field's
# introducing-release merge SHA. The introducing release itself is exempt. This
# script does not gate by version — the caller (Stage 13 spoke) honors cutover.
#
# Exit codes (stated against MEASURED behaviour — a caller may rely on exactly this):
#   0 = success, INCLUDING every degraded path. An absent register, an unavailable gh, or
#       an unresolvable repo each set an N/A reason for the indicators they feed and the
#       run still emits a fully conformant eight-slot line at exit 0.
#   1 = argument validation ONLY — unknown flag, unexpected positional, missing <version>,
#       missing --milestone, out-of-domain --close-gate.
#   2 = a register that EXISTS but is UNREADABLE (an I/O / permission condition, not a
#       content condition — no content-validity path exits non-zero), or a sub-task
#       evidence payload that cannot be parsed. Source-integrity violation; escalate.
#
#   A CALLER CANNOT DISTINGUISH THE gh-UNAVAILABLE PATH BY EXIT CODE, and must not try.
#   That disposition is readable only from the emitted line — `carry-forward-closure
#   N/A — gh unavailable …` and `evidence-preservation N/A — gh unavailable …`.
#
# NO EXIT CODE IS ADDED FOR A DEGRADED OR UNMEASURABLE INDICATOR 6, and that is deliberate.
# The consumer (automated-closeout.sh, phase_inject_close_class_telemetry_field) routes ANY
# non-zero exit to FAIL and returns 3, aborting the close-out phase. Signalling a measurement
# outage by exit code would therefore convert "the check could not measure" into a merge-
# blocking gate — which review-discipline-principles.md § 8 PV-7c forbids in terms, and which
# would silently invalidate two sibling standards (phase-telemetry-front-cluster.md,
# phase-telemetry-middle-cluster.md) that both declare they mirror this tool's 0/1/2 exit
# semantics. The rule the states follow is that the CONDITION'S KIND picks the transport: a
# measurement outage never gates and rides IN-BAND in slot 6; an input failure the caller
# handed us is what exit 1 already covers. A future reader who reads this divergence as an
# oversight and "fixes" it into an exit code re-opens exactly that gate.
#
# INDICATOR 6 SLOT-6 RENDERINGS — three shapes, and the distinction between the last two is
# the whole point:
#   <P>/<S> (<ratio>)                          a clean measured rate
#   N/A — <reason>                             a CLEAN ABSENCE — a genuine zero, or a
#                                              population that is entirely terminal-stage
#   <TOKEN> — <reason> — this is not a clean result
#                                              a degraded or unmeasurable reading
# TOKEN is a Register B member frozen by review-discipline-principles.md § 8 PV-7 and NO
# local token is coined here: NOT-EVALUATED when nothing usable was measured, DEGRADED when a
# rate was computed over a known-incomplete sample. Both always carry the mandated clause.
# On a NOT-EVALUATED state the counters are ABSENT, never zeroed (PV-7b), so --json publishes
# null rather than a fabricated "0" for a run that measured nothing. --json additionally
# reports the Register A measurement status (fetched | truncated | degraded | not-run |
# fixture) and the unlabelled-candidate count; a consumer MUST branch on that status before
# reading any counter. `N/A — no stage sub-tasks scaffolded` stays reserved for a GENUINE
# zero and never renders an unmeasurable one.
#
#   NO STATE STRING MAY CONTAIN A SEMICOLON. The eight-slot field grammar
#   (automated-closeout.sh _close_class_line_conformant, deploy.sh Check 48) splits the field
#   on `; `, so a semicolon inside a slot silently corrupts the field rather than failing it.
#   The --self-test asserts this directly over every reachable rendering.
#
# Diagnostics go to stderr; stdout carries the single field-value line and nothing else.

set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md (BLOCK-DESTRUCTIVE-020).
# gh is resolved by absolute discovery below (not on the pinned PATH).
export PATH="/usr/bin:/bin"

# ─── Repo-relative paths ─────────────────────────────────────────────────────

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"

die() { echo "ERROR: $*" >&2; exit "${2:-1}"; }

usage() {
  # Line range = the header comment block, lines 4..145 (ends at the "Diagnostics go to
  # stderr" line, immediately before the blank line and `set -euo pipefail`). Re-check this
  # range whenever the header grows or shrinks; a stale upper bound silently truncates --help.
  /usr/bin/sed -n '4,145p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# Resolve gh off the pinned PATH (commonly /opt/homebrew/bin or /usr/local/bin).
# Empty when not installed — callers that need it (Indicator 3) fail with a clear
# message; --self-test never needs it.
find_gh() {
  local c
  for c in /opt/homebrew/bin/gh /usr/local/bin/gh /usr/bin/gh "$HOME/.local/bin/gh"; do
    [[ -x "$c" ]] && { printf '%s' "$c"; return 0; }
  done
  command -v gh 2>/dev/null || true
}

# ─── The canonical-form section markers (Indicator 1) ────────────────────────
# Verbatim headers from release-learnings-register-template.md. The template
# mandates these be kept verbatim precisely so this read-model can grep them.
# Kept as exact line-anchored strings (a marker counts as present iff a line
# EQUALS it, after trimming — not a substring, to avoid false positives).
CANONICAL_MARKERS=(
  "## 1. Kerth Retrospective (full ceremony)"
  "### 1.1 Prime Directive (recite before reflecting)"
  "### 1.2 Three-question framework"
  "### 1.3 Ritual of closure"
  "## 2. PMBOK 7 Lessons-Learned (full ceremony)"
  "### 2.1 Situation"
  "### 2.2 Outcome"
  "### 2.3 Lessons"
  "### 2.4 Next-cycle Actions"
  "## 3. Triple Linkage (records the COEXIST relationship)"
)
EXPECTED_MARKERS=${#CANONICAL_MARKERS[@]}   # 10 canonical-form markers

# ─── The A7.1 roll-up section marker (Indicator 5) ───────────────────────────
# A SEPARATE array — deliberately NOT appended to CANONICAL_MARKERS. That array is
# Indicator 1's DENOMINATOR (EXPECTED_MARKERS above): appending an eleventh entry would
# silently move retro-conformance from /10 to /11 and retroactively depress the rate on
# every register already written, biasing the calibration baseline this whole field feeds.
# Two arrays, two questions, two denominators.
#
# Same matching discipline as Indicator 1: the header is mandated verbatim in
# release-learnings-register-template.md precisely so this read-model can grep it, and a
# marker counts as present iff a whole line matches it exactly (grep -Fxq) — never as a
# substring, so a stray mention of the phrase in prose cannot read as a roll-up.
ROLLUP_MARKERS=(
  "## 4. Recommendation↔choice delta roll-up (Stage 13 A7.1)"
)

# ─── The competing category labels (Indicator 6 Layer 2) ─────────────────────
# A THIRD array, under the same discipline as ROLLUP_MARKERS and for the same reason: it is
# a FILTER, never a population the rate is computed over, and folding it into either marker
# array would move a denominator. Three arrays, three questions, three denominators.
#
# SSOT: the `group = "category"` rows of core/packs/_common/pack.toml, less `sub-task`
# itself. label-taxonomy.md § Rules 1 mandates EXACTLY ONE category label per issue, and
# `sub-task` IS one of those category rows — so a scaffolded stage sub-task whose label went
# missing carries NO category label at all, while an ordinary intake card always carries
# exactly one. That documented invariant, not a hand-picked blocklist, is what separates a
# genuine unlabelled sub-task from an intake card that merely has a stage in its title.
#
# DRIFT IS FAIL-SAFE BY CONSTRUCTION. The taxonomy is the union of the installed packs, so a
# pack that adds a category label drifts this array. An UNLISTED label leaves its issue
# inside the candidate set, which produces a spurious NON-GATING flag — never a missed one.
# The failure direction is loud, which is the direction this whole guard exists to enforce.
CATEGORY_LABELS_EXCEPT_SUBTASK=(
  improvement protocol skill-update structure documentation
  enhancement routing-rules tracker-schema bug observation
)

# The row bound on BOTH Indicator-6 reads. Held as a constant rather than repeated as a
# literal because the saturation guard below compares against it: a `--limit` and a
# saturation test that drifted apart would report a truncated read as a complete one.
SUBTASK_QUERY_LIMIT=500

# ─── Indicator 5: A7.1 roll-up presence ──────────────────────────────────────
# Returns 0 iff any ROLLUP_MARKERS entry appears as an exact whole line in the register.
# Mirrors count_retro_conformance's technique verbatim rather than restating it.
rollup_marker_present() {
  local file="$1" m
  for m in "${ROLLUP_MARKERS[@]}"; do
    if /usr/bin/grep -Fxq "$m" "$file" 2>/dev/null; then
      return 0
    fi
  done
  return 1
}

# ─── round-half-up ratio (the canonical mode, by reference) ──────────────────
# Compute numerator/denominator to 2 decimals using round-half-up at the 2nd
# decimal. Pure-integer arithmetic (no float drift). Echoes "0.00".."1.00"+ ;
# echoes "N/A" when denominator == 0.
ratio_round_half_up() {
  local num="$1" den="$2"
  if [[ "$den" -eq 0 ]]; then echo "N/A"; return 0; fi
  local hundredths=$(( (num * 10000 + den * 50) / (den * 100) ))
  /usr/bin/printf '%d.%02d\n' "$(( hundredths / 100 ))" "$(( hundredths % 100 ))"
}

# ─── Indicator 1: retro canonical-form conformance ───────────────────────────
# Count how many of the CANONICAL_MARKERS appear as exact (trimmed) lines in the
# retro file. Echoes "<present> <expected>" on stdout. Caller forms the ratio.
count_retro_conformance() {
  local file="$1"
  local present=0 m
  for m in "${CANONICAL_MARKERS[@]}"; do
    # exact-line match (trim trailing CR/space). grep -Fx = fixed-string, whole-line.
    if /usr/bin/grep -Fxq "$m" "$file" 2>/dev/null; then
      present=$(( present + 1 ))
    fi
  done
  echo "$present $EXPECTED_MARKERS"
}

# ─── Indicator 2: lessons-register population ────────────────────────────────
# A template-prompted row is a markdown table row whose first cell is an L<n> or
# A<n> id (the template's `| L1 | ... |` Lessons rows + `| A1 | ... |` Actions
# rows). It is POPULATED iff no content cell is still the verbatim `<…>`
# placeholder (the template uses the U+2026 horizontal-ellipsis placeholder).
# Echoes "<populated> <prompted>".
count_lessons_population() {
  local file="$1"
  /usr/bin/python3 - "$file" <<'PY'
import sys, re
path = sys.argv[1]
prompted = 0
populated = 0
placeholder = "…"  # the template's <…> ellipsis placeholder
try:
    with open(path, encoding="utf-8") as f:
        for line in f:
            s = line.strip()
            if not s.startswith("|"):
                continue
            cells = [c.strip() for c in s.strip("|").split("|")]
            if not cells:
                continue
            first = cells[0]
            # template-prompted row: first cell is an L<n> or A<n> id
            if re.fullmatch(r"[LA]\d+", first):
                prompted += 1
                # populated iff NO content cell still carries the <…> placeholder
                content = cells[1:]
                if content and not any(placeholder in c for c in content):
                    populated += 1
except (OSError, UnicodeDecodeError) as e:
    print(f"lessons register unreadable: {e}", file=sys.stderr)
    sys.exit(2)
print(f"{populated} {prompted}")
PY
}

# ─── Indicator 6: phase-completion evidence preservation (read-model over sub-task gh state) ─
# Bounded read-model, NO net-new store. The per-stage hub-spoke sub-task surface IS the
# evidence trail: the hub scaffolds one `sub-task`-labelled issue per release-execution stage
# and closes it ONLY after consuming its output comment (skipped stages carry a skip-closure
# comment). A CLOSED sub-task carrying >=1 trusted-authored comment = phase-completion evidence
# preserved.
#   Denominator S = MEASURABLE stage sub-tasks scaffolded for the release (milestone +
#                   label:sub-task), EXCLUDING the terminal stages 12 (Execute) and 13 (Close).
#   Numerator   P = those CLOSED with >=1 trusted-authored (output / skip-closure) comment.
#
# TERMINAL-STAGE EXCLUSION (why S is not simply the scaffolded count). The field's mandated
# capture moment is the Stage-13 Phase B chore PR (close-class-telemetry.md § 3.2) — i.e.
# DURING stage 13, with stage 12/13 evidence not yet terminal. Counting stages 12/13 in S made
# the published rate a function of WHEN it was read rather than of how well evidence was
# preserved: three readings of one live milestone moved 0.46 -> 0.61 -> 0.75 with the numerator
# equal to the closed count every time (100% of the variance was measurement timing). Excluding
# the two terminal stages makes the rate measure the thing its name claims. Detection is by the
# sub-task title's `Stage <N>` prefix; a title that does not parse to a stage number is RETAINED
# (fail-safe — never shrink the denominator on an unrecognized title).
#
# "Trusted-authored" = comment authorAssociation in {OWNER, MEMBER, COLLABORATOR, CONTRIBUTOR}
# (guards a public drive-by comment on a CLOSED sub-task from counting as evidence); when the
# payload carries no authorAssociation, or `comments` is an integer count, falls back to
# comment-presence (>=1). Echoes "<P> <S> <X>" (X = terminal-stage sub-tasks excluded) from a
# JSON array of {number,title,state,comments} (both the gh-issue-list array shape and an
# integer-count shape are accepted). Exit 2 on unparseable source (integrity violation).
#
# PAYLOAD TRANSPORT — the payload must NEVER travel as an argv operand. `gh issue list
# --json number,title,state,comments` over a real milestone returns every sub-task's full
# comment bodies; that routinely exceeds the platform argument limit (measured 1,098,975 B
# against an ARG_MAX of 1,048,576), and the interpreter then never starts at all —
# `/usr/bin/python3: Argument list too long`, no indicator produced, the whole script dead.
# The heredoc already occupies stdin, so the payload travels on a process-substitution FD
# whose PATH is the single small argv operand. Created and closed by the shell, so there is
# no temp-file lifetime to leak and no new CLI flag: this function's own interface is
# unchanged — callers still pass a JSON STRING, and every --self-test arm below still drives
# it that way.
count_subtask_evidence() {
  local json="$1" _rc=0
  # `printf` here is the BASH BUILTIN, deliberately — an exec'd /usr/bin/printf would put the
  # payload back on an argv and re-open the very failure this transport exists to close.
  /usr/bin/python3 - <(printf '%s' "$json") <<'PY' || _rc=$?
import json, re, sys
TRUSTED = {"OWNER", "MEMBER", "COLLABORATOR", "CONTRIBUTOR"}
# Terminal stages: their own completion evidence is produced at or after the § 3.2 capture
# moment, so their inclusion would measure timing, not preservation.
TERMINAL_STAGES = {12, 13}
STAGE_RE = re.compile(r"^\s*stage\s*0*(\d+)\b", re.IGNORECASE)

def is_terminal(title):
    m = STAGE_RE.match(str(title or ""))
    # Unparseable title -> NOT terminal (fail-safe: retain in the denominator).
    return bool(m) and int(m.group(1)) in TERMINAL_STAGES

# argv[1] is a PATH (a process-substitution FD), not the payload itself — see the transport
# note above. OSError/UnicodeDecodeError join the parse-failure set: an unreadable or
# undecodable source is the same integrity violation as an unparseable one, exit 2 either way.
try:
    with open(sys.argv[1], encoding="utf-8") as _fh:
        items = json.load(_fh)
except (ValueError, TypeError, OSError, UnicodeDecodeError) as e:
    print(f"sub-task evidence source unparseable: {e}", file=sys.stderr)
    sys.exit(2)
excluded = 0
scaffolded = 0
preserved = 0
for it in items:
    if is_terminal(it.get("title", "")):
        excluded += 1
        continue
    scaffolded += 1
    if str(it.get("state", "")).upper() != "CLOSED":
        continue
    c = it.get("comments", 0)
    if isinstance(c, list):
        if any("authorAssociation" in cm for cm in c):
            has_evidence = any(str(cm.get("authorAssociation", "")).upper() in TRUSTED for cm in c)
        else:
            has_evidence = len(c) >= 1   # no author data in payload -> presence fallback
    else:
        has_evidence = int(c or 0) >= 1  # integer comment-count shape -> presence
    if has_evidence:
        preserved += 1
print(f"{preserved} {scaffolded} {excluded}")
PY
  return "$_rc"
}

# ─── Indicator 6 Layer 2: denominator corroboration (the unlabelled-candidate check) ─
# The SIXTH member of this file's read-model function family (rollup_marker_present,
# ratio_round_half_up, count_retro_conformance, count_lessons_population,
# count_subtask_evidence) — one function per population question, JSON-in / counts-out, and
# drivable from --self-test without gh. count_subtask_evidence was deliberately NOT widened
# to answer this second question: its contract is the LABEL-SCOPED payload, every shipped arm
# drives that exact shape, and widening it would re-open the argv-transport question a
# previous fix closed. A separate function keeps the tested surface tested.
#
# THE QUESTION IT ANSWERS is "is the label-scoped denominator COMPLETE?" — never "what is the
# true denominator?". It reports how many stage sub-task CANDIDATES the milestone holds that
# the `--label sub-task` query could not see; it NEVER substitutes them for the measured
# population. Substituting a title-derived population would invent a denominator, which
# close-class-telemetry.md FM1 forbids in terms — withholding is the sanctioned response.
#
# THE DISCRIMINATOR is the label taxonomy's own category axis, not a bare title match:
#   L  = { i in M : 'sub-task' in labels(i) }                      the measured population
#   T' = { i in M : STAGE_RE(title(i)) AND labels(i) has no
#                   CATEGORY_LABELS_EXCEPT_SUBTASK member }        the candidate population
#   U  = |T' \ L|                                                  the signal
# A BARE title match does NOT work and this was measured, not assumed: applied to the
# label-free population it returns ordinary intake cards — "Stage 9 can render GO on a draft
# release PR …", "Stage 13 Phase C5 thread-locking has not fired …" — several of them
# milestoned right now, so an unfiltered guard would flag live milestones DEGRADED on a
# perfectly-measured denominator. The category filter removed every one of those without
# removing any labelled sub-task, because of the § Rules 1 invariant cited on the array above.
#
# U > 0 IS THE SIGNAL, and the difference is ONE-SIDED BY CONSTRUCTION. The converse — a
# labelled sub-task whose title carries no `Stage N` prefix — is NORMAL and must never flag;
# the suite already fixtures one. Computed as a PYTHON SET DIFFERENCE over issue numbers,
# never with shell `comm`, which requires a lexical sort and silently yields a wrong set
# difference under a numeric one — and a wrong U here fails open in BOTH directions.
#
# STAGE_RE IS REUSED VERBATIM from count_subtask_evidence. A second stage-title regex in one
# file is a duplicate source, and if the two ever diverged the terminal-stage exclusion and
# the denominator corroboration would disagree about what a stage sub-task IS.
#
# Echoes "<M> <T'> <U>" from a JSON array of {number,title,labels}. On an unparseable payload
# it echoes "-1 0 0" and EXITS 0 — deliberately NOT exit 2. Exit 2 is reserved for a register
# that EXISTS but is UNREADABLE, a source-integrity violation the caller escalates to FAIL; a
# cross-check that could not read is a DEGRADATION, and escalating it would turn a measurement
# outage into a gate. The -1 sentinel is what the caller reads to say so out loud.
count_denominator_corroboration() {
  local json="$1"
  # `printf` here is the BASH BUILTIN, deliberately — see the transport note above.
  /usr/bin/python3 - <(printf '%s' "$json") "${CATEGORY_LABELS_EXCEPT_SUBTASK[@]}" <<'PY'
import json, re, sys
# Reused verbatim from count_subtask_evidence — one definition of "a stage sub-task title".
STAGE_RE = re.compile(r"^\s*stage\s*0*(\d+)\b", re.IGNORECASE)
SUBTASK_LABEL = "sub-task"
CATEGORY_EXCEPT_SUBTASK = {a.strip().lower() for a in sys.argv[2:] if a.strip()}

def labels_of(item):
    out = set()
    for lab in (item.get("labels") or []):
        name = lab.get("name", "") if isinstance(lab, dict) else lab
        name = str(name or "").strip().lower()
        if name:
            out.add(name)
    return out

# argv[1] is a PATH (a process-substitution FD), not the payload itself.
try:
    with open(sys.argv[1], encoding="utf-8") as _fh:
        items = json.load(_fh)
    if not isinstance(items, list):
        raise ValueError("expected a JSON array of issues")
except (ValueError, TypeError, OSError, UnicodeDecodeError) as e:
    print(f"denominator corroboration source unparseable: {e}", file=sys.stderr)
    print("-1 0 0")           # sentinel, exit 0 — a failed cross-check degrades, never gates
    sys.exit(0)

measured = set()       # L  — carries the sub-task label
candidates = set()     # T' — stage-titled AND carrying no competing category label
total = 0
for it in items:
    total += 1
    num = it.get("number") if isinstance(it, dict) else None
    if num is None:
        continue
    labs = labels_of(it)
    if SUBTASK_LABEL in labs:
        measured.add(num)
    if STAGE_RE.match(str(it.get("title") or "")) and not (labs & CATEGORY_EXCEPT_SUBTASK):
        candidates.add(num)
# ONE-SIDED difference. |L \ T'| is benign (a labelled sub-task with an unparseable title is
# normal and already fixtured) and is deliberately neither computed nor reported.
print(f"{total} {len(candidates)} {len(candidates - measured)}")
PY
}

# ─── Indicator 6: slot-6 state resolution (the denominator-integrity guard) ───
# ONE decision point for every reachable rendering of slot 6, called by the live emission
# path and driven directly by --self-test. It is a FUNCTION rather than an inline branch for
# one reason: the DZ/DU arms compare the EMITTED STRINGS, and a test that recomputed the
# branch itself would be a second copy of the contract — the same duplicate-denominator
# breach the separate marker arrays exist to prevent, one level up.
#
# WHY IT EXISTS. Three genuinely different conditions used to emit the SAME 21 bytes,
# `N/A — no stage sub-tasks scaffolded`: a true zero, a milestone whose stage sub-tasks exist
# but are unlabelled, and an unresolvable `--milestone` (which returns `[]` at exit 0, byte-
# identical to a true zero). A milestone that scaffolded 29 sub-tasks published S=0 and a
# reader had no signal that anything was wrong. A metric that fails open is worse than a
# missing one, because it is trusted.
#
# REGISTERS per review-discipline-principles.md § 8 PV-7 — NO token is coined here:
#   Register A (measurement status): fetched | truncated | degraded | not-run | fixture
#   Register B (degraded state)    : NOT-EVALUATED (nothing usable was measured)
#                                    DEGRADED      (a rate over a known-incomplete sample)
# Every Register-B emit carries the mandated clause `this is not a clean result`, and no
# clean row carries it. The CLEAN-ABSENCE rendering `N/A — <reason>` is a separate register
# (indicator-value) and keeps its spelling byte-for-byte: the fix is not to replace N/A, it
# is to stop the UNMEASURABLE case borrowing the CLEAN-ABSENCE rendering.
#
# NO REASON STRING MAY CONTAIN A SEMICOLON — the eight-slot field grammar splits on `; `.
#
# PRECEDENCE among conditions that can hold at once, stated so it cannot drift: read-integrity
# first (gh absent -> repo unresolvable -> primary read failed -> milestone unlocatable), then,
# on a measured rate, truncation (a deterministic fact about the read itself) -> uncorroborated
# (U could not be computed at all) -> label gap (U > 0). One condition, one reason, always the
# same one for the same inputs.
#
# args: <status> <primary_rc> <primary_rows> <M> <U> <P> <S> <X> [<milestone>]
#   status        live | no-gh | no-repo | fixture   (fixture => Register A `fixture`)
#   primary_rc    exit status of the label-scoped `gh issue list`
#   primary_rows  rows the label-scoped read returned (|L| payload rows)
#   M             milestone-wide row count from count_denominator_corroboration, or -1 when
#                 the cross-check could not run at all
#   U             unlabelled stage sub-task candidates (|T' \ L|)
#   P S X         count_subtask_evidence output (preserved / measurable / terminal-excluded)
# Echoes TAB-separated: <register-a>\t<register-b or ->\t<reason>\t<slot-6 string>
evidence_slot_state() {
  local status="$1" prc="$2" prows="$3" m="$4" u="$5" p="$6" s="$7" x="$8" ms="${9:-}"
  local ra="fetched" rb="-" reason="" slot="" rate=""
  local clause="this is not a clean result"
  local corrob=0
  [[ "$m" -lt 0 ]] && corrob=1

  if [[ "$status" == "no-gh" ]]; then
    ra="not-run"; rb="NOT-EVALUATED"
    reason="gh unavailable, phase-evidence preservation not computed"
  elif [[ "$status" == "no-repo" ]]; then
    ra="not-run"; rb="NOT-EVALUATED"
    reason="could not resolve target repo, set REPO or run inside a gh-authenticated repo"
  elif [[ "$prc" -ne 0 ]]; then
    # Layer 1, deterministic: the read FAILED. Distinct from a read that succeeded and
    # found nothing, which every earlier version of this branch could not tell apart.
    ra="degraded"; rb="NOT-EVALUATED"
    reason="the sub-task read failed (gh exit $prc), the population is unmeasured"
  elif [[ "$m" -eq 0 ]]; then
    # Layer 1, deterministic: an unresolvable --milestone returns [] at exit 0. Without this
    # limb a wrong milestone publishes "this release scaffolded no stage sub-tasks" when the
    # truth is "I looked in the wrong place".
    ra="degraded"; rb="NOT-EVALUATED"
    if [[ -n "$ms" ]]; then
      reason="milestone $ms returned no issues at all, so the population could not be located"
    else
      reason="the milestone returned no issues at all, so the population could not be located"
    fi
  elif [[ "$s" -eq 0 ]]; then
    if [[ "$corrob" -eq 1 ]]; then
      ra="degraded"; rb="NOT-EVALUATED"
      reason="the denominator cross-check could not run, so a genuine zero could not be told apart from an unmeasurable one"
    elif [[ "$u" -gt 0 ]]; then
      ra="truncated"; rb="NOT-EVALUATED"
      if [[ "$prows" -eq 0 ]]; then
        reason="denominator unmeasurable: 0 labelled rows against $u unlabelled stage sub-task candidates"
      else
        reason="denominator unmeasurable: 0 measurable labelled rows against $u unlabelled stage sub-task candidates"
      fi
    elif [[ "$x" -gt 0 ]]; then
      reason="no non-terminal stage sub-tasks scaffolded"
    else
      reason="no stage sub-tasks scaffolded"
    fi
  else
    rate="$(ratio_round_half_up "$p" "$s")"
    # EITHER read saturating the row bound truncates this reading. The cross-check's own
    # saturation matters for the same reason the primary's does, and in the same direction:
    # a truncated milestone read can only SHRINK the candidate set, so it can only lose a
    # flag, never invent one. Both reads share one bound, so one comparison covers both.
    if [[ "$prows" -ge "$SUBTASK_QUERY_LIMIT" || "$m" -ge "$SUBTASK_QUERY_LIMIT" ]]; then
      ra="truncated"; rb="DEGRADED"
      reason="$p/$s ($rate) over a read truncated at the $SUBTASK_QUERY_LIMIT-row limit"
    elif [[ "$corrob" -eq 1 ]]; then
      ra="degraded"; rb="DEGRADED"
      reason="$p/$s ($rate), uncorroborated: the denominator cross-check could not run"
    elif [[ "$u" -gt 0 ]]; then
      ra="truncated"; rb="DEGRADED"
      reason="$p/$s ($rate) over a label-scoped sample, $u unlabelled stage sub-task candidates not counted"
    fi
  fi

  # ONE composition point for the three renderings, so the mandated clause cannot ride a
  # clean row and a clean absence cannot borrow a Register-B spelling.
  if [[ "$rb" != "-" ]]; then
    slot="$rb — $reason — $clause"
  elif [[ -n "$reason" ]]; then
    slot="N/A — $reason"
  else
    slot="$p/$s ($rate)"
  fi
  # --self-test drives this same decision with fixture inputs; Register A says so, which is
  # why `fixture` is a member at all. It is never emitted on the field line — the self-test
  # exits before the emission section.
  [[ "$status" == "fixture" ]] && ra="fixture"
  # An ABSENT reason is emitted as `-`, never as an empty field, and the caller translates it
  # back. Tab is IFS *whitespace*, so `IFS=$'\t' read` COLLAPSES consecutive tabs — an empty
  # third field would silently shift the slot string into the reason variable and emit an
  # EMPTY slot 6. That is a fail-open in the guard against fail-open, and it is only reachable
  # on the clean measured row, which is the row a degraded-state test is least likely to drive.
  /usr/bin/printf '%s\t%s\t%s\t%s\n' "$ra" "$rb" "${reason:--}" "$slot"
}

# ─── Self-test mode (no gh / no network) ─────────────────────────────────────

if [[ "${1:-}" == "--self-test" ]]; then
  # Test 1: ratio round-half-up — exact / below-half / at-half / above-half / zero-den
  R="$(ratio_round_half_up 9 9)";  [[ "$R" == "1.00" ]] || die "self-test: ratio 9/9 = $R, expected 1.00"
  R="$(ratio_round_half_up 8 10)"; [[ "$R" == "0.80" ]] || die "self-test: ratio 8/10 = $R, expected 0.80"
  R="$(ratio_round_half_up 2 3)";  [[ "$R" == "0.67" ]] || die "self-test: ratio 2/3 = $R, expected 0.67"
  R="$(ratio_round_half_up 1 8)";  [[ "$R" == "0.13" ]] || die "self-test: ratio 1/8 = $R, expected 0.13 (round-half-up)"
  R="$(ratio_round_half_up 0 3)";  [[ "$R" == "0.00" ]] || die "self-test: ratio 0/3 = $R, expected 0.00"
  R="$(ratio_round_half_up 5 0)";  [[ "$R" == "N/A"  ]] || die "self-test: ratio 5/0 = $R, expected N/A"

  # Test 2: Indicator 1 — retro conformance against a synthetic FULLY-conformant
  #         register (all 10 canonical markers present) and a PARTIAL one (6 of 10).
  TMPD="$(/usr/bin/mktemp -d)"
  trap 'rm -rf "$TMPD"' EXIT
  RETRO_FULL="$TMPD/retro_full.md"
  { for m in "${CANONICAL_MARKERS[@]}"; do echo "$m"; echo "body"; done; } > "$RETRO_FULL"
  read -r P E < <(count_retro_conformance "$RETRO_FULL")
  [[ "$P" == "10" && "$E" == "10" ]] || die "self-test: retro conformance(full) = $P/$E, expected 10/10"
  R="$(ratio_round_half_up "$P" "$E")"; [[ "$R" == "1.00" ]] || die "self-test: retro conformance ratio(full) = $R, expected 1.00"

  RETRO_PARTIAL="$TMPD/retro_partial.md"
  { echo "## 1. Kerth Retrospective (full ceremony)"
    echo "### 1.1 Prime Directive (recite before reflecting)"
    echo "### 1.2 Three-question framework"
    echo "### 1.3 Ritual of closure"
    echo "## 2. PMBOK 7 Lessons-Learned (full ceremony)"
    echo "### 2.1 Situation"
    echo "some unrelated text"
  } > "$RETRO_PARTIAL"
  read -r P E < <(count_retro_conformance "$RETRO_PARTIAL")
  [[ "$P" == "6" && "$E" == "10" ]] || die "self-test: retro conformance(partial) = $P/$E, expected 6/10"
  R="$(ratio_round_half_up "$P" "$E")"; [[ "$R" == "0.60" ]] || die "self-test: retro conformance ratio(partial) = $R, expected 0.60"

  # Test 3: Indicator 2 — lessons population. 4 prompted rows (L1,L2,A1,A2); L2
  #         + A2 still carry the <…> placeholder (unpopulated) -> 2/4.
  LESSONS="$TMPD/lessons.md"
  {
    echo "### 2.3 Lessons"
    echo "| # | Lesson | Type | Evidence anchor |"
    echo "|---|---|---|---|"
    echo "| L1 | A real lesson learned | pattern | file:42 |"
    echo "| L2 | <…> | <…> | <…> |"
    echo "### 2.4 Next-cycle Actions"
    echo "| # | Action | Owner | Disposition |"
    echo "|---|---|---|---|"
    echo "| A1 | A real action item | operator | backlog |"
    echo "| A2 | <…> | <…> | <…> |"
  } > "$LESSONS"
  read -r PL TL < <(count_lessons_population "$LESSONS")
  [[ "$PL" == "2" && "$TL" == "4" ]] || die "self-test: lessons population = $PL/$TL, expected 2/4"
  R="$(ratio_round_half_up "$PL" "$TL")"; [[ "$R" == "0.50" ]] || die "self-test: lessons population ratio = $R, expected 0.50"

  # Test 4: Indicator 2 — a register with ZERO prompted rows -> 0 prompted (N/A ratio)
  LESSONS_EMPTY="$TMPD/lessons_empty.md"
  { echo "### 2.3 Lessons"; echo "no table rows here"; } > "$LESSONS_EMPTY"
  read -r PL TL < <(count_lessons_population "$LESSONS_EMPTY")
  [[ "$PL" == "0" && "$TL" == "0" ]] || die "self-test: empty-lessons = $PL/$TL, expected 0/0"
  R="$(ratio_round_half_up "$PL" "$TL")"; [[ "$R" == "N/A" ]] || die "self-test: empty-lessons ratio = $R, expected N/A"

  # Test 5: expected-marker count is the canonical 10
  [[ "$EXPECTED_MARKERS" -eq 10 ]] || die "self-test: EXPECTED_MARKERS = $EXPECTED_MARKERS, expected 10"

  # Test 5b: the A7.1 roll-up marker lives in its OWN array. If it were ever appended to
  # CANONICAL_MARKERS, Indicator 1's denominator would move /10 -> /11 and retro-conformance
  # would drop retroactively on every register already written. Test 5 above catches the
  # denominator move; this arm names the cause, so a future editor reads WHY rather than
  # just WHAT.
  [[ "${#ROLLUP_MARKERS[@]}" -eq 1 ]] || die "self-test: ROLLUP_MARKERS holds ${#ROLLUP_MARKERS[@]} entries, expected 1"
  for m in "${CANONICAL_MARKERS[@]}"; do
    [[ "$m" == "${ROLLUP_MARKERS[0]}" ]] && die "self-test: the A7.1 roll-up marker leaked into CANONICAL_MARKERS — that moves Indicator 1's denominator and retroactively depresses retro-conformance on every existing register"
  done

  # Test 5c: Indicator 5 — rollup-presence BIVALENCE. This is the anti-tautology control, and
  # it is the arm the previous implementation could not have: rollup-presence used to read a
  # caller-supplied flag standing in for a field the close-out run writes itself, so no
  # reading could ever have differed. Two registers identical except for the marker MUST
  # produce different answers; a fixture whose two arms agree is a broken probe, not a clean
  # one, and must fail this suite.
  RETRO_ROLLUP="$TMPD/retro_rollup.md"
  { for m in "${CANONICAL_MARKERS[@]}"; do echo "$m"; echo "body"; done
    echo "${ROLLUP_MARKERS[0]}"
    echo "rec: tighten the gate · chose: tighten the gate · why: aligned"
  } > "$RETRO_ROLLUP"
  RETRO_NOROLLUP="$TMPD/retro_norollup.md"
  { for m in "${CANONICAL_MARKERS[@]}"; do echo "$m"; echo "body"; done
    echo "Some prose that merely mentions the Stage 13 A7.1 roll-up without the header."
  } > "$RETRO_NOROLLUP"
  rollup_marker_present "$RETRO_ROLLUP"   || die "self-test: rollup-presence(marker present) read ABSENT, expected PRESENT"
  rollup_marker_present "$RETRO_NOROLLUP" && die "self-test: rollup-presence(marker absent) read PRESENT, expected ABSENT — a substring match, not a whole-line match, would do exactly this"

  # Test 5d: the no-register limb is a THIRD state, distinct from `absent`. Collapsing them
  # would make a missing register read as a governance failure rather than as an unmeasured
  # one, which is the distinction the standard's `N/A (reason)` form exists to preserve.
  rollup_marker_present "$TMPD/does_not_exist.md" && die "self-test: rollup-presence(no file) read PRESENT, expected the predicate to be false so the caller can emit the N/A state"

  # Test 6: Indicator 6 — phase-completion evidence preservation (read-model over sub-task gh
  #   state). Denominator = MEASURABLE scaffolded stage sub-tasks (terminal stages 12/13
  #   excluded); numerator = CLOSED with >=1 trusted-authored comment. Covers: full-preserved /
  #   OPEN-excluded / CLOSED-empty-excluded / untrusted-author-excluded / no-author-payload
  #   presence-fallback / integer-count shape / zero-scaffolded -> N/A.
  EVID_FULL='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[{"authorAssociation":"OWNER"},{"authorAssociation":"MEMBER"}]},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":[{"authorAssociation":"COLLABORATOR"}]},{"number":4,"title":"Stage 8 · #1 · QA / Acceptance","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_FULL")
  [[ "$EP" == "4" && "$ES" == "4" && "$EX" == "0" ]] || die "self-test: subtask-evidence(full) = $EP/$ES (excl $EX), expected 4/4 (excl 0)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "1.00" ]] || die "self-test: subtask-evidence ratio(full) = $R, expected 1.00"

  # OPEN (excluded), CLOSED-empty (excluded), CLOSED-OWNER (counted), CLOSED-NONE (untrusted, excluded) -> 1/4
  EVID_PARTIAL='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"OPEN","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[]},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":4,"title":"Stage 8 · #1 · QA / Acceptance","state":"CLOSED","comments":[{"authorAssociation":"NONE"}]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_PARTIAL")
  [[ "$EP" == "1" && "$ES" == "4" ]] || die "self-test: subtask-evidence(partial) = $EP/$ES, expected 1/4 (OPEN + CLOSED-empty + untrusted-author excluded)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "0.25" ]] || die "self-test: subtask-evidence ratio(partial) = $R, expected 0.25"

  # No authorAssociation in payload -> presence fallback (CLOSED w/ >=1 comment counts; CLOSED-empty excluded) -> 1/2
  EVID_FALLBACK='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":[{"body":"output posted"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_FALLBACK")
  [[ "$EP" == "1" && "$ES" == "2" ]] || die "self-test: subtask-evidence(no-author-payload) = $EP/$ES, expected 1/2 (presence fallback)"

  # Integer comment-count shape -> presence (CLOSED count>=1 counts; OPEN excluded; CLOSED count0 excluded) -> 1/3
  EVID_INT='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":2},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"OPEN","comments":5},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":0}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_INT")
  [[ "$EP" == "1" && "$ES" == "3" ]] || die "self-test: subtask-evidence(int-count) = $EP/$ES, expected 1/3"

  # F-01 terminal-stage exclusion (the capture-timing artifact). At the § 3.2 capture moment
  # (the Stage-13 chore PR) the Stage-12/13 sub-tasks are still in flight; counting them made
  # the rate a function of WHEN it was read. 6 scaffolded, 2 terminal -> 4/4 (1.00), not 4/6.
  EVID_TERMINAL='[{"number":1,"title":"Stage 5 · #1 · Solutioning","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 6 · #1 · Engineering","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":3,"title":"Stage 7 · #1 · Dev Testing","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":4,"title":"Stage 9 · Plan Review (GO/NO-GO) — r","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":5,"title":"Stage 12 · Execute — r","state":"OPEN","comments":[]},{"number":6,"title":"Stage 13 · Close — r","state":"OPEN","comments":[]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_TERMINAL")
  [[ "$EP" == "4" && "$ES" == "4" && "$EX" == "2" ]] || die "self-test: subtask-evidence(terminal-exclusion) = $EP/$ES (excl $EX), expected 4/4 (excl 2)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "1.00" ]] || die "self-test: subtask-evidence ratio(terminal-exclusion) = $R, expected 1.00 (terminal stages must not depress the rate)"

  # Fail-safe: a sub-task whose title does not carry a parseable `Stage <N>` prefix is RETAINED
  # in the denominator (never shrink S on an unrecognized title). Stage 1/2/3 are not terminal.
  EVID_UNPARSEABLE='[{"number":1,"title":"[Subtask] Software-domain templates — Wave 1","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"","state":"OPEN","comments":[]},{"number":3,"title":"Stage 3 · Bundle","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_UNPARSEABLE")
  [[ "$EP" == "2" && "$ES" == "3" && "$EX" == "0" ]] || die "self-test: subtask-evidence(unparseable-title) = $EP/$ES (excl $EX), expected 2/3 (excl 0 — fail-safe retain)"

  # All-terminal population -> S collapses to 0 -> N/A (not a 0/0 rate)
  EVID_ALL_TERMINAL='[{"number":1,"title":"Stage 12 · Execute — r","state":"CLOSED","comments":[{"authorAssociation":"OWNER"}]},{"number":2,"title":"Stage 13 · Close — r","state":"OPEN","comments":[]}]'
  read -r EP ES EX < <(count_subtask_evidence "$EVID_ALL_TERMINAL")
  [[ "$EP" == "0" && "$ES" == "0" && "$EX" == "2" ]] || die "self-test: subtask-evidence(all-terminal) = $EP/$ES (excl $EX), expected 0/0 (excl 2)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "N/A" ]] || die "self-test: subtask-evidence ratio(all-terminal) = $R, expected N/A"

  # Zero scaffolded -> 0/0 -> N/A rate
  read -r EP ES EX < <(count_subtask_evidence '[]')
  [[ "$EP" == "0" && "$ES" == "0" && "$EX" == "0" ]] || die "self-test: subtask-evidence(zero) = $EP/$ES (excl $EX), expected 0/0 (excl 0)"
  R="$(ratio_round_half_up "$EP" "$ES")"; [[ "$R" == "N/A" ]] || die "self-test: subtask-evidence ratio(zero) = $R, expected N/A (no stage sub-tasks scaffolded)"

  # Test 7: Indicator 6 — the OVER-ARGV arm. Every arm above feeds a payload of a few hundred
  # bytes, so this suite reported PASS for a long time while the tool could not run on ANY live
  # milestone: `gh issue list --json number,title,state,comments` over a real release returns
  # every sub-task's full comment bodies, and that payload used to travel as argv. This arm
  # drives the SAME function through the SAME call form with a payload that genuinely cannot be
  # passed as an argv operand on the running system, so the suite can no longer be green on a
  # code path the live invocation cannot execute.
  #
  # The fixture is sized ADAPTIVELY rather than to a literal, because the argv ceiling is
  # platform-dependent (a total-bytes cap on one platform, plus a per-argument cap on another).
  # A hardcoded size would silently become an in-bounds payload on some host and the arm would
  # go vacuous — which is precisely the failure class this arm exists to close. The sizing loop
  # IS the anti-vacuity control: it exits only once an exec with the payload as argv has
  # actually been refused, and it dies rather than continuing if it never is.
  # Built by DOUBLING, not by pattern substitution: bash 3.2's ${var// /X} is quadratic and
  # would turn this arm into a multi-minute stall that reads as a hang rather than a test.
  BIG_BODY="XXXXXXXXXXXXXXXX"
  while [[ "${#BIG_BODY}" -lt 32768 ]]; do BIG_BODY="${BIG_BODY}${BIG_BODY}"; done
  BIG_N=40
  while :; do
    EVID_BIG="["
    BIG_SEP=""
    for (( BIG_I = 1; BIG_I <= BIG_N; BIG_I++ )); do
      EVID_BIG="${EVID_BIG}${BIG_SEP}{\"number\":${BIG_I},\"title\":\"Stage 6 · #${BIG_I} · Engineering\",\"state\":\"CLOSED\",\"comments\":[{\"authorAssociation\":\"OWNER\",\"body\":\"${BIG_BODY}\"}]}"
      BIG_SEP=","
    done
    # One OPEN non-terminal (counts in S, not in P) + two terminal-stage sub-tasks (excluded
    # from S entirely) — so the arm asserts the Indicator-6 SEMANTICS survive the transport
    # change at scale, not merely that the interpreter starts.
    EVID_BIG="${EVID_BIG},{\"number\":9001,\"title\":\"Stage 7 · Dev Testing\",\"state\":\"OPEN\",\"comments\":[]}"
    EVID_BIG="${EVID_BIG},{\"number\":9002,\"title\":\"Stage 12 · Execute — r\",\"state\":\"CLOSED\",\"comments\":[{\"authorAssociation\":\"OWNER\"}]}"
    EVID_BIG="${EVID_BIG},{\"number\":9003,\"title\":\"Stage 13 · Close — r\",\"state\":\"OPEN\",\"comments\":[]}]"
    # Negative control: the payload must be genuinely un-passable as an argv operand HERE.
    if ! /usr/bin/true "$EVID_BIG" 2>/dev/null; then break; fi
    [[ "$BIG_N" -ge 1280 ]] && die "self-test: could not build an over-argv payload (${#EVID_BIG} bytes at $BIG_N items) — the over-argv arm would be vacuous on this host"
    BIG_N=$(( BIG_N * 2 ))
  done
  read -r EP ES EX < <(count_subtask_evidence "$EVID_BIG")
  [[ "$EP" == "$BIG_N" ]] || die "self-test: subtask-evidence(over-argv) preserved = $EP, expected $BIG_N"
  [[ "$ES" == "$(( BIG_N + 1 ))" ]] || die "self-test: subtask-evidence(over-argv) scaffolded = $ES, expected $(( BIG_N + 1 )) (the OPEN sub-task stays in the denominator)"
  [[ "$EX" == "2" ]] || die "self-test: subtask-evidence(over-argv) terminal-excluded = $EX, expected 2"
  R="$(ratio_round_half_up "$EP" "$ES")"
  [[ -n "$R" && "$R" != "N/A" ]] || die "self-test: subtask-evidence ratio(over-argv) = '$R', expected a computed rate"

  # Test 8: Indicator 6 DENOMINATOR INTEGRITY — the guard that stops an UNMEASURABLE
  #   denominator borrowing the CLEAN-ABSENCE rendering. Before it, a true zero and a total
  #   label gap emitted the identical 21 bytes, so a milestone that scaffolded 29 stage
  #   sub-tasks published S=0 with no signal that anything was wrong.
  #   Following Test 5c: a fixture whose two arms agree is a broken probe, not a clean one,
  #   and must fail this suite.

  # DZ — TRUE ZERO. A milestone with issues in it, none of them a stage sub-task.
  DENOM_DZ='[{"number":1,"title":"[Improvement]: something unrelated","labels":[{"name":"improvement"}]}]'
  read -r DM DT DU < <(count_denominator_corroboration "$DENOM_DZ")
  [[ "$DM" == "1" && "$DT" == "0" && "$DU" == "0" ]] || die "self-test: denominator-corroboration(DZ true-zero) = M=$DM T'=$DT U=$DU, expected M=1 T'=0 U=0"
  IFS=$'\t' read -r DZ_RA DZ_RB DZ_REASON DZ_STR < <(evidence_slot_state live 0 0 "$DM" "$DU" 0 0 0)
  [[ "$DZ_STR" == "N/A — no stage sub-tasks scaffolded" ]] || die "self-test: denominator-integrity(DZ) emitted '$DZ_STR', expected the clean-absence rendering 'N/A — no stage sub-tasks scaffolded' byte-for-byte — a genuine zero keeps its spelling"
  [[ "$DZ_RA" == "fetched" && "$DZ_RB" == "-" ]] || die "self-test: denominator-integrity(DZ) status = $DZ_RA/$DZ_RB, expected fetched with NO Register-B token — a clean absence is not a degradation"

  # DU — UNLABELLED SUB-TASKS. The same shape plus rows the hub would have scaffolded,
  #      WITHOUT the sub-task label. This is the card's headline instance.
  DENOM_DU='[{"number":1,"title":"[Improvement]: something unrelated","labels":[{"name":"improvement"}]},{"number":2,"title":"Stage 5 Solutioning — parent card (slug)","labels":[]},{"number":3,"title":"Stage 6 Engineering — parent card (slug)","labels":[]}]'
  read -r DM DT DU < <(count_denominator_corroboration "$DENOM_DU")
  [[ "$DM" == "3" && "$DT" == "2" && "$DU" == "2" ]] || die "self-test: denominator-corroboration(DU unlabelled) = M=$DM T'=$DT U=$DU, expected M=3 T'=2 U=2"
  IFS=$'\t' read -r DU_RA DU_RB DU_REASON DU_STR < <(evidence_slot_state live 0 0 "$DM" "$DU" 0 0 0)
  [[ "$DU_RA" == "truncated" && "$DU_RB" == "NOT-EVALUATED" ]] || die "self-test: denominator-integrity(DU) status = $DU_RA/$DU_RB, expected truncated/NOT-EVALUATED"
  [[ "$DU_STR" != "N/A"* ]] || die "self-test: denominator-integrity(DU) emitted '$DU_STR' — an unmeasurable denominator must NEVER render as N/A"
  [[ "$DU_STR" == *"this is not a clean result" ]] || die "self-test: denominator-integrity(DU) emitted '$DU_STR' without the mandated clause"

  # THE ASSERTION — the two states must DIFFER. This is the whole card in one line.
  [[ "$DZ_STR" != "$DU_STR" ]] || die "self-test: denominator-integrity — DZ (true zero) and DU (unlabelled sub-tasks) emitted the IDENTICAL state '$DZ_STR'. An unmeasurable denominator is borrowing the clean-absence rendering, which is the fail-open this guard exists to close"

  # DFP — SPECIFICITY. An ordinary intake card whose TITLE carries the stage vocabulary but
  #   which carries a competing category label is NOT a sub-task and must NOT flag. Measured
  #   at the release base, a bare title match returned several such cards, milestoned right
  #   now; without this arm the guard would ship with a live false-positive population.
  DENOM_DFP='[{"number":4,"title":"Stage 9 can render GO on a draft release PR — the transition is described but never asserted","labels":[{"name":"bug"},{"name":"status: proposed"}]},{"number":5,"title":"Stage 13 Phase C5 thread-locking has not fired","labels":[{"name":"improvement"}]}]'
  read -r DM DT DU < <(count_denominator_corroboration "$DENOM_DFP")
  [[ "$DM" == "2" && "$DT" == "0" && "$DU" == "0" ]] || die "self-test: denominator-corroboration(DFP specificity) = M=$DM T'=$DT U=$DU, expected M=2 T'=0 U=0 — an intake card carrying a category label is not an unlabelled sub-task"
  IFS=$'\t' read -r DFP_RA DFP_RB DFP_REASON DFP_STR < <(evidence_slot_state live 0 0 "$DM" "$DU" 0 0 0)
  [[ "$DFP_STR" == "$DZ_STR" ]] || die "self-test: denominator-integrity(DFP) emitted '$DFP_STR', expected the clean-absence rendering — the guard flagged a correctly-measured denominator"

  # DL — ONE-SIDED-DIFFERENCE GUARD. A LABELLED sub-task whose title carries no `Stage N`
  #   prefix is normal (the shape arm above already fixtures one) and must not flag. The
  #   difference is |T' \ L|, never a symmetric comparison.
  DENOM_DL='[{"number":6,"title":"[Subtask] Software-domain templates — Wave 1","labels":[{"name":"sub-task"}]},{"number":7,"title":"Stage 6 Engineering — parent card (slug)","labels":[{"name":"sub-task"}]}]'
  read -r DM DT DU < <(count_denominator_corroboration "$DENOM_DL")
  [[ "$DM" == "2" && "$DT" == "1" && "$DU" == "0" ]] || die "self-test: denominator-corroboration(DL one-sided) = M=$DM T'=$DT U=$DU, expected M=2 T'=1 U=0 — |L \\ T'| is benign and must not flag"

  # DP — the PARTIAL label gap. The more dangerous half: a plausible RATE over a wrong
  #   denominator is trusted more than a false N/A, so the guard fires on the non-zero
  #   branch too, not only when the labelled population is empty.
  IFS=$'\t' read -r DP_RA DP_RB DP_REASON DP_STR < <(evidence_slot_state live 0 4 40 2 3 4 0)
  [[ "$DP_RA" == "truncated" && "$DP_RB" == "DEGRADED" ]] || die "self-test: denominator-integrity(partial gap) status = $DP_RA/$DP_RB, expected truncated/DEGRADED"
  [[ "$DP_STR" == "DEGRADED — 3/4 (0.75) over a label-scoped sample, 2 unlabelled stage sub-task candidates not counted — this is not a clean result" ]] || die "self-test: denominator-integrity(partial gap) emitted '$DP_STR'"

  # Test 8b: the SLOT-6 STATE GRAMMAR over every reachable rendering. The no-semicolon rule
  #   is the one constraint that would silently CORRUPT the eight-slot field rather than fail
  #   it (both grammar predicates split on `; `), so it is asserted directly rather than
  #   trusted. The clause check is two-sided on purpose: a probe that flags all thirteen has
  #   not discriminated between a degraded row and a clean one.
  SLOT_ROWS=0; SLOT_CLEAN=0; SLOT_TOKENED=0; SLOT_RA_SEEN=""; SLOT_RATE_ROWS=0
  while IFS=$'\t' read -r _ra _rb _rs _slot; do
    SLOT_ROWS=$(( SLOT_ROWS + 1 ))
    # NON-EMPTINESS FIRST, and it is not a formality: every other assertion in this loop is
    # vacuously satisfied by an empty string, so without this one a rendering that failed to
    # reach its variable at all would read as clean on every check below.
    [[ -n "$_slot" ]] || die "self-test: slot-6 rendering $SLOT_ROWS is EMPTY — every assertion below is vacuous on an empty string, so this is a broken probe rather than a clean one"
    [[ -n "$_rs" ]] || die "self-test: slot-6 rendering $SLOT_ROWS carries an empty reason field — an absent reason must be emitted as '-' so the tab-separated read cannot collapse it"
    case "$_slot" in
      *";"*) die "self-test: slot-6 state '$_slot' contains a SEMICOLON — the eight-slot field grammar splits on '; ' and this would silently corrupt the field" ;;
    esac
    # Reproduce the CONSUMER'S parse structurally rather than copying its regex: compose the
    # full field line with this rendering in slot 6 and count the `; `-separated slots. Eight
    # is the contract; a state string that split the field would land here as 9, which is the
    # corruption mode a permissive `.+` grammar cannot see.
    _line="**Close-Class-Telemetry:** retro-conformance 10/10 (1.00); lessons-population 8/10 (0.80); carry-forward-closure 2/3 (0.67); pattern-emergence deferred-to-aggregate (see synthesize-release-learnings.sh); rollup-presence present; evidence-preservation ${_slot}; evidence-close-gate pass; mechanism: compute-close-class-telemetry.sh"
    _slots=1; _rest="$_line"
    while [[ "$_rest" == *"; "* ]]; do _slots=$(( _slots + 1 )); _rest="${_rest#*"; "}"; done
    [[ "$_slots" -eq 8 ]] || die "self-test: slot-6 state '$_slot' composes a field line of $_slots slots, expected 8 — this state string splits the field"
    case "$SLOT_RA_SEEN" in *"|$_ra|"*) : ;; *) SLOT_RA_SEEN="${SLOT_RA_SEEN}|$_ra|" ;; esac
    if [[ "$_rb" == "-" ]]; then
      SLOT_CLEAN=$(( SLOT_CLEAN + 1 ))
      [[ "$_slot" != *"this is not a clean result"* ]] || die "self-test: clean slot-6 state '$_slot' carries the not-clean clause"
      # A clean row is EITHER a clean absence (`N/A — <reason>`, reason present) or a measured
      # rate (reason absent, so `-`). Nothing else is a lawful clean rendering.
      if [[ "$_rs" == "-" ]]; then
        SLOT_RATE_ROWS=$(( SLOT_RATE_ROWS + 1 ))
        [[ "$_slot" =~ ^[0-9]+/[0-9]+\ \([0-9]+\.[0-9][0-9]\)$ ]] || die "self-test: clean slot-6 state '$_slot' has no reason and is not a measured rate"
      else
        [[ "$_slot" == "N/A — "* ]] || die "self-test: clean slot-6 state '$_slot' carries a reason but does not render as a clean absence"
      fi
    else
      SLOT_TOKENED=$(( SLOT_TOKENED + 1 ))
      case "$_rb" in
        NOT-EVALUATED|DEGRADED) : ;;
        *) die "self-test: slot-6 emitted the out-of-register token '$_rb' — Register B is a CLOSED two-member set and a surface that needs another state amends the rider, it does not coin one here" ;;
      esac
      [[ "$_slot" == "$_rb"* ]] || die "self-test: slot-6 state '$_slot' does not open with its Register-B token"
      [[ "$_slot" == *"this is not a clean result" ]] || die "self-test: Register-B slot-6 state '$_slot' is missing the mandated clause"
    fi
  done < <(
    evidence_slot_state no-gh   0   0   0 0 0 0 0            # gh absent
    evidence_slot_state no-repo 0   0   0 0 0 0 0            # repo unresolvable
    evidence_slot_state live    1   0  -1 0 0 0 0            # primary read failed
    evidence_slot_state live    0   0   0 0 0 0 0 314        # milestone unlocatable
    evidence_slot_state live    0   0   3 2 0 0 0            # total label gap
    evidence_slot_state live    0   2   5 1 0 0 2            # all-terminal, still unmeasurable
    evidence_slot_state live    0   4  -1 0 3 4 0            # uncorroborated rate
    evidence_slot_state live    0 500 600 0 400 500 0        # limit-saturated primary read
    evidence_slot_state live    0   4 500 0   3   4 0        # limit-saturated cross-check
    evidence_slot_state live    0   4  40 2 3 4 0            # partial label gap
    evidence_slot_state live    0   0   5 0 0 0 0            # true zero
    evidence_slot_state live    0   2   5 0 0 0 2            # all-terminal clean absence
    evidence_slot_state live    0   4   8 0 4 4 0            # normal measured rate
    evidence_slot_state fixture 0   4   8 0 4 4 0            # fixture-sourced measurement
  )
  [[ "$SLOT_ROWS" -eq 14 ]] || die "self-test: slot-6 grammar walked $SLOT_ROWS renderings, expected 14 — the extraction is broken and the zero-semicolon finding is not a finding"
  [[ "$SLOT_TOKENED" -eq 10 ]] || die "self-test: slot-6 grammar saw $SLOT_TOKENED Register-B rows, expected 10"
  [[ "$SLOT_CLEAN" -eq 4 ]] || die "self-test: slot-6 grammar saw $SLOT_CLEAN clean rows, expected 4"
  [[ "$SLOT_RATE_ROWS" -eq 2 ]] || die "self-test: slot-6 grammar saw $SLOT_RATE_ROWS measured-rate rows, expected 2 — the clean measured row is the ONLY one with an absent reason, and it is the row an empty-field collapse would silently blank"
  for _m in fetched truncated degraded not-run fixture; do
    case "$SLOT_RA_SEEN" in *"|$_m|"*) : ;; *) die "self-test: Register A member '$_m' is unreachable — the mapping claims all five are reachable" ;; esac
  done

  rm -rf "$TMPD"; trap - EXIT
  echo "self-test: PASS"
  echo "  ratio round-half-up validated (exact / below-half / at-half / above-half / zero-den)"
  echo "  Indicator 1 retro canonical-form conformance validated (full 10/10 + partial 6/10)"
  echo "  Indicator 2 lessons-population validated (placeholder detection 2/4 + zero-prompted N/A)"
  echo "  canonical-marker set validated (10 verbatim Kerth + PMBOK 7 + Triple-Linkage headers)"
  echo "  Indicator 5 rollup-presence validated (BIVALENT: marker present -> present, marker absent -> absent, no register -> N/A; roll-up marker held in its own array so Indicator 1's denominator stays 10)"
  echo "  Indicator 6 phase-evidence preservation validated (full 4/4 + partial 1/4 + presence-fallback + int-count + zero-scaffolded N/A)"
  echo "  Indicator 6 terminal-stage exclusion validated (Stage-12/13 excluded 4/4 not 4/6 + unparseable-title fail-safe retain + all-terminal N/A)"
  echo "  Indicator 6 OVER-ARGV transport validated (${#EVID_BIG} bytes, $BIG_N items — refused as argv by exec, accepted by the FD transport, semantics preserved: $EP/$ES excl $EX)"
  echo "  Indicator 6 denominator-integrity validated (DZ true-zero and DU unlabelled emit DIFFERENT states: '$DZ_STR' vs '$DU_STR')"
  echo "  Indicator 6 denominator-integrity DFP specificity validated (an intake card whose title carries the stage vocabulary but which holds a competing category label does NOT flag — U=0)"
  echo "  Indicator 6 denominator-integrity DL one-sided-difference validated (a labelled sub-task with a non-Stage title does NOT flag — the difference is |T' \\ L|, never symmetric)"
  echo "  Indicator 6 denominator-integrity partial-gap validated (a plausible rate over a wrong denominator degrades too: '$DP_STR')"
  echo "  Indicator 6 slot-6 state grammar validated ($SLOT_ROWS reachable renderings: 0 semicolons and an 8-slot field line each, the mandated clause on all $SLOT_TOKENED Register-B rows and on none of the $SLOT_CLEAN clean rows, tokens confined to NOT-EVALUATED|DEGRADED, all 5 Register-A members reachable)"
  exit 0
fi

# ─── Argument parsing ────────────────────────────────────────────────────────

VERSION=""
MILESTONE=""
RETRO_PATH=""
LESSONS_PATH=""
OUTCOME_PRESENT_SEEN=0  # DEPRECATED flag was passed (value ignored; notice emitted)
CLOSE_GATE="na"       # Indicator 6 (pass|fail|na)
OUTPUT_FORMAT="human" # human | json

while [[ $# -gt 0 ]]; do
  case "$1" in
    --milestone) MILESTONE="${2:-}"; shift 2 ;;
    --retro) RETRO_PATH="${2:-}"; shift 2 ;;
    --lessons) LESSONS_PATH="${2:-}"; shift 2 ;;
    # DEPRECATED — accepted and ignored for one release so an existing caller does not
    # hard-fail on an unknown flag. The value is consumed positionally and discarded; it is
    # deliberately NOT domain-checked any more, because validating a value nothing reads
    # would keep asserting a contract this tool no longer honours.
    --outcome-present) OUTCOME_PRESENT_SEEN=1; shift 2 ;;
    --close-gate) CLOSE_GATE="${2:-}"; shift 2 ;;
    --json) OUTPUT_FORMAT="json"; shift ;;
    --help|-h) usage ;;
    -*) die "Unknown flag: $1" ;;
    *)
      if [[ -z "$VERSION" ]]; then VERSION="$1"; else die "Unexpected positional arg: $1 (version already set to '$VERSION')"; fi
      shift
      ;;
  esac
done

# ─── Required-field validation ───────────────────────────────────────────────

[[ -z "$VERSION" ]] && die "Required: <version> (positional)"
[[ -z "$MILESTONE" ]] && die "Required: --milestone <N> (the release's GitHub milestone number for carry-forward closure)"
case "$CLOSE_GATE" in pass|fail|na) : ;; *) die "--close-gate must be pass|fail|na (got '$CLOSE_GATE')" ;; esac

# Deprecation notice to STDERR — stdout carries the field-value line and nothing else.
if [[ "$OUTCOME_PRESENT_SEEN" -eq 1 ]]; then
  echo "NOTICE: --outcome-present is DEPRECATED and was IGNORED. Indicator 5 now measures the Stage-13 A7.1 roll-up from the retro register itself; a caller-supplied value would re-open the fabrication path the flag was retired to close. Remove it from the invocation — the flag is accepted for one release, then removed." >&2
fi

# Default the lessons path to the retro path (template carries both blocks in one file).
[[ -z "$LESSONS_PATH" && -n "$RETRO_PATH" ]] && LESSONS_PATH="$RETRO_PATH"

# ─── Indicator 1: retro-conformance ──────────────────────────────────────────

RETRO_PRESENT="N/A"; RETRO_EXPECTED="N/A"; RETRO_RATIO="N/A"; RETRO_NA_REASON=""
# RETRO_RESOLVED is the ONE resolution answer, reused by Indicator 5 below rather than
# re-tested there — two `-f` tests on the same path are two chances to drift apart.
RETRO_RESOLVED=0
if [[ -n "$RETRO_PATH" && -f "$RETRO_PATH" ]]; then
  # exists -> parse (a register that exists but is unreadable is a source-integrity error)
  [[ -r "$RETRO_PATH" ]] || die "retro register exists but is unreadable: $RETRO_PATH" 2
  RETRO_RESOLVED=1
  read -r RETRO_PRESENT RETRO_EXPECTED < <(count_retro_conformance "$RETRO_PATH")
  RETRO_RATIO="$(ratio_round_half_up "$RETRO_PRESENT" "$RETRO_EXPECTED")"
else
  RETRO_NA_REASON="no retro register found for $VERSION"
fi

# ─── Indicator 2: lessons-population ─────────────────────────────────────────

LESS_POP="N/A"; LESS_PROMPTED="N/A"; LESS_RATIO="N/A"; LESS_NA_REASON=""
if [[ -n "$LESSONS_PATH" && -f "$LESSONS_PATH" ]]; then
  [[ -r "$LESSONS_PATH" ]] || die "lessons register exists but is unreadable: $LESSONS_PATH" 2
  read -r LESS_POP LESS_PROMPTED < <(count_lessons_population "$LESSONS_PATH")
  if [[ "$LESS_PROMPTED" -eq 0 ]]; then
    LESS_RATIO="N/A"; LESS_NA_REASON="lessons register present but prompts zero rows"
  else
    LESS_RATIO="$(ratio_round_half_up "$LESS_POP" "$LESS_PROMPTED")"
  fi
else
  LESS_NA_REASON="no lessons register found"
fi

# ─── Indicator 3: carry-forward-closure (gh status: deferred over the milestone) ─

CF_CLOSED="N/A"; CF_RAISED="N/A"; CF_RATIO="N/A"; CF_NA_REASON=""
GH="$(find_gh)"
if [[ -z "$GH" ]]; then
  CF_NA_REASON="gh unavailable — carry-forward closure not computed"
else
  REPO="${REPO:-$("$GH" repo view --json nameWithOwner -q .nameWithOwner 2>/dev/null || true)}"
  if [[ -z "$REPO" ]]; then
    CF_NA_REASON="could not resolve target repo — set REPO or run inside a gh-authenticated repo"
  else
    # Enumerate issues this release labelled `status: deferred`. Per deferred-item-
    # tracking.md the Stage 13 defer DE-MILESTONES the issue, so a label-scoped query
    # over the milestone would miss them. The robust read: all `status: deferred`
    # issues (open + closed), filtered to those whose deferral was raised by this
    # release. The release linkage is the milestone the issue carried before de-
    # milestoning, recorded in the canonical comment trail; in the absence of a
    # machine-readable back-link the Stage 13 spoke passes the raised-set explicitly.
    # Here: read state of all `status: deferred` issues and report closed/raised over
    # the set the milestone still references PLUS any the caller pins via REPO/label.
    # Mechanical default: count over the milestone's `status: deferred` membership
    # that is still milestone-attached (the clean-close case is zero -> N/A).
    DEFERRED_JSON="$("$GH" issue list --repo "$REPO" \
      --milestone "$MILESTONE" --label "status: deferred" --state all --limit 500 \
      --json number,state 2>/dev/null || true)"
    if [[ -z "$DEFERRED_JSON" || "$DEFERRED_JSON" == "[]" ]]; then
      CF_NA_REASON="no carry-forward items raised"
      CF_RAISED=0; CF_CLOSED=0
    else
      read -r CF_CLOSED CF_RAISED < <(/usr/bin/python3 - "$DEFERRED_JSON" <<'PY'
import json, sys
items = json.loads(sys.argv[1])
raised = len(items)
closed = sum(1 for i in items if i.get("state","").upper() == "CLOSED")
print(f"{closed} {raised}")
PY
)
      if [[ "$CF_RAISED" -eq 0 ]]; then
        CF_NA_REASON="no carry-forward items raised"
      else
        CF_RATIO="$(ratio_round_half_up "$CF_CLOSED" "$CF_RAISED")"
      fi
    fi
  fi
fi

# ─── Indicator 4: pattern-emergence (POINTER ONLY — never recomputed here) ───

PATTERN_POINTER="deferred-to-aggregate (see synthesize-release-learnings.sh)"

# ─── Indicator 5: rollup-presence (presence, NOT a rate) ─────────────────────
# MEASURED here from the retro register — the A7.1 roll-up limb, which is operator-authored
# and which NO close-out phase writes. The `Outcome:` conjunct is discharged as a documented
# construction invariant of phase 6.5, not probed; see the INDICATOR 5 note in the header for
# why probing it would publish a fabricated metric. Three states, and the third one matters:
# "no register resolved" is a different fact from "register present, roll-up missing", and
# collapsing them would make an absent register read as a governance failure. The N/A limb
# reuses Indicator 1's single resolution answer (RETRO_RESOLVED) rather than re-testing.

if [[ "$RETRO_RESOLVED" -eq 1 ]]; then
  if rollup_marker_present "$RETRO_PATH"; then ROLLUP_PRESENCE="present"; else ROLLUP_PRESENCE="absent"; fi
else
  ROLLUP_PRESENCE="N/A — no retro register found"
fi

# ─── Indicator 6: phase-completion evidence preservation (read-model) + retained close-gate ─
# Primary reading: a bounded read-model over the hub-spoke sub-task `gh` state (NO net-new
# store) — CLOSED stage sub-tasks carrying >=1 trusted-authored comment (P) / MEASURABLE stage
# sub-tasks scaffolded for the release (S, terminal stages 12/13 excluded); rate = P/S. Reuses
# the GH + REPO resolved for Indicator 3. Mechanical gh-state read only — honors the standard
# § 8 boundary (NOT the event log). N/A when the release scaffolded zero stage sub-tasks
# (pre-hub-spoke / grandfathered), or when every scaffolded sub-task is terminal-stage.
#
# DENOMINATOR INTEGRITY (Layer 1 read-integrity + Layer 2 corroboration). The label-scoped
# query is the population whose COMPLETENESS is in question, so it is retained byte-for-byte
# and the guard AUDITS it rather than replacing it — a title-derived denominator would be an
# invented one, which FM1 forbids. Layer 1 is heuristic-free: it separates a failed read, an
# unlocatable milestone and a limit-saturated read, all three of which used to render as the
# clean absence. Layer 2 is the only heuristic and it is confined to the label-gap case.
EVID_PRESERVED="N/A"; EVID_SCAFFOLDED="N/A"; EVID_RATIO="N/A"; EVID_NA_REASON=""; EVID_EXCLUDED=0
EVID_STATE="not-run"; EVID_TOKEN="-"; EVID_UNLABELLED="N/A"; EVID_STR=""
EVID_P_RAW=0; EVID_S_RAW=0; EVID_X_RAW=0; EVID_M=-1; EVID_U=0
if [[ -z "$GH" ]]; then
  IFS=$'\t' read -r EVID_STATE EVID_TOKEN EVID_NA_REASON EVID_STR < <(evidence_slot_state no-gh 0 0 0 0 0 0 0)
elif [[ -z "${REPO:-}" ]]; then
  IFS=$'\t' read -r EVID_STATE EVID_TOKEN EVID_NA_REASON EVID_STR < <(evidence_slot_state no-repo 0 0 0 0 0 0 0)
else
  # Capture the read's exit status instead of swallowing it. `|| SUBTASK_RC=$?` keeps the
  # `2>/dev/null` (the diagnostic is noise) while making "the read FAILED" observably
  # different from "the read succeeded and found nothing" — which `|| true` could not.
  SUBTASK_RC=0
  SUBTASK_JSON="$("$GH" issue list --repo "$REPO" \
    --milestone "$MILESTONE" --label "sub-task" --state all --limit "$SUBTASK_QUERY_LIMIT" \
    --json number,title,state,comments 2>/dev/null)" || SUBTASK_RC=$?

  # Layer 2 — the corroborator. A SECOND, metadata-only read over the milestone-wide
  # population (no comment bodies, measured at ~10% of the primary payload). A milestone
  # that returns no issues AT ALL is an unresolvable --milestone, which the primary query
  # cannot distinguish from a true zero because it returns `[]` at exit 0 either way.
  CORROB_RC=0
  CORROB_JSON="$("$GH" issue list --repo "$REPO" \
    --milestone "$MILESTONE" --state all --limit "$SUBTASK_QUERY_LIMIT" \
    --json number,title,labels 2>/dev/null)" || CORROB_RC=$?
  if [[ "$CORROB_RC" -eq 0 && -n "$CORROB_JSON" ]]; then
    read -r EVID_M EVID_TPRIME EVID_U < <(count_denominator_corroboration "$CORROB_JSON")
  fi

  SUBTASK_ROWS=0
  if [[ "$SUBTASK_RC" -eq 0 && -n "$SUBTASK_JSON" && "$SUBTASK_JSON" != "[]" ]]; then
    read -r EVID_P_RAW EVID_S_RAW EVID_X_RAW < <(count_subtask_evidence "$SUBTASK_JSON")
    SUBTASK_ROWS=$(( EVID_S_RAW + EVID_X_RAW ))
  fi
  EVID_EXCLUDED="$EVID_X_RAW"

  IFS=$'\t' read -r EVID_STATE EVID_TOKEN EVID_NA_REASON EVID_STR < <(evidence_slot_state \
    live "$SUBTASK_RC" "$SUBTASK_ROWS" "$EVID_M" "$EVID_U" \
    "$EVID_P_RAW" "$EVID_S_RAW" "$EVID_X_RAW" "$MILESTONE")
fi

# Counters follow the state, not the other way round: on a NOT-EVALUATED row nothing usable
# was measured, so they are ABSENT (rendered null by --json), never zeroed. A zeroed counter
# on an unmeasured run publishes a MEASUREMENT that was never taken — the machine-surface
# twin of the very fail-open this guard closes. The clean-absence rows keep their literal 0/0
# because there the zero IS the measurement.
[[ "$EVID_NA_REASON" == "-" ]] && EVID_NA_REASON=""
if [[ -z "$EVID_STR" ]]; then
  # Structurally unreachable — the resolver returns exactly one non-empty slot string on
  # every path. Asserted anyway because an EMPTY slot 6 is the one failure this whole change
  # could introduce that the permissive `.+` field grammar would accept without complaint.
  die "internal: Indicator 6 resolved to an EMPTY slot-6 state — refusing to emit a field with a blank indicator" 2
fi
if [[ "$EVID_TOKEN" == "NOT-EVALUATED" ]]; then
  EVID_PRESERVED="N/A"; EVID_SCAFFOLDED="N/A"; EVID_RATIO="N/A"
else
  EVID_PRESERVED="$EVID_P_RAW"; EVID_SCAFFOLDED="$EVID_S_RAW"
  EVID_RATIO="$(ratio_round_half_up "$EVID_P_RAW" "$EVID_S_RAW")"
fi
[[ "$EVID_M" -ge 0 ]] && EVID_UNLABELLED="$EVID_U"

# Retained secondary sub-signal: the single Stage-13 G-CL4 close-gate boolean (non-destructive
# upgrade — the rate is primary, the boolean loses no signal).
case "$CLOSE_GATE" in
  pass) EVIDENCE_GATE="pass" ;;
  fail) EVIDENCE_GATE="fail" ;;
  na)   EVIDENCE_GATE="N/A" ;;
esac

# ─── Emission ────────────────────────────────────────────────────────────────

# Build the three rate sub-signal strings (value or N/A — reason).
fmt_rate() {
  # args: ratio num den na_reason  -> "<num>/<den> (<ratio>)" OR "N/A — <reason>"
  local ratio="$1" num="$2" den="$3" reason="$4"
  if [[ "$ratio" == "N/A" ]]; then
    echo "N/A — $reason"
  else
    echo "$num/$den ($ratio)"
  fi
}

RETRO_STR="$(fmt_rate "$RETRO_RATIO" "$RETRO_PRESENT" "$RETRO_EXPECTED" "$RETRO_NA_REASON")"
LESS_STR="$(fmt_rate "$LESS_RATIO" "$LESS_POP" "$LESS_PROMPTED" "$LESS_NA_REASON")"
CF_STR="$(fmt_rate "$CF_RATIO" "$CF_CLOSED" "$CF_RAISED" "$CF_NA_REASON")"
# EVID_STR is NOT built by fmt_rate: Indicator 6 carries three renderings, not two, and its
# resolution has to be callable from --self-test — which runs long before fmt_rate is defined.
# evidence_slot_state above is the single composition point for all three.

if [[ "$OUTPUT_FORMAT" == "json" ]]; then
  /usr/bin/python3 - \
    "$VERSION" "$MILESTONE" \
    "$RETRO_RATIO" "$RETRO_PRESENT" "$RETRO_EXPECTED" "$RETRO_NA_REASON" \
    "$LESS_RATIO" "$LESS_POP" "$LESS_PROMPTED" "$LESS_NA_REASON" \
    "$CF_RATIO" "$CF_CLOSED" "$CF_RAISED" "$CF_NA_REASON" \
    "$ROLLUP_PRESENCE" "$EVIDENCE_GATE" \
    "$EVID_RATIO" "$EVID_PRESERVED" "$EVID_SCAFFOLDED" "$EVID_NA_REASON" "$EVID_EXCLUDED" \
    "$EVID_STATE" "$EVID_TOKEN" "$EVID_UNLABELLED" <<'PY'
import json, sys
a = sys.argv
def na(v): return None if v == "N/A" else v
out = {
  "version": a[1],
  "milestone": a[2],
  "retro_conformance": {"ratio": na(a[3]), "present": na(a[4]), "expected": na(a[5]), "na_reason": a[6] or None},
  "lessons_population": {"ratio": na(a[7]), "populated": na(a[8]), "prompted": na(a[9]), "na_reason": a[10] or None},
  "carry_forward_closure": {"ratio": na(a[11]), "closed": na(a[12]), "raised": na(a[13]), "na_reason": a[14] or None},
  "pattern_emergence": "deferred-to-aggregate",
  "rollup_presence": a[15],
  # `scaffolded` is the MEASURABLE denominator (terminal stages 12/13 excluded);
  # `terminal_excluded` discloses how many were held out, so a reader can reconcile
  # it against the raw sub-task count without re-deriving the rule.
  #
  # `measurement_state` is Register A and a CONSUMER MUST BRANCH ON IT BEFORE READING ANY
  # COUNTER. `state_token` is Register B (null on a clean reading). On a NOT-EVALUATED row
  # the counters are null rather than 0, because nothing was measured and a zero would be a
  # fabricated measurement. `unlabelled_candidates` is the corroborator's finding — the
  # stage sub-task candidates the label-scoped query could not see; it is null when the
  # cross-check could not run at all, which is itself a different fact from zero.
  "phase_evidence_preservation": {"ratio": na(a[17]), "preserved": na(a[18]), "scaffolded": na(a[19]), "na_reason": a[20] or None, "terminal_excluded": int(a[21]), "measurement_state": a[22], "state_token": (None if a[23] == "-" else a[23]), "unlabelled_candidates": (None if a[24] == "N/A" else int(a[24]))},
  "evidence_close_gate": a[16],
  "mechanism": "compute-close-class-telemetry.sh",
}
print(json.dumps(out))
PY
  exit 0
fi

# Human form == the literal **Close-Class-Telemetry:** field value embedded in the H4 block.
echo "retro-conformance ${RETRO_STR}; lessons-population ${LESS_STR}; carry-forward-closure ${CF_STR}; pattern-emergence ${PATTERN_POINTER}; rollup-presence ${ROLLUP_PRESENCE}; evidence-preservation ${EVID_STR}; evidence-close-gate ${EVIDENCE_GATE}; mechanism: compute-close-class-telemetry.sh"
exit 0
