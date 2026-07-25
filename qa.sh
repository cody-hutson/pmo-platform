#!/usr/bin/env bash
# qa.sh — standalone QA-as-code regression suite (pmo-platform).
#
# Runs the onboarding-install/update regression checks (F1-F10 + R1/R2) and
# prints a Markdown report. Standalone entry — nothing in install.sh / update.sh
# / orchestrate.sh invokes it (auto-run wiring is a deferred follow-up).
#
# Usage:
#   ./qa.sh [--only F1,F5,R2] [--read-only] [--format md|text] [--list]
#
# Exit codes (propagated from python3 -m qa):
#   0  all checks PASS (SKIP is not a failure)
#   1  at least one check FAIL
#   2  internal error
#
# Bash version: 3.2.57-safe.

set -Eeuo pipefail

# qa.sh sits at the repo root; anchor on its own location so it runs from any cwd.
REPO_ROOT="$(cd "$(dirname "$0")" && pwd)"

# core/deploy on PYTHONPATH so `python3 -m qa` finds the package AND its
# sibling compose.py (the sys.path-injection reuse convention). As the last
# command, its exit code becomes the script's exit code.
PYTHONPATH="${REPO_ROOT}/core/deploy${PYTHONPATH:+:${PYTHONPATH}}" python3 -m qa "$@"
