<!-- repo-integrity: allow-dead-file-ref -->
<!-- The marker above is declared because § Current State › Census method carries the locked census block byte for byte, and one of its self-test lines builds a registry row holding the link-syntax literal "(x)". The dead-file-reference checker scans fenced code for links, so it reads that literal as a dead link; the block cannot change, because its sha256 is the reproducibility anchor. This record carries no other link. -->
---
title: "ADR-238 — Each never-invoked role Specialist, and the router, takes exactly one disposition, decided on a re-runnable invocation census"
status: Proposed
date: 2026-11-13
release: never-invoked-specialists-dispositioned
deciders: "the operator at the Stage-9 D-Ratify gate; design by the Stage 5 Solutioning spoke; census and authoring by the Stage 6 Engineering spoke"
tags: [architecture, skills, routing, role-specialist, registry, census, disposition, lifecycle, methodology-conditional]
source_observations:
  - "Invocation census as of 2026-11-13 at census head 29c60404, until 2026-11-13T21:42:22: sessions by class {'cli': 1549, 'agent-mode': 209}; subagent files {'cli': 7329, 'agent-mode': 384}; store floor 2026-03-17; control release-hub 434; nonce arm 1 file, 0 subject events; self-test 16 PASS; mutations 0 MISSED."
  - "Never invoked as of 2026-11-13: 13 of 21 role Specialists and the router read total 0 in their windows; every verdict CLEAN; 0 probe-only subjects; agent-mode holds no in-window session."
  - "Listing finding as of 2026-11-13: 153 UTC days with listing records; described when used in the prior 14 days 28281/33346 (84.8%), when not used 36947/196773 (18.8%)."
  - "Collision baseline as of 2026-11-13: Check 67 0 ESCALATE, 0 WATCH over 1540 pairs (max J 0.188); body-level 51 rows, two of them counted own-line overlaps between a row and a used sibling."
supersedes: none
---

# ADR-238 — Each never-invoked role Specialist, and the router, takes exactly one disposition, decided on a re-runnable invocation census

## Status

Proposed.

Authored at Stage 6 Engineering for the `never-invoked-specialists-dispositioned` release. The operator renders every disposition at the Stage-9 D-Ratify gate: ratify, ratify with row amendments, or redirect. D-Ratify writes the operator's value into every row marked `[ASSUMPTION – CONFIRM]`, and edits this section and the frontmatter `status:` together. Once Accepted the record is immutable; a change takes a record that supersedes this one.

**Numbering provenance.** This record was authored at the next-free number computed from the mainline anchor at authoring. An ADR number is allocated at authorship but claimed at merge; should the mainline claim this number first, the renumbering tool moves this record at merge time and appends one provenance note here per hop. Citations of this record elsewhere use its slug token, `{{ADR:each-never-invoked-specialist-takes-one-disposition}}`.

## Context

The platform registers role Specialists — skills named for a delivery role, each composing function-skills that own the mechanics — and a router meant to map a request to the right one. A point-in-time census, recorded with the observation that opened this decision spike, found most of them never invoked, and named three contributing signals:

- **The triggers do not match how operators ask.** Specialist triggers and the registry's trigger surfaces use role vocabulary; operators ask by goal. `[INFERRED]` — the observation's own label, carried.
- **The listing hides them.** In one session's rendered skill listing, most Specialists rendered by name only, with no description, although each `SKILL.md` description runs to several hundred characters.
- **The router never runs.** It had no invocation at that census.

Nothing decides what an unused Specialist is for, so each stays deployed and unused. This record re-runs the census with a stated method, a denominator, per-subject exposure windows and both control arms, reads the listing across days, and gives every never-invoked Specialist and the router exactly one disposition. It implements none of them: each disposition other than a keep is a tagged follow-up.

Its current state, future state and gap map follow `## Related ADRs`.

## Decision

Every role Specialist that the census reads at total 0 inside its own exposure window, and the router, takes exactly one disposition: **re-trigger** (goal-shaped trigger phrases, collisions named), **re-home** (its content moves into a skill that is used), **retire** (through the registry's `lifecycle-state`, `active → deprecated → retired`, never deletion), or **keep (dormant by design, ADR-033)**. The router takes no keep. The coding scheme below decides a row where its deciding read is graded G1 or G2. Where it is not, the row is handed to the operator at D-Ratify as an `[ASSUMPTION – CONFIRM]` row carrying a recommended value, the predicate that produced it, and the alternative.

### Coding scheme

The first rule that decides wins. This is the locked scheme with the Stage-5 lock amendments applied.

| Rule | Condition → outcome |
|---|---|
| R0 | total 0 in the window → the row enters, carrying its printed verdict. The router always enters. A subject whose every in-window event sits in a session whose origin is `sdk-cli` also enters, as a `probe-only` row |
| R1 | methodology-conditional and DORMANT → `keep`, CHEAP, `follow-up: none`. Otherwise continue |
| R2 | 0 listed sessions in a class: a qualifier, not a value. The reason names the gap, and any re-trigger then depends on fixing it |
| R3 | where a persona card's role is the subject's role, the card's stage is one the subject's registry trigger surface names, and the skill holds `Modes:` the card lacks (G1 reads) → `re-trigger` through the persona seam. The card's Replacement line is a covariate. The else-branch does not decide: the row continues to R4a |
| R4a | against used sibling Specialists that are not the subject's `DEPENDS_ON` targets: ADR-019's three conjuncts. Trigger = a Check 67 band, or an exact or ≥ 3-token overlap where each phrase sits on a line stating that skill's own triggers; write and role need a stated comparator and role source, else that conjunct is G3 and the row goes to the tie. Any failure → `re-home` into that sibling; ≥ 2 failing siblings → the tie |
| R4b | against every `DEPENDS_ON` target, of any kind: compare the subject's `Modes:` with the modes of the skills it composes. The audience and sourcing clauses every Specialist template carries are not a role layer. A subject whose every mode is a composed mode → `retire`; otherwise → R5 |
| R5 | an operator decision at D-Ratify, recorded G4: a recommended value from a stated predicate, plus its alternative |
| R6 | the router: an operator decision at D-Ratify, recorded G4, with a recommended value and an alternative, resting on its verdict and its stale self-counts |
| tie | a deciding read below G2, or ≥ 2 failing siblings in R4a → `[ASSUMPTION – CONFIRM]` plus the alternative; the operator decides. A rule whose deciding read is below G2 sends the row here; it never falls through to the next rule |

**Rubric.** G1: `[SOURCE]` with a CLEAN probe or verdict. G2: `[SOURCE]` with one or more INDETERMINATE elements, each named. G3: `[INFERRED]`. G4: `[ASSUMPTION – CONFIRM]`, or an operator decision. **The bar:** an R0 zero needs G1, or G2 with its elements named, and deciding evidence needs G1 or G2. A zero whose verdict carries an `invoked_skills` residue is below the bar, and so is a zero for which every stratum of its listed classes is blind; either goes to the tie. Every remaining G2 zero carries a D-Ratify flag. An UNEXPOSED zero enters R0 under R2.

### Readings this record states

The lock requires these reads to be stated rather than left to the author.

- **R2 — what names an exposure gap.** Read here as: a class that holds at least one session inside the subject's window and lists the subject in none of them. At authoring no class meets it for any row. `cli` lists every subject in most of its in-window sessions. `agent-mode` holds no session inside any window: a run of the same block with `--until` one second before the earliest registration reads 209 `agent-mode` sessions, the same 209 the full run reads, so every `agent-mode` session predates every window. So R2 names no gap on any row, and R5's example predicate returns `re-trigger` wherever a recommendation reaches it. **The other reading** — any class with 0 listed sessions names a gap, whether or not it holds an in-window session — makes `agent-mode` and the empty classes name a gap on every row and turns every one of those recommendations to `retire`. The operator weighs the reading at D-Ratify.
- **R3 — the persona cards.** Card roles, read from the card titles: Software Engineer (Stage 6), QA Lead (Stages 7 and 8), Release Manager (Stages 4, 12 and 13), Principal Engineer (Stage 5 and its adversarial review), Portfolio Manager (Stages 2, 3 and 9). Three rows hold one of those roles: the software engineer, the QA lead and the portfolio manager. "Covers" is a string read of the registry trigger surface: the software engineer's names Stage 6 ("Executes end-to-end Stage-6 Engineering"); the QA lead's names Stage 7 ("gates dev-testing"), and not Stage 8's name, QA Testing; the portfolio manager's names none of its cards' stages. The cards carry no `Modes:` line, and both covered subjects hold one. R3 decides two rows; the portfolio manager continues to R4a.
- **R4a — the trigger input.** Own-trigger lines only (lock amendment 1): a phrase found only on a comparison-table row carrying two or more quoted cells, or in a deconfliction sentence quoting another skill, does not count. Near-miss arm: the first-line versus escalation support comparison table reads 0 counted overlaps, as required. Check 67 reads 0 ESCALATE and 0 WATCH. Two overlaps between a row and a used sibling count, both against the release manager: the project manager's "should we go live" containing "should we go", and the devops Specialist's "execute the deploy" inside "execute the deploy now the GO is in". Each fails ADR-019's trigger conjunct at G1.
- **R4a — the write comparator and the role source.** The adversarial review offered two candidates: the two emissions name the same artifact (write), and the tier phrase each registry row states (role).
  - **role** — the deciding read: a tier phrase, or one named altitude, appears in 8 of the 21 role-Specialist trigger surfaces at authoring. Of the eight used siblings, the OCM lead and the principal engineer state none, and the architect states an altitude axis rather than one tier. Neither of the first two is a `DEPENDS_ON` target of any row, so for each row that reaches R4a the role conjunct is unreadable against at least those two siblings, which is G3. For the 7 of those 10 rows at authoring whose own trigger surface states no tier, it is unreadable against every used sibling.
  - **write** — not read across the population: the two Output Contracts sampled (the project manager's and the release manager's) state audience framing and sourcing to composed modes — the template clauses the lock excludes as a role layer — and name no emission artifact; the other 19 were not read for one. The tie does not rest on this read.
  So amendment 1 sends each of the 10 rows that reach R4a at authoring to the tie. R4b and R5 decide no row.
- **The recommended value on a tie row, and its alternative.** One predicate, applied to every tie row:
  - **Recommended:** the value R4b and R5 give with R4a's G3 conjuncts set aside. R4b reads a mode map: the count of composed skills each `### Mode` section of the subject's `SKILL.md` names. A subject whose every mode names exactly one composed skill reads as composing only, so `retire`; otherwise R5's example predicate — `re-trigger` when the verdict is CLEAN and R2 names no exposure gap, else `retire`. The mode map is a name-mention count: an input to a recommendation, not a G1 read of "every mode is a composed mode".
  - **Alternative:** `re-home` into the used sibling that fails a G1-read conjunct, where one exists; otherwise the other of `re-trigger` and `retire`.
- **The bar and R0.** At authoring 0 rows carry an `invoked_skills` residue and 0 rows have every listed-class stratum blind, so the bar sends no row to the tie; every verdict is CLEAN (G1), so no row carries the G2 D-Ratify flag. Probe-only: 0 subjects — every in-window event of every invoked subject reads origin `claude-desktop`.

### Disposition table

One row per subject at total 0, plus the router. Counts are as of authoring, at the census head; neighbour counts are store-wide (see § Current State › Limitations).

| Subject · kind · module | Census · verdict | Listed and no-record sessions per class | Activation | Persona card | Disposition | Rule · reason | Tier · confidence | Collisions | Pre-count | Receiving skill · mode | Downstream work | Covariates | Follow-up |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| `pmo-release-train-engineer` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1513 name-only / 0 described; every other class 0 in window (at authoring) | `DORMANT` — rungs read: tracked default, individual config; neither names SAFe or Custom. Program and project rungs: the operator's answer at the Stage-5 lock, no SAFe configuration today | none | **keep (dormant by design, ADR-033)** | R1 — methodology-conditional and DORMANT. The keep is conditioned on the configuration: the operator recorded that no SAFe configuration exists today and that this may change. If a SAFe `delivery_approach` appears, the ADR-033 activation gate turns the Specialist on with no change to this record | CHEAP · HIGH | — (keep) | pre 15 live / 25 (9 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `delivery-engine` 12; `ppm-agent` 123; `by_origin` empty; the only subject with a methodology-conditional activation gate | `follow-up: none` |
| `pmo-software-engineer` · role-Specialist · release | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1513 name-only / 0 described; every other class 0 in window (at authoring) | — | Stage 6, Software Engineer — Implementation. Replacement line (covariate): a reference workflow, not a skill | **re-trigger** through the persona seam | R3 — the card's role is the subject's role; the registry trigger surface names the card's stage ("Executes end-to-end Stage-6 Engineering"); the skill holds a `Modes:` line (Development) the card lacks. The seam: the Stage-6 card's Replacement line becomes a skill invocation reference | CHEAP · MEDIUM (the role mapping is a title read) | Check 67 max-J pair `release-executor`, J 0.188, PASS, exact overlap none, not linked; counted body overlaps 0 | pre 12 live / 23 (10 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | the Stage-6 persona card | neighbours (store-wide): `implementation-planner` 0; `by_origin` empty; the Stage-6 session that authored this record ran as a general-purpose persona and invoked no skill; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-qa-lead` · role-Specialist · release | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1513 name-only / 0 described; every other class 0 in window (at authoring) | — | Stages 7 and 8, QA Lead — Dev Testing and Acceptance Review. Replacement lines (covariate): QA auditor modes, which this Specialist composes | **re-trigger** through the persona seam | R3 — the card's role is the subject's role; the registry trigger surface names the Stage-7 card's stage ("gates dev-testing" → Stage 7, Dev Testing); the skill holds `Modes:` (Strategy · Acceptance · Defect-Governance · Dev-Test) the card lacks. Stage 8's name is not named, so the Stage-7 card's Replacement line is the one that becomes the invocation reference | CHEAP · MEDIUM (the role mapping is a title read) | Check 67 max-J pair `pmo-qa-auditor`, J 0.182, PASS, exact overlap none, composition-linked; counted body overlaps 0 | pre 17 live / 35 (17 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | the Stage-7 persona card | neighbours (store-wide): `pmo-qa-auditor` 48; `build-reviewer` 2; `by_origin` empty; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-business-analyst` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1474 name-only / 39 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds 2 of 4 modes naming both composed skills, so not every mode is a single composed mode; R5's example predicate: the verdict is CLEAN and R2 names no exposure gap, so `re-trigger`. Alternative: `retire` (no used sibling fails a G1-read conjunct) | CHEAP · LOW | Check 67 max-J pair `ppm-agent`, J 0.087, PASS, exact overlap none, not linked; body: 5 own-line overlaps with `pmo-process-designer`, its composed skill (an R4b input, not R4a) | pre 9 live / 22 (12 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `pmo-process-designer` 4; `delivery-engine` 12; `by_origin` empty; its description changed inside its window; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-portfolio-manager` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1485 name-only / 28 described; every other class 0 in window (at authoring) | — | Stages 2, 3 and 9, Portfolio Manager. R3 does not fire: the trigger surface names none of those stages. Replacement lines (covariate): Stages 2 and 3 name a future Portfolio Manager skill | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds 3 of 4 modes naming both composed skills; R5's example predicate: the verdict is CLEAN and R2 names no exposure gap, so `re-trigger`. Alternative: `retire` | CHEAP · LOW | Check 67 max-J pair `intake-desk`, J 0.077, PASS, exact overlap none, not linked; counted body overlaps 0 | pre 15 live / 29 (13 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `ppm-agent` 123; `weekly-status-rollup` 13; `by_origin` empty; its description changed inside its window; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-program-coordinator` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1496 name-only / 17 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds 1 of 2 modes naming both composed skills; R5's example predicate: the verdict is CLEAN and R2 names no exposure gap, so `re-trigger`. Alternative: `retire` | CHEAP · LOW | Check 67 max-J pair `tracker-manager`, J 0.167, PASS, exact overlap none, composition-linked; counted body overlaps 0 | pre 13 live / 27 (13 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `tracker-manager` 3; `daily-status` 1; `by_origin` empty; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-project-manager` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1512 name-only / 1 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **retire** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds every one of its 4 modes naming exactly one composed skill, `delivery-engine`, so R4b reads it as composing only; retire through `lifecycle-state`. Alternative: `re-home` into `pmo-release-manager` (Go/No-Go Evidence), the used sibling failing ADR-019's trigger conjunct at G1 | MODERATE · LOW | Check 67 max-J pair `pmo-program-manager`, J 0.087, PASS, exact overlap none, not linked; body, own-line: "should we go live" / "should we go" with `pmo-release-manager` (counted); 4 with `delivery-engine`, its composed skill; "plan the sprint" with `pmo-scrum-master`, an unused sibling | pre 11 live / 25 (13 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | alternative only: `pmo-release-manager`, Go/No-Go Evidence | none named | neighbours (store-wide): `delivery-engine` 12; `by_origin` empty; its description changed inside its window; the readiness collision | `follow-up: user-visible` — Severity: Minor |
| `pmo-scrum-master` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1193 name-only / 320 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **retire** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds every one of its 4 modes naming exactly one composed skill, `delivery-engine`; retire through `lifecycle-state`. Alternative: `re-trigger` (no used sibling fails a G1-read conjunct) | MODERATE · LOW | Check 67 max-J pair `pmo-release-train-engineer`, J 0.143, PASS, exact overlap none, not linked; body, own-line: "help the team plan the sprint" with `delivery-engine` (composed) and with `pmo-project-manager` (unused) | pre 15 live / 26 (10 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `delivery-engine` 12; `by_origin` empty; its trigger surface reads "Default-active under Scrum"; it carries no activation gate | `follow-up: user-visible` — Severity: Minor |
| `pmo-tier-1-support` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1513 name-only / 0 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds 1 of 3 modes naming both composed skills; R5's example predicate: the verdict is CLEAN and R2 names no exposure gap, so `re-trigger`. Alternative: `retire` | CHEAP · LOW | Check 67 max-J pair `pmo-tier-2-support`, J 0.167, PASS, exact overlap none, not linked; counted body overlaps 0 — its overlaps with the escalation Specialist rest on its own comparison-table row (the near-miss arm) | pre 13 live / 21 (7 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `artifact-generator` 0; `intake-desk` 117; `by_origin` empty; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-tier-2-support` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1513 name-only / 0 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds 2 of 3 modes naming two or more composed skills; R5's example predicate: the verdict is CLEAN and R2 names no exposure gap, so `re-trigger`. Alternative: `retire` | CHEAP · LOW | Check 67 max-J pair `pmo-tier-1-support`, J 0.167, PASS, exact overlap none, not linked; counted body overlaps 0 | pre 12 live / 23 (10 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `artifact-generator` 0; `file-router` 9; `pmo-knowledge-manager` 3; `intake-desk` 117; `by_origin` empty; the used knowledge manager is one of its `DEPENDS_ON` targets, so R4a excludes it and R4b reads it; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-wms-specialist` · role-Specialist · operations | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-07-02 · `CLEAN` | `cli`: 1247 listed, 23 no-record, of 1514 in window; render 1247 name-only / 0 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds both modes naming no composed skill, an own grounded method; R5's example predicate: the verdict is CLEAN and R2 names no exposure gap, so `re-trigger`. Alternative: `retire` | CHEAP · LOW | Check 67 max-J pair `pmo-data-engineer`, J 0.047, PASS, exact overlap none, not linked; counted body overlaps 0 | pre 6 live / 11 (4 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `artifact-generator` 0; `intake-desk` 117; `by_origin` empty; 244 in-window listing sessions do not name it at authoring; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-data-engineer` · role-Specialist · release | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-08-08 · `CLEAN` | `cli`: 1308 listed, 21 no-record, of 1342 in window; render 1306 name-only / 2 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds 1 of 3 modes naming both composed skills and 1 naming none; R5's example predicate: the verdict is CLEAN and R2 names no exposure gap, so `re-trigger`. Alternative: `retire` | CHEAP · LOW | Check 67 max-J pair `pmo-wms-specialist`, J 0.047, PASS, exact overlap none, not linked; counted body overlaps 0 | pre 7 live / 13 (5 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | none named | neighbours (store-wide): `implementation-planner` 0; `pmo-technical-analyst` 6; `by_origin` empty; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |
| `pmo-devops-sre` · role-Specialist · release | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-21 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1474 name-only / 39 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **retire** — recommended | tie — R4a's role conjunct is G3 against at least two used siblings, the OCM lead and the principal engineer, which state no tier (§ Readings). Predicate: the mode map finds every one of its 3 modes naming exactly one composed skill, `release-executor`; retire through `lifecycle-state`. Alternative: `re-home` into `pmo-release-manager` (Deploy Execution), the used sibling failing ADR-019's trigger conjunct at G1 | MODERATE · LOW | Check 67 max-J pair `release-hub`, J 0.143, PASS, exact overlap none, not linked; body, own-line: "execute the deploy" / "execute the deploy now the GO is in" with `pmo-release-manager` (counted); 5 further overlaps rest on the release manager's comparison row or its deconfliction sentence and do not count | pre 12 live / 28 (15 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | alternative only: `pmo-release-manager`, Deploy Execution | none named | neighbours (store-wide): `release-executor` 13; `by_origin` empty; both files document a decision-versus-execution boundary | `follow-up: user-visible` — Severity: Minor |
| `pmo-skill-router` · router · core | total 0 at authoring (ch1 0 · ch2 0 · ch3 0; errors 0; pre-registration 0; residue 0) · window from 2026-06-23 · `CLEAN` | `cli`: 1513 listed, 23 no-record, of 1549 in window; render 1502 name-only / 11 described; every other class 0 in window (at authoring) | — | none | `[ASSUMPTION – CONFIRM]` **re-trigger** — recommended | R6 — an operator decision. Predicate: its verdict is CLEAN, R2 names no exposure gap, and it is the registry's only goal-to-role mapper; its self-counts are stale (§ Current State), so the re-trigger also refreshes them. Alternative: `retire` through `lifecycle-state`, leaving goal-to-role routing to re-triggered Specialist descriptions | CHEAP · LOW | Check 67 max-J pair `pmo-skill-editor`, J 0.083, PASS, exact overlap none, not linked; one trigger phrase; counted body overlaps 0 | pre 15 live / 22 (6 history, 1 artifacts) at authoring, plus the out-of-repo deployed copy | — | the study-and-design Specialists card names the router as a method for reaching new capabilities | neighbours (store-wide): none (no `DEPENDS_ON`); `by_origin` empty; listing note: a description may not render until the skill is used (§ Current State › Listing finding) | `follow-up: user-visible` — Severity: Minor |


**Counts, at authoring.** 14 rows at authoring: 3 decided by the scheme (R1: 1 keep; R3: 2 re-trigger) and 11 handed to the operator (10 tie rows and the router at R6), each marked `[ASSUMPTION – CONFIRM]`. Recommended values on the handed rows: 8 re-trigger and 3 retire. 0 rows decided at R4a, R4b or R5; 0 probe-only rows.

### What this record does not do

It edits no `SKILL.md`, no registry row and no router. A re-trigger, re-home or retire is a tagged follow-up, implemented through `pmo-skill-editor` in its own card; a keep needs none. It files nothing: the follow-up tags are read by the release's filing step.

## Alternatives Considered

- **Re-trigger every Specialist at once.** Rejected: it decides on the listing defect rather than past it, and it creates collisions the readiness case already shows (one goal phrase reaching two skills with different readiness rules).
- **Retire every never-invoked Specialist.** Rejected: it would retire a methodology-conditional Specialist that is dormant by design, and it ignores the exposure question the listing finding raises.
- **Annotate the registry rows instead of recording a decision.** Rejected: it edits the router's classification source, a runtime routing surface, outside this card's scope.
- **A separate tracked census record cited by this one.** Rejected at the Stage-4 gate: a second file restates the census headline, and the method here is one fenced block.
- **Decide nothing until the router is rebuilt.** Rejected: the router is itself one of the subjects, so deferring on it is circular.

## Consequences

- **Positive:** every never-invoked Specialist and the router has one row, with its evidence, its rule and its follow-up tag; the census is re-runnable at pinned bounds, with both arms; the operator decides the rows the scheme cannot, with a recommended value and an alternative in front of them; the listing finding keeps a re-trigger from being decided on a rendering defect alone.
- **Negative:** most rows reach the operator, because ADR-019's role conjunct cannot be read against two of the used siblings, which state no tier (§ Readings); the recommended values rest on the lock's example predicate and on a name-mention mode map, both stated; the census reads one machine's stores, so off-machine use is a named residual; an Accepted record cannot carry a later census, so a sunset re-run records its results elsewhere.

## Reversibility

EXPENSIVE — the dispositions bind follow-up cards and may retire skills, and once Accepted the record changes only by supersession. Before ratification it is CHEAP: rows are edited in place while the record is Proposed.

## Related ADRs

- ADR-019 — Specialists compose function-skills and do not absorb them; the three-conjunct skill-boundary test R4a applies.
- ADR-033 — methodology-conditional activation; the dormant-by-design keep R1 applies.
- ADR-035 — the role-Specialist kind the population is drawn from.
- ADR-038 — the registry as the skill CMDB, with `lifecycle-state`; retirement runs through it.
- ADR-114 — the composition-aware trigger-collision gate (Check 67) whose bands the collisions column reads.
- ADR-181 — an in-release record is cited by its slug token until its number binds at merge.
- ADR-230 — the record shape with Current State, Future State and Gap Map sections, followed here.
- ADR-231 — non-tracked data homed by risk class; raw per-session data stays in the operator's local transcript store.

## Current State

As of authoring:

### Validity threats and mitigations

Declared before any finding. Each threat names its guard in the procedure.

| # | Threat → mitigation · guard |
|---|---|
| V1 | a listing mention read as an invocation → only the three record predicates count · the nonce arm and the self-test |
| V2 | double counting across resumes and copies → each event keyed once, at its earliest time · the dedupe mutation |
| V3 | a copied store hiding the live one → every copy is read and the most recent copy wins · the copy fixtures |
| V4 | coverage gaps (record shapes, profiles, other machines) → whole app-data directories read, counters printed; off-machine use is a named residual |
| V5 | left-censoring → the store floor; each window opens at the later of registration and the floor |
| V6 | registered is not exposed, and no listing record is not "not listed" → listed and no-record counts per class |
| V7 | a blind channel → zero strata printed and read by the verdict |
| V8 | a control chosen after the fact → `release-hub`, named before the run |
| V9 | a persona card standing in for the Specialist → a covariate, and R3 |
| V10 | attribution, or an errored call read as a run → the `invoked_skills` residue; the error join |
| V11 | reproducibility → pinned `--head` and `--until`; a copy only adds, so a zero stays zero |
| V12 | name forms → the last `:` segment, without `/` |
| V13 | the methodology gate → rung classes; a Custom rung goes to the operator |
| V14 | privacy → class labels only; the path-to-class map stays in the run directory; the leak scan plus an app-data-name count |

### Population

The registry's `## Configuration Items` rows of kind `role-Specialist` or `router` at the census head: 22 at authoring — 21 role Specialists (14 operations, 7 release) and the router — plus their `DEPENDS_ON` targets, read as neighbours. At authoring 13 of the 21 Specialists and the router read total 0 in their windows; 8 Specialists read at least one invocation.

### Census method

**Channels** are record predicates, never substrings:
- **ch1:** in a top-level session file, an assistant record holding a `tool_use` named `Skill`.
- **ch2:** the same, in a subagent file, or in any nested file carrying `isSidechain: true`.
- **ch3:** a top-level, non-meta user turn whose text opens with `<command-message>` or `<command-name>`.

A call whose `tool_result` carries `is_error: true` counts in `skill_call_errors`, not in `total`. Never counted: attachments, request replicas, `tool_result` text, prose, audit logs and the prompt history. A session is a file with at least one assistant record that starts by `--until`.

**Store classes.** `cli` (the CLI and desktop Code store), `config-dir`, `extractor-root`, then each app-data directory the vendor-default pattern matches, read whole. An app-data directory that shares a session with another store and wins none is a copy (`agent-mode-copy`); the default is `agent-mode`; the rest are `profile-N`. The run used no `--roots`, and `FINOPS_SOURCE_ROOT` and `CLAUDE_CONFIG_DIR` were unset.

**Window:** from the later of the subject's registration (the first first-parent commit carrying its registry row, UTC) and the store floor, to `--until`. **Arms:** per-class strata, zeros printed; the control `release-hub` at least 1; the nonce-located census transcript, with mentions above 0 and events 0; `self-test`; `mutations`.

**The procedure**, byte for byte as locked (sha256 `6b43236f9fce612f96b3c29db0138b66f17bb75b8ce53733cf0bef0ac6fe7a59`):

```python
#!/usr/bin/env python3
# Role-Specialist invocation census: read-only; aggregates keyed by store CLASS, never a path, id, prompt or per-session row.
# Modes: self-test | mutations | nonce | activation | collisions --head H | run --head H --until T --nonce N [--since T] [--roots P:P] [--json F]
# TMPDIR must be the run directory: `run` writes the path-to-class map there.
import argparse, glob, hashlib, json, os, re, secrets, shutil, subprocess, sys, tempfile
from collections import Counter, defaultdict
from datetime import datetime, timedelta
HOME, CONTROL, APP = os.path.expanduser("~"), "release-hub", "Claude"  # APP: the vendor's default app-data directory name
TAG = re.compile(r"<command-name>\s*/?([^<\s]+)\s*</command-name>")
ROW = re.compile(r"^\|\s*\[?`([a-z0-9][a-z0-9-]*)`")
ENTRY = re.compile(r"^- ([A-Za-z0-9_.-]+(?::[A-Za-z0-9_.-]+)?)(.*)$")
J = os.path.join
def norm(n): n = (n or "").strip().lstrip("/"); return (n.split()[0] if n else n).rsplit(":", 1)[-1]
def ts(d): t = d.get("timestamp"); return t[:19] if isinstance(t, str) else None
def store_roots(home=None, env=None, override=None):  # precedence order; whole app-data dirs
  home, env = home or HOME, os.environ if env is None else env
  if override: return [os.path.normpath(r) for r in override.split(os.pathsep) if os.path.isdir(r)]
  r = [J(home, ".claude", "projects")] + ([J(env["CLAUDE_CONFIG_DIR"], "projects")] if env.get("CLAUDE_CONFIG_DIR") else []) + ([env["FINOPS_SOURCE_ROOT"]] if env.get("FINOPS_SOURCE_ROOT") else [])
  r += sorted(glob.glob(J(home, "Library", "Application Support", APP + "*")), key=lambda p: (os.path.basename(p) != APP, os.path.basename(p)))
  out = []
  for x in map(os.path.normpath, r):
    if os.path.isdir(x) and x not in out: out.append(x)
  return out
def kind_of(root, home, env):
  for k, p in (("cli", J(home, ".claude", "projects")), ("config-dir", env.get("CLAUDE_CONFIG_DIR") and J(env["CLAUDE_CONFIG_DIR"], "projects")), ("extractor-root", env.get("FINOPS_SOURCE_ROOT"))):
    if p and root == os.path.normpath(p): return k
  if os.path.dirname(root) == os.path.normpath(J(home, "Library", "Application Support")): return "app-default" if os.path.basename(root) == APP else "app"
  return "override"
def classify(p):  # ("top"|"sub"|"nested", session) for a file under a projects/ segment, else None
  parts = p.split(os.sep)
  if "projects" not in parts: return None
  rest = parts[len(parts) - parts[::-1].index("projects"):]
  if len(rest) == 2: return ("top", rest[1][:-6])
  return ("sub" if rest[2] == "subagents" else "nested", rest[1]) if len(rest) >= 4 else None
def read(p, kind, nonce, subjects):
  f = dict(start=None, last="", n=0, asst=0, side=False, listed=None, calls=[], slash=[], err=set(), inv=set(), origin=Counter(), raw=0, nonce=False)
  for line in open(p, encoding="utf-8", errors="replace"):
    try: d = json.loads(line)
    except ValueError: continue
    if not isinstance(d, dict): continue
    t, ty = ts(d), d.get("type"); f["n"] += 1; f["last"] = max(f["last"], t or "")
    if ty in ("user", "assistant") and t: f["start"] = min(f["start"] or t, t)
    if ty in ("user", "assistant") and isinstance(d.get("entrypoint"), str): f["origin"][d["entrypoint"]] += 1
    f["asst"] += ty == "assistant"; f["side"] |= d.get("isSidechain") is True
    a = d.get("attachment") if ty == "attachment" else None
    if isinstance(a, dict) and a.get("type") == "skill_listing" and a.get("isInitial") and f["listed"] is None:
      f["listed"] = ({norm(x) for x in a.get("names") or []}, {norm(m.group(1)): "described" if m.group(2).startswith(": ") else "name-only"
             for m in map(ENTRY.match, (a.get("content") or "").splitlines()) if m}, len(a.get("content") or ""))
    if isinstance(a, dict) and a.get("type") == "invoked_skills": f["inv"] |= {norm(s.get("name")) for s in a.get("skills") or [] if isinstance(s, dict)}
    if nonce: f["nonce"] |= nonce in line; f["raw"] += sum(line.count(s) for s in subjects)
    c = d["message"].get("content") if isinstance(d.get("message"), dict) else None
    if ty == "assistant" and isinstance(c, list):  # ch1/ch2
      f["calls"] += [(i.get("id") or "%s/%d" % (d.get("uuid"), k), norm(str((i.get("input") or {}).get("skill") or (i.get("input") or {}).get("command") or "")), t)
             for k, i in enumerate(c) if isinstance(i, dict) and i.get("type") == "tool_use" and i.get("name") == "Skill"]
    if ty == "user" and isinstance(c, list):
      f["err"] |= {i.get("tool_use_id") for i in c if isinstance(i, dict) and i.get("type") == "tool_result" and i.get("is_error") is True}
    if ty == "user" and kind == "top" and not d.get("isMeta"):  # ch3: text that OPENS with the tag
      for x in [c] if isinstance(c, str) else [i.get("text", "") for i in c if isinstance(i, dict) and i.get("type") == "text"] if isinstance(c, list) else []:
        s = x.lstrip()
        if s.startswith(("<command-message>", "<command-name>")) and TAG.search(s):
          f["slash"].append((d.get("uuid") or hashlib.sha1(line.encode()).hexdigest(), norm(TAG.search(s).group(1)), t)); break
  return f
def scan(roots, until, nonce, subjects, home=None, env=None):  # every copy is read
  home, env = home or HOME, os.environ if env is None else env
  files, extra = [], defaultdict(Counter)
  for ri, root in enumerate(roots):
    for dp, _, fn in os.walk(root):
      for name in sorted(x for x in fn if x.endswith(".jsonl")):
        k = classify(J(dp, name))
        if not k: extra[ri]["audit_logs" if name == "audit.jsonl" else "unclassified_jsonl"] += 1; continue
        f = read(J(dp, name), k[0], nonce, subjects); f.update(ri=ri, kind=k[0], sid=k[1], name=name)
        if k[0] == "nested":
          if f["side"]: f["kind"] = "sub"
          else: extra[ri]["unclassified_jsonl"] += 1; extra[ri]["unclassified_skill_calls"] += len(f["calls"]); continue
        files.append(f)
  return files, [kind_of(r, home, env) for r in roots], extra
def aggregate(files, kinds, extra, subjects, reg, until, neighbours=()):
  ok = [f for f in files if f["asst"] and f["start"] and f["start"] <= until]
  rank = lambda f: (f["last"], f["n"], -f["ri"])  # the most recent copy wins
  win = {}
  for f in ok:
    k = (f["kind"], f["sid"], f["name"] if f["kind"] == "sub" else "")
    if k not in win or rank(f) > rank(win[k]): win[k] = f
  W = {id(f) for f in win.values()}; S = {k[1]: f for k, f in win.items() if k[0] == "top"}
  share, wins, by = Counter(), Counter(), defaultdict(list)
  for f in ok:
    if f["kind"] == "top": by[f["sid"]].append(f)
  for fs in by.values():
    if len({f["ri"] for f in fs}) > 1:
      for f in fs: share[f["ri"]] += 1; wins[f["ri"]] += id(f) in W
  held, cls, nc, npf, am = Counter(f["ri"] for f in S.values()), {}, 0, 0, "app-default" in kinds
  for ri, k in enumerate(kinds):
    if k in ("cli", "config-dir", "extractor-root"): cls[ri] = k
    elif k == "override": cls[ri] = "override-%d" % (ri + 1)
    elif share[ri] and not wins[ri]: nc += 1; cls[ri] = "agent-mode-copy" + ("-%d" % nc) * (nc > 1)
    elif (k == "app-default" or (not am and held[ri])) and "agent-mode" not in cls.values(): am = True; cls[ri] = "agent-mode"
    else: npf += 1; cls[ri] = "profile-%d" % npf
  errs, occ = set().union(*[f["err"] for f in ok]), defaultdict(list)
  for f in ok:
    for ch, lst in (("ch1" if f["kind"] == "top" else "ch2", f["calls"]), ("ch3", f["slash"])):
      for key, n, t in lst: occ[key].append((t, f, ch, n))
  ev, hit, inv = {}, defaultdict(set), defaultdict(set)
  for key, os_ in occ.items():
    tl = [o[0] for o in os_ if o[0]]
    if not tl: continue
    t = min(tl)  # an event's time is its earliest copy
    o = next((o for o in os_ if id(o[1]) in W), min(os_, key=lambda o: o[0] or "9"))
    ev[key] = (o[2], o[3], t, cls[o[1]["ri"]], key in errs, (o[1]["origin"].most_common(1) or [("absent", 0)])[0][0])
    for o in os_:
      if key not in errs: hit[o[1]["sid"]].add(o[3])
  for f in ok: inv[f["sid"]] |= f["inv"]
  inwin = lambda e, r: r <= e[2] <= until and not e[4]
  floor = min((f["start"] for f in S.values()), default=None)
  strata = Counter((e[3], e[0]) for e in ev.values() if inwin(e, ""))
  keys = {(cls[f["ri"]], c) for f in S.values() for c in ("ch1", "ch3")} | {(cls[f["ri"]], "ch2") for k, f in win.items() if k[0] == "sub"}
  sens = {"%s | %s" % k: strata.get(k, 0) for k in sorted(keys | set(strata))}
  def counts(s, r):
    c = Counter(e[0] for e in ev.values() if e[1] == s and inwin(e, r))
    return dict(ch1_direct=c["ch1"], ch2_subagent=c["ch2"], ch3_slash=c["ch3"], total=sum(c.values()), skill_call_errors=sum(1 for e in ev.values() if e[1] == s and e[4] and r <= e[2] <= until))
  per = {}
  for s in subjects:
    r = reg.get(s, "9999"); ws = [f for f in S.values() if r <= f["start"] <= until]
    listed = Counter(cls[f["ri"]] for f in ws if f["listed"] and s in f["listed"][0])
    res = sum(1 for x, f in S.items() if r <= f["start"] and s in inv[x] and s not in hit[x])
    el = ["%s | %s blind" % k for k in sorted(keys) if k[0] in listed and strata.get(k, 0) == 0] + ["invoked_skills residue %d" % res] * bool(res)
    per[s] = dict(registered=r, window_start=max(r, floor or r), sessions_in_window=dict(Counter(cls[f["ri"]] for f in ws)), listed_sessions_in_window=dict(listed), sessions_without_listing_record=dict(Counter(cls[f["ri"]] for f in ws if not f["listed"])),
           **counts(s, r), pre_registration=sum(1 for e in ev.values() if e[1] == s and e[2] < r and not e[4]), invoked_skills_unexplained=res,
           by_origin=dict(Counter(e[5] for e in ev.values() if e[1] == s and inwin(e, r))),
           verdict="UNEXPOSED" if not listed else "CLEAN" if not el else "INDETERMINATE: " + "; ".join(el))
  nb = {n: counts(n, "") for n in neighbours}
  days, tally, r4, dn, ln, evs = Counter(), defaultdict(Counter), Counter(), [], [], defaultdict(list)
  for e in ev.values():
    if inwin(e, ""): evs[e[1]].append(e[2])
  for f in S.values():
    if not f["listed"]: continue
    names, forms, size = f["listed"]; days[f["start"][:10]] += 1; ln.append(size); dn.append(sum(v == "described" for v in forms.values()))
    lo = (datetime.fromisoformat(f["start"]) - timedelta(days=14)).isoformat()
    for n, v in forms.items(): r4[v, any(lo <= t < f["start"] for t in evs.get(n, ()))] += 1
    for s in subjects:
      if reg.get(s, "9999") <= f["start"]: tally[s][forms.get(s, "listed-unparsed" if s in names else "not-listed")] += 1
  q = lambda x: [min(x), sorted(x)[len(x) // 2], max(x)] if x else None
  rate = lambda u: "%d/%d" % (r4["described", u], r4["described", u] + r4["name-only", u])
  cnt = lambda C, c: sum(1 for f in C if cls[f["ri"]] == c)
  classes = {c: dict(sessions=cnt(S.values(), c), copy_sessions_skipped=cnt([f for f in ok if f["kind"] == "top" and id(f) not in W], c),
           copy_only_sessions=cnt(S.values(), c) * c.startswith("agent-mode-copy"), sessions_with_listing=cnt([f for f in S.values() if f["listed"]], c), subagent_files=cnt([f for k, f in win.items() if k[0] == "sub"], c),
           **{x: extra[ri][x] for x in ("unclassified_jsonl", "unclassified_skill_calls", "audit_logs")}) for ri, c in cls.items()}
  nf = [f for f in ok if f["nonce"]]
  return {"until": until, "store_floor": floor, "classes": classes, "sessions_by_store": {c: v["sessions"] for c, v in classes.items() if v["sessions"]},
      "subagent_files_by_store": {c: v["subagent_files"] for c, v in classes.items() if v["subagent_files"]},
      "arms": {"sensitivity_by_store_channel": sens, "control_" + CONTROL: sum(1 for e in ev.values() if e[1] == CONTROL and inwin(e, "")),
          "specificity_nonce_files": len(nf), "specificity_nonce_raw_subject_mentions": sum(f["raw"] for f in nf),
          "specificity_nonce_subject_events": sum(1 for f in nf for _, n, _ in f["calls"] + f["slash"] if n in subjects)},
      "subjects": per, "neighbours": nb, "_classmap": cls,
      "listing": {"days_with_listings": len(days), "sessions_with_listing": sum(days.values()), "described_per_listing": q(dn),
            "described_if_used_in_prior_14d": rate(True), "described_if_not_used": rate(False), "per_subject": {s: dict(c) for s, c in tally.items()}}}
def git(*a): return subprocess.run(["git", *a], capture_output=True, text=True, check=True, env=dict(os.environ, TZ="UTC")).stdout
def population(head):
  subj, deps, on = [], {}, False
  for line in git("show", head + ":core/skills/registry.md").splitlines():
    if line.startswith("## "): on = line.startswith("## Configuration Items")
    m = ROW.match(line) if on else None
    if m and line.split("|")[2].strip() in ("role-Specialist", "router"): subj.append(m.group(1)); deps[m.group(1)] = re.findall(r"DEPENDS_ON ([a-z0-9-]+)", line.split("|")[5])
  return subj, deps
def registration(head, subj):
  reg = {}
  for line in git("log", "--first-parent", "--reverse", "--date=format-local:%Y-%m-%dT%H:%M:%S", "--format=%H %cd", head, "--", "core/skills/registry.md").splitlines():
    sha, when = line.split()
    for s in set(subj) & {m.group(1) for m in map(ROW.match, git("show", sha + ":core/skills/registry.md").splitlines()) if m}: reg.setdefault(s, (when, sha))
  return reg
def base_before(head, when): return git("rev-list", "-1", "--before=" + when, head).strip()
def descriptions_changed(head, subjects, bases):  # bases: {subject: commit or ""}; an empty base is INDETERMINATE
  def desc(sha, s):
    p = [l for l in git("ls-tree", "-r", "--name-only", sha).splitlines() if l.endswith("/skills/%s/SKILL.md" % s)]
    m = re.search(r"^description:[ \t]*[>|]?-?[ \t]*\n?((?:[ \t]+.*\n?)+|.*)", (git("show", "%s:%s" % (sha, p[0])) if p else "").split("\n---", 1)[0], re.M)
    return " ".join(m.group(1).split()) if m else None
  out = {"changed": [], "indeterminate": [], "unchanged": 0}
  for s in subjects:
    b = bases.get(s); x, y = (desc(b, s), desc(head, s)) if b else (None, None)
    if x is None or y is None: out["indeterminate"].append(s)
    elif x != y: out["changed"].append(s)
    else: out["unchanged"] += 1
  return out
def toml_key(path, sec, key):
  cur = None
  for line in open(path, encoding="utf-8", errors="replace") if os.path.isfile(path) else []:
    m = re.match(r"^\s*\[([^\]]+)\]", line)
    if m: cur = m.group(1).strip(); continue
    m = re.match(r'^\s*%s\s*=\s*"([^"]*)"' % re.escape(key), line)
    if cur == sec and m: return m.group(1)
  return "absent"
def activation(home=None, ws=None, template="core/config/operator.toml.template"):
  home = home or HOME; ws = ws or os.environ.get("CLAUDE_WORKSPACE_ROOT", J(home, "Claude")); pf = J(ws, "projects/_config/PORTFOLIO.md")
  rungs = [("tracked default", toml_key(template, "methodology", "default_delivery_approach")), ("individual config", toml_key(J(home, ".config/pmo-platform/operator.toml"), "methodology", "default_delivery_approach"))]
  rungs += [("portfolio file", v) for v in re.findall(r"delivery_approach:\s*\"?([A-Za-z0-9]+)", open(pf, encoding="utf-8").read().split("\n---", 1)[0])] if os.path.isfile(pf) else []
  safe = next((c for c, v in rungs if v == "SAFe"), None); cust = next((c for c, v in rungs if v == "Custom"), None)
  return {"pmo-release-train-engineer": "ACTIVE-POSSIBLE" if safe else "OPERATOR-CONFIRM (Custom)" if cust else "DORMANT",
      "deciding_rung_class": safe or cust or "none", "rungs_read": sorted({c for c, v in rungs if v != "absent"}), "operator_confirms": "program, project"}
def collisions(head, subjects, min_tokens=3):
  phr = {}
  for f in git("ls-tree", "-r", "--name-only", head).splitlines():
    if re.match(r"^(core|operations|release)/skills/[^/]+/SKILL\.md$", f):
      phr[f.split("/")[2]] = {p for p in {" ".join(re.findall(r"[a-z0-9]+", q.lower())) for l in git("show", head + ":" + f).splitlines()
                  if re.search(r"Trigger|→ \*\*Mode|\|\s*Mode\b", l) for q in re.findall(r'"([^"]{6,80})"', l)} if len(p.split()) >= 2}
  def hit(x, y):
    a, b = sorted((x, y), key=len)
    return x == y or (len(a.split()) >= min_tokens and " %s " % a in " %s " % b)
  return [(a, b, x, y) for a in subjects for b in phr if b != a for x in phr.get(a, ()) for y in phr[b] if hit(x, y)]
def self_test():  # synthetic HOME and git history only
  global git
  tmp = tempfile.mkdtemp(); h = tmp + "/home"; app = h + "/Library/Application Support/"; c = h + "/.claude/projects/p/"
  S = ["pmo-" + x for x in ("architect", "ocm-lead", "qa-lead", "program-manager", "tier-1-support", "data-engineer", "release-manager", "scrum-master", "devops-sre", "software-engineer")]
  def w(p, *recs): os.makedirs(os.path.dirname(p), exist_ok=True); open(p, "w").write("\n".join(json.dumps(r) for r in recs) + "\n")
  def R(ty, u, t, c, **k): return dict({"type": ty, "uuid": u, "timestamp": t, "message": {"content": c}}, **k)
  def A(u, t, *items, **k): return R("assistant", u, t, [i if isinstance(i, dict) else {"type": "tool_use", "id": i[0], "name": "Skill", "input": {"skill": i[1]}} for i in items], **k)
  def L(t, desc): return {"type": "attachment", "timestamp": t, "attachment": {"type": "skill_listing", "isInitial": True, "names": S + [CONTROL, "fx-engine"],
              "content": "\n".join("- %s%s" % (s, ": d" * (s in desc)) for s in S + [CONTROL, "fx-engine"])}}
  D1, D2, D5, OK, E = "2026-11-01T10:00:00Z", "2026-11-03T10:00:00Z", "2026-11-05T10:00:00Z", {"type": "text", "text": "ok"}, {"entrypoint": "claude-desktop"}
  tag = lambda n: "<command-name>/%s</command-name>" % n; nb = "NONCE-X " + " ".join(S)
  s1 = [L(D1, {S[0]}), R("user", "u1", D1, "<command-message>pmo-ocm-lead</command-message>\n" + tag(S[1]), **E), R("user", "u2", D1, tag("x:" + S[3]), **E),
     A("a1", D1, ("T1", S[0]), ("T10", "fx-engine"), **E), {"type": "attachment", "timestamp": D1, "attachment": {"type": "invoked_skills", "skills": [{"name": S[0]}, {"name": S[2]}]}},
     A("a9", "2026-12-03T10:00:00Z", ("T11", S[5]), **E)]
  w(c + "S1.jsonl", *s1); w(c + "S2.jsonl", *s1)
  w(c + "S1/subagents/agent-1.jsonl", A("a2", D1, ("T2", S[2]), isSidechain=True), R("user", "u7", D1, tag(S[4]), isSidechain=True))
  w(c + "S1/workflows/run-1/agent-w.jsonl", A("a8", D1, ("T8", S[9]), isSidechain=True))
  w(c + "S1/tool-results/x.jsonl", A("a10", D1, ("T14", S[8])))
  w(c + "S3.jsonl", L(D1, {S[0]}), R("user", "u3", D1, [{"type": "tool_result", "content": nb + tag(S[0])}]), R("user", "u4", D1, tag(S[4]), isMeta=True),
   R("user", "u15", D1, "see %s above" % tag(S[8])), {"type": "api-request-blob", "timestamp": D1, "message": {"content": [A("x", D1, ("T9", S[5]))["message"]["content"][0], {"type": "text", "text": tag(S[0])}]}},
   A("a3", D1, {"type": "text", "text": S[0]}, {"type": "tool_use", "id": "T3", "name": "Read", "input": {"file_path": "operations/skills/pmo-ocm-lead/SKILL.md"}}))
  w(c + "S5.jsonl", R("user", "u5", D1, tag(S[0])))
  w(c + "S6/subagents/agent-n.jsonl", R("user", "u6", D1, [{"type": "tool_result", "content": nb}], isSidechain=True), A("a6", D1, OK, isSidechain=True))
  w(c + "S6/subagents/agent-m.jsonl", A("a7", D1, ("T7", S[4]), isSidechain=True))  # a sibling in the nonce file's lineage
  w(c + "S10.jsonl", A("a11", D5, ("T5", S[6]))); w(c + "S11.jsonl", R("user", "u11", "2026-11-20T10:00:00Z", "go"), A("a11", "2026-12-05T10:00:00Z", ("T5", S[6])))
  w(c + "S12.jsonl", R("user", "u12", "2026-12-02T10:00:00Z", "go"), A("a13", "2026-12-02T10:00:00Z", ("T12", S[5])))
  w(c + "S13.jsonl", L(D2, {S[0], S[1]}), R("user", "u13", D2, "go", entrypoint="sdk-cli"), A("a14", D2, ("T13", S[7])),
   R("user", "u14", D2, [{"type": "tool_result", "tool_use_id": "T13", "is_error": True, "content": "no"}]), A("a15", D2, OK), L(D2, set()))
  lam, T1, T2 = "/local-agent-mode-sessions/x/y/local_z/", "2026-10-01T09:00:00Z", "2026-10-05T09:00:00Z"
  for d, s4 in ((APP, [A("a4", T1, OK), A("a5", T2, ("T4", CONTROL))]), (APP + "-zz", [A("a4", T1, OK)])):
    w(app + d + lam + ".claude/projects/p/S4.jsonl", *s4); w(app + d + lam + ".claude/projects/p/S4/subagents/agent-2.jsonl", A("a16", T1, OK, isSidechain=True))
  w(app + APP + lam + "audit.jsonl", A("a5", T2, ("T4", CONTROL))); w(app + APP + "-zz" + lam + ".claude/projects/p/S8.jsonl", A("a17", T1, OK))
  w(app + APP + "P" + lam + ".claude/projects/p/S9.jsonl", A("a18", T1, OK)); w(app + APP + "Q" + lam + ".claude/projects/p/S9.jsonl", A("a18", T1, OK), A("a19", T2, ("T15", "fx-engine")))
  os.makedirs(app + APP + "R")  # an empty profile directory; APP+"P" is a stale copy of profile APP+"Q" that sorts before it
  U = "2026-12-01T00:00:00"; reg = dict({s: "2026-06-20T00:00:00" for s in S}, **{S[3]: "2026-11-05T00:00:00"})
  roots = store_roots(home=h, env={}); r = aggregate(*scan(roots, U, "NONCE-X", S, home=h, env={}), S, reg, U, neighbours=["fx-engine"])
  P, Ar, G, C = r["subjects"], r["arms"], r["listing"], r["classes"]
  want = dict(zip(S, [(1, 0, 0), (0, 0, 1), (0, 1, 0), (0, 0, 0), (0, 1, 0), (0, 0, 0), (1, 0, 0), (0, 0, 0), (0, 0, 0), (0, 1, 0)]))
  sens = {"agent-mode | ch1": 1, "agent-mode | ch2": 0, "agent-mode | ch3": 0, "agent-mode-copy | ch1": 0, "agent-mode-copy | ch3": 0, "cli | ch1": 3, "cli | ch2": 3, "cli | ch3": 2, "profile-1 | ch1": 1, "profile-1 | ch3": 0}
  checks = [("roots", [os.path.basename(x) for x in roots] == ["projects", APP, APP + "-zz", APP + "P", APP + "Q", APP + "R"]),
       ("channels", all((P[k]["ch1_direct"], P[k]["ch2_subagent"], P[k]["ch3_slash"]) == v for k, v in want.items())),
       ("sessions", r["sessions_by_store"] == {"cli": 6, "agent-mode": 1, "agent-mode-copy": 1, "profile-1": 1}),
       ("counters", (C["agent-mode-copy"]["copy_sessions_skipped"], C["agent-mode-copy-2"]["copy_sessions_skipped"], C["agent-mode-copy"]["copy_only_sessions"],
                            C["cli"]["unclassified_jsonl"], C["cli"]["unclassified_skill_calls"], C["agent-mode"]["audit_logs"]) == (1, 1, 1, 1, 1, 1)),
       ("subagent files", r["subagent_files_by_store"] == {"cli": 4, "agent-mode": 1}),
       ("strata", Ar["sensitivity_by_store_channel"] == sens and Ar["control_" + CONTROL] == 1),
       ("nonce", (Ar["specificity_nonce_files"], Ar["specificity_nonce_subject_events"]) == (2, 0) and Ar["specificity_nonce_raw_subject_mentions"] > 0),
       ("errors, pre-registration", (P[S[7]]["total"], P[S[7]]["skill_call_errors"], P[S[3]]["pre_registration"]) == (0, 1, 1)),
       ("verdicts", [P[k]["verdict"] for k in (S[0], S[2], S[3])] == ["CLEAN", "INDETERMINATE: invoked_skills residue 1", "UNEXPOSED"]),
       ("origin, neighbours", P[S[0]]["by_origin"] == {"claude-desktop": 1} and r["neighbours"]["fx-engine"]["total"] == 2),
       ("listing", (G["days_with_listings"], G["described_if_used_in_prior_14d"], G["described_if_not_used"]) == (2, "2/7", "3/41")
       and G["per_subject"][S[0]] == {"described": 4} and S[3] not in G["per_subject"])]
  rm = "## Configuration Items\n\n| name | kind | module | lifecycle | dependencies | owner | trigger | modes |\n|---|---|---|---|---|---|---|---|\n"
  row = lambda n, k, d: "| [`%s`](x) | %s | m | active | %s | o | t | m |\n" % (n, k, d)
  sm = lambda n, ds, tr: "---\nname: %s\ndescription: >\n  %s\n---\n**Trigger:** %s\n" % (n, ds, tr)
  c1 = {"core/skills/registry.md": rm + row(S[0], "role-Specialist", "DEPENDS_ON fx-engine") + row("fx-engine", "function-skill", "—"), "release/skills/pmo-architect/SKILL.md": sm(S[0], "A", '"are we ready for go-live", "integration risk"')}
  c2 = dict(c1, **{"core/skills/registry.md": c1["core/skills/registry.md"] + row(S[3], "role-Specialist", "—") + row("pmo-skill-router", "router", "—"),
          "release/skills/pmo-architect/SKILL.md": sm(S[0], "B", '"are we ready for go-live", "integration risk"'),
          "operations/skills/pmo-program-manager/SKILL.md": sm(S[3], "P", '"are we ready", "tie the integration risk to the sprint plan"')})
  hist = [("c1", "2026-06-20T00:00:00", c1), ("c2", "2026-11-05T00:00:00", c2)]
  def fake(*a):
    snap = lambda x: next((f for s, _, f in hist if s == x), {})
    if a[0] == "show": x, p = a[1].split(":", 1); return snap(x).get(p, "")
    if a[0] == "log": return "\n".join("%s %s" % (s, t) for s, t, _ in hist)
    if a[0] == "rev-list": return ([s for s, t, _ in hist if t <= a[2].split("=", 1)[1]] or [""])[-1]
    return "\n".join(sorted(snap(a[3])))
  real, git = git, fake
  try: sj, deps = population("c2"); rg = registration("c2", sj); dc = descriptions_changed("c2", sj, {S[0]: "c1", S[3]: rg[S[3]][1]}); co = collisions("c2", [S[0]])
  finally: git = real
  os.makedirs(h + "/.config/pmo-platform"); open(h + "/.config/pmo-platform/operator.toml", "w").write('[methodology]\ndefault_delivery_approach = "Custom"\n')
  open(tmp + "/tpl.toml", "w").write('[methodology]\ndefault_delivery_approach = "Scrum"\n'); ac = activation(home=h, ws=tmp + "/ws", template=tmp + "/tpl.toml")
  checks += [("population", (sj, deps[S[0]]) == ([S[0], S[3], "pmo-skill-router"], ["fx-engine"])),
       ("registration", (rg[S[0]], rg[S[3]][0]) == (("2026-06-20T00:00:00", "c1"), "2026-11-05T00:00:00")),
       ("descriptions", dc == {"changed": [S[0]], "indeterminate": ["pmo-skill-router"], "unchanged": 1}),
       ("collisions", co == [(S[0], S[3], "are we ready for go live", "are we ready")]),
       ("activation", ac["pmo-release-train-engineer"] == "OPERATOR-CONFIRM (Custom)" and ac["deciding_rung_class"] == "individual config")]
  shutil.rmtree(tmp)
  for name, ok in checks: print(("PASS " if ok else "FAIL ") + name)
  return 0 if all(ok for _, ok in checks) else 1
MUTATIONS = [  # (id, defect, old, new): each must turn self-test FAIL; `mutations` re-runs them all (Stage 7's sensitivity arm)
  ("M1", "replica counted", 'if ty == "assistant" and isinstance(c, list):', 'if ty in ("assistant", "api-request-blob") and isinstance(c, list):'),
  ("M2", "dedupe removed", "occ[key].append((t, f, ch, n))", "occ[(key, len(occ))].append((t, f, ch, n))"),
  ("M3", "tag anywhere", 's.startswith(("<command-message>", "<command-name>")) and TAG.search(s)', "TAG.search(s)"),
  ("M4", "walk-order precedence", 'rank = lambda f: (f["last"], f["n"], -f["ri"])', 'rank = lambda f: (-f["ri"],)'),
  ("M5", "no spend filter", 'if f["asst"] and f["start"] and', 'if f["start"] and'),
  ("M6", "nonce by lineage", 'for f in nf for _, n, _ in f["calls"]', 'for g in nf for f in ok if f["sid"] == g["sid"] for _, n, _ in f["calls"]'),
  ("M7", "no registration bound", "inwin = lambda e, r: r <= e[2] <= until", "inwin = lambda e, r: e[2] <= until"),
  ("M8", "zero strata dropped", "strata.get(k, 0) for k in sorted(keys | set(strata))}", "v for k, v in sorted(strata.items())}"),
  ("M9", "isMeta counted", 'kind == "top" and not d.get("isMeta"):', 'kind == "top":'),
  ("M10", "errors counted", 'i.get("is_error") is True}', 'i.get("is_error") is None and False}'),
  ("M11", "verdict over unlisted", "if k[0] in listed and strata", "if strata"),
  ("M12", "tally unwindowed", 'if reg.get(s, "9999") <= f["start"]: tally', "if True: tally"),
  ("M13", "no neighbours", 'nb = {n: counts(n, "") for n in neighbours}', "nb = {}"),
  ("X1", "no upper bound", "r <= e[2] <= until and not e[4]", "r <= e[2] and not e[4]"),
  ("X2", "no session filter", 'f["start"] and f["start"] <= until]', 'f["start"]]'),
  ("X3", "latest copy", "t = min(tl)", "t = max(tl)"),
  ("X4", "glob narrowed", 'APP + "*")', "APP)"),
  ("X5", "last registration", "reg.setdefault(s, (when, sha))", "reg.__setitem__(s, (when, sha))"),
  ("X6", "no kind filter", 'strip() in ("role-Specialist", "router")', 'strip() != "?"'),
  ("X7", "rates swapped", "rate(True), \"described_if_not_used\": rate(False)", "rate(False), \"described_if_not_used\": rate(True)"),
  ("X8", "Custom ignored", 'cust = next((c for c, v in rungs if v == "Custom"), None)', "cust = None"),
  ("X9", "nested as subagent", 'if f["side"]: f["kind"] = "sub"', 'if 1: f["kind"] = "sub"'),
  ("X10", "no description diff", 'elif x != y: out["changed"].append(s)', "elif 0: pass"),
  ("X11", "last listing", ' and f["listed"] is None:', ":"),
  ("X12", "subagent turns counted", 'if ty == "user" and kind == "top" and', 'if ty == "user" and'),
  ("X13", "2-token containment", "len(a.split()) >= min_tokens", "len(a.split()) >= 2")]
def mutations():
  code, table = open(__file__).read().split("\nMUTATIONS = [", 1); missed = []
  for mid, what, old, new in [("C0", "none (control)", "", "")] + MUTATIONS:
    assert not old or code.count(old) == 1, mid
    d = tempfile.mkdtemp(); p = J(d, "m.py"); open(p, "w").write(code.replace(old, new, 1) * bool(old) + code * (not old) + "\nMUTATIONS = [" + table)
    rc = subprocess.run([sys.executable, "-I", p, "self-test"], capture_output=True, text=True, env=dict(os.environ, TMPDIR=d)).returncode; shutil.rmtree(d)
    ok = (rc == 0) if mid == "C0" else (rc != 0); missed += [mid] * (not ok); print("%-4s %-24s %s" % (mid, what, "caught" if ok and old else "ok" if ok else "MISSED"))
  return 1 if missed else 0
if __name__ == "__main__":
  ap = argparse.ArgumentParser(); ap.add_argument("mode", choices=["self-test", "mutations", "nonce", "run", "activation", "collisions"])
  for f in ("--head", "--until", "--nonce", "--json", "--since", "--roots"): ap.add_argument(f)
  o = ap.parse_args()
  if o.mode in ("self-test", "mutations"): sys.exit(self_test() if o.mode == "self-test" else mutations())
  if o.mode in ("nonce", "activation"): sys.exit(print("census-nonce-" + secrets.token_hex(8) if o.mode == "nonce" else json.dumps(activation(), indent=1)))
  subj, deps = population(o.head)
  if o.mode == "collisions": sys.exit(print("\n".join(" | ".join(r) for r in collisions(o.head, subj))))
  until, regs, roots = o.until[:19], registration(o.head, subj), store_roots(override=o.roots)
  out = aggregate(*scan(roots, until, o.nonce, subj), subj, {s: w for s, (w, _) in regs.items()}, until, neighbours=sorted({t for v in deps.values() for t in v}))
  cm = out.pop("_classmap"); open(J(tempfile.gettempdir(), "census-class-map.txt"), "w").write("".join("%s\t%s\n" % (cm[i], r) for i, r in enumerate(roots)))
  ws = lambda s: out["subjects"][s]["window_start"]
  bases = {s: base_before(o.head, o.since) if o.since else regs[s][1] if ws(s) == regs[s][0] else base_before(o.head, ws(s)) for s in regs}
  out.update(head=o.head, subject_count=len(subj), stores_covered=sorted(out["classes"]), descriptions=descriptions_changed(o.head, subj, bases))
  if o.json: json.dump(out, open(o.json, "w"), indent=1)
  print(json.dumps(out, indent=1))
```

**As run**, from the worktree root with `TMPDIR` set to the run directory:

```text
self-test    16 PASS
mutations    26 caught, control ok, 0 MISSED
run          --head 29c604045def22ebd21fb4a758c3bb56be277b20 --until 2026-11-13T21:42:22 --nonce <printed into the census transcript>
--since ctl  same --head, --until and nonce, --since 2026-10-15T23:59:59 -> descriptions changed 0, indeterminate 0
pre-reg run  same --head and nonce, --until 2026-06-21T03:43:04 (one second before the earliest registration) -> agent-mode sessions 209
activation   pmo-release-train-engineer DORMANT; deciding rung class none; rungs read individual config, tracked default
collisions   --head 29c604045def22ebd21fb4a758c3bb56be277b20 -> 51 rows
Check 67     run_eval_audit.py --composition-aware over the deploy roster -> 56 skills, 1540 pairs, ESCALATE 0, WATCH 0, max J 0.188
pre-counts   git grep -l -wF <name> <head> -- . per row, plus an absent-name control -> 0
```

The two passes over the full window agree on every aggregate except the nonce file's own mention count, which grew with this session's transcript.

### Census results

Class counters, at authoring:

```text
cli              sessions  1549 · copy sessions skipped    0 · copy-only 0 · with listing  1526 · subagent files  7329 · unclassified .jsonl 0 · unclassified skill calls 0 · audit logs 0
agent-mode       sessions   209 · copy sessions skipped    0 · copy-only 0 · with listing    41 · subagent files   384 · unclassified .jsonl 0 · unclassified skill calls 0 · audit logs 214
profile-1        sessions     0 · copy sessions skipped    0 · copy-only 0 · with listing     0 · subagent files     0 · unclassified .jsonl 0 · unclassified skill calls 0 · audit logs 0
profile-2        sessions     0 · copy sessions skipped    0 · copy-only 0 · with listing     0 · subagent files     0 · unclassified .jsonl 0 · unclassified skill calls 0 · audit logs 0
agent-mode-copy  sessions     0 · copy sessions skipped  186 · copy-only 0 · with listing     0 · subagent files     0 · unclassified .jsonl 0 · unclassified skill calls 0 · audit logs 191
profile-3        sessions     0 · copy sessions skipped    0 · copy-only 0 · with listing     0 · subagent files     0 · unclassified .jsonl 0 · unclassified skill calls 0 · audit logs 0
store floor 2026-03-17T15:20:50 · until 2026-11-13T21:42:22 · sessions by store {'cli': 1549, 'agent-mode': 209}
```

Arms, at authoring:

```text
sensitivity strata (store-wide, every channel of every class that holds sessions):
  agent-mode | ch1       81
  agent-mode | ch2       1
  agent-mode | ch3       58
  cli | ch1              484
  cli | ch2              179
  cli | ch3              591
control `release-hub` (in window, errors excluded): 434
specificity — nonce-located census transcript files: 1 · raw subject mentions in them: 189 · subject events in them: 0
```

Per subject, at authoring (window counts are in-window sessions; channel counts exclude errored calls):

```text
pmo-business-analyst            registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-knowledge-manager           registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 2 ch2 1 ch3 0 total 3 · errors 0 · pre-registration 0 · residue 0 · origin {'claude-desktop': 3} · CLEAN
pmo-ocm-lead                    registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 2 ch2 1 ch3 0 total 3 · errors 0 · pre-registration 0 · residue 0 · origin {'claude-desktop': 3} · CLEAN
pmo-portfolio-manager           registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-product-owner               registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 14 ch2 0 ch3 4 total 18 · errors 0 · pre-registration 0 · residue 1 · origin {'claude-desktop': 18} · INDETERMINATE: invoked_skills residue 1
pmo-program-coordinator         registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-program-manager             registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 1 ch3 0 total 1 · errors 0 · pre-registration 0 · residue 0 · origin {'claude-desktop': 1} · CLEAN
pmo-project-manager             registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-release-train-engineer      registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-scrum-master                registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-technical-program-manager   registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 1 ch3 0 total 1 · errors 0 · pre-registration 0 · residue 0 · origin {'claude-desktop': 1} · CLEAN
pmo-tier-1-support              registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-tier-2-support              registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-wms-specialist              registered 2026-07-02 · window from 2026-07-02 · in-window sessions {'cli': 1514} · listed {'cli': 1247} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-architect                   registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 8 ch2 2 ch3 0 total 10 · errors 0 · pre-registration 0 · residue 0 · origin {'claude-desktop': 10} · CLEAN
pmo-data-engineer               registered 2026-08-08 · window from 2026-08-08 · in-window sessions {'cli': 1342} · listed {'cli': 1308} · no-record {'cli': 21} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-devops-sre                  registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-principal-engineer          registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 2 ch2 3 ch3 0 total 5 · errors 0 · pre-registration 0 · residue 0 · origin {'claude-desktop': 5} · CLEAN
pmo-qa-lead                     registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-release-manager             registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 4 ch3 0 total 4 · errors 0 · pre-registration 0 · residue 0 · origin {'claude-desktop': 4} · CLEAN
pmo-software-engineer           registered 2026-06-21 · window from 2026-06-21 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
pmo-skill-router                registered 2026-06-23 · window from 2026-06-23 · in-window sessions {'cli': 1549} · listed {'cli': 1513} · no-record {'cli': 23} · ch1 0 ch2 0 ch3 0 total 0 · errors 0 · pre-registration 0 · residue 0 · origin {} · CLEAN
```

### Activation

Only the release train engineer carries a methodology-conditional activation gate. At authoring it reads `DORMANT`: the tracked default and the individual operator config both read, and neither names SAFe or Custom. The program and project rungs are outside a platform session's read set; the operator answered them at the Stage-5 lock — no SAFe configuration today, which may change.

### Listing finding

Read from the census's own listing records, at authoring:

```text
days with listings 153 · sessions with a listing record 1567 · described entries per listing (min, median, max) [13, 42, 135]
described if used in the prior 14 days: 28281/33346 (84.8%) · described if not used: 36947/196773 (18.8%)
pmo-business-analyst            described 39, name-only 1474, not-listed 13
pmo-knowledge-manager           described 497, name-only 1016, not-listed 13
pmo-ocm-lead                    described 162, name-only 1351, not-listed 13
pmo-portfolio-manager           described 28, name-only 1485, not-listed 13
pmo-product-owner               described 1446, name-only 67, not-listed 13
pmo-program-coordinator         described 17, name-only 1496, not-listed 13
pmo-program-manager             described 26, name-only 1487, not-listed 13
pmo-project-manager             described 1, name-only 1512, not-listed 13
pmo-release-train-engineer      name-only 1513, not-listed 13
pmo-scrum-master                described 320, name-only 1193, not-listed 13
pmo-technical-program-manager   described 232, name-only 1281, not-listed 13
pmo-tier-1-support              name-only 1513, not-listed 13
pmo-tier-2-support              name-only 1513, not-listed 13
pmo-wms-specialist              name-only 1247, not-listed 244
pmo-architect                   described 1431, name-only 82, not-listed 13
pmo-data-engineer               described 2, name-only 1306, not-listed 13
pmo-devops-sre                  described 39, name-only 1474, not-listed 13
pmo-principal-engineer          described 805, name-only 708, not-listed 13
pmo-qa-lead                     name-only 1513, not-listed 13
pmo-release-manager             described 419, name-only 1094, not-listed 13
pmo-software-engineer           name-only 1513, not-listed 13
pmo-skill-router                described 11, name-only 1502, not-listed 13
```

- **Two or more days:** the listing records span 153 UTC days at authoring, so the comparison is not a single session's rendering.
- **No-record sessions kept apart:** sessions with no listing record are counted per subject, never read as "not listed".
- **Description changes inside a window:** the full run's per-subject description comparison reads 7 changed and 0 INDETERMINATE: `pmo-business-analyst`, `pmo-portfolio-manager`, `pmo-program-manager`, `pmo-project-manager`, `pmo-technical-program-manager`, `pmo-architect`, `pmo-release-manager`. Three of them are rows here — the business analyst, the portfolio manager and the project manager. Their tallies span the change, because the locked procedure does not split a tally at a change date. The specification asks that render forms be compared only after such a change; with no split available, the record names each change instead, and the per-subject render counts for those rows mix both descriptions. The `--since 2026-10-15T23:59:59` control reads 0 changed, so no description changed after that date.
- **Mechanism, labelled `[INFERRED]`:** a listing entry renders with its description 28281/33346 (84.8%) of the time when the skill was used in the prior 14 days, and 36947/196773 (18.8%) of the time when it was not. That is an association, not a measured cause: it is consistent with a listing that renders descriptions for recently used skills and names the rest. It is not Specialist-specific — function-skills split the same way. **Consequence:** a re-trigger that edits only `description:` may not reach an operator while the skill stays unused, so every re-trigger row, recommended values included, carries that note.

### Collisions

Check 67, at authoring: 0 ESCALATE and 0 WATCH over 1540 pairs; the highest J is 0.188. The body-level read (`collisions --head`) returns 51 rows at authoring; each counted row was read back to its source lines, and only phrases on a skill's own trigger lines count (§ Decision › Readings). The readiness case — a go-live readiness ask reaching the change-management function-skill and the OCM lead with different readiness rules — sits between two skills that are not rows here: the OCM lead reads 3 invocations at authoring.

### Persona-card map

| Card role | Stages | Subject holding the role | At total 0? | R3 covers read |
|---|---|---|---|---|
| Software Engineer | 6 | `pmo-software-engineer` | yes | Stage 6 named |
| QA Lead | 7, 8 | `pmo-qa-lead` | yes | Stage 7 named |
| Release Manager | 4, 12, 13 | `pmo-release-manager` | no | — |
| Principal Engineer | 5, adversarial review | `pmo-principal-engineer` | no | — |
| Portfolio Manager | 2, 3, 9 | `pmo-portfolio-manager` | yes | none named |

### The router

At authoring the router reads total 0 with a CLEAN verdict. Its own `SKILL.md` states 19 role Specialists (13 operations, 6 release) and 43 catalogued items, where the registry states 21 (14 operations, 7 release) and 55; its routing view is read live, so the counts are stale prose, not a stale view.

### Pre-counts and neighbours

Referencing sites per row at the census head, in the four classes (`live` is everything outside the release history and the packages), at authoring:

```text
_control-absent                 all=0 history=0 artifacts=0 live=0
pmo-business-analyst            all=22 history=12 artifacts=1 live=9
pmo-data-engineer               all=13 history=5 artifacts=1 live=7
pmo-devops-sre                  all=28 history=15 artifacts=1 live=12
pmo-portfolio-manager           all=29 history=13 artifacts=1 live=15
pmo-program-coordinator         all=27 history=13 artifacts=1 live=13
pmo-project-manager             all=25 history=13 artifacts=1 live=11
pmo-qa-lead                     all=35 history=17 artifacts=1 live=17
pmo-release-train-engineer      all=25 history=9 artifacts=1 live=15
pmo-scrum-master                all=26 history=10 artifacts=1 live=15
pmo-skill-router                all=22 history=6 artifacts=1 live=15
pmo-software-engineer           all=23 history=10 artifacts=1 live=12
pmo-tier-1-support              all=21 history=7 artifacts=1 live=13
pmo-tier-2-support              all=23 history=10 artifacts=1 live=12
pmo-wms-specialist              all=11 history=4 artifacts=1 live=6
```

Neighbour counts (the rows' `DEPENDS_ON` targets), store-wide at authoring:

```text
artifact-generator       ch1 0 ch2 0 ch3 0 total 0 errors 0
build-reviewer           ch1 0 ch2 2 ch3 0 total 2 errors 0
change-management        ch1 4 ch2 0 ch3 1 total 5 errors 0
daily-status             ch1 1 ch2 0 ch3 0 total 1 errors 0
delivery-engine          ch1 7 ch2 1 ch3 4 total 12 errors 0
file-router              ch1 7 ch2 0 ch3 2 total 9 errors 0
implementation-planner   ch1 0 ch2 0 ch3 0 total 0 errors 0
intake-desk              ch1 77 ch2 14 ch3 26 total 117 errors 0
pmo-knowledge-manager    ch1 2 ch2 1 ch3 0 total 3 errors 0
pmo-principal-engineer   ch1 2 ch2 3 ch3 0 total 5 errors 0
pmo-process-designer     ch1 0 ch2 4 ch3 0 total 4 errors 0
pmo-qa-auditor           ch1 4 ch2 44 ch3 0 total 48 errors 0
pmo-technical-analyst    ch1 1 ch2 5 ch3 0 total 6 errors 0
ppm-agent                ch1 53 ch2 0 ch3 70 total 123 errors 0
release-executor         ch1 3 ch2 2 ch3 8 total 13 errors 0
release-planner          ch1 17 ch2 4 ch3 18 total 39 errors 0
tracker-manager          ch1 3 ch2 0 ch3 0 total 3 errors 0
weekly-status-rollup     ch1 13 ch2 0 ch3 0 total 13 errors 0
```

### Limitations

- **The verdict's sensitivity arms are store-wide,** not windowed per subject: a stratum counts events from any time up to `--until`. Every row's listed class here (`cli`) holds events in all three channels, but the arm does not prove each window.
- **`unclassified_skill_calls` covers nested files only:** a file outside a `projects` path segment is counted in `unclassified_jsonl` and never read. Every class reads 0 of both at authoring, and the run used no extra root.
- **A subagent event's origin is read from the subagent file,** which can read `absent` where the parent session has an origin.
- **Neighbour counts are store-wide,** not windowed to the subject being weighed.
- **One machine's stores.** Use on another machine, or in a store the vendor-default pattern does not match, is not counted.


## Future State

Once the dispositions are ratified and their follow-ups land, a goal-shaped ask reaches the role expertise built for it, or the platform has decided deliberately that no Specialist answers it. The asks below are authored archetypes, not operator prompts.

| Archetype ask | What it should reach |
|---|---|
| "Get this approved plan built and opened as a PR." | the Stage-6 engineering Specialist, invoked from the Stage-6 persona card rather than by a general-purpose persona |
| "Is this release's testing good enough to gate on?" | the QA-leadership Specialist from the Stage-7 card, composing the QA auditor |
| "Which of our projects should get the next dollar?" | a portfolio-level call, from the portfolio Specialist or from the skills it composes, whichever D-Ratify keeps |
| "Make sure today's status and the trackers agree." | the coordination Specialist, or the tracker and status skills directly, as ratified |
| "Are we ready to go live?" | one readiness rule, not two: the collision named in the readiness case resolved by the follow-up |
| "Why did this break, and how do we stop it happening again?" | the escalation support Specialist, reached by its own trigger lines rather than by the first-line Specialist's comparison table |
| "Is this load right, and can we replay it safely?" | the data-engineering Specialist |
| "Run the deploy now that we are a go." | one owner for deploy execution, with the decision-versus-execution boundary either kept with distinct triggers or folded into the release manager |
| "I don't know which skill does this — help me ask." | the router, re-triggered with current counts, or nothing, if D-Ratify retires it |
| "Help us run PI planning." | the release train engineer, once a SAFe configuration activates it; until then, nothing |

## Gap Map

| # | Gap | Current | Future | Rows | Where closed |
|---|---|---|---|---|---|
| G1 | Goal-shaped triggers | role-vocabulary triggers; a re-trigger follow-up per row | goal-shaped trigger phrases, collisions named and resolved | every re-trigger row and every `[ASSUMPTION – CONFIRM]` row whose recommended value is re-trigger | each row's follow-up, through `pmo-skill-editor`, gated by Check 67 |
| G2 | Listing exposure | a skill not used in the prior 14 days renders described in a small minority of listings, a recently used one in most | descriptions render whether or not a skill was used recently, or the re-trigger plan accounts for it | every re-trigger row (recommended values included) | a listing follow-up; until then each re-trigger row carries the note |
| G3 | Persona-card seam | the Stage-6 and Stage-7 cards name a reference workflow and an auditor mode; no card invokes a Specialist | each card a Specialist covers names it as its skill invocation reference | the software-engineer and QA-lead rows | the persona-card follow-up |
| G4 | Write-scope and role comparators | a tier phrase on fewer than half of the Specialist rows at authoring, and no emission artifact read | a stated emission artifact and a role tier on every Specialist row, so R4a decides | every tie row | a registry follow-up; it would let a later census decide these rows mechanically |
| G5 | Router currency | self-counts behind the registry | counts read from the registry, never restated | the router row | the router row's follow-up |
| G6 | Readiness collision | one goal phrase reaches two skills with different readiness rules | one readiness rule per ask | the project-manager and devops rows (overlaps with the release manager), and the used OCM lead, which is not a row | the collision follow-up named on those rows |
| G7 | Mechanical census | a fenced procedure re-run by hand | an invocation dimension on the transcript extractor | none — it informs the census, not a row | a follow-up sequenced after the sibling release `release-usage-measured-right` |
| G8 | Agent-mode exposure | agent-mode sessions predate every window, so that class never listed a subject | a later census reads any agent-mode use inside the windows | every row (the R2 qualifier) | the sunset re-run |

## References

- #8452 — this decision spike: the census, one disposition per never-invoked Specialist and the router, the listing finding, and the current state, future state and gaps.
- #8540 — the parent epic: a goal-shaped ask reaches the review or role expertise built for it.
- #8451 — the reader-and-practitioner review card in the next slice, whose host this table may move.
- #8304 — the document consistency check, composed with the card above into the next slice.
- #8818 — the study-and-design Specialists card, which names the router as a method for reaching new capabilities and two used Specialists as candidate hosts.
- #8896 — the Stage-4 planning sub-task: the plan and the operator's Stage-4 decisions.
- #8930 — the Stage-5 Solutioning sub-task: the locked specification and the operator's lock with its amendments.
- #8982 — the Stage-5 adversarial design review, the source of each lock amendment.
- #8932 — the Stage-6 Engineering sub-task under which this record was authored.
