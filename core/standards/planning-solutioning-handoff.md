<!-- reference-durability: allow-link -->
# Planning-to-Solutioning Handoff — Activation-Criteria Matrix

**Origin:** Planning-to-Solutioning handoff requires pre-existing activation criteria.
**Tier:** K1 codified-knowledge corpus per [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md).
**Primary consumer:** Stage 4 Planning spokes (per [`pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md) § 5 Phase B Handoff).
**Secondary consumers:** Stage 5 Solutioning spokes (per [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0); [`release-planner`](../../release/skills/release-planner/SKILL.md) skill (Mode B release-plan authoring); release plans' Stage Applicability Matrix section.
**Status:** Canonical
**Introduced:** solutioning-routing-and-handoff release
**Cross-references:** see § 6 Cross-Reference Protocol and § Related References at the foot of this file.

## § 1. Purpose + Scope

This standard canonicalizes the trigger conditions that determine whether **Stage 5 Solutioning** activates for a given release. Stage 4 Planning spokes consume the matrix here to make a release-wide ACTIVATE / SKIP decision before authorizing Engineering Stage 6.

Before this standard existed, the trigger conditions lived only inline in the Stage 5 shard at [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 — a single-sentence comma-list. Originating evidence for the gap: Stage 5 execution discovered that Stage 4 had decided "Solutioning skipped" *before* activation criteria were formally defined; retroactive re-evaluation showed an issue triggered the "new file with non-trivial content" criterion. This standard removes the chicken-and-egg: Stage 4 now has a pre-existing, queryable matrix.

**In scope:**
- The 6 trigger conditions (T1-T6) and their definitions, detection mechanisms, examples, and authoritative source citations.
- The combination rule (logical OR), the release-level rollup, and the SKIP path semantics.
- The per-release evaluation pattern that Stage 4 spokes instantiate in the release plan's Stage Applicability Matrix.

**Out of scope:**
- **Phase 0.5 Re-Review Delta** — handled by [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) § 6.
- **Collective Review** — fires post-Solutioning, validates cross-issue design coherence; handled by [`.claude/rules/release-process.md`](../../release/governance/release-process.md) § Collective Review Protocol.
- **Per-issue mixed routing** (different activation verdicts per issue inside one release) — DISABLED future-state exception path at [`protocols/mixed-release-solutioning-routing.md`](../../release/references/protocols/mixed-release-solutioning-routing.md). Current state is all-or-nothing per release — see § 2.

## § 2. The All-or-Nothing Rule

Stage 5 Solutioning activates for the **WHOLE release** when ANY one of T1-T6 fires on ANY in-bundle issue. There is no per-issue activation surface in the current pipeline contract: either every issue in the release routes through a Solutioning sub-task, or every issue routes directly to Engineering with Planning-level specs.

**Rationale:** All-or-nothing preserves Collective Review's coherence guarantee — Collective Review's N-way consistency table assumes a uniform Solutioning corpus across the release. Mixed per-issue routing would fragment the cross-issue consistency surface and is therefore gated as a future-state exception.

**Forward-compatibility forward reference:** Mixed per-issue routing variant is specified (DISABLED) at [`protocols/mixed-release-solutioning-routing.md`](../../release/references/protocols/mixed-release-solutioning-routing.md) pending prerequisite-control validation. If/when enabled, this standard's Combination Rule will be conditional on the release's `routing-mode` declaration; until then, the all-or-nothing rule is invariant.

## § 3. Activation-Criteria Matrix

**Combination rule:** Logical OR — Stage 5 ACTIVATES for the WHOLE release when ANY one of T1-T6 fires on ANY in-bundle issue.

**Skip path:** When zero triggers fire across all in-bundle issues → Engineering (Stage 6) receives Planning-level specs directly; no Solutioning sub-tasks are created. (See § 5.)

| ID | Trigger | Definition | Detection mechanism (Stage 4 spoke applies) | Examples | Source |
|---|---|---|---|---|---|
| **T1** | **New file with non-trivial content** | Issue body declares a NEW file (not a frontmatter-only or label-only change) carrying ≥1 structural concept (schema, contract, named protocol, template, governance rule). | Read issue body's "Affected Files" + "Proposed Change" sections; flag any file path not present in `git ls-tree HEAD`. Apply non-triviality test: does the body propose ≥1 named heading, table, or schema? | New K1 standards doc; new pipeline-stage shard; new protocol file; new ADR | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 |
| **T2** | **Skill logic changes** | Issue modifies behavior, mode definition, trigger phrase, output contract, or process step in any `<module>/skills/<skill>/SKILL.md` (or the skill's `references/`). | Read issue body's "Affected Files"; flag any path matching `<module>/skills/*/SKILL.md` or `<module>/skills/*/references/*.md`. | New mode on existing skill; trigger-phrase change; output-section change | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 |
| **T3** | **Structural design decisions** | Issue requires a design choice that constrains downstream artifacts — schema, contract, naming convention, identifier format, directory layout. | Read issue body; flag any "Design decisions to make" / "Open questions" / "Mechanism unresolved" framing. Body containing the literal phrase "deferred to Stage 5 Solutioning" auto-flags. | Frontmatter schema definition; identifier-format rule; cross-doc reference protocol | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 (alias `structural changes` appears in [`release-process.md`](../../release/governance/release-process.md) § Stage 5 § Activation — historical wording variant; this matrix supersedes) |
| **T4** | **Multiple valid approaches** | Issue has ≥2 candidate implementations with non-trivial trade-offs (cost, blast radius, reversibility, compatibility). | Read issue body; flag any "Option A / Option B" pattern, "trade-off" / "trade-offs" mention, or "candidate mechanisms" enumeration. | New-skill-vs-extend-existing; canonical-name-A-vs-B; centralize-vs-embed storage; matrix-vs-flowchart form factor | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 (alias `technical trade-offs` appears in [`release-process.md`](../../release/governance/release-process.md) § Stage 5 § Activation — semantic-equivalent historical wording; this matrix supersedes) |
| **T5** | **Cross-cutting governance changes (≥3 files)** | Issue modifies ≥3 governance files (CLAUDE.md, `.claude/rules/*.md`, `core/governance/*.md`, `release/governance/*.md`, and their mirrors). | Read issue body's "Affected Files"; count paths under the four governance-file roots. Threshold: ≥3 distinct governance files. | Pipeline-stage protocol change touching `release-process.md` + a `stage-NN-*.md` shard + a skill SKILL.md + a dependency-graph entry; convention rename rippling across rules + standards + skills | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 (alias `cross-cutting governance changes` appears in [`release-process.md`](../../release/governance/release-process.md) § Stage 5 § Activation but **drops the ≥3-file threshold** — the threshold is load-bearing per `duplicate-source-discipline.md` canonical-source rule; this matrix supersedes) |
| **T6** | **Blast-radius uncertainty** | Issue's blast radius (set of files / skills / protocols affected by the change) is not deterministically derivable from the issue body. | Read issue body; flag any "may also affect", "scope uncertain", "TBD which files", or "depends on Solutioning" framing. ALSO flag when the change-spec mentions a shared pattern (regex, identifier scheme, naming convention) used in `grep -r`-discoverable locations. | New regex/pattern with unknown current-state distribution; refactor of a convention used in unknown number of locations; rule change with unknown propagation | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 |

**Authoritative-source discipline:** The Stage 5 pipeline shard ([`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0) is the canonical wording source per [ADR-002](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md) modular-pipeline-stages split. The 3 wording variants in [`.claude/rules/release-process.md`](../../release/governance/release-process.md) § Stage 5 § Activation are documented above in the Source column as historical aliases for navigation-aid only; they are NOT authoritative. The [`duplicate-source-discipline.md`](duplicate-source-discipline.md) register-or-remove rule routes future wording-alignment edits to the mirror summary, not the canonical shard.

## § 4. Per-Release Evaluation Pattern

Stage 4 Planning spokes instantiate the matrix below in the release plan's `## Stage Applicability Matrix` section. The instantiation produces a Verdict + per-trigger rationale that Stage 5 spokes (or the SKIP-path downstream stages) read at gate-entry.

| Issue | T1 | T2 | T3 | T4 | T5 | T6 | Verdict | Rationale |
|---|---|---|---|---|---|---|---|---|
| `#N` | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | ✓/✗ | ACTIVATE / SKIP | one-line cite per fired trigger |

**Release-level rollup rule:**
- ANY ✓ on ANY issue → release-wide **ACTIVATE** (Stage 5 sub-tasks created for ALL retained issues).
- ALL ✗ across ALL issues → release-wide **SKIP** (Engineering Stage 6 receives Planning-level specs directly).

**Worked instantiation (this release):** See [the release plan](<OPERATOR_INSTANCE_RELEASES_PLANS_PATH>) § 6 Stage Applicability Matrix for the canonical example. All four release issues hit ≥1 trigger; release-level verdict is **ACTIVATE**.

**Authoring note (Stage 4 spoke):** The matrix can be terse (single ✓/✗ glyph per cell) when the Rationale column captures the per-trigger evidence. The Rationale column is the read-surface for Collective Review's R4 N-way consistency table — it must be specific enough that a downstream reader can verify the trigger fired without re-reading the issue body.

## § 5. Skip Path

When the release-level rollup yields SKIP, the handoff bypasses Stage 5 entirely:

- **No Stage 5 sub-tasks created.** Hub Procedure 1 Scaffolding skips Stage 5 chips for all retained issues.
- **No Collective Review fires.** Collective Review's trigger ("Release has ≥2 issues with Solutioning activated") cannot fire when zero issues activated.
- **Engineering Stage 6 receives Planning-level specs directly.** Stage 4 spoke's change-spec output (file-level: what to add/edit/remove) is the authoritative engineering input; no ADR drafting, no design-artifact production, no blast-radius re-analysis.
- **Release plan still records SKIP.** The Stage Applicability Matrix shows ✗ for every trigger × every issue, with Verdict SKIP and Rationale "no trigger fires" (or per-issue equivalent).

**When SKIP is appropriate:** Releases consisting entirely of (a) text corrections / typo fixes, (b) cross-reference updates with deterministic targets, (c) deletion of confirmed-orphan files, (d) tracker-format adjustments that don't change semantics, (e) version-field bumps on already-shipped artifacts. The common pattern: every change has a single deterministic implementation; no design choice is open.

**Anti-pattern:** Using SKIP to avoid Solutioning overhead on a release that *should* activate. If any issue body contains "deferred to Stage 5 Solutioning" framing, T3 fires automatically — SKIP is invalid. The Stage 5 shard's Phase 0.5 Re-Review Delta will retroactively flip the verdict at Stage 5 entry if Stage 4 mis-classified.

## § 6. Cross-Reference Protocol

**Authoritative cross-refs from this standard:**

| Direction | Surface | Section | Role |
|---|---|---|---|
| Inbound (consumers cite here) | [`pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md) | § 5 Phase B Handoff | Stage 4 spoke entry — instantiates the per-release evaluation matrix per § 4 above. |
| Inbound (consumers cite here) | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) | § 5 Phase 0 — Activation Gate | Stage 5 spoke entry — gates on the per-release matrix's Verdict column. |
| Outbound (this standard cites) | [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) | § 5 Phase 0 | Canonical wording source for T1-T6 trigger names; this standard is a re-encoding into matrix form with detection mechanisms added. |
| Outbound (forward-compatibility) | [`protocols/mixed-release-solutioning-routing.md`](../../release/references/protocols/mixed-release-solutioning-routing.md) | full file | Future-state exception path for per-issue mixed routing (DISABLED in current state — see § 2). |
| Outbound (mirror summary) | [`.claude/rules/release-process.md`](../../release/governance/release-process.md) | § Stage 5 § Activation | Operational mirror summary; historical wording variants documented as aliases in § 3 Source column. |
| Outbound (sibling K1 conventions) | [`evidence-grounding-standard.md`](evidence-grounding-standard.md) / [`design-artifact-standard.md`](design-artifact-standard.md) / [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) | full files | Sibling K1 standards establishing head-metadata-block convention adopted by this file (matched Collective Review N-way consistency expectation). |

**Mirror-pair discipline:** Edits to the canonical source [`release/governance/release-process.md`](../../release/governance/release-process.md) must mirror byte-identically to the deployed mirror `~/.claude/rules/release-process.md` per [`skill-deployment.md`](../rules/skill-deployment.md) Check 9. This standard is NOT a mirror pair — it is a single canonical K1 file under `core/standards/`.

## § 7. Cutover + Version History

**Cutover discipline:** Applies to all releases going forward.

**Pre-cutover behavior:** Stage 4 spokes consulted the inline single-sentence list at [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) § 5 Phase 0 directly. Pre-cutover release plans may not include a `## Stage Applicability Matrix` section in the standardized form of § 4 above; their Solutioning verdicts are recorded inline in the release plan body.

**Version history:**

| Version | Change | Origin |
|---|---|---|
| Initial | Initial publication. Canonicalizes the 6 trigger names from the Stage 5 shard into matrix form; adds Detection mechanism + Examples + Source columns; establishes Per-Release Evaluation Pattern for Stage 4 spokes; establishes SKIP path semantics. |  |

## Related References

**Pipeline shards (authoritative wording sources):**
- [`pipeline/stage-04-planning.md`](../../release/references/pipeline/stage-04-planning.md) — Stage 4 Planning shard; § 5 Phase B Handoff routes via this matrix.
- [`pipeline/stage-05-solutioning.md`](../../release/references/pipeline/stage-05-solutioning.md) — Stage 5 Solutioning shard; § 5 Phase 0 Activation Gate gates on this matrix.

**Sibling K1 standards (convention references):**
- [`evidence-grounding-standard.md`](evidence-grounding-standard.md) — head-metadata-block frontmatter convention reference.
- [`design-artifact-standard.md`](design-artifact-standard.md) — Tier-A activation matrix sibling (table form for activation rules).
- [`triage-design-rereview.md`](../../release/references/standards/triage-design-rereview.md) — Phase 0.5 Re-Review Delta protocol; Premise-Rejection routing for stale-assumption discovery.
- [`duplicate-source-discipline.md`](duplicate-source-discipline.md) — canonical-source-vs-mirror discipline that gates the wording-variant note in § 3.

**Operational mirrors (downstream summaries):**
- Canonical source [`release/governance/release-process.md`](../../release/governance/release-process.md) — § Stage 5 § Activation operational mirror summary; deployed byte-identically to the workspace mirror `~/.claude/rules/release-process.md` (Check 9).

**Future-state forward references:**
- [`protocols/mixed-release-solutioning-routing.md`](../../release/references/protocols/mixed-release-solutioning-routing.md) — DISABLED per-issue mixed-routing variant; § 2's all-or-nothing rule will become conditional on `routing-mode` declaration if/when enabled.

**Process-context cross-refs:**
- [`release/ADRs/ADR-002-modular-pipeline-stages-split.md`](../../release/ADRs/ADR-002-modular-pipeline-stages-split.md) — establishes the pipeline shard as the canonical-wording source.
- [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1 tier classification.
- [`.claude/rules/release-process.md`](../../release/governance/release-process.md) § Collective Review Protocol — downstream consumer that reads activation outcomes to gate scope-lock.

**Origin issue:**
-  — Planning-to-Solutioning handoff requires pre-existing activation criteria.
