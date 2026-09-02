<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-173 — The lifecycle audit trail is retired from the index; frontmatter last-transition state is the only lifecycle state"
status: Proposed — flips to Accepted when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure or from a review comment.
date: 2026-09-02
release: pda-decisions-and-conformance-baseline
deciders: "Stage 5 Solutioning spoke (options analysis, evidence-grounding, blast radius) + adversarial design review (predicate-soundness finding) + operator at Collective Review scope-lock (binding predicate-repair entry condition; ratification at Stage 9) + Stage 6 Engineering spoke (authorship, repair-path selection)"
tags: [architecture, sqlite-index, lifecycle, audit-trail, disposable-cache, source-of-truth, health-check, domain-c, lifecycle-trigger, governed-vocabulary]
supersedes: none
source_observations:
  - "The index schema declares lifecycle_events an audit trail — one row per transition — inside a database the same schema declares a disposable cache that must rebuild identically. Both cannot hold, and the builder silently chose: a full rebuild unlinks the database and writes one initial row per file, so every rebuild destroys accumulated transition rows; the schema itself mandates a daily full rebuild."
  - "The rows never held transition facts. Every row's timestamp is the file's created_date and its agent is the managing skill, because the builder is forbidden to synthesize timestamps and no code path captures transition-time facts — the event source that would is explicitly deferred scope."
  - "A fixture falsification confirmed the mechanism: rebuild yields 8 rows; a state-changing update yields 9 (the control fired); a rebuild of the same mutated tree yields 8 — history destroyed."
  - "Exactly five files reference the table, and none of them is a runner: the builder, the schema, the two compliance specs that cite the trail, and the tools README. Zero executables outside the builder implement the event lookup the compliance claims require. The zero was measured three times independently (design, adversarial review, engineering), each with a sensitivity arm that fired and a specificity arm that stayed zero."
  - "The first restatement drafted for the published-without-approval check — an inequality against the trigger field's example value — was unsound: the trigger field is optional free text with no governed vocabulary, and the platform's only two committed published files both carry the mass-backfill trigger value, so the drafted predicate classified the check's entire committed test universe as violations on day one. The operator made repairing this a binding entry condition for authoring this record."
  - "The lifecycle protocol's transition table is exhaustive and admits exactly two edges into the published state, both human acts — initial approval and re-validation after source change. A closed approval-class vocabulary is therefore small, complete, and checkable."
  - "Merged records in the same season decided the adjacent defect classes this record leans on: a sink with no writer measures the wiring rather than the behaviour; an append-only log whose consumer needs history acquires retention obligations the moment it exists; and the founding ecosystem design rejected a centralized metadata registry precisely because metadata would diverge from files."
---

# ADR-173 — The lifecycle audit trail is retired from the index; frontmatter last-transition state is the only lifecycle state

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the Stage 9 Plan Review gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified.

**Numbering provenance.** Allocated at this Engineering commit as the next number above the union of the mainline anchor and this branch's own in-flight claims — never `max(claimed)+1`. `renumber-adr.py --detect` at the commit instant reported `ANCHOR 172 origin/main`, `NEXT-FREE 173`, `CLAIMED-SET-BRANCH-ONLY 173,174,175,176 (detection only — never binds)`, and `CLAIM NONE` for this tree. This branch carried no ADR of its own at allocation time, so the union is the mainline anchor alone and 173 binds here. The branch-only claims on 173–176 belong to other in-flight branches; a cross-branch collision is governed — resolved by the renumber tool at merge time, as this corpus has done before — and is never a reason to skip ahead.

## Context

The `lifecycle_events` table asserts two guarantees that cannot both hold. Principle 1 of the index schema: files are source of truth — deleting the database and rebuilding must produce an identical result. The table's own contract: an audit trail of lifecycle state changes, one row per transition. The builder resolved the contradiction silently in favour of rebuild identity: `--rebuild` unlinks the database and inserts one initial row per file; only a manual `update_file` call appends a transition row, and the schema mandates a daily full rebuild that destroys it. The rows are additionally not audit data even while they exist: `timestamp` is populated from the file's `created_date` and `agent` from `managed_by`, because the builder never synthesizes timestamps and nothing captures transition-time facts — the event source is deferred, open scope. Frontmatter — the declared source of truth — carries no history: only `lifecycle_state`, `lifecycle_changed`, and `lifecycle_trigger`, the last transition. The trail is therefore not derivable from files (violating principle 4), not identical across rebuilds (violating the checklist's identity assertion when included), and not satisfying the two compliance surfaces that cite it.

Retiring the table forces a second decision this record must also make soundly. The two compliance claims that cite the trail — the health-check's published-without-approval check and the lifecycle protocol's matching checklist item — need a replacement evidence source. The natural replacement, the frontmatter `lifecycle_trigger` field, is today declared optional free text: its schema row offers `human-approval` only as an illustrative example, the protocol instructs writers to stamp whatever caused the transition, and the corpus-scale backfill stamped `retroactive-backfill` as its marker value. An inequality test against one example string over that field is not a predicate over a closed set — it mis-classifies the platform's only two committed `published` files (both carry the backfill trigger) and reads every cause-named re-validation as a violation. A check that is computable but wrong is a worse failure class than the structurally-unsatisfiable claim it replaces, because it produces confident false violations. The restatement therefore ships only together with the field governance that makes it sound.

## Decision

### 1. The table is retired, with its schema claims

`lifecycle_events` is removed from the index schema and the builder: the table definition, its two indexes, rebuild-protocol step 8, incremental-protocol step 6, the invocation table's incremental-update trail-preservation wording, and the validation-checklist entry requiring at least one row per file. The equality-witness exclusion in the builder becomes moot and is removed with the table. The index returns to a pure projection of frontmatter.

### 2. Frontmatter last-transition state is the only lifecycle state

`lifecycle_state`, `lifecycle_changed`, and `lifecycle_trigger` — authored in each file's frontmatter at transition time, mirrored into the `files` table — are the platform's complete lifecycle state. Authority follows authorship: these are the only lifecycle facts anything authors, so they are the only lifecycle facts the platform asserts.

### 3. The approval-class trigger vocabulary is governed

Because `lifecycle_trigger` becomes the sole approval evidence for `published` files, the value set for transitions into `published` stops being free text and becomes a closed, governed vocabulary — one member per human edge in the protocol's exhaustive transition table:

| Inbound edge into `published` | Actor per protocol | Governed trigger value |
|---|---|---|
| `validated` → `published` | Human confirms synthesis is authoritative | `human-approval` |
| `stale` → `published` | Human re-validates after reviewing source changes | `human-re-validation` |

Both values form the **approval class**. The two-member form is chosen over collapsing both edges to a single token because the protocol's stamp contract records the *cause* of a transition, and initial approval and re-validation are different causes; a two-member class costs the predicate nothing. For every other transition (any edge not entering `published`), `lifecycle_trigger` remains cause-named free text — this decision governs only the edges where the field carries compliance weight.

Consequently, in the frontmatter schema, `lifecycle_trigger` becomes **conditionally required and enumerated**: when `lifecycle_state: published` (a state only Domain C reaches), the field is required and its value must be a member of the approval class. In all other states the field's existing contract (optional, free text) is unchanged.

### 4. Disposition of the consumer claims

- **Health-check "published without approval" (Check 6.2)** is restated as a frontmatter predicate over the governed vocabulary: a file with `lifecycle_state: published` whose `lifecycle_trigger` is **not a member of the approval class** is a violation, and a `published` file with **no `lifecycle_trigger` at all is equally a violation** — the absent case fails closed. The fail-closed rule binds on every evaluation substrate: a frontmatter read treats a missing field as a violation, and any SQL-executable form must treat NULL as a violation rather than letting three-valued logic exclude unstamped rows (if the delivery child adds a `lifecycle_trigger` column to the `files` table, published rows carry it NOT NULL or the query handles NULL as failing). The check's intent is preserved by mechanism, not assertion: the protocol admits no non-human edge into `published`, so a published file whose last transition did not stamp an approval-class trigger is exactly the population the original check meant to catch. The actor-based reading is retired with the trail — no actor source exists, and an actor claim without a source is fabricated data.
- **The lifecycle protocol's checklist** is amended in the same two ways: its published-without-approval item takes the identical governed predicate, and its per-transition audit-trail item is **retired and replaced** by the last-transition claim — every lifecycle transition updates `lifecycle_changed` and `lifecycle_trigger` in the file's frontmatter (enforceable through the existing frontmatter-completeness check family).

### 5. The surviving guarantee

**"Rebuild is identical" survives, now unqualified. "Audit trail" is retired as an index claim.** The honest residual is stated rather than papered over: the operations domain is not under version control, so with the trail retired, per-transition history is recorded nowhere — which is materially unchanged from the prior state, where the claimed trail never held real transition facts and was destroyed daily. This record removes a false claim, not a working capability.

### 6. The re-open path

The carrier question re-opens as a new decision when BOTH hold: an event source exists that captures transition-time facts at write time (the deferred watcher scope), and a consumer with a genuine per-transition need exists. The leading design at that point is per-file frontmatter history (the trail becomes derivable from files, restoring both principles by construction), with the shared-sink form and relocation-bounded retention doctrine as its design inputs. Until both conditions hold, building a carrier reproduces the sink-with-no-writer defect. The governed vocabulary in §3 is independent of that future: it governs the last-transition field and survives unchanged whether or not a history carrier ever exists.

### 7. What the delivery child executes

This record decides; the index-contract-seams delivery child executes. Its scope, enumerated here by named surface so nothing lands as surprise breakage — the deletion set was reconciled against the full 5-file / 28-reference-line fan-out, not just the regions the originating card cited:

- **Builder:** the table DDL and its two index statements; the `lifecycle_events` member of the expected-tables self-test tuple; the initial-row insert helper and its rebuild-path call; the update-path conditional insert block; the `lifecycle_events` member of the canonical-dump table list (the self-test's own witness path — deleting the table without this membership fails the dump); the update-file docstring's FK and append-step references; the self-test arm asserting a lifecycle row append on state change; the equality-witness exclusion comment.
- **Index schema:** the table section (definition + indexes); rebuild-protocol step 8; incremental-protocol step 6; the invocation table's incremental-update row wording that promises trail preservation and row appends; the checklist entry requiring one row per file. The rebuild-identity checklist claim **survives** and loses its implicit carve-out.
- **Health-check specification + lifecycle protocol:** the two restatements and one replacement per §4.
- **Frontmatter schema:** the `lifecycle_trigger` row gains the §3 conditional requirement and approval-class enumeration; the lifecycle protocol's transition-stamp contract and its two inbound-`published` edge rows name the governed values.
- **Fixtures:** the two committed `published` fixtures carry the backfill trigger and are reconciled to the governed vocabulary (restamped; the child may deliberately keep or add one out-of-vocabulary `published` specimen as the check's sensitivity fixture — a test-design choice, not a grandfather clause). **No grandfather clause ships**: the affected stock is closed and tiny — exactly two committed fixture files and zero `published` files in the live instance at decision time — and every future promotion stamps a fresh trigger under §3, so the corpus-wide backfill stamps never intersect the predicate. A dated exemption would be standing complexity guarding an empty set.
- **Tools README:** the schema-table count claim is corrected as part of the same sweep.

## Alternatives Considered

**Carrier question — five candidates across three altitude bands; two survived to trade-off.**

| # | Candidate | Verdict | Ground |
|---|---|---|---|
| C1 | Dedicated append-only event-log file (durable carrier, shared-sink form) | Rejected | Carrier without an emitter: nothing captures transition-time facts today and the builder's determinism contract forbids synthesizing them — the sink-with-no-writer defect class; a second authored surface for lifecycle facts creates a divergence pair the founding design already rejected; a durable append-only log acquires retention obligations and a governed row schema — a blast-radius ceiling breach for one seam. |
| C2 | Per-file frontmatter `lifecycle_history` array | Survived elimination, lost the matrix | Mechanism sound (same-file append kills the divergence pair; bounded by the state graph) but MODERATE reversibility across six-plus surfaces and every transitioning writer, for **zero present consumers** of per-transition history. Recorded as the leading re-open design (§6), not built now. |
| C3 | **Retire the table and its consumer claims (selected)** | **Selected** | CHEAP reversibility (re-introduction purely additive; no real history exists to lose), HIGH confidence (three independent reproductions of the zero-consumer measurement; full fan-out enumerated), blast radius exactly the five files already dispositioned. Both index design principles restored unqualified. |
| C4 | Legalize the identity carve-out (keep table, exempt it from rebuild identity) | Rejected | Renames the contradiction instead of resolving it: "audit trail" survives in text while false in substance; the compliance claims stay unsatisfiable; no surviving-guarantee statement is possible. |
| C5 | Re-type as initial-state registry (one derived row per file) | Rejected | Duplicate source: restates facts already carried row-level in the `files` table — a second home for the same facts. |

**Predicate question — four forms weighed for the §4 restatement.**

| # | Form | Verdict | Ground |
|---|---|---|---|
| P1 | Inequality against the example value (`lifecycle_trigger != human-approval`), field contract untouched | Rejected — the repaired defect | Unsound over an optional free-text field: classifies both committed `published` fixtures as violations, reads every cause-named re-validation as a violation, and inverts verdicts between dict and SQL substrates on the absent case. This was the drafted form; repairing it was the operator's binding entry condition. |
| P2 | **Governed vocabulary + fail-closed absent rule (selected)** | **Selected** | The edge set into `published` is closed at two, so the vocabulary is complete by construction; the predicate ranges over a governed set; absent-value semantics pinned identically on every substrate; sound against the committed test universe by construction. Cost: one conditional requirement on the frontmatter schema row — a surface the fan-out had already flagged for sweep. |
| P3 | Mark the control UNVERIFIED and defer the predicate to the instance-conformance validator seam | Rejected, narrowly | Honest (the check family is runner-less today regardless) and operator-sanctioned as an acceptable path — but it leaves the control predicate-less with no acceptance criterion binding any owner to adopt it, and re-touches the same spec lines twice. Chosen against because the closed two-edge enumeration makes governing the vocabulary cheap *now*, at the decision record where the field became evidence. |
| P4 | Governed predicate plus a dated grandfather clause for pre-existing backfill stamps | Rejected | The grandfathered set is closed and near-empty (two committed fixtures, zero live `published` files); a dated exemption inside a compliance rule is standing complexity guarding an empty set. Reconciling the two fixtures is cheaper than carrying the clause forever. |

## Consequences

**Positive.**

- Both index design principles hold unqualified; the identity carve-out in the equality witness is deleted rather than legalized.
- The two compliance surfaces become satisfiable **and sound**: the restated predicate ranges over a closed vocabulary, fails closed on the absent case on every substrate, and is consistent with the committed test universe by construction rather than by luck.
- Zero data loss: accumulated rows are synthetic (creation dates, managing skills) and are already destroyed by the mandated daily rebuild. Nothing operational breaks — no executable outside the builder implements the event lookup, a zero measured three times with live control arms.
- The delivery child receives a reconciled, named-surface deletion set rather than a partial region list — the gap between the fan-out probe's count and the originally-cited regions is closed in this record, not discovered at its first self-test.

**Negative, and accepted.**

- Per-transition history, dwell-time analytics, and actor attribution stop being claimable until the §6 re-open conditions hold. Stated, not hidden.
- Domain-C writers promoting into `published` acquire a real constraint: the trigger value stops being free text on those two edges. This is the price of making an optional field load-bearing, paid in the open — the alternative was a check that could not tell governed evidence from whatever string a writer guessed.
- The two committed fixtures must be reconciled in the same child that retires the table — a small, enumerated, one-time cost taken instead of a permanent grandfather clause.
- The restated check reads frontmatter; if a SQL-executable form is wanted, the `files` table needs a `lifecycle_trigger` column carrying the §4 NULL rule — a delivery-child micro-decision, flagged there.

## Reversibility

**CHEAP** · confidence **HIGH**. Re-introduction of a history carrier is purely additive and better-informed (an emitter will exist first); retirement destroys no real data; widening the approval-class vocabulary later is a one-row spec edit plus the same fixture sweep. Falsifiable against the enumerated five-file fan-out and the closed transition table.

## Related ADRs

- ADR-164 (Accepted) — authority follows authorship; the doctrine deciding which lifecycle facts the platform may assert.
- ADR-167 (Proposed at this record's authoring; merged) — the sink-with-no-writer analysis that eliminates the emitterless carrier. Cited as merged doctrine whose reasoning this record adopts on its own force, not as a ratified ruling; the elimination stands independently on the divergence-pair and retention grounds.
- ADR-169 (Proposed at this record's authoring; merged) — the retention obligations any durable append-only carrier acquires; a cost of the rejected branch and an input to the §6 re-open path.
- ADR-045 (Accepted) — the no-shadow-source-of-truth invariant a second authored lifecycle surface would breach.

### Provenance

- Decision card: #5838 — this record is its sole deliverable. Designed at Stage 5 (sub-task #6662), adversarially reviewed (predicate-soundness Major, comment 5514327491), entry condition bound by the operator at Collective Review scope-lock, authored at Stage 6 (sub-task #6663).
- Delivery child: #5845 (milestone #361) executes the §7 enumeration; its AC4 "table absent" arm is the verifier.
- Event source (re-open dependency): epic #1153 — open at decision time; its body carries no reference to the retired table, so retirement dangles no epic-spec reference.
- Release: pda-decisions-and-conformance-baseline (version-less).
