"""event-log-population — the pipeline event-log rows that are this repository's, by key rule.

Inputs: the event-log rows the generator kept. The generator applies the population rule before
this file runs, so no row of another repository and no unkeyed row reaches it.

Population: the rows of the pipeline event log whose release key is this repository's by a
positive check against its host — a slug key equal to a milestone title, or a legacy version key
equal to a tag name. A slug or a version string that another repository shares is counted, and a
legacy row whose version predates the host's tags is not.

Report: the row total; the rows and the distinct release keys under each key rule; and the rows
by event type. Aggregates only; no key, subject or payload is written.
"""
from collections import Counter, defaultdict


def measure(inputs, params):
    rows = []
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            for line in text.splitlines():
                cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
                if line.startswith("| ") and len(cells) >= 10:
                    rows.append(cells)
    by_rule = Counter()
    keys = defaultdict(list)
    for cells in rows:
        version = cells[1]
        legacy = version.startswith("v") and len(version) > 1 and version[1] in "0123456789"
        rule = "legacy version key" if legacy else "slug key"
        by_rule[rule] += 1
        if version not in keys[rule]:
            keys[rule].append(version)
    kinds = Counter(cells[3] for cells in rows)
    lines = [f"rows in the population: {len(rows)}"]
    for rule in sorted(by_rule):
        lines.append(f"  {rule}: rows {by_rule[rule]}; distinct release keys {len(keys[rule])}")
    lines.append("by event type:")
    for kind in sorted(kinds):
        lines.append(f"  {kind}: {kinds[kind]}")
    return "\n".join(lines) + "\n"
