#!/usr/bin/env bash
# cross-module-audit.sh — Cross-Module Extraction-Readiness Audit Wrapper
#
# Per the module-restructure Stage 5 spec:
#   Bash entrypoint for the cross-module audit. Delegates parsing,
#   classification, and emit to cross_module_audit_helper.py which inherits
#   primitive correctness (FM-1 fence-stripping, FM-2 anchor-resolution)
#   from check-doc-links.py via Python import (per CD-2 counter-design).
#
# Composition:
#   - check-doc-links.py — primitive (markdown link extraction + path resolution)
#   - cross_module_audit_helper.py — directionality + cross-ref-type classification
#     + 7-strategy enum recommendation + TSV/markdown emit
#   - this wrapper — CLI surface + exit codes per Surface 1.5
#
# Cross-ref-type refinement (per counter-design CD-3): cycle predicates classify
# Cat-1/Cat-2 matches into code-import (BLOCKER), markdown-doc-link (Suspect;
# carry-forward allowed per ADR-007), and narrative-mention (Minor). Documentary
# cross-refs from core/disciplines + core/schemas to
# release/governance/release-process.md + release/references/pipeline/* are
# accepted cohesion (per the ADR-007 carry-forward contract).
#
# Usage (from pmo-platform-v2 repo root):
#   core/deploy/tools/cross-module-audit.sh [<md-output>] [<tsv-output>]
#
# Defaults:
#   md-output  = audit-output/cross-module-audit-${AUDIT_DATE_UTC}.md
#   tsv-output = audit-output/cross-module-audit-${AUDIT_DATE_UTC}.tsv
#
# Exit codes (per Surface 1.5):
#   0 — no cycle-class violations (clean OR non-cycle violations only)
#   1 — code-import cycle violation detected (BLOCKS module extraction)
#   2 — non-cycle violations detected (advisory; routes to the cleanup queue)
#   3 — script error
#
# Authored per the module-restructure Stage 5 spec + counter-design CD-3.

set -euo pipefail

# Resolve script dir + python helper.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HELPER="$SCRIPT_DIR/cross_module_audit_helper.py"

# Resolve repo root (3 levels up from core/deploy/tools/).
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Audit date — UTC YYYY-MM-DD.
AUDIT_DATE_UTC="${AUDIT_DATE_UTC:-$(date -u +%Y-%m-%d)}"

# Default output paths.
MD_OUTPUT="${1:-audit-output/cross-module-audit-${AUDIT_DATE_UTC}.md}"
TSV_OUTPUT="${2:-audit-output/cross-module-audit-${AUDIT_DATE_UTC}.tsv}"

# Validate prerequisites.
if [ ! -f "$HELPER" ]; then
    echo "ERROR: Python helper not found at $HELPER" >&2
    exit 3
fi
if [ ! -d "$REPO_ROOT/core" ] || [ ! -d "$REPO_ROOT/release" ] || [ ! -d "$REPO_ROOT/operations" ]; then
    echo "ERROR: Expected modules (core/, release/, operations/) not found at $REPO_ROOT" >&2
    exit 3
fi

# Resolve commit SHA for report stamping.
COMMIT_SHA="$(cd "$REPO_ROOT" && git rev-parse --short HEAD 2>/dev/null || echo 'unknown')"

# Make output paths absolute (or repo-rooted).
case "$MD_OUTPUT" in
    /*) MD_ABS="$MD_OUTPUT" ;;
    *)  MD_ABS="$REPO_ROOT/$MD_OUTPUT" ;;
esac
case "$TSV_OUTPUT" in
    /*) TSV_ABS="$TSV_OUTPUT" ;;
    *)  TSV_ABS="$REPO_ROOT/$TSV_OUTPUT" ;;
esac

echo "Cross-Module Audit — $AUDIT_DATE_UTC at $COMMIT_SHA" >&2
echo "  Markdown report: $MD_ABS" >&2
echo "  TSV report:      $TSV_ABS" >&2

# Invoke Python helper.
cd "$REPO_ROOT"
set +e
python3 "$HELPER" \
    --md-output "$MD_ABS" \
    --tsv-output "$TSV_ABS" \
    --commit-sha "$COMMIT_SHA" \
    --audit-date "$AUDIT_DATE_UTC"
HELPER_EXIT=$?
set -e

# Propagate helper exit code per Surface 1.5 semantics.
case $HELPER_EXIT in
    0) echo "Audit clean — no violations." >&2 ;;
    1) echo "BLOCKER: code-import cycle violations — see $MD_ABS" >&2 ;;
    2) echo "Non-cycle violations detected — see $MD_ABS" >&2 ;;
    *) echo "ERROR: helper exited with code $HELPER_EXIT" >&2; exit 3 ;;
esac

exit $HELPER_EXIT
