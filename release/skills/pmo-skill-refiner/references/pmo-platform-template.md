# PMO Platform SKILL.md Template

## Usage

This file is consumed by `pmo-skill-refiner` after Anthropic scaffolding completes. Each `{{placeholder}}` below is filled from the Interview-mode packet or derived from platform state. The refiner applies this template additively — whatever the Anthropic scaffolder produced is preserved; these PMO-specific fields are injected into the produced SKILL.md alongside it.

The 7 injection fields map to the 7 PMO Injection Points in the refiner's SKILL.md — one field per row.

---

## Frontmatter additions

Append these keys to the YAML frontmatter that the Anthropic scaffolder produced. Do not overwrite `name` or `description` — inject alongside.

```yaml
# (Required — 1 of 7 injection fields)
# Methodology the skill assumes. If "n/a", the skill is methodology-agnostic.
# If "context-aware", the skill derives delivery_approach from project context;
# this is a planned future capability until the context-aware derivation ships.
delivery_approach: {{waterfall|agile|kanban|hybrid|n/a|context-aware (planned)}}

# (Required when skill produces Tier 1 artifacts — see CLAUDE.md § Cascade Approval)
# Scope string declaring what downstream Tier 2 files this skill may auto-write after user approval.
# Omit entirely for skills that never produce Tier 1 artifacts.
cascade_scope: {{scope-string-or-omit}}

# (Recommended — declared self-target)
# Principal Standard target tier at creation per the Scoring Guide in
# `core/standards/principal-standard-checklist.md`. Typically CONDITIONAL PASS.
# pmo-skill-refiner pre-handoff gate enforces this target against the skill's own body.
principal_standard_pass: {{SCORING_GUIDE_TIER}}
```

---

## Body template blocks

The refiner injects these sections into the Anthropic scaffold body. If the Anthropic scaffolder produced a section with the same heading, the refiner appends rather than replaces (preserving scaffolder content while adding PMO rigor).

### Guardrails (Platform)

Optional explicit reference block — CLAUDE.md § Universal Preferences are always in force; restating them in-skill is permitted for emphasis but not required.

```markdown
## Guardrails (Platform)
Inherits CLAUDE.md § Universal Preferences and § Quality Standards. See the source
for the authoritative list. Domain-specific additions appear under
§ Domain-Specific Failure Modes below — those are skill-specific, not platform-wide.
```

Note: `## Guardrails (Platform)` header is fixed (G7 gate regex keys on the exact string). Skills currently using `## Guardrails` should rename during the next structural-edit pass.

### When to use

Placeholder filled from Interview Q1. Short prose, 1–3 paragraphs, answering: what this skill enables Claude to do + the situations where it fires vs. skips.

```markdown
## When to use
{{Q1-answer-prose}}

Skip and route elsewhere when {{Q1-out-of-scope-enumeration}}.
```

### Output Contract

Injection field 2. Stubs a reference; the authoritative schema lives in `per-skill-output-contracts.md` Skill N, which the refiner registers concurrently.

```markdown
## Output Contract

See `core/schemas/per-skill-output-contracts.md` §
Skill {{N}} — `{{skill-name}}` for the canonical output schema, required
elements, validation checklist, and RAID prefix.
```

### Dependency Graph Node

Injection field 3. Stubs a reference; the authoritative dependency edges live in `registry.md`, which the refiner registers concurrently.

```markdown
## Dependency Graph Node

This skill's dependency edges are declared in its CI row in
`core/skills/registry.md`.
- Upstream: {{upstreams}}
- Downstream: {{downstreams}}
- Shared contracts: {{shared-contracts}}
- RAID prefix: {{prefix}}
```

### Evidence Quality Protocol

Injection field 4. Required clause. Applies to the skill's internal analysis, not only user-facing outputs.

```markdown
## Evidence Quality Protocol

Every factual claim in this skill's outputs carries an evidence-quality label
per CLAUDE.md § Universal Preferences: `[SOURCE]`, `[INFERRED]`,
`[ASSUMPTION – CONFIRM]`, `[CONTEXT]`, or `[RECOMMENDED]`. This applies to the
skill's internal analysis and reasoning chain — not only to user-facing output.
Unsourced claims are not acceptable intermediate state.
```

### Reversibility Discipline

Injection field 6. Two forms — decision-class (full tier vocabulary) or report-only (explicit opt-out). Interview Q3 determines which form applies.

**Form A — Decision-class (skill produces recommendations, plans, escalations, or proposed actions):**

```markdown
## Reversibility Discipline

This skill produces decision-class outputs. Every decision-class item carries
a reversibility tier (CHEAP / MODERATE / EXPENSIVE / IRREVERSIBLE) paired
with confidence (HIGH / MEDIUM / LOW) per
`core/specs/reversibility-protocol.md`. pmo-qa-auditor G4
validates tier labeling on outputs.

Typical tier mix for this skill's outputs:

| Output | Typical tier | Rationale |
|---|---|---|
| {{output-name}} | {{TIER}} · {{confidence}} | {{why}} |
```

**Form B — Report-only (skill produces summaries, reports, or data extracts with no recommended actions):**

```markdown
## Reversibility Discipline

This skill produces report-only outputs. No decision-class items are emitted.
pmo-qa-auditor G4 reversibility check is not applicable to this skill's outputs —
G4 skip is intentional and declared here.
```

### Domain-Specific Failure Modes

Injection field 5. Placeholder for ≥ 3 entries using the 5-field template from `failure-mode-standard.md`. Each entry carries one category tag (TRIG / INPUT / PROC / OUT / HAND). The refiner LOOPS Interview Q5 if the user cannot produce 3 real domain-specific failure modes — under-specification is a signal to sharpen scope, not to ship with generic platform-guardrail restatements.

```markdown
## Domain-Specific Failure Modes

### {{failure-mode-name-1}} — {{TRIG|INPUT|PROC|OUT|HAND}}

- **Signature (observable signal):** {{what-a-reviewer-would-see}}
- **Conditional:** do NOT {{X}} when {{Y}}, because {{Z}}.
- **Root cause:** {{why-this-pattern-emerges}}
- **Mitigation:** {{what-to-do-instead}}
- **Principal response vs. junior response:** {{gradient}}

### {{failure-mode-name-2}} — {{TAG}}

[... same 5 fields ...]

### {{failure-mode-name-3}} — {{TAG}}

[... same 5 fields ...]
```

**Category reminder (from failure-mode-standard.md):**
- **TRIG** — when to invoke (wrong methodology, wrong scope, wrong domain)
- **INPUT** — how input is trusted or verified (unchecked evidence, self-reports)
- **PROC** — which protocol steps execute (skipping gates, mis-ordering)
- **OUT** — output shape and grounding (placeholders, un-evidenced claims, vague framing)
- **HAND** — boundary and transition (swallowed conflict, missed escalation)

The ≥ 3 floor is skill-level, not per-category. A skill may cluster all 3 entries in one category if its failure surface concentrates there; diverse category coverage is encouraged but not mandated.

### Principal Standard Target

Injection field 7. Declared self-target and competency gradient.

```markdown
## Principal Standard Target

≥ {{N}}/8 PASS at creation per
`core/standards/principal-standard-checklist.md`.

Competencies this skill naturally strengthens:
- **{{Competency}}** — {{why-strengthened}}
- ...

Competencies this skill is at risk for:
- **{{Competency}}** — {{why-at-risk}}
- ...
```

---

## Cross-reference resolution

After all 7 injections, the refiner runs a cross-reference resolution pass. Every `reference/*.md` path, every platform-doc link (`per-skill-output-contracts.md`, `registry.md`, `failure-mode-standard.md`, `reversibility-protocol.md`, `principal-standard-checklist.md`) must resolve to an existing file at pre-handoff time. Broken references fail the pre-handoff gate.

## Integration with Interview packet

Field-to-Interview mapping:

| Injection field | Interview question | Derivation |
|---|---|---|
| `delivery_approach` | Q4 | Direct assignment |
| `## Output Contract` stub | Q7 | Skill number N = next unused slot in `per-skill-output-contracts.md` (refiner computes) |
| `## Dependency Graph Node` stub | Q6 | Upstream/downstream from Q6; shared-contracts enumerated from Q7 |
| `## Evidence Quality Protocol` | (inherited from CLAUDE.md) | Fixed content; no Interview source |
| `## Domain-Specific Failure Modes` | Q5 + Q9 | ≥ 3 entries; Q9 feeds the Principal-vs-junior gradient field |
| `## Reversibility Discipline` | Q3 | Form A if "decision-class"; Form B if "report-only" |
| `## Principal Standard Target` | Q8 | Target N from Q8; competency gradient from Q8 answers |

## Validation checklist (pre-handoff gate)

- [ ] YAML frontmatter parses; `delivery_approach` present and valid enum
- [ ] `## Output Contract` stub resolves to an actual Skill N entry in per-skill-output-contracts.md
- [ ] `## Dependency Graph Node` stub resolves to an actual CI row for `<skill-name>` in registry.md
- [ ] `## Evidence Quality Protocol` clause present
- [ ] `## Domain-Specific Failure Modes` has ≥ 3 entries; each matches the 5-field template; each heading carries a TRIG/INPUT/PROC/OUT/HAND tag
- [ ] `## Reversibility Discipline` is Form A (tier vocabulary + typical-tier-mix table) or Form B (explicit opt-out)
- [ ] `## Principal Standard Target` declares a target N/8 and lists strengths + risks
- [ ] All cross-references resolve to existing files
