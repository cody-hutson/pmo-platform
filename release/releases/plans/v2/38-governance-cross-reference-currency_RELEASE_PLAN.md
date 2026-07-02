<!-- repo-integrity: allow-issue-ref -->
<!-- reference-durability: allow-link -->
# Release Plan — governance-cross-reference-currency

**Milestone:** `38-governance-cross-reference-currency` (#123)
**Branch:** `release/38-governance-cross-reference-currency` (theme-named; version-insulated)
**Bump-class:** `minor` — Phase 1 intent per RELEASE_PROTOCOL § Versioning. **Provisional-display:** `v2.29` is a LABEL only; the concrete number is computed next-free over `anchor()` and atomically claimed at Stage 12 (defer-to-merge, ADR-036). Anchor re-verified 2026-06-26 = `v2.28` (sibling `15-generated-vs-source-provenance` shipped v2.28 mid-run; the provisional drifted v2.28→v2.29 per defer-to-merge) → next-free = `v2.29`. Re-verified again at the Stage 12 atomic claim.
**Release Class:** `cross-cutting` (operator-rendered 2026-06-26) → engagement Tight · Stage 9 review Deep · Stage 5 bias ALL · outcome-window 30-day.
**Full Stage 4 plan:** sub-task #2087 comment (dependency graph, D-gate detail, full risk register).

## Theme
Clear stale cross-references — issue `#N`, dead file-path citations, stale numeric claims — that survived the v1.01 re-versioning and the modular-monolith restructure, and add the durable gate that stops the `#N` drift recurring.

## Execution tracks
| Track | Issues | Mechanism |
|---|---|---|
| T-CI (durable platform change) | #2081 | net-new `#N`-target-validity check in `reference-durability.yml`; full pipeline + version |
| T-DOC (cosmetic sweeps) | #677, #399, #121 | per-file read-classify-plan-then-edit; PR on release branch; no individual version bump |
| T-OPS (issue-ops, off-pipeline) | #2080 | `gh`-driven; no repo PR, no version; verify-only closure at Stage 13 |
| Umbrella | #753 | no direct deliverable; mark closed at Stage 13 once #2080 + #2081 close |

Closed-for-accounting (already VERIFIED in prior releases): #114, #110, #95.

## Implementation sequence (Engineering — D-C SINGLE topology)
1. **#121** — single-token `≥3`→`>3` at `core/disciplines/operating-model.md:412` (zero contention).
2. **#677** — 13 SKILL.md `pmo-platform/reference/specs/` → `core/specs/` (routed through `pmo-skill-editor`).
3. **#399** — 42-file path-drift sweep (raw 55 − #677's 13), exclusion rubric applied per-file.
4. **#2081** — `#N`-target-validity gate in `reference-durability.yml` + fixture test.

`#2080` (gh) runs in parallel — no branch interaction. `#753` is marked closed last.

## Contention map (load-bearing carve-out)
- `raw55` = `grep -rlE 'pmo-platform/(reference|skills|engineering|governance)/' core release operations docs --include='*.md'` (excl. `CLAUDE.md.template`).
- `#677_13` = `grep -rlE 'pmo-platform/reference/specs/' {core,operations,release}/skills/*/SKILL.md`.
- **`#677_13 ⊂ raw55`** (verified live: 0 of the 13 fall outside raw55). **`#399 net = raw55 − #677_13 = 42`.** #399 EXCLUDES the 13 (no double-touch) and further prunes historical release-corpus + deploy-path globs + tool-examples per its exclusion rubric.
- `#121` target (`operating-model.md`) ∉ raw55 (0 matching path strings). `#2081` (`.github/`) and `#2080` (no repo files) carry no corpus overlap.

## Stage applicability
- **#2081** — S5 / S6 / S7 / S8 / S9 / S12 / S13 full (executable behavior + fixture-able AC).
- **#677, #399, #121** — S5 SKIP; S6 APPLY; S7/8 REDUCE → doc-conformance (grep + `check-doc-links.py` / Check 14); S9 / S12 / S13.
- **#2080** — off-pipeline (no S5/6/7/8/9/12); S13 verify-only accounting (re-scan returns 0 + #242→#196 rewired).
- **#753** — close-only at S13.

## Risk register (summary — full on #2087)
- **R-SKILL** — #677 SKILL.md edits via `pmo-skill-editor`; `.skill` packages rebuild at release-cut; Check 14 + `link-check.yml` must pass on the new `core/specs/` paths.
- **R-MECH** — #399 / #677 use per-file read-classify-plan-then-edit + citations-only diff review (NOT mechanical find-replace; the link-rewriter is the post-edit no-broken-link guard only).
- **R-RESCAN** — #2080 live re-scan mandatory before any sweep (the 2026-06-06 catalog is stale).
- **R-VERSION** — bind bump-class `minor`; defer the concrete number to the Stage 12 atomic claim (the v2.x mainline moves fast).
- **R-ROLLBACK** — T-DOC/T-CI = git revert of the release PR (CHEAP); #2080 = individual `gh` reversal (MODERATE; keep the pre-sweep catalog as the rollback reference).

## Operator decisions (rendered 2026-06-26)
- **D-ReleaseClass** = `cross-cutting`.
- **D-Version** = versioned, bump-class `minor` (concrete number deferred to Stage 12 atomic claim).
- **D-2080-Track** = off-pipeline via `gh` (verify-only closure at Stage 13).
- **Execution model** = do the work this session; no per-stage sub-task issues (operator direction — minimal ticket ceremony).

## Provenance
Stage 4 planning sub-task: #2087 (full plan, dependency graph, D-gate detail). Source issues: #753 (umbrella), #2080, #2081, #677, #399, #121.
