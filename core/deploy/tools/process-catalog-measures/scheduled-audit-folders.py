"""scheduled-audit-folders — the dated folders of the analysis home, by audit family.

Inputs: the analysis-folder summaries. For each folder directly inside the analysis home whose
name ends in a date, the generator hands over the folder's name and the frontmatter block of its
summary file, and nothing else under the folder.

Population: every such dated folder. A folder's family is its name with the trailing date removed.
Two frontmatter fields are read, the analysis type and the created date; the second only for
whether it is present.

Report: per family, its folder total, how many carry a summary, how many state a created date,
and its folders by analysis type. Aggregates only; no folder name with its date is written.
"""
from collections import Counter, defaultdict
from re import compile


def field(block, name):
    for line in block.splitlines():
        if line.startswith(name + ":"):
            return line.split(":", 1)[1].strip()
    return ""


def measure(inputs, params):
    dated = compile("^(.+)-[0-9]{4}-[0-9]{2}-[0-9]{2}$")
    families = defaultdict(list)
    for entry in sorted(inputs):
        for label, text in inputs[entry]:
            hit = dated.search(label)
            if hit:
                families[hit.group(1)].append(text)
    lines = [f"dated folders: {sum(len(blocks) for blocks in families.values())} in {len(families)} families"]
    for family in sorted(families):
        blocks = families[family]
        with_summary = [block for block in blocks if block.strip()]
        created = sum(1 for block in with_summary if field(block, "created"))
        kinds = Counter(field(block, "analysis_type") or "not stated" for block in with_summary)
        by_kind = ", ".join(f"{kind} {kinds[kind]}" for kind in sorted(kinds)) or "none"
        lines.append(f"family {family}: folders {len(blocks)}; with a summary {len(with_summary)}; "
                     f"stating a created date {created}; by analysis type: {by_kind}")
    return "\n".join(lines) + "\n"
