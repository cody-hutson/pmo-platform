---
title: Release Plan — hook-publisher-republishes (the hook publisher republishes a stale platform copy, and says so when it declines)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class patch; patch-base v4.67; concrete number binds at the Stage-12 atomic claim)
milestone: hook-publisher-republishes
release_class: hotfix
reversibility: CHEAP / Confidence HIGH — every row is a bounded edit to tracked files plus two new files, single branch and single merge, so `git revert -m 1` of the merge restores `main` byte-for-byte. No schema changes, no new artifact format, no package rebuild. The one qualification, recorded in § Rollback Strategy: the version tag is retained and recorded rather than deleted.
---
# Release Plan — `hook-publisher-republishes`

**Milestone:** `hook-publisher-republishes` · hub sub-task **#7509** = Stage-4 plan source, the hub's R1 adversarial evaluation, and the D2/D3 **Decision Recorded** gate comment · **#7510** = Stage-5 Solutioning source and its R1 evaluation · **#7511** = the Stage-6 Engineering sub-task that authored this file.

**Version identity:** **versioned** — bump-class **`patch`**, patch-base **`v4.67`**, provisional display **`v4.67.1`**. Rendered by the operator at the Stage-4 gate (D3), overturning the plan's `version-less` determination after the hub's R1 evaluation falsified two of its three supporting signals and found the third unattested; gate criterion **G3-19** governs the residual (*"an absent declaration resolves to `versioned`, the shipped default"*). The concrete `vX.Y.Z` binds only at the Stage-12 atomic claim per ADR-092, so the plan file and the branch stay slug-primary while in flight and the Header `**Version**` cell carries the unresolved stamp token. The Commit-0 re-verify ran in full, both halves — see § Commit-0 Version Re-Verify Record.

**Topology:** D-C **SINGLE** — one release branch (`release/hook-publisher-republishes`), one PR opened at Commit 0 in draft so CI runs while the later slices land, one merge, base `main`. This plan lands as **Engineering Commit 0**.

**Concurrency posture:** **P0 fully-serial** — the only posture reachable at n=1 content member. Every non-serial posture prohibits force-push (including `--force-with-lease`) on the shared release branch; P0 is in force, so the prohibition is moot here and is recorded for completeness.

**Release class:** `hotfix` — CONFIRMED at the Stage-4 gate. Triggers (a) a P1 defect against a deployed release, (b) ≤3 issues, (c) corrective scope, and — under D3 — (d) a trailing patch number, all fire. Differentiation posture: **Light** Stage-9 review depth, **7-day** outcome window, no stage skips beyond the compressed 10/11.

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #7509 and both **Decision Recorded** gate comments on it, reconciled to the approved **Stage-5 Solutioning** design posted on #7510 and the hub's R1 evaluation of that design. **Where a later disposition superseded a Stage-4 value, the transcribed section carries the ratified value and § Deviation Log records the delta with its authority.** Authored at Engineering Commit 0 by the Stage-6 Engineering spoke (#7511).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | `patch` — the durable determination, rendered by the operator at the Stage-4 gate (D3). Patch-base **`v4.67`**; the recorded provisional display is **`v4.67.1`**, and the Commit-0 re-verify recomputed the same value against fresh authoritative host state. It sets the floor and binds no concrete number. |
| **Date Created** | 2026-09-19 (Friday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/hook-publisher-republishes` |
| **PR** | opened in **draft** at Commit 0 per the SINGLE topology, so CI runs while the remaining slices land on the same branch; transitions to ready-for-review at the Stage-9 gate |
| **Milestone** | `hook-publisher-republishes` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-09-19, domain: software }`

**Domain classification.** Form **X** (sourcing-exempt): every add/edit row targets an internal `pmo-platform` artifact — two production shell scripts, one shell regression suite, three markdown governance/pipeline surfaces, one ADR and this plan — so no external body of practice is consumed and no Form-A citation exists to record. Dominant domain **`software`**: the determinative evidence is executable shell source, not governance prose, and the markdown rows document the behaviour the scripts carry. Secondary domain `governance` (three markdown rule/pipeline surfaces). Transcribed unchanged from Stage-4 Phase A1.5 and re-affirmed at Stage 5; no Mode B → Mode A upgrade applies, because no external source is consumed at all.

**Why the label is load-bearing rather than ceremonial.** It is read by the Stage-13 close-class rung, by the Stage-5 impact-method selector (which is what routed the design spoke to the default markdown-tree blast-radius tool), by the design-review checklist's guide resolution, and by Stage 7 Phases A and C. A transcription that dropped it would silently starve four consumers.

---

## Commit-0 Version Re-Verify Record

Run in full at Engineering Commit 0, both halves, per the D3 consequence list. **This release is `versioned`, so neither half is inapplicable** — the Stage-4 plan's `version-less` reading, under which no stamp token would have been emitted, was overturned at the gate and is not transcribed.

### Version half (steps 1–3, pre-write)

| Step | Action | Observed |
|---|---|---|
| **1** | `git fetch --tags origin` | exit 0; tag refs current |
| **2** | Recompute next-free for bump-class **`patch`** against patch-base **`v4.67`**. The floor for a patch bump is `(4, 67, 1)` and the walk increments the PATCH component, per the claim tool's own `compute_next_free`; the anchor is deliberately NOT read for a patch bump | floor `v4.67.1`; **free** |
| **3** | HALT on collision — the slot must be free across all three `claimed_set()` arms (published Releases ∪ origin tags ∪ RELEASE_LOG `DEPLOYED` rows) | **no collision; PROCEED** |

**Probe record for the step-3 zero** (per `review-discipline-principles.md` § 8, elements PV-0..PV-7):

```
Probe:       git ls-remote --tags origin 'refs/tags/v4.67.*' | wc -l
             gh release list --limit 5000 --json tagName  → select tagName startswith "v4.67"
             grep -n 'v4\.67' release/releases/RELEASE_LOG.md
Denominator: 209 published Releases (counted by the same reader, no truncation — the
             first read at --limit 200 returned exactly 200 and was re-run at 5000);
             16 v4.6*-prefixed origin tags; 1 RELEASE_LOG row naming v4.67
Control - sensitivity: the SAME readers on the v4.67 slot itself — origin tags matching
             'refs/tags/v4.6*' → 16; published releases starting "v4.67" → ["v4.67"];
             RELEASE_LOG grep → 6 lines. All three arms non-zero, so all three readers
             resolve and a zero on the .1 slot is a real negative
Control - specificity: NOT TRIGGERED — PV-2c needs a near-miss the probe must not flag.
             A patch-slot occupancy question over an exact tuple has no near-miss class:
             v4.67 itself is a DIFFERENT tuple, not a near-miss of v4.67.1, and the
             comparator is tuple equality rather than string prefix
Extraction:  full ls-remote output; full 209-row release list; full RELEASE_LOG match set
Result:      0 occupants of the (4,67,1) slot on every arm
Verdict:     CLEAN — v4.67.1 is free; no HALT
```

### Manifest half (step 3b, post-write / pre-commit)

`release/tools/claim-version.sh --verify-stamp hook-publisher-republishes` — run after this file was written and before it was committed. Required exit **0**. Result recorded in § Verification Evidence.

The verb runs the SAME pre-flight the Stage-12 claim runs before the compare-and-swap, so a Commit-0 PROCEED rehearses the real claim rather than a lookalike. This plan carries **exactly one** double-brace `RELEASE_VERSION` placeholder — the Header `**Version**` cell — so the stamp has a single, verifiable resolution site, and the cell contains the placeholder and no other text per the plan template's machine-read-stamp-manifest rule.

**Why this section NAMES the placeholder instead of reproducing it.** The claim tool resolves the token by global substitution across the whole file, with no classifier separating a *record* site from a *citation* site. A prose mention written in the literal braced form is therefore rewritten too, and this plan would ship sentences reading *"carries exactly one `v4.67.x` token"*. Measured on this file while authoring it: the literal form occurred **4** times — one record and three citations — and the three citations were rewritten to the named form, leaving the record site as the single resolution target the rule requires. The tool gap is pre-existing and out of this release's scope; the authoring convention that avoids it is the one used here.

### Commit-0 Survival Set

Every element the Stage-4 gate determined that a named downstream consumer reads **from this file**. A transcription that drops one is a spec violation, not an oversight.

| # | Survival element | Carried at |
|---|---|---|
| 1 | `domain_practice` label (`source` · `date` · in-label `domain`; Form X, no Mode-B rationale required) | § Header |
| 2 | File Change Matrix (machine-readable, fence-delimited) | § File Change Matrix |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria — **structurally empty at n=1**, declared rather than omitted |
| 4 | Verification Plan | § Verification Plan |
| 5 | Release-version stamp manifest (the double-brace `RELEASE_VERSION` placeholder, named rather than reproduced — see the note below) | § Header `**Version**` cell — **APPLICABLE** under D3 |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin (`origin/main` SHA) | § Baseline pin |

---

## Scope

**One content member.** The milestone's content-member set is `{#5251}`, cardinality 1.

`--refresh-hooks` re-deploys the platform hook bundle only when a deployed hook's content still hashes to the recorded baseline. The baseline is written by a full installer run; the bundle is advanced by the update path. The two diverge on any normally-maintained instance, and from that point every refresh misclassifies the platform-updated hook as an operator edit, preserves it with a *warning*, and exits **0**. The full-update path delegates to the same code and inherits the same outcome. **A merged security-hook fix therefore never reaches the running instance, and nothing in the output says so.**

**The scope shape is corrected from the milestone's original "one file".** Four production/verification paths plus four documentation/record paths, one PR, one merge.

### Reconciled Acceptance Set — 12 criteria

Amended onto the card at the Stage-4 gate as a Tier-1 [ADJUST], reconciling four partial sets (the card body, its `2026-08-20` comment, and two folded cards) into one. AC-1..AC-6 are the card's originals; AC-7/8/9 were named for transfer from the folded cards and had never landed; AC-10/11 come from the comment and a folded card; AC-12 is new from Stage-4 analysis.

| # | Criterion |
|---|---|
| **AC-1** | `--refresh-hooks` updates a hook whose deployed content matches a *known platform version*, rather than treating any baseline mismatch as an operator edit |
| **AC-2** | The `hook_checksums` baseline is advanced by whichever path deploys hooks, so it cannot go stale against the bundle it describes |
| **AC-3** | A refresh that declines to update at least one hook does **not** exit 0 silently — the outcome is visible in the exit status or a summary line, not only an inline warning |
| **AC-4** | A genuine operator edit is still preserved, with a must-flag / must-not-flag pair **and a control arm proving the discriminator can reach both verdicts** |
| **AC-5** | A supported way exists to force reconciliation without a full re-bootstrap |
| **AC-6** | Regression test: given a deployed hook advanced past a stale baseline, a refresh deploys the current source |
| **AC-7** | A post-refresh whole-bundle hash assertion compares every deployed hook against source and fails on any mismatch |
| **AC-8** | The pipeline's Stage-12/13 deployment guidance names the invocation that refreshes hooks |
| **AC-9** | The fix is a narrow persister beside the existing state writer (a `persist_hook_checksums_to_state` sibling), never a `write_state_file` call — with a control that refreshes **twice** against a changed source hook and asserts the second republishes |
| **AC-10** | Where the classification is genuinely ambiguous, the printed remedy **changes the outcome**, or the message states that a baseline correction is required rather than a re-run |
| **AC-11** | Demonstrated by planting a stale baseline, observing the false preservation, applying the remedy the message names, and showing the state actually changes |
| **AC-12** | `update.sh` Phase 5c **surfaces** a declined security hook rather than swallowing it into a warn-and-continue |

---

## Implementation Sequence

**Supersedes the Stage-4 sequence at steps 2–4** per the Stage-5 handoff; steps 1, 6 and 7 carry forward unchanged. Ordered so each step's verification is observable before the next depends on it.

| # | Limb | File | Satisfies |
|---|---|---|---|
| **1** | Author the new arms **RED first** — fixtures **L** (latched) and **E** (edited), the must-flag / must-not-flag pair, and sequence arms **S-1 / S-2 / S-3**. Observe each RED. **S-2 is authored against a deliberately whole-map persister and observed RED**, or it measures nothing | `core/deploy/tests/test_refresh_hooks.sh` | AC-6, AC-9, AC-11 |
| **2** | `persist_hook_checksums_to_state()` on the `persist_settings_baseline_to_state` template; **field-scoped to the hooks this run actually deployed** — REFRESHED / INSTALLED / SYNC / MODE-REPAIRED — and **never** persisting the preserve arm's re-anchor. Called from `refresh_hooks_flow` after `install_hooks`, before `INSTALL_COMPLETE=1`. Never a `write_state_file` call | `docs/scripts/setup-workspace.sh` | AC-2, AC-9 |
| **3** | Git-history probe consulted **only** on the preserve branch. Adopt the shipped `classify_drift` semantics verbatim: three verdicts, a declared cap of 60, and *"an unfinished search is not a finding"*. STALE → refresh; DIVERGENT → preserve; UNCLASSIFIED-DEPTH / no git / shallow / unreadable → **preserve** | `docs/scripts/setup-workspace.sh` | AC-1, AC-4, AC-10 |
| **4** | `--reconcile-hooks`: `parse_argv` case label, `usage()` entry, and a flow that forces reconciliation to source without scaffold/token/skill phases. Named in the PRESERVED warning, replacing the non-converging "re-run to reconcile" | `docs/scripts/setup-workspace.sh` | AC-5, AC-10 |
| **5** | Decline signal: counter global inside the `REFRESH_HOOKS` block; `DECLINED: N hook(s) …` summary line; `exit 75` **after** `INSTALL_COMPLETE=1`; propagated through `main`. Then Phase 5c: **compute `PHASE5_DEPLOYED` before branching on `rc`**, discriminate `75` from other non-zero, and add the terminal `EX_INCOMPLETE` surface | `docs/scripts/setup-workspace.sh`, `update.sh` | AC-3, AC-12 |
| **6** | Post-refresh whole-bundle hash assertion — every deployed hook entrypoint hash-equals source or is accounted for by a recorded decline; non-zero on an unexplained mismatch | `docs/scripts/setup-workspace.sh` | AC-7 |
| **7** | Docs: the currency caveat (count-preserving, **not** a fifth condition) and the hook-bundle propagation clause | `core/rules/bypass-mode-readiness/block-destructive.md`, `release/references/pipeline/stage-12-execute.md`, `stage-13-close.md` | AC-8, Documentation Impact |

**Steps 1–3 are the high-value core.** Interrupted after step 3, both the forward latch and the already-latched instance are fixed and operator edits are protected — a coherent shippable increment.

---

## Stage Applicability Matrix

| Stage | #5251 | Verdict basis |
|---|---|---|
| **5 — Solutioning** | **APPLY** | T3 ∧ T4 fire. AC-1's "known platform version" named an outcome with no mechanism; the two folded cards enumerated **opposing** mechanisms for AC-5. The hotfix `SKIP-where-trivial` bias does not apply by its own terms — it is conditioned on no design uncertainty being surfaced, and the tickets surface it |
| **6 — Engineering** | APPLY | Write set non-empty, all-`unconstrained` |
| **7 — Dev Testing** | **APPLY** | Executable behaviour with an existing, agent-runnable fixture suite. Run the suite agent-side; do **not** plan a direct installer run — `setup-workspace.sh` is not on the script-execution allowlist |
| **8 — QA Testing** | **APPLY** | 12 reconciled criteria need per-criterion verdicts; the release's purpose *is* a functional change to a security-control publisher |
| **9 — Plan Review** | **APPLY (Light)** | `hotfix` review depth. Two items are carried to this gate — see § Operator Decisions Carried to Stage 9 |
| **10 / 11** | **COMPRESS** | Sub-tasks created, then closed with the Skip Closure Format |
| **12 — Execute** | **APPLY** | Atomic claim + signed annotated tag via the claim tool with `--bump patch --patch-base v4.67`, then the GitHub Release publish |
| **13 — Close** | **APPLY** | Version-keyed output set; the `version-less` carve-out does **not** apply |

---

## File Change Matrix

One path per line, `<path>  <VERB>`, fence-delimited for deterministic extraction.

```
# ── Production ──
docs/scripts/setup-workspace.sh                          edit
update.sh                                                edit

# ── Verification ──
core/deploy/tests/test_refresh_hooks.sh                  edit
.github/workflows/install-tests.yml                      edit

# ── Documentation ──
core/rules/bypass-mode-readiness/block-destructive.md    edit
# generator output of the fragment above — build-hook-registry.py, not hand-edited
core/rules/bypass-mode-readiness.md                      edit
# canonical home of the coverage-boundary statement the fragment restates — pulled in at the Stage-9 gate (D8, DEV-11)
core/standards/subagent-security-posture.md              edit
release/references/pipeline/stage-12-execute.md          edit
release/references/pipeline/stage-13-close.md            edit

# ── Decision record ──
core/ADRs/ADR-203-hook-refresh-discriminator-composition.md   add

# ── Release corpus ──
release/releases/plans/hook-publisher-republishes_RELEASE_PLAN.md   add
```

#### Read-only inputs

```
core/deploy/deploy.sh                                    READ
core/hooks/block-autonomy-ceiling.sh                     READ
core/hooks/block-skill-direct-edit.sh                    READ
core/config/allowlists/script-execution-allowlist.txt    READ
```

#### Release-wide explicit non-scope

```
core/deploy/deploy.sh                                    NOT EDITED
core/hooks/block-destructive.sh                          NOT EDITED
```

**The CONDITIONAL row is resolved and promoted in this commit.** The Stage-4 matrix carried `CONDITIONAL:stage5-selects-new-flag  docs/scripts/setup-workspace.sh  edit`. Stage 5 **did** select a new CLI flag (`--reconcile-hooks`), so the condition fired and the row is promoted into the unconditional set here, in the same commit as its resolution, per the authoring contract. It names a path already unconditionally present, so **no new path enters the matrix by that promotion**.

**One path was added, and one was declined and then pulled back in — all three recorded rather than made silently.** `core/ADRs/ADR-203-…md` is **added** on the Stage-6 instruction that the discriminator-composition record be authored at Commit 0; § Deviation Log carries the row with its authority. `core/standards/subagent-security-posture.md` is the amendment Stage 5 proposed and the hub deferred: it was **declined at Stage 5** and moved into explicit non-scope with the canonical-home sync named as a successor item (DEV-5), and it was then **pulled in at the Stage-9 gate** by operator decision D8, so the restatement and its canonical home agree at merge rather than diverging until a successor lands. It is now an `edit` row under *Documentation* and is no longer in non-scope (DEV-11).

**One path moved from READ-only to edit-permitted, scoped.** `.github/workflows/install-tests.yml` was declared **READ** in the matrix the operator locked at the Stage-4 gate. It is now an `edit` row under *Verification*, **bounded to the checkout-depth change and nothing else** — a single `fetch-depth: 0` on the `shell-tests` job's `actions/checkout` step, which is the only job in the file that runs `test_refresh_hooks.sh`. Nothing else in the workflow is in scope: no step, no matrix, no trigger, no permission. The other three jobs keep their shallow checkouts, so the cost stays job-scoped. § Deviation Log carries the row with its authority and the finding that justified it.

**Zero `add` rows for executables** → the new-executable companion obligation (an allowlist row + CI wiring) does **not** fire. The two `add` rows are a markdown ADR and this plan. `test_refresh_hooks.sh` is an `edit` of an already-allowlisted, already-CI-wired script.

**`core/ADRs/` adds no index obligation.** The release-module ADR index is generated only for `release/ADRs/`; `core/ADRs/README.md` is a curated thematic document with no projector and no projected region, so a core-only ADR addition trips no projection trigger. The whole-tree `adr-number-integrity` job still asserts the gap-free sequence, which is why the number was claimed against the mainline anchor rather than against a branch-local maximum.

### Agent-Editability Read

Transcribed from the Stage-4 derivation, controls read at the baseline commit. **Every row decided on conjunct 1** — no path carries a `*/skills/<name>/` segment, so the skill-gate's first conjunct is false everywhere and the exemption list's absence never becomes load-bearing.

| Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class |
|---|---|---|---|
| `docs/scripts/setup-workspace.sh` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| `update.sh` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| `core/deploy/tests/test_refresh_hooks.sh` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| `core/rules/bypass-mode-readiness/block-destructive.md` | ∅ — the Tier-0 `.claude/rules/*` arm names the **deployed** mirror, not `core/rules/`; this file is not a mirror-pair member | ∅ — conjunct 1 false | `unconstrained` |
| `release/references/pipeline/stage-12-execute.md` · `stage-13-close.md` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| `core/standards/subagent-security-posture.md` (added at the Stage-9 gate, D8) | ∅ — no `core/standards/` arm in the Tier-0 governance set, re-read at the amendment | ∅ — conjunct 1 false | `unconstrained` |
| `core/ADRs/ADR-203-…md` | ∅ | ∅ — conjunct 1 false | `unconstrained` |
| `release/releases/plans/hook-publisher-republishes_RELEASE_PLAN.md` | ∅ | ∅ — conjunct 1 false | `unconstrained` |

**Card class `unconstrained`; execution path: ordinary Engineering spoke.** All-`unconstrained` is the correct and informative output, not an omission. An `unconstrained` row means no control refuses the write — never that the change is ungoverned.

---

## Blast Radius

Method: markdown-tree default row (`domain: software` deliverable). Raw fan-out on the two production scripts is dominated by prose and archived release plans; the **behavioural** consumer set — anything whose verdict can flip — is narrow, and every member is dispositioned.

| Consumer | Disposition | Ground |
|---|---|---|
| `update.sh` Phase 5c | **UPDATED** | The AC-12 surface, plus the `PHASE5_DEPLOYED` ordering defect |
| `test_refresh_hooks.sh` `rc -eq 0` arms following a refresh | **accepted — cannot flip** | Every such fixture is built by the healthy-bundle helper; each hook takes the in-sync arm and returns before the refresh predicate is read, so no decline is reachable. **Stage-7 re-verifies this enumeration against the full `rc`-zero population** — see § Deviation Log DEV-3 |
| `test_refresh_hooks.sh` failure arms pinning 74 / 66 | **accepted** | `75` collides with none of them, and their fixtures decline nothing |
| `test_upgrade_config_durability.sh` Suite F `EX_NOCHANGE` | **accepted — not a real consumer** | Its workspace is built by a real fresh install, so baseline = deployed = source and the decline branch is unreachable |
| 38 other suites under `core/deploy/tests/` | **accepted** | Only `test_refresh_hooks.sh` mutates the checksum baseline; every other fixture is install-fresh, so the preserve branch is unreachable |
| `deploy.sh` Check 79 remedy constant | **accepted — no edit; becomes true** | It already names `--refresh-hooks`; today that names a carrier that silently no-ops on a latched instance, and after this release the instruction actually reconciles |
| `deploy.sh` Check 79 DIVERGENT string | **accepted — stays accurate** | It asserts that a republish will PRESERVE a *baseline-diverged* copy; post-fix a DIVERGENT copy still preserves. Only the STALE case changes, and that string makes no preservation claim |

**Mover-set is empty by construction** — the matrix declares zero renames or path moves — so the ref-form and path-literal consumer sweeps are N/A with reason rather than omitted.

---

## Risk Register

| # | Risk | Mitigation | Rating |
|---|---|---|---|
| **R2** | A **whole-map** persister actively clobbers operator edits on the second refresh — it converges the self-latch *and* the operator edit, indiscriminately | Structural, not sequencing: the persister is field-scoped to hooks this run deployed and never persists the preserve arm's re-anchor. Pinned by arm S-2, authored RED against a deliberately whole-map persister | **HIGH** / MODERATE |
| **R3** | The new decline exit status perturbs existing `rc -eq 0` assertions | All post-refresh `rc`-zero arms enumerated and dispositioned `accepted — cannot flip`, with the fixture reason. **Denominator stated rather than implied; Stage 7 re-verifies over the full population** | **LOW** / CHEAP |
| **R4** | A new suite arm passes without ever having been RED, measuring nothing | Every new arm is authored and observed RED before its fix lands, and the RED commit is pushed. The healthy-bundle fixture helper seeds a *healthy* baseline, which is exactly how an arm passes for free | **MEDIUM** / CHEAP |
| **R9** | **`EX_NOCHANGE` inversion.** A mixed refresh-plus-decline run loses `PHASE5_DEPLOYED` because Phase 5c returns before the flag is computed, so a genuinely-changed workspace can report "no changes" | Compute the flag from the captured output **before** branching on `rc`; the output is valid regardless of exit status | **MEDIUM** / CHEAP |
| **R10** | **Doc-cascade blowout.** Reading the Documentation Impact as "add a fifth condition" triggers a multi-surface governance cascade including a `SKILL.md` on a different execution path | Count-preserving currency caveat; the FOUR cardinality is untouched. The defect is an orthogonal currency axis, not a fifth condition — the card itself says every condition reads as satisfied | **LOW** / CHEAP |
| **R12** | The history probe degrades on a shallow clone, an absent `git`, or a source tree that is not a checkout, and silently overwrites | **Fail-safe direction is the load-bearing property.** Every degraded outcome resolves to PRESERVE — today's behaviour, unchanged. The change can only widen what is refreshed, never narrow what is preserved | **LOW** / CHEAP |

---

## Delivery Strategy

One branch `release/hook-publisher-republishes` off `origin/main`; one PR, opened in draft at Commit 0; one merge at Stage 12. Slices are commits on that branch, never separate PRs. Commit messages carry the `release(hook-publisher-republishes):` prefix and reference the source card. The PR body is parser-clean: close-family verbs adjacent to a number appear only in the dedicated Issue References block, and the card is transitioned to closed at Stage 13 rather than by an auto-close keyword on merge.

---

## Verification Plan

**Every method cell carries its command LITERALLY, with its operands.** A cell is dispatchable by the plan-driven verification executor `release/tools/verify-release-plan.sh` and reproducible from the cell alone, without resolving a token defined in the prose around the table. The earlier `SUITE` alias is **retired** for that reason: an alias resolved only in this paragraph is not a method a reader — or the executor — can run from the row.

| AC | Verification Method | Expected Result |
|---|---|---|
| **AC-1** | `bash core/deploy/tests/test_refresh_hooks.sh` — the latched-baseline arm on fixture **L** | `REFRESHED:` emitted for the latched hook; deployed hash = source hash |
| **AC-2** | `bash core/deploy/tests/test_refresh_hooks.sh` — the arm reading `hook_checksums[H]` from the state file after a refresh | Equals the **source** hash, not the pre-refresh baseline |
| **AC-3** | `bash core/deploy/tests/test_refresh_hooks.sh` — the decline-status arm | Non-zero status **and** a summary line naming the declined count |
| **AC-4** | `bash core/deploy/tests/test_refresh_hooks.sh` — the platform-version-axis pair | must-flag (**L**) → `REFRESHED`; must-not-flag (**E**) → `PRESERVED` · control: both arms drive the same instrument and return **different** verdicts |
| **AC-5** | `bash core/deploy/tests/test_refresh_hooks.sh` — the `--reconcile-hooks`-against-a-DIVERGENT-fixture arm | The divergent instance converges to source without a full bootstrap |
| **AC-6** | `bash core/deploy/tests/test_refresh_hooks.sh` (full run) | 0 failed; arm count ≥ its pre-change count of **51** |
| **AC-7** | `bash core/deploy/tests/test_refresh_hooks.sh` — the post-refresh bundle-currency assertion arms | Every deployed hook hash-equals source or is a recorded decline · control: plant one unexplained mismatch → non-zero |
| **AC-8** | `grep -n 'refresh-hooks' release/references/pipeline/stage-12-execute.md release/references/pipeline/stage-13-close.md` | ≥1 match naming the invocation · control: the same grep at the baseline returns **0** in both shards, so a post-change non-zero is attributable |
| **AC-9** | `grep -n 'persist_hook_checksums_to_state' docs/scripts/setup-workspace.sh` | ≥1 definition + ≥1 call from `refresh_hooks_flow` · control: the same grep at the baseline returns **0**, with `hook_checksums` → 4 as the live sensitivity arm |
| **AC-10** | `bash core/deploy/tests/test_refresh_hooks.sh` — the arm that captures the `PRESERVED` text and runs exactly the remedy it names | The remedy changes the observed state |
| **AC-11** | `bash core/deploy/tests/test_refresh_hooks.sh` — the plant-stale-baseline demonstration arm | Pre-state and post-state hashes differ; both recorded |
| **AC-12** | `bash core/deploy/tests/test_refresh_hooks.sh` — the Phase-5c discrimination arms on a fixture carrying one declined hook | The decline is visible in the caller's own status, not only in the delegated script's inline warn |

**A literal `bash …` cell is dispatchable but is NOT executed by the executor, by that tool's own design.** Its `RUNNABLE_VERBS` set is deliberately closed to read-only queries (`grep test ls head wc cat`), on the stated principle that a verification harness driven by an authored artifact must not acquire a code-execution channel when the same pull request can author both. The suite rows are therefore expected to read as an honest, reasoned SKIP or ERROR naming the verb rather than as a PASS; their mechanical guarantee lives in the suite's own CI-invoked run (`Shell harness (macOS)`), which is a gate in its own right. The two `grep` rows are the cells this executor does run.

**The whole plan's control arm is step 1 of the Implementation Sequence.** Every new suite arm is authored and observed **RED** before the fix lands, then GREEN after. An arm that was never RED is not evidence that the fix did anything.

**Engineering re-measures, never computes, the two `51` totals** recorded as measured quantities in the suite's own mutation-record comments. Both halves of each pair are re-observed on the same tree.

---

## Cross-Issue Acceptance Criteria

**Structurally empty — declared, not omitted.** A `CIAC-N` spans an issue *pair*; this release has one content member, so the candidate population is empty by construction rather than by an unfinished search. Stage-9 QC3.5 reads this declaration and correctly finds nothing to verify.

---

## Quota Budget

Stage-4 Checkpoint A estimate for a `hotfix` at n=1: Stages 5 / 6 / 7 / 8 as single spokes, Stages 10 / 11 compressed to closure comments, Stages 9 / 12 / 13 hub-run. No fan-out lane exceeds one concurrent spoke under P0.

---

## Release Class declaration

**`hotfix`** — rendered by the operator at the Stage-4 plan-approval gate (D2). Differentiation posture: **Light** Stage-9 review depth, **7-day** outcome window, no skips beyond the compressed 10/11, and a single Cross-Issue-free acceptance surface.

**The class re-test fired and is carried, not decided here.** The Stage-4 plan's own trigger states that if Stage 5 selects the git-history discriminator instead of a force flag, that adds a new classification mechanism inside the publisher and the class must be re-tested at the Stage-5 review. **The design selects it.** Stage 5 recommended the class **stands** — the history probe is the remedy a folded card already prescribed rather than a novel protocol; it introduces no new contract *between* components, being a second oracle consulted inside one existing function; and the one genuinely new inter-component contract, the `75` decline code, rides an exit-status channel the caller already consumes. Stage 5 flagged that a reasonable operator could disagree on the third ground. The hub **deferred the re-test to the Stage-9 GO/NO-GO gate**, which is operator-facing and is where the class's only remaining consequence — review depth, Light versus Deep — is consumed. Nothing between Commit 0 and that gate depends on the answer.

---

## Rollback Strategy

`git revert -m 1` of the merge commit restores `main` byte-for-byte. Every row is an additive or bounded edit to tracked files plus two new markdown files; there are no schema changes, no file-format changes, no package rebuilds, and no data migration.

**Instance-side rollback is already covered and is not this release's to build.** The refresh path captures a durable pre-refresh bundle snapshot before its first write, and a restore flow recovers from it after a refresh has already succeeded. A workspace that ran the new publisher and then wants the old bundle uses that path.

**The version tag is retained, never deleted.** If this release is rolled back after Stage 12, revert the merge and record the rollback; the tag remains as the record that the version was claimed and then withdrawn. Version tags are host-protected and no account can delete one on the remote.

---

## Operational Deployment Manifest

| Surface | Propagation | Mechanism |
|---|---|---|
| `docs/scripts/setup-workspace.sh` · `update.sh` | **Repository-only** — both are invoked from the source repo by path; there is no deployed copy to sync | none required |
| `core/deploy/tests/test_refresh_hooks.sh` | **Repository-only** — CI-executed and agent-executed from the repo | none required |
| `core/rules/bypass-mode-readiness/block-destructive.md` | **Repository-only** — not a mirror-pair member, so no Check-9 obligation attaches | none required |
| `release/references/pipeline/stage-12-execute.md` · `stage-13-close.md` | **Repository-only** | none required |
| `core/ADRs/ADR-203-…md` · this plan | **Repository-only** | none required |

**`deliverable_state: deployed-copy-synced`** — the release declares **no** Layer-2 propagation target, which is the "or the release declares no propagation target" limb of that state's exit condition, satisfied here explicitly rather than by omission.

**Hook-bundle propagation is the release's own subject.** The deploy script does not propagate the deployed hook bundle; the refresh invocation does. That is the clause AC-8 lands in the Stage-12/13 guidance.

---

## Deviation Log

| # | Deviation | Authority | Disposition |
|---|---|---|---|
| **DEV-1** | **The Stage-4 implementation sequence steps 2–4 are superseded.** Step 2's whole-map persister is replaced by a field-scoped one; steps 3–4 are replaced by the history-probe discriminator plus a recovery flag | Stage-5 design § Output for Stage 6, accepted by the hub's R1 evaluation, which re-verified the persister finding independently | **APPLIED.** § Implementation Sequence carries the ratified sequence |
| **DEV-2** | **The `version-less` release identity is overturned to `versioned` / `patch`.** The Stage-4 plan emitted no stamp token; this file carries one | Operator decision D3 at the Stage-4 gate | **APPLIED.** § Header carries the token; § Commit-0 Version Re-Verify Record carries both halves |
| **DEV-3** | **R3's downgrade rests on a narrower enumeration than the population.** Three post-refresh `rc`-zero arms were dispositioned; the suite carries nine `rc`-zero assertions in total, and whether the other six sit behind fixtures that can reach the decline branch is not established | Hub R1 evaluation of the Stage-5 design | **CARRIED to Stage 7.** Enumerate every `rc`-zero assertion following a refresh in the delivered suite and disposition each against the new decline contract. If the enumeration is still three, LOW is confirmed on a stated denominator |
| **DEV-4** | **One path added to the operator-locked File Change Matrix:** `core/ADRs/ADR-203-hook-refresh-discriminator-composition.md`. Stage 5 named the record under the slug-token discipline and created no ADR issue; the matrix ratified at the Stage-4 gate carried no path for it | Stage-6 sub-task instruction, which directs that the record be authored at Commit 0 | **APPLIED.** The row is in § File Change Matrix under *Decision record*; the number is claimed against the mainline anchor |
| **DEV-5** | **One path declined from the matrix:** `core/standards/subagent-security-posture.md`, which Stage 5 proposed adding as the canonical home of the coverage-boundary statement | Hub disposition — a scope addition against an operator-locked matrix is the operator's call. Engineering executes the stated fallback | **FALLBACK EXECUTED.** The currency caveat is written into the approved path only, count-preserving; the canonical-home sync is named as a successor item and the amendment is carried to the Stage-9 gate, where the operator can still pull it in before merge |
| **DEV-6** | **The `hotfix` class re-test fired** on the Stage-4 plan's own trigger, because Stage 5 selected the git-history discriminator | Hub deferral | **CARRIED to Stage 9**, where review depth is consumed |
| **DEV-7** | **Implementation-sequence steps 3–6 landed in ONE commit** rather than four. They share one code block and one pair of outcome ledgers: the discriminator decides the preserve branch, the decline summary reads the set that branch populates, the currency assertion reads the same set to account for a legitimate mismatch, and the reconcile flow is a force arm sited inside the same refresh block | Engineering judgement, surfaced rather than taken silently | **APPLIED — minor.** Split apart, the intermediate commits would have been red for reasons unrelated to the limb under test, which destroys the attribution the RED-first discipline exists to create. The RED→GREEN pairing is preserved at the arm level: every affected arm was observed RED at the fixtures commit and GREEN after, and each arm names the criterion it serves |
| **DEV-8** | **The AC-12 arms are SOURCE-ORDER assertions over `update.sh`, not a live update run.** Driving `./update.sh` end to end needs a full sandboxed instance and exits in preflight against anything less, so an arm built that way would report on preflight rather than on Phase 5c | Engineering judgement, with the bound written into the suite source | **APPLIED — minor, and not a weaker proxy for the property under test.** The defect is an ORDERING defect: where the deployed-flag read sits relative to the `rc` branch IS the bug and IS the fix. The arms were observed RED by restoring the pre-fix file beneath them. Live end-to-end exercise of Phase 5c is Stage-7/8 scope |
| **DEV-9** | **One path moved from READ-only to edit-permitted in the operator-locked File Change Matrix:** `.github/workflows/install-tests.yml`, scoped to the checkout depth and nothing else — `fetch-depth: 0` on the `shell-tests` job, the only job in the file that runs `test_refresh_hooks.sh` | Operator decision D6, rendered at the Stage-6 iteration-2 routing point, amending the matrix ratified at the Stage-4 gate. Same class of record as DEV-4 (a path added) and DEV-5 (a path declined), resolved the other way | **APPLIED.** The finding that justified it: `hook_history_classify()` guards on `git rev-parse --is-shallow-repository` and returns `UNCLASSIFIED-DEPTH` for any answer but `false` — a **binary test on shallowness, not a depth threshold** — so no partial `--deepen` reaches the `STALE` verdict the five `report_hist` arms assert, and no in-suite fix exists. The gap was **OBSERVED, not inferred**: at head `63817750` the required `Shell harness (macOS)` check read GREEN while its log reported `72 passed, 0 failed, 5 skipped` plus `!! NOT FULL COVERAGE`, so a colour-only read recorded a pass over five unmeasured subjects — among them `13-L`, the latched-platform scenario this release is named after, and `13-control`, the arm proving the classifier discriminates. The suite's loud-skip mechanism is **RETAINED unchanged** as the compensating control for any environment that is still shallow; with full history it stops firing rather than being weakened |
| **DEV-10** | **One path landed outside the operator-locked File Change Matrix as ratified:** `core/rules/bypass-mode-readiness.md`, the **generated** hook-registry index. It is `build-hook-registry.py` output over the source fragments, and the matrix carried its fragment `core/rules/bypass-mode-readiness/block-destructive.md` but not the index the fragment regenerates. The edit is therefore a **product of an in-scope fragment edit**, not new scope: no line of it was hand-authored, and re-running the generator against an unmodified fragment set reproduces it | Hub fix directive at the Stage-7 → Stage-6 iteration-3 routing point, whose item **DT-6** ordered the regeneration after the fragment was edited — a **Tier-1 [ADJUST]** under the already-approved plan. Same class of record as DEV-4 (a path added) and DEV-9 (a path's verb amended); recorded here rather than left implicit because the matrix is the deterministic-extraction surface and every other delta to it carries a row | **APPLIED.** The row is in § File Change Matrix under *Documentation*, directly beneath its fragment and carrying an in-fence comment naming the generator, so a reader of the fence alone cannot mistake it for a hand-edited doc. The gap was **OBSERVED, not inferred**: at head `86757cf6` `git diff --name-only origin/main...HEAD` returned **10** paths against **9** declared rows, with this exact path absent from the plan at **0** occurrences while its fragment appeared at 6 — measured by the Stage-7 re-verification and confirmed by the hub's independent parse. With this row the two surfaces agree at **10** |
| **DEV-11** | **One path added to the operator-locked File Change Matrix, reversing DEV-5's decline:** `core/standards/subagent-security-posture.md`, the canonical home of the coverage-boundary statement that `block-destructive.md` restates. At Stage 5 the path was declined and the currency caveat was written into the restatement only, so the restatement ran **ahead of its canonical source** — the divergence duplicate-source-discipline forbids, carried to the Stage-9 gate as PA-003 | Operator decision **D8** at the Stage-9 gate (carried as `AI-002` in the release's action-items ledger), amending the matrix ratified at the Stage-4 gate. The hub had recommended routing it forward as a named successor; the operator chose to pull it in so the two surfaces agree at merge. Same class of record as DEV-4 (a path added) and DEV-9 (a path's verb amended) | **APPLIED.** § 3.1 of the standard now carries the caveat in the standard's own register, with the same substance as the registry entry: currency is orthogonal to the four conditions and deliberately not a fifth; the mechanism is the publisher, not the hook; verify by refreshing the bundle and reading the result, not by re-reading the conditions. The row is in § File Change Matrix under *Documentation* with an in-fence comment naming the amendment; the path is removed from *Release-wide explicit non-scope*; § Agent-Editability Read carries its row (`unconstrained` on conjunct 1, the Tier-0 set re-read at the amendment); § Documentation Impact carries the commit. DEV-5's disposition stands as the record of what happened at Stage 5 — this row is what happened at Stage 9 |

---

## Documentation Impact

| Issue | Declared docs | Status | Commit | Notes |
|---|---|---|---|---|
| #5251 | `core/rules/bypass-mode-readiness/block-destructive.md` — the coverage-boundary note | **UPDATED** | `086615a9` | Count-preserving currency caveat. The FOUR cardinality is untouched — **measured, not asserted**: cardinality-bearing phrases count **3 before and 3 after**. Conditions 1–4 decide whether the control *runs at all*, whereas this defect is that it runs and enforces a superseded version; the card itself calls it a fifth *failure mode*, not a fifth condition |
| #5251 | `release/references/pipeline/stage-12-execute.md` · `stage-13-close.md` | **UPDATED** | `086615a9` | AC-8 — the hook-bundle propagation clause, landing as the third sibling of an existing convention rather than a new section. Stage 13 gains a conditional `B-OPS4.5` beat that records N/A-with-reason when no hook source changed, so the no-op is honest rather than silent |

---

## Verification Evidence

*Populated at Stage 6 C4 self-verification; extended at Stage 7 and Stage 8.*

| Check | Result |
|---|---|
| **Pre-change suite baseline** (the control arm for every new arm) | `bash core/deploy/tests/test_refresh_hooks.sh` at the pinned baseline → **51 passed, 0 failed**, exit 0, bash 3.2.57 |
| **Post-change suite** | Same invocation on the delivered tree → **77 passed, 0 failed, 0 skipped**, exit 0, bash 3.2.57. **AC-6 satisfied on a stated denominator:** 77 ≥ the pre-change count of 51; the release adds **26** arms. Re-measured at head `86757cf6` after the DT-1 and DT-5 arms landed — the earlier **75 / +24** reading predates them and was never advanced arithmetically |
| **RED-then-GREEN, per limb** | Every new arm was observed RED before its fix. `d0930d15` → 56/14 (the fixtures commit, against a deliberately whole-map persister); `f6f04800` → 58/12 (field-scoped persister); `ffe64e97` → 70/0 (discriminator, reconcile, decline, currency); `d85b4683` → 75/0 (AC-12 arms, observed RED at 71/4 against the restored pre-fix `update.sh`) |
| **Commit-0 version half** | `git fetch --tags origin`; next-free for bump-class `patch` on patch-base `v4.67` = **`v4.67.1`**, free across all three `claimed_set()` arms. Denominator 209 published Releases (re-read at `--limit 5000` after a first read at `--limit 200` returned exactly 200), 16 `v4.6*` origin tags, 1 RELEASE_LOG row. Sensitivity: the same three readers on the `v4.67` slot return 1, 16 and 6 — all live, so the zero on `.1` is a real negative. **No HALT** |
| **Commit-0 manifest half** | `release/tools/claim-version.sh --verify-stamp hook-publisher-republishes` → **exit 0**, *"manifest resolvable; plan-only manifest"*. Exactly one double-brace `RELEASE_VERSION` placeholder in this file (the Header `**Version**` cell), so the stamp has a single verifiable resolution site. **Self-caught during C4:** the first draft carried the literal braced form at three prose sites as well, which the claim tool's global substitution would have rewritten into the prose at Stage 12; measured at 4 occurrences, corrected to 1 |
| **AC-8 control arm** | `refresh-hooks` occurrences in the two pipeline shards: **0 and 0** at the baseline, **1 and 1** after. Sensitivity on the same reader and token over `update.sh` and `deploy.sh` → 4 lines each, so the pre-change zero is a real negative and the post-change match is attributable |
| **AC-9 control arm** | `persist_hook_checksums_to_state` occurrences in `docs/scripts/setup-workspace.sh`: **0** at the baseline; after, 1 definition plus 1 call from `refresh_hooks_flow`. Sensitivity: `hook_checksums` at the baseline → non-zero, so the reader resolves |
| **Doc-link integrity** | The link-resolver primitive over all four changed/added markdown files with `--require-targets` → **no findings**, exit 0. `check-release-links.py --plan-depth-lint` → **no findings**; its own `--self-test` passes and asserts that lint *"scopes and fires correctly"*, which is the sensitivity arm for that zero |
| **Mutation re-measurement** (every total observed, never arithmetic) | **On the 75-arm tree:** mode-template rename → **74 passed / 1 failed**, the precondition arm failing alone while the preserve arm still passes vacuously, which is exactly the pair the comment describes; cohort-seed move → **74 passed / 1 failed**, the confinement guard failing alone; the same move with the guard **excised** → **74 passed / 0 failed**, the silent-retirement state the guard converts into a named failure. **At head `86757cf6` (77 arms):** unmutated → **77 passed / 0 failed / 0 skipped**, re-measured. The three mutated halves are **NOT re-run at this head** — they are recorded against the 75-arm tree they were measured on rather than advanced to a 77 denominator they were never observed against, per the RE-MEASURED rule the suite comment states. Re-running them at this head was attempted in the Stage-6 iteration-4 pass and was stopped by an environment control before the mutated run could execute; it is surfaced to the hub as an open item rather than derived |
| **ADR index freshness** | **N/A — this release adds no record under `release/ADRs/`.** The one ADR added is under `core/ADRs/`, which has no projector and no projected region, so no index regeneration is triggered. The honest no-op, recorded rather than silent |
| **ADR number integrity** | Claimed **203** against a mainline anchor of **202**, read from the repository's own detector on `origin/main` rather than from a branch-local maximum. Detector reports `CLAIM ADR-203 … BINDS`; the integrity checker reports **PASS (203 ADRs, contiguous 001..203, no duplicates)**. The ADR durability lint over the new record reports **COUNT 0** |
| **Mirror-pair parity** | **N/A — no mirror-pair member is added, removed or renamed.** `core/rules/bypass-mode-readiness/block-destructive.md` is not a member of the mirrored set |
| **Skill-package freshness** | **N/A — no path in the change matrix sits under a rostered skill tree, and none is a packaging input.** Resolved against the roster rather than eyeballed |
| **Shell syntax** | `bash -n` over both edited production scripts → clean |
| **Runtime suite** | `test_refresh_hooks.sh` is the mapped suite for this code path, run after every slice; the per-slice counts are in the RED-then-GREEN row above |

**One probe was mis-read and is recorded rather than quietly re-run.** The release-links checker prints *"0 broken links across 0 files"*, and the second number is **files carrying findings**, not files scanned. Read as a scan count it looks like a vacuous zero, and it was — until the reading was checked against the tool's own source. The zero is genuine; the first reading of it was not evidence.

---

## Change Description

*Authored at Stage 6 Phase C1 per RELEASE_PROTOCOL § Change Description Protocol. Operator-facing.*

### Outcome

**A merged security-hook fix now reaches the running instance, and a hook that is deliberately left behind says so.**

Before this release, `--refresh-hooks` would overwrite a deployed hook only while its content still hashed to the value the installer last recorded. That baseline is written by a full installer run; the bundle it describes is advanced by the update path. The two drift apart on any instance that is actually maintained — on the instance where this was found, the recorded value, the deployed file and the repository source were three different hashes. From that point the publisher read every platform-updated hook as an operator edit, declined to touch it, and **exited zero**. The full-update path delegated to the same code and inherited the same outcome. Both documented ways to update hooks were inoperative, and both reported success.

Three things change:

- **The baseline stops going stale.** The path that deploys a hook now records it, so the self-latch cannot form going forward.
- **An already-latched instance is repaired without operator judgement.** When the baseline says "different", the publisher asks the source repository's own history whether the deployed bytes are simply an older platform version. If they are, it updates. If they match no revision, it preserves — that is a genuine operator edit and it is not the publisher's to overwrite.
- **A decline is loud.** The run names each hook it left behind and exits non-zero, and `./update.sh` surfaces that instead of folding it into a warning.

### Issues resolved

One content member: the hook-publisher defect card, against its twelve-criterion reconciled acceptance set. Every criterion has a named verification method and a landed arm; the suite grew from 51 arms to 77.

### Key decisions

**The persister is field-scoped, and that is the decision that changed the design.** The planned fix was to write the checksum map back to the state file after a refresh. Reading the preserve branch closely shows it does not only warn — it re-anchors the baseline to the *deployed* bytes. Persist the whole map and the *next* refresh reads that re-anchor as permission to overwrite, so a genuine operator edit is not protected, its destruction is merely deferred by one run. The release carries the proof as a standing regression arm: it was authored against a deliberately whole-map persister, observed destroying an edit on run 2, and only then did the correct implementation land.

**The discriminator is adopted, not invented.** A three-valued history classifier with exactly the needed semantics already shipped in the deploy checker, and its own header names this misclassification. The verdicts, the walk cap and the rule that an unfinished search is not a finding are taken verbatim, so the two copies cannot disagree. The duplication is registered with a named successor extraction rather than hidden.

**The force path is a recovery role, not the discriminator.** The two folded source cards appeared to prescribe opposing remedies. They are answers to different questions — what *decides*, and what an operator *does* about a divergence only they can adjudicate — so both ship, each with its role stated.

**Fail-safe direction.** Every degraded outcome — no `git`, a shallow clone, a source tree that is not a checkout, a history deeper than the cap — preserves. This release can only widen what is recognised as refreshable; it can never narrow what is preserved.

### Reversibility

**CHEAP · confidence HIGH.** Additive edits to tracked files plus two new markdown files, one branch, one merge: `git revert -m 1` restores `main` byte-for-byte. No schema change, no file-format change, no package rebuild, no data migration. Instance-side, the refresh already captures a durable pre-write bundle snapshot and `--restore-hooks` recovers from it. The version tag is retained and recorded rather than deleted if the release is withdrawn.

### Downstream impact

`./update.sh` gains one terminal status it did not previously have: a run that completes but leaves a security control superseded now exits non-zero rather than reporting success. That is the intended behaviour change and the one a caller might notice — a script that treats any non-zero from `./update.sh` as a failed update will now see a status meaning *"the update applied, and one named control did not"*. The `EX_NOCHANGE` contract is unchanged in intent and strictly more accurate in practice: a mixed run that refreshed some hooks and declined one previously lost its deployed flag and could report "no changes" over real work.

No deployed copy, mirror or package is affected; this release declares no Layer-2 propagation target.

### Cross-references

The decision record for the composition is `core/ADRs/ADR-203-hook-refresh-discriminator-composition.md` on this branch. The pipeline guidance for propagating a hook-bundle change — and for reading the refresh's exit status — is in the Stage-12 and Stage-13 shards, and the currency caveat is in the `block-destructive` registry entry **and** in the canonical home that entry cites, `core/standards/subagent-security-posture.md` § 3.1 — the two carry the same statement, pulled into agreement at the Stage-9 gate (D8) rather than left to diverge until a successor landed.

---

## Baseline pin

`origin/main` @ **`f07b944a`** (`f07b944a9ea40f8b8174f0b30304678b731f6871`), measured at Stage-4 Phase A0, re-confirmed by the hub's R1 evaluations of both the Stage-4 plan and the Stage-5 design, and re-confirmed unmoved at Engineering Commit 0 — the release branch is cut from exactly this commit. Read by the Stage-9 mid-pipeline divergence re-check.

---

## Issue References

<!-- repo-integrity: allow-issue-ref — limb 1: a release plan's member enumeration IS its subject matter; the numbers are the release's own scope, not prose citations, and relocating them would delete the plan's scope statement -->

The single content member of this milestone is transitioned to closed at Stage 13, by the Stage-13 close-out on the merged PR rather than by an auto-close keyword in the PR body.

- **#5251** — `setup-workspace.sh --refresh-hooks` silently deploys nothing once the checksum baseline goes stale, so merged hook fixes never reach the instance. Carries the twelve-criterion reconciled acceptance set.
- **#7039** — folded source card; supplied the operational definition of *known platform version*, the byte-exact falsification of the operator-edited classification, and the constraint that the git-history test fill the discriminator role rather than a force flag.
- **#7204** — folded source card; supplied the self-latch mechanism, the `persist_hook_checksums_to_state` identifier, and the prior decision that the refresh path must not call the whole-document state writer.
- **#7509 · #7510 · #7511** — the Stage-4, Stage-5 and Stage-6 hub sub-tasks carrying the plan source, the design, both adversarial evaluations, and the D2/D3 decision record.
