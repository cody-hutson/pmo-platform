---
version: declarations-have-a-firing-surface
date: 2026-08-29
type: note
issues: ["#5825", "#5826"]
pr: "#6353"
links:
  plan: release/releases/plans/declarations-have-a-firing-surface_RELEASE_PLAN.md
  log_anchor: "#declarations-have-a-firing-surface-version-less"
reversibility-tier: MODERATE
themes: ["cluster:governance-enforcement"]
summary: "A written rule could describe exactly when it applies and still have nothing that acts when that moment arrives. Each such rule now names what enforces it, or is recorded as a known gap."
requires_action: false
breaking: false
components: ["gate-efficacy-standard", "bundle-composition-doctrine", "release-hub", "deploy-check-36", "deploy-check-62"]
followups: ["#6394", "#6395", "#6396"]
---

# Governed rules now name what enforces them, or record that nothing does

2026-08-29 · declarations-have-a-firing-surface

A written rule in this platform could describe exactly when it applies and still have nothing that acts when that moment arrives, so whether it ran came down to whether someone happened to remember it, and skipping it left no trace. Each such rule now either names the check that enforces it or is recorded as a known gap carrying the evidence that would close it.

> **Skip the rest** unless you write or rely on the platform's governed procedures.

## Who this affects

- Anyone who writes a governed procedure — a rule that says "when X happens, do Y". Those rules now carry one extra obligation at the moment they are written or changed.
- Anyone who relies on those rules running. Nothing you do changes; what changes is that a rule which quietly stops being enforced now says so.

## What changed for everyone using the platform

- **A rule that says when it applies now has to say what enforces it.** Until now the platform could only track rules phrased as a verdict — "this is correct, that is wrong". A rule phrased as an obligation — "when this happens, do that" — had no way to be tracked at all, so it was simply left out. Both kinds are now tracked the same way. *Why it matters:* the rules most likely to be skipped were exactly the ones the platform had no way to watch, because a rule that tells you to do something only works if something notices when you do not.

- **A rule nobody can enforce yet is written down as a gap rather than quietly dropped.** When there is no check that can enforce a rule, it gets recorded as an open gap that names the evidence which would close it. *Why it matters:* deleting a rule you cannot yet enforce looks tidy and loses the requirement; recording it keeps the requirement and makes the gap countable, so it can be closed later rather than forgotten.

- **A check now notices when a saved note quietly disagrees with the live source it was copied from.** Names, titles, and states that belong to another system should be read fresh each time rather than written down once. A check now spots the copies. *Why it matters:* a copied value looks right long after the thing it was copied from has changed, and it fails silently — the answer is simply wrong, with nothing indicating it.

- **The tool that verifies release plans stopped silently discarding rows.** It was treating certain ordinary words inside a plan's own table as a signal that the row was a heading, and dropping those rows without reporting anything. Across every release plan on record, **23 verification records came back and none were lost**. *Why it matters:* a plan could lose some of the very checks it promised to run and still report that everything passed — the worst shape a verification tool can fail in, because it fails towards looking fine.

- **Release-readiness checks now look at what a bundle depends on, not only at what is in it.** The readiness review confirmed the work already bundled hung together, but never asked what unbundled work it depended on, or whether an older open bundle was waiting on it. *Why it matters:* those are the two questions that catch a release which cannot actually ship in the order it was planned, and neither was being asked.

## Known limits

**This release makes governed rules detectable, not enforced.** That distinction is the honest description of what shipped, and it is stated here rather than left to be discovered:

- Both new checks report rather than block. One is advisory and runs only when the platform is deployed, never as part of the pre-merge checks; the other logs a warning and lets the work through. Neither will stop anything today.
- **Nothing finds a rule that was never recorded in the first place.** The check reads the list of recorded rules and re-verifies each one. It does not go looking through the platform for a rule that was written without being recorded — so a rule that was never added and a rule that was deleted look identical to it. What puts a rule on the list is a person doing the review step, not a computation.
- A check confirms that the named enforcer still exists, not that it still enforces the whole rule. An enforcer carrying half of what it promised still reports clean — which happened live in this very release before it was fixed.
- The evidence a rule is supposed to leave behind is verified by a reviewer, not by a machine. A rule that names no evidence, and a rule whose named evidence is never actually produced, both read exactly like a correct one.
- The tracking reaches only files kept in this repository, so anything stored outside it is out of reach of this particular mechanism.
- Seven such limits are recorded in full alongside the rule itself, for the same reason they are listed here: a mechanism that hides its limits recreates the problem it was built to solve.

Report issues at https://github.com/cody-hutson/pmo-platform/issues with the `cluster: governance-enforcement` label.

## Reversibility

MODERATE / HIGH confidence. A single `git revert -m 1` of the release pull request restores the previous state exactly, and returns the count of tracked rules to what it was. The change is additive text plus three tracking entries and one detector; no stored data changes shape, so nothing needs unwinding. Outcome window: 30 days.

---

### Operator and engineering detail

**A second admission form, not a fourth gate class.** The gate-efficacy standard's class 3 already admitted a prose-declared normative predicate through a verdict limb. It gained an alternative first limb — the obligation limb — routed into the same gate-coverage register and recomputed by the same `deploy.sh --check` Check 62. The scope-boundary heading stays at three classes by construction, so no count cascaded across the version-history rows or the consumers that repeat it. The falsifiable evidence that this was the right home is that **Check 62 required no code change to admit the new form**: its computation was already general over `runner-def:` pointers and indifferent to which limb admitted the row. Three seed rows shipped; the register now resolves seven pointers, verified live.

**The detector shipped in place, claiming no new check number.** ADR-109's deferred `external-target-referent-stored` detector landed as Check 36's sixth drift class rather than as a new check. Its predicate is **declaration-scoped, not content-scoped**, and that is the whole design: a resolved target-side referent is byte-identical to a permitted practice statement quoting the same string, so no content test can separate them. The discriminator is *ownership* — who the value belongs to — which the author records at write time and the detector verifies. The fixture pins an opposite-verdict pair (a seeded stored referent must warn; the one sanctioned stored item must not), because a detector returning the same verdict for both would be asserting nothing, and a third arm asserts the declared class count against the count actually covered, so adding a seventh class without fixturing it fails the suite.

**Two fixes that were not on the original card.** `ADR-162` records the form-not-class decision. Separately, `verify-release-plan.sh` was treating any table row containing `predicate`, `expected`, or `verification method` as a header and consuming it — a silent-drop class the tool's own design notes recorded as rejected in another candidate. Header detection is now positional. Reproduced first with a nine-arm probe (four sensitivity arms dropped, five specificity arms kept), then regression-tested across all 185 release plans: **+23 records recovered, 12 plans gained, zero lost.** A stricter two-token variant was tried and rejected against that same corpus for zeroing five plans whose real headers name only one column. This plan's own two lost rows were restored in their natural vocabulary, so it now serves as its own live regression case.

**One shape contract changed.** A register row admitted through the obligation limb carries a trigger, an act, an explicit note that no verdict is stated for the negation, and a declared observable. Trimmed to its load-bearing parts:

```
| **class 3-O.** <predicate>. **Trigger:** <condition>. **Act:** <what must happen>.
  **No verdict** is stated for the negation, which is why the verdict limb never
  admitted it
| **Runner:** <named runner>, `runner-def: <path>::<anchor>`
| <enforcement surface — e.g. deploy-time, no CI mirror>
| advisory (review-step runner; `required` unavailable per Requirement (b'))
| **Declared observable:** <what the compliant path emits and the bypassing path
  does not> |
```

A named-gap row carries no `runner-def:` pointer at all — an empty enforcing-gate cell is honest, where a pointer aimed at a runner that does not carry the predicate is not. Deleting every pointer to silence the gate is itself flagged: Check 62 reports `NOSET` on a register declaring zero pointers, in every mode.

**Close-out note.** This release closes under the version-less identity mode, so no version key and no tag were claimed. The automated close-out could not run it — the tool validates its `--version` argument against the canonical version grammar before dispatching any phase and exits at that boundary, which is the documented path for this identity mode rather than a fault. The close was produced through the Phase B chore-PR mechanism, and the complete output set was verified on `main`.

For full implementation detail see the RELEASE_LOG entry and the release plan linked from the milestone below.

### References

- Release pull request: https://github.com/cody-hutson/pmo-platform/pull/6353
- Milestone: https://github.com/cody-hutson/pmo-platform/milestone/368
- Closed issues: https://github.com/cody-hutson/pmo-platform/issues/5825 · https://github.com/cody-hutson/pmo-platform/issues/5826
- Follow-ups: https://github.com/cody-hutson/pmo-platform/issues/6394 · https://github.com/cody-hutson/pmo-platform/issues/6395 · https://github.com/cody-hutson/pmo-platform/issues/6396
