<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-030 — Hook registry — per-hook drop-in sources + generated canonical-path index + completeness check
status: Accepted
date: 2026-06-19
release: 36-ci-gate-trustworthiness-and-parallel-pr-safety
deciders: "Workspace owner (rendered at the #18 Collective Review); design authored at Stage 5 Solutioning (deep architecture pass)"
tags: [architecture, hooks, security, registry, drop-in, generated-index, deploy-check, parallel-pr, cascade-conflict, drift-resistance, reversibility]
source_observations:
  - "Parallel-PR cascade-conflict class observed N=2 within one release (#18): the fs-boundary hook PR blocked behind the shell-injection hook PR, then the subagent-security PR blocked behind the fs-boundary restructure that bumped the 'The N Hooks' summary count. Every hook-adding PR edits multiple shared sections of the single ~32KB bypass-mode-readiness.md monolith (summary table row + a Rule Registry sub-table + an allowlist row + warn-mode wiring + a recovery note), so two concurrent hook PRs collide on the same file at merge."
  - "Live registry drift, three-way, observed at Stage 5 (commit 6ada20c): ground truth is 9 block-*.sh scripts. core/rules/bypass-mode-readiness.md says 'Seven... The 7 Hooks' (7 registry sub-tables; missing block-fragile-refs and block-skill-direct-edit); core/standards/subagent-security-posture.md says 'The 5 existing hooks' with a dead '§ The 5 Hooks' anchor; the machine-consumed core/settings.json.template correctly registers all 9. No deploy-check reconciles the doc registry against the hook scripts — which is precisely why the drift survived undetected."
  - "Repo drop-in precedents are pervasive (the house pattern): core/hooks/ is 9 block-*.sh scripts (one per hook); core/hooks/tests/ is 8 block-*.test.sh companion files (one per hook); core/ADRs/ is 22 ADR files + a hand-maintained README index; core/config/allowlists/ is 14 allowlist files (one per surface). The hook code is already a drop-in directory; only the hook documentation was a monolith."
---

# ADR-030 — Hook registry: per-hook drop-in sources + generated canonical-path index + completeness check

## Status

**Accepted.** The workspace owner rendered this option at the #18 Collective Review (2026-06-19), choosing it over the simpler D1 (per-hook split + hand-maintained thin index) and the minimum-lift D3 (monolith + anchored-append lint) because it eliminates **both** the cascade-conflict class the milestone exists to kill **and** the live 5/7/9 registry drift the architecture pass exposed. The four-issue release scope (#1101, #673, #18, #90) is locked. Two Stage-6 caveats were carried into Engineering from hub review and are honored in this ADR (see § Decision points 4 and 6).

## Context

`core/rules/bypass-mode-readiness.md` is a single ~32 KB file documenting the PreToolUse hook layer that makes it safe to run Claude Code in `bypassPermissions` mode. It carries shared structure: a `## The 7 Hooks` summary table, a `## Rule Registry` with per-hook sub-tables, a 7-row `## Allowlist Maintenance` table, `## Warn-Mode vs. Enforce-Mode`, `## Recovery Procedures`, `## Known Limitations`, and the `## Shakedown → Enforce Transition Checklist`. Every hook-adding PR edits **multiple** of these sections, so two concurrent hook PRs collide on the same file at merge. The issue records N=2 within one release.

Beyond the cascade *symptom*, the monolith has a deeper defect surfaced at Stage 5: it is a hand-maintained registry that **has already drifted, three ways at once.** Ground truth is **9** `block-*.sh` scripts. The doc says "The 7 Hooks" (7 sub-tables). `subagent-security-posture.md` says "The 5 existing hooks" with a `§ The 5 Hooks` anchor that does not exist. The machine-consumed `settings.json.template` correctly lists all 9. No deploy-check reconciles the prose registry against the scripts — which is exactly why the drift survived. The hand-maintained registry drifted; the one-entry-per-file machine registry did not.

The decisive design constraint that bounds the blast radius: both the deploy-time link gate (Check 14) and the PR-time `link-check.yml` invoke the same primitive (`core/deploy/tools/check-doc-links.py`), and that primitive **validates the file-path portion of a markdown link and skips pure `#`/`§` anchors natively.** The `§ <section>` text in the corpus is prose *preceding* the link, not a URL fragment. Therefore a restructure that **retains the index file at the canonical path** `core/rules/bypass-mode-readiness.md` keeps every inbound link's path-target alive — the real rewrite surface is 2 deep-anchor prose references, not the 66 inbound files / 128 occurrence-lines the planning estimate assumed.

The ownership boundary (Stage-6 caveat 1, load-bearing): the "7 Hooks" framing is deliberately scoped to the **7 bypass-mode security hooks**. The other two `block-*.sh` scripts are owned by their own discipline docs: `block-skill-direct-edit` (rules BLOCK-SKILL-EDIT-001..002) is owned by `core/standards/canonical-skill-structure.md` (operationally surfaced in `core/rules/skill-deployment.md`); `block-fragile-refs` (rules BLOCK-FRAGILE-REF-001..004) is owned by `core/standards/reference-durability-standard.md`. They are NOT bypass-mode hooks and do NOT move into `core/rules/bypass-mode-readiness/`. The completeness check reconciles each script against its **declared owner**, not a forced single-file bijection.

## Decision

Restructure the bypass-mode hook registry as a **drop-in directory of per-hook source fragments + a generated canonical-path index + a completeness check that reconciles every hook script against its owning doc**:

1. **Per-hook source files** at `core/rules/bypass-mode-readiness/<hook>.md` — one per **bypass-mode security hook** (the 7: `block-credential-reads`, `block-destructive`, `block-egress`, `block-fs-boundary`, `block-mcp-writes`, `block-rm-prefer-trash`, `block-shell-injection`), each carrying that hook's matcher, scope, Rule Registry sub-table, path-resolution notes, and hook-specific posture/limitations.

2. **Cross-cutting sections** authored once as source fragments (`_header.md` = Purpose; `_cross-cutting.md` = the Absolute-Path-Aware Verb Anchor that spans three hooks, `CLAUDE_HOOK_BYPASS — Escape Hatch`, `Allowlist Maintenance`, `Warn-Mode vs. Enforce-Mode`, `Recovery Procedures`, `Known Limitations`, `Shakedown → Enforce Transition Checklist`, `Related`). These are not per-hook and stay singular. Fragment files are name-prefixed with `_` so the generator and the completeness check exclude them from the per-hook set.

3. **The canonical `core/rules/bypass-mode-readiness.md` is generated** at deploy time by `core/deploy/tools/build-hook-registry.py` (stdlib-only, matching the `check-doc-links.py` posture): header fragment + an **auto-generated `## The Hooks` table** (one row per per-hook source, so it can never undercount) + the per-hook bodies in deterministic (lexicographic) order + the cross-cutting fragments. The index is **committed** (the repo ships the rule file as a consumed artifact) and kept fresh by a regenerate-and-diff check.

4. **A new hook-registry completeness check** (`deploy.sh --check`) asserts that every `core/hooks/block-*.sh` maps to its **correct owning doc**, driven by an explicit ownership manifest: the 7 bypass-mode hooks ⇒ a `core/rules/bypass-mode-readiness/<hook>.md` source ⇒ a row in the generated index; `block-skill-direct-edit` ⇒ `core/standards/canonical-skill-structure.md`; `block-fragile-refs` ⇒ `core/standards/reference-durability-standard.md`. A script with no owner, or a bypass-mode source with no script, FAILS the check. This is the piece that makes 5/7/9 structurally impossible going forward (Stage-6 caveat 1 honored — no forced single-file bijection). Ships **warn-mode-initial** (advisory) per the Shakedown → Enforce Transition Checklist precedent.

5. **An index-freshness check** (`deploy.sh --check`, the `verify-ci` pattern): regenerate the index into a temp file and `diff` against the committed one; a non-empty diff FAILS ("regenerate + commit"). The generator is deterministic, so this is **always-enforce** at the deploy surface — a stale committed artifact must never ship green.

6. **The `§ Shakedown → Enforce Transition Checklist`, `Known Limitations`, and the other cross-cutting sections remain at the canonical path** inside the generated index, so the ~38 inbound `§ Shakedown` references and the bulk of the 66 inbound files stay green (link primitive validates path-not-fragment). The committed generated index is honestly still a shared file both concurrent PRs touch (Stage-6 caveat 2): the win is **deterministic auto-resolution** (regenerate from sources) + **drift-elimination**, NOT literal zero-shared-touch — a hook PR no longer hand-edits the shared registry; the generator writes the index row.

## Consequences

- **Cascade class eliminated.** A new bypass-mode hook adds its own source file under `core/rules/bypass-mode-readiness/`; the shared index row is **generated**, not hand-edited. Two concurrent hook PRs touch only their own new source fragments. The residual shared surface is the committed generated index, which is deterministically reproducible from sources and therefore auto-resolvable rather than a hand-merge contention point.

- **Drift eliminated.** The completeness check fails any PR that adds a hook script without registering it against an owner doc; the index-freshness check fails any stale committed index. The 5/7/9 condition becomes unreachable. (As a fast-follow, the pre-existing `subagent-security-posture.md` "5 hooks" prose is corrected in-band by this release's xref rewrite.)

- **Tooling cost (the honest extra).** One generator script + two new deploy-checks (completeness + index-freshness) over the simpler D1. Justified because D1's hand-maintained thin index re-creates the exact failure that is live in the tree today; paying for a check once is cheaper than re-litigating drift every few releases.

- **Check 9 (mirror-pair) gains a directory-walk** over `core/rules/bypass-mode-readiness/*.md` versus the operator-instance `~/.claude/rules/bypass-mode-readiness/` mirror, preserving SKIP-on-missing (the public repo, where `.claude/rules/` is operator-instance and absent, stays a clean SKIP) and the warn-mode posture. The index-file pair entry stays a byte-diff on the committed generated file.

- **Generator-absent fallback fails loud.** If `/usr/bin/python3` or the generator is absent, the index-freshness check flags rather than silently passing a potentially-stale index — the same fail-loud posture as the other content checks.

## Alternatives Considered

- **D1 (per-hook split + hand-maintained thin index).** Eliminates the cascade but **not** the drift: a thin index is hand-maintained, so a hook can still be added without an index row and nothing catches it. This is the failure mode already live (the monolith's own table is a hand-maintained index that drifted to 7). Fixes the symptom the milestone names and leaves the disease the evidence exposes. Defensible only if the operator explicitly accepts ongoing manual-registry drift risk for zero new tooling — the operator chose otherwise.

- **D2 (generated index, no completeness check).** A generated index cannot undercount existing sources, but nothing forces a *source file* to exist for each script, so a hook added with no doc source still goes undocumented. The completeness check is the missing half.

- **D3 (monolith + anchored-append lint).** Lowest lift, CHEAP reversibility, Check 9 untouched — but by the issue body's own admission only *dampens* conflict probability (same-anchor appends still collide), and does **nothing** for drift (it is the status quo that produced 5/7/9). The minimum-lift fallback, not the right architecture.

- **A2 (per-hook docs co-located at `core/hooks/<hook>.md`).** The purest drop-in (doc beside script beside test), and it earns the same completeness guarantee. Rejected because the content is a **governed runtime rule humans and Claude navigate under `core/rules/`**; relocating rule prose into `core/hooks/` worsens discoverability and has no clean `.claude/rules/` mirror story. The drop-in *discipline* is adopted; the drop-in *location* stays in `core/rules/`.

- **B-none (enumerate the directory, no index).** Lowest discoverability; fails the human+agent navigability constraint and breaks the ~38 `§ Shakedown` inbound refs (no canonical-path file to anchor them). Rejected.

## Reversibility

**MODERATE.** Undo = concatenate the per-hook + cross-cutting fragments back into one static monolith at `core/rules/bypass-mode-readiness.md` and delete the generator + two checks + the Check 9 directory-walk; mechanical and fully git-recoverable. **Confidence: HIGH** on the diagnosis (the three counts are directly grepped; the missing check is confirmed by absence) / **MEDIUM-HIGH** on the recommendation over plain D1 (the increment is one generator + two ~40-line checks; the live 5/7/9 drift is the justification).

## Related ADRs

- [ADR-005](../../release/ADRs/ADR-005-append-pattern-aware-cross-pr-contention-scoring.md) — append-pattern-aware cross-PR contention scoring; the contention-class lens this restructure resolves for the hook-registry file specifically.
- [ADR-007](ADR-007-core-module-boundary.md) — core-module boundary; the bypass-mode hook layer is core-owned infrastructure consumed by both consumer modules.
- [ADR-029](ADR-029-memory-corpus-ssot-boundary.md) — corpus-SSOT precedent for the "one authoritative surface, generated/derived views, drift-detection gate" shape this ADR applies to the hook registry.
