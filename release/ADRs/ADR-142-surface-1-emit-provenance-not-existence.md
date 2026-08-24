<!-- reference-durability: allow-link -->
---
title: ADR-142 — A backstop records its pre-mutation observation as a witness token, and the downstream check asks provenance rather than existence
status: Proposed — flips to Accepted when the operator ratifies it at the release close gate. The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure.
date: 2026-08-24
release: pipeline-spec-self-consistency
deciders: "Workspace owner (Surface-1 ownership ruled 2026-08-15 at the release-hub Mode R milestone-readiness pre-flight for milestone 350: Stage 12 Phase B5.5 owns the emit). Design decisions D-1 and D-2 rendered at Stage 5 Solutioning on sub-task #6078 and accepted by the hub at Procedure 4."
supersedes: none
tags: [architecture, release-pipeline, gates, observability, witness-record, provenance, backstop, aggregation-safety, reversibility-cheap]
source_observations:
  - "The check was not circular — it was unimplemented. `automated-closeout.sh` carries exactly ONE live `gh release view` existence read, at L5907, INSIDE the producer itself. The spec places Phase B5.6's existence check BEFORE the chore-PR merge, and the mandated close-out tool has no phase at that position. B5.6 was not executing at all on the mandated path."
  - "The defect is systemic, not anecdotal. 11 of the last 12 releases published Surface 1 at or after their Stage-13 chore-PR merge. The ticket filed it as N=2; the measured population is 11 of 12, with v4.27 the lone exception at -0.21 h."
  - "The obvious fix silently inverts a downstream verdict. Promoting the create path to its own `mark_phase` outcome token would break `automated-closeout.sh:6221` (`if [[ \"$pub_result\" != \"PASS\" ]]`), making a genuinely-created Release report as 'Surface 1 not emitted this run' and marking phase 15.6 `N/A` instead of `WARN`. Demonstrated by execution, not argued: the mutation was injected and both self-test arms went red, arm (i) reporting the literal `N/A`."
  - "The value vocabulary already existed at two of three emit paths. `CREATED / EDITED / NO-OP` is live at `hub-spoke-bridge.md:1273` (Stage-12 chip required deliverable) and `release-executor/SKILL.md:475` (Mode F report field). All three Surface-1 emit paths share one state machine; `automated-closeout.sh` phase 15.5 was the only path that did not record it."
  - "A blocking existence check placed before the backstop would have hard-blocked 11 of the last 12 closes — including the close of the release shipping the fix. The Step-4 `GitHub Release` row is `required` and BLOCKS; moving it pre-backstop converts a reporting gap into a release-stopping gate."
  - "The outcome-token vocabulary is a closed 9-value set over 253 `mark_phase` call sites (FAIL 89 / PASS 50 / SKIPPED 44 / DRY-RUN 43 / WARN 15 / N-A 8 / MANUAL 2 / SKIP 1 / one self-test control). Adding a tenth member is a corpus-wide change to a surface consumed by a live branch predicate and by at least six self-test assertions."
  - "The ancestry-repair path would have swallowed the token. Phase 15.5's repair limb called `mark_phase` and fell through without returning, so the state machine marked the same phase twice; `get_phase` and `is_first_phase_occurrence` surface the FIRST mark only. Any token added to the terminal mark was invisible on exactly that path."
---

# ADR-142 — A backstop records its pre-mutation observation as a witness token, and the downstream check asks provenance rather than existence

## Status

**Proposed** — flips to **Accepted** when the operator ratifies it at the release close gate. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified — never inferred from a review comment, a plan row, or milestone closure.

**Numbering.** `142` is the mainline anchor plus one, re-derived against `origin/main` at Engineering time across **both** ADR directories via `release/tools/renumber-adr.py --next-free`, immediately before this file was authored. The union of the two directories reaches `ADR-141` on the mainline with zero gaps and zero duplicates over a denominator of 141 numbered records. The number was deliberately **not** allocated at design time: the oracle is a *read*, not a reservation, so three Stage-5 spokes in this release independently resolved the same `142`. A duplicate is mechanically renumberable by the same tool at merge time; a **gap blocks the repo**, because the next release's `anchor + 1` lands under a hole. That asymmetry is why allocation happens here and never reserves high.

## Context

Three surfaces disagreed about which stage owns the Surface-1 emit — the published GitHub Release. `stage-12-execute.md` § Phase B5.5 assigned it to Stage 12. `stage-13-close.md` § Phase B5.6 was written as a *verification* of that Stage-12 emit. And `automated-closeout.sh` phase 15.5 actually created it, at Stage 13.

The operator ruled the ownership question in favour of **Stage 12**: the specification is the intent, the Stage-13 production is the accident. Stage 12 has accumulated deliberate codified investment in owning the emit — a three-state view-then-create-or-edit machine, an explicit rigor-invariance clause, a `deploy.sh` Check 48 backstop, and a stage-anchor rationale binding stage assignment to mechanism execution surface. Ratifying Stage 13 would orphan all of it.

That ruling leaves two engineering questions the ruling itself does not answer, and this record exists because both have a defensible wrong answer that a future reader will re-litigate.

**The structural problem is sharper than "the check is circular."** The measured root cause is that the Stage-13 existence check is **not implemented on the mandated path at all**. There is exactly one live `gh release view` existence read in the close-out tool, and it sits *inside* the producer. The spec's B5.6 position — before the chore-PR merge — has no phase.

This matters because it eliminates the intuitive framing. "The verifier runs after the producer, so its question is vacuous" suggests the fix is to move the verifier earlier. It is not. B5.6's existence question is unanswerable at **both** candidate positions: after the backstop it is vacuously true, and before the backstop the mandated tool has nothing there. Any design that keeps B5.6 as an **existence** check inherits that, wherever it is placed.

## Decision

Two decisions, one principle.

### D-1 — The producer records its pre-mutation observation as a structured token in its phase *detail*, and its outcome token is left byte-identical

Phase 15.5 prefixes `SURFACE1-STATE=<CREATED|EDITED|NO-OP>` to the detail of each of its three terminal `mark_phase` calls. The result token stays `PASS` (create), `PASS` (edit), `SKIPPED` (no-op), `WARN` (ancestry repair) — unchanged on every reachable path.

The value vocabulary is **reused, not invented**. `CREATED / EDITED / NO-OP` already binds two of the three Surface-1 emit paths; phase 15.5 was the one path that never recorded it. Minting a fourth vocabulary would have given one state machine two vocabularies across three emit paths — the exact spec-versus-reality divergence this work exists to remove, re-created inside the fix.

### D-2 — The downstream check asks **provenance**, not existence

`stage-13-close.md` § Phase B5.6 is re-framed. It no longer asks *"does Surface 1 exist?"* — a question that is vacuously true by the time it runs. It asks *"by what path did Surface 1 come to exist?"*, reading the token the producer recorded. `CREATED` is reported as a Stage-12 omission; `EDITED` or `NO-OP` is a genuine pass; an absent token resolves `UNVERIFIED` and is **never** read as PASS.

The verdict is **reported, not blocking**, and that is deliberate rather than timid. The release's outputs are complete — the backstop converged Surface 1 — so blocking a close on an upstream omission the backstop already repaired is the reflexive-pipeline-loop pathology the close-out tool's own exit-2/3 rationale names. The ticket asked for reportability, not blocking: *"a real Stage-12 miss is reportable as a defect rather than silently repaired."*

### The principle

**A producer can be made auditable by recording an observation it necessarily made before it acted, without being granted authority over its own verdict.**

The circularity objection — *"this has the producer report on itself, which is the defect the ticket names"* — is worth answering directly, because it is the objection a future reader will raise first. The original defect was that the **verifier's question** was rendered vacuous because the producer acted first. This design does not ask the producer to *grade* itself. It asks it to record the State-0/1/2 discrimination it **must** perform to route at all — an observation made strictly **before** any mutation. A witness record of a pre-action observation is how a producer's action becomes auditable; it is categorically different from a producer asserting its own output is correct.

## Alternatives considered

The rejections are the load-bearing content of this record. In both decisions the *obvious* option is the wrong one, and in D-1 the obvious option is actively dangerous.

### D-1 alternatives

| # | Candidate | Why rejected |
|---|---|---|
| **A** | **A new `mark_phase` outcome token on the create path** (`BACKSTOP`, or reusing `WARN`) | **The obvious fix, and it silently inverts a downstream verdict.** `automated-closeout.sh:6221` branches on `[[ "$pub_result" != "PASS" ]]`, so a genuinely-created Release would report as *"Surface 1 not emitted this run"* and phase 15.6 would mark `N/A` instead of `WARN` — the tool asserting the exact opposite of what happened. It also collides with the existing `WARN` semantics on the ancestry-repair path and adds a tenth value to a closed 9-value vocabulary spanning 253 call sites. **Proven, not predicted:** this mutation was injected during Engineering and the self-test went red on both arm (e) and arm (i), with (i) reporting the literal `N/A`. |
| **C** | **A new phase `15.51 assert_surface1_origin`** | Structurally impossible without cheating. It would have to re-derive *"did Surface 1 exist before?"* **after** phase 15.5 already mutated the Release. A phase whose only possible input is another phase's variable is a parallel mechanism with no independent evidence — a second surface to keep in step, buying nothing. |
| **D** | **Prose-only enrichment** — say "backstopped" more loudly in the existing detail | This is materially what already shipped: the create branch already said "created". It is precisely what the ticket reports as insufficient — the distinction was neither machine-addressable nor asserted by any test. |

### D-2 alternatives

| # | Candidate | Why rejected |
|---|---|---|
| **α** | **Implement the Step-4 `GitHub Release` row inside `phase_run_verification`**, i.e. a real existence check *before* the backstop | That row is `required` and **BLOCKS**. Placed pre-backstop it would have hard-blocked **11 of the last 12 closes — including the close of the release shipping this very fix**. A design that blocks the release shipping it is not a fix. It also conflates two distinct questions: *did the output set land* (correct, and correctly evaluated post-backstop) versus *did Stage 12 do it* (provenance). |
| **γ** | **Two independent probes** — a non-blocking `gh release view` before phase 15.5 recorded as evidence, plus the existing post-backstop assertion | The runner-up, and the only option not relying on the producer's own record — genuinely the strongest on independence. Rejected because it duplicates a fact phase 15.5 **must** compute anyway to route, can *disagree* with it (a Release published in the seconds between the two probes), and adds a network call plus a phase for zero new information. |

## Consequences

**What this buys.** A Stage-12 omission becomes visible in the close-out record instead of being silently repaired. The rate of `CREATED` verdicts is itself the evidence that would justify fixing the Stage-12 chip — which is the real remedy, and which no blocking gate at Stage 13 could deliver.

**What it costs, stated plainly.** The provenance check trusts a token the producer wrote. That trust is bounded — the token records a pre-mutation observation, and the observation is the one the state machine must make to function — but it is not the same as an independent probe. Option γ remains the upgrade path if the token is ever found to be unreliable in practice.

**What it deliberately does not change.** The Step-4 `GitHub Release (Surface 1)` row and its `deploy.sh` Check 48 twin are **untouched and unchanged in meaning**. They assert the output set landed, evaluated post-backstop where that assertion is correct. No new Surface-1 assertion is added anywhere, so nothing duplicates Check 48.

**A constraint on future editors, and a test that enforces it.** The outcome token of `phase_publish_github_release` must not change. The temptation to "improve" this design into Option A is real — it is the more natural-looking shape — so the prohibition is stated in a block comment at the phase itself **and** enforced by self-test arm (i), which drives phase 15.6 with a drift-tool exit 3 and asserts the create path still reaches the `WARN` limb rather than the `N/A` limb. That arm fails if anyone promotes `CREATED` to its own token. A comment can be ignored; a red test cannot.

**Both arms are proven offline.** The detection question is verified against fixtures on the existing hermetic `$GH`-stub harness — `CREATED`, `NO-OP`, and `EDITED` each driven, plus a specificity arm asserting neither found-arm reports `CREATED`, plus the aggregation arm above. No fixture tag, no public mutation, and the no-op fixture's canonical body is extracted with the phase's own expression and asserted non-empty, so the no-op is a genuine State-2 comparison rather than `""` against `""`.

**Reversibility: CHEAP · confidence HIGH.** Five text-only edits across five tracked files plus this record; no schema migration, no data movement, no path move. Full rollback is `git revert` of the release merge.

**One residual, recorded rather than absorbed.** Phase 15.5's ancestry-repair path previously marked the phase twice and would have swallowed the token, since `get_phase` surfaces the first mark only. The fix folds the repair note and its `WARN` outcome into the single terminal mark. **Net verdict change is zero** — the path reported `WARN` before and reports `WARN` after; what changes is that the phase now marks once and the token survives on that path.
