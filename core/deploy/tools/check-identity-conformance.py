#!/usr/bin/env python3
"""Slug-primary release-identity conformance check for deploy.sh Check 59 (#3107).

Window-gated predicate: it is IN SCOPE only when the runner is on a `release/*`
branch AND the release is still PRE-claim (its in-flight plan carries the
unresolved `{{RELEASE_VERSION}}` token — #2548's AC3 mechanism, ADR-092). Within
scope it REJECTS a concrete `vX.Y` bound into either the branch name or the
new-on-branch plan filename before the Stage-12 claim. Off a release branch, or
once the release is claimed (post-claim), it SKIPs cleanly — absence is not drift.

This is the pre-CLAIM naming-conformance twin of the pre-MERGE version-freeness
gate (deploy.sh Check 41): same window, same claim oracle family. It reads git
state (branch + the release's own new/renamed plan) but re-implements no version
parser — the claim-state oracle is simply the presence of the `{{RELEASE_VERSION}}`
token that #2548 emits pre-claim and `claim-version.sh` resolves at the claim.

The single discriminator between a version-primary IN-FLIGHT plan (FAIL) and a
post-claim RENAMED `vX.Y` plan (no-fire) is the claim-state oracle: an unresolved
token means pre-claim (in scope); a resolved concrete version means post-claim
(out of scope). Both are new-on-branch `vX.Y`-named files; only the oracle tells
them apart.

Exit codes: 0 = clean or SKIP (out of scope / compliant), 1 = finding(s)
(a concrete vX.Y bound pre-claim), 3 = input/context failure (git unavailable /
origin/main unreachable — the surface is unverifiable, not clean; fail-loud per
the Check 20/57/58 convention).

Usage:
    python3 core/deploy/tools/check-identity-conformance.py [--root .]
    python3 core/deploy/tools/check-identity-conformance.py --self-test
"""
from __future__ import annotations

import argparse
import os
import re
import subprocess
import sys

CLAIM_TOKEN = "{{RELEASE_VERSION}}"
# A concrete vX.Y bound into a release branch name (the pre-claim leak, branch leg).
BRANCH_VERSION_RE = re.compile(r"^release/v[0-9]+\.[0-9]+")
# A concrete vX.Y bound into a plan filename (the pre-claim leak, plan leg).
PLAN_VERSION_RE = re.compile(r"^v[0-9]+\.[0-9]+.*_RELEASE_PLAN\.md$")
PLAN_GLOB_SUFFIX = "_RELEASE_PLAN.md"

EXIT_CLEAN = 0
EXIT_FINDING = 1
EXIT_CONTEXT = 3


def evaluate(branch: str | None, in_flight_plan: str | None, preclaim: bool | None) -> tuple[int, str]:
    """Pure window-gated predicate. Inputs are the already-resolved git/plan state.

    branch:         current branch name (e.g. 'release/foo', 'main', 'HEAD', 'fix/x')
    in_flight_plan: basename of the release's own new/renamed plan, or None
    preclaim:       True (in-flight plan is PRE-claim — carries the token),
                    False (post-claim — token resolved to a concrete version),
                    None (no in-flight plan / indeterminate claim state)
    Returns (exit_code, message).
    """
    # --- SCOPE GATE ---
    if not branch or not branch.startswith("release/"):
        return (EXIT_CLEAN, "SKIP: not a release branch (absence is not drift)")
    if in_flight_plan is None or preclaim is None:
        return (EXIT_CLEAN, "SKIP: no in-flight plan on this release branch (absence is not drift)")
    if preclaim is False:
        return (EXIT_CLEAN,
                f"SKIP: release already claimed — post-claim plan '{in_flight_plan}' "
                f"(the version-named form is legitimate after the Stage-12 rename)")

    # --- WITHIN SCOPE (pre-claim): reject a concrete vX.Y in branch or plan basename ---
    findings: list[str] = []
    if BRANCH_VERSION_RE.match(branch):
        findings.append(
            f"branch '{branch}' embeds a concrete vX.Y before the claim — use the "
            f"slug-primary form 'release/<slug>' (the version binds at the Stage-12 claim)")
    if PLAN_VERSION_RE.match(in_flight_plan):
        findings.append(
            f"in-flight plan '{in_flight_plan}' embeds a concrete vX.Y before the claim — use "
            f"the slug-primary form '<slug>_RELEASE_PLAN.md' (renamed to vX.Y at the claim)")
    if findings:
        return (EXIT_FINDING, "; ".join(findings))
    return (EXIT_CLEAN, f"OK: slug-primary in-flight identity (branch '{branch}', plan '{in_flight_plan}')")


# ---------------------------------------------------------------------------
# git-state resolution (main path only; the self-test drives evaluate() directly)
# ---------------------------------------------------------------------------
def _git(root: str, *args: str) -> str:
    """Run a git command in <root>; raise on failure (mapped to exit 3 by main)."""
    out = subprocess.run(
        ["git", "-C", root, *args],
        capture_output=True, text=True, check=True,
    )
    return out.stdout.strip()


def _plan_is_preclaim(path: str) -> bool:
    """Claim-state oracle O: the plan is PRE-claim iff it still carries the
    unresolved {{RELEASE_VERSION}} token (its identity has not been stamped)."""
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return CLAIM_TOKEN in fh.read()
    except OSError:
        return False


def _resolve_in_flight(root: str) -> tuple[str | None, bool | None]:
    """Return (basename, preclaim) for the release's own in-flight plan, or (None, None).

    The in-flight plan is the release's own new/renamed _RELEASE_PLAN.md vs origin/main.
    When several plans differ on the branch (e.g. a historical rename lands alongside
    the release's own new plan), the PRE-claim one (token-carrying) is the release's
    own identity — prefer it; if all are post-claim, report the first (it SKIPs).
    """
    diff = _git(root, "diff", "--name-only", "--diff-filter=AR",
                "origin/main...HEAD", "--", "release/releases/plans/")
    candidates = [
        line for line in diff.splitlines()
        if line.strip().endswith(PLAN_GLOB_SUFFIX)
    ]
    if not candidates:
        return (None, None)
    # Prefer the release's own pre-claim (token-carrying) plan.
    for rel in candidates:
        if _plan_is_preclaim(os.path.join(root, rel)):
            return (os.path.basename(rel), True)
    # All post-claim (e.g. only a historical renamed vX.Y plan differs) → first, post-claim.
    return (os.path.basename(candidates[0]), False)


def run_main(root: str) -> int:
    try:
        branch = _git(root, "rev-parse", "--abbrev-ref", "HEAD")
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print(f"CONTEXT-FAIL: cannot resolve HEAD branch ({exc}) — identity conformance unverifiable")
        return EXIT_CONTEXT
    # Off a release branch we can SKIP without needing origin/main (cheap, offline-safe).
    if not branch.startswith("release/"):
        code, msg = evaluate(branch, None, None)
        print(msg)
        return code
    try:
        in_flight, preclaim = _resolve_in_flight(root)
    except (subprocess.CalledProcessError, FileNotFoundError) as exc:
        print(f"CONTEXT-FAIL: cannot diff against origin/main ({exc}) — fetch origin/main first")
        return EXIT_CONTEXT
    code, msg = evaluate(branch, in_flight, preclaim)
    print(msg)
    return code


# ---------------------------------------------------------------------------
# Self-test — the 4 fixtures (this IS the Stage-7 DevTest surface for #3107)
# ---------------------------------------------------------------------------
def run_self_test() -> int:
    # (label, branch, in_flight_plan, preclaim, expected_exit)
    fixtures = [
        # 1 · version-primary in-flight (token unresolved) → FAIL (both legs fire)
        ("version-primary in-flight", "release/v3.93-widget", "v3.93_RELEASE_PLAN.md", True, EXIT_FINDING),
        # 1b · slug branch but version-named in-flight plan (token unresolved) → FAIL (plan leg)
        ("slug branch, version plan", "release/widget", "v3.93_RELEASE_PLAN.md", True, EXIT_FINDING),
        # 2 · slug in-flight (token unresolved) → PASS
        ("slug in-flight", "release/widget", "widget_RELEASE_PLAN.md", True, EXIT_CLEAN),
        # 3 · grandfathered (runner on main; committed vX.Y plan) → no-fire (out of scope)
        ("grandfathered on main", "main", "v3.77_RELEASE_PLAN.md", False, EXIT_CLEAN),
        # 4 · post-claim renamed (release branch; token RESOLVED) → no-fire (out of scope)
        ("post-claim renamed", "release/widget", "v3.93_RELEASE_PLAN.md", False, EXIT_CLEAN),
    ]
    failures = 0
    for label, branch, plan, preclaim, expected in fixtures:
        code, msg = evaluate(branch, plan, preclaim)
        ok = code == expected
        # The F1/F4 discriminator is load-bearing: same vX.Y plan, opposite verdict via the oracle.
        status = "PASS" if ok else "FAIL"
        if not ok:
            failures += 1
        print(f"  [{status}] {label}: exit {code} (expected {expected}) — {msg}")
    if failures == 0:
        print("check-identity-conformance.py --self-test: PASS (4 fixtures + 1b: "
              "version-primary→FAIL, slug→PASS, grandfathered→no-fire, post-claim→no-fire; "
              "the F1/F4 discriminator is the claim-state oracle)")
        return EXIT_CLEAN
    print(f"check-identity-conformance.py --self-test: FAIL ({failures} fixture(s))")
    return EXIT_FINDING


def main(argv: list[str]) -> int:
    ap = argparse.ArgumentParser(description="Slug-primary release-identity conformance (Check 59).")
    ap.add_argument("--root", default=".", help="repo root (default: cwd)")
    ap.add_argument("--self-test", action="store_true", help="run the embedded 4-fixture harness")
    args = ap.parse_args(argv)
    if args.self_test:
        return run_self_test()
    return run_main(args.root)


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
