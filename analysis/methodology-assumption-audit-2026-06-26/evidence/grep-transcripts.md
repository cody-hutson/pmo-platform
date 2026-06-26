<!-- repo-integrity: allow-issue-ref -->
# Grep Transcripts — Methodology-Assumption Audit (#1094)

**Baseline SHA:** `d1d896c`   **Audit date:** 2026-06-26 (UTC)
Re-run any block below against `d1d896c` to byte-reproduce the finding. Paths are repo-root-relative.

## §0 grep set (the reproducible instrument)

- Selector reads: `grep -rnE 'delivery_approach|lifecycle:|custom_methodology_definition' <surface>`
- Archetype vocab: `grep -rinE 'story[ -]?point|burndown|velocity|sprint[ -](hygiene|goal|assignment)|\bsprint\b|phase[ -]gate|\bDoR\b|\bDoD\b' <surface>`
- Co-mgmt binary (NOT a selector): `grep -rinE 'dual_framing_enabled|spm_comanaged' <surface>`

## Census hit-density (archetype vocab, per surface)

| Surface | archetype-vocab hits |
|---|---|
| S1 intake-desk | 5 (all phase-gate homonyms) |
| S2 delivery-engine | 425 (densest; SKILL.md + references machinery) |
| S3 tracker-manager | 6 (phase-gate, resolver-gated) |
| S4 ppm-agent | 38 (mostly examples/input-parsing; 1 ambiguous row) |
| S5 weekly-status-rollup | 17 (metric registry + DFB) |
| S6 daily-status | 3 (1 DFB site + 2 agnostic-fallback refs) |
| S7 release-planner | 0 (out of methodology axis) |
| S8 work-org-framework | 5 (archetype-row primitives, R3) |
| S9a OPERATIONS.md | 15 (the resolver contract itself) |
| S9b project-schema.md | 11 (enum/validation definitions) |

## F01 (leak, A1) — delivery-engine Mode A: absence-proof

```
$ sed -n '109,142p' operations/skills/delivery-engine/SKILL.md | grep -nE 'delivery_approach|lifecycle:|custom_methodology_definition'
(no output) ; exit 1   # Mode A (lines 109-142) reads NO selector

$ grep -nE 'Sprint hygiene|current sprint|Sprint cycling' operations/skills/delivery-engine/SKILL.md
122:   - **Priority distribution**: P1/P2 without assignees, P1s not in current sprint
123:   - **Sprint hygiene**: items in sprint without estimates, items assigned to closed
130:   - Sprint cycling -> escalation recommendation with impact statement
```
Mode A boundary: `grep -nE '^### Mode [A-G]:'` -> Mode A = 109, Mode B = 143 (so Mode A body = 109-142).
The sprint scorecard dimensions (122-125) are behavior-determining (emitted as universal health findings) with zero selector branch -> LEAK / §6.4 hardcoded-sprint-presumption.

## F02 (ambiguous, A2) — delivery-engine Mode D: indeterminacy-proof

```
$ sed -n '178,217p' operations/skills/delivery-engine/SKILL.md | grep -c delivery_approach
2     # selector read for sub-features only: :191 facilitation, :196 tech-debt floor
```
Mode D body = 178-217 (Mode D = 178, Mode E = 218). The selector is read for two sub-features but the sprint/iteration *frame* (capacity/velocity/sprint-goal, trigger "Plan the sprint") is ungated. Indeterminate: Scrum-by-design vs presumption.

## F03 (ambiguous, A2) — ppm-agent artifact-gap-detection: indeterminacy-proof

```
$ grep -nE 'delivery_approach|methodology|archetype|Waterfall|Kanban|agnostic' operations/skills/ppm-agent/references/artifact-gap-detection.md
(no output) ; exit 1   # no methodology branch anywhere in the file

$ grep -n 'Sprint Execution' operations/skills/ppm-agent/references/artifact-gap-detection.md
17:| **Sprint Execution** | Sprint DoR (per sprint) | Sprint Backlog, Sprint Goal, Acceptance Criteria per PBI | Refinement pipeline (2+ sprints ahead) |
```
One row hardcodes Scrum artifacts in an otherwise-agnostic phase checklist; no archetype branch. Indeterminate: row inert for non-Scrum (phase never reached) vs row fires phase-agnostically (leak).

## F04 (ambiguous, A2) — weekly-status-rollup metric-registry: indeterminacy-proof

```
$ grep -c delivery_approach operations/skills/weekly-status-rollup/references/metric-registry.md
0     # no selector branch in the metric registry

$ grep -nE 'Velocity Variance|Sprint Commitment Reliability|Blocked-Item' operations/skills/weekly-status-rollup/references/metric-registry.md
80:| **Velocity Variance** | ... | sprint metrics roll-up | ...
102:| **Sprint Commitment Reliability** | `delivered / committed` | sprint board | ...
103:| **Blocked-Item Count** | ... | sprint board | ...
125:| Velocity Variance | Program | **Leading** | ...
133:| Sprint Commitment Reliability | Team | **Lagging** | ...
134:| Blocked-Item Count | Team | **Leading** | ...
```
Sprint-derived metrics defined as the universal program metric set with no archetype gating. Indeterminate: degrade-to-N/A on absent source vs presumes a sprint board universally.

## Resolver-gated anchors (selected proofs)

```
# RG-S4★ gold exemplar — ppm-agent decision-authority negative path
$ grep -nE 'never silently assume a model|methodology-agnostic' operations/skills/ppm-agent/SKILL.md
192:**Negative path - never silently assume a model.** ...
195:PROC-4 "hardcoded sprint presumption" anti-patterns). Instead, emit a **methodology-agnostic**

# RG-S2a — delivery-engine Mode E Stage-Tracking reads selector + never-assume-Scrum
$ grep -n 'never silently assume Scrum' operations/skills/delivery-engine/SKILL.md
238:   - **Resolve the model column.** Read `delivery_approach` ... never silently assume Scrum ...

# RG-S9a — the resolver contract
$ grep -n 'MUST read the `delivery_approach`' core/governance/OPERATIONS.md   # (approx)
345:Every skill that reads PROJECT.md MUST read the `delivery_approach` field ...

# RG-S3 — tracker-manager resolver-gating target (out-of-frame corroborator)
$ grep -n 'Methodology Variation' core/schemas/tracker-schemas.md
340:## Methodology Variation - Tracker Applicability
349:| **Waterfall** | Milestone + phase-gate trackers are primary; no sprint-scale trackers. ...
```

## Stale-premise correction (spm_comanaged retired)

```
$ grep -nE 'spm_comanaged|retired in v2.19|no longer accepted' core/schemas/project-schema.md
97:**Renamed field.** ... the legacy key it replaced was **retired in v2.19** and is no longer accepted on read. ...
324:The dual-framing co-management trigger is named **`dual_framing_enabled`**. The legacy key `spm_comanaged` ... **retired in v2.19** ...
```
The #1094 "5 of 7 read spm_comanaged" premise is stale. The live binary is `dual_framing_enabled` (orthogonal co-management trigger, NOT a methodology selector). Coding read the live key throughout.
