"""workflow-run-history — how the runs of the named workflows ended, over a trailing window.

Inputs: one run-history input per workflow file the register row names. Each is handed over as one
line per run, tab-separated: trigger event, conclusion, status, created date. No other field of a
run reaches this file.

Population: every run of each named workflow created in the trailing window the row's parameters
declare, as the generator read it from the host in slices and verified against the host's own
total for each slice. With the `by_event` parameter set to `yes`, the tally is split by trigger
event.

Report: per workflow, its run total and its runs by conclusion; then one total line. Aggregates
only.
"""
from collections import Counter


def ending(cells):
    return cells[1] or cells[2] or "none"


def tally(counts):
    return ", ".join(f"{key} {counts[key]}" for key in sorted(counts))


def measure(inputs, params):
    split = params.get("by_event") == "yes"
    lines = []
    total = 0
    workflows = 0
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            rows = [line.split("\t") for line in text.splitlines() if line.strip()]
            rows = [cells for cells in rows if len(cells) == 4]
            workflows += 1
            total += len(rows)
            lines.append(f"workflow {label}: runs {len(rows)}")
            if rows:
                lines.append(f"  by conclusion: {tally(Counter(ending(cells) for cells in rows))}")
            if split:
                for event in sorted(Counter(cells[0] for cells in rows)):
                    of_event = [cells for cells in rows if cells[0] == event]
                    lines.append(f"  event {event}: runs {len(of_event)}; "
                                 f"{tally(Counter(ending(cells) for cells in of_event))}")
    lines.append(f"total: runs {total} across {workflows} workflows; trailing window of "
                 f"{params.get('window_days')} days ending {params.get('today')}")
    return "\n".join(lines) + "\n"
