---
title: C3 — Path-B External Sync + Evidence-Gate Close-Proposal
purpose: Declares the scheduled Path-B external-sync sweep — MCP read-poll of the configured ticketing/KB/Smartsheet adapters, snapshot-diff against persisted state, tracker-reconciliation proposals, and Evidence-Gate close-PROPOSALS (Context-Decided → Context-Closed) — clamped to the automation_level ceiling. Wiring spec only — extends the existing OPERATIONS.md Daily Processing Cycle step-9 External Sync with a scheduler, a persisted snapshot, and the Evidence-Gate close path; READ/poll external + LOCAL-tracker-write only.
type: standard
status: ACTIVE
consumers: "mcp__scheduled-tasks (the registration target that runs the sweep); OPERATIONS.md Daily Processing Cycle step-9 External Sync (the step this sweep extends with a scheduler + snapshot + Evidence-Gate close path); the configured ticketing/KB/Smartsheet MCP adapters (read-polled)"
composes_with: [depersonalization-spec.md, ../disciplines/context-lifecycle-model.md, ../specs/autonomy-tiers.md, ../governance/OPERATIONS.md]
reversibility: MODERATE (spec + 2 path fields + 2 token rows + consumer registration) / Confidence HIGH — git revert restores prior state; the operator-instance snapshot/run-log are runtime artifacts whose post-revert absence is harmless (cold-start re-seeds); no external-system state is ever mutated, so there is no external rollback surface.
---

<!-- repo-integrity: allow-issue-ref -->

# C3 — Path-B External Sync + Evidence-Gate Close-Proposal

> Reversibility: MODERATE / Confidence: HIGH. The run-record schema (§5) is the load-bearing contract the C4 sweep-digest/heartbeat consumer binds to — do NOT change its field set after this spec ships without re-touching that consumer.
> Consumed by: the C4 sweep-digest/heartbeat, which reads the latest run-record per sweep (last-run / counts / failures) and rolls `proposals_held` into its "actions proposed but held" digest block.
> Extends: `core/governance/OPERATIONS.md` §Daily Processing Cycle step 9 (External Sync) — adds the scheduler + persisted snapshot + Evidence-Gate close path that step 9 lacks today.

## 1. What C3 adds (the delta over step-9 External Sync)
Step-9 External Sync today is a synchronous, in-cycle pull with no persistence and no scheduler
("Jira MCP pulls ticket statuses; Confluence MCP checks for drift in FDDs/RAID logs").
C3 adds, as one scheduled fan-out sweep:
- **(a) a schedule** — run the poll independent of the manual daily cycle (§7).
- **(b) a persisted snapshot** — so "what changed since last run" is computable (§3).
- **(c) a diff** — turning raw external state into drift records (§4).
- **(d) reconciliation proposals** — routed to the existing consolidated-update surface (§4).
- **(e) Evidence-Gate close-proposals** — external-Done → proposed close, treating the external
  status as qualifying evidence (§5–§6).

C3 invents no new approval surface, no new evidence vocabulary, and no new state machine — it
feeds the surfaces that already exist (Tracker Manager step 10 → User Approval step 11; the
Evidence Gate; the Context Lifecycle states).

## 2. Poll set (per-adapter, degrade-gracefully)
Read the configured adapters from `operator.toml [adapters]` and poll ONLY those that are
configured AND reachable. An unconfigured or unreachable adapter is a recorded run-record
outcome (a `skipped`/`reachable:false` row), never a hard failure that aborts the sweep.

| Adapter | Configured by | Poll via (MCP read verbs only) |
|---|---|---|
| Ticketing (Jira) | `[adapters].ticketing` includes Jira (`jira+github` / `gitlab+jira`) | live Atlassian MCP — `searchJiraIssuesUsingJql` (status pull for tracked keys) / `getJiraIssue` (per-key detail) |
| KB (Confluence) | `[adapters].kb` selects Confluence (future selector) | live Atlassian MCP — `getConfluencePage` / `getConfluencePageFooterComments` (FDD/RAID drift — the existing step-9 "Confluence MCP checks for drift" behavior) |
| Smartsheet | per-project `co_management_smartsheet_id` present (`dual_framing_enabled: true`; `core/schemas/project-schema.md`) | live Smartsheet MCP — `get_sheet_summary` / `get_columns`, ONLY when a grid is configured |

**Smartsheet is not yet an `[adapters]` selector** — `operator.toml [adapters]` declares
`repo_host`/`ticketing`/`kb`/`ai_tool` only; Smartsheet appears solely as the per-project
`co_management_smartsheet_id` field (co-management-gated). C3 therefore polls Smartsheet only when a grid is
configured; absent config → a run-record `skipped: smartsheet (no grid configured)` row.
A first-class `[adapters].smartsheet` selector is out of C3 scope (a separate adapter-config
change). The poll set degrades per-adapter so C3 ships against the live adapter set without
blocking on a config-schema change.

## 3. The snapshot artifact (poll-state persistence)
- **Format:** JSON. One object per polled external entity, keyed by stable external ID, carrying
  `{ external_id, source_adapter, status, last_modified, polled_at }`. JSON (not markdown)
  because the diff is a structural field-compare, not a prose read — matching the repo's
  structured-state convention (config is TOML-parsed; the lifecycle machine is field-typed).
- **Location:** operator-instance path token `<OPERATOR_INSTANCE_EXTERNAL_SYNC_SNAPSHOT_PATH>`
  (per `core/standards/depersonalization-spec.md` §4). Canonical default:
  `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/external-sync/snapshot.json` (gitignored).
  Override: `operator.toml [paths].operator_instance_external_sync_snapshot_path`
  (empty → default; non-empty → verbatim). **Operator-instance, never git-tracked** — it holds
  live external data (Jira keys, statuses) which must not enter the public repo (self-containment /
  no-PII discipline); same `.gitignored` `personal/pmo-instance/` tree the hub-state, roadmap,
  and inbox tokens already use.
- **Lifecycle:** overwritten last-write-wins at the END of each successful sweep, AFTER the diff
  is computed, so the next run diffs against the most recent observed state. A first run with no
  prior snapshot is a **cold-start**: no diff, snapshot seeded, run-record notes
  `cold-start: snapshot seeded, N entities`.

## 4. The diff + reconciliation proposal
**Diff (pure, no side effects):** load the prior snapshot → for each polled entity compare
`status` (and `last_modified`) old-vs-new → emit one drift record per changed entity:
`{ external_id, source_adapter, field, old_value, new_value, observed_at }`. New entities
(present now, absent in snapshot) and disappeared entities are drift sub-types. The diff is the
shared input to BOTH the reconciliation proposal (this section) and the Evidence-Gate close path (§5–§6).

**Reconciliation proposal:** each drift record becomes a *proposed* tracker reconciliation routed
to the EXISTING consolidated-update surface — `OPERATIONS.md` §Daily Processing Cycle step 10
(Tracker Manager consolidated change summary: "what's changing, where, why, evidence") → step 11
(User Approval). C3 does NOT invent a new approval surface. The proposal carries the drift record
as its `evidence` field, shaped to the Evidence-Gate `Example Evidence` idiom, e.g.
`"Jira PROJ-123: In Progress → Done [observed 2026-06-19 via Atlassian MCP]"`.

## 5. The run-record (failure-visibility producer contract)
Every sweep run — success, error, or empty — appends ONE run-record so a silent no-op is
impossible.

```
Sync run-record (one per scheduled sweep):
  run_id: <ISO-8601 UTC start>
  sweep: "external-sync-path-b"                  # the discriminator the C4 digest reads (REQUIRED — first-class field)
  status: ok | partial | error                   # partial = >=1 adapter failed, >=1 succeeded
  adapters: [ { name, reachable: bool, polled: N, drift: N, skipped_reason? } ]
  drift_total: N
  proposals_emitted: N
  auto_closed: N                                  # Tier-2 in-scope only
  proposals_held: N                               # Tier-1 / out-of-scope
  errors: [ "<adapter>: <message>" ]
  empty: bool                                     # true = ran, found zero drift (distinct from "did not run")
  finished_at: <ISO-8601 UTC>
```

- **`sweep` discriminator (REQUIRED):** the run-record MUST carry the literal
  `sweep: "external-sync-path-b"` as a first-class field. The C4 sweep-digest/heartbeat reads it
  to attribute each run-record to its producer sweep and to keep the two run-logs distinct
  (C3's `external-sync/run-log.jsonl` vs. the Path-A intake sweep's `ambient-intake/run-log.jsonl`).
  This field is the cross-card discriminator — do not drop or rename it.
- **Location:** operator-instance path token `<OPERATOR_INSTANCE_EXTERNAL_SYNC_RUNLOG_PATH>`
  (per `core/standards/depersonalization-spec.md` §4). Canonical default:
  `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/external-sync/run-log.jsonl` (append-only JSONL;
  gitignored; same instance tree as the snapshot). Override:
  `operator.toml [paths].operator_instance_external_sync_runlog_path` (empty → default;
  non-empty → verbatim).
- **The `empty` flag is the anti-silent-failure seam:** it distinguishes "sweep ran and found
  nothing" from "sweep did not run" (absence of a fresh `run_id`) — the distinction the C4
  heartbeat requires to tell RAN-EMPTY from MISSED.
- **Consumer:** the C4 sweep-digest/heartbeat reads the latest run-record per sweep (last-run /
  counts / failures) and rolls `proposals_held` into its "actions proposed but held" digest block.
  C3 is the **producer**; C4 is the **consumer** — the field set above is the frozen C3↔C4 contract.

## 6. Evidence-Gate close-proposal (external-Done → *proposed* close)
**Trigger:** a drift record where a **blocking** external ticket transitions to a Done-class status
(`Done` / `Closed` / `Resolved` — the adapter's terminal states), AND a local waiting item is
blocked-by that external ticket.

**The close path (cites `OPERATIONS.md` §Evidence Gate for Closing Items):** the Evidence Gate
already names the qualifying-evidence shape — a **Blocker** closes on "Resolved OR mitigation
approved" with example evidence "Jira: ticket moved to In Progress". C3 makes the **Done external
status the qualifying evidence** and *proposes* the close. It does not invent a new gate; it
supplies the gate's evidence automatically and routes a close proposal.

**Evidence-Gate close record (mirrors the Evidence-Gate `Item Type | Closure Requirement |
Example Evidence` row shape):**
```
Evidence-Gate close record:
  item: <local tracker item id>            # the waiting item proposed for close
  item_type: Blocker | Action | Decision | Retest Queue
  closure_requirement: <verbatim from OPERATIONS.md §Evidence Gate row>
  qualifying_evidence: "<adapter> <external_id>: <prev_status> -> <Done-class status>"
  evidence_source: <adapter MCP server> (read verb: <getJiraIssue|...>)
  observed_at: <ISO-8601 UTC>
  proposed_transition: Context-Decided -> Context-Closed
  autonomy_disposition: PROPOSAL (held) | AUTO-CLOSED (bounded_auto, Tier-2, in cascade_scope)
```
`closure_requirement` is copied verbatim from the matching Evidence-Gate row; `qualifying_evidence`
reuses the existing `"<source>: <observation>"` string idiom so the auto-generated evidence is
indistinguishable from a hand-entered Daily-Status-Log entry. Both `proposed_transition` and the
evidence shape are CITATIONS of existing canon, not new vocabulary.

## 7. State transition + Document-Tier gating (the safety clamp)
**Transition (object-typed, verbatim from `core/disciplines/context-lifecycle-model.md` §2):** the
close moves the item `Context-Decided → Context-Closed`. §2 fixes the semantic C3 must honor: this
is the ONE forward transition that "requires Evidence-Gate-qualifying evidence (Jira API match,
transcript content match, etc.)" and "Evidence detection can be automated; closure write is a
Document Tier 1 / 2 mutation." C3 implements exactly that split — **detection automated** (the
diff + Evidence-Gate match), **closure write gated** by Document Tier:

- **Document Tier 1 items** (RAID Log, FDDs, Project Plan — stakeholder-facing): the close is
  **always a proposal**, never auto-executed, at ANY `automation_level`. RAID-close is a Tier-1
  stakeholder write that never auto-closes per `core/specs/autonomy-tiers.md` §Irreducible Human
  Tasks (and OPERATIONS.md: RAID "never auto-closes"). Even at `bounded_auto` the proposal is HELD.
- **Document Tier 2 items** (Daily Status Log carry-forward, operational-tracker rows — internal):
  may **auto-close** ONLY when (a) `automation_level = bounded_auto` AND (b) the item sits inside
  the declared `cascade_scope`. Otherwise → proposal.

## 8. Clamp to automation_level (the C0 keystone)
Every C3 close + reconciliation action computes `effective = min(automation_level, per-action max)`,
where `automation_level` is read from `operator.toml [automation].automation_level` (the C0 dial;
enum `off` / `recommend` / `bounded_auto`) and `per-action max` is the action's Autonomy Tier
ceiling per `core/specs/autonomy-tiers.md`:

| Action | per-action max (Autonomy Tier) | At `off` | At `recommend` | At `bounded_auto` |
|---|---|---|---|---|
| Reconciliation proposal (drift → tracker) | Tier 1 (Recommend) | nothing surfaced | propose (surface for approval) | propose (still Tier-1-capped) |
| RAID / Document-Tier-1 close | Tier 1, irreducible (never auto) | nothing | propose | propose (HELD — never auto) |
| Document-Tier-2 item close, inside `cascade_scope` | Tier 2 (Bounded Auto) | nothing | propose | AUTO-CLOSE |
| Document-Tier-2 item close, outside `cascade_scope` | Tier 1 (descends per autonomy-tiers) | nothing | propose | propose (descended to Tier-1) |

The named fixture: at `bounded_auto`, a Tier-1 RAID close is HELD as a proposal while a Tier-2
in-scope item is AUTO-CLOSED — both behaviors fall straight out of the `min()` clamp + the
Document-Tier gate (§7). The dial is **advisory/soft until the C5 PreToolUse enforcement hook**
(which ships warn-mode-initial in this same release and is hard-enforced after the operator flips
it post-shakedown); C3 self-limits regardless of enforcement posture.

## 9. MCP write constraint — the design invariant (READ/poll + LOCAL-write only)
**C3 is READ/poll external + LOCAL-tracker-write only. It NEVER writes to an external system.**
This is a hard design invariant, stated so a future revision cannot silently re-open the exfil/gate
surface:
- **External side = reads only.** All external interaction uses `get*`/`search*`/`list*`/`browse*`/
  `find*` read verbs. These do NOT match `core/hooks/block-mcp-writes.sh`'s write-verb pattern
  (`create`/`edit`/`update`/`delete`/`add`/`transition`/…) → BLOCK-MCP-001 never fires for C3.
- **Why not write back:** writing a status back to Jira (`transitionJiraIssue`) or a row to
  Smartsheet (`update_rows`) would (a) trip BLOCK-MCP-001 (those verbs ARE in the write set),
  (b) require the live MCP server IDs in `core/mcp-write-allowlist.txt` (they are NOT — it is a
  test allowlist whose `atlassian` server segment does not match the live UUID server IDs), and
  (c) invert the data-flow (external systems would become the source of truth the operator's
  trackers are reconciled against). C3's job is "external reality flows INTO trackers," not the
  reverse.
- **Local side = local-tracker writes + local-file writes** (the snapshot + run-log), gated by
  Document Tier + the C0 clamp (§7–§8). These are not `mcp__*` write tools, so the MCP write-gate
  is orthogonal to them.
- **Egress invariant (parent AC):** the sync runs over the sanctioned **governed MCP channel**, not
  Bash/WebFetch. `core/hooks/block-egress.sh` matches only the Bash and WebFetch tools, so polling
  via MCP read tools is the non-blocked channel the AC requires.

**If a future capability genuinely needs external write-back**, it is a *separate* governed change:
a new Issue + plan + the specific live-server write verbs added to `core/mcp-write-allowlist.txt`
via the allowlist-add tool. That is explicitly out of C3 scope — recorded so the boundary is not
silently crossed.

## 10. Scheduler surface + thin-bootstrap registration
- **Scheduler:** C3 declares the sweep as a scheduled invocation on the platform's existing
  scheduled-task surface (the same operator-instance, Layer-2, git-ignored mechanism the
  `platform-health` scheduled tasks use). C3 introduces no new scheduler primitive. Cadence is
  operator-configurable; default once daily, aligned to the daily-processing rhythm. The
  registration is non-git MCP install-root state — recorded as a Stage 12 deploy-log line item;
  rollback is deregistration (`enabled:false` or task delete), NOT `git revert`.
- **Thin-bootstrap prompt (the registration is a delegator, not a contract copy):** the scheduled
  task's `prompt` is a THIN BOOTSTRAP that delegates to THIS tracked spec — it does NOT inline the
  sweep contract. The full sweep behavior lives here (§1–§9); the registration only points at it,
  so the registration cannot drift away from the tracked source. Bootstrap shape (illustrative):
  > "Run the Path-B external-sync sweep per `core/standards/c3-external-sync-path-b.md`: poll the
  > configured `[adapters]`, diff against the snapshot, emit reconciliation + Evidence-Gate
  > close-proposals clamped to `automation_level`, and append the run-record. READ/poll + local
  > write only."
- **Re-registration deploy step:** because the bootstrap references the spec rather than copying
  it, the bootstrap text stays small and stable — but any change to the bootstrap wording or the
  spec path MUST be followed by re-registering the scheduled task so the delegator stays in sync.
  The deploy/close checklist carries an explicit **"re-register the `external-sync-path-b`
  scheduled task"** step for this reason (alongside the C2 `ambient-intake-sweep` re-registration);
  it runs at Stage 12 deploy and is a deregistration target at rollback.

## 11. Per-adapter resilience (why one fan-out sweep, not N per-adapter sweeps)
C3 is ONE sweep that fans out to all configured adapters — it produces the single run-record the
C4 heartbeat binds to; per-adapter sweeps would fragment that contract. Per-adapter resilience
lives INSIDE the one sweep: one unreachable adapter degrades to a `partial` run-record row
(`reachable: false`), never aborts the whole sweep; the reachable adapters still produce drift +
proposals. This is what makes the single-sweep shape safe.

## Framework Reference
This spec consumes the Context Lifecycle Model (`core/disciplines/context-lifecycle-model.md`):
it implements the `Context-Decided → Context-Closed` transition (§2) for Evidence-Gate-qualifying
external-Done evidence, registered as a §8 consumer (the Daily-sweep automation implementation the
§8 Forward-citation row anticipates). It changes no §2 vocabulary, §4 threshold, or §5 mechanism —
§8 consumer-registration is Issue-exempt per §9.
