<!-- reference-durability: allow-link -->
---
title: Release Plan — declarations-have-a-firing-surface (a governed procedure that declares a trigger acquires a named runner or a named gap)
type: release-plan
plan_type: release
status: ACTIVE
release: version-less (theme-named; no tag claimed)
milestone: 368-declarations-have-a-firing-surface
release_class: novel
reversibility: MODERATE / Confidence HIGH
---
# Release Plan — `declarations-have-a-firing-surface`

**Milestone:** `declarations-have-a-firing-surface` (#368) · hub sub-task #6260 = Stage 4 plan source · #6264 = #5825 Stage 5 Solutioning source · #6265 = #5826 Stage 5 Solutioning source · #6266 = this Engineering slice
**Version identity:** **version-less / theme-named** — the milestone title is slug-only, so the release carries no version key. **No tag is claimed at Stage 12**; the Engineering-Commit-0 version re-verify and the Stage-12 atomic version claim are **INAPPLICABLE** (there is no version slot to contend for). No `{{RELEASE_VERSION}}` token is emitted anywhere in this plan, and `claim-version.sh --verify-stamp` is not run.
**Topology:** D-C SINGLE — one release branch (`release/declarations-have-a-firing-surface`), one PR, one merge; this plan lands as **Engineering Commit 0**.
**Concurrency posture:** P0 fully-serial (operator-ratified) — Stage 6 slices route one at a time in dep order on the single branch. #5826's slice builds on this branch after #5825's lands.
**Release class:** `novel` — **re-classified from `routine`** at Stage 4 Plan Review (2026-08-28); see § Operator Decisions § D-ReleaseClass.
**Domain-practice provenance:** `domain_practice: { source: N/A — pipeline-internal release, date: 2026-08-29, domain: governance }` — determined at Stage 4 Phase A1.5 and carried unchanged through Stage 5 (§ 5.7: the design depends on no external best-practice; the governance domain guide was consulted and no contraindication fired).

> **Provenance.** This file transcribes the Stage-4 Release Planning output posted on hub sub-task #6260, reconciled to the approved **Stage-5 Solutioning** designs posted on #6264 (#5825) and #6265 (#5826) and to the **Collective Review scope-lock dispositions** posted on #6266 (decisions **D-3** / **D-4** / **D-5**). Where a scope-lock disposition superseded a Stage-4 assumption, the transcribed sections preserve the Stage-4 plan of record and the **§ Deviation Log** records the ratified delta. Authored at Engineering Commit 0 by the first Engineering spoke (#6266).

---

## Header

| Field | Value |
|-------|-------|
| **Version** | version-less (theme-named; no tag, no stamp manifest) |
| **Date Created** | 2026-08-29 (Saturday) |
| **Release Manager** | Agent-assisted (release-hub Mode O) |
| **Status** | Executing (Stage 6 Engineering) |
| **Branch** | `release/declarations-have-a-firing-surface` |
| **Baseline pin** | `origin/main` @ `e19a9d30682abefac51cca1ff8aa0ebbf8708593` |
| **PR** | (populated at PR creation, Stage 6) |
| **Milestone** | `declarations-have-a-firing-surface` (#368) |

---

## Scope

### Summary

Two members, no hard dependency edge, one in-bundle file contention, **zero stage skips**. The release's capability outcome: **a governed procedure that declares a trigger acquires a named runner or a named gap** — the platform's existing firing-surface machine (the gate-efficacy class-3 register plus `deploy.sh --check` Check 62) is extended by one admission form so it reaches obligation-shaped procedures, and its first instance ships in the same PR.

The mechanism is an **admission-limb extension, not a new registry.** `core/standards/gate-efficacy-standard.md` already defines a class-3 *prose-declared normative predicate* admitted by `L1 ∧ L2` — where `L1` is a **verdict** limb, and the standard excludes conduct-constraining rules in terms. Class 3 gains a second admission form, `L1′ ∧ L2` (the **obligation** limb), routed into the same gate-coverage register and the same Check 62. **Check 62 needs no code change** — its computation was already general over `runner-def:` pointers; only the admission test was narrow.

**A second FORM, not a fourth CLASS.** The standard's `## Scope boundary — three gate classes` heading stays at three, by construction. That is the reason for the form-not-class shape: a fourth class would cascade across the heading, the version-history rows, and every consumer that repeats the count.

### Members

| # | Issue | Size | Surface | Slice |
|---|-------|------|---------|-------|
| 1 | **#5825** Governed procedures declare triggers with no surface that enforces them | L(8) | `core/standards/gate-efficacy-standard.md`, `release/references/templates/design-review-checklist.md`, `core/CLAUDE.md.template`, `release/references/standards/bundle-composition-doctrine.md`, `release/skills/release-hub/references/milestone-readiness-checklist.md`, one ADR | Engineering spoke 1 (this slice) |
| 2 | **#5826** Ship the deferred detector for the `external-target-referent-stored` drift class | M(4) | `core/deploy/deploy.sh` (Check 36, in place), `core/disciplines/knowledge-architecture.md`, `core/disciplines/memory-architecture.md`, `core/deploy/tests/test_check36_drift_classes.sh`, `release/references/how-to/memory-corpus-drift-audit.md`, `core/config/allowlists/script-execution-allowlist.txt`, `.github/workflows/install-tests.yml` | Engineering spoke 2 |

Raw Σ = 12 pts, inside the acceptable band for a two-member capability slice. **No merge, no split** — the members are a rule and its first instance, with a clear capability boundary.

### Capability Outcome Statement

**BEFORE:** a governed procedure could state a trigger in prose and carry no surface that acts when the trigger fires; whether it ran depended on whether the agent happened to recall it, and a skip left no record.
**AFTER:** a governed procedure that declares a trigger is admitted to the gate-coverage register, where it either names a runner whose predicate is recomputed on every `deploy.sh --check` run, or is recorded as a **named gap** carrying the observable that would close it.

---

## Change Description

### Outcome

Governed procedures in this platform state their trigger in prose — *"whenever you identify a gap"*, *"the method applies per proposed milestone"* — and, until now, nothing acted at the moment the trigger fired. Whether a procedure ran depended on whether the agent happened to recall it, and a skip left no trace. Three such procedures were each skipped in a single session; none produced any signal.

This release makes a declared trigger **detectable**. A governed procedure that names a condition and an act is now admitted to the platform's existing gate-coverage register, where it either names a runner whose check set is re-resolved on every `deploy.sh --check` run, or is recorded as a **named gap** carrying the observable that would close it. An unenforced obligation is still unenforced — but it is now *counted* rather than invisible, and a runner that quietly stops carrying its half of a procedure turns the check red instead of going unnoticed.

The change is deliberately small. The platform already owned this machine for verdict-shaped rules; what it lacked was an admission test that could see obligation-shaped ones. One alternative first limb was added to that test. **No code changed.**

### Issues resolved

| Issue | What landed |
|---|---|
| **#5825** | The `L1′` obligation limb, its disposition pair, its five-item non-coverage statement, three seed register rows, the two evidence passages' `**Runner:**` labels, and the authoring-time checklist trigger. Marked as closed at Stage 13. |
| **#5826** | Not yet built — its slice lands on this same branch and PR in the next Engineering spoke. Marked as closed at Stage 13 alongside its sibling. |
| **Major-1** (operator disposition D-4) | `release-hub` Mode R group 6 gains composition-doctrine Steps 3 and 4. Not a separate ticket — an in-release fix locked into this slice at Collective Review. |

### Key decisions

- **A second admission FORM, not a fourth gate class** (ADR-162). The "three gate classes" count is held at three by construction, so nothing cascades. The falsifiable evidence that this was the right home is that the check required no code change to admit the new form.
- **An unenforceable obligation is registered, never downgraded.** Deleting an unrunnable verdict is a correction; deleting a correct instruction is a regression. That asymmetry is the whole reason class 3-O's second disposition differs from class 3-V's.
- **A tool-call-time hook was eliminated on a falsified premise, not on cost.** The sanctioned path and the bypassing path issue byte-identical tool calls. Recorded so the question stops being re-opened.
- **The mechanism's own limits ship with it.** Five of them, stated in the standard rather than left implied — because a mechanism that hides its limits reproduces the failure class it exists to close.

### Reversibility

**CHEAP** for this slice; **MODERATE** for the release as a whole, per the operator's scope-lock record. Everything here is additive prose plus three register rows and one sub-check pair, with no code path touched. `git revert -m 1 <merge-sha>` restores the prior state exactly and returns the register's pointer count to its previous value of four.

### Downstream impact

- **Authors of governed procedures** gain an obligation: a passage that names a trigger and an act now owes a `**Runner:**` label and a register row. The obligation attaches **on the change**, not retroactively — no existing document is swept, and no new frontmatter field exists.
- **Stage 5 design review** gains the second trigger form in check 4.9, including the named-gap pass path.
- **`release-hub` Mode R** readiness runs now report on the dependency half of composition, which they previously did not. Its `.skill` package is rebuilt in this PR.
- **The next Engineering spoke** adds the `runner-def:` pointer to the third register row when it ships the detector that makes it resolvable.

### Cross-references

The decision record is `core/ADRs/ADR-162-obligation-limb-is-a-form-not-a-fourth-gate-class.md`. The mechanism lives in `core/standards/gate-efficacy-standard.md` § *Scope boundary* and § *Runner resolution — class 3*. The authoring-time surface is `release/references/templates/design-review-checklist.md` check 4.9.

---

## Dependency Graph

Directional edges (`A ──▶ B` = B depends on A).

```
#5825 ──E1 coherence / sequencing (soft)──▶ #5826
#5826 ──E2 grading (soft, REVERSE)───────▶ #5825
#5825 ◀──E3 design-boundary (cross-milestone)──▶ #5286  [milestone #347, epic #5867]
```

**Hard blocking edges: none.** Both issue bodies state it: #5825 — *"the `external-target-referent-stored` detector, filed separately — it is one concrete instance of this gap and is independently shippable."* #5826 — *"Independently shippable — this one has a pre-specified target shape, that one does not."*

| # | Edge | Direction | Type | Consequence |
|---|------|-----------|------|-------------|
| **E1** | #5825 → #5826 | forward | coherence (sequencing) | #5825 states the class rule; #5826 ships its first instance. The instance should conform to the rule, so the rule is built first. |
| **E2** | #5826 → #5825 | **reverse** | grading | #5825's AC-5 (*"ADR-109's deferred detector is either delivered by this work or explicitly excluded from it"*) is not gradable from #5825's own outputs — it needs #5826's disposition to be known. |
| **E3** | #5825 ↔ #5286 (milestone #347) | cross-milestone | design-boundary | Both are children of epic #5867. **Settled at Stage 5 (AI-001) — a composition seam, not a duplication.** #5825 owns the DECLARATION and the AT-TRIGGER fire-or-record surface; #5286 owns the AT-CLOSE MEASUREMENT of newly-declared obligations. Neither relocation nor duplicate-treatment is indicated. |

**E1 and E2 point opposite ways on the same pair.** That is not a cycle — they are different relations (build-order vs grade-order) — but it is load-bearing: **#5825 cannot be fully graded until #5826 has landed.** D-C SINGLE resolves it for free (one branch, both issues present at grading time).

**The falsifying test for "#5825 and #5286 are the same machine."** A close-time population count structurally cannot observe a runtime skip: #5286's criterion measures corpus state at a release boundary; #5825's AC-2 concerns agent conduct at the moment of an act. #5286 cannot deliver #5825's AC-2, and #5825 cannot deliver #5286's per-release population number. **Two machines.**

---

## Implementation Sequence

Single branch, serial:

| Order | Issue | Why here |
|-------|-------|----------|
| 1 | **#5825** | Foundation. States the class rule and owns the D-Mechanism decision. Carries the Major-1 fix (D-4) and the combined ADR (D-5). |
| 2 | **#5826** | The rule's first instance. Target shape pre-specified by ADR-109 § 8, so its design surface is narrow. Builds on #5825's branch after it lands. |

**Sequence is preferred, not mandatory.** #5826's shape does not depend on the details of #5825's mechanism; if #5825 stalls, #5826 proceeds independently rather than blocking.

### Commit sequence within slice 1 (#5825)

| # | Commit | Contents |
|---|--------|----------|
| **0** | Engineering Commit 0 | This plan file, alone. Lands before any implementation commit. |
| **1** | `feat(gate-efficacy)` | `core/standards/gate-efficacy-standard.md` — the `L1′` admission form, the class-3-O disposition pair, the non-coverage statement, and 3 seed register rows. `release/references/templates/design-review-checklist.md` — check 4.9's second trigger form. |
| **2** | `feat(declarations)` | `core/CLAUDE.md.template` + `release/references/standards/bundle-composition-doctrine.md` — the two `**Runner:**` labels for Instances 1 and 2. |
| **3** | `fix(release-hub)` | `release/skills/release-hub/references/milestone-readiness-checklist.md` — Mode R group 6 gains doctrine Steps 3 + 4 (D-4 / Major-1), plus the `release-hub` `.skill` package rebuild + `.sha256` sidecar. |
| **4** | `docs(adr)` | The combined ADR (D-5), number allocated live against the mainline anchor at commit time. |
| **5** | `docs(plan)` | The plan's `## Change Description` section, per Stage-6 Phase C1. |

---

## Stage Applicability Matrix

**Verdict: all stages apply to both issues. Zero skips.** Stages 10 and 11 are skip-closed by the git-native path (branch protection + PR review are the environment-promotion and approval surfaces).

| Stage | #5825 | #5826 | Basis |
|-------|-------|-------|-------|
| 5 Solutioning | APPLY | APPLY | The `SKIP-where-trivial` bias does not fire — its precondition ("no design uncertainty surfaced") is false for both; each body defers its mechanism to Stage 5 by name. Superseded anyway by the `novel` re-classification, whose bias is ALL. |
| 6 Engineering | APPLY | APPLY | Both produce shipped surfaces. |
| 7 Dev Testing | APPLY | APPLY | Both have functional impact — a mechanism that must fire, and a detector that must discriminate FLAG from CLEAN. |
| 8 QA / Acceptance | APPLY | APPLY | Both carry gradable per-criterion ACs (5 and 6 respectively). |
| 9 Plan Review | APPLY | APPLY | Release-scoped; depth **Deep** per the `novel` class. |
| 10 Environment promotion | skip-closed | skip-closed | Git-native: the release branch IS the environment, and branch protection is the promotion gate. No separate environment exists to promote into. |
| 11 Approval | skip-closed | skip-closed | Git-native: PR review at Stage 9 IS the approval. No separate approval surface exists. |
| 12 Execute | APPLY | APPLY | Merge + Deployment Log. **No version claim** — version-less. |
| 13 Close | APPLY | APPLY | Standard close path; both members are marked as closed at Stage 13 on the single merge. |

---

## Contention Map

**In-bundle file contention: exactly one file.**

| File | #5825 | #5826 | Contention |
|------|-------|-------|------------|
| `core/disciplines/knowledge-architecture.md` | **cites, does not edit** — Instance 3's register row points at the drift-class home | edits § 7 (class table, count five → six, sixth class row) | **RESOLVED — zero shared write paths.** #5826 is the sole writer. |
| `core/standards/gate-efficacy-standard.md` | sole writer | — | none |
| `core/deploy/deploy.sh` | **NO CHANGE** — Check 62 needs no code change | Check 36 block, in place | none (single writer) |
| `release/skills/release-hub/references/milestone-readiness-checklist.md` | sole writer (D-4) | — | none |
| `core/ADRs/ADR-109-external-target-knowledge-scope.md` | cites | cites | **none — read-only for both.** An immutable decision record; its § 8 forward-reference resolves without an edit. |
| `core/config/operator.toml.template` | — | read-only reference (arm 2's whitelist subject) | none |

**Cross-release contention on `core/deploy/deploy.sh` — downgraded, with evidence.** The live renumber churn on that file is **tail-allocation** contention (two releases racing for the next free check number; Checks 70/71/72 sit at lines 12518 / 12627 / 12757). #5826 edits Check 36 **in place at line 9459** and **claims no new check number**, so it is structurally immune to the numbering collision, with ~3,000 lines of hunk separation. **Revised severity: numbering NONE, textual LOW.**

---

## Cross-PR Overlap Audit

### Baseline SHA

`e19a9d30682abefac51cca1ff8aa0ebbf8708593` — `origin/main` at Stage-4 audit start, re-verified at Engineering Commit 0 (`git fetch origin main`; `HEAD == origin/main == FETCH_HEAD`).

### In-Flight Release Roster

**Measured at:** `d40de588` · 2026-08-28 · **Population: n=0 siblings in flight**

Recorded explicitly rather than omitted, per audit-baseline discipline — a default-to-zero over a transiently-empty population is not load-bearing without its pinned baseline. Derivation:

- Open PRs with a `release/*` head: **0**. Instrument control: `gh pr list --state closed --limit 3` returned 3 rows, so the zero-open reading is a real absence rather than a dead instrument.
- Remote `release/*` heads with no open PR: **1** — `release/operational-folder-enforcement-migration` @ `9dcb960f`. Tested with `git merge-base --is-ancestor`: it **is an ancestor of `origin/main`**, i.e. already merged. Excluded with its reason rather than silently dropped.
- **Net in-flight: 0.** No sibling declares a rename, relocate, or delete, because there is no sibling.

**This roster is a pinned measurement and carries no verdict.** Stage 9 Phase A6.6 re-measures fresh pre-GO and renders the `CONTENTION-*` verdict.

---

## Risk Register

| ID | Class | Sev | Risk | Owner | Mitigation | Reversibility |
|----|-------|-----|------|-------|------------|---------------|
| **R1** | Blast radius | **HIGH → CLOSED** | The five → six drift-class move asserts the literal "five" at 11 sites across 5 files; #5826's Affected Files named 2 of the 5. One unnamed surface (`memory-corpus-drift-audit.md:133`) states that the manual audit and Check 36 *"agree by construction"* — a partial update silently falsifies that invariant. | Stage 5 → Eng 2 | **Closed at Stage 4:** the File Change Matrix below carries all five files. Stage 7 runs `test_check36_drift_classes.sh` as a gating check, not an optional one. | CHEAP |
| **R2** | Scope | **HIGH → CLOSED** | #5825's scope was unbounded until the mechanism was decided; its 8-pt estimate sized the decision, not the sweep the decision might authorize. | Stage 5 | **Closed at Stage 5 (AI-002): the sweep collapses to zero.** Class 3's obligation already attaches *"on the change, not on the corpus: no scan and no allowlist"*, and the register is *"never required to be exhaustive in one pass."* No `trigger:` field is added to any document; no existing passage is rewritten except the two that are themselves the evidence instances. | CHEAP |
| **R3** | Cross-milestone | **MED-HIGH → CLOSED** | #5825's conformance half and #5286's Gate-13 criterion are plausibly the same machine, specified in two milestones reaching Stage 5 independently. | Stage 5 entry | **Closed at Stage 5 (AI-001):** a composition seam, not a duplication. Ownership split stated in § Dependency Graph E3. Coordination note only — no edit to #5286 from this release. | CHEAP |
| **R4** | Coherence | **MED** | The shipped detector may not satisfy the rule its sibling states. Check 36 is warn-mode and SKIPs entirely when `~/.claude/memory` is absent (fresh install / CI) — exactly where the observed violation lived. | Stage 9 QC3.5 | Graded by **CIAC-1** and **CIAC-2**. #5825 deliberately defines "detectable signal" as *a named, resolvable runner whose verdict is observable and whose resolution is recomputed* — a definition Check 36 satisfies — precisely so #5826 stays conformant rather than being defined out. | CHEAP |
| **R5** | Contention | **LOW** | `core/deploy/deploy.sh` cross-release textual contention. | Stage 6 | ~3,000 lines of hunk separation; no new check number claimed; in-flight sibling population n=0 at `d40de588`. Re-check at Stage 9 Phase A6.6 — the roster is a pinned prior, not a durable verdict. | CHEAP |
| **R6** | Anchor | **LOW** | `{#drift-classes}` at `knowledge-architecture.md:313` is an **explicitly declared** anchor. Converting it to auto-derived while retitling "five" → "six" breaks the inbound reference at `:358`. | Eng 2 | Preserve the explicit `{#drift-classes}` anchor **verbatim**. Covered by CIAC-3's anchor-resolution arm. | CHEAP |
| **R7** | Teeth | **MED** | The mechanism inherits deploy-time-only, warn-mode teeth. Check 62 declares `advisory / deploy-time-only`; Requirement (b′) bars `required` while no CI mirror exists; `deploy-check-ci.yml`'s required subset is one member (Check 38). AC-2's "detectable signal" is real but not pre-merge. | operator | **Accepted as a stated residual.** Pre-existing debt this release inherits and does not worsen. Stated in the standard's own non-coverage clause rather than hidden. Do not attempt a CI mirror here — that belongs to `deploy-check-ci.yml`'s own back-fill effort. | n/a |
| **R8** | Anchor grammar | **MED** | Check 62's `runner-def:` anchor is captured by the character class `[A-Za-z0-9._-]`, which **stops at the first space**. A space-bearing anchor silently truncates to its first word and asserts a weaker predicate than the author wrote — a CLEAN verdict over an assertion nobody made. The standard states no anchor-form rule. | Eng 1 | **Mitigated in this release by authoring space-free anchors only**, each currently absent from its runner-definition file so its presence is a real assertion. **The standard is NOT edited for it** — stating an anchor-form rule is scope beyond the lock; routed as a follow-on (§ Findings F-1). | CHEAP |

### Rollback strategy

Single release branch, single PR, single merge (D-C SINGLE) → `git revert -m 1 <merge-sha>` restores prior state wholesale.

| Surface | Rollback | Tier |
|---------|----------|------|
| `gate-efficacy-standard.md` admission form + 3 register rows | `git revert` — additive limb; Check 62's pointer count returns to its prior value (4) | **CHEAP** |
| `design-review-checklist.md` check 4.9 | `git revert` — trigger-form extension only; Section 4's conjunction arity unchanged | **CHEAP** |
| Two `**Runner:**` passage labels (`CLAUDE.md.template`, `bundle-composition-doctrine.md`) | `git revert` — additive labels; no obligation text reworded | **CHEAP** |
| Mode R group 6 Steps 3 + 4 (D-4) | `git revert` — one table cell plus one line, plus the package rebuild | **CHEAP** |
| The combined ADR | `git revert` — a new file | **CHEAP** |
| #5826's Check 36 sixth class + class-table edits | `git revert` restores the five-class table; nothing downstream depends on the sixth | **CHEAP** |
| **Aggregate** | | **MODERATE** — the release inherits the stricter of the two, and the operator recorded MODERATE / HIGH at the D-3 scope lock. **#5825's own tier improved MODERATE → CHEAP** once the sweep collapsed (§ Deviation Log Δ1). |

---

## Cross-Issue Acceptance Criteria

Three. All span both members, all gradable on the merged PR at Stage 9 QC3.5.

**Cross-Issue Acceptance Criteria**
- [ ] **CIAC-1 (#5825 × #5826 on the non-coverage declarations):** Both issues ship an explicit non-coverage statement, both name the auto-memory store (`~/.claude/memory`), and the two give a **consistent** answer on whether that surface is reached — consistent meaning each statement names the mechanism it is about, so that "#5825's register-and-Check-62 mechanism does not reach the store" and "#5826's Check 36 reads the store at deploy time on an operator machine and cannot in CI, where it does not exist" are read as the two non-overlapping facts they are, rather than as a contradiction. *Method:* `git diff origin/main...HEAD -- '*.md' '*.sh' | grep -n 'claude/memory'` · control: the same instrument against the same target for `runner-def` → non-zero, so a zero on the subject is a real absence and not an unresolvable diff range. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-2 (#5825 × #5826 on the firing-surface mechanism):** The ADR-109 detector shipped by #5826 is **either** registered with the firing-surface mechanism #5825 establishes, **or** recorded by that mechanism as explicitly out of its declared population with a stated reason. **Affirmative branch taken:** #5825 ships the class-3-O register row for the `external-target-referent-stored` drift class, naming `deploy.sh --check` Check 36 as its enforcing gate. *Method:* read the gate-coverage register in `core/standards/gate-efficacy-standard.md` for the `external-target-referent-stored` row and confirm it names Check 36 and describes a posture the merged PR delivers. *Graded at Stage 9 QC3.5 on the merged PR.*
- [ ] **CIAC-3 (#5825 × #5826 on ADR-109 § 8's forward reference):** #5825's shipped disposition of its own AC-5 — "delivered by this work" or "explicitly excluded from it" — is consistent with #5826's merged state in the same PR, and the `{#drift-classes}` anchor still resolves from every inbound reference after the heading retitle. **#5825's disposition: explicitly excluded from #5825 and registered by it; delivered by #5826 in the same PR.** *Method:* `python3 -c "import re; t=open('core/disciplines/knowledge-architecture.md').read(); print('anchor:', bool(re.search(r'\{#drift-classes\}', t)), 'six:', len(re.findall(r'six drift classes', t)), 'five:', len(re.findall(r'five drift classes', t)))"` — expect `anchor: True`, `six > 0`, `five == 0` in the class-table context. **Null arm carries its control:** the `five == 0` expectation is paired with the same instrument against the same target returning **non-zero for `six`** — a zero on both means the file was not read, not that the transition landed. *Graded at Stage 9 QC3.5 on the merged PR.*

---

## File Change Matrix

Machine-readable path list — one path per line, `<VERB>  <path>`. Intent tokens: `add` (new file) · `edit` (modify).

```
# ── slice 1 — #5825 (+ Major-1 D-4, + combined ADR D-5) ──
add   release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md
edit  core/standards/gate-efficacy-standard.md
edit  release/references/templates/design-review-checklist.md
edit  core/CLAUDE.md.template
edit  release/references/standards/bundle-composition-doctrine.md
edit  release/skills/release-hub/references/milestone-readiness-checklist.md
edit  packages/release-hub.skill
edit  packages/release-hub.skill.sha256
# ── slice 2 — #5826 ──
edit  core/deploy/deploy.sh
edit  core/disciplines/knowledge-architecture.md
edit  core/disciplines/memory-architecture.md
edit  core/deploy/tests/test_check36_drift_classes.sh
edit  release/references/how-to/memory-corpus-drift-audit.md
edit  core/config/allowlists/script-execution-allowlist.txt
edit  .github/workflows/install-tests.yml
```

**The ADR row is deliberately outside the fenced block above and is declared here instead, with its path resolved at commit time.** ADR numbering is a global sequence spanning `core/ADRs/` and `release/ADRs/`, allocated against the mainline anchor at commit time and never reserved ahead of a sibling's unmerged claim — so a literal path authored at Commit 0 would be a pre-reservation, which the numbering discipline forbids. The delivered path is recorded in § Deviation Log Δ6 once allocated.

| Path | Intent | Issue | Note |
|------|--------|-------|------|
| `release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md` | add | release | **Flat in `plans/`** — version-less releases are not version-keyed, so there is no `v<MAJOR>/` home and no Stage-12 `git mv`. Workspace-rooted links only. |
| `core/standards/gate-efficacy-standard.md` | edit | #5825 | § *Scope boundary*: "three gate classes" preserved **verbatim**; the class-3 admission paragraph gains the `L1′` obligation limb, the stated-trigger admission bar, and the precedence rule. § *Runner resolution — class 3*: the class-3-O disposition pair (**wire it** / **register as a named gap with a declared observable**) plus the rationale for its divergence from 3-V, and the explicit non-coverage statement. § *Gate-coverage register*: **3 rows appended** (Instances 1–3). |
| `release/references/templates/design-review-checklist.md` | edit | #5825 | Check **4.9**: the two-limb trigger gains `L1′ ∧ L2` = class 3-O; the 3-O disposition pair is named in the check body and in the `**Fail action:**` sentence; the `**Pass criterion:**` gains the 3-O clause. **No new checklist member** — Section 4's conjunction arity is unchanged. |
| `core/CLAUDE.md.template` | edit | #5825 | § Continuous Improvement, the auto-logging rule: append the `**Runner:**` label recording that no runner is resolvable, pointing at the register row (Instance 2). **Surgical** — the rule's obligation text is not reworded, restructured, or softened. |
| `release/references/standards/bundle-composition-doctrine.md` | edit | #5825 | § 3 *The 7-Step Method*, opening paragraph: append the `**Runner:**` label naming `release-hub` Mode R group 6 (Instance 1). The `runner-def:` pointer lives in the register row alone, per the shipped convention (§ Deviation Log Δ10). **No step text is edited.** |
| `release/skills/release-hub/references/milestone-readiness-checklist.md` | edit | #5825 (D-4 / Major-1) | Mode R group 6's Sub-checks cell gains doctrine **Step 3** (backward dep walk to discover *unbundled* prerequisites) and **Step 4** (older-milestone prerequisite check), plus the one-line composition sentence naming which doctrine steps group 6 composes. **Skill-adjacent reference file** → the `pmo-skill-editor` discipline applies, and the `.skill` package rebuilds. |
| `packages/release-hub.skill` + `.sha256` | edit | #5825 | **Mandatory companion** of the row above. `release-hub` is a rostered skill; a `references/` edit without a package rebuild fails `deploy.sh --check` Check 7 and the pre-merge `skill-package-freshness` CI gate. |
| `core/deploy/deploy.sh` | edit | #5826 | Check 36 block, **in place at ~L9459**. Sixth drift class, three arms. **No new check number claimed** — this is what keeps the mainline renumber edge latent. |
| `core/disciplines/knowledge-architecture.md` | edit | #5826 | Class table five → six; retitle the `:313` heading; **preserve the `{#drift-classes}` anchor verbatim**; reconcile the `:358` *"Detector deferred / not one of the five"* paragraph. |
| `core/disciplines/memory-architecture.md` | edit | #5826 | Two stale "five drift classes" cross-refs at `:24` and `:114`. **Undeclared by #5826's own Affected Files** — carried here per R1. |
| `core/deploy/tests/test_check36_drift_classes.sh` | edit | #5826 | Sixth-class FLAG + CLEAN fixtures (sanctioned `identifier` = CLEAN; observed violation = FLAG). **Undeclared by #5826's own Affected Files** — carried here per R1. |
| `release/references/how-to/memory-corpus-drift-audit.md` | edit | #5826 | H2 at `:22` + the *"agree by construction"* invariant at `:133`. **Undeclared by #5826's own Affected Files** — carried here per R1. |
| `core/config/allowlists/script-execution-allowlist.txt` | edit | #5826 | Entry for `core/deploy/tests/test_check36_drift_classes.sh`. **Locked in at D-3** — the fixture is 0 of 281 entries today, so `BLOCK-DESTRUCTIVE-022` fires on this card's own test file and Stage 6/7 cannot run it. |
| `.github/workflows/install-tests.yml` | edit | #5826 | L484–489 carry a "two new Check 36 detectors" enumeration that goes stale on a sixth class. **Locked in at D-3 as the 6th file.** |

#### Read-only inputs (NOT EDITED — excluded from the delivery obligation set)

| Path | Why read | Issue |
|------|----------|-------|
| `core/ADRs/ADR-109-external-target-knowledge-scope.md` | READ — immutable decision record; its § 8 forward-reference resolves without an edit | both |
| `core/config/operator.toml.template` | READ — `[trackers.<id>].identifier` is the one sanctioned stored item; #5826's arm 2 must **not** flag it | #5826 |
| `core/hooks/**` | NOT EDITED — Candidate A (a `PreToolUse` hook) was eliminated on a falsified premise; see § Operator Decisions § D-Mechanism | #5825 |
| `core/deploy/deploy.sh` Check 62 / `_rr_compute_verdict()` | READ — **Check 62 needs no code change**; the computation was already general over `runner-def:` pointers. Editing it would be a scope deviation | #5825 |
| `core/standards/regression-checks.md` | READ — the `RCP-01`/`02`/`03` resolution targets of the existing class-3-V rows; untouched because no existing row changes | #5825 |

---

## Verification Plan

### AC baseline

Per-issue acceptance-criterion counts as read at plan time, with the commit the read was taken against. The ordinal in the `AC` column is positional, so this baseline is what makes ordinal drift countable rather than silent. **The baseline is a pinned measurement and carries no verdict.**

| Issue | AC count at plan time | Read at |
|-------|----------------------|---------|
| #5825 | **5** | `e19a9d30682abefac51cca1ff8aa0ebbf8708593` |
| #5826 | **6** | `e19a9d30682abefac51cca1ff8aa0ebbf8708593` |

### Per-Issue Verification

| Issue | AC | Verification Method | Expected Result |
|-------|----|--------------------|-----------------|
| #5825 | AC-1 | `grep -c 'class 3-O' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'class 3-V'` → non-zero, so a zero on the subject is a real absence rather than an unreadable file | Three register rows present, one per Evidence instance; each names its admission form, its runner-or-named-gap, and its disposition |
| #5825 | AC-2 | `grep -c 'runner-def:' core/standards/gate-efficacy-standard.md`, then re-resolve every pointer the register declares (Check 62's `_rr_compute_verdict` computation) | `CLEAN` with a pointer count of five — four pre-existing plus one new, for Instance 1. Instances 2 and 3 are named gaps and correctly carry no pointer, per Δ9 |
| #5825 | AC-3 | `grep -c 'L1′' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'L1 — verdict limb'` → non-zero, so a zero on the subject is a real absence rather than an unreadable file | `L1′` present; the register row is data and Check 62 is a computation over it; no new prose instruction to the agent is added anywhere in the diff |
| #5825 | AC-4 | `grep -c 'does NOT detect' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'Runner resolution'` → non-zero | The non-coverage enumeration is present and carries five numbered items — runtime skip, surfaces outside the repository, byte-identical tool calls, anchor-presence granularity, and advisory deploy-time-only teeth |
| #5825 | AC-5 | `grep -c 'external-target-referent-stored' core/standards/gate-efficacy-standard.md` · control arm, same instrument, same target: `grep -c 'NAMED GAP'` → non-zero | The row is present, names `deploy.sh --check` Check 36 as its intended enforcing gate, and records the disposition *explicitly excluded from this card and registered by it*; the detector itself ships in the sibling slice on this same branch |
| #5826 | AC-1 | `[DEFERRED — slice 2. Verified by the #5826 Engineering spoke and re-executed at Stage 7.]` | — |
| #5826 | AC-2 | `[DEFERRED — slice 2. Verified by the #5826 Engineering spoke and re-executed at Stage 7.]` | — |
| #5826 | AC-3 | `[DEFERRED — slice 2. Verified by the #5826 Engineering spoke and re-executed at Stage 7.]` | — |
| #5826 | AC-4 | `[DEFERRED — slice 2. Verified by the #5826 Engineering spoke and re-executed at Stage 7.]` | — |
| #5826 | AC-5 | `[DEFERRED — slice 2. Verified by the #5826 Engineering spoke and re-executed at Stage 7.]` | — |
| #5826 | AC-6 | `[DEFERRED — slice 2. Verified by the #5826 Engineering spoke and re-executed at Stage 7.]` | — |

---

## Release-Scoped Verification

Held in its own H2, deliberately. The plan verifier extracts everything under `## Verification Plan` and parses every markdown table it finds there as per-issue check rows, so a second table with different columns living inside that section is read at the per-issue column indices and emits spurious records. Promoting this table out of the section is the authoring fix; the column names below are also deliberately distinct from the per-issue table's.

| # | Release-scoped check | Invocation | Result required |
|---|----------------------|-----------|-----------------|
| **V-1** | Check 62 resolves | The `_rr_compute_verdict` computation over the edited register | `CLEAN`, pointer count 5 |
| **V-2** | ADR numbering contiguity | `python3 release/tools/check-adr-numbers.py` | Zero duplicates, zero gaps across both ADR homes |
| **V-3** | Plan conformance | `bash release/tools/verify-release-plan.sh release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md` | Every family PASS or a named SKIP. The `release-version-stamp` element is **correctly absent** — it fires only when a version-stamp token is present, and a version-less plan emits none |
| **V-4** | Doc-link integrity | `deploy.sh --check` Check 14 over the modified `.md` files | Every internal markdown link in a modified file resolves |
| **V-5** | Skill-package freshness | `deploy.sh --check` Check 7 after the `release-hub` rebuild | `FRESH` — package content-hash matches source |
| **V-6** | Register-row anchor liveness | For each new `runner-def: <path>::<anchor>`, assert the anchor is **absent** from the runner-definition file at `origin/main` and **present** after the edit | Absent-before / present-after for both new anchors, with a sensitivity arm (a token present in both) and a specificity arm (a token present in neither) |

**Anti-vacuity note on V-6.** A pointer whose anchor was already present before the change asserts nothing the release delivered; the absent-before arm is what distinguishes a real assertion from a pointer aimed at pre-existing text.

---

## Delivery Strategy

- **One branch, one PR, one merge** (D-C SINGLE). #5826's slice lands on this same branch and PR in the next Engineering spoke.
- **P0 fully-serial.** No force-push on the shared branch under multi-chip activity.
- **Sub-task container: PR-body checklist.** Slice 1 decomposes into 5 file-level units plus the 3 always-generated special sub-tasks (sync / plan-update / verification) — the threshold predicate selects the checklist container for the doc-and-governance-only, single-logical-unit shape, and the checklist rows are the decomposition record.
- **Commit messages reference their source issue.** Close-family verbs bound to an issue number appear only in the PR body's dedicated Issue References block — never in a commit message, a plan section, or a PR narrative section.

---

## Quota Budget

**Verdict:** **PASS** (per `quota-budget-protocol.md` Checkpoint A)
**Parallel-eligible spokes per parallel stage (from the Stage Applicability Matrix):** Stage 5: **2** · Stage 7: **2** · Stage 8: **2**
**Per-spoke cost estimate:** ordinal size-bucket band (no telemetry medians available; the cutover conditions — n≥3, rMAD≤0.50, confidence≥MEDIUM — are met for neither bucket). #5825 `size:L` → **moderate–high**; #5826 `size:M` → **low–moderate**. Source: `quota-budget-protocol.md` § 5 heuristic.
**Assumed/stated remaining usage-window envelope:** not operator-stated at hub start → **conservative default assumed**.
**Estimated cumulative draw % (worst parallel batch):** worst batch = **2 spokes** (1×L + 1×M), the smallest non-trivial parallel batch the pipeline can produce. Estimated cumulative draw **well under 50 %** of a conservative envelope → **PASS band**.
**Routing:** **PASS — proceed parallel; no warning required in plan.**
**Confidence:** `[CALIBRATE-AFTER-3]` **MEDIUM** — bands and cumulative-draw budget are provisional.
**Note:** Checkpoint B re-validates at every `Agent`-tool launch — wave or singleton, every stage (runtime, load-bearing) — with PROCEED/SERIALIZE/DEFER/REDUCE-scope for a wave and PROCEED/DEFER for a singleton; STAGGER is a secondary rate-limit-only defense, not a usage-window mitigation. Checkpoint B also gates on a **second axis** the fields above deliberately do not carry — the host-API quota (`core`/`graphql` pools), read at runtime and combined DEFER-dominant. Checkpoint A stays usage-window-only: a plan-time pool reading has no predictive value at Engineering time.

---

## Operator Decisions (recorded)

### D-Version — RECORDED DETERMINATION (rule-determined; not an operator gate)

- **Determination:** **version-less / theme-named** — the milestone title is slug-only, so no version key is claimed. Bump-class / next-free: **N/A**. **No tag at Stage 12.**
- **Consequence:** the Commit-0 version re-verify and the Stage-12 atomic claim are **INAPPLICABLE**. This plan emits **no `{{RELEASE_VERSION}}` token** and `release/tools/claim-version.sh --verify-stamp` is **not run** — there is no version slot to contend for and no stamp manifest to assert. The plan file therefore stays **flat in `plans/`** and is never `git mv`'d into a `v<MAJOR>/` subdirectory.
- **Reversibility / Confidence:** CHEAP / HIGH.

### D-ReleaseClass — SETTLED: `novel` (re-classified from `routine`)

- **Value:** **`novel`**, re-classified at Stage 4 Plan Review (2026-08-28). Both the prior and current values are recorded because the change is load-bearing on Stage 9 depth.
- **Why `routine` was wrong, tested literally against the class enum:** (a) *all issues P3/P4 and size:S/M* — **NO**, #5825 is P2 and `size:L`; (b) *all change-spec files have ≥3 prior release touches* — **NO**, not assertible while the mechanism was undecided; (c) *zero new files added* — **NO**, the candidate directions included a new hook and a new check; (d) *zero new D-class decisions in the release plan* — **NO**, both bodies defer a mechanism decision to Stage 5 by name. **`routine` fires nothing.**
- **Why `novel`:** trigger (b) fires — ≥1 D-class decision in the release plan (D-Mechanism for #5825; D-DetectorScope for #5826) — and (c) very likely, a Stage-5 ADR. `cross-cutting` does not fire: no `pipeline/stage-*.md` files; fewer than 3 of the 6 rule-defining surfaces; and a 2-node bundle admits at most 1 in-bundle compositional edge against a ≥3 requirement. Multi-trigger resolution (`cross-cutting` > `novel` > `routine`) lands on **`novel`**.
- **Differentiation posture:** engagement density **Standard** (from Light) · Stage 9 review depth **Deep** (from Standard) · Stage 5 activation bias **ALL** (from SKIP-where-trivial) · Stage 13 outcome-window 30-day (unchanged).
- **Reversibility / Confidence:** CHEAP / HIGH — cheaper-to-stricter adds ceremony, invalidates no downstream artifact.

### D-C Branch Topology — **SINGLE**

One release branch, one PR, one merge. Chosen independently, and independently justified by edge **E2**: under a split-PR topology, #5825's AC-5 could not be graded until #5826's PR merged.

### D-Concurrency Posture — **P0 fully-serial**

### D-Mechanism (#5825) — **Extend the class-3 admission test with an obligation limb**

Five candidates were generated across all three altitude bands and narrowed on hard constraints first.

| Candidate | Altitude | Disposition |
|-----------|----------|-------------|
| **A** — a `PreToolUse` hook keyed to the tool calls that mark a governed task class | point-fix | **ELIMINATED on a falsified premise, not on cost.** Compliance is not a payload property: `intake-desk` Mode C's *sanctioned* `gh issue create` and a bypassing agent's `gh issue create` are **byte-identical tool calls**, and hooks read no session / subagent / skill / mode field. Two of the three evidence rows have no distinguishing tool-call signature at all — composing an oversized milestone leaves a `gh issue edit` on a milestone description indistinguishable from any other milestone edit. It also re-opens two settled dispositions (ADR-053 Alternative D; ADR-112) on the same infeasibility. |
| **B** — a net-new `trigger:` frontmatter field plus a net-new deploy check | new-abstraction | **ELIMINATED on extend-before-create plus blast radius.** Two covering surfaces exist; a third parallel declaration registry is a shadow SSOT of *"what the platform declares, and what enforces it."* It also manufactures the unbounded corpus sweep at MODERATE reversibility, where an on-change posture achieves the same outcome at CHEAP. |
| **C** — extend the class-3 **admission test** with an obligation limb; route into the same register and Check 62 | extend-seam | **CHOSEN.** |
| **D** — corpus-wide honesty pass labelling unrunnable obligation rules advisory | point-fix | **Dominated as a sole answer; adopted as a sub-limb.** It is already class 3's existing exit disposition, and C routes obligation-shaped rules to a disposition of which honest-labelling is one. |
| **E** — extend the decision-time-adherence index with an action-shaped checkpoint row | extend-seam (different seam) | **Dominated as a sole answer; its one load-bearing part reused.** As the mechanism it is prose whose enforcement is *"the agent honoring the index plus a reviewer inspecting the emitted token"* — the failure class the card forbids. Its **emitted-observable** pattern is reused rather than a second trailer family being invented. |

**Extend-before-create determination:** *extend `core/standards/gate-efficacy-standard.md`'s class-3 admission test, its gate-coverage register, and `deploy.sh --check` Check 62*, because (i) the register and Check 62 already compute exactly this obligation — a named runner that still carries its predicate, recomputed rather than vouched for; (ii) the extension requires **zero code change**; (iii) the authoring-time surface (checklist 4.9) and the Stage-7 backstop already exist and need only the second trigger form; (iv) a net-new surface would be a second registry of the same concept. **Chosen altitude: `extend-seam`.**

**Nearest-seam search, cited:** `gate-efficacy-standard.md` class 3 (**fits — chosen**); `core/rules/decision-time-adherence.md` § 2 index (does not fit — § 1's predicate is claim-shaped, and widening it re-opens ADR-112's bounded-index decision); `core/standards/platform-doc-frontmatter-standard.md` + Check 50 (does not fit — scope is `core/**` only, and `bundle-composition-doctrine.md` lives outside it); `core/hooks/` `PreToolUse` (does not fit — Candidate A); `operator.toml [adapters]` selectors (not applicable — no host binding).

**Reversibility / Confidence:** **CHEAP / HIGH** (improved from the card's recorded MODERATE / MEDIUM — see § Deviation Log Δ1).

### D-3 — Scope lock: **LOCK AS DESIGNED** (Collective Review, 2026-08-29)

**Reversibility: MODERATE / confidence HIGH.** The bundle is **hard scope-locked**; a post-lock change requires a governed override. The locked change set is the File Change Matrix above, including the two elements the scope lock expanded into it: #5826's `operator.toml [trackers.*]` schema arm (closing ADR-109's own recorded Alternative C), the `script-execution-allowlist.txt` entry (a Stage-6/7 blocker — the fixture is 0 of 281 entries), and `install-tests.yml` as the 6th file.

### D-4 — Major-1: **FIX IN-RELEASE**

**Reversibility: CHEAP / confidence HIGH.** `release-hub` Mode R group 6 carries `bundle-composition-doctrine` Steps **1** (Outcome Statement) and **5** (size band) — and **not** Steps **3** (backward dep walk) or **4** (older-milestone prerequisites). Group 2 validates the dependency graph (`2a` validity / `2b` acyclic + ordered / `2c` cross-milestone leaks); it never checks whether the composition *performed* the walk. Hub-verified independently.

That is precisely the half the motivating defect skipped, and **this milestone is a live instance**: its own Parallelization-Map reconfirm query is a broken probe (2 of 2 false positives, hub finding at Stage 4), so #368 carries no valid record that a backward dep walk was performed.

**Disposition:** add Steps 3 + 4 to Mode R group 6 — one table cell plus one line in `milestone-readiness-checklist.md`. Group 6's owning spec is `bundle-composition-doctrine`; this **widens what the group composes**, and adds no new check logic to the hub (ADR-019 compose-not-absorb).

### D-5 — ADR: **ONE COMBINED ADR**

**Reversibility: MODERATE / confidence MEDIUM.** The number is **not reserved in this document.** ADR numbering is a global monotonic sequence spanning both `core/ADRs/` and `release/ADRs/`; the number is allocated live at commit time against the mainline anchor via `release/tools/renumber-adr.py --next-free`, never ahead of a sibling's unmerged claim (a gap blocks the repo; a duplicate is tooled).

The ADR records: the **form-not-class** shape and its cascade rationale; the **hook-infeasibility falsification**; the **#5286 composition boundary**; and #5826's **declaration-scoped predicate**.

---

## Non-coverage — what this release does NOT deliver

Stated here as well as in the standard itself, because a release that leaves its own limits implied reproduces the failure class it exists to close.

1. **No runtime-skip detector.** For a row whose runner is a named review step or a named gap, the detectable record is the **absent observable**, which a reviewer must notice. Check 62 asserts that the *named runner still carries the predicate*; it asserts nothing about whether the procedure *ran on any given occasion*.
2. **The mechanism does not reach the operator auto-memory store.** `runner-def: <path>::<anchor>` resolves against **repo** paths, and the auto-memory store sits outside the repository. This is a statement about **#5825's register-and-Check-62 mechanism** and about nothing else; #5826's Check 36 *does* read that store at deploy-check time on an operator machine and structurally cannot in CI, where the store does not exist. The two statements are non-overlapping facts, not a contradiction — see CIAC-1.
3. **No hook can distinguish compliance from bypass on a byte-identical tool call.** A property of the payload, not of any hook's implementation.
4. **Check 62's R1 is anchor-presence, not predicate-completeness.** A runner that carries **half** its predicate resolves `CLEAN`. Instance 1 was a live example of exactly this before D-4 fixed it, and the general limitation remains.
5. **The mechanism is advisory and deploy-time-only.** Check 62 declares `advisory / deploy-time-only; warn-mode initial`, and Requirement (b′) bars `required` while no CI mirror exists. **This release makes governed obligations detectable, not enforced** — the mechanism's own runner is advisory and its first instance is warn-mode. That is coherent and deliberate, and it is recorded here so Stage 9 reviews it as a stated property rather than discovering it.

---

## Findings routed forward (not fixed in this release)

| # | Finding | Severity | Routing |
|---|---------|----------|---------|
| **F-1** | **The gate-efficacy standard states no lexical form for a `runner-def:` anchor, and a space-bearing anchor silently truncates.** Check 62 captures the anchor with `[A-Za-z0-9._-]`, which stops at the first space, so `::Bundle coherence` is asserted as `::Bundle` — a weaker predicate than the author wrote, resolving CLEAN. Demonstrated against the shipped regex during this release. | **Major** | Follow-on card. Mitigated here by authoring space-free anchors only; **the standard is not edited for it**, which is scope beyond the D-3 lock. |
| **F-2** | **A shipped skill file states a false claim about hook behaviour.** `operations/skills/intake-desk/SKILL.md:228` says `gh issue create` is *"not payload-detectable — the hook never sees it."* `core/hooks/block-gh-path-leak.sh:176` gates on `TOOL_NAME = "Bash"` and `:192` acts on gh issue/PR writes, so the hook demonstrably does see it. The **operative** claim (not a `block-autonomy-ceiling.sh` Tier-0 class) is true; the **stated** claim is not, and the phrasing is mirrored at `references/output-contract.md:119` and repeated at SKILL.md `:474` and `:728`. Opened by the hub as **AI-004**. | **Major** | Filed as a `bug`, carrying the corrected framing: *the non-detectability is semantic (compliant and bypassing calls are byte-identical), not lexical.* Not fixed inline — a skill-file edit outside this card's declared scope, requiring the `pmo-skill-editor` discipline plus a package rebuild. The corrected framing already ships in this release's non-coverage statement, so the release is accurate even before the skill file is amended. |
| **F-3** | **A latent mis-cascade target.** `core/standards/gate-efficacy-standard.md:242` reads *"those three class-3 rows"* — scoped correctly to the `RCP-01`/`02`/`03` rows that name `pmo-skill-editor` Mode C, and therefore still true after 3 new rows land. A later author who re-reads it as a class-3 **total** will mis-cascade it. | **Minor** | **Accepted residual.** Engineering must not touch it; Stage 7 DT confirms it still reads scoped. |
| **F-4** | **The failure-mode anti-pattern entry for this signature.** `root-cause-analysis.md` § 3 step 6 routes an N≥2 recurring root cause to a `failure-mode-standard.md` 5-field entry, and N=3 here. Recommended home, from precedent rather than invention: a third `<class>-class workflow` subsection of `## Examples` (the file already hosts two non-skill-scoped workflow-class subsections at `:274` and `:720`), category tag **`TRIG`** — the failure is at the trigger surface, a declared trigger that fires nothing. | **Minor** | Follow-on card. Genuinely separable, and it needs the shipped mechanism to name in its Mitigation field. |
| **F-6** | **`verify-release-plan.sh` silently DROPS any Verification-Plan table row whose cells use the vocabulary of the schema's own column names.** The parser's header detector runs over every table row, not only the first, and sets `is_header` when any cell contains the substring `predicate`, `expected`, or `verification method` (or lowercases to exactly `issue` / `ac` / `method`). A data row matching any of those is consumed as a header and `next`ed — no record, no `parity-error`, no ERROR verdict. This is the **silent-drop class the tool's own design notes say was rejected in another candidate**, and it is a false-clean vector: a plan can lose acceptance-criterion rows and still read all-PASS. Two rows of this very plan were lost to it before it was found, both because their cells said *"predicate"* — a word an author writing about gate predicates uses constantly. | **Major** | Follow-on card. Mitigated here by authoring around it (no in-table cell uses the trigger vocabulary) and by promoting the release-scoped table out of the parsed section. **The tool is not edited** — it is outside the D-3 lock. Reproduced with a controlled 9-arm probe: 4 sensitivity arms dropped (`predicate` in the result cell, `expected`, `verification method`, `predicate` in the method cell), 5 specificity arms kept (two plain-ASCII controls, an exact-`issue` near-miss, a hyphenated `pred-icate` near-miss, and a nonsense token). |
| **F-5** | **Check 62 and Check 50 have no CI mirror.** `deploy-check-ci.yml`'s required subset resolves to exactly one member (Check 38). Pre-existing, declared honestly by Requirement (b′). | **Minor** | Belongs to `deploy-check-ci.yml`'s own back-fill effort, whose header states the subset *"grows as posture:required checks lacking a mirror are back-filled."* Not this release's scope. |

---

## Deviation Log

Deltas between the Stage-4 plan of record and the ratified Stage-5 + Collective Review scope-lock position. All are refinements, reductions, or corrections; none re-opens the bundle.

| # | Stage-4 record | Ratified delta | Basis |
|---|----------------|----------------|-------|
| **Δ1** | #5825 reversibility **MODERATE / MEDIUM**, justified as *"every governed procedure edited to carry a trigger declaration is a corpus-wide change that is tedious to walk back."* | **CHEAP / HIGH.** The premise no longer holds: the mechanism inherits class 3's on-change posture (*"the check is on the change, not on the corpus: no scan and no allowlist"*), so **the sweep collapses to zero retroactive edits**. `git revert -m 1` restores the prior state exactly and Check 62's pointer count returns to 4. This is a rollback-complexity reduction, which was R2's stated purpose. The **aggregate** release tier stays MODERATE per the operator's D-3 record. | Stage 5 AI-002; operator D-3 |
| **Δ2** | Hub assertion at Stage 4: *editing Check 36 without updating `test_check36_drift_classes.sh` fails the suite* — the drift guard was treated as a forcing function. | **FALSIFIED.** The guard is a **presence-only** assertion over six Class-4/5 fragments, all of which an **additive** sixth class preserves. Tested by the Stage-5 spoke (baseline PASS / additive PASS / control-break FAIL) and re-read by the hub. The finding survives inverted: the fixture guard is a **missing forcing function**, and #5826's spec ships one. | Stage 5 spoke test + hub re-read |
| **Δ3** | Hub assertion at Stage 4: the `{#drift-classes}` anchor has **three** live inbound references. | **FALSIFIED — it has ONE** (`knowledge-architecture.md:358`). `memory-architecture.md:24` and `:114` link `#memory-corpus-boundary`, carrying the class count as prose only. R6's mitigation is unchanged; only the count was wrong. | Stage 5 spoke measurement + hub re-read |
| **Δ4** | Change set = 4 file edits + 1 ADR (the Stage-5 in-release footprint), with `milestone-readiness-checklist.md` **conditional** on the Major-1 disposition. | **The conditional row is PROMOTED to unconditional in this commit**, its condition having resolved at D-4 (FIX IN-RELEASE). The change set grows to include it, plus its mandatory `release-hub` `.skill` package rebuild, plus #5826's 6th file (`install-tests.yml`) and the allowlist entry. | Operator D-3 + D-4 |
| **Δ5** | #5826's declared Affected Files named 2 of the 5 files asserting the literal "five". | **All five carried** in the File Change Matrix (adding `memory-architecture.md`, `test_check36_drift_classes.sh`, `memory-corpus-drift-audit.md`). Routed as a body refinement, not a scope change — the work was always implied by ADR-109 § 8's *"the class joins that table"*, it was simply not enumerated. | Stage 4 R1 |
| **Δ6** | The Stage-5 File Change Matrix declared the ADR at a placeholder path (`core/ADRs/ADR-<next>-….md`). | **The ADR path is declared outside the machine-readable fenced block**, because a literal path authored at Commit 0 would pre-reserve a number the allocation discipline forbids reserving ahead of a sibling's unmerged claim. The number was allocated live at the ADR commit via `release/tools/renumber-adr.py --next-free`, which returned **162** both at authoring time and again after a fresh `git fetch origin main` immediately before that commit. **Delivered as `core/ADRs/ADR-162-obligation-limb-is-a-form-not-a-fourth-gate-class.md`**; `check-adr-numbers.py` reports PASS, contiguous 001..162, zero duplicates. Recorded here at the plan-update commit — this file states the number once it is a fact rather than once it is an intention. | ADR numbering discipline; § Operator Decisions D-5 |
| **Δ7** | Stage 5 proposed `runner-def: release/skills/release-hub/references/milestone-readiness-checklist.md::Bundle coherence` for Instance 1. | **Anchor changed to a space-free token.** Check 62's capture class stops at the first space, so the proposed anchor would have asserted only `Bundle`. The shipped anchors are `backward-dep-walk-performed` and, for the doctrine passage, a space-free token absent from the runner-definition file before this release — so its presence is an assertion this release actually adds. Recorded as **F-1**, and the standard is deliberately **not** edited to state the rule (scope beyond the lock). | Stage 6 mechanism probe against the shipped regex |
| **Δ8** | CIAC-1 as authored at Stage 4 asked only whether the two cards give *"a consistent answer on whether that surface is reached"*, and the two Stage-5 spokes returned literally opposite words — #5825 *"not reached"*, #5826 *"reached at deploy-check time."* The scope-lock record did not adjudicate it. | **Reconciled in the shipped text rather than left to a grader.** The two statements are about **different mechanisms** and are both true; each shipped statement now names the mechanism it is about. CIAC-1's predicate is restated above to make that the grading standard. No design changed — only the subject scoping that makes the claim gradable. | Stage 6, reading #6264 and #6265 together |
| **Δ9** | Instance 3's register row was to carry `runner-def:` naming Check 36. | **The row names Check 36 as its enforcing gate and carries NO `runner-def:` pointer at this commit.** Check 36 does not carry the sixth class until #5826 lands, so a pointer resolving CLEAN here would assert something not yet true — the false-confidence this standard exists to forbid. The row ships as a **named gap** naming its intended gate, and the pointer lands with the detector. **Coordination note for slice 2:** #5826's spoke adds the `runner-def:` pointer to that row when it ships the sixth class. | Stage 5 Instance-3 disposition (*"Pre-#5826: none — a named gap"*); Requirement (a) |
| **Δ10** | Stage 5's matrix specified that the `bundle-composition-doctrine.md` § 3 passage gains *"the `**Runner:**` label … plus the `runner-def:` pointer."* | **The passage carries the `**Runner:**` label only; the `runner-def:` pointer lives in the register row alone.** That is the shipped class-3-V convention, measured rather than assumed: across the tracked corpus every `runner-def:` pointer sits in the gate-coverage register or in Check 62's own parser and fixtures, and **not one source passage carries one** — `core/schemas/tracker-schemas.md` § Template parity, the `RCP-01` precedent, names its runner in prose and stops there. Check 62 reads only the standard, so a pointer in the passage would be inert *and* a second copy of the register's value. Following the spec literally would have created the duplicate the standard's own single-home discipline forbids. | Stage 6 corpus measurement of the shipped convention |
| **Δ11** | The Verification Plan was authored in the natural vocabulary of the subject, and the release-scoped check table sat inside the `## Verification Plan` H2. | **Both re-authored around a parser defect (F-6).** The plan verifier drops any per-issue row whose cells contain `predicate`, `expected`, or `verification method`, and parses every table inside the Verification Plan section at the per-issue column indices. Two acceptance-criterion rows were silently lost, and six spurious `PENDING` records were emitted from the release-scoped table, before the cause was isolated. Cells now avoid the trigger vocabulary and the release-scoped table is promoted to its own H2 with distinct column names. **The tool is not edited** — that is scope beyond the lock, and the finding is routed as a follow-on. | Stage 6 C4 self-verification; controlled 9-arm probe |

---

*Closure-phrasing note: every per-issue closure reference in this plan is written as "marked as closed at Stage 13" — no close-family verb is bound to an issue number anywhere in this file, so transcription into PR bodies cannot trip GitHub's close parser.*
