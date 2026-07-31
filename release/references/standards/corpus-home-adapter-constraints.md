---
title: Corpus-Home Adapter — Path-Resolution Constraints
purpose: Records the constraints any future corpus-home adapter MUST honour when it makes release/tools/automated-closeout.sh --check-paths instance-aware — chiefly that instance-absence resolves to N/A (exit 0), never HARD-FAIL, because --check-paths is a required CI smoke gate that would otherwise redden on every PR from a fresh clone or CI runner. Constraint record only — defines no adapter, no config selector, and no resolution logic.
type: standard
status: ACTIVE
consumers: "the corpus-home adapter design (the future seam that makes corpus-path resolution instance-aware); release/tools/automated-closeout.sh check_paths() (the function the seam must edit); release/tools/tests/test_corpus_home_tolerance.sh (the executable assertion of CH-1..CH-4); .github/workflows/release-tooling-smoke.yml closeout-smoke (the gate that reddens on violation)"
composes_with: [release-corpus-schema.md, ../../../core/standards/repo-host-adapter-versioning.md, ../../../core/standards/public-repo-vs-operator-instance-taxonomy.md, ../../../core/standards/gate-efficacy-standard.md]
reversibility: CHEAP / Confidence HIGH — a constraint record plus its executable assertion; git revert restores prior state. The document adds no runtime surface of its own, and no adapter implements it yet, so there is no migration to unwind.
---
<!-- reference-durability: allow-link -->

# Corpus-Home Adapter — Path-Resolution Constraints

> Reversibility: CHEAP / Confidence: HIGH.
> **Status: anticipatory.** No corpus-home adapter exists. `operator.toml [adapters]` ships four selectors (`repo_host`, `ticketing`, `kb`, `ai_tool`) and **no `corpus_home`** — and this document creates none. It records the constraints the seam must honour *when someone builds it*, so the constraint does not have to be rediscovered by a reddened required gate.

## 1. Why this exists

The release corpus — `RELEASE_LOG.md`, `RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, and the notes directory — is **in-tree today**. `release/tools/automated-closeout.sh --check-paths` resolves all four off `$REPO_ROOT` and HARD-FAILs (exit 1) if any does not resolve. That probe is wired as a **required step of the `closeout-smoke` CI job**, which triggers on every PR touching `release/tools/**`.

When the corpus home becomes configurable — the seam the corpus-home adapter design owns — the naive resolver is to resolve the four paths under the operator instance and fail when they are not found. On the operator's own machine that resolver passes. **On a fresh clone, on a CI runner, and in any environment with no operator instance, it fails** — reddening a required gate on every PR, for a condition that is not a defect.

The cost asymmetry is the whole argument. Recording the constraint now is one document. Discovering it later means a required gate is red on every PR in the repository, at the moment the adapter lands, with the fix competing against the pressure to disable the gate. Gates that are disabled to unblock a merge do not come back.

**This document defines no adapter and no selector.** It states a property that a future resolver must satisfy, and it ships with an executable assertion of that property (§5) so the constraint cannot be silently violated.

## 2. Scope

**Applies to:** any change that makes corpus-path resolution in `release/tools/automated-closeout.sh` (or a successor tool that owns the same probe) dependent on an operator-instance path, an adapter-selected corpus home, or any other resolution root that is not guaranteed to exist in every checkout.

**Does not apply:** while the corpus is in-tree. Today's in-tree resolution is conformant by construction — `$REPO_ROOT` always exists.

**Does not govern:** *where* the corpus should live, *whether* the corpus should move, or the adapter's configuration surface. Those are the corpus-home adapter design's decisions. This document constrains only how the resolver must behave once that decision is made.

## 3. The constraints (normative)

| ID | Constraint | Asserted by |
|---|---|---|
| **CH-1** | When corpus-path resolution is instance-aware **and the instance-corpus root is absent**, `--check-paths` MUST record **N/A** and **exit 0** — never HARD-FAIL. | Fixture **B** (rule R3) |
| **CH-2** | When the instance-corpus root **is present**, `--check-paths` MUST resolve all four corpus paths through the active corpus home and **exit 0**. | Fixture **A** (rules R3/R5) |
| **CH-3** | `--check-paths` MUST still **exit non-zero** on a genuine resolution defect when the corpus **is** present — under **any** corpus home. | Fixtures **C** + **D** (rules R1/R2) |
| **CH-4** | The N/A outcome MUST be emitted as a **distinguishable per-path record**, never an undifferentiated `OK`, so an unresolved path cannot be read as a resolved one. | Fixture **B** stdout (rule R4) |

> **These IDs are load-bearing.** `release/tools/tests/test_corpus_home_tolerance.sh` rule **R6** greps this file for each of `CH-1`..`CH-4` and fails if the file is absent or any ID is missing. **Do not renumber them.** Adding `CH-5` is safe; renumbering `CH-1`..`CH-4` breaks the doc↔test binding and reddens the gate.

**CH-2 and CH-1 are a pair, and neither is sufficient alone.** A resolver that returns exit 0 unconditionally satisfies CH-1 (tolerance) while resolving nothing at all. CH-2 forbids that degenerate answer by requiring a *present* instance corpus to actually resolve. **CH-4 closes the remaining hole:** without it, an implementer could satisfy CH-1 by silently downgrading an unresolved path to `OK`, which would defeat CH-3.

## 4. Why N/A and not HARD-FAIL

Two grounds, both already established in the platform — no new vocabulary is invented here.

**(a) The script already owns this idiom.** `automated-closeout.sh` records `N/A` rather than failing when a phase's precondition is legitimately absent — `phase_append_reversions` marks the phase `N/A` on the no-reversion path instead of erroring. "The thing this step operates on does not exist here" is already modelled as N/A, not as failure, inside the very tool this constraint governs. Canonicalizing anything else would fork the script's own vocabulary.

**(b) Absence of an operator instance is a supported state, platform-wide.** `core/deploy/lib-instance-path.sh::pmo_instance_path()` resolves an instance path unconditionally, and consumers treat a non-existent instance root as a legitimate environment rather than an error — the public repo is expected to be clonable and testable with no operator instance present at all. A corpus-path probe that HARD-FAILs on instance-absence would be the only surface asserting the opposite.

**(c) The consequence is a required gate, not a warning.** `--check-paths` gates `closeout-smoke`, which is path-filtered onto `release/tools/**`. A HARD-FAIL-on-absence resolver does not degrade one developer's local run; it reddens CI for everyone touching release tooling, immediately and permanently, until someone edits the workflow.

## 5. How the constraint is enforced

`release/tools/tests/test_corpus_home_tolerance.sh` runs four hermetic fixtures against the real `--check-paths` probe in throwaway temp trees, and grades the **exit-code vector**, not any single fixture.

| Fixture | Repo tree | Instance root | Asserts |
|---|---|---|---|
| **A** | corpus **absent** in-tree | **present**, corpus inside | CH-2 |
| **B** | corpus **absent** in-tree | **absent** | CH-1, CH-4 |
| **C** | corpus in-tree, `RELEASE_LOG.md` **omitted** | not used | CH-3 |
| **D** | corpus in-tree, all four present | not used | CH-3 (baseline) |

Let `a b c d` be the four exit codes. The verdict rules:

```
R1  d != 0                                -> FAIL   in-tree baseline regressed
R2  c == 0                                -> FAIL   probe blind: a broken corpus path no longer fails
R3  a == 0 && b != 0                      -> FAIL   SEAM LANDED, TOLERANCE VIOLATED  (CH-1)
R4  a == 0 && b == 0 && B has no N/A      -> FAIL   tolerance is silent              (CH-4)
R5  a != 0 && b == 0                      -> FAIL   degenerate resolver              (CH-2)
R6  a CH-id claimed by the suite is absent from this file -> FAIL   doc<->test binding broken
    a != 0 && b != 0                      -> PENDING-SEAM      exit 0 + notice
    a == 0 && b == 0 && B has N/A         -> PASS-SEAM-LANDED  exit 0 + retire-notice
```

**The teeth are a divergence rule, not a pass rule — and that is the design.** R1/R2/R5/R6 gate from day one. R3/R4 **arm themselves**: the moment `--check-paths` becomes instance-aware with a HARD-FAIL-on-absence resolver, fixture A starts passing while fixture B still fails, and **the PR that introduced the violation goes red**. There is no cutoff date to set, no flag to flip, and no human who has to remember this document exists.

**Today's posture is `PENDING-SEAM`.** No instance-aware resolution exists, so `a = 1` and `b = 1`, R3/R4 do not fire, and the suite exits 0. It cannot redden a PR before the seam lands.

**Retirement condition — state it plainly, because a dormant branch that is never retired is debt.** When fixtures A and B both pass (`PASS-SEAM-LANDED`), the seam has landed conformantly. At that point the `PENDING-SEAM` branch has no remaining purpose: replace it with a hard `a != 0 || b != 0 -> FAIL`, so the suite gates the tolerance property unconditionally rather than tolerating a regression back to the pre-seam state. The suite prints this instruction itself when it reaches `PASS-SEAM-LANDED`.

## 6. Composition boundary

This standard owns **the constraint** and nothing else. It restates none of the following:

| Concern | Owner |
|---|---|
| The corpus's frontmatter contract | `release-corpus-schema.md` |
| The repo-host adapter's operation interface | `core/standards/repo-host-adapter-versioning.md` |
| What content is public-repo vs operator-instance | `core/standards/public-repo-vs-operator-instance-taxonomy.md` |
| Gate posture / invariant / falsification declarations | `core/standards/gate-efficacy-standard.md` |
| Instance-path resolution | `core/deploy/lib-instance-path.sh` |
| Where the corpus lives and whether it moves | the corpus-home adapter design (not yet written) |

## 7. Cutover

Applies **from this release forward**. There is no retroactive obligation and no backfill: no seam exists, so nothing is currently non-conformant. The first change that makes corpus-path resolution instance-aware is the first change this document binds — and the suite in §5 will tell that change's author, on their own PR, whether they got it right.
