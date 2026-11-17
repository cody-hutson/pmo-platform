"""secret-scan-range — what the blocking secret-scanning step read on its newest run, per trigger event.

Inputs: the newest-run-log input of the security workflow. For each trigger event the row's
parameters name, it is handed over as text: a `created` line, a `head` line carrying the run's
head commit, then the run's log text. An event with no run is handed over empty.

Population: the most recent run of the security workflow for each named trigger event.

Report: per event, whether the scan named a commit range and whether that range starts at the
run's own head commit, how many commits-scanned lines the log carries, and the verdict the scan
printed. No commit identifier, date or log line is written to the report.
"""
from re import compile


def first(pattern, lines):
    for line in lines:
        hit = pattern.search(line)
        if hit:
            return hit.group(1)
    return ""


def measure(inputs, params):
    wanted = params.get("events") or []
    events = [wanted] if str(wanted) == wanted else wanted
    span = compile("scanning ([0-9a-f]+)[.][.]HEAD")
    scanned = compile("([0-9]+) commits? scanned")
    clean = compile("(no leaks found)")
    dirty = compile("(leaks found: [0-9]+)")
    texts = {}
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            texts[label] = text
    lines = []
    for event in events:
        log = texts.get(event, "").splitlines()
        if not log:
            lines.append(f"event {event}: no run")
            continue
        head = ""
        for line in log:
            if line.startswith("head "):
                head = line.split(" ")[1].strip()
        base = first(span, log)
        if not base:
            reach = "no range line"
        elif head and (head.startswith(base) or base.startswith(head)):
            reach = "the range starts at the run's own head commit"
        else:
            reach = "the range starts at another commit"
        counted = sum(1 for line in log if scanned.search(line))
        if first(dirty, log):
            verdict = "leaks reported"
        elif first(clean, log):
            verdict = "no leaks reported"
        else:
            verdict = "no verdict line"
        lines.append(f"event {event}: {reach}; commits-scanned lines {counted}; {verdict}")
    return "\n".join(lines) + "\n"
