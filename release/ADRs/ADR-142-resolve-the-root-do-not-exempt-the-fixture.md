<!-- reference-durability: allow-link -->
---
title: ADR-142 — Self-test reachability at a destructive-scope boundary is restored by resolving the root, not by exempting the fixture
status: Accepted — ratified by the operator at the v4.39 release close gate (2026-08-28). The flip is recorded in this file's `status:` field, which is where it must be verified — never inferred from milestone closure, from a green close-out, or from a review comment.
date: 2026-08-24
release: selftests-actually-test
deciders: "Workspace owner, at the D8 scope-lock gate. Option set generated and narrowed by the Stage 5 Solutioning spoke (Principal Engineer — Architecture Assessment) against the ADR authoring guide's when-to-write rubric; implemented at Stage 6 Engineering of the same release."
supersedes: none
tags: [architecture, release-tooling, self-test, ci, defense-in-depth, destructive-operations, boundary-guard, selftest-coverage, reversibility-cheap]
source_observations:
  - "The measured defect is REACHABILITY, not hermeticity. `workspace_boundary_check` runs one line before the `--self-test` dispatch in `release/tools/cleanup-orphan-state.sh` and hard-exits 2, so the suite never runs on a runner whose cwd is the checkout rather than the operator workspace. The exclusion entry recorded the observed ubuntu-latest failure verbatim: exit 2 with `outside workspace /home/runner/Claude (defense-in-depth boundary)`."
  - "The excluding entry's own narrative offered two remediations — exempt the hermetic fixture run from the destructive-scope guard, OR resolve the root from the checkout. Both are viable on their face; only one survives evidence."
  - "The exemption option is structurally INSUFFICIENT here. `self_test()` makes 12 inner invocations of the script and 0 of the 12 carry `--self-test`, so a flag-conditioned exemption cannot reach them; they would still exit 2 on a runner. Measured by whole-file scan with a sensitivity control (the literal `--self-test` occurs 9 times elsewhere, so the zero is a real absence, not a dead pattern)."
  - "The exemption option is ALSO wrong on the merits, and this inverts the surface reading of the in-repo precedent. The two sibling tools that implement it justify it as '--self-test is hermetic: no network, no workspace, no gh'. That premise is FALSE for this tool: its self-test creates 9 worktrees and runs `git branch -D`, `git worktree remove --force` and `git push --delete` against a fixture remote. It is the one self-test in the corpus that performs real destructive git operations — precisely the case the guard exists for."
  - "The card's own stated mechanism was falsified before design. The issue body claimed the suite's assertions 'depend on ambient workspace state (worktrees, branches) rather than on a fixture it constructs and tears down'. All 9 `git worktree add` sites build under the repo's own worktrees directory and tear down on every exit path; the fixture is already net-zero. A spoke following the body literally would have built a fixture rewrite that does not fix the defect."
  - "The prefix match was independently defective in all three mirror implementations: `case \"$cwd\" in \"$ROOT\"*)` also matches a SIBLING directory whose name merely extends the root. Adding a second accepting arm would have doubled that surface, so both arms are separator-anchored in this tool as part of the same change."
  - "Physical-path resolution is load-bearing on the new arm. The guard compares against `pwd -P`, while the pre-existing `REPO_ROOT` is built with logical `pwd`; behind a symlinked checkout a logical comparison silently fails to match. The file already documents the hazard at its own `physical_path()` helper (macOS /tmp → /private/tmp), but that helper is defined too late in the file to be callable at the assignment site."
  - "A second, undeclared blocker sat behind the guard: `selftest_gh_bin_resolves` ran a live authenticated `gh pr list --repo \"$REPO_SLUG\"` and failed the fixture on ANY non-zero exit, including auth failure. On CI `REPO_SLUG` falls through to the bare literal `pmo-platform` with no owner, so that query fails even with a token. Fixing the guard alone could not have greened the suite."
---

# ADR-142 — Self-test reachability at a destructive-scope boundary is restored by resolving the root, not by exempting the fixture

## Status

**Accepted** — ratified by the operator at the v4.39 release close gate on 2026-08-28. The flip is recorded in this file's frontmatter `status:` field, which is where it must be verified. A green close-out does not imply the flip landed.

**Numbering.** `142` is the next-free number derived across **both** record directories (`core/ADRs/` and `release/ADRs/`) via the `release/tools/renumber-adr.py --next-free` oracle, run at Stage 6 authoring time. Stage 5 deliberately declined to pin a number at design time: a number reserved at design and merged later is a reservation hazard against a sibling's unmerged claim, and a numbering gap blocks the repo while a duplicate is tooled. The design's own provisional guess would have collided with an already-committed `ADR-141` in the sibling directory — which is the concrete reason the oracle, not inspection, is the authority.

## Context

`release/tools/cleanup-orphan-state.sh` carries a `--self-test` suite of 16 checks. The suite was excluded from the platform's self-test coverage gate under an F4 "non-hermetic" classification, making it the last in-scope suppression in that gate — a real self-test taken out of enforcement, kept visible by a standing `::warning::` on every run.

The stated reason was that the suite "cannot reach a verdict on a CI runner". The measured cause is narrower and more specific than "non-hermetic": the tool's **defense-in-depth boundary guard** runs immediately *before* the `--self-test` dispatch and hard-exits 2 whenever the current directory is outside `WORKSPACE_ROOT`. On a CI runner the checkout lives at the runner's work directory while `WORKSPACE_ROOT` resolves to a home-relative default that does not exist. The suite is therefore **unreachable**, not unstable.

That guard is not incidental. This tool's apply path executes `git branch -D`, `git worktree remove --force`, and `git push --delete`. The guard is the barrier that keeps those operations from running against an unintended tree. Two sibling tools (`audit-epic-rollup-close.sh`, `automated-closeout.sh`) carry a byte-identical copy of the same predicate, and **both** resolve the same reachability tension the opposite way: they dispatch `--self-test` *before* their guard, treating the fixture run as exempt. That 2-of-3 pattern is the established in-repo convention, and it is what makes this decision worth recording — an unrecorded divergence from a visible convention gets "fixed" back by the next reader.

## Decision

**Widen the boundary predicate to accept the script's own physical checkout root as a SECOND accepted root, additively — and retain the guard-before-dispatch ordering.**

Concretely:

1. A physically-resolved sibling of the existing repo root (`REPO_ROOT_PHYS`, built with `pwd -P`) is introduced and consumed **only** by the guard. The pre-existing logical `REPO_ROOT` is left byte-identical so no existing consumer moves.
2. The guard accepts `WORKSPACE_ROOT` **or** `REPO_ROOT_PHYS`. The second arm is strictly **additive**: no invocation accepted before this change can now be rejected, so the Stage-13 close-out invocation and every operator path are unaffected by construction. It admits no unrelated clone either, because `REPO_ROOT_PHYS` derives from `$0` rather than from the environment.
3. Both arms are **separator-anchored** — matching the root exactly or the root followed by `/` — closing a pre-existing defect where a sibling directory whose name merely extended the root was accepted.
4. The guard **still runs before** the `--self-test` dispatch. This is the deliberate divergence from the two sibling tools, and it is recorded in the code at the dispatch site as well as here.

The ordering is retained because the siblings' exemption rests on a hermeticity premise that is **false for this tool**. Their self-tests perform no destructive git operations; this one performs several. Exempting it would remove the only barrier on exactly the case the barrier exists for, and — because 12 of its 12 inner self-invocations carry no `--self-test` flag — the exemption would not even work: those invocations would continue to exit 2.

Two changes travel with the decision because the outcome is unreachable without them:

- **The credential-bearing assertion is split from the hermetic one.** The subject of the `gh` fixture is binary *reachability* under a pinned `PATH` — that a bare `gh` would exit 127. `"$GH_BIN" --version` asserts exactly that, unconditionally, with no network and no credential. The live `pr list` query is retained but **conditionally armed**, requiring both a present credential and a `REPO_SLUG` that actually carries `owner/name`; when unarmed it is reported `SKIPPED` with its reason, never silently dropped.
- **A SKIP ledger is emitted before the terminal verdict.** Several checks legitimately skip on a shallow checkout that lacks the `origin/main` remote-tracking ref. Without a ledger, a run that exercised a fraction of the suite is indistinguishable in a CI log from one that exercised all of it — the same silent-pass failure class this gate exists to eliminate, one level up.

## Alternatives Considered

Seven candidates were generated; five were eliminated on evidence before the trade-off matrix.

| # | Alternative | Why rejected |
|---|---|---|
| 1 | **Exempt `--self-test` from the guard by dispatching first** (the 2-of-3 sibling precedent) | Rejected on two independent grounds. **Insufficient:** 12 of 12 inner self-invocations carry no `--self-test`, so a flag-conditioned exemption structurally cannot reach them. **Wrong on the merits:** the precedent's stated hermeticity premise is false here — this is the one self-test in the corpus performing real destructive git operations, so the exemption strips the guard from precisely the case it guards. |
| 2 | Exempt via an exported environment marker, so the inner invocations inherit it | A guard-disabling environment variable on a tool whose apply path runs `git branch -D`, `git worktree remove --force` and `git push --delete`. Any caller could set it. Security regression. |
| 3 | **Replace** `WORKSPACE_ROOT` with the repo root in the predicate | Regresses the operator path: invoking from `WORKSPACE_ROOT` but outside the repo passes today and would begin exiting 2. Also leaves the depersonalization spec describing a variable the guard no longer honors. |
| 4 | Declare the tool macOS-only via a `# selftest-runner:` declaration | A false claim — the exclusion entry's own measurement records that the failure is not OS-bound and the macOS runner fails identically. Because the runner partition is disjoint, the declaration would move the tool **off** ubuntu rather than onto both. |
| 5 | Export `WORKSPACE_ROOT` in the CI workflow step | Forbidden by the coverage engine's own design rule — the runner declaration lives at the tool, not in the workflow, because putting per-tool environment facts in YAML re-creates the roster the gate replaced. |
| 6 | Retain the exclusion (do nothing) | It is the defect. It leaves the gate's last in-scope suppression standing. |
| 7 | Rewrite the ambient-dependent checks against a constructed fixture repository | Correct in the long run and explicitly **not** rejected on merit — deferred as out of scope. It is a substantially larger rewrite of the fixture code, and the SKIP ledger this change ships is what sizes it properly. Routed as a follow-on rather than folded in. |

## Consequences

**Positive.**

- The suite becomes reachable on a runner, and the tool leaves the exclusions file — retiring the last in-scope suppression in the self-test coverage gate. The gate acquires real authority over this tool: its `--self-test` can now redden a pull request on a regression, where previously it could not.
- The destructive-scope guard is **retained** on the one path in the corpus that genuinely needs it. Reachability and defense-in-depth are both preserved rather than traded against each other.
- A latent prefix-matching defect is closed in this tool: a sibling directory whose name merely extended the accepted root no longer passes.
- The `gh` fixture loses a network-and-credential coupling it never needed to assert its actual subject, so an unauthenticated runner no longer fails it.
- A shallow-but-green run is now distinguishable from a complete-green one.

**Negative, and accepted.**

- This tool now **diverges** from its two sibling guard implementations on dispatch ordering. That divergence is the reason this record exists; without it the next reader restores the convention and reopens the defect. The siblings keep their exemptions, correctly — their hermeticity premise does hold.
- The separator anchoring is a behavior **tightening**. The only invocation that stops working is one that was passing through the bug.
- The prefix defect remains in the two mirror implementations, which are outside this change's declared files and are not broken today. Sweeping them is routed as separate work.
- The SKIP ledger reports the skips; it does not eliminate them. Several checks still depend on ambient state under a shallow checkout. The ledger is deliberately the cheaper half of that problem, and it produces the evidence the expensive half needs.

## Reversibility

**CHEAP · Confidence HIGH.** Single-commit revert across three files plus this record. No schema change, no data migration, no governance-file edit, and no path move. The `WORKSPACE_ROOT` resolution cascade is untouched byte-for-byte — this decision changes what the boundary *accepts*, never how the workspace root is *resolved*, and that distinction is what keeps the depersonalization spec's contract intact.

## Related ADRs

- **ADR-119** — *Self-test coverage is discovered with a committed manifest floor.* Defines the gate this tool now enters; the committed manifest row that had to be regenerated is that floor.
- **ADR-135** — *A gate ships armed by a committed default.* Same posture applied here: the suite is enforced by default rather than left opt-in behind a suppression.
- **ADR-062** — Governs leaving the issue body as historical record. The card's falsified mechanism narrative was corrected in the design record rather than by amending the body.
