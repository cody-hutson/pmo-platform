---
version: vX.Y
date: 2026-05-24
type: note
issues: [""]
pr: ""
links:
  plan: pmo-platform/releases/plans/vX.Y_RELEASE_PLAN.md
  log_anchor: "#vX-Y-synthetic-fail-fixture"
reversibility-tier: CHEAP
themes: ["cluster:test-fixture"]
summary: "Synthetic counter-example designed to fail 5 of the 12 lint checks (L4, L7, L10, L11, L12)."
requires_action: false
breaking: false
components: ["test-fixture"]
followups: []
---

# Synthetic fixture demonstrating eval rubric FAIL cases

2026-05-24 · vX.Y

This fixture is designed to fail five specific lint checks so that the eval rubric can prove its FAIL-case behavior on a controlled input. It deliberately violates the summary-length rule, the vague-filler rule, the banned-jargon rule, the why-it-matters-beat rule, and the file-path-purity rule. Each violation is annotated below so a reader can audit which check the bullet exercises.

## What changed for everyone using the platform

- **Various improvements.** This bullet matches the §2.6 specificity-rule anti-pattern verbatim and should trigger L7 FAIL.
- **Reflexive-pipeline self-exemption clauses now ship with every release.** The phrase "reflexive-pipeline self-exemption" is a §2.4 banned-jargon term and should trigger L10 FAIL.
- **The new mode lives in pmo-platform/skills/foo/SKILL.md and replaces the legacy mode.** The raw path `pmo-platform/skills/foo/SKILL.md` outside markdown-link parentheses should trigger L12 FAIL.
- **A new capability is available now.** This bullet has no `*Why it matters:*` beat and no `<!-- impact:foundational -->` escape comment, so it should trigger L11 FAIL.

## Known limits

- This fixture is a test fixture only — do not consume as a real release note.

Report issues at https://github.com/[OPERATOR_GITHUB]/pmo-platform/issues with the `cluster: test-fixture` label.

## Reversibility

CHEAP / HIGH confidence. Delete the fixture file; no platform behavior depends on it.

---

### Operator and engineering detail

**Fixture provenance** — Authored at Stage 6 Engineering for AC#2 verification. The fixture deliberately exercises the FAIL paths of L4, L7, L10, L11, L12 so that invoking the eval rubric against this fixture produces 5 FAILs with named checks. The PASS reference is a structurally well-formed release note.

**Expected rubric output** — invoking the rubric on this fixture should emit `FAIL (7/12)` with per-check rationales naming L4, L7, L10, L11, L12 as the failing checks. L1, L2, L3, L5, L6, L8, L9 PASS by construction (the fixture is structurally well-formed except where the FAIL cases require violation).

For full implementation detail see the [release-notes-eval-rubric.md](../../references/release-notes-eval-rubric.md) Worked Examples section.

### References

- Establishing issue: AC#2
- Rubric: [release-notes-eval-rubric.md](../../references/release-notes-eval-rubric.md)
- PASS reference: a well-formed release note
