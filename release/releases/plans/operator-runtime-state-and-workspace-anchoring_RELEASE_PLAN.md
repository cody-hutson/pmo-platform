---
title: Release Plan — operator-runtime-state-and-workspace-anchoring (resolve the operator-instance home class + isolation key, and anchor the operations workspace)
type: release-plan
plan_type: release
status: ACTIVE
release: slug-only (ADR-092 — the concrete version binds at the Stage-12 atomic claim)
milestone: operator-runtime-state-and-workspace-anchoring
release_class: cross-cutting
reversibility: MODERATE / Confidence MEDIUM
---
# Release Plan — `operator-runtime-state-and-workspace-anchoring`

**Version identity:** **slug-only** per **ADR-092**. This file is `operator-runtime-state-and-workspace-anchoring_RELEASE_PLAN.md` and the branch is `release/operator-runtime-state-and-workspace-anchoring`; no version stem appears in the plan filename, the branch name, or this plan's identity prose. The bump class is the durable declaration; the concrete number binds at the **Stage-12 atomic claim**, when the claim tool resolves every braced RELEASE_VERSION token this file carries and renames the file into the major-version plans folder.

**Topology:** D-C **SINGLE** — one release branch, one PR, one merge gate. This file lands as **Engineering Commit 0**, authored by the first per-issue Stage-6 Engineering spoke.

**Concurrency posture:** **P0 fully-serial**. Stage-6 spokes route one at a time in the approved sequence on the single shared branch; force-push — including the lease-guarded form — is prohibited on that branch under any multi-spoke activity. The posture is not a default here: the two threads share six files, so serial execution is a measured requirement rather than a convention.

**Release class:** **`cross-cutting`** — operator verdict at the Stage-4 gate, re-classifying the milestone's declared `novel`. Trigger (c) fires: four in-bundle compositional edges. Posture: engagement density **Tight** · Stage-9 review depth **Deep** · Stage-5 activation bias **ALL** · Stage-13 outcome window **30-day**.

**Accepted sizing breach, recorded rather than avoided.** At `cross-cutting` weight 1.3, raw 20 points becomes **26 effective against a 25 bound — the size gate breaches**, and Phase-2's slice count is not yet known, so the final figure is higher. The operator accepted this breach as the cost of shipping the milestone as one coherent phased unit. The alternative considered and rejected was to declare the cheaper class to stay inside the bound; selecting a classification to avoid a gate outcome inverts the gate's purpose, so the true class stands and the breach is carried explicitly.

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | **minor** — the durable determination. The concrete number binds only at the Stage-12 atomic claim (ADR-092). |
| **Date Created** | 2026-08-16 (Sunday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing |
| **Branch** | release/operator-runtime-state-and-workspace-anchoring |
| **PR** | (populated at Stage 6 Phase C) |
| **Milestone** | operator-runtime-state-and-workspace-anchoring |

---

## Card Labels

This plan refers to its six work items by durable label rather than by number, so the plan survives renumbering and re-bundling. The label-to-number binding lives once, in the § Issue References block at the foot of this file.

| Label | Card | Type | Size | Thread |
|---|---|---|---|---|
| `SPIKE-FORKS` | Resolve the operator-instance home design forks and compute the relocation blast radius | spike | M | A |
| `DISCOVERY-CTX` | Measure runtime context-resolution semantics for the operations workspace | spike | S | B |
| `DEC-HOME` | The operator-instance home and the platform-config read-path are being decided independently | decision | M | A |
| `OBS-CONFIG` | The platform-config template is written to one home and read from another | observation | S | A |
| `UMB-RELOCATE` | Relocate the operator-instance runtime-state default out of the personal namespace | umbrella | M | A |
| `BLD-ANCHOR` | Anchor the operations workspace so a session rooted there resolves its procedure set | build | M | B |

---

## Scope

Six work-item cards across two threads, sequenced into three phases inside this release. The operator's scope verdict is **phased build within this release** — spikes, then decisions, then build — overriding the Stage-4 recommendation to bundle the relocation's child slices to a successor milestone. The divergence was taken on dependency reasoning rather than point arithmetic: composition is decided by capability coherence and dependency edges, not by fitting points to a band.

**Late-add extension.** Procedure-1 scaffolding could not be complete up front: `UMB-RELOCATE`'s child slices do not exist until `SPIKE-FORKS` returns. The scaffold covers the six known cards; the Procedure-1 Step-2 late-add rule fires when the slice plan lands, and the child slices join Phase 2 at that point.

---

## Dependency Graph

Directional. `==>` hard (downstream cannot start), `-->` soft (absorbable), `<~>` file-contention coupling (no ordering implied by itself).

```
THREAD A — runtime-state relocation + home class
                           DEC-HOME   (fork 0a/0b tracking home)
                              |
                              | --> absorbed as forks 0a + 0b
                              v
   P0 spike ............ SPIKE-FORKS  ========>  UMB-RELOCATE  (children late-added)
                              |
                              | ==> sets the resolution DIRECTION
                              v
                          OBS-CONFIG  <~>  UMB-RELOCATE

THREAD B — operations-workspace context anchoring
   P0 discovery ....... DISCOVERY-CTX ========>  BLD-ANCHOR
                       (native sub-issue of BLD-ANCHOR)

CROSS-THREAD (measured — contradicts the milestone's "no shared file" claim)
   UMB-RELOCATE / OBS-CONFIG  <~>  BLD-ANCHOR   on six shared files
```

**Circular chains: zero.** The five directional edges form a DAG with two roots (`SPIKE-FORKS`, `DISCOVERY-CTX`) and two sinks (`UMB-RELOCATE`, `BLD-ANCHOR`); no node is reachable from itself.

---

## Implementation Sequence

Three phases, strictly gated. The two threads run concurrently only through Phase 0.

### Phase 0 — spikes (both threads; serial on the shared branch)

1. **`SPIKE-FORKS`** — resolve the fork set, re-measure the blast radius at this release's own pinned base, and produce the ordered slice plan Phase 2 consumes. Fork order: **0a (home class) → 0b (isolation key) → 1 (family scope) → 2 (inline fallbacks) → 3 (corpus-split sequencing) → 4 (supersession ADR)**. Forks 0a and 0b resolve together, not in sequence. Before resolving forks 2 and 3 the spike re-derives their statements from live state — the three sibling cards they were scoped against have all closed.
2. **`DISCOVERY-CTX`** — discovery of the runtime context-resolution semantics. Produces a findings record with per-shape verdicts, each probe carrying both control arms. Produces findings, not a mechanism.

### Phase 1 — decisions (thread A; gated on `SPIKE-FORKS`)

3. **`DEC-HOME`** — consumes the fork record; carries no independent execution. Expected shape: ratify the split the platform already runs, name the classification rule for operator-instance path tokens, and record it. Recommended disposition: **mark this card as closed at Stage 13**, superseded by the spike's fork record.
4. **`OBS-CONFIG`** — gated on fork 0a's direction. Once the direction is set the fix is one of two mechanical edits. Coordinate with the sibling milestone registering a settings surface against the same composition manifest before the edit lands.

### Phase 2 — build (gated on Phases 0 and 1)

5. **`UMB-RELOCATE` child slices** — filed and triaged from the slice plan, then late-added to this milestone and built in the slice plan's stated order. The relocation's hard precondition is copy-first, then flip, then verify — bound in the slice plan rather than discovered at build time.
6. **`BLD-ANCHOR`** — mechanism selection against the measured discovery verdicts, under two hard constraints: reference-never-restate (no shadow SSOT), and the Layer-2 write prohibition, which forces the carrier to be the installer rather than an agent write. Must be sequenced against — or explicitly coordinated with — the sibling milestone designing the same operations-branch carrier.

**Why `BLD-ANCHOR` does not run in Phase 0.** It is hard-blocked by `DISCOVERY-CTX`, and it shares six files with thread A. Running it concurrently with Phase 1 would put two threads on the two hottest files in the repository simultaneously.

---

## Stage Applicability Matrix

Default is all stages; every SKIP / N-A carries its reason.

| Card | S5 Solutioning | S6 Eng | S7 DevTest | S8 QA | S9 Review | S12 | S13 |
|---|---|---|---|---|---|---|---|
| `SPIKE-FORKS` | **N-A** — the spike *is* the design activity | **YES** — commits the fork record + slice plan | **N-A** — no functional surface | **YES** — 3 gradable completion conditions | YES | YES | YES |
| `DISCOVERY-CTX` | **N-A** — discovery, not design | **YES** — commits the findings record | **N-A** — no functional surface | **YES** — 6 testable ACs | YES | YES | YES |
| `DEC-HOME` | **SKIP-superseded** — resolves inside forks 0a/0b | **CONDITIONAL** — only if it executes standalone | **N-A** — decision-scoped | **YES** — verified against the fork record | YES | YES | YES |
| `OBS-CONFIG` | **YES** — two viable directions with different costs | **YES** | **YES** — edit-then-resolve round-trip | **YES** | YES | YES | YES |
| `BLD-ANCHOR` | **YES** — mechanism selection deferred here by the card | **YES** | **YES** — functional | **YES** — 6 ACs | YES (**Deep**) | YES | YES |
| `UMB-RELOCATE` | **YES (per child slice)** — the children carry the design | **YES (per child slice)** | **YES** | **YES** | YES (**Deep**) | YES | YES |

The `UMB-RELOCATE` row changed from the Stage-4 draft: under the operator's phased-build verdict the umbrella's children build in this release, so Solutioning and Engineering apply to them rather than being deferred.

---

## File Change Matrix

Machine-readable — one repo-relative path per line, so downstream Stage 7/8/9 chips extract the list deterministically. This is the **known** set at Engineering Commit 0; the late-add rule extends it when the relocation child slices are filed.

```
release/releases/plans/operator-runtime-state-and-workspace-anchoring_RELEASE_PLAN.md
core/references/reference/operator-instance-home-and-isolation-key.md
core/references/reference/claude-code-runtime-state.md
core/references/reference/README.md
release/references/standards/corpus-home-adapter-constraints.md
core/deploy/composition-surface-manifest.sh
core/standards/composition-surface-spec.md
core/deploy/deploy.sh
core/deploy/lib-instance-path.sh
core/deploy/tools/path-leak-patterns.sh
core/deploy/allowlists/skip-path-portability-check.txt
core/hooks/tests/block-gh-path-leak.test.sh
core/standards/depersonalization-spec.md
core/config/operator.toml.template
core/rules/operations-bridge.md
core/CLAUDE.md.template
CLAUDE.md
docs/scripts/setup-workspace.sh
docs/scripts/validate-install.sh
docs/INSTALL.md
docs/GETTING_STARTED.md
docs/workspace-setup.md
release/tools/append-pipeline-event.sh
release/tools/query-pipeline-event.sh
release/tools/automated-closeout.sh
```

**Matrix caveat, stated rather than implied.** The final rows are conditional on the Phase-2 slice plan selecting them; they are listed because a Stage-7/8/9 chip that reads a short matrix and finds a longer diff cannot distinguish scope creep from a sanctioned late-add. Listing the anticipated set makes the late-add visible as an extension rather than a surprise. A new ADR file is expected under the platform ADR directory as fork 4's deliverable; its number is allocated at authoring time and is therefore not pre-listed here.

---

## Contention Map

Sourced from each card's declared affected files, cross-referenced against the live mover set re-measured at this release's pinned base.

| File | `SPIKE-FORKS` | `UMB-RELOCATE` | `DEC-HOME` | `OBS-CONFIG` | `BLD-ANCHOR` | `DISCOVERY-CTX` | Class |
|---|---|---|---|---|---|---|---|
| `core/deploy/deploy.sh` | reads | **edit** | **edit** | **edit** | **edit** | — | **HIGH — cross-thread** |
| `docs/scripts/setup-workspace.sh` | reads | **edit** | — | — | **edit** | — | **HIGH — cross-thread** |
| `docs/scripts/validate-install.sh` | reads | **edit** | — | — | **edit** | — | **MODERATE — cross-thread** |
| `docs/INSTALL.md` · `GETTING_STARTED.md` · `workspace-setup.md` | reads | **edit** | — | — | **edit** | — | **MODERATE — cross-thread** |
| `core/deploy/lib-instance-path.sh` | reads | **edit** | **edit** | — | — | — | LOW — thread A only |
| `core/deploy/composition-surface-manifest.sh` | reads | **edit** | **edit** | **edit** | — | — | MODERATE — thread A only |
| `core/deploy/tools/path-leak-patterns.sh` | reads | **edit** | reads | — | — | — | LOW |
| `core/standards/depersonalization-spec.md` | reads | **edit** | **edit** | — | — | — | LOW |
| `core/config/operator.toml.template` | reads | **edit** | **edit** | — | — | — | LOW |
| `CLAUDE.md` · `core/CLAUDE.md.template` · `core/rules/operations-bridge.md` | — | — | — | — | **edit** | — | NONE within release — thread B only |
| `core/references/reference/claude-code-runtime-state.md` | — | — | — | — | reads | **edit** | LOW |

**The cross-thread rows are the finding.** The milestone asserts the two threads are independent with no shared file. Measured: **six of the ten files thread B declares sit inside thread A's live mover set**. The *no shared decision* half of the claim stands — the two threads decide different objects — but they share a constraint surface: both change what the installer lays down outside the repository and where, and both are bound by the Layer-1/Layer-2 write boundary.

**Cross-milestone coordination — note, not relocation.** Three sibling milestones carry serialization edges: the rules-mirror milestone (designing the same operations-branch carrier as `BLD-ANCHOR`, intersecting on four paths), the install-parity milestone (registering a surface against the same composition manifest `OBS-CONFIG`'s fix needs), and the check-subject milestone (reading the very operator-instance token surface thread A relocates). Soft cross-milestone coupling gets a coordination note, never a trim or a move.

---

## Risk Register

| # | Risk | Class | Sev | Mitigation | Reversibility |
|---|---|---|---|---|---|
| R-1 | A hub trusting the milestone's "may run in parallel" verdict fans both threads onto the two hottest files simultaneously | Contention | **HIGH** | Verdict amended; fully-serial posture adopted; the contention map above is the authority | CHEAP · HIGH |
| R-2 | Phase-2's slice count pushes effective sizing further past the already-breached bound | Scope | **HIGH** | Breach accepted at the gate and recorded above; the slice plan states per-slice size so the figure is knowable rather than discovered | CHEAP · HIGH |
| R-3 | `BLD-ANCHOR` and the rules-mirror sibling design the same operations-branch carrier in two milestones — two carriers, or one overwriting the other | Dependency | **HIGH** | Serialization edge recorded; the Stage-5 design must state its relationship to the sibling's carrier before a mechanism is selected | MODERATE · MEDIUM |
| R-4 | PII-needle continuity — if the resolver flips before the needle file is copied, the pre-commit hook fails **open** and personal data can reach a commit | Security | **HIGH** | Copy-first, then flip, then verify is bound as a hard precondition in the slice plan, not left to Stage-5 discovery. The hook degrades to empty resolution rather than fabricating a path, which bounds but does not remove the exposure | EXPENSIVE · HIGH |
| R-5 | Path-leak detector drift — the instance-relative pattern bundles three sibling forms in one alternation; a runtime-state-only fork-1 answer leaves two behind | Security | MODERATE | Re-measured at this base: the two siblings appear in **no tracked file other than the detector and its own fixture**, so the residual is far smaller than the card predicted. The slice plan states the disposition explicitly | MODERATE · HIGH |
| R-6 | Fork 0b converts from a recorded decision into build scope, re-opening the size band | Scope | MODERATE | Fork 0b held decision-scoped in this release; a CH-5 addition to the corpus-home constraints doc is the maximum in-release artifact | CHEAP · MEDIUM |
| R-7 | Rebase pressure — the deploy script took well over a hundred touches in the last thirty days; a long-running release branch diverges | Contention | MODERATE | Keep the phases short; the sibling-merge stale-pin trigger re-runs at Stage 9 entry | CHEAP · HIGH |
| R-8 | Immutable historical records corrupted by a blind sweep | Data integrity | MODERATE | The immutable set is enumerated at the pinned base and asserted untouched on the merged PR; the spike widened that set by one file | EXPENSIVE · HIGH |
| R-9 | The "installer writes to the read-path" direction requires a **new** composition-surface tier, colliding with the sibling milestone's parallel tier registration | Dependency | MODERATE | Both directions priced in the fork record; coordinate before the edit lands | MODERATE · MEDIUM |
| R-10 | Discovery-to-design leak — `BLD-ANCHOR` pre-selects a mechanism before the discovery findings land | Scope | MODERATE | Hard gate: Stage 5 on `BLD-ANCHOR` does not start until `DISCOVERY-CTX` is complete; the citation is graded on the merged PR | CHEAP · HIGH |

**Rollback strategy.** Single release branch, one PR, one merge. Phases 0 and 1 commit no behavioral flip — they land two findings records, a resolved decision, and at most one manifest or resolver row; rollback there is a revert of the merge commit with no data migration and no installed-state change. **Phase 2 raises the tier**: the relocation carries a copy-first data migration, a security-detector change, and the fail-open pre-commit window. Rollback of a merged Phase 2 requires reversing the resolver flip *and* confirming the needle file resolves at the restored home before the pre-commit hook is trusted again. **Reversibility: MODERATE · MEDIUM overall** — CHEAP through Phase 1, EXPENSIVE once the relocation lands.

---

## Cross-Issue Acceptance Criteria

Five cohesion constraints spanning two or more cards, graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 (`SPIKE-FORKS` × `DEC-HOME` × `OBS-CONFIG` — the fork-0 record):** one decision record resolves **both** fork 0a (home class) and fork 0b (isolation key), **and** states which of the two directions `OBS-CONFIG` takes as a consequence. Three cards, one decision — not three. *Method:* case-insensitive match for the fork-0a and fork-0b subject terms and for both direction terms in the fork record, each with a nonsense-token control arm returning zero.
- [ ] **CIAC-2 (`SPIKE-FORKS` × `UMB-RELOCATE` — the mover-set baseline):** the slice plan is sized against a mover set **re-measured at this release's own pinned base**, and records the invocation plus the immutable/live split as separate counts. *Method:* re-run the reference sweep at the declared baseline commit and assert it equals the total the slice plan declares; assert the immutable count and the live-mover count appear separately.
- [ ] **CIAC-3 (`DISCOVERY-CTX` × `BLD-ANCHOR` — findings citation):** the selected anchoring mechanism cites the discovery findings record **by path** and by the specific per-shape verdict token for the shape it selects — not a general reference.
- [ ] **CIAC-4 (`UMB-RELOCATE` × `OBS-CONFIG` × `BLD-ANCHOR` — the immutable set):** the merged PR modifies **none** of the immutable historical files enumerated at the pinned base. The spike's re-baseline widened that set from thirteen to **fourteen** — the release-body pre-capture is a historical snapshot and is now inside the guard. *Method:* a name-only diff over the immutable paths returns empty; sensitivity arm — the same invocation over the release's declared edit-set returns non-empty. A **new** ADR added under the platform ADR directory is in scope and is not an immutable-set touch.
- [ ] **CIAC-5 (`UMB-RELOCATE` × `BLD-ANCHOR` — the shared installer surface):** neither thread adds a **new** hard-coded instance-home literal to the deploy script, the workspace-setup script, or the install validator; every path on those three files resolves through the single resolver. Any added literal requires an accompanying resolver call or a deviation-log row.

---

## Verification Plan

| Family | Check | Applies to |
|---|---|---|
| Per-issue | Each card's own acceptance criteria graded at Stage 8 | all six |
| Integration | The five cross-issue criteria above | cross-cutting |
| Regression | The deploy check suite green, including the path-leak detector check and the doc-link check | all |
| Regression | The corpus-home tolerance suite green, with its arming sentinel consistent with the observed seam | thread A |
| Sync | Deployed rule and skill copies re-synced where the change edits a mirrored surface | Phase 2 |
| Runtime suite | The suite selected by the runtime-suite map, run under a temporary-HOME sandbox | Phases 1 and 2 |

Phases 0 and 1 are doc- and decision-class; the runtime-suite selection for them is the explicit no-match row, which emits the honest skip rather than a fabricated pass.

---

## Operator Decisions Recorded

| # | Decision | Verdict | Reversibility |
|---|---|---|---|
| D1 | Release scope | **Phased build within this release** — spikes, then decisions, then build. Overrides the Stage-4 recommendation to bundle the relocation's children to a successor milestone | MODERATE · HIGH |
| D2 | Release class | **`cross-cutting`** — trigger (c) fires; the resulting sizing breach is accepted rather than avoided by declaring a cheaper class | MODERATE · MEDIUM |
| D3 | Concurrency posture | **Fully serial** | CHEAP · HIGH |
| D4 | Branch topology | **SINGLE** — one branch, one PR, one merge gate | CHEAP · HIGH |
| D5 | Version | **Rule-computed determination**, re-verified at Engineering Commit 0 against authoritative host state | CHEAP · HIGH |
| D6 | Sibling coordination | **Coordination note, not pull-in** — soft cross-milestone coupling never triggers a trim or a move | CHEAP · HIGH |

---

## Change Description

> **Currency note.** This section is authored incrementally. It currently reflects **Phase 0, both threads** — the first two Engineering spokes' work. Each subsequent Stage-6 spoke refreshes it as its card lands, and it is complete before the PR is transitioned to ready-for-review at the Stage-9 gate.

### Outcome

The release opens by answering the question every other card in it was waiting on: **what class of home does platform-written state use, and what is that home keyed on?** The answer turned out to be cheaper than the milestone assumed. The platform *already* runs the split the fork set asked it to choose — configuration in the XDG config root, runtime state workspace-relative — and the distribution ADR's fourth decision already wrote that rule down. So the home-class fork resolves to **ratification plus one repair**, not a three-way design choice, and the relocation it unblocks is a leaf correction rather than a re-architecture.

Two of the six forks turned out to be asking about a world that no longer exists, which is exactly what the planning stage flagged and required this spike to re-check. The inline-fallback fork was scoped against roughly five un-converged sites; **two** remain, and the deploy script's twenty-one declared fallthroughs measure **zero** — that convergence debt was paid without anyone updating the card. The sequencing fork asked how to order against a pending corpus migration that, measured, **never executed and has no successor** — the platform solved that problem a different way, with a tolerance adapter that is live and armed. Both forks were re-derived from current state before being resolved rather than answered against their stale framing.

Thread B's discovery slice returns a result the gate needs to see plainly: **the runtime's context-resolution semantics could not be measured on this instance, and the record says so rather than inferring them.** Four independent instruments were tried. Purpose-built context-file fixtures cannot be created — the platform's own autonomy-ceiling control refuses any file carrying the context-file basename, at any path. A fresh non-interactive session, which would have read its own resolved context back, cannot authenticate. Startup diagnostics die with it. And the session store, which records a real session that ran at exactly the directories in question, turns out not to persist the resolved context set at all — proven by running the same probe against a session whose loaded context is known with certainty and getting the same zero.

What the slice did establish is the surrounding state, measured with both control arms: the operations workspace still carries no context file at its root or anywhere on the path up to the workspace charter, no user-scope carrier exists, and the charter uses linking rather than inclusion. It also found that session identity is keyed by working directory rather than by context-file location, and that a spawned agent thread runs under its parent's key rather than its own — so any design resting on working-directory discovery needs separate confirmation for spawned threads. The three open questions — walk-up depth, whether several context files on one chain combine or the nearest wins, and scope precedence — are recorded as unmeasured with their reasons, together with the procedure that would answer them where a session can authenticate. **The design card therefore does not receive the measured input the plan promised it**, and that is a gate decision rather than something for this spoke to paper over.

### Issues resolved so far

| Card | State after this phase |
|---|---|
| `SPIKE-FORKS` | All three completion conditions met — six forks resolved, blast radius re-measured at this release's own base with both control arms, ordered slice plan authored. Ready to be marked as closed at Stage 13 |
| `DEC-HOME` | Its question is answered inside forks 0a and 0b. Stays open as the decision's tracking home through Stage 8; recommended to be marked as closed at Stage 13, superseded by the fork record |
| `OBS-CONFIG` | Its direction is set as a consequence of fork 0a — the installer changes, not the resolver. The edit itself lands in Phase 1 |
| `DISCOVERY-CTX` | Findings record committed at its declared path. Three candidate-shape verdicts rendered, six probes carry both control arms, one instrument recorded broken against a positive control. Three of the questions stay open as unmeasured-with-reason because the instruments that would answer them are unavailable on this instance. No mechanism recommended — that is the design card's call |
| `BLD-ANCHOR` · `UMB-RELOCATE` | Not yet entered; unchanged by this phase |

### Key decisions

- **Home class:** ratify the running split; move the runtime-state leaf to the workspace-root home. The derived-internals tier stays prospective — the distribution ADR explicitly declines to migrate existing content, and that clause is what keeps this a one-leaf move.
- **Isolation key:** target-slug namespace, **recorded but not built** in this release. Its urgency is lower than assumed, because the masking condition the home-class card expected to disappear is not scheduled to disappear.
- **Family scope:** one member left to move. The other two already left under earlier decisions, which is why the predicted "two stranded siblings" residual measures one file each — both inside the detector itself.
- **Supersession ADR:** yes, but it supersedes the unratified reorganization convention, not the distribution ADR — the relocation realigns with that ADR rather than reversing it.

### Reversibility

**CHEAP · HIGH** for everything committed in this phase. Three documents landed: a release plan, a decision record, and a findings record. No resolver default moved, no detector pattern changed, no installed state was touched. Rollback is a revert of the merge commit.

The tier rises sharply in Phase 2, and the plan says so rather than discovering it later: the relocation carries a copy-first data migration and a pre-commit hook that fails **open** if its needle file has not arrived at the new home before the resolver flips.

### Downstream impact

The slice plan is the load-bearing output. Its ten slices become the relocation umbrella's child work items through the late-add rule, and its stated dependency order is not cosmetic — the detector must learn the new path form **before** anything writes it, and the two convergence slices must land **before** the resolver flips so the flip has a single resolution site.

One finding materially affects the release's shape and is routed to the Stage-9 gate rather than absorbed: **the slice plan's arithmetic puts the bundle far past the sizing breach the operator accepted.** The accepted figure was 26 effective against a 25 bound; the measured figure with Phase 2 included is roughly 59. That is a decision the operator has not yet been asked to make.

### Cross-references

The fork record and slice plan live at `core/references/reference/operator-instance-home-and-isolation-key.md` — the single authoritative home for both. Work-tracker comments that mirror them are copies for card-completion purposes, not second sources.

---

## Issue References

The label-to-number binding for this release. Each entry carries a summary noun phrase so the meaning survives if a number rots.

- `SPIKE-FORKS` — **#3615** — the thread-A spike resolving the operator-instance home design forks and computing the relocation blast radius.
- `DISCOVERY-CTX` — **#5161** — the thread-B discovery slice measuring runtime context-resolution semantics for the operations workspace.
- `DEC-HOME` — **#5589** — the tracking home for the home-class question and the isolation-key dimension added to it.
- `OBS-CONFIG` — **#4038** — the observation that the platform-config template is written to one home and read from another.
- `UMB-RELOCATE` — **#3382** — the umbrella proposing relocation of the operator-instance runtime-state default out of the personal namespace.
- `BLD-ANCHOR` — **#4896** — the build card anchoring the operations workspace so a session rooted there resolves its procedure set.
