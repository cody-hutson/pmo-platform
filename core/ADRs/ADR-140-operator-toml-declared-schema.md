<!-- reference-durability: allow-link -->
---
title: "ADR-140 — The operator.toml key set is declared as data, and the generator derives its emit from that declaration"
status: Accepted
date: 2026-08-23
release: operator-instance-home-and-install-scaffold
deciders: "operator (D-1 adopt S3; D-2 deliver three sections) + Stage 5 Solutioning spoke (design) + Collective Review (M1 disposition) + Stage 6 Engineering spoke (build, re-derivation)"
tags: [operator-toml, schema-as-data, install, update, reconcile, single-source-of-truth, ADR-022, deploy-check]
source_observations:
  - "write_operator_toml is invoked from exactly ONE place — install / re-bootstrap — measured across 1,741 tracked files with a live control arm (read_operator_toml: 10 occurrences, 3 call sites). No deploy or update path invoked it, so a schema addition reached NEW INSTALLS ONLY."
  - "The [automation] dial shipped 2026-08-09 and was absent from a config generated 2026-07-12 for roughly six weeks. Nothing surfaced it: automation_level appeared 0 times across core/deploy/*.sh, against 7 occurrences in core/deploy/tests/ — the tests asserted the freshly GENERATED file and never an existing instance."
  - "The reconcile slot already existed and was hollow. update.sh:217 schema_migrate() is called from both update paths, already read the template, already compared schema_version, and already reserved exit 66 — 'Schema migration aborted (operator dismissed prompt)' — which NOTHING emitted."
  - "The comparison had never been unequal: schema_version has read the literal 1 in both the generator and the template since Initial public release, so the branch was unreachable-equal, and its mismatch arm only warned and continued."
  - "operator.toml.template's header told the operator to 'run ./update.sh which prompts for missing values'. Nothing prompted. The platform shipped three-quarters of a feature."
  - "The template documented 40 keys across 9 sections while the generator emitted 16 across 5. The emitted 16 was an EXACT match for the hand-maintained MANAGED set, which is what made lifting it to a declaration faithful rather than a redesign."
  - "One of the four undelivered sections was [adapters] — which ADR-022 §1/§4 (status Accepted) names the #703 onboarding seam, and whose defaults deploy.sh Check 33 already asserted exist in the template — yet no generated config had ever contained it."
  - "field_to_token was a SECOND hand-maintained key list carrying the comment 'Edit BOTH or neither', and its drift caused the v4.15 cowork_install_path blanking defect: the key is cowork_install_path and the token is [COWORK_INSTALL_PATH_BASE], and the name asymmetry is exactly what got missed."
  - "update.sh carries ZERO JSON parsers — 0 jq, 0 python3, 0 node — and parses TOML with grep and awk (control arms: 11 and 7). The Stage-5 format matrix scored the decision against three consumers and never scored update.sh, which the design itself made the reconcile trigger."
  - "tomllib is Python 3.11+ only and at least one path on the reference host runs 3.9, while json is stdlib everywhere and jq is already a hard preflight dependency pinned to an absolute path."
---

# ADR-140 — The operator.toml key set is declared as data

## Status

**Accepted.** Authored at Engineering for the `operator-instance-home-and-install-scaffold` release, against the operator's D-1 (adopt S3) and D-2 (deliver three sections) decisions, as amended by the Collective Review M1 disposition.

**Refines:** [ADR-022](ADR-022-platform-config-vs-operator-toml-split.md), by delivering the `[adapters]` and `[methodology]` tables §1/§4 already assigned to `operator.toml`. It contradicts nothing there, so ADR-022 needs no status change.

## Context

`operator.toml` is generated once, at install, by `write_operator_toml`. That function is invoked from exactly one place and no deploy or update path calls it. A key added to the generator therefore reached **new installs only**; every existing instance kept whatever key set it was born with, indefinitely and silently.

The `[automation]` dial demonstrated the class rather than merely instantiating it: it shipped, it was absent from a pre-existing config for about six weeks, `deploy.sh --check` reported nothing, `update.sh` reported nothing, and the install test suite stayed green throughout because it only ever graded a freshly generated file.

Three factors compounded, and each independently defeated detection: there was no reconcile trigger, there was no detector, and the version stamp that could have driven a migration was inert — emitted as a hardcoded literal and compared against a template constant that had never differed.

The obvious repair is to write a reconciler. The reason this record exists is that **the propagation bug is downstream of a missing canonical home.** The schema lived in four partial places at once: the sequence of `out.append()` calls, the hand-maintained `MANAGED` set, the hand-maintained `field_to_token` map, and 437 lines of prose in `operator.toml.template`. A reconciler built without a canonical home must either re-derive the schema from the generator (fragile) or maintain a second list (a shadow SSOT). So the question is not "how do we reconcile" — it is: **where does the key set actually live?**

## Decision

**D1 — The key set is declared as data at `core/config/operator-toml-schema.json`, and it is the single source of truth.** Per key it carries section, type, `source`, default-or-none, delivered-vs-opt-in disposition, optional `enum`, `required`, `deprecated`, `since`, and the bracketed `token` where one applies. Every consumer reads that one declaration.

**D2 — The generator DERIVES its emit from the declaration; it does not merely agree with it.** This is the whole load-bearing distinction. A declaration the generator agrees with by convention is a shadow SSOT that drifts on the first hand-edit. A declaration the generator *reads* cannot drift, because there is no second copy to drift from. `MANAGED`, `MANAGED_SECTIONS` and `field_to_token` all become one-line comprehensions — a **net removal of three hand-maintained lists**, not the addition of a fourth artifact beside them.

**D3 — Key-ABSENCE means "no default"; `"default": ""` never does.** The empty string is a legitimate, load-bearing default meaning "resolve via the canonical default" for the eight `operator_instance_*` overrides and for `comms_platform`, per `depersonalization-spec.md` §4's Read-source contract. Conflating the two would turn every optional path override into a prompt. The platform already made and paid for this distinction once, in `json_has_key`, which exists precisely because a stored `""` was indistinguishable from "never resolved" and made optional tokens re-prompt forever.

**D4 — The reconciler is ADDITIVE-ONLY: it never removes a key, and never rewrites a NON-EMPTY value the operator set.** The non-empty qualifier is load-bearing and is stated rather than smoothed over: `ovd()` treats `""` as unset, so a deliberately-blanked value does take the declared default. That is pre-existing generator semantics; an absolute invariant here would have been an assertion the mechanism does not guarantee, and Stage 8 would have graded against the absolute.

**D5 — The declaration covers ADD only.** Rename, removal and retype are breaking changes: they bump `declaration_version` and route to guided recovery rather than silently mutating a `chmod 600` file the operator owns. Declaring the boundary is the point — versioned per-field migrations were rejected because a migration per field *is* per-field propagation code.

**D6 — `schema_version` is kept, narrowed, and made real.** It is the **breaking-change marker**, rendered from `declaration_version` rather than hardcoded, and genuinely compared: equal proceeds, live-newer-than-declared refuses (that case previously downgraded silently), live-older routes to guided recovery. It is explicitly **not** the delta detector — the detector is the key-set diff, because a version tells you *that* something changed and never *what*, and it depends on a human remembering to bump it, which is the exact failure that produced this defect. Per-key `since` carries the additive history instead.

**D7 — The predicate has ONE home, and `update.sh` gains no runtime dependency.** Three consumers share it — `deploy.sh` Check 70, the repo-integrity CI job, and `update.sh` Phase 2 — so it lives in `core/deploy/tools/check-operator-toml-schema.sh`, following the Check 69 primitive convention. `update.sh` calls that primitive rather than parsing JSON itself, because it carries zero JSON parsers and `--surfaces-only` is the lighter update path precisely because it depends on less. An unresolvable parser is a **loud non-zero**, never a quiet `return 0`: a delta that computes empty because the probe could not run is indistinguishable from "already reconciled", which would reproduce the exact inertness this record exists to remove.

## Decision kernel (version-agnostic)

A generated operator-owned config file has exactly one authoritative declaration of its key set; the generator reads that declaration rather than restating it; and every other consumer — checker, reconciler, external UI — reads the same one. Convergence is additive, the reconcile action is the generator invoked narrowly, and the version stamp marks breaking changes rather than detecting deltas.

## Alternatives Considered

**S1 — Status quo: the schema stays implicit in the emit plus the `MANAGED` set.** Rejected. It is unreadable by anything that is not the generator: a checker would have to *run the writer* to know what to expect, which is not a check. It also fails the milestone's coordination assignment outright, since the settings-manager consumer cannot read a Python heredoc.

**S2 — The template IS the schema: parse `operator.toml.template`, with annotation comments carrying type and default.** The strongest extend-before-create candidate and the real contender. Rejected on two grounds. First, the template's 40 keys are a **deliberate superset** of the 16 delivered, so making it the emit spec forces either emitting all 40 (changing every install's file and breaking the durability comparators for no benefit) or adding a per-key `delivered: yes/no` annotation layer — at which point it *is* this record's decision, behind a comment-based parser nobody can lint. Second, the parser cost is not hypothetical: `setup-workspace.sh` already carries two hand-rolled minimal TOML readers and `session-retro-trigger.sh` a third, so reading the artifact that exists to stop divergence would have required a **fourth**. S2 was not discarded but **inverted**: the template stays hand-authored, because 437 lines of per-key operator-facing prose is its value and generating it would be a lossy rewrite, and it gains a parity lint against the declaration in both directions. One source for *what exists*, one hand-authored artifact for *what it means*, and a check that they agree.

**S4 — A declaration as documentation only; the emit stays hand-written.** Rejected as the textbook shadow SSOT — precisely the failure `duplicate-source-discipline.md` exists to prevent. It is also the alternative most likely to be reached for later, which is why C70b exists as its falsifier.

**S5 — Versioned per-field migrations, DB-migration style, keyed on a bumped `schema_version`.** Rejected: a migration per field *is* per-field propagation code, which the card forbids by name. Its residual is genuine and is recorded as D5's coverage boundary — S5 handles rename, remove and retype, which a declarative additive reconciler does not.

**Format — TOML or YAML instead of JSON.** Rejected. YAML has zero readers in this toolchain and no declared `yq` dependency. TOML would need a fourth hand-rolled parser. JSON is the only format all consumers read with **zero** new dependencies: `json` is Python stdlib on every Python 3 (`tomllib` is 3.11+ and the reference host runs 3.9 on at least one path), `jq` is already a hard preflight dependency, and `raid-log.schema.json` is the existing in-repo precedent.

**Location — `core/schemas/` instead of `core/config/`.** Rejected, but the divergence is real enough to record: a reader looking for "the operator.toml schema" may reasonably start at `core/schemas/`. `core/schemas/` is by measurement the **markdown** schema-*document* corpus (21 of 22 files), and its single `.json` is a JSON Schema for a data artifact rather than a generator input. This declaration is a runtime generator input read at install and update time, which is what `core/config/` holds. Mitigation: `core/schemas/README.md` carries a pointer row.

## Consequences

**Adding a field costs one JSON object and zero lines of code.** Demonstrated rather than asserted: the commit delivering `[adapters]`, `[methodology]` and `[session_retro]` — 10 keys across 3 sections, taking the delivered set from 16 to 26 — is a **three-line diff in one file** with zero changed `.sh` lines.

**Three hand-maintained lists are deleted**, including the one whose own comment read "Edit BOTH or neither" and whose drift caused the v4.15 blanking defect. That defect class is closed structurally rather than by vigilance.

**An existing instance now converges** on the next deploy or update instead of never. Until it does, `deploy.sh --check` reports the delta in warn mode, naming each missing key, the version it shipped in, and the remedy command.

**Warn mode for the instance leg is deliberate.** An operator whose config is behind is the victim of this defect, not its author; red-walling their deploy would punish them for a bug the platform shipped. The posture is operator-adjustable to enforce via a mode file, so "non-blocking" is a current-posture property rather than a structural one.

**`enum` is declared but NOT yet enforced.** It feeds the settings-manager consumer's control-type selection and a future value-validity check. Declared-not-enforced is recorded here so a reader does not assume a guarantee that does not exist.

**Emit stayed byte-identical through the derivation change** on the unchanged delivered set — verified against five fixtures with a harness first shown capable of detecting three perturbations. The commit that changes behaviour is separate from the commit that changes mechanism, so each is reviewable alone.

**Residual debt, recorded not hidden.** Four hand-rolled minimal TOML parsers now exist across the codebase; this work adds none and consolidates none. `update.sh`'s multi-line-array corruption is untouched, and the declaration's `type` enum deliberately excludes `array` so nothing delivered can reach it. `SCRIPT_VERSION` is still hand-bumped; per-key `since` is what makes that non-load-bearing here.

## Reversibility

**CHEAP · HIGH** for the mechanism — every commit is a `git revert`, and the reconciler is additive-only over a file the operator owns, so no snapshot machinery is needed beyond git.

**MODERATE · HIGH** for the delivery of the three sections: reverting the code does not un-write keys already added to an operator's `operator.toml`. The residual is cosmetic — every added key is inert-at-default and `passthrough()` preserves it — but the undo is not automatic. Nothing in this record is IRREVERSIBLE.

## Related ADRs

- [ADR-022](ADR-022-platform-config-vs-operator-toml-split.md) — the `platform-config.toml` vs `operator.toml` split. Refined, not superseded: this record delivers the `[adapters]` and `[methodology]` tables §1/§4 assign to `operator.toml`, and keeps `[platform].work_board` as a deprecation alias marked `deprecated` in the declaration so no future cleanup removes it by omission.
- [ADR-121](ADR-121-settings-json-baseline-anchored-refresh.md) — the sibling pattern: a generated surface that gained a guard so a re-render cannot silently drop operator keys. `operator.toml` was the last generated surface without one.
