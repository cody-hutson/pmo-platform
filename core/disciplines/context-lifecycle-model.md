# Context Lifecycle Model

> **Status:** Stage 6 Engineering
> **Companion source:** [`../standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) — cross-machine state-name registry.
> **Reversibility tier:** CHEAP / Confidence: HIGH — single-file governance doc; `git revert` restores prior state.

<!-- repo-integrity: allow-issue-ref -->

---

## §1 Purpose

The platform has 14+ independent anti-loss mechanisms across processing skills with no unifying framework. Inbound content (transcripts, file-router routed files, artifact staging) flows through phases without a platform-level concept of "this content is at state X, expecting transition to state Y" — making information loss invisible and unsystematic.

This document defines the **Context Lifecycle Model**: the platform-level state machine that inbound content moves through from arrival to resolution, with documented per-state stall criteria, a mechanism map of the 17 existing anti-loss mechanisms allocated to states they apply at, and an automation-boundary specification.

**What this framework is:**
- The single named source for "inbound content state" vocabulary across all processing skills
- The stall-detection specification (thresholds + signal sources) that every skill can reference rather than re-deriving
- The integration map that allocates existing anti-loss mechanisms to the state transition each one operates at

**What this framework is NOT:**
- A scheduler implementation (specification only — automated daily-sweep implementation is downstream, see §6)
- A PROJECT.md template dashboard (downstream consumer — future release)
- A replacement for any existing skill's logic (skills continue to operate as they do today; this framework provides shared vocabulary)
- The Domain C synthesized-intelligence lifecycle (separate machine — see §7)

---

## §2 State Definitions

The Context Lifecycle Model defines **5 object-typed states**. State names follow the `<Object>-<State>` convention from [`lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md), where Object = `Context` for inbound-content state.

| Order | State | Definition | Entry criterion |
|---|---|---|---|
| 1 | `Context-Captured` | Content arrived in workspace; not yet classified or registered. | File present (user upload, MCP sync, drop). |
| 2 | `Context-Structured` | Classified by file-router AND registered (TR-### entry OR routed to a 01-08 folder with metadata). | Routing complete + register entry written. |
| 3 | `Context-Reviewed` | Processed by an analytical skill (PPM Agent, etc.); items extracted; follow-up tags emitted. | Tags + items present in skill output. |
| 4 | `Context-Decided` | Items routed to trackers (RAID, Daily Status, Comms, Meetings) OR rejected with rationale. | Tracker write executed (Document Tier 2) OR rejection rationale logged. |
| 5 | `Context-Closed` | Items resolved per Evidence Gate (OPERATIONS.md §Evidence Gate). | Closure evidence present (transcript / Jira / Confluence / email). |

**Transition semantics:**
- All forward transitions are agent-detectable except `Context-Decided → Context-Closed`, which requires Evidence-Gate-qualifying evidence (Jira API match, transcript content match, etc.). Evidence detection can be automated; closure write is a Document Tier 1 / 2 mutation.
- No backward transitions are specified (out-of-scope; reserved for a future release).
- **Forced terminal transitions:** `08-Generated/` 10bd auto-archive sweeps `Context-Captured` / `Context-Structured` orphans to `Context-Closed` (archive variant — terminal) per CLAUDE.md §File Management Protocol.

---

## §3 Transition Diagram

```
                    [user upload / MCP sync / drop]
                                │
                                ▼
                       ┌─────────────────┐
                       │ Context-Captured │
                       └────────┬─────────┘
                                │ file-router classify + register
                                ▼
                       ┌─────────────────┐
                       │Context-Structured│
                       └────────┬─────────┘
                                │ analytical skill processes
                                │ (PPM Agent / artifact-generator / etc.)
                                ▼
                       ┌─────────────────┐
                       │ Context-Reviewed │
                       └────────┬─────────┘
                                │ tracker write OR rejection rationale
                                ▼
                       ┌─────────────────┐
                       │  Context-Decided │
                       └────────┬─────────┘
                                │ closure evidence per Evidence Gate
                                ▼
                       ┌─────────────────┐
                       │  Context-Closed  │ (terminal)
                       └─────────────────┘

  Forced terminal (08-Generated/ 10bd auto-archive):
     Context-Captured ─────────┐
     Context-Structured ───────┴──→  Context-Closed (archive variant)
```

---

## §4 Per-State Stall Detection

A stall is content that has entered a state and not transitioned within the documented threshold. The table below specifies stall criteria as a **specification**; automated detection IMPLEMENTATION (daily-sweep scheduler) is downstream per §6.

| State | Stall criterion | Threshold | Detection signal source |
|---|---|---|---|
| `Context-Captured` | File present but unrouted (orphan in workspace root OR sitting in `08-Generated/_unclassified/`) | >1 business day | OPERATIONS.md §15 Orphan Detection; file-router unclassified-queue scan |
| `Context-Structured` | Registered but `UNASSIGNED` or `PENDING` (TR-### with no PPM owner) | >3 business days (escalation pending) / >5 business days (escalation to project lead) | OPERATIONS.md §Transcript Processing Protocol — Unassigned Transcript Escalation |
| `Context-Reviewed` | Tagged for downstream skill but tracker write not yet executed | >1 daily processing cycle | OPERATIONS.md §Daily Processing Cycle Step 10-12 (Tracker Manager consolidated update) |
| `Context-Decided` | Item in tracker without closure event (varies per item type) | RAID: indefinite-open allowed; Action: 5 business days without status update; Decision: open until evidence | OPERATIONS.md §Evidence Gate for Closing Items + RAID Active/Archive lifecycle |
| `Context-Closed` | Terminal — no stall detection | — | (terminal) |

---

## §5 Mechanism Map

The platform's existing 17 anti-loss mechanisms are allocated below to the state transition or state they operate at. This map satisfies AC4 (≥14 mechanisms mapped).

| # | Mechanism | Source citation | Applies at |
|---|---|---|---|
| 1 | File Router 3-layer classification + auto-route | [`operations/skills/file-router/SKILL.md`](../../operations/skills/file-router/SKILL.md) | `Context-Captured` → `Context-Structured` transition |
| 2 | Transcript Register TR-### entry | OPERATIONS.md §Transcript Processing Protocol | `Context-Structured` (entry write) |
| 3 | Path validation on register write | OPERATIONS.md §Transcript Intake | `Context-Structured` (validation gate) |
| 4 | Single-source-recording flag | OPERATIONS.md §Transcript Intake | `Context-Structured` (annotation) |
| 5 | Unassigned Transcript Escalation (>3bd / >5bd) | OPERATIONS.md §Unassigned Transcript Escalation | `Context-Structured` (stall) |
| 6 | PPM Triage | OPERATIONS.md §Daily Processing Cycle Step 4 | `Context-Structured` → `Context-Reviewed` |
| 7 | Skill chaining via follow-up tags ([DELIVERY]/[COMMS]/[TECHNICAL]/[CHANGE]/[RISK]/[DECISION]) | OPERATIONS.md §Daily Processing Cycle Step 6 | `Context-Reviewed` (emit) / `Context-Decided` (consume) |
| 8 | Daily Status Log carry-forward | OPERATIONS.md §Evidence Gate + §Lifecycle | `Context-Decided` (persistence) |
| 9 | Evidence Gate for closing items | OPERATIONS.md §Evidence Gate | `Context-Decided` → `Context-Closed` |
| 10 | Communications ACTIVE/CORE/ARCHIVE lifecycle | OPERATIONS.md §Lifecycle Transitions | `Context-Decided` (per-item) |
| 11 | Drift Check (Daily Processing Cycle Step 0) | OPERATIONS.md §Daily Processing Cycle | All states (cross-cutting) |
| 12 | Orphan Detection (Daily Processing Cycle Step 15) | OPERATIONS.md §Daily Processing Cycle | `Context-Captured` (stall) |
| 13 | 08-Generated/ 10bd auto-archive | CLAUDE.md §File Management Protocol | `Context-Captured`/`Context-Structured` (forced terminal) |
| 14 | SESSION_STATE.md staleness rule (>2bd) | CLAUDE.md §Session Management | All states (session-level) |
| 15 | Tracker Manager consolidated update | OPERATIONS.md §Daily Processing Cycle Step 10-12 | `Context-Reviewed` → `Context-Decided` |
| 16 | Artifact Generator outdated-artifact detection | OPERATIONS.md §Daily Processing Cycle Step 13 | `Context-Decided` (artifact freshness) |
| 17 | External Sync drift detection (Confluence/Jira MCP) | OPERATIONS.md §Daily Processing Cycle Step 9 | `Context-Decided` (cross-system reconciliation) |

**Total:** 17 mechanisms allocated across 5 states (exceeds the "14+" floor in evidence — the count grew during Stage 5 enumeration).

---

## §6 Automation Boundary Specification

The framework distinguishes **what the platform should detect** from **how detection runs**. This release ships the specification; the implementation lands in a downstream release (likely a future file-router ingest release or a dedicated automation milestone).

### In scope (specification)

- The 5-state vocabulary (§2) — bound and stable
- Per-state stall criteria and thresholds (§4) — bound and stable
- Per-state mechanism allocation (§5) — bound and stable
- Consumer registration mechanism: skills that consume the framework declare it via a `## Framework Reference` subsection in their SKILL.md (see file-router as the demonstrating consumer — AC3)

### Out of scope (implementation deferred)

- Automated daily-sweep scheduler that scans the workspace for stalled content and emits escalation outputs
- PROJECT.md template lifecycle dashboard
- Backward transitions (`Context-Reviewed → Context-Structured` after PPM reprocesses, etc.) — reserved for a future release
- New stall-detection mechanisms beyond the 17 listed (additions go through standard intake → triage → bundle process)

### Forward contract for downstream automation consumers

A downstream automation consumer (e.g., daily-sweep skill, PROJECT.md dashboard) reads this framework as its specification:

1. **State vocabulary** — uses the 5 object-typed names verbatim, never aliases.
2. **Stall thresholds** — uses §4 thresholds as canonical; deviation requires an issue + plan + approval to update §4 first.
3. **Mechanism allocation** — emits escalations referencing the mechanism number from §5 (e.g., "Stall detected at `Context-Structured` — mechanism #5 escalation pending").
4. **Consumer registration** — adds a `## Framework Reference` subsection to its SKILL.md citing this file path.

---

## §7 Distinction from Domain C

The platform has a **separate state machine** for synthesized-intelligence artifacts (content authored by skills, residing in `08-Generated/`) governed by [`domain-c-lifecycle-protocol.md`](../../release/references/how-to/domain-c-lifecycle-protocol.md). That machine uses the states `draft` / `validated` / `published` / `stale` / `archived`.

**The two machines are distinct:**

| Concern | Context Lifecycle Model (THIS doc) | Domain C Lifecycle |
|---|---|---|
| **What it tracks** | Inbound content lifecycle (transcripts, emails, FDDs, uploads) | Synthesized-intelligence artifact lifecycle (skill-authored content in `08-Generated/`) |
| **Object type** | `Context` (inbound) | `Domain-C` (outbound synthesis) |
| **State names** | `Context-Captured` / `Context-Structured` / `Context-Reviewed` / `Context-Decided` / `Context-Closed` | `draft` / `validated` / `published` / `stale` / `archived` |
| **Object-typing** | Adopted (this release) | Object-prefix not yet adopted (see `lifecycle-states-canonical.md` for cross-machine convention) |
| **Trigger** | File arrival in workspace | Skill produces an artifact under `08-Generated/` |
| **Terminal** | `Context-Closed` (resolution evidence) | `archived` (10bd auto-archive or explicit) |

**Cross-reference discipline.** When this framework references Domain C in skill outputs or governance prose, use the object-typed form `Domain-C-<state>` (e.g., `Domain-C-published`) per [`lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) Object-Typing Convention. The bare Domain C states (`draft` / `validated` / `published` / `stale` / `archived`) are retained inside `domain-c-lifecycle-protocol.md` and in YAML/SQL schema-field-value contexts per the canonical-source object-typing rule.

**Why two machines?** Inbound and outbound content have different ownership, different state criteria, and different stall thresholds. Forcing both into a single state machine would conflate the concerns and obscure the distinct anti-loss mechanisms each pipeline needs. The two machines coexist; the canonical source ([`lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md)) enumerates both with their object-typed names so consumers always know which machine a state belongs to.

---

## §8 Consumers

Skills and governance documents that consume this framework's state vocabulary register here. Consumers add a `## Framework Reference` subsection (or equivalent cross-reference) to their SKILL.md citing this file path.

### Registered consumers

| Consumer | Consumption surface | Reference location |
|---|---|---|
| [`operations/skills/file-router/SKILL.md`](../../operations/skills/file-router/SKILL.md) | `Context-Captured` → `Context-Structured` transition (mechanism #1) | `## Framework Reference` subsection (demonstrating consumer) |
| [`../standards/lifecycle-states-canonical.md`](../standards/lifecycle-states-canonical.md) | All 5 Context Lifecycle states enumerated in cross-machine registry | §3 In-Scope Machines (Context Lifecycle subsection) |

### Forward-citation consumers (future releases)

These consumers are designed but not yet authored. They will register here when their releases ship:

| Consumer | Planned release | Expected consumption |
|---|---|---|
| Future file-router ingest+KB consumer | TBD | `Context-Captured` and `Context-Structured` state metadata on routed files (soft outbound contract) |
| ppm-agent | TBD | Emit `Context-Reviewed` state transition signal when triage completes |
| artifact-generator | TBD | Emit `Context-Decided` state transition signal when staged-artifact promotion happens |
| Daily-sweep automation | v2.07 (governor) / impl C2+C4 | All states (§6 impl). Clamps to `operator.toml [automation].automation_level` (C0 #322) as its autonomy ceiling — `effective = min(automation_level, per-action max)`; never unlocks the irreducible Tier-0 set per [`../specs/autonomy-tiers.md`](../specs/autonomy-tiers.md) § Irreducible Human Tasks |
| PROJECT.md template lifecycle dashboard | TBD | All states — per-project rollup |

---

## §9 Change protocol

Modifications to the state vocabulary (§2), stall thresholds (§4), or mechanism allocation (§5) require:

1. A GitHub Issue via the `improvement.yml` template (any category label per `label-taxonomy.md`) capturing what and why.
2. An implementation plan reviewed and approved by the operator before execution (per CLAUDE.md "No ungoverned changes" rule).
3. PR review via the Claude Code path (the PR diff IS the dry-run governance gate; git history IS the snapshot).
4. Update to this file's `Status:` line at the top to record the new release tag.

Adding a new consumer to §8 does NOT require a separate Issue — consumers register at their own release time when they add a `## Framework Reference` subsection to their SKILL.md or equivalent.

Adding a new mechanism to §5 (beyond the existing 17) requires the same Issue + plan + approval flow — mechanism count growth implies new anti-loss capability that affects stall detection.
