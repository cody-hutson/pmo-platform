"""flip-decision-rows — the flip-decision rows of the gate-efficacy standard, by leading decision.

Inputs: the tracked gate-efficacy standard, as checked out.

Population: the data rows of both tables under the standard's flip-decision heading, up to the
next heading of the same level. The first table is the rows above the paragraph that states the
row form; the second is the rows below it. Each row is read for the leading decision of its third
column.

Report: per table, its row total and its rows by leading decision. A decision outside the
standard's own set is counted as `other`. Aggregates only.
"""
from collections import Counter


def leading(cell):
    text = "".join(cell.split("**")).strip()
    for token in ("DEFERRED — precondition-blocked", "DEFERRED WITH A DEADLINE", "RATIFIED ADVISORY",
                  "SPLIT DISPOSITION", "shakedown continues", "flipped", "deferred"):
        if text.startswith(token):
            return token
    return "other"


def measure(inputs, params):
    tables = [Counter(), Counter()]
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            inside = False
            which = 0
            for line in text.splitlines():
                if line.startswith("## "):
                    inside = line.startswith("## Flip-decision status")
                    which = 0
                    continue
                if not inside:
                    continue
                if line.startswith("**Row form"):
                    which = 1
                    continue
                cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
                if not line.startswith("| ") or len(cells) < 3 or cells[0] == "Gate" or cells[0].startswith("---"):
                    continue
                tables[which][leading(cells[2])] += 1
    lines = []
    for name, counts in (("first table", tables[0]), ("second table", tables[1])):
        lines.append(f"{name}: rows {sum(counts.values())}")
        for token in sorted(counts):
            lines.append(f"  {token}: {counts[token]}")
    return "\n".join(lines) + "\n"
