#!/usr/bin/env bash
# check-event-record-integrity.sh — READ-ONLY population validator for the
# pipeline event log, its write-log, and the AI-NNN action-item ledgers.
#
# READ-ONLY BY CONTRACT, not by style. Every surface it touches is opened for
# reading and never for writing: schema § 4.1 makes the event log append-only and
# § 7 makes it Vital, so a validator that can write is a validator that can
# destroy the evidence it exists to protect. `append-pipeline-event.sh`
# demonstrated the alternative — its --self-test used to append to the live log
# and revert by truncation, destroying concurrent appends (#6116).
#
# Usage:
#   ./check-event-record-integrity.sh [--surface=log|ledger|both] [--since ISO]
#                                     [--format=table|json]
#   ./check-event-record-integrity.sh --self-test
#
# Flags:
#   --surface=log|ledger|both : which population to sweep (default: both)
#   --since <ISO-8601 UTC>    : override the cutover instant. Default: parsed
#                               from pipeline-event-log-schema.md § 4.1
#                               `integrity_cutover:`. The schema is the single
#                               authority; this flag is for probing, not policy.
#   --format=table|json       : report shape (default: table)
#   --self-test               : run every check against committed fixtures, both
#                               arms, and exit 0 when all arms hold
#   --version                 : print the tool version
#   --help                    : print usage
#
# Checks (each prints its DENOMINATOR — a finding count with no population is
# not a measurement):
#   C1  log row integrity        — 10 fields under " | ", § 4.3a pipe grammar
#   C2  log enum conformance     — event_type / event_subtype / outcome /
#                                  reversibility / stage / ts_iso / actor
#   C3  log <-> write-log        — SHA1 CONTENT join, BOTH directions, reported
#                                  separately. A net count hides two opposite
#                                  failures inside one smaller number.
#   C4  ledger <-> log           — AI-NNN id join both ways, PLUS terminal-state
#                                  agreement. A presence predicate passes while
#                                  every row is stale; currency is the failure.
#   C5  ledger row integrity     — 13 fields, status in the § 2.3 enum
#
# C5 IS A PRECONDITION OF C4, NOT AN EXTENSION. A field-shifted ledger row makes
# a position-based `status` read return some other column, so C4's verdict on
# that row would be meaningless. C5-failing rows are reported and EXCLUDED from
# C4's denominator, and the exclusion is printed.
#
# Cutover: findings on rows BEFORE the cutover instant report LEGACY and do not
# affect the exit code; findings at or after it are VIOLATIONs. LEGACY means
# "does not gate", never "not reported" — every LEGACY finding is still printed
# with its denominator. The boundary exists because § 4.1 forbids editing and
# § 7 makes the log Vital, so a pre-cutover violation is permanently unrepairable
# and an un-dated validator is born failing.
#
# Exit codes: 0 = no post-cutover violation, 1 = >=1 post-cutover violation,
#             2 = surface unreadable / bad arguments / unparseable cutover
set -euo pipefail

# Pin PATH to system tools per bypass-mode-readiness.md
export PATH="/usr/bin:/bin"

TOOL_VERSION="1.0.0"

SCRIPT_DIR="$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )"
# TWO levels up from release/tools/, not three — the same anchor correction
# append-pipeline-event.sh carries. From a worktree at
# .claude/worktrees/<name>/release/tools/, a three-level walk mis-anchors.
REPO_ROOT="$( cd "$SCRIPT_DIR/../.." && pwd )"
SCHEMA_FILE="$REPO_ROOT/release/references/standards/pipeline-event-log-schema.md"
FIXTURE_DIR="$REPO_ROOT/release/tools/tests/fixtures/event-record"

# Fail-closed on an absent resolver, and pass an empty positional: a sourced file
# inherits the caller's "$@", so sourcing while $1 is still `--self-test` would
# run the LIBRARY's self-test and exit.
INSTANCE_LIB="$REPO_ROOT/core/deploy/lib-instance-path.sh"
[[ -r "$INSTANCE_LIB" ]] || { echo "ERROR: instance-path resolver missing at $INSTANCE_LIB" >&2; exit 2; }
# shellcheck source=/dev/null
source "$INSTANCE_LIB" ""

# The SAME resolver the writer and the reader use. A validator that resolved the
# path itself could validate a file the writer never writes — the exact drift
# that put a reader and its writer in different directories until #5634.
EVALS_RESULTS_PATH="$(pmo_evals_results_path)"
LOG_FILE="$EVALS_RESULTS_PATH/pipeline-event-log.md"
WRITE_LOG="$EVALS_RESULTS_PATH/pipeline-event-log-write.log"

# Hub-state root, resolved on the ladder automated-closeout.sh already publishes:
#   $HUB_STATE_PATH -> operator.toml operator_instance_hub_state_path
#                   -> $PMO_INSTANCE_PATH (inherited) -> the rooted default.
# The optional-key grep is guarded because a no-match `grep` under `pipefail`
# would abort at LOAD time, before argument parsing — a silent total failure of
# the tool caused by the ABSENCE of an optional config key.
HUB_STATE_PATH="${HUB_STATE_PATH:-}"
if [[ -z "$HUB_STATE_PATH" ]] && [[ -r "${HOME}/.config/pmo-platform/operator.toml" ]]; then
  _hs=$(/usr/bin/grep -m1 -E '^operator_instance_hub_state_path' "${HOME}/.config/pmo-platform/operator.toml" 2>/dev/null | /usr/bin/awk -F= '{gsub(/[" ]/,"",$2); print $2}' || true)
  [[ -n "$_hs" ]] && HUB_STATE_PATH="$_hs"
fi
HUB_STATE_PATH="${HUB_STATE_PATH:-$(pmo_instance_path)/hub-state}"

die() { echo "ERROR: $*" >&2; exit "${2:-2}"; }

usage() {
  # RANGE IS LOAD-BEARING: it must span the whole Usage + Flags block above. A
  # stale range prints the wrong help SILENTLY.
  /usr/bin/sed -n '12,27p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
  exit 0
}

# ─── The analysis engine ─────────────────────────────────────────────────────
#
# python3, not shell. Every predicate here is a load-bearing detector over a
# whole population, and this platform's `grep` is ugrep-shimmed: a pattern it
# rejects yields a PLAUSIBLE ZERO rather than an error, which is indistinguish-
# able from a clean population. python3 has no pattern to silently reject, and
# the field-split / SHA1-join predicates below have no correct shell form anyway.
#
# Usage: run_engine <log> <writelog> <ledger-glob-root> <cutover> <surface> <format>
run_engine() {
  /usr/bin/python3 - "$@" <<'PYEOF'
import sys, os, re, glob, hashlib, json

log_path, wlog_path, ledger_root, cutover, surface, fmt, schema_file = sys.argv[1:8]

TS_RE = re.compile(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$')
ACTOR_RE = re.compile(r'^(hub|operator|spoke:#\S+|skill:\S+)$')
REVERSIBILITY = {"CHEAP", "MODERATE", "EXPENSIVE", "IRREVERSIBLE"}
OUTCOMES = {"resolved", "pending", "escalated", "superseded"}
ITERATION_PREFIXES = ("dt-eng-pass-", "qa-dt-pass-")

# § 2.3 status enum, plus the § 2.3 alias table (`resolved`->`done`,
# `withdrawn`->`cancelled`) which that section declares READABLE, not migrated.
LEDGER_STATUS = {"open", "in-flight", "done", "cancelled", "superseded"}
LEDGER_STATUS_ALIAS = {"resolved": "done", "withdrawn": "cancelled"}
TERMINAL_STATUS = {"done", "cancelled", "superseded"}
TERMINAL_EVENT = {
    "action-item-resolved": "done",
    "action-item-cancelled": "cancelled",
    "action-item-superseded": "superseded",
}
AI_RE = re.compile(r'\bAI-\d+\b')


def parse_schema_enum(path):
    """§ 3 event_type -> set(subtypes). Bounded to the '## 3.' section so tables
    elsewhere in the doc cannot leak bogus types in — the same bound the writer's
    awk parser uses. Returns {} when the schema is unreadable."""
    try:
        text = open(path, encoding="utf-8", errors="replace").read()
    except OSError:
        return {}
    out, in_s3 = {}, False
    for line in text.splitlines():
        if line.startswith("## 3."):
            in_s3 = True
            continue
        if in_s3 and line.startswith("## "):
            break
        if not in_s3 or not line.startswith("|"):
            continue
        cols = line.split("|")
        if len(cols) < 4:
            continue
        c1, c3 = cols[1].strip(), cols[3]
        m = re.match(r'^`([a-z0-9.-]+)`$', c1)
        if not m:
            continue
        out[m.group(1)] = set(re.findall(r'`([a-z0-9.-]+)`', c3))
    return out


def split_row(line):
    """Canonical § 4.3a field split. The delimiter is ' | ' — a BARE pipe, never
    an escaped one. Counting bare pipes is the exact defect that produced this
    card's own wrong number: § 4.3a ADMITS `\\|` inside a payload, so a bare-pipe
    count legitimately exceeds 11 on a conformant row."""
    body = line
    if body.startswith("| "):
        body = body[2:]
    if body.endswith(" |"):
        body = body[:-2]
    return body.split(" | ")


def read_rows(path):
    """-> (rows, unreadable). Each row: (lineno, raw_line, fields)."""
    try:
        lines = open(path, encoding="utf-8", errors="replace").read().splitlines()
    except OSError:
        return None, True
    rows = []
    for i, raw in enumerate(lines, 1):
        if not raw.startswith("|"):
            continue
        if raw.startswith("|---") or raw.startswith("| ts_iso") or raw.startswith("| id "):
            continue
        rows.append((i, raw, split_row(raw)))
    return rows, False


def graded(ts):
    """A finding is a VIOLATION at or after the cutover, LEGACY before it. An
    unparseable timestamp cannot be dated, so it is graded — the safe direction:
    silently excusing a row whose date we cannot read would let a malformed row
    hide behind its own malformation."""
    if cutover == "(unset)":
        return False
    if not ts or not TS_RE.match(ts):
        return True
    return ts >= cutover


findings = []   # (check, severity, lineno-or-key, message, ts)
denoms = {}     # check -> (population, unit)
notes = []


def add(check, key, msg, ts):
    findings.append((check, "VIOLATION" if graded(ts) else "LEGACY", key, msg, ts))


schema_enum = parse_schema_enum(schema_file)
if not schema_enum:
    notes.append("schema § 3 unreadable or empty — C2 enum conformance SKIPPED "
                 "(explicit zero-state; a skipped check is never reported as a pass)")

# ─── C1 + C2 + C3: the log surface ───────────────────────────────────────────
log_rows, log_missing = None, False
if surface in ("log", "both"):
    log_rows, log_missing = read_rows(log_path)
    if log_missing:
        print("ERROR: log surface unreadable: %s" % log_path, file=sys.stderr)
        sys.exit(2)

    denoms["C1"] = (len(log_rows), "log rows")
    for lineno, raw, f in log_rows:
        ts = f[0].strip() if f else ""
        # (a) exactly 10 fields under the canonical delimiter
        if len(f) != 10:
            add("C1", "L%d" % lineno,
                "wrong field count: %d under ' | ' (expected 10)" % len(f), ts)
            continue
        # (b) the § 4.3a pipe grammar: with escaped pipes removed, exactly the
        #     11 structural pipes of a 10-column row remain.
        if raw.replace(r"\|", "").count("|") != 11:
            add("C1", "L%d" % lineno,
                "bare '|' in a field: %d structural pipes after stripping '\\|' (expected 11)"
                % raw.replace(r"\|", "").count("|"), ts)
        if not raw.startswith("| ") or not raw.endswith(" |"):
            add("C1", "L%d" % lineno, "row does not open '| ' and close ' |'", ts)

    if schema_enum:
        wellformed = [(n, r, f) for (n, r, f) in log_rows if len(f) == 10]
        denoms["C2"] = (len(wellformed), "well-formed log rows")
        for lineno, raw, f in wellformed:
            ts, ver, stage, etype, esub, actor = (x.strip() for x in f[:6])
            rev, outcome = f[7].strip(), f[8].strip()
            if not TS_RE.match(ts):
                add("C2", "L%d" % lineno, "ts_iso not ISO-8601 UTC: %r" % ts, ts)
            if etype not in schema_enum:
                add("C2", "L%d" % lineno, "undeclared event_type %r" % etype, ts)
            else:
                ok = esub in schema_enum[etype]
                if not ok and etype == "iteration":
                    ok = esub.startswith(ITERATION_PREFIXES)
                if not ok:
                    add("C2", "L%d" % lineno,
                        "undeclared event_subtype %r on event_type %r" % (esub, etype), ts)
            if not ACTOR_RE.match(actor):
                add("C2", "L%d" % lineno, "actor outside the declared forms: %r" % actor, ts)
            if rev not in REVERSIBILITY:
                add("C2", "L%d" % lineno, "reversibility outside the 4-value enum: %r" % rev, ts)
            if outcome not in OUTCOMES:
                add("C2", "L%d" % lineno, "outcome outside the 4-value enum: %r" % outcome, ts)
            if not (stage.isdigit() and 1 <= int(stage) <= 13):
                add("C2", "L%d" % lineno, "stage outside 1..13: %r" % stage, ts)

    # C3 — CONTENT join, both directions, never netted.
    if os.path.exists(wlog_path):
        row_sha = {}
        for lineno, raw, f in log_rows:
            row_sha.setdefault(hashlib.sha1(raw.encode("utf-8")).hexdigest(),
                               []).append((lineno, f[0].strip() if f else ""))
        entry_sha = {}
        for i, line in enumerate(open(wlog_path, encoding="utf-8", errors="replace")
                                 .read().splitlines(), 1):
            parts = line.split("\t")
            if len(parts) < 2:
                continue
            entry_sha.setdefault(parts[1].strip(), []).append((i, parts[0].strip()))
        denoms["C3"] = (len(log_rows), "log rows joined against %d write-log entries"
                        % sum(len(v) for v in entry_sha.values()))
        for sha, occurrences in row_sha.items():
            if sha not in entry_sha:
                for lineno, ts in occurrences:
                    add("C3", "L%d" % lineno,
                        "row-without-entry: no write-log entry for sha %s" % sha[:12], ts)
        for sha, occurrences in entry_sha.items():
            if sha not in row_sha:
                for i, ts in occurrences:
                    add("C3", "W%d" % i,
                        "entry-without-row: write-log entry for sha %s has no matching row "
                        "(a write that was attempted and did not land, or a row mutated "
                        "in place after it was written)" % sha[:12], ts)
    else:
        notes.append("write-log absent at %s — C3 reconciliation SKIPPED (explicit "
                     "zero-state)" % os.path.basename(wlog_path))

# ─── C5 then C4: the ledger surface ──────────────────────────────────────────
if surface in ("ledger", "both"):
    if os.path.isdir(ledger_root):
        ledgers = sorted(glob.glob(os.path.join(ledger_root, "*", "action-items.md")))
    else:
        ledgers = sorted(glob.glob(ledger_root)) if "*" in ledger_root else (
            [ledger_root] if os.path.exists(ledger_root) else [])

    all_rows, malformed_keys = [], set()
    for lp in ledgers:
        rows, _ = read_rows(lp)
        for lineno, raw, f in rows or []:
            if not f or not f[0].strip().startswith("AI-"):
                continue
            all_rows.append((lp, lineno, raw, f))

    denoms["C5"] = (len(all_rows), "ledger rows across %d ledger(s)" % len(ledgers))
    wellformed_ledger = []
    for lp, lineno, raw, f in all_rows:
        key = "%s:L%d" % (os.path.basename(os.path.dirname(lp)) or "ledger", lineno)
        created = f[1].strip() if len(f) > 1 else ""
        if len(f) != 13:
            malformed_keys.add((lp, lineno))
            add("C5", key, "wrong field count: %d under ' | ' (expected 13) — a "
                           "position-based status read on this row returns another column"
                % len(f), created)
            continue
        status = f[10].strip()
        canonical = LEDGER_STATUS_ALIAS.get(status, status)
        if canonical not in LEDGER_STATUS:
            add("C5", key, "status outside the § 2.3 enum (and not an aliased value): %r"
                % status, created)
        wellformed_ledger.append((lp, lineno, f, canonical, created))

    excluded = len(all_rows) - len(wellformed_ledger)
    if excluded:
        notes.append("C4 EXCLUDES %d of %d ledger row(s) that C5 rejected — state cannot "
                     "be reconciled against a row that cannot be parsed" % (excluded, len(all_rows)))

    if surface == "both" and log_rows is not None:
        # Index the log's action-item events by AI id, looking in BOTH subject and
        # payload: the id is the join key, and writers have put it in either.
        log_ai_subtypes = {}
        for lineno, raw, f in log_rows:
            if len(f) != 10:
                continue
            esub = f[4].strip()
            for m in AI_RE.findall(f[6] + " " + f[9]):
                log_ai_subtypes.setdefault(m, set()).add(esub)

        denoms["C4"] = (len(wellformed_ledger), "well-formed ledger rows joined "
                        "against %d distinct AI id(s) in the log" % len(log_ai_subtypes))

        ledger_ids = set()
        for lp, lineno, f, canonical, created in wellformed_ledger:
            ai = f[0].strip()
            ledger_ids.add(ai)
            key = "%s:L%d" % (os.path.basename(os.path.dirname(lp)) or "ledger", lineno)
            seen = log_ai_subtypes.get(ai)
            # (a) presence, ledger -> log
            if not seen:
                add("C4", key, "%s is on the ledger but has NO event in the log" % ai, created)
                continue
            # (b) STATE AGREEMENT — the limb that makes this a check. A 1:1 id
            #     join alone passes while every row is stale: it is a PRESENCE
            #     predicate and the failure mode is CURRENCY.
            if canonical in TERMINAL_STATUS:
                wanted = [e for e, s in TERMINAL_EVENT.items() if s == canonical]
                if not any(e in seen for e in wanted):
                    add("C4", key,
                        "%s carries terminal ledger status %r but the log has no matching "
                        "terminal event (%s) — the id join is clean and the record is STALE"
                        % (ai, canonical, "/".join(sorted(wanted))), created)
        # (c) presence, log -> ledger
        for ai, seen in sorted(log_ai_subtypes.items()):
            if ai not in ledger_ids:
                add("C4", ai, "%s has events in the log but no row on any ledger" % ai, "")
    elif surface == "ledger":
        notes.append("C4 requires BOTH surfaces — run with --surface=both to reconcile "
                     "ledger state against the log (explicit zero-state, not a pass)")

# ─── Report ──────────────────────────────────────────────────────────────────
violations = [f for f in findings if f[1] == "VIOLATION"]
legacy = [f for f in findings if f[1] == "LEGACY"]

if fmt == "json":
    print(json.dumps({
        "cutover": cutover,
        "surface": surface,
        "denominators": {k: {"population": v[0], "unit": v[1]} for k, v in denoms.items()},
        "violations": [{"check": c, "key": k, "message": m, "ts": t}
                       for c, s, k, m, t in violations],
        "legacy": [{"check": c, "key": k, "message": m, "ts": t}
                   for c, s, k, m, t in legacy],
        "notes": notes,
        "exit": 1 if violations else 0,
    }, indent=2))
else:
    print("event-record integrity — surface=%s cutover=%s" % (surface, cutover))
    if cutover == "(unset)":
        print("  ** CUTOVER UNRESOLVED ** — no boundary is bound yet, so every finding "
              "below is LEGACY and the tool exits 0. Bind the instant in schema § 4.1 "
              "at merge. This is an EXPLICIT zero-state, not a clean population.")
    for check in ("C1", "C2", "C3", "C4", "C5"):
        if check not in denoms:
            print("  %s  SKIPPED — surface not swept in this run" % check)
            continue
        pop, unit = denoms[check]
        v = sum(1 for f in findings if f[0] == check and f[1] == "VIOLATION")
        lg = sum(1 for f in findings if f[0] == check and f[1] == "LEGACY")
        print("  %s  %d violation(s) + %d legacy of %d %s" % (check, v, lg, pop, unit))
    for note in notes:
        print("  note: %s" % note)
    for c, s, k, m, t in findings:
        print("  [%s] %s %s: %s" % (s, c, k, m))
    print("RESULT: %d post-cutover violation(s), %d legacy finding(s)"
          % (len(violations), len(legacy)))

sys.exit(1 if violations else 0)
PYEOF
}

# Parse the cutover from the schema. The tool does NOT carry its own constant:
# the schema is the single authority, the same pattern parse_schema_enum uses,
# and the pattern whose absence let a tool drift from this document once already.
parse_cutover() {
  [[ -r "$SCHEMA_FILE" ]] || { printf '%s\n' "(unset)"; return 0; }
  /usr/bin/python3 -c '
import re, sys
m = re.search(r"^integrity_cutover:\s*(\S+)\s*$", open(sys.argv[1], encoding="utf-8",
              errors="replace").read(), re.M)
print(m.group(1) if m else "(unset)")' "$SCHEMA_FILE"
}

validate_cutover() {
  # Neither the sentinel nor a well-formed instant is a HARD ERROR. A cutover the
  # tool cannot parse must never silently degrade to "grade everything" or to
  # "grade nothing" — both are wrong, and both look like a pass from outside.
  case "$1" in
    "(unset)") return 0 ;;
    [0-9][0-9][0-9][0-9]-[0-9][0-9]-[0-9][0-9]T[0-9][0-9]:[0-9][0-9]:[0-9][0-9]Z) return 0 ;;
    *) die "unparseable integrity_cutover: '$1' — expected an ISO-8601 UTC instant (YYYY-MM-DDTHH:MM:SSZ) or the reserved sentinel (unset)" 2 ;;
  esac
}

# ─── Argument parsing ────────────────────────────────────────────────────────
SURFACE="both"
SINCE=""
FORMAT="table"
SELF_TEST=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --surface=*) SURFACE="${1#*=}"; shift ;;
    --surface) SURFACE="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --format) FORMAT="$2"; shift 2 ;;
    --self-test) SELF_TEST=true; shift ;;
    --version) echo "check-event-record-integrity.sh $TOOL_VERSION"; exit 0 ;;
    --help|-h) usage ;;
    *) die "Unknown flag: $1" 2 ;;
  esac
done

case "$SURFACE" in log|ledger|both) : ;; *) die "--surface must be log, ledger, or both (got '$SURFACE')" 2 ;; esac
case "$FORMAT" in table|json) : ;; *) die "--format must be table or json (got '$FORMAT')" 2 ;; esac

# ─── Self-test ───────────────────────────────────────────────────────────────
#
# Grades against COMMITTED FIXTURES, never the operator-instance population. A
# population sweep is a REPORT, not a gradeable criterion: its result depends on
# operator-local state no reviewer can reproduce, and it changes between two
# passes — the live log moved by 91 rows during this card's own build. An
# assertion pinned to a moving Layer-2 population is ungradeable by construction.
#
# EVERY check carries BOTH ARMS: a clean fixture that MUST pass and a dirty one
# that MUST fail. An arm that can only pass has not demonstrated that the check
# discriminates.
if [[ "$SELF_TEST" == "true" ]]; then
  [[ -d "$FIXTURE_DIR" ]] || die "self-test: fixture directory missing at $FIXTURE_DIR" 2

  ARMS=0
  FAILED=0
  PAST="2020-01-01T00:00:00Z"     # every fixture row is at or after this
  FUTURE="2099-01-01T00:00:00Z"   # every fixture row is before this

  # arm <expect-rc> <label> <log> <writelog> <ledger> <cutover> <surface>
  arm() {
    local want="$1" label="$2" lg="$3" wl="$4" ld="$5" co="$6" sfc="$7"
    local out rc=0
    ARMS=$((ARMS + 1))
    out="$(run_engine "$lg" "$wl" "$ld" "$co" "$sfc" table "$SCHEMA_FILE" 2>&1)" || rc=$?
    if [[ "$rc" -ne "$want" ]]; then
      echo "ERROR: self-test arm FAILED: $label (expected rc=$want, got rc=$rc)" >&2
      printf '%s\n' "$out" >&2
      FAILED=$((FAILED + 1))
    fi
  }

  F="$FIXTURE_DIR"
  # C1 — both arms
  arm 0 "C1 clean log passes"                    "$F/log-clean.md"        "$F/writelog-clean.log" "$F/ledger-clean.md" "$PAST" log
  arm 1 "C1 arity-bad log fails"                 "$F/log-arity-bad.md"    "/nonexistent"          "/nonexistent"       "$PAST" log
  arm 1 "C1 bare-pipe log fails"                 "$F/log-barepipe-bad.md" "/nonexistent"          "/nonexistent"       "$PAST" log
  # THE D-1 REGRESSION GUARD. § 4.3a ADMITS an escaped pipe, so a canonical `\|`
  # row is NOT malformed. This card's own filing claimed 20 malformed rows; all
  # 20 were conformant and the probe had counted BARE pipes. Anyone who
  # re-implements that probe fails here.
  arm 0 "D-1 guard: escaped-pipe log is CLEAN"   "$F/log-escapedpipe-clean.md" "/nonexistent"     "/nonexistent"       "$PAST" log
  # C2 — both arms
  arm 1 "C2 enum-bad log fails"                  "$F/log-enum-bad.md"     "/nonexistent"          "/nonexistent"       "$PAST" log
  # C3 — both arms, in BOTH directions, each on its own fixture
  arm 1 "C3 row-without-entry fails"             "$F/log-clean.md"        "$F/writelog-orphan-row.log"   "/nonexistent" "$PAST" log
  # THE DELIBERATELY FAILED WRITE: an entry with no row is the case a row-count
  # check cannot see, because it NETS against the opposite direction.
  arm 1 "C3 entry-without-row fails"             "$F/log-clean.md"        "$F/writelog-orphan-entry.log" "/nonexistent" "$PAST" log
  # C5 — both arms
  arm 0 "C5 clean ledger passes"                 "/nonexistent"           "/nonexistent"          "$F/ledger-clean.md" "$PAST" ledger
  arm 1 "C5 arity-bad ledger fails"              "/nonexistent"           "/nonexistent"          "$F/ledger-arity-bad.md" "$PAST" ledger
  # C4 — both arms. The clean pair joins 1:1 AND agrees on state; the divergent
  # pair ALSO joins 1:1 and must still FAIL. That asymmetry is the whole point:
  # a presence predicate passes both.
  arm 0 "C4 clean ledger+log agrees"             "$F/log-clean.md"        "$F/writelog-clean.log" "$F/ledger-clean.md" "$PAST" both
  arm 1 "C4 state-divergent ledger fails"        "$F/log-clean.md"        "$F/writelog-clean.log" "$F/ledger-state-divergent.md" "$PAST" both
  # Cutover contract — a DIRTY fixture that exits 0 because every finding is
  # pre-cutover. Without this arm the boundary could be dead code.
  #
  # THE FIXTURE CHOICE IS LOAD-BEARING, so do not "simplify" it to log-enum-bad.
  # A row whose ts_iso is unparseable cannot be dated, and graded() deliberately
  # fails TOWARD grading it: excusing a row because we cannot read its date would
  # let a malformed row hide behind its own malformation. log-enum-bad carries
  # exactly such a row, so it can never go fully LEGACY — by design. This arm
  # needs a dirty fixture whose rows are all DATABLE, which log-arity-bad is.
  arm 0 "cutover: pre-cutover findings are LEGACY" "$F/log-arity-bad.md"  "/nonexistent"          "/nonexistent"       "$FUTURE" log
  # The undatable row proves the fail-toward-grading rule is live: the SAME
  # future cutover leaves log-enum-bad non-zero.
  arm 1 "cutover: an undatable row grades anyway"  "$F/log-enum-bad.md"   "/nonexistent"          "/nonexistent"       "$FUTURE" log
  arm 0 "cutover: (unset) grades nothing"          "$F/log-enum-bad.md"   "/nonexistent"          "/nonexistent"       "(unset)" log
  # Unreadable surface is exit 2 — distinct from "clean". A tool that reported 0
  # findings on a file it could not open would be the defect this card is about.
  arm 2 "unreadable log surface exits 2"           "/nonexistent/log.md"  "/nonexistent"          "/nonexistent"       "$PAST" log

  # A denominator must actually be printed — a finding count with no population
  # is not a measurement, and CIAC-4 grades on the denominator's presence.
  ARMS=$((ARMS + 1))
  if ! run_engine "$F/log-clean.md" "$F/writelog-clean.log" "$F/ledger-clean.md" "$PAST" both table "$SCHEMA_FILE" \
       | /usr/bin/grep -q "of .* log rows"; then
    echo "ERROR: self-test arm FAILED: report must print a DENOMINATOR for every check" >&2
    FAILED=$((FAILED + 1))
  fi
  # A specificity arm on a fabricated identifier must return nothing. If this
  # ever fires, the AI-id extractor is matching something it should not.
  ARMS=$((ARMS + 1))
  if run_engine "$F/log-clean.md" "$F/writelog-clean.log" "$F/ledger-clean.md" "$PAST" both table "$SCHEMA_FILE" \
       | /usr/bin/grep -q "AI-999"; then
    echo "ERROR: self-test arm FAILED: fabricated AI-999 must not appear in any finding" >&2
    FAILED=$((FAILED + 1))
  fi
  # The cutover parser must reject a value it cannot read, rather than defaulting.
  ARMS=$((ARMS + 1))
  if ( validate_cutover "not-an-instant" ) 2>/dev/null; then
    echo "ERROR: self-test arm FAILED: an unparseable cutover must exit 2, not default" >&2
    FAILED=$((FAILED + 1))
  fi
  # And it must ACCEPT both admissible forms — a validator asserted only on its
  # rejections would still pass while false-rejecting every real value.
  ARMS=$((ARMS + 1))
  validate_cutover "(unset)" || { echo "ERROR: self-test arm FAILED: '(unset)' must be accepted" >&2; FAILED=$((FAILED + 1)); }
  ARMS=$((ARMS + 1))
  validate_cutover "2026-08-24T00:00:00Z" || { echo "ERROR: self-test arm FAILED: a well-formed instant must be accepted" >&2; FAILED=$((FAILED + 1)); }

  echo "self-test: $((ARMS - FAILED))/$ARMS assertion(s) passed"
  if [[ "$FAILED" -ne 0 ]]; then
    echo "ERROR: self-test: $FAILED arm(s) FAILED" >&2
    exit 1
  fi
  echo "self-test: PASS"
  echo "  C1 C2 C3 C4 C5 each exercised with a clean fixture that PASSES and a dirty one that FAILS"
  echo "  D-1 regression guard live: a canonical escaped-pipe row is NOT malformed"
  echo "  C3 asserted in BOTH directions on separate fixtures — a net count sees neither"
  echo "  C4 asserted on state agreement, not presence: the divergent pair joins 1:1 and still fails"
  echo "  cutover contract live: pre-cutover findings are LEGACY at exit 0; (unset) grades nothing"
  echo "  unreadable surface exits 2 — never reported as clean"
  exit 0
fi

# ─── Population sweep ────────────────────────────────────────────────────────
CUTOVER="${SINCE:-$(parse_cutover)}"
validate_cutover "$CUTOVER"

if [[ "$SURFACE" != "ledger" && ! -r "$LOG_FILE" ]]; then
  die "event log unreadable at the resolved instance path (surface=$SURFACE)" 2
fi

run_engine "$LOG_FILE" "$WRITE_LOG" "$HUB_STATE_PATH" "$CUTOVER" "$SURFACE" "$FORMAT" "$SCHEMA_FILE"
