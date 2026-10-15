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
#   ./check-event-record-integrity.sh --assert-bound
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
#   --assert-bound            : exit 1 while `integrity_cutover:` is still the
#                               reserved sentinel `(unset)`, 0 once an instant is
#                               bound. This is the ONLY mode that treats (unset)
#                               as a failure; every other mode honours the § 4.1
#                               value contract, where (unset) grades nothing at
#                               exit 0. Stage 12 runs it after binding the merge
#                               instant, so a SKIPPED binding fails loudly rather
#                               than leaving this validator green forever.
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
#   C4  ledger <-> log           — (release, AI-NNN) join both ways, PLUS
#                                  terminal-state agreement. A presence predicate
#                                  passes while every row is stale; currency is
#                                  the failure.
#   C5  ledger row integrity     — 13 fields, status in the § 2.3 enum
#
# C5 IS A PRECONDITION OF C4, NOT AN EXTENSION. A field-shifted ledger row makes
# a position-based `status` read return some other column, so C4's verdict on
# that row would be meaningless. C5-failing rows are reported and EXCLUDED from
# limbs (a)/(b) and their denominator, and the exclusion is printed. Limb (c)
# makes no status read — it reads only the id, cell 0 at any arity — so a
# C5-failing row still puts its id on the ledger for limb (c).
#
# C4 JOINS ON (RELEASE, ID), NEVER ON THE BARE ID. Every release numbers its action
# items from AI-001, so a bare-id join lets one release's event satisfy another's
# ledger row. A log row's release is its `version` column (schema § 2a rung 1); a
# ledger's release is the name of its hub-state directory. Every C4 finding key starts
# with the release — `<release>:L<n>` (a ledger row) or `<release>:<AI-id>` (log-side
# events with no row) — so attribution by release is a prefix read.
#
# LEGACY RULE. A version-form key (rows written before the writer enforced the slug;
# a few early directories) joins only under its literal value and is NEVER re-keyed
# through § 2a rung 3 — § 2a keeps rung 3 out of any gate that asserts an emission
# obligation, and every C4 limb is one. Its findings are graded by the one § 4.1
# cutover (log-side findings dated by their own rows); those rows predate it, so they
# report LEGACY. Legacy keys naming more than one milestone are reported
# release-INDETERMINATE in a report-only note.
#
# LIMB (c) HAS ITS OWN POPULATION AND ITS OWN DATE. Limbs (a)/(b) grade ledger rows;
# limb (c) grades the (release, id) pairs the log carries, so its tally prints on its
# own denominator line, C4c — a count over pairs is never printed as a ledger-row
# rate. A pair is dated by its own rows and graded when ANY of them is (at or after
# the cutover, or undatable), so a pair straddling the cutover grades.
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
VERSION_GRAMMAR_FILE="$SCRIPT_DIR/version-grammar.sh"   # sourced by the C4 legacy screen, never copied

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
  /usr/bin/sed -n '12,36p' "${BASH_SOURCE[0]}" | /usr/bin/sed 's/^# \{0,1\}//'
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
  C4_VERSION_GRAMMAR="$VERSION_GRAMMAR_FILE" /usr/bin/python3 - "$@" <<'PYEOF'
import sys, os, re, glob, hashlib, json, subprocess

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


def ledger_release(lp):
    """A ledger's release: the name of the directory holding it (<hub-state>/<slug>/
    action-items.md; a few early directories keep the version they were made under).
    One derivation for the C5 key, the C4 key and the C4 join."""
    return os.path.basename(os.path.dirname(lp)) or "ledger"


def legacy_release_keys(keys):
    """-> the subset of `keys` in the version form (the form the writer REJECTS as a
    release key), or None when that cannot be evaluated. The grammar is SOURCED from
    release/tools/version-grammar.sh (its contract: source, do not copy); keys travel
    as argv, never as script text."""
    grammar = os.environ.get("C4_VERSION_GRAMMAR", "")
    if not os.path.isfile(grammar):
        return None
    if not keys:
        return set()
    try:
        r = subprocess.run(
            ["/bin/bash", "-c",
             'keys=("$@"); source "$C4_VERSION_GRAMMAR" "" || exit 3; '
             'for v in "${keys[@]}"; do version_canonical "$v" && printf "%s\\n" "$v"; done; exit 0',
             "_"] + list(keys), capture_output=True, text=True, timeout=60)
    except (OSError, subprocess.SubprocessError):
        return None
    return {k for k in r.stdout.splitlines() if k} if r.returncode == 0 else None


findings = []   # (check, severity, lineno-or-key, message, ts)
denoms = {}     # check -> (population, unit)
notes = []

# FM-3 — limb (c) of C4 has its OWN population. Limbs (a)/(b) grade ledger rows; limb
# (c) grades the (release, id) pairs the log carries. One denominator over both would
# print a count over two populations as a ledger-row rate — one that can exceed its own
# population. So limb-(c) findings are tallied under the report label C4c, on their own
# denominator line, while every finding LINE still names the check C4: the close gate
# and the JSON consumers read `C4 <release>:…`, so the label splits the tally, never
# the check.
REPORTED_AS = {"C4c": "C4"}


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
        key = "%s:L%d" % (ledger_release(lp), lineno)
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
        notes.append("C4 EXCLUDES %d of %d ledger row(s) that C5 rejected from limbs (a)/(b) — "
                     "state cannot be reconciled against a row that cannot be parsed; limb (c) "
                     "still reads their ids, which sit first at any arity"
                     % (excluded, len(all_rows)))

    if surface == "both" and log_rows is not None:
        # Index action-item events by (release, AI id). Every release numbers from
        # AI-001, so a bare id names a different item in each release and a bare-id
        # join lets one release's event satisfy another's ledger row. The release is
        # the row's `version` column VERBATIM (schema § 2a rung 1 — the field M4 joins
        # on); the id is read from BOTH subject and payload.
        log_ai, log_ai_ts = {}, {}
        for lineno, raw, f in log_rows:
            if len(f) != 10:
                continue
            rel, esub, ts = f[1].strip(), f[4].strip(), f[0].strip()
            for m in AI_RE.findall(f[6] + " " + f[9]):
                log_ai.setdefault((rel, m), set()).add(esub)
                log_ai_ts.setdefault((rel, m), []).append(ts)

        denoms["C4"] = (len(wellformed_ledger), "well-formed ledger rows joined "
                        "against %d distinct (release, id) pair(s) in the log" % len(log_ai))
        denoms["C4c"] = (len(log_ai), "distinct (release, id) pair(s) in the log, each "
                         "joined to its release's ledger")

        # Limb (c)'s ledger side is keyed on EVERY AI row the ledger carries, C5-rejected
        # rows included (review CD-1). Limb (c) reads only the id, and the id is cell 0 at
        # any arity. The C5 exclusion exists to keep a POSITION-based status read off a
        # field-shifted row — a read limbs (a)/(b) make and limb (c) never does — so
        # excluding the row here would turn one C5 defect into a second, false C4 finding
        # that sends the operator to add a row the ledger already carries.
        ledger_keys = {(ledger_release(lp), f[0].strip()) for lp, lineno, raw, f in all_rows}
        for lp, lineno, f, canonical, created in wellformed_ledger:
            ai, rel = f[0].strip(), ledger_release(lp)
            key = "%s:L%d" % (rel, lineno)
            seen = log_ai.get((rel, ai))
            # (a) presence, ledger -> log, within the ledger's own release
            if not seen:
                add("C4", key, "%s is on the ledger but has NO event in the log under "
                               "release %r" % (ai, rel), created)
                continue
            # (b) STATE AGREEMENT — the limb that makes this a check. A 1:1 id
            #     join alone passes while every row is stale: it is a PRESENCE
            #     predicate and the failure mode is CURRENCY.
            if canonical in TERMINAL_STATUS:
                wanted = [e for e, s in TERMINAL_EVENT.items() if s == canonical]
                if not any(e in seen for e in wanted):
                    add("C4", key,
                        "%s carries terminal ledger status %r but the log has no matching "
                        "terminal event (%s) under release %r — the (release, id) join is "
                        "clean and the record is STALE"
                        % (ai, canonical, "/".join(sorted(wanted)), rel), created)
        # (c) presence, log -> ledger, within the event's own release, dated by the
        #     pair's OWN rows (graded when any is at/after the cutover; an undatable
        #     one grades, per graded()). Never undated: that grades every pre-cutover
        #     pair forever — the born-failing validator § 4.1 exists to prevent.
        #     Tallied as C4c, against its own population (FM-3).
        for (rel, ai), _seen in sorted(log_ai.items()):
            if (rel, ai) not in ledger_keys:
                tss = log_ai_ts[(rel, ai)]
                add("C4c", "%s:%s" % (rel, ai),
                    "%s has events in the log under release %r but no row on that "
                    "release's ledger" % (ai, rel),
                    next((t for t in tss if graded(t)), max(tss)))

        # (d) LEGACY RELEASE KEYS — REPORT-ONLY (notes, never add()). A version-form
        #     key joins only under its literal value and is never re-keyed through
        #     § 2a rung 3, which § 2a keeps out of every gate asserting an emission
        #     obligation. One naming >1 `milestone:#N` subject is INDETERMINATE (the
        #     measure query-pipeline-event.sh applies to a rung-3 match).
        keys = sorted({r for r, _ in log_ai} | {r for r, _ in ledger_keys})
        legacy = legacy_release_keys(keys)
        if legacy is None:
            notes.append("C4 legacy release keys NOT-EVALUATED — the version grammar could "
                         "not be sourced; this is not a clean result (report-only: findings "
                         "and grading are unaffected)")
        else:
            subs = {}
            for lineno, raw, f in log_rows:
                if len(f) == 10 and f[1].strip() in legacy and f[6].strip().startswith("milestone:#"):
                    subs.setdefault(f[1].strip(), set()).add(f[6].strip())
            indeterminate = sorted(k for k in legacy if len(subs.get(k, ())) > 1)
            notes.append(
                "C4 legacy release keys — legacy=[%s] indeterminate=[%s] (%d of %d release "
                "key(s) C4 joined are in the version form: each joins only under its literal "
                "value and is never re-keyed through § 2a rung 3; an indeterminate key names "
                "more than one milestone, so its verdicts are not 1:1 with a release). "
                "REPORT-ONLY — emitted through `notes`, never `add()`."
                % (", ".join(sorted(legacy)), ", ".join(indeterminate), len(legacy), len(keys)))
    elif surface == "ledger":
        notes.append("C4 requires BOTH surfaces — run with --surface=both to reconcile "
                     "ledger state against the log (explicit zero-state, not a pass)")

# ─── M4: the population screen ───────────────────────────────────────────────
#
# WHAT C4 STRUCTURALLY CANNOT SEE. C4 is a (release, AI-NNN) join both ways plus terminal-
# state agreement. Both directions of a join over ids cannot detect a commitment
# that minted NO id on either side — there is nothing to join on. That residue is
# what this screens for, which is why it is not a duplicate of C4.
#
# REPORT-ONLY BY CONSTRUCTION, not by convention. It emits through `notes`, so its
# output never enters `findings`, never becomes a VIOLATION, and therefore never
# reaches `sys.exit(1 if violations else 0)`. The screen reports OTHER releases'
# history, which the closing release neither caused nor can repair, and a blocking
# arm would gate every future close on debt its own operator cannot pay.
#
# The lifecycle term is the point. `(>=1 decision row) AND (no ledger)` is also
# what a CORRECT in-flight release looks like between plan approval and its first
# durable commitment, so a screen without a completion term flags healthy siblings
# at every close, forever.
if surface == "both" and log_rows is not None:
    if os.path.isdir(ledger_root):
        slug_dirs = sorted(d for d in os.listdir(ledger_root)
                           if os.path.isdir(os.path.join(ledger_root, d)))
        # field 2 (index 1) is the release SLUG — the schema names it the
        # "release join key — the Milestone SLUG". No new data source.
        rows_by_slug = {}
        for _ln, _raw, _f in log_rows:
            if len(_f) == 10:
                rows_by_slug.setdefault(_f[1].strip(), []).append(_f)

        m4_flagged, m4_notyet, m4_nodec, m4_ledger = [], [], [], []
        for slug in slug_dirs:
            fs = rows_by_slug.get(slug, [])
            if os.path.exists(os.path.join(ledger_root, slug, "action-items.md")):
                m4_ledger.append(slug)
            elif sum(1 for _f in fs if _f[3].strip() == "decision") < 1:
                m4_nodec.append(slug)
            elif any(_f[2].strip() == "13" for _f in fs):
                m4_flagged.append(slug)
            else:
                m4_notyet.append(slug)

        _tot = len(slug_dirs)
        _sum = len(m4_ledger) + len(m4_flagged) + len(m4_notyet) + len(m4_nodec)
        # What the denominator EXCLUDES, stated with it. The screen walks the
        # hub-state root, so a release that never got a directory is outside its
        # population entirely — and that is the case where the reported condition
        # is most severely true. An undeclared scope turns "N of 77" into "N of
        # every release", which is the denominator defect this tool exists to end.
        _unseen = sorted(s for s in rows_by_slug
                         if s not in set(slug_dirs)
                         and sum(1 for _f in rows_by_slug[s] if _f[3].strip() == "decision") >= 1)
        # EVERY bucket is rendered as `name=[...]`, and that is an assertion
        # contract, not formatting. A slug appears in MORE THAN ONE bucket name's
        # vicinity in this text, so an arm that greps the note AS A WHOLE for a
        # slug passes while the screen is inverted — measured, not assumed: the
        # mutation that demotes a flagged slug into not-yet leaves every whole-note
        # substring test satisfied. An arm MUST bind inside one bucket's brackets.
        notes.append(
            "M4 population screen — flagged=[%s] (%d of %d slug director(ies) scanned "
            "carry >=1 decision-class row, NO action-items.md, and a stage-13 row, i.e. "
            "the release completed)"
            % (", ".join(m4_flagged), len(m4_flagged), _tot))
        notes.append(
            "M4 partition of %d scanned director(ies): ledger-bearing=%d flagged=%d "
            "not-yet-assessable=%d no-decision-row=%d; not_yet=[%s]; buckets %s the "
            "denominator (%d vs %d). DENOMINATOR SCOPE: this screen walks the "
            "hub-state root only — %d further release slug(s) carry decision rows in "
            "the log with NO hub-state directory at all and are OUTSIDE this "
            "denominator. REPORT-ONLY — emitted through `notes`, never `add()`, so it "
            "cannot affect the exit status."
            % (_tot, len(m4_ledger), len(m4_flagged), len(m4_notyet), len(m4_nodec),
               ", ".join(m4_notyet),
               "sum to" if _sum == _tot else "DO NOT SUM TO", _sum, _tot, len(_unseen)))
    else:
        notes.append("M4 population screen SKIPPED — ledger_root is not a directory "
                     "(explicit zero-state; a skipped screen is never reported as a "
                     "clean population)")
else:
    # The screen needs BOTH surfaces: the slug directories AND the log rows the
    # slug joins against. Say so, rather than emitting nothing — an absent note
    # and a clean population are the same output, which is the defect family
    # this whole release exists to close.
    notes.append("M4 population screen SKIPPED — requires BOTH surfaces; run with "
                 "--surface=both (explicit zero-state, not a pass)")

# ─── Report ──────────────────────────────────────────────────────────────────
violations = [f for f in findings if f[1] == "VIOLATION"]
legacy = [f for f in findings if f[1] == "LEGACY"]

if fmt == "json":
    print(json.dumps({
        "cutover": cutover,
        "surface": surface,
        "denominators": {k: {"population": v[0], "unit": v[1]} for k, v in denoms.items()},
        "violations": [{"check": REPORTED_AS.get(c, c), "key": k, "message": m, "ts": t}
                       for c, s, k, m, t in violations],
        "legacy": [{"check": REPORTED_AS.get(c, c), "key": k, "message": m, "ts": t}
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
    for check in ("C1", "C2", "C3", "C4", "C4c", "C5"):
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
        print("  [%s] %s %s: %s" % (s, REPORTED_AS.get(c, c), k, m))
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
ASSERT_BOUND=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --surface=*) SURFACE="${1#*=}"; shift ;;
    --surface) SURFACE="$2"; shift 2 ;;
    --since) SINCE="$2"; shift 2 ;;
    --format=*) FORMAT="${1#*=}"; shift ;;
    --format) FORMAT="$2"; shift 2 ;;
    --self-test) SELF_TEST=true; shift ;;
    --assert-bound) ASSERT_BOUND=true; shift ;;
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
  # C4 runs on DIRECTORY roots: it joins on (release, id) and a ledger's release is its
  # directory, so only a tree pairs a ledger with its own release's rows. The per-limb
  # collision arms, near-misses and controls follow the M4 block.
  arm 0 "C4 clean ledger+log agrees (directory branch)" "$F/log-m4.md" "/nonexistent" "$F/hub-state-tree" "$PAST" both
  # C5 grades STRUCTURE, never currency: a well-formed but state-stale ledger passes C5.
  arm 0 "C5 passes a well-formed but state-stale ledger" "/nonexistent" "/nonexistent" "$F/ledger-state-divergent.md" "$PAST" ledger
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

  # SIGPIPE-REWRITE, covering this arm and the specificity arm below. Both were
  # `run_engine … | /usr/bin/grep -q …`, which under this file's `set -euo pipefail`
  # (:56) lets `grep -q`'s early exit break the pipe so the pipeline reports the
  # WRITER's status instead of the match. They failed in opposite directions and the
  # second one is the dangerous one: the denominator arm would report a denominator
  # missing that is present (a false failure), while the specificity arm would
  # silently DROP a genuine AI-999 sighting — a probe that cannot fire, shipped
  # inside the validator whose whole subject is population integrity. Both are
  # size-dependent, so they stay inert on small fixtures and wake up on the live log.
  #
  # NOT a here-string here. `grep -q … <<<"$(run_engine …)"` discards run_engine's
  # exit status inside the command substitution. Unlike a `printf` writer this one
  # carries a real status (1 = findings, 2 = unreadable surface), so it is captured
  # the way every other arm in this harness captures it — see `arm()` above — and
  # reported on failure, which is also what makes an engine that never ran
  # distinguishable from an engine that ran and printed the wrong thing.

  # A denominator must actually be printed — a finding count with no population
  # is not a measurement, and CIAC-4 grades on the denominator's presence.
  ARMS=$((ARMS + 1))
  _dn_rc=0
  _dn_out="$(run_engine "$F/log-clean.md" "$F/writelog-clean.log" "$F/ledger-clean.md" "$PAST" both table "$SCHEMA_FILE")" || _dn_rc=$?
  if ! /usr/bin/grep -q "of .* log rows" <<<"$_dn_out"; then
    echo "ERROR: self-test arm FAILED: report must print a DENOMINATOR for every check (engine rc=$_dn_rc)" >&2
    FAILED=$((FAILED + 1))
  fi
  # A specificity arm on a fabricated identifier must return nothing. If this
  # ever fires, the AI-id extractor is matching something it should not.
  ARMS=$((ARMS + 1))
  _sp_rc=0
  _sp_out="$(run_engine "$F/log-clean.md" "$F/writelog-clean.log" "$F/ledger-clean.md" "$PAST" both table "$SCHEMA_FILE")" || _sp_rc=$?
  if /usr/bin/grep -q "AI-999" <<<"$_sp_out"; then
    echo "ERROR: self-test arm FAILED: fabricated AI-999 must not appear in any finding (engine rc=$_sp_rc)" >&2
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

  # --assert-bound, BOTH arms. Without the negative arm this mode could exit 0
  # unconditionally and nothing would notice — which is the exact shape of the
  # defect it exists to detect, so asserting only the positive direction would be
  # self-defeating. The mode dispatches below this block, so it is exercised as a
  # SUBPROCESS of this same file rather than re-implemented. `--since` overrides
  # the parsed cutover (its documented probing use), so neither arm edits the
  # schema, and both exit before any surface is opened — the live log is untouched.
  ARMS=$((ARMS + 1))
  if bash "${BASH_SOURCE[0]}" --assert-bound --since "(unset)" >/dev/null 2>&1; then
    echo "ERROR: self-test arm FAILED: --assert-bound must exit non-zero while the cutover is (unset)" >&2
    FAILED=$((FAILED + 1))
  fi
  ARMS=$((ARMS + 1))
  if ! bash "${BASH_SOURCE[0]}" --assert-bound --since "2026-01-01T00:00:00Z" >/dev/null 2>&1; then
    echo "ERROR: self-test arm FAILED: --assert-bound must exit 0 once an instant is bound" >&2
    FAILED=$((FAILED + 1))
  fi

  # ─── M4 population screen — BOTH ARMS in ONE engine run ────────────────────
  #
  # `arm()` grades the EXIT CODE and M4 cannot touch the exit code by design, so
  # these arms capture the report and assert on the NOTE TEXT — the shape the
  # denominator and specificity probes above already use, here-strings rather
  # than pipes (see the SIGPIPE note above).
  #
  # BIND INSIDE ONE BUCKET'S BRACKETS. A whole-note grep for a slug is VACUOUS:
  # every scanned slug is named somewhere in the two notes, so an inverted screen
  # (flagged slug demoted to not-yet) still satisfies it. Measured, not assumed —
  # the first form of this arm set reported 9/9 and let that exact mutation
  # through. The distinct tokens `flagged=[` and `not_yet=[` each occur exactly
  # once in the report, so the extraction needs no `head` and stays clear of the
  # SIGPIPE idiom the repository-integrity gate detects.
  M4T="$F/hub-state-tree"
  _m4_rc=0
  _m4_out="$(run_engine "$F/log-m4.md" "/nonexistent" "$M4T" "$PAST" both table "$SCHEMA_FILE")" || _m4_rc=$?
  _m4_flagged="$(/usr/bin/sed -n 's/.*flagged=\[\([^]]*\)\].*/\1/p' <<<"$_m4_out")"
  _m4_notyet="$(/usr/bin/sed -n 's/.*not_yet=\[\([^]]*\)\].*/\1/p' <<<"$_m4_out")"

  m4_assert() {   # m4_assert <must|mustnot> <bucket-contents> <slug> <label>
    local mode="$1" bucket="$2" slug="$3" label="$4" found=0
    ARMS=$((ARMS + 1))
    case ",${bucket// /}," in *",$slug,"*) found=1 ;; esac
    if { [[ "$mode" == "must" ]] && [[ "$found" -ne 1 ]]; } ||
       { [[ "$mode" == "mustnot" ]] && [[ "$found" -ne 0 ]]; }; then
      echo "ERROR: self-test arm FAILED: $label (flagged=[$_m4_flagged] not_yet=[$_m4_notyet] rc=$_m4_rc)" >&2
      FAILED=$((FAILED + 1))
    fi
  }

  m4_assert must    "$_m4_flagged" fixture-closed-no-ledger   "M4 POSITIVE: a completed ledger-less slug MUST be flagged"
  m4_assert mustnot "$_m4_flagged" fixture-inflight-no-ledger "M4 NEGATIVE: an in-flight ledger-less slug must NOT be flagged"
  m4_assert must    "$_m4_notyet"  fixture-inflight-no-ledger "M4 PARTITION: the in-flight slug lands in not-yet-assessable"
  m4_assert mustnot "$_m4_flagged" fixture-clean-release      "M4 NEGATIVE: a ledger-bearing slug must NOT be flagged"
  m4_assert mustnot "$_m4_flagged" fixture-quiet-no-ledger    "M4 NEGATIVE: a slug with no decision row must NOT be flagged"

  # REPORT-ONLY, OBSERVED rather than argued: a run that FLAGS a slug still exits 0.
  ARMS=$((ARMS + 1))
  [[ "$_m4_rc" -eq 0 ]] || {
    echo "ERROR: self-test arm FAILED: the M4 screen must not affect the exit status — a run that flags a slug must still exit 0, got rc=$_m4_rc" >&2
    FAILED=$((FAILED + 1)); }
  # The denominator is COMPUTED from the scanned tree, never carried as a constant.
  ARMS=$((ARMS + 1))
  /usr/bin/grep -qF "of 4 slug director" <<<"$_m4_out" || {
    echo "ERROR: self-test arm FAILED: M4 must print a denominator computed from the scanned tree" >&2
    FAILED=$((FAILED + 1)); }
  # The buckets must account for EVERY scanned directory.
  ARMS=$((ARMS + 1))
  /usr/bin/grep -qF "buckets sum to the denominator (4 vs 4)" <<<"$_m4_out" || {
    echo "ERROR: self-test arm FAILED: M4 buckets must account for every scanned directory" >&2
    FAILED=$((FAILED + 1)); }
  # The DIRECTORY branch must actually have been taken — the branch C4/C5 use in
  # production; the C4 release-scope arms below run there too.
  ARMS=$((ARMS + 1))
  /usr/bin/grep -qF "ledger rows across 1 ledger(s)" <<<"$_m4_out" || {
    echo "ERROR: self-test arm FAILED: the fixture tree must exercise the DIRECTORY branch of the ledger resolver" >&2
    FAILED=$((FAILED + 1)); }
  # A file-shaped root must report the screen SKIPPED — never silence.
  ARMS=$((ARMS + 1))
  _m4f_rc=0
  _m4f_out="$(run_engine "$F/log-clean.md" "$F/writelog-clean.log" "$F/ledger-clean.md" "$PAST" both table "$SCHEMA_FILE")" || _m4f_rc=$?
  /usr/bin/grep -qF "M4 population screen SKIPPED" <<<"$_m4f_out" || {
    echo "ERROR: self-test arm FAILED: a file-shaped ledger_root must report the screen SKIPPED, not nothing (rc=$_m4f_rc)" >&2
    FAILED=$((FAILED + 1)); }

  # ─── C4 release scope — collision arms, near-misses, controls ────────────────
  # Each limb: one finding a bare-id join HIDES (RED pre-fix) and a NEAR-MISS owning its
  # event/row in its own release, which must stay silent. Bound to key + message, per
  # bucket, at every cutover: a false positive graded LEGACY exits 0, so at FUTURE only
  # the C4 line and per-key absence can see it (U5 limb 3).
  MID="2026-08-20T00:00:00Z"   # after the v0.92 rows and AI-006's first row; before every other row
  CL="$F/log-c4-collision.md";         CT="$F/c4-collision-tree"
  CLC="$F/log-c4-collision-control.md"; CTC="$F/c4-collision-tree-control"
  rec_find() {   # rec_find <check> <output> <VIOLATION|LEGACY> <key-prefix> <message-fragment>
    local chk="$1" out="$2" bucket="$3" kp="$4" frag="$5" line
    while IFS= read -r line; do
      case "$line" in *"[$bucket] $chk $kp"*": "*"$frag"*) return 0 ;; esac
    done <<<"$out"
    return 1
  }
  c4_find() { rec_find C4 "$@"; }   # c4_find <output> <VIOLATION|LEGACY> <key-prefix> <message-fragment>
  c4_expect() {   # c4_expect <must|mustnot> <label> <output> <bucket> <key-prefix> <fragment>
    local mode="$1" label="$2" found=0
    shift 2
    ARMS=$((ARMS + 1))
    c4_find "$@" && found=1
    if { [[ "$mode" == "must" ]] && [[ "$found" -ne 1 ]]; } ||
       { [[ "$mode" == "mustnot" ]] && [[ "$found" -ne 0 ]]; }; then
      echo "ERROR: self-test arm FAILED: $label" >&2
      FAILED=$((FAILED + 1))
    fi
  }
  for _co in "$PAST" "$MID" "$FUTURE"; do
    _c4_rc=0
    _c4_out="$(run_engine "$CL" "/nonexistent" "$CT" "$_co" both table "$SCHEMA_FILE")" || _c4_rc=$?
    _b=VIOLATION; [[ "$_co" == "$FUTURE" ]] && _b=LEGACY
    c4_expect must "C4 limb (b) @${_co}: fixture-c4-rel-a AI-001 stale in its OWN release (rc=$_c4_rc)" "$_c4_out" "$_b" "fixture-c4-rel-a:L" "AI-001 carries terminal ledger status 'superseded'"
    c4_expect must "C4 limb (a) @${_co}: fixture-c4-rel-a AI-002 has no event in its OWN release" "$_c4_out" "$_b" "fixture-c4-rel-a:L" "AI-002 is on the ledger but has NO event in the log under release 'fixture-c4-rel-a'"
    c4_expect must "C4 limb (c) @${_co}: fixture-c4-rel-b AI-003 has no row on its OWN ledger" "$_c4_out" "$_b" "fixture-c4-rel-b:AI-003" "no row on that release's ledger"
    # FM-4 — limb (c) is dated by the pair's OWN rows, graded when ANY of them is.
    # AI-006's two rows straddle MID, so the MID pass is the pin: dating the pair by
    # its earliest (or its first) row would read it LEGACY there.
    c4_expect must "C4 limb (c) dating @${_co}: fixture-c4-rel-b AI-006 straddles MID and grades by ANY own row" "$_c4_out" "$_b" "fixture-c4-rel-b:AI-006" "no row on that release's ledger"
    for _bk in VIOLATION LEGACY; do
      c4_expect mustnot "C4 near-miss @${_co}/${_bk}: fixture-c4-rel-b rows own their events" "$_c4_out" "$_bk" "fixture-c4-rel-b:L" ""
      c4_expect mustnot "C4 near-miss @${_co}/${_bk}: fixture-c4-rel-a AI-003 owns its row" "$_c4_out" "$_bk" "fixture-c4-rel-a:AI-003" ""
      # CD-1 — limb (c) reads only the ledger's id cell, so a C5-rejected row still puts
      # its id on the ledger. Key-agnostic, so a bare-id key cannot slip past it.
      c4_expect mustnot "C4 near-miss @${_co}/${_bk}: AI-005's C5-rejected row is on its own ledger" "$_c4_out" "$_bk" "" "AI-005 has events in the log"
    done
    if [[ "$_co" == "$MID" ]]; then   # LEGACY RULE — graded by the one cutover, by date
      c4_expect must    "C4 legacy key v0.92 AI-004 reports LEGACY at MID" "$_c4_out" LEGACY "v0.92:AI-004" "no row on that release's ledger"
      c4_expect mustnot "C4 legacy key v0.92 AI-004 is not a VIOLATION at MID" "$_c4_out" VIOLATION "v0.92:AI-004" ""
      # FM-3 — limb (c) prints against its OWN population, the (release, id) pairs, never
      # against ledger rows. At MID the two lines split 2+0 of 5 rows and 2+1 of 8 pairs.
      ARMS=$((ARMS + 1))
      /usr/bin/grep -qF "C4  2 violation(s) + 0 legacy of 5 well-formed ledger rows " <<<"$_c4_out" || {
        echo "ERROR: self-test arm FAILED: the C4 line must count limbs (a)/(b) against well-formed ledger rows only (rc=$_c4_rc)" >&2
        FAILED=$((FAILED + 1)); }
      ARMS=$((ARMS + 1))
      /usr/bin/grep -qF "C4c  2 violation(s) + 1 legacy of 8 distinct (release, id) pair(s) in the log" <<<"$_c4_out" || {
        echo "ERROR: self-test arm FAILED: limb (c) must print its own line against its (release, id) pairs (rc=$_c4_rc)" >&2
        FAILED=$((FAILED + 1)); }
    fi
  done
  # CD-1's input carries the near-miss: the AI-005 row IS a C5 finding. The loop's last
  # pass ran at FUTURE, so that finding reports LEGACY.
  ARMS=$((ARMS + 1))
  rec_find C5 "$_c4_out" LEGACY "fixture-c4-rel-b:L" "wrong field count: 12 under" || {
    echo "ERROR: self-test arm FAILED: the collision tree's AI-005 row must be a C5 finding (12 fields)" >&2
    FAILED=$((FAILED + 1)); }
  ARMS=$((ARMS + 1))   # 8 pairs over 6 bare ids — pre-fix prints "6 distinct AI id(s)"
  /usr/bin/grep -qF "joined against 8 distinct (release, id) pair(s) in the log" <<<"$_c4_out" || {
    echo "ERROR: self-test arm FAILED: the C4 denominator must count distinct (release, id) pairs" >&2
    FAILED=$((FAILED + 1)); }
  # AC-1 CONTROL — same tree, log plus A's OWN events: nothing for A; B's finding stays.
  _c4c_rc=0
  _c4c_out="$(run_engine "$CLC" "/nonexistent" "$CT" "$PAST" both table "$SCHEMA_FILE")" || _c4c_rc=$?
  for _bk in VIOLATION LEGACY; do
    c4_expect mustnot "C4 control: fixture-c4-rel-a with its own events reports nothing (${_bk}, rc=$_c4c_rc)" "$_c4c_out" "$_bk" "fixture-c4-rel-a:" ""
  done
  c4_expect must "C4 control: the other release's finding remains" "$_c4c_out" VIOLATION "fixture-c4-rel-b:AI-003" ""
  for _co in "$PAST" "$FUTURE"; do   # the agreeing control: zero at a grading and an all-legacy cutover
    _c4z_rc=0
    _c4z_out="$(run_engine "$CLC" "/nonexistent" "$CTC" "$_co" both table "$SCHEMA_FILE")" || _c4z_rc=$?
    ARMS=$((ARMS + 1))
    /usr/bin/grep -qF "C4  0 violation(s) + 0 legacy of " <<<"$_c4z_out" || {
      echo "ERROR: self-test arm FAILED: the agreeing control must read 0 violation(s) + 0 legacy at ${_co} (rc=$_c4z_rc)" >&2
      FAILED=$((FAILED + 1)); }
    ARMS=$((ARMS + 1))   # FM-3: the ledger-row line alone no longer sees limb (c)
    /usr/bin/grep -qF "C4c  0 violation(s) + 0 legacy of " <<<"$_c4z_out" || {
      echo "ERROR: self-test arm FAILED: the agreeing control's limb-(c) line must read 0 violation(s) + 0 legacy at ${_co} (rc=$_c4z_rc)" >&2
      FAILED=$((FAILED + 1)); }
  done
  # The legacy note, bound INSIDE each bucket's brackets (a whole-note grep is vacuous).
  _c4_lg="$(/usr/bin/sed -n 's/.* legacy=\[\([^]]*\)\] indeterminate=.*/\1/p' <<<"$_c4z_out")"
  _c4_id="$(/usr/bin/sed -n 's/.* indeterminate=\[\([^]]*\)\].*/\1/p' <<<"$_c4z_out")"
  c4_bucket() {   # c4_bucket <must|mustnot> <bucket-contents> <item> <label>
    local mode="$1" bucket="$2" item="$3" label="$4" found=0
    ARMS=$((ARMS + 1))
    case ",${bucket// /}," in *",$item,"*) found=1 ;; esac
    if { [[ "$mode" == "must" ]] && [[ "$found" -ne 1 ]]; } ||
       { [[ "$mode" == "mustnot" ]] && [[ "$found" -ne 0 ]]; }; then
      echo "ERROR: self-test arm FAILED: $label (legacy=[$_c4_lg] indeterminate=[$_c4_id])" >&2
      FAILED=$((FAILED + 1))
    fi
  }
  c4_bucket must    "$_c4_lg" v0.92            "C4 legacy note names the version-form key"
  c4_bucket mustnot "$_c4_lg" fixture-c4-rel-a "C4 legacy note never names a slug"
  c4_bucket must    "$_c4_id" v0.92            "C4 legacy note: a version-form key naming two milestones is INDETERMINATE"
  c4_bucket mustnot "$_c4_id" fixture-c4-rel-b "C4 legacy note: a slug naming two milestones is NOT indeterminate"
  ARMS=$((ARMS + 1))   # PV-7 — the screen reports its own degradation and cannot move the exit
  _c4n_rc=0
  _c4n_out="$(VERSION_GRAMMAR_FILE=/nonexistent; run_engine "$CLC" "/nonexistent" "$CTC" "$PAST" both table "$SCHEMA_FILE")" || _c4n_rc=$?
  if [[ "$_c4n_rc" -ne 0 ]] || ! /usr/bin/grep -qF "C4 legacy release keys NOT-EVALUATED" <<<"$_c4n_out" \
     || ! /usr/bin/grep -qF "this is not a clean result" <<<"$_c4n_out"; then
    echo "ERROR: self-test arm FAILED: an unavailable grammar must report NOT-EVALUATED and leave the exit alone (rc=$_c4n_rc)" >&2
    FAILED=$((FAILED + 1))
  fi
  ARMS=$((ARMS + 1))   # --surface=ledger narrows C4 OUT: SKIPPED, never a zero — on both lines
  _c4s_rc=0
  _c4s_out="$(run_engine "$CL" "/nonexistent" "$CT" "$PAST" ledger table "$SCHEMA_FILE")" || _c4s_rc=$?
  if ! /usr/bin/grep -qF "C4  SKIPPED" <<<"$_c4s_out" || ! /usr/bin/grep -qF "C4c  SKIPPED" <<<"$_c4s_out"; then
    echo "ERROR: self-test arm FAILED: at --surface=ledger both C4 lines must report SKIPPED (rc=$_c4s_rc)" >&2
    FAILED=$((FAILED + 1))
  fi
  _c4g_rc=0   # one key derivation for every root shape: a GLOB root keys like the tree
  _c4g_out="$(run_engine "$CL" "/nonexistent" "$CT/*/action-items.md" "$PAST" both table "$SCHEMA_FILE")" || _c4g_rc=$?
  c4_expect must "C4 glob-shaped root keys like the tree (rc=$_c4g_rc)" "$_c4g_out" VIOLATION "fixture-c4-rel-a:L" "AI-001 carries terminal ledger status 'superseded'"
  ARMS=$((ARMS + 1))   # FM-3 — the JSON report carries limb (c)'s own denominator too
  _c4j_rc=0
  _c4j_out="$(run_engine "$CL" "/nonexistent" "$CT" "$PAST" both json "$SCHEMA_FILE")" || _c4j_rc=$?
  /usr/bin/grep -qF '"C4c": {' <<<"$_c4j_out" || {
    echo "ERROR: self-test arm FAILED: the JSON denominators must carry C4c, limb (c)'s (release, id)-pair population (rc=$_c4j_rc)" >&2
    FAILED=$((FAILED + 1)); }

  echo "self-test: $((ARMS - FAILED))/$ARMS assertion(s) passed"
  if [[ "$FAILED" -ne 0 ]]; then
    echo "ERROR: self-test: $FAILED arm(s) FAILED" >&2
    exit 1
  fi
  echo "self-test: PASS"
  echo "  C1 C2 C3 C4 C5 each exercised with a clean fixture that PASSES and a dirty one that FAILS"
  echo "  D-1 regression guard live: a canonical escaped-pipe row is NOT malformed"
  echo "  C3 asserted in BOTH directions on separate fixtures — a net count sees neither"
  echo "  C4 asserted per (release, id): each limb's collision arm fires where a bare-id join is"
  echo "    blind; each near-miss stays silent at PAST, MID and FUTURE; the agreeing control reads"
  echo "    0 violation(s) + 0 legacy; a legacy version-form key is dated by the one cutover and"
  echo "    named INDETERMINATE when it spans more than one milestone"
  echo "  C4 limb (c) keys its ledger side on EVERY AI row, so a C5-rejected row's id stays on the"
  echo "    ledger; it prints its own (release, id)-pair denominator line (C4c); and a pair is dated"
  echo "    by its own rows — one straddling the cutover grades"
  echo "  cutover contract live: pre-cutover findings are LEGACY at exit 0; (unset) grades nothing"
  echo "  --assert-bound asserted BOTH ways: non-zero while (unset), zero once an instant is bound"
  echo "  unreadable surface exits 2 — never reported as clean"
  echo "  M4 population screen asserted on its NOTE TEXT, bound INSIDE one bucket's brackets:"
  echo "    a whole-note grep is vacuous — every scanned slug is named somewhere in the notes,"
  echo "    so an inverted screen satisfies it; the first form of these arms passed while the"
  echo "    detector was dead. Four buckets, one fixture slug apiece, summing to the computed"
  echo "    denominator; report-only OBSERVED (a run that flags still exits 0); and the fixture"
  echo "    tree was the FIRST arm to enter the ledger resolver's DIRECTORY branch — the branch"
  echo "    C4 and C5 use in production, where the C4 release-scope arms now run too"
  exit 0
fi

# ─── Population sweep ────────────────────────────────────────────────────────
CUTOVER="${SINCE:-$(parse_cutover)}"
validate_cutover "$CUTOVER"

# ─── --assert-bound ──────────────────────────────────────────────────────────
#
# THE BINDING IS THE THING THAT CAN BE SKIPPED, so it is the thing that gets a
# check. § 4.1 defers the instant to Stage 12 on a correct argument — the boundary
# is the merge instant, which does not exist while the change is being built — but
# a deferral with no executor is just a sentence. While the key reads `(unset)`
# every finding is LEGACY, the tool exits 0, and the § 7 Close-time "a post-cutover
# violation BLOCKS close" clause cannot fire: there are no post-cutover rows by
# construction. That reads exactly like a healthy validator from outside, which is
# the failure family this whole release exists to close.
#
# This mode is the inverse assertion, and it is deliberately the ONLY place where
# `(unset)` is a non-zero: the value contract in § 4.1 stays intact for every other
# invocation. Stage 12 binds the instant and then runs this; if the binding is
# skipped the step fails loudly instead of leaving a green-forever check behind.
if [[ "$ASSERT_BOUND" == "true" ]]; then
  if [[ "$CUTOVER" == "(unset)" ]]; then
    echo "integrity_cutover is UNBOUND ((unset)) — this validator grades nothing and exits 0 on every input." >&2
    echo "Bind the merge instant in ${SCHEMA_FILE#"$REPO_ROOT"/} § 4.1 (\`integrity_cutover: YYYY-MM-DDTHH:MM:SSZ\`), then re-run." >&2
    exit 1
  fi
  echo "integrity_cutover BOUND at ${CUTOVER} — rows at or after it are graded; a violation fails this tool."
  exit 0
fi

if [[ "$SURFACE" != "ledger" && ! -r "$LOG_FILE" ]]; then
  die "event log unreadable at the resolved instance path (surface=$SURFACE)" 2
fi

run_engine "$LOG_FILE" "$WRITE_LOG" "$HUB_STATE_PATH" "$CUTOVER" "$SURFACE" "$FORMAT" "$SCHEMA_FILE"
