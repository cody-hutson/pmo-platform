---
title: Operator-Instance Home and Isolation Key — resolved fork record + relocation slice plan
purpose: Records how the operator-instance runtime-state family resolves today, resolves the six design forks governing its relocation out of the personal namespace, and carries the ordered slice plan the relocation build consumes.
type: reference
status: ACTIVE
reversibility: MODERATE / Confidence MEDIUM
consumers: the relocation umbrella's child slices; the home-class decision card; the platform-config write/read divergence card; the supersession ADR authored as fork 4's deliverable
---
# Operator-Instance Home and Isolation Key

**What this is.** The resolved fork record for the operator-instance runtime-state relocation, plus the ordered slice plan the relocation build consumes. It is the single authoritative home for both; the work-tracker comments that mirror it are copies for card-completion purposes, not second sources.

**Baseline.** Every measurement below was taken at the release's own pinned base — mainline commit `130a1e6b`, 2026-08-16 — not inherited from the cards. Each probe records its invocation and both control arms.

**Durability note.** This record is an *interim* home. Fork 4 resolves to author a supersession ADR at the relocation; when that ADR lands it absorbs §2's decisions and this file reduces to the current-state description in §1 plus the slice plan in §3.

---

## 1. How the family resolves today (measured, not asserted)

### 1.1 The split already runs in code

The platform does **not** have a single undifferentiated home. It already runs a two-way split, and that split matches what the distribution ADR's fourth decision wrote:

| Class | Home | Where this is implemented |
|---|---|---|
| **Configuration** — the operator's declared choices | XDG config root, defaulting to `${HOME}/.config/pmo-platform/` | The workspace-setup script writes `operator.toml` there and self-labels the location canonical; the instance-path library reads every override key back from the same location |
| **Runtime state** — machine-written data | Workspace-relative, defaulting to `${CLAUDE_WORKSPACE_ROOT}/personal/pmo-instance/` | The instance-path library's base resolver |

This matters because the fork set as originally written asked the platform to *choose* between workspace-relative, XDG, and a split — as though none were in force. One already is. The question was therefore never a three-way design choice; it was whether to **ratify** the running split and repair the surfaces that deviate from it.

### 1.2 The distribution ADR already stated the rule — including a clause that bounds it

The fourth decision of the distribution ADR is titled for the split directly: operator content stays workspace-relative, and only derived internals go to XDG state or cache. It fixes three destinations — configuration to XDG config, content workspace-relative, derived internals to XDG state or cache — and closes with two clauses that are load-bearing here and are easy to miss:

> the derived-internals routing is *"a refinement to apply as such artifacts are added; it is not a relocation of existing content"*, and the decision's net statement ends *"No mass migration."*

That clause is what keeps this relocation cheap. Several current members of the runtime-state family — the pipeline event log, the FinOps telemetry store, the two ambient run-logs, the external-sync snapshot — are, in the ADR's own vocabulary, *derived internals* presently sitting in the content tree. Read without the bounding clause, the ADR appears to demand that they move to XDG state, which would convert a one-leaf relocation into a three-home re-homing. Read with it, the ADR explicitly declines that migration for existing content and applies the rule prospectively.

**Consequence recorded so it is not re-opened:** the family's heterogeneity under the derived-internals rule is *known, pre-existing, and deliberately un-migrated*. It is not a defect this relocation introduces, and it is not scope this relocation carries.

### 1.3 The one confirmed deviation

Exactly one surface sits on the wrong side of the running split: the platform-config template. The composition-surface manifest writes it to the **instance** tier, while the deploy script resolves it from the **XDG config** root. An operator editing the installed file sees no effect at resolve time.

The read side is **wider than the divergence card records**. Measured at the pinned base, the deploy script resolves the XDG config root at **4** call sites, not one; a repo-wide sweep finds **21** files referencing that root. This materially changes the cost comparison the divergence card sets up — see §2.7.

### 1.4 Measured reference surface

| Probe | Invocation | Subject | Sensitivity arm | Specificity arm |
|---|---|---|---|---|
| Total tracked references | reference sweep for the instance leaf at `130a1e6b` | **57** | resolver symbol → **34** | nonsense token → **0** |
| Immutable / live split | prefix classification over the 57 | **14 immutable / 43 live movers** | 14 enumerated | — |
| Detector sibling forms | sweep for the two sibling leaves | **1 file each** | — | both arms extract |
| Deploy-script inline fallthroughs | sweep for the inline instance-path default | **0** | repo-wide → 8 files | — |

Both arms are valid on every probe with a zero: the specificity arm returns zero and the sensitivity arm returns non-zero, so each reported zero is a real absence rather than a failed read.

### 1.5 The immutable/live classification rule applied

The two edge cases the planning stage flagged were adjudicated by a single stated rule, applied uniformly:

> **A reference is immutable when it records what was true at a past moment; it is live when it states what the platform does now.** The test is the tense of the claim, not the folder the file sits in.

- **The ADR index** — counted **immutable**. Its reference sits inside a restatement of a past decision's summary. Editing it would falsify the record of what that decision said. The index legitimately *grows* as new decisions are added; growth is not mutation of an existing row, so "immutable" and "append-target" are compatible here.
- **The release-body pre-capture** — reclassified to **immutable**, against its earlier count as a live mover. It is a snapshot of published release bodies taken before an overwrite; its content is historical by construction.

**Net effect:** the immutable set is **14**, not 13, and the live mover set is **43**, not 44. The guard asserting the immutable set is untouched must be widened by the pre-capture path, or a correct sweep will appear to violate it.

> **Do not read the 43 as a vindication of the original estimate.** The card's original figure of 43 was a count of *total tracked references*, of which roughly 29 were thought to be movers. The 43 here is the *live-mover* count out of 57 total. The two numbers are equal by coincidence and are measuring different sets; the mover set has grown by roughly half since the card was written.

---

## 2. The six forks, resolved

Forks 0a and 0b were resolved together, not in sequence. Forks 2 and 3 were re-derived from live state before being resolved, because all three sibling cards they were originally scoped against have since closed.

### 2.1 Fork 0a — what class of home does platform-written state use?

**Decision: (c) the split — ratified as already written and already running, with the leaf corrected.**

- **Configuration** (the operator's declared choices) → **XDG config root**. Already in force.
- **Runtime state** (machine-written data) → **workspace-relative**, moving from the personal namespace to the workspace-root home `${CLAUDE_WORKSPACE_ROOT}/pmo-instance/`.
- **Derived internals** → XDG state or cache **prospectively, for newly added artifacts only**. Existing members are not migrated, per the bounding clause in §1.2.

**Rationale.** This is not a new convention. It is the distribution ADR's fourth decision restated, plus the leaf correction the relocation umbrella asks for. The personal-namespace nesting was never ratified by any ADR — it traces to a reorganization working note — so correcting it *realigns with* the ADR rather than superseding it.

**Standing obligation this creates** — the thing the home-class card actually asked for: every future operator-instance path token, at registration, states which of the three classes it belongs to. A token whose class is not stated is not registered.

**Reversibility: MODERATE · Confidence HIGH.** The decision is cheap; the migration it authorizes is not.

### 2.2 Fork 0b — what is the home keyed on when the toolkit runs against more than one target?

**Decision: target-slug namespace, recorded now, built later.**

The key is a target segment beneath the instance home — owner and repository — so that state for two targets cannot collide in one home. Selected over the two alternatives on these grounds:

- **Workspace-keyed** (one workspace root per target) is the lightest code change and the heaviest operator change: it requires the operator to relocate a target that currently lives inside the working workspace. It shifts a cost the platform created onto the operator.
- **Repo-local** (a git-ignored corpus inside each target's own tree) requires write access to every target and re-opens the in-repository-leak question once per target. At least one live target is a public repository with restricted write, so the shape is not universally available.
- **Target-slug namespace** is the only shape that survives both a second target and the eventual removal of the in-tree corpus tier, and adding a fifth constraint to the corpus-home constraints document is explicitly safe where renumbering the existing four is not.

**Scope bound: this fork is decision-scoped in this release.** The maximum in-release artifact is one added constraint row. No path gains a target segment in this release.

**Urgency, corrected downward.** The home-class card argued 0b was urgent because the corpus-split migration would remove the in-tree tier that currently masks the multi-target case. §2.6 establishes that migration is *not scheduled*. The masking therefore persists, and 0b's urgency is lower than the card assumed — which is the reason it is safe to record the decision without building it.

**Reversibility: CHEAP · Confidence MEDIUM** to record. **EXPENSIVE** to retrofit after both the relocation and any future corpus migration have executed against a single-keyed home.

### 2.3 Fork 1 — family scope: move only the runtime-state member, or the whole personal-namespace family?

**Decision: move only the runtime-state member. The other two are already gone.**

Measured at the pinned base, the two sibling leaves the detector recognizes alongside the runtime-state leaf appear in **exactly one tracked file each — the detector's own pattern definition and its own self-test fixture.** They have no other consumer anywhere in the repository.

The reason is that both already left:

- The **analysis** member's registered token now defaults to an **in-repo** workspace, not the personal namespace.
- The **roadmaps** member's token likewise moved to an in-repo home under an earlier ADR, which drew exactly the cut this fork asks about: authored content ships in-repo, runtime state stays operator-local.
- The **harness** member is not a registered token at all — it is operator working material the platform never writes.

So the fork's premise — a family of three that must move together or be split — no longer describes the corpus. There is one platform-written member left to move.

**This collapses the risk the card predicted.** The registered concern was that a runtime-state-only answer would strand two siblings inside the detector's recognized set. They are *already* stranded, and were stranded by earlier decisions, not by this one. The correct disposition is therefore a detector question, not a relocation question: see §3 slice 3.

**Reversibility: CHEAP · Confidence HIGH.**

### 2.4 Fork 2 — inline fallbacks: converge onto the resolver, or retarget in place?

**Re-derived first.** The sibling card this fork's convergence overlap was scoped against has closed, having converged one consumer onto its accessor. That is the precedent, not a competing effort.

**Decision: converge. Retargeting in place is not a live option.**

The measured surface is much smaller and much sharper than the card's "roughly five sites":

| Site | State at the pinned base |
|---|---|
| Deploy script | **Converged.** It sources the library and calls the accessor. The 21 inline fallthroughs the corpus-split ADR named as outstanding convergence debt are **gone** — measured 0 |
| Install validator, workspace-setup script, corpus-closeout tool, pre-commit hook | **Source the resolver.** Their remaining literals are prose, messages, or comments |
| Pre-commit hook | **Converged by design** — where the library is unreachable it degrades to empty resolution rather than re-deriving the path inline, and says so |
| **Pipeline-event append tool** | **Not converged** — one executable inline default |
| **Pipeline-event query tool** | **Not converged** — one executable inline default |

So the genuine un-converged executable set is **two files**, and both resolve the same path.

**What forces the answer.** The resolver *already exposes* a three-tier accessor for that exact path — environment variable, then the operator-config key, then the default. The two tools implement a **one-tier** inline version of it. They therefore **ignore the operator-config override**: an operator who sets that key has it honored by the deploy check and ignored by the event-log writer and reader. That is a live split-brain defect today, independent of any relocation. "Retarget in place" would mean maintaining a second, weaker resolution of a path that already has a canonical accessor.

**Reversibility: CHEAP · Confidence HIGH.** This slice is independently valuable and lands first.

### 2.5 Fork 3 — sequencing against the deferred release-corpus migration

**Re-derived first, and the re-derivation changes the answer.** This fork asked whether to relocate before the corpus-split ADR's deferred migration executes, or to sequence the two together. Both options presuppose that the migration is pending and scheduled. Measured:

- The execution card the ADR named is **closed**.
- The repository ignore rules contain **no** entry for the release corpus.
- **413 corpus files remain tracked.** The migration did not execute.
- No open card anywhere tracks the ADR's deferred migration.
- What *did* land is a different mechanism: a config-driven corpus-home **adapter** that tolerates an instance corpus without requiring the in-tree corpus to move. Its committed arming sentinel reads `armed`, so the seam is live; the in-tree tier simply wins first.

**Decision: the fork is moot on its original terms; no sequencing decision is required.** There is no scheduled migration to sequence against. What survives is not a sequencing choice but a **file dependency inside the relocation**: the corpus-home adapter computes its own instance root, so the relocation must update the adapter's instance tier in lockstep or that tier will probe the old home. That is slice 2 in §3.

**Finding surfaced, not actioned — this is outside the spike's scope to fix.** The corpus-split ADR still declares an obligation that "a deferred execution issue must" discharge. That issue closed without discharging it, no successor exists, and the ADR reads as though the work is still queued. Either the ADR's deferred-migration section needs a superseded-by note pointing at the adapter, or a successor card needs to exist. Recorded here so the next reader does not re-derive it a third time.

**Reversibility: CHEAP · Confidence HIGH.**

### 2.6 Fork 4 — author a supersession ADR?

**Decision: yes, and it supersedes less than the card assumed.**

The ADR records the home-class ratification (§2.1), the isolation-key decision (§2.2), and the leaf move. Its supersession target is **not** the distribution ADR's fourth decision — the relocation *realigns with* that decision rather than reversing it. What it supersedes in part is the unratified reorganization-note convention that placed runtime state inside the personal namespace in the first place.

It follows the pattern of the earlier in-repo-home ADR, which is the executed precedent for relocating one family member's canonical default across the SSOT surfaces with a copy-migration and preserved overrides.

**Number allocation:** taken at authoring time from the ADR numbering tool, never reserved in advance — a reserved number above an unmerged sibling's claim blocks the repository, whereas a duplicate is tooled.

**Reversibility: CHEAP · Confidence HIGH.**

### 2.7 Consequence for the platform-config write/read divergence

The divergence card's fix has two directions, and this record prices both so the choice is made on cost rather than symmetry:

| Direction | What it costs |
|---|---|
| **Installer writes to the read-path** (add an XDG/config destination tier to the composition manifest) | The manifest declares exactly **4** destination tiers and none of them is a config tier, so this adds a **fifth** tier and edits the composition-surface spec. It collides with a sibling milestone registering a different surface against the same manifest — two milestones adding tiers to one manifest concurrently is a merge collision |
| **Resolver reads the write-path** (point the deploy script at the instance home) | One line in principle, **four call sites** in fact, and it re-opens the very split fork 0a just ratified — configuration would move out of XDG config, contradicting both the running behavior and the distribution ADR |

**Direction selected as the fork-0a consequence: installer writes to the read-path.** Configuration belongs in the XDG config root under §2.1; the deviating surface is the *writer*, so the writer is what changes. The manifest gains a config tier. The collision risk is real and is managed by coordinating with the sibling milestone before the edit lands, not by choosing the direction that contradicts the ratified split.

---

## 3. Ordered slice plan

Ten slices. The order is a dependency order, not a preference: the detector must recognize the new form **before** anything writes it, and the convergence slices must land **before** the resolver flips so the flip has one resolution site rather than three.

Sizes use the platform's discrete buckets — one bucket per slice, never a range.

| # | Slice | Scope | Size |
|---|---|---|---|
| 1 | **Converge the pipeline-event tools onto the evals-results accessor** | Replace the one-tier inline default in the event-log append and query tools with the resolver's existing three-tier accessor. Fixes a live split-brain in which both tools ignore the operator-config override. Independently valuable; carries no relocation dependency | `size:S` |
| 2 | **Converge the corpus-home adapter's instance tier onto the resolver** | The closeout tool computes its own instance root inline. Route it through the resolver so the adapter's instance tier follows the relocation automatically. Update the tolerance suite alongside | `size:S` |
| 3 | **Teach the path-leak detector the new sanctioned form, and dispose of the vestigial siblings** | Add the workspace-root form to the recognized alternation while the old form stays recognized — a deliberate both-forms window so in-flight operator instances are still protected. Decide and record whether the two vestigial sibling forms (§2.3) stay recognized defensively or are dropped. Detector-first: nothing may write the new form before the detector knows it. Four files to edit, **five** to re-test — the consuming hook carries no literal but must be re-run | `size:M` |
| 4 | **Flip the resolver default, copy-first** | Change the single canonical default in the instance-path library. **Hard precondition, not a discovery item:** copy the existing instance directory to the new home, flip the resolver, verify the pre-commit hook resolves its needle file at the new home, and only then remove the originals. The hook fails **open** when its needle file is missing, so an un-copied needle silently disables personal-data blocking | `size:M` |
| 5 | **Update the SSOT surfaces** | The token registry's canonical-defaults table and prose, and the operator-config template's commented defaults. These are the declared source of truth for the defaults and must agree with the resolver exactly | `size:S` |
| 6 | **Update the installer and validator surface** | Workspace-setup script, install validator, and repository ignore rules. **Cross-thread contended** — the workspace-anchoring card edits the same three files, so this slice and that card must not run concurrently | `size:S` |
| 7 | **Update the prose corpus** | Roughly fifteen documentation and standards files carrying the old path in descriptive prose: the workspace-setup guide (the convention's origin), the getting-started, install and update guides, the platform-config reference, the three ambient-capability standards, hub-session continuity, the composition-surface spec, the deploy-tools readme, two operations templates, the daily-status skill and its digest reference, three release-reference documents, and the release-tooling smoke workflow. Read-before-edit per file — this is a sweep, not a find-and-replace | `size:M` |
| 8 | **Update the FinOps subsystem references** | The usage-store schema, the extractor skill definition, its four scripts, and its expected-output test fixture. Separated because a fixture change needs its own re-test and the subsystem is self-contained | `size:S` |
| 9 | **Close the both-forms window** | After migration is confirmed on the operator instance, drop the old form from the detector's recognized set and update its fixtures. Deliberately last and deliberately separate — closing the window early strands any un-migrated instance | `size:XS` |
| 10 | **Author the supersession ADR** | Record the home-class ratification, the isolation-key decision, the leaf move, and the migration procedure including the needle-continuity step. Supersedes in part the unratified placement convention, not the distribution ADR's fourth decision | `size:S` |

### 3.1 Sizing arithmetic, stated rather than left to be discovered

Raw points on the platform's scale: 2 + 2 + 4 + 4 + 2 + 2 + 4 + 2 + 1 + 2 = **25 raw**, added to the release's existing 20 raw for a bundle total of **45 raw**. At the `cross-cutting` weight of 1.3 that is **≈59 effective against a 25 bound**.

The release already accepted a breach at 26 effective. This slice plan takes the figure well past that. **The arithmetic is stated here rather than absorbed silently** — the operator accepted a known breach, not an open-ended one, and the difference between 26 and 59 is a decision the operator has not yet been asked to make. Routed as a scope finding at the Stage-9 gate.

The natural cleave, if a split is wanted: **slices 1–2 are independently valuable and carry no relocation dependency** — they fix a live override-ignoring defect and a tier-coupling gap on their own merits. Slices 3–9 are the relocation proper and are only coherent together. Slice 10 records whatever ships.

### 3.2 Preconditions binding every slice

1. **Detector before writer.** Slice 3 lands before any slice writes the new form.
2. **Copy before flip before verify before delete.** Slice 4's sequence is a hard precondition, not a recommendation. The failure mode is silent: the pre-commit personal-data hook fails open on a missing needle file.
3. **Immutable set untouched.** The 14 files enumerated in §1.5 are historical records and are correct as written. A sweep that edits them corrupts the audit trail.
4. **Cross-thread serialization.** Slice 6 shares three files with the workspace-anchoring card; the two do not run concurrently.

---

## 4. Card references

The work-tracker binding for this record. Each entry carries a summary noun phrase so the meaning survives if a number rots.

- **#3615** — the spike this record is the deliverable of: resolve the design forks and compute the relocation blast radius.
- **#3382** — the relocation umbrella whose child slices §3 defines.
- **#5589** — the tracking home for the home-class question and the isolation-key dimension; resolved by §2.1 and §2.2.
- **#4038** — the platform-config write/read divergence; its direction is set by §2.7.
- **#1184** — the adapter epic under which the corpus-home adapter was designed.
