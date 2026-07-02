---
version: domain-aware-stage5-design
date: 2026-06-07
type: note
issues: ["#1", "#345", "#346"]
pr: "#503"
links:
  plan: release/releases/plans/domain-aware-stage5-design_RELEASE_PLAN.md
  log_anchor: "#deployment-log-domain-aware-stage5-design"
reversibility-tier: CHEAP
themes: ["cluster:pipeline-definitions", "cluster:knowledge-architecture"]
summary: "Stage 5/7 design is now domain-aware: a governed explore-then-narrow step, per-domain best-practice guides, a domain-fit impact-analysis selector, and a domain-practice review criterion. Version-less release (no vX.Y, no tag, no GitHub Release)."
requires_action: false
breaking: false
components: ["design-exploration.md", "core/standards/domain-best-practices/", "stage-05-solutioning.md", "stage-07-dev-testing.md", "design-review-checklist.md"]
followups: ["#504", "#505"]
---

# Stage 5/7 design is now domain-aware, not markdown-bound

2026-06-07 · domain-aware-stage5-design (version-less)

Design work in the pipeline no longer assumes every deliverable is a pmo-platform markdown file. Stage 5 now runs a governed "generate options, then narrow" step before the trade-off matrix, picks an impact-analysis method that fits the work's domain, checks the design against the right body of best-practice for that domain, and ships with the first two per-domain guides (software and governance).

> **Skip the rest** unless you author or review designs through the release pipeline (Stage 5 Solutioning / Stage 7 Dev Testing).

## Who this affects

- Anyone authoring a design at Stage 5 Solutioning or reviewing one at Stage 7 Dev Testing — the pipeline now classifies the deliverable's domain and adapts the design protocol, the impact-analysis method, and the review criteria to it.

## What changed for everyone using the platform

### Added

- **Design starts with a real "generate options, then narrow" step.** Stage 5 design now runs a short governed exploration — generate candidate approaches, eliminate the weak ones with stated reasons, then score the survivors on the trade-off matrix — before the trade-off matrix that used to be the starting point. *Why it matters:* the long-standing "consider at least three alternatives" expectation is now backed by an actual generation step, so alternatives are explored rather than asserted after one approach was already picked.
- **The first per-domain best-practice guides — software and governance.** Two domain guides land, each stating where its practices apply and where they do not, so a design can be checked against the right body of practice for the kind of work it is. *Why it matters:* design guidance is no longer one-size-fits-all — software work is measured against software practice and governance work against governance practice, instead of both against generic platform conventions.
- **A domain-best-practice review criterion, with an honest "not assessed" flag.** The design-review checklist and the Stage 7 review now assess a design against its target domain's authoritative practice, and mark the work explicitly "not assessed" when no guide exists yet rather than passing it silently. *Why it matters:* a design that ignores its domain's established practice gets caught in review, and a missing guide is surfaced as a visible gap instead of an invisible pass.

### Changed

- **Impact analysis is chosen to fit the work's domain.** Stage 5 now selects the impact-analysis method by domain: the existing markdown dependency scan stays the default for documentation and governance work, while code, component, and solution-graph domains can use a fan-out method suited to them, with a documented opt-out when no instrument fits. *Why it matters:* impact analysis on non-documentation work is no longer forced through a markdown-tree scan that does not describe it.

## Known limits

- **The code-domain fan-out tool is specified, not built yet.** This release admits a non-markdown impact-analysis method for code/component/solution domains at the specification level; the executable fan-out instrument that performs it is a separate follow-up ([#505](https://github.com/cody-hutson/pmo-platform/issues/505)).
- **Two seed guides for now.** Only the software and governance domain guides ship in this release; other domains (web, data, enterprise-platform, hardware) are named in the domain classification but do not yet have their own guides, and a design in those domains will carry the honest "not assessed" flag until a guide exists.
- **Version-less by design.** No `vX.Y` is assigned and no git tag or GitHub Release is cut for this release; it ships under the slug `domain-aware-stage5-design`. The release-tracking corpus carries the slug in place of a version and the Tag column is `(none)`.

Report issues at https://github.com/cody-hutson/pmo-platform/issues.

## Reversibility

CHEAP / HIGH confidence. The release is purely additive — two new reference docs, two new domain guides, and additive wiring into the Stage 5/7 specs, the design-review checklist, and the framework catalog. The new protocols carry an introducing-release-exempt clause, so reverting affects only forward releases. Reverting the release pull request (`git revert -m 1` the merge commit) removes the additions cleanly; no schema migration and no skill deploy-state change. Standard rollback window.

---

### Operator and engineering detail

**The keystone substrate (`domain:` class field)** — the foundational, build-first commit adds a `domain:` class field to the `domain_practice` provenance label in `stage-04-planning.md` §5.7, populated across Mode A, Mode B, and the pipeline-internal exemption, so every mode carries a domain class. It adds A3-time deliverable-domain classification — the Planning/Solutioning spoke classifies the deliverable's domain from the File-Change-Matrix — and reconciles the "already-encoded" exemption to reference the new domain guides (the "sourcing-exempt ≠ classification-exempt" two-property reconciliation). All three issues consume this single field; the N-way "how is the domain signaled" check (the §5.7 `domain:` field ↔ the #345 selector ↔ the #346 criterion) reads one consistently-classified field across all three consumers.

**The design-exploration protocol (#1)** — a new Stage-5 Phase-A4 micro-protocol at `release/references/standards/design-exploration.md` inserting divergent generation → convergent narrowing before the trade-off matrix (the de-facto entry point today), closing the gap that the design-review checklist demanded "≥3 alternatives" with no governed generation step. Eight sections including an AC5 worked example showing all three steps end-to-end and a Tier-A process-flow §7 declaration; the protocol carries the reflexive introducing-release-exempt cutover clause in §8 so it does not fire on its own introducing release.

**The domain best-practice guides (#1)** — `core/standards/domain-best-practices/software.md` and `governance.md`, Applicability-Profile-bearing K1 guides governed by the four shipped corpus protocols (corpus-curation / framework-corpus-discipline + framework-catalog / applicability-framework / knowledge-architecture + km-protocols). Each carries the full §2 Applicability Profile (UNIVERSALITY / APPLIES-WHEN / CONTRAINDICATED-WHEN / EVIDENCE-TIER / RESOLUTION-ON-CONFLICT) and the §5 rubric demonstrated in-doc. The software guide sources GoF / ADR-Nygard / Fowler with the mandatory ET5 paired contraindication on the Fowler/YAGNI entry; the governance guide sources PMBOK7 / PRINCE2 / Nonaka SECI / Diátaxis with the ET3 paired applicability note on Diátaxis. Both guide frameworks are registered in `core/specs/framework-catalog.md` (3 EXTERNAL source rows + 2 INTERNAL guide rows; both guides carry a `framework_version_anchor:` for machine-checkability).

**The domain-aware impact-analysis selector (#345)** — a new Phase A3.1 in `stage-05-solutioning.md` admits a non-markdown impact-analysis method or a documented opt-out, with the markdown `blast-radius.sh` tree-fan-out preserved as the DEFAULT (an additive 16-insertion / 0-deletion edit; the A3 mandate line is byte-identical between main and the branch). The code-domain method has a grep-reproducible worked example in `blast-radius-protocol.md` §12 (an import-graph fan-out on a real symbol; the first-order grep is designated the reproducibility contract and reproduces exactly against the branch tree). The `design-review-checklist.md` Section 1 is augmented in place to admit non-markdown methods while preserving the markdown DEFAULT. The selector reads the class already classified at Planning A3 — it does not re-derive the domain signal or read PROJECT.md. The executable code-fan-out instrument is deferred to a follow-up ([#505](https://github.com/cody-hutson/pmo-platform/issues/505)); this release admits it at the spec level only.

**The domain-best-practice review criterion (#346)** — `design-review-checklist.md` check 4.6 (domain-best-practice conformance, assessed against the target domain's authoritative practice and citing the external guides + `applicability-framework.md` §2/§3/§4, not the internal-convention checks 4.1/4.2) and a `stage-07-dev-testing.md` Phase C conditional domain-practice conformance dimension with a `DOMAIN-PRACTICE-NOT-ASSESSED` Note-severity honest flag. It is a genuine wiring of `applicability-framework.md`, not a re-implemented engine. The implementation is stronger than the Stage-5 design proposed: per adversarial review it dropped the governance exemption short-circuit, so a governance deliverable now runs the FULL applicability walk against `governance.md` and PASSes by assessment rather than by bypass (the `N/A — pipeline-internal release` token is scoped to Phase A provenance only — provenance ≠ conformance). The Phase C dimension count was cascade-fixed to "5 always-on scored dimensions + 1 conditional" with zero stale "5 scored dimensions" references.

**Reflexivity** — this release is itself a pipeline-internal / governance deliverable whose subject is the domain-best-practice machinery, so it self-demonstrates the substrate it builds. Its own release-plan `domain_practice` label carries the canonical pipeline-internal-exempt form WITH the new in-label `domain: governance` field. The introducing release is classified `domain: governance`, takes the markdown-tree DEFAULT impact-analysis row, and is cutover-exempt from the new Stage-5 protocol — so the new machinery does not fire on its own introducing release.

**Process note** — single-branch (D-C SINGLE) via one release PR (#503; 14 commits · 11 files · +648/−17), Release Class `novel`, version-less per operator decision at Stage 4 following the `intake-elicitation-skill` and `public-flip-install-blockers` precedents. Stage 7 Dev Testing PASS (3/3 issues) caught and fixed two real defects across two iterations — the F-1 release-plan exemplar mismatch and a §12 fabricated worked example, both verified after fix. Stage 8 QA PASS — #1 6/6 ACs (#490), #345 3/3 (#491), #346 3/3 (#492); zero FAIL, zero conditional-pass. Stage 9 Plan Review GO (operator-rendered; Deep depth) with hub Empirical Verification 8/8. No signed-annotated tag and no GitHub Release (version-less).

For full implementation detail see the [RELEASE_LOG.md entry](../RELEASE_LOG.md#deployment-log-domain-aware-stage5-design) and [the release plan](../plans/domain-aware-stage5-design_RELEASE_PLAN.md).

### References

- Milestone: domain-aware-stage5-design
- Release PR: [#503](https://github.com/cody-hutson/pmo-platform/pull/503) at `552b33efd5b98011d456eccb527da4e7925a8f14`
- Issues: [#1](https://github.com/cody-hutson/pmo-platform/issues/1) · [#345](https://github.com/cody-hutson/pmo-platform/issues/345) · [#346](https://github.com/cody-hutson/pmo-platform/issues/346)
- Tag: (none) — version-less release, no git tag and no GitHub Release cut
- Follow-ups (out of scope): [#504](https://github.com/cody-hutson/pmo-platform/issues/504) (pre-existing deploy.sh Check-18 stale catalog path) · [#505](https://github.com/cody-hutson/pmo-platform/issues/505) (domain-fan-out impact-analysis instrument)
