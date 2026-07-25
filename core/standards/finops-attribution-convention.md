---
title: FinOps Usage Attribution Convention
purpose: The canonical session→work-item attribution convention for the Agent-FinOps usage store — the subagent→agent→session chain (in-transcript sidechains AND cross-file spokes), the ordered LOCAL-ONLY session→work-item resolver (issue-event key → branch-milestone → hub-state lineage → unattributed, with an opt-in network PR-resolve), the work-item-key format, the roll-up formula that honors the summation invariant with its count-once precondition, the coverage health metric, and the ground-truth correctness contract. Consumed by finops-usage-extractor (rollup-attribution.sh) and the downstream agent-finops-intelligence milestone.
type: standard
status: ACTIVE
source: ""
reversibility: MODERATE / MEDIUM confidence (the mapping heuristic is calibratable by the downstream calibration slice; the unattributed bucket makes the convention safe-by-construction — it never claims a grain it cannot deliver)
consumers: "finops-usage-extractor rollup-attribution.sh (producer); the agent-finops-intelligence milestone — estimation, reporting, calibration (all read the rollup + coverage records and this convention)"
---
<!-- reference-durability: allow-link -->

# FinOps Usage Attribution Convention

> Defines HOW a usage `session` record maps to its owning work item, and how subagent spend chains to its agent and session. The `rollup` and `coverage` RECORD SHAPES live in [`finops-usage-store-schema.md`](../schemas/finops-usage-store-schema.md) (v1.1.0); THIS doc owns the mapping ALGORITHM. The two concerns are split on purpose — the schema doc is the shape; this standard is the resolution.

## Purpose + Scope

The roll-up phase needs a session→work-item map. Local session data lacks an explicit work-item linkage: a session's `git_branch` is often a harness-auto `claude/*` / `agent-*` name (which does not parse to a work item), a `release/vX.Y-*` / `chore/vX.Y-stage-N-*` name (which encodes only the **milestone**, not a sub-task), or `null` (legacy). And because this platform's hub-spoke model spawns spokes as **separate session files**, the subagent→agent link crosses files — the substrate that would carry a session↔work-item edge at issue grain does not exist yet. This standard states the convention that resolves what is resolvable, buckets the rest fail-visibly, and never claims a grain it cannot deliver.

**Honest bottom line.** The design reliably delivers **milestone-grain** attribution from local data alone. It does **not** deliver reliable issue-grain (`#N`); issue-grain is **best-effort ONLY where a deterministic key exists** (a decision-event payload, or an opt-in PR resolve). Reliable issue-grain and a reliable hub-vs-spoke role split both require a hub-emitted spawn-ledger marker (the hub logging each spoke's worktree / session id ↔ work item at spawn) — an enhancement **deferred to the agent-finops-intelligence milestone**, out of this convention's scope.

## The attribution chain: subagent → agent → session → work-item

### Case (a) — in-transcript sidechains

An `isSidechain==true` record links to its spawning turn via `parent_uuid` **within one session file**; the store's `subagent` record already captures this. Its tokens are **already inside** `session.tokens` (the summation invariant) — a drill-down, never re-summed.

### Case (b) — cross-file spokes (this platform's hub-spoke model)

Hub-spawned spokes are **separate session files** → each is its own `session` record. Attribution targets the **work item** (not the spoke→hub parent link): a spoke session resolves to the same work item as its hub via the resolver below, and the roll-up sums `Σ session.tokens` over all sessions (hub + spokes) mapped to that work item. The subagent→agent hierarchy is NOT a correctness precondition for the total — and a reliable per-session hub-vs-spoke split is deferred (release-branch spokes share the hub's branch shape, so no local heuristic separates them). This is the critical realization: the work-item roll-up does not require resolving the spoke→hub PARENT link — only spoke→work-item.

## Session → work-item resolver (ordered, first-match-wins, LOCAL-ONLY by default)

The **default** resolver path reads only local data: the store, plus the local operator-instance hub-state surfaces ([`hub-session-continuity.md`](hub-session-continuity.md) Surface B = the pipeline event log; Surface C = the sessions log). **No network, no `gh`, no provider call** on the default path. This preserves two contracts: (1) "reconciled from local data alone", and (2) the store's **derived-cache determinism** — a rebuild-from-source must be idempotent, and a network PR/merge state is time-varying, so the default resolver never consults it.

**Multi-branch guard (sits ABOVE the resolver).** If `session.branch_switch == true` (the session's source records spanned >1 distinct `gitBranch`), the session is routed to a distinct `work_item_kind:"multi-branch"` bucket carrying the observed `git_branches[]` — it is **never** silently run through the branch tiers against a single collapsed branch. Absent/`false` (the graceful default, and the case when the extraction phase has not populated the field) ⇒ single-branch behavior, exactly as below.

For a single-branch session, first match wins:

| Tier | Rule | Grain | Determinism / source | `attribution_tier` |
|---|---|---|---|---|
| **T1 — issue-event key** (best-effort issue-grain) | The session emitted a `decision` / `gate-outcome` / `escalation` event whose Surface-B first-event `payload` carries `session:<composite>` where the composite's worktree component equals `basename(session.cwd)`, **and** that row's `subject`/`actor` names an issue `#N`, **and** the event `ts` ∈ `[started_utc, ended_utc]` → `#N` | issue `#N` | deterministic **where the key exists**; narrow (decision-emitting sessions only); fuzzy (worktree+time reconstruction, not id equality); LOCAL | `issue-event-keyed` |
| **T2 — release/chore branch** (RELIABLE milestone-grain — the default workhorse) | `git_branch ∈ {release/vX.Y-<slug>, chore/vX.Y-stage-N-<slug>, chore/vX.Y-<slug>}` → parse `vX.Y` → `milestone:vX.Y` | `milestone:vX.Y` | **deterministic; LOCAL-ONLY** (no join, no network) | `branch-milestone` |
| **T3 — hub-state lineage** (milestone-grain corroboration) | `basename(session.cwd)` matches a Surface-C `worktree` row under `<hub-state>/vX.Y/sessions.md` **and** `[started_utc, ended_utc]` falls inside that release's pipeline-event window → `milestone:vX.Y` | `milestone:vX.Y` | deterministic join where hub-state is present; LOCAL | `hub-state-lineage` |
| **T4 — unattributed** (TERMINAL) | no issue-event key, no parseable branch, no lineage hit (auto `claude/*` / `agent-*`, `git_branch:null`) → `unattributed` with an `attribution_basis` naming the reason | `unattributed` | **fail-visible by construction** | `unattributed` |
| **[OPT-IN] T-PR — fix/feat PR-resolve** (OFF by default; requires `--resolve-prs`) | `git_branch ∈ {fix/<slug>, feat/<slug>}` → merged-PR → closing-issue via `gh` → `#N` | issue `#N` | **heuristic; NETWORK; non-reproducible** → gated + stamped | `pr-resolved` |

**Ordering rationale.** T1 (finer issue-grain) precedes T2/T3 (milestone) because first-match-wins prefers the finer grain **where a deterministic key is present**; the overwhelmingly common outcome for release-work spokes is **T2 → milestone** (the reliable target). Among the milestone tiers, T2 (the session's own branch) precedes T3 (an inferred lineage join) because the branch is the stronger signal.

**T-PR is opt-in and fenced off from the default path.** It fires **only** when the operator passes `--resolve-prs` **and** `gh` is reachable. Absent either, `fix/*` / `feat/*` sessions degrade to **T4 `unattributed`** — never fail, never silently guess. Every T-PR-resolved row is stamped `attribution_tier: pr-resolved` **and** `reproducible: false`, so the coverage metric and downstream consumers can exclude or weight network-derived attributions. A `--resolve-prs` pass makes the store non-idempotent by construction; the `coverage` record's `pr_resolved_present: true` records that, so a later local-only rebuild legitimately differs (smaller issue coverage) without reading as drift.

## Work-item key format

`work_item` ∈ { `#N` (issue-grain, bare issue ref) · `milestone:vX.Y` (milestone-grain from a branch token) · `"unattributed"` · `"multi-branch"` }; `work_item_kind` disambiguates. This conforms to the [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) subject/version identifier convention (its `subject` column uses `#N` and its `version` column uses `vX.Y`) rather than inventing a parallel identifier scheme.

## Roll-up formula (honors the summation invariant)

`work_item_total = Σ session.tokens` over the sessions resolving to that work item, where a session's total is the four leaf integers `input + output + cache_creation.total + cache_read`. Subagent (sidechain) records are **never** added on top (already inside `session.tokens`). Cross-file spoke sessions are distinct `session` records → each is summed once.

**Count-once precondition (across the hub↔spoke file boundary).** `Σ session.tokens` is correct only if each unit of spoke spend is embedded in **exactly one** `session` record — either the hub session's whole-file total (as an in-transcript `isSidechain` subagent) XOR the spoke's own standalone `session` record — never both. On this platform, hub-spawned spokes run as separate session files, so the hub's `Task` spawn does not embed spoke spend in the hub's whole-file total; that is the property that makes the sum count-once. Should a future harness change make a spoke appear both as a sidechain inside the hub file and as its own standalone `session` record, the standalone record is authoritative and the overlapping sidechain contribution is excluded; the roll-up surfaces the collision in its `coverage` output.

## Correctness proof: ground-truth fixtures (primary), conservation (secondary)

The correctness contract is a **ground-truth labeled-fixture** check, NOT a conservation identity:

- **Ground-truth attribution (PRIMARY).** Each synthetic `session` fixture carries a **known** `(work_item, attribution_tier)` label in a sidecar oracle the resolver does not read. The resolver's per-session resolution MUST reproduce the known mapping, tier by tier (a `release/vX.Y-<slug>` fixture → `(milestone:vX.Y, branch-milestone)`; a decision-emitting fixture with a matching event-log payload → `(#N, issue-event-keyed)`; a `cwd`-joinable fixture with hub-state but an unparseable branch → `(milestone:vX.Y, hub-state-lineage)`; an auto-`claude/*` / null-branch fixture with no hit → `(unattributed, unattributed)`; a `branch_switch` fixture → `(multi-branch, …)`; and, in the opt-in suite, a `fix/<slug>` fixture with a stubbed merged-PR→issue → `(#N, pr-resolved)`). This is the check a wrong resolver **fails**.
- **Conservation (SECONDARY plumbing).** `Σ rollup.tokens` (including `unattributed` and `multi-branch`) `== Σ session.tokens` over all records, and per-row `rollup.tokens == Σ session.tokens over rollup.session_ids`. This is **necessary but NOT sufficient** — it holds for ANY assignment (including the degenerate "route everything to `unattributed`"), so it proves conservation, not attribution correctness. It is retained as an independent guard on the summation invariant, but it is not the correctness proof.

## Coverage metric + health threshold

Every roll-up run emits one `coverage` record (shape in the schema doc) — the run-level attribution health, so a healthy roll-up is distinguishable from one that bucketed most spend to `unattributed`. Its `health` enum keys on `unattributed_token_fraction` against this threshold:

| health | condition |
|---|---|
| `OK` | `unattributed_token_fraction ≤ 0.25` |
| `WARN` | `0.25 < unattributed_token_fraction ≤ 0.50` |
| `FAIL` | `unattributed_token_fraction > 0.50` |

**Grounding-honesty note.** This is a `[RECOMMENDED]` provisional default, **NOT an empirically-grounded canonicalization**: no usage distribution exists to calibrate against (data-hygiene forbids live extraction on the public repo, and there is no committed store). The threshold is explicitly **calibratable by the downstream calibration slice**, which consumes exactly the `tier_distribution` + `unattributed`-rate signals. It is recorded here as a proposed value, not a fabricated measurement.

## Cross-file linkage — what is reliably linkable vs unattributed

- **Reliably → milestone-grain:** any spoke whose `git_branch` is `release/vX.Y-*` / `chore/vX.Y-*` (T2, deterministic, local). Content spokes (engineering, dev-test, QA, execute, close) build on the release branch → this is the common case.
- **Reliably → milestone-grain (corroboration):** any session whose `basename(cwd)` joins a hub-state `worktree` row (T3).
- **Best-effort → issue-grain:** a decision-emitting session with a matching event-log payload (T1), or an opt-in PR resolve (T-PR).
- **Lands in `unattributed` (honest gap):** write-nothing auto-`claude/*` spokes with no hub-state worktree row and no unique temporal resolution. Fail-visible, never dropped.
- **Deterministic upgrade (deferred, out of scope):** a thin additive hub-emitted spawn-ledger marker — the hub logs each spoke's worktree / session id ↔ work item at spawn into a hub-state row — collapses the issue-grain gap and enables a reliable role split. It is a hub-session-continuity / hub-spoke-bridge change, not part of this convention's file set, and is routed to the agent-finops-intelligence milestone.

## Failure modes (summary — full 5-field entries live in the skill)

The skill's `SKILL.md` carries the full domain-specific failure-mode entries (5-field template). In brief, the load-bearing ones for attribution are: double-counting cross-file spokes against their session totals (mitigation: sum `session.tokens` over distinct `session_ids`; count-once at the file boundary); mis-parsing an auto `claude/*` branch as a work item (mitigation: only the T2/T-PR prefixes parse; everything else → `unattributed`); mis-allocating a branch-switching session to one collapsed branch (mitigation: the multi-branch guard above the resolver); a coverage-blind roll-up (mitigation: always emit the `coverage` record + the health enum); and heuristic/PR-resolved attribution presented as authoritative (mitigation: `attribution_tier` + `reproducible` on every row).

## Cross-references

| Reference | Relationship |
|---|---|
| [`finops-usage-store-schema.md`](../schemas/finops-usage-store-schema.md) | the `rollup` + `coverage` record SHAPES (v1.1.0); this doc owns the mapping ALGORITHM |
| [`hub-session-continuity.md`](hub-session-continuity.md) | the session-lineage substrate reused by T1 (Surface-B payload composite) and T3 (Surface-C `worktree` join); the composite `<worktree>__<iso>__<sha>` format |
| [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) | the subject/version/actor identifier convention that the work-item-key format conforms to |
| [`git-workflow.md`](../rules/git-workflow.md) | the branch-naming convention the branch tiers parse (`release/vX.Y-*`, `chore/vX.Y-*`, `fix/*`, `feat/*`, harness `claude/*` / `agent-*`) |

## Version History

| Version | Date | Change |
|---|---|---|
| 1.0.0 | 2026-07-25 | Initial — the ordered LOCAL-ONLY resolver (issue-event key → branch-milestone → hub-state lineage → unattributed) with an opt-in network PR-resolve; work-item-key format; roll-up formula with the count-once precondition; multi-branch guard; ground-truth-fixture correctness contract (conservation secondary); coverage health threshold; milestone-grain-reliable / issue-grain-best-effort / deferred posture. |
