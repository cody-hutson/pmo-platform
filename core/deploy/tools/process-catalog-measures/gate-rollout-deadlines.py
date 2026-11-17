"""gate-rollout-deadlines — where each gate rollout stands against its own review and escalation windows.

Inputs: the tracked deploy script and the tracked destructive-operations hook, each read for its
rollout constants; and the committed enforce sentinels, each read for its token.

Population: every rollout family that declares a phase, an arming date, a review window and an
escalation window as read-only constants in those two files, classified as the two deadline checks
classify it on the day of the run; and every committed enforce sentinel.

Report: per rollout family, its phase and its standing — graduated, within its window, review
due, or escalation overdue — with the days elapsed since arming; then the sentinels by token.
"""
from collections import Counter
from datetime import date
from re import compile


def standing(found, today):
    if found.get("PHASE") == "enforce":
        return "graduated"
    try:
        elapsed = (date.fromisoformat(today) - date.fromisoformat(found.get("ARMED", ""))).days
        review = int(found.get("REVIEW_DAYS", ""))
        escalate = int(found.get("ESCALATE_DAYS", ""))
    except ValueError:
        return "not readable"
    if elapsed >= escalate:
        return f"escalation overdue, {elapsed} days since arming"
    if elapsed >= review:
        return f"review due, {elapsed} days since arming"
    return f"within its window, {elapsed} days since arming"


def measure(inputs, params):
    constant = compile("^readonly ([A-Z0-9_]+)_(PHASE|ARMED|REVIEW_DAYS|ESCALATE_DAYS)=\"?([A-Za-z0-9-]+)")
    families = {}
    tokens = Counter()
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            if label.endswith(".enforce"):
                kept = [line.strip() for line in text.splitlines() if line.strip() and not line.strip().startswith("#")]
                tokens[kept[0] if kept else "empty"] += 1
                continue
            for line in text.splitlines():
                hit = constant.search(line)
                if hit:
                    families[hit.group(1)] = families.get(hit.group(1)) or {}
                    families[hit.group(1)][hit.group(2)] = hit.group(3)
    lines = []
    for family in sorted(families):
        found = families[family]
        if "PHASE" in found and "ARMED" in found:
            lines.append(f"rollout {family}: phase {found['PHASE']}; {standing(found, params.get('today', ''))}")
    lines.append(f"enforce sentinels: {sum(tokens.values())}")
    for token in sorted(tokens):
        lines.append(f"  {token}: {tokens[token]}")
    return "\n".join(lines) + "\n"
