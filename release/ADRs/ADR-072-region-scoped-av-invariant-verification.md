---
title: "ADR-072 — Region-scoped AV invariant verification"
status: Accepted
date: 2026-07-03
release: 70-verification-execution-surface
deciders: "Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) + operator at the Collective Review scope-lock"
tags: [release-ops, stage-13, qc4-05, av-invariant, verification-integrity, lexical-scoping, verdict-soundness, region-scoped-assertion]
source_observations:
  - "QC4-05/AV-1 re-verification at Stage-13 Phase A4 was an unscoped grep over the whole deliverable. A grep has no model of lexical context: it cannot distinguish a token in executable code from the same token inside a comment or a negation. In the originating website trace, `localStorage` matched inside a disclaiming ADR comment ('NOT localStorage') and the correct AC was false-FAILed; the symmetric false-PASS (a violating token the lexical pattern misses) is reachable."
  - "The defect is domain-independent — QC4-05 protects the post-deploy verdict of every release including governance — so a verdict machine that can be fooled by a comment cannot be trusted for any gate."
  - "There is no AV DSL, no av-verify tool, and — verified across the full release-plan corpus — ZERO formal `AV-<n>` assertion rows in any release plan prior to this one. 'AV-1' was a naming convention referenced in the Checkpoint text, never an authored corpus of assertions. So this is a mechanism + a forward-looking authoring convention, not a migration of an existing formal corpus; regression is proven with synthetic fixtures, not by replaying prior assertions (there are none to replay)."
---
<!-- reference-durability: allow-link -->
# ADR-072 — Region-scoped AV invariant verification

## Status
Proposed. Drafted at Stage 5 Solutioning for the QC4-05 soundness card — the foundation card of the 70-verification-execution-surface release. Flips to Accepted at this release's Collective Review scope-lock (the ratification surface the release-ADR README names), consistent with how in-repo release ADRs set their own status. Recorded Proposed because that gate has not yet run. (Originating-issue provenance is carried in the `source_observations` frontmatter.)

## Context
QC4-05 (Post-Deploy Verification, `release/governance/release-process.md` Checkpoint 4) re-executes each release-plan AV-N invariant against post-deploy main at Stage-13 Phase A4. The mechanism string read `structural (AV-1 grep mechanism)`. A bare grep matches its pattern anywhere in the file — including inside comments and negation contexts — so it returns an incorrect verdict when the asserted token appears only in a disclaiming comment (false-FAIL, proven in the originating website trace) and can miss a violating token the pattern does not lexically reach (false-PASS, reachable). Because QC4-05 is the substrate every gate's post-deploy verdict relies on, this is a verification-integrity defect (P1), not a cosmetic one.

Verified reality that shapes the fix: there is **no existing formal AV corpus**. A full sweep of the release-plan corpus finds **zero** authored `AV-<n>` assertion rows — "AV-1" was a naming convention in the Checkpoint prose, not a body of assertions. The mechanism therefore governs assertions authored **going forward**; there is nothing to migrate, and the regression guarantee is demonstrated with synthetic fixtures rather than by replaying prior assertions.

## Decision
1. **An AV-N invariant is a declarative record** `{id, target, pattern, region, polarity, expect}` authored in the release plan's `## Verification Plan`. `region ∈ {code, comment, any}`; `polarity ∈ {present, absent}`.
2. **Verdicts are computed by `release/tools/av-verify.py`**, which resolves the target's comment syntax from its extension, produces a comment-stripped **code view** and a **comment view**, and applies `pattern` only to the region the assertion declares. A `region: code` assertion never sees comment bytes → **a comment match can neither satisfy nor violate it** (the comment-vs-code ambiguity class this ADR resolves is structurally excluded). For markdown targets the code view additionally excludes fenced code blocks (backtick/tilde fences — info-strings, indented, and nested/adjacent fences handled), isolated as their own region, so a token inside an illustrative fenced block does not count as "in code" for an absence assertion (full `.md` soundness). Negation invariants are expressed as `polarity: absent` (e.g., `absent-in-code`), not as fragile pattern gymnastics.
3. **`region: any` is byte-equivalent to a whole-file grep** and is the default for prose/markdown targets with no code/comment split — so the change is backward-compatible and any future assertion that does not depend on the code-vs-comment distinction carries the current behavior unchanged.
4. **Unknown lexer + a `code`/`comment` region is fail-loud (exit 3)**, never a silent whole-file fallback — the mechanism must not silently degrade to the unsound behavior it replaces.
5. **The QC4-05 record — its ID, Stage-13 position, disposition options (A/B/C), and `qc4-05-result` event payload — is retained unchanged**; only the mechanism (grep → region-scoped) changes. Cutover: applies to releases entering Stage 13 strictly AFTER this ADR's introducing-release merge SHA (**v3.65**); the introducing release itself is exempt (reflexive-pipeline-loop discipline — its own Stage-13 QC4-05 runs the old grep).

## Alternatives Considered
| Option | Decision | Rationale |
|---|---|---|
| Full AST / parse-aware assertion | Rejected | No universal grammar across the md/sh/py/json/yml/toml/prose corpus; governance `.md` has no meaningful AST; N parsers to build + maintain — unsound *for the corpus* and disproportionate. |
| Structured invariant DSL (full grammar + engine) | Rejected | A bespoke language + evaluator is a multi-release build for a population that is, today, empty of formal assertion rows. YAGNI; over-built. |
| Two-pass grep + manual comment-strip in the Verification-Plan prose (no tool) | Rejected | Soundness would rest on the author remembering to strip comments every time — re-creating the silent-omission failure mode this ADR exists to eliminate. |
| Leave grep, add author guidance | Rejected | The defect is structural; guidance does not make an incorrect verdict impossible. |

The survivor — scoped/anchored assertion with a small declarative record (region + polarity) evaluated by a one-file stdlib helper — is the minimum mechanism that makes the ambiguity **unrepresentable** rather than **avoidable**. It takes the useful nucleus of the DSL option (a declarative record) without the engine, and gets the AST option's comment-exclusion guarantee via lexical region-stripping without a full parser.

## Consequences
### Positive
- The comment-vs-code / negation false-verdict class becomes **unrepresentable**, not merely avoidable — soundness rests on structure, not author diligence.
- One small stdlib helper + a per-extension comment table; new target languages are a table row, not a re-architecture.
- Declarative AV records are reviewable at Collective Review + Stage-9; a single point of correctness replaces per-assertion hand-rolled comment-stripping.
- Backward-compatible: `region: any` reproduces a whole-file grep; downstream QC4-05 references (payload, escalation threshold, event schema) are untouched.

### Negative / cost
- A new (small) tool to own + test in `release/tools/`.
- String-literal-naive comment stripping is a documented bound (`region: any` is the escape hatch); acceptable because AV targets are governance/config, not code where `#`-in-a-string is load-bearing.
- Authors must now declare `region` + `polarity` per assertion (a deliberate, cheap discipline that surfaces intent).

## Reversibility
**EXPENSIVE / Confidence MEDIUM.** Changing the QC4-05 verdict mechanism is a model change to logic every gate relies on; a wrong design could silently mis-verdict future releases. The regression anchor — a synthetic `region: any`-equivalence fixture proving the `any` path reproduces whole-file grep byte-for-byte — is the falsification test; Deep Stage-9 review is warranted; the interim manual-QC4-05 mitigation stays available as the backout path. Whole-release rollback = revert the single squash-merge (deletes `av-verify.py`, restores the grep string) — CHEAP at the release grain; the *mechanism* re-authoring is what is EXPENSIVE.

## Related ADRs
- ADR-039 (declarative gate-condition construct) — precedent for expressing a gate check as a small declarative record with a typed discriminator; this ADR applies the same "declarative record over ad-hoc predicate" instinct to the AV-assertion surface (region/polarity are the discriminators).
- ADR-062 (substrate-vs-canonical precedent) — cited for the canonical-edit-wins discipline: the mechanism string is changed at its **canonical governed home** (`release/governance/release-process.md` Checkpoint 4), not by mutating downstream mentions.
