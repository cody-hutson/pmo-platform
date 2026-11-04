#!/usr/bin/env python3
"""Reconcile DECLARED-required gate contexts against LIVE branch protection.

WHAT THIS IS, AND WHY IT EXISTS
-------------------------------
`core/standards/gate-efficacy-standard.md` § Requirement (b) draws a line that is easy
to read past. A declaration's posture is "derived from that surface" — it states what
the enforcement surface ACTUALLY DELIVERS — while the declaration itself "does not
itself edit branch-protection", so "reconciling the declared postures against the
actual branch-protection configuration remains a **coverage-audit item under
Requirement (c)**, not a file edit any single gate performs."

So the standard NAMES an audit and assigns it to Requirement (c). Until this tool, that
audit had no runner. Every occurrence of the branch-protection API in an executable
surface across the tracked tree was a COMMENT describing the operator step; nothing
asserted it, and nothing reported it.

This tool closes that by MEASURING the declared set against the live set on every pull
request and failing its own verdict when they diverge. It never blocks a merge: see the
next section for why both halves of that sentence hold at once.

WHY IT IS NEVER A REQUIRED CHECK, AND WHY IT FAILS ANYWAY
--------------------------------------------------------
Part of its verdict input is out-of-tree GitHub state. A gate whose Verdict-Input
Closure over repository paths cannot contain its whole verdict input cannot be
`required`: a transient `gh`, auth or rate-limit failure would become merge-blocking,
"declaring an enforcement the surface cannot deliver, which Requirement (b) forbids".
That is verbatim the reason `deploy.sh` Check 51 (`label-parity`) was declined and
ratified permanently advisory, and this tool is in the same class. It must never join
`deploy.sh --check-required-subset` (`rs_checks`), whose verdict enum additionally
fail-closes on an unexpected verdict REGARDLESS of its warn/enforce sentinel.

Posture and mode answer different questions, and the standard already keeps them
apart. POSTURE says whether a red verdict BLOCKS a merge; MODE says whether a finding
turns the check RED. This tool's posture is advisory, permanently: its check is never a
required context. Its mode is enforcing: a MEASURED divergence exits 1, and the
workflow turns its verdict check red. It fails, and it stops nobody merging.

THE THREE-VALUED LIVE STATUS IS THE WHOLE POINT
-----------------------------------------------
A reconciliation that printed agreement when it could not read branch protection would
launder a NON-MEASUREMENT into a clean bill of health — the precise defect class this
tool exists to close. `main`'s live required contexts come from TWO reads, and each is
reported as one of the closed status set in
`core/disciplines/review-discipline-principles.md` § 8.1 PV-7a:

    fetched   — the read returned a list of contexts; it is a MEASUREMENT
    degraded  — a read was supplied and did not return a usable list: a refused or
                failed request, an API error body, a body that is not the expected
                shape, a --live file that is empty or holds a line that cannot be a
                context name, or a rule this read cannot name the checks of; nothing
                is measured
    not-run   — no input was supplied for that read at all

The live status is `fetched` only when BOTH reads are `fetched`; otherwise it is the
first non-fetched status, in branch-protection-then-rules order. Under `degraded` and
`not-run` the verdict is NOT-EVALUATED — this is not a clean result — and the class
table and class sections are ABSENT rather than empty: a consumer must branch on the
status before reading any count, and a count is never zeroed to stand in for a
measurement that did not happen.

The CI job reads the PUBLIC branch object, `GET /repos/{owner}/{repo}/branches/main`,
which returns `protection.required_status_checks.contexts` to any caller that can read
the repository. The admin-scoped `.../branches/main/protection` endpoint returns the
same list and refuses the workflow token, which is why this job once reported a
non-measurement on every CI run. The workflow hands the response body over whole
(`--live-branch-json`): the decision "is this body a measurement" is verdict-bearing,
so it lives here, under the self-test, and not in workflow shell. A body that is not a
branch object carrying the context list is `degraded`, never `fetched` with an empty
set — an empty set reads as "every declared context is unregistered", which would be
the failing verdict manufactured from a failed read. The same holds for `--live`: an
empty file cannot tell an empty set from a failed read, so it is `degraded`; pass the
branch object when the measured set may legitimately be empty.

The second read is of the rules that apply to `main`, `GET
/repos/{owner}/{repo}/rules/branches/main?per_page=100`, handed over whole
(`--live-rules-json`) — never the repository's ruleset list, which also carries
rulesets that target tags. The tool dispatches on each rule's `type` by ALLOW-LIST: a
type known to add no merge gate is ignored, `required_status_checks` is read for its
contexts, and every other type — including any type the host adds later — is
`degraded`, because it holds a merge on something no status context this read can name
carries. A list at the page limit cannot exclude truncation, so it is `degraded` too.

WHAT DIVERGE MEANS
------------------
The definition is stated once, in core/standards/gate-efficacy-standard.md § Requirement
(b); this tool computes it. A context is DECLARED REQUIRED when a declaration on the
registration track names it. The track is defined once, in § Declared-required contexts —
registration disposition of the same standard; `declared_required()` below computes it,
with the conformance ratchet's own grammar for a required posture.

A declared-required context DISCLOSES A HOLD when every declaration naming it carries the
qualifier `warn-mode-initial` exactly. Otherwise it CLAIMS DELIVERY — and that includes
`required(enforce; ratified …)` and any qualifier the standard has not named, so a newly
coined qualifier buys no exemption. A context that discloses a hold is HELD only when
that section's table carries a HOLD or CORRECT-THEN-HOLD row for it, so the qualifier
alone buys no exemption either.

On a run whose two live reads both returned, the declared and live sets DIVERGE when any
of four classes has a member:

    unregistered         — a context that claims delivery and is absent from the live set
    held and registered  — a context that discloses a hold and is present in the live
                           set, with or without a row: the registered job that still
                           swallows its findings, a required check that cannot turn red
    unrecorded hold      — a context that discloses a hold, is absent from the live set,
                           and has no HOLD or CORRECT-THEN-HOLD row
    undeclared           — a live context that no declaration on the track names

A context that discloses a hold, is ABSENT from the live set and has its row is HELD:
listed on every measured run, never a divergence, because the qualifier states what is
not being delivered and the row states what ends it. So `required(warn-mode-initial)`
with its row falls on the agreeing side while its context is unregistered and on the
diverging side once it is registered.

The table is a VERDICT INPUT. It is read from the standard (`--standard`) through the
shared table splitter, and any format drift — the heading or the header row changed, a
row that is not four cells, a disposition outside the closed set, a context on two rows,
or no rows at all — is exit 2, never an empty set of rows.

SINGLE PARSER
-------------
The declared set is extracted by importing the conformance ratchet's header parser from
`core/deploy/tests/test_gate_efficacy_declarations.py` — `parse_headers`, its quoted-
context pattern, its required-posture grammar, its enforcement keys, its surface reader
and its table-row splitter — rather than re-implementing the header grammar. Two parsers over one header
format is a second thing to keep in agreement, and the agreement is exactly what rots:
an earlier version of this file took any posture that merely BEGAN with the letters,
where the ratchet takes `required` or `required(`.

That module imports PyYAML at module scope, so the self-test runs in two tiers. Tier 1
is stdlib-only and runs everywhere. Tier 2 drives `declared_required()` through the
real parser over a fixture workflow tree; where the parser cannot be loaded its arms are
reported NOT-EVALUATED — this is not a clean result for those arms — and the exit is
tier 1's, unless `--require-parser` is passed, which makes an unloadable parser exit 2.
The reconciliation job passes it, so tier 2 has a mandatory runner.

EXIT CONTRACT
-------------
    0  MEASURED and RECONCILED. Both live reads returned and no divergence class has a
       member. Held contexts may exist; they are listed.
    1  MEASURED and DIVERGED. Both live reads returned and at least one divergence class
       has a member. This is the failing verdict.
    2  THE INSTRUMENT CANNOT ASSERT. A --self-test arm did not behave as declared, or the
       declared set could not be read at all (no workflows resolved, the shared parser
       unreachable, or zero declared contexts discovered), or the disposition table could
       not be read, or the verdict could not be written to --github-output. A broken
       probe, never a gate verdict.
    3  NOT-EVALUATED. Either live read did not return (`degraded`) or was not supplied
       (`not-run`). This is not a clean result: it is never agreement and never the
       failing verdict, and it carries its own exit code so the state survives the
       process boundary.
"""

from __future__ import annotations

import argparse
import importlib.util
import json
import sys
import tempfile
from pathlib import Path

PARSER_MODULE_REL = "core/deploy/tests/test_gate_efficacy_declarations.py"
STANDARD_REL = "core/standards/gate-efficacy-standard.md"

# The names this tool reads from the shared parser. A module missing any of them is
# reported unreachable rather than half-used.
PARSER_NAMES = (
    "parse_headers",
    "QUOTED_RE",
    "POSTURE_REQUIRED_RE",
    "BLOCKING_SURFACE",
    "ENFORCEMENT_KEYS",
    "enforcement_surface",
    "_table_cells",
)

# The disposition table — a verdict input. Its heading, its four column names and its
# closed disposition set are read exactly; anything else fails the instrument (exit 2).
TABLE_HEADING = "## Declared-required contexts — registration disposition"
TABLE_COLUMNS = ("Context", "Declared at", "Disposition", "Basis / ending condition")
HOLD_FAMILY = ("HOLD", "CORRECT-THEN-HOLD")
DISPOSITIONS = ("REGISTER",) + HOLD_FAMILY

# The rules read. A full page cannot exclude truncation, so a list this long is degraded.
RULES_PAGE_LIMIT = 100
RULE_TYPE_STATUS_CHECKS = "required_status_checks"
# ALLOW-LIST of rule types known to add no merge gate: each restricts which refs may be
# created, updated or deleted, or what a pushed commit, ref name or file may look like —
# none holds a merge on a result. `required_status_checks` is read; EVERY other type,
# including one the host adds later, is degraded, because it holds a merge on something
# (a review, a deployment, a scan, a workflow, a queue) no status context here names.
RULE_TYPES_NO_MERGE_GATE = (
    "creation",
    "update",
    "deletion",
    "non_fast_forward",
    "required_linear_history",
    "required_signatures",
    "commit_message_pattern",
    "commit_author_email_pattern",
    "committer_email_pattern",
    "branch_name_pattern",
    "tag_name_pattern",
    "file_path_restriction",
    "max_file_path_length",
    "file_extension_restriction",
    "max_file_size",
)

STATUS_FETCHED = "fetched"
STATUS_DEGRADED = "degraded"
STATUS_NOT_RUN = "not-run"

VERDICT_RECONCILED = "RECONCILED"
VERDICT_DIVERGED = "DIVERGED"
VERDICT_NOT_EVALUATED = "NOT-EVALUATED"
EXIT_CODE = {VERDICT_RECONCILED: 0, VERDICT_DIVERGED: 1, VERDICT_NOT_EVALUATED: 3}
EXIT_CANNOT_ASSERT = 2
NOT_CLEAN_CLAUSE = "this is not a clean result"

HELD_QUALIFIER = "warn-mode-initial"

CLASS_RECONCILED = "reconciled"
CLASS_HELD = "held"
CLASS_UNREGISTERED = "unregistered"
CLASS_HELD_REGISTERED = "held and registered"
CLASS_UNRECORDED = "unrecorded hold"
CLASS_UNDECLARED = "undeclared"
CLASS_ORDER = (CLASS_RECONCILED, CLASS_HELD, CLASS_UNREGISTERED,
               CLASS_HELD_REGISTERED, CLASS_UNRECORDED, CLASS_UNDECLARED)
DIVERGENCE_CLASSES = (CLASS_UNREGISTERED, CLASS_HELD_REGISTERED, CLASS_UNRECORDED,
                      CLASS_UNDECLARED)

# Detail-section headings, as CONSTANTS the self-test asserts on rather than as prose it
# substring-matches. An earlier implementation let the harness match the summary table's
# ROW LABELS, which are printed on every measured run — so a specificity arm fired on a
# fully reconciled set and the arm was right: a substring oracle could not tell "this
# class has members" from "this class is named in the legend". Each heading appears ONLY
# when its class has members, which is the property the arms actually need.
SEC_UNREGISTERED = "#### Unregistered — declared `required`, absent from live"
SEC_HELD_REGISTERED = ("#### Held and registered — declared required(warn-mode-initial), "
                       "present in live")
SEC_UNRECORDED = ("#### Unrecorded hold — declared required(warn-mode-initial), not "
                  "registered, no HOLD or CORRECT-THEN-HOLD row")
SEC_UNDECLARED = ("#### Undeclared — live and blocking, named by no declaration on the "
                  "registration track")
SEC_HELD = ("#### Held — declared required(warn-mode-initial), not registered, its "
            "HOLD-family row recorded")
SEC_RECONCILED = "#### Reconciled — declared set and live set agree"
SEC_NOT_MEASURED = "#### NOT-EVALUATED — the live read did not return"
TABLE_HEADER = "| Class | Count |"


def repo_root_from(start: Path) -> Path | None:
    for candidate in [start] + list(start.parents):
        if (candidate / ".github" / "workflows").is_dir():
            return candidate
    return None


def load_shared_parser(root: Path | None):
    """Import the ratchet's header parser by path. Returns the module, or None.

    By PATH rather than by package import because `core/deploy/tests/` is not a package
    and this tool must be runnable from any cwd. `importlib.util` is the established
    idiom for this in the release tool set.
    """
    if root is None:
        return None
    target = root / PARSER_MODULE_REL
    if not target.is_file():
        return None
    spec = importlib.util.spec_from_file_location("_gate_efficacy_parser", target)
    if spec is None or spec.loader is None:
        return None
    module = importlib.util.module_from_spec(spec)
    try:
        spec.loader.exec_module(module)
    except SystemExit:
        # The ratchet exits 2 at import time when PyYAML is absent. Its yaml
        # dependency belongs to the TRIGGER read, which this tool does not use — but
        # honouring the module contract beats reaching around it, so this is reported
        # as an unreachable parser rather than worked around with a private copy.
        return None
    except Exception:
        return None
    if any(not hasattr(module, name) for name in PARSER_NAMES):
        return None
    return module


def on_track(fields: dict[str, str], parser) -> bool:
    """True iff a declaration is on the registration track, as the standard defines it.

    The posture test is the ratchet's own grammar (`required`, or `required(` followed
    by a qualifier), and the surface test is the ratchet's own surface reader — so this
    tool and the ratchet cannot disagree about which declarations claim a blocking
    posture. Both failure shapes it replaces are recorded here because each happened: a
    space-intolerant match silently drops the compound form `required(enforce; ratified
    …)`, which is exactly how an earlier measurement of this population came back one
    short; and a leading-letters match sweeps in any posture word that merely begins
    with them.
    """
    if not parser.POSTURE_REQUIRED_RE.match(fields.get("posture", "")):
        return False
    surface = parser.enforcement_surface(fields)
    return surface is not None and surface.startswith(parser.BLOCKING_SURFACE)


def _workflow_texts(workflows: Path):
    for path in sorted(workflows.iterdir()):
        if path.suffix in (".yml", ".yaml"):
            yield path.name, path.read_text(encoding="utf-8")


def declared_required(workflows: Path, parser) -> dict[str, dict[str, list[str]]]:
    """context -> {posture: [file:line, ...]} over registration-track declarations."""
    out: dict[str, dict[str, list[str]]] = {}
    for name, text in _workflow_texts(workflows):
        for lineno, fields in parser.parse_headers(text):
            if not on_track(fields, parser):
                continue
            posture = fields.get("posture", "")
            for key in parser.ENFORCEMENT_KEYS:
                for ctx in parser.QUOTED_RE.findall(fields.get(key, "")):
                    out.setdefault(ctx, {}).setdefault(posture, []).append(
                        f"{name}:{lineno}")
    return out


def named_anywhere(workflows: Path, parser) -> dict[str, list[str]]:
    """context -> ["file:line (posture=…)", ...] over EVERY declaration, on the track or
    off it. Read only to tell an undeclared context's two repairs apart."""
    out: dict[str, list[str]] = {}
    for name, text in _workflow_texts(workflows):
        for lineno, fields in parser.parse_headers(text):
            posture = fields.get("posture", "") or "(none)"
            for key in parser.ENFORCEMENT_KEYS:
                for ctx in parser.QUOTED_RE.findall(fields.get(key, "")):
                    out.setdefault(ctx, []).append(f"{name}:{lineno} (posture={posture})")
    return out


def is_context_name(line: str) -> bool:
    """A line that opens a JSON value cannot be a context name: it is a response body
    that was never extracted — the shape a failed read redirected into the file leaves.
    A line carrying a control character is not a context name either."""
    return not line.startswith(("{", "[", '"')) and line.isprintable()


def read_live(live_path: str | None) -> tuple[str, list[str]]:
    """(status, contexts) from a file of context names, one per line."""
    if not live_path:
        return STATUS_NOT_RUN, []
    try:
        raw = Path(live_path).read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError):
        return STATUS_DEGRADED, []
    names = [line.strip() for line in raw.splitlines() if line.strip()]
    if not names:
        # An empty file cannot tell an empty set from a read that did not return.
        return STATUS_DEGRADED, []
    if not all(is_context_name(name) for name in names):
        return STATUS_DEGRADED, []
    return STATUS_FETCHED, names


def read_live_branch_json(path: str | None) -> tuple[str, list[str]]:
    """(status, contexts). `fetched` ONLY for a branch object carrying the context list."""
    if not path:
        return STATUS_NOT_RUN, []
    try:
        body = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, ValueError):
        return STATUS_DEGRADED, []
    if not isinstance(body, dict) or not isinstance(body.get("name"), str) or not body["name"]:
        return STATUS_DEGRADED, []
    protection = body.get("protection")
    rsc = protection.get("required_status_checks") if isinstance(protection, dict) else None
    contexts = rsc.get("contexts") if isinstance(rsc, dict) else None
    if not isinstance(contexts, list) or not all(isinstance(c, str) for c in contexts):
        return STATUS_DEGRADED, []          # never `fetched` with an empty set
    return STATUS_FETCHED, contexts


def read_live_rules_json(path: str | None) -> tuple[str, list[str]]:
    """(status, contexts) from the body of GET .../rules/branches/main.

    `fetched` ONLY for a list, shorter than the page limit, whose every rule names a
    type: a type on the no-merge-gate allow-list is ignored, a `required_status_checks`
    rule contributes its contexts, and any other type is `degraded` — it holds a merge on
    something this read cannot name, so the live set would be under-read."""
    if not path:
        return STATUS_NOT_RUN, []
    try:
        body = json.loads(Path(path).read_text(encoding="utf-8"))
    except (OSError, UnicodeDecodeError, ValueError):
        return STATUS_DEGRADED, []
    if not isinstance(body, list) or len(body) >= RULES_PAGE_LIMIT:
        return STATUS_DEGRADED, []
    contexts: list[str] = []
    for rule in body:
        kind = rule.get("type") if isinstance(rule, dict) else None
        if not isinstance(kind, str) or not kind:
            return STATUS_DEGRADED, []
        if kind in RULE_TYPES_NO_MERGE_GATE:
            continue
        if kind != RULE_TYPE_STATUS_CHECKS:
            return STATUS_DEGRADED, []
        params = rule.get("parameters")
        checks = params.get(RULE_TYPE_STATUS_CHECKS) if isinstance(params, dict) else None
        if not isinstance(checks, list) or not all(
                isinstance(c, dict) and isinstance(c.get("context"), str) and c["context"]
                for c in checks):
            return STATUS_DEGRADED, []
        contexts.extend(c["context"] for c in checks)
    return STATUS_FETCHED, list(dict.fromkeys(contexts))


def combined_status(classic: str, rules: str) -> str:
    """`fetched` only when both reads are; otherwise the first that is not, in
    branch-protection-then-rules order."""
    for status in (classic, rules):
        if status != STATUS_FETCHED:
            return status
    return STATUS_FETCHED


class TableError(Exception):
    """The disposition table cannot be read. Never an empty set of rows."""


def read_disposition_rows(text: str, parser) -> dict[str, str]:
    """{context: disposition} from § Declared-required contexts, read through the shared
    table splitter. Raises TableError on any format drift."""
    lines = text.splitlines()
    if TABLE_HEADING not in lines:
        raise TableError(f"the heading `{TABLE_HEADING}` is absent")
    start = lines.index(TABLE_HEADING) + 1
    end = next((i for i in range(start, len(lines)) if lines[i].startswith("## ")),
               len(lines))
    table: list[str] = []
    for line in lines[start:end]:
        if line.lstrip().startswith("|"):
            table.append(line)
        elif table:
            break
    if len(table) < 2 or tuple(parser._table_cells(table[0])) != TABLE_COLUMNS:
        raise TableError(f"no header row reading {' | '.join(TABLE_COLUMNS)}")
    if not all(c and set(c) <= set(":-") for c in parser._table_cells(table[1])):
        raise TableError("the header row is not followed by a separator row")
    rows: dict[str, str] = {}
    for line in table[2:]:
        cells = parser._table_cells(line)
        if len(cells) != len(TABLE_COLUMNS):
            raise TableError(f"a row carries {len(cells)} cells, not "
                             f"{len(TABLE_COLUMNS)}: {line[:80]}")
        context, disposition = cells[0], cells[2].replace("**", "").strip()
        if disposition not in DISPOSITIONS:
            raise TableError(f"`{context}` carries the disposition `{disposition}`, "
                             f"outside {', '.join(DISPOSITIONS)}")
        if context in rows:
            raise TableError(f"`{context}` appears on two rows")
        rows[context] = disposition
    if not rows:
        raise TableError("the table carries zero rows")
    return rows


def load_disposition_rows(standard: Path | None, parser) -> dict[str, str]:
    """read_disposition_rows over a file; an unreadable file is a TableError too."""
    if standard is None:
        raise TableError("no standard resolved")
    try:
        text = standard.read_text(encoding="utf-8")
    except (OSError, UnicodeDecodeError) as exc:
        raise TableError(f"the file cannot be read ({exc.__class__.__name__})") from None
    return read_disposition_rows(text, parser)


def discloses_hold(postures) -> bool:
    return bool(postures) and all(p == f"required({HELD_QUALIFIER})" for p in postures)


def classify(declared: dict, rows: dict[str, str], status: str,
             live: list[str]) -> tuple[str, dict[str, list[str]]]:
    """(verdict, classes). Classes are computed ONLY from reads that returned."""
    if status != STATUS_FETCHED:
        return VERDICT_NOT_EVALUATED, {}
    live_set = set(live)
    disclosed = {c for c in declared if discloses_hold(declared[c])}
    recorded = {c for c in disclosed if rows.get(c) in HOLD_FAMILY}
    classes = {
        CLASS_RECONCILED: sorted(c for c in declared
                                 if c in live_set and c not in disclosed),
        CLASS_HELD: sorted(c for c in recorded if c not in live_set),
        CLASS_UNREGISTERED: sorted(c for c in declared
                                   if c not in live_set and c not in disclosed),
        CLASS_HELD_REGISTERED: sorted(c for c in disclosed if c in live_set),
        CLASS_UNRECORDED: sorted(c for c in disclosed
                                 if c not in live_set and c not in recorded),
        CLASS_UNDECLARED: sorted(c for c in live_set if c not in declared),
    }
    diverged = any(classes[k] for k in DIVERGENCE_CLASSES)
    return (VERDICT_DIVERGED if diverged else VERDICT_RECONCILED), classes


def _sites(declared: dict, ctx: str) -> str:
    return ", ".join(f"{site} (posture={posture})"
                     for posture, sites in sorted(declared[ctx].items())
                     for site in sites)


READ_LABELS = ("branch protection (`branches/main`)",
               "the rules for `main` (`rules/branches/main`)")


def _row_note(rows: dict[str, str], ctx: str) -> str:
    return f"its row reads {rows[ctx]}" if ctx in rows else "no row"


def render(declared: dict, rows: dict[str, str], reads, live: list[str], verdict: str,
           classes: dict[str, list[str]], named: dict[str, list[str]]) -> list[str]:
    """`reads` is ((classic status, classic contexts), (rules status, rules contexts));
    `live` is their union, and is read only when both are fetched."""
    status = combined_status(reads[0][0], reads[1][0])
    out: list[str] = []
    out.append("### Gate posture reconciliation — declared vs live branch protection")
    out.append("")
    if verdict == VERDICT_NOT_EVALUATED:
        out.append(f"**Verdict:** {VERDICT_NOT_EVALUATED} — {NOT_CLEAN_CLAUSE}")
    else:
        out.append(f"**Verdict:** {verdict}")
    out.append("")
    out.append(f"- declared-required contexts (on the registration track): "
               f"**{len(declared)}**")
    out.append(f"- live-read status: **{status}**"
               + (f" ({len(live)} context(s))" if status == STATUS_FETCHED else ""))
    for label, (read_status, contexts) in zip(READ_LABELS, reads):
        out.append(f"  - {label}: **{read_status}**"
                   + (f" ({len(contexts)} context(s))"
                      if read_status == STATUS_FETCHED else ""))
    out.append("")

    if status != STATUS_FETCHED:
        missing = [label for label, (read_status, _) in zip(READ_LABELS, reads)
                   if read_status != STATUS_FETCHED]
        out.append(SEC_NOT_MEASURED)
        out.append("")
        out.append("**No comparison is published, because none was measured.** A live "
                   "read did not return a usable list — " + "; ".join(missing) + " — "
                   "so this run reports its own non-measurement — never agreement and "
                   "never the failing verdict. The declared set is still listed, and the "
                   "comparison resumes on the next run whose two reads both return.")
        out.append("")
        out.append("Declared contexts (unreconciled this run):")
        out.append("")
        for ctx in sorted(declared):
            out.append(f"- `{ctx}` — {_sites(declared, ctx)}")
        return out

    out.append(TABLE_HEADER)
    out.append("|---|---|")
    for cls in CLASS_ORDER:
        out.append(f"| {cls} | {len(classes[cls])} |")
    out.append("")

    if classes[CLASS_UNREGISTERED]:
        out.append(SEC_UNREGISTERED)
        out.append("")
        out.append("Each claims an enforcement that branch protection is not delivering. "
                   "The repair is one of two: the operator registers the context (a "
                   "repository-settings action no pull request can perform), or the "
                   "header is corrected to the posture the gate actually delivers. "
                   "Before registering, confirm the job can reach a RED verdict on its "
                   "own invariant — a job that swallows findings to `exit 0` would become "
                   "a required check incapable of failing.")
        out.append("")
        for ctx in classes[CLASS_UNREGISTERED]:
            out.append(f"- `{ctx}` — {_sites(declared, ctx)}")
        out.append("")

    if classes[CLASS_HELD_REGISTERED]:
        out.append(SEC_HELD_REGISTERED)
        out.append("")
        out.append("Each is registered while its declaration says it is held in "
                   "warn-mode: a required check whose job still swallows its findings, so "
                   "a merge-predicate conjunct that can never be false. The repair is the "
                   "flip its graduation clause names, then the header reads `required`; or "
                   "the context leaves the required set until then.")
        out.append("")
        for ctx in classes[CLASS_HELD_REGISTERED]:
            out.append(f"- `{ctx}` — {_sites(declared, ctx)}")
        out.append("")

    if classes[CLASS_UNRECORDED]:
        out.append(SEC_UNRECORDED)
        out.append("")
        out.append("Each discloses a hold through its qualifier, but "
                   "`core/standards/gate-efficacy-standard.md` § Declared-required "
                   "contexts carries no HOLD or CORRECT-THEN-HOLD row naming what ends the "
                   "hold and who owns it, so the qualifier is buying an exemption nothing "
                   "records. The repair is one of two: add the row naming what ends the "
                   "hold and its owner, or flip the gate and drop the qualifier.")
        out.append("")
        for ctx in classes[CLASS_UNRECORDED]:
            out.append(f"- `{ctx}` — {_sites(declared, ctx)}; {_row_note(rows, ctx)}")
        out.append("")

    if classes[CLASS_UNDECLARED]:
        out.append(SEC_UNDECLARED)
        out.append("")
        out.append("Each blocks merges with no declaration on the registration track. "
                   "This is the more serious direction: enforcement the tree does not "
                   "record.")
        out.append("")
        for ctx in classes[CLASS_UNDECLARED]:
            if named.get(ctx):
                out.append(f"- `{ctx}` — named off the track at {', '.join(named[ctx])}: "
                           f"its registration has landed, so the repair is to flip that "
                           f"header to `required` on `branch-protection`")
            else:
                out.append(f"- `{ctx}` — named by no header: the repair is to declare it in "
                           f"its workflow's `gate-efficacy:` header, or to have it leave "
                           f"the required set")
        out.append("")

    if classes[CLASS_HELD]:
        out.append(SEC_HELD)
        out.append("")
        out.append("Listed on every measured run and never a divergence: each declares "
                   "`required(warn-mode-initial)`, which discloses its own non-delivery, "
                   "is not registered, and has the HOLD or CORRECT-THEN-HOLD row that "
                   "names what ends the hold.")
        out.append("")
        for ctx in classes[CLASS_HELD]:
            out.append(f"- `{ctx}` — {_sites(declared, ctx)}; {_row_note(rows, ctx)}")
        out.append("")

    if verdict == VERDICT_RECONCILED:
        out.append(SEC_RECONCILED)
        out.append("")
        out.append("Every context that claims delivery is live, no held context is live, "
                   "every disclosed hold has its row, and every live context is declared.")
        out.append("")

    out.append("_Never a required context: part of this verdict's input is out-of-tree "
               "repository settings, so it must not block a merge — see "
               "`core/standards/gate-efficacy-standard.md` Requirement (b). A measured "
               "divergence turns this check red. A read that did not return is "
               "NOT-EVALUATED and turns nothing red._")
    return out


def emit(verdict: str, status: str, rules_status: str, github_output: str | None) -> int:
    """Write the verdict for the workflow (if asked) and return the exit code for it.

    The verdict token and the exit code are derived from ONE verdict value here, so the
    two transports cannot disagree; arm T1 asserts it. `live_status` is the combined
    status of the two reads and `rules_status` the rules read's own. A write failure is
    exit 2: a verdict the caller cannot read is not a verdict.
    """
    if github_output:
        try:
            with open(github_output, "a", encoding="utf-8") as fh:
                fh.write(f"verdict={verdict}\n")
                fh.write(f"live_status={status}\n")
                fh.write(f"rules_status={rules_status}\n")
        except OSError as exc:
            print(f"FAIL ({EXIT_CANNOT_ASSERT}): the verdict could not be written to "
                  f"--github-output ({exc}).", file=sys.stderr)
            return EXIT_CANNOT_ASSERT
    return EXIT_CODE[verdict]


def declared_set_problem(declared: dict) -> str | None:
    """A reason the declared set cannot be asserted over, or None. Zero declared
    contexts is a BROKEN PROBE, not an empty population: this tree carries registration-
    track declarations by construction, so a zero means the extraction missed them."""
    if not declared:
        return ("zero declared-required contexts discovered. A zero here is a BROKEN "
                "PROBE, not an empty population — this tree carries registration-track "
                "declarations by construction.")
    return None


# ── Self-test ──────────────────────────────────────────────────────────────────────

TIER1_ARMS = ("U1", "U2", "H1", "H2", "H3", "H4", "H5", "H6", "N1", "N2", "Q1",
              "M1", "M2", "M3", "J1", "J2", "J3", "J4", "J5", "L1", "L2",
              "RS1", "RS2", "RS3", "RS4", "T1", "D1")
TIER2_ARMS = ("P1", "P2", "P3", "P4", "P5", "P6", "P7",
              "TB1", "TB2", "TB3", "TB4", "TB5", "TB6")

FIXTURE_HEADERS = {
    # P1 — a bare `required` header naming two contexts.
    "p1.yml": '# gate-efficacy: posture=required  enforcement=branch-protection:"P one","P two"  always-reports=yes\n',
    # P2 — the legacy enforcement key.
    "p2.yml": '# gate-efficacy: posture=required  enforcement-surface=branch-protection:"P legacy key"  always-reports=yes\n',
    # P3 — the held qualifier.
    "p3.yml": '# gate-efficacy: posture=required(warn-mode-initial)  enforcement=branch-protection:"P held"  always-reports=yes\n',
    # P4 — a qualifier containing spaces, which claims delivery.
    "p4.yml": '# gate-efficacy: posture=required(enforce; ratified 2026-09-04)  enforcement=branch-protection:"P ratified"  always-reports=yes\n',
    # P5 — advisory headers, on a non-blocking surface and on branch-protection.
    "p5.yml": ('# gate-efficacy: posture=advisory  enforcement=ci-enforce:"P advisory"  always-reports=yes\n'
               '# gate-efficacy: posture=advisory  enforcement=branch-protection:"P advisory on bp"  always-reports=yes\n'),
    # P6 — a required posture on surfaces that cannot block.
    "p6.yml": ('# gate-efficacy: posture=required  enforcement=ci-enforce:"P non-blocking"  always-reports=yes\n'
               '# gate-efficacy: posture=required(warn-mode-initial)  enforcement=path-filtered  skip-semantics=absent-is-pass\n'),
    # P7 — a posture that merely begins with the letters.
    "p7.yml": '# gate-efficacy: posture=required-on-release  enforcement=branch-protection:"P lookalike"  always-reports=yes\n',
}

# TB1's well-formed disposition table; TB2 to TB6 are one-edit variants of it. The row
# after the next `## ` heading carries a disposition outside the closed set and must not
# be read, and `Ctx two`'s basis cell carries an escaped pipe that must not split it.
TB_TABLE = (
    "Lead text.\n"
    "\n"
    f"{TABLE_HEADING}\n"
    "\n"
    "A paragraph about the table.\n"
    "\n"
    "| Context | Declared at | Disposition | Basis / ending condition |\n"
    "|---|---|---|---|\n"
    "| `Ctx one` | `a.yml` | **REGISTER** | basis |\n"
    "| `Ctx two` | `b.yml` | **HOLD** | ends when a \\| b is decided |\n"
    "| `Ctx three` | `c.yml` | **CORRECT-THEN-HOLD** | basis |\n"
    "\n"
    "A paragraph after the table.\n"
    "\n"
    "## Next section\n"
    "\n"
    "| Context | Declared at | Disposition | Basis / ending condition |\n"
    "|---|---|---|---|\n"
    "| `Not read` | `d.yml` | **PARK** | outside the section |\n"
)


def _run(declared: dict, status: str, live: list[str], rows: dict | None = None,
         rules_status: str = STATUS_FETCHED, rules_live: tuple = ()):
    """`status`/`live` are the branch-protection read; the rules read defaults to a
    fetched empty list, and the rows to one HOLD row for the fixture context `H`."""
    rows = {"H": "HOLD"} if rows is None else rows
    union = list(dict.fromkeys(list(live) + list(rules_live)))
    verdict, classes = classify(declared, rows, combined_status(status, rules_status), union)
    reads = ((status, list(live)), (rules_status, list(rules_live)))
    body = "\n".join(render(declared, rows, reads, union, verdict, classes, {}))
    return verdict, classes, body


def _tier1(failures: list[str], scratch: Path) -> None:
    def check(arm: str, ok: bool, what: str) -> None:
        if not ok:
            failures.append(f"{arm}: {what}")

    claim = {"required": ["w.yml:3"]}
    held = {"required(warn-mode-initial)": ["x.yml:5"]}
    decl = {"A": claim, "B": claim}

    # U1 / U2 — SENSITIVITY then SPECIFICITY on the same non-empty input: a context that
    # claims delivery and is absent from live is UNREGISTERED and the run DIVERGES; the
    # same declared set with that context live reports nothing and RECONCILES.
    verdict, classes, body = _run(decl, STATUS_FETCHED, ["A"])
    check("U1", verdict == VERDICT_DIVERGED and classes[CLASS_UNREGISTERED] == ["B"]
          and SEC_UNREGISTERED in body and "`B`" in body
          and EXIT_CODE[verdict] == 1,
          "a delivery-claiming context absent from live was not reported unregistered "
          "with a DIVERGED verdict and exit 1")
    verdict, classes, body = _run(decl, STATUS_FETCHED, ["A", "B"])
    check("U2", verdict == VERDICT_RECONCILED and not classes[CLASS_UNREGISTERED]
          and SEC_UNREGISTERED not in body and SEC_RECONCILED in body,
          "the same declared set with every context live did not reconcile — the "
          "unregistered class over-matches")

    # H1 / H2 — a HELD context: registered, it is a divergence; unregistered, it is
    # listed as held and is NOT a divergence.
    decl_h = {"A": claim, "H": held}
    verdict, classes, body = _run(decl_h, STATUS_FETCHED, ["A", "H"])
    check("H1", verdict == VERDICT_DIVERGED and classes[CLASS_HELD_REGISTERED] == ["H"]
          and SEC_HELD_REGISTERED in body,
          "a held context present in live was not reported as held and registered")
    verdict, classes, body = _run(decl_h, STATUS_FETCHED, ["A"])
    check("H2", verdict == VERDICT_RECONCILED and classes[CLASS_HELD] == ["H"]
          and not classes[CLASS_UNREGISTERED] and SEC_HELD in body
          and SEC_HELD_REGISTERED not in body and SEC_UNREGISTERED not in body,
          "a held context absent from live was reported as a divergence, or was not "
          "listed as held")

    # H3 / H4 — SENSITIVITY then SPECIFICITY for the fourth class on one input: a context
    # that discloses a hold, is absent from live and has NO row is an UNRECORDED HOLD and
    # the run DIVERGES; the same input with its HOLD row is held and RECONCILES.
    decl_u = {"A": claim, "U": held}
    verdict, classes, body = _run(decl_u, STATUS_FETCHED, ["A"], rows={})
    check("H3", verdict == VERDICT_DIVERGED and classes[CLASS_UNRECORDED] == ["U"]
          and not classes[CLASS_HELD] and SEC_UNRECORDED in body and "`U`" in body
          and EXIT_CODE[verdict] == 1,
          "a qualified context with no disposition row, absent from live, was not "
          "reported as an unrecorded hold with a DIVERGED verdict and exit 1")
    verdict, classes, body = _run(decl_u, STATUS_FETCHED, ["A"], rows={"U": "HOLD"})
    check("H4", verdict == VERDICT_RECONCILED and classes[CLASS_HELD] == ["U"]
          and not classes[CLASS_UNRECORDED] and SEC_UNRECORDED not in body
          and SEC_HELD in body,
          "the same qualified context WITH its HOLD row was still reported as an "
          "unrecorded hold, or was not listed as held")

    # H5 — the row must be a HOLD-family row: CORRECT-THEN-HOLD holds; a REGISTER row on
    # a qualified context is a stale record and diverges as an unrecorded hold.
    verdict, classes, _ = _run(decl_u, STATUS_FETCHED, ["A"], rows={"U": "CORRECT-THEN-HOLD"})
    ok_cth = verdict == VERDICT_RECONCILED and classes[CLASS_HELD] == ["U"]
    verdict, classes, body = _run(decl_u, STATUS_FETCHED, ["A"], rows={"U": "REGISTER"})
    check("H5", ok_cth and verdict == VERDICT_DIVERGED
          and classes[CLASS_UNRECORDED] == ["U"] and "its row reads REGISTER" in body,
          "a CORRECT-THEN-HOLD row did not hold, or a REGISTER row on a qualified "
          "context was read as a hold")

    # H6 — held and registered keys on the qualifier ALONE, and is never double-counted
    # as an unrecorded hold: a live qualified context reads held-and-registered only,
    # with its row and without one.
    for arm_rows in ({}, {"U": "HOLD"}):
        verdict, classes, _ = _run(decl_u, STATUS_FETCHED, ["A", "U"], rows=arm_rows)
        check("H6", verdict == VERDICT_DIVERGED and classes[CLASS_HELD_REGISTERED] == ["U"]
              and not classes[CLASS_UNRECORDED] and not classes[CLASS_HELD],
              f"a live qualified context with rows={arm_rows} was not held and "
              f"registered alone")

    # N1 / N2 — a live context no track declaration names is UNDECLARED; the same live
    # set with that context declared is clean.
    verdict, classes, body = _run({"A": claim}, STATUS_FETCHED, ["A", "Z"])
    check("N1", verdict == VERDICT_DIVERGED and classes[CLASS_UNDECLARED] == ["Z"]
          and SEC_UNDECLARED in body,
          "a live context named by no track declaration was not reported undeclared")
    verdict, classes, body = _run({"A": claim, "Z": claim}, STATUS_FETCHED, ["A", "Z"])
    check("N2", verdict == VERDICT_RECONCILED and not classes[CLASS_UNDECLARED]
          and SEC_UNDECLARED not in body,
          "the same live set with that context declared was still reported undeclared")

    # Q1 — any qualifier other than `warn-mode-initial`, and a context named by BOTH a
    # held and a delivery-claiming declaration, claim delivery: absent from live, each
    # is unregistered, not held. A coined qualifier buys no exemption.
    decl_q = {"A": claim,
              "E": {"required(enforce; ratified 2026-09-04)": ["y.yml:7"]},
              "M": {"required(warn-mode-initial)": ["x.yml:5"], "required": ["w.yml:9"]}}
    verdict, classes, body = _run(decl_q, STATUS_FETCHED, ["A"])
    check("Q1", verdict == VERDICT_DIVERGED and classes[CLASS_UNREGISTERED] == ["E", "M"]
          and not classes[CLASS_HELD],
          "a non-held qualifier, or a mixed-posture context, was treated as held")

    # M1 / M2 — each non-measuring status publishes no table and no class section,
    # carries the not-clean clause, and exits 3. The closed non-measurement vocabulary
    # is asserted as LITERALS, never through the constants that render it: an oracle
    # read from the tool's own constants moves with them, so a respelled or emptied
    # token, clause or heading would pass.
    for arm, status in (("M1", STATUS_DEGRADED), ("M2", STATUS_NOT_RUN)):
        verdict, classes, body = _run(decl_h, status, [])
        sections = (TABLE_HEADER, SEC_UNREGISTERED, SEC_HELD_REGISTERED, SEC_UNRECORDED,
                    SEC_UNDECLARED, SEC_HELD, SEC_RECONCILED)
        check(arm, verdict == "NOT-EVALUATED" and classes == {}
              and not any(s in body for s in sections)
              and "**Verdict:** NOT-EVALUATED — this is not a clean result" in body
              and "#### NOT-EVALUATED — the live read did not return" in body
              and EXIT_CODE[verdict] == 3,
              f"a `{status}` read published a class table or section, omitted the "
              f"not-clean clause, or did not map to exit 3")

    # M3 — a failed read yields NEITHER verdict, on a fixture that would reconcile and on
    # one that would diverge had the read returned.
    for status in (STATUS_DEGRADED, STATUS_NOT_RUN):
        for live in (["A", "B"], ["A"]):
            verdict, _, _ = _run(decl, status, live)
            check("M3", verdict == VERDICT_NOT_EVALUATED,
                  f"a `{status}` read with live={live} produced {verdict} — a "
                  f"non-measurement rendered as a measurement")

    # J1 to J5 — the branch-object reader decides what is a measurement.
    def jfile(name: str, payload) -> str:
        path = scratch / name
        path.write_text(payload if isinstance(payload, str) else json.dumps(payload),
                        encoding="utf-8")
        return str(path)

    ok_body = {"name": "main",
               "protection": {"required_status_checks": {"contexts": ["A", "B"]}}}
    check("J1", read_live_branch_json(jfile("j1.json", ok_body)) == (STATUS_FETCHED, ["A", "B"]),
          "a well-formed branch object was not read as fetched")
    error_body = {"message": "Not Found", "status": "404",
                  "documentation_url": "https://docs.github.com/rest"}
    # The second leg carries the context list where a branch object would, but is not a
    # branch object (no branch `name`); without it the name test could be deleted and
    # every arm here would still pass, because an error body also lacks the list.
    not_branch = {"protection": {"required_status_checks": {"contexts": ["A", "B"]}}}
    check("J2", read_live_branch_json(jfile("j2.json", error_body)) == (STATUS_DEGRADED, [])
          and read_live_branch_json(jfile("j2b.json", not_branch)) == (STATUS_DEGRADED, []),
          "an API error body, or a body that is not a branch object, was not read as "
          "degraded")
    no_list = {"name": "main", "protection": {"enabled": False}}
    check("J3", read_live_branch_json(jfile("j3.json", no_list)) == (STATUS_DEGRADED, []),
          "a branch object without the context list was read as something other than "
          "degraded — possibly fetched with an empty set")
    empty_list = {"name": "main",
                  "protection": {"required_status_checks": {"contexts": []}}}
    status, live = read_live_branch_json(jfile("j4.json", empty_list))
    verdict, classes, _ = _run(decl_h, status, live)
    check("J4", status == STATUS_FETCHED and live == [] and verdict == VERDICT_DIVERGED
          and classes[CLASS_UNREGISTERED] == ["A"] and classes[CLASS_HELD] == ["H"],
          "a present, empty context list was not a measurement in which every "
          "delivery-claiming context is unregistered and every held one held")
    check("J5", read_live_branch_json(str(scratch / "absent.json")) == (STATUS_DEGRADED, [])
          and read_live_branch_json(jfile("j5.json", "")) == (STATUS_DEGRADED, []),
          "a missing or empty branch-object file was not read as degraded")

    # L1 / L2 — the `--live` reader carries the same guarantee: an empty file, and a file
    # holding an unextracted response body, are degraded; the same names written one per
    # line are fetched (the specificity leg on the same content).
    check("L1", read_live(jfile("l1.txt", "")) == (STATUS_DEGRADED, [])
          and read_live(jfile("l1b.txt", "\n  \n")) == (STATUS_DEGRADED, [])
          and read_live(jfile("l1c.txt", "A\nB\n")) == (STATUS_FETCHED, ["A", "B"]),
          "an empty --live file was read as a measurement, or a list of names was not")
    check("L2", read_live(jfile("l2.txt", json.dumps(error_body) + "\n")) == (STATUS_DEGRADED, [])
          and read_live(jfile("l2b.txt", "A\n" + json.dumps(["A", "B"]) + "\n")) == (STATUS_DEGRADED, [])
          and read_live(jfile("l2c.txt", "Shell harness (macOS)\nbandit\n"))
          == (STATUS_FETCHED, ["Shell harness (macOS)", "bandit"]),
          "a --live file holding a response body was read as a measurement, or real "
          "context names were not")

    # RS1 to RS4 — the rules read of `rules/branches/main`. Its sensitivity rests on these
    # fixtures: no rule applies to `main` today, so the live read returns `[]`.
    def rsc_rule(*contexts):
        return {"type": RULE_TYPE_STATUS_CHECKS, "ruleset_id": 1,
                "parameters": {"strict_required_status_checks_policy": False,
                               "required_status_checks": [{"context": c} for c in contexts]}}

    # RS1 — SENSITIVITY: a required context delivered ONLY by a rule is live — reconciled
    # when the rule names it, unregistered when the same rule does not.
    decl_r = {"A": claim, "R": claim}
    r_status, r_live = read_live_rules_json(jfile("rs1.json", [{"type": "deletion"}, rsc_rule("R")]))
    verdict, classes, _ = _run(decl_r, STATUS_FETCHED, ["A"], rules_status=r_status,
                               rules_live=tuple(r_live))
    ok_with = (r_status, r_live) == (STATUS_FETCHED, ["R"]) and verdict == VERDICT_RECONCILED
    r_status, r_live = read_live_rules_json(jfile("rs1b.json", [rsc_rule()]))
    verdict, classes, _ = _run(decl_r, STATUS_FETCHED, ["A"], rules_status=r_status,
                               rules_live=tuple(r_live))
    check("RS1", ok_with and r_status == STATUS_FETCHED and verdict == VERDICT_DIVERGED
          and classes[CLASS_UNREGISTERED] == ["R"],
          "a context delivered by a required_status_checks rule was not read as live, or "
          "a rule naming no context made it live")

    # RS2 — the verdict is CONJUNCTIVE: with branch protection fetched and the rules read
    # degraded or not supplied, a fixture that would reconcile and one that would diverge
    # both read NOT-EVALUATED, exit 3, naming the rules read as the one that did not return.
    for rules in (STATUS_DEGRADED, STATUS_NOT_RUN):
        for live in (["A", "B"], ["A"]):
            verdict, classes, body = _run(decl, STATUS_FETCHED, live, rules_status=rules)
            check("RS2", verdict == VERDICT_NOT_EVALUATED and classes == {}
                  and EXIT_CODE[verdict] == 3 and TABLE_HEADER not in body
                  and "#### NOT-EVALUATED — the live read did not return" in body
                  and f"{READ_LABELS[1]}: **{rules}**" in body
                  and f"{READ_LABELS[0]}: **fetched**" in body,
                  f"branch protection fetched with the rules read `{rules}` and live={live} "
                  f"produced {verdict}, or did not name the rules read")

    # RS3 — the ALLOW-LIST dispatch. Every shape below is degraded: an error body, a
    # non-list, a list at the page limit, a rule with no type, a malformed status-check
    # rule, and every merge-holding type that is not `required_status_checks` — named or
    # unknown. Its specificity legs: a no-merge-gate rule alone, and a list one short of
    # the page limit, are fetched with no context. The page limit is asserted as the
    # LITERALS 100 and 99, never through the constant: an oracle read from the tool's own
    # constant moves with it, so a raised or deleted limit would pass.
    degraded_inputs = {
        "error body": error_body,
        "a non-list": {"type": "deletion"},
        "a list at the page limit": [{"type": "deletion"}] * 100,
        "a rule with no type": [{"parameters": {}}],
        "a status-check rule with no list": [{"type": RULE_TYPE_STATUS_CHECKS, "parameters": {}}],
        "a status-check rule with an empty context": [rsc_rule("")],
        "a workflows rule": [{"type": "workflows", "parameters": {"workflows": []}}],
        "a code_scanning rule": [{"type": "code_scanning", "parameters": {}}],
        "a pull_request rule": [{"type": "pull_request", "parameters": {}}],
        "an unknown type": [{"type": "zzz-type"}],
        "a gating rule beside a status-check rule": [rsc_rule("R"), {"type": "merge_queue"}],
    }
    for label, payload in degraded_inputs.items():
        check("RS3", read_live_rules_json(jfile("rs3.json", payload)) == (STATUS_DEGRADED, []),
              f"{label} was not read as degraded")
    check("RS3", read_live_rules_json(str(scratch / "absent-rules.json")) == (STATUS_DEGRADED, [])
          and read_live_rules_json(jfile("rs3e.json", "")) == (STATUS_DEGRADED, [])
          and read_live_rules_json(None) == (STATUS_NOT_RUN, []),
          "a missing or empty rules file was not degraded, or no file was not not-run")
    check("RS3", read_live_rules_json(jfile("rs3s.json", [{"type": "deletion"}]))
          == (STATUS_FETCHED, [])
          and read_live_rules_json(jfile("rs3t.json", [{"type": "non_fast_forward"}] * 99))
          == (STATUS_FETCHED, [])
          and all(read_live_rules_json(jfile("rs3u.json", [{"type": t}]))
                  == (STATUS_FETCHED, []) for t in RULE_TYPES_NO_MERGE_GATE),
          "a rule type known to add no merge gate, or a list one short of the page limit, "
          "was not read as fetched with no context")

    # RS4 — an empty rules list with branch protection fetched leaves the verdict to the
    # branch-protection set alone, in both directions.
    r_status, r_live = read_live_rules_json(jfile("rs4.json", []))
    reconciled, _, _ = _run(decl, STATUS_FETCHED, ["A", "B"], rules_status=r_status)
    verdict, classes, _ = _run(decl, STATUS_FETCHED, ["A"], rules_status=r_status)
    check("RS4", (r_status, r_live) == (STATUS_FETCHED, []) and reconciled == VERDICT_RECONCILED
          and verdict == VERDICT_DIVERGED and classes[CLASS_UNREGISTERED] == ["B"],
          "an empty rules list did not leave the verdict to the branch-protection set")

    # T1 — the token written for the workflow and the return code agree, for all three
    # verdicts, and the three codes are distinct. The rules read's own status is written
    # beside the combined one, so a run can be read for `rules_status` on its own.
    codes = set()
    for live, status, rules, want in (
            (["A", "B"], STATUS_FETCHED, STATUS_FETCHED, VERDICT_RECONCILED),
            (["A"], STATUS_FETCHED, STATUS_FETCHED, VERDICT_DIVERGED),
            ([], STATUS_DEGRADED, STATUS_FETCHED, VERDICT_NOT_EVALUATED),
            (["A", "B"], STATUS_FETCHED, STATUS_NOT_RUN, VERDICT_NOT_EVALUATED)):
        verdict, _, _ = _run(decl, status, live, rules_status=rules)
        combined = combined_status(status, rules)
        out_path = scratch / f"t1-{want}-{rules}.out"
        rc = emit(verdict, combined, rules, str(out_path))
        written = out_path.read_text(encoding="utf-8").splitlines()
        codes.add(rc)
        check("T1", verdict == want and rc == EXIT_CODE[want]
              and f"verdict={want}" in written and f"live_status={combined}" in written
              and f"rules_status={rules}" in written,
              f"for {want} (rules {rules}), the written tokens or the return code ({rc}) "
              f"disagreed")
    check("T1", codes == {0, 1, 3}, f"the three verdicts did not map to three distinct "
          f"codes 0, 1 and 3 (got {sorted(codes)})")

    # D1 — DEAD CONTROL: the fixtures above are non-empty, and an empty declared set is the
    # exit-2 path, never a zero.
    check("D1", bool(decl) and bool(decl_h) and declared_set_problem(decl) is None
          and declared_set_problem({}) is not None,
          "an empty fixture, or an empty declared set not routed to the exit-2 path")


def _tier2(failures: list[str], parser, scratch: Path) -> None:
    def check(arm: str, ok: bool, what: str) -> None:
        if not ok:
            failures.append(f"{arm}: {what}")

    tree = scratch / "workflows"
    tree.mkdir()
    for name, text in FIXTURE_HEADERS.items():
        (tree / name).write_text(text, encoding="utf-8")
    declared = declared_required(tree, parser)

    check("P1", declared.get("P one") == {"required": ["p1.yml:1"]}
          and declared.get("P two") == {"required": ["p1.yml:1"]},
          "a bare `required` header did not yield each of its contexts")
    check("P2", declared.get("P legacy key") == {"required": ["p2.yml:1"]},
          "the legacy `enforcement-surface=` key was not read")
    check("P3", set(declared.get("P held", {})) == {"required(warn-mode-initial)"}
          and discloses_hold(declared["P held"]),
          "the held qualifier did not survive the parse intact")
    check("P4", set(declared.get("P ratified", {})) == {"required(enforce; ratified 2026-09-04)"}
          and not discloses_hold(declared["P ratified"]),
          "a qualifier containing spaces did not survive the parse, or was read as held")
    check("P5", "P advisory" not in declared and "P advisory on bp" not in declared,
          "an `advisory` header's context was declared required")
    # The total is the control: five contexts sit on the track in this tree (P1's two,
    # P2's, P3's and P4's), so a sixth means something off the track was swept in.
    check("P6", "P non-blocking" not in declared and len(declared) == 5,
          "a required posture on a non-blocking surface named a context on the track")
    check("P7", "P lookalike" not in declared,
          "a posture that merely begins with the letters was swept in")

    # TB1 to TB6 — the disposition-table reader, through the shared splitter (which is
    # why they are tier 2). TB1 is the specificity leg every malformed arm is a one-edit
    # variant of: it parses, with backticks and `**` stripped, an escaped pipe kept inside
    # its cell, and the next section's table not read.
    def tb(name: str, text: str):
        path = scratch / name
        path.write_text(text, encoding="utf-8")
        try:
            return load_disposition_rows(path, parser), None
        except TableError as exc:
            return None, str(exc)

    rows, err = tb("tb1.md", TB_TABLE)
    check("TB1", err is None and rows == {"Ctx one": "REGISTER", "Ctx two": "HOLD",
                                          "Ctx three": "CORRECT-THEN-HOLD"},
          f"a well-formed disposition table did not parse to its three rows ({err or rows})")
    variants = {
        "TB2": (TB_TABLE.replace(TABLE_HEADING, "## Declared-required contexts"),
                "the heading absent"),
        "TB3": (TB_TABLE.replace("| Disposition |", "| Decision |"),
                "a column renamed"),
        "TB4": (TB_TABLE.replace("| `Ctx three` | `c.yml` |", "| `Ctx three` |"),
                "a three-cell row"),
        "TB5": (TB_TABLE.replace("**HOLD**", "**PARK**"),
                "a disposition outside the closed set"),
        "TB6": (TB_TABLE.replace("`Ctx three`", "`Ctx one`"),
                "a context on two rows"),
    }
    for arm, (text, what) in variants.items():
        rows, err = tb(f"{arm.lower()}.md", text)
        check(arm, rows is None and err is not None,
              f"{what} was read as a table ({rows}) rather than failing the instrument")
    for arm, text, what in (
            ("TB3", TB_TABLE.replace("| Context | Declared at | Disposition | Basis / ending "
                                     "condition |\n|---|---|---|---|\n", ""),
             "the header row deleted"),
            ("TB6", TB_TABLE.split("| `Ctx one`")[0].rstrip("\n") + "\n\n## Next section\n",
             "zero rows")):
        rows, err = tb(f"{arm.lower()}b.md", text)
        check(arm, rows is None and err is not None,
              f"{what} was read as a table ({rows}) rather than failing the instrument")
    try:
        load_disposition_rows(scratch / "no-such-standard.md", parser)
        unreadable_failed = False
    except TableError:
        unreadable_failed = True
    check("TB2", tb("empty.md", "")[1] is not None and unreadable_failed,
          "an empty or unreadable standard was read as a table")


def self_test(require_parser: bool) -> int:
    """Falsification harness. Runs on demand, on every `selftest-discovery` run, and as
    the first hard step of the reconciliation job (with --require-parser).

    Each sensitivity arm has a specificity arm on the same non-empty input — a detector
    that classified everything as a finding would otherwise pass every sensitivity arm
    and be worthless. Fixtures are plain files in a temporary directory; nothing reads
    or writes git.
    """
    failures: list[str] = []
    parser = load_shared_parser(repo_root_from(Path(__file__).resolve().parent))
    with tempfile.TemporaryDirectory() as tmp:
        scratch = Path(tmp)
        _tier1(failures, scratch)
        if parser is not None:
            _tier2(failures, parser, scratch)

    if failures:
        print("SELF-TEST FAILED:", file=sys.stderr)
        for failure in failures:
            print(f"  {failure}", file=sys.stderr)
        return EXIT_CANNOT_ASSERT
    if parser is None:
        line = (f"self-test: tier 1 PASS — {len(TIER1_ARMS)} of "
                f"{len(TIER1_ARMS) + len(TIER2_ARMS)} arms ran: tier 1 (stdlib) "
                f"{' '.join(TIER1_ARMS)}; tier 2 (shared parser) {' '.join(TIER2_ARMS)} "
                f"NOT-EVALUATED — {NOT_CLEAN_CLAUSE} for tier 2: the shared header parser "
                f"at {PARSER_MODULE_REL} could not be loaded (it needs PyYAML).")
        if require_parser:
            print(line, file=sys.stderr)
            print(f"FAIL ({EXIT_CANNOT_ASSERT}): --require-parser was given and the "
                  f"shared parser could not be loaded.", file=sys.stderr)
            return EXIT_CANNOT_ASSERT
        print(line)
        return 0
    print(f"self-test: PASS — {len(TIER1_ARMS) + len(TIER2_ARMS)} arms: tier 1 (stdlib) "
          f"{' '.join(TIER1_ARMS)}; tier 2 (shared parser) {' '.join(TIER2_ARMS)}. "
          f"Every sensitivity arm fired and every specificity arm stayed silent on its "
          f"own non-empty input; a read that did not return produced neither verdict.")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--workflows", default=None,
                    help="workflow directory (default: <repo root>/.github/workflows)")
    live = ap.add_mutually_exclusive_group()
    live.add_argument("--live", default=None,
                      help="the branch-protection input: a file of live "
                           "required_status_checks contexts, one per line; "
                           "an empty file, or one holding a JSON response body, is degraded; a non-JSON body (an HTML page, a stderr line) is not detected — use --live-branch-json")
    live.add_argument("--live-branch-json", default=None,
                      help="the branch-protection input: the response body of GET "
                           "/repos/{owner}/{repo}/branches/main; anything but a branch "
                           "object carrying the context list is degraded")
    ap.add_argument("--live-rules-json", default=None,
                    help="the response body of GET /repos/{owner}/{repo}/rules/branches/main"
                         "?per_page=100; required for a verdict — without it the rules read "
                         "is not-run and the run is NOT-EVALUATED")
    ap.add_argument("--standard", default=None,
                    help=f"the gate-efficacy standard whose disposition table is read "
                         f"(default: <repo root>/{STANDARD_REL})")
    ap.add_argument("--github-output", default=None,
                    help="append verdict=<TOKEN>, live_status=<status> and "
                         "rules_status=<status> to this file")
    ap.add_argument("--self-test", action="store_true",
                    help="run the falsification harness and exit")
    ap.add_argument("--require-parser", action="store_true",
                    help="with --self-test: exit 2 if the shared header parser cannot "
                         "be loaded, instead of reporting its arms NOT-EVALUATED")
    args = ap.parse_args()

    if args.self_test:
        return self_test(args.require_parser)

    here = Path(__file__).resolve().parent
    root = repo_root_from(here)
    workflows = Path(args.workflows) if args.workflows else (
        (root / ".github" / "workflows") if root else None
    )
    if workflows is None or not workflows.is_dir():
        print(f"FAIL ({EXIT_CANNOT_ASSERT}): no workflow directory resolved — the declared "
              f"set could not be read, so no report is published.", file=sys.stderr)
        return EXIT_CANNOT_ASSERT

    root = root or repo_root_from(workflows.resolve())
    parser = load_shared_parser(root)
    if parser is None:
        print(f"FAIL ({EXIT_CANNOT_ASSERT}): the shared header parser at "
              f"{PARSER_MODULE_REL} is unreachable, so the declared set could not be "
              f"read. This tool does NOT carry a private copy of the header grammar — two "
              f"parsers over one format is the drift this single-parser coupling exists "
              f"to prevent.", file=sys.stderr)
        return EXIT_CANNOT_ASSERT

    declared = declared_required(workflows, parser)
    problem = declared_set_problem(declared)
    if problem:
        print(f"FAIL ({EXIT_CANNOT_ASSERT}): {problem}", file=sys.stderr)
        return EXIT_CANNOT_ASSERT

    standard = Path(args.standard) if args.standard else (
        (root / STANDARD_REL) if root else None
    )
    try:
        rows = load_disposition_rows(standard, parser)
    except TableError as exc:
        print(f"FAIL ({EXIT_CANNOT_ASSERT}): the disposition table in {standard} cannot be "
              f"read ({exc}) — a verdict input that cannot be read is not an empty one, so "
              f"no report is published.", file=sys.stderr)
        return EXIT_CANNOT_ASSERT

    if args.live_branch_json is not None:
        classic = read_live_branch_json(args.live_branch_json)
    else:
        classic = read_live(args.live)
    rules = read_live_rules_json(args.live_rules_json)
    status = combined_status(classic[0], rules[0])
    live_contexts = list(dict.fromkeys(classic[1] + rules[1]))
    verdict, classes = classify(declared, rows, status, live_contexts)
    named = named_anywhere(workflows, parser)
    print("\n".join(render(declared, rows, (classic, rules), live_contexts, verdict,
                           classes, named)))
    return emit(verdict, status, rules[0], args.github_output)


if __name__ == "__main__":
    sys.exit(main())
