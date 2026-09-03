---
title: Work-Item Type Consumer Map
purpose: Factual enumeration of every surface that reads, creates, updates or deletes a work-item kind — the pack-declared `kind_id` vocabulary, its `type:<kind>` label projection, and the `role`/`applies_to` pack grammar — with each row's discovery method, so a change to the type system is assessed against a measured consumer set rather than an assumed one.
type: reference
status: ACTIVE
layer: 1
reversibility: CHEAP / Confidence HIGH
consumers: Any agent changing the pack grammar, the licensed-kind vocabulary, the `type:*` label surface, or the intake type-derivation contract; release-pipeline spokes performing blast-radius assessment on those surfaces.
verified_at: e747f3e9
---
<!-- reference-durability: allow-link -->

# Work-Item Type Consumer Map

## Purpose + scope

This map enumerates every surface that **reads, creates, updates or deletes** a work-item
kind. Three things count as "a work-item kind" here: a pack-declared `kind_id` row, its
projection onto the live `type:<kind>` label surface, and the `role` / `applies_to` pack
grammar that decides which kinds a deployment resolves.

**It is descriptive, and it is not a gate.** No check reads this file and no verdict is
computed from it. A criterion phrased *"conforms to the map"* is ungradable — no verdict
enum renders MET against a forty-row matrix. Cite a **named row** and assert the behaviour
that row licenses.

**What it deliberately does not cover.** Operator-local pack instances are configuration
by design, so this repository is not the whole population — every count below is *"in the
population this repository can measure."* Historical release plans and notes that merely
narrate a past change are excluded unless they are the sole record of a decision.

**Coverage target.** Complete enumeration for the in-repo population; best-effort with
named gaps for the four out-of-repo populations (§ Flows beyond this repository).

### How completeness was established, and what would make it wrong

The enumeration is **not** the output of a single token search, because a single token
search is what produced the error this map was corrected for. Four independent passes
build the row set, and each row carries the pass that found it:

1. **Structural tracer.** `blast-radius.sh --mode=structural core/packs` — path-literal
   referrers. Now includes Python (§ Instrument blind spots).
2. **Path-literal tracer.** `blast-radius.sh` per shipped pack file — referrers naming a
   specific pack.
3. **Whole-corpus token census** under `python3` over all tracked files, every count paired
   with a sensitivity arm that must fire and a specificity arm that must return zero.
4. **Direct read of every candidate consumer's source**, because passes 1–3 find *tokens*
   and the thing being enumerated is a *property* — an archetype-scoped join. Prose
   expresses that property without using any of the tokens.

**Pass 4 is the one that closes the gap, and its absence is what made the original
enumeration wrong.** A prior pass reported "exactly one consumer breaks" by searching the
literal `applies_to`. The intake type-map's higher-precedence rung contains **zero**
occurrences of that token and carries a second archetype-scoped join in prose — so the
probe reported a population when it had measured a spelling. Both joins are enumerated in
§ Named breakages.

**What would make this enumeration wrong, stated so it is checkable:**

| Failure | Why it would evade the four passes | Detectable by |
|---|---|---|
| A consumer that expresses the archetype join in prose using none of the searched tokens, in a file no tracer flags | Passes 1–3 are token-driven; pass 4 is bounded by the candidate set passes 1–3 produce | Re-reading the type-derivation contract of any agent-executed reference, not just the flagged set |
| A consumer added after `verified_at` | Every count is a measurement at one commit | Re-running § Reproduction and diffing the row set |
| An operator-local pack or Layer-2 consumer | Out of the measurable population by design | Not detectable from this repository — named, not claimed clean |
| A consumer reached only at runtime through a configured adapter | Leaves the repository entirely | Not detectable from this repository — F7 below |

A row asserting a consumer relationship is graded **A** (executed probe), **B** (direct
`file:line` read) or **C** (tool output). No row is inference. Inference appears only in
the impact columns — what *would* break — and is labelled there.

## Read paths

Every consumer that reads the type registry, with its read path and the pass that found
it. Line anchors are at `verified_at`; § Reproduction re-derives them.

| # | Consumer | What it reads | Read path | Found by |
|---|---|---|---|---|
| R1 | `core/deploy/tools/check-work-hierarchy.py:338` `load_licensed_kinds_checked()` | `kind_id` rows | `os.listdir(core/packs)` → `<entry>/pack.toml` → `KIND_ID_RE` (`:208`); the union loop is `:362`–`:380` | structural tracer (post-fix) + direct read |
| R2 | same file, `--emit-kinds` → `emit_kinds()` (`:404`) | the union, one id per line | stdout contract; **exit 3** on a partial parse *or* an empty set (`:417`, `:421`) | structural tracer (post-fix) + direct read |
| R3 | `core/deploy/deploy.sh:8093` Check 22 (emitter `:7726`) | R2's stdout | `/usr/bin/python3 <tool> --emit-kinds` subprocess → CSV membership → Gate-1 Step-0 F2 predicate | structural tracer + direct read |
| R4 | `core/deploy/deploy.sh:11852` Check 55 | licensed kind vocabulary | hierarchy doc invariant — no banned parent tier above a licensed kind | structural tracer + direct read |
| R5 | `core/deploy/tools/check-label-parity.py` | `[[labels]]` `name` / `color` / `description` **and — since the mainline change that resolves `type:*` against declared kinds rather than a namespace prefix — the `[[kinds]]` `kind_id` rows it projects to `type:<kind_id>`.** The word *only* stood in this cell at the previous stamp and is FALSE at this one — the file resolves `type:*` against declared kinds instead of a namespace prefix, making it a `kind_id` reader in its own right | `_TOML_ROW_KV_RE` line scan + `parse_toml_kind_ids` | structural tracer (post-fix) + direct read; surfaced by the `kind_id` census arm moving 2 → 31 occurrences in this file |
| R6 | `core/deploy/deploy.sh:11571` Check 51 | R5 over the pack glob | `for c51_pack in core/packs/*/pack.toml` | structural tracer + direct read |
| R7 | `core/deploy/tests/test_g1_form_family.sh:111` | `--emit-kinds` | test harness invoking the same subprocess | path-literal tracer |
| **R8** | **`operations/skills/intake-desk/references/type-map.md:88`–`:100`** — precedence **rung 2** | **`kinds[]` from ELIGIBLE packs — two limbs since the grammar slice: `applies_to` equals `M` (`:93`), OR `applies_to` is `*` AND `role` is `kit` and it is the resolved `K` (`:94`–`:95`)** | **agent-executed, per invocation, never cached** | structural tracer |
| **R8b** | **same file, `:70`–`:81`** — precedence **rung 1 (K4), which WINS** | **operator/project type-pack kinds; scope is now conditioned on the pack's `role`, not on `M` alone (`:74`–`:79`), and the prose-vs-token asymmetry is stated in-place at `:83`–`:87`** | **agent-executed, per invocation** | **direct read; the block now carries 1 occurrence of `applies_to` where it carried 0 at the previous stamp** |
| R9 | `operations/skills/intake-desk/references/elicitation-loop.md:78` | methodology resolution + fallback rung | agent-executed | structural tracer |
| R10 | `core/schemas/gate-criteria-spec.md:199`, `:991` | the Gate-1 Step-0 contract — *"resolved, never enumerated"* | spec | structural tracer |
| R11 | `core/specs/label-taxonomy.md` | the `type:*` namespace grammar | spec | structural tracer |
| R12 | `release/tools/compute-close-class-telemetry.sh:218` | `_common`'s `group = "category"` rows, declared SSOT in-comment | comment-declared SSOT | structural tracer |
| R13 | `release/tools/synthesize-release-learnings.sh:164` | label-presence precondition — *"applies labels it does not create"* | presence check before auto-promotion | structural tracer |
| R14 | `core/packs/README.md` | layout + the `role` / `extends` model | doc | structural tracer |
| **R15** | **`core/deploy/tools/check-work-hierarchy.py:733`** (`_validate_one_pack()`, `:728`) **and `:1254`** (`resolve_archetype()`, `:1140`) | **`[meta].applies_to` — the pack-level archetype join key, read in BOTH senses the grammar defines: as a validated value and as a resolution input** | **`--validate-packs` (`:3144`) → PACK-P03 value-domain membership (`:750`–`:755`) + PACK-P05 role↔`applies_to` weld (`:771`–`:779`); `--resolve ARCHETYPE` (`:3149`) → the two-limb eligibility join (`:1271`–`:1272`), limb (a) `applies_to == <archetype>` and limb (b) `applies_to == "*" AND role == "kit"`. Wired as `core/deploy/deploy.sh:13983` **Check 75** (pack-grammar conformance, warn-mode initial; block header `:13925`) — the THIRD deploy.sh consumer of this primitive, after Check 22 (R3) and Check 55 (R4)** | **direct read. This reader is what moved the corpus census from 0 to 1 of 244 in the note below; at the previous stamp it was recorded in that prose ONLY and held no row of its own, so the map's own read-path table did not enumerate a reader the release ships (Stage-7 F-01, carried as Stage-8 F-E)** |

**The union is archetype-blind by construction, and that is load-bearing.** R1 reads
`kind_id` only. It performs no `role` join and no `applies_to` join — verified by direct
read of the loop (`:362`–`:380`), which is unchanged at this stamp. That is precisely why
R1–R7 absorb a methodology-neutral kind-bearing pack unchanged.

> **RE-DERIVED AT THIS STAMP — the census moved, and this release moved it.** At the
> previous stamp this paragraph closed *"the constraint being relaxed is not enforced in
> code anywhere,"* resting on `applies_to` occurring in **0 of 244** tracked executables.
> That is now **1 of 244** — `core/deploy/tools/check-work-hierarchy.py`, whose
> `--validate-packs` and `--resolve` branches this release ships, wired as `deploy.sh`
> Check 75 — enumerated as **R15** above — and read by R8's own two-limb eligibility rule. Measured on both refs over the
> same denominator: `origin/main` 0 of 244, this stamp 1 of 244; sensitivity arm `kind_id`
> 3 files on both; specificity arm 0 on both; extraction non-empty (244 of 244 readable).
> **R1's own archetype-blindness is untouched** — the new reader is a separate argv branch
> that returns before the H1/H2/H3 legs and shares no state with the union. What changed
> is the corpus-level claim, not the mechanism: the relaxation now meets a live reader,
> which is the window-closing the grammar's own extension note records.

## Create / update / delete paths

The axis most likely to hide surprises, because two of its entries are unreachable from any
in-repo search.

| # | Op | Path | Execution locus | Note |
|---|---|---|---|---|
| C1 | CREATE | `.github/ISSUE_TEMPLATE/epic.yml:11` — `labels: ["type:epic", "status: proposed"]` | **GitHub servers** | no repo code runs; a kind is stamped with no pack consulted |
| C2 | CREATE | `.github/ISSUE_TEMPLATE/story.yml:12` — `labels: ["type:story", …]` | **GitHub servers** | same |
| C3 | CREATE / UPDATE | `check-label-parity.py --emit-fix` → label create/edit commands | rendered in-repo, **executed by the operator** | a write *generator*; the write itself leaves the repo |
| C4 | CREATE | intake-desk ambient auto-log → issue create with a `type:<kind_id>` label | agent, at runtime | the only create path that consults the pack, via R8/R8b |
| C5 | CREATE | hub/spoke sub-task creation | agent | stamps a sub-task marker, not a `type:*` kind |
| C6 | CREATE | `synthesize-release-learnings.sh` auto-promotion | script | applies labels it does not create — presence-gated at R13 |
| U1 | UPDATE | issue label add/remove across the ticket-architecture, release-process, deferred-item and handoff surfaces | agent | many occurrences across the governance corpus |
| U2 | UPDATE | label edit via C3 | operator | mutates colour/description of a live `type:*` |
| U3 | UPDATE | pack edit + `pack_version` bump | repo | **no consumer is notified**; R1 re-reads on the next check, R8 on the next invocation |
| **D1** | **DELETE** | deleting a `type:<kind_id>` label | operator, **GitHub-side** | the label is stripped from **every** issue carrying it; no bulk restore. **IRREVERSIBLE** `[INFERRED]` — reasoned from documented label-deletion behaviour, deliberately not tested |
| **D2** | **DELETE** | removing or deselecting a pack directory | repo | the vocabulary **silently shrinks**; every issue carrying its kinds flips out of the licensed partition with no diagnostic |

**D1 and D2 are the answer to "writes, updates and deletes are not enumerable by grep."**
Neither is reachable from any in-repo search: D1 executes on GitHub, and D2's signal is the
*deliberate absence* of a signal. D2 is by design, quoted from R1's own docstring:

> An ABSENT pack (no directory, or no `pack.toml` inside it) is NOT a degradation: which
> packs a deployment licenses is a configuration choice, and treating a deselected pack as
> a fault would fail loud on a correct instance.

The function separates *not licensed* from *not read* — correct for deselection, and
indistinguishable from accidental deletion.

## Flows beyond this repository

Traced to their far end. Three sit inside the doc tracer's own default exclusions, which is
why a repo-only scan cannot reach them by construction.

| # | Far-end surface | Carried by | Excluded from the doc tracer? | State at `verified_at` |
|---|---|---|---|---|
| F1 | **Live label surface** — 80 labels, **9** `type:*` vs **4** pack-declared kinds | C1–C3, U2, D1 | n/a (not a file) | 5 `type:*` labels are pack-undeclared |
| F2 | **Live issue surface** — every open and closed issue's label set | C1–C6, U1 | n/a | unbounded; not enumerated here |
| F3 | **Deployed skill mirror** of the intake type-map | deploy sync | **yes** | present, and **NO LONGER byte-identical**: repo copy **16,665** bytes, deployed mirror **13,577** bytes at this stamp. The drift window the second-order table predicts is **OPEN**, measured rather than inferred — the grammar slice edited the repo copy and no redeploy has run. It closes at deploy, not here |
| F4 | Compiled `.skill` distribution artifacts | package build | **yes** | present |
| F5 | Operations-tier project records carrying the delivery-approach selection input | operator authoring | **yes** | out of the measurable population |
| F6 | Operator configuration — the methodology default, the **work-item-kit default**, and the ticketing adapter selector, the head of the configuration cascade | config cascade | n/a (template only in repo) | `[methodology].default_work_item_kit` + the `PROJECT.md` `work_item_kit:` override **landed**; see the note below |
| F7 | The configured **ticketing adapter** — one value today, the selector admits others | adapter | n/a (outside the repo entirely) | **out of reach; named, not reported clean** |
| F8 | The operator-instance pipeline event log | stage event emits | n/a (operator-instance) | out of the measurable population |

**F6's forward-declared row has been reconciled to what landed.** The selection slice of
this release adds a work-item-kit key to operator configuration and to the project-level
override surface, and that key is a member of F6's enumeration. It was declared here at
authoring time rather than left for a later slice to append, because the far-end
enumeration is this map's contract and an integration criterion asserting F6's
completeness would otherwise name a surface no change matrix owns. The selection slice
then named the landed keys in the row above rather than leaving the forward-looking
phrasing standing, so the row reads as an enumeration rather than as a promise.

## First-order vs second-order impact

Keyed to the grammar relaxation: permitting a kind-bearing pack to be archetype-neutral,
at the pack level and at the kind level.

**First-order — resolves differently the moment the relaxation lands:**

| Consumer | Verdict | Why |
|---|---|---|
| **R8** (rung 2) | **WOULD HAVE BROKEN — quietly; REPAIRED at this stamp** | the join *was* `applies_to` **equals** `M`; a neutral value equals no concrete methodology, so the kit's kinds were dropped and derivation fell through to a lower rung, with no error at any rung. The grammar slice replaced it with the two-limb eligibility rule at `:92`–`:98`. |
| **R8b** (rung 1, K4 — **higher precedence**) | **WOULD HAVE BROKEN — quietly, and first; REPAIRED at this stamp** | the same archetype scoping, expressed as *"the declared kinds ARE the registry **for their archetype**"*, at the rung **above** the one a fix at rung 2 alone would have repaired. The slice widened the whole block rather than one line (`:74`–`:79`), which is what this row asked for. |
| R1 / R2 | unaffected | archetype-blind by construction — the union reads `kind_id` from any pack directory |
| R3 / R4 | unaffected | consume R2's already-archetype-blind output |
| R5 / R6 | unaffected in mechanism; **improved in signal** | a kit declaring label rows not live on the label surface is correctly reported missing |
| the meta-schema's role-conditional block | **is the change** | the grammar slice edits it |
| `core/packs/README.md` | **is the change** | composition order is documented there |

**Second-order — resolves differently one hop out:**

| Effect | Mechanism |
|---|---|
| **The Gate-1 Step-0 partition shifts** | a kit's kinds enter the licensed vocabulary, so issues carrying them move into the evaluated partition and become subject to criteria they previously escaped. **A previously-unevaluated card class becomes evaluated** — new findings in warn mode, new blocks at an enforce flip. |
| **The pack-undeclared label population shrinks** | 5 of 9 live `type:*` labels are pack-undeclared today; any kit declaring one removes it from that set, which is why the sibling parity-hardening work must read the post-change definition. |
| **Close-class telemetry widens** | R12's SSOT is the base pack's category rows; a kit contributing category rows changes the close-class denominator. |
| **Deployed-mirror drift window opens** | R8/R8b are a *deployed* file. An edit that is not redeployed leaves the runtime reader stale. The grammar slice edits that file, so the window is **OPEN at this stamp** — F3 measures it rather than infers it: repo copy **16,665** bytes against a deployed mirror of **13,577**. It closes at deploy, not here. (This cell previously read *"in sync at `verified_at`, so the window is currently closed"* — a claim carried over from a stamp before the slice edited the file, and one its own next clause already contradicted. F3 is the measured row and governs.) |
| **Hardcoded kind literals stay hardcoded** | **8 of 244** executables carry a bare `type:epic` literal. They do not read the pack, so they neither break nor adapt — they simply continue to assert one kind name regardless of what a deployment licenses. |

## Named breakages

Consumers that **would have broken** under a decoupled, archetype-neutral kind unit, stated
here as the map found them at the baseline. **Two rows, not one** — and the second was
invisible to the probe that produced the original count. **Both are repaired at this
stamp** by the grammar slice, which widened the derivation block rather than one clause;
the rows are retained because the failure mode, not the defect, is what a future editor of
that contract needs to have read.

| # | Consumer | Rung | Precedence | Failure mode |
|---|---|---|---|---|
| **B1** | `operations/skills/intake-desk/references/type-map.md:67` | rung 2 — shipped methodology packs | loses to rung 1 | The join reads `kinds[]` from packs *"whose `applies_to` equals `M`"*. A neutral value equals no concrete methodology, so the kit's kinds are dropped and derivation falls through to the lower rungs and types the item by the invariant tier. **Silent fallthrough — no error, no gate, no test.** |
| **B2** | same file, `:60`–`:65` (the join phrase at `:62`–`:63`) | rung 1 — the operator's/project's own type-pack (K4) | **WINS** | *"the declared kinds ARE the registry **for their archetype**"*. An operator-authored kit is a K4 pack, so it is read **here first**, where the same archetype scoping drops it. Repairing rung 2 alone leaves the winning rung broken. **Silent, and higher-precedence than B1.** |

**The framing line is the deeper defect.** Line 58 parameterizes the entire derivation on a
single resolved methodology `M`. A kit introduces a **second selector** the contract has no
parameter for. Repairing one clause inside a single-axis contract leaves the contract
single-axis — the grammar slice's edit must widen the block, not a line.

**Why B2 was missed, stated as a method failure rather than an oversight.** The original
enumeration searched the literal `applies_to` and reported the result as a population. The
breakage class is *archetype-scoped joins*; `applies_to ==` is one spelling of that class
and *"for their archetype"* is another. Measured **at the baseline**: the whole file
contained **1** occurrence of `applies_to`, at `:67`; the rung-1 block at `:60`–`:65`
contained **0**; the file contained **9** occurrences of `archetype`. The control was live
— the token *was* present in the file — so the rung-1 zero was a real absence and not an
unresolvable path. **A count of one was a count of one spelling.** Re-measured at this
stamp, after the repair: the file is **228 lines / 16,554 characters**, `applies_to` occurs
**6** times, the rung-1 block `:70`–`:81` now carries **1** of them, the rung-2 block
`:88`–`:100` carries **3**, and `archetype` occurs **18** times. The rung-1 zero is closed
by the repair, which is the observable that shows the fix reached the winning rung.

**Everything else absorbs the relaxation unchanged.** That asymmetry is this map's single
most decision-relevant output: the grammar change is safe in code and unsafe in prose,
which is the inverse of where review attention naturally goes.

## Mapped hazards

Each carries its `file:line` and is recorded here rather than filed — the owning milestone
is composition-locked, so these route to a later bundle.

| # | Hazard | Anchor | Consequence |
|---|---|---|---|
| H1 | **The licensed-kind union silently widens.** The loop walks every directory under `core/packs/` holding a `pack.toml` and unions its `kind_id` rows — **no allowlist, no naming filter, no underscore-prefix skip**. | `core/deploy/tools/check-work-hierarchy.py:362`–`:380` | A fixture pack placed in that tree is absorbed into the **production** gate's vocabulary. This is why every fixture in this release lives outside `core/packs/`. |
| H2 | **The label-parity check cannot detect a pack-undeclared kind label.** `type:` is registered as a namespace *pattern*, so any live `type:*` resolves as a pattern match and is never an orphan. | `core/deploy/tools/check-label-parity.py:73` (`REGISTERED_NAMESPACES`) | 5 of 9 live `type:*` labels sit unflagged. Adjacent to, and distinct from, the parity-hardening work in a sibling milestone. |
| H3 | **Pack removal is silently non-degrading** (D2 above). | `core/deploy/tools/check-work-hierarchy.py:338` docstring (the quoted clause at `:352`) | Correct for deselection; indistinguishable from accidental deletion. A pack-count drift signal would separate the two. |
| H4 | **A consumer map goes stale, and `verified_at` cannot stop it.** | this file | The stamp is a **convention with no enforcement**: measured over the tracked corpus, `verified_at` appears in **2 of 1876** readable files — this map and one release plan — with **no schema declaring it, no gate reading it, and no runner comparing it to `HEAD`** (sensitivity arm, the schema-governed frontmatter key `reversibility:` → 298 files; specificity arm → 0; same denominator, same instrument). So nothing detects the gap between the stamp and the head, and nothing ever will until something reads it. **This was not hypothetical here**: the stamp was set at the commit that authored this map, three slices then rewrote its subject, and the map kept asserting six classes of claim that had gone false — including *"the constraint being relaxed is not enforced in code anywhere,"* which the same release falsified by shipping the first reader. Mitigated meanwhile by § Reproduction — re-verification is one command set, not a re-derivation. **The durable fix is a check that compares `verified_at` to the head and reports the delta**; it is net-new infrastructure and is recorded here rather than filed, because the owning milestone is composition-locked. |

## Instrument blind spots

**Stated as a property of the map, because a map produced by incomplete instruments that
does not say so launders staleness as evidence.**

**The Python blind spot was closed in the release that authored this map, and every
`Found by` value above reflects the post-fix instrument.** The doc tracer's scanned-type list
omitted `py`, so it could never surface R1, R2 or R5 — the only executables that read the
pack corpus. Measured before and after **at the commit that landed the fix**, on the same
target — the counterfactual half of this table is anchored there and is deliberately not
re-executed at later stamps, because the "without" state no longer exists in the tree:

| Instrument state | Files in scan population | First-order consumers of `core/packs` | `.py` consumers surfaced |
|---|---|---|---|
| without the Python type (at the fix commit) | 1555 | 25 | **0** |
| with it (at the fix commit) | 1627 | 27 | **2** — the two pack-reading executables |
| with it (**re-executed at this stamp**) | 1658 | 44 | **2** — the same two |

The +72 scan-population delta equals the **tracked `.py` file count** exactly (72 of the
244 tracked `.py` / `.sh` / `.ps1` files) — the cross-check that the delta is the Python
corpus and not drift. That it matches exactly, rather than falling short, additionally
shows no tracked `.py` file sits under a default exclusion. **The cross-check still holds
at this stamp and was re-derived independently of the tool**: tracked files matching the
scanned-type set are 1658 with `py` and 1586 without, a delta of 72, and 1658 is exactly
what the tool reports as its scan population. The first-order count moved 27 → 44 because
the release added referrers to `core/packs`, not because the instrument changed.
The fix ships with a discriminating self-test arm: the suite previously returned an
identical result patched and unpatched because its fixture region contained no `.py` file
at all, so the one-line change alone would have landed behind a gate that could not fail.

**Two blind spots remain, and neither is closed by a type-list edit.**

1. **An import-graph tracer cannot see a subprocess.** The software-domain tracer already
   scans Python — the type is the first entry in its own list — yet it reports **0**
   first-order consumers for the pack-reading gate primitive, while its control arm (a
   module that genuinely *is* imported) reports **7**. The control fires, so the zero is
   real. The mechanism: `deploy.sh:8092` invokes the primitive as
   `/usr/bin/python3 <tool> --emit-kinds`, a shell subprocess — **never an import edge**.
   The blindness is **architectural, not a type-list omission**, so no entry added to any
   scanned-type list reaches it. Extending that tracer would be a no-op that looked like a
   fix.
2. **A token census cannot see a join expressed in prose.** This is B2's root cause and it
   is a property of the method, not of any one tool. Any enumeration of the archetype-join
   class that is built from a token search will under-report it, because the class has more
   spellings than the search has tokens. The mitigation is pass 4 in § Purpose + scope —
   read the candidate consumers' derivation contracts directly — and its residual is stated
   there: pass 4 is bounded by the candidate set the token passes produce.

**One consequence for rules that compute a verdict over "flagged consumers."** A rule whose
denominator is the set of consumers an instrument flags returns its clean value on a change
whose only consumer the instrument cannot see — clean because unseen, not because
dispositioned. That is not a missing row in a report; it is a gate that passes a genuinely
broken change. The Python limb of this is now closed; limb 1 above is not, and its
consequence grows with any graduation from advisory to blocking.

## Reproduction

Every invocation below was run at `verified_at`. Re-running them re-derives the map rather
than re-deriving trust in it. Run from the repository root.

**Engine note.** Load-bearing detectors run under `python3`, not the workstation `grep`,
which is `ugrep` and can reject a pattern into a plausible zero. Every count below is
paired with a sensitivity arm that must fire and a specificity arm that must return zero.

```bash
# 0 — the stamp. verified_at is the head the MEASUREMENT was taken at; this file
#     lands as the NEXT commit, so the stamp equals this map's own PARENT, never
#     the commit that writes it. An inequality here is expected on any later
#     commit and is NOT drift on its own — what makes it drift is a row below
#     failing to re-derive.
#     The stamp must also be REACHABLE. A stamp that is not an ancestor of the branch
#     head is an orphan: a rebase rewrites the commits it names, and the old object
#     survives only in the local store of whoever ran the rebase. It resolves there
#     and NOWHERE on a fresh clone, so step 0 silently becomes unrunnable for every
#     other reader while still looking correct to its author. That is what happened
#     to the previous stamp c7c4b9bd, and the assertion below is what would have
#     caught it: re-stamp AFTER the rebase and after the last content edit, never
#     before, then assert reachability rather than assuming it.
git rev-parse --short=8 HEAD                 # note the delta; re-derive rows 1-6
git log -1 --format=%h --abbrev=8 <verified_at>   # the tree every anchor is read at
git merge-base --is-ancestor <verified_at> HEAD   # MUST exit 0 — an orphaned stamp
                                                  # makes every row below unverifiable

# 1 — instrument self-test (39 assertions, 0 skipped, exit 0)
bash release/tools/blast-radius.sh --self-test

#     the discriminating arms: remove the "py" entry from SCANNED_TYPES and re-run.
#     T6a and T5l MUST go red; T6z MUST stay green. A run where all three stay green
#     means the fixture no longer discriminates and every count below is unverified.

# 2 — structural consumers of the pack corpus (expect 44 at this stamp, incl. the two .py readers)
bash release/tools/blast-radius.sh --mode=structural --format=json --no-color core/packs \
  | jq -c '{tfs:.stats.total_files_scanned, fo:.stats.first_order_count,
            py:[.first_order[].path|select(endswith(".py"))]}'

# 3 — path-literal consumers per shipped pack (sensitivity: each must be non-zero)
bash release/tools/blast-radius.sh --format=json --depth=1 --no-color core/packs/_common/pack.toml
bash release/tools/blast-radius.sh --format=json --depth=1 --no-color core/packs/scrum/pack.toml
bash release/tools/blast-radius.sh --format=json --depth=1 --no-color core/packs/kanban/pack.toml

# 4 — the architectural blind spot, subject then control. Subject 0, control non-zero.
bash release/tools/domain-blast-radius.sh --domain=software --format=json \
  core/deploy/tools/check-work-hierarchy.py | jq -c '.stats.first_order_count'
bash release/tools/domain-blast-radius.sh --domain=software --format=json \
  core/deploy/tools/_frontmatter.py        | jq -c '.stats.first_order_count'

# 5 — the reader is live (control for every claim about the vocabulary)
python3 core/deploy/tools/check-work-hierarchy.py --emit-kinds   # 4 kinds, exit 0

# 6 — live label surface vs pack-declared kinds (REST; the GraphQL pool is separate)
gh api --paginate "repos/OWNER/REPO/labels?per_page=100" --jq '.[].name'
```

**The two census passes, restated so they are reproducible without the scratch script.**
Both iterate `git ls-files`, read each path as UTF-8, and count with `str.count` /
`re.findall` — no shell matcher in the path.

- **Corpus census.** Denominator **1931** tracked files; **1876** readable as UTF-8; 55
  binary (image and archive assets, none a text consumer). Sensitivity arm `\bthe\b` →
  **1751 files / 243,831 occurrences**. Specificity arm, an impossible token → 0 / 0.
- **Executable census.** Denominator **244** executables (72 `.py`, 169 `.sh`, 3 `.ps1`) —
  all 244 readable, extraction non-empty. Same-shape sensitivity arm — a TOML key these
  files *do* read, `kind_id` → **4 files / 97 occurrences**
  (`check-work-hierarchy.py` 54, `check-label-parity.py` 31, `deploy.sh` 6,
  `compute-release-velocity.sh` 6). **This arm MOVED, and the move is a finding rather
  than noise**: it read 3 files / 62 at the previous stamp, and the mainline this branch
  rebased onto added a fourth reader and widened a third — see R5 and the rebase note.
  General sensitivity arm → **242 files / 42,868**. Specificity arm → 0.
  **Subjects at this stamp: `applies_to` → 1 file / 56. An archetype-valued `role` →
  1 file / 9. `general_level` → 1 file / 37 — all three in
  `core/deploy/tools/check-work-hierarchy.py`, and all three were 0 / 0 at the baseline
  (`origin/main`, same denominator, same arms).** The subject moved because this release
  shipped the first reader; the arms did not.
- **The two-rung probe.** Over the intake type-map at this stamp (**228 lines, 16,554
  characters** — extraction non-empty): `applies_to` occurs **6** times file-wide, **1** in
  the rung-1 block `:70`–`:81` and **3** in the rung-2 block `:88`–`:100`; `archetype`
  occurs **18** times file-wide. At the baseline the same probe read 1 file-wide, 0 in
  rung 1, 9 for `archetype` over 188 lines / 13,478 characters — the rung-1 zero that made
  B2 invisible, now closed by the repair.

**The corpus figures above moved with the REBASE, not with a change of method.** This has now happened at three stamps, and the three together say more than any one of them. The same script, the same arms and the same denominators still re-derive each earlier stamp's figures exactly when run at that stamp — `1911 / 1856`, then `1926 / 1871` — so nothing was re-measured differently and no instrument changed at any point. What moved is the corpus underneath the measurement. The first rebase carried this branch onto a mainline 41 commits further along, adding **15** tracked files; the second, at Stage 12, carried it 8 commits further and added **1**; the third, forced when a sibling release merged during this release's own CI wait, carried it **31** commits further and added **5**. Every addition is text, so the binary count holds at 55 and the readable count moves by the same amount each time (**1926 → 1931**, **1871 → 1876**).

**The discriminating observation is the executable census — and at this stamp it stopped agreeing, which is the useful part.** Across all three rebases the executable DENOMINATOR never moved: same 244, same 72 / 169 / 3 split. At the first two stamps its subjects did not move either, and the reading was clean: a corpus denominator shifting while an executable-scoped denominator holds is the signature of a rebase. At this stamp the denominator still held, but the `kind_id` arm moved **3 files / 62 → 4 files / 97**. That is NOT the rebase signature, and reporting it as one would have been the error this map exists to prevent: an unchanged aggregate hiding a real change beneath it. The arm moved because the mainline added a `kind_id` reader (`compute-release-velocity.sh`) and widened an existing one (`check-label-parity.py`, 2 → 31 occurrences, under the mainline's type-resolution change) — a genuine consumer-set change, recorded at **R5**, not a measurement artifact. The `applies_to` 1 / 56 and `general_level` 1 / 37 subjects did hold, which is what localises the change to the `kind_id` axis rather than to the instrument.

So the rule survives in a sharper form: a moving corpus denominator with a holding executable denominator indicates a rebase, **but only while the subject arms hold too**. A subject arm that moves under a held denominator is a new consumer, and the map owes it a row.

**A zero whose control arm also returned zero is a broken probe.** Every zero recorded in
this map is paired with a live control in the same invocation over the same denominator.

## Reference block

Bare references are confined here with an inline summary, per the reference-durability
standard.

- The founding architecture decision for the work-item kit as a first-class,
  archetype-neutral, kind-bearing pack role — recorded as `ADR-180` in `core/ADRs/`.
- The pack composition grammar and the composing-unit record this map's grammar rows sit
  under — `ADR-070` and `ADR-069` respectively, both in `core/ADRs/`.
- The parity-gate hardening that measures the pack-undeclared `type:*` label population
  (H2's neighbour) is owned by a sibling milestone and is coordination-only here; the gate
  stays permissive through this change.
