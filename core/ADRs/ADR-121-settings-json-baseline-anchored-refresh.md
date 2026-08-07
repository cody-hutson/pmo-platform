<!-- reference-durability: allow-link -->
---
title: ADR-121 — settings.json is refreshed at update time by baseline-anchored whole-file regeneration with operator-key migration
status: Accepted — ratified by the operator at the Stage 5 Collective Review scope-lock gate for the `96-update-install-config-safety` release, 2026-08-06. The flip is verified against this file's `status:` field, never inferred from milestone closure or a review comment.
date: 2026-08-07
release: 96-update-install-config-safety
deciders: "Workspace owner (ratified the scope and mechanism at the Stage 5 Collective Review scope-lock gate); mechanism designed at Stage 5 Solutioning, authored at Stage 6"
tags: [composition-surface, update-mechanism, category-contract, customizable, settings-json, security-hooks, durability, layer-model]
source_observations:
  - "A workspace surveyed at authoring was missing four hook registrations its shipped template
     carries — two PreToolUse matchers for a scope-segregation guard, one SessionStart entry, and
     the entire Stop block — while every referenced hook script was present on disk and
     byte-identical to source. The scripts had been delivered by the update path; the
     registrations that make them fire had not."
  - "That workspace's last full install ran weeks before the survey. Its settings template had
     gained three revisions since, and those three carry exactly the four missing registrations
     and nothing else — the staleness is precisely the post-install template delta."
  - "The update script contains no reference to the settings file at any point, and the operator
     documentation already carries a troubleshooting entry telling operators that a workspace
     installed before a hook was wired will not carry its entry and must re-run the full
     installer to obtain it."
  - "The runtime-native operator overlay that the platform's own layer model designates as the
     operator-owned settings surface is named in several governed documents and explicitly
     permitted by a security hook, but appears nowhere on the install or update path: neither
     scaffolded, nor documented there, nor referenced by the durability spec."
  - "Two corpus surfaces contradict each other on this file: the durability spec records that the
     update script does not refresh it, while the token-vocabulary spec asserts it is regenerated
     from template plus operator config on install AND update."
---

# ADR-121 — settings.json is refreshed at update time by baseline-anchored whole-file regeneration with operator-key migration

## Status

**Accepted** — ratified by the operator at the Stage 5 Collective Review scope-lock gate for the
`96-update-install-config-safety` release, 2026-08-06. Authored at Stage 6 per the Stage-6
ADR-authoring precedent. Acceptance is the Stage-5 → Stage-6 boundary condition on the
settings-refresh work item and blocks no other card in the release. The flip is recorded in this
file's frontmatter `status:` field, which is where it must be verified.

**Numbering.** This record's number was derived at Engineering Commit 0 against the mainline
anchor per ADR-115 §Decision (1) — next-free is `anchor(origin/main) + 1`, never
`max(claimed_set) + 1` — then advanced past the numbers claimed earlier in this same release.

**Numbering provenance — `120 → 121`.** Drafted at Stage 5 as **ADR-120**. Between the design and
this write, a concurrent release claimed 119 on the mainline and the sibling card in this release
claimed 120 on this branch, so the rule-determined next-free advanced to 121. No file was ever
created at 120 for this record — the draft lived in the Stage-5 handoff comment — so nothing had to
be moved or renamed. The move did **not** come free of a citation sweep, however, and the original
claim that it did was wrong: the release plan had already been authored at Engineering Commit 0
against the drafted numbers, so it carried 24 `ADR-119` and 10 `ADR-120` references — every one of
them denoting an in-release record — plus two ADR filenames in its machine-readable File Change
Matrix that never existed on disk. All were re-classified and repointed at the pre-PR reconciliation
pass. No file outside that plan cited a drafted number, because the corpus edits for this record were
authored after the shift. In-release Stage-4/Stage-5 citations reading "ADR-120" in
the settings-refresh context denote this record; ADR-120 itself is the sibling CLAUDE.md
re-categorization record. The substance the operator ratified — scope and mechanism — is unchanged
by the renumber.

## Context

The composition-surface spec assigns every package-shipped file to one of four categories, each
with an install-time and an update-time contract. Two files are **Customizable**: the workspace-root
governance file and the managed runtime settings file. The Customizable update-time contract reads,
in full, *not refreshed by the update script* — the operator is directed to re-run the full
installer, which recomposes the whole file.

For the settings file that contract has a consequence the spec does not state. The file is not
merely stale documentation when it lags: it is the **registry binding the platform's security hooks
to the events they guard**. The update path already refreshes the hook *scripts* — a prior release
added exactly that, on the stated ground that a hook security fix must reach an already-installed
workspace rather than waiting for a full re-install. But it refreshes only the scripts. The
registrations live in the settings file, which nothing refreshes. So a workspace can hold every
current hook script on disk while the events that would invoke them are not wired, and no signal
anywhere reports the condition. As of authoring this is not hypothetical; it is the observed state
of a live install, and it includes a fail-closed scope-segregation guard on two tool matchers, a
session-configuration verifier, and the platform's first Stop-event registration.

The obvious remedy — treat the settings file the way composition-surface files are treated — is foreclosed
by the spec itself. JSON has no in-file comment syntax and therefore no marker carve-out, so the
managed-section fence that carries the regeneration trigger and the tamper anchor for every other refreshed
file cannot exist here. The spec states this as a deliberate simplification and directs JSON composition to
be expressed **structurally** instead. That clause is not in question and this record does not amend it.
What this record amends is the **Customizable row's update-time contract** — a category contract the spec
fixes at the first public-flip release and permits amending only via formal ADR. The sibling record in the
same release amends the category *assignment* of the other Customizable file; the two are disjoint, and
neither touches the JSON clause.

One further force shapes the answer. The platform's layer model already designates a runtime-native,
separately-merged operator settings overlay as the operator-owned surface, and a security hook
already permits writes to it. That destination is well-governed. What is missing is any path to it:
the overlay is not scaffolded at install, not created at update, and not named anywhere on the
update path. So an operator who wants to add a permission has no signposted place to put it except
the managed file — the one place a refresh would overwrite.

## Decision

**The managed settings file is refreshed at update time by whole-file regeneration from the current
template, gated by a baseline-anchored guard that migrates any operator-added content to the
runtime-native operator overlay before the file is rewritten. It remains a Customizable file; it is
not re-categorized and it is not registered in the composition-surface manifest.**

1. **The category assignment is unchanged.** No fence is added, no marker emitted, no manifest entry
   created, and the JSON clause stands verbatim. What changes is one cell of the Customizable row:
   its update-time behavior.

2. **The two-hash separation is retained in semantics and relocated in carrier.** The prior record
   establishing managed-section tamper detection defines the source-template hash as the
   regeneration trigger and the post-substitution installed-body hash as the tamper anchor. Both are
   retained with identical meaning. Because no fence can carry them, they are stored as two fields
   in the installer's existing durable state file — which already carries per-hook checksums and
   resolved tokens for exactly this purpose and is already restored on a re-run. **This sidecar
   carrier is the structural expression of composition the JSON clause calls for.**

3. **The guard classifies before it writes, and classifies against the resolved template.** A hash
   match against the recorded installed-body anchor proves an untouched platform copy and authorizes
   regeneration outright. Only on mismatch — or when no anchor is recorded — does the guard perform
   a structural comparison, made against the **freshly resolved template**, never a hardcoded key
   list, because the whole file is template-rendered and any fixed list would be stale on its next
   revision.

4. **Migration precedes regeneration; warning alone is not sufficient.** Content found to be
   operator-added is written into the operator overlay first, the pre-write file is backed up on the
   existing pre-update backup convention, and only then is the managed file regenerated. A warn-only
   guard would leave the affected install permanently unrefreshed, which for a file carrying
   security-hook registrations and a deny list is the worse outcome — and it is migration that makes
   the security-priority default safe, because applying the platform version then costs the operator
   nothing.

5. **The one case that must not be resolved silently is a migration conflict.** When the operator
   overlay already defines a migrating key with a different value, the refresh aborts for that
   install: nothing is written, the conflicting key and the backup location are named, and the
   warning states explicitly that platform security registrations did not land. The rest of the
   update proceeds. A settings file is not a surface on which to guess.

6. **An unparseable live file is treated as the tamper case** — backed up on the tamper convention
   and regenerated, because a settings file the runtime cannot parse means the runtime is loading no
   platform settings at all, strictly worse than any customization loss, and the backup makes the
   operator's bytes recoverable.

7. **The operator overlay is scaffolded, empty, create-once, at install and at update.** This makes
   the layer split discoverable by existence rather than by documentation alone, and scaffolding it
   on **update** is what delivers it to workspaces that already exist. The create-once,
   never-regenerated contract is the one the package already uses for its other operator-owned
   scaffolds.

8. **The refresh runs after the hook-script refresh, never before.** Registrations must not reach a
   workspace ahead of the scripts they name.

9. **Discoverability is delivered as documentation and a scaffold, not as an in-file pointer.** The
   originating work item proposed a pointer comment in the managed file. It structurally cannot
   exist: JSON has no comments, and the installer already strips the template's single comment key
   so the runtime file is clean JSON. The intent is met by the install and update documentation, by
   the scaffolded overlay, and by a sentence in the template's own comment key — which documents the
   overlay for a reader of the template while still being stripped from the runtime file.

10. **Registration identity is the `(event, matcher, script basename)` triple, and the comparison
    domain is the resolved file — never the raw template.** The workspace root is baked into every
    registered command path, so keying on the full path would report a false operator addition after
    any workspace move; and the template's own comment key names a script in prose that is stripped
    before the file is written, so a filename-shaped scan over the raw template counts a registration
    that can never exist in a deployed file. Both are the same error — measuring a surrogate instead
    of the registration — and the triple over the resolved file is what excludes them.

## Alternatives Considered

**(A) Baseline-anchored whole-file regeneration with operator-key migration — SELECTED.** Reuses the only
writer this file has ever had, so install-time and update-time output are byte-identical by construction —
restoring the one-writer invariant whose absence produced the defect the sibling record supersedes — and
inherits that writer's two existing failure gates rather than re-implementing them.

**(B) Key-level three-way structural merge, preserving operator content in place — REJECTED.** It requires
the platform to declare an identity rule for every JSON container it merges: rules correct for today's
schema that become a silent liability the moment the runtime's schema grows a container they do not
describe, where the failure is a duplicated or dropped entry in a security settings file. It also keeps
operator content inside the platform-owned file, perpetuating the two-writer ownership this record ends.

**(C) Reconcile only the hook-registration block — REJECTED, and the closest call.** It fails the release's
own outcome statement, which promises the *file* is refreshed: a template change to the deny list — itself a
security surface — would still never reach an installed workspace, so it ships a second-class refresh a
later record must widen on the same file.

**(D) Render-time deep-merge of an operator overlay into the managed file — REJECTED on two independent
grounds.** It re-implements a merge the runtime already performs natively, modelling semantics the platform
neither owns nor can test in its own repository; and it consumes the overlay *into* the managed file,
destroying the very layer separation this record establishes.

**(E) Store the two hashes in the file itself, as a provenance object — REJECTED.** It reverses a shipped
decision: the installer deliberately strips the template's one comment-shaped key so the resolved file is
clean JSON, and re-adding platform metadata contradicts both that decision and the spec clause directing
JSON composition to be structural rather than in-file. Its one advantage — surviving loss of the state file
— is covered by the selected design's conservative degradation path.

**(F) A bare two-way diff against the resolved template, with no stored baseline — REJECTED.** It cannot
distinguish an operator addition from a platform *removal*, so it would migrate a deliberately retired
platform key into the operator's overlay and thereby resurrect it — silently re-enabling something the
platform removed on purpose.

**(G) Warn the operator and refuse to refresh — REJECTED.** The conservative-looking option is the unsafe
one: it leaves every customized install permanently un-refreshed, and the affected operator is by definition
the one who has already demonstrated they will edit the managed file. Warning is retained as a *component*
of the selected design, never as the whole answer.

| Option | Registrations reach a deployed install | Can it drop operator content | Managed file stays platform-owned | Models a schema the platform does not own | Verdict |
|---|---|---|---|---|---|
| A | Yes, any template change | No — migrate, back up, then write | Yes | Classification only; degrades conservatively | **Selected** |
| B | Yes, any template change | Yes, via a mis-specified container rule | No | Yes, load-bearing | Rejected |
| C | Registrations only | No | Yes | Minimal | Rejected |
| D | Yes | Yes, via merge precedence | No | Yes, and untestable in-repo | Rejected |
| E | Yes | No | Yes, but with foreign metadata | No | Rejected |
| F | Yes | Yes — resurrects removed platform keys | Yes | No | Rejected |
| G | No | No | Yes | No | Rejected |

## Consequences

**Positive.** A template change reaches an installed workspace through the ordinary update path, closing the
condition where a platform-shipped security hook is present on disk and never invoked. The operator gains a
signposted, scaffolded, runtime-native home for their own settings — created at update as well as at install,
so existing workspaces get it too. The tamper-detection contract every other refreshed file enjoys extends to
this one, in the only carrier its format permits. The four-category taxonomy becomes true rather than
aspirational for both Customizable members, and the two corpus surfaces that contradicted each other on this
file are reconciled in the direction that makes the stronger claim correct. The install validator gains the
registration-parity assertion whose absence let the condition persist unnoticed: presence, validity, and
token-resolution all passed on the affected install.

**Negative.** The update path now rewrites a live operator file it previously never touched, and that write
cannot be undone by reverting the release — the mitigation is that migration precedes it and a backup is
taken, not that the write is cheap to reverse. An operator who placed content in the managed file will find it
relocated, so the migration warning must name every key moved and where it went. The guard depends on a
durable baseline whose absence degrades to a structural comparison on every run, which makes persisting the
baseline after each refresh a hard requirement rather than a nicety. The platform now models a small part of
the runtime's settings schema for classification purposes — bounded and conservative, but a coupling that did
not exist before. And an update will make previously-inert registrations live: both newly-registered classes
land behind their own opt-in defaults and are inert on arrival, but the update output must still say what
became registered — a guardrail change is not permitted to be silent even when it lands inert.

**For the sibling record on the workspace governance file: the two are complementary, not competing.**
That record moves its file *into* the composition surface and preserves operator content *in place*
behind a fence. This record keeps its file *out* of the composition surface and relocates operator
content *elsewhere*. The mechanisms diverge because the files have opposite properties: one can carry
a fence but has no separately-merged operator counterpart; the other can carry no fence but has one.
Sharing a helper across that divide would put two disjoint implementations behind one name, so no
shared helper is introduced. The two share four files, edit disjoint subjects within them, and agree
on one point stated as an integration criterion rather than assumed.

## Reversibility

**EXPENSIVE / Confidence HIGH.** Two independent reasons, and only the first is the one the spec's
clause names: past the public flip, changing a category contract is a coordinated user-side migration
with stakeholder impact, and the spec is fixed at that release and amendable only by formal ADR.

The second is concrete and asymmetric. Reverting the release restores the package but does not
un-write a regenerated settings file, and does not un-move a key already migrated into the operator
overlay. A reverted platform would then read a workspace whose managed file was written by a
mechanism the reverted code no longer contains, and whose operator content now lives in a file the
reverted code does not scaffold. The pre-write backup and the migration record make the operator-side
state recoverable; they do not make the decision cheap to reverse. The scaffold and documentation
halves are separately CHEAP and could be retained across a revert of the rest.

## Related ADRs

Builds on **ADR-014**, whose two-hash separation — source-template hash as the regeneration trigger,
post-substitution installed-body hash as the tamper anchor — is reused here unchanged in meaning and
relocated from an in-file marker to the installer's durable state file, because this file's format
admits no marker. Sibling to **ADR-120**, which amends the category *assignment* of the other
Customizable file while this record amends the update-time *contract* of the category itself; the two
are disjoint and neither amends the JSON clause. Numbering derived per **ADR-115**, whose mainline-anchor
rule is what makes the `120 → 121` advance rule-determined rather than discretionary. Relates to
**ADR-030**, which established the machine-readable hook registry this file embodies and whose
completeness check reconciles hook scripts against their owning documents but not against their
registrations — the gap this record closes on the deployed side. Relates to **ADR-087**, which
introduced the first Stop-event registration, one of those observed missing from the field.

## References

- The work item carrying the unguarded-overwrite defect and, after its scope change, the
  settings-refresh mechanism this record governs — tracked as issue #1355.
- The sibling work item carrying the workspace-governance-file refresh, whose record is ADR-120 —
  tracked as issue #3831.
- The earlier release that refreshed deployed hook scripts on update, delivering the half of this
  mechanism that this record completes — tracked as issue #3430.
- The earlier release that took the honest-documentation path on the sibling file and deferred
  building a refresh mechanism — tracked as issue #2232.
