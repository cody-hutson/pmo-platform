# Release Plan: documentation-model-adopted — the documentation model is a recorded decision, and the release pipeline carries documentation end to end

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — protocol text and references plus one decision record, with no new skill or governance file; the v4.77 plan landed a decision record as `minor`. Provisional v4.78 (anchor v4.77), re-verified at Engineering Commit 0 on 2026-10-24: `claim-version.sh --sha cebcf6c2 --bump minor --dry-run` → v4.78, and v4.78 is absent from the tag, published-release and ledger arms. The concrete number binds only at the Stage-12 atomic claim (ADR-092). |
| **Date Created** | 2026-10-24 (Saturday) |
| **Release Manager** | Agent-assisted |
| **Status** | Executing — Stage 6 Engineering; Engineering Commit 0 landed, #8117 next |
| **Branch** | release/documentation-model-adopted |
| **PR** | opened in **draft** after #8117's commit; ready for review at the Stage-9 gate |
| **Milestone** | documentation-model-adopted |
| **Release Class** | cross-cutting (D-ReleaseClass, operator, 2026-10-24) |
| **Release Identity** | versioned (D-ReleaseIdentity, operator, 2026-10-24) |
| **Baseline Pin** | `origin/main` at `cebcf6c2` — the Stage 4 Phase A0 `main_head_sha` operand (L4), read 2026-10-24T06:01:30Z; still the `origin/main` head at Engineering Commit 0 (0 commits behind) |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-10-24, domain: governance }`

**Domain classification.** Every matrix path is an internal pmo-platform artifact — governance standards, the gate spec, pipeline specs, issue forms and one ADR. The secondary domain is `software`, for the emitter and its self-test.

## Scope

### Issues Included

| # | Issue | Title | Priority | Category | Labels |
|---|-------|-------|----------|----------|--------|
| 1 | #8117 | Decide how a repository's system documentation is modelled, and record the decision as an ADR | P2 | improvement | cluster: documentation, improvement, size:M, status: bundled, type:spike, project:system-documentation |
| 2 | #8494 | Extend the design-artifact standard to the generated process catalog the documentation-model ADR chose | P2 | improvement | cluster: documentation, improvement, size:M, status: bundled, type:task, project:system-documentation |
| 3 | #8119 | Documentation Impact reaches every work-item form, covers docs/, and can declare a retirement | P2 | improvement | cluster: process-protocol, improvement, size:M, status: bundled, type:task, project:system-documentation |
| 4 | #8495 | Planning reads the current-state process pages a change touches, and close verifies documentation instead of only specifying it | P2 | improvement | cluster: process-protocol, improvement, size:L, status: bundled, type:task, project:system-documentation |

**Plan:** four cards, one branch (`release/documentation-model-adopted`, D-C SINGLE), one PR, Stage 6 fully serial (P0). Order **#8117 → #8494 → #8119 → #8495** — the milestone's own Internal Sequence, re-derived from the edges below and unchanged. Raw 20 pts; effective **26 pts** at the cross-cutting weight (20 × 1.3). The G3-15 keep-as-one disposition stands and is not reopened.

**Scope lock (Collective Review, 2026-10-24):** Engineering is authorized for #8117, #8494 and #8119, serial in the plan order. #8495 was returned to Stage 5 Solutioning and is not built until its re-spec clears Collective Review (DEV-6).

### Release Class

**cross-cutting**, confirmed from the File Change Matrix: trigger (a) fires on **5** `pipeline/stage-*.md` specs (02, 05 and 13 named by the cards; 01 and 06 found by the restatement sweep). Trigger (b) counts 2 of 6 rule-defining surfaces (`gate-criteria-spec.md`, `release-process.md`) and does not fire. The novel triggers (b) and (c) also fire; cross-cutting dominates under the multi-trigger rule. Blocks: engagement Tight, Stage 9 Deep, Stage 5 ALL, 30-day outcome window.

### Dependency Graph

Native GraphQL edges: **0 `blockedBy` / 0 `blocking` on all four cards** at Stage 4 (control: #7962 → `blockedBy` 2). Every edge below is from prose and the A0 reads, classified per the build-dependency vs release-gate test.

```
#8117 ADR ──build──► #8494 standard ──build (emitter half)──► #8495 planning read + emitters
   │                       ┊ consistency (retire)                ▲
   └──release-gate─────────┊────────────────────────────────────┤
                           ▼                                     │
                     #8119 Documentation Impact ──build──────────┘
```

| Edge | Class | Basis |
|---|---|---|
| #8494 ← #8117 | build (FS) | the standard implements ADR Consequence 1 and cites the ADR by `{{ADR:<slug>}}`, which needs the ADR file on the branch first |
| #8495 ← #8119 | build (FS) | the G-CL8 emitter reads the vocabulary (retire) and the single scope list #8119 sets; both edit the G-CL8 row and its self-repair row |
| #8495 ← #8494 | build for the emitter half; release-gate for the planning-read half | G-CL6 detection lives in standard § 8, and `last_verified_commit` is a page field the standard defines. The Stage 2/5 text can be drafted in parallel but must not ship ahead. Undeclared on the card at Stage 4 (A9) |
| #8495 ← #8117 | release-gate | cites ADR decisions 2 and 10; no build input |
| #8119 ⇢ #8117, #8494 | consistency (not build-blocking) | the retire verification must agree with decision 6 and the standard's retire step — settled by D-RetireSemantics |

**Acyclic.** Longest chain: 3 (#8117 → #8494 → #8495). **Cross-milestone:** nothing blocking — #5062 (sibling, `governance-obligations-measured`, no open PR, owns the presence check) · #7962 (merge-order neighbour on `epic.yml`, no open PR) · #8157 (coordination) · #8339 (adjacent) · #6433 (informational) · #8118 (engine decision, open and unmilestoned — a forward reference in ADR Consequence 3, not a dependency).

### File Change Matrix

Machine-readable form — one path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction. The #8117 block carries the Stage 5 refinements recorded in DEV-3 and DEV-4; the other blocks are transcribed from the approved Stage 4 plan, and each card's Engineering spoke promotes its own refinements.

```
# ── Commit 0 — the release plan ──
release/releases/plans/documentation-model-adopted_RELEASE_PLAN.md  ADD
# ── #8117 — the documentation-model ADR, landed from the ratified text ──
core/ADRs/ADR-NNN-system-documentation-is-a-generated-process-catalog.md  ADD
core/ADRs/README.md  EDIT  CONDITIONAL:ADR-RENUMBERED-AT-CLAIM
# ── #8494 — the standard governs the generated process catalog (standard § 8 is also edited by #8495) ──
core/standards/design-artifact-standard.md  EDIT
core/specs/terminology-glossary.md  EDIT
core/deploy/allowlists/doc-link-target-paths.txt  EDIT
core/<catalog-folder>/README.md  ADD
release/references/how-to/design-artifact-backfill-completion-condition.md  EDIT  CONDITIONAL:EIGHTH-ENUM-VALUE
# ── #8119 — Documentation Impact on every shipping form (gate-criteria-spec, stage-13-close, release-process and deploy.sh are also edited by #8495) ──
.github/ISSUE_TEMPLATE/epic.yml  EDIT
.github/ISSUE_TEMPLATE/story.yml  EDIT
.github/ISSUE_TEMPLATE/observation.yml  EDIT  CONDITIONAL:OBSERVATION-FORM-IN-SET
.github/ISSUE_TEMPLATE/adr.yml  EDIT  CONDITIONAL:ADR-FORM-IN-SET
.github/ISSUE_TEMPLATE/improvement.yml  EDIT
.github/ISSUE_TEMPLATE/bug.yml  EDIT
.github/PULL_REQUEST_TEMPLATE.md  EDIT
core/schemas/gate-criteria-spec.md  EDIT
release/references/pipeline/stage-13-close.md  EDIT
release/governance/release-process.md  EDIT
core/deploy/deploy.sh  EDIT
release/references/pipeline/stage-01-intake.md  EDIT
release/references/pipeline/stage-06-engineering.md  EDIT
core/schemas/field-lifecycle-matrix.md  EDIT
# ── #8495 — planning reads current-state pages; G-CL6 and G-CL8 emit (shared files listed above) ──
release/references/pipeline/stage-02-triage.md  EDIT
release/references/pipeline/stage-05-solutioning.md  EDIT
core/standards/gate-efficacy-standard.md  EDIT
core/deploy/tests/test_doc_gate_emitters.sh  ADD  CONDITIONAL:EMITTER-IN-DEPLOY-CHECK
release/tools/doc-gate-emitter.py  ADD  CONDITIONAL:EMITTER-AS-RELEASE-TOOL
release/tools/tests/test_doc_gate_emitter.py  ADD  CONDITIONAL:EMITTER-AS-RELEASE-TOOL
core/config/allowlists/script-execution-allowlist.txt  EDIT  CONDITIONAL:NEW-SHELL-SCRIPT
```

#### Read-only inputs

```
core/ADRs/ADR-089-embedded-design-artifact-declaration-marker.md  READ
core/ADRs/ADR-211-design-axes-and-cut-patterns-key-on-work-nature.md  READ
core/disciplines/diataxis-framework.md  READ
core/standards/lifecycle-states-canonical.md  READ
core/standards/platform-doc-frontmatter-standard.md  READ
core/standards/process-flow-diagram-standards.md  READ
core/deploy/tools/check-doc-links.py  READ
release/tools/blast-radius.sh  READ
core/packs/scrum/pack.toml  READ
```

**Matrix notes.** The ADR number binds at merge: anchor 220, `{{ADR:<slug>}}` in every other file's prose, `--stamp` at Stage 12. `core/ADRs/README.md` is a curated thematic document with no projector, so it is never hand-edited: `renumber-adr.py` appends its renumber-log line at Stage 12, and only if the claim moves the number (DEV-4). The catalog folder's first `.md` ships in the **same commit** as its scope row. The emitter rows are mutually exclusive by home. **CI wiring:** a deploy-check emitter runs inside `deploy.sh --check`; a `release/tools/` emitter runs at Stage 13 A5/A11, and its self-test joins an existing CI test job. A new `*.sh` takes its allowlist row in the same release. No mover: a retire is a status move. Placement per current main (A0.7).

### Stage Applicability Matrix

| Issue | 5 Solutioning | 6 Engineering | 7 Dev Testing | 8 QA | 9–13 |
|---|---|---|---|---|---|
| #8117 | **apply** — a landing and conformance pass, not re-authoring: References block, `## Related ADRs`, `release:` slug, D6 alternative, `{{ADR:<slug>}}` | apply | apply — required-check rehearsal (issue-ref validity, ADR-number integrity, ADR durability) | apply | release-scoped |
| #8494 | apply — layout, eighth value or sub-class, folder name, first tracked file, retire text per D-RetireSemantics | apply | apply — § 12 lint positive control; link check `--require-targets` | apply | release-scoped |
| #8119 | apply — the form set (observation/adr), non-Scrum kind forms (A6), retire verification, the one scope list | apply | apply — Check 28 runs; template parse; scope single-sourcing sweep | apply | release-scoped |
| #8495 | apply — emitter home (reuse-first: extend Check 28), no-page record form, W2 exit criteria | apply | apply — emitter self-test fixtures | apply | release-scoped |

No skips: cross-cutting biases Stage 5 to ALL, and every card has functional or gate-facing impact. Parallel-eligible: Stage 5 = 4 (recommended as 3 + 1), Stage 7 = 4, Stage 8 = 4.

### Contention Map

#### Within the release (one branch, serial)

| File | Cards | Where | Resolution |
|---|---|---|---|
| `core/schemas/gate-criteria-spec.md` | #8119 × #8495 | **same rows** — G-CL8 (`:853`) and its self-repair row (`:911`); #8495 also G-CL6 (`:851`, `:909`) | sequence #8119 → #8495; #8495's slice rebases on #8119's |
| `release/references/pipeline/stage-13-close.md` | #8119 × #8495 | **same paragraph** — Phase A11 (`:221`); #8495 also Phase A5 (`:48`) | sequence; CIAC-1 grades the integrated result |
| `core/standards/design-artifact-standard.md` | #8494 × #8495 | §§ 2, 3, 5, 9, 10, 12 vs § 8 — disjoint sections | sequence; CIAC-2 grades § 8 |
| `core/deploy/deploy.sh` | #8119 × #8495 (conditional) | Check 28 (`:12034`–`:12105`): the template list vs the per-issue mechanism its header already describes | sequence; one check block |
| `release/governance/release-process.md` | #8119 × #8495 (conditional) | Stage 1 (`:231`) and Stage 13 (`:619`, names Check 28 as backing) | sequence |

#### Cross-PR Overlap Audit (A4)

**Baseline SHA:** `cebcf6c2`. Population: 2 open PRs, both drafts at Stage 4 (count read twice). Hunks are from each branch's diff against its merge-base, which is `cebcf6c2` for both. This release's ranges are **projected** from the target sections, because nothing was written at Stage 4.

| File | This release (projected) | #8396 hunks | #8306 hunks | `overlap_class` (ADR-005 rule) |
|---|---|---|---|---|
| `core/ADRs/README.md` | renumber-log line only if the Stage-12 claim moves the number (tool-written) | insert @130 | insert @130 | **line-range-overlap** — all three insert at one position; resolve by re-running the tool, never by hand |
| `core/standards/design-artifact-standard.md` | §§ 2, 3, 5, 8, 9 (`~211–216`, `~225–246`), 10, 12 | `221` (§ 9 citation form) | — | append-pattern by rule (disjoint), but the nearest projected hunk is about 4 lines away → merge-order neighbour; rebase whichever lands second |
| `core/schemas/gate-criteria-spec.md` | `851–853`, `909–911` | `570`, `625` | — | append-pattern (disjoint) |
| `core/standards/gate-efficacy-standard.md` | `507`, `543` | `313`, `346` | — | append-pattern (disjoint) |
| `release/references/pipeline/stage-13-close.md` | `48`, `221` | `244`, `246` | — | append-pattern (disjoint, 23 lines) |
| `core/deploy/deploy.sh` | `12034–12105` | — | `16739–16850` | append-pattern (disjoint) |
| `core/config/allowlists/script-execution-allowlist.txt` | conditional append | — | `1123–1143` | conditional |

**ADR numbers:** 221 is claimed by **both** siblings (#8306 also claims 222 and 223); only the mainline binds, at merge. This release lands with the oracle's next-free value and renumbers through the tool if a sibling merges first.

**Structural blast radius:** this release's mover-set is empty (no rename, relocate or delete), so `SURFACE(R)` is only the version token `Δversion/4.78.0`. Neither sibling has a mover. **Tier-S edges: 2, both version-slot** — the atomic claim arbitrates them at merge.

**Baseline-pin limitation:** a sibling merging after `cebcf6c2` is invisible here. Stage 9 Phase A6.5 re-measures (HALT-eligible), and the sibling-merge trigger re-runs this audit at Stage 9 entry.

**Reconfirmed at Stage 6 entry (#8117, 2026-10-24):** `origin/main` still `cebcf6c2`; open-PR population still 2 (#8396, #8306; `gh pr list --limit 500` length). #8396 left draft and its head moved to `be5d7327`; #8306 is unchanged at `31b3955a`. Both still add an ADR-221 under their own slugs. No sibling has merged, so no audit row changes.

#### In-Flight Release Roster

**Measured at:** `cebcf6c2` · `2026-10-24T06:25:14Z` · **Population:** n=2 sibling(s) (open `release/*` PRs, drafts included, plus remote `release/*` heads without a PR — none; this release's branch was not yet on the remote)

| Slug | PR | Head SHA | Bump-class | Carried label | Recomputed next-free | EDITSET ∩ FCM |
|---|---|---|---|---|---|---|
| `authoring-conventions-enforced-or-retired` | `#8396` | `36344222` | `minor` | `v4.75` | `v4.78` | `core/ADRs/README.md`, `core/schemas/gate-criteria-spec.md`, `core/standards/design-artifact-standard.md`, `core/standards/gate-efficacy-standard.md`, `release/references/pipeline/stage-13-close.md` |
| `hook-walk-adjudicates-every-operand` | `#8306` | `31b3955a` | `minor` | `v4.75` | `v4.78` | `core/ADRs/README.md`, `core/deploy/deploy.sh`, `core/config/allowlists/script-execution-allowlist.txt` (conditional) |

Both carried labels are stale. All three in-flight releases recompute to the **same** slot (v4.78), and the first merge takes it. This is a pinned measurement and carries no verdict; the verdict belongs to Stage 9 Phase A6.6.

### Cross-Milestone Dependency Validation

PASS — 5 dependency edges checked (all in-release, listed under § Dependency Graph), 0 cross-milestone violations. The cross-milestone neighbours listed there are coordination, adjacency or forward references, none blocking.

### Exclusions

None — enumerated over the four members. #8495 stays a member; its Engineering is held until its Stage 5 re-spec clears Collective Review (DEV-6).

## Phase A0 — Triage→Design Re-review (Stage 4 baseline)

**G-PL5 cache-read — HIT.** `rows_source: mode-r-cache` · briefing = the Stage 4 sub-task's first comment (author association OWNER, `part: 1/1`, `schema_version: v1.0`) · `emitted_at: 2026-10-24T05:58:17Z`.

| Limb | Recorded in briefing | Recomputed at A0 (2026-10-24T06:01:30Z, published recipes, `set -o pipefail`, every read exit 0) | Result |
|---|---|---|---|
| L1+L2 `card_set_fingerprint` | `c53c61ec…45039c3` | `c53c61ec…45039c3` (card set 8117:05:57:22Z · 8119:05:57:23Z · 8494:05:57:24Z · 8495:05:57:26Z) | equal |
| L3a `milestone_updated_at` | `2026-10-24T05:58:41Z` | `2026-10-24T05:58:41Z` | equal |
| L3b `milestone_description_sha256` | `e6682ad0…af85bae6` | `e6682ad0…af85bae6` | equal |
| L4 `main_head_sha` | `cebcf6c2…5e34a5` | `cebcf6c2…5e34a5` | equal |
| L5 age | `emitted_at` 05:58:17Z | 3 min old (bound: 7 days) | within |

MISS guards checked: member count 5 (4 cards + the Stage 4 sub-task) < `--limit` 500; no non-`sub-task` member title matches `^Stage [0-9]`; every adopted row is in the § 1 six-column form with no empty D1/D2/D3 cell (python cell scan over 24 rows). **No adopted row is C3 / PT-2**, so no § 3.1 freshness re-run is owed. No G-PL4 supersession (all four admit-still-valid).

Per-card header (8 fields authored at A0; rows adopted verbatim below):

| issue_number | release_milestone | stage | spoke_author | re_review_date | issue_body_revision | triage_decision_date | effort_tier |
|---|---|---|---|---|---|---|---|
| #8117 | documentation-model-adopted (milestone #434) | 4 | Stage 4 planning spoke | 2026-10-24 | 2026-10-24T05:57:22Z | 2026-10-02 | standard |
| #8119 | same | 4 | same | 2026-10-24 | 2026-10-24T05:57:23Z | 2026-10-02 | complex |
| #8494 | same | 4 | same | 2026-10-24 | 2026-10-24T05:57:24Z | 2026-10-24 | standard |
| #8495 | same | 4 | same | 2026-10-24 | 2026-10-24T05:57:26Z | 2026-10-24 | complex |

<details><summary>Adopted six-column rows — #8117</summary>

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| **AC1** — the ADR records D1, D2 and D6, each with considered options and the chosen option | `decision-discipline.md` § 2.2 Opposing View: the rejected options must be recorded. The ratified text records them for D1, D2 and placement — **none for D6** [SOURCE] | `adr-schema.md` §3 row 4 (`## Alternatives Considered` required). The card's D6 options were "axes × readers grid" or "one document per top-level process and component class". Decision 3 picks "one page per node plus generated views", and the reader set changes (requester dropped; small-context local model and adopter added) [SOURCE] | ADR-033 recorded even its rejected two-ADR split [SOURCE: ADR-033 § Alternatives Considered] | C2 | When landing the text, add the D6 alternative and record the reader-set change. |
| **AC2** (re-worded 2026-10-24 by operator decision) — the ADR states the catalog (index, graph, views) is generated from page frontmatter and the element inventory, never hand-maintained, and cites ADR-089's reasoning against a hand-kept index | `review-discipline-principles.md` § 1 Rule 3: read against the ratified text — Context bullet 2 cites ADR-089's lost-entry reasoning; decision 1 states generation from page frontmatter and the element inventory [SOURCE] | No conflict with the corpus: the design-artifact standard's embedded-artifact marker keeps governing embedded artifacts; the catalog is a separate generated layer (#8494 extends the standard to say so) [SOURCE / INFERRED] | ADR-089's learning (a hand-kept index silently loses entries) is encoded as "generated, never hand-maintained" plus a CI drift check (decision 10) [SOURCE] | C1 | (verbatim) — the earlier C3 / PT-1 premise problem is closed by the re-wording; the ratified text satisfies the criterion unchanged. |
| **AC3** (re-worded 2026-10-24 by operator decision) — the ADR names the state/lifecycle flow class as follow-on work for the standard-extension card, and states the page lifecycle reuses the platform-doc `status` field rather than new state names | `reversibility-protocol.md` § The Four Tiers: the criterion now matches decision 6 instead of asserting its opposite [SOURCE] | Consequence 1 names the state and lifecycle flow class for the standard extension (#8494 in this milestone); decision 6 names the platform-doc `status` field and "no new state names" [SOURCE] | `lifecycle-states-canonical.md` reserves the bare draft/validated/published/stale names; reusing the platform-doc `status` vocabulary avoids that collision [SOURCE] | C1 | (verbatim) — closed by the re-wording. |
| **AC4** — `status:` is terminal on main after its ratifying review | `reversibility-protocol.md` § Confidence Pairing: HIGH on D1, D2 and placement; MEDIUM on L3 seeding [SOURCE] | The G-CL9 authored limb (`gate-criteria-spec.md:854`) needs a terminal leading token. `Accepted` satisfies it, and R1 and R7 are clean (Part E). The ratifying authority is the operator's planning-gate ratification [SOURCE] | Read `status:` directly rather than trusting the ratification-flip check — this check did [SOURCE] | C2 | `[ASSUMPTION – CONFIRM]` the planning-gate ratification counts as the ratifying review (proposed: yes) — confirmed by the operator's AC refinement on #8117 |
| **proposed-change-1** — record D1, D2 and D6 through the ADR process at Stage 5 | `principal-standard-checklist.md` Competency 3: the decision exists as ratified text; Stage 5 lands it [SOURCE] | ADR-033 was "materialized at Stage 6" per the ADR-007 / 028 / 029 precedent [SOURCE] | One PR per milestone [SOURCE] | C2 | Re-word as "landed from the ratified text". The number binds at merge (Part E). |
| **risk-1** — a hand-maintained catalog reintroduces ADR-089's failure | `decision-discipline.md` § 2.1 Mechanism 1: honoured — "generated … never hand-maintained", with committed output and a CI drift check (decisions 1 and 10) [SOURCE] | **9b AL-FIT** — seams searched: the design-artifact standard §§ 2–3 (7 classes; the centralization test at `:65` → `core/diagrams/`) and the ADR-089 section marker. As written, the card leaves the band open. The ratified new-abstraction band is captured once, under AC2 / F2 [SOURCE] | The ratification pilot: a clean validator "said nothing about whether numbers were right"; the refuter caught copied figures, which became the decision-12 rules [SOURCE]. 9a **PV-D**: the card cites only its own corpus (standard §§ 2–3, ADR-089, ADR-211, the lifecycle reservation) and a dated operator *direction* (2026-07-28). It names no witnessed instance where the gap caused a failure, so § 11.1's bound classes it PV-D [SOURCE] | C2 | Consequence 3 cites the engine decision (#8118) as settled, but #8118 is open and unmilestoned → forward reference (A3). |

</details>

<details><summary>Adopted six-column rows — #8119</summary>

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| **AC1** — every shipping work-item form carries Documentation Impact | `review-discipline-principles.md` § 1 Rule 3: the denominator is explicitly deferred to Solutioning (5-test T2) [SOURCE] | `epic.yml` and `story.yml` are pack-projected kind forms (from `core/packs/scrum/pack.toml`, per their header comments). Under `type-map.md` § Kind-derivation contract, other methodologies supply their own forms. Affected Files name neither [SOURCE] | #7962 lists `core/packs/scrum/pack.toml` for an `epic.yml` edit [SOURCE] | C2 | State in Solutioning how non-Scrum kind forms get the field, or scope to the shipped dedicated forms (A6). |
| **AC2** — retire in the vocabulary; G-CL8's row says how a retirement is verified | `decision-discipline.md` § 2.1.1 Audit-Snapshot Reconciliation: reconcile with the sibling card and the ratified decision [SOURCE] | The Proposed Change verifies retire as "the document is gone and nothing still references it". **#8494's AC3 says "no deletion"** (a status move), and ADR decision 6 agrees. G-CL8's corpus scope (`core/`) contains the new catalog folder [SOURCE] | #5062 (v4.16, milestone 265, AI-022): a miss was reported honestly rather than back-filled — a retire check must fail visibly, not vacuously [SOURCE] | C2 | **Intra-milestone semantic conflict** — define retire per document class at Stage 5 Collective Review (A5). |
| **AC3** — `docs/` in scope; one scope list, cited elsewhere | `principal-standard-checklist.md` Competency 2 [SOURCE] | The G-CL8 row declares itself the scope authority. `improvement.yml:127` differs from it, and neither includes `docs/` [SOURCE] | `gate-criteria-spec.md` v2.9 made G-CL8 body-keyed and "self-revoking": new forms enter scope automatically [SOURCE] | C1 | (verbatim) Epic #8116 later turns this list into a profile lookup. |
| **AC4** — an epic filed after the change carries the section | `review-discipline-principles.md` § 1 Rule 15: observable only after a future filing [INFERRED] | G1-05b wants a named realistic fixture; triage added this AC with operator approval [SOURCE] | A version-less close-out goes through the Phase-B chore PR [SOURCE] | C2 | Name a fixture, or a post-ship observation surface (A7). |
| **proposed-change-1** — forms, retire, `docs/`, one list | `reversibility-protocol.md` § In-place bias: extend the G-CL8 authority row rather than add a gate [SOURCE] | **9b AL-FIT** — seams searched: `core/packs/_common/pack.toml` (`role = "base"`, 0 `[[controls]]`; controls take only enum or integer domains); the kind meta-schema `core = "inherit"` (frozen source, `work-item-type-schema.md:17`); the kind-derivation contract. None fits a free-text field [SOURCE] | #5062 Mode R sweep (2026-09-02): an AC was re-anchored after its surface moved — scope surfaces drift [SOURCE] | C1 | (verbatim) |
| **risk-1** — a required field changes intake; G-CL8 stays warn-mode | `failure-mode-standard.md` 5-field template: named, with a mitigation [SOURCE] | G-CL8's per-issue row is "specified, not yet emitting" until #8495 lands an emitter [SOURCE] | 9a **PV-A**: the 2026-07-28 (Tuesday) operator finding [SOURCE] | C1 | (verbatim) |

</details>

<details><summary>Adopted six-column rows — #8494</summary>

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| **AC1** — a catalog section naming the folder, the page levels, and generated-never-hand-kept | `decision-discipline.md` § 2.1 Mechanism 1: localized to ratified decisions 1, 3 and 4 [SOURCE] | § 3 Storage Model (embed in parent; centralize at ≥ 3 references, `:65`). The card has the standard "govern both models", which is additive [SOURCE] | ADR-089's lost-entry learning is encoded as "never hand-kept" [SOURCE] | C1 | (verbatim) |
| **AC2** — link types and a behaviour-over-time flow class; the § 12 harness and lint accept it | `review-discipline-principles.md` § 1 Rule 15: running the lint on a marker that uses the new class is a positive control [SOURCE] | The § 12.2 harness hard-codes the seven values (the grep enum and the `for t in …` loop). The card names the same-commit obligation. Whether this is an eighth value or a sub-class is deferred to Stage 5 [SOURCE] | Ratified Consequence 1 names this class; #8111's TODAY lists it as missing [SOURCE] | C1 | (verbatim) |
| **AC3** — the retire step: status transitions, no deletion, inbound links re-pointed | `decision-discipline.md` § 2.1.1: reconcile with the sibling #8119 [SOURCE] | **Conflicts with #8119's Proposed Change** ("the document is gone"). Agrees with ADR decision 6. The superseded-page retention rule is `[ASSUMPTION – CONFIRM]` (not ratified) [SOURCE] | #5062 Mode R sweep (2026-09-02): an AC re-anchored after a removed path — a removal without re-pointing dangles [SOURCE] | C2 | Same intra-milestone conflict as #8119 AC2 (A5). |
| **AC4** — § 9 states the process-page exception to reciprocal links | `principal-standard-checklist.md` Competency 1: the generated inbound index replaces a hand obligation [SOURCE] | **Open draft PR #8396 edits § 9** (`:218`, cross-reference citation form) — a same-section merge-order neighbour [SOURCE] | Ratified decision 8 [SOURCE] | C2 | Rebase § 9 on whichever lands first (A11). |
| **AC5** — the catalog folder is in `doc-link-target-paths.txt`; `check-doc-links.py --require-targets` runs over it | `review-discipline-principles.md` § 1 Rule 15: `--require-targets` is a fail-loud arm [SOURCE] | `link-check.yml:99-102` passes `--target-paths-file` and `--require-targets`. A glob that resolves to **zero files exits 3, which is a hard fail regardless of warn-mode**. Pages publish "in later milestones", so in this milestone the folder may hold no `.md` [SOURCE / INFERRED] | A red check blocks the merge in practice [SOURCE] | C2 | Ship a tracked file in the folder with this milestone, or add the scope row in the first page milestone (A8). |
| **risk-1** — a governance-file change; the enum change lands in one commit | `failure-mode-standard.md`: the risk is named with its mitigation [SOURCE] | **9b AL-FIT** — seam searched: the design-artifact standard itself (extend-seam), which this card extends [SOURCE] | 9a **PV-D**: corpus sections and ADR decisions only; no witnessed instance cited [SOURCE] | C1 | (verbatim) |

</details>

<details><summary>Adopted six-column rows — #8495</summary>

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| **AC1** — Stages 2 and 5 read current-state pages and cite the page ID and `last_verified_commit`, or record that no page covers the area | `decision-discipline.md` § 2.1 Mechanism 1 (read local state before deciding) [SOURCE] | Gap verified: Stage 2 has 0 hits; Stage 5's 2 hits are unrelated. `last_verified_commit` is a decision-6 field that #8494's standard must define → an **undeclared #8495 ← #8494 edge** [SOURCE / INFERRED] | The ratification pilot: stage specs seed "about half", so expect "no page" answers for a while — the card says so [SOURCE] | C2 | Declare the edge (A9). |
| **AC2** — G-CL6 and G-CL8 emitters write FAIL rows (one fixture: one unrefreshed Tier-A artifact, one unresolved declaration) | `review-discipline-principles.md` § 1 Rule 15: the fixture is a positive control [SOURCE] | Both rows read "not yet emitting"; the sink is the shared `deploy-check-warn-log.jsonl`. G-CL6's detection steps live in design-artifact standard § 8, **which #8494 amends** [SOURCE] | G3-15's per-gate sink "was never written and is RETIRED (W1)" — a declared sink no one writes reads as a control [SOURCE: `gate-criteria-spec.md:631`] | C2 | The G-CL6 emitter's coverage of catalog pages depends on #8494 (A9). The emitter's home is deferred to Stage 5. |
| **AC3** — G-CL6 and G-CL8 rows name their emitter | `principal-standard-checklist.md` Competency 2 [SOURCE] | #8119 edits the same G-CL8 row. #8396 edits other rows of the same file (G3-09) [SOURCE] | The same-row edits sequence on one branch [SOURCE] | C1 | (verbatim) Sequence after #8119, as the card states. |
| **AC4** — the first Stage 5 output after ship cites pages or records none | `review-discipline-principles.md` § 1 Rule 15: a post-ship observation [INFERRED] | G1-05b fixture expectation [SOURCE] | A version-less close-out goes through the Phase-B chore PR [SOURCE] | C2 | Name the observation surface (A7). |
| **proposed-change-1** — the written-to-visual check is deferred to the generator | `reversibility-protocol.md` § In-place bias: deferring is CHEAP [SOURCE] | #8114's Outcome includes the match check. Decision 10 makes it the generator's regenerate-and-diff (engine #8118, later) [SOURCE] | The ratification pilot: "regenerate-and-diff … need the Phase 3 generator" [SOURCE] | C1 | (verbatim) `[ASSUMPTION – CONFIRM]` remains Collective Review's. |
| **risk-1** — combines two of #8114's candidate children; the split is named as the alternative | intake 5-test T1 failure routing satisfied (one card kept, split noted) [SOURCE] | #8114 lists "Planning reads…" and "Close verifies…" as separate candidates [SOURCE]. **9b AL-FIT** — seams searched: the existing Stage 2 / Stage 5 phase steps; the deploy-check warn log and Check framework (home deferred) [SOURCE] | 9a **PV-D** (the v4.16 miss on #5062 would be PV-A but is not cited) [SOURCE] | C2 | The planning-read half is the cheapest split seam for F5 option A (Part B). |

</details>

**Sibling A0 gates (unconditional):**
- **Ticket-architecture reconciliation:** of the governing surfaces, only `stage-13-close.md` changed after a filing date (2026-10-16, a branch sync adding 38 lines outside A5/A11). A5 and A11 were re-read on main and match #8119's evidence.
- **A0.5 / G-PL1 — PASS.** 22 of 22 cited paths resolve on `origin/main` (`git cat-file -e`; control, a non-existent path → MISSING).
- **A0.6 / G-PL2 — PASS 4/4.** G1-02, G1-04 and G1-05 hold on every current body. #8119 AC4 and #8495 AC4 are post-ship observations, admitted as declared-deferred.
- **A0.7 / G-PL3 — SKIP.** Base `cebcf6c2` = `origin/main` → 0 rows. Control on the same instrument (200 commits before base) → 239 `R`/`D` rows.
- **A0.8 / G-PL4 — admit-still-valid 4/4** at `cebcf6c2`. Every card was re-run, so the drift-class lane is satisfied either way.
  - #8117: no ADR decides the documentation model (0; control ADR-089 "hand-kept" → 1).
  - #8119: `Documentation Impact` per form — epic 0 · story 0 · observation 0 · adr 0 · improvement 2 · bug 1. `retire` 0/0 (control `update` 5/2). No `docs/` in either list.
  - #8494: `retire` in the standard 0 (control "flow class" 10); seven classes; lint "enum OK".
  - #8495: stage-02 `current-state` 0 (control 2); stage-05's 2 hits unrelated (control 13); both gate rows "not yet emitting".
- **Parallelization-Map currency — FINDING at Stage 4:** no `## Parallelization Map` section, which A9.6 requires. Reconfirm scan (the map's own recipe): 4/4 `CLEAN` (control milestone #430 → `EDGE` 2). Tier-S: neither sibling has a rename or delete (0 `R`/`D`; control `A` 4/5), so the only Tier-S edge is the version slot. Resolved by the hub's Tier 1 [ADJUST] (the map is now in the milestone description).
- **A0 confidence gate:** A7 outcome **amend** — description metadata only; membership and the Composition Lock are unchanged. The signal is grounded: a HIT corroborated by four admit-still-valid verdicts, and a nameable gap. `[CHEAP · confidence: HIGH]`.

## Implementation Sequence

1. **Commit 0** — this plan file (`{{RELEASE_VERSION}}` in the Header Version cell; Commit-0 re-verify per Procedure 0), then **#8117**: land the ratified text as one ADR, reshaped only as the gates require. The number binds at merge.
2. **#8494** — standard extension and glossary; then the catalog folder's first tracked file **and** its scope-list row, in one commit.
3. **#8119** — forms, vocabulary, the one scope list (the G-CL8 row), restatement sweep, Check 28 template set.
4. **#8495** — Stage 2/5 planning read; G-CL6 and G-CL8 emitters with self-test; gate rows, Stage 13 phases, § 8 sink, and gate-efficacy register rows. **Held** — returned to Stage 5 Solutioning at Collective Review (DEV-6).

### Issue #8117: Decide how a repository's system documentation is modelled, and record the decision as an ADR

**Change Specification** (Solutioning-level; the Stage 5 spec on sub-task #8497 is the authority, as amended by the Collective Review adjustments on #8496):
- **Files:** `core/ADRs/ADR-221-system-documentation-is-a-generated-process-catalog.md` (add — `<N>` = `renumber-adr.py --next-free` at Commit 0, which printed 221); `core/ADRs/README.md` (no edit at Stage 6 — DEV-4).
- **Change description:** land the operator-ratified documentation-model decision as an `Accepted` ADR with the spec's gate-driven edits E1–E10 (identity frontmatter, references moved into a `## References` block, an H1, `## Related ADRs`, the Context count dated to the spike's filing, the D6 alternative and the reader-set note under Alternatives Considered), plus the Collective Review status-wording adjustment (the ratifying review named as the operator's planning-gate ratification, without the undefined gate label). `## Decision` stays byte-identical to the ratified text.
- **Acceptance criteria:** four, per the card (AC2 and AC3 as re-worded by the operator on 2026-10-24).
- **Estimated complexity:** Low — one new file, mechanical edits.
- **Dependencies:** none.

### Issue #8494: Extend the design-artifact standard to the generated process catalog the documentation-model ADR chose

**Change Specification:** the Stage 5 spec on sub-task #8498 is the authority, with the Collective Review adjustments that fall on this card (seven link types; superseded-page retention (b); no § 7 Tier-A trigger for `state-lifecycle` this release; the § 5 retirement row and the re-pointing exclusions; one sentence on the L0 page's visual class; the structural map gains the catalog folder; the two count-free rewordings outside the matrix). Stage 4 carried: an eighth enum value vs a sub-class (R4 sites); the folder name and its first file (R3); the retire text per D-RetireSemantics. **Dependencies:** #8117 (build).

### Issue #8119: Documentation Impact reaches every work-item form, covers docs/, and can declare a retirement

**Change Specification:** the Stage 5 spec on sub-task #8499 is the authority, with the Collective Review adjustments that fall on this card (four of six forms carry the field, observation and ADR forms exempt; the scope list as the union of its three wordings plus `docs/`; the forms' retire gloss aligned to the G-CL8 row and standard § 5; the intake-desk type-map pointer deferred to a later release). Stage 4 carried: the PR-template status vocabulary gains a retire value, restated in Stage 6 C1.5; one scope list in the G-CL8 row, with every other site citing it. **Dependencies:** consistency with #8117 and #8494 (D-RetireSemantics).

### Issue #8495: Planning reads the current-state process pages a change touches, and close verifies documentation instead of only specifying it

**Change Specification:** **held** — returned to Stage 5 Solutioning on sub-task #8500 to fold in the adversarial review's two Major failure modes and to re-estimate its size (DEV-6). Stage 4 carried: emitter home — reuse first, since Check 28's header already specifies the per-issue mechanism (steps 1–4) that was never implemented; the no-page record form; § 8 sink realignment (CIAC-2); W2 exit criteria for G-CL6 and G-CL8 in the gate-efficacy register (R9); the written-to-visual deferral. **Dependencies:** #8119 (build), #8494 (build for the emitter half), #8117 (release-gate).

### Agent-Editability Read

**Derivation** — controls read at commit `cebcf6c2`:
- Tier-0 floor: `core/hooks/block-autonomy-ceiling.sh` — every `case` block whose arms invoke `always_block "BLOCK-AUTONOMY-001"`: **2** blocks observed (3 `always_block` call sites; block 2 calls it on two branches). Arms quoted verbatim:
  - Block 1: `"${PRIMARY_ROOT}/CLAUDE.md"` · `"${PRIMARY_ROOT}/projects/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"` · `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"` · `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"` · `"${PRIMARY_ROOT}/.claude/settings.json"` · `"${PRIMARY_ROOT}/.claude/hooks/"*` · `"${PRIMARY_ROOT}/.claude/rules/"*`
  - Block 2 (repository membership): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`
  - Projected repo-relative union: `CLAUDE.md`, `*/CLAUDE.md`, `OPERATIONS.md`, `*/OPERATIONS.md`, `RELEASE_PROTOCOL.md`, `*/RELEASE_PROTOCOL.md`. The workspace-root and `.claude/` arms are discarded because the repository tracks none of them (`git ls-files .claude` → 0).
- Sanctioned-session gate: `core/hooks/block-skill-direct-edit.sh` — `SKILL_SCOPE_RE` = `'(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$'`; arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`; exemption list resolved by `pmo_skill_editor_exemption_list_for` under `<deploy-root>` — **undetermined, not consulted**: conjunct 1 is false for every write-set path, so conjunct 3 is never reached.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| #8117 | `core/ADRs/ADR-NNN-<slug>.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8117 | `core/ADRs/README.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8494 | `core/standards/design-artifact-standard.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8494 | `core/specs/terminology-glossary.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8494 | `core/deploy/allowlists/doc-link-target-paths.txt` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8494 | `core/<catalog-folder>/README.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8494 | `release/references/how-to/design-artifact-backfill-completion-condition.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `.github/ISSUE_TEMPLATE/epic.yml` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `.github/ISSUE_TEMPLATE/story.yml` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `.github/ISSUE_TEMPLATE/observation.yml` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `.github/ISSUE_TEMPLATE/adr.yml` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `.github/ISSUE_TEMPLATE/improvement.yml` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `.github/ISSUE_TEMPLATE/bug.yml` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `.github/PULL_REQUEST_TEMPLATE.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `core/schemas/gate-criteria-spec.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `release/references/pipeline/stage-13-close.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `release/governance/release-process.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `core/deploy/deploy.sh` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `release/references/pipeline/stage-01-intake.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `release/references/pipeline/stage-06-engineering.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8119 | `core/schemas/field-lifecycle-matrix.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `release/references/pipeline/stage-02-triage.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `release/references/pipeline/stage-05-solutioning.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `core/standards/gate-efficacy-standard.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `core/standards/design-artifact-standard.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `core/schemas/gate-criteria-spec.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `release/references/pipeline/stage-13-close.md` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `core/deploy/deploy.sh` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `core/deploy/tests/test_doc_gate_emitters.sh` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `release/tools/doc-gate-emitter.py` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `release/tools/tests/test_doc_gate_emitter.py` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |
| #8495 | `core/config/allowlists/script-execution-allowlist.txt` | no | no (conj. 1) | unconstrained | unconstrained | ordinary Engineering spoke |

All rows read `unconstrained`: no control refuses these writes. That does not make them ungoverned — the standards, gate spec and pipeline specs are governed surfaces under the issue → plan → PR path.

## Risk Register

| # | Risk | Sev. | Mitigation | Owner |
|---|---|---|---|---|
| R1 | Ratified ADR text **fails the required issue-reference-validity check as-is**: 6 findings on 5 lines, including the `status:` frontmatter | High | Move every reference into a `## References` block; drop `(#8117)` from `status:`; path-mode rehearsal at Stage 7 | Stage 5/6 |
| R2 | ADR 221 is claimed twice in flight; the README renumber-log inserts collide | Med | Oracle number + `{{ADR:<slug>}}`; `--stamp` at Stage 12; the renumber tool writes the README | Stage 6/12 |
| R3 | Scope row on an empty catalog folder → link check **exit 3, hard fail even in warn mode** | High | First tracked `.md` in the same commit as the row | #8494 |
| R4 | Eighth flow class silently dropped (§ 2, § 9 query and rule, § 12.2 loop and lint, backfill how-to) | Med | One commit for all sites; Stage 7 positive-control marker | #8494 |
| R5 | Contradictory retire semantics across two Stage 5 specs | High | D-RetireSemantics at the Stage 4 gate | Operator |
| R6 | Same-row edits by #8119 and #8495 (G-CL8 row and self-repair row, A11, Check 28) | Med | P0 serial in card order; CIAC-1 | Stage 6 |
| R7 | Cross-PR neighbour #8396 at § 9 `:221`; disjoint hunks in 3 more files | Low–Med | Rebase whichever lands second; Stage 9 A6.5 | Hub |
| R8 | Three in-flight `minor` releases recompute to v4.78 | Low | Atomic claim at merge; Commit-0 re-verify | Stage 6/12 |
| R9 | Emitting G-CL6/G-CL8 flips W1 to a written sink; **W2 still needs a repo-derivable exit criterion**; G-CL6 has no register row | Med | Stage 5 authors both register rows | #8495 |
| R10 | Restatement sweep incomplete (scope: 7 sites, 3 list wordings; vocabulary: 5 sites) → #8119 AC3 fails | Med | Matrix rows for every site; Stage 6 pre/post counts | #8119 |
| R11 | New required field changes intake; kind forms are pack-projected (A6) | Med | Stage 5 states the kind-derivation path or scopes AC1 | #8119 |
| R12 | #8119 AC4 and #8495 AC4 are observable only after ship | Low | Declared-deferred; read in the 30-day window | Stage 13 |
| R13 | The emitters ship in the release they would grade | Low | Introducing-release-exempt; run informationally | Stage 13 |
| R14 | Wrong identity mode → wrong close-out path | Med | D-ReleaseIdentity before Commit 0 (rendered: versioned) | Operator |
| R15 | Rollback reverts an Accepted ADR | Low | One revert; tag retained; release-log row | Operator |

## Delivery Strategy

| Aspect | Decision |
|--------|---------|
| **Implementation approach** | Sequential (dependency-ordered), P0 fully serial |
| **Commit strategy** | Commits in card order, each card one coherent slice; Commit 0 is this plan |
| **Review approach** | Single PR for the entire release |
| **Deployment mechanism** | Git merge; the atomic version claim and the ADR `--stamp` at the Stage-12 merge; no Layer-2 propagation target (see § Operational Deployment Manifest) |
| **Stacked-base cleanup posture** | Phase B0 base-shift per dep (default — Option A); no stacked bases planned |

**Delivery:** D-C SINGLE. One branch, which existed **locally only** at `cebcf6c2` until it was pushed at Commit 0. One PR. Stage 6 is serial (P0). Stage 5/7/8 per-card spokes may run in parallel under Checkpoint B, with Stage 5 in two lanes (see § Quota Budget). Stage 12 merges after the Stage 9 GO; the atomic version claim and the ADR `--stamp` run at merge. Close-out actions read *mark #8117, #8494, #8119 and #8495 as closed at Stage 13*.

**Pacing (Collective Review, 2026-10-24):** Engineering one card at a time, each launch quota-gated; stop cleanly between cards at the operator's weekly-usage line and resume after the weekly reset.

## Verification Plan

### Per-Issue Verification

`ac_baseline: { #8117: 4, #8494: 5, #8119: 4, #8495: 4, read_at: cebcf6c2 }`

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8117 | AC-1 | `grep -c -F "One document per top-level process and component class" core/ADRs/ADR-221-system-documentation-is-a-generated-process-catalog.md` at least 1 [READER-GRADED — Decision items 1–3 name the chosen option for D1, D2 and D6; Alternatives Considered carries each one's rejected options] | ≥1 (base: file absent) |
| #8117 | AC-2 | `grep -c -F "never hand-maintained" core/ADRs/ADR-221-system-documentation-is-a-generated-process-catalog.md` at least 1 [READER-GRADED — Decision 1 generates the index, graph and views from page frontmatter and the element inventory; Context bullet 2 cites ADR-089's lost-entry reasoning] | ≥1 (base: file absent) |
| #8117 | AC-3 | `grep -c -F "is the page lifecycle; no new" core/ADRs/ADR-221-system-documentation-is-a-generated-process-catalog.md` at least 1 [READER-GRADED — Decision 6 reuses the platform-doc `status` field; Consequence 1 names the state and lifecycle flow class for the standard extension] | ≥1 (base: file absent) |
| #8117 | AC-4 | [DEFERRED — `status:` is terminal on main only after merge; the Stage 13 G-CL9 authored limb reads the frontmatter of the landed path on main] | leading token `Accepted` |
| #8494 | AC-1 | `grep -c -i -F "value stream" core/standards/design-artifact-standard.md` at least 1 [READER-GRADED — the section names the folder and the generated-never-hand-kept rule] | ≥1 (base 0) |
| #8494 | AC-2 | `grep -c -F "sub-flow-of" core/standards/design-artifact-standard.md` at least 1 [READER-GRADED — § 2 lists the state/lifecycle class; the § 12 lint run on a marker using it prints enum OK] | ≥1 (base 0) |
| #8494 | AC-3 | `grep -c -i -F "retire" core/standards/design-artifact-standard.md` at least 1 [READER-GRADED — status transitions, no deletion, inbound links re-pointed in the same change] | ≥1 (base 0) |
| #8494 | AC-4 | `grep -c -F "inbound index" core/standards/design-artifact-standard.md` at least 1 [READER-GRADED — the exception sits in § 9] | ≥1 (base 0) |
| #8494 | AC-5 | [DEFERRED — the folder name binds at Stage 5; the PR-time link check runs `check-doc-links.py --require-targets` over the list and exits 3 on an empty entry] | link check green; folder row present |
| #8119 | AC-1 | `grep -c -F "label: Documentation Impact" .github/ISSUE_TEMPLATE/epic.yml` at least 1 [READER-GRADED — the same count is non-zero on story.yml and on each further form Solutioning names] | ≥1 (base 0) |
| #8119 | AC-2 | `grep -c -i -F "retire" .github/ISSUE_TEMPLATE/improvement.yml` at least 1 [READER-GRADED — the G-CL8 row states how a retirement is verified] | ≥1 (base 0) |
| #8119 | AC-3 | `grep -c -F "docs/" core/schemas/gate-criteria-spec.md` at least 1 [READER-GRADED — forms, PR template and stage restatements cite the G-CL8 row instead of restating a list] | ≥1 (base 0) |
| #8119 | AC-4 | [DEFERRED — post-ship observation: the first epic filed through epic.yml after merge, read in the Stage 13 30-day outcome window] | `### Documentation Impact` present |
| #8495 | AC-1 | `grep -c -F "last_verified_commit" release/references/pipeline/stage-02-triage.md` at least 1 [READER-GRADED — stage-05-solutioning.md carries the same step and the no-page record form] | ≥1 (base 0) |
| #8495 | AC-2 | [DEFERRED — the emitter home binds at Stage 5; its CI-invoked self-test runs the two-fixture case and asserts both warn-log rows] | 2 FAIL rows, warn mode |
| #8495 | AC-3 | `grep -c -E "^. G-CL[68] .*not yet emitting" core/schemas/gate-criteria-spec.md` expect 0 [READER-GRADED — each row names its emitter] | 0 · control: the identical count returns 3 at `cebcf6c2` (G-CL8 row, G-CL6 and G-CL8 self-repair rows) |
| #8495 | AC-4 | [DEFERRED — post-ship observation: the first Stage 5 output comment after merge] | cites pages, or records that none covers the area |

**#8117 rows bound at Commit 0.** Stage 4 deferred AC-1 to AC-3 until the ADR path bound; the path bound at Commit 0 (`renumber-adr.py --next-free` → 221), so each row now names a runnable probe on the landed path and keeps its reader-graded limb (DEV-5). If the Stage-12 claim renumbers the record, the post-merge reads follow the renamed file; Stages 7 and 8 run before any renumber.

**Stage 7 positive controls owed:** (a) a scratch marker using the new flow class → § 12.2 lint prints `enum OK` and the per-type loop counts it; (b) `check-issue-ref-validity.sh` in path mode on the ADR → exit 0 (the ratified text as-is → exit 1 with 6 findings); (c) the ADR durability lint → `## Related ADRs` present and `release:` set to the slug; (d) each emitter's fixture run → its row in the warn log.

### Release-Level Verification

- [ ] File Integrity — every unconditional ADD in the File Change Matrix present on the branch (`verify-release-plan.sh` `fcm-delivery` family)
- [ ] Content Correctness — per-issue rows above, reader-graded limbs at Stage 8
- [ ] Cross-Reference Validity — the dead-file-reference gate, the doc-link checker over the shared scope list with `--require-targets`, the issue-reference validity gate
- [ ] Skill Invocation — N/A: no skill file and no skill-package input in the matrix (`build-skill-packages.sh --skills-for-paths` resolves 0 skills over every matrix path)
- [ ] Output Contract Compliance — ADR schema and durability lint on the ADR; the § 12 lint on the standard; Check 28 on the forms

## Cross-Issue Acceptance Criteria

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8119 × #8495 on `release/references/pipeline/stage-13-close.md`):** After both cards land, the two Stage 13 phases they both edit — Phase A5 (G-CL6) and Phase A11 (G-CL8), which #8119 realigns to the one scope list and the retire action and #8495 rewires to run the emitters — no longer carry the "specified, not yet emitting" disclosure. *Method:* `grep -c -F "specified, not yet emitting" release/references/pipeline/stage-13-close.md` expect 0. *Graded at Stage 9 QC3.5 on the merged PR.* Control arm, same instrument and same target: the identical count returns 2 at the release base cebcf6c2 (Phase A5 and Phase A11).
- [ ] **CIAC-2 (#8494 × #8495 on `core/standards/design-artifact-standard.md` § 8):** The G-CL6 refresh-gate text in the standard #8494 extends names no per-gate warn-log file, so it agrees with the shared deploy-check warn log the #8495 G-CL6 emitter writes. *Method:* `grep -c -F "design-artifact-warn-log.jsonl" core/standards/design-artifact-standard.md` expect 0. *Graded at Stage 9 QC3.5 on the merged PR.* Control arm, same instrument and same target: the identical count returns 1 at the release base cebcf6c2 (§ 8 warn-mode row).
- [ ] **CIAC-3 (#8494 × #8495 on the `last_verified_commit` page field):** The page field the Stage 2 and Stage 5 planning read cites (#8495) is defined in the standard that governs the generated process catalog (#8494). *Method:* `grep -c -F "last_verified_commit" core/standards/design-artifact-standard.md` at least 1. *Graded at Stage 9 QC3.5 on the merged PR.*

G4-06 lint at Stage 4: `CIAC-LINT-SUMMARY	declared=3	parsed=3	clean=3	declared-deferral=0	flagged=0` (exit 0). Lint sensitivity: a prose-method control CIAC → `FLAG no-runnable-command`, exit 3. Retire agreement (#8119 × #8494) is **not** a CIAC because its wording depends on D-RetireSemantics; Stage 5 authors it as an INT-N on the #8119 ↔ #8494 surface.

## Rollback Strategy

### Per-Issue Rollback

| Issue | Rollback Method | Rollback Complexity |
|-------|----------------|-------------------|
| #8117 | `git revert` of its commit removes the ADR file | Low — one new file, no inbound referrer outside this release |
| #8494 | `git revert` of its commits; #8495's emitter half reads the standard, so revert #8495 first | Medium |
| #8119 | `git revert` of its commits; #8495 edits the same G-CL8 rows, so revert #8495 first | Medium |
| #8495 | `git revert` of its commits | Low–Medium |

### Whole-Release Rollback

One revert of the merge commit (`git revert -m 1`) removes the ADR, the standard and glossary edits, the form and gate changes and the emitter together. The version tag is **retained**, never deleted (host-protected); the rollback is recorded in the release log. Residue that survives a revert is harmless: cards filed on the new forms keep their `### Documentation Impact` section, and G-CL8 is body-keyed. `[MODERATE · confidence: HIGH]` — the decision the ADR records is EXPENSIVE, but landing and unlanding it is one commit.

| Strategy | Trigger | Procedure |
|----------|---------|-----------|
| **Partial Revert** | Isolated card failure | Revert that card's commits, in reverse dependency order |
| **Full Restore** | Systemic failure | Revert the merge commit |
| **Forward Fix** | Minor issue, fix well-understood | Fix branch |

## Operational Deployment Manifest

N/A — enumerated over the Layer-2 propagation classes (the skills mirror and skill packages, the rules mirror, harness artifacts, operator-instance seed files); no File Change Matrix path is a member of any. `build-skill-packages.sh --skills-for-paths` resolves 0 skills over the whole matrix (control: `release/skills/release-hub/SKILL.md` → `release-hub`), and none of the nine rules-mirror pairs in `deploy.sh` `mirror_pair_set()` (all under `core/rules/`) is in the matrix. The issue forms and the PR template take effect on GitHub at merge, with no deploy step.

### Schema Migrations (if applicable)

N/A — enumerated over frontmatter schemas, issue-form field schemas and gate-row formats; the new Documentation Impact field and retire value are additive, and no stored record is rewritten.

## Quota Budget

**Verdict:** PASS (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: 4 (recommended lanes 3 + 1) · Stage 7: 4 · Stage 8: 4
**Per-spoke cost estimate:** size-bucket band (heuristic; no telemetry medians): 3 × `size:M` low–moderate, 1 × `size:L` moderate–high. Anchored to a fan-out measurement of about 5 % of a 5-hour window per heavy spoke, and about 7.5 % for `L`.
**Assumed/stated remaining usage-window envelope:** not stated to the Stage 4 spoke → conservative default of half a 5-hour window.
**Estimated cumulative draw % (worst parallel batch):** Stage 7 or 8 at 4 spokes ≈ 22.5 % of a full window ≈ **45 % of the assumed envelope**. Stage 5 as 3 + 1 lanes ≈ 30 %.
**Routing:** PASS: proceed — at the upper edge. If the stated remaining window is under about 45 % of a full window, the same batch reads WARN → run two lanes of two.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton. Bands are `[CALIBRATE-AFTER-3]` MEDIUM.

## Hub-Rendered D-Decisions

| ID | Decision | Verdict | Reversibility · Confidence | Where recorded |
|---|---|---|---|---|
| **D-Plan** | Stage 4 release plan + Release Outcome Statement | **Approved** | MODERATE · HIGH | Stage 4 gate, #8496 |
| **D-ReleaseClass** | What Release Class does this release carry? | **(C) cross-cutting** — trigger (a) fires on five pipeline stage specs (01, 02, 05, 06, 13); 26 effective pts under the keep-as-one disposition | CHEAP · HIGH | Stage 4 gate, #8496 |
| **D-ReleaseIdentity** | Is this release versioned or version-less? | **(A) versioned** — every member changes tracked files | CHEAP · HIGH | Stage 4 gate, #8496 |
| **D-Version** | What version does this release claim? | recorded determination (not a gate): bump-class **minor**; provisional **v4.78** (anchor v4.77); binds only at the Stage 12 atomic claim; re-verified at Engineering Commit 0 | CHEAP · HIGH | Stage 4 gate, #8496; re-verify at Commit 0 |
| **D-RetireSemantics** | What does "retire" mean, per document class? | **(A)** — a document carrying the platform-doc `status` field retires by a status move (DEPRECATED, or SUPERSEDED with its successor), inbound links re-pointed in the same change, nothing deleted; a document without the field is deleted with zero inbound references left; close-out verifies whichever applies | CHEAP · HIGH | Stage 4 gate, #8496 |
| **D-Concurrency Posture** | Which Stage 6 parallelism posture? | **P0 fully serial**; no force-push on the release branch | CHEAP · HIGH | Stage 4 gate, #8496 |
| **D-Pacing (Stage 4)** | Pacing of Stages 5–8 | run Stages 5–8 with one spoke per stage covering every card (Engineering serial inside it); stop at the operator's weekly-usage line and resume after the weekly reset | MODERATE · MEDIUM | Stage 4 gate, #8496 |
| **D-CR1** | Scope lock | **Approved for #8117, #8494 and #8119** — Engineering authorized for these three, serial in the plan order | MODERATE · HIGH | Collective Review, #8496 |
| **D-CR2** | #8495 | **Returned to Stage 5 Solutioning** — re-spec to fold in the adversarial review's two Major failure modes and to re-estimate its size; no Engineering on #8495 before its re-spec returns to Collective Review | MODERATE · HIGH | Collective Review, #8496 |
| **D-CR3** | Stage 5 design recommendations | **Accepted as one set** (enumerated in DEV-7) | CHEAP · HIGH | Collective Review, #8496 |
| **D-CR4** | Consistency-table disagreement | **Resolved by adjustment:** the forms' retire gloss ("every inbound link") aligns at Engineering to the G-CL8 row and standard § 5 (no live mention of the path left) | CHEAP · HIGH | Collective Review, #8496 |
| **D-CR5** | Adversarial Minor fixes adopted for Engineering | the ADR status wording names the operator's planning-gate ratification without an undefined gate label; one sentence in the standard on the L0 page's visual class; the structural map gains the catalog folder | CHEAP · HIGH | Collective Review, #8496 |
| **D-CR6** | Pacing | Engineering one card at a time, each launch quota-gated; stop cleanly between cards at the operator's weekly-usage line and resume after the weekly reset | CHEAP · HIGH | Collective Review, #8496 |

**Per-card disposition at the Stage 4 gate:** #8117 carried · #8494 carried · #8119 carried · #8495 carried.

**D-CR1 scope — explicitly NOT covered:** Engineering on #8495, and any change to the size labels or the size disposition (re-rendered when #8495's re-spec returns to Collective Review).

## Deviation Log

| # | Deviation | Source | Disposition |
|---|---|---|---|
| **DEV-1** | Readiness-stage operator decisions, rendered before Stage 4 entry on 2026-10-24: composition kept at four cards; size kept as one with rationale under G3-15 (raw 20, effective 26, one point over the 25-pt ceiling); #8117 AC2 and AC3 re-worded to the decision the operator ratified at the process-baseline planning gate on 2026-10-23 (AC1 and AC4 unchanged; that ratification is AC4's ratifying review, so the ADR lands `Accepted`); warrant re-confirmed | Operator, milestone readiness pre-flight; recorded on #8117 and with the Stage 4 gate on #8496 | **APPLIED** |
| **DEV-2** | Stage 4 Tier 1 [ADJUST] items applied by the hub: the release-identity line and the Parallelization Map in the milestone description; the cascade files on the cards' Affected Files and Documentation Impact; dependencies recorded under `Blocked by:` and mirrored natively | Stage 4 → hub, Tier 1 | **APPLIED** (by the hub before Stage 5) |
| **DEV-3** | File Change Matrix, #8117 ADD row: `core/ADRs/ADR-NNN-<slug>.md` becomes `core/ADRs/ADR-NNN-system-documentation-is-a-generated-process-catalog.md`. The slug bound at Stage 5 (D-Slug); the number stays a placeholder in the matrix because it binds at the Stage-12 claim, and the record lands as ADR-221 per the `--next-free` oracle at Commit 0 | Stage 5 spec, #8497 (D-Slug); Collective Review scope lock | **APPLIED** at Commit 0 |
| **DEV-4** | File Change Matrix, `core/ADRs/README.md`: Stage 4's unconditional EDIT ("regenerated by `generate-adr-index.py`") becomes `CONDITIONAL:ADR-RENUMBERED-AT-CLAIM`. No core ADR index projector exists — the generator projects only `release/ADRs/README.md`, and the core README is a curated thematic document — so Stage 6 makes no edit; `renumber-adr.py` appends one renumber-log line at Stage 12 only if the claim moves the number | Stage 5 spec, #8497 (F1, D-README); Collective Review accepted the spec set | **APPLIED** at Commit 0 |
| **DEV-5** | Verification Plan, #8117 AC-1 to AC-3: converted from `[DEFERRED — the ADR path binds at landing]` to runnable probes on the bound path, as the Stage 4 rows directed for Commit 0; each keeps its reader-graded limb | Stage 4 plan direction; Stage 5 AC-binding table, #8497 | **APPLIED** at Commit 0 |
| **DEV-6** | #8495 returned to Stage 5 Solutioning at Collective Review (2026-10-24): re-spec to fold in the adversarial review's two Major failure modes (lenient declaration grammar → false PASS; silent population-read fallback → false CLEAN) and to re-estimate its size (the spec reports `size:XL` work against the `size:L` label, which moves the bundle from raw 20 / effective 26 to raw 28 / effective 36). Its size disposition is re-rendered when its re-spec returns to Collective Review. The scope lock covers three of four cards until then | Operator, Collective Review, #8496 | **APPLIED** — Engineering on #8495 held |
| **DEV-7** | Collective Review accepted the Stage 5 design recommendations as one set: superseded-page retention (b) — in place, marked in the generated index, no timed window; seven link types; no § 7 Tier-A trigger for `state-lifecycle` this release; the ADR's Context count dated to the spike's filing (ratified figure unchanged) plus its two recording additions (the D6 alternative; the reader-set note); the two count-free rewordings outside the matrix; the § 5 retirement row for embedded artifacts and the release-record / ADR re-pointing exclusions; the Documentation Impact scope list as the union of its three wordings plus `docs/`; four of six forms carry the field (observation and ADR forms exempt); the intake-desk type-map pointer deferred to a later release | Operator, Collective Review, #8496 | **APPLIED** — each card's Engineering spoke implements its share |
| **DEV-8** | Stage 5 corrections to Stage 4 premises, both accepted with the #8117 spec: no index regeneration applies to a core ADR (DEV-4); and the Context count is anchored to the spike's filing (40 = 38 embedded + 2 dedicated on first-parent main at the end of 2026-10-02), not "at the pilot", when the count was 47 | Stage 5 spec, #8497 (F1, F2); adversarial review, #8518 (premises verified) | **APPLIED** |
| **DEV-9** | Collective Review adjustment on #8117 (adopted adversarial Minor fix, FM-1): the ADR's `status:` line and its `## Status` sentence name the ratifying review as the operator's process-baseline planning-gate ratification (2026-10-23), replacing the undefined gate label. The adversarial review's other #8117 items were not adopted: FM-1's alternative mitigation (extend the References entry instead) and CD-1 (keep Context byte-identical) | Operator, Collective Review, #8496; adversarial review, #8518 | **APPLIED** in #8117's commit |
| **DEV-10** | Collective Review adjustment across #8119 and #8494 (consistency-table disagreement): the forms' retire gloss aligns to the G-CL8 row and standard § 5 — no live mention of the path left | Operator, Collective Review, #8496 | **PENDING** — #8494 and #8119 Engineering |
| **DEV-11** | Transcription edits at Commit 0, each a pointer rewrite with the finding unchanged: (a) in the adopted A0 rows, six citations of operator-local memory entries and five uses of the undefined planning-gate label are replaced by the content they stood for, because neither surface exists in the tracked corpus — the same class as DEV-9; (b) the DEV-4 correction is carried into the Cross-PR Overlap row for `core/ADRs/README.md`, the R2 mitigation and the matrix notes, which named the regeneration Stage 5 showed does not exist; (c) sections the Stage 4 comment carried as hand-offs (the Tier 1 [ADJUST] list, the Stage 5 inputs) are folded into DEV-2 and the per-issue Change Specifications rather than transcribed as open instructions, since both have been executed | Stage 6, Tier 1 | **APPLIED** at Commit 0 |

## Verification Evidence

(Populated at Stage 6 C4 self-verification onward, and after Stage 12 execution — see verification-checklist.md for format)

## Deployment Execution Log

(Populated during Stage 12 — see execution-checklist.md)

| Step | Timestamp | Result | Notes |
|------|-----------|--------|-------|
| Pre-execution check | | | |
| Merge PR | | | |
| Tag release | | | |
| Skill deployment | | | |
| Manifest execution | | | |
| State anchor update | | | |
| Post-execution verification | | | |
