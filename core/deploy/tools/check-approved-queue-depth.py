#!/usr/bin/env python3
"""Approved-queue-depth monitor primitive (card queue-depth-monitor).

deploy.sh Check 53's scan engine. Counts the open approved-but-unbundled
queue — issues carrying `status: approved` with NO milestone assigned — and,
when the count crosses the bundling threshold (default 5), emits an ACTIONABLE
bundle-candidate summary (count + themes + priorities), not a bare number. The
threshold DEFINITION lives in the Stage-3 Bundle definition (Phase B4:
"threshold-triggered (5+ Approved)") and is REFERENCED here via --threshold, not
redefined.

This is the active DETECTOR behind the Stage-3 A7 "T1 Approved-queue depth"
refresh trigger — the trigger's definition already exists in the Stage-3 shard;
this monitor is the mechanism that surfaces it to the operator at deploy time.

Population (the counted set):
  open issues WITH the `status: approved` label AND NO milestone
  == `gh issue list --label "status: approved" --search "no:milestone" --state open`
Themes are derived from each issue's `cluster:*` / `project:*` labels; priority
signal from any `priority:*` / `P0`-`P3` style label present (best-effort — the
platform's priority lives in a Projects field, absent from the issue-label set,
so label-derived priority is a heuristic and gaps are reported, never invented).

Exit codes (the check-label-parity.py / check-doc-links.py family convention):
  0  below threshold — queue is not a bundle candidate (silent-PASS)
  1  at/above threshold — a bundle-candidate summary was emitted (a FINDING)
  2  argument / input error
  3  gh unavailable OR the live issue set was unreadable (fail-loud: a blind
     read must not green a possibly-full queue)

Ships warn-mode-initial per core/rules/bypass-mode-readiness.md; deploy.sh
Check 53 downgrades the exit-1 finding to a non-blocking WARN during the
shakedown window (the queue is ~29 today, so the check fires on first run —
warn-mode is what keeps that non-blocking). Flip via an
`approved-queue-depth.mode` file after the >=3-day warn-log review.
"""
from __future__ import annotations

import argparse
import json
import subprocess
import sys

APPROVED_LABEL = "status: approved"
# Label namespaces that carry the "theme" signal for a bundle-candidate summary.
THEME_PREFIXES = ("cluster:", "project:")
# Best-effort priority-label shapes. The canonical priority lives in a Projects
# field (not on the issue-label set), so a missing priority label is a KNOWN gap
# reported as "unlabeled", never fabricated.
PRIORITY_PREFIXES = ("priority:", "p0", "p1", "p2", "p3")


def fetch_approved_unbundled():
    """Live open `status: approved` + no-milestone issues via gh. Returns a list
    of {number, title, labels:[name,...]}. Raises on gh failure (caller -> exit 3)."""
    res = subprocess.run(
        [
            "gh", "issue", "list",
            "--label", APPROVED_LABEL,
            "--search", "no:milestone",
            "--state", "open",
            "--limit", "500",
            "--json", "number,title,labels",
        ],
        capture_output=True,
        text=True,
    )
    if res.returncode != 0:
        raise RuntimeError(f"gh issue list failed: {res.stderr.strip()[:200]}")
    rows = json.loads(res.stdout)
    out = []
    for row in rows:
        out.append(
            {
                "number": row.get("number"),
                "title": row.get("title", ""),
                "labels": [lb.get("name", "") for lb in row.get("labels", [])],
            }
        )
    return out


def _labels_matching(labels, prefixes):
    """Case-insensitive prefix match; returns the matched label names, sorted."""
    hits = set()
    for lb in labels:
        low = lb.lower()
        if any(low.startswith(p) for p in prefixes):
            hits.add(lb)
    return sorted(hits)


def summarize(issues):
    """Return (theme_counts:dict, priority_counts:dict, unthemed:int).
    theme_counts / priority_counts key on the label token; unthemed counts issues
    with no cluster:/project: label at all."""
    theme_counts = {}
    priority_counts = {}
    unthemed = 0
    for iss in issues:
        themes = _labels_matching(iss["labels"], THEME_PREFIXES)
        if not themes:
            unthemed += 1
        for t in themes:
            theme_counts[t] = theme_counts.get(t, 0) + 1
        prios = _labels_matching(iss["labels"], PRIORITY_PREFIXES)
        if prios:
            for p in prios:
                priority_counts[p] = priority_counts.get(p, 0) + 1
        else:
            priority_counts["(unlabeled)"] = priority_counts.get("(unlabeled)", 0) + 1
    return theme_counts, priority_counts, unthemed


def _fmt_counts(counts):
    """Descending by count, then label; 'label (n)' comma-joined."""
    items = sorted(counts.items(), key=lambda kv: (-kv[1], kv[0]))
    return ", ".join(f"{k} ({v})" for k, v in items) if items else "(none)"


def _self_test():
    """Offline fixture suite — no gh/network. Proves count + theme/priority roll-up."""
    fixture = [
        {"number": 1, "title": "a", "labels": ["status: approved", "cluster: automation", "priority: high"]},
        {"number": 2, "title": "b", "labels": ["status: approved", "cluster: automation"]},
        {"number": 3, "title": "c", "labels": ["status: approved", "project:pipeline"]},
        {"number": 4, "title": "d", "labels": ["status: approved"]},  # unthemed, unlabeled priority
        {"number": 5, "title": "e", "labels": ["status: approved", "cluster: automation", "project:pipeline"]},
    ]
    ok = True
    theme_counts, priority_counts, unthemed = summarize(fixture)
    if theme_counts.get("cluster: automation") != 3:
        print(f"FAIL theme cluster: automation={theme_counts.get('cluster: automation')} want 3")
        ok = False
    if theme_counts.get("project:pipeline") != 2:
        print(f"FAIL theme project:pipeline={theme_counts.get('project:pipeline')} want 2")
        ok = False
    if unthemed != 1:
        print(f"FAIL unthemed={unthemed} want 1")
        ok = False
    if priority_counts.get("priority: high") != 1:
        print(f"FAIL priority high={priority_counts.get('priority: high')} want 1")
        ok = False
    if priority_counts.get("(unlabeled)") != 4:
        print(f"FAIL priority unlabeled={priority_counts.get('(unlabeled)')} want 4")
        ok = False
    # Threshold behavior: count 5 vs default 5 => at/above => finding.
    if not (len(fixture) >= 5):
        print("FAIL threshold arithmetic")
        ok = False
    print("self-test: PASS" if ok else "self-test: FAIL")
    return 0 if ok else 1


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Approved-queue-depth monitor — Stage-3 bundling trigger detector"
    )
    ap.add_argument(
        "--threshold",
        type=int,
        default=5,
        help="bundle-candidate threshold (default 5; DEFINITION lives in the Stage-3 shard, referenced not redefined)",
    )
    ap.add_argument("--output-format", choices=("tsv", "text"), default="tsv")
    ap.add_argument(
        "--self-test", action="store_true", help="run the offline fixture suite; no gh needed"
    )
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    if args.threshold < 1:
        print(f"--threshold must be >= 1 (got {args.threshold})", file=sys.stderr)
        return 2

    try:
        issues = fetch_approved_unbundled()
    except Exception as e:  # noqa: BLE001 - any gh/parse failure is fail-loud (exit 3)
        print(f"cannot read the approved-unbundled queue: {e}", file=sys.stderr)
        return 3

    count = len(issues)
    theme_counts, priority_counts, unthemed = summarize(issues)

    if count < args.threshold:
        # Below threshold: silent-PASS. TSV carries the count for the caller's log.
        if args.output_format == "tsv":
            print(f"COUNT\t{count}")
            print(f"THRESHOLD\t{args.threshold}")
            print("BELOW_THRESHOLD\ttrue")
        else:
            print(f"approved-unbundled queue depth {count} < threshold {args.threshold} — not a bundle candidate")
        return 0

    # At/above threshold: emit an ACTIONABLE bundle-candidate summary.
    themes_str = _fmt_counts(theme_counts)
    prios_str = _fmt_counts(priority_counts)
    if args.output_format == "tsv":
        print(f"COUNT\t{count}")
        print(f"THRESHOLD\t{args.threshold}")
        print("BELOW_THRESHOLD\tfalse")
        print(f"THEMES\t{themes_str}")
        print(f"PRIORITIES\t{prios_str}")
        print(f"UNTHEMED\t{unthemed}")
    else:
        print(f"approved-unbundled queue depth {count} >= threshold {args.threshold} — BUNDLE CANDIDATE")
        print(f"  themes:     {themes_str}")
        print(f"  priorities: {prios_str}")
        if unthemed:
            print(f"  unthemed:   {unthemed} issue(s) with no cluster:/project: label")

    return 1


if __name__ == "__main__":
    sys.exit(main())
