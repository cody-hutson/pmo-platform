# Implementation-Planner Domain Packs — Registry & Schema

Domain packs parameterize the `implementation-planner` skill with domain-specific planning context (RT-type applicability, severity-scale native, operator profile, sequencing rules, batch limits). This file is the registry, the shared schema contract, and the domain-detection rules. Mirrors the structure established by `build-reviewer`'s dimension packs for common-key alignment.

**See also:** [`../../SKILL.md`](../../SKILL.md) — the planner skill that loads these packs; [`../output-format-spec.md`](../output-format-spec.md) — the Edit-ready output contract consumed by [`release/references/how-to/implementation-execution-pattern.md`](../../../../references/how-to/implementation-execution-pattern.md).

---

## Pack Registry

| `pack_name` | file | `applies_to` | `rt_types_supported` | `severity_scale_native` | `default_when_no_match` |
|---|---|---|---|---|---|
| `copilot-builder` | [`copilot-builder-domain.md`](copilot-builder-domain.md) | Copilot Builder Agent Document Pack (30 production files + 1 derived artifact `Runtime_Constitutional_Minimum_Set.md`) | RT-1..RT-8 (all) | CS1..CS4 | false |
| `pmo-platform` | [`pmo-platform-domain.md`](pmo-platform-domain.md) | PMO platform remediation planning (skills, governance, reference docs, pipeline stages, suite contracts) | RT-1, RT-2, RT-3, RT-4, RT-5, RT-8 | CRITICAL..LOW | false |
| `generic` | [`generic-document-pack-domain.md`](generic-document-pack-domain.md) | Any document pack without a domain-specific pack match | RT-1, RT-2, RT-3, RT-4, RT-5, RT-8 | CRITICAL..LOW | **true** (fallback) |

---

## Shared Pack Schema (YAML Frontmatter Contract)

Every pack declares the following frontmatter. Keys split into two groups: common keys mirror build-reviewer's dimension packs for cross-skill schema consistency; content-specific keys legitimately differ because the two skills operate on different axes (dimensions vs. remediation types).

### Common Keys (identical to build-reviewer's dimension packs)

| Key | Type | Required | Description |
|---|---|---|---|
| `pack_name` | string | yes | Short pack identifier (kebab-case). Used for `--pack=<name>` user override. Must match the filename stem (e.g., `copilot-builder` ↔ `copilot-builder-domain.md`). |
| `pack_version` | string | yes | Semantic version (`MAJOR.MINOR`). Increment MAJOR on breaking schema changes; MINOR on additive-only content updates. |
| `applies_to` | string | yes | Natural-language description of the target document pack. Surfaced in plan metadata. |
| `detection_patterns` | list[string] | yes | List of path globs (may be empty for fallback pack). Matched against the findings register's Affected Files set during Domain Detection Step 2. |
| `default_when_no_match` | boolean | yes | `true` iff this pack is the fallback when no other pack's `detection_patterns` match. Exactly one pack must set this to `true` (the generic pack). |

### Content-Specific Keys (implementation-planner-specific)

| Key | Type | Required | Description |
|---|---|---|---|
| `rt_types_supported` | list[RT-N] | yes | Subset of `[RT-1, RT-2, RT-3, RT-4, RT-5, RT-6, RT-7, RT-8]` applicable to this pack. RT types not listed are NOT valid classifications when planning against this pack. |
| `operator_profile_default` | string | yes | Calibration-context default operator profile (replaces the previously hardcoded "Senior TPM"). Loaded into the plan's `## Calibration Context` section at emission. |
| `severity_scale_native` | `"CS1..CS4"` \| `"CRITICAL..LOW"` | yes | Primary severity scale this pack's upstream build-reviewer emits. The planner normalizes per `SKILL.md § Severity Normalization` (D8 — accepts both). |
| `sequencing_rules_ref` | string (markdown anchor) | yes | In-pack section anchor that declares pack-specific sequencing rules (e.g., `#constitutional-first-sequencing`). Loaded at Sequencing step. |
| `batch_limits` | object | yes | `{max_records: N, max_files: N}`. Overrides the SKILL.md defaults (`max_records=5`, `max_files=3`). Pack-level overrides preserve pack-local sequencing semantics. |
| `principal_dimensions_included` | boolean | yes | Whether this pack's planner invocations emit the 3 Principal §4 sub-dimensions (reversibility classification, confidence levels, evidence labels). Matches the key name in build-reviewer's dimension packs for cross-skill audit. |

---

## Domain Detection Rules

The planner resolves **exactly one pack** at invocation time. Order of resolution:

1. **User override (wins).** If the invoking context passes `--pack=<pack_name>` (literal arg token, or the first `--pack=` match in the invocation prompt), load `reference/domain-packs/<pack_name>-domain.md`. If the named pack does not exist, halt with `PACK_NOT_FOUND: <pack_name>`.
2. **Path-pattern inferred.** If no `--pack` override, scan each pack's `detection_patterns` globs against the findings register's Affected Files set. The first pack whose patterns match any affected file is loaded. Ordering is deterministic: iterate packs in registry-table order above (copilot-builder → pmo-platform → generic).
3. **Default fallback.** If neither 1 nor 2 resolves to a non-generic pack, load `generic-document-pack-domain.md`. **Render the Fallback Banner** (below) at the top of the Implementation Register.

### Fallback Banner (verbatim text)

```markdown
_Generic pack used — no domain-specific pack matched the target. Consider authoring a pack for this domain if planning recurs._
```

This banner is mandatory for generic-pack invocations. Its absence is a plan-format defect.

---

## RT-Type Applicability Declaration

Each pack's frontmatter enumerates the RT types it supports. At classification time (SKILL.md `## Remediation Planning Process` Step 2), the planner consults the active pack's `rt_types_supported` list. RT types not listed are NOT valid classifications for findings in that pack's invocation.

Example:
- `copilot-builder` pack: `[RT-1, RT-2, RT-3, RT-4, RT-5, RT-6, RT-7, RT-8]` — all 8 RT types valid.
- `pmo-platform` pack: `[RT-1, RT-2, RT-3, RT-4, RT-5, RT-8]` — RT-6 / RT-7 not valid (no derived extract / manifest analog in pmo-platform by default).
- `generic` pack: `[RT-1, RT-2, RT-3, RT-4, RT-5, RT-8]` — same as pmo-platform. Operator may widen via `--rt-extensions=RT-6,RT-7` if the target pack has an extract/manifest analog.

---

## Authoring a New Pack

To add a pack for a new domain:

1. Copy `generic-document-pack-domain.md` as a template.
2. Assign a kebab-case `pack_name` matching the filename stem.
3. Populate frontmatter per the Shared Pack Schema above.
4. Author these required body sections:
   - `## Pack Input Expectations` — what the upstream build-reviewer findings register looks like for this pack.
   - `## Severity Scale Native` — map of this pack's native severity tokens (e.g., CS1..CS4 or CRITICAL..LOW) to their meaning.
   - `## <sequencing_rules_ref>` — the pack-specific sequencing rules section (the anchor name must match the `sequencing_rules_ref` frontmatter value).
   - Per-RT specifics for any RT types where the pack overrides the default behavior (commonly RT-6, RT-7).
   - `## Calibration Context` — the pack-level operator profile body.
5. Register the pack in this file's Pack Registry table above.
6. If the pack is not the fallback, set `default_when_no_match: false`. Exactly one pack (currently `generic`) sets it to `true`.

**Packs are authored, not generated.** Pack content encodes domain expertise; machine generation would drift from the authoring operator's calibration.

---

## Cross-Reference

- **Consumer skill:** [`../../SKILL.md`](../../SKILL.md) — loads a pack via Domain Detection, uses pack frontmatter throughout planning process.
- **Downstream contract:** [`../output-format-spec.md`](../output-format-spec.md) — Edit-ready output format consumed by [`release/references/how-to/implementation-execution-pattern.md`](../../../../references/how-to/implementation-execution-pattern.md) (the downstream reference workflow).
- **Schema mirror:** [`release/skills/build-reviewer/references/dimension-packs/README.md`](../../../build-reviewer/references/dimension-packs/README.md) — parallel structure for build-reviewer.
