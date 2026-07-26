<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: ADR-096 — FinOps usage store — operator-local data home, tracked-schema authority, git-ignore enforcement
status: Accepted
date: 2026-07-25
release: agent-finops-foundation (v3.96)
deciders: "Workspace owner (ratified D-DataHome option A at the Stage-4 D-Gate, 2026-07-25; carried unchanged through the r2 Collective Review scope-lock, 2026-07-25). Design resolved at #3909 Stage-5 Solutioning (r1 + r2 revision)."
tags: [architecture, finops, token-spend, data-store, schema, git-ignore, operator-instance, security, reversibility, derived-cache]
source_observations:
  - "#3909 (C1) establishes the FinOps data foundation: extract per-session/per-subagent token counts from local Claude Code session data into an operator-local, git-ignored store, path resolved from config, no hardcoded operator path. On a flat-rate Max plan the local data is authoritative; a provider connector is optional plan-gated enrichment only."
  - "#3944 Stage-5 Solutioning: local session data exposes EXACT per-turn token counts (message.usage), so the store is a derived cache (a deterministic projection of source transcripts), NOT an audit log — the sqlite-index-schema.md precedent. Source transcripts remain the source of truth; the store may be rebuilt from source at any time."
  - "#3944 r2 Collective Review (operator ADJUST->lean): adversarial design review accepted 3 Major fixes pre-freeze. Load-bearing for this ADR: the git-ignore control was fail-OPEN (a custom store path resolving inside the repo but not matching a .gitignore pattern would commit on a PUBLIC repo). The fix is a resolve-time git check-ignore runtime guard that makes the fail-closed property enforced, not asserted."
---

# ADR-096 — FinOps usage store: operator-local data home, tracked-schema authority, git-ignore enforcement

## Status

**Accepted.** Authored at #3909 Stage 6 per the Stage-6 ADR-authoring precedent (ADR-091 / ADR-031). The D-DataHome decision (option A) was ratified by the workspace owner at the Stage-4 D-Gate (2026-07-25) and carried unchanged through the r2 Collective Review scope-lock (2026-07-25); the r2 revision strengthened the git-ignore consequence (resolve-time guard) without changing the decision. References issues as bare `#N` with the file-level `allow-issue-ref` marker above.

## Context

Agent token-spend FinOps (parent epic #1494) needs a durable per-session and per-subagent usage store. The source data — local Claude Code session transcripts under `${CLAUDE_CONFIG_DIR:-$HOME/.claude}/projects/**/*.jsonl` — carries `gitBranch`, `cwd` (an operator home path), and work-item identifiers, all **PII-adjacent on a PUBLIC repo**. The store is consumed by the sibling slice C2 (#3910, attribution/roll-up) and by the downstream `agent-finops-intelligence` milestone (estimation, reporting, calibration), so **schema stability is the #1 risk** — an unstable schema forces rework across two milestones.

Two questions must be answered together: (1) WHERE the store lives and HOW its path resolves without a hardcoded operator path; (2) WHAT owns its schema and HOW the git-ignore control is guaranteed. A naive static-`.gitignore`-only control fails OPEN — a custom store path that resolves inside the repo but matches no ignore pattern would commit usage data on a public repo.

## Decision

1. **Store = a derived JSONL cache** at `<OPERATOR_INSTANCE_FINOPS_STORE_PATH>/usage.jsonl`, default `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/finops`, resolved from `operator.toml [paths].operator_instance_finops_store_path` (override if set, else the default). It is a deterministic projection of the source transcripts, which remain the source of truth — NOT an audit log. Because it is a derived cache, **no `.template` seed file is shipped** (the divergence from seeded-then-mutated state files such as the hub-state templates); the schema doc plus the extractor fully define it, and the extractor writes the `meta` header on first run.

2. **Schema authority = a tracked K1 document** `core/schemas/finops-usage-store-schema.md`, **frozen at v1.0.0** with the `meta` / `session` / `subagent` record kinds and their field sets (`provider` reserved-optional). C2 (#3910) extends it **additively** to v1.1.0 with the `rollup` record kind, touching no frozen v1.0.0 field. An additive change is a minor bump; a breaking change to a frozen kind is a major bump plus a downstream coordination event.

3. **Git-ignore = a fail-closed exfil control, enforced at resolve time, not asserted.** The store's canonical home is already git-ignored by the existing `personal/` + `pmo-instance/` patterns, plus defensive `.gitignore` stems for the finops store. Beyond those static patterns, the extractor runs a **resolve-time `git check-ignore` guard before any write**: if the resolved store path falls inside a git repository but is NOT git-ignored there, the extractor refuses to write (a dedicated non-zero exit). A store resolving outside any repository (the default case — the workspace `personal/` tree is a sibling of the repo) is not committable and proceeds. This converts git-ignore from a passive assertion into an active write precondition — the fail-closed property is **enforced**, not merely asserted by the static `.gitignore` alone.

This mirrors the tracked-schema / git-ignored-instance split used for hub-state (per the public-repo-vs-operator-instance taxonomy), diverging only by shipping no `.template` seed because the store is a derived cache rather than seeded-then-mutated state.

## Alternatives Considered

- **Reuse `<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>`** (the evals/results home) — rejected: conflates runtime FinOps spend with eval/pipeline telemetry (different lifecycle + consumer).
- **A new top-level git-ignored dir outside `pmo-instance/`** — rejected: breaks the established `personal/pmo-instance/<stem>/` operator-instance convention.
- **A markdown-table store or a SQLite store** — rejected (D-StoreFormat): a markdown table is awkward for nested token dimensions and heterogeneous record kinds; SQLite adds a runtime dependency + wrapper for single-operator-PMO scale, the same reason an external store was rejected for hub-state continuity. JSONL (one record per line, `record`-discriminated) matches the two existing operator-instance run-logs and extends additively for C2 with zero disturbance to existing lines.
- **Static-`.gitignore`-only exfil control** (the r1 design) — rejected by the r2 adversarial review: fail-OPEN for a custom in-repo store path that matches no pattern. Replaced by the resolve-time `check-ignore` guard above.

## Consequences

- **Positive:** the path is config-parameterized (no hardcode, satisfying the no-hardcoded-operator-path AC); one schema home owns the contract; the security control is fail-closed by construction (the runtime guard refuses an unignored in-repo store, so usage data carrying branch/`cwd`/work-item identifiers cannot commit on the public repo).
- **Negative:** a schema-freeze checkpoint gates C2 (foundation-before-skill-core serialization); a breaking field change becomes a major bump plus a downstream coordination event across the `agent-finops-intelligence` consumers.
- **Reserved-but-real cost signal:** cache-write tier split (`cache_creation.{total, ephemeral_1h, ephemeral_5m}`) and `service_tier` are folded into v1.0.0 **pre-freeze** (r2 PR-2), so the cost-determining dimensions present at the source are not discarded and do not force a post-freeze coordination event.
- **Bounded residual:** the store legitimately holds `cwd` home paths, so the no-hardcoded-path AC grep scopes to module SOURCE, not the git-ignored store data; redaction-on-export is out of scope (noted, not built — relevant only if the store is ever exported).

## Reversibility

**MODERATE / Confidence HIGH.** Additive net-new schema + config token + skill; content-only. A single `git revert -m 1` of the release merge removes the surface with no data migration; the operator-local store is operator-deletable (`rm -rf "$STORE"`). The MODERATE tier reflects that the frozen schema propagates into C2 and the downstream `agent-finops-intelligence` milestone — the v1.0.0 freeze plus additive-only extension is the mitigation.

## Related ADRs

- ADR-031 — autonomy-ceiling unified payload-triggered hook (the Stage-6 ADR-authoring + own-lifecycle precedent this ADR follows).
- ADR-046 — roadmap-instance in-repo home (the tracked-folder / git-ignored-instance "analysis-workspace" pattern the operator-instance store home echoes).
- D-AttributionConvention (C2 #3910) is authored as its own ADR at C2's Stage 5 — one decision per ADR (the Stage-4 combined-ADR assumption was refined at Stage 5); this ADR owns D-DataHome only.
