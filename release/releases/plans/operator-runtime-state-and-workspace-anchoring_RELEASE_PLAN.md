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
| `FIX-CMDPOS` | The destructive-deletion guard does not fire when the command sits at a command-start position its anchor cannot see | bug | S | — |

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
core/deploy/tests/test_instance_path_roundtrip.sh
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
release/tools/tests/test_corpus_home_tolerance.sh
.github/workflows/release-tooling-smoke.yml
core/deploy/tests/test_version_stamping.sh
```

**Matrix caveat, stated rather than implied.** The final rows are conditional on the Phase-2 slice plan selecting them; they are listed because a Stage-7/8/9 chip that reads a short matrix and finds a longer diff cannot distinguish scope creep from a sanctioned late-add. Listing the anticipated set makes the late-add visible as an extension rather than a surprise. The last three rows were added when `SLICE-CORPUS-HOME` landed: its Stage-5 design measured that routing the close-out tool through the shared resolver cannot land without also carrying that resolver into the three trees that run the tool from a stripped copy — the tolerance fixtures, the CI precision probe, and the version-stamping harness's sourced slice. They are preconditions of the requested change rather than adjacent work, and one of them fails *upward* into a false green if left untreated, so they are recorded here as a sanctioned extension under this caveat. A new ADR file is expected under the platform ADR directory as fork 4's deliverable; its number is allocated at authoring time and is therefore not pre-listed here.

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
| R-11 | **Two deploy-side gates stop skipping and start evaluating on a workspace-root-configured instance, and a finding either raises is read as caused by this release.** Both `SLICE-EVENT-PATH` consumers — Check 19 and the decision-emission gate — resolve the event log through the shared resolver. Until this release that resolver's workspace-root cascade was narrower than the writer's, so on any instance setting `WORKSPACE_ROOT` or the operator.toml `claude_workspace_root` key both gates resolved to a directory the writer never wrote to and took their benign-absence SKIP branch. They were **vacuous, not passing**. After the fix they read the real log and evaluate for the first time on that instance class | Verification integrity | MODERATE | The two gates escalate **differently**, so one release-note sentence does not cover both. Check 19: `flag_warn_or_issue` — `enforce` adds an issue, `warn` emits a WARN plus a warn-log row. Decision-emission gate: `SKIP` becomes `INCOMPLETE`, which Check 61 escalates through `resolve_check_mode "decision-emission" "warn"` — and that resolver reads an **operator-instance mode file first**, so an operator who has flipped it locally gets an issue rather than a warn; separately `--check-decision-emission` exits 1 iff the committed `.github/decision-emission.enforce` sentinel reads `enforce` (it ships `warn`). Both sentinels ship warn-mode, so the default-instance blast radius is a warn line, not a red. **Release notes MUST state, for both gates, that a first-run finding after upgrade is a pre-existing condition being revealed, not one this change caused.** Default instances and CI are unaffected — CI sets neither root variable, and the resolved path is byte-identical there | CHEAP · HIGH |

| R-12 | **Two `SLICE-CORPUS-HOME` behaviour deltas reach operators, and the obvious way to write either one down is wrong.** (a) The close-out tool's hub-state default now resolves through the instance accessor, so on an instance relocated by `PMO_INSTANCE_PATH` hub-state follows the instance root where it previously stayed behind. (b) An operator whose `operator.toml` exists but omits `claude_workspace_root` finds the tool **starts working** — today it aborts at load on every invocation with exit 1 and no output | Operator-visible behaviour | MODERATE | **(a) is conditional and MUST NOT be stated unconditionally.** The composite precedence is `HUB_STATE_PATH` env → operator.toml `operator_instance_hub_state_path` → `PMO_INSTANCE_PATH` → the workspace-root-rooted default. The instance variable therefore sits **below** a config key, inverting the resolver's own instance-variable-is-highest convention for this one surface — defensible, because a key naming *this* directory beats a coarse whole-instance relocation, but new, so it is stated rather than inferred. Measured: with the dedicated key set, the resolved value is **identical before and after** (the `:-` default never evaluates), so an operator carrying that key sees no change at all. A release note saying "hub-state now follows the instance root" without that qualifier is false for exactly the operators most likely to have relocated. **(b) must be framed as a pre-existing condition being fixed, not a new capability.** The self-test reassigns the variable at runtime and `--check-paths` returns before any hub-state read, so no fixture or self-test verdict moves | CHEAP · HIGH |

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

> **Currency note.** This section is authored incrementally. It currently reflects **Phase 0, both threads**, the **`OBS-CONFIG`** and **`BLD-ANCHOR`** cards in Phase 1, and the first two Phase-2 convergence slices **`SLICE-EVENT-PATH`** and **`SLICE-CORPUS-HOME`**. Each subsequent Stage-6 spoke refreshes it as its card lands, and it is complete before the PR is transitioned to ready-for-review at the Stage-9 gate.

### Outcome

The release opens by answering the question every other card in it was waiting on: **what class of home does platform-written state use, and what is that home keyed on?** The answer turned out to be cheaper than the milestone assumed. The platform *already* runs the split the fork set asked it to choose — configuration in the XDG config root, runtime state workspace-relative — and the distribution ADR's fourth decision already wrote that rule down. So the home-class fork resolves to **ratification plus one repair**, not a three-way design choice, and the relocation it unblocks is a leaf correction rather than a re-architecture.

Two of the six forks turned out to be asking about a world that no longer exists, which is exactly what the planning stage flagged and required this spike to re-check. The inline-fallback fork was scoped against roughly five un-converged sites; **two** remain, and the deploy script's twenty-one declared fallthroughs measure **zero** — that convergence debt was paid without anyone updating the card. The sequencing fork asked how to order against a pending corpus migration that, measured, **never executed and has no successor** — the platform solved that problem a different way, with a tolerance adapter that is live and armed. Both forks were re-derived from current state before being resolved rather than answered against their stale framing.

Thread B's discovery slice returns a result the gate needs to see plainly: **the runtime's context-resolution semantics could not be measured on this instance, and the record says so rather than inferring them.** Four independent instruments were tried. Purpose-built context-file fixtures cannot be created — the platform's own autonomy-ceiling control refuses any file carrying the context-file basename, at any path. A fresh non-interactive session, which would have read its own resolved context back, cannot authenticate. Startup diagnostics die with it. And the session store, which records a real session that ran at exactly the directories in question, turns out not to persist the resolved context set at all — proven by running the same probe against a session whose loaded context is known with certainty and getting the same zero.

What the slice did establish is the surrounding state, measured with both control arms: the operations workspace still carries no context file at its root or anywhere on the path up to the workspace charter, no user-scope carrier exists, and the charter uses linking rather than inclusion. It also found that session identity is keyed by working directory rather than by context-file location, and that a spawned agent thread runs under its parent's key rather than its own — so any design resting on working-directory discovery needs separate confirmation for spawned threads. The three open questions — walk-up depth, whether several context files on one chain combine or the nearest wins, and scope precedence — are recorded as unmeasured with their reasons, together with the procedure that would answer them where a session can authenticate. **The design card therefore does not receive the measured input the plan promised it**, and that is a gate decision rather than something for this spoke to paper over. *(Superseded within this release — see the re-measurement below. The record on this branch now carries the measured semantics, not the unmeasured verdicts described in this paragraph.)*

**Phase 1's config card turned out to be reporting a real defect for the wrong reason, and fixing it properly meant fixing a second one underneath.** The card said an operator who edits the installed platform-config sees no effect because the resolver reads a different file. Measured, the resolver already reads the shipped template in place from the clone, so the defaults were never missing. What was actually wrong is narrower and worse: the composition manifest was installing a further full copy of that 23 KB template into the operator-instance home that **no code path read at all**, while shipping it with an empty operator-additions fence that invited edits taking no effect. The fix is therefore a deletion, not a relocation — the orphan row comes out and the template is recorded as what it has always behaved like, a file read in place from the clone.

That reframing also disqualified the mechanism the spike's fork record had selected. Registering the operator's own config file as a composition surface would have put it under update-time regeneration, and the regeneration contract discards operator content that sits outside a fence. The live file carries no fences — its entire content is the operator's security-hooks master enable — so the first update after that change would have silently switched the operator's workflow-hook posture back off. That was caught by design review, not by any check, and the fork record's §2.7 is reconciled in the same commit as the manifest edit: its principle stands, its mechanism does not.

**Underneath the reported defect sat an inverted precedence order, and it is corrected here rather than filed.** Governance states deliberately that an individual operator's own override is the *highest*-precedence rung — more specific than a project setting, and winning over it. The resolver did the opposite: it folded the operator's file in at the lowest rung and then let the portfolio, program and project rungs overwrite it, with no diagnostic. A flat `key = value` line in a portfolio or project file silently beat the operator's explicit setting. Measured before and after against the real resolver bytes with both control arms and a restore-check: before, a value set in both the operator's file and the portfolio file resolved to the portfolio's; after, it resolves to the operator's, while a value set only in the shipped template still resolves to the template's. This is the same defect the card reports, one layer in — the operator edits the right file and still does not get their value — so leaving it filed while shipping "your edit now takes effect" would have been misleading.

**The measurement that could not be taken was taken, and it changed what the anchor is for.** Re-reading the reproduction procedure dissolved the blocker: it needs **no fixtures** — a directory chain already carrying context at more than one level does the job — and the session that could not authenticate had an expired login, not an architectural limit. Measured, walk-up is **CONFIRMED** and precedence is **ACCUMULATIVE with ancestor-first ordering**. That second result is the one the whole design rests on: under the intuitive nearest-wins model, a context file placed at the operations-workspace root would have **displaced** the workspace charter for every session beneath it — strictly worse than shipping nothing. Adversarial review then caught that the re-measurement had covered a session root that carried *its own* context file, which is not the configuration an anchor runs in; the missing arm — root carrying none, two ancestors each carrying one — was run, both ancestors loaded, and the depth floor rose from two levels to **three**. The upper bound remains **UNMEASURED**, and three levels is the floor rather than the ceiling: nothing here says where resolution stops, and no artifact in this release claims a bound.

**The anchor is not a rescue for a broken load — it is a shortening, a declaration, and an extension point.** Because the charter does resolve by walk-up, the card's framing that operations-rooted sessions get no platform context is false at shallow roots. What the anchor buys is that the worst-case distance to *some* governance-bearing context file drops to two levels, inside the measured band rather than beyond it; that the platform now **declares** what an operations-rooted session loads, where before nothing did; and that the sibling rules-mirror card inherits one carrier instead of standing up a second. It is pointer-only by construction and, better, pointer-only by enforcement: the autonomy-ceiling control blocks writes to that basename unconditionally, so the installer can lay it down and no agent can ever hand-edit it. The reference-never-restate invariant is held by a control rather than by review discipline — verified on a real install, where the anchor's twenty-two content lines share **zero** lines with the charter or the operations governance file.

**Adding a second file named `CLAUDE.md` broke something nobody had enumerated, and it was found by running the standing suite rather than by reading the code.** The update path keyed its backup filenames on basename alone. With two manifest rows resolving to that basename, `./update.sh --force-regen` regenerates both within the same second, into the same timestamped backup directory — and the second pre-write copy silently overwrote the first. That backup is the recovery path the charter's regeneration contract depends on. Backups are now keyed on tier plus basename, which is unique across the manifest, and the operator-facing messages name the tier so two files called `CLAUDE.md` are distinguishable. The regression suite caught it as a red resolver arm whose probe had been reading the wrong file's absence; that probe is now tier-qualified too.

**The first convergence slice reported its own defect backwards, and the real one was the inverse.** The card said the two pipeline-event tools carried a one-tier default and therefore ignored the operator's configured path. Measured, both already ran the full three-rung ladder and that override already worked. What was actually broken was the **shared resolver** the card wanted them to call — the one surface whose own header promised it mirrored the writer *so a reader can never resolve somewhere the writer does not write*. It did not mirror it. The writer's workspace-root fallback had four steps; the resolver's had two. So converging the tools onto the resolver exactly as the card worded it would have **caused** the defect the card claimed to fix: it would have silenced a registered configuration key on the event log's own write path. The fix is therefore to complete the resolver first and then converge, which leaves both tools behaving identically in every configuration measured and moves the two consumers that were reading the wrong directory onto the right one.

**Those two consumers were not failing — they were not running.** On any instance setting a workspace root through the environment or the operator's own config, the deploy check that audits the event log and the decision-emission gate both resolved to a directory the log was never written to, found nothing, and took their benign-absence skip. A check that skips from an empty denominator looks identical to a check that passes. After this change both evaluate for the first time on that instance class, which means either can now surface a finding it was previously incapable of surfacing. That is the fix working, and it is why the release note owes an explicit sentence — for **both** gates, whose escalation paths differ — saying that a first-run finding after upgrade is a pre-existing condition being revealed rather than one this change caused. Default instances and continuous integration are untouched: neither sets a workspace root, so the resolved path is byte-identical there.

**The regression guard was rewritten because the one the design specified could not fail.** The design asked for an assertion that the resolver and the reader tool agree on the path — but the same change makes the tool's path *be* the resolver's return value, so after convergence both sides of that comparison are one function and the assertion reduces to a tautology. It would have passed on the correct implementation and on a narrowed one alike. Each limb now pins the resolved path to a **literal expected value**, and those literals were not read back off the resolver: they were measured from where the writer actually created the log under each configuration, before the convergence landed. The guard was then proven capable of failing rather than assumed to be — a one-line mutant that removes the configuration tier reddens exactly that limb and no other, a second that restores the old narrow fallback reddens both override limbs while the no-override control stays green, and restoring the correct code returns it to green.

**The second convergence slice had the same shape as the first and the opposite answer, and the difference is which of two accessors you pick.** The card asked for the close-out tool's instance root to route through the shared resolver, and that request is correct — the tool spells the operator-instance leaf twice, so a relocation would strand both. But the resolver offers two accessors, and the obvious reading of "route it through the resolver" selects the wrong one: the no-arg form rebuilds its own two-step base and would have discarded the environment override and the configuration key that this tool's own four-step cascade resolves. Measured, that reading diverges in five of nine configurations while the arg-taking form — the one whose header already names this exact call shape, a caller that holds a workspace root and must keep it — agrees in nine of nine. So unlike the first slice, nothing in the resolver needed widening; the whole risk was in the choice, and the choice was made on measurement rather than on the card's wording.

**The suite that would have graded it could not see the difference, and that was proven rather than suspected.** The tolerance fixtures pin exactly the two resolution tiers at which the two accessors cannot differ, and short-circuit the cascade before the configuration tier is ever consulted — so the fixture matrix is blind by construction to the one thing this change could get wrong. A new arm closes that gap, and it deliberately does not reuse the fixture runner whose pins are the cause of the blindness: each limb states its whole environment explicitly and seeds its own configuration file, because the specificity limb is *defined* by the absence of the key the other limbs require. Its assertions are pinned to expected literals rather than to what the resolver returns, so a future narrowing cannot move both sides of the comparison together. It was then proven capable of failing — dropping the environment tier reddens only that limb, dropping the configuration tier reddens only its two, and a no-arg convergence reddens three while the control limb stays green.

**Making the load fail-closed meant every tree that runs the tool from a stripped copy had to carry the resolver, and one of those trees fails upward.** Three consumers run this script from a directory tree that holds the script and nothing else. Two of them would have gone loudly red, which is the safe direction. The continuous-integration precision probe would not: its rule treats any non-zero exit as a successful detection, so a load-time abort would have made it print that the broken corpus path was correctly caught while never having reached the code that catches it — a green that had stopped measuring. It now carries the resolver, and the probe's exit code was read back from the job log to confirm it is still the check's own failure code rather than the abort's. Underneath all this sat a live silent failure that had nothing to do with relocation: an operator whose configuration file existed but omitted one optional key saw the tool abort at load, on every invocation, with exit 1 and no output at all. That is guarded now, and the new specificity limb is the executable proof of it.

### Issues resolved so far

| Card | State after this phase |
|---|---|
| `SPIKE-FORKS` | All three completion conditions met — six forks resolved, blast radius re-measured at this release's own base with both control arms, ordered slice plan authored. Ready to be marked as closed at Stage 13 |
| `DEC-HOME` | Its question is answered inside forks 0a and 0b. Stays open as the decision's tracking home through Stage 8; recommended to be marked as closed at Stage 13, superseded by the fork record |
| `OBS-CONFIG` | **Landed.** The orphan manifest row is deleted (20 rows to 19, with the manifest's self-declared count corrected in the same edit), the shipped template is recategorized from Composition-surface to Universal in the governing spec, the operator's own config file is named as the edit surface in the schema and the config reference, the fork record's §2.7 mechanism is reconciled, and the resolver's inverted rung precedence is corrected so the individual rung wins as governance specifies |
| `DISCOVERY-CTX` | **Findings record now carries measured semantics.** The three `UNMEASURED` verdicts are superseded: Shape A is `VIABLE`, Shape C is `VIABLE` at the depths measured, Shape B stays `UNMEASURED` because no pass exercised inclusion resolution and its reason is restated accurately rather than left citing a blocker that no longer applies. Five further probes recorded (P8–P12) with both control arms **and the directory layout each arm ran in** — the addition that lets a downstream consumer check a verdict's applicability instead of matching a token. Two open questions closed, four stated as still open, and the instruments table reconciled so a future reader does not re-attempt a route on stale information |
| `BLD-ANCHOR` | **Landed.** The anchor source, a new `operations-root` composition-surface tier (manifest row, resolver arm, installer parent pre-create), the manifest count moved 19 to 20, an `A5b` install-validation check that reports non-green when the anchor is absent, the Routing declaration in the charter template, and a Context-Load Contract in the operations bridge rule. Three review-found defects folded in as corrections, plus a fourth found here |
| `SLICE-EVENT-PATH` | **Landed.** The shared resolver's workspace-root fallback is widened from two steps to the writer's four, both pipeline-event tools drop their inline copies and call it behind a fail-closed load, the writer's out-of-tree self-test carries the resolver into its throwaway tree so the fail-closed load does not break a probe that passes today, a value-pinned cascade guard is added in two places — one of which has a pre-merge runner — and three surfaces that asserted the false mirroring guarantee are reconciled: the resolver header, the deploy check's own comment, and the token's read-source declaration in the governing spec |
| `SLICE-CORPUS-HOME` | **Landed.** Both of the close-out tool's inline instance-root sites — the corpus instance root and the hub-state default — now call the resolver's arg-taking accessor behind a fail-closed load; the tolerance fixtures and the CI precision probe carry the resolver into their stripped trees and the version-stamping harness pins it in its existing neutralization pipeline; a new tolerance arm covers the two resolution tiers the fixture matrix was blind to by construction, with per-limb environments, per-limb configuration seeding and value-pinned assertions, proven by three one-line mutants; the load-time abort on a present-but-partial configuration file inside the instance-root chain is guarded; an ambient-value hole that outranked the fixtures' own pin is closed; and the stale pre-seam posture claims in the suite, the workflow and the constraints standard are reconciled |
| `UMB-RELOCATE` | Not yet entered; unchanged by this phase |
| `FIX-CMDPOS` | **Landed, at four hooks rather than the one the card named.** The card was wrong twice — it named a hook file that does not exist, and it identified the discriminator as "inside a shell-function body" when a *multi-line* body already fired and the real boundary is whether the verb is the first token of a delimited segment. A fix built to the card's framing would have closed 3 of 26 gaps and shipped as a fix. All four hooks share one byte-identical anchor, so the blind spot was shared: the root-filesystem rule did not fire on `sudo rm -rf /` for the same reason. One shared canonicalizer now rewrites genuine command starts into positions the existing anchor recognises, consumed by all four hooks; anchors, rule patterns, rule IDs and messages are untouched. Measured per hook against 35 positional variants of the identical command: containment guard and boundary guard 9/35 → 28/35, credential-read guard 9/35 → 27/35, root-filesystem guard 9/35 → 21/35 — the last one's shortfall isolated by a two-arm probe to that rule's own terminator class, not to position. Zero regression and zero new false positives across all 379 committed fixture payloads × all 59 rule patterns in the four hooks |

### Key decisions

- **Home class:** ratify the running split; move the runtime-state leaf to the workspace-root home. The derived-internals tier stays prospective — the distribution ADR explicitly declines to migrate existing content, and that clause is what keeps this a one-leaf move.
- **Isolation key:** target-slug namespace, **recorded but not built** in this release. Its urgency is lower than assumed, because the masking condition the home-class card expected to disappear is not scheduled to disappear.
- **Family scope:** one member left to move. The other two already left under earlier decisions, which is why the predicted "two stranded siblings" residual measures one file each — both inside the detector itself.
- **Supersession ADR:** yes, but it supersedes the unratified reorganization convention, not the distribution ADR — the relocation realigns with that ADR rather than reversing it.
- **Config divergence:** close it by **deregistering** the orphan write, not by adding a destination tier. The fork record's principle — configuration belongs at the read-path, so the writer is what changes — is kept; its selected mechanism is rejected on safety grounds, because registering the operator's own config file would have let regeneration discard their security-hooks opt-in.
- **Category of the shipped template:** **Universal**, not Composition-surface. That is a recategorization, which the spec names a breaking change gated at Solutioning, and it is recorded at the governing spec rather than in a new ADR — the spec is the category source of truth, and the relocation's own supersession ADR absorbs it later.
- **Rung precedence:** corrected in this release rather than filed. The alternative was to ship working code that contradicts stated governance with no tracking item, which is the worse of the two.
- **Class versus instance:** three of the manifest's five operator-scoped rows carry the same writer-reader divergence, one of them with no card at all. This release ships the point fix; the invariant is *stated* in the spec, and *enforcing* it is filed as its own work rather than absorbed here.
- **Anchoring mechanism:** a pointer-only context file at the operations-workspace root, carried by a new composition-surface tier. Selected against measured runtime semantics rather than assumed ones — the findings record at `core/references/reference/claude-code-runtime-state.md` carries the verdict token **`VIABLE`** for that shape, measured in the configuration the anchor actually runs in. The carrier is the existing manifest rather than a bespoke installer function, because a row inherits install-if-missing, the operator-extension fence, tamper detection, update-time regeneration and a registered rollback op at zero marginal cost.
- **Operations-folder literal:** lifted to the resolver seam rather than spelled inside the composition resolver, whose own contract states that an operator-directory leaf literal lives only in the resolver. A future relocation of the operations sibling now re-points one function instead of hunting call sites. No new environment variable and no new config key were minted for it — the governing ADR forbids inventing a variable to fill a symmetry that buys nothing, and no operations-path token exists in the closed token vocabulary for a config tier to read.
- **Where the non-green check runs:** in the install sub-mode only. The pre-existing sub-mode SKIPs it, because that sub-mode's entire population is workspaces created before the installer that produces the anchor — running a real check there would fail workspaces that were healthy before this release and, through the mode gate, suppress their first-task validation entirely. The acceptance criterion asks for non-green when the artifact is absent on a workspace the installer has run against, which the install sub-mode supplies with a non-zero exit.
- **Anchor pointer base:** paths stated relative to the anchor's own location, not to the workspace root. The artifact exists precisely because the reader's working directory is *not* the workspace root and may be an unbounded distance from it, so a workspace-root-relative path has no computable base — and read cwd-relatively from the operations root, the first entry resolved to the anchor itself.
- **Backup key:** tier plus basename, not basename. Forced by this release rather than chosen: a second row resolving to `CLAUDE.md` made a basename-keyed backup collide with the charter's, silently, on the recovery path.
- **Convergence direction:** complete the shared resolver first, then converge onto it — never the reverse. Converging consumers onto an accessor that is *weaker* than the code it replaces closes a divergence by making the writer as wrong as the reader, and silently drops whatever overrides the accessor happens not to honour. The general form is now stated where the next converging consumer will read it: the resolver's header carries a per-function contract naming which environment variables and which configuration keys each function honours, and which it deliberately ignores. That is the field every future consumer has to know before it can safely stop resolving a path itself, and until now it could only be discovered by measurement.
- **Guard-fix scope — class, not instance.** The design scoped the command-position fix to one hook. The operator widened it to all four carrying the byte-identical anchor, on the grounds that shipping one hardened hook beside three with the same blind anchor reads as class closure when it is not. That is also why the residual is restated in the governing docs rather than left implicit.
- **How the widening is made false-positive-safe:** the anchor is *not* widened. The command is canonicalized first, so the regex never becomes the deny authority over a loose pattern. Two properties carry it — insertion-only on the syntactic axis (anything that matched before still matches), and quote-neutralized command-start detection (shell text carried as *content* is not a command). The second is load-bearing rather than cosmetic: two of the three measured false-positive shapes were **blocked before this change**, and neutralization is what makes them allow. A guard that fires on ordinary engineering work gets disabled by the operator, which is a worse security outcome than the gap it closed.
- **One implementation, four consumers — not four copies that agree today.** Four agreeing copies is precisely how this cohort drifted into a common blind spot. The shared primitive is carried as a co-shipped `lib/*.awk` guarded by the existing `deny_missing_primitive` contract, reusing the proven pattern rather than minting a new sourcing surface on a security hook. Each hook canaries it before trusting its output, because a truncated copy would emit an empty string and take the hook's whole matcher with it — a fail-OPEN strictly worse than the gap being closed.
- **Regression-guard form:** value assertions against measured literals, never parity between two sites the same change collapses into one. A parity assertion across a seam that convergence removes cannot fail, and a guard that cannot fail is the exact defect class this release exists to close. Guards are proven by mutant rather than asserted — the correct code and a deliberately broken copy must produce different verdicts, and the demonstration is recorded, not promised to a later stage.

### Reversibility

**CHEAP · HIGH** for Phase 0. Three documents landed: a release plan, a decision record, and a findings record. No resolver default moved, no detector pattern changed, no installed state was touched.

**CHEAP · HIGH** for the config card's documentation and manifest work — re-adding one array row and reverting prose. It is worth stating plainly that deregistration does **not** delete anything already installed: an operator instance carrying the stale copy keeps it, inert, exactly as before, because nothing ever read it. Nothing that worked stops working.

**CHEAP to revert · MODERATE in effect · confidence HIGH** for the precedence correction, and the three are deliberately separated. Reverting is one commit. The *effect* is a real behavior change on any instance that sets the same field both in the operator's own config and in a portfolio, program or project surface — that field now resolves to the operator's value where it previously resolved to the other one. That is the governed order being restored rather than a new choice, the change is measured in both directions against the real resolver, and the common case is unaffected: where only one rung sets a field, the resolved value is identical before and after.

**CHEAP · HIGH** for the anchoring card. One manifest row, one resolver arm, one resolver function, one installer line, one validator check, one template, and documentation. The installed anchor is inert — nothing reads it but a session, and its absence is the pre-change state — so rollback is a revert and an operator who already has the file keeps an accurate pointer list. The one non-inert change is the backup filename key: after a revert, a backup written under the new tier-qualified name is still present and readable, just under a name the reverted code no longer writes. No data is lost in either direction, which is the property the change exists to restore.

**CHEAP to revert · MODERATE in effect · confidence HIGH** for the event-path convergence slice, and again the three are separated deliberately. Reverting is one commit across six files, and no data moves — the event log stays where the writer already puts it. The *effect* is real on any instance carrying a workspace-root override: two deploy-side gates change which directory they read, from one the log was never in to the one it is in. Those gates therefore move from a vacuous skip to a live verdict, which is an increase in what they can report, not a decrease. Both ship in warn mode, so the default consequence is a warning line rather than a failure. On a default instance and in continuous integration the resolved path is byte-identical before and after, measured with a no-override control arm.

Rollback for the whole phase is a revert of the merge commit.

The tier rises sharply in Phase 2, and the plan says so rather than discovering it later: the relocation carries a copy-first data migration and a pre-commit hook that fails **open** if its needle file has not arrived at the new home before the resolver flips.

### Downstream impact

The slice plan is the load-bearing output. Its ten slices become the relocation umbrella's child work items through the late-add rule, and its stated dependency order is not cosmetic — the detector must learn the new path form **before** anything writes it, and the two convergence slices must land **before** the resolver flips so the flip has a single resolution site.

One finding materially affects the release's shape and is routed to the Stage-9 gate rather than absorbed: **the slice plan's arithmetic puts the bundle far past the sizing breach the operator accepted.** The accepted figure was 26 effective against a 25 bound; the measured figure with Phase 2 included is roughly 59. That is a decision the operator has not yet been asked to make.

The config card leaves the composition manifest **one row shorter**, and the anchor card adds a row and a destination tier to the same array. That is why the two are sequenced rather than run in parallel: deletion goes first, so the anchor card is not registering a tier next to a row that is about to disappear. The manifest also carries a self-declared row count that an enforcing check asserts against the actual rows, so any card changing manifest membership owes that numeral in the same commit — the config card set it to 19, and the anchor card moved it to **20**.

**The manifest's consumer set is larger than the sourcing graph shows, and that is now written down where the next author will find it.** Three consumers are invisible to the question "who sources or iterates the array": one that **regex-parses the file** (the QA count check, which reduces manifest membership to a single pass/fail verdict), one that **branches on a tier name downstream of resolution** (the update path's discard notice), and one that **filters the array before aggregating**, so its denominator is not the array's cardinality (the install validator's completeness check, whose tier switch silently drops any tier it does not handle). A fourth surfaced during this card's own build: a **message string derived from a manifest value**, grepped by a regression probe. The governing spec now states the enumeration rule — find every reader of a manifest-*derived* value, not every reader of the manifest — and records that adding a **tier** costs a resolver arm, a validator arm and any downstream tier-literal branch, not just a row.

**One decision is still open and is not this card's to make.** The design recommended a new architecture decision record for narrowing the sibling-model's never-writes absolute, and the sibling card recommended none this release on release-weight grounds. Collective Review recorded neither ruling. The narrowing itself is implemented and documented in the prose it governs; whether it also earns its own record is left to the gate rather than decided by a spoke.

### Cross-references

The fork record and slice plan live at `core/references/reference/operator-instance-home-and-isolation-key.md` — the single authoritative home for both. Work-tracker comments that mirror them are copies for card-completion purposes, not second sources.

---

## Domain Practice Provenance

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-16, domain: governance }` — every file in the change matrix is an internal pmo-platform artifact (governance, deploy tooling, ADRs, reference docs), so A1.5 external sourcing is not triggered; the deliverable class is nonetheless classified per the mandatory `domain:` field. Rationale from the matrix: `core/deploy/` + `core/standards/` + `core/ADRs/` + `docs/` + `core/rules/` dominate; the secondary domain is `software` (the four `core/deploy/*.sh` and `docs/scripts/*.sh` edits).

---

## Issue References

The label-to-number binding for this release. Each entry carries a summary noun phrase so the meaning survives if a number rots.

- `SLICE-CORPUS-HOME` — **#5635** — the second relocation convergence slice, routing the corpus-home adapter's close-out tool onto the shared instance-path resolver so its instance tier follows a relocation without a coordinated edit.
- `FIX-CMDPOS` — **#5644** — the late-added guard defect: the destructive-deletion guard evaluates lexical position rather than the action, so the same deletion changes verdict depending on where it sits; widened by operator decision to all four hooks carrying the shared anchor.
- `SPIKE-FORKS` — **#3615** — the thread-A spike resolving the operator-instance home design forks and computing the relocation blast radius.
- `DISCOVERY-CTX` — **#5161** — the thread-B discovery slice measuring runtime context-resolution semantics for the operations workspace.
- `DEC-HOME` — **#5589** — the tracking home for the home-class question and the isolation-key dimension added to it.
- `OBS-CONFIG` — **#4038** — the observation that the platform-config template is written to one home and read from another.
- `UMB-RELOCATE` — **#3382** — the umbrella proposing relocation of the operator-instance runtime-state default out of the personal namespace.
- `BLD-ANCHOR` — **#4896** — the build card anchoring the operations workspace so a session rooted there resolves its procedure set.
- `SLICE-EVENT-PATH` — **#5634** — the first relocation convergence slice, folding the pipeline-event writer and its reader onto the shared instance-path resolver after completing that resolver's workspace-root fallback.
