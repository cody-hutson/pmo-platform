---
title: Date-Variable Convention — Stage 5 Solutioning
purpose: The Stage-5 convention for parameterizing dates as variables rather than hardcoding them across load-bearing locations, so a UTC day-boundary crossing at Stage 6 cannot create internal contradictions.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: Stage 5 Solutioning spokes; Stage 6 Engineering (date-variable resolution at execution); AC-verifier and ADR source-observation authoring
---
<!-- reference-durability: allow-link -->
# Date-Variable Convention — Stage 5 Solutioning

**Origin:**  — process-protocol; class-potential observation surfaced via the file-overlap-audit Stage 13 retrospective.
**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Primary consumer:** Stage 5 Solutioning spokes (when authoring specs whose downstream artifacts carry a load-bearing date identifier).
**Secondary consumers:** Stage 6 Engineering spokes (variable resolution at first commit); `failure-mode-standard.md` (anti-pattern catalog reference).

## Purpose

Stage 5 specs that hardcode dates in multiple downstream load-bearing locations
(folder paths, AC verifier criteria, ADR source-observation references) create
internal contradictions when Stage 6 execution crosses a UTC day boundary
relative to the operator-local date used at spec authoring. Engineering faces
an unresolvable choice: honor the literal `date -u` instruction (force edits
across multiple files + break AC verification) OR honor the spec's hardcoded
references (Tier 1 [ADJUST] documentation burden). A single source-of-truth
date variable eliminates the contradiction class.

**Originating evidence:** Stage 6 Engineering Pass 1
encountered exactly this drift — `date -u +%Y-%m-%d` returned `2026-05-02`;
operator-local + verbatim Stage 5 spec references all used `2026-05-01`.
Spoke chose `2026-05-01` for consistency; documented as Tier 1 [ADJUST] in
`pmo-platform/analysis/file-overlap-audit-2026-05-01/SUMMARY.md` § 1 UTC drift note.

## When the convention fires (trigger predicate)

The convention applies to a Stage 5 spec iff ALL hold:

1. Spec text contains ≥1 literal date in `YYYY-MM-DD` form (operator-local at
   authoring time).
2. The same literal date appears in ≥1 downstream load-bearing artifact:
   - File or folder path created/named by the spec (e.g.,
     `pmo-platform/analysis/<audit-name>-YYYY-MM-DD/`)
   - Acceptance Criterion verifier identifier (e.g., `AC-15: File present at
     pmo-platform/analysis/<audit-name>-YYYY-MM-DD/SUMMARY.md`)
   - ADR source-observation reference (e.g., ADR `source_observation:` field
     citing a date-baked path)
   - Release-plan Deviation Log entry citing a date-baked path
3. The downstream artifact does not yet exist at spec authoring time (the
   spec instructs Stage 6 to create it).

**Does NOT fire when:**

- Date appears only in narrative context ("Survey baseline: 2026-05-21",
  "Bundle created 2026-05-16") with no load-bearing downstream consumer.
- Date is in a verbatim historical snapshot referencing an artifact that
  already exists at a fixed historical date.
- Spec creates no downstream artifacts (e.g., pure prose addition to an
  existing governance file).

**Predominant trigger today:** audit-class Stage 5 specs creating
`pmo-platform/analysis/<audit-name>-YYYY-MM-DD/` folders (24 existing audit
folders demonstrate the pattern). The trigger generalizes — applies to any
future date-baked load-bearing identifier surface.

## Variable schema

When the convention fires, the Stage 5 spec MUST use the following variable:

| Field | Value |
|---|---|
| Variable name | `${AUDIT_DATE_UTC}` |
| Format | `YYYY-MM-DD` (ISO 8601 short form) |
| Source | `date -u +%Y-%m-%d` at Stage 6 first commit |
| Scope | Resolved value propagates consistently across ALL downstream artifacts in the release (single value per release, set once at Stage 6 first commit) |

**Variable definition block in Stage 5 spec (required, top of spec):**

```markdown
### Date Variable (per `date-variable-convention.md`)

- **Variable:** `${AUDIT_DATE_UTC}`
- **Format:** `YYYY-MM-DD`
- **Source:** `date -u +%Y-%m-%d` at Stage 6 first commit
- **Propagation rule:** Engineering resolves once at first commit; substitutes
  consistently into ALL artifacts in this release's File Change Matrix.
- **Resolution moment:** Stage 6 first commit (not Stage 5 spec authoring time).
```

The variable is referenced (not resolved) throughout the Stage 5 spec body —
every path, AC verifier criterion, ADR source-obs ref uses `${AUDIT_DATE_UTC}`
in place of a literal date.

## Stage 6 propagation discipline

When Engineering spoke begins execution:

1. Read the Stage 5 spec's Date Variable block.
2. Execute `date -u +%Y-%m-%d` at the moment of the first commit; capture
   the result as the canonical resolved value (e.g., `2026-05-02`).
3. Substitute `${AUDIT_DATE_UTC}` → resolved value across ALL artifacts the
   spec instructs Stage 6 to create or modify. The substitution is mechanical
   — Engineering does not reason about which date to use.
4. Record the resolved value in the Stage 6 spoke output's `### Detail`
   section: `Resolved ${AUDIT_DATE_UTC} = <YYYY-MM-DD> at commit <short SHA>`.
5. If `date -u` returns a different date than was implied by the operator-
   local context at Stage 5 authoring, Engineering uses the UTC value as
   the canonical instantiation. No Tier 1 [ADJUST] is required — the
   contradiction class is dissolved by the convention.

## Stage 5 spec rejection criteria (load-bearing test)

A Stage 5 spec for a release where the trigger predicate holds is **incomplete**
if ANY hold:

- Date Variable block omitted from spec top.
- Variable defined but spec body contains literal `YYYY-MM-DD` strings in
  load-bearing positions (paths, AC verifiers, ADR refs) — must use
  `${AUDIT_DATE_UTC}` instead.
- Variable resolution moment unspecified or specifies a moment other than
  "Stage 6 first commit."
- Source command unspecified or specifies anything other than
  `date -u +%Y-%m-%d`.

Stage 5 spoke output that violates these is incomplete; Collective Review
flags as a structural defect; spec returns to spoke for variable hoisting.

## Cutover

This convention applies to any Stage 5 spec meeting the trigger predicate. Cutover discipline: applies to all releases going forward.

## Cross-references

| Surface | Reference | Role |
|---|---|---|
| Stage 5 protocol | [`pipeline/stage-05-solutioning.md` § 6 Outputs](../../release/references/pipeline/stage-05-solutioning.md) | Thin cross-reference at output enumeration |
| Stage 5 spoke prompt template | [`hub-spoke-bridge.md` Procedure 3](../../release/references/how-to/hub-spoke-bridge.md) | Inject convention reference alongside R1 Evidence-Grounding block |
| Failure-mode catalog | [`failure-mode-standard.md`](../standards/failure-mode-standard.md) | Anti-pattern `utc-drift-spec-contradiction` (added by Engineering at Stage 6) |
| Originating evidence | `pmo-platform/analysis/file-overlap-audit-2026-05-01/SUMMARY.md` § 1 | UTC drift incident |

## Version History

| Version | Date | Change |
|---|---|---|
| Initial | 2026-05-21 | Initial authoring —  |
