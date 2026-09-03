---
version: pda-decisions-and-conformance-baseline
date: 2026-09-02
type: note
issues: ["#5836", "#5838", "#5840", "#5841"]
pr: "#6746"
links:
  plan: release/releases/plans/pda-decisions-and-conformance-baseline_RELEASE_PLAN.md
  log_anchor: "#pda-decisions-and-conformance-baseline-version-less"
reversibility-tier: CHEAP
themes: ["cluster:data-architecture"]
summary: "How project data is identified, kept and checked each had several answers or none. Each now has one, and conformance is measured."
requires_action: false
breaking: false
components: ["entity-field-schemas", "project-schema", "lifecycle-protocol", "health-check", "deploy-check-family"]
followups: ["#5842"]
---

# Three unsettled rules about project data are decided, and conformance measured

2026-09-02 · pda-decisions-and-conformance-baseline

Three questions — how a record in one project refers to a record in another, where a file's lifecycle history actually lives, and what checks the rules on a recurring basis — had each been answered several different ways across the platform, or not at all. Each now has one recorded answer, and for the first time there is a measured count of how far the live records sit from the rules they are supposed to follow.

> **Skip the rest** unless you write references between projects, rely on the lifecycle history of a published file, or are waiting on the project-data cleanup work.

## Who this affects

- Anyone who writes a reference from one project's record to another project's record — there is now a single written form for it.
- Anyone who relies on the lifecycle history of a published file — where that history is kept has changed.
- Anyone waiting on the project-data cleanup: three groups of work that were blocked on these answers can now be planned and sized.

## What changed for everyone using the platform

- **A reference from one project to another now has one written form.** It is written as the target project's identifier, a slash, then the record's own identifier — and the project identifier comes from the project's own record, not from the name of the folder it sits in. *Why it matters:* a folder name is a display label anyone may rename, so anchoring references to it would have broken every stored reference the first time somebody tidied up a folder name.

- **A project's own identifier and the key everything resolves against must now match exactly.** Where the two differ, the record is treated as malformed and its identifier is corrected toward the key — never the reverse. *Why it matters:* two competing identifiers for the same project is precisely how a reference quietly resolves to nothing, and repairing in the wrong direction would move every reference that embeds it.

- **Lifecycle history moves out of a separate table and into each file's own record.** The separate table that recorded every transition is retired; the current state, when it last changed, and why it changed are kept on the file itself. *Why it matters:* that table was the only thing claiming to know who approved a file, and it had no source for the claim — so the answer it gave was invented rather than recorded, which is worse than having no answer.

- **A published file must now carry an approval reason drawn from a short fixed list.** A file marked published records either a human approval or a human re-validation, and anything else — including no reason at all — counts as a violation. *Why it matters:* a missing approval previously read as "nothing found", so the unapproved files were indistinguishable from the clean ones; it now fails in the safe direction.

- **There is now a measured count of how far the live records sit from the rules.** The existing structure checker was run across the live project records, and the classes it does not reach were measured separately, producing counts by rule class. *Why it matters:* every estimate for the cleanup work was previously a guess, and a guess cannot tell you whether the work in front of you is a day or a month.

## Known limits

- **These are decisions and a measurement, not the changes themselves.** The reference form, the identifier repair rule, and the lifecycle change are recorded here and carried out by later work. Nothing in your files changes as a result of this release.
- **The measurement counts and classifies; it repairs nothing.** Records it flags are left exactly as they were, and what to do about them is a separate decision.
- **The recurring checker is decided, not built.** The decision names where it will live, how it will report, and what evidence would let it start blocking; the build is separate work.
- **The measurement report is kept outside the shared repository.** Only its counts and rule classes appear in the public record, by design.
- **The three decision records still carry their ratification step.** Recording a decision and ratifying it are separate acts, and the second is a human decision taken at release close rather than something this release performs.

Report issues at the [pmo-platform issue tracker](https://github.com/cody-hutson/pmo-platform/issues).

## Reversibility

CHEAP / HIGH confidence. A single additive change — reverting the release commit restores the prior state completely, and nothing outside the repository was written or modified. No time-bounded window applies.

---

### Operator and engineering detail

**The key form, and why the namespace root moved (ADR-179)** — The cross-boundary key is the qualified composite `<project_id>/<id>`, carried by one reference grammar defined once in the entity-field schema and cited rather than restated by every consumer. The load-bearing correction against the design as proposed is the namespace root: it is the project's frontmatter `project_id`, not the folder-derived surrogate. A Project record's core `id` is bound to `project_id` unconditionally, with the folder-slug derivation re-scoped from source of truth to a seed-time fallback that never re-derives, so a folder rename followed by a re-seed cannot move the root. Anchoring a qualifier embedded in every reference value on a cosmetic display projection would have made the namespace root the least-governed key in the scheme. The grammar's local token deliberately admits uppercase and underscore rather than borrowing the naming standard's kebab segment rule, because the tracker row-id dialects it must carry are legitimate targets a kebab-only production would reject — the grammar states the charset it actually accepts.

Here is the reference grammar the delivery child implements, in the form the record fixes it:

```
REF      := [ TAG ":" ] BODY
BODY     := LOCAL | PROJECT "/" LOCAL
PROJECT  := the target project's project_id (the frontmatter join key)
LOCAL    := a single reference token [A-Za-z0-9_-], containing neither "/" nor ":"
```

**Retiring the lifecycle trail rather than sourcing it (ADR-177)** — The per-transition table is removed from the index schema and the builder along with its rebuild and incremental protocol steps, returning the index to a pure projection of frontmatter. Authority follows authorship: the frontmatter transition fields are the only lifecycle facts anything authors, so they are the only ones the platform asserts. The consumer claim that mattered — the published-without-approval check — is restated as a frontmatter predicate over a newly governed two-member approval vocabulary, and it fails closed on the absent case on every evaluation substrate, including any SQL form, where three-valued logic would otherwise quietly exclude the unstamped rows. The actor-based reading is retired with the trail, because an actor claim with no source is fabricated data.

**Where the recurring validator lands (ADR-178)** — It becomes a member of the existing deploy-check family with a standalone read-only engine, shipping in warn mode, because that family is the only candidate where the shared warn sink, the committed-default graduation form, and the absent-subject precedent all already exist rather than needing invention. Both sanctioned invocation paths — the numbered check and a new single-check dispatcher arm — route through one block, so a graduation to blocking binds both at once. The evidence design is the part worth reading: an unconditional per-run summary row is emitted on every run through a dedicated mode-independent appender, and the run-outcome universe is closed at three so that a skipped or failed-usage run breaks the clean streak instead of being invisible to it. An unenumerated fourth outcome emitting nothing would have let a window that measured nothing 40% of the time still satisfy the graduation criterion.

**Close mechanics** — This release declared version-less identity at bundling, so it claims no version and cuts no tag, and it therefore publishes no GitHub Release. The corpus surfaces landed through the documented close-out chore-PR path, which is the expected route for this identity mode. For the full audit trail see the [RELEASE_LOG entry](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/RELEASE_LOG.md) and [the release plan](https://github.com/cody-hutson/pmo-platform/blob/main/release/releases/plans/pda-decisions-and-conformance-baseline_RELEASE_PLAN.md).

### References

- Milestone: [pda-decisions-and-conformance-baseline](https://github.com/cody-hutson/pmo-platform/milestone/357)
- Release PR: [#6746](https://github.com/cody-hutson/pmo-platform/pull/6746)
- Issues: [#5836](https://github.com/cody-hutson/pmo-platform/issues/5836), [#5838](https://github.com/cody-hutson/pmo-platform/issues/5838), [#5840](https://github.com/cody-hutson/pmo-platform/issues/5840), [#5841](https://github.com/cody-hutson/pmo-platform/issues/5841)
- Decision records: ADR-177 (lifecycle audit trail), ADR-178 (validator surface), ADR-179 (cross-boundary key form)
- Follow-up: [#5842](https://github.com/cody-hutson/pmo-platform/issues/5842) — the named runner child for the recurring validator
