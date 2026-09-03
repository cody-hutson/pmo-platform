<!-- reference-durability: allow-link -->
---
title: "ADR-182 — The automation registry is the gate, and it decouples what runs from how it fires from who governs"
status: Accepted (operator-ratified at the automation-registry-as-gate Stage 5 Collective Review scope-lock 2026-09-02)
date: 2026-09-03
release: automation-registry-as-gate
deciders: Stage 5 Solutioning spoke (four-candidate design exploration on the decoupling shape; three canonicalizations grounded against the live corpus) + operator at the Collective Review scope-lock
tags: [automation-registry, scheduler-adapter, automation-level, registry-as-gate, host-binding, adapters-seam, ADR-022, ADR-038, ADR-007]
source_observations:
  - "Five documents under release/references/protocols/ declare a recurring routine (each carries 24-31 hits of the word cadence, against 0-1 for every other file in that directory). Four of them name a host scheduler inline; decision-audit-cadence.md states the identical staleness-sentinel policy naming no backend at all. Measured at authoring: nine backend occurrences across the four, zero across the fifth, whose own cadence control fires 31 times over a 14,948-byte file. The corpus therefore already contains a worked instance of the routine policy stated without the firing mechanism."
  - "The hardcoded backend token appears, as of authoring, in 12 tracked files carrying 23 occurrences; excluding the frozen historical release plans, the live consumer surface is 9 files carrying 19 occurrences. On the authoring instance, none of the routines those documents declare were ever registered — the platform asserted a cadence that no mechanism ran."
  - "docs/INSTALL.md instructs the installer to register scheduled tasks on a named host surface, and states that nothing runs until they do and that this is deliberate — the one step the installer cannot perform. A tracked install document is therefore unrunnable as written on any host without that surface, which is the portability leak this decision closes."
  - "The operator-configuration template's adapter table carries four host-adapter selectors, each a scalar with a documented default, and its own header comment names the table the canonical onboarding seam. No scheduler axis exists on it — a measured absence over an enumerated table, not an unsearched one."
  - "core/standards/c2-intake-sweep-path-a.md carries what runs, how it fires and who governs it in one prose section: a cron cadence, a named host scheduler, a delegating entrypoint, and an automation-level clamp. The governance clamp is prose only, so nothing mechanically relates the declared ceiling to the registration — a gate could assert the routine exists but never that it declares a ceiling. The backend is additionally named in that file's frontmatter, at purpose: and consumers:, so a body-only scan reads clean while the file's machine-read contract still binds the host."
  - "core/schemas/ holds contract documents and no appendable instance data — every file there is a contract, none is a row set. core/skills/registry.md is the platform's one existing registry of this shape, and its contract lives separately in core/schemas/, which is the split this decision reuses rather than invents."
  - "The parent epic frames the registry as a design/architecture/data gate, states the what/how/who decoupling, declares the scheduled-automation library a catalog atop this registry, and explicitly guards against building a universal scheduler abstraction up front."
  - "The Scheduled Automation Library catalog, which this decision makes a view of the registry rather than its owner."
  - "The host-adapter family this decision extends by one axis under its existing seam."
  - "The prior release that shipped the automation-level dial, proving scheduled-autonomous-governed for a single routine; the WHO axis cites that dial and does not change it."
supersedes: none
---

# ADR-182 — The automation registry is the gate, and it decouples what runs from how it fires from who governs

## Status

**Accepted** — operator-ratified at the `automation-registry-as-gate` Stage 5 Collective Review scope-lock, 2026-09-02.

**Numbering provenance.** This record was authored at the next-free number computed from the mainline anchor at Engineering Commit 0. An ADR number is *allocated at authorship but claimed at merge*, so a record on a live branch is exposed to every sibling that merges ahead of it; the detector's own branch-claim reading is explicitly non-binding, and pre-reserving a higher slot is no remedy because the contiguity gate fails a gap as readily as a duplicate. Should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop.

**Numbering provenance — `181 → 182`.** Held **ADR-181** branch-local; renumbered to **ADR-182** at merge time by `release/tools/renumber-adr.py`, because the mainline already claimed 181. In-release citations that read "ADR-181" denote this record.

## Context

The platform declares recurring routines in prose and, beside each declaration, names the host mechanism that fires it. That entanglement has three separable costs, and the corpus exhibits all three.

**The routine policy is already statable without the firing mechanism — and the corpus proves it.** Five documents under `release/references/protocols/` declare a recurring routine. Four of them name a host scheduler inline. The fifth, `decision-audit-cadence.md`, states the *identical* staleness-sentinel policy — "a scheduled staleness sentinel", "creating the scheduled job" — and names no backend at all. As of authoring the four carry nine backend occurrences between them; the fifth carries zero, while its own cadence vocabulary fires 31 times across the document, so the zero is a measurement over a real cadence document rather than a coincidental absence in an unrelated file.

**This is the decisive argument, and it is not an argument from first principles.** A design that must reason its way to an abstraction is speculative; a design that generalizes a form its own corpus already carries is not. Four sibling documents state one policy two ways, and the backend-free way loses nothing. This record therefore **generalizes an existing form rather than inventing an abstraction** — and `decision-audit-cadence.md` is the worked in-corpus target for migrating the other four, not a spec to interpret.

**The entanglement is a portability leak that reaches the install path.** As of authoring the hardcoded backend token appears in 12 tracked files carrying 23 occurrences; net of the frozen historical release plans, the live consumer surface is 9 files carrying 19 occurrences. One of them is `docs/INSTALL.md`, which instructs the installer to register scheduled tasks on a named host surface — so a tracked install document is unrunnable as written on any host that does not have it. And on the authoring instance **none of the routines those documents declare were ever registered**: the platform asserted a cadence that no mechanism ran, and nothing detected the gap, because a prose declaration has no reader that can fail.

**The governance ceiling is prose, so no gate can grade it.** `core/standards/c2-intake-sweep-path-a.md` carries a cadence, a named host scheduler, a delegating entrypoint and an automation-level clamp in one prose section. The clamp is prose only. Nothing mechanically relates the declared ceiling to the registration, so a gate could assert *a routine exists* but never *the routine declares its ceiling* — and an ungoverned scheduled routine would ship with the gate reading green.

**The seam this decision needs already exists, with one axis missing.** The operator-configuration template's adapter table carries four host-adapter selectors, each a scalar with a documented default, and its own header comment names that table the canonical onboarding seam. There is no scheduler axis on it — an absence measured over an enumerated table.

## Decision

### The three concerns are separated onto three surfaces with three owners

| Concern | The question it answers | Surface (where it is written) | Owner / domain | Changes when |
|---|---|---|---|---|
| **WHAT runs** | which routine, on what cadence, invoking what | **routine-spec row** — `core/automations/registry.md`, validated against `core/schemas/automation-registry-schema.md` | **platform corpus** (git-tracked, public) | the platform ships or retires a routine |
| **HOW it fires** | which backend actually triggers it | **the `scheduler` selector on the operator-configuration adapter table**, resolved by the scheduler adapter at fire time | **operator instance** (git-ignored, restricted-permission) | the operator changes host, or has no scheduler |
| **WHO governs** | how much it may do unattended | **the operator-configuration automation-level dial** (effective value); the row carries an `automation_level_default` (declared value only) | **operator instance** | the operator moves the dial, at any time |

### Why the three separate — three independent axes, each with its own evidence

1. **Different change frequency.** WHAT changes on a platform release; HOW on an install or a host change; WHO whenever the operator moves a dial. Entangled, the least-frequent change — a corpus edit needing a governed pull request — is forced by the most-frequent one. The automation-level block runs to pages of operator-facing prose precisely because it is meant to be re-read and re-set; none of that belongs in a git-tracked routine catalog.

2. **Different ownership domain — a security boundary, not a preference.** WHAT is public git-tracked corpus. HOW and WHO live in the operator-configuration file, which ADR-022 keeps at restricted permissions as the operator-environment and identity surface. So entangling WHAT with HOW does not merely couple two fields: it **moves an instance-local fact across the public/private boundary**. The install document naming a host scheduler is that leak, already shipped.

3. **Different failure mode, therefore different detector.** WHAT wrong → the routine does the wrong thing, and its own acceptance criteria catch it. HOW wrong or absent → **the routine never fires, silently**, and only a liveness or degrade check catches it. WHO wrong → it does too much or too little unattended, and the ceiling catches it. One entangled surface can carry at most one detector — which is why the headline defect went undetected: routines declared in five documents, none registered.

### The registry is the admission gate, not a description

**An automation is admitted only if it has a registry row that validates against the schema.** The registry is the single source of truth for the automation population, and the gate is what keeps it so.

A *descriptive* registry is not an option. With no admission predicate there is no forcing function, so coverage decays to whatever the last author remembered — which is not hypothetical, but the finding that opened the parent epic: a close-out asserted a routine "runs on a schedule" while no registered or portable mechanism existed. A second copy of a fact with no gate is a shadow source of truth, which the platform's single-source rule forbids.

**Reuse, not invention.** The gate shape exists one domain over. `.github/workflows/skill-registry-currency-check.yml` asserts *every rostered skill has a `core/skills/registry.md` row*; the registry gate asserts *every automation has a registry row* — the same invariant with the population swapped. It already carries a gate-efficacy header declaring posture, enforcement, invariant and a falsification repro; a single-sourced predicate at `core/deploy/tools/check-registry-currency.sh` consumed by **both** the continuous-integration job and the deploy-time check (duplicate a parse, never a policy); the reasoning for running with no path filter on a whole-population property; and an explicitly non-required posture with a documented one-step promotion path. The registry gate models on it rather than inventing an enforcement shape.

### Stored versus cited — the operative content of this decision

The registry stores only what it originates. **A reviewer falsifies the decoupling by finding a stored field in the cited half.**

| Axis | Stored / Cited | Authority when cited | Why not stored |
|---|---|---|---|
| `id`, `cadence`, `trigger`, `entrypoint`, `automation_level_default`, `reversibility` | **STORED** | — | The registry originates these; they *are* the routine spec |
| **the firing backend** | **CITED** | the `scheduler` selector on the operator-configuration adapter table, read by the adapter at fire time | Instance-local and permission-restricted; storing it is the host-binding leak this record exists to close |
| **the effective automation level** | **CITED (computed)** | `effective = min(automation_level, per-action max)` per the dial's ceiling semantic | A stored effective value drifts the instant the operator moves the dial |
| **the routine's behavior contract** | **CITED** | the tracked spec named by `entrypoint` | Copying the contract into the row recreates the thin-bootstrap drift the intake-sweep standard explicitly designed against |
| **the autonomy tier** | **CITED** | `core/specs/autonomy-tiers.md` | A second tier vocabulary is a parallel-vocabulary leak |

### Three canonicalizations

- **C-1 — schema/data split.** The contract lives at `core/schemas/automation-registry-schema.md`; the rows live at `core/automations/registry.md`. This reuses the split ADR-038 established for the platform's one existing registry, and is grounded on the measured invariant that `core/schemas/` holds contracts and no appendable instance data.
- **C-2 — six routine-spec fields, and zero new value vocabularies.** `id` · `cadence` · `trigger` · `entrypoint` · `automation_level_default` · `reversibility`. Every value space is bound to an existing closed vocabulary: the routine-name character rule to `core/standards/artifact-naming-standard.md`, the trigger enum to the cadence documents' own `time-driven` / `event-driven` / `hybrid` words verbatim, the governance default to the automation-level enum, and the reversibility tier to `core/specs/reversibility-protocol.md`. The registry mints **no** new enum.
- **C-3 — the adapter seam.** A `scheduler` selector on the operator-configuration adapter table: a fifth member of the family ADR-022 already ratified as *the* onboarding seam. Its default is **`none`**, deliberately — the shipped install documentation states that nothing runs until the operator registers the tasks and that this is deliberate, so an `agent-runtime` default would assert a backend the documentation says is not registered, and would reduce the adapter's degrade path to a fixture with no real caller.

### What this makes true elsewhere

The **scheduled-automation library catalog becomes a view of the registry, not its owner** — the parent epic's own dependency direction states the library sits atop this registry, so nesting the registry inside the catalog would make the foundation a child of its consumer. The **host-adapter family gains a fifth axis** under its existing seam, unchanged in shape. The **automation-level dial, its enum and its ceiling semantic are unchanged**: the registry cites the dial as a declared default and never as the effective value.

## Alternatives Considered

Four candidates were generated across all three altitude bands — point-fix, extend-seam, and new-abstraction — and narrowed on breached hard constraints.

### Rejected — extend the existing scheduled-automation-library catalog in place

**The mechanism:** one artifact, the catalog, carries cadence, backend and governance per routine. It is the cheapest edit and the obvious existing enumeration of routines, which is exactly why it must be named and refused on the record. **Four reasons, each independently sufficient:**

1. **Host-binding leak into the public corpus.** Placing the firing backend in a git-tracked catalog writes an instance-local, non-portable fact into public corpus — the precise defect the four hardcoding documents exhibit, re-committed deliberately at a new location.
2. **Inverted dependency direction.** The parent epic's own Dependencies field states the library is the catalog *atop* this registry. Nesting the registry inside the catalog makes the foundation a child of its consumer.
3. **No admission predicate.** A catalog has no schema-validated entry shape, so there is nothing for a gate to assert an entry *against*. "Extend the catalog" collapses into "build the registry inside the catalog, with the catalog's looser contract."
4. **Re-entangled change cadences.** The catalog would again force a corpus edit for an operator-side host change, which is failure mode 1 above.

### Rejected — put the firing backend in the routine spec itself

The near-miss worth recording, because it **passes the release's own test while missing its outcome**. Cut WHAT and HOW apart one level too low and the backend name lands inside the routine spec: the consumer-facing scan for a hardcoded backend then returns zero and the acceptance criterion goes green, while the leak has simply **relocated into the registry** — which is now git-tracked *and* host-bound at once. This is why the release's cross-issue criterion was amended to assert that the registry itself names no backend, and to cover frontmatter as well as prose body: a body-only scan over consumers alone verifies that the leak *moved*, not that it *closed*.

### Rejected — a full automation runtime

A new automation-execution subsystem: registry, dispatcher, policy engine, and pluggable backend drivers. Rejected on a blast-radius ceiling breached against the parent epic's own written guard — start from the real backends plus a manual degrade, and do not build a universal scheduler abstraction up front. A structural-tier subsystem where an extend-seam answer reaches the same capability outcome.

### Carried as the opposing view — the two-way split

The strongest surviving alternative: the registry carries WHAT *and* WHO together, and only HOW is adapter-abstracted. Its case is real — a two-axis split is smaller, and the automation-level dial is already an operator dial, so naming WHO separately may look like ceremony.

**It loses on gradability, not on elegance.** Under the two-way split a routine's governance ceiling lives only in the entrypoint spec's prose — which is precisely today's state, where an intake-sweep standard declares an autonomy tier bounded by the dial in prose and nothing relates that claim to the registration. So the gate could assert *an entry exists* but not *the entry declares its ceiling*, and an ungoverned routine would ship green. Naming WHO as a **stored field** is what converts "the routine is governed" from a prose promise into a gradable predicate. That is the gate-vacuity risk on a second axis, and the two-way split would ship it.

## Consequences

**Positive.** Routines become portable: a host change is an operator-configuration edit, not a corpus pull request. Governance becomes gradable: a gate can assert that a routine declares its ceiling, not merely that it exists. The silent-non-firing failure mode acquires a detector for the first time, because a declaration now has a reader that can fail. Four sibling slices are unblocked with their premise fixed rather than re-derived — the schema knows its field set and whether the backend is a field; the adapter knows which surface owns the selector and how many arms to build; the gate knows the registry is mandatory and what a complete entry is; the migration knows that swapping one backend name for another is not migration.

**Negative, plainly.** One net-new `core/` directory, which extends the core-module file-placement boundary ADR-007 draws — recorded here rather than accreted silently, which is part of why a founding record is the right vehicle. The existing automation declarations gain a row but stay **physically scattered** across `core/standards/` and `release/references/protocols/`; the registry gives them a row, not a home, and co-locating them is no slice's scope in this release. A fifth adapter selector is one more question on the onboarding path. And the `none` default means a fresh install fires nothing until the operator acts — which is the honest behaviour and matches what the install documentation already promises, but it is a real trade against convenience.

**Unenforced by construction, and stated so.** The registration of this record in the core module's ADR README is **not** machine-checkable: that file is a curated thematic document rather than an index by ratified determination (ADR-117), and the index projector's own scope excludes it. The registration is therefore human-graded, and recorded here as unverified-by-machine rather than as absent-therefore-fine.

## Reversibility

**CHEAP** at ship — the split is expressed as field names in a schema that has no consumer yet, plus one configuration selector, so unwinding it is a schema edit before anything reads it. **Trending MODERATE** as registry rows and citations accumulate: once consumers cite the seam and rows carry declared defaults, re-cutting the boundary means re-opening every row and every citation. Confidence **HIGH** — all three home surfaces exist and are ratified.

## Related ADRs

| ADR | Relation |
|---|---|
| **ADR-022** | Composes-with — establishes the operator-configuration adapter table as *the* onboarding seam, and the operator-environment versus platform-behavior boundary the WHAT/HOW split rides. A host selector on the platform-behavior surface instead would contradict a ratified access-control boundary and would ship unvalidated by the configuration-schema job |
| **ADR-017** | Composes-with — names adapters as an operator-configuration concern, which ADR-022 then refines |
| **ADR-031** | Composes-with — the unified payload-triggered enforcement hook for the automation-level dial; the mechanical half of the WHO axis, cited and unchanged |
| **ADR-038** | Composes-with — registry-as-configuration-management-database; the stored-versus-cited construction reused here, and the principle that there is exactly one catalog and other views are projections of it, which is what makes the scheduled-automation library a view |
| **ADR-007** | **Extended** — the core-module file-placement boundary, extended by one directory (`core/automations/`) |
| **ADR-062** | Composes-with — substrate versus canonical surface; why the inherited affected-files boilerplate on the source work items is left intact as historical record rather than amended |
| **ADR-117** | Composes-with — ADR index as a derived surface with a scoped conformance claim; the authority behind the unenforced-registration consequence above |
| **ADR-005** | Composes-with — append-pattern-aware contention scoring; why the concurrent thematic-entry appends to the core ADR README are informational rather than blocking |

## References

Provenance for the observations above. Each entry is the work item the
observation was drawn from, with the noun phrase naming what it contributes.

| Ref | Contribution |
|---|---|
| #2437 | Parent epic, Automation Registry — frames the registry as a design, architecture and data gate, states the what/how/who decoupling, and declares the Scheduled Automation Library a downstream view. |
| #1633 | The Scheduled Automation Library catalog, which this decision makes a view of the registry rather than its owner. |
| #1184 | The host-adapter family this decision extends by one axis under its existing seam. |
| #322 | The release that shipped the automation-level dial, proving scheduled-autonomous-governed for a single routine. The WHO axis cites that dial and does not change it. |
