---
title: Release Notes — Voice & Terminology Guardrails
tier: K1
scope: platform-wide
extends: release/references/standards/release-notes-standard.md
status: Active
version: v12.08
last_reviewed: 2026-05-24
---
<!-- reference-durability: allow-link -->

# Release Notes — Voice & Terminology Guardrails

## Purpose

Operational guardrails extending [`release-notes-standard.md`](release-notes-standard.md) §2.5 Voice Rules with concrete terminology, forbidden phrases, and attribution conventions. The standard is the contract; this doc is the operational checklist. Consumers: [`release-executor`](../../skills/release-executor/SKILL.md) Mode E, [`pmo-qa-auditor`](../../../core/skills/pmo-qa-auditor/SKILL.md), human operators reviewing release notes at Stage 9 / Stage 13.

This document does NOT redefine §2.5 Rules 1-3 (fabricate-or-omit / voice-constraint / review-surface). It supplies the *terminology dictionary* and *forbidden-phrases registry* that operationalize Rule 2 (voice-constraint) at authoring time, and the *attribution conventions* that operationalize the named-voice prohibition.

## 1. Terminology Dictionary

The dictionary names the approved capability noun for recurring concepts and pairs each with the banned alternative that operator-grade drafts tend to slip in. Mode E consults this table during Step 3 drafting; pmo-qa-auditor flags violations as G4 findings.

### 1.1 Approved capability nouns (Section 6a leads)

| Approved | Why approved | Banned alternative |
|---|---|---|
| "automated Stage 13 close-out" | Names the user-observable mechanism — operator invokes one command, the script runs Phases 5-16 | "the close fixing thing", "auto-closeout" (jargon for Layer A) |
| "deployment cycle-time" | Mechanism-name discoverable in the `**Cycle-Time:**` field on every Deployment Log block | "cycle-time instrumentation" (operator-grade), "T_DEPLOY - T_GO" (formula leak) |
| "decision outcome tracking" | User-observable in the `**Outcome:**` field on every Deployment Log block | "outcome instrumentation", "QC4 verification record" (operator-grade) |
| "release-corpus navigation update" | Names the artifact category — INDEX + DIGEST + NOTES corpus | "INDEX update" (jargon for Layer A), "navigation hygiene" (vague) |
| "release-learnings synthesizer" | Names the script + Issue auto-promotion mechanism that surfaces patterns across releases | "pattern detection automation" (vague), "release retrospective tooling" (process-grade) |
| "partial-deployment recovery protocol" | Names the K1 standard's deliverable — a 3-state decision tree (fix-forward / rollback / accept) | "partial-failure protocol", "recovery routing" (vague) |
| "deferred-item tracking standard" | Names the K1 deliverable — `status: deferred` label + 3-line comment trail + Status Proposed | "deferred routing", "bundled-but-not-closed protocol" (operator-grade) |
| "release note presence check" | Names the deploy.sh Check 26 user-observable behavior — drift detection per released version | "Check 26", "release-note drift" (operator-grade) |
| "user-facing release note" | Standard term across the corpus — distinguishes from RELEASE_LOG / release plan | "release notes" (ambiguous — could mean LOG row), "RELEASE_NOTES.md file" (path leak) |

**Operator extension protocol:** Add rows during Stage 9 Plan Review when a new capability noun gains adoption (rationale captured inline in the third column or in adjacent prose). Removals require explicit justification — the term has become unambiguous to all Layer A readers per §2.4 default protocol.

### 1.2 Approved vs. banned verb forms (impact-first framing)

| Approved | Banned | Rationale |
|---|---|---|
| "now records" | "is instrumented with" | Active voice, user-observable. "instrumented" reads as engineering noun |
| "ships as" | "is delivered via" | Concrete; "delivered via" is passive marketing-cliché |
| "fires at" | "is triggered by" | Concrete actor visible. "triggered by" obscures who fires |
| "applies to" | "is applicable to" | Shorter, clearer; "applicable to" is marketing-padding |
| "you can now …" | "users are now able to …" | Direct second-person. "users are able to" is third-person abstraction |
| "X replaces Y" | "X supersedes Y" | "supersedes" reads as legalese; "replaces" is plain |
| "stops the release until fixed" | "structurally gate-blocking" | Plain language; "gate-blocking" is §2.4 banned-jargon |
| "logged but not blocking" | "warn-mode posture", "warn-mode initially" | §2.4 banned phrase in 6a; "logged but not blocking" is the canonical replacement |

## 2. Forbidden-Phrases Registry

Strict-deny list for Section 6a. Mode E's Step 4 self-lint rejects any draft containing these literal phrases (case-insensitive); pmo-qa-auditor flags as automatic G4 finding. Replacement guidance is column 3 — apply verbatim during Mode E Step 3 drafting.

| Phrase | Reason | Replacement |
|---|---|---|
| "We're so excited" / "We're thrilled" / "We're proud" | §2.5 Rule 2 — marketing-enthusiasm voice the agent cannot author | Omit; describe the change directly |
| "This is going to be huge" / "game-changer" / "revolutionary" | Rule 2 — stability-promise without evidence | Omit; the user judges magnitude from the description |
| "Built by [name]" / "Thanks to [name]" / "Special thanks to" | Rule 2 — named-attribution the agent cannot synthesize | Omit; use structural voice ("X is now available") |
| "various improvements" / "minor enhancements" / "general improvements" | §2.6 specificity-rule violation; §2.7 anti-pattern | List specific changes (one bullet per capability) OR omit the section per §2.5 Rule 1 |
| "bug fixes and minor enhancements" | §2.6 + §2.7 anti-pattern (the single most-criticized release-notes pattern) | List specific fixes (one bullet per fix) OR omit |
| "as part of our commitment to quality" | Rule 2 marketing-cliché | Omit; the change speaks for itself |
| "under the hood" | §2.4 banned-jargon-adjacent; obscures behavior change | Describe the behavior change directly |
| "powered by" / "built on" (as marketing leads) | Rule 2 marketing-padding | Omit when used as flourish; retain only when the dependency is user-visible |
| "we hope you enjoy" / "let us know what you think" | Rule 2 — first-person/named voice | Omit; replace with the `Report issues at <channel>` line per Section 7 |
| "stay tuned" / "more to come" | Rule 2 — stability-promise the agent cannot commit | Omit; if a follow-up is real, cite the tracking issue in §References |
| "now bulletproof" / "won't happen again" | Rule 2 — stability-promise without evidence | Describe the specific fix; omit absolute claims |
| "30% faster" / "N% improvement" without inline citation to source | §2.5 Rule 2 — invented percentages | Cite the source measurement (closed-issue body, release plan section) OR describe behavior change without the percentage |

**Operator extension protocol:** Additions follow the §1.1 extension protocol — operator approval at Stage 9 Plan Review; rationale recorded inline.

## 3. Attribution Conventions

### 3.1 Verified human attribution

Named-voice content REQUIRES verified human authorship per §2.5 Rule 2. Agents do NOT synthesize named-voice content. When the release plan or a closed-issue body includes operator-authored quoted content with explicit author attribution AND operator confirms re-use at Stage 9 Plan Review, Mode E MAY include the attribution verbatim in Section 6b only — never in Section 6a (per §2.5 Rule 2 prohibition on agent-synthesized named voice in Layer A).

The Stage 9 confirmation discipline is structural: the operator approves the named-voice quote at Stage 9 by leaving a `[NAMED-VOICE-OK: <quote>] confirmed for 6b` comment on the release PR. Without that comment, Mode E omits the quote.

### 3.2 Component attribution (approved)

Components touched by the release are listed in `components:` frontmatter (per [`release-corpus-schema.md`](release-corpus-schema.md)). Mode E Step 2 populates the field from the intersection of closed-issue affected-files with the platform component registry (skills, K1 standards, engineering tools). Component names use canonical kebab-case per the schema:

- Skills: `release-executor`, `eval-writer` (NOT `release-executor/SKILL.md` or path leaks)
- Standards: `release-notes-standard.md`, `decision-outcome-tracking.md` (filename without path prefix)
- Tools: `automated-closeout.sh`, `compute-cycle-time.sh` (filename without path prefix)

Component attribution is approved in BOTH Section 6a (as inline noun) and the frontmatter.

### 3.3 Issue/PR/Milestone attribution (approved)

Standard `closes #N` / `Issue #N` / `Milestone #N` / `PR #N` references in the References block at note foot. No prose attribution in Section 6a body — `#N` as a primary noun is a §2.7 anti-pattern. The References block format:

```markdown
### References

- Milestone: [vX.Y-slug](https://github.com/{REPO}/milestone/<N>)
- Integration PR: [#PRN](https://github.com/{REPO}/pull/PRN) merged at `<sha>`
- Closed issues: [#A] · [#B] · …
- Follow-up: [#X] (one-line scope) · [#Y] (one-line scope)
```

The dot separator `·` is the canonical separator for issue/PR lists; commas are acceptable when the list crosses a line wrap.

## 4. Composition with `release-notes-standard.md`

This doc COMPOSES with — does not replace — the standard:

- **§2.5 Rule 1 (fabricate-or-omit)** — invoked when this doc's §1 terminology dictionary has no approved term for a needed concept. Mode E omits the bullet rather than coining a new term mid-draft; the operator adds the term during Stage 9 review if the concept recurs.
- **§2.5 Rule 2 (voice-constraint)** — operationalized by §2 forbidden-phrases registry of this doc. Voice-constraint violations detected at Mode E Step 4 self-lint route to revision before Step 5 presentation.
- **§2.5 Rule 3 (review-surface)** — gates §1.1 terminology dictionary additions at Stage 9 when a new capability noun ships with the release. Additions land via the same Stage 9 review surface that approves the note itself.
- **§2.4 banned-jargon list (in standard)** — supersedes this doc's §2 when contradiction occurs (this doc is intended to extend, not contradict). If §2.4 of the standard names a term as banned that this doc names as approved, the standard wins until the operator reconciles via Stage 9 review.

## 5. Maintenance Protocol

Operator-driven additions only — Mode E does not extend the dictionary or registry autonomously. Each addition row carries inline rationale (third column or paragraph below the table). Deletions require explicit justification (the term has become unambiguous to all Layer A readers per §2.4 default protocol).

Cadence: review at Stage 9 of any release whose Section 6a content surfaced a new capability noun or banned phrase. The review is part of the existing Stage 9 Plan Review gate; no separate cadence is required.

## 6. Reversibility

CHEAP / HIGH confidence. The doc is reference-only — Mode E and pmo-qa-auditor compose against it but degrade gracefully when it is absent. Revert is `git revert <merge-sha>`. Post-revert: Mode E falls back to §2.4-only enforcement (the standard's banned-jargon list); pmo-qa-auditor's G4 finding-set decreases but does not regress correctness on existing notes.

## 7. Cross-References

- [`release-notes-standard.md`](release-notes-standard.md) — parent contract (this doc extends §2.4 + §2.5)
- [`release-corpus-schema.md`](release-corpus-schema.md) — frontmatter schema (`components:` field used here)
- [`release/skills/release-executor/SKILL.md`](../../skills/release-executor/SKILL.md) — Mode E consumer; reads this doc at Step 1 Input validation
- [`core/skills/eval-writer/references/release-notes-eval-rubric.md`](../../../core/skills/eval-writer/references/release-notes-eval-rubric.md) — sibling rubric covering the 14 lint checks
- [`core/skills/pmo-qa-auditor/SKILL.md`](../../../core/skills/pmo-qa-auditor/SKILL.md) — G4 enforcement consumer

## 8. Version History

| Version | Date | Changes |
|---|---|---|
| 1.0 | 2026-05-24 | Initial release per the Phase 2 voice-guardrails work; seeds §1.1 (9 approved nouns), §1.2 (8 verb pairs), §2 (12 forbidden phrases) from the release-notes corpus. |
