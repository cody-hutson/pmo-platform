<!-- reference-durability: allow-issue-ref -->
<!-- repo-integrity: allow-issue-ref -->
# Release Plan — release-version-claim-determinism

**Milestone:** release-version-claim-determinism (#222) · **Release Class:** cross-cutting · **Topology:** D-C SINGLE
**Epic:** #1187 (PIPE-Release-Identity) · **Issues:** 14 (the in-scope set listed below)
**Capability slug:** `release-version-claim-determinism` — the durable pipeline identity (branch `release/release-version-claim-determinism`, plan `release-version-claim-determinism_RELEASE_PLAN.md`). Per the architecture this release builds, the **version leaves pipeline identity** and is claimed atomically at the Stage-12 merge tag — this plan binds **no concrete `vX.Y`** (bump-class + provisional-display only).
**Stage 4 source:** the Stage 4 Release Planning sub-task comment (the Stage 4 spoke output on sub-task #1702), reproduced below as the committed release plan (Engineering Commit 0). The Scope-Lock Addendum at the end transcribes the locked decisions + the elevated host-agnostic architecture from the Collective Review scope-lock comment.

---

## Stage 4 Release Planning — release-version-claim-determinism

> Milestone #222 · 14 issues · capability slug `release-version-claim-determinism` (the durable pipeline identity) · epic #1187 (PIPE-Release-Identity).
> Read-only planning output. No tracked file modified; no branch/commit created. This comment + the `### Per-Issue Verification` mappings are the Stage-4 working reference until Engineering Commit 0.

### Summary (30 seconds)

The wave structure from the milestone description **holds under graph evidence** with one refinement: **#1008 belongs in Wave A**, not Wave B — it is a hub-D-Version-gate doc edit (`hub-spoke-bridge.md` Procedure 0) with no dependency on the claim mechanism, and it co-locates with the same file #66 edits. Everything else sequences as declared.

The single canonical serialization order for Engineering (Stage 6) is: **#1697 → #1674 → #1673 → #1676 → #65 → #66 → #1008 → #1675 → #769 → #1677 → #1678 → #1679 → #1092 → #950**. This is the order the hub routes against; it respects every dependency edge and front-loads the high-contention shared files (`RELEASE_PROTOCOL.md`, `release-process.md`, `hub-spoke-bridge.md`, `stage-12-execute.md`, ADR-024) so each is touched by adjacent slices, never by widely-separated ones.

> **Stage-6 sequencing note (Collective Review scope-lock supersedes the Stage-4 order):** the locked Engineering serialization is `#1697 → #1676 → #1673 → #1674 → #1008 → #65 → #66 → #1675 → #769 → #1677 → #1679 → #1678 → #1092` (grammar SSOT #1676 lands second so every later slice sources one parser; #1679 owns the ledger schema #1678 consumes). See the Scope-Lock Addendum § Implementation Sequence. The Stage-4 order below is retained as the planning rationale that the scope-lock refined.

**Recommendations up front:** Release Class = **cross-cutting** (confirmed — 4 trigger conditions fire). Branch topology = **D-C SINGLE** (default; recommended — 14 wave-dependent slices with heavy shared-file overlap make per-issue PRs net-negative). Version = **minor bump**, provisional-display **v2.16** (do NOT bind; tags through v2.14 exist, v2.15 held by open PR #1700, v2.16 next-free at the moment of this read). **No split recommended** — the bundle's coherence override is sound and the dep chain is genuinely tight. Quota Budget = **PASS**.

**One correction to the pre-loaded context (verified against live state):** coordination point **#1643 (`.version` stamping) is CLOSED**, milestone `release-version-stamping` — it has shipped, it is not in-flight. This materially downgrades the Wave-B coordination risk: `.version` stamping at claim-time is now a *consume-the-shipped-behavior* relationship, not a *coordinate-with-concurrent-work* one. #1672 (closeout-tooling rework) **remains open + unmilestoned** — the Wave-C coupling stands.

**Audit baseline (pin this finding):** verified at `origin/main = d3bc6dd` (merge of PR #1703), `git fetch --tags` at read time. Tags v2.00…v2.14 exist (incl. the real three-component hotfix `v2.06.1`). PR #1700 (`release(v2.15)…`) holds v2.15, claimed-but-untagged. PR #1704 is a v2.12 Stage-13 corpus chore. The version landscape is the population this plan's version recommendation rests on; re-verify next-free at Stage-6 Commit 0 and again at the Stage-12 atomic claim (the whole point of this release).

---

### Dependency Graph

Directional edges (A → B means "A blocks B" / "B requires A"). Sourced from issue bodies + the milestone wave declaration; graph-verified against the actual file surfaces.

```
#1697  (Wave 0 — Founding ADR)
   │  blocks (every Wave-A/B foundation ticket reads "the founding ADR (Wave 0)")
   ├──────────────► #1674  (version-as-contended-axis / ADR-024 extension)
   ├──────────────► #1673  (authoritative allocation rule)
   ├──────────────► #1676  (canonical version grammar)   [also requires #1673]
   └──────────────► #1675  (atomic claim mechanism)        [also requires #1674]

#1673  (allocation rule — the "what is next-free" definition)
   ├──────────────► #1676  (grammar reads the allocation rule — issue body: "Requires G3 allocation rule")
   ├──────────────► #1677  (CI freeness check — issue body: "Requires version grammar (G4)")  [transitive via #1676]
   └──────────────► #1675  (claim mechanism resolves next-free per the allocation rule)

#1674  (version axis in cross-release model)
   └──────────────► #1675  (claim mechanism / freeness checks built on the model — issue body: "Requires … the cross-release-model extension")

#1676  (grammar — X.Y / X.Y.Z / suffix)
   ├──────────────► #1677  (freeness check must compare all three forms correctly)
   ├──────────────► #769   (Stage-12 freeness check compares versions — needs grammar)
   └──────────────► #1678  (recovery doctrine — issue body: "Requires the claim mechanism + grammar")

#1675  (claim mechanism — defer-to-merge + CAS-retry)
   ├──────────────► #1678  (recovery doctrine for residual post-tag collisions — "Requires the claim mechanism")
   ├──────────────► #1679  (machine-readable ledger records claim/abandon/reship events)
   └──────────────► #950   (source observation — closes when the prevention mechanism lands)

#65  ⇄ #66   (co-Solutioning pair — BOTH edit core/standards/version-field-semantics.md)
   │  #65 owns allocation-rule caveat + numbering semantics; #66 owns slot-vs-sequence + ship-order=merge-order
   │  Soft edge, not hard: either can land independently; cross-reference is cleaner shipped together.
   └──  #66 references already-shipped G-PR9 (compose, don't re-invent) — no new edge into this milestone

#769, #1008, #1677  →  all are DETECTION layer; depend on grammar (#1676) + the model (#1674)
   │  #1008 specifically edits hub-spoke-bridge Procedure 0 D-Version (planning-time + Commit-0 catch)
   └──  composes with the shipped Stage-9 G-PR8/G-PR9 (no edge into this milestone)

#1092  (Stage-13 corpus conflict doctrine)  — near-independent
   └──  "Composes with #769; no hard blocker" (issue body). Doc-only; can land any time after #1697.

#950  (root observation)  ← closed-by the landing of #1675 + #769 + #1008 + #1677 (the prevention+detection set)
```

**Graph-evidence confirmation of the wave structure:** The milestone's declared waves are a valid topological layering. The only correction the graph forces is #1008's wave membership (below). The tight chain the coherence override rests on — **#1697 → #1675 → #1678** — is graph-verified (ADR blocks mechanism; mechanism blocks recovery-of-residual). The #65⇄#66 pair is a genuine bidirectional co-edit on `version-field-semantics.md`, correctly grouped in Wave A.

**Wave-membership refinement (#1008 → Wave A):** The milestone description places #1008 in Wave B ("hub D-Version check"). The graph and the file surface argue for Wave A: #1008 edits `hub-spoke-bridge.md` Procedure 0 (the D-Version gate + Commit-0 re-verify) and depends only on the *allocation rule* (#1673) being authoritative — it does not depend on the claim *mechanism* (#1675). It also co-locates with #66 and #1675, which both touch `hub-spoke-bridge.md`. Sequencing it in Wave A (right after #65/#66, before #1675) reduces the hub-spoke-bridge.md edit span. This is a sequencing refinement, not a scope change — #1008 stays in the bundle. [INFERRED from issue #1008 body: "verifies next-free against AUTHORITATIVE refs … re-verifies at Stage-6 Commit 0" — no claim-mechanism dependency stated.]

---

### Implementation Sequence

The canonical serialization order for Stage 6 Engineering (the hub routes ONE Engineering chip at a time under D-C SINGLE, in exactly this order). Rationale per position emphasizes dependency-satisfaction first, shared-file adjacency second.

| # | Issue | Size | Why here (dependency + contention rationale) |
|---|---|---|---|
| 1 | **#1697** | M | Wave 0. Authors the founding ADR file (new). Unblocks all of Wave A/B. The ADR is authored *inside* this slice (not pre-written). Touches ADR-024 only as a cross-reference stub. |
| 2 | **#1674** | L | First foundation slice: extends ADR-024 with the version axis. Sequenced before #1673/#1676 because the *model* (what "contended" means) frames the *rule* (#1673) and the *grammar* (#1676). Touches ADR-024 + the cross-release-model spec — done early so later slices read the extended model. |
| 3 | **#1673** | M | The authoritative allocation rule ("what is next-free") in `RELEASE_PROTOCOL.md §Versioning`. Must precede grammar (#1676 reads it) and the claim mechanism (#1675 resolves next-free per it). First touch of `RELEASE_PROTOCOL.md`. |
| 4 | **#1676** | M | Canonical grammar (X.Y / X.Y.Z / suffix). Requires #1673. Precedes every freeness check (#1677/#769) — they compare versions per this grammar. Creates a new grammar reference doc. |
| 5 | **#65** | M | Numbering semantics + version-field chronological caveat. Co-Solutioning with #66. First touch of `version-field-semantics.md` (dual-gated: pre-commit hook + deploy.sh Check 6). Edits `release-process.md` / `stage-03-bundle.md` references. |
| 6 | **#66** | M | Parallel-release semantics (slot = identifier; ship-order = merge-order = tag-order). Second touch of `version-field-semantics.md` — adjacent to #65 to keep the dual-gated file's edits contiguous. Edits `release-process.md` §Stage 12 + first touch of `hub-spoke-bridge.md` (xref). |
| 7 | **#1008** | S | Hub D-Version gate: verify next-free against authoritative refs + re-verify at Commit 0. Edits `hub-spoke-bridge.md` Procedure 0 — adjacent to #66's hub-spoke-bridge touch. Requires the allocation rule (#1673, done). Detection-layer, planning-time catch. |
| 8 | **#1675** | L | **The prevention mechanism** — defer-to-merge + atomic CAS-retry. Requires #1697 + #1674. First substantive touch of `stage-12-execute.md` (atomic-claim step) + `RELEASE_PROTOCOL.md` (allocation timing). The graph spine's middle node (blocks #1678/#1679). |
| 9 | **#769** | M | Stage-12 / Stage-9 A6.5 pre-merge version-freeness check. Second touch of `stage-12-execute.md` (Phase A.5) — adjacent to #1675's edit. Also edits `stage-09-plan-review.md` + `hub-spoke-bridge.md`. Detection layer reinforcing the mechanism. |
| 10 | **#1677** | M | CI freeness gate + deploy.sh check. Requires grammar (#1676). **Executable surface** — adds a deploy.sh check + a new CI workflow under `.github/workflows/`. Front of the executable cluster. |
| 11 | **#1678** | M | Post-tag re-version recovery doctrine + orphaned-tag/ledger reaping. Requires #1675 + #1676. **Executable surface** — extends `cleanup-orphan-state.sh` (tag logic) + a new recovery runbook. |
| 12 | **#1679** | S | Machine-readable re-version ledger. Requires #1675 (the events it records). Defines a structured re-version record (RELEASE_LOG sub-field or a dedicated ledger). |
| 13 | **#1092** | M | Stage-13 concurrent-corpus conflict-resolution doctrine in `stage-13-close.md`. Near-independent (only "composes with #769"). Sequenced late: it is doctrine for the *close* stage and touches the four append-only ledgers' resolution rules. |
| 14 | **#950** | — | Source observation. No engineering work of its own — it is marked closed at Stage 13 once #1675 + #769 + #1008 + #1677 land (the prevention+detection set it asked for). Verification = trace its asks to the shipped slices. |

**Note on #65/#66 co-Solutioning:** both issue bodies explicitly recommend co-Solutioning (shared `version-field-semantics.md` edit, dual-gated). If Stage 5 activates (it should — see Stage Applicability), run #65 and #66 as a co-Solutioning pair producing one coherent design for the dual-gated file, then engineer them back-to-back (positions 5–6) to avoid a double-touch / merge-thrash on the dual-gated file.

---

### Stage Applicability Matrix

Default: all of Stages 5–13 apply. Skip Solutioning (5) only when a slice is trivially mechanical. Skip Dev-Testing (7) / QA (8) only when a slice has no functional/executable surface (pure doctrine prose). Below, "compress" = run the stage but at reduced depth (a single coherence pass rather than per-AC fixture execution). The per-release evaluation matrix the Stage-4 spoke instantiates.

| Issue | Surface class | S5 Solutioning | S6 Eng | S7 Dev Test | S8 QA | S9 Plan Review | S10 Dry-run | S11 Snapshot | S12 Execute | S13 Close | Rationale |
|---|---|---|---|---|---|---|---|---|---|---|---|
| **#1697** | ADR (new file) | **APPLY** | APPLY | **compress** | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | Founding ADR — design *is* the deliverable; S5 = the ADR authoring itself. DT compresses to "ADR template-conformance + 5-clause presence + immutable" structural checks (no executable surface). QA verifies the cite-not-restate of ADR-024. |
| **#1674** | ADR-024 extension + model spec | **APPLY** | APPLY | **compress** | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | Extends a shipped model (#87) — design uncertainty real (must preserve path-axis behavior). DT = grep-for-"version"-axis + "≥1 gate accounts for version contention" structural checks. |
| **#1673** | RELEASE_PROTOCOL.md §Versioning | **APPLY** | APPLY | **compress** | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | Reconciliation may *correct* (not just add to) the stale semantic table — design judgment needed. DT = read-section + diff-against-current verification (per AC). |
| **#1676** | grammar reference doc (new) | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | Grammar drives executable freeness comparison (#1677/#769 consume it). DT **applies fully** — AC says "compares all three forms correctly (method: test fixtures)". Real fixtures (X.Y vs X.Y.Z vs suffix, hotfix-vs-minor collision). |
| **#65** | version-field-semantics.md + refs | **APPLY** (pair w/ #66) | APPLY | **compress** | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | Co-Solutioning pair. Doctrine/spec prose; the only executable check is `deploy.sh --check` Check 6 still PASS (a deploy-check, run at S7-compress + S12). Stale-input flag (v1.x single-track) must be validated at S5. |
| **#66** | version-field-semantics.md + refs | **APPLY** (pair w/ #65) | APPLY | **compress** | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | Co-Solutioning pair. Must specify its Stage-9 check as *referencing* G-PR9, not a new gate — a design constraint resolved at S5. DT = Check 6 PASS + worked-example presence. |
| **#1008** | hub-spoke-bridge.md Procedure 0 | **compress** | APPLY | **compress** | APPLY | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | S-size doc edit to a procedure; design is constrained by #1697's ADR (defer-to-merge). S5 compresses to a fit-against-ADR check. DT = read-procedure verification. |
| **#1675** | stage-12-execute.md + RELEASE_PROTOCOL.md | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | The prevention mechanism — highest design weight in the bundle. **Has executable/behavioral surface** (CAS-retry logic, --force-with-lease ledger guard). DT/QA **apply fully**: the CAS-failure recompute+retry path must be exercised, not just read. AC method = grep + inspect plan template + read execute spec; behavioral AC needs a reproduction-and-observe method declared. |
| **#769** | stage-12 + stage-09 + hub-spoke-bridge | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | Pre-merge freeness check — **behavioral** (halt-and-re-version-before-merge). DT/QA apply: the "version taken → halt" branch is executable logic to test. |
| **#1677** | deploy.sh + .github/workflows/ | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | **Executable — tooling + CI.** Clearly needs DT/QA: a deploy.sh check (grep-verifiable + must actually detect a taken version) + a CI workflow (must block merge on a claimed version). Highest test value in the bundle alongside #1675. |
| **#1678** | cleanup-orphan-state.sh + runbook | **APPLY** | APPLY | **APPLY** | **APPLY** | APPLY (Deep) | APPLY | APPLY | APPLY | APPLY | **Executable** — extends a script with orphaned-tag detection logic. DT/QA apply: tag-detection logic must be exercised against a fixture orphan tag. Runbook half is doc (compress within S7). Couples #1672. |
| **#1679** | RELEASE_LOG schema / ledger | **APPLY** | APPLY | **compress** | APPLY | APPLY (Standard) | APPLY | APPLY | APPLY | APPLY | Schema/format definition. S size. DT = "format defined" + "≥1 historical re-version representable" (the v1.03 / v1.18→v1.19→v1.20 rows are ready fixtures). No executable logic — compress S7. |
| **#1092** | stage-13-close.md | **compress** | APPLY | **compress** | APPLY | APPLY (Standard) | APPLY | APPLY | APPLY | APPLY | Doc-only doctrine (the issue itself: "CHEAP reversibility / doc-only"). The resolution it documents already worked on main (merge `35364dd`). S5 compresses to fitting the doctrine to the real worked example; DT = doctrine-present + worked-example-present + post-resolution-checks-stated. |
| **#950** | (observation — no file) | **SKIP** | **SKIP** | **SKIP** | **SKIP** | n/a | **SKIP** | **SKIP** | n/a | APPLY | No deliverable of its own. Marked closed at S13 once the prevention+detection set lands. The only "stage" it touches is Stage-13 closure (trace-its-asks verification). |

**Compression honesty note (per persona anti-pattern "assess DT/QA value per issue"):** The bundle splits cleanly into two surface classes. **Pure-doctrine/spec issues** (#1697, #1674, #1673, #65, #66, #1008, #1679, #1092) have no executable logic — their DT is structural (grep/read/diff/template-conformance), so S7 compresses to a single structural-verification pass; full per-AC fixture execution would be theater. **Executable issues** (#1676 grammar comparison, #1675 CAS mechanism, #769 halt logic, #1677 deploy-check + CI gate, #1678 tag-reaping) have real behavioral surface and get **full** DT + QA — these are where a defect would actually ship. This is the honest assessment the persona demands, not a blanket "all apply" or a blanket "docs skip QA".

---

### Contention Map (File Change Matrix)

Machine-readable: **one path per line** in the fenced block below (downstream Stage 7/8/9 chips extract this list deterministically per the baseline-pin awareness convention). Paths are repo-relative. `[NEW]` = file created by the release; `<NNN>` in the ADR path is assigned at creation per the immutable-ADR system. Issue→file attributions follow the block.

```
release/ADRs/ADR-<NNN>-version-claim-determinism.md
release/ADRs/ADR-024-cross-release-impact-model.md
core/standards/repo-host-adapter-versioning.md
release/governance/RELEASE_PROTOCOL.md
release/governance/release-process.md
release/references/how-to/hub-spoke-bridge.md
release/references/pipeline/stage-03-bundle.md
release/references/pipeline/stage-04-planning.md
release/references/pipeline/stage-09-plan-review.md
release/references/pipeline/stage-12-execute.md
release/references/pipeline/stage-13-close.md
release/references/specs/parallel-release-semantics.md
release/references/specs/version-allocation-rule.md
release/references/specs/version-grammar.md
release/references/specs/cross-release-impact-model.md
core/standards/version-field-semantics.md
core/deploy/deploy.sh
core/schemas/gate-criteria-spec.md
release/tools/cleanup-orphan-state.sh
release/tools/automated-closeout.sh
release/releases/RELEASE_LOG.md
release/releases/RELEASE_INDEX.md
release/releases/RELEASE_DIGEST.md
CHANGELOG.md
.github/workflows/version-freeness.yml
```

> **Contention-map addendum (scope-lock):** `core/standards/repo-host-adapter-versioning.md` `[NEW]` is added by #1697 (this slice) — the NET-NEW `repo_host` version-claim interface spec that the elevated architecture introduces alongside the ADR. Sole author: #1697. No overlap.

**Path provenance note:** the four `release/references/specs/*.md` "new spec" paths and the `.github/workflows/version-freeness.yml` path are **[ASSUMPTION – CONFIRM]** — the issue bodies mark these "TBD — identified in Planning" and the exact filename is a Stage-5 decision (Q1 in #65/#66 asks new-file-vs-append). They are listed as the *expected* new-file targets so downstream chips have a path to watch; the engineer confirms the final name at Commit 0. The four existing-spec parents (`RELEASE_PROTOCOL.md`, `release-process.md`, `hub-spoke-bridge.md`, `version-field-semantics.md`, the pipeline stage files, ADR-024, the three ledgers, `CHANGELOG.md`, `deploy.sh`, the two `.sh` tools, `gate-criteria-spec.md`) are **[SOURCE]** — verified to exist at `origin/main = d3bc6dd`.

**Per-file attribution + overlap flags** (★ = multi-issue contended file — the primary sequencing hazard):

| File | Issues touching it | Intent | Overlap risk |
|---|---|---|---|
| `release/ADRs/ADR-<NNN>-version-claim-determinism.md` `[NEW]` | #1697 | add | None — sole author. |
| `core/standards/repo-host-adapter-versioning.md` `[NEW]` | #1697 | add | None — sole author (the NET-NEW `repo_host` interface spec; scope-lock elevation). |
| `release/ADRs/ADR-024-cross-release-impact-model.md` ★ | #1697 (xref by slug), #1674 (the axis extension) | edit | **LOW** — #1697 cross-references ADR-024 by slug from within the new ADR (it does NOT edit ADR-024 — ADR-024 is immutable; its back-reference is #1674's surface). #1674 does the substantive version-axis extension. Sequenced #1697(1) → #1674, adjacent. |
| `release/governance/RELEASE_PROTOCOL.md` ★ | #1673 (allocation rule), #1675 (allocation timing) | edit | **MODERATE** — two distinct sections (§Versioning rule vs. claim-timing). Sequenced #1673 → #1675; not adjacent but no other RELEASE_PROTOCOL toucher between them. Engineer #1675's edit against the #1673-updated §Versioning. |
| `release/governance/release-process.md` ★ | #65, #66 | edit | **LOW–MOD** — both add spec cross-references (#65: Stage-3 refs; #66: Stage-12 ref). Adjacent. Co-Solutioning resolves the shared edit region. |
| `release/references/how-to/hub-spoke-bridge.md` ★★ | #66 (xref), #1008 (Procedure 0 D-Version), #769 (baseline-pin awareness), #1092 (Procedure 7 xref) | edit | **HIGH** — four issues, four different sections (Procedure 0 / baseline-pin / Procedure 7). The two close-together (#66/#1008) edit different procedures; #769 and #1092 are later and sectionally disjoint. Each chip must pull the latest HEAD before editing (D-C SINGLE serializes commits, so this is safe — see Branch Topology). |
| `release/references/pipeline/stage-12-execute.md` ★ | #1675 (atomic-claim step, Phase B), #769 (Phase A.5 freeness check) | edit | **MODERATE** — same file, adjacent phases (B vs A.5). Sequenced #1675 → #769, back-to-back. Engineer #769 against #1675's just-landed claim step. |
| `release/references/pipeline/stage-09-plan-review.md` | #769 (A6.5 re-check) | edit | None — sole toucher. |
| `release/references/pipeline/stage-13-close.md` | #1092 (Phase B conflict doctrine) | edit | None — sole toucher. |
| `release/references/pipeline/stage-03-bundle.md` | #65 (Phase B3/B4 ref) | edit | None — sole toucher. |
| `release/references/pipeline/stage-04-planning.md` | #950 (cites D-Version timing) | (likely none) | None expected — #950 is the observation; its *asks* are met by #1675/#769/#1008. Listed because #950's body names this file; no edit anticipated. |
| `core/standards/version-field-semantics.md` ★ (dual-gated) | #65, #66 | edit | **MODERATE** — **both add a caveat to the SAME dual-gated file** (pre-commit hook + deploy.sh Check 6). This is the canonical co-Solutioning driver. Adjacent; one coherent design, two contiguous commits. Check 6 must PASS after each. (Scope-lock: thin one-paragraph caveat only; sequencing/numbering doctrine lands in `bundle-composition-doctrine.md`.) |
| `core/deploy/deploy.sh` | #1677 (version-freeness check) | edit | None — sole toucher (the next check after Check 39/#1643). |
| `core/schemas/gate-criteria-spec.md` | #66 (G-PR9 xref), #769 (gate spec) | edit | **LOW** — both reference the existing G-PR9; compose-don't-duplicate is explicit in both bodies. May be xref-only (no body edit). |
| `release/tools/cleanup-orphan-state.sh` | #1678 (orphaned-tag reaping) | edit | None — sole toucher. **Couples #1672** (open, unmilestoned — the closeout-tooling slug/version-assumption rework). |
| `release/tools/automated-closeout.sh` | #1678 (coordination — slug-primary rework surface), #1092 (corpus close behavior) | edit | **COORDINATION** — the slug-primary identity rework (S-2 spike in #1697) lands its closeout-tooling consequences here; #1672 owns the parallel fix. Risk-register entry below. |
| `release/releases/RELEASE_LOG.md` ★ | #1679 (re-version sub-field/schema), #1092 (state-machine resolution doctrine) | edit | **LOW** — #1679 adds a schema field; #1092 documents merge-conflict resolution *of* that ledger. Different concerns; #1679 before #1092. |
| `release/releases/RELEASE_INDEX.md` | #1092 (resolution doctrine target) | (referenced) | None — referenced by #1092's doctrine, not necessarily edited. |
| `release/releases/RELEASE_DIGEST.md` | #1092 (resolution doctrine target) | (referenced) | None — as above. |
| `CHANGELOG.md` | #1092 (uniform-footer post-resolution check) | (referenced) | None — referenced by the doctrine. |
| `release/references/specs/*.md` `[NEW ×4]` | #1673 (allocation-rule), #1676 (grammar), #66 (parallel-release-semantics), #1674 (cross-release-model) | add | None — each a distinct new file (names CONFIRM at S5). |
| `.github/workflows/version-freeness.yml` `[NEW]` | #1677 | add | None — sole author (name CONFIRM at S5). |

**Contention summary:** `hub-spoke-bridge.md` (4 issues) is the highest-contention file, then `stage-12-execute.md`, `RELEASE_PROTOCOL.md`, `release-process.md`, `version-field-semantics.md`, `RELEASE_LOG.md`, ADR-024 (2 issues each — ADR-024 is cite-by-#1697 / edit-by-#1674). All overlaps are **sectionally disjoint** (different sections/phases of the same file) — none is a true line-range collision on identical content. Under D-C SINGLE every commit serializes onto `release/<slug>`, so the mitigation is purely "each Engineering chip rebases/pulls latest release-branch HEAD before editing" (the standard Procedure-2 FILE-blocker discipline). This is exactly the contention profile D-C SINGLE handles best.

---

### Risk Register

Each entry: **Risk · Owner-stage · Mitigation · Reversibility tier · Confidence.**

| # | Risk | Owner stage | Mitigation | Reversibility / Conf |
|---|---|---|---|---|
| R1 | **Shared-file merge thrash on `hub-spoke-bridge.md` (4 touchers) / `stage-12-execute.md` / `version-field-semantics.md` (2 each).** Out-of-order or stale-HEAD edits cause conflicts. | Stage 6 Eng (hub routing) | D-C SINGLE serializes all commits onto one branch; hub routes ONE Engineering chip at a time per the Implementation Sequence; each chip pulls latest `release/<slug>` HEAD before editing. Overlaps are sectionally disjoint (verified above). | CHEAP / HIGH |
| R2 | **#1674 mutates an immutable ADR (ADR-024).** ADRs are immutable once authored; a naive "edit ADR-024" violates the immutable-ADR system. | Stage 5 Solutioning (#1674) | Resolve at S5: extend via the cross-release-model **spec** + an ADR-024 **successor/cross-reference** (the founding ADR gains a forward-pointer by slug; ADR-024's back-pointer is #1674's surface), NOT a body rewrite. The milestone architecture already frames #1674 as "ADR-024 extension," consistent with a successor. | MODERATE / HIGH |
| R3 | **Allocation-rule reconciliation surfaces that the documented semantic-bump rule was never followed** (#1673 body warns of this). The fix is a *corrective* edit, not additive — risk of breaking a downstream consumer that read the old table. | Stage 5 / Stage 7 (#1673) | S5 maps every consumer of `RELEASE_PROTOCOL.md §Versioning`; #1676 grammar + #1677 freeness check are the downstream consumers and ship in the same release, so the correction propagates atomically. DT diffs against current. | MODERATE / MEDIUM |
| R4 | **Stale-input in #65** — the card cites v11/v12/v13 track-by-theme conventions from a 2026-04-24 memory; the repo now runs a v1.x→v2.x single track, so those meanings are obsolete. Codifying them as normative would inject drift. | Stage 5 (#65) | #65 body already flags this (`[~] Stale-input flag`). S5 MUST validate track conventions against the live single-track reality before codifying; treat track conventions as *informative-only* or collapse the section. Do not restate stale meanings as normative. | CHEAP / HIGH |
| R5 | **#66 re-invents the already-shipped G-PR9 gate** instead of referencing it. | Stage 5 (#66) | #66 body flags this (`[~] Compose-with note`). S5 specifies #66's Stage-9 check as *referencing/extending* G-PR9 (records baseline SHA + sibling-merge revalidation), not a second Stage-9 gate. | CHEAP / HIGH |
| R6 | **Behavioral surface (#1675 CAS-retry, #769 halt-logic, #1677 CI gate) ships without an executable verifier.** These have real logic, but the platform's freeness/CAS executor may not be fully built (per stage-04 "declared, verification deferred"). | Stage 7/8 (#1675/#769/#1677) | Per stage-04 §Verification-Plan AC→method mapping: a behavioral AC is admitted with its `method:` **declared** even before the executor exists, and recorded/surfaced (not dropped). DT runs the declared reproduction-and-observe method (spike S-1 already empirically confirmed ref-CAS rejection — a ready fixture). | MODERATE / MEDIUM |
| R7 | **Coordination — #1672 (automated-closeout.sh slug/version assumptions, OPEN, unmilestoned).** The slug-primary identity rework (S-2 spike) changes the milestone-naming assumption `automated-closeout.sh` depends on; #1678 also edits closeout/cleanup tooling. If #1672 lands concurrently, the two collide on `automated-closeout.sh` + `cleanup-orphan-state.sh`. | Stage 4/9 (cross-milestone) + Stage 6 (#1678) | Treat #1672 as a serialization sibling on `release/tools/*.sh`: at S9 G-PR9, intersect this release's SURFACE against any open #1672 PR; one merges, the other re-baselines. Recommend **sequencing #1672 AFTER this milestone** (it adapts closeout to the slug-primary convention this milestone establishes) — or pull #1672 into Wave C if the operator wants them atomic. **Scope-lock: #1672 kept SEPARATE** (couples #1678 via a header-keyed row reader; not folded). Flag for operator at the D-gate. | MODERATE / MEDIUM |
| R8 | **Coordination — #1643 (`.version` stamping).** *Correction:* **#1643 is CLOSED** (shipped, milestone `release-version-stamping`). The pre-load called it "in-flight"; live state contradicts that. | Stage 6 (#1675) | **Risk downgraded to LOW.** `.version` stamping is shipped behavior (deploy.sh Check 39 already references it). #1675's claim mechanism *consumes* the shipped `.version`-at-claim behavior rather than coordinating with concurrent work. Verify the Check 39 interaction at S6; no concurrent-merge race. | CHEAP / HIGH |
| R9 | **Scope risk — ≈56 pts across 14 issues, well above the 15–25 pt target.** Over-scoped releases risk long pipelines (the very failure mode this release fixes — long pipeline loses its version) and quota strain. | Stage 4 (this gate) | Operator-judgment coherence override is **recorded** in the milestone description (bundle-composition-doctrine §4 tight-merge: graph-verified #1697→#1675→#1678 chain; §8 Shape-1 54-pt precedent). The dep chain genuinely requires co-shipping the foundation. Mitigation: D-C SINGLE + strict serialization keeps the blast radius one-commit-at-a-time; Quota Budget PASS (below) confirms capacity. **Meta-risk:** this long-pipeline release is itself exposed to the bug it fixes until Stage 12 — re-verify next-free at Commit 0 AND at the atomic claim. | MODERATE / MEDIUM |
| R10 | **Rollback complexity — the founding ADR + mechanism is EXPENSIVE to reverse once #1675 ships** (#1697 AC states this). | Stage 12/13 | Whole-release rollback = `git revert -m 1` of the release-PR merge (additive new files + sectional edits strand no consumer mid-way, per the cross-cutting CHEAP-per-file profile). But the *architectural commitment* (slug-primary identity, defer-to-merge) is EXPENSIVE to unwind once tooling adopts it — the counter-commitment is a **superseding ADR** (named in #1697 AC). Per-file reversibility is CHEAP; architectural reversibility is EXPENSIVE. | EXPENSIVE (architecture) / CHEAP (per-file) / HIGH |
| R11 | **Two claim surfaces are not both atomic** — the tag is atomic-CAS, but the corpus ledgers (RELEASE_LOG/INDEX/DIGEST/CHANGELOG) are conflict-resolved (#1092), not CAS. A residual divergence between the authoritative tag and the ledgers is possible. | Stage 6 (#1675/#1092) | #1697 ADR already records this consequence ("the tag is authoritative; ledgers are conflict-resolved, not CAS"). #1092's per-row state-machine reconciliation doctrine is the mitigation for the ledger side; #1679's machine-readable ledger makes residual divergence *auditable*. The tag remains the single source of truth. | MODERATE / HIGH |
| R12 | **Audit-baseline staleness — the version landscape this plan rests on is a transiently-mutating population.** v2.16 is "next-free" only at read time (`d3bc6dd`); PR #1700 (v2.15) or another concurrent release could claim v2.16 before this release reaches Stage 12. | Stage 6 Commit 0 + Stage 12 | **Pinned baseline:** `origin/main = d3bc6dd`, `git fetch --tags` at this read; tags ≤ v2.14, v2.15 held by PR #1700. Per the ratified architecture this release binds **no concrete version** — it declares bump-class + provisional display only, and claims atomically at the Stage-12 merge tag by recomputing next-free then. The plan is *designed* to be immune to R12; the recommendation v2.16 is display-only. | CHEAP / HIGH |

---

### Recommendations

#### Release Class — **cross-cutting** (CONFIRM the milestone's provisional class)

Proposed class: **cross-cutting**. Trigger-condition evidence (per `release-class-taxonomy.md` §Class Enum — *any one* fires; **all three cross-cutting triggers fire here**):
- **(a) File Change Matrix touches ≥3 `pipeline/stage-*.md` files** — YES: `stage-03-bundle.md`, `stage-04-planning.md` (ref), `stage-09-plan-review.md`, `stage-12-execute.md`, `stage-13-close.md` (5 stage files). [SOURCE: Contention Map]
- **(b) Touches ≥3 of {CLAUDE.md, OPERATIONS.md, RELEASE_PROTOCOL.md, RELEASE_LOG.md, hub-spoke-bridge.md, gate-criteria-spec.md, release-process.md}** — YES: `RELEASE_PROTOCOL.md`, `RELEASE_LOG.md`, `hub-spoke-bridge.md`, `gate-criteria-spec.md`, `release-process.md` (5 of 7). [SOURCE: Contention Map]
- **(c) ≥3 in-bundle compositional edges per the DAG** — YES: the dependency graph has well more than 3 edges (#1697 blocks 4; #1673 blocks 3; #1676 blocks 3; #1675 blocks 3). [SOURCE: Dependency Graph]

Multi-trigger resolution also engages the **novel** triggers (≥1 new reference doc/ADR; ≥1 D-class decision) — but `cross-cutting > novel` per the highest-ceremony-wins order, so **cross-cutting** is dominant. Per the anti-pattern guard, this is NOT mis-classification: aggregate scope (14 issues, 5 stage files, 5 governance files) is the relevant signal.

**Differentiation posture (per the taxonomy mapping):**
- Engagement density: **Tight** — per-spoke completion surfaces a consolidated Decision Briefing; explicit cross-D upstream-compatibility scan at every D-decision.
- Stage 9 Plan Review depth: **Deep** — Collective Review N-way consistency + cross-D scan + blast-radius assessment + design-spec conformance + empirical verification of the executable slices.
- Stage 5 Activation bias: **ALL** — bias toward activating Solutioning even on borderline slices (the cross-issue compositional surface — slug-primary identity, immutable-ADR extension, dual-gated file co-edit — surfaces design questions the per-issue triggers miss). Concretely: activate S5 for all except the trivially-mechanical (#1008/#1092 compress, but still run).
- Stage 13 Outcome-window: **30-day** — standard; this is not a hotfix.

`domain:` class (per stage-04 §A1.5 A3-time classification): **governance** — the entire File Change Matrix is internal pmo-platform governance/pipeline/tooling artifacts (no application source, no web surface). `domain_practice: { source: N/A — pipeline-internal release, date: 2026-06-20, domain: governance }`. Sourcing-exempt (internal deliverable), but domain-classified per the rule that sourcing-exemption ≠ domain-less.

#### Branch Topology (D-C) — **D-C SINGLE** (default; RECOMMENDED)

Recommend **single-branch topology**: all 14 slices land sequentially on `release/release-version-claim-determinism`; the plan file is Engineering Commit 0; one release PR merges to main; one atomic tag claim at Stage 12.

Trade-offs:

| | D-C SINGLE (recommended) | D-C OPTION-A (per-issue branches + PRs) |
|---|---|---|
| Shared-file contention | **Handled by construction** — commits serialize on one branch; the 4-toucher `hub-spoke-bridge.md` and the dual-gated `version-field-semantics.md` are edited one chip at a time in sequence. | Contention shifts to **PR-merge order** at Stage 12 — 14 PRs with heavy line-range overlap on the same governance files means a base-shift cascade (every dependent PR re-bases after its parent merges). High overhead for a wave-dependent chain. |
| Dependency ordering | The Implementation Sequence IS the commit order — trivially enforced. | Each wave-edge becomes a dependent-PR base-shift; #1697→#1674→#1673→#1676→#1675 is a 5-deep PR dependency chain to manage. |
| Atomic version claim | **One** tag claim at the single merge — exactly the defer-to-merge + ref-CAS model this release builds (dogfoods the architecture). | 14 merges, but still **one** release tag (Option-A merges per-issue to main pre-tag) — fragments the "one well-defined claim point" the release is establishing. Philosophically inconsistent with the deliverable. |
| Review surface | One release PR diff (large, but cohesive — the operator reviews the whole capability at once at the Deep Stage 9). | 14 smaller PRs — more granular review, but the operator reviews the capability piecemeal and must hold cross-PR coherence in their head. |
| Early-merge value | None needed — no slice has independent user value to ship early. | Option-A's value is early-merging independently-valuable slices; **none of these 14 qualify** (all are foundation for one capability). |

**Decision rationale:** Option-A's payoff is real only when slices have independent value OR file-disjoint parallelism. Here the slices are a tight dependency chain editing the same governance files — Option-A's per-issue PRs convert the (cheap, serialized) commit-order discipline into an (expensive) 5-deep base-shift PR cascade for zero parallelism gain, and fragment the single-claim-point the release exists to establish. **D-C SINGLE is the correct topology.** (Operator decision — this is the recommendation.)

#### Version / bump-class (D-Version, re-scoped to bump-class) — **minor bump, provisional-display v2.16** (do NOT bind concrete vX.Y)

Per the ratified architecture (#1697 clause 2: "intent-to-bump, not a number"), this release declares a **bump-class + provisional-display version** and binds **no concrete `vX.Y`**. The concrete version is claimed atomically at the Stage-12 merge tag by recomputing next-free at that instant.

- **Bump-class: minor** — the release adds new capability (deterministic version-claiming) without breaking existing release-pipeline consumers. It is additive (new ADR, new spec docs, new checks) + sectional edits; no major restructure of a public surface. Not patch (it is not a corrective sub-release of a deployed version; it is net-new capability). [INFERRED from change profile + `RELEASE_PROTOCOL.md §Versioning` semantic intent.]
- **Provisional-display version: v2.16** — next-free at read time. [SOURCE, audit-baselined: `origin/main = d3bc6dd`; `git fetch --tags` → tags v2.00…v2.14 exist (incl. v2.06.1); PR #1700 holds v2.15 claimed-but-untagged; v2.15 is therefore TAKEN-in-flight; **v2.16 is the next free minor slot**.]
- **git describe is NOT authoritative here:** `git describe` from the worktree HEAD reports a reachability-stale tag (the worktree branch point predates the latest tags). Do NOT use it for next-free; use the fetched tag set + open-PR scan (which #1008 is the very issue codifying). The allocation rule this release authors (#1673) is what makes "v2.16" deterministic; until it ships, this recommendation uses the fetched-refs method.
- **Re-verify gates:** next-free MUST be recomputed at **Stage-6 Commit 0** (per #1008's own ask) and again at the **Stage-12 atomic claim** (per #1675/#769). If PR #1700 (v2.15) merges and another release claims v2.16 in the interim, the CAS-retry recomputes to v2.17+ — that is the architecture working as designed, not a re-version incident.

#### Merge / Split — **NO split; ship as one milestone** (CONFIRM the recorded coherence override)

No split recommended. The graph genuinely demands co-shipping:
- The founding ADR (#1697) blocks 4 foundation tickets; splitting it out leaves the foundation un-shippable.
- The prevention mechanism (#1675) requires both the ADR and the model extension (#1674), and blocks recovery (#1678) + ledger (#1679) — the #1697→#1675→#1678 spine is graph-verified and tight.
- The detection layer (#769/#1008/#1677) is meaningless without the grammar (#1676) + model (#1674) it compares against.
- #65/#66 are a bidirectional co-edit pair on the dual-gated file — splitting them forces a double-touch on `version-field-semantics.md`.

The only near-independent slice is **#1092** (Stage-13 corpus doctrine, "no hard blocker"). It *could* ship separately, but: (1) it is the close-stage half of the same "two claim surfaces" consequence #1697 records (R11), (2) it is doc-only/CHEAP, and (3) extracting it buys nothing — it would still need this milestone's slug-primary context. **Keep it in.** The recorded operator-judgment coherence override (bundle-composition-doctrine §4 + §8 54-pt precedent) is sound; the ≈56-pt scope is justified by the dependency density, and D-C SINGLE + Quota PASS contain the execution risk.

**Out-of-scope discoveries (noted, not acted on per scope guardrails):**
- **#1672** (automated-closeout.sh slug/version assumptions) is OPEN and unmilestoned. It is the natural *downstream* of this release's slug-primary identity decision (it adapts closeout tooling to the convention this release establishes). Recommend the operator either (a) sequence #1672 immediately after this milestone, or (b) pull it into Wave C for atomicity. Flagged in R7 — operator's call. **Scope-lock decision: kept SEPARATE.**
- The four "new spec" filenames and the CI workflow filename are Stage-5 decisions (#65/#66 Q1). Confirm at Solutioning before Commit 0.

---

### Quota Budget

**Verdict:** **PASS** (per `quota-budget-protocol.md` Checkpoint A — cumulative draw < 50% of envelope).

**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix — parallel-safe stages are 5 / 7 / 8 per the Procedure 2 Parallelism Rules table; Stage 6 Engineering and Stage 13 Close are write-serialized and excluded):**
- **Stage 5 (Solutioning):** up to **11** parallel-eligible (the 11 APPLY/compress-but-run slices: #1697, #1674, #1673, #1676, #65, #66, #1675, #769, #1677, #1678, #1679; #1008/#1092 compress; #950 skips). *Realistic worst batch ≈ 11.*
- **Stage 7 (Dev Testing):** up to **13** parallel-eligible (all but #950). But the **executable** subset that gets *full* DT — #1676, #1675, #769, #1677, #1678 (**5**) — is the cost-dominant batch; the other 8 are compressed structural passes (low cost). *Cost-weighted worst batch ≈ 5 full + 8 light.*
- **Stage 8 (QA):** up to **13** parallel-eligible (all but #950); same cost split as S7.

**Per-spoke cost estimate (size-bucket ordinal band, no telemetry yet — `[CALIBRATE-AFTER-3]` MEDIUM):** bundle is 2×L (#1674, #1675) + 8×M + 3×S + 1 observation. Worst parallel batch by ordinal cost = the Stage-5 batch where the 2 L-slices (#1674, #1675) + the M-slices fire together. Using the §5 ordinal bands (S=lowest, M=low–moderate, L=moderate–high), the worst batch's cumulative band is **moderate** — dominated by 2 L + several M, no XL slices.

**Assumed/stated remaining usage-window envelope:** operator did not state quota at hub start → **conservative default** (assume a partial window, not fresh). [ASSUMPTION – CONFIRM at hub start.]

**Estimated cumulative draw % (worst parallel batch):** the worst batch (Stage 5, ≈11 spokes, 2 L + ~6 M + ~3 S ordinal) against a conservative-partial envelope estimates **< 50%** — no XL slice, and the cost-dominant DT/QA batches are only 5 full-cost spokes (the rest compress). **< 50% → PASS.**

**Routing:** **PASS → proceed parallel; no warning required in the plan.** The mitigating structural fact: although 11–13 slices are *nominally* parallel-eligible at S5/S7/S8, only **5** carry full executable-test cost (#1676/#1675/#769/#1677/#1678); the other 8 are compressed structural-verification passes (grep/read/diff) at low per-spoke cost. The realized worst-batch draw is well under the FAIL threshold.

**Note:** Checkpoint B re-validates at every parallel wave at runtime (load-bearing) with PROCEED / SERIALIZE / DEFER / REDUCE-scope; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Bands + cumulative-draw budget are `[CALIBRATE-AFTER-3]` MEDIUM. **Operator action:** state remaining quota at hub start so Checkpoint B refines this conservative-default estimate; if the window is near-tail, the S5 batch of 11 is the one to SERIALIZE or split.

---

*Stage 4 Release Planning complete. Planning-only output — no tracked file modified, no branch/commit created. Operator decisions pending at the D-gate: D-ReleaseClass (recommend cross-cutting), D-C branch topology (recommend SINGLE), D-Version bump-class (recommend minor / provisional v2.16), coherence-override confirmation (recommend keep-as-one). Two live-state corrections surfaced: #1643 is CLOSED (Wave-B coupling downgraded); #1672 remains open (Wave-C coupling stands).*

---

## Scope-Lock Addendum (Collective Review — 2026-06-21)

> Transcribes the locked decisions + the **elevated host-agnostic architecture** from the Collective Review scope-lock. Stage 5 complete for all 13 issues (Solutioning + adversarial). Architecture elevated by the operator (architect-of-record) and locked. Engineering (Stage 6) authorized under the operator's standing "run the full release" + this scope-lock. The architecture below SUPERSEDES the GitHub-concrete framing in any earlier Stage-5 spec.

### Architecture (elevated)

Version-claim is a **host-agnostic capability** with a **config-selected `repo_host` adapter**. The capability is defined by five host-agnostic invariants; the GitHub/git mechanism becomes one *adapter*, not the architecture.

**The five invariants (the contract — no `gh`/`git` in the contract text):**
1. **Slug-primary identity** — the capability slug is the durable through-line; the version leaves pipeline identity and binds only at claim.
2. **Intent-to-bump** — the plan declares a bump-class (major/minor/patch) + a provisional-display version; it binds no concrete version.
3. **Defer-to-claim** — the concrete version binds only at the claim moment (the merge), not at planning.
4. **Atomic compare-and-swap claim** — a collision recomputes-and-retries; the claim never overwrites.
5. **Defense-in-depth** — detect early (planning-time + pre-merge freeness checks), recover residual (recovery doctrine + machine-readable ledger).

**The `repo_host` adapter interface (NET-NEW coupled deliverable — #1697 authors it alongside the ADR).** A new spec, `core/standards/repo-host-adapter-versioning.md`, defines the four operations a release-host adapter provides, with abstract semantics (not a git mechanism):
- `anchor()` → the highest claimed version in the **mainline lineage** (orphan lineages excluded).
- `claimed_set()` → all versions currently claimed or in-flight.
- `atomic_claim(version, release_ref)` → CAS-claim; returns OK or COLLISION.
- `lineage(version)` → is this version mainline vs orphan.

**Selection = user config (the existing seam — no new one invented).** The active adapter is `operator.toml [adapters].repo_host` (default `github`; "additional hosts gated on their adapter tickets" — the existing template comment is the extraction-ready pattern). Cascade-resolved per the Platform-Config Resolution Protocol (global → portfolio → program → project → individual). Cites the config-home ADRs: ADR-017 (`operator.toml` as adapters home, §S2) + ADR-022 (platform-config vs operator.toml split) + the `adapter-config-foundation` release.

**The GitHub/git v1 reference adapter (the only adapter shipped):**
- `anchor()` → `gh api repos/{REPO}/releases/latest` (returns v2.15 today; self-excludes the v3.x orphan lineage).
- `claimed_set()` → git tags ∪ published Releases ∪ RELEASE_LOG DEPLOYED/VERIFIED rows.
- `atomic_claim()` → push signed tag → git ref-CAS rejection on collision (the S-1 spike is now *adapter validation*, not the architecture).
- `lineage()` → mainline-reachability / published-sequence membership.

**Consequence for the "anchor decision":** it is **out of the architecture** — `releases/latest` is the GitHub adapter's internal `anchor()` impl, not an architectural choice. No max-semver/grep elaboration needed in the contract.

### Cross-slice contracts (LOCKED)

1. **Anchor** — dissolved into the adapter `anchor()` op (semantics: highest claimed version in mainline lineage, orphans excluded; GitHub impl = `releases/latest`). No max-semver/grep in the contract. (See #1715.)
2. **#1678 ↔ #1679 ledger schema** — reconcile to #1679's published schema: **row-per-abandoned-version** + add `abandoned_tag_pushed`, `merge_sha`, `residual_labels`, list-typed `abandoned_versions`, + a `disposition`↔fields mapping. #1679 owns the schema; #1678 consumes it.
3. **#65 ↔ #66 home** — thin caveat (one paragraph) in `core/standards/version-field-semantics.md`; release-sequencing + numbering doctrine in `bundle-composition-doctrine.md`. (#65's scope argument prevails.)
4. **Parser SSOT** — all version logic sources #1676's `version-grammar.sh` (integer-tuple, leading-zero tolerant). **#1676 lands first.** No re-encoded parsers.
5. **ADR identity** — slug-anchored cross-refs; the ADR number is assigned next-free at creation (re-verified vs `origin/main` + `check-adr-numbers.py`). Cross-references use the slug `version-claim-determinism`, never a hardcoded ADR number.
6. **Adapter discipline** — executable slices call the named adapter operations; **no inlined `gh`/`git`** in host-agnostic contract code.
7. **Stale-baseline fix** — Engineering runs `git fetch origin main` and baselines against `origin/main` (the worktree HEAD is ~26 commits behind); never local `git describe` / `git tag` for version / ADR-number state.

### Per-issue blocking findings — FOLD into Engineering

- **#1675** — discriminate push-failure (only ref-rejection retries; net/signing → hard-HALT).
- **#1677** — `test_version_freeness.sh` (deploy.sh has no `--self-test`) + CI verdict→exit + allowlist glob.
- **#1678** — consumer field-names → #1679 schema + gate local tag-delete on origin success + scope-gate the reap.
- **#1679** — query greps (dotted-slug numerator + version-less denominator) + round-trip `abandoned_versions`.
- **#1008** — drop the false "Check 39 = converged anchor" + the Commit-0 re-verify is Procedure 0.
- **#769** — defer the anchor to the adapter op.
- **#1092** — preserve insertion order (not version-descending) + DIGEST shape + two-region RELEASE_LOG.

### Ratified AC departures

- **#65/#66 governed home** (caveat in `version-field-semantics.md`; doctrine in `bundle-composition-doctrine.md`), **#1092 Procedure-3 cross-ref**, **#1676 suffix-as-rejected** — ACCEPTED (the ACs predate the ratified architecture).
- **#1672 kept SEPARATE** (couples #1678 via a header-keyed row reader; not folded).

### Implementation Sequence (Stage 6, serialized, D-C SINGLE; branch `release/release-version-claim-determinism`)

`#1697 (founding ADR + repo_host interface spec; Commit 0 = this plan file)` → `#1676 (grammar SSOT)` → `#1673 (allocation, host-agnostic)` → `#1674` → `#1008` → `#65 → #66` → `#1675` → `#769` → `#1677` → `#1679 → #1678` → `#1092`.

> Closure phrasing reminder (parser-clean discipline): in this plan and every downstream artifact, issues are referenced with safe phrasing — `mark #N as closed at Stage 13`, `#N → Closed`, `transition #N to closed` — never a close-family verb + `#N` outside a dedicated reference block. The 14 milestone issues are marked closed at Stage 13 close-out, not auto-closed by the release PR (this is a multi-slice release).

---

## Provenance

- Milestone #222 (`release-version-claim-determinism`) — Stage-3 Bundle artifact (wave structure, elevated architecture, coherence override).
- The 14 in-scope issues: #1697, #1673, #1676, #1674, #65, #66, #1675, #769, #1008, #1677, #1678, #1679, #1092, #950.
- Stage 4 Release Planning sub-task #1702 (the plan reproduced above) + the Collective Review scope-lock (the addendum above).
- Stage 5 Solutioning + adversarial design review sub-task #1707 (+ the host-agnostic architecture elevation).
- `release/ADRs/ADR-024-cross-release-impact-model.md` (the model #1674 extends — currently path/structural axes only, no version axis).
- Live-state verification at Commit 0: `origin/main = 007e637`; ADR next-free re-surveyed across `core/ADRs/` + `release/ADRs/` (max ADR-035 → next-free ADR-036) with `release/tools/check-adr-numbers.py` as the gap-free/unique backstop.
