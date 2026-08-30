---
version: one-system-of-record-per-element
date: 2026-08-29
type: note
issues: ["#5837", "#5839", "#5844", "#5846"]
pr: "#6393"
links:
  plan: release/releases/plans/_unversioned/one-system-of-record-per-element_RELEASE_PLAN.md
  log_anchor: "#one-system-of-record-per-element-version-less"
reversibility-tier: MODERATE
themes: ["cluster:templates-schemas", "cluster:knowledge-architecture"]
summary: "Three rules gave three answers about which copy of a shared value wins. Now there is one: the system the value was written in wins."
requires_action: false
breaking: false
components: ["entity-field-schemas", "project-schema", "portfolio-writeback-contract", "health-check", "tracker-manager", "ppm-agent", "file-router"]
followups: ["#6355"]
---

# Every shared value now has one system of record

2026-08-29 · one-system-of-record-per-element

When the same value lives both in this platform and in a system it reads from, three separate platform rules used to give three different answers about which copy wins — and none of them referred to the others. There is now one rule, and a project's health colour has a real home instead of being published out of a field that could never hold it.

> **Skip the rest** unless you work with data this platform copies from another system, or you read project health in the portfolio view.

## Who this affects

- Anyone whose projects mirror work items, risks, or issues from another system — Jira, Confluence, Smartsheet, SharePoint, Google Drive, or GitHub. Nothing you do changes; what changes is which copy the platform treats as correct when the two disagree.
- Anyone who reads or publishes project health in the portfolio view. The colour now comes from a recorded, dated value instead of an unnamed derivation.

## What changed for everyone using the platform

- **One answer for which copy of a shared value wins.** When a value exists both here and in a system this platform reads from, the system the value was *written in* is the one that wins on disagreement. *Why it matters:* three separate rules used to answer that question differently and none of them cited the others, so the same disagreement could be settled in opposite directions depending on which rule a reader happened to open first.

- **"Which copy wins" and "which copy we may edit" are now separate questions.** They used to share one phrase, sometimes inside a single sentence. They are now named apart: one decides authority, the other decides what this platform is allowed to write. *Why it matters:* the old wording made rules look like they contradicted each other when they were quietly answering different questions, so reconciling them meant guessing which one an author meant.

- **A copied record can now say where it came from.** Records mirrored from another system can record which system authored them, the key they hold over there, and when the copy was last refreshed. *Why it matters:* a copy that never says what it is a copy of cannot be checked against the original or refreshed on purpose — and a link back to the original can now be built from what is recorded rather than pasted in once and left to go stale.

- **Project health colour now comes from somewhere real.** The portfolio view published a red, yellow, or green colour per project by reading a field that only ever holds lifecycle states such as active or closed. Projects now carry a health field of their own, and the portfolio view reads that. *Why it matters:* until now the platform published a health colour with no recorded source, so nobody reading it could tell where it came from or check whether it was right.

- **That colour is worked out, not typed in.** The health value is a computed roll-up of the signals beneath it, and it is dated. *Why it matters:* a colour anyone can set by hand is exactly how a project comes to report green over a component that is red, and a value with no date cannot be told from one that went stale months ago.

- **A project's folder name and its identifier are now formally different things.** The identifier is the only key anything joins on; the folder name is a display label that is never converted into one. *Why it matters:* renaming a project folder to read better no longer risks quietly breaking whatever pointed at that project.

## Known limits

- **The rule is written down and cited; it is not yet machine-enforced.** Four governance surfaces now point at one decision record instead of contradicting each other, but nothing scans records at rest to confirm they obey it. A record that names the wrong authority still reads as correct.
- **Recording where a copy came from is optional, and most records will not carry it.** The fields are available to the two record types that adopt them, not required of them. A record with none of them is a normal, correct record — so their absence never signals a problem, and their presence is the only signal available.
- **The portfolio view still shows one health colour under five different labels.** This release gave the colour a real source; it did not fix the display that repeats that single value across five separate dimension rows, so a reader still cannot tell which dimension is dragging a project down. That defect is tracked separately at https://github.com/cody-hutson/pmo-platform/issues/6355.
- **The roll-up rule behind the colour is still written as prose, not as a formula.** The decision records where the value is mastered and that it must be derived; the derivation itself remains described in words, so two readers can still compute it slightly differently.
- **One earlier decision is now partly, not wholly, replaced.** Its remaining decisions stay in force. A reader who assumes the whole record was retired will draw the wrong conclusion from it.

Report issues at https://github.com/cody-hutson/pmo-platform/issues with the `cluster: templates-schemas` label.

## Reversibility

MODERATE / HIGH confidence. A single `git revert -m 1` of the release pull request restores the previous state exactly. Every field this release adds is optional, so no stored record changes shape and nothing needs unwinding or migrating; reverting returns the governance surfaces to their previous — mutually contradictory — wording. Outcome window: 30 days.

---

### Operator and engineering detail

**Authority follows authorship.** The decision generalizes an already-ratified principle rather than inventing one: an existing record decides, for the external-target population, that the target is the sole source of truth for its own facts. Extending that to the operational-mirror population resolves all four disagreeing surfaces without overriding any of them, and — unlike a hand-maintained lookup table of elements — it yields an answer for elements nobody has enumerated yet. A single system-level winner was never available in either direction: naming external systems universally authoritative would assign a system of record to elements the platform alone authors and can never write, since the sync path is read-and-poll only; naming local artifacts universally authoritative would invert a settled decision by fiat. The prior health-check source-set record is **superseded in part** — its first decision only — and remains `Accepted` and in force for the rest. That disposition is carried on the record's own status line, not merely in its body: a full supersession would have exempted a record carrying four live decisions from continuous-integration durability coverage silently, which a three-arm experiment on byte-identical copies confirmed before the shape was chosen.

**One entity-surface amendment, not two.** Both delivery children carried a scope change against the same frozen entity surface. They were batched into a single amendment note with one re-freeze and one authorization, rather than reopening the surface twice — verified at close against a baseline-pinned ceiling measured on the release's own base commit rather than a chosen number. The entity roster stays at 19: the health decision selected a field-list amendment over a roster extension, deliberately, because a sibling card in an unstarted milestone owns a counting assertion over that roster number and a release that moved it would have moved a number another card is concurrently asserting against.

**Two shape contracts changed, both optional in whole.** External identity is defined once and adopted per entity rather than restated per entity. Trimmed to its load-bearing parts:

```yaml
source_system:  enum      # optional; the system that AUTHORS this element.
                          # Value domain referenced from the frontmatter schema,
                          # never restated here.
external_id:    string    # optional; the record's key IN source_system.
                          # Opaque - never parsed. A deep link is RENDERED from
                          # (source_system, external_id) plus connector keys,
                          # never stored.
mirrored_date:  YYYY-MM-DD  # optional; when the local copy was last refreshed.
# V-EXT-02: external_id present => source_system present.
# V-EXT-03: mirrored_date present => external_id present.  One-way, not both:
#           a linkage recorded at intake whose first poll has not run is
#           legitimate, and requiring a date there would force a fabricated one.
```

The project health pair is deliberately asymmetric to the group above: its date rule is a **biconditional**, because an undated derived value cannot be distinguished from a stale one, so either half alone is malformed. The external-identity date rule is one-way for the reason in the comment.

**A dialect projection, not a second field.** The external-sync path contract names the same value `source_adapter` in its poll snapshot. That is a view of the one field, not a separate one — the same relation the RAID identifier already has to the entity identifier — and it is recorded as such so a later reader does not resolve it into a duplicate.

**Close-out note.** This release closes under the version-less identity mode, so no version key and no tag were claimed, and no public release page was published — there is no tag to publish one against. The automated close-out could not run it: the tool validates its version argument against the canonical version grammar before dispatching any phase and exits at that boundary, which is the documented path for this identity mode rather than a fault. The close was produced through the chore-pull-request mechanism and the output set was verified on `main`. Two decision records were promoted from proposed to accepted during this close, against the review that ratified them, because the promotion had not landed with the merge.

For full implementation detail see the RELEASE_LOG entry and the release plan linked from the milestone below.

### References

- Release pull request: https://github.com/cody-hutson/pmo-platform/pull/6393
- Milestone: https://github.com/cody-hutson/pmo-platform/milestone/359
- Closed issues: https://github.com/cody-hutson/pmo-platform/issues/5837 · https://github.com/cody-hutson/pmo-platform/issues/5839 · https://github.com/cody-hutson/pmo-platform/issues/5844 · https://github.com/cody-hutson/pmo-platform/issues/5846
- Follow-up: https://github.com/cody-hutson/pmo-platform/issues/6355 (one health colour rendered under five dimension labels)
