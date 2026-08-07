<!-- reference-durability: allow-link -->
# Dimension Packs — Pack Registry and Schema

> **Why this file carries a link-class override.** This document is a registry: every
> row in the Pack Registry table resolves a pack name to its file, and the link *is*
> the registration. Summarizing the target inline — the usual durability remedy —
> would delete the mapping the table exists to carry. The links are intra-directory
> and sibling-relative, so they survive a repository move as a unit.

Build-reviewer loads exactly one **dimension pack** at invocation time. Each pack supplies the review dimensions for a specific domain. Shared review discipline (anti-laziness rules, root-cause requirement, 6-deliverable output structure, reviewer calibration, anti-patterns for reviewers themselves) lives in [`core/disciplines/review-discipline-principles.md`](../../../../../core/disciplines/review-discipline-principles.md) and governs every review regardless of pack.

This document is the **pack registry** and the **shared pack schema**. New packs are added by creating a `<pack-name>-dimensions.md` file in this directory and registering it below.

---

## Pack Registry

| Pack Name | File | Applies To | Dimension Count | Principal Dimensions |
|---|---|---|---|---|
| `copilot-builder` | [`copilot-builder-dimensions.md`](copilot-builder-dimensions.md) | Copilot Builder Agent Document Pack (30 documents + 1 derived artifact) | 12 | inherited from SKILL.md `## Principal Dimensions` |
| `pmo-platform` | [`pmo-platform-dimensions.md`](pmo-platform-dimensions.md) | PMO platform production-readiness review (skills, governance files, reference docs, pipeline stages, suite contracts) | 12 | inherited from SKILL.md `## Principal Dimensions` |
| `security` | [`security-dimensions.md`](security-dimensions.md) | Review-time AppSec/SecOps review of a platform surface (security controls, hooks, CI security jobs, dependency + secret posture); organized by area — 3 areas, 4+2+2 hierarchy | 8 | inherited from SKILL.md `## Principal Dimensions` |
| `generic` | [`generic-document-pack-dimensions.md`](generic-document-pack-dimensions.md) | Any document pack without a domain-specific pack match (default fallback) | 7 | inherited from SKILL.md `## Principal Dimensions` |

**How to read the table:**
- **Pack Name** — identifier used when a caller passes `--pack=<name>` explicitly.
- **File** — pack file in this directory. Must exist and must carry the pack schema.
- **Applies To** — human-readable summary of the pack's target domain. Authoritative match is via `detection_patterns` in the pack frontmatter.
- **Dimension Count** — how many pack-specific dimensions the pack carries.
- **Principal Dimensions** — whether the pack itself includes the 3 Principal-level dimensions (`Operational Awareness`, `Organizational Leverage`, `Mentorship & Culture`) or inherits them from the SKILL.md `## Principal Dimensions` section. Every review gets Principal Dimensions exactly once; packs declare whether they duplicate them or rely on the skill-level section.

---

## Shared Pack Schema (YAML Frontmatter Contract)

Every pack file in this directory begins with YAML frontmatter containing exactly these keys:

```yaml
---
pack_name: <string>            # Unique identifier (kebab-case). Must match filename stem (e.g., "copilot-builder" for copilot-builder-dimensions.md).
pack_version: <string>         # Semantic version (e.g., "1.0").
applies_to: <string>           # One-line human-readable summary of the pack's target domain.
detection_patterns:            # List of bash-compatible glob patterns for path-pattern inference. Empty list ([]) means the pack never auto-matches (fallback-only).
  - "<glob-pattern-1>"
  - "<glob-pattern-2>"
default_when_no_match: <bool>  # true if this pack is the default fallback (exactly one pack may be true across the registry).
dimension_count: <int>         # Number of pack-specific dimensions defined below (excluding Principal Dimensions if inherited).
principal_dimensions_included: <bool>  # true if the pack file itself carries the 3 Principal Dimensions (duplicating SKILL.md); false if it relies on SKILL.md to supply them.
---
```

**Schema enforcement:**
- Exactly one pack in the registry has `default_when_no_match: true`. The `generic` pack holds this slot today.
- `detection_patterns` for the default-fallback pack is `[]` (the empty list) — the pack never matches by pattern; it is selected only when no other pack matches.
- `pack_name` is kebab-case, matches the filename stem, and is globally unique across the registry.
- `principal_dimensions_included: false` means the pack delegates Principal Dimensions to SKILL.md. Either rendering path produces Principal Dimensions exactly once in the output — duplication is a finding.

---

## Shared Dimension-Block Schema (Markdown Body Contract)

After the frontmatter, each pack renders its dimensions as `###`-level subsections under a top-level section (typically `## Review Dimensions`).

**Heading-level flexibility (hierarchical packs):** Packs that organize dimensions into logical groups (e.g., areas, phases, categories) may use `###` for the grouping heading and `####` for the dimensions under each group. The `pmo-platform` pack is the canonical example — dimensions organized into 4 areas of 3 dimensions each. When a pack uses hierarchical grouping, its Pack Registry row should note the grouping convention (e.g., "organized by area" or "4×3 hierarchy") so downstream tooling understands the nesting depth. The shared frontmatter schema is unchanged; only the body heading levels vary.

Each dimension block has:

```markdown
### Dimension <N> — <Name>

- **What to check:**
  - <specific check bullet 1>
  - <specific check bullet 2>
  - …

- **Specific areas of known risk:** (optional — include when the domain has concentrated risk zones)
  - <known-risk bullet 1>
  - <known-risk bullet 2>
  - …

- **Root-cause requirement:** <one-sentence directive naming what the finding's root cause must trace>
```

**Header conventions:**
- Dimension numbering is per-pack. Pack authors choose their own numbering scheme (e.g., Copilot pack uses `Dimension 1`, PMO pack uses `PMO-D1`, generic pack uses `GEN-D1`) — numbering drives traceability into the findings register, so consistency within a pack is required.
- `**What to check:**` and `**Root-cause requirement:**` are mandatory per block. `**Specific areas of known risk:**` is optional; include when the domain concentrates risk at known surfaces.
- The root-cause requirement is not a restatement of Section 2 of `review-discipline-principles.md` — it is a pack-specific directive that tells the reviewer what kind of root cause the dimension demands (e.g., "trace missing reference to the renaming release" vs. "identify whether remediation was attempted and failed").

---

## Domain Detection Rules

At invocation time, build-reviewer selects exactly one pack via this priority order:

1. **User-specified (wins unconditionally):** If the invoking context passes a pack name (e.g., `--pack=pmo-platform`, or an explicit `pack_name` argument), load that pack. User override wins over any other signal. If the named pack does not exist in the registry, the skill fails fast with a registry-miss error.
2. **Path-pattern inferred (first-match):** If no pack is user-specified, scan each registered pack's `detection_patterns` against the target paths. Load the **first pack whose patterns match any target path**. Scan order is registry order (top-to-bottom in the table above). A target path matches a pack if any path in the review's scope matches any glob in that pack's `detection_patterns`.
3. **Default fallback:** If neither user-specified nor path-pattern resolves, load the pack whose `default_when_no_match: true` is set (today: `generic`).

**Known shadowing — auto-detection is effectively unavailable to the `security` pack for a whole-surface security review.** The `pmo-platform` pack carries `**/core/**`, which subsumes the `security` pack's `**/core/security/**` and `**/core/hooks/**` and sits earlier in scan order, so a target under those two trees resolves to `pmo-platform` by first-match. The `security` pack's other two patterns — the security workflow file and the secret-scanner config — are themselves unshadowed, but *pattern* is the wrong granularity to reason at: **first-match is evaluated against the whole target set, not pattern by pattern.** Those two patterns select `security` only when the scope contains **no** path under `**/core/**`, `**/release/skills/**`, `**/core/governance/**`, or `CLAUDE.md`. The platform's security surface is principally `core/hooks/` and `core/security/`, so the realistic whole-surface case — hooks *plus* the security workflow *plus* the secret-scanner config — resolves to `pmo-platform`, not `security`. Stated plainly: auto-detection reaches the `security` pack only for a narrow scope that excludes `core/`, and any review whose target set includes even one hook file will not reach it. **For a security review, pass `--pack=security`.**

**Not reordering remains the correct call.** Promoting `security` above `pmo-platform` would send a broad platform review to the security pack whenever its target set happens to include a hook file, which is the worse failure — and the actual fix is to narrow `**/core/**`, which is that pack's own decision. Explicit selection (`--pack=security`) is genuinely unaffected: user-specified selection wins unconditionally at step 1, and it is the invocation path the skill's security triggers name.

**Fallback indicator rule:** When the `generic` pack is loaded via fallback (step 3), the review output MUST render a visible banner at the top of the findings register:

> *Generic pack used — no domain-specific pack matched the target. Consider authoring a pack for this domain if reviews recur.*

Fallback is auditable — the operator sees when a domain lacks a pack and can decide whether to author one. When the `generic` pack is selected explicitly by user override (step 1) or because a detection pattern matched, the banner is omitted — the pack was chosen intentionally.

---

## Adding a New Pack

To register a new pack:

1. Create `<pack-name>-dimensions.md` in this directory with the shared frontmatter schema above.
2. Author the dimensions using the shared dimension-block schema.
3. Add a row to the Pack Registry table above (correct dimension count, Principal Dimensions disposition).
4. Verify that `default_when_no_match: true` remains unique (only one pack may hold it).
5. Verify `detection_patterns` do not collide in a way that creates ambiguous first-match ordering. When a collision exists there are **three** remedies, in order of preference: (a) order packs in the registry so the more-specific pack appears first; (b) tighten the patterns; or (c) when both (a) and (b) would produce a *worse* routing outcome than the collision itself, **record the shadowing** in § Domain Detection — state the reasoning, name which scopes still auto-select and which do not, and confirm explicit `--pack=` selection is unaffected. Option (c) is a real remedy and has been exercised: the `security` pack is shadowed by `pmo-platform`'s `**/core/**`, and reordering would misroute every broad platform review whose target set happens to include a hook file. It is legitimate only when the reasoning **and** the residual are both written down — an unrecorded collision is a defect, not a decision.
6. Author at least one eval case per new pack exercising the detection, dimension rendering, and Principal-Dimensions composition paths.

---

## Cross-Skill Coordination

The pack-schema frontmatter keys (`pack_name`, `pack_version`, `applies_to`, `detection_patterns`, `default_when_no_match`) are **shared common keys** with implementation-planner's domain packs (per the Stage 5 schema-alignment design). Build-reviewer packs additionally carry `dimension_count` and `principal_dimensions_included`; implementation-planner packs carry content-specific keys appropriate to their own domain. Shared common keys preserve cross-skill user expectations and permit future registry tooling.

Cross-spoke structural consistency is validated at Collective Review (Stage 5→6) — divergence on common keys requires documented rationale.
