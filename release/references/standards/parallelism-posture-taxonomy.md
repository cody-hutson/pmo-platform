<!-- reference-durability: allow-link -->
---
title: Parallelism Posture Taxonomy — Stage 6 Engineering Concurrency
purpose: Names the Stage-6 Engineering concurrency behavior the hub-spoke bridge already encodes (D-C SINGLE serial / D-C OPTION-A parallel-per-branch) as a first-class, plug-and-play posture taxonomy, and adds the per-posture mechanics (hook-execution / commit-attribution / rollback), the multi-chip-safety-class attribute, and the force-push prohibition a prior multi-chip lease-race near-miss requires.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: hub-spoke-bridge.md Procedure 2 (Stage-6 posture dispatch); release-planner SKILL Mode B (D-Concurrency Posture decision); stage-04-planning.md (D-Gate recurring-D); stage-06-engineering.md (default-serial-when-undeclared)
---

# Parallelism Posture Taxonomy — Stage 6 Engineering Concurrency

## Purpose

A Stage-6 Engineering **parallelism posture** is the named concurrency contract that governs how multiple hub-spawned Engineering chips write to a release's branch(es). This taxonomy **names** the behavior the hub-spoke bridge already encodes — D-C SINGLE topology = serial commit/push (`hub-spoke-bridge.md` File-contention boundary rules, the D-C SINGLE row); D-C OPTION-A topology = per-issue-branch parallel commits with contention deferred to PR-merge order — and makes the choice an explicit, plug-and-play Stage-4 `D-Concurrency Posture` decision. It does **not** introduce conditionality from scratch; it gives a vocabulary and a dispatch surface to the conditionality that already exists.

**Default-serial floor.** When `D-Concurrency Posture` is undeclared, the posture is **P0 fully-serial** — the current safe-by-construction guarantee. (default: serial.)

## The multi-chip-safety-class attribute

Every posture declares exactly one `multi-chip-safety-class` from this fixed enum:

| Value | Meaning | Permitted push modes to the shared release branch |
|---|---|---|
| `single-writer-only` | Safe only when exactly one writer touches the branch at a time | fast-forward append (serial) |
| `multi-writer-safe-fast-forward-only` | Safe under N writers because each writes an isolated branch; integration is fast-forward / no-rewind | fast-forward, append-commit |
| `multi-writer-safe-rebase-retry` | Safe under N writers via fetch → rebase → re-push retry on non-fast-forward; NO history rewrite of the shared tip | plain `git push`; on rejection: fetch + rebase + re-push (retry) |

**Force-push / history-rewriting class is named-and-excluded.** No posture in this taxonomy may declare a class that permits `--force`, `--force-with-lease`, or `--force-if-includes` to the shared release branch under multi-chip activity. Rewinding the shared branch tip — even with lease protection — is **prohibited** by construction when N writers race: the root cause is that the lease validates against the operator's last fetch, not the true remote tip, so an N-writer window can close the lease undetected (see the **Failure Modes** section below and `core/standards/failure-mode-standard.md` "Lease-races-multi-chip"). [SOURCE: prior-release Engineering-spoke force-push near-miss — a spoke force-pushed with a stale lease, momentarily rewinding sibling commits that had landed on the shared release branch during its compute window]

### Posture admission rule — validated-by-composition vs. needs-own-evidence

A posture ships as a selectable contract only when it is **validated** — and validation comes from exactly one of two grounds:

1. **Validated-by-composition.** A posture whose mechanism is a strict composition of primitives that already ship safely inherits their validation and needs no independent evidence. Its git operations are a subset of operations the shipped postures already perform safely (a serialized commit/push gate; an isolated per-branch fast-forward merge), so it introduces no novel operation to validate. P1 (serialized-commit-lane) ships on this ground: it is the P0 serialization mechanism applied to parallel-compute chips, integrating fast-forward-only per the P2 safety class — no git operation P0 or P2 do not already perform.
2. **Needs-own-evidence.** A posture that introduces a **novel** mechanism — an integration authority, a write path, or a coordination primitive the shipped postures do not already exercise — must carry its own empirical or structural validation before it ships, and is a `[CALIBRATE-AFTER-N]` extension stub until it does. P4 (commit-broker) is deferred on this ground: a broker is a novel integration authority with no precedent in the shipped set, so it is named for completeness but not shipped.

This single rule settles the ship-vs-stub line for every posture: P1 ships (validated-by-composition), P2 ships (empirically validated by the convergent safe path under real multi-chip contention), P3 ships (constrained, with the no-force rule below), and P4 stubs (needs-own-evidence, none yet).

## Postures

### P0 — Fully Serial (DEFAULT)

- **Trigger conditions:** `D-Concurrency Posture` undeclared (default), OR the release contention map shows heavy file overlap, OR topology = D-C SINGLE with no isolation, OR wave count = 1.
- **Mechanism:** Hub Procedure 2 routes ONE Engineering chip at a time per the release plan's Implementation Sequence; the next chip waits until the prior commit lands on the release branch.
- **Hook-execution semantics:** hooks run per-commit, serially; no concurrency interaction.
- **Commit-attribution semantics:** each commit is attributed to its chip; the shared branch keeps a linear history.
- **Rollback semantics:** `git revert` of any single commit; linear history makes the revert unambiguous.
- **multi-chip-safety-class:** `single-writer-only`
- **Trade-off matrix:** Throughput LOW · Contention-risk NONE · Complexity LOWEST · Blast-radius-if-wrong NONE (this is today's behavior).

### P1 — Serialized Commit Lane

- **Trigger conditions:** D-C SINGLE topology; multiple chips ready; contention map shows file-disjoint work that still shares the branch tip.
- **Mechanism:** chips compute in parallel but **commit through a serialized lane** — a single ordered commit/push gate on the shared branch (one chip holds the lane, pushes, releases; the next acquires). No branch rewind.
- **Hook-execution semantics:** hooks run inside the lane (serialized at commit), so per-commit hooks never race.
- **Commit-attribution semantics:** each chip's commit retains its own author/trailer; the lane only orders the push, it does not rewrite authorship.
- **Rollback semantics:** `git revert` per commit; lane ordering preserves a clean linear history.
- **multi-chip-safety-class:** `multi-writer-safe-fast-forward-only`
- **Force-push:** PROHIBITED incl. `--force-with-lease` on the shared release branch under multi-chip activity (named-and-excluded class).
- **Trade-off matrix:** Throughput LOW-MED (compute parallel, commit serial) · Contention-risk LOW · Complexity LOW · Blast-radius MODERATE (lane coordination is the only new surface).
- **Validation ground:** validated-by-composition (the P0 serialization gate + the P2 fast-forward-only integration; introduces no novel git operation).

### P2 — Per-Sub-Task-Branch Merge-Queue  *(SHIPS FIRST — empirically validated)*

- **Trigger conditions:** D-C OPTION-A topology (per-issue branches) OR convertible-to-per-branch; multiple chips; contention map shows isolable work; wave count ≥ 2.
- **Mechanism:** each chip writes its **own sub-task branch** (never the shared tip); branches enter a **merge-queue** that integrates them one at a time, fast-forward / no-rewind, in dependency order (the Implementation Sequence). This is the convergent safe path observed under real multi-chip contention — a spoke stacked its work on a side branch alongside the release branch rather than rewinding the shared tip. [SOURCE: prior-release multi-chip near-miss — the convergent safe path was a stacked side-branch alongside the release branch]
- **Hook-execution semantics:** per-branch hooks run independently and in parallel on each sub-task branch; integration-time hooks run once per merge-queue step (serialized at the queue).
- **Commit-attribution semantics:** each sub-task branch carries its chip's commits with native authorship; the merge-queue preserves them (merge / fast-forward, no squash-rewrite of authorship).
- **Rollback semantics:** revert a whole sub-task branch's merge (revert the merge commit) OR drop it from the queue before integration; isolation means one branch's rollback does not disturb siblings.
- **multi-chip-safety-class:** `multi-writer-safe-fast-forward-only`
- **Force-push:** PROHIBITED incl. `--force-with-lease` on the shared release branch under multi-chip activity (named-and-excluded class).
- **Trade-off matrix:** Throughput HIGH · Contention-risk LOW (isolation + ordered fast-forward merge) · Complexity MED (queue management) · Blast-radius MODERATE. **Validated:** empirical convergence under real multi-chip contention.
- **Validation ground:** needs-own-evidence — satisfied (empirical convergent-safe-path evidence).

### P3 — Parallel-Push Rebase-Retry  *(constrained option)*

- **Trigger conditions:** D-C SINGLE topology where per-branch isolation is impractical but chips are genuinely concurrent; append-pattern-heavy contention map (ADR-005 `append-pattern` overlap_class).
- **Mechanism:** chips push to the shared branch with **plain `git push`**; on a non-fast-forward rejection, the chip runs **fetch → rebase onto the new tip → re-push**, retrying until the push fast-forwards. **There is NO force-push escape hatch** — `--force`, `--force-with-lease`, and `--force-if-includes` are PROHIBITED on the shared release branch under multi-chip activity (lease protection does not make a rewind safe when N writers race: `--force-with-lease` validates a stale lease against the operator's last fetch, not the true remote tip). [SOURCE: prior-release Engineering-spoke force-push near-miss]
- **Hook-execution semantics:** per-push hooks run on each (re-)push attempt; a rejected push re-runs hooks after the rebase.
- **Commit-attribution semantics:** the rebase replays the chip's own commits onto the new tip, preserving authorship; no authorship rewrite of sibling commits.
- **Rollback semantics:** `git revert` per commit; because no history is rewritten, the shared branch reflog is a faithful audit trail.
- **multi-chip-safety-class:** `multi-writer-safe-rebase-retry`
- **Force-push:** PROHIBITED incl. `--force-with-lease` on the shared release branch under multi-chip activity (named-and-excluded class). The only `--force*` mentions in this posture are these prohibition statements; the retry loop uses plain `git push` + fetch + rebase + re-push.
- **Trade-off matrix:** Throughput MED-HIGH · Contention-risk MED (rebase-retry churn under heavy overlap) · Complexity MED-HIGH (the retry loop) · Blast-radius MODERATE. **Constraint:** safe ONLY with the no-force rule above.
- **Validation ground:** validated-by-composition under its no-force constraint (plain push + the rebase-retry the worktree discipline already performs; no history-rewrite).

### P4 — Commit Broker  *(taxonomy-extension stub — NOT shipped this release)*

- **Status:** **DEFERRED extension point.** Named for completeness; the mechanism is a future slice gated by `[CALIBRATE-AFTER-N]` per the new-posture convention.
- **Intended sketch (non-binding):** a broker process serializes commit *intent* across chips (chips submit patches; the broker applies them in order), decoupling compute-parallelism from a single integration authority.
- **multi-chip-safety-class:** `multi-writer-safe-fast-forward-only` (intended; to be confirmed when built).
- **Force-push:** PROHIBITED incl. `--force-with-lease` on the shared release branch under multi-chip activity (named-and-excluded class) — binding on the eventual build.
- **Trade-off matrix:** TBD at the extension slice. Not selectable until built.
- **Validation ground:** needs-own-evidence — **not yet satisfied** (a broker is a novel integration authority with no precedent in the shipped set); this is why P4 is a stub and not a ship.

## Posture crosswalk (narrative enumeration → posture IDs)

Earlier narrative descriptions of this contention class enumerated the postures as a 1-indexed list (positions 1 through 5). This taxonomy re-anchors them to **P0-indexed** IDs so the default serial posture is the zero/identity posture (matching "default when undeclared"). The crosswalk below maps the narrative list positions onto the canonical IDs so a reader holding the older enumeration can locate each posture here:

| Narrative list position | Canonical ID | Posture name |
|---|---|---|
| no. 1 (fully serial) | **P0** | Fully Serial (DEFAULT) |
| no. 2 (serialized commit lane) | **P1** | Serialized Commit Lane |
| no. 3 (parallel push + rebase) | **P3** | Parallel-Push Rebase-Retry |
| no. 4 (per-sub-task branches + merge queue) | **P2** | Per-Sub-Task-Branch Merge-Queue |
| no. 5 (commit broker) | **P4** | Commit Broker (stub) |

Note the deliberate re-ordering: the empirically-validated **per-sub-task-branch merge-queue** (narrative no. 4) becomes **P2** and ships first, ahead of the parallel-push-rebase posture (narrative no. 3 becomes **P3**), because the merge-queue is the validated convergent safe path and the rebase posture is the more constrained option.

## Posture Selection (Stage-4 D-Concurrency Posture)

A posture is selected at Stage 4 as the `D-Concurrency Posture` decision from four inputs: (1) the release **contention map**, (2) the **ADR-005 overlap_class distribution** (`append-pattern` / `line-range-overlap` / `single-pr`), (3) the **D-C topology** (SINGLE / OPTION-A), and (4) the **wave count**. The decision is **judgment, not rule-determined** — these inputs are advisory signals the planner weighs; the operator ratifies at the D-Gate. There is no deterministic function from inputs to posture: a severe contention map can justify P0 even at OPTION-A topology. Default = **P0** when undeclared. See `release/skills/release-planner/SKILL.md` D-Gate template and the `hub-spoke-bridge.md` Stage-6 posture dispatch.

## Failure Modes

(Per `core/standards/failure-mode-standard.md` 5-field template; ≥3 entries.)

### Lease-races-multi-chip — force-push validates a stale lease — PROC

- **Signature (observable signal):** an Engineering chip runs `git push --force-with-lease` to rewind the shared release branch tip; the push succeeds because the lease validated against the chip's stale local ref, momentarily rewinding sibling commits that landed during the chip's compute window.
- **Conditional:** do NOT use `--force-with-lease` (or any history-rewriting push) to rewind the shared release branch tip when concurrent Engineering chips are active, because the lease validates against the operator's last fetch — not the true remote tip — and an N-writer window can close the lease undetected.
- **Root cause:** `--force-with-lease` provides single-writer safety only; multi-chip activity violates the single-writer premise the lease semantics rely on.
- **Mitigation:** prohibit history-rewriting push under all non-serial postures; route the operation through a sub-task branch + merge-queue (P2) instead — the empirically convergent safe path.
- **Principal response vs. junior response:** the junior reaches for `--force-with-lease` believing the lease makes it safe; the principal recognizes that lease semantics require a single writer and routes to a side branch when N > 1.

### Undeclared-posture-treated-as-parallel — PROC

- **Signature (observable signal):** the hub routes concurrent Engineering chips for a release whose plan declares no `D-Concurrency Posture`.
- **Conditional:** do NOT route concurrent Engineering chips when `D-Concurrency Posture` is undeclared, because the safe-by-construction default is P0 fully-serial and treating undeclared as parallel reintroduces the shared-tip race this taxonomy exists to prevent.
- **Root cause:** the absence of a declared posture is read as "no constraint" rather than "the strictest default".
- **Mitigation:** the hub treats undeclared as P0 (default: serial); posture parallelism is opt-IN, never opt-out.
- **Principal response vs. junior response:** the principal defaults to serial on missing data; the junior assumes parallel is safe because the file sets look disjoint (they still serialize at push under SINGLE topology).

### Safety-class-posture-mismatch — OUT

- **Signature (observable signal):** a posture is declared with a `multi-chip-safety-class` whose permitted push modes contradict the posture's mechanism (e.g., a rebase-retry posture tagged `single-writer-only`, or any posture tagged with a force-push-permitting class).
- **Conditional:** do NOT declare a posture's `multi-chip-safety-class` from a value outside the 3-value enum, nor one whose permitted push modes its mechanism violates, because the safety-class is the load-bearing safety contract and a mismatch silently permits an unsafe push mode.
- **Root cause:** treating the safety-class as a descriptive label rather than an enforceable contract.
- **Mitigation:** map each mechanism to its class per the attribute table; force-push-permitting classes are named-and-excluded — no posture may claim one.
- **Principal response vs. junior response:** the principal derives the class from the mechanism's actual push modes; the junior copies a neighboring posture's class without checking the push-mode implication.

## Cutover

**The introducing release itself is exempt** from this posture protocol — it ships under D-C SINGLE serial and cannot apply its own protocol without a reflexive-pipeline-loop. The protocol applies to releases entering Stage 4 strictly AFTER this protocol's introducing-release merge SHA recorded in the release log. All releases that entered the pipeline prior are also exempt.
