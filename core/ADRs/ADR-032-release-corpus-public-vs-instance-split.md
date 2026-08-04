---
title: ADR-032 — Release-corpus public-vs-instance split: ship the capability, keep per-release content operator-instance
status: Accepted
date: 2026-06-20
deciders: "operator (D-1412-Scope at the 62-close-out-registers Stage 4 plan-approval gate, 2026-06-19) + the 62-close-out-registers Stage 5 Solutioning design and its design sub-task"
tags: [architecture, distribution, release-corpus, operator-instance, public-repo-boundary, gitignore, deploy-checks]
source_observations:
  - "#1412 — the release-corpus audit trail (RELEASE_LOG, INDEX, DIGEST, notes/, plans/) is tracked in the public install-oriented repo and ships in every clone; this is maintainer content (operational detail, not PII), not install capability."
  - "Half-migration evidence (survey @ 8c164c5, 2026-06-20): deploy.sh:1458 Check 4 already drops RELEASE_LOG.md as in-repo governance ('lives at the operator-instance release-log path'); 28 references use the <OPERATOR_INSTANCE_RELEASE_LOG_PATH> token; yet the files are still tracked (git ls-files: 75 corpus files) and deploy.sh Check 32 + generate_release_index.py + automated-closeout.sh hardcode the in-repo release/releases/ paths."
  - "ADR-017 Decision 1 (four distribution surfaces) already rules S1-Package (versioned, shared, zero operator-environment leakage) vs S3-State (operator-instance, never in the package repo per ADR-012); #1412 is the application of that model to the release corpus, not a new architectural axis."
  - "#48 (RELEASE_LOG active+archive) made the leak worse by archiving content into more tracked files; abandoned and superseded by #1412."
---

<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->

# ADR-032 — Release-corpus public-vs-instance split: ship the capability, keep per-release content operator-instance

## Status

**Accepted** 2026-06-20 — design rendered at the 62-close-out-registers release Stage 5 Solutioning (#1412 / sub-task #1414); operator authorized the design-only scope at the Stage 4 plan-approval gate (D-1412-Scope, 2026-06-19). Committed here as the decision record per the ADR-007 / ADR-017 / ADR-028 / ADR-027 Stage-6 ADR-authoring precedent. **This ADR decides the architecture; the corpus migration EXECUTION is deferred** to a dedicated follow-up issue (filed post-review) per D-1412-Scope.

**Number provenance:** Authored as ADR-029 in the Stage 5 design; renumbered to **ADR-032** at Stage 6 because the contiguous global ADR sequence advanced during this release's engineering window — ADR-029 (Memory SSOT), ADR-030 (hook-registry drop-in), and ADR-031 (autonomy-ceiling hook) all landed first. `check-adr-numbers.py` confirmed 032 as the next gap-free number per the README renumber-log discipline.

## Context

The `pmo-platform` repo is simultaneously a publicly-shareable PMO **package** (which must leak zero operator content) and the maintainer's working tree (which generates a per-release audit corpus). The release corpus — `RELEASE_LOG.md`, `RELEASE_INDEX.md`, `RELEASE_DIGEST.md`, `release/releases/notes/*.md` (38), `release/releases/plans/*.md` (35) — is the maintainer's internal development narrative. It is tracked, so a fresh clone ships 30+ releases of operational detail (not PII) that bloats the clone and exposes internal process.

The platform **half-built** the fix: `deploy.sh` Check 4 already declares `RELEASE_LOG.md` operator-instance and 28 references use the `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>` token — but the files were never moved out of the tracked tree, and `deploy.sh` Check 32, `core/deploy/tools/generate_release_index.py`, and `release/tools/automated-closeout.sh` bound themselves to the in-repo `release/releases/` paths, cementing the leak. Check 32's own header comment documents the in-repo ledger as a *deliberate* target ("differs deliberately from Check 23/26"), so the divergence is documented, not accidental — it must be reconciled, not just patched.

`#48` ("bound RELEASE_LOG size" via active+archive) made it worse by archiving content into *more* tracked files; it is abandoned and superseded by this decision.

## Decision Drivers

- **No operator content in the package** — ADR-017's S1 invariant: the shared package contains zero operator-local content; local content is *instanced*, not committed (reinforced by ADR-012).
- **Ship the capability, not the history** — anyone who installs the platform runs their own releases and gets their *own* local corpus; they get the mechanism, never the maintainer's narrative.
- **Reversibility** — the content is non-PII operational detail, so a reversible HEAD-only removal suffices; an irreversible history rewrite buys nothing the threat model needs and is denied by repo settings anyway.
- **Parameterize over hardcode** (CLAUDE.md) — reuse the established `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}` resolution idiom (the ADR-017 canonical S3 resolver); invent no new variable.

## Decision

Five sub-decisions, applying ADR-017's S1-Package-vs-S3-State cut to the release corpus.

### Decision 1 — Classify by ADR-017 surface (the model)

Every release-corpus surface is **S1 (Package/capability → PUBLIC)** or **S3 (State/content → OPERATOR-INSTANCE)**:

| Surface | Class | Home |
|---|---|---|
| `RELEASE_LOG.md`, `RELEASE_DIGEST.md`, `notes/`, `plans/`, `logs/` | **S3 → instance** | `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/...` |
| `RELEASE_INDEX.md` | **SPLIT** — empty seed S1-public; filled content S3-instance | seed tracked; filled instance |
| `CHANGELOG.md` (root) | **S1 → public** | tracked (the concise public release surface) |
| `release/references/templates/*`, `standards/*` (incl. `release-corpus-schema.md`, `release-notes-standard.md`), `pipeline/*`, `release/tools/*`, `core/deploy/` checks + `generate_release_index.py`, `release/releases/README.md` + `hub-state/*.template` | **S1 → public** | tracked (the mechanism + scaffolding) |

The load-bearing rule: **the capability ships; the content instances.** Templates/schema/pipeline/tools/deploy-checks are mechanism (public); the maintainer's filled LOG/INDEX/DIGEST/notes/plans are content (instance).

### Decision 2 — Own history goes instance, with a thin public surface (Q1)

pmo-platform's own release history goes operator-instance, EXCEPT a thin public surface for transparency: **`CHANGELOG.md`** (concise, user-facing) + an **empty `RELEASE_INDEX.md` seed** (header + column row + "populated locally per release"). A cloner sees the corpus *shape* and the public changelog without the maintainer's per-release narrative.
*Opposing view (rejected):* full-instance (no public seed) — rejected because it leaves no public navigation shape; full-public (status quo) — rejected as the leak itself (ADR-017 S1 breach).

### Decision 3 — `notes/` are instance; the standard/template are public (Q2)

`release/releases/notes/*.md` (the maintainer's filled per-release notes) → instance. `release-notes-standard.md` + the notes template (the mechanism) → public. Same template-public / content-instance split as the LOG and the registers.

### Decision 4 — HEAD-only removal; git-history scrub REJECTED (Q4)

The migration removes content **HEAD-only**: `.gitignore` + `git rm --cached` + physical move to the instance. **Git-history scrub is rejected.**
*Rollback-infeasibility note (per CLAUDE.md reversibility discipline):* a full-history scrub (`git filter-repo` + force-push) would be **IRREVERSIBLE** on a public repo; force-push is **denied in repo settings**; and `refs/pull/*` retain pre-rewrite commits regardless, so a rewrite is *insufficient* to flip content private. The content is **non-PII operational detail**, so the threat model is "don't ship it in new clones" — fully met by HEAD-only removal, which stays **MODERATE / `git revert`-reversible**. Choosing the reversible path is the deliberate decision; the irreversible path is not gated, it is declined.

### Decision 5 — Register placement: template public, filled content instance (Q5)

The combined close-out register **TEMPLATE** ships PUBLIC at `release/references/templates/release-learnings-register-template.md`. The **FILLED per-release register CONTENT** writes to `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/...`, never the tracked tree. This is the rule #360/#361 build on; their `stage-13-close.md` §6 schema edit points filled output at the instance path.

### Bootstrap (Q3)

`install.sh` lays down the empty instance corpus skeleton (`${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/{plans,notes}/` + empty LOG/INDEX/DIGEST seeds, idempotent); the first local release's Stage 13 populates it; `generate_release_index.py` self-heals (writes a fresh INDEX when none exists).

### Canonicalization note — `CLAUDE_WORKSPACE_ROOT`, not `PMO_INSTANCE_PATH`

The operator-instance corpus root resolves via **`${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}`** — the canonical S3-content resolver ADR-017 ruled (Decisions 1 + 4: "S3 operator content workspace-relative under `CLAUDE_WORKSPACE_ROOT`, default `$HOME/Claude`"). It does **not** use `PMO_INSTANCE_PATH`. ADR-017 (this ADR's cited authority) explicitly names `PMO_INSTANCE_PATH` "an orphan variable (never set anywhere)" and the #504/#528/#529 path-portability defect, with `CLAUDE_WORKSPACE_ROOT` canonical. There is a live tension to name honestly: `deploy.sh` still carries 21 `${PMO_INSTANCE_PATH:-<default>}` fallthroughs (the orphan var falls through to its default on every read, so the paths *resolve* but via the non-canonical name). That is **convergence-debt** the deferred execution issue resolves — re-pointing those reads toward `CLAUDE_WORKSPACE_ROOT` — not a second canonical variable. This ADR states the canonical form so downstream surfaces (the deferred-migration plan below, the register-placement rule, and #360/#361) inherit the correct resolver from the start.

## Consequences

**Positive:** A fresh clone ships zero maintainer content; the platform is genuinely plug-and-play (a second install produces its own local corpus); the spec-vs-reality divergence (Check 4 says instance, Check 32 says in-repo) is closed; the thin public surface preserves transparency.

**Negative / obligations:** A deferred execution issue must re-point 4 tools + `.gitignore` + 2 reference docs, reconcile the Check-32 header comment, and converge the 21 `deploy.sh` `PMO_INSTANCE_PATH` fallthroughs onto `CLAUDE_WORKSPACE_ROOT`. The migrating release hits a reflexive-pipeline hazard (its own close-out writes to the path it is moving) — handled by the introducing-release-exempt discipline (author that close-out directly to the new instance path). One new install-time bootstrap obligation (bounded, idempotent).

**Neutral / known:** Reversibility MODERATE throughout (HEAD-only); no `core/schemas/` changes; no Anthropic upstream surface. The public `CHANGELOG.md` is the sole public projection of the now-instance `notes/`; its Section-6a source is intentionally instance-side, so CHANGELOG entries are **not regenerable from a clean clone** — a documented design choice (the thin-public-surface trade of Decision 2), not an oversight.

## Alternatives Considered

| Decision | Chosen | Rejected (kill-reason) |
|---|---|---|
| Own history (Q1) | thin public surface (CHANGELOG + empty INDEX seed) | full-instance (no public shape); full-public (ADR-017 S1 leak) |
| Removal method (Q4) | HEAD-only | history-scrub (IRREVERSIBLE, force-push denied, refs/pull/* persist, non-PII → unneeded); delete-and-recreate (disproportionate) |
| `notes/` (Q2) | instance content / public standard | notes-public (the leak); current-major-public (stateful boundary for marginal gain) |
| Bootstrap (Q3) | install.sh scaffolding + generator self-heal | separate bootstrap CLI (ADR-020 over-promotion) |
| Instance-root variable | `CLAUDE_WORKSPACE_ROOT` (ADR-017 canonical) | `PMO_INSTANCE_PATH` (ADR-017-named orphan; never set; the #504/#528/#529 defect) |

## Deferred-migration plan

The execution issue (filed post-review per D-1412-Scope) carries: `.gitignore` block + negations; `git rm --cached` + move of LOG/DIGEST/notes/plans to `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/releases/`; `RELEASE_INDEX.md` → empty public seed; re-point Check 32 + `generate_release_index.py` + `automated-closeout.sh` + `stage-13-close.md` §5 Phase B + `release-corpus-schema.md` (and converge the 21 `deploy.sh` `PMO_INSTANCE_PATH` fallthroughs onto `CLAUDE_WORKSPACE_ROOT`); AUDIT `check-doc-links.py`; `install.sh` bootstrap; cross-PR overlap re-audit at its Stage 9/12. AC: fresh clone shows no maintainer content; generator self-test PASS against instance; Check 32 resolves to instance; second-install produces its own corpus. Reversibility MODERATE / MEDIUM.

## Related ADRs

- **ADR-017** (distribution architecture — S1/S3 surfaces + the canonical `CLAUDE_WORKSPACE_ROOT` resolver; the model this applies)
- **ADR-012** (instance-content de-scope to operator-local)
- **ADR-013** (install-path resolution via operator.toml)
- **#1412** (parent design issue; closed design-only) · **#48** (abandoned archive-split, superseded) · **#360 / #361** (registers — template public, content instance per Decision 5)

## References

- #1414 — the Stage 5 Solutioning sub-task under which this record's design was rendered.
