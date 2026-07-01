<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
---
title: "ADR-062 — Substrate-vs-canonical precedent: a canonical-spec edit wins over a substrate-body mutation for issues that cite substrate-level affected files"
status: Accepted
date: 2026-07-01
release: 67-spoke-execution-safety
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Decision) + operator at the Collective Review scope-lock"
tags: [release-ops, stage-5, solutioning, scope-assessment, canonical-surface, substrate-citation, cross-repo-citation-translation, issue-body-historical-record, precedent]
source_observations:
  - "Originating gap: the decision that a canonical-spec edit wins over a substrate (issue-body) mutation was APPLIED ONCE — the v1.02-triage-and-related release resolved an R6 D-decision as an Option-A canonical edit on stage-02-triage.md rather than a gh-issue-edit on the cross-repo-cited substrate — but the GENERALIZED, queryable rule for all future Stage-5 spokes was never codified. No ADR recorded the decision (ADR-021 was later claimed by unrelated liveness-oracle work; the next-free slot is now 062), and no Stage-5 spec carried the cross-repo-citation-translation discipline."
  - "Staleness reconciliation (Mode R readiness, 2026-07-01, baseline v3.41): the original ticket body named ADR-021 as free; ADR-021 now exists (liveness-oracle-selection) and the ADR space runs through ADR-061, so the next-free number resolved to ADR-062 across BOTH core/ADRs/ and release/ADRs/, confirmed contiguous by check-adr-numbers.py at the authoring commit."
  - "Cross-repo-citation surface: an issue may cite an affected file by a SUBSTRATE path (a cross-repo `originally #NNN` migration artifact from the public-flip, or a raw body-level path) rather than by the file's CANONICAL governed home. A Stage-5 spoke that mutates the substrate citation rather than the canonical spec leaves the durable corpus unchanged and the fix invisible to every downstream reader."
---

# ADR-062 — Substrate-vs-canonical precedent (canonical-spec edit wins; substrate body preserved)

## Status

Accepted — operator-ratified at this release's Collective Review scope-lock (the Status-enum gate the release-ADR README names: "Operator-ratified at Collective Review or equivalent gate"). Authored at Stage 6 per the Stage-6 ADR-authoring precedent established by the core-module-boundary ADR and followed by the operations-consume-via-public-api / memory-corpus-SSOT / methodology-conditional-activation ADRs.

Numbered as the next-free slot across `core/ADRs/` and `release/ADRs/`, resolved at the authoring commit with the platform-wide gap-free / unique check (`release/tools/check-adr-numbers.py`, the `adr-number-integrity` CI job) as the backstop. The ADR is referenced downstream **by slug**, never by its number — the number is an authoring-time assignment, not a stable cross-reference handle.

This decision is extended or reversed only by a **successor / superseding ADR** (Nygard `Superseded` / `Deprecated`, citing the successor) — never by an in-place edit of this record.

## Context

A work item declares its **affected files**. Two distinct kinds of file reference can appear:

1. A **canonical** reference — the file's governed home in the tracked corpus (e.g., a pipeline spec under `release/references/pipeline/`, a standard under `core/standards/`, a rule under `core/rules/`).
2. A **substrate** reference — a lower-level or migration-artifact pointer that is not the canonical governed home. Two substrate shapes recur:
   - a **cross-repo citation** — an `originally #NNN` marker left by the public-flip migration, where the local `#NNN` may or may not resolve to a live issue in this repository (the number was meaningful in the pre-flip source, and survives as provenance, not as an actionable in-repo reference);
   - a **body-level raw path** — a path named in the issue body prose that points at where the content is *observed*, not at the canonical surface that *governs* it.

When a Stage-5 spoke resolves a design decision whose remediation touches such a file, it faces a fork: edit the **canonical spec** (the governed home) or mutate the **substrate** (the issue body / the cited artifact). The decision was made once, in the applied precedent, but never generalized: the applied release edited the canonical triage spec rather than issuing a `gh issue edit` on the cross-repo-cited substrate. Absent a durable rule, a future spoke can plausibly do the opposite — patch the substrate citation, leave the canonical spec stale — and the fix becomes invisible to every downstream consumer that reads the governed corpus rather than the issue body.

Two things were missing:

1. **A durable precedent** — no ADR recorded "canonical wins over substrate" as a queryable decision, so it could not be cited, enforced, or reasoned about at scope-assessment time.
2. **A scope-assessment discipline** — the Stage-5 A1 scope-assessment surface did not require a spoke to *enumerate the canonical surface* for each affected file, nor to *translate* a cross-repo `originally #NNN` citation into its canonical in-repo home before designing the change.

## Decision

**A canonical-spec edit WINS over a substrate-body mutation.** When a work item cites a substrate-level affected file, the Stage-5 spoke resolves the change at the file's **canonical governed home**, not by mutating the substrate citation. Concretely:

1. **Canonical-surface precedence.** For any affected file, the remediation target is the canonical governed home in the tracked corpus. A substrate reference (a cross-repo `originally #NNN` marker, or a body-level raw path) is a *pointer to be translated*, not a *surface to be edited*.
2. **Issue bodies remain historical-record.** An issue body is a point-in-time intake artifact. A spoke does NOT rewrite the body to "fix" a stale or substrate-level citation; the body stays as authored (historical record), and the corrected understanding lives in the canonical spec + the Stage-5 output. This composes with the body-is-directional-not-authoritative posture: the body is directional; the canonical corpus is authoritative.
3. **Cross-repo-citation translation is a scope-assessment step.** At Stage-5 A1 scope-assessment, the spoke enumerates the canonical surface for each affected file and translates every `originally #NNN` / substrate citation into its canonical in-repo home before designing the change. The translation is recorded in the Stage-5 output so the Engineering spoke edits the canonical surface by construction. (The executable discipline lives in the Stage-5 spec as **Phase A1.5**, which this ADR records the decision for; the ADR states the *rule*, the spec carries the *procedure*.)

**Scope-of-precedent (reflexive cutover).** This precedent applies to releases entering Stage 5 strictly AFTER the introducing release's merge SHA (recorded in the operator-instance release log). **The introducing release — this milestone — is itself exempt** (reflexive-pipeline-loop discipline: the rule cannot fire on the release that ships it without creating a self-reference loop). All releases that entered Stage 5 before the introducing release are also exempt. The one prior application (the v1.02-triage canonical edit) stands as the pre-codification precedent that motivated the generalization, not as a release governed by this ADR.

## Alternatives Considered

- **(A) Codify the rule as substrate-mutation-wins (patch the citation, defer the canonical edit) — REJECTED.** This inverts the applied precedent and defeats the purpose: a corrected substrate citation is invisible to every downstream reader of the governed corpus, and the canonical spec silently rots. The whole value of the decision is that the durable corpus, not the intake artifact, carries the truth.

- **(B) Rewrite the issue body to fix stale / substrate citations — REJECTED.** Treating the body as a mutable source-of-truth contradicts the body-is-historical-record posture and the body-is-directional-not-authoritative rule. It also creates a second SSOT (body vs canonical spec) that can diverge — exactly the duplicate-source failure the corpus disciplines exist to prevent.

- **(C) Leave the decision as un-generalized applied precedent (status quo) — REJECTED.** One applied instance in one release plan is not a queryable rule. A future Stage-5 spoke has no durable surface to cite, so the decision is re-litigated (or contradicted) every time the fork appears. An ADR + a Stage-5 procedure step is the minimal durable form.

- **The selected approach** — record the decision as an ADR + wire the translation discipline into Stage-5 A1 scope-assessment as Phase A1.5 — is the minimal-blast-radius codification: it is additive prose (a new ADR record + one new phase block in an existing spec), `git revert`-able with no data migration, and it re-uses the existing Stage-5 A1 surface rather than introducing a new gate.

## Consequences

**Positive:**
- The substrate-vs-canonical fork becomes a **decided, queryable rule** — a Stage-5 spoke cites this ADR instead of re-deriving the call, and the design-review checklist can confirm the canonical surface was enumerated.
- **The durable corpus stays authoritative** — fixes land where downstream readers look (the governed home), not in an intake artifact they never read.
- **Cross-repo `originally #NNN` citations stop misdirecting edits** — the A1.5 translation step converts a migration-artifact pointer into a canonical home before design, so the Engineering spoke edits the right file by construction.
- **Composes cleanly** with the substrate-drift-disposition chip (which defers its drift disposition to this canonical-surface precedent) and with the body-is-directional-not-authoritative posture.

**Negative / costs:**
- A new scope-assessment obligation (Phase A1.5 canonical-surface enumeration + citation translation) rides every activated Stage-5 spoke — bounded, because it fires only when Solutioning is activated and only adds an enumeration the spoke already needs to design correctly.
- A cross-repo `originally #NNN` whose canonical home is genuinely ambiguous requires a judgment call at A1.5; the discipline records the translation and its basis rather than hiding the ambiguity.

## Reversibility

**CHEAP / Confidence HIGH** — the change is a new ADR record plus one additive phase block in an existing Stage-5 spec plus a README index line. No routing primitive, schema, or executable is touched. A `git revert` of the single release PR restores the prior state with no data migration. The reflexive-cutover clause means no prior release is retroactively bound, so there is no back-fill to undo.

## Related ADRs

- **ADR-016** (intake front door as a distinct architectural component) — establishes that intake authors a typed work item and does not author ADRs; this ADR governs how a *downstream* Stage-5 spoke treats the substrate citations that intake recorded.
- **ADR-043** (staleness-confidence canonical representation) — sibling discipline on how stale-vs-current is represented; this ADR governs *where the fix lands* once a substrate citation is found stale, ADR-043 governs *how staleness is labeled*.
- The Stage-5 procedure that carries this decision is **Phase A1.5** in `release/references/pipeline/stage-05-solutioning.md` (canonical-surface enumeration + cross-repo `originally #NNN` translation), wired into the A1 design-scope-assessment surface.

### Issue References
Originating ADR-class deliverable: #307 (milestone `67-spoke-execution-safety`, epic #1190). Composes with: #47 (substrate-drift disposition defers to this canonical-surface precedent) and #497 (issue body is directional, not authoritative). Pre-codification applied precedent: the v1.02-triage-and-related release (canonical edit on the triage spec rather than a substrate `gh issue edit`).
