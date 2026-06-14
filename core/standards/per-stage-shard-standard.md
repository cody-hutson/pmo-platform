<!-- reference-durability: allow-version-ref -->
<!-- reference-durability: allow-link -->
# Per-Stage Shard Standard — Pipeline Stage Definition Files

**Origin:** sub-task re-scoped under Tier 0 Override (Option B) on 2026-05-23 — original premise referenced the now-deleted `pipeline-stages.md` (per [ADR-002](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md)); re-scoped to per-stage shard authoring discipline.
**Tier:** K1 codified-knowledge corpus per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md).
**Primary consumers:** Stage 5 Solutioning spokes (when authoring or materially modifying a per-stage shard); Stage 6 Engineering spokes (when implementing shard edits); [`release-planner`](../../release/skills/release-planner/SKILL.md) Mode B (when planning shard-touching releases); [`build-reviewer`](../../release/skills/build-reviewer/SKILL.md) (when auditing pipeline-corpus structural integrity); future Stage 14+ authors.
**Secondary consumers:** [`prompt-builder`](../skills/prompt-builder/SKILL.md) (when generating shard-edit prompts); [`pipeline/README.md`](../../release/references/pipeline/README.md) Stage Index (per § 8.1 below). [`pmo-skill-editor`](../../release/skills/pmo-skill-editor/SKILL.md) is **NOT** a consumer — pipeline shards are not skills (see § 4.5).
**Status:** Canonical
**Introduced:** solutioning-routing-and-handoff release
**Cross-references:** see § 8 Related References and § 9 Cutover + Version History at the foot of this file.

## § 1. Purpose + Scope

A **per-stage shard** is a single self-contained `release/references/pipeline/stage-NN-<name>.md` file that defines one of the 13 stages of the pmo-platform improvement-to-deployment pipeline. The shard set replaced the monolithic `release/references/pipeline-stages.md` per [ADR-002](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md).

This standard codifies, prospectively:

- The canonical **10 numbered H2 sections** every shard follows (§ 2).
- Three documented **variants** — full / PLATFORM-SATISFIED / extended (§ 3).
- **Authoring conventions:** modify-vs-new, naming, anchors, cutover clauses, mirror-pair non-contract (§ 4).
- **Source-reference format** and citation conventions (§ 5).
- **Revision-handling:** current-only + git history; no YAML frontmatter on shards (§ 6).
- **Audit-trail capture** convention for § 11 (§ 7).

**Non-goal.** This standard does NOT replace [ADR-002](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md). ADR-002 records the architectural decision to split the monolith; this standard codifies the per-shard structure that the split produced, so that future shard authors (Stage 14+ or major shard revisions) have an inspectable specification rather than relying on empirical mimicry of the 13 existing files.

**Audience.** Stage 5 Solutioning spokes (when their output specifies a shard edit), Stage 6 Engineering spokes (when implementing shard edits), [`release-planner`](../../release/skills/release-planner/SKILL.md), [`build-reviewer`](../../release/skills/build-reviewer/SKILL.md), and future-stage authors. Shard *readers* (operators consulting a stage definition) need only the Stage Index at [`pipeline/README.md`](../../release/references/pipeline/README.md); they do not need this standard.

**Originating evidence.** The original sub-task body framed the gap as "No pipeline-stages.md compilation process" — a Stage 1 framing predating the monolith deletion. The Tier 0 re-scope (operator-rendered 2026-05-23 in the sub-task) refocused the deliverable on the post-split educational debt: there was no canonical place for an operator to learn how to author a new per-stage shard. This standard fills that gap.

## § 2. Canonical Structure (10 numbered H2 sections)

Every shard uses this structure unless it declares the PLATFORM-SATISFIED variant (§ 3.1):

```markdown
# Stage N: <Name>

> **Source:** #<NN>[, #<NN>]
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../disciplines/execution-framework.md) of governance hierarchy.

## 1. Purpose
<1-2 sentences: what this stage produces and why it exists>

## 2. Reference Model Alignment
<table: Ref Model Attribute | Part 6 Definition | Our Implementation | Compression Note (optional)>
<Key compression note (1 paragraph) if applicable>

## 3. Persona
<table: Role | Skills-Map Ref | Modes (optional) | Autonomy>

## 4. Inputs
<prose: From <upstream stage>, From <other sources>, Set at <this stage>>
<optional: For the structured boundary contract, see ../schemas/stage-io-contracts.md>

## 5. Process
**Phase A — <name> (Tier N):** <enumerated mechanics A1..AN>
**Phase B — <name> (Tier N):** <enumerated mechanics B1..BN>
<additional phases as needed; cutover blocks per § 4.4 of this standard>
**Ticket lifecycle:** Claim / Execute / Resolve per `ticket-information-architecture.md`
**Framework dimensions touched:** <subset of Work Breakdown / Assignment / Tracking / Handoff / State Persistence> per `execution-framework.md`

## 6. Outputs
<prose: artifacts produced>
<optional "negative space": "Stage N does NOT produce: ..." when clarifying boundary>

## 7. Stage-Transition Gate
Transition orchestration: per [handoff-coordinator-spec.md](../schemas/handoff-coordinator-spec.md) (invokes [gate-evaluation-spec.md](../schemas/gate-evaluation-spec.md)). Criteria below.
Metrics (canonical IDs per [gate-criteria-spec.md Gate N](../schemas/gate-criteria-spec.md#gate-N-...)): <enumerated>
Judgment (1-5): <qualitative dimensions>
Calibration / Gate output: <signal shape>

## 8. Automation Level
Overall Tier <0-3>. <1-2 sentence detail per role>

## 9. Gap Summary
<count> gaps (#NN..#NN). Key: <list>

## 10. Retro
<lessons learned; "To be populated after execution" before first run>

## 11. Audit-Trail Capture
<see § 7 of this standard; OMIT when stage emits no events>
```

Section numbering is sequential (`## 1.` ... `## 10.`) and the section titles are **exact** — `Purpose`, `Reference Model Alignment`, `Persona`, `Inputs`, `Process`, `Outputs`, `Stage-Transition Gate`, `Automation Level`, `Gap Summary`, `Retro`. Anchor stability depends on title stability (see § 4.3).

## § 3. Variants

### § 3.1 PLATFORM-SATISFIED variant (stages 10, 11)

When a stage's function is satisfied automatically by a git-native mechanism (PR diff = dry run; git history = snapshot), the shard MUST declare the compressed variant:

```markdown
# Stage N: <Name>

> **Source:** #<NN>
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../disciplines/execution-framework.md) of governance hierarchy.

## Classification: PLATFORM-SATISFIED
<1 paragraph: what platform mechanism satisfies this stage; cross-reference [`.claude/rules/release-process.md` § Stage Compression](../../release/governance/release-process.md)>

## 1. Purpose
<as in § 2>

## 2. Reference Model Alignment
<as in § 2 — include a "Compression Note" column or paragraph>

## 3. Persona
<as in § 2>

## 8. Automation Level
<as in § 2>

## 9. Gap Summary
<as in § 2>

## 10. Retro
<as in § 2>
```

**Omitted on purpose:** §§ 4 Inputs, 5 Process, 6 Outputs, 7 Stage-Transition Gate, and § 11 Audit-Trail Capture. The platform mechanism IS the inputs/process/outputs; no audit-trail events emit because the stage runs without an executing agent.

**Empirical instances:** [stage-10-dry-run.md](../../release/references/pipeline/stage-10-dry-run.md), [stage-11-snapshot.md](../../release/references/pipeline/stage-11-snapshot.md). The compression-exception path (when PLATFORM-SATISFIED does NOT apply — non-git deployment targets, destructive operations, etc.) is documented in [`.claude/rules/release-process.md` § Stage Compression](../../release/governance/release-process.md); when the exception fires for a given release, the stage activates per § 2 of THIS standard (full 10-H2 form for that release's execution), but the shard's standing classification remains PLATFORM-SATISFIED.

### § 3.2 Extended-protocol H2 (stages 5, 7)

When a stage owns a cross-stage nested protocol that does not fit cleanly inside § 5 Process (because the protocol applies across stage boundaries and is independently citable), the shard MAY append an additional **un-numbered** H2 AFTER § 11:

```markdown
## <Protocol Name> (Source: #<NN>[, #<NN>])
<protocol body>
```

**Empirical instances:**

| Shard | Extended-protocol H2 |
|---|---|
| [stage-05-solutioning.md](../../release/references/pipeline/stage-05-solutioning.md) | `## Release-Level Checkpoint: Collective Review` |
| [stage-07-dev-testing.md](../../release/references/pipeline/stage-07-dev-testing.md) | `## DT↔Engineering Iteration Loop Protocol` |
| [stage-07-dev-testing.md](../../release/references/pipeline/stage-07-dev-testing.md) | `## DT↔QA Handoff Protocol` |

Extended-protocol H2s are not numbered because they are not part of the 10-point stage-definition framework. Cross-references from other docs use the protocol's anchor (auto-slug of the title; see § 4.3) directly.

### § 3.3 Stage-specific decimal sub-sections (§ 5.N)

Within § 5 Process, a stage MAY add **decimal-numbered** subsections for stage-local protocol extensions that are independently citable from outside the shard. Prefer folding the extension into the existing § 5 Phase X body; introduce a decimal sub-section only when the extension's protocol is cited by another shard or another K1 doc.

**Empirical instances:**

| Shard | Decimal sub-section |
|---|---|
| [stage-05-solutioning.md](../../release/references/pipeline/stage-05-solutioning.md) | `## 5.5 Forecast Discipline (Deploy-Resolution Claims)` |
| [stage-05-solutioning.md](../../release/references/pipeline/stage-05-solutioning.md) | `## 5.6 Cascade-Completeness Sweep (Phase A4.1)` |

Decimal sub-section indices start at a value that does not collide with the Phase letters used in the shard's § 5 Process (e.g., `5.5` is chosen because Phases A-D already exist; `5.1`-`5.4` would suggest reorder of existing Phases).

### § 3.4 Extensions beyond § 11 (§ 12+)

A stage MAY add additional numbered H2s beyond § 11 when it owns stage-specific enforcement infrastructure (hook-layer detection patterns, schema enforcement, CI surface declarations) that is conceptually parallel to the 10-point framework but not part of it. Use the **next available integer**.

**Empirical instance (single case):**

| Shard | Extension |
|---|---|
| [stage-02-triage.md](../../release/references/pipeline/stage-02-triage.md) | `## 12. Enforcement Surface` |

Future extensions beyond § 12 follow the same rule. If a stage requires more than one extension H2, number them sequentially (`## 12.`, `## 13.`, ...). Do not collapse multiple unrelated extensions into a single § 12 — that defeats independent citability.

## § 4. Authoring Conventions

### § 4.1 MODIFY existing shard vs author NEW shard

| Change class | Modify existing | Author NEW |
|---|---|---|
| Update an existing stage's mechanics (new Phase, new gate criterion, new audit-trail event) | YES | NO |
| Add a new cross-stage protocol owned by an existing stage | YES — append as extended-protocol H2 after § 11 (§ 3.2) | NO |
| Add a stage-specific decimal sub-section to § 5 Process | YES — within the owning shard (§ 3.3) | NO |
| Add a new enforcement infrastructure section to a stage | YES — append as § 12+ to the owning shard (§ 3.4) | NO |
| Add a 14th stage to the pipeline | NO | YES — `stage-14-<name>.md` + Stage Index row in [`pipeline/README.md`](../../release/references/pipeline/README.md) + cross-cuts in the canonical source [`release/governance/release-process.md`](../../release/governance/release-process.md), redeployed to the workspace mirror `~/.claude/rules/release-process.md` (Check 9) |
| Document a brand-new artifact class that is NOT a pipeline stage | NO | YES — but the artifact does NOT belong at `pipeline/stage-NN-*.md`; route per K1 standards / specs placement per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) |

Author NEW shards in their entirety per § 2 (or § 3.1 when PLATFORM-SATISFIED applies). Pre-populate every § 1-§ 10 heading even when content is sparse; future revisions will fill them in.

### § 4.2 No mirror-pair contract

There is NO mirror-pair contract for `pipeline/stage-NN-*.md` shards. Shards are **single-source** K1 reference docs. The mirror-pair pattern (per [`.claude/rules/skill-deployment.md`](../rules/skill-deployment.md) and [`.claude/rules/harness-deployment.md`](<OPERATOR_INSTANCE_CLAUDE_DIR>/rules/harness-deployment.md)) applies to canonical source `core/rules/<name>.md` ↔ deployed mirror `~/.claude/rules/<name>.md` pairs and is validated by `./deploy.sh --check` Check 9. Shard authors do NOT mirror, and no Check asserts byte-identity across two copies of a shard.

### § 4.3 Naming + anchor conventions

**File naming** per [ADR-002](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md):

- `stage-NN-<name>.md` where `NN` is **zero-padded** (`01`-`13`; future Stage 14 → `stage-14-<name>.md`).
- `<name>` is **lowercase, kebab-case**, matching the stage's canonical name (e.g., Intake → `intake`, Plan Review → `plan-review`).
- ASCII-safe, filesystem-sort-aligned with index order per the `tree-audit-2026-04-18` NARA finding (cited in ADR-002).

**Anchor conventions** rely on GitHub's auto-slug for headings:

| Heading | Auto-slug anchor |
|---|---|
| `## 1. Purpose` | `#1-purpose` |
| `## 2. Reference Model Alignment` | `#2-reference-model-alignment` |
| `## 5. Process` | `#5-process` |
| `## 5.6 Cascade-Completeness Sweep (Phase A4.1)` | `#56-cascade-completeness-sweep-phase-a41` |
| `## 11. Audit-Trail Capture` | `#11-audit-trail-capture` |
| `## 12. Enforcement Surface` | `#12-enforcement-surface` |
| `## DT↔Engineering Iteration Loop Protocol` | `#dtengineering-iteration-loop-protocol` |

Cross-references from other docs use either an anchored form or a bare-path form (whole-file reference):

```markdown
[stage-NN-<name>.md § N. <Section>](../pipeline/stage-NN-<name>.md#N-section-name)
[stage-NN-<name>.md](../pipeline/stage-NN-<name>.md)
```

Anchor stability is contingent on heading-title stability — do not rename a section title without a deliberate cascade pass updating all inbound references.

### § 4.4 Cutover-clause discipline

When a protocol shipping in version `vX.Y` lands inside a stage shard (typically as a new Phase, a new gate criterion, or a new audit-trail event), the author SHOULD include a **Cutover paragraph** per the workspace's reflexive-pipeline-loop discipline:

```markdown
**Cutover:** <protocol name> applies to releases entering Stage N strictly AFTER the v<X.Y> merge SHA
recorded in [`release/releases/RELEASE_LOG.md`](../../release/releases/RELEASE_LOG.md).
**The v<X.Y> release itself is exempt** (the rule shipping in v<X.Y> cannot fire on its own
Stage N without creating a reflexive-pipeline loop).
```

The pattern is empirically present in stages 02, 03, 04, 05, 07, 12, 13 across multiple cutover bands. Place the cutover paragraph at the end of the Phase / sub-section it constrains. When the cutover protocol introduces an exempt-release class beyond the introducing release itself (e.g., "all releases that entered Stage N prior to vX.Y are also exempt"), append that clause to the paragraph.

See the precedent at [feedback_stage12_13_release_log_chore_pr.md (workspace memory)] and the systemic discussion in [`.claude/rules/release-process.md`](../../release/governance/release-process.md) (search for "reflexive-pipeline-loop").

### § 4.5 Shards are not skills

Pipeline shards are K1 reference docs, not skills. Confusions to avoid:

- The [`canonical-skill-structure.md`](canonical-skill-structure.md) standard does NOT apply to shards.
- The skill `version:` field discipline at [`version-field-semantics.md`](version-field-semantics.md) does NOT apply to shards. Shards carry no version field (see § 6).
- The skill-edit hook (`block-skill-direct-edit.sh`) does NOT match `pipeline/` paths. Shards may be edited via Write/Edit directly without `pmo-skill-editor` involvement.
- The `.skill` package mechanism does NOT apply to shards.

Shards are governed by THIS standard alone (structure), [ADR-002](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md) (the split decision), and the corpus-hygiene checks at `./deploy.sh --check` (Checks 14 / 15 for doc-link maintenance) plus the standard PR review gates.

## § 5. Source-Reference Format

### § 5.1 Header blockquote (canonical, empirically uniform across all 13 shards)

Every shard places a 2-line blockquote header **immediately below the H1 title and before § 1 Purpose**:

```markdown
# Stage N: <Name>

> **Source:** #<NN>[, #<NN>]
> **Part of:** [13-stage pipeline](README.md) — [Process layer](../disciplines/execution-framework.md) of governance hierarchy.
```

**Source:** lists the GitHub issue(s) that originated the stage definition. Multiple issues separate by `, ` (e.g., `> **Source:** , `). No "Session N" suffix (a Stage 1 proposal pre-supersession that was never adopted in any shard).

**Part of:** is a fixed, copy-paste line that links the shard to the pipeline directory README and to the Process-layer explanation in `execution-framework.md`. Do not vary this line per shard.

### § 5.2 In-body inline citations

Inside § 1-§ 11 (or extension H2s), cite a specific issue using a markdown link:

```markdown
... per [#NN](https://github.com/<owner>/<repo>/issues/NN) ...
... per [`<file>.md § X`](path#x) ...
```

The bare `(Source: #NN)` parenthetical form is reserved for **extended-protocol H2 titles only** (§ 3.2), where the title itself names the originating issue (e.g., `## DT↔Engineering Iteration Loop Protocol (Source: parent issue)`). Do not use the parenthetical inside body paragraphs.

### § 5.3 Why the empirical form supersedes the original Stage 1 proposal

The original Stage 1 body proposed `(Source: #NN, Session N)` as the source-reference format. That format is **not observed** anywhere in the 13 shards: the blockquote-header form predates ADR-002 (it was carried over from the per-stage subsections of the deleted monolithic `pipeline-stages.md`). The "Session N" suffix is not observed at all. This standard codifies the empirical form and supersedes the Stage 1 proposal. No backedit to the original sub-task body is needed; the re-scope already invalidated it.

## § 6. Revision-Handling

### § 6.1 Current-only + git history

**Single canonical version per shard** at its `pipeline/stage-NN-<name>.md` path. Historical versions live in `git log --follow <path>`. No parallel snapshot directory. No per-release version numbering in shard content. No "last-N retained" policy.

This matches the workspace's canonical K1 retention pattern:

| Standard | Retention model |
|---|---|
| [`design-artifact-standard.md` § 5](design-artifact-standard.md) | Current-only + git history |
| [`release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) | Single canonical file per release; git history for revisions to that file |
| [`evidence-grounding-standard.md`](evidence-grounding-standard.md) | Single canonical doc; revisions tracked in git |

### § 6.2 Historical-view procedure

```bash
# All commits that touched the shard:
git log --follow release/references/pipeline/stage-NN-<name>.md

# Specific historical version:
git show <sha>:release/references/pipeline/stage-NN-<name>.md

# Diff between two points in time:
git diff <sha-old>..<sha-new> -- release/references/pipeline/stage-NN-<name>.md
```

### § 6.3 No frontmatter version field on shards

Shards do NOT carry YAML frontmatter and do NOT carry a `version:` field. The [`version-field-semantics.md`](version-field-semantics.md) standard scopes the version-field discipline to skill `SKILL.md` files only. Empirical verification: `grep -l "^version:" release/references/pipeline/*.md` returns nothing.

The shard's *content* is the shard's contract. When a shard changes materially, the change ships in a release whose plan (`release/releases/plans/vX.Y_RELEASE_PLAN.md`) cites the shard among the modified files and whose `RELEASE_LOG.md` deployment-log block records the release SHA. The combination of release-plan + RELEASE_LOG + `git log --follow` is sufficient for version-tracing; no in-file frontmatter is needed.

### § 6.4 No shard header-metadata-block

Shards also do NOT carry the bold-key "head-metadata-block markdown" header that K1 standards docs (like this file) use. The shard's only header-area content is the H1 title plus the 2-line `> **Source:**` / `> **Part of:**` blockquote per § 5.1. Authors of new K1 *standards* docs (not shards) use the head-metadata-block per the precedent of [`evidence-grounding-standard.md`](evidence-grounding-standard.md), [`design-artifact-standard.md`](design-artifact-standard.md), [`planning-solutioning-handoff.md`](planning-solutioning-handoff.md), and this file. Shards stay lean.

## § 7. Audit-Trail Capture (§ 11)

### § 7.1 The pattern

```markdown
## 11. Audit-Trail Capture

This stage emits the following events to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the [unified schema](../../release/references/standards/pipeline-event-log-schema.md):

| Event type | Subtype | When | Actor |
|---|---|---|---|
| `<event_type>` | `<subtype>` | <Phase / condition that fires> | `<spoke:#N \| hub \| operator>` |

Cutover: events occurring on or after the FIRST release entering this stage strictly AFTER v<X.Y> merge SHA. v<X.Y> itself: exempt (reflexive-pipeline-loop discipline).
```

Add additional table rows for each distinct event the stage emits. The table is the authoritative inventory; the hub-spoke chip prompts for that stage cite it.

### § 7.2 When § 11 is REQUIRED

When the stage emits any event row to [`pipeline-event-log.md`](<OPERATOR_INSTANCE_EVALS_RESULTS_PATH>/pipeline-event-log.md) per the unified schema at [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md). Currently true for stages 02, 03, 04, 05, 06, 07, 08, 09, 12, 13 (10 of 13).

### § 7.3 When § 11 is OMITTED

When the stage emits no audit-trail events. Currently true for:

- **Stage 01 (Intake):** issue creation is the surface; pipeline-event-log emit is not the substrate.
- **Stages 10, 11 (PLATFORM-SATISFIED):** no executing agent → no events. § 11 is omitted alongside §§ 4-7 per § 3.1.

### § 7.4 Prospective addition

A future revision MAY add § 11 to a stage that currently omits it (e.g., if Stage 1 begins emitting `intake-template-validation` events under a new schema entry). The standard PERMITS adding § 11 prospectively as audit-trail coverage expands; no special permission is needed — append the H2 in the same release that adds the schema entry to [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md).

## § 8. Related References

### § 8.1 Canonical companions

- [ADR-002 — Modular Pipeline Stages Split](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md) — the architectural decision the shards implement.
- [`release/references/pipeline/README.md`](../../release/references/pipeline/README.md) — directory index + Stage Index table + Cross-Cutting Reference Map. The shard reader's primary entry point.
- [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1 tier classification (this standard and the shards are K1).
- [`execution-framework.md`](../disciplines/execution-framework.md) — the Process-layer explanation that every shard's § 5 Process body's `**Framework dimensions touched:**` line refers back to.

### § 8.2 Sibling K1 standards (precedent)

- [`evidence-grounding-standard.md`](evidence-grounding-standard.md) — sibling K1 authoring standard; head-metadata-block precedent.
- [`design-artifact-standard.md`](design-artifact-standard.md) — sibling K1 authoring standard; head-metadata-block precedent; current-only retention precedent.
- [`release-notes-standard.md`](../../release/references/standards/release-notes-standard.md) — sibling K1 authoring standard for user-facing release notes.
- [`planning-solutioning-handoff.md`](planning-solutioning-handoff.md) — co-released K1 standard governing the Stage 4 → Stage 5 activation matrix.
- [`solutioning-output-template.md`](../../release/references/standards/solutioning-output-template.md) — co-released K1 standard governing Stage 5 Solutioning spoke output.

### § 8.3 Schema + protocol references that shards cite

- [`pipeline-event-log-schema.md`](../../release/references/standards/pipeline-event-log-schema.md) — unified schema cited by every shard § 11 Audit-Trail Capture.
- [`gate-criteria-spec.md`](../schemas/gate-criteria-spec.md) — canonical gate criteria cited by every shard § 7 Stage-Transition Gate.
- [`gate-evaluation-spec.md`](../schemas/gate-evaluation-spec.md) — 3-layer evaluation protocol (metrics / judgment / calibration).
- [`handoff-coordinator-spec.md`](../schemas/handoff-coordinator-spec.md) — 5-phase handoff protocol invoked at every stage transition.
- [`stage-io-contracts.md`](../schemas/stage-io-contracts.md) — structured boundary contracts referenced from § 4 Inputs.
- [`.claude/rules/release-process.md`](../../release/governance/release-process.md) — concise operating procedure for the 13 stages; per-shard reference cross-links to this rule.
- [`ticket-information-architecture.md`](../../release/references/specs/ticket-information-architecture.md) — `Claim / Execute / Resolve` ticket lifecycle cited by every shard § 5 Process.

## § 9. Cutover + Version History

### § 9.1 Cutover

**Applies to all per-stage shards authored or materially modified going forward.** The 13 existing shards already conform empirically to this standard's canonical structure with the variant accommodations spec'd in § 3.

**Operational meaning of "materially modified":** edits that add / remove / reorder § 1-§ 11 H2s, edits that introduce a new variant (PLATFORM-SATISFIED declaration, extended-protocol H2, decimal sub-section, § 12+ extension), and edits that change the source-reference header. Edits internal to an existing section's body (Phase mechanics, gate criteria, audit-trail table rows) are not "material" for this standard's purposes — they are routine shard maintenance and ship per the normal release pipeline.

### § 9.2 Version History

| Version | Date | Change | Issue |
|---|---|---|---|
|  | 2026-05-24 | Initial authoring — re-scoped per Tier 0 Override (Option B); codifies the empirically-observed 10-H2 canonical structure (§ 2) + PLATFORM-SATISFIED variant (§ 3.1) + extended-protocol H2 variant (§ 3.2) + decimal sub-section policy (§ 3.3) + § 12+ extension policy (§ 3.4) + § 11 Audit-Trail Capture convention (§ 7) |  |

Future revisions append rows here. Per § 6.1, git history is the canonical retention mechanism — this table is a navigation aid, not a parallel snapshot.
