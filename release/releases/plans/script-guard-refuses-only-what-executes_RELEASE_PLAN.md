---
title: Release Plan — script-guard-refuses-only-what-executes (BLOCK-DESTRUCTIVE-022 refuses only commands that execute a script)
type: release-plan
plan_type: release
status: ACTIVE
release: versioned (bump-class minor; the rule-computed next-free at Engineering Commit 0 is v5.14, equal to the Stage-4 provisional; the concrete number binds at the Stage-12 atomic claim)
milestone: script-guard-refuses-only-what-executes
release_class: novel
reversibility: MODERATE / Confidence HIGH — one guard hook, its suite, its corpus and its readiness fragment on one branch, one pull request and one merge; each card reverts by its own GREEN commit (its RED arms then read red by design), and the deployed hook needs a second operator refresh after a revert. A claimed version tag is retained and recorded, never deleted.
---
# Release Plan — `script-guard-refuses-only-what-executes`

**Milestone:** `script-guard-refuses-only-what-executes` (milestone 440). Five cards on BLOCK-DESTRUCTIVE-022 (`core/hooks/block-destructive.sh`): **#8490**, **#8548**, **#8326**, **#8493** and **#8327**. The Stage-4 planning sub-task **#9058** carries the approved plan (comment 6962575704, part 1/2, and comment 6962578848, part 2/2), the Stage-4 gate's Decision Recorded (comment 6962704266), the Mode R readiness briefing (comment 6961772876) and the Collective Review scope-lock Decision Recorded (comment 6966866565). The Stage-5 designs are on **#9059** (#8490), **#9060** (#8548), **#9061** (#8326, hub-direct after a safety-classifier stop), **#9062** (#8493) and **#9063** (#8327); their Phase A6.5 adversarial reviews are on **#9084** (#8490), **#9085** (#8548), **#9087** (#8493), and **#9086** and **#9092** (#8326 and #8327: both attempts stopped by a safety classifier, gap recorded). The Stage-6 Engineering sub-tasks are **#9064**–**#9068**; the hub builds every slice itself (operator decision at the Stage-4 gate). This file is Engineering Commit 0.

**Version identity:** **versioned** — bump-class **`minor`**. The concrete number binds only at the Stage-12 atomic claim (ADR-092): the branch and this file stay slug-primary while in flight, and the Header `**Version**` cell carries the double-brace release-version placeholder, which this file reproduces in that cell only. The rule-computed next-free at Engineering Commit 0 is **`v5.14`**, equal to the D-Version determination (§ Commit-0 Version Re-Verify Record).

**Topology:** D-C **SINGLE** — one release branch, `release/script-guard-refuses-only-what-executes`, cut from `origin/main` at `62af4efe`; one pull request opened in **draft**; one merge into `main`.

**Concurrency posture:** **P0 fully serial**, hub-built: Commit 0, then #8490 → #8548 → #8326 → #8493 → #8327. Force-push, `--force-with-lease` included, is not used on the shared branch.

**Release class:** `novel`; Stage 9 review depth **Deep**.

> **Provenance and precedence.** This file transcribes the Stage-4 Release Planning output on #9058 and is amended, in order, by: the Stage-4 gate's Decision Recorded (plan approved as recommended; D-F07 (A); D-Readings (A); D-EnclosureExecRows (A); D-Concurrency P0; D-ReleaseClass `novel`; D-Version minor as a recorded determination; Stage 6 hub-built; the Collective Review pre-lock), then the five Stage-5 designs and the adversarial reviews as the Collective Review adopted them, then the Collective Review scope-lock Decision Recorded. Where the plan and a later record differ, the later record wins, and each change is recorded in § Deviation Log. Every thread comment consumed is authored by the repository owner (Comment-Ingestion Trust Boundary).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | {{RELEASE_VERSION}} |
| **Bump Class** | minor — the durable determination (D-Version, a recorded determination at the Stage-4 gate): a guard hook's behaviour changes and its readiness text with it, per the Bump-Class Selection Guide's row "Protocol text addition or modification". The rule-computed next-free re-verified at Engineering Commit 0 is `v5.14`. The concrete number binds at the Stage-12 atomic claim (ADR-092) |
| **Date Created** | 2026-11-18 (Wednesday, UTC) |
| **Release Manager** | Agent-assisted (release-hub, hub-built Stage 6) |
| **Status** | Executing — Stage 6 Engineering: Engineering Commit 0 (this file) |
| **Branch** | `release/script-guard-refuses-only-what-executes` |
| **PR** | opened in **draft** at Stage 6 |
| **Milestone** | `script-guard-refuses-only-what-executes` |

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-17, domain: software }`

## Commit-0 Version Re-Verify Record

### Version half (steps 1–3, pre-write)

1. `git fetch --tags origin` and `git fetch origin main` at Commit 0: `origin/main` = `62af4efe`; the highest version tag is `v5.13`.
2. Recomputed next-free for bump-class `minor` through the version-claim adapter (`release/tools/claim-version.sh --bump minor --sha 62af4efe --dry-run`): **`v5.14`**.
3. `v5.14` is not in the claimed set and equals the recomputed next-free: **PROCEED**. The tag arm binds; no in-flight `release/*` sibling exists (`git ls-remote --heads origin 'release/*'` returned 0 before this branch).

### Manifest half (step 3b, post-write and pre-commit)

`release/tools/claim-version.sh --verify-stamp script-guard-refuses-only-what-executes` — recorded in the Engineering Commit 0 message.

### Commit-0 Survival Set

| # | Element | Where in this file |
|---|---|---|
| 1 | `domain_practice` label | under § Header |
| 2 | File Change Matrix (machine-readable) | § File Change Matrix (as amended in § Deviation Log) |
| 3 | Cross-Issue Acceptance Criteria | § Cross-Issue Acceptance Criteria |
| 4 | Verification Plan | § Verification Plan |
| 5 | the release-version stamp manifest | § Header, the **Version** cell |
| 6 | Stage Applicability Matrix | § Stage Applicability Matrix |
| 7 | Release Class declaration | § Release Class declaration |
| 8 | Implementation Sequence | § Implementation Sequence |
| 9 | Baseline pin | Stage 4 `b7ea0de8`; branch cut at `62af4efe` (the window between them touches none of the File Change Matrix, § Deviation Log DEV-2) |

## Summary (30 seconds)

- **Verdict: CONDITIONAL.** The plan is complete and executable. Six operator decisions sit at the plan gate: D-F07 (re-rate #8327), D-Readings, D-EnclosureExecRows, D-Concurrency, D-ReleaseClass, and D-Version, which is a recorded determination. The plan proceeds as written once the gate renders them.
- **Scope holds at 5 cards, 18 raw / 21 effective points (`novel` ×1.15, round-half-up), in the 15–25 band.** D-F07 recommends re-sizing #8327 from M to L. That gives 22 raw / 25 effective, still in band but at its ceiling. Any further growth splits the release.
- **No native dependency edge runs inside the bundle: 0 of 5.** Control: #8493 is blocked by #7018, which is CLOSED, so the same read returns non-zero. The derived edges are ordering and file-contention only. The sequence is Commit 0 → #8490 → #8548 → #8326 → #8493 → #8327, then the post-deploy readings. The ceiling goes last among the edits. This sequence moves #8493's message edit ahead of #8327 (R-REC-2).
- **The #8490 AC2 ↔ #8548 boundary.** A command substitution outside a variable assignment's value belongs to #8490. A substitution inside an assignment's value belongs to #8548, listed and unlisted scripts alike. CIAC-1 grades the boundary.
- **G-PL5 cache-read: MISS, so PT-1..4 were re-run.** All five currency limbs are equal. The miss is the column-completeness clause: three adopted rows carry a bare "—" D3 cell. **A0.8 is a documented pass-through** for all five cards: no card body carries a machine-runnable repro, and every exact spelling is withheld by convention. A static read at the pin finds each card's mechanism still present. The empirical re-measure lands at the Stage-6 RED commits. Carry-forward 2 is therefore only partly discharged.
- **Two findings the operator should see first:**
  - **(1)** On the deployed drain since the widened walk was published, 9,408 of the exec arm's 11,519 non-worktree rows were written at enclosure positions. #8490 owns the 416 of them that are backtick-led. The other 8,992 have no owner. The fragment says much of that population is prose, and an exec-arm graduation would start refusing it (D-EnclosureExecRows).
  - **(2)** Three acceptance criteria read instruments that do not record what they ask for. The drain row carries no hook hash and no command. The block-log row carries no cause, so a refusal cannot be tied to the latch gate that issued it (D-Readings).

## Phase A0 — Triage→Design Re-Review

**G-PL5 cache-read.** Briefing: this sub-task, comment `#issuecomment-6961772876`. That is the permalink fragment on #9058; the repository owner handle is omitted so the plan file can be transcribed past the depersonalization gate. It is authored by the trusted set (repository owner association), `emitted_at` 2026-11-17T21:15:59Z, part 1/1 complete. Each operand was recomputed with the literal § G-PL5 pipelines under `pipefail` at 2026-11-17T21:44Z:

| Limb | Recorded | Recomputed | Result |
|---|---|---|---|
| L1+L2 `card_set_fingerprint` | `77b85202…dbbc` | `77b85202…dbbc`, from 5 card lines; members 6 including the sub-task, under the limit of 500 | equal |
| L3a `milestone_updated_at` | 2026-11-17T21:39:32Z | 2026-11-17T21:39:32Z | equal |
| L3b `milestone_description_sha256` | `79bb7210…593d` | `79bb7210…593d` | equal |
| L4 `main_head_sha` | `b7ea0de8…` | `b7ea0de8…`; `git ls-remote` agrees | equal. The briefing predicted a MISS here; `main` did not move |
| L5 age | 21:15:59Z | ~0.5 h | inside the 7-day bound |
| Title guard | — | 0 non-`sub-task` members titled `^Stage N`. Control: 1, the sub-task | clean |
| **(d) column completeness** | — | three rows carry a bare "—" in D3: #8327 AC3, #8493 AC3 and #8548 AC2. `triage-design-rereview.md` § 1 Rule 3 forbids a finding-free dimension | **MISS** |

**`rows_source: re-derived (PT-1..4 re-run)`.** The briefing is an input here. Its rows are not adopted verbatim. Each row below rests on this spoke's own read at the pin. The PT-2 freshness sub-step does not apply: no row is C3.

### #8490

`issue_number` #8490 · `release_milestone` script-guard-refuses-only-what-executes (version-less until the Stage 12 claim) · `stage` 4 · `spoke_author` Stage 4 Release Planning spoke · `re_review_date` 2026-11-17 · `issue_body_revision` 2026-10-27T16:25:52Z · `triage_decision_date` 2026-10-24 · `effort_tier` standard

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1: backtick-led text writes no row (must-not-flag, red pre-fix) | `review-discipline-principles.md` § 8 PV-1: a must-not-flag arm needs a paired arm that does flag. AC2 supplies it | The exec arm's verdict router `destructive_022_exec_verdict` still takes the token as the path. The phase is `warn` (`DESTRUCTIVE_022_EXEC_PHASE`) [SOURCE: block-destructive.sh] | On the deployed drain since 2026-10-26, outside worktrees: 863 of 2,111 first-view exec rows (40.9 %) and 416 of 9,408 enclosure-position rows are backtick-led. The 2026-10-16 figure, taken on the pre-publish hook, was 35.4 % [SOURCE: count-only drain read; #8175] | C2 | The class is still the largest first-view class, and #8490 owns it at both positions. The text/real-substitution split stays the card's own [ASSUMPTION – CONFIRM]. Its closing method, a per-row read against the producing commands, cannot run as written, because the drain records no command (D-Readings) |
| AC2: a real substitution is still flagged, and a listed script is admitted | § 8 PV-3: an over-broad drop turns a refusal into an allow | #8548's shape is a substitution inside an assignment's value, and it overlaps "a listed script reached the same way" | The Stage 7 report on #8182 routed #8548 to intake (finding F-07) | C2 | Tier 1 [ADJUST], proposed: scope AC2 to substitutions outside an assignment's value. Add: "(a substitution in a variable assignment's value is #8548's)". CIAC-1 grades it |
| AC3: zero movements on the corpus differential | Rule 15: the differential has to name its population and its control | The corpus at the pin has 1,820 rows, 1,378 of them `block-destructive` (B 817 · a 420 · W 141). Its `open-` groups are `open-stdin` 8 and `open-encl` 4 | v5.11 DEV-10: a refuse/record→allow re-grade is declared in its card's GREEN commit | C1 | — |
| AC4: the next drain reading reports the class with its count, hook hash and commands | § 8 PV-6: a reading must name its population | The drain row fields are `ts hook rule tool phase reason arm cause path cwd [pos]`. They carry **no hook hash and no command** [SOURCE: `log_would_fire_022`] | The 2026-10-16 reading counted commands as distinct timestamps (4,307 rows / 2,818 commands) [SOURCE: fragment graduation record] | C2 | Restate AC4 to what the instruments support, or add the instrument (D-Readings). It reads post-deploy |
| Risk: contention with #8316 / #8318 / #8319 | Rule 4: name the proximal cause | Their code is merged (#8993, v5.11). The cards stay open until v5.11's Stage 13. That milestone's only open PR, #9054, touches none of the -022 files | — the merge order is settled | C1 | — |

### #8548

`issue_number` #8548 · `release_milestone` script-guard-refuses-only-what-executes · `stage` 4 · `spoke_author` Stage 4 Release Planning spoke · `re_review_date` 2026-11-17 · `issue_body_revision` 2026-11-17T21:37:20Z · `triage_decision_date` 2026-11-17 · `effort_tier` standard

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1: an allowlisted script run inside an assignment's substitution writes no exec row (must-not-flag) | § 8 PV-1: paired with AC2 | v5.11's assignment-value step declines a value carrying a substitution opener (`script_qval_opaque`: `$(`, a backtick, `${`, and others), so this shape keeps the pre-v5.11 reading [SOURCE: block-destructive.sh] | #7028's design G2 left this "not paid down, by decision" (#8166) | C2 | The mechanism persists at the pin (static read). Stage 5 settles walk-vs-reading |
| AC2: an unlisted script run the same way is still adjudicated | § 8 PV-3: the change must narrow no refusal | The enclosure view opens a position at a substitution opener and reads the verb there, so both views meet this shape | v5.11 sweep #9052 S-3 rows WR132/WR133 sit adjacent: a substitution in an assignment value ahead of an interpreter [SOURCE: Mode R relay, not re-read] | C2 | Stage 5 measures both views on the shape |
| AC3: zero movements on the differential | Rule 15 | The same corpus and exit bar as #8490 AC3 | v5.11 DEV-10 | C1 | — |
| AC4: the next drain reading reports the population | § 8 PV-6 | The drain has no hook-hash or command field | The same as #8490 AC4 | C2 | Placed with #8490 AC4 (D-Readings) |

### #8326

`issue_number` #8326 · `release_milestone` script-guard-refuses-only-what-executes · `stage` 4 · `spoke_author` Stage 4 Release Planning spoke · `re_review_date` 2026-11-17 · `issue_body_revision` 2026-11-17T20:57:29Z · `triage_decision_date` 2026-10-24 · `effort_tier` standard (size S, on a security hook)

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1: a non-carrier inert body is admitted; a receiver behind a group opener is resolved | `reversibility-protocol.md`: widening an exemption on a fail-closed control is the costly direction to get wrong | The carrier set is `gh\|printf\|echo\|jq`. Membership is a **conjunction**: the member (a) cannot evaluate its argument and (b) does not execute its stdin. The hook's R-4 note keeps the non-carrier false positive on purpose and names `cat` and `tee` as plausible members it did not add. `script_resolve_head` splits on whitespace and returns the first token that is not an assignment, so `(` and `{` are never stepped over [SOURCE: block-destructive.sh] | v5.11 D-Family: the rule keeps its own model, takes no shared lexer, and needs no ADR (#8898; #8928) | C2 | Tier 1 [ADJUST], proposed, restating AC1 in the allowlist direction (text below). The two halves interact: stepping over an opener only helps a receiver that is already a carrier |
| AC2: a real execution through a here-document is still refused | § 8 PV-1: the must-flag control | Condition (1) exists to refuse a stdin-executing receiver | The shape is unchanged since v5.11 | C1 | — |
| AC3: no admitted real execution changes verdict; the suite stays green at its floor | Rule 15 | "Documented floor" is defined nowhere in the hook, suite, runner or fragment: 0 matches. Control: the fragment carries "graduation" 9 times | The v5.11 plan defines it as "0 FAIL, AGGREGATE at or above the Commit-0 floor" | C2 | This plan fixes the floor at Engineering Commit 0 (Verification Plan) |
| L43, folded 2026-11-17: #8320's INT-2 premise read against DEV-14 | Rule 3: a folded re-check needs a finding line | The pin `AC-ENCL-RESIDUAL-hd-continuation` holds a receiver behind a line continuation at allow, as an under-match | v5.11 plan DEV-14: the continuation reading adds a second walk rather than joining segments | C2 | Tier 1 [ADJUST], proposed as AC4 (text below), plus risk R4 |

**Proposed AC1 restatement (#8326).** Verify the following, each with an arm red against the pre-fix hook:

- A here-document whose body executes nothing is admitted when its receiver is a named verb that passes both membership tests: it cannot evaluate its argument, and it does not execute its standard input.
- A receiver written behind a group opener resolves to the verb behind the opener before the membership test.
- A receiver outside the allowlist keeps today's verdict.

**Proposed AC4 (#8326, carrying L43).** Verify that #8320's INT-2 premise is re-checked against the continuation reading v5.11 shipped. Record the finding at Stage 5. Verify that the `AC-ENCL-RESIDUAL-hd-continuation` pin keeps its verdict, or is re-pointed in the same commit with its reason recorded.

### #8327

`issue_number` #8327 · `release_milestone` script-guard-refuses-only-what-executes · `stage` 4 · `spoke_author` Stage 4 Release Planning spoke · `re_review_date` 2026-11-17 · `issue_body_revision` 2026-11-07T03:17:13Z · `triage_decision_date` 2026-10-24 · `effort_tier` complex (scope grew by three inbound items)

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1: a per-command ceiling bounds time on the pathological shapes | § 8 PV-2: a timing arm needs a RED prediction that was actually observed red | There is no whole-command ceiling: 0 matches. Control: the per-feature budget constants match 4 times (`SCRIPT_ENCL_POS_MAX`=512, `SCRIPT_ENCL_TAIL_BYTES`=262144, a shared quote work cap of 1000, `SCRIPT_LINEAR_MIN`=256). v5.05 made the separator split linear; v5.11 made the continuation join linear | v5.11 R11 became #8327's residual (#8975 ruling G5). v5.05 DEV-54's held slow places were routed here by class (notice of 2026-11-07). The `AC-022-Z*` RED predictions were hub-stated | C2 | Re-size to L (D-F07). Every shape is re-timed at the pin on an idle host at the RED commit, with the load average recorded |
| AC2: reaching the ceiling degrades toward adjudication, never toward an allow | `reversibility-protocol.md`: the fail direction | The runtime's command-hook default is **600 s**, and a PreToolUse hook that times out **does not block**. An `onFailure: "block"` setting exists [SOURCE: runtime hooks reference, read 2026-11-17 through a summarizing fetch; Stage 5 confirms it against the installed runtime]. #8660 owns that settings-level remedy | Stage 7 F-07 (#8180): a real ~100 kB body ran 835 s on a forced copy at a load average of 14–19, past the timeout, and so failed open | C2 | The operator renders the F-07 re-rating at this gate (D-F07) |
| AC3: ordinary commands are unaffected (a control timing arm) | Rule 15: the control arm | Neither the workspace nor the account-home settings carries a `timeout` key on any block-destructive entry. The workspace settings carry none on any of their 27 hook entries. Control: 3 other account-home entries do carry one | The "25 s" figure is the Stage-7 spoke's measurement cap, not the runtime default [SOURCE: #8965 comment 6904660964] | C2 | **The runtime default of 600 s binds.** Stage 5 sets the cap with margin under it |

### #8493

`issue_number` #8493 · `release_milestone` script-guard-refuses-only-what-executes · `stage` 4 · `spoke_author` Stage 4 Release Planning spoke · `re_review_date` 2026-11-17 · `issue_body_revision` 2026-10-27T16:26:08Z · `triage_decision_date` 2026-10-25 · `effort_tier` standard

| Requirement | D1 finding | D2 finding | D3 finding | Classification | Delta or Premise-Problem Type |
|---|---|---|---|---|---|
| AC1: a bash/sh sweep of the plain set in eight positions, with a splitting control | § 8 PV-0/PV-1: a sweep needs its control arm | The plain set `script_plain_word` is unchanged at the pin. The CI hook harness runs on `macos-latest`, so on CI `sh` is the macOS system shell [SOURCE: install-tests.yml] | #8179: a spawned session could not invoke the shell binaries from a plain command | C2 | Plan the sweep as a **suite arm**. The suite spawns the shells inside its own process, which no PreToolUse hook sees, so it runs in CI and through the admitted runner |
| AC2: a live-traffic reading of the two gates' refusals | § 8 PV-6 | A refusal goes through `block` → `log_block`, whose row is `{ts, hook, rule, tool, input_digest, cwd}`. It has no cause and no gate identity, and the input is a one-way digest [SOURCE: block-destructive.sh] | The latch shipped 2026-10-25 (PR #8306) | C2 | The population the AC names is not recorded today. D-Readings decides it |
| AC3: the route's refusal names its cause | Rule 3 | `script_take_cmode_route` emits no message of its own. A refusal it causes arrives as the generic -022 text | The review finding F-4 on #8233 asked for exactly this | C1 | — |

**Other Phase A0 gates.**

- **A0.5 / G-PL1 (reference currency).** Every AC-cited path is tracked at the pin. The fragment line cites were re-verified at the pin: :31 is the exec phase, :33 is the graduation record and hold-back list, :121 is the linear split, and :240 names #8490 as owner. Correction to carry-forward 2: **v5.08 (#8992) did not change the -022 walk.**
  - Of its 11 files, none is the hook, its suite, the -022 fragment or the walk corpus. One pattern was run over those four paths: v5.08's merge `4e70b20f` returns 0, v5.11's merge `20149aeb` returns 4 and v5.05's merge `e58a77f0` returns 4.
  - v5.08 did regenerate the shared registry `core/rules/bypass-mode-readiness.md` and edit `_cross-cutting.md`.
  - Its one shared code surface is `lib/command-position.awk`, which -022 is "deliberately NOT routed through" (block-destructive.sh:155-158). The -022 surface moved in #8306, v5.05 (#8651) and v5.11 (#8993). The G-PL1 failures are the Tier-1 proposals above: #8326 AC1 and AC4, and #8490 AC2.
- **A0.6 / G-PL2 (crisping).** All five bodies pass G1-02 and G1-04.
  - G1-05 passes with three C2 items: the two AC4s and #8493 AC2 read instruments that lack the field they ask for.
  - #8326 and #8327 state Documentation Impact in prose. Carry-forward 10 plans their repair to `path | action | reason` rows at Stage 5/6.
  - Proposed rows:
    - #8326: `core/rules/bypass-mode-readiness/block-destructive.md | update | the here-document receiver handling and the two inert shapes' disposition`
    - #8327: `core/rules/bypass-mode-readiness/block-destructive.md | update | the per-command work ceiling, its value against the 600 s default, and its degrade direction`
- **A0.7 / G-PL3 (placement).** The release base is the pin (`b7ea0de8`). The window from base to `origin/main` is empty, so the check is a **SKIP**. Every new file lands in a directory that exists at the pin.
- **A0.8 / G-PL4 (empirical repro).** None of the five cards is drift-class: none matches `drift`/`reconcil`, none carries a governance-hygiene label, and none is designated drift-class. None carries a machine-runnable repro command, because each body withholds its payloads by convention. That makes all five **documented pass-throughs**: they are not FAILs and they supersede no row. A static read finds every mechanism present at the pin (rows above).
  - The admitted instrument failed. A direct run of the suite under the hook CI layout read allow on the must-block arms sampled (1,142 PASS / 579 FAIL before it was stopped), so that probe is **unusable**. [INFERRED cause: the layout's workspace-scope guard was inert without the setting the runner exports for its own subshells, per the runner's header.]
  - A control refused the corrective single-suite spelling (Control firings).
  - The documented runner sets that value inside its own process. It was not run in this pass, for time: the full harness takes minutes on CI and longer at this host's load. No control forbids it.
  - The empirical re-measure is therefore placed at the Stage-6 RED commits, each run through the documented runner.
- **Parallelization-Map currency.** The milestone carries no `## Parallelization Map (recorded …)` H2. That is a Tier 1 [ADJUST]. A draft is below for the Phase B1 PATCH.
- **Ticket-architecture reconciliation.** The cards were filed between 2026-10-15 and 2026-10-25. The governing fragment last changed on 2026-11-15/16 (v5.11), and ADR-150 on 2026-10-23. The citations are by section and re-verified (A0.5). No architecture-surface citation is stale.
- **Currency-decision confidence gate.** The outcome is **amend**: the Phase B1 PATCH adds the Parallelization Map and the `**Limb owners:**` line, plus the Tier-1 AC proposals, which go to the hub. The signal is CONVERGENT, because A0.5, A0.6 and the map check agree on the same deltas. The outcome proceeds at its existing authorization.

## Dependency Graph

Native edges, read through GraphQL `blockedBy`/`blocking` on all five: **0 in-bundle**. The one native edge is #8493 ← #7018 (CLOSED, satisfied). The milestone's reconfirm scan returns `CLEAN` 1 (#8493, typed 1) and `NO-SECTION` 5 (the bug template has no Dependencies field, plus the sub-task).

Derived edges (implementation, not issue dependencies):

```
#8490 ──file-contention + shared arm (exec first view)──▶ #8548   (boundary: CIAC-1)
#8490, #8548, #8326, #8493 ──"ceiling bounds the final walk"──▶ #8327   (sequencing; CIAC-3)
#8490, #8548, #8493 ──post-deploy readings──▶ Stage 12 hook refresh   (D-Readings)
#8326 ──file-contention only (here-document pre-pass)── others
```

There are no cycles: 3 derived ordering edges, all pointing toward #8327 or the deploy.

## Implementation Sequence

The topology is single-branch `release/script-guard-refuses-only-what-executes`: one PR for the milestone. The posture is P0 fully serial (D-Concurrency).

**A RED commit precedes every fix.** Where the behaviour is believed correct, the arm is armed red and then reverted, with the prediction stated in the commit message before the run. The **tracked walk payload corpus differential is the exit bar.** Every measurement runs in the worktree under `core/hooks/tests/setup-ci-layout.sh` and the documented runner, never against the deployed hooks. Exact must-refuse spellings stay off public surfaces: commit messages and comments describe them by class, and the spellings live only in tracked fixtures, addressed by row id.

0. **Engineering Commit 0.**
   - Write the plan file, after the Commit-0 version re-verify and `release/tools/claim-version.sh --verify-stamp`.
   - Read the suite floor: the full runner's AGGREGATE, which becomes the floor at 0 FAIL.
   - Add corpus rows at **today's** verdict for each must-allow shape: groups `looks-like-text` (#8490), `looks-like-asgn` (#8548) and `looks-like-hd` (#8326), ground truth `-`. Each card's GREEN commit re-grades its own rows to `a` and declares it (v5.11 DEV-10).
   - Add latency fixtures from the existing placeholders (`@LONGX@`, `@LONGN@`, `@QPAD@`).
1. **#8490.** RED: the must-not-flag text arms are red; the must-flag and listed-script substitution arms are armed red, then reverted. GREEN: the exec arm's command-word test stops reading a backtick-led token in text as a command word, and a real substitution is adjudicated as the script it runs. Fragment: the class's disposition in the graduation record. Regenerate the registry in the same commit.
2. **#8548.** RED, then GREEN: the first view attributes an interpreter inside an assignment value's substitution to the interpreter arm. Measured on both views. Fragment: the hold-back list item. Regenerate the registry.
3. **#8326.** RED, then GREEN: the receiver resolution steps over a group opener, and the carrier membership follows the Stage-5 decision under D-Family. Any added member answers both tests, each with an arm. The L43 re-check is recorded. Regenerate the registry.
4. **#8493.**
   - Sweep arms in the suite (bash, sh, and a splitting control). A failing member stops the slice and routes Tier 2: it is re-filed at P1, and the operator decides.
   - RED, then GREEN: the route's refusal names its cause, and the block-log tag follows D-Readings.
   - Fragment: the plain set's fail-safe property stated as measured on each shell, and the reading specification.
5. **#8327.** RED: timing arms on the final walk, including every scan slices 1–4 added (CIAC-3), with predictions in the commit message, measured on an idle host with the load average recorded. GREEN: the per-command ceiling and its at-ceiling direction, per D-F07. Fragment and registry.
6. **Close of Engineering.** Full runner at or above the floor; the WALKCORPUS differential with zero undeclared refuse/record→allow movements; `bash core/deploy/deploy.sh --check`; `release/tools/verify-release-plan.sh` on the plan.
7. **Post-deploy (Stage 12/13).** The operator refreshes the deployed hooks. Check 79 asserts the deployed copy equals the merged source. Then the D-Readings readings run.

### Agent-Editability Read

**Derivation.** Controls read at commit `b7ea0de8`:

- **Tier-0 floor:** `core/hooks/block-autonomy-ceiling.sh`, every `case` block whose arms invoke `always_block "BLOCK-AUTONOMY-001"`. **2 blocks observed.**
  - Block 1 arms, verbatim:
    - `"${PRIMARY_ROOT}/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/projects/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/CLAUDE.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/OPERATIONS.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/OPERATIONS.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/RELEASE_PROTOCOL.md"`
    - `"${PRIMARY_ROOT}/pmo-platform/"*"/RELEASE_PROTOCOL.md"`
    - `"${PRIMARY_ROOT}/.claude/settings.json"`
    - `"${PRIMARY_ROOT}/.claude/hooks/"*`
    - `"${PRIMARY_ROOT}/.claude/rules/"*`
  - Block 2 arms (membership): `*/CLAUDE.md|*/OPERATIONS.md|*/RELEASE_PROTOCOL.md`
  - Projected and filtered against the tracked index: the 3 `.claude/` arms are **discarded**, because the repository tracks 0 `.claude/` files (control: 84 tracked `core/hooks/` files). The union is the 3 governance basenames, of which the repository tracks 3.
- **Sanctioned-session gate:** `core/hooks/block-skill-direct-edit.sh`.
  - `SKILL_SCOPE_RE` = `(^|/)(operations|release|core|pmo-platform)/skills/[^/]+/(SKILL\.md|references?/.+\.md)$`
  - Arming key = `^skill_discipline_migrated_v10_2:[[:space:]]*true[[:space:]]*$`
  - The exemption list at its deployed path is `undetermined`: it was not read.
  - Conjunct 1 is false for every write-set path, and that decides every row.

| Card | Write-set path | Tier-0 ∩ | Skill-gate ∩ | Path class | Card class | Execution path |
|---|---|---|---|---|---|---|
| all five | `core/hooks/block-destructive.sh` | no | no (conjunct 1) | unconstrained | unconstrained | ordinary Engineering spoke, or hub-direct under the standing rule |
| all five | `core/hooks/tests/block-destructive.test.sh` | no | no (conjunct 1) | unconstrained | unconstrained | the same |
| #8490, #8548, #8326, #8327 | `core/hooks/tests/fixtures/walk-payload-corpus.txt` | no | no (conjunct 1) | unconstrained | unconstrained | the same |
| all five | `core/rules/bypass-mode-readiness/block-destructive.md` | no | no (conjunct 1) | unconstrained | unconstrained | the same |
| all five | `core/rules/bypass-mode-readiness.md` (generated) | no | no | class of its source, the fragment: unconstrained | unconstrained | regenerated by `core/deploy/tools/build-hook-registry.py`, never hand-edited |
| hub (Commit 0) | `release/releases/plans/script-guard-refuses-only-what-executes_RELEASE_PLAN.md` | no | no (conjunct 1) | unconstrained | — | the first Engineering spoke, or the hub |

**Note on the Stage-12 refresh. It is outside this read, which covers `Write`/`Edit` payloads only.** The deployed hook tree sits under the anchored Tier-0 arm `"${PRIMARY_ROOT}/.claude/hooks/"*`. The refresh itself is a script: the hook carrier `docs/scripts/setup-workspace.sh --refresh-hooks`. That carrier has no agent-invocable allowlist row, so the refresh is **operator-executed** and never routes through the bypass variable.

## Stage Applicability Matrix

Stage 5 activates for the **whole release**. T4 fires on #8490, #8548, #8326 and #8327, each of which names two or more candidate mechanisms or values. T6 fires on #8490 and #8548 ("chosen at Stage 5 Solutioning") and on #8493 (its population is an open assumption). The `novel` bias is ALL.

| Issue | 5 Sol. | 6 Eng. | 7 DT | 8 QA | 9 Plan Review | 10–11 | 12 Execute | 13 Close |
|---|---|---|---|---|---|---|---|---|
| #8490 | ✅ text/substitution split; hook vs reading | ✅ | ✅ | ✅ | ✅ (Deep) | compressed (git-native) | ✅ | ✅ + AC4 post-deploy reading |
| #8548 | ✅ walk vs reading; both views measured | ✅ | ✅ | ✅ | ✅ | compressed | ✅ | ✅ + AC4 post-deploy reading |
| #8326 | ✅ receiver resolution; carrier membership under D-Family; L43 | ✅ | ✅ | ✅ | ✅ | compressed | ✅ | ✅ |
| #8327 | ✅ ceiling value against 600 s; at-ceiling direction (D-F07) | ✅ | ✅ (idle-host timing) | ✅ | ✅ | compressed | ✅ | ✅ |
| #8493 | ✅ sweep as a suite arm; cause tag; reading population | ✅ | ✅ | ✅ | ✅ | compressed | ✅ | ✅ + AC2 live-traffic reading |

**Execution paths (carry-forward 8; standing rule of 2026-11-17).**

- Each spoke is spawned once. A spoke stopped by a safety classifier is taken over by the hub, which builds that card directly. A stopped independent review (the Stage 7/8 review, or an adversarial review) goes to the **operator**, not to the hub, to keep it independent.
- Evidence: in v5.11, #8491 and #8320 were built hub-direct after classifier stops; seven agents were stopped on this code (v5.11 plan DEV-13 and DEV-14).
- Chip prompts describe payloads by class and address them by fixture row id, never by spelling.

## Contention Map

**Within the release.** All five cards edit the same three surfaces, so the contention is total by construction:

- `core/hooks/block-destructive.sh` (5/5)
- `core/hooks/tests/block-destructive.test.sh` (5/5)
- `core/rules/bypass-mode-readiness/block-destructive.md` (5/5), and with it the generated `core/rules/bypass-mode-readiness.md`

The walk corpus is shared by #8490, #8548, #8326 and #8327. Every pair has a probable `line-range-overlap` class, which cannot be computed until the hunks exist. Where the overlap falls:

- #8490 and #8548 share the exec arm's first-view command-word site and the assignment-prefix walk.
- #8326 sits in the here-document pre-pass and the head walk.
- #8327 reaches every scan.

Resolved by **serial sequencing (P0)** in the order above, with the fragment and registry regenerated per slice so each commit stays `--check`-green.

**Cross-PR Overlap Audit (A4).**

`### Baseline SHA` `b7ea0de862f9` (origin/main at 2026-11-17T21:44Z).

The scan covered 3 open PRs and 16 files, and found **0** on the -022 surface. The specificity arm is the pattern `block-destructive|walk-payload|bypass-mode-readiness|script-execution-allowlist|core/hooks/`, and it returned 0 for each PR. Re-read at 2026-11-17T22:13Z: the same 3 PRs and the same 0. The sensitivity arm shows each PR's file list is non-empty: #9054 begins `.version, CHANGELOG.md, RELEASE_DIGEST.md`. Every `overlap_class` is `single-pr`. `check-line-range-overlap.py` was not needed, because fewer than three PRs contend.

**Cross-milestone (open milestones).** The scan covered 48 open milestones, 237 open milestoned issues and 696 open issues in total, all fetched under `--limit 5000`. It searched issue bodies for the four -022 paths. The control found this milestone's own five cards and the sub-task.

| Milestone | Cards | Edge | Note |
|---|---|---|---|
| `script-guard-reads-every-token-as-the-shell-does` (v5.11) | 7 (#8316–#8320, #8491, #8492) | file-contention, **settled** | Code merged (#8993). Stage 13 is open; its PR #9054 touches none of these files |
| `spoke-authority-bounded` | #5184 (a new rule in the same hook), #5289 (conditional limb), #4918 | file-contention, soft | No branch in flight. The rule regions differ, so the probable class is `append-pattern`. Whichever starts later rebases |
| `evergreen-cleanup-batch` | #6195 | reference-only | It cites -022's per-arm constants as precedent for the egress hook [INFERRED: no edit to this file] |

**Structural blast radius (A4).** This release declares no rename, relocate or delete (empty mover set), so it has no structural surface. A0.7 is a SKIP. The version-slot token `Δversion/minor-after-v5.13` meets no in-flight sibling (roster below).

### In-Flight Release Roster

**Measured at:** `b7ea0de8` · `2026-11-17T22:13:28Z` · **Population:** n=0 sibling(s): none in flight at `b7ea0de8` / 2026-11-17T22:13:28Z. The read found 0 remote `release/*` heads and no open PR with a `release/*` head. Control: the same `ls-remote` returns 3 `chore/*` heads.

## File Change Matrix

The release is **5 EDIT + 1 ADD** unconditional, plus CONDITIONAL rows. No row is a delete.

```
# ── release-wide (always delivered) ──
core/hooks/block-destructive.sh  EDIT
core/hooks/tests/block-destructive.test.sh  EDIT
core/hooks/tests/fixtures/walk-payload-corpus.txt  EDIT
core/rules/bypass-mode-readiness/block-destructive.md  EDIT
core/rules/bypass-mode-readiness.md  EDIT
release/releases/plans/script-guard-refuses-only-what-executes_RELEASE_PLAN.md  ADD
core/ADRs/ADR-150-block-destructive-022-governs-execution-capability.md  EDIT
# ── CONDITIONAL ──
CONDITIONAL:CORPUS-GROUP core/hooks/tests/fixtures/README.md  EDIT
CONDITIONAL:SWEEP-SCRIPT core/hooks/tests/plain-set-sweep.sh  ADD
CONDITIONAL:SWEEP-SCRIPT core/config/allowlists/script-execution-allowlist.txt  EDIT
CONDITIONAL:SWEEP-CI .github/workflows/install-tests.yml  EDIT
```

What each conditional row depends on, and the rules on generated and read-only files:

- `core/rules/bypass-mode-readiness.md` is generated from the fragment by `core/deploy/tools/build-hook-registry.py` and never hand-edited.
- `CORPUS-GROUP` fires if a new group class or placeholder needs the README's row procedure.
- `SWEEP-SCRIPT` and `SWEEP-CI` fire only if Stage 5 rejects the planned shape, a sweep arm inside the suite, for a standalone script. The script then ships with its four allowlist invocation forms in the same release, and is CI-executed in the macOS shell-harness job.
- `ADR-150-AMEND` fires if D-F07 picks the fail-closed deny, which changes the arm's stated failure posture.
- A fired conditional row is promoted at Engineering Commit 0 or in the commit that fires it.

**Read-only inputs (NOT EDITED):**

- `core/hooks/lib/command-position.awk`. -022 does not route through it.
- `core/settings.json.template`. A settings `onFailure` or `timeout` key is #8660's surface.
- The deployed hook tree, which is operator-refreshed at Stage 12.

**Domain classification** (A3, from the matrix): every row is internal hook code, its suite, its fixture or its readiness text. That makes the release `domain: software`. The label is under the Release Class declaration.

**Parse check (fcm-delivery).** This block was run through `release/tools/verify-release-plan.sh`'s delivered-set test seam on a draft plan. Result: declared=11, interpreted=11, obligations=1 (the plan ADD), conditional=1, uninterpreted=0, pathless=0. Control: removing the ADD from the delivered set turns `FCM-1` FAIL. One defect was found and fixed before posting: a block label that contained the word "unconditional" was read as a CONDITIONAL sub-heading.

## Risk Register

The control census: risks=16 · control=R1, R2, R3, R4, R5, R6, R15 · owner-act=R7, R8, R9, R10, R11, R12, R13, R14, R16. Read 2026-11-17T22:13Z. Under G-PR4, a control-rested row is accepted only once that control is observed acting.

| ID | Risk | Type | Severity | Mitigation / disposition |
|---|---|---|---|---|
| R1 | #8490 drops backtick-led text too broadly, so a real substitution that runs an unlisted script moves to allow | scope / security | High | Must-flag arms (#8490 AC2), the CIAC-1 partition, and the WALKCORPUS differential, with zero undeclared movements |
| R2 | The #8490/#8548 boundary leaves a gap or a double owner for substitution forms | dependency | Medium | The boundary is stated in the Summary. The Tier-1 #8490 AC2 clause. CIAC-1 |
| R3 | A carrier-set change fails open for a stdin-executing receiver (#8326) | security | High | The membership conjunction, with an arm for each test per added member. D-Family binds (own model, no shared lexer). The direction is always allowlist |
| R4 | Fixes silently flip the enclosure view's declared pins: 10 over-match, 5 under-match and 2 budget pins (`AC-ENCL-RESIDUAL-*`) | contention | Medium | #8326 is expected to re-point some of them. `AC-ENCL-RESIDUAL-heredoc-kept` is #8326's own shape: a non-carrier receiver whose here-document body names a script in a code span. `-hd-cat` moves if `cat` joins the carrier set. `-hd-continuation` carries L43. A pin whose verdict moves is re-pointed in the same commit with its reason, as v5.11 did with `F1-QTOK-RESIDUAL-space`. Pin labels are counted at Commit 0 and re-counted at close |
| R5 | #8327's ceiling degrades toward an allow, or its fail-closed deny refuses large legitimate inline bodies (the inline here-document body idiom) | security / availability | High | A must-not-allow arm at the ceiling. D-F07 names the availability cost; the remedy for a refused body is a file passed by reference |
| R6 | Timing arms flap on a loaded host (load average 10.7 at this read) | test validity | Medium | Ratio budgets against an in-run control copy (`LIN_LIMIT` / `AC-022-Z-CTL` precedent). The load average is recorded with every RED/GREEN timing. Re-time on an idle host |
| R7 | A safety classifier stops spokes on this code (v5.11 DEV-13/DEV-14: seven stops) | execution | High | The standing rule: spawn once, hub-direct on a stop, a stopped review to the operator. Prompts describe payloads by class and fixture row id |
| R8 | The post-deploy readings cannot be taken from today's instruments: no hook hash or command in drain rows, no cause in block-log rows | verification | Medium | D-Readings |
| R9 | The deployed hook is not refreshed, so the readings measure the old build | deploy | Medium | Operator-executed carrier at Stage 12 (tier-0-floored path). The hub verifies with `bash core/deploy/deploy.sh --check` (Check 79) before any reading |
| R10 | Exec-arm rows at enclosure positions, much of them prose: 9,408 of 11,519 since 2026-10-26. #8490 owns 416 of them; 8,992 are unowned. A 2026-12-15 graduation would refuse them | scope / outcome | High | D-EnclosureExecRows. The Outcome draft claims only the two named classes |
| R11 | Cross-milestone file contention: `spoke-authority-bounded` (#5184 adds a rule to the same hook) | contention | Low | Not in flight. Whichever starts later rebases. Stage 9 A6.5 re-checks |
| R12 | Date: the 2026-12-15 (Tue) review needs a post-publish drain with at least 25 evidence rows (`DESTRUCTIVE_022_EXEC_REVIEW_ROWS`) | schedule | Medium | Ship and refresh before then. The milestone already states that the graduation waits if it has not shipped |
| R13 | #8493's sweep finds a wrongly included plain-set member, a fail-open on an always-enforce arm | security | High if it fires | Stop the slice, re-file at P1, Tier 2 to the operator. Fixing in-release is not planned |
| R14 | Rollback complexity: the PR revert restores source, but the deployed copy needs a second operator refresh | rollback | Medium | MODERATE. The carrier keeps hook snapshots (`--restore-hooks`). Rollback Strategy below |
| R15 | Registry drift: a fragment edit without regeneration | consistency | Low | Regenerate in the same commit. The registry `--check` in CI. CIAC-4 |
| R16 | The version slot: v5.14 is provisional and may be claimed first | version | Low | The Commit-0 re-verify and the Stage-12 atomic claim |

## Cross-Issue Acceptance Criteria

**Arm and group naming convention, which binds the CIACs.** A Stage-5 or Stage-6 rename of an arm label or corpus group amends its CIAC in the same change.

- Substitution-boundary arms: `SUBST-BOUNDARY-TEXT-LISTED`, `-TEXT-UNLISTED`, `-ASGN-LISTED`, `-ASGN-UNLISTED`
- Corpus groups: `looks-like-text`, `looks-like-asgn`, `looks-like-hd`
- Ceiling-over-new-scan arms: `CEIL-NEWSCAN-TEXT`, `-ASGN`, `-HD`
- Per-issue arm prefixes, disjoint from one another and from the CIAC prefixes: `EXEC-TEXT-NF` · `HD-RECV-ADMIT-` · `HD-RECV-MF` · `CEIL-SHAPE-` · `CEIL-AT-CAP` · `CEIL-CTL` · `LATCH-SWEEP-` · `LATCH-CAUSE-`

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#8490 × #8548 on `core/hooks/tests/block-destructive.test.sh`):** each command-substitution execution shape on the exec arm belongs to exactly one card. A substitution outside an assignment's value is #8490's; a substitution inside an assignment's value is #8548's. Each owner carries a listed-script must-not-flag arm and an unlisted-script must-flag arm. *Method:* `grep -c -F "SUBST-BOUNDARY-" core/hooks/tests/block-destructive.test.sh` at least 4. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#8490 × #8548 × #8326 on `core/hooks/tests/fixtures/walk-payload-corpus.txt`):** the corpus carries at least two rows per card for the shapes this release admits, under the shared group prefix. Each row was re-graded to `a` in its card's GREEN commit, so the single differential grades all three cards together. *Method:* `grep -c -F "|looks-like-" core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 6. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#8327 × #8490 × #8548 × #8326 on `core/hooks/tests/block-destructive.test.sh`):** every scan the three precision cards add charges the per-command ceiling, and has a timing arm under the ceiling's cap on the final walk. *Method:* `grep -c -F "CEIL-NEWSCAN-" core/hooks/tests/block-destructive.test.sh` at least 3. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-4 (#8490 × #8548 on `core/rules/bypass-mode-readiness/block-destructive.md`):** the exec arm's graduation record states the disposition, as of merge, of all four hold-backs it lists, including the two this release clears, and the generated registry equals the fragments. *Method:* declared, verification deferred to core/rules/bypass-mode-readiness/block-destructive.md (the graduation record) and core/deploy/tools/build-hook-registry.py (the registry check run in CI). *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-5 (#8490 × #8548 × #8493 on the post-deploy reading specification):** one reading specification in the fragment governs all three readings. It states the population, a window opening at the Stage-12 hook refresh, a hook hash taken at reading time, and a control. *Method:* declared, verification deferred to core/rules/bypass-mode-readiness/block-destructive.md (the reading specification). *Graded at Stage 9 QC3.5 on the merged PR.*

**Lint (G4-06).** `release/tools/verify-release-plan.sh --ciac-lint` was run on this section written to a draft plan file:

`CIAC-LINT-SUMMARY	declared=5	parsed=5	clean=3	declared-deferral=2	flagged=0` (exit 0; CIAC-1..3 CLEAN, CIAC-4..5 DECLARED)

## Verification Plan

**AC baseline.** The counts read at plan time against `b7ea0de8`: #8490 4 · #8548 4 · #8326 3 · #8327 3 · #8493 3, so 17. If the hub applies the proposed #8326 AC4, #8326 becomes 4 and its row is bound in the same change.

**Suite floor.** Read at Engineering Commit 0 by the full runner (`bash .claude/hooks/tests/test-runner.sh` after the layout build). The floor is 0 FAIL and an AGGREGATE at or above the Commit-0 count.

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|---|---|---|---|
| #8490 | AC-1 | `grep -c -F "EXEC-TEXT-NF" core/hooks/tests/block-destructive.test.sh` at least 1 | ≥1 must-not-flag arm; red at its RED commit; its behaviour graded by the suite in the CI shell harness |
| #8490 | AC-2 | `grep -c -F "SUBST-BOUNDARY-TEXT-" core/hooks/tests/block-destructive.test.sh` at least 2 | the listed and unlisted pair on substitutions outside an assignment value |
| #8490 | AC-3 | `grep -c -F "looks-like-text" core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 2 | 0 undeclared refuse/record→allow movements on the WALKCORPUS differential · control: the same run grades ≥1,378 `block-destructive` corpus rows |
| #8490 | AC-4 | [DEFERRED — post-deploy reading of the git-ignored drain at the Stage-13 outcome window, per D-Readings] | the class reported with count, window, reading-time hook hash and command count |
| #8548 | AC-1 | `grep -c -F "SUBST-BOUNDARY-ASGN-LISTED" core/hooks/tests/block-destructive.test.sh` at least 1 | the listed script inside an assignment's substitution writes no exec row |
| #8548 | AC-2 | `grep -c -F "SUBST-BOUNDARY-ASGN-UNLISTED" core/hooks/tests/block-destructive.test.sh` at least 1 | the unlisted script adjudicated as today or more strictly, on both views |
| #8548 | AC-3 | `grep -c -F "looks-like-asgn" core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 2 | 0 undeclared movements · control: as #8490 AC-3 |
| #8548 | AC-4 | [DEFERRED — post-deploy reading with #8490 AC-4, per D-Readings] | the population reported on its own |
| #8326 | AC-1 | `grep -c -F "HD-RECV-ADMIT-" core/hooks/tests/block-destructive.test.sh` at least 2 | the allowlist-direction receiver arms and the group-opener arm, red pre-fix |
| #8326 | AC-2 | `grep -c -F "HD-RECV-MF" core/hooks/tests/block-destructive.test.sh` at least 1 | a stdin-executing receiver is still refused |
| #8326 | AC-3 | `grep -c -F "looks-like-hd" core/hooks/tests/fixtures/walk-payload-corpus.txt` at least 2 | 0 undeclared movements; the full runner at or above the Commit-0 floor · control: as #8490 AC-3 |
| #8327 | AC-1 | `grep -c -F "CEIL-SHAPE-" core/hooks/tests/block-destructive.test.sh` at least 4 | timing arms for a long segment, many segments, empty quotes and enclosure openers, under the cap |
| #8327 | AC-2 | `grep -c -F "CEIL-AT-CAP" core/hooks/tests/block-destructive.test.sh` at least 1 | at the ceiling the verdict is never an allow |
| #8327 | AC-3 | `grep -c -F "CEIL-CTL" core/hooks/tests/block-destructive.test.sh` at least 1 | ordinary commands are unaffected; the full runner at or above the floor |
| #8493 | AC-1 | `grep -c -F "LATCH-SWEEP-" core/hooks/tests/block-destructive.test.sh` at least 3 | bash and sh, every non-alphanumeric member in 8 positions, plus a splitting control |
| #8493 | AC-2 | [DEFERRED — live-traffic reading after the Stage-12 hook refresh, per D-Readings] | the population, window, and legitimate-work count stated |
| #8493 | AC-3 | `grep -c -F "LATCH-CAUSE-" core/hooks/tests/block-destructive.test.sh` at least 1 | the route's refusal names its condition |

**Parse check.** `release/tools/verify-release-plan.sh` read this table as a draft plan. It parsed 17 rows: 14 per-issue rows read FAIL at the pin and 3 declared-deferred rows read SKIP, with 0 ERROR. The FAILs are expected: no arm or group carrying the proposed prefixes exists yet. Each prefix has 0 occurrences in the suite and corpus; the control `AC-ENCL-` has 132. The rows turn PASS only as each slice authors its arms.

**Release-level verification.**

- `bash core/deploy/deploy.sh --check` passes: the registry, mirror and hook checks.
- The CIAC lint is re-read at Gate 1, at Stage-6 entry and at Stage 9.
- The Success Indicator's "deployed copy equals merged source" is graded at Stage 12, after the operator's hook refresh, by Check 79 in the same `--check` run.

## Delivery Strategy · Rollback Strategy

- **Delivery.**
  - One branch, `release/script-guard-refuses-only-what-executes`, and one PR.
  - Each card is a RED/GREEN slice pair, serial (P0), and no force-push.
  - Merge at Stage 12 under the atomic version claim.
  - The operator refreshes the deployed hooks with `docs/scripts/setup-workspace.sh --refresh-hooks` from their own terminal.
  - The hub verifies Check 79, then opens the reading window.
- **Per-issue rollback.** Revert the card's GREEN commit; its RED arms then read red again by design. The fragment and registry are regenerated in the same revert.
- **Whole-release rollback.** Revert the merge on `main`, then have the operator re-run the carrier or `--restore-hooks` to the pre-release generation. The version tag stays (Tag Retention).
- **Reversibility.** MODERATE overall, because of the deployed-copy second step. CHEAP per slice before merge. Confidence HIGH.

## Quota Budget

**Verdict:** WARN (per `quota-budget-protocol.md` Checkpoint A). The verdict basis is **`UNSTATED`**, so the conservative default applies.
**Parallel-eligible spokes per parallel stage (from the A2 Stage Applicability Matrix):** Stage 5: 5 · Stage 7: 5 · Stage 8: 5
**Per-spoke cost estimate:** size-bucket ordinal band: 4 × `size:M` low–moderate and 1 × `size:S` lowest. If D-F07 takes L, one moves to moderate–high (source: heuristic, § 5).
**Assumed/stated remaining usage-window envelope:** UNSTATED, because the plan does not report the 5-hour window. The operator states weekly all-models usage at 41 %, resetting 2026-11-20T15:00Z (Fri) [ASSUMPTION – CONFIRM]. That is a weekly band, not the 5-hour envelope.
**Estimated cumulative draw % (worst parallel batch):** not synthesized (§ 6.1 refuse-to-synthesize). The worst batch is any of Stage 5, 7 or 8 at 5-wide.
**Routing:** WARN. Window-aware launch timing, and each 5-wide stage split into sub-waves of at most 2 (the UNSTATED `W_max` of 2, § 4.3c), giving 3 sub-waves.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch, wave or singleton, at every stage. That runtime check is the load-bearing one. A wave gets PROCEED/SERIALIZE/DEFER/REDUCE-scope and a singleton gets PROCEED/DEFER. STAGGER is a secondary, rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on the host-API quota (`core`/`graphql` pools), combined DEFER-dominant (§ 4.3b). Checkpoint A stays usage-window-only (§ 3.1). The bands, the cumulative-draw budget and the host-API floor are `[CALIBRATE-AFTER-3]`, MEDIUM.

**The weekly axis is not graded by this protocol, but it binds.** v5.11 DEV-14 measured a spoke pass on this code at about 8–12 % of the weekly window, against 1–3 % for a hub build [SOURCE: v5.11 plan DEV-14]. With 59 % of the week left, the 15 Stage 5/7/8 spoke passes [INFERRED: at DEV-14's rate] cannot all run before 2026-11-20T15:00Z. Recommendation R-REC-3 covers it.

## Parallelization Map (draft for the Phase B1 PATCH)

```
## Parallelization Map (recorded 2026-11-17)

**Verdict:** Tier-B soft-coupled — bidirectional scan; no hard edge, no structural edge, no version-slot collision.

| Other milestone | Direction | Edge type | Body confirmation |
|---|---|---|---|
| script-guard-reads-every-token-as-the-shell-does | other-blocks-this (satisfied) | file-contention | same -022 walk; its PR #8993 merged 2026-11-17; its open Stage-13 PR #9054 touches none of this release's files |
| spoke-authority-bounded | bidirectional | file-contention | #5184 adds a new rule to core/hooks/block-destructive.sh; no branch in flight; later starter rebases |
| labels-and-allowlists-have-a-stated-rule | soft | soft | #6425 is the exec arm's other graduation owner (release gate, not a build dependency) |
| engineering-harness-pages-published | soft | soft | its process-catalog pages cite hook text |

**Reconfirm procedure:** the A9.6 scan (members 6: CLEAN 1, NO-SECTION 5; edge candidate #8493 typed 1 → #7018 CLOSED), plus the mover and version-slot clauses; reconfirmed at Stage 4 Phase A0 on 2026-11-17 against b7ea0de8.
```

## Release Outcome Statement (draft, for Phase B1)

- **AFTER.** BLOCK-DESTRUCTIVE-022 refuses commands that execute a script and lets text through that only looks like one: a backtick-led path inside text, or a here-document fed to a non-carrier receiver or to one behind a group opener. An allowlisted script run inside an assignment's command substitution is admitted as the script it is. The rule's per-command work stays bounded on pathological shapes, and both error directions of its option-run latch are measured. That clears the two over-match classes the exec arm's record names as holding it back from enforce at its 2026-12-15 (Tuesday) review. The arm's other enclosure-position rows are read separately, as the 2026-10-23 decision requires.
- **BEFORE.** Unchanged from the milestone.
- **Actor(s):** unchanged from the milestone.
- **Success Indicator:** unchanged from the milestone.

**Limb owners:** text through the exec arm → #8490 · allowlisted script in an assignment's substitution admitted → #8548 · here-document inert shapes admitted → #8326 · per-command work bounded → #8327 · latch error directions measured → #8493

## Release Class declaration

**Proposed: `novel`**, confirming the milestone. Trigger (b) fires: the plan carries D-class decisions (D-F07, D-Readings, D-EnclosureExecRows). The `routine` class fails on (a), because #8490 and #8548 are P1, and on (d). The `cross-cutting` class does not fire: no `stage-*.md` file and none of the six rule-defining surfaces is touched. The `hotfix` class fails on (b), because the bundle has more than 3 issues.

Differentiation posture:

- Engagement density **Standard**
- Stage 9 review depth **Deep**
- Stage 5 activation bias **ALL**
- Stage 13 outcome window **30-day**, whose window holds the 2026-12-15 review

The milestone's `## Release Class` block lacks the posture sub-field. Add it in the Phase B1 PATCH.

`domain_practice: { source: N/A — pipeline-internal release, date: 2026-11-17, domain: software }`

## Operator Decisions (D-Gate Block)

### D-F07: Does #8327 take the Stage-7 F-07 re-rating (a fail-open with a fail-closed remedy), and at what size?
**Gate input:** Stage 7 F-07 (#8180): a real ~100 kB inline body ran past the 600 s default, which a PreToolUse hook fails open on [SOURCE: runtime hooks reference]. There are three inbound items: v5.11 R11 (#8975 G5), v5.05 DEV-54, and F-07 itself. Under D8, a measured fail-open on an enforcing rule carries security priority; #8493's own text holds that P1 needs a measured fail-open.
**Gate decision:**
- (A) **Re-rate to P1 and re-size to L.** The ceiling **denies** when it is exhausted, set with margin under 600 s and timed on an idle host. A large inline body is then refused, and the remedy is a file passed by reference. #8660 stays the complementary settings-level remedy and is not pulled in. 22 raw / 25 effective, in band.
- (B) **Re-rate to P2 and keep M.** The ceiling bails to the existing conservative reading, which latches toward adjudication, and the timeout fail-open is left to #8660.
- (C) **Keep P3 and M.** Latency only.
**Blocks:** #8327's Stage 5 design and its RED predictions, and the `ADR-150-AMEND` conditional.
**Upstream compatibility:** N/A. This D-decision does not modify skill-authoring surface, so the upstream compatibility check does not apply.
**Design-Principle Conformance:**
- (A) is ALIGNED with DP-8 Security (core/disciplines/build-philosophy.md:53): a control that cannot finish its rule fails closed. It is ALIGNED with DP-5 Stability (:52): no silent failure. It is **CONFLICT.** with DP-4 Simplicity (:51), because it adds an at-ceiling deny path. Mitigation: reuse the existing `script_qbail` latch site, adding no new structure.
- (B) is **CONFLICT.** with DP-8, because a timeout still fails open until #8660 lands. Mitigation: name #8660 as the owner in the fragment.
- (C) is **CONFLICT.** with DP-8 and DP-5.
- The register entries were last verified 2026-07-27, more than 90 days ago, so this verdict carries that staleness.
**Reversibility / Confidence:** CHEAP, a card re-rating and a re-size. The deny behaviour itself is MODERATE once deployed / MEDIUM.
**Recommendation:** **(A)**. The fail-open is reachable by input size whatever the load, so the load caveat moves only the threshold, not the kind [INFERRED].

### D-Readings: Where do the four deployed-hook readings land, and which instrument do they read?
**Gate input:** #8490 AC4 and #8548 AC4 ask for a hook hash and producing commands, and the drain row has neither. For the same reason, #8490's own closing method for its class-B split (a per-row read against the commands that wrote the rows) cannot run as written. #8493 AC2 asks how many refusals by the two gates were legitimate work, and the block-log row has no cause and only a one-way digest. The Success Indicator reads the deployed copy. The carrier is operator-run.
**Gate decision:**
- (A) **Reading-level instruments, recommended.**
  - The hook hash is taken from the deployed file at reading time, with the window bounded by the Stage-12 refresh instant and its snapshot generation.
  - The command count is distinct timestamps, the 2026-10-16 method. Tier-1 restatements of both AC4s say exactly that.
  - #8493 gains a minimal cause tag on the latch route's refusal row, designed at Stage 5 inside AC3's slice.
  - #8490's split assumption closes at Stage 5 by a per-row read of the path's shape. The record states that a command-level split cannot be derived.
  - The readings are taken by the hub in the Stage-13 30-day window, and the review copy goes to the 2026-12-15 graduation reading.
  - The operator refreshes the deployed hook at Stage 12, and the hub verifies Check 79.
- (B) **Row-level instruments.** Add `hook_sha` and a command digest to every drain row as well. That is more precise and costs per-row hashing on every would-fire, and changes the drain schema the graduation readers parse.
- (C) **Restate all four as reading specifications only.** The readings are owned by the 2026-12-15 review and nothing post-deploy is graded in this release.
**Blocks:** #8490 AC4, #8548 AC4, #8493 AC2 and AC3's slice, and CIAC-5.
**Upstream compatibility:** N/A. This D-decision does not modify skill-authoring surface, so the upstream compatibility check does not apply.
**Design-Principle Conformance:**
- (A) is ALIGNED with DP-4 Simplicity (build-philosophy.md:51), the smallest instrument, and with DP-3 Maintainability (:50), one reading specification.
- (B) is **CONFLICT.** with DP-4, because it widens the drain schema. Mitigation: field-add only, readers unchanged.
- (C) is ALIGNED with DP-4, and **CONFLICT.** with DP-5, because the release leaves its own outcome unmeasured. Mitigation: name the reading owner.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **(A)**.

### D-EnclosureExecRows: Who owns the exec arm's enclosure-position rows that a graduation would refuse?
**Gate input:**
- On the deployed drain since 2026-10-26, outside worktrees, the exec arm wrote 11,519 rows. Of those, 9,408 sit at enclosure positions. 416 of those are backtick-led and owned by #8490; **8,992 are unowned**. The builds in the window are mixed, there is no per-row hash, and worktrees were excluded by a `cwd` substring.
- The fragment records that these rows are "much of it prose", and that an exec-arm graduation "would start refusing" them.
- `destructive_022_exec_verdict` reads `DESTRUCTIVE_022_EXEC_PHASE` alone, with no enclosure-phase branch.
- #8549 owns the enclosure family's shell/source phase, not these rows. #7026 is closed.
**Gate decision:**
- (A) **Route a new owner card through intake** (the hub runs Mode C), keep this milestone's scope, and scope the Outcome claim as drafted.
- (B) **Pull the class into this milestone.** At M it reaches 26 raw / 30 effective with D-F07 (A), which is over the band and forces a split.
- (C) **Record it as a read-separately population** with no owner.
**Blocks:** the Outcome Statement wording at Phase B1. It does not block Engineering.
**Upstream compatibility:** N/A. This D-decision does not modify skill-authoring surface, so the upstream compatibility check does not apply.
**Design-Principle Conformance:** N/A. No design-principle `scope_predicate` matches a scope-routing choice.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **(A)**.

### D-Concurrency Posture: What Stage-6 parallelism posture does this release run?
**Gate input:**
- The A4 contention is total: 5/5 cards on the same three files, with probable line-range overlap.
- The topology is SINGLE.
- There are 5 slices.
- Classifier-stop risk (R7) favours one writer.
**Gate decision:** (A) P0 fully serial · (B) P1 serialized commit lane · (C) P2/P3.
**Blocks:** Stage 6 dispatch.
**Upstream compatibility:** N/A. This D-decision does not modify skill-authoring surface, so the upstream compatibility check does not apply.
**Design-Principle Conformance:** N/A. No design-principle `scope_predicate` matches a dispatch posture.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **(A) P0**. That is also the default when undeclared.

### D-ReleaseClass: What Release Class does this release carry?
**Gate input:** The proposed class with its trigger evidence (the Release Class declaration above).
**Gate decision:** (A) routine, (B) novel, (C) cross-cutting, (D) hotfix.
**Blocks:** the Stage 9 depth and the per-class posture.
**Upstream compatibility:** N/A. Release Class is PMO platform internal taxonomy with no Anthropic upstream surface, so the upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH.
**Recommendation:** **(B) novel**, as declared.

### D-Version: What version does this release claim?
**Rendering:** a RECORDED DETERMINATION, not a click-gate.
- The bump class is **minor**, as the milestone intends: protocol and behaviour modification.
- `git fetch --tags origin` reads `anchor()` = v5.13, claimed at merge `f5df15cd`, which is on `main`.
- No in-flight `release/*` sibling exists (roster n=0). The provisional is **v5.14** [INFERRED: the highest claimed tag after `git fetch --tags`, plus a minor bump. The adapter's `claimed_set()` next-free is recomputed at Engineering Commit 0].
- It is re-verified at Engineering Commit 0 (steps 1–3b) and bound at the Stage-12 atomic claim.
- No (B) or (C) override condition is present.
**Upstream compatibility:** N/A. Version identity is PMO platform internal, so the upstream compatibility check does not apply.
**Reversibility / Confidence:** CHEAP / HIGH.

## Recommendations

- **R-REC-1.** Apply the Tier-1 [ADJUST] proposals at Phase B1. These are hub edits; this spoke made none.
  - The #8490 AC2 boundary clause.
  - The #8326 AC1 restatement and its AC4 (L43).
  - The two AC4 restatements, per D-Readings (A).
  - The #8326 and #8327 Documentation Impact rows.
  - The milestone PATCH: the Parallelization Map, the `**Limb owners:**` line, and the Release Class posture sub-field.
- **R-REC-2.** The sequence moves #8493 ahead of #8327 so that the ceiling is literally last among the edits. #8493's code limb is a message plus a cause tag, so its cost is neutral. The milestone's Internal sequence line places it after #8327; update that line with the PATCH. CHEAP.
- **R-REC-3.** Given DEV-14's weekly cost, prefer hub-direct builds at Stage 6, as in the v5.11 precedent, and keep spokes for Stage 5 design and the Stage 7/8 independent checks. Launch Stage 5 after the 2026-11-20T15:00Z reset if the hub's Checkpoint B reading is not fresh.
- **R-REC-4 (correction, informational).** The Mode R relay and carry-forward 2 say v5.08 changed the -022 walk. It did not (Phase A0, A0.5). The surfaces that did move are #8306, v5.05 and v5.11.
- **Pattern Cache Scan** (`decision-discipline.md` § 2.3). Domain: release-ops.
  - Checked: whether any card's acceptance criteria already pass at the pin, in which case the card is verified and closed rather than rebuilt (CONFIRMED). **Not applicable**: no card's ACs pass at the pin, and every mechanism is present.
  - Checked: the general-behaviour patterns indexed for one-PR milestones, never merging red CI, discrete sizes, no hedge-defer at planning, assertions over prose, and public-surface abstraction.
  - Applied: one PR (Delivery). A single size bucket per card (D-F07 offers L, not "M–L"). D-F07 is decided on gating evidence rather than deferred to an idle re-measure. RED→GREEN arms. Spellings kept off this comment.
  - No emergence candidate; no observation logged (no operator correction in this run).
- **Out-of-scope discoveries.**
  - (1) The enclosure-position exec rows (D-EnclosureExecRows).
  - (2) The deployed drain mixes hook builds with no per-row hash, a general limit of every graduation reading. It is routed through D-Readings (B) if the operator wants it, otherwise noted for #7026's successor readings.
- **Control firings:** 1 firing.
  - The control was the deployed `block-destructive.sh`, rule `BLOCK-DESTRUCTIVE-023`.
  - It tripped on a Bash call that put an environment assignment in front of the allowlisted suite invocation, setting the workspace-scope-guard root that the test runner exports for its own subshells.
  - What came next: **stopped**. It was not retried through the runner or any other route. The suite baseline moves to Engineering Commit 0 through the documented runner.
  - Effect on this plan: A0.8 stays a documented pass-through. The earlier run without that setting is reported as an unusable probe (Phase A0).

## Evidence

- Run directory: `${SCRATCH_BASE}/spoke-4-9058-2aAFux`
- **Pin.** Worktree HEAD = `origin/main` = `b7ea0de862f9`. `git ls-remote` agrees. The CI layout was built in the worktree's own git-ignored `.claude/`, and `git status` is clean.
- **Probe records** (`review-discipline-principles.md` § 1 Rule 15, § 8).
  - **In-bundle native edges = 0.** Invocation: GraphQL `blockedBy`/`blocking` × 5 cards. Denominator: 5. Sensitivity: #8493 → #7018 = 1 (PV-1). Extraction is non-empty for all 5 (PV-0).
  - **Cross-PR overlap = 0.** Invocation: `gh pr list --limit 500` → 3 PRs, `gh pr view --json files` → 16 paths. Specificity pattern: `block-destructive|walk-payload|bypass-mode-readiness|script-execution-allowlist|core/hooks/`. Sensitivity: the PR file lists are non-empty (PV-0/PV-1). Re-read 2026-11-17T22:13Z, unchanged.
  - **In-flight roster n=0.** `git ls-remote --heads origin 'release/*'` = 0. Control: `'chore/*'` = 3 (PV-1).
  - **Whole-command ceiling absent.** `git grep` over ceiling and limit names: 0. Control: the per-feature budget names: 4 (PV-1).
  - **No timeout key.** A JSON walk of both settings files: workspace 0 of 27 entries; block-destructive entries 0 of 3 in each file. Control: 3 account-home entries carry the key (PV-1).
  - **Documented floor undefined.** `git grep -i 'documented floor'` over the hook, suite, runner and fragment: 0. Control: "graduation" in the fragment: 9.
  - **v5.08 did not touch the -022 code surface.** One anchored pattern over the four paths (the hook, its suite, the -022 fragment and the corpus), run on `git diff --name-only <merge>^1 <merge>`: v5.08's `4e70b20f` = 0 of 11 files. Control on the same pattern: v5.11's `20149aeb` = 4 of 13, and v5.05's `e58a77f0` = 4 of 25 (PV-1). All three touched the generated registry.
  - **Drain counts.** A count-only JSON parse of the deployed drain (87,847 rows; 0 unparseable). Exec rows since 2026-10-26: 12,884, of which 11,519 are outside worktrees. Split by `pos` and by the path's leading character. No path or command text left the run directory (PV-6).
  - **AC counts.** A Python parse of the `### Acceptance Criteria` section of each card: 17. Control: the count of checkboxes anywhere in each body is the same (PV-0).
  - **Suite under the layout.** Unusable (Phase A0, A0.8).
- **Main re-read** at 2026-11-17T22:13:28Z: `b7ea0de8`, unchanged from the pin.
- **Who refreshes the deployed hook.** The hook carrier is `docs/scripts/setup-workspace.sh --refresh-hooks`, which `update.sh` delegates to. Check 79 asserts deployed equals source (deploy.sh hook-publish block). The allowlist names the carrier only in a comment, so the refresh is operator-executed. Today the deployed copy's sha256 prefix `2b3cc1128645ccac` equals the merged source.

**Canonical-checklist attestation:** every codified Phase step in `pipeline/stage-04-planning.md` § 5 ran, or is explicitly recorded N/A-with-reason.

- **Ran:**
  - A0 with the G-PL5 cache-read (MISS, then PT-1..4), the ticket-architecture reconciliation, A0.5, A0.6, A0.7 (SKIP: empty window), A0.8 (pass-through: no runnable check), the Parallelization-Map currency check, and the confidence gate.
  - A1 milestone validation: 5 cards, 18 raw / 21 effective, in band, with Composition Lock present.
  - A1.5: Form X exempt with `domain: software`.
  - A2, A3, A3.5, A4 with the in-flight roster, A5, and A6.
- **N/A-with-reason:**
  - The architecture evaluative-lens: no component introduced or reshaped.
  - The structural-blast-radius sub-audit: empty mover set.
  - The sibling-merge stale-pin trigger: empty window.
  - The PT-2 freshness sub-step: no C3 row.
- **Phase B** is the operator's.

**Carry-forward landing** (sub-task Instructions 1–12):

| # | Carry-forward | Landed in |
|---|---|---|
| 1 | Membership change; the #8490 AC2 ↔ #8548 boundary | Summary · A0 #8490 AC2 · CIAC-1 · R2 |
| 2 | Code moved since `4babbba9`; A0.8 re-measure | A0.5 (v5.08 correction) · A0.8 pass-through · Implementation Sequence slices 1–5 RED. **Partly discharged** |
| 3 | v5.11 D-Family; #8317 and #8320 reach; L43; AC1 restated | A0 #8326 rows · proposed AC1 and AC4 · R3 · R4 |
| 4 | Inbound to #8327; the F-07 re-rating; re-size; which timeout binds | A0 #8327 · D-F07 · **the 600 s runtime default binds; 25 s is a measurement cap** |
| 5 | ACs that read a deployed hook, and who refreshes it | D-Readings · Verification Plan · Agent-Editability Read (Stage 12 row) · R9 |
| 6 | #8493 bash/sh sweep | A0 #8493 AC1: a suite arm, CI-run and runner-admitted |
| 7 | Parallelization Map | Draft above |
| 8 | Execution path, standing rule | Stage Applicability Matrix · R7 · R-REC-3 |
| 9 | `**Limb owners:**` line | Outcome draft |
| 10 | Documentation Impact rows | A0.6 |
| 11 | The 2026-12-15 (Tue) date | R12 · Outcome draft · D-Readings |
| 12 | Evidence shape | Implementation Sequence preamble · Verification Plan |

## Operator Decisions — rendered

### Stage 4 plan gate (operator, 2026-11-17)

Recorded on #9058 (comment 6962704266): plan + Outcome approved with the Tier 1 refinements; Collective Review pre-locked (returns to the operator only if Stage 5 changes scope or size); **D-F07 (A)** — #8327 re-rated P1 and re-sized M → L, the ceiling refuses when exhausted; **D-Readings (A)**; **D-EnclosureExecRows (A)** — an owner card held for this release's filing step (#9058 comment 6962807026); **D-Concurrency (A) P0**; **D-ReleaseClass (B) `novel`**; **Stage 6 hub-built**; **D-Version** minor, a recorded determination.

### Stage 5 Collective Review scope lock (operator, 2026-11-18)

Recorded on #9058 (comment 6966866565): the narrowed claims accepted (#8490 AC1, #8548 AC1, the Outcome sentence; the exec arm's graduation record says the text-shaped class is re-attributed, not cleared); **D-8548-A (A)**; **D-8326-1 (A)** and **D-8326-2 (A)**, with the closer rule applied to every receiver reading; the A6.5 gaps of #8326 and #8327 covered by Stages 7 and 8; **D-8493-Legit** — script join, an agent judges only this repository's sessions, every other row on an operator-only worksheet, counts only; **#8327** built in full including **D-8327-3 (A)**, with **D-8327-4 (A)** and the ADR-150 dated amendment. Scope: 5 cards, 22 raw / 25 effective.

## Deviation Log

| ID | Stage | Deviation | Decision |
|---|---|---|---|
| DEV-1 | 4 | #8548 joined the milestone at the Mode R pre-flight; #8327 re-sized M → L (22 raw / 25 effective) | operator, Mode R and the Stage-4 gate |
| DEV-2 | 6 | The branch is cut at `62af4efe`, not the Stage-4 baseline `b7ea0de8`. The window is the v5.13 Stage-12 release-log chore (#9051); `git diff --stat b7ea0de8 62af4efe` over every File Change Matrix path is empty | hub, recorded determination |
| DEV-3 | 6 | Stage 6 is built by the hub, not by spawned Engineering spokes | operator, Stage-4 gate |
| DEV-4 | 6 | File Change Matrix: `CONDITIONAL:ADR-150-AMEND` fired (D-8327-5) and is promoted to `core/ADRs/ADR-150-block-destructive-022-governs-execution-capability.md EDIT`. `CONDITIONAL:CORPUS-GROUP` is promoted in the commit that adds a new corpus group, if the fixtures README's row procedure requires it | Collective Review |
| DEV-5 | 6 | Ground truth for every row Commit 0b adds is `?` (not run): the fixtures README defines ground truth as a run under the real interpreters, and Commit 0b runs no payload. Stage 7 takes the readings (expected `o` for most `looks-like-asgn` rows, `-` for the `looks-like-text` and `looks-like-hd` rows) | #8548 design finding 1, Tier 1; hub |
| DEV-6 | 6 | The Stage-4 premise that the block log's digest is one-way is narrowed: it cannot be inverted but can be matched (#8493 design F-1); D-Readings (A) stands | #8493 design, Tier 1 |
| DEV-8 | 6 | Commit 0b adds 48 corpus rows (LT01–LT04, AS01–AS23, HL01–HL12, HM01–HM11) in 8 new groups at today's verdicts. #8326's closer row (HM09) is an inert subshell, recorded `a` today and moved to B by the closer rule. The runner read every row at its recorded verdict: block-destructive 2096 PASS / 0 FAIL | hub |
| DEV-7 | 5 | v5.08 did not change the -022 walk (the Mode R carry-forward said it did); the surfaces that moved are #8306, v5.05 and v5.11 | Stage-4 spoke, R-REC-4 |
| DEV-9 | 6 | Builders: the hub built #8490, #8493 and #8327. After two safety-classifier stops on the hub, #8326 and #8548 were each built by one Engineering spoke, attempted once | operator, 2026-11-18 |
| DEV-10 | 6 | #8326's closer rule, applied to every receiver reading as the Collective Review rendered it, also refused two inert classes: a carrier whose quoted argument holds a parenthesis (a conventional pull-request title) and a carrier with a closed substitution in its own arguments. Narrowed: a `)` keeps the body only when, read with the shell's quoting from the receiver's head on, it closes an opener the head sits inside | operator, on #8326's Stage 6 sub-task |
| DEV-11 | 6 | #8327: `CEIL-NEWSCAN-ASGN` and `-HD` were authored by the #8548 and #8326 spokes, whose scans were built after #8327; three existing arms that lift hook functions define a no-op ceiling check; R11's Z-cell observation is the existing `AC-022-Z-CTL` arm | hub, Tier 1 |
| DEV-12 | 6 | #8493: `LATCH-CAUSE-opaque-word` and `-ctl-allow` read corpus rows ZH05 and ZU05 in place of the design's candidates | hub, Tier 1 |
| DEV-13 | 6 | #8548: twelve decline markers (six beyond the design), so every decline has a mutant; arms beyond the design's table; the moved-walk test compares indices (FM-3) | spoke, Tier 1 |

## Change Description

### Outcome

BLOCK-DESTRUCTIVE-022 refuses fewer commands that run nothing, and refuses every command it cannot finish reading. Five changes to `core/hooks/block-destructive.sh`:
- **Text read as a path:** a backtick-led command word is no longer read as a path to execute.
- **Substitution in a value:** an allowlisted script inside an assignment's substitution is read as that script.
- **Here-document bodies:** an inert body behind a grammar opener, or received by `cat` with no consumer, is excised.
- **Named causes:** the option-run latch's conservative route names its cause in the refusal and in the block log.
- **Work ceiling:** a per-command deadline and a length gate refuse a command whose reading would outlast the runtime's hook timeout.

### Issues resolved

| # | Outcome | Status |
|---|---|---|
| #8490 | The exec arm declines a backtick-led command word to the enclosure position its backtick opens; the text-shaped hold-back is narrowed and re-attributed, with its residual shapes declared | DONE |
| #8548 | An allowlisted script inside an assignment's substitution is read as that script, not as unresolvable; the second hold-back is narrowed to the admitted spellings, its residuals declared | DONE |
| #8326 | An inert here-document body behind `(`, `{` or a reserved word, or received by `cat` with no consumer, is excised; a closer of the receiver's own enclosure keeps the body | DONE |
| #8493 | The latch's plain set is measured on bash, sh, dash and zsh; the conservative route's refusal names its gate and its block-log row carries `features.route` | DONE |
| #8327 | A 120-second per-command deadline at every loop on the rule's surface and a 65,536-character gate refuse what the rule cannot finish; four cubic quote counts take a linear pass | DONE |

### Key decisions

- **D-8548-A (A):** the bail-latched chained spelling stays a declared residual.
- **D-8326-1 (A), D-8326-2 (A):** `cat` joins a pre-pass-only receiver list under a whole-command no-consumer condition, and the receiver read steps the grammar openers.
- **The closer rule:** it applies to every receiver reading, and the operator narrowed it at Stage 6 to a closer of the receiver's own enclosure (DEV-10).
- **D-8493-Legit:** a refused command's legitimacy is judged by a script join. An agent judges only rows from this repository's own sessions; every other row goes on an operator-only worksheet, and only counts are published.
- **D-8327-3 (A), D-8327-4 (A), D-8327-5:**
  - the enclosure view's two budget exits refuse once an enclosure-reaching arm enforces;
  - the ceiling's row carries `features.ceiling`;
  - ADR-150 gains a dated amendment (the rule's one refusal no phase governs).

### Reversibility

MODERATE · confidence MEDIUM. Before merge, reverting the five GREEN commits restores today's verdicts. Once deployed, the hook refresh is reverted the same way, and the corpus re-grades revert with their commits.

### Downstream impact

- **Exec arm review, 2026-12-15 (Tue):** it reads the first drain written after this hook is published. Two hold-backs are narrowed, not cleared. Their declared residual spellings, and the enclosure-position class (its owner card is held for filing at Stage 9), still gate graduation.
- **Ceiling cost:** an inline command longer than 65,536 characters is now refused. The documented remedy is passing the text by file (`--body-file`, `-F`, or the Write tool).
- **Stage 7 owes:**
  - the real-interpreter readings for corpus rows whose verdict moved (ground truth `?`);
  - a check of the declared standard-input residual for `cat`-received bodies.
- **Follow-up candidates held for filing at Stage 9 / Stage 13:**
  - the enclosure-rows owner card;
  - #8548's blank- or wrapper-led over-block;
  - #8490 F-7;
  - the spoke-template transcript rule;
  - #8548 FM-4, CD-1 and CD-2.

### Cross-references

- This plan: `release/releases/plans/script-guard-refuses-only-what-executes_RELEASE_PLAN.md` (top: § Header, § Summary).
- Milestone #440, `script-guard-refuses-only-what-executes`.
- User-facing release notes: authored at Stage 13 Close under `release/releases/notes/`.
