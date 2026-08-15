<!-- reference-durability: allow-link -->
# Release Plan — hooks-enforce-under-adversity

> **Milestone:** `hooks-enforce-under-adversity` · **Release Class:** `cross-cutting` · **Version:** slug-identified; the concrete number is **bound at the Stage-12 atomic claim** *(bump-class `minor`)* · **Scope:** 5 issues, 18 raw / 23 effective pts (G3-15 bound 25) · One release branch, one PR, one merge gate · **Branch:** `release/hooks-enforce-under-adversity` (slug-only, no version prefix).

This plan is the Stage-4 release plan (rendered 2026-08-15 Saturday) written to disk as **Engineering Commit 0** by the first Stage-6 spoke, reconciled with the operator's Stage-4 plan gate, the **Plan Amendment** recorded at the Stage-5 W1/W2 return, and the Stage-5 Solutioning outputs for Waves 1 and 2. **Where the Stage-4 plan and the Plan Amendment disagree, this file carries the amended position** — the superseded model is recorded as such rather than silently dropped, so a reader can see both the original reasoning and its correction. Deltas discovered after this commit are folded into the Deviation Log rather than silently applied.

**Reference discipline for this file.** Cards are named by their wave position and their capability, not by bare ticket number, so this plan stays readable when the numbers age out of anyone's head. Every bare ticket reference is confined to the designated block at the end, each with a summary noun phrase, per the reference-durability standard.

| Wave | Short name | Capability |
|---|---|---|
| **W1** | **fixture-exemption** | A home path is reported as a leak regardless of the username it carries; the per-line marker becomes the sole exemption |
| **W2** | **dependency-floor** | A hook whose dependency library is corrupt denies with a named cause instead of exiting silently |
| **W3** | **destructive-matcher** | The destructive-rule matcher reaches the same verdict however an invocation is spelled or prefixed — two arms, one build unit |
| **W4** | **egress-loop-form** | The egress api-path matcher adjudicates an invocation inside a loop body, and every invocation rather than the first |
| **W5** | *terminal, not a card* | The generated hook-readiness index is regenerated once, after every fragment edit has landed |

## Version identity — NOT bound in this plan

The release runs **slug-identified**. No version literal appears in this file, in the branch name, or in any commit subject on this branch; the concrete number is recomputed next-free and claimed atomically at the Stage-12 merge tag (defer-to-claim, per ADR-092). The durable declaration here is the **bump-class (`minor`)**, not a number. The in-flight version reference is the unresolved `{{RELEASE_VERSION}}` token, which `claim-version.sh` resolves on the CAS-win path and which is simultaneously the claim-state oracle the identity-conformance check reads.

**Commit-0 version re-verify — executed, verdict PROCEED.** Run by the first Engineering spoke immediately before this file was written, per the codified single detect-and-HALT procedure:

| Step | Result |
|---|---|
| Refresh authoritative host state | `git fetch --tags origin` + `git fetch origin main` — both clean; `origin/main` at `320cfa27` |
| Recompute next-free for bump-class `minor` | `anchor(origin/main) + 1`, with the anchor established by two independent methods (`git describe --tags --abbrev=0` and a `git tag --merged` version-sort) that agree |
| Planned slot in the claimed set? | **No.** The remote-tag arm returned zero for the slot against an observed non-zero control on the preceding version; the ledger arm, read from the origin ref and never a worktree copy, agreed |
| Verdict | **PROCEED** — the planned slot equals the recomputed next-free and is unclaimed |

**The tag arm is authoritative; the ledger arm corroborates only.** This release has already observed the two arms disagreeing in the direction that matters: a sibling's tag was merged into the mainline while the mainline ledger still carried **zero** rows for it, because that sibling's Stage-12 chore PR had not yet landed. A re-verify consulting only the ledger returns a **false PROCEED** in that window and writes a plan file declaring a version another release has already shipped. Gate on the tag.

**This is a re-spawn of Wave 1.** The first W1 attempt HALTED correctly at this rung — the slot recorded at Stage 4 had been claimed by an in-flight sibling roughly three minutes before that spoke fetched. It wrote nothing: no branch, no commit, no PR. The operator re-rendered the determination against fresh state and re-spawned. The re-verify is a **single** detect-and-HALT: it does not auto-recompute-and-retry, which is why the second look had to come from the operator rather than from the spoke. Two further siblings remain in flight and were resolving to the same slot, so a re-anchor at the Stage-12 claim is **expected, not exceptional** — that is the atomic-claim rung's job, not this one's.

## Summary (30 seconds)

Five defects, one thesis: **a control's verdict must not depend on how its input is spelled, and a control that cannot evaluate its input must deny.**

- **W1 (fixture-exemption)** deletes a username-keyed exemption that silently cleared a genuine home path under any of ten common account names, on both the macOS and Linux forms. The already-shipped per-line marker becomes the sole exemption. Removing the defective axis rather than tuning it is the whole point: a username can never distinguish fixture from real, because the two are the same string.
- **W2 (dependency-floor)** closes a hole beneath every hook — a syntactically-valid corrupt dependency library terminates the hook *inside the guard's own condition*, so the guard cannot report its own failure. This is the release's largest card and carries its only ADR.
- **W3 (destructive-matcher)** is two tickets built as one work unit: they share four of four files, the same rule, and adjacent arms of one matcher. Quote-stripping and command-position normalization on one arm; an assignment-prefix skip on the other.
- **W4 (egress-loop-form)** closes a fail-open where a large batch of write invocations inside a loop body passed unadjudicated, and widens evaluation from the first invocation to all of them.

**Release Class `cross-cutting` — CONFIRMED and unchanged by the amendment.** Trigger (c) requires at least three in-bundle compositional edges; six remain after the contention correction. **Concurrency posture P0 fully-serial**, D-C `SINGLE` topology — derived from the contention map, not chosen defensively. **Quota Budget: WARN** (envelope `UNSTATED`). **Five cross-issue acceptance criteria.** No Tier-0 premise rejection on any card.

**The sharpest risk is not a card — it is the absence of a shakedown window.** Three of the five tightenings land on hooks that have **no warn dial at all** and go live hard on deploy. Only the egress card gets a warn window. That asymmetry is stated in the Risk Register and is a Stage-9 briefing obligation.

## Change Description

*Phase C1 (G6-05). This section is authored by the FINAL Stage-6 Engineering spoke, after every per-issue commit has landed, so that it describes what shipped rather than what was planned — per RELEASE_PROTOCOL § Change Description Protocol. It is committed on the release branch BEFORE the PR is transitioned draft→ready at the Stage-9 gate, so it is visible in the PR diff at Plan Review. The section anchor is established here at Commit 0; its six sub-sections (Outcome / Issues resolved / Key decisions / Reversibility / Downstream impact / Cross-references) are filled at Phase C1.*

## Dependency Graph

**No card blocks another** — all five are independently buildable. Every edge is a **compositional** (shared-surface or convention) edge, which is precisely what the cross-cutting Release-Class trigger counts.

| Edge | Type | Direction | Evidence |
|---|---|---|---|
| fixture-exemption → all four others | **convention** | W1 first | After the deletion, any test fixture or rendered brief embedding a home path must carry the per-line marker. Landing it first is what keeps later waves from needing a retro-marking pass. **Rationale replaced by the amendment — see below.** |
| dependency-floor → destructive-matcher | file-region | W2 first | Both edit the destructive hook. W2 edits the top-of-file dependency guard; W3 edits the rule body. Different regions, same file — ordering avoids a rebase, not a semantic block. |
| destructive-matcher's two arms | **identity** | merged | Four of four files shared, same rule, adjacent arms. Built as one work unit; both tickets stay separately tracked. |
| egress-loop-form → (none) | — | any | Its only shared surface is the regenerated index. |
| all fragment-editors → the generated index | build | terminal | Every fragment edit invalidates the generated index; it is regenerated once at W5. |

**Zero circular chains.** The edge set is a DAG over five nodes; the only bidirectional relation is the destructive-matcher pair, which the build-unit merge collapses to a single node.

### The W1-first rationale was replaced, and the conclusion survived

Recorded explicitly, because a plan whose conclusion survives on a replaced rationale is exactly the kind of thing that rots silently.

**Superseded premise (Stage 4):** W1 was sequenced first *because its exemption-mechanism decision set the release's contention topology* — a per-line marker was priced at five test files and twenty-seven fixture lines, colliding with every other card.

**That premise is false.** Those fixture-bearing test files reference the detection primitive **zero times each**; they are payload files, not consumers. Nothing evaluates them against the exemption. W1 sets no contention topology either way.

**W1-first nonetheless holds, on a different and stronger rationale — INT-1.** After the username exemption is deleted, a later-wave spoke brief that quotes a hook-test payload containing a home path is flagged by the orchestrator's pre-spawn brief scan, and **the hub refuses to spawn**. The constraint binds the orchestrator, not only Engineering. Landing W1 first means every later brief is authored under the rule; landing it last would flag briefs already rendered.

## Implementation Sequence

Dependency-ordered, D-C `SINGLE` topology, **P0 fully-serial** — one Engineering chip at a time, the next waiting until the prior commit lands on the release branch.

| Wave | Card(s) | Why here |
|---|---|---|
| **W1** | fixture-exemption | Establishes the fixture-marking convention every later wave's new fixtures and rendered briefs must honour (INT-1). |
| **W2** | dependency-floor | The floor beneath every hook. Edits the top-of-file dependency guard in three always-enforce hooks — including the destructive hook, so it must precede the rule-body edits. Carries the ADR and the cross-cutting guarantee-prose rewrite. |
| **W3** | destructive-matcher (both arms, one work unit) | One hook-body region, one test file, one doc fragment, one design. |
| **W4** | egress-loop-form | Structurally independent hook. Sequenced last among the fixes because its loop-form close is the widest behavioural change and benefits from landing on an otherwise-settled tree. |
| **W5** | *terminal, not a card* | Regenerate the hook-readiness index **once** from its fragments, then run the deploy check for index-freshness and hook-registry completeness. Regenerating per wave would churn the same file four times. Intermediate commits between W2 and W5 will carry a stale index; only the merged tree is gated, per the one-PR-one-merge model. |

**Delivery strategy.** One release branch, one PR, one merge gate. The PR is created in **draft** at Stage 6 and transitioned to ready-for-review only at the Stage-9 gate. This plan file is Engineering Commit 0.

## Rollback Strategy

Revert the single merge commit. The version tag is retained per the tag-retention rule, never deleted.

**Rollback is NOT symmetric across this release, and that asymmetry is load-bearing.** The dependency-floor guard is evaluated *before* the bypass check, so the bypass escape hatch **cannot** clear a dependency-missing block. An agent that ships a broken guard cannot repair it from inside a session. Recovery is a hook-bundle reinstall from the operator's own terminal, which the hooks do not gate. This is the one failure in this release the operator, not the agent, has to recover, and it must be stated in the Stage-9 briefing.

Settled architecture, not an open question: moving the bypass check above the guard was already considered and **rejected** in the governing ADR, because a working recovery exists and moving it would touch all thirteen carriers.

## Stage Applicability Matrix

Release Class `cross-cutting` → Stage 5 activation bias **ALL**. Every card is a security-control defect with a live test surface, so **no card skips Stages 5, 7, or 8.**

| Wave | S5 | S6 | S7 | S8 | S9–S13 |
|---|---|---|---|---|---|
| W1 fixture-exemption | YES — exemption-mechanism fork | YES | YES | YES | release-scoped |
| W2 dependency-floor | YES — integrity-primitive fork; ADR-threshold | YES | YES | YES | release-scoped |
| W3 destructive-matcher | YES — one design for both arms | YES | YES | YES | release-scoped |
| W4 egress-loop-form | YES — placeholder resolution + loop-form matcher | YES | YES | YES | release-scoped |

**Justification for zero skips.** The Stage-5 skip test is "trivial change"; the Stage-7/8 skip test is "no functional impact". Neither holds for any card — all five alter the *verdict* of a live security control, and two change verdicts in the fail-open→fail-closed direction, the highest-consequence change class a hook can carry.

**Stage 9 review depth: Deep.** **Stage 13 outcome-window: 30-day.** Engagement density: Tight.

## Contention Map

**AMENDED.** The Stage-4 contention model was falsified in both directions and the correction was verified with control-armed probes rather than adopted on assertion.

| Stage-4 claim | Corrected finding | Control arm |
|---|---|---|
| The fixture-exemption card's twenty-seven fixture lines collide with all four siblings | The five fixture-bearing test files reference the detection primitive **zero times each** — payload files, not consumers | The two genuine consumers return non-zero, so the extraction is live and the subject zero is real |
| The file-scope allowlist is the zero-contention option | It is a **structural no-op** for this defect. The deploy check's corpus glob does not cross a `/` and therefore matches **zero** files under the hook tests directory | Twenty-two top-level hook files matched, so the corpus probe discriminates |
| The commit-path PII guard consumes the detection primitive | It does **not** — zero references; it carries its own hardcoded regex | — |

**Consequences.** The fixture-exemption card drops to **zero** contention against every sibling — the corresponding risk is **closed, not mitigated**. The dependency-floor card's overlap with it drops from two shared files to one, making the credential-reads test file single-claimant. Card-pairs sharing at least one file: **ten of ten → six of ten**. **Release Class is UNCHANGED** — trigger (c) needs three, and six remain.

**Why the error survived re-review — the generalizable finding.** Every path in the Stage-4 contention model **resolved**, so reference-currency passed it. The files were real; the *dependency* was not. **Reference-currency validates that cited paths EXIST — it never validates that cited populations are CONSUMED.** Routed to intake as an action item; it is a gap in the re-review's reference axis, not a defect of this release.

**Claim frequency after the amendment — the hot files.**

| Claims | Path | Note |
|---|---|---|
| **4** | `core/rules/bypass-mode-readiness.md` | GENERATED. Resolved by regenerating **once** at W5. |
| **3** | `core/hooks/tests/block-destructive.test.sh` | dependency-floor (corruption arm), destructive-matcher (both arms). |
| **3** | `core/hooks/block-destructive.sh` | Three **distinct regions**: dependency guard (top), and the two rule arms. |
| 1 | `core/rules/bypass-mode-readiness/block-destructive.md` | Collapses to a single claimant under the build-unit merge. |
| 1 | `core/hooks/tests/block-credential-reads.test.sh` | Single-claimant after the amendment. |
| 1 | `core/hooks/tests/block-egress.test.sh` | Single-claimant after the amendment. |

**Cross-PR contention: zero, against a pinned baseline.** No in-flight sibling's edit set contains any path in this release's File Change Matrix. The sensitivity arm is that the sibling edit sets intersect *each other* non-trivially, so the instrument demonstrably detects overlap when overlap exists. The single cross-release edge is on the **version axis only** — the shared next-free slot, contributed identically by every in-flight sibling. This audit is pinned and cannot see a sibling that branches or pushes after the pin; re-measurement at Stage 9 and Stage 12 is not optional ceremony.

## Release Class Declaration

**`cross-cutting` — CONFIRMED** (operator-rendered at the Stage-4 plan gate; unchanged by the amendment).

| Trigger | Verdict | Evidence |
|---|---|---|
| cross-cutting (a) — matrix touches ≥3 pipeline stage specs | does not fire | zero |
| cross-cutting (b) — matrix touches ≥3 named governance surfaces | does not fire | zero |
| **cross-cutting (c) — ≥3 in-bundle compositional edges** | **FIRES** | six card-pairs share ≥1 file after the amendment (was ten); three files are claimed by three or more cards |
| novel (b) — ≥1 D-class decision | fires | version, branch topology, concurrency posture, plus two substantive design forks |
| novel (c) — ≥1 Stage-5 ADR | fires | the dependency-floor integrity primitive |
| routine / hotfix | do not fire | one `size:L` card at Severity High; five issues |

**Multi-trigger resolution:** highest ceremony wins. **Dominant trigger: cross-cutting (c).**

**Honest note on the basis.** The classification rests on trigger (c) alone — this release touches no pipeline spec and no governance surface. What makes it genuinely cross-cutting is not document breadth but **enforcement-surface breadth**: one card alters the dependency floor beneath every hook, and another alters a detector substrate four independent consumers read. A reader checking only (a) and (b) would mis-read this as `novel`; (c) is the correct and sufficient trigger.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-15, domain: software }` — the matrix is entirely shell sources, shell test suites, allowlists and their governing reference docs, so the dominant deliverable class is `software`; the secondary class is `governance`. Sourcing-exempt (all-internal deliverable), domain-classified regardless. This label travels unchanged from Stage 4 through Stage 5.

## Operator Decisions (D-Gate Block)

| ID | Decision | Verdict | Reversibility · confidence |
|---|---|---|---|
| **D1** | Stage-4 release plan — five waves, D-C `SINGLE`, P0 fully-serial, zero stage skips | **APPROVED as written** | `MODERATE` · HIGH |
| **D2** | Release Class | **`cross-cutting` CONFIRMED** — Tight / Deep / Stage-5 ALL / 30-day | `CHEAP` · HIGH |
| **D3** | destructive-matcher build-unit merge | **APPROVED** — one design, one Engineering pass, one DT pass; both tickets stay separately tracked and both are **marked as closed at Stage 13** | `CHEAP` · HIGH |
| **D4** | Three Tier-1 adjustments at the plan gate | **ALL THREE APPLIED** — generated-file AC repointed to its authorable fragment; parallelization map added to the milestone; a stale code snippet reconciled to live code | `CHEAP` · HIGH |
| **D5** | The destructive-matcher false-positive mirror, previously ungraded scope | **ADD AN ACCEPTANCE CRITERION AT STAGE 5** — routed into the W3 Solutioning pass | `CHEAP` · MEDIUM |
| **D6** | fixture-exemption mechanism | **The already-shipped per-line marker as the SOLE exemption**, with the username-keyed constant and its branch **deleted outright**. Removes the defective axis rather than tuning it | `CHEAP` · HIGH |
| **D7** | dependency-floor integrity primitive | **Accept** out-of-process contract attestation + premature-termination interceptor + pre-source read-only capture, with the **version-skew lockout residual accepted** and a CI-gated conformance check as mitigation | `EXPENSIVE` · MEDIUM |
| **D8** | Wave sequence after the falsified premise | **UNCHANGED** — W1 first, on the INT-1 rationale | `CHEAP` · HIGH |
| **D9** | In-scope reconciliations | **All recorded** — the detector-substrate risk re-scoped, a Stage-8 grading note added, a cross-cutting fragment fix folded into W2 | `CHEAP` · HIGH |

**On D6 — the reuse-first stance was tested and correctly overridden.** The file-scope allowlist was surfaced as the option matching the standing extend-over-new preference. Reuse-first carries a bar of *necessary, not plausible*; an option that provably does nothing does not clear it. The chosen option is itself reuse — of already-shipped, already-exercised, already-documented infrastructure.

**On D7 — the residual is stated plainly, not buried.** The CI gate guards the repository path. A hand-edited or partially-installed deployment remains reachable, and partial install is **not hypothetical**: a deployed hook copy in this very workspace is currently stale against source, verified by hash. Stage 7 must grade **source**, and any hook redeploy must be verified **by hash, never by exit status** — the refresh path can report success while deploying nothing.

## Risk Register

| ID | Risk | Sev | Reversibility | Mitigation |
|---|---|---|---|---|
| **R1** | **dependency-floor blast radius.** The dependency library is sourced by every hook, not only the three named. A guard that over-triggers denies *every* tool call across the whole hook layer — total agent lockout, not one hook misbehaving. | **HIGH** | **EXPENSIVE** / HIGH | Scope the fix to the three always-enforce hooks; the guard change must be additive and must not alter the healthy-library path. Dev Testing must include a **healthy-library negative control** alongside the corruption arm, or a false-positive guard ships green. |
| **R2** | **R1's rollback is not a git revert.** The guard is evaluated before the bypass check, so bypass cannot clear a dependency-missing block. | **HIGH** | **EXPENSIVE** / HIGH | Recovery is a hook-bundle reinstall from the operator's own terminal. **Settled architecture** — the alternative was considered and rejected in the governing ADR. Remains a Stage-9 briefing obligation. |
| **R3** | **fixture-exemption blast radius — RE-SCOPED.** Stage 4 named the commit path and the deploy check. **Neither is exposed:** the commit-path guard is not a consumer, and the deploy check exempted **zero** of its scanned lines via the deleted constant. The real over-fire surfaces are the two **runtime content scans** — the gh issue/PR-ops guard and the scope-segregation guard. | **HIGH** | MODERATE / HIGH | The substrate is registered in the self-test coverage manifest, so its self-test is CI-gated on both runners and must stay green. **The scope-segregation guard is the sharp one: its always-block tier fires even in warn mode**, so an over-fire there is *not* softened by the mode dial. Dev Testing must exercise both runtime consumers, not only the deploy check. |
| **R4** | **Fail-closed regression, unbounded on three of five cards.** Each tightening can break a legitimate workflow. | **HIGH** | MODERATE / MEDIUM | **Bounding is asymmetric and this is the release's sharpest risk.** The egress hook reads a shared mode file and lands behind a warn dial with a real shakedown window and an allowlist escape. The destructive, credential-reads and trash-preference hooks are **mode-independent — no warn dial exists** — so three cards go live hard on deploy. Pair every new must-flag case with a must-not-flag control; the rule allowlist is the runtime escape. **Do not assume a warn window exists for the destructive-family changes.** |
| **R5** | **Reflexive-pipeline risk — this release tightens the controls its own pipeline runs under.** Downstream spokes invoke `source`, script execution, and gh write commands constantly. | **MED** | CHEAP / HIGH | **Empirically confirmed, not predicted:** control firings have accumulated across every stage of this release so far, on multiple distinct hooks — including one that blocked the hub's own scaffolding script. All were resolved by rewording; none bypassed. Dev Testing must exercise the *pipeline's own* invocation shapes as must-not-flag controls before the tightening merges. |
| **R6** | **Generated-index contention.** The hook-readiness index is claimed by four cards and is machine-assembled; four independent regenerations conflict, and a stale committed index fails the deploy check. | **MED** | CHEAP / HIGH | Single terminal regeneration at W5. Accept that intermediate commits carry a stale index; only the merged tree is gated. |
| **R7** *(CLOSED)* | The fixture-exemption design fork drives the release's contention topology. | — | — | **CLOSED, not mitigated.** The premise was falsified: the card sets no topology either way, so there is no risk left to carry. Retained as a row rather than deleted, so a reader of the Stage-4 register can see what became of it. See the Contention Map. |
| **R8** | **ADR number multi-claim.** The next-free ADR number is claimed on more than one unmerged branch; this release's would be another. | **MED** | CHEAP / HIGH | Allocate next-free per the recorded rule and let the CI number-integrity gate and the renumber tool resolve at merge. **Do not reserve above the sibling claims** — a gap blocks the repository; a duplicate is tooled. Whichever release merges later renumbers. |
| **R9** | **Version-slot contention.** Multiple siblings resolve to the same next-free slot. | LOW | CHEAP / HIGH | By design — arbitrated at the Stage-12 atomic claim. **This risk has already fired once**, HALTing the first W1 attempt at the Commit-0 rung. Slug-primary identity means nothing renames. |
| **R10** | **Widening evaluation from first-invocation to all.** Commands that currently pass because only their first invocation was adjudicated will begin to be evaluated in full. | MED | MODERATE / MEDIUM | Budget for allowlist additions during shakedown; capture them through the supported allowlist tool so they are logged rather than ad-hoc. |
| **R11** | **The mode-capable hook cohort retains the same corruption hole.** The dependency-floor card scopes to three always-enforce hooks; the remaining hooks carry the same idiom with a syntax precheck that a valid-syntax early exit also defeats. | LOW | CHEAP / HIGH | **Out of scope, deliberately** — recorded so a green result is not read as closing the class. Follow-up card once the chosen primitive is proven. |
| **R12** | **Baseline staleness.** Siblings were updated within minutes of the planning pin, and one claimed the version slot mid-run. | LOW | CHEAP / HIGH | Re-measure at Stage 9 (HALT-eligible) and Stage 12. Recorded, not assumed. |

## Cross-Issue Acceptance Criteria

Graded at Stage 9 on the merged PR.

- [ ] **CIAC-1 — spelling invariance.** For each of the destructive and egress hooks, an allowlisted target and a non-allowlisted target each receive the **same verdict** across every spelling this release addresses: bare, single-quoted, double-quoted, and (for the destructive hook) preceded by a leading environment-variable assignment. A tightening that converts an allowed spelling into a denial fails this criterion just as a fail-open does. *Method:* dispatch both hook suites; each asserts a must-flag case paired with a must-not-flag control per spelling.

- [ ] **CIAC-2 — every invocation is evaluated.** Neither hook truncates its invocation scan to the first match, and each suite proves a **second** invocation after a separator is adjudicated even when the first resolves to an allowlisted target. *Method:* a first-match-truncation grep over both hook bodies returns empty **and** the chained-invocation cases pass; the pre-change grep returning non-empty is the sensitivity arm.

- [ ] **CIAC-3 — a control that cannot evaluate its input denies.** All three unevaluable-input classes reach a **deny**, each with a message naming the cause: a syntactically-valid corrupt dependency library, a variable-bearing script path, and an unresolvable placeholder-bearing api path. No class exits zero silently. *Method:* dispatch the fail-closed suite plus the two hook suites; each class emits a non-zero exit and a cause-naming stderr line.

- [ ] **CIAC-4 — documented contract matches shipped behavior.** Every rule whose behavior this release changes has its contract updated in the corresponding hook-readiness **fragment**, the generated index is regenerated from those fragments, and no fragment edit is left unreflected in the index. *Method:* the deploy check's index-freshness and hook-registry-completeness legs both green on the merged tree.

- [ ] **CIAC-5 — one fixture-exemption convention, applied uniformly.** Every test fixture this release authors or edits that embeds a home path is exempted by the **single** non-username mechanism, and a genuine home path under a former fixture username is reported as a leak on every consuming surface. *Method:* the detection primitive's self-test green; plus both arms proven against the deploy check **and** at least one hook consumer.
  > **Grading note (amendment).** CIAC-5's clause "no fixture anywhere in the hook tests directory still relies on a bare username to escape the detector" is satisfied **vacuously and correctly** — no fixture there ever relied on it, because no consumer scans that directory. Stage 8 should read the vacuous pass as *graded and met*, not as an ungraded criterion.

## File Change Matrix

**AMENDED** from the Stage-4 matrix. One path per line, for deterministic downstream extraction.

```
core/hooks/block-credential-reads.sh
core/hooks/block-destructive.sh
core/hooks/block-egress.sh
core/hooks/block-rm-prefer-trash.sh
core/hooks/lib/dep-resolve.sh
core/hooks/tests/block-credential-reads.test.sh
core/hooks/tests/block-destructive.test.sh
core/hooks/tests/block-egress.test.sh
core/hooks/tests/block-gh-path-leak.test.sh
core/hooks/tests/block-rm-prefer-trash.test.sh
core/hooks/tests/check-hook-dep-hardening.sh
core/hooks/tests/hook-fail-closed.test.sh
core/deploy/tools/path-leak-patterns.sh
core/deploy/tools/README.md
core/standards/analysis-workspace-standard.md
core/config/allowlists/egress-allowlist.txt
core/rules/bypass-mode-readiness/_cross-cutting.md
core/rules/bypass-mode-readiness/block-destructive.md
core/rules/bypass-mode-readiness/block-egress.md
core/rules/bypass-mode-readiness/block-scope-segregation.md
core/rules/bypass-mode-readiness.md
core/ADRs/ADR-133-hook-dependency-integrity-invariant.md
release/releases/plans/hooks-enforce-under-adversity_RELEASE_PLAN.md
```

Per-path intent: `add` — the ADR and this plan file. `edit` — all others. `delete` — none.

**Rows changed by the amendment.** Dropped, because the fixture population they represented is not consumed by anything: `core/hooks/tests/block-fs-boundary.test.sh`, `core/hooks/tests/block-shell-injection.test.sh`. Dropped, because the file-scope allowlist option was rejected on evidence and the allowlist is **not** to be extended for fixture purposes: `core/deploy/allowlists/skip-path-portability-check.txt`. Added, as the true surfaces of the fixture-exemption card: `core/hooks/tests/block-gh-path-leak.test.sh`, `core/deploy/tools/README.md`, `core/standards/analysis-workspace-standard.md`.

**Files explicitly NOT changed** (recorded so their absence reads as a decision, not an omission): the path-portability allowlist, and the fixture-bearing test suites for the credential-read, destructive-command, egress, filesystem-boundary and shell-injection hooks *on the fixture-exemption card's account* — three of those files are still edited by other cards, for their own reasons.

**New-executable companion obligation: satisfied, no new rows required.** The script-execution allowlist already carries wildcard forms covering the hook test suites. **Constraint for Engineering:** a new helper that is *not* named as a test suite is **not** covered by that wildcard and would need an explicit row in the same release.

## Verification Plan

| # | Check | Family | Method |
|---|---|---|---|
| V1 | Detection-primitive self-test green, both new arms present | runtime-suite | Run the primitive directly with its self-test flag; assert the case count rose and zero failures. CI-gated on both runners via the self-test coverage manifest. |
| V2 | A genuine home path under a former fixture username is caught | per-issue | Source the primitive; assert the line-scan predicate flags it on both the macOS and Linux forms. |
| V3 | A fixture line carrying the per-line marker stays exempt | per-issue | Same inputs as V2 with the marker appended; assert clean. Identical inputs across the two arms is what makes the pair a falsification test rather than two unrelated assertions. |
| V4 | The hook-consumer arm blocks end-to-end | runtime-suite | Dispatch the gh-path-leak hook suite; assert the new must-flag case blocks with its rule identifier. |
| V5 | Fail-closed classes all deny with a named cause | runtime-suite | Dispatch the fail-closed suite plus the destructive and egress hook suites. |
| V6 | Generated index is fresh and the hook registry complete | sync | Deploy-check index-freshness and hook-registry-completeness legs, on the merged tree only. |
| V7 | Doc-link integrity across modified markdown | regression | Deploy-check doc-link leg. |
| V8 | No new path-portability finding on the executable surface | regression | Deploy-check path-portability leg on the merged tree. |

**Runtime-suite discipline.** Suites run under the temp-directory home-override sandbox. Stage 7 re-runs the selected suite as the authoritative gate input; the Stage-6 run is self-verification evidence, not the gate.

## Deviation Log

| # | Wave | Deviation | Classification | Disposition |
|---|---|---|---|---|
| 1 | W1 | The first W1 spoke HALTED at the Commit-0 version re-verify: the slot recorded at Stage 4 had been claimed by an in-flight sibling minutes earlier. | Tier 2 scope change | Surfaced to the operator, who re-rendered the determination and re-spawned the wave. No branch, commit or PR was created by the halted attempt. **Working as designed** — this is the rung's purpose. |
| 2 | W1 | The Stage-4 and Stage-5 analyses were pinned to a baseline the tree has since advanced past. | Minor adjustment | Every load-bearing citation re-verified against the advanced mainline before implementation; the detection primitive was byte-identical across the window. Deploy-script line citations in the Stage-5 design are treated as **stale-suspect and descriptive**, never load-bearing. |

## Engineering Constraints (carried forward)

1. **One commit per issue** — the release rollback granularity, not a style preference. Commit 0 is the sole exception and carries no issue work.
2. **INT-1 — the fixture-marking convention, in force from W1's implementation commit.** The only sanctioned way to exempt a home-path-shaped string from the path-leak detector is the per-line `path-leak: allow` marker. A username is not an exemption: a home path is flagged regardless of the username it carries, on both the macOS and Linux forms, unless the line carries the marker. This binds authored source lines, rendered spoke briefs, and gh issue and PR bodies alike. The path-portability allowlist is **not** to be extended for fixture purposes — it is reserved for files that *define* the detection.
3. **Do NOT regenerate the hook-readiness index before W5.** It is generated, claimed by four cards, and regenerated once, terminally. Edit only its fragments.
4. **Do NOT extend the script-execution allowlist** except for a genuinely new executable that the existing test-suite wildcards do not cover.
5. **Verify any hook redeploy by hash, never by exit status.** The refresh path can report success while deploying nothing when its baseline is stale.
6. **Stage 7 grades SOURCE, not the deployed copy.** At least one deployed hook copy in this workspace is stale against source.
7. **Address deploy checks by number, never by line.** The deploy script changed during this release's planning window and is edited by in-flight siblings.
8. **PR body and commit messages parser-clean** — where prose describes per-issue closure, write `mark #N as closed at Stage 13`; never a close-family verb adjacent to a ticket reference, in any section. The auto-close parser fires on the verb plus the reference regardless of section context.
9. **Commit messages are depersonalization-gated in CI.** A personal email address or an absolute home path in a commit *message* hard-fails CI. Read the composed message before committing — a local hook may inject a co-author trailer.

## Issue References

Bare ticket references are confined to this block, each with a summary noun phrase, per the reference-durability standard.

W1 (fixture-exemption) is issue #5075 — the username-keyed path-leak exemption that clears a genuine home path under ten common account names.

W2 (dependency-floor) is issue #5071 — the dependency-resolution guard that a syntactically-valid corrupt library defeats from inside the guard's own condition.

W3 (destructive-matcher) is issues #5249 and #5285, built as one work unit — the quote-stripping and command-position arm, and the assignment-prefix-skip arm, of one destructive-command rule.

W4 (egress-loop-form) is issue #5292 — the egress api-path matcher that does not adjudicate a loop-body invocation and truncates evaluation to the first invocation.

The planning sub-task is issue #5521; the Stage-5 Solutioning sub-tasks for W1 and W2 are issues #5528 and #5524. The Stage-6 Engineering sub-task for W1 is issue #5529.

The milestone is #339.

The ADR allocated for the dependency-floor integrity primitive is ADR-133; its governing antecedent on guard mode-coupling is ADR-130, and the plan-file identity convention is ADR-092.

The originating survey that surfaced the fixture-exemption defect is issue #4186, under milestone #310, which shipped the gh-path-leak guard at warn.

The generated-file convention governing the hook-readiness index is ADR-030; the scope-segregation guard that is the fixture-exemption card's fourth consumer was added by ADR-091.
