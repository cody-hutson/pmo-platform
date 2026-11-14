"""event-log-deploy-replay — stamped deploys replayed against the order the deploy is designed to keep.

Inputs: the event-log rows the generator kept under the population rule.

Population: the stamped-deploy cases of that population. A case is one release key with
deployment-status rows. The designed order is: the rules mirror first, one mirror row for each
stamped run; then one row for each skill; then packages; then harness artifacts; every row at the
execute stage with the hub as its actor.

Tests, per case. Order: the fewest non-decreasing chains that cover the case's subtype sequence do
not exceed the stamped runs its mirror rows show, at least one. Stage and actor: every row is at
the execute stage with the hub as actor. Mirror presence: a case whose rows all follow the first
mirror row in the log carries a mirror row; a case that precedes it is outside that test.

Report: the case total, and the cases that fit each test and all of them. Aggregates only; no
key, subject or payload is written.
"""
from collections import defaultdict


def chains(sequence):
    tails = []
    for value in sequence:
        placed = False
        for index, tail in enumerate(tails):
            if tail <= value and not placed:
                tails[index] = value
                placed = True
        if not placed:
            tails.append(value)
        tails.sort(reverse=True)
    return len(tails)


def measure(inputs, params):
    order = {"deploy-rules-mirror": 0, "deploy-skill": 1, "deploy-package": 2, "deploy-harness": 3}
    cases = defaultdict(list)
    mirror_times = []
    unknown = 0
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            for line in text.splitlines():
                cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
                if line.startswith("| ") and len(cells) >= 10 and cells[3] == "deployment-status":
                    cases[cells[1]].append(cells)
                    if cells[4] == "deploy-rules-mirror":
                        mirror_times.append(cells[0])
                    if cells[4] not in order:
                        unknown += 1
    first_mirror = min(mirror_times) if mirror_times else ""
    fit_order = 0
    fit_attributes = 0
    fit_mirror = 0
    in_mirror_test = 0
    fit_all = 0
    for key in sorted(cases):
        rows = cases[key]
        sequence = [order[cells[4]] for cells in rows if cells[4] in order]
        mirrors = sum(1 for cells in rows if cells[4] == "deploy-rules-mirror")
        ordered = chains(sequence) <= max(1, mirrors)
        attributed = not any(cells[2] != "12" or cells[5].split(":")[0] != "hub" for cells in rows)
        tested = first_mirror != "" and min(cells[0] for cells in rows) >= first_mirror
        mirrored = mirrors > 0 or not tested
        fit_order += 1 if ordered else 0
        fit_attributes += 1 if attributed else 0
        in_mirror_test += 1 if tested else 0
        fit_mirror += 1 if tested and mirrors > 0 else 0
        fit_all += 1 if ordered and attributed and mirrored else 0
    lines = [
        f"stamped-deploy cases: {len(cases)}",
        f"  fit the order test: {fit_order}",
        f"  fit the stage and actor test: {fit_attributes}",
        f"  inside the mirror-presence test: {in_mirror_test}; of which with a mirror row: {fit_mirror}",
        f"  fit every test: {fit_all}",
        f"rows with a subtype outside the designed order: {unknown}",
    ]
    return "\n".join(lines) + "\n"
