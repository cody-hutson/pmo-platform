---
pack_name: generic
pack_version: 1.0
applies_to: "Any document pack without a domain-specific pack match"
detection_patterns: []
default_when_no_match: true
rt_types_supported: [RT-1, RT-2, RT-3, RT-4, RT-5, RT-8]
operator_profile_default: "Operator is responsible for confirming the execution toolchain (git, Edit tool, Bash). Plan assumes read-access to all files cited in the findings register and write-access to the target pack's working copy."
severity_scale_native: "CRITICAL..LOW"
sequencing_rules_ref: "#dependency-first-sequencing"
batch_limits: { max_records: 5, max_files: 3 }
principal_dimensions_included: false
---

# Implementation-Planner — Generic Document Pack Domain (v1.0)

This pack is the **fallback** when no domain-specific pack matches the findings register. It is selected by the planner at Domain Detection Step 3 (after user-override Step 1 and path-pattern Step 2 both fail to resolve to a non-generic pack).

Analog of `build-reviewer`'s `generic-document-pack-dimensions.md` — same fallback role in the sibling skill.

**Registry:** [`README.md`](README.md) — pack schema, domain-detection rules, fallback-banner spec.

---

## Fallback-Banner Enforcement

When this pack is selected by fallback (not by explicit `--pack=generic` user override), the implementation plan's Implementation Register MUST render the fallback banner at its top:

```markdown
_Generic pack used — no domain-specific pack matched the target. Consider authoring a pack for this domain if planning recurs._
```

**Mandatory.** Absence of this banner in a generic-pack-loaded plan is a format defect. Verification: `grep -q "^_Generic pack used" <plan-output-path>`.

---

## Pack Input Expectations

Input: findings register from any build-reviewer invocation that did not target a domain-specific pack. Register format is assumed to conform to the build-reviewer shared output contract (F-NNN finding IDs, severity, affected files, root cause, evidence, recommended resolution), though individual fields may be incomplete since no domain-specific validator enforced their presence.

The planner validates Source-file references during Step 1 per SKILL.md — missing or drifted references surface as `FINDING_NOT_CONFIRMED`.

---

## Severity Scale Native (CRITICAL..LOW)

The generic pack uses the CRITICAL..LOW scale by default (per review-discipline-principles.md Section 5 generalized scale). CS1..CS4 findings are accepted and normalized per `SKILL.md § Severity Normalization`, same as the pmo-platform pack.

| CRITICAL..LOW | CS Equivalent | Meaning |
|---|---|---|
| CRITICAL | CS4 | Would cause failure if unresolved |
| HIGH | CS3 | Materially degrades correctness or integrity |
| MEDIUM | CS2 | Noticeable defect with a workaround |
| LOW | CS1 | Cosmetic or low-impact drift |

---

## #dependency-first-sequencing (Sequencing Rules)

These rules apply when no pack-specific sequencing information is available from the target domain.

1. **Upstream before downstream (dependency-ordered).** If finding A's fix changes text that finding B's fix references, apply A first. The planner builds a dependency graph across RIs at Step 3.
2. **Schema before consumer.** Changes to structural or contract definitions apply before changes to files that consume those structures.
3. **Vocabulary before semantic.** Fixes to enum values, glossary entries, or naming conventions apply before fixes to logic that depends on those names.
4. **Independent parallelize.** Fixes to unrelated files with no shared dependency can land in the same batch.
5. **Extract / manifest operations (RT-6 / RT-7) not offered by default.** This pack's `rt_types_supported` excludes RT-6 and RT-7. If the target document pack has an extract/manifest analog, the operator specifies via `--rt-extensions=RT-6,RT-7` at invocation time, and the planner will attempt those classifications. If the extension is applied, the operator is responsible for supplying the regeneration/checksum scripts (the generic pack has no domain-specific fragments).

---

## Pack-Authoring Prompt

If this generic fallback is used repeatedly for the same target, author a domain-specific pack under `reference/domain-packs/<pack-name>-domain.md` with the frontmatter schema from [`README.md`](README.md). Use this file as the template — copy its structure, populate the frontmatter with domain-specific `detection_patterns` and `operator_profile_default`, author the pack-specific sequencing rules section (matching the `sequencing_rules_ref` anchor), and register the new pack in `README.md`'s Pack Registry.

**Indicator that pack authorship is warranted:** Generic pack used ≥3 times for findings registers whose Affected Files all fall under a common path prefix. The prefix is the signal that a domain exists and has not yet been formalized.

---

## Calibration Context (generic)

The operator is responsible for confirming the execution toolchain: git on a feature branch (not primary checkout), Claude Code Edit/Read/Bash tools available, findings-register read-access, target-pack files read/write-access. No pack-level assumptions about operator role, methodology familiarity, or target-pack history are made here — the plan is executable purely on the Edit-ready format and the operator's own toolchain.

The primary concern is: does the plan's RI-NNN set correctly close the findings, with `old_string` anchors that the Step 1 drift check confirms are present in the target files, and `new_string` replacements that the Step 3 write-verify confirms landed exactly as specified. Beyond that, the operator substitutes their own domain judgment where the generic pack's defaults don't fit — or, preferably, authors a domain-specific pack so those judgments become queryable.

---

## Pack Version Log

- **v1.0 (2026-04-19):** Initial authorship per the pluggable-domain Spec 4 Stage 5 design. Fallback pack; empty `detection_patterns`; `default_when_no_match: true`; fallback-banner mandatory.
