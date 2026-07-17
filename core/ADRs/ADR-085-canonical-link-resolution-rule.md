<!-- reference-durability: allow-link -->
---
title: "ADR-085 — Canonical markdown link-resolution rule; retire the bare module-prefix workspace-root fallback"
status: Accepted
date: 2026-07-17
release: v3.76 deploy-tooling-resolver-and-test-parity
deciders: "Stage-5 Solutioning (Principal-Engineer spoke; the premise-overturning grounding that the bare fallback is the GitHub-UNfaithful mechanism, HIGH confidence) + hub R1 + Collective Review scope-lock (operator elected Option (b) — retire the fallback)"
tags: [tooling, doc-link-maintenance, link-resolution, gate-efficacy, check-doc-links, check-release-links, github-rendering, supersedes-adr-009]
source_observations:
  - "The platform ran TWO markdown-link resolvers with different rules over one corpus: check-doc-links.py (deploy Check 14 + link-check.yml) resolved relative-first THEN fell back to a workspace-root anchor for bare module-prefixed paths, while release/tools/check-release-links.py (the Dead-file-reference gate's delegate) resolved relative-only and skipped leading-`/` entirely. A single link form could therefore get opposite verdicts across two required branch-protection gates — a gate-trustworthiness gap, the theme of the gate-efficacy standard this issue was filed under."
  - "The protocol asserted the bare-prefix fallback 'matches GitHub web rendering'. Grounding overturned that: GitHub renders a bare, no-leading-slash link relative to the current file's directory, so a bare `core/x.md` from a non-root file renders as `<dir>/core/x.md` -> 404. The fallback therefore MASKED links GitHub renders broken — the exact class the ADR-030 hook-registry restructure hit (check-doc-links.py exited 0; the stricter dead-file-reference gate caught 45 genuinely-broken links). GitHub fidelity lives in the leading-`/` clause, not the bare-prefix fallback."
  - "Corpus enumeration at Stage 5: 0 links in any scanned `*.md` file depend on the fallback; its sole live dependency is `core/CLAUDE.md.template` (19 root-anchored links). That template deploys to the repo root (deploy.sh validate_workspace), so rewriting its 19 bare links to the leading-`/` form is verdict-preserving for the checker and correct for the deployed `CLAUDE.md`."
---
# ADR-085 — Canonical markdown link-resolution rule; retire the bare module-prefix workspace-root fallback

## Status

**Accepted** (v3.76). Operator elected Option (b) — retire the fallback — at Collective Review scope-lock, escalating the originating issue beyond its named files to supersede the fallback-establishing ADR and rewrite the template.

This ADR **supersedes in part [ADR-009](ADR-009-rewrite-map-cli-design.md)**: specifically ADR-009 Rule 2 (the V1/V2 workspace-rooted prefix tables and the resolver bare-prefix workspace-root fallback they drove). ADR-009's rewrite-map CLI (Rules 1, 3, 4, 5) is untouched and remains in force.

## Context

Two resolvers applied different rules to one documentation corpus:

- `core/deploy/tools/check-doc-links.py` (deploy-time Check 14 + PR-time `link-check.yml`): resolved **relative-to-source first**, then, for a path beginning with a known module prefix (`core/`, `release/`, `pmo-platform/`, `.claude/`, …), **fell back to a workspace-root anchor** — the ADR-009 Rule-2 behavior.
- `release/tools/check-release-links.py` (the checker the `repo-integrity.yml` Dead-file-reference gate delegates to): resolved **relative-to-source only**, and **skipped** any leading-`/` target entirely.

Because both feed **required** branch-protection gates, one link form could pass one gate and fail the other. The originating issue asked for a single canonical rule, documented once, implemented by both checkers, with a controlled repro proving parity.

The load-bearing correction surfaced at Solutioning: the protocol claimed the bare-prefix fallback "matches GitHub web rendering," but it does the opposite. GitHub renders a bare, no-leading-slash link **relative to the current file's directory**; the fallback re-anchored such links to the repo root and so **passed links GitHub renders as 404s from non-root files**. That masking is the ADR-030 failure mode this issue cites. GitHub-faithful workspace-root anchoring is expressed by the **leading-`/`** form — a separate mechanism from the bare-prefix fallback.

## Decision

Adopt one canonical rule, implemented identically by both checkers:

> **A markdown link resolves relative to the source file's directory. A leading `/` denotes the workspace (repo) root — matching GitHub's rendered-blob behavior. There is NO bare module-prefix fallback: a path like `core/…` or `release/…` with no leading slash is an ordinary relative path, so from any non-root file it is a broken link.** Anchors (`#…`) and queries (`?…`) are stripped before path resolution.

Concretely:

1. `check-doc-links.py` `resolve_target()` — **remove** the bare-prefix workspace-root fallback block and the `V1_PREFIXES`/`V2_PREFIXES`/`WORKSPACE_ROOTED_PREFIXES` tables; **retain** the leading-`/` → workspace-root clause.
2. `check-release-links.py` — stop skipping leading-`/` targets; **resolve** them against the repo root (identical to clause 2). The no-argument bare-invocation contract is preserved (there are zero `/`-rooted links in `release/` today, so behavior is byte-identical there).
3. `core/CLAUDE.md.template` — rewrite its 19 bare workspace-rooted links (`](core/…)` / `](release/…)`) to the leading-`/` form. The template deploys to the repo root, so the leading-`/` form resolves correctly both as the scanned template and as the deployed `CLAUDE.md` — a verdict-preserving rewrite.
4. The protocol (`core/standards/doc-link-maintenance-protocol.md`), its rule mirror (`core/rules/doc-link-maintenance.md`), and the tools README document the three-clause rule as the single source of truth, with the "matches GitHub rendering" attribution corrected to the leading-`/` clause.

No enforcement posture changes: the required gates (`link-check.yml`, Dead-file-reference gate) and the advisory `release-link-check.yml` keep their tiers. This ADR changes the **rule**, not the enforcement tier.

## Consequences

- **Positive — gate trustworthiness.** The two required gates can no longer return opposite verdicts on a link form; the strict rule preserves the dead-file-reference gate's ability to catch a workspace-rooted `.md` link that masks a real 404, and makes the deploy-time and PR-time checkers agree.
- **Positive — GitHub fidelity.** The canonical rule is exactly GitHub's rendered-blob model, so a reader following a link in the browser and the checker verifying it now agree.
- **Cost — churn + a sanctioned root-anchor form.** 19 links in one governance template were rewritten to leading-`/`. Authors anchoring a link to the repo root must now write the leading-`/` form explicitly; a bare `core/…` from a non-root file is (correctly) a broken link.
- **Negative (bounded) — forward-protection is lightly tested.** Zero `/`-rooted links existed in the `release/` corpus at decision time, so `check-release-links.py`'s new `/`-rooted resolution is forward-protective rather than corpus-exercised. The parity is currently pinned on the `check-doc-links.py` side only — that checker's `--self-test` carries an in-script anti-fallback and `/`-rooted guard, whereas `check-release-links.py` has no self-test and no committed shared fixture exercises the two resolvers against one case set, so a regression in its `/`-rooted clause would surface only through a corpus link that depends on it.
- **Retained separation.** The ADR-009 rewrite-map CLI (`--from-path`/`--to-path`, EMIT-ONLY, asymmetry handling) is independent of the retired fallback and continues to operate unchanged.

## Reversibility

**CHEAP / Confidence HIGH.** The resolver change is a small diff on each checker (revertible directly); the 19-link template rewrite is a mechanical bare→leading-`/` substitution that reverses trivially. No data migration, no persisted state.

## Related ADRs

- **Supersedes in part [ADR-009](ADR-009-rewrite-map-cli-design.md)** — retires its Rule-2 V1/V2 prefix-table workspace-root fallback; leaves its rewrite-map CLI (Rules 1/3/4/5) in force.
- **[ADR-030](ADR-030-hook-registry-drop-in-with-generated-index.md)** — the hook-registry restructure whose workspace-rooted links passed `check-doc-links.py` but failed the dead-file-reference gate (45 broken links), the concrete incident motivating a single canonical rule.
- **[ADR-008](ADR-008-deploy-sh-per-module-array-design.md)** — sibling module-restructure tooling ADR; references the same primitive but is unaffected by the resolver change.
