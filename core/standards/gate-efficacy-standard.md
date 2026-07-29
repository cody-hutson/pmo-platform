---
title: Gate-Efficacy Standard
purpose: The normative standard that an automated gate's green verdict must mean the invariant it claims actually holds — so a gate that goes green without asserting its invariant is treated as a defect, not a pass.
type: standard
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
consumers: authors of any deploy-check, hook, or release-executor quality gate; the gate-evaluation and gate-criteria specs; CLAUDE.md §No status theater (green-must-mean-the-invariant-holds)
---
<!-- reference-durability: allow-link -->
<!-- repo-integrity: allow-issue-ref -->
# Gate-Efficacy Standard

## Purpose

An automated gate earns trust only when a green verdict *means* the invariant it claims holds. A gate that goes green without asserting its invariant is worse than no gate: it manufactures false confidence, and the failure it was built to catch ships behind a passing check. This standard is the normative contract for the platform's **automated-assertion gates** — the integrity checks in `core/deploy/deploy.sh --check` and the jobs in `.github/workflows/`. It names three requirements every such gate MUST satisfy, plus a posture rule that decides whether a red verdict actually blocks.

The governing rule, stated unconditionally: every automated-assertion gate MUST verify the invariant it claims by inspecting the content that embodies that invariant — never a proxy signal that merely correlates with it — MUST self-declare whether it is required or advisory, and MUST be auditable both for false-confidence (a gate that passes when it should fail) and for coverage gaps (an invariant with no gate at all).

## Scope boundary — two gate classes, this standard governs one

The platform runs two distinct classes of gate. They share the word "gate" and nothing else; conflating them duplicates governance. This standard governs exactly the second class, and references — never redefines — the first.

| Gate class | What it gates | Surface | Owner document |
|---|---|---|---|
| **Pipeline stage-transition gates** | Movement between the 13 pipeline stages — Stage-N readiness, the named G1–G3 gates, GO/NO-GO decisions | Issue fields, anchors, artifacts; LLM-judged | `core/schemas/gate-criteria-spec.md` + `core/schemas/gate-evaluation-spec.md` |
| **Automated-assertion gates** | A code/corpus invariant on every change — package freshness, mirror sync, reference validity, depersonalization, link integrity | `deploy.sh --check` Check 1–N; `.github/workflows/*` jobs | **This standard** |

A pipeline stage-transition gate asks a judgment question ("is this work ready to advance?") and is answered by an evaluator against criteria. An automated-assertion gate asks a mechanical question ("does this byte-level invariant hold?") and is answered by a script that either finds the violation or does not. This standard does not touch the stage-transition class; for that, read `core/schemas/gate-criteria-spec.md`.

## Requirement (a) — Assert by content, not by proxy

Every automated-assertion gate MUST verify its claimed invariant by inspecting the **content** that embodies the invariant. A **proxy signal** — a value that correlates with the content but can diverge from it — is FORBIDDEN as the sole, verdict-bearing assertion.

The canonical failure this requirement closes: a package-freshness gate that compared file modification time (`mtime`) instead of file content. A modification time is a proxy for "rebuilt from current source" — it correlates, until someone runs `touch` (or a fresh `git checkout` resets every timestamp to checkout-time), at which point a stale package passes a green gate. The fix is to assert the content directly: hash what is *in* the artifact and compare against a known-good baseline.

### Proxy-vs-content decision table

| Claimed invariant | Proxy (FORBIDDEN as sole assertion) | Content assertion (REQUIRED) |
|---|---|---|
| "package is fresh / rebuilt from source" | file mtime (`stat -f '%m'` compare) | content-manifest hash vs committed baseline |
| "mirror matches source" | mtime, or mere file presence | `diff -q` byte-compare (already content — compliant) |
| "required field present and well-formed" | line-count, file-size | regex match on the field's value (already content — compliant) |
| "no forbidden token introduced" | filename or path heuristic | `grep` over the changed-file **content** of the base..head delta (already content — compliant) |
| "referenced file exists / anchor resolves" | link-text presence | resolve the target path and the heading slug (already content — compliant) |

Most existing gates already assert content (the right three columns of every row above are mostly already in place). The rule's bite is the first row: any freshness or rebuild claim asserted by timestamp is non-compliant and MUST be converted to a content hash.

### Pre-filter escape valve

A proxy MAY serve as a cheap pre-filter that *gates entry to* the content assertion, provided a content assertion remains the **verdict-bearing** step. Example: "if mtime is unchanged, skip the expensive hash and pass; if mtime is newer, run the hash and let the hash decide." This keeps the common case fast while making content the source of truth — a `touch` that bumps mtime forces the hash, and the hash (unchanged content) still passes correctly; a real source edit forces the hash, and the hash fails. The proxy narrows *when* the content check runs; it never *substitutes* for the content check's verdict.

## Requirement (b) — Required-vs-advisory declaration

Every automated-assertion gate MUST self-declare its enforcement posture in a machine-greppable form, so a reader (and an auditor's `grep`) can tell whether a red verdict blocks or merely signals — without reverse-engineering branch-protection settings or warn-mode files.

### Declaration schema

One declaration per gate, carrying these fields:

- **`posture: required | advisory`** — `required` means a red verdict blocks merge or ship (a branch-protection required check, or a `deploy.sh --check` block that is always-enforce). `advisory` means red is a signal that never blocks (a warn-mode `--check` during its shakedown window, or a workflow that no-ops on a path-skip).
- **`enforcement-surface:`** — where the posture is *realized*: the branch-protection rule name, or `always-enforce` in `--check`, or the `deploy-check.mode` warn-window.
- **`skip-semantics:`** (workflows only) — REQUIRED when a workflow carries a `paths:` or `on:` filter that can make GitHub report the check as skipped/absent for an unrelated PR. The declaration states whether absence is treated as a pass (`absent-is-pass`, the advisory posture) or whether the workflow runs filter-free to *always report a result* (the always-reports posture — the established `reference-durability.yml` pattern).

### Realization per surface

**In `deploy.sh`:** the declaration is the existing inline Check-header comment, made uniform. Each `# Check N — <name> (<posture>; <enforcement-surface>)` header carries an explicit `required` or `advisory` token. The mapping from the historical free-text is fixed: a check that today says `always-enforce` is **required**; a check that today says `warn-mode initial` is **advisory** for the duration of its shakedown window (it becomes required at flip-to-enforce). This standard makes the token canonical and greppable; it does not change any check's behavior.

**In `.github/workflows/`:** the declaration is a standardized header comment block placed near the top of the file, formalizing the prose idiom that `reference-durability.yml` and `skill-count-imp-check.yml` already carry. The greppable form:

```yaml
# gate-efficacy: posture=required  enforcement=branch-protection:"<check name>"  always-reports=yes
#   invariant: <one line — what this gate asserts, by content>
#   falsification: <one-line repro that MUST turn this gate red>
```

or, for an advisory path-scoped workflow:

```yaml
# gate-efficacy: posture=advisory  enforcement=path-filtered  skip-semantics=absent-is-pass
#   invariant: <one line — what this gate asserts, by content>
#   falsification: <one-line repro that MUST turn this gate red on an in-scope change>
```

A `posture=required` declaration records the *intended* posture and names its enforcement surface. It does NOT itself edit branch-protection — that is a repository-settings change made operator-side, outside the tree. Reconciling a declared `required` posture against the actual branch-protection configuration is a coverage-audit item under Requirement (c), not a file edit any single gate performs. The comment is the declaration of intent; the branch-protection rule is the enforcement; the two are kept honest by the audit.

### Requirement (b′) — A required gate must be CI-enforced, not deploy-time-only

A gate declared `required` MUST run **pre-merge in CI** — its red verdict must be reachable as a blocking status check before a change lands on the main branch. A check that runs only at deploy time (after merge, on the operator's machine) cannot block a merge; declaring it `required` while it has no CI surface is a posture that the enforcement cannot honor. Such a check is **advisory** until a CI mirror exists.

This dimension classifies a real class of gap: a `deploy.sh --check` assertion that is genuinely load-bearing but exists only as a post-merge, deploy-time check has no pre-merge teeth. The required-vs-advisory declaration is the instrument that surfaces this honestly — a deploy-time-only check declares `advisory` (with `enforcement-surface: deploy-time-only`) until its CI mirror ships, at which point the declaration flips to `required`. The declaration never claims an enforcement the surface cannot deliver.

The pairing of a deploy-time check with a CI mirror is the structural pattern: the deploy-time check is the operator-machine safety net; the CI mirror is the pre-merge gate. A check that should block a merge needs both, and its posture declaration is `required` only once the CI mirror is in place.

## Requirement (c) — False-confidence and coverage auditability

The gate corpus MUST be auditable for two distinct failure modes. Each has a prescribed audit method.

### False-confidence — a gate that passes when it should fail

A false-confidence gate goes green without asserting its invariant (the mtime-package case under Requirement (a); the broad class of "the check is present but toothless"). 

**Audit method:** every gate carries a **falsification test** in its declaration — a one-line, concrete repro describing the tampered or stale input that MUST flip the gate red. The falsification test is not prose about the gate; it is an executable recipe ("`touch` the package and it must stay green; mutate one source byte without rebuilding and it must turn red"). A reviewer, or a Dev-Testing spoke, runs the falsification test and empirically confirms the gate fails when it should. A gate whose falsification test cannot be made to fail it is a false-confidence gate by definition, and the audit catches it.

### Coverage gap — an invariant with no gate

A coverage gap is a named platform invariant that no gate enforces (the governance-as-code class: rules the platform states but does not mechanically check).

**Audit method:** a **gate-coverage register** — a table mapping each declared platform invariant to its enforcing gate and that gate's posture. An invariant with an empty "enforcing gate" cell is a *named* gap, visible and trackable, not a silent omission. This mirrors the coverage-matrix discipline the platform already applies elsewhere ("an empty cell is a named gap, not a silent omission"). The register is authored incrementally: each release that touches a gate adds or updates that gate's row. The register is never required to be exhaustive in one pass — exhaustive population of every check and workflow is a standing coverage-completion effort, not a precondition for the register to be useful.

## Gate-coverage register (seed)

This register seeds the invariant→gate→posture mapping with the gates this standard's introducing release touches. It is intentionally partial: the remaining `deploy.sh` checks and workflows are added by the releases that touch them, and the bulk back-fill of every existing check header is a tracked coverage-completion follow-up (see the Provenance block). An empty or absent row is a named gap, not a claim of coverage.

| Invariant (what must hold) | Enforcing gate | Surface | Posture | Falsification test (MUST flip it red) |
|---|---|---|---|---|
| Every rostered skill's `.skill` package reflects current source content | `deploy.sh --check` Check 7 (package-freshness, content-hash) | deploy-time | required (always-enforce) | Mutate one byte in a skill source file without rebuilding the package → Check 7 FAILS. A `touch` of the package alone → Check 7 stays GREEN (content current). |
| Every rostered skill SKILL.md is canonical-structure compliant (required frontmatter, references threshold, ≥3 failure modes) | `deploy.sh --check` Check 6 (canonical-structure compliance) | deploy-time | required (always-enforce) | Remove a required frontmatter field, or drop a skill below 3 failure-mode entries → Check 6 FAILS. |
| Every workspace rules-mirror file is byte-identical to its in-repo source | `deploy.sh --check` Check 9 (mirror-pair sync) | deploy-time | advisory (warn-mode initial; required at flip-to-enforce) | Edit a workspace `~/.claude/rules/<file>.md` mirror so it diverges from its `core/rules/` source → Check 9 WARNS (advisory) / FAILS (post-flip). |
| No durable-corpus change introduces a fragile reference (markdown link, version-cutover apparatus, mis-placed bare issue ref, raw issue/PR/milestone URL) | `.github/workflows/reference-durability.yml` | CI (pull_request, no paths filter) | required (always-reports) | Add a markdown link sequence or a version-cutover clause to a durable-corpus file in a PR → the workflow FAILS on the added line. |
| No changed file introduces an integrity violation (operator PII in C6 domains, an unresolvable/mis-placed issue ref, a dead file/anchor link) | `.github/workflows/repo-integrity.yml` (3 gates) | CI (pull_request, no paths filter) | required (always-reports) | Add the operator's name/email to a `core/`/`release/`/`operations/`/`packages/` file, or a `#N` that 404s outside a reference block → the relevant gate FAILS. |
| A path-scoped workflow never blocks a PR as required-but-absent | `.github/workflows/release-link-check.yml`, `release-tooling-smoke.yml`, `skill-license-check.yml` | CI (pull_request, paths-filtered) | advisory (absent-is-pass) | On a PR that does not touch the filtered paths, the check is skipped and absence is treated as pass; on an in-scope change, the gate runs and a broken target FAILS it. |
| Every `core/hooks/block-*.sh` maps to its correct owning doc (the 7 bypass-mode hooks ⇒ a per-hook source under `core/rules/bypass-mode-readiness/` + a row in the generated index; `block-skill-direct-edit` ⇒ `canonical-skill-structure.md`; `block-fragile-refs` ⇒ `reference-durability-standard.md`) — an ownership-scoped bijection, not a forced single-file one | `deploy.sh --check` Check 37 (hook-registry completeness) | deploy-time | advisory (warn-mode initial; required at flip-to-enforce) | Add a `core/hooks/block-foo.sh` with no owner-manifest entry → Check 37 WARNS (advisory) / FAILS (post-flip). Delete a per-hook source whose script still exists → Check 37 WARNS / FAILS. This is the gate that makes the live 5/7/9 registry drift (per ADR-030) structurally impossible. |
| The committed `core/rules/bypass-mode-readiness.md` is byte-identical to what `build-hook-registry.py` regenerates from its sources (regenerate-and-diff freshness) | `deploy.sh --check` Check 38 (hook-registry index freshness) | deploy-time | required (always-enforce) | Edit a per-hook source (e.g. add a rule row) without regenerating → Check 38 FAILS (committed index drifts from sources). Regenerate + commit → Check 38 GREEN. Deterministic generator, so a non-empty diff is unambiguous drift. |
| Every `deploy.sh`-rostered skill (`OPERATIONS_SKILLS` + `RELEASE_SKILLS` + `CORE_SKILLS`, canary excluded) has a `core/skills/registry.md` `## Configuration Items` row; symmetrically every row is a roster member and resolves to a live `SKILL.md` | `.github/workflows/skill-registry-currency-check.yml` (CI mirror of `deploy.sh --check` Check 5(d) row layer) | CI (pull_request, no paths filter) | advisory (ci-enforce, red-on-violation; not yet a required branch-protection context) | Roster a skill in a `deploy.sh` `*_SKILLS` array without adding its `registry.md` row → the check FAILS (exit 1) naming the skill; the one-line `NAME=(a b)` array-garbage form → shape-guard exit 3; an absent `registry.md` → exit 3. |
| The committed `core/rules/bypass-mode-readiness.md` is byte-identical to what `build-hook-registry.py` regenerates — asserted PRE-MERGE (the CI mirror of the deploy-time Check 38 row above) | `.github/workflows/deploy-check-ci.yml` (thin caller of `deploy.sh --check-required-subset` — the enumerated load-bearing subset, today Check 38 only; EXCLUDES any check with a dedicated mirror so no invariant is double-gated) | CI (pull_request, paths-filtered) | required (warn-mode-initial; flips when `.github/deploy-check-ci.enforce` token → `enforce` AND the job is added to branch-protection required checks) | Edit a per-hook source under `core/rules/bypass-mode-readiness/` without regenerating the index → the subset gate reports STALE (warn: summary + exit 0; enforce: red + exit 1). A fresh index → green. |
| Every VERIFIED `RELEASE_LOG` row at/after the cutover carries its complete Stage-13 output-set (INDEX row + DIGEST entry + NOTES file [+ tag + published Release]) — asserted PRE-MERGE (wires the close-completeness probe + sentinel that previously shipped deploy-time-only, with no CI caller) | `.github/workflows/close-completeness.yml` (thin caller of `deploy.sh --check-close-completeness`, Check 48's `_cc_compute_verdict`) | CI (pull_request, paths-filtered `release/releases/**`) | required (warn-mode-initial; dormant until the cutover is armed; flips when `.github/close-completeness.enforce` token → `enforce` AND the job is added to branch protection) | Add a VERIFIED `RELEASE_LOG` row (at/after the armed cutover) missing its INDEX/DIGEST/NOTES companion → the gate reports INCOMPLETE (warn: summary + exit 0; enforce: red + exit 1). A complete output-set, or the dormant default → green/SKIP. |
| Every `RELEASE_LOG` row at/after the corpus cutover implies its INDEX row + DIGEST entry + NOTES file (+ tag + published Release post-cutover) — the highest-frequency documented release failure, asserted PRE-MERGE (the CI mirror the deploy-time-only Check 32 lacked; Check 32 gains a `posture: required` header) | `.github/workflows/release-corpus-completeness.yml` (thin caller of `deploy.sh --check-release-corpus`, Check 32's `_c32_compute_verdict`; the SINGLE canonical required-context for Check 32 — the required-subset runner EXCLUDES it, so no double-gating) | CI (pull_request, paths-filtered `release/releases/**`) | required (warn-mode-initial; flips when `.github/release-corpus-completeness.enforce` token → `enforce` AND the job is added to branch protection) | Present a `RELEASE_LOG` row with its INDEX row / DIGEST entry / NOTES file absent → the gate reports INCOMPLETE (warn: summary + exit 0; enforce: red + exit 1). A complete output-set for every in-scope row → CLEAN/green. |
| Every rostered skill's `.skill` package reflects current source content — enforced PRE-MERGE (the CI mirror of the deploy-time Check 7 row above; closes the class where a skill-source edit merged green with a stale package, caught only at Stage-13 close-out) | `.github/workflows/skill-package-freshness.yml` (thin caller of `deploy.sh --check-package-freshness`, Check 7's `_c7_compute_verdict`; the workflow path-filters the TRIGGER only — no per-skill diff-scoping logic) | CI (pull_request, paths-filtered skill sources + `packages/*.skill`) | required (warn-mode-initial; flips when `.github/skill-package-freshness.enforce` token → `enforce` AND the job is added to branch protection) | Edit a `skills/*/SKILL.md` or its `references/` without rebuilding the `.skill` package → the gate reports STALE (warn: summary + exit 0; enforce: red + exit 1). Rebuild via `build-skill-packages.sh` + commit the package + `.sha256` sidecar → FRESH/green. |
| Every VERIFIED `RELEASE_LOG` row at/after the emission cutover carries >=1 event row for each MUST class in the orchestration playbook's `EMISSION-CONTRACT` block, resolved via the `pipeline-event-log-schema.md` § 2a release join key (rung 1 slug → rung 2 milestone subject; the ambiguous legacy rung 3 is excluded so a non-unique match can never count as satisfying an obligation) | `deploy.sh --check` Check 61 (decision-emission-minimum-set) + `deploy.sh --check-decision-emission` probe, invoked from `stage-13-close.md` Phase A8.2 | deploy-time (**no CI mirror — deploy-time-only**) | advisory (warn-mode initial, committed default; flips when `.github/decision-emission.enforce` token → `enforce` AND a CI mirror exists per Requirement (b′)) | Seed a VERIFIED post-cutover release whose event log carries zero rows for it → verdict INCOMPLETE (`deploy.sh --self-test` group DE, assertion DE-2). Seed all 3 MUST classes keyed on the slug → CLEAN. Seed only 2 of 3 → INCOMPLETE (DE-4, defeats a predicate that degenerates to "it emitted something"). Seed all 3 keyed on the legacy `vX.Y` value only → INCOMPLETE (DE-5, defeats a predicate that accepts any key). Remove the asserted-set file → NOSET, never a silent pass (DE-9). |
| The class set a downstream gate ASSERTS on is a subset of the MUST rows the orchestration playbook INSTRUCTS (CIAC-3) — an asserted class the playbook never instructs is a gate that can only ever fail | `release/tools/check-emission-contract-subset.sh` over `core/deploy/allowlists/decision-emission-asserted-set.txt`, invoked from `.github/workflows/release-tooling-smoke.yml` (the live relation AND the lint's own `--self-test` in the same step) | CI (pull_request, paths-filtered — filter includes the playbook and the asserted-set file, so a contract-block-only edit still triggers) | advisory (absent-is-pass, per the path-filtered row above) | Add a class to the asserted set that is not a MUST row of the `EMISSION-CONTRACT` block → the step exits 1 naming the class. Regress the lint into always-passing → its `--self-test` negative cases (uninstructed class exits 1; CONDITIONAL-only class exits 1) fail the same step. **The prior state of this gate is itself the canonical Requirement (c) finding: the lint shipped with zero call sites and SKIP-returned 0 without an asserted set — present, greppable, and asserting nothing.** |

## Flip-decision status (warn-mode `deploy.sh --check` + stage-gate criteria)

This subsection records the enforce-flip decision for the warn-mode `deploy.sh --check` cohort and the warn→enforce stage-gate criteria. It is authored incrementally alongside the register: each release that evaluates a warn-mode gate for graduation records its decision here (flipped, or "shakedown continues" with a reason).

**The one-token flip mechanism is already in-tree and proven.** A check graduates warn→enforce by a single committed change — a per-check `MODE=$(resolve_check_mode "<check-id>" "enforce")` committed default plus a bespoke gated emitter (live at Check 22 `g1-enforcement`, Check 47 `release-body-drift`, and the `version-freeness` per-check mode); a CI gate graduates by flipping its committed `.enforce` sentinel token. No new mechanism is required to flip any gate below — only the drain evidence and the operator's branch-protection change.

**Flip decisions — ALL DEFERRED (evidence-based).** The shakedown-drain signal for the warn-mode cohort is the per-check `*-warn-log.jsonl` (and the shared operator-instance `deploy-check-warn-log.jsonl`). That signal is **git-ignored and absent in a fresh checkout / CI**, so it is not readable by a pull-request agent; a green-on-current-tree snapshot is NOT the shakedown criterion (the drain HISTORY is). A current full `deploy.sh --check --warn` run over the cohort still emits hundreds of warn-findings (the cohort is actively warning, not drained). No gate is flipped this pass; each remains **advisory (warn-mode, shakedown continues)**, with the flip owned by the operator once the local warn-log is confirmed drained.

| Gate | Current posture | Flip decision |
|---|---|---|
| `deploy.sh` Checks 8 / 10 / 13b / 34 / 35 / 36 / 37 (shared warn-mode cohort) | advisory (warn) | shakedown continues — drain signal operator-instance/git-ignored, not repo-derivable; and the cohort is still warning at scale. Deferred to the operator. |
| `deploy.sh` Checks 9 / 11 / 30 (dormant per the posture back-fill) | dormant / advisory | deferred — a dormant check is not a flip candidate until it is reactivated; do not flip. |
| stage-gate G3-14 / G3-15 (Bundle metrics; `2–3 release` threshold) | advisory (warn → enforce) | shakedown continues — the `[CALIBRATE-AFTER-3]` threshold is not demonstrably met with drain evidence a PR agent can read. Deferred. |
| stage-gate G-CL7 / G-CL8 (Stage-13 close; `2–3 release` threshold) | advisory (warn → enforce) | shakedown continues — deferred pending drain evidence. |
| `deploy.sh` Check 61 (decision-emission) | advisory (warn) | **DEFERRED — no drain evidence can exist yet.** The gate SKIPs at ship (zero VERIFIED releases exist strictly after the cutover anchor at merge time) and cannot fire on its introducing release (orchestration-playbook.md § 4a.4 reflexive exemption), so its ship-time guarantee is nil and real coverage begins at the *next* release's close. The flip is an operator decision after ≥2 post-cutover closes produce a readable hit-record; **never auto-promoted by hit count** (`progressive-rollout-convention.md`, which owns the ladder). A CI mirror is a precondition for `posture: required` under Requirement (b′) — the check is deploy-time-only today and its declaration must not claim an enforcement the surface cannot deliver. Note the ladder walked is `warn → enforce → removed`: the `shadow` rung is **unreachable** in this codebase (`resolve_check_mode()` accepts `enforce\|warn\|off` only), so the gate enters at the lowest *implementable* rung — recorded explicitly rather than silently rung-skipped. |

Reconciled against `gate-criteria-spec.md`: G3-14 / G3-15 / G-CL7 / G-CL8 retain their declared `auto (warn → enforce)` posture — they are correctly still in shakedown, so no spec edit is needed (a "still warn" edit would be redundant). When a gate's local warn-log is drained to zero-false-positives, apply the one-token flip above, update its row here, add the CI job to branch-protection required checks where applicable, and validate it FAILS closed on its falsification input.

## Consumer references

- `core/deploy/deploy.sh` — the Check headers are the deploy-side declarations; Check 7 is the reference implementation of Requirement (a)'s content-hash conversion.
- `core/deploy/tools/build-skill-packages.sh` — emits the committed content-manifest baseline (`packages/<skill>.skill.sha256`) that Check 7 compares against.
- `.github/workflows/*.yml` — each carries a `# gate-efficacy:` header declaration per Requirement (b).
- `core/rules/skill-deployment.md` — documents the Check 7 package-freshness semantics for the deploy audience.
- `core/schemas/gate-criteria-spec.md` — owns the *other* gate class (pipeline stage-transition gates); this standard references it at the scope boundary and does not redefine it.

## Reversibility

MODERATE. The standard is a normative reference document; adopting it changes how gates are authored and audited going forward, and the Check 7 conversion changes a verdict mechanism. Reverting the standard is a documentation change (CHEAP in isolation); reverting the Check 7 content-hash back to mtime would re-open the false-confidence it closes (the reason the conversion is MODERATE, not CHEAP — the prior state is a known-defective state). Confidence: HIGH that the content-not-proxy requirement is correct; the design is grounded in an observed false-confidence failure and an empirically-confirmed rebuild-stable hash.

## Provenance

This standard graduated from a pattern review over three observations, all in the release-ops domain, converging on the mechanism "automated gates that do not verify what they claim":

### Source(s)
- #1080 — Check 7 package-freshness was mtime-based, so a stale `.skill` passed on a fresh checkout (the originating false-confidence instance).
- #312 — adversarial review of CI/git workflows that found gates going green without asserting the invariant, and named the missing required-vs-advisory declaration.
- #313 — the governance-as-code coverage-expansion roadmap (invariants with no gate; the natural umbrella for the bulk coverage-register population and the back-fill of the remaining check-header posture tokens).

## Version History

| Version | Change |
|---|---|
| Introduced | Initial standard — three requirements (content-not-proxy, required-vs-advisory declaration, false-confidence/coverage auditability) + Requirement (b′) CI-enforced-not-deploy-time-only + the seed gate-coverage register. |
