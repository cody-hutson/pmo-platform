---
title: scheduler Adapter — Routine-Firing Operation Interface
purpose: Defines the two operations a scheduler adapter must provide so a routine declared once in the automation registry fires on whatever backend the operator configured — resolve / register — with abstract, backend-agnostic semantics, the config-selection binding to operator.toml [adapters].scheduler, the SD-1..SD-4 manual-degrade contract for an install with no scheduler, and the two v1 reference adapters. Interface spec plus the degrade contract; the registry row it resolves is governed by the automation-registry schema, and the executable resolver that implements this interface is a separate file.
type: standard
status: ACTIVE
consumers: "core/deploy/tools/resolve-automation-binding.sh (the executable implementation of this interface, and the asserter of SD-1..SD-4); core/automations/registry.md (the rows resolve() reads); operator.toml [adapters].scheduler (the config-selector that binds a backend); the automation-registry CI gate (runs this interface's self-test as a hard step)"
composes_with: [../schemas/automation-registry-schema.md, repo-host-adapter-versioning.md, ../config/operator.toml.template, ../ADRs/ADR-017-distribution-architecture.md, ../ADRs/ADR-022-platform-config-vs-operator-toml-split.md]
reversibility: CHEAP (an interface spec + one config selector on an existing table + one resolver script, all net-new with no inbound references at creation) / Confidence HIGH — git revert restores prior state; the selector defaults to "none", which is the behaviour of every install today, so a revert changes no install's effective firing.
---
<!-- reference-durability: allow-link -->

# scheduler Adapter — Routine-Firing Operation Interface

**Layer:** 1 (Engineering, git-tracked)

## 1. Why this interface exists

Firing a registered routine is a **backend-agnostic capability**: the platform declares *that* a routine runs, on what cadence, invoking what entrypoint. *Which mechanism actually triggers it* is a property of the operator's install, not of the routine. This spec is the seam between the two.

The split is the one the automation registry's founding decision records. The registry row is the **WHAT** — a git-tracked, public, instance-independent declaration. The firing backend is the **HOW** — instance-local, permission-restricted, and never a column. [`../schemas/automation-registry-schema.md`](../schemas/automation-registry-schema.md) § 7 states the constraint from the registry's side: *the firing backend is CITED, never stored*. This document is what it cites.

**The defect this closes is a silence.** Before this interface, a routine's cadence was declared in prose alongside a hardcoded backend name, and an install on which that backend was never registered produced **no output at all** — the platform asserted a cadence that nothing ran, and nothing said so. Tolerating an absent backend is therefore not enough: the degraded state has to be *observable*, which is what § 4 exists for.

This spec defines **the interface and the degrade contract**. The routine-spec contract is the registry schema's; the executable resolver that implements § 2 lives at [`../deploy/tools/resolve-automation-binding.sh`](../deploy/tools/resolve-automation-binding.sh). No policy is restated in either direction — the resolver parses the schema's field list rather than holding a copy of it.

*See also:* [`repo-host-adapter-versioning.md`](repo-host-adapter-versioning.md) — the sibling interface spec for the `repo_host` adapter, whose six-section shape this document instantiates, and [`../../release/references/standards/corpus-home-adapter-constraints.md`](../../release/references/standards/corpus-home-adapter-constraints.md) — the platform's first absent-backend degrade contract, whose four-constraint shape § 4 re-cuts for this axis.

## 2. The two operations (abstract, backend-agnostic semantics)

A conforming `scheduler` adapter MUST provide exactly these two operations. The semantics are abstract — they describe *what* each returns, never *how* a backend produces it.

**The operations are deliberately asymmetric in executability, and the interface says so rather than pretending otherwise.** `resolve` is a pure read of tracked state plus one config value, so it is executable everywhere. `register` is a write against a backend that may live outside the repository and outside any script's reach; the adapter therefore **emits** the registration payload and the responsible actor performs it. This is not a gap awaiting automation — it is the same boundary the install documentation already states to operators.

### 2.1 `resolve(id) → binding`

Returns the **firing binding** for the routine whose registry primary key is `id`.

```
resolve(id):
  row     := the row of the registry's `## Routines` table whose `id` cell == id
             (absent -> routine-level failure)
  spec    := the tracked file at row.entrypoint          (unresolvable -> failure)
  class   := REPO-FIRED    if spec is a repository workflow
             SESSION-FIRED otherwise
  backend := the repository host          if class == REPO-FIRED
             [adapters].scheduler         if class == SESSION-FIRED
  emit one binding record (§ 2.3)
```

- **`id` is the sole argument, and the join is on the value.** The registry primary key, the `automation_id` marker the entrypoint declares, and the name the backend registers are **one string on three surfaces**. An adapter MUST NOT key on the entrypoint path, on file adjacency, or on any alias table: keying on anything but `id` makes the registry roster voluntary, and the admission gate's whole forcing function is that omitting a row costs the routine its ability to fire.
- **The backend class is DERIVED from `entrypoint`, never stored.** A routine whose entrypoint is a repository workflow is **repo-fired**: its own host runs it, on the cadence written in the workflow, and the operator's scheduler MUST NOT also register it — a second registration double-fires it. Every other tracked spec is **session-fired**: the routine's work is an agent session driving a governed document, so it needs the runtime the selector names. This derivation is what lets the adapter support both real backends while the registry names neither.
- **Fresh read, never cached.** The selector is read at every `resolve` call. An operator may change runtimes between two firings; a cached selector fires the backend that is no longer there, and the routine looks healthy while running nowhere.
- **Determinism:** `resolve` is a pure read. It performs no registration, mutates no tracked file, and contacts no backend.

### 2.2 `register(id)` / `deregister(id)`

**Emits the registration payload** for `resolve(id)`'s binding, and names the actor who applies it. The adapter never performs the registration itself.

| Backend class | Who registers | Mechanism | Reversal |
|---|---|---|---|
| repo-fired | the repository host | the schedule block already present in the workflow named by `entrypoint` | edit or delete the workflow — a tracked-file revert |
| session-fired | the operator, from an agent session | a scheduled task named `id`, carrying the row's `cadence` and a thin-bootstrap prompt citing the row's `entrypoint` | deregister, or disable — **not** a git revert, because the registration is non-git install-root state |
| none | nobody | — | not applicable |

**What changes versus copy-authored registration instructions:** the payload is now *derived from the row*, so the registration cannot drift from the declaration. The row is the single source; a registration that disagrees with it is a difference an operator can see rather than a divergence nobody measures.

### 2.3 The binding record — one line per routine, state token first

The record is the adapter's whole observable output, and § 4 grades two of its four constraints on this content rather than on an exit code. The **first field is a state token**, so a degraded routine and a scheduled routine are distinguishable by reading, not by inference.

```
AGENT-RUNTIME  <id>  cron='<row cadence>'  task='<id>'  entrypoint=<row entrypoint>
GITHUB-ACTIONS <id>  cron='<the workflow's own schedule>'  workflow=<row entrypoint>
MANUAL         <id>  not scheduled on this install (scheduler="none"); invoke: run the routine declared at <row entrypoint>
```

- The token set is closed: `AGENT-RUNTIME`, `GITHUB-ACTIONS`, `MANUAL`. An undifferentiated `OK` is forbidden — it is the exact downgrade that would satisfy tolerance while asserting nothing.
- `MANUAL` rather than a not-applicable marker is deliberate. A degraded routine is not inapplicable: it is applicable, unscheduled and **invocable**, and the record must carry the invocation. The token is also the vocabulary the registry's `trigger` field already uses for a human limb, so no parallel vocabulary is introduced.

**The bounded honesty limb, stated rather than implied.** For a session-fired routine the adapter reports the backend as **declared, never verified**: it cannot read out-of-tree registration state, so a clean `resolve` means *this routine is bound to a backend*, never *this routine is registered and will fire*. Registration liveness is unasserted by any surface today. Stating it here is what stops a clean resolve from being read as a liveness guarantee.

## 3. Config-selection (the existing seam — no new mechanism)

The active `scheduler` adapter is selected at the seam that already exists. No new selector file, table, or resolution path is introduced.

- **Selector:** `operator.toml [adapters].scheduler`, the fifth member of the host-adapter selector table.
- **Value space:** `"agent-runtime"` (the scheduled-task surface of the runtime named by `[adapters].ai_tool`) or `"none"` (this install has no scheduler — the manual degrade of § 4). The repo-fired class never consults the selector, so the repository host is **not** a selector value: shipping one would be an arm no code path can reach.
- **Resolution:** cascade-resolved per the platform's config-resolution protocol — global → portfolio → program → project → individual — with the install-level default as the floor. Same path as every sibling selector; no new resolution behaviour.
- **Default: `"none"`.** This reverses the table's house rule that each selector ships a working default, and the reversal is the deliberate call of this interface. Registration is the one install step the installer cannot perform, and the shipped install documentation states in terms that nothing runs until the operator registers the routines. A default of `agent-runtime` would make tracked config assert a backend the tracked install document says is not there — which is the founding defect of this whole capability re-expressed one layer down. **The house rule is honoured in substance:** a fresh install runs the capability end-to-end with no operator action — manually, and visibly.
- **An absent key resolves to `"none"`, never to an error.** That is the pre-existing state of every install that has not yet taken the key, and it must be a supported state rather than a crash.
- **A value outside the value space is a hard error, never a silent fallback to `"none"`.** A typo must not read as "this install has no scheduler" — indistinguishable-from-absent is precisely the failure mode this interface exists to make visible.
- **Adding a backend:** a third backend (a) implements the two operations of § 2 against its mechanism, (b) adds its value to the selector's allowed set, and (c) ships under its own ticket. This interface, the registry, and the schema are unchanged.

This binding is faithful to the platform's config-home decisions: the distribution-architecture decision names `operator.toml` as the home for identity, paths, methodology and **adapters**, and the platform-config-vs-`operator.toml` split decision consolidates host-adapter selectors into the `[adapters]` table with a v1 default each. The selector is instance-local and lives on a restricted-permission file, which is the correct side of the public/private boundary for a fact about one operator's machine.

## 4. SD-1..SD-4 — the manual-degrade contract (normative)

**This section is the reason an absent scheduler is a degraded state rather than a silent one.** It re-cuts, for the scheduler axis, the four-constraint shape the platform already ships for an adapter whose backend root is absent.

| ID | Constraint | Asserted by |
|---|---|---|
| **SD-1** *(tolerance)* | With `scheduler = "none"`, or the key absent, `resolve(id)` on a well-formed row MUST **exit 0** and emit a `MANUAL` binding. Never an error, never a non-zero, never silence. | self-test arm **F-B**, exit code |
| **SD-2** *(non-degeneracy)* | With `scheduler = "agent-runtime"`, `resolve(id)` MUST emit a **fully-populated** `AGENT-RUNTIME` binding — task name equal to `id`, cron equal to the row's `cadence` verbatim, entrypoint equal to the row's `entrypoint` — and exit 0. This forbids the unconditionally-zero resolver that SD-1 alone would accept. | self-test arm **F-A**, graded on **stdout content** |
| **SD-3** *(the failure channel survives the degrade)* | A genuine defect — an unknown `id`, an unresolvable `entrypoint`, an `automation_id` mismatch, a selector value outside the value space — MUST exit **non-zero under every selector value, `"none"` included**. `none` degrades the *firing*, never the *validation*. | arms **F-C** / **F-D**, each run once per selector value |
| **SD-4** *(distinguishability)* | The degraded outcome MUST be a **per-routine record** carrying the literal token `MANUAL` **and the exact manual invocation** — never an undifferentiated `OK`, never absence. A degraded routine and a scheduled routine MUST be distinguishable from the adapter's output alone. | arm **F-B** stdout, **per routine id**, with negative control **F-F** |

> **These IDs are load-bearing.** The implementation's `--self-test` greps this file for each of `SD-1`..`SD-4` and fails if the file is absent or any ID is missing. **Do not renumber them.** Adding `SD-5` is safe; renumbering `SD-1`..`SD-4` breaks the doc-to-test binding and reddens the gate.

**SD-1 and SD-2 are a pair, and neither is sufficient alone.** A resolver that exits 0 unconditionally satisfies SD-1 while resolving nothing at all. SD-2 forbids that degenerate answer by requiring a *present* backend to actually produce a populated binding. **SD-4 closes the remaining hole:** without it an implementer could satisfy SD-1 by downgrading every unresolved routine to a bare `OK`, which would defeat SD-3 as well. **SD-2 and SD-4 are therefore graded against CONTENT, not exit codes** — a constraint that is stated but graded only through an exit code is not enforced, and a tolerance rule graded on an exit code alone would pass today, pass after a correct seam ships, and pass after a violating seam ships.

**What "degrade to manual" means for each actor:**

- **The operator** runs the adapter in its all-routines form and reads the `MANUAL` lines. Each carries the invocation verbatim — the same thin-bootstrap pointer that would have been registered — so the routine is invoked in a session at the moment the operator chooses. Nothing is hidden behind an absent backend.
- **The routine** does exactly what it does when scheduled: same entrypoint, same governance ceiling, a human trigger instead of a cadence trigger. A registered routine's spec already declares it triggered by user *or* automation, so the manual limb is the routine's pre-existing path, not a reduced mode.
- **A reviewer** distinguishes degraded-but-working from silently-not-running by the printed record, and distinguishes degraded from broken by SD-3: a malformed row still fails non-zero on a no-scheduler install.

## 5. The two v1 reference adapters

Exactly two adapters ship. They are a **reference mapping** — they show how the abstract operations bind to a concrete mechanism; they are not part of the contract, and a third adapter would bind differently.

They are not two implementations of one thing. They are the two **classes of firing the platform has**, and the class is what § 2.1 derives.

| | `agent-runtime` (session-fired) | the repository host (repo-fired) |
|---|---|---|
| **Selected by** | `[adapters].scheduler = "agent-runtime"` | nothing — derived from `entrypoint`; the selector is not consulted |
| **`resolve` emits** | an `AGENT-RUNTIME` record: task name `id`, cron from the row's `cadence`, entrypoint from the row | a `GITHUB-ACTIONS` record: the workflow's **own** schedule and its path |
| **`register` payload** | a scheduled task named `id` carrying the cadence and a thin-bootstrap prompt citing `entrypoint`; applied by the operator from a session | already applied — the schedule block in the workflow **is** the registration |
| **Why only this class** | the routine's work *is* an agent session driving a governed spec; a workflow runner has no agent, and the platform ships bring-your-own-key on a public repository | the work is the workflow's own steps; it fires whether or not any application is open, which is precisely the property the session-fired class lacks |
| **Cadence authority** | the row declares a recommended default; the operator's registration is the effective schedule | the workflow's own schedule is authoritative, and the row **mirrors** it — the two are asserted equal rather than left to drift |

**No third arm, no plugin interface, no registry of adapters.** The value space has exactly two members, the derivation has exactly two classes, and both are reachable on real data: the registry ships one routine of each class, so neither arm is dead code. A third backend adds one value and one arm under its own ticket.

## 6. Conformance checklist (for a new `scheduler` adapter)

A new adapter conforms when all of the following hold.

1. **Both operations present** — `resolve(id)` and the `register`/`deregister` payload emission — with the § 2 abstract semantics.
2. **Resolution is by registry `id`**, and by nothing else. No entrypoint key, no alias table, no second identifier. A roster declaration with no row, and a row whose entrypoint declares a different id, both fail non-zero.
3. **The backend class is derived from `entrypoint`**, never read from a stored field. A repo-fired routine is never registered on the operator's scheduler.
4. **The selector is read fresh at every call**, and an absent key resolves to `"none"` rather than erroring.
5. **A selector value outside the value space is a hard error**, never a silent fallback.
6. **SD-1..SD-4 all hold**, with SD-2 and SD-4 asserted against output content and SD-3 asserted under *every* selector value.
7. **The record's first field is a state token** from the closed set, one line per routine.
8. **No backend mechanism leaks into the registry or the schema** — the row names a cadence and an entrypoint, and this document is the only place a backend is named.
9. **Selector value registered** — the adapter's name is an allowed value of `operator.toml [adapters].scheduler`, shipped under its own ticket; the default remains `"none"`.

## 7. Provenance

- **Capability and decoupling decision:** the automation-registry architecture decision recording the what/how/who split — the registry is the WHAT, this interface is the HOW, the operator's automation dial is the WHO.
- **Routine-spec contract:** [`../schemas/automation-registry-schema.md`](../schemas/automation-registry-schema.md) — the six fields, their value spaces, and § 7's cited-never-stored table, which names this document as the authority for the firing backend.
- **Interface shape:** [`repo-host-adapter-versioning.md`](repo-host-adapter-versioning.md) — the platform's first adapter interface spec; its six-section structure is instantiated here, not modified.
- **Degrade-contract shape:** [`../../release/references/standards/corpus-home-adapter-constraints.md`](../../release/references/standards/corpus-home-adapter-constraints.md) § 3 — the `CH-1`..`CH-4` tolerance / non-degeneracy / defects-still-fail / distinguishable-record shape, and the reasoning that a constraint graded only through an exit code is not enforced.
- **Config home:** [ADR-017](../ADRs/ADR-017-distribution-architecture.md) § S2 (`operator.toml` as the adapters home) and [ADR-022](../ADRs/ADR-022-platform-config-vs-operator-toml-split.md) (the `[adapters]` selector table, each selector with a v1 default).
- **Implementation:** [`../deploy/tools/resolve-automation-binding.sh`](../deploy/tools/resolve-automation-binding.sh) — the executable adapter and the asserter of `SD-1`..`SD-4`.
