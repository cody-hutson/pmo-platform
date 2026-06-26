<!-- reference-durability: allow-link -->
# Evidence-Grounding Standard — Stage 5 Solutioning

**Origin:**  R1 (Evidence-Grounding at Solutioning) — process-hardening defense-in-depth bundle.
**Tier:** K1 codified-knowledge corpus per [knowledge-architecture.md](../disciplines/knowledge-architecture.md).
**Primary consumer:** Stage 5 Solutioning spokes (Procedure 3 spoke prompts in [`hub-spoke-bridge.md`](../../release/references/how-to/hub-spoke-bridge.md)).
**Secondary consumers:** Collective Review Decision Briefing template (R1 ↔ R4 composition per [`.claude/rules/release-process.md`](../../release/governance/release-process.md) Collective Review Protocol); Hub Decision Briefing Empirical Verification subsection (R3 ↔ R1 composition per `hub-spoke-bridge.md` Operating Principle).

## Purpose

Every Stage 5 Solutioning spoke output that **canonicalizes a convention** must include an inspectable Evidence-Grounding artifact. The artifact lives as a `### Evidence-Grounding (per R1 )` subsection inside the spoke output, placed **after** the per-R Detail subsections and **before** the `### Decisions & Recommendations` section. Collective Review Decision Briefing rejects scope-lock approval when a canonicalization is detected without the artifact (the R4 N-way scan catches this).

This standard codifies the schema, load-bearing test, and rejection criteria the consumers reference. It complements but does not replace: the spoke prompt language at [`hub-spoke-bridge.md` Procedure 3](../../release/references/how-to/hub-spoke-bridge.md) (injection point at Stage 5 entry), the Collective Review rejection schema at [`.claude/rules/release-process.md`](../../release/governance/release-process.md) Collective Review Protocol bullet 6 (rejection-gate point at scope-lock), and the failure-mode entry `spec-vs-reality-divergence` at [`failure-mode-standard.md`](../standards/failure-mode-standard.md) (anti-pattern catalog).

## What counts as "canonicalizing a convention"

The Stage 5 spoke output triggers Evidence-Grounding for any of the following operations:

| Operation class | Example | Triggers? |
|---|---|---|
| Selecting a canonical value from ≥2 observed variants in the codebase | `reference/` vs `references/`; `feat:` vs `feature:` | YES |
| Introducing a new structural rule that constrains existing artifacts | "every SKILL.md MUST have `version:` field" | YES |
| Naming a new file/section/identifier that fits into an existing naming scheme | "new `release-corpus-schema.md` in `core/standards/`" | YES (verify scheme conformance) |
| Specifying a regex / grep pattern that asserts against current state | `^v[0-9]+\.[0-9]+(-[a-z]+)?$` (version-field regex) | YES |
| Setting a numeric threshold or boundary | "N=2 emergence rule", "180-day staleness window" | YES (justify against current state distribution) |
| Pure design choice without state-comparison surface | "use markdown table over YAML for the briefing template" | NO (no current state to canonicalize against) |
| Writing prose explanations / commentary in governance docs | "The release process follows a 13-stage pipeline." | NO |

**Test of last resort:** Whether a downstream reader can ask "what is the current state of this convention across the codebase?" — if yes, Evidence-Grounding applies.

## Schema (load-bearing 2-part artifact)

Each canonicalization produces a 2-part artifact:

```markdown
### Evidence-Grounding (per R1 )

#### Canonicalization: <convention name>

**Current-state enumeration** (REQUIRED — must be empirically grounded):
| Source | Variant observed | Count | Evidence |
|---|---|---|---|
| `<file/section/issue>` | `<value>` | <N> | `<grep command or file:line>` |
| `<file/section/issue>` | `<value>` | <N> | `<grep command or file:line>` |
| ... | ... | ... | ... |

**Survey command:** `<exact grep/find command the operator can re-run>`
**Survey date:** `<YYYY-MM-DD>` at commit `<short SHA>`

**Canonical choice:** `<value>`

**Canonical-choice justification** (REQUIRED — must reference at least one of the 3 categories below):
- Audit finding: `<file:section reference>` OR
- Upstream convention: `<reference to upstream-reference-catalog.md entry per R2>` OR
- Documented rationale: `<reference to ADR issue # OR governance doc section>`

**Out-of-scope drift detected during survey** (REQUIRED if non-zero — surfaces R1's spec-vs-reality work to downstream stages):
- `<file:line>` — `<observation>` — `<routing: Tier 1 [ADJUST] | next-release issue | accepted-residual>`
```

The three justification categories — audit / upstream / ADR — are exhaustive by construction. Sample prompt language at [`hub-spoke-bridge.md` Procedure 3 Spoke Template](../../release/references/how-to/hub-spoke-bridge.md) routes the spoke to one of the three. When justification cites the **upstream** category, the entry references [`upstream-reference-catalog.md`](upstream-reference-catalog.md).

## Load-bearing test (rejection criteria)

Reviewers reject the artifact as ceremony when ANY of these hold (load-bearing test references [`decision-discipline.md`](../disciplines/decision-discipline.md) § 5 G1 / G3 ceremony-management guards):

- Current-state enumeration lists < 2 sources OR fails to cite reproducible evidence (`grep` / `file:line` / `gh issue view`)
- Canonical-choice justification cites "platform conventions" / "best practice" alone (per [`decision-discipline.md`](../disciplines/decision-discipline.md) G3 evidence-citation requirement)
- Survey command is missing OR irreproducible (e.g., `grep <pattern>` without file scope)
- "Out-of-scope drift detected" section omitted entirely (zero entries is valid; **omission is structural defect** — drift may have been observed and ignored)

The "REQUIRED if non-zero" framing for the drift section is intentional: the section must always be present; its contents may be empty when no drift is observed. The omission test is structural, not content-based.

## Collective Review rejection schema (R1 ↔ R4 composition)

The Collective Review Decision Briefing template (amended) includes an Evidence-Grounding scan column. For each canonicalization in any Solutioning output in the release, the hub records:

| Convention canonicalized | Spoke output (issue # / sub-task #) | Evidence-Grounding present? | Grounding category | Verdict |
|---|---|---|---|---|
| `<name>` | `#<issue>` (sub-task #N) | YES / NO | audit / upstream / ADR / NONE | PASS / BLOCK |

Verdict `BLOCK` triggers operator decision: (a) return to Solutioning for re-grounding, (b) override with documented rationale in the briefing's deviation log. Default rule: BLOCK unless operator overrides.

## Sample spoke prompt language (enforcement at Stage 5 entry)

The Stage 5 Spoke Template at [`hub-spoke-bridge.md` Procedure 3](../../release/references/how-to/hub-spoke-bridge.md) embeds the following block into the `## Task` section of every Stage 5 spoke prompt, after the existing task instructions and before `## Output`:

```
## R1 Evidence-Grounding Discipline

If your output canonicalizes ANY convention (dir name, frontmatter field, file
path pattern, regex, identifier format, naming scheme, numeric threshold, any
structural-spec value chosen from ≥2 candidates), you MUST produce an
inspectable Evidence-Grounding artifact in your output:

1. Enumerate current state across the codebase (specific files/sections/issue
   citations + reproducible grep command).
2. Justify the canonical choice with citation to (a) an audit finding,
   (b) an upstream-reference catalog entry per R2 (see
   `core/standards/upstream-reference-catalog.md`), or
   (c) a documented governance rationale (ADR issue # or doc section).
3. List any out-of-scope drift observed during the survey, with routing
   recommendation (Tier 1 [ADJUST] / next-release issue / accepted-residual).

Place the artifact as a `### Evidence-Grounding (per R1 )` subsection
in your output, AFTER `### Detail` and BEFORE `### Decisions & Recommendations`.

Failure to ground a canonicalization is a Collective Review rejection
trigger (per `.claude/rules/release-process.md` Collective Review Protocol
bullet 6 — N-way consistency + evidence-grounding scan). Stage 5 sub-task
output is incomplete without this artifact when applicable.
```

The block is the operational injection point; this standard is the schema authority.

## R3 ↔ R1 composition (Empirical Verification consumes evidence-citation discipline)

The Hub's per-recommendation Empirical Verification subsection (per R3, embedded in [`hub-spoke-bridge.md` Procedure 4 step 6](../../release/references/how-to/hub-spoke-bridge.md) Decision Briefing template) consumes this standard's evidence-citation discipline:

- The `Verification command / artifact read` line in the R3 template follows the same reproducible-evidence discipline as this standard's `Survey command` line — scoped, reproducible, citable.
- The `Observed result` line in the R3 template follows the same load-bearing test as this standard's `Current-state enumeration` — specific evidence, not "platform conventions" / "looks correct".

This composition is why operator pre-decision LOCKED D-D KEEP STANDALONE (single PR, sequenced commits) — splitting R3 from R1 would require R3 to either duplicate this standard's discipline (specification debt) or operate without it (defeats R3's purpose).

## Cross-references

| Surface | Reference | Role |
|---|---|---|
| Spoke prompt template | [`hub-spoke-bridge.md` Procedure 3 Spoke Template](../../release/references/how-to/hub-spoke-bridge.md) | Injection point at Stage 5 entry |
| Collective Review rejection | [`.claude/rules/release-process.md` Collective Review Protocol bullet 6](../../release/governance/release-process.md) | Rejection-gate point at scope-lock |
| Failure-mode entry (R1) | [`failure-mode-standard.md` § Reorg / structure-change examples](../standards/failure-mode-standard.md) | Anti-pattern catalog (`spec-vs-reality-divergence`) |
| Failure-mode entry (R3) | [`failure-mode-standard.md` § Reorg / structure-change examples](../standards/failure-mode-standard.md) | Anti-pattern catalog (`concurrence-without-verification`) — composes with R1 evidence-citation |
| Persona behavioral marker (Stage 5) | [`release-personas.md` § Stage 5: Solutioning](../../release/references/specs/release-personas.md) | Stage 5 persona binding (R1) |
| Persona behavioral marker (Stage 9) | [`release-personas.md` § Stage 9: Plan Review](../../release/references/specs/release-personas.md) | Stage 9 persona binding (R3 — empirical verification before go/no-go) |
| Decision-discipline ceremony guards | [`decision-discipline.md` § 5](../disciplines/decision-discipline.md) | Load-bearing test parent framework (G1 / G3) |
| Upstream-reference catalog | [`upstream-reference-catalog.md`](upstream-reference-catalog.md) | One of three justification categories (added) |
| Empirical Verification template (R3) | [`hub-spoke-bridge.md` Operating Principle + Procedure 4 step 6](../../release/references/how-to/hub-spoke-bridge.md) | R3 ↔ R1 composition — Empirical Verification subsection cites this standard for evidence-citation format (added commit) |

## Cutover

**Cutover discipline:** Applies to all releases entering Stage 5 going forward.

## Version History

| Version | Date | Change |
|---|---|---|
| — | 2026-05-16 | Initial authoring — R1 defense-in-depth bundle |
