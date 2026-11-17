"""event-log-deploy-status — the deployment-status rows of the pipeline event log.

Inputs: the event-log rows the generator kept under the population rule.

Population: the rows of that population whose event type is the deployment status. Such a row is
written only by a deploy that was stamped with a release, so an install-time, update-time or
post-merge deploy leaves none: those runs cannot be seen here.

Report: the row total and the distinct release keys; then the rows by subtype, by stage, by actor
kind and by outcome. Aggregates only; no key, subject or payload is written.
"""
from collections import Counter


def block(title, counts):
    return [f"{title}:"] + [f"  {key or 'not stated'}: {counts[key]}" for key in sorted(counts)]


def measure(inputs, params):
    rows = []
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            for line in text.splitlines():
                cells = [cell.strip() for cell in line.strip().strip("|").split("|")]
                if line.startswith("| ") and len(cells) >= 10 and cells[3] == "deployment-status":
                    rows.append(cells)
    releases = sorted(Counter(cells[1] for cells in rows))
    lines = [f"deployment-status rows: {len(rows)}; distinct release keys: {len(releases)}"]
    lines += block("by subtype", Counter(cells[4] for cells in rows))
    lines += block("by stage", Counter(cells[2] for cells in rows))
    lines += block("by actor kind", Counter(cells[5].split(":")[0] for cells in rows))
    lines += block("by outcome", Counter(cells[8] for cells in rows))
    return "\n".join(lines) + "\n"
