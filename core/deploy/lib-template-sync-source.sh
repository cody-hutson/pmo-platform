#!/usr/bin/env bash
# lib-template-sync-source.sh — single resolver for the TEMPLATE_SYNC_MAP
# canonical-source path. THE one definition of the canonical-source resolution
# rule; sourced by BOTH consumers (deploy.sh + core/deploy/tools/
# build-skill-packages.sh) so the two can never diverge (#2158).
#
# Why this exists (the drift class it closes):
#   deploy.sh's resolve_template_sync_source() and build-skill-packages.sh's
#   resolve_canonical_source() were two parallel `case` copies of the SAME rule,
#   kept aligned only by a "Keep byte-aligned" comment. During v2.29, #94
#   registered regression-checks.md in deploy.sh's copy but not the other, so the
#   pmo-skill-editor package rebuild errored at release-cut
#   (`canonical missing: operations/templates/regression-checks.md`) and had to be
#   patched during close-out. Single-sourcing the resolver into this fragment
#   makes that divergence structurally impossible: there is now exactly one
#   definition, and both scripts source it (the idiom deploy.sh already uses for
#   lib-instance-path.sh / lib-composition.sh).
#
# Resolution convention (add a NEW shared-standards basename to arm 1 HERE — this
# is now the single place that changes):
#   output-format.md          → core/standards/<name>   (explicit; #316)
#   operational-artifacts.md  → core/standards/<name>   (explicit; #316)
#   regression-checks.md      → core/standards/<name>   (explicit; #94)
#   tracker-schemas.md        → core/schemas/<name>     (explicit; #4178)
#   template-*.md             → core/standards/<name>
#   *-template.{md,csv} / …   → operations/templates/<name>   (default)
# (templates → operations, template-* standards → core. The modular canonical is
# operations/templates/ — the public-API surface per docs/module-apis.md §
# Operations module § Public templates.)
#
# The explicit shared-standards-doc basenames (output-format.md,
# operational-artifacts.md, regression-checks.md) are single-sourced shared
# references homed in core/standards/ per template-storage.md §3 / §7.2. They
# match neither the template-*.md nor the *-template.{md,csv} pattern, so they are
# mapped by an explicit narrow basename rule rather than a broad "non-template →
# core/standards/" catch-all — a catch-all would silently re-home any future
# non-template basename and is deliberately avoided. Add a new explicit basename
# to arm 1 below when a further shared standards doc is single-sourced.
#
# tracker-schemas.md gets its OWN arm rather than joining arm 1 because it homes
# to core/schemas/, not core/standards/. It is the canonical half of a registered
# COMPLEMENTARY pair (core/deploy/allowlists/complementary-reference-pairs.txt),
# injected into tracker-manager's package at its repo-relative path so the
# SKILL.md citations of that path resolve verbatim from the package root.
#
# THE ARM IS LOAD-BEARING, NOT COSMETIC. Without it the basename matches no
# explicit arm and no template-*.md pattern, so it falls to the DEFAULT and
# resolves to operations/templates/tracker-schemas.md — a THIRD path that does
# not exist, neither half of the pair. Check 13 (always-enforce) would then
# report "canonical missing from registry" and build_one() would return 1 on
# every tracker-manager build. Because this resolver is the ONE definition both
# deploy.sh and build-skill-packages.sh source, the arm keeps the two staging
# paths resolving identically by construction — which is the whole reason the
# injection is expressed as a map entry rather than hand-coded into one builder.
#
# The function is a pure stdout-echoing resolver (no side effects, no mutation);
# safe to call under `set -euo pipefail`. Sourceable AND idempotent: re-sourcing
# is a no-op (the definition is simply re-declared). The caller checks file
# existence of the echoed path.
#
# Bash version: 3.2.57-safe (no associative arrays, no `local -n` nameref).

# Resolve the source path for a TEMPLATE_SYNC_MAP canonical filename.
# Args:
#   $1 — canonical filename (e.g., raid-log-template.csv, template-storage.md,
#        output-format.md)
# Echoes the resolved source path. Caller checks file existence.
resolve_template_sync_source() {
  local name="$1"
  case "$name" in
    output-format.md|operational-artifacts.md|regression-checks.md) echo "core/standards/$name" ;;
    tracker-schemas.md)                        echo "core/schemas/$name" ;;
    template-*.md)                             echo "core/standards/$name" ;;
    *)                                         echo "operations/templates/$name" ;;
  esac
}
