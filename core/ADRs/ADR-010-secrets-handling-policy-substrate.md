---
title: ADR-010 — Secrets-Handling Policy lives at core/standards/, not root SECURITY.md
status: Accepted
date: 2026-05-31
release: ""
deciders: "operator + Stage 5 solutioning"
tags: [architecture, security, policy-substrate, file-location]
source_observations:
  - Stage 5 spec for secrets-handling-policy substrate (4 options analyzed)
  - Existing root SECURITY.md is scoped to vulnerability reporting (GitHub convention)
  - Existing core/standards/ holds peer security-adjacent specs (subagent-security-posture.md, public-repo-gitignore-template.md, depersonalization-spec.md)
---

# ADR-010 — Secrets-Handling Policy substrate location

## Status

Accepted at Stage 5 solutioning for the secrets-handling substrate ticket. Implementation lands in the same release.

## Context

The release authoring an operational secrets-handling policy (categorization, storage matrix, gitignore policy, onboarding flow, rotation, failure modes, audit surface, public-flip implications) faces a placement decision. Four locations were considered:

| Option | Location | Rationale |
|---|---|---|
| **A** | `core/standards/secrets-handling-policy.md` (NEW) | Peers with existing security-adjacent specs; follows the "category-owner spec" pattern from `composition-surface-spec.md`; clear policy-substrate framing |
| **B** | Extend root `SECURITY.md` | One file for all security topics; visible to GitHub vuln-reporter UI |
| **C** | Split into 2 files: `core/standards/secrets-handling-policy.md` + `core/config/secrets-categories.md` | Separates policy declarations from categorization mechanics |
| **D** | `docs/SECURITY-OPERATIONS.md` | User-facing surface in `docs/` |

The existing root `SECURITY.md` is the GitHub-convention vulnerability-reporting file. It covers external vuln intake, response targets, and scope — content distinct from an internal operational policy. Conflating the two would bloat the GitHub-convention file with operational content that has nothing to do with vulnerability reporting.

The existing `core/standards/` directory holds 33 specs including `subagent-security-posture.md`, `public-repo-gitignore-template.md`, and `depersonalization-spec.md` — all security-adjacent peers. The `composition-surface-spec.md` pattern (category-owner spec referenced from multiple consumers) is the closest precedent for a policy substrate of this shape.

## Decision

**The secrets-handling policy lives at `core/standards/secrets-handling-policy.md` as a single file** (Option A).

Cross-references are added to:

1. Root `SECURITY.md` — link to the new policy under "Defenses Currently in Place" so external vulnerability reporters can discover the operational layer
2. `core/rules/bypass-mode-readiness.md` — cross-reference in "Related" so the runtime-enforcement layer points up to the policy declaration

The following candidate edits were **declined**:

| Candidate | Why declined |
|---|---|
| `core/governance/OPERATIONS.md` "policy catalog" entry | The file is a PMO project-management operations manual, not a policy catalog. Adding a Policy Catalog section would be a structural addition outside the file's scope. Discoverability via L1+L2 cross-references is sufficient. |
| `core/standards/README.md` index entry | The README explicitly states "Standards are referenced by governing docs and skills — not enumerated here, to avoid duplicate-source drift." Adding an entry would violate the file's stated convention. |

## Consequences

### Positive

- **Locality of reasoning**: the policy substrate sits with its security-adjacent peers; future readers find it without having to know it's somewhere "in the root."
- **Single source of truth**: one file, eight sections, no fragmentation. Future amendments edit one place.
- **Composes cleanly**: the policy declares categories and locations; runtime enforcement (`bypass-mode-readiness.md`) and gitignore baseline (`public-repo-gitignore-template.md`) compose with it without restating its content.
- **GitHub-convention preserved**: root `SECURITY.md` stays focused on vulnerability reporting — the file that external researchers look for stays small and easy to act on.

### Negative

- **Discoverability friction for first-time onboarders**: new operators see root `SECURITY.md` first; they have to follow the link to find the operational policy. Mitigation: the link is in the "Defenses Currently in Place" table, which is the natural read path for anyone learning the security posture.
- **Cross-reference fan-out**: the policy is referenced from at least 4 places (root SECURITY.md, bypass-mode-readiness.md, this ADR, and future Stage 6 setup-workspace.sh integration). Each cross-reference must be maintained on file moves. Mitigation: the `composes_with:` frontmatter declares the relationships explicitly.

### Neutral

- **Out-of-scope by design**: the substrate doc declares the onboarding flow (§4) but the setup-workspace.sh implementation lands in a follow-up. This is a deliberate scope split — the substrate is what the pre-flip security audit consumes; the implementation is what the operator runs.

## Reversibility

CHEAP / Confidence HIGH. The policy file can be relocated by moving it and updating the ≤4 cross-references. The `composes_with:` frontmatter explicitly tracks the relationships so the move is mechanical.

## Related ADRs

- `core/standards/secrets-handling-policy.md` — the substrate this ADR codifies
- `core/standards/composition-surface-spec.md` — precedent pattern for "category-owner spec" placement at `core/standards/`
- `core/standards/subagent-security-posture.md` — security-adjacent peer at `core/standards/`
- Root `SECURITY.md` — vulnerability-reporting layer above the policy substrate
