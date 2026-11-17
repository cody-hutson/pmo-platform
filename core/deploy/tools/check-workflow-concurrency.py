#!/usr/bin/env python3
"""check-workflow-concurrency.py — the superseded-run cancellation gate.

THE INVARIANT. Every workflow under .github/workflows/ that a pull request
triggers carries the ONE canonical superseded-run cancellation block, at
workflow level and nowhere else:

    concurrency:
      group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.run_id }}
      cancel-in-progress: true

On a pull request the group is per workflow and per pull request, so a newer
run cancels the older one. On a push, a tag, a schedule or a dispatch the
pull-request number is empty, the key falls back to the run id, and the run has
a group of its own: it is never cancelled and never waits. An event whose
payload carries a pull request — a review event — resolves the key to the pull
request's group instead, which is why the population below refuses a review
event beside a pull-request trigger. No other key is accepted, because the
property that matters — "can this group hold two runs triggered by pushes to
main?" — is decidable for this one form and not for expressions in general.
A presence-only check would pass `${{ github.workflow }}-${{ github.ref }}`,
whose key is `refs/heads/main` on every push to main.

POPULATION. Every *.yml / *.yaml directly under the workflows directory (the
host reads no subdirectory). Each file is classified by its trigger set:

    called     triggers include workflow_call -> MUST NOT also carry a
               pull-request trigger (pull_request or pull_request_target), and
               MUST NOT carry a workflow-level concurrency key. A called workflow
               evaluates its caller's github context, so its group would equal
               the caller's and cancel it; and a pull-request trigger beside
               workflow_call would otherwise let one inert trigger line take a
               pull-request workflow out of this gate. The remedy is a split: a
               caller that carries the canonical block, and a called workflow
               with neither.
    in scope   triggers include pull_request or pull_request_target, and not
               workflow_call -> MUST carry the canonical block, no job of the
               file may carry a concurrency key, and the trigger set MUST NOT
               add a review event (pull_request_review,
               pull_request_review_comment): a review event's payload carries
               the pull request, so its run joins this pull request's group and
               cancels a pull-request run it does not supersede
    exempt     anything else (push, tags, schedule, dispatch, merge_group, a
               review event on its own, ...) -> no constraint

and, across the in-scope files, the workflow identity the key embeds (the
`name:`, or the file path when there is none, which is what github.workflow
evaluates to) is distinct after case-folding, because group names are
case-insensitive.

TWO ARMS, BOTH MUST HOLD. The structure is read with a PyYAML compose (node
graph, so a bare `on:` key is read as the text "on", never as the boolean
PyYAML 1.1 resolves it to), and the form is read from the raw source line each
node starts on. Equality is TEXTUAL: a quoted value, a trailing comment, a
different indent or a plain scalar continued onto a second line is not the
canonical form, whatever it parses to — so this gate and a fixed-string grep of
the canonical line can never disagree on a file this gate passes.

REJECTED FORMS, KEPT HERE SO THEY ARE NOT RE-LITIGATED. A key built from
github.ref (the same value on every push to main). A key built from
github.head_ref (a branch name, shared by two forks' same-named branches). A
key built from github.sha (a dispatch at a pushed commit would share the push
run's group). A job-level group, mapping or string form (it can hold two jobs
of two push runs). cancel-in-progress false (a superseded run is not ended).
Parsed rather than textual equality (PyYAML's YAML 1.1 resolution reads `yes`
and `on` as booleans, so a parsed comparison accepts spellings the canonical
line does not have, and a quoted value would pass this gate while failing a
fixed-string search of the canonical line). Changed-files scanning
(a workflow that arrives by merging main is unchanged relative to the base).
Exempting a pull-request-triggered workflow that also declares workflow_call
(one inert trigger line would switch the gate off for that file).

LIMITS, STATED. The gate does not read activity types: a pull_request trigger
typed `labeled`, or any type that fires more than once on one head, lets
successive events of that type cancel each other's runs. An exempt workflow may
carry any concurrency key; the gate does not grade it.

EXIT CODES. 0 clean · 1 findings (every finding line begins `FAIL: `) ·
2 the instrument cannot assert (PyYAML unimportable, no workflow file found,
the control arm dead, a failed self-test arm) · 3 NOT-EVALUATED (the
workflows directory could not be read). Neither 2 nor 3 is a clean result.
"""
from __future__ import annotations

import argparse
import contextlib
import difflib
import io
import sys
import tempfile
from pathlib import Path

try:
    import yaml
except ImportError:  # pragma: no cover - environment guard
    print("SCAN-ERROR: PyYAML is required; the trigger and structure read must be "
          "STRUCTURAL. Exit 2: the instrument cannot assert.", file=sys.stderr)
    sys.exit(2)

GATE_ID = "workflow-concurrency"
CANONICAL_GROUP = "${{ github.workflow }}-${{ github.event.pull_request.number || github.run_id }}"
CANONICAL_LINES = {
    "concurrency": "concurrency:",
    "group": "  group: " + CANONICAL_GROUP,
    "cancel-in-progress": "  cancel-in-progress: true",
}
PR_TRIGGERS = {"pull_request", "pull_request_target"}
REVIEW_TRIGGERS = {"pull_request_review", "pull_request_review_comment"}
CALLED_TRIGGER = "workflow_call"
DEFAULT_DIR = ".github/workflows"
CONTROL_HOST = "repo-integrity.yml"   # this gate's own host: PR-triggered by construction
FIXTURE_FILE = Path(__file__).resolve().parent / "fixtures" / GATE_ID / "cases.yml"

TEACH = """\
The canonical block (insert it above the top-level `jobs:` line):

concurrency:
  group: ${{ github.workflow }}-${{ github.event.pull_request.number || github.run_id }}
  cancel-in-progress: true

Write it exactly: unquoted, two-space indent, nothing after the value. A key built
from github.ref is refs/heads/main on every push to main, so it puts those pushes in
one group, and a later merge cancels an earlier merge's run. A workflow that declares
workflow_call has no pull-request trigger and carries no workflow-level concurrency
key: split such a file into a caller that carries the block and a called workflow
with neither. A review event (pull_request_review, pull_request_review_comment)
belongs in a workflow of its own, never beside a pull-request trigger."""


def _key(node) -> str | None:
    return node.value if isinstance(node, yaml.ScalarNode) else None


def _triggers(node) -> set[str] | None:
    if isinstance(node, yaml.ScalarNode):
        return {node.value}
    if isinstance(node, yaml.SequenceNode):
        names = {_key(n) for n in node.value}
        return None if None in names else names
    if isinstance(node, yaml.MappingNode):
        names = {_key(k) for k, _ in node.value}
        return None if None in names else names
    return None


def evaluate_file(rel: str, text: str) -> tuple[str, str | None, list[str]]:
    """Return (class, identity, findings) for one workflow file."""
    lines = text.splitlines()
    try:
        root = yaml.compose(text, Loader=yaml.SafeLoader)
    except yaml.YAMLError as exc:
        mark = getattr(exc, "problem_mark", None)
        line = mark.line + 1 if mark else 0
        return "unreadable", None, [f"FAIL: {rel}:{line} UNPARSEABLE the file is not one YAML document"]
    if not isinstance(root, yaml.MappingNode):
        return "unreadable", None, [f"FAIL: {rel}:1 UNPARSEABLE the document is not a mapping"]

    top: dict[str, list] = {}
    for k, v in root.value:
        top.setdefault(_key(k) or "", []).append((k, v))
    findings: list[str] = []
    for name in ("on", "concurrency", "jobs", "name"):
        if len(top.get(name, [])) > 1:
            findings.append(f"FAIL: {rel}:{top[name][1][0].start_mark.line + 1} "
                            f"DUPLICATE-KEY top-level `{name}` appears more than once")
    if "on" not in top:
        return "unreadable", None, findings + [f"FAIL: {rel}:1 TRIGGER-UNREADABLE no top-level `on` key"]
    on_line = top["on"][0][0].start_mark.line + 1
    triggers = _triggers(top["on"][0][1])
    if triggers is None:
        return "unreadable", None, findings + [f"FAIL: {rel}:{on_line} TRIGGER-UNREADABLE the `on` value has a shape this gate does not read"]

    name_node = top.get("name", [(None, None)])[0][1]
    identity = name_node.value if isinstance(name_node, yaml.ScalarNode) and name_node.value else rel
    conc = top.get("concurrency", [])

    if CALLED_TRIGGER in triggers:
        pr = sorted(triggers & PR_TRIGGERS)
        if pr:
            findings.append(f"FAIL: {rel}:{on_line} CALLED-WITH-PR-TRIGGER a workflow that declares "
                            f"workflow_call also has a pull-request trigger ({', '.join(pr)}); split it "
                            "into a caller that carries the canonical block and a called workflow with neither")
        if conc:
            findings.append(f"FAIL: {rel}:{conc[0][0].start_mark.line + 1} CALLED-CARRIES-GROUP "
                            "a workflow that declares workflow_call carries a workflow-level concurrency key")
        return "called", None, findings
    if not (triggers & PR_TRIGGERS):
        return "exempt", None, findings

    review = sorted(triggers & REVIEW_TRIGGERS)
    if review:
        findings.append(f"FAIL: {rel}:{on_line} REVIEW-WITH-PR-TRIGGER the trigger set adds "
                        f"{', '.join(review)} to a pull-request trigger; a review event's run joins this "
                        "pull request's group and cancels a pull-request run it does not supersede")
    if not conc:
        findings.append(f"FAIL: {rel}:1 MISSING-GROUP pull-request-triggered and carries no workflow-level concurrency block")
    else:
        knode, vnode = conc[0]
        kline = knode.start_mark.line
        if lines[kline] != CANONICAL_LINES["concurrency"] or not isinstance(vnode, yaml.MappingNode):
            findings.append(f"FAIL: {rel}:{kline + 1} NONCANONICAL-SHAPE the concurrency value is not the two-key block mapping")
        else:
            seen: dict[str, list] = {}
            for ck, cv in vnode.value:
                seen.setdefault(_key(ck) or "", []).append((ck, cv))
            extra = sorted(set(seen) - {"group", "cancel-in-progress"})
            dup = sorted(k for k, v in seen.items() if len(v) > 1)
            if extra or dup or set(seen) != {"group", "cancel-in-progress"}:
                findings.append(f"FAIL: {rel}:{kline + 1} NONCANONICAL-SHAPE keys must be exactly group and "
                                f"cancel-in-progress (extra={','.join(extra) or '-'} duplicate={','.join(dup) or '-'})")
            if "group" in seen:
                gk, gv = seen["group"][0]
                raw = lines[gk.start_mark.line]
                parsed = gv.value if isinstance(gv, yaml.ScalarNode) else None
                if raw != CANONICAL_LINES["group"] or parsed != CANONICAL_GROUP:
                    findings.append(f"FAIL: {rel}:{gk.start_mark.line + 1} NONCANONICAL-GROUP the group line is not the canonical line")
            if "cancel-in-progress" in seen:
                ck, cv = seen["cancel-in-progress"][0]
                raw = lines[ck.start_mark.line]
                ok = isinstance(cv, yaml.ScalarNode) and cv.tag == "tag:yaml.org,2002:bool" and cv.value == "true"
                if raw != CANONICAL_LINES["cancel-in-progress"] or not ok:
                    findings.append(f"FAIL: {rel}:{ck.start_mark.line + 1} NONCANONICAL-CANCEL cancel-in-progress is not the unquoted boolean true")
    jobs = top.get("jobs", [(None, None)])[0][1]
    if isinstance(jobs, yaml.MappingNode):
        for jk, jv in jobs.value:
            if isinstance(jv, yaml.MappingNode):
                for k, _ in jv.value:
                    if _key(k) == "concurrency":
                        findings.append(f"FAIL: {rel}:{k.start_mark.line + 1} JOB-CONCURRENCY job `{_key(jk)}` "
                                        "carries its own concurrency key")
    return "in-scope", identity, findings


def evaluate(files: dict[str, str]) -> tuple[list[str], dict[str, int], dict[str, str]]:
    findings: list[str] = []
    counts = {"in-scope": 0, "called": 0, "exempt": 0, "unreadable": 0}
    classes: dict[str, str] = {}
    idents: dict[str, list[str]] = {}
    for rel in sorted(files):
        cls, ident, fs = evaluate_file(rel, files[rel])
        counts[cls] += 1
        classes[rel] = cls
        findings += fs
        if ident is not None:
            idents.setdefault(ident.casefold(), []).append(rel)
    for folded, rels in sorted(idents.items()):
        if len(rels) > 1:
            for rel in rels:
                findings.append(f"FAIL: {rel}:1 NAME-COLLISION workflow identity collides after case-folding with "
                                f"{', '.join(r for r in rels if r != rel)} (group names are case-insensitive)")
    return findings, counts, classes


def read_dir(d: Path) -> dict[str, str] | None:
    if not d.is_dir():
        return None
    out = {}
    for p in sorted(d.iterdir()):
        if p.is_file() and p.suffix in (".yml", ".yaml"):
            out[f"{d.as_posix().rstrip('/')}/{p.name}"] = p.read_text(encoding="utf-8")
    return out


def report(files: dict[str, str], control: bool, where: str) -> int:
    if not files:
        print(f"SCAN-ERROR: {where} holds no *.yml or *.yaml file — an empty population is not a clean result")
        return 2
    findings, counts, classes = evaluate(files)
    print(f"DENOM: {GATE_ID} — status=fetched declared=1 resolved=1 examined={len(files)} exempted=0")
    print(f"SCOPE: in-scope={counts['in-scope']} called={counts['called']} "
          f"trigger-exempt={counts['exempt']} unreadable={counts['unreadable']}")
    if control:
        host = next((r for r in classes if Path(r).name == CONTROL_HOST), None)
        if host is None or classes[host] != "in-scope":
            print(f"SCAN-ERROR: control arm dead — this gate's own host {CONTROL_HOST} is "
                  f"{'absent' if host is None else classes[host]}, not in scope; the trigger read is broken")
            return 2
        print(f"CONTROL: {CONTROL_HOST} classified in-scope (the trigger read reaches its own host)")
    for f in findings:
        print(f)
    if findings:
        print(f"VERDICT: FINDINGS ({len(findings)})")
        print(TEACH)
        return 1
    print("VERDICT: CLEAN")
    return 0


def scan(d: Path, control: bool) -> int:
    try:
        files = read_dir(d)
    except OSError as exc:
        print(f"NOT-EVALUATED: {d} could not be read ({exc})")
        return 3
    if files is None:
        print(f"NOT-EVALUATED: {d} is not a readable directory")
        return 3
    return report(files, control, str(d))


def load_cases() -> list[tuple[str, dict[str, str], int, set[str], bool]]:
    """Read FIXTURE_FILE: YAML documents separated by `---` lines. Each document opens
    with `# case: <id>  expect=<exit>  codes=<c1,c2|->  kind=<near-miss|other>`; the
    documents of one id form one population (the name-collision case has two)."""
    text = FIXTURE_FILE.read_text(encoding="utf-8")
    docs, cur = [], []
    for line in text.splitlines(keepends=True):
        if line.rstrip("\n") == "---":
            docs.append("".join(cur))
            cur = []
        else:
            cur.append(line)
    docs.append("".join(cur))
    cases: dict[str, list] = {}
    for doc in docs:
        head = next((ln for ln in doc.splitlines() if ln.startswith("# case: ")), None)
        if head is None:
            continue
        fields = dict(t.split("=", 1) for t in head[len("# case: "):].split()[1:])
        cid = head[len("# case: "):].split()[0]
        row = cases.setdefault(cid, [cid, {}, int(fields["expect"]),
                                     set() if fields["codes"] == "-" else set(fields["codes"].split(",")),
                                     fields["kind"] == "near-miss"])
        row[1][f"{cid}-{len(row[1]) + 1}.yml"] = doc
    return [tuple(r) for r in cases.values()]


def _body(doc: str) -> list[str]:
    return [ln for ln in doc.splitlines() if not ln.startswith("# case: ")]


def self_test() -> int:
    bad = 0
    def arm(name, ok, detail=""):
        nonlocal bad
        print(f"{'ok  ' if ok else 'FAIL'} {name}{(' — ' + detail) if detail else ''}")
        bad += 0 if ok else 1
    def quiet(d, control):
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = scan(d, control)
        return rc, buf.getvalue()
    def quiet_report(texts):
        # The exit the gate RETURNS for a population, not one computed beside it:
        # a regression in the findings-to-exit mapping fails every case arm.
        buf = io.StringIO()
        with contextlib.redirect_stdout(buf):
            rc = report(texts, control=False, where="self-test")
        return rc
    def codes_of(texts):
        return {f.split()[2] for f in evaluate(texts)[0]}
    cases = load_cases()
    arm("fixture file holds cases", len(cases) > 0, f"{len(cases)} cases")
    canonical = next((c for c in cases if c[0] == "canonical"), None)
    arm("fixture file holds the passing case `canonical`", canonical is not None)
    if canonical is None:
        print("SELF-TEST: FAIL (no canonical case)")
        return 2
    base_doc = next(iter(canonical[1].values()))
    for case, texts, rc, codes, near in cases:
        got = codes_of(texts)
        got_rc = quiet_report(texts)
        arm(f"CASE {case} expected={rc}:{','.join(sorted(codes)) or '-'}",
            got_rc == rc and got == codes, f"observed={got_rc}:{','.join(sorted(got)) or '-'}")
        if near:
            first = next(iter(texts.values()))
            hunks = [g for g in difflib.SequenceMatcher(None, _body(base_doc), _body(first)).get_opcodes()
                     if g[0] != "equal"]
            arm(f"CASE {case} is a one-property mutation of `canonical`", len(hunks) == 1, f"{len(hunks)} hunk(s)")
    base = base_doc
    inline = {
        "bare `on:` key read as text, string form": ("name: A\non: pull_request\njobs: {}\n", "in-scope"),
        "sequence form": ("name: A\non: [push, pull_request]\njobs: {}\n", "in-scope"),
        "quoted on key": ('name: A\n"on": {pull_request: {}}\njobs: {}\n', "in-scope"),
        "pull_request_review is not pull_request": ("name: A\non: pull_request_review\njobs: {}\n", "exempt"),
        "pull_request_review_comment alone is exempt": ("name: A\non: pull_request_review_comment\njobs: {}\n", "exempt"),
        "merge_group only is exempt": ("name: A\non: merge_group\njobs: {}\n", "exempt"),
        "pull_request_target is in scope": ("name: A\non: pull_request_target\njobs: {}\n", "in-scope"),
        "workflow_call alone is the called class": ("name: A\non: workflow_call\njobs: {}\n", "called"),
        "no `on` key is unreadable": ("name: A\njobs: {}\n", "unreadable"),
    }
    for name, (text, want) in inline.items():
        cls, _, _ = evaluate_file("x.yml", text)
        arm(f"TRIGGER {name}", cls == want, f"classified {cls}")
    code_arms = {
        "pull_request_target beside workflow_call is CALLED-WITH-PR-TRIGGER":
            ("name: A\non: [pull_request_target, workflow_call]\njobs: {}\n", {"CALLED-WITH-PR-TRIGGER"}),
        "pull_request_review_comment beside pull_request is REVIEW-WITH-PR-TRIGGER":
            (base.replace("  push:\n    branches: [main]\n", "  pull_request_review_comment:\n", 1),
             {"REVIEW-WITH-PR-TRIGGER"}),
        "no `on` key is TRIGGER-UNREADABLE": ("name: A\njobs: {}\n", {"TRIGGER-UNREADABLE"}),
        "a string-shorthand workflow-level concurrency value is NONCANONICAL-SHAPE":
            (base.replace("\n".join(CANONICAL_LINES[k] for k in ("concurrency", "group", "cancel-in-progress")),
                          "concurrency: fixture-shared", 1),
             {"NONCANONICAL-SHAPE"}),
    }
    for name, (text, want) in code_arms.items():
        got = codes_of({"x.yml": text})
        arm(name, got == want, f"observed={','.join(sorted(got)) or '-'}")
    cont = base.replace(CANONICAL_LINES["group"], CANONICAL_LINES["group"] + "\n    -tail", 1)
    arm("plain scalar continued onto a second line is NONCANONICAL-GROUP",
        any("NONCANONICAL-GROUP" in f for f in evaluate({"x.yml": cont})[0]))
    dup = base.replace("jobs:", "concurrency:\n  group: x\n  cancel-in-progress: true\n\njobs:", 1)
    arm("a second top-level concurrency key is DUPLICATE-KEY",
        any("DUPLICATE-KEY" in f for f in evaluate({"x.yml": dup})[0]))
    yes = base.replace(CANONICAL_LINES["cancel-in-progress"], "  cancel-in-progress: yes", 1)
    arm("`yes` (a YAML 1.1 boolean) is NONCANONICAL-CANCEL",
        any("NONCANONICAL-CANCEL" in f for f in evaluate({"x.yml": yes})[0]))
    arm("unparseable YAML is a finding, never a skip",
        any("UNPARSEABLE" in f for f in evaluate({"x.yml": "name: [unclosed\n"})[0]))
    with tempfile.TemporaryDirectory() as td:
        rc, out = quiet(Path(td), False)
        arm("an empty directory exits 2, not 0", rc == 2 and "SCAN-ERROR" in out)
        rc, out = quiet(Path(td) / "absent", False)
        arm("a missing directory exits 3 (NOT-EVALUATED)", rc == 3 and "NOT-EVALUATED" in out)
        (Path(td) / CONTROL_HOST).write_text("name: H\non: push\njobs: {}\n", encoding="utf-8")
        rc, out = quiet(Path(td), True)
        arm("a dead control arm (host read as exempt) exits 2", rc == 2 and "is exempt, not in scope" in out)
        (Path(td) / CONTROL_HOST).write_text(base, encoding="utf-8")
        rc, out = quiet(Path(td), True)
        arm("the live control arm (host in scope and canonical) exits 0", rc == 0 and "CONTROL:" in out)
        nog = next((c for c in cases if c[0] == "no-group"), None)
        if nog is None:
            arm("a scan with a finding exits 1 and names it", False, "no `no-group` case")
        else:
            text = next(iter(nog[1].values())).replace("name: Fixture canonical", "name: Fixture no-group", 1)
            (Path(td) / "no-group.yml").write_text(text, encoding="utf-8")
            rc, out = quiet(Path(td), True)
            fails = [ln for ln in out.splitlines() if ln.startswith("FAIL: ")]
            arm("a scan with a finding exits 1 and names it (the findings exit is graded, not inferred)",
                rc == 1 and len(fails) == 1 and " MISSING-GROUP " in fails[0],
                f"rc={rc}, {len(fails)} FAIL line(s)")
    print(f"SELF-TEST: {'PASS' if not bad else f'FAIL ({bad} arm(s))'}")
    return 0 if not bad else 2


def main() -> int:
    ap = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    ap.add_argument("--workflows-dir", type=Path, default=None,
                    help="scan this directory instead of .github/workflows (no control arm)")
    ap.add_argument("--case", default=None,
                    help="scan one committed fixture case from fixtures/workflow-concurrency/cases.yml (no control arm)")
    ap.add_argument("--self-test", action="store_true")
    a = ap.parse_args()
    if a.self_test:
        return self_test()
    if a.case is not None:
        found = [c for c in load_cases() if c[0] == a.case]
        if not found:
            print(f"SCAN-ERROR: no fixture case `{a.case}` in {FIXTURE_FILE.name}")
            return 2
        return report(found[0][1], control=False, where=f"case {a.case}")
    if a.workflows_dir is not None:
        return scan(a.workflows_dir, control=False)
    return scan(Path(DEFAULT_DIR), control=True)


if __name__ == "__main__":
    sys.exit(main())
