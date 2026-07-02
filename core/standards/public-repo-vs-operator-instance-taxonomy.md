---
title: Public-Repo vs. Operator-Instance Taxonomy
purpose: K1 standard articulating the content-nature classification (UNIVERSAL-PUBLIC / CUSTOMIZABLE-PUBLIC / OPERATOR-INSTANCE) that determines whether an artifact is git-tracked in the public repo, ships as a customizable template, or remains operator-machine-local. Composes with (does NOT restate) `knowledge-architecture.md` (K1-K5 tiers), `universal-vs-release-pipeline-split-rule.md` (subdirectory placement), `public-repo-gitignore-template.md` (extraction patterns), and `secrets-handling-policy.md` (C1-C7 secrets).
type: standard
status: ACTIVE
consumers: "authors + Stage-5 placement decisions (apply the UNIVERSAL-PUBLIC / CUSTOMIZABLE-PUBLIC / OPERATOR-INSTANCE classification to decide git-tracked vs template vs operator-local); Stage-5/6 git-tracking-decision (§7 — durable/derived/runtime classification of the already-tracked set + the four verdict tokens); universal-vs-release-pipeline-split-rule.md (operates above this classification for subdir placement); public-repo-gitignore-template.md (the extraction-pattern surface this classification feeds)"
composes_with: [knowledge-architecture.md, universal-vs-release-pipeline-split-rule.md, public-repo-gitignore-template.md, secrets-handling-policy.md, composition-surface-spec.md, depersonalization-spec.md, hub-session-continuity.md]
reversibility: CHEAP / Confidence HIGH
---

# Public-Repo vs. Operator-Instance Taxonomy

## Purpose

This standard is the **content-nature classifier** for every state-bearing artifact in pmo-platform. It answers a single question:

> **Does this artifact ship in the public repo, or stay local to the operator's machine?**

The classification is orthogonal to subdirectory placement (`core/` vs. `release/references/`, owned by [`universal-vs-release-pipeline-split-rule.md`](universal-vs-release-pipeline-split-rule.md)) and to knowledge-tier (K1-K5, owned by [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md)). All three axes apply to every file independently — a file is simultaneously some-tier × some-subdirectory × some-public-class.

This taxonomy owns only the **public-class** axis. Sibling standards own the other two.

---

## §1 The three classes

Every artifact in pmo-platform — codified standards, runtime substrate, runtime artifacts, templates, operator state, secrets — maps to exactly one of these three classes.

| Class | Git-tracked in public repo? | Read by | Examples |
|---|---|---|---|
| **UNIVERSAL-PUBLIC** | Yes — verbatim | Any participant in the system (hub, spokes, downstream consumers, future operators) | `core/standards/*`, `release/references/pipeline/stage-*.md`, `release/releases/plans/vX.Y_RELEASE_PLAN.md`, `release/releases/notes/vX.Y_RELEASE_NOTES.md` |
| **CUSTOMIZABLE-PUBLIC** | Yes — as template | Any participant reads the template; operator's runtime instance is local | `core/CLAUDE.md.template`, `core/config/operator.toml.template`, `.env.example` / `.env.template`, `release/releases/hub-state/*.template` (schema templates); operator's runtime instance (e.g., `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/pending-approvals.md`) lives at operator-local path and is NOT git-tracked |
| **OPERATOR-INSTANCE** | No — `.gitignored` or outside repo | Only the originating operator's machine | `projects/`, `personal/`, `pmo-instance/`, `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/*` (runtime hub-state instance), `~/.claude/<tool>/<state>.log`, `.claude/settings.local.json`, secrets per [`secrets-handling-policy.md`](secrets-handling-policy.md) C1-C7 |

---

## §2 The apply test

To classify any artifact, apply this single test:

> **Does any participant outside the originating operator's session need to read this?**

- **YES, verbatim** → UNIVERSAL-PUBLIC
- **YES, with operator-customization seam** → CUSTOMIZABLE-PUBLIC (template tracked, instance local)
- **NO** → OPERATOR-INSTANCE

"Participant" means any of: a spoke session in this release, a future hub session resuming this release, a downstream consumer of a release artifact (an operator reading the release notes), a future operator cloning the repo. If any of those need it, it ships.

### §2.1 Why the apply test isn't "would it be nice to share?"

The test is **strict necessity**, not optional convenience. Three reasons:

1. **Self-containment is a release blocker.** Per [`depersonalization-spec.md`](depersonalization-spec.md) and the public-repo discipline, every tracked file must be self-contained — no operator handle, no absolute paths, no cross-repo issue refs that don't resolve. Operator-specific content fails this gate at audit time.
2. **Spokes can't see operator-local files.** Hub-and-spoke sessions run in isolated worktrees. If a spoke needs an artifact and it exists only on the hub operator's local disk, the spoke fails at chip-execution time. Git is the substrate that makes the architecture function — UNIVERSAL-PUBLIC isn't a "nice-to-have," it's the operating mechanism.
3. **Operator-instance content has its own homes.** Five concrete storage tiers per [`secrets-handling-policy.md`](secrets-handling-policy.md) §2 (env var, `~/.claude/settings.local.json`, OS keychain, `.env` gitignored, encrypted-at-rest) plus the `.gitignore` baseline for non-secret operator state. Operator state isn't homeless; it has the right home, which is not the public repo.

---

## §3 Composition with sibling standards

This standard articulates the public-class axis. Other axes are owned elsewhere — do not restate them here.

| Sibling | Axis it owns | Composition |
|---|---|---|
| [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) | Knowledge tier (K1-K5) | Independent — a K1 standard is usually UNIVERSAL-PUBLIC (most codified knowledge), occasionally CUSTOMIZABLE-PUBLIC ([`public-repo-gitignore-template.md`](public-repo-gitignore-template.md)). |
| [`universal-vs-release-pipeline-split-rule.md`](universal-vs-release-pipeline-split-rule.md) | Subdirectory placement (`core/` vs. `release/references/`) | Independent — both placements can host UNIVERSAL-PUBLIC or CUSTOMIZABLE-PUBLIC content. OPERATOR-INSTANCE content lives in neither (it is outside the public-repo source tree). |
| [`public-repo-gitignore-template.md`](public-repo-gitignore-template.md) | `.gitignore` patterns for repos EXTRACTED from pmo-platform | Specialization — the extraction template applies this taxonomy's OPERATOR-INSTANCE class as concrete gitignore rules in the extracted repo. |
| [`secrets-handling-policy.md`](secrets-handling-policy.md) | C1-C7 secrets categories with storage matrix | Specialization — all C1-C7 categories are OPERATOR-INSTANCE per this taxonomy. The secrets policy refines how that class is stored, audited, and rotated. |
| [`composition-surface-spec.md`](composition-surface-spec.md) | Files that mix package-seed defaults with operator extensions | Specialization — composition-surface files are CUSTOMIZABLE-PUBLIC with a defined marker-fence mechanism for the customization seam. |
| [`hub-session-continuity.md`](hub-session-continuity.md) | Hub state persistence across session boundaries within a release | Consumer — invokes CUSTOMIZABLE-PUBLIC for the hub-state schema (templates ship at `release/releases/hub-state/*.template`); runtime instance lives at the operator-instance path per OPERATOR-INSTANCE class. The split-class treatment exists because hub-state mutates on every routing decision — git-tracking the runtime instance would create dozens of micro-commits per release for state that has zero cross-operator readership. |

The classification is intentionally redundant with the `.gitignore` patterns and the [`secrets-handling-policy.md`](secrets-handling-policy.md) storage matrix — those are enforcement mechanisms; this is the codified rule that says what should be enforced.

---

## §4 Worked examples

### §4.1 UNIVERSAL-PUBLIC — `release/releases/plans/vX.Y_RELEASE_PLAN.md`

- **Apply test:** Every per-issue Stage 5/6/7/8 spoke session reads the plan to ground its work. The hub re-reads the plan when resuming a session across context resets. Future operators auditing "what did we plan vs. what shipped?" need it.
- **Verdict:** UNIVERSAL-PUBLIC — git-tracked verbatim under the release branch (Engineering Commit 0 under D-C SINGLE topology; chore PR under D-C OPTION-A) and merged to main on release.

### §4.2 UNIVERSAL-PUBLIC — `release/releases/notes/vX.Y_RELEASE_NOTES.md`

- **Apply test:** The canonical artifact is read by `gh release create --notes-file` at Stage 12 Phase B5.5 (Surface 1 of the Layer-1 dual-write per [`../../release/references/standards/release-notes-standard.md`](../../release/references/standards/release-notes-standard.md)) and transformed into the `CHANGELOG.md` entry at Stage 13 (Surface 2). Both surfaces run in spoke worktrees that need the file on the branch.
- **Verdict:** UNIVERSAL-PUBLIC — git-tracked; upstream of two downstream public surfaces.

### §4.3 CUSTOMIZABLE-PUBLIC — hub-state schema templates + operator-local runtime instance

- **Template path (tracked):** `release/releases/hub-state/pending-approvals.md.template`, `action-items.md.template`, `sessions.md.template` — empty schema starters with frontmatter, an empty append-only table, and inline comments documenting field semantics.
- **Runtime instance path (operator-local):** `<OPERATOR_INSTANCE_HUB_STATE_PATH>/vX.Y/pending-approvals.md` and siblings — the hub writes here on every routing decision, queued approval, action item enqueue, and resolution.
- **Apply test (templates):** Yes — every operator install needs the schema to seed their first emit; the template is also the contract that `hub-session-continuity.md` §3 references. Template is UNIVERSAL-PUBLIC-shaped via the CUSTOMIZABLE-PUBLIC class.
- **Apply test (runtime instance):** No — the runtime instance is read only by the same operator's hub across sessions. No spoke, no future operator, no downstream consumer needs the per-release approval-queue state. Audit-trail concerns are already satisfied by `pipeline-event-log.md` (separately operator-instance per [`hub-session-continuity.md`](hub-session-continuity.md) §3.2) plus GitHub Issue comments carrying the Decision Briefing context.
- **Verdict:** CUSTOMIZABLE-PUBLIC for the template + OPERATOR-INSTANCE for the runtime instance. The split avoids dozens of micro-commits per release for state that has no cross-operator readership; it preserves the install contract via the tracked template.
- **Why not UNIVERSAL-PUBLIC for the runtime instance:** Hub-state mutates on every routing decision (typically 10–50+ writes per release). Tracking the runtime instance would force a commit on each mutation, trigger CI on each commit, and produce release-branch noise that obscures the engineering signal. The benefit (git history as audit trail) is already provided by sister surfaces, so the cost is pure.

### §4.4 CUSTOMIZABLE-PUBLIC — `core/CLAUDE.md.template`

- **Apply test:** The template ships in the public repo so any operator cloning gets the seed. Each operator's deployed `CLAUDE.md` at the runtime path is identity-specific (operator handle, project paths) and must NOT be tracked.
- **Verdict:** CUSTOMIZABLE-PUBLIC — template git-tracked with managed-section + operator-extension fences per [`composition-surface-spec.md`](composition-surface-spec.md); runtime instance is operator-local.

### §4.5 OPERATOR-INSTANCE — `projects/_config/SESSION_STATE.md`

- **Apply test:** Tracks the current operator's workspace session (active project, last-routing decision). No spoke or future operator needs it; the current operator's hub is the only consumer.
- **Verdict:** OPERATOR-INSTANCE — `.gitignored` via the `projects/` rule in `.gitignore`; lives outside the public repo's source tree.

### §4.6 OPERATOR-INSTANCE — secrets (all of C1-C7 per [`secrets-handling-policy.md`](secrets-handling-policy.md))

- **Apply test:** Tokens and credentials are operator-account-specific. Sharing them would defeat the security model.
- **Verdict:** OPERATOR-INSTANCE — stored per the [`secrets-handling-policy.md`](secrets-handling-policy.md) §2 storage matrix. `.gitignore` baseline + L2 runtime-hook enforcement (per [`bypass-mode-readiness.md`](../rules/bypass-mode-readiness.md)) defend the boundary.

---

## §5 Boundary failure modes

The taxonomy fails when an artifact straddles classes. Two patterns to watch for:

### §5.1 UNIVERSAL-PUBLIC content with operator-specific leakage

Authoring a file that *should* be UNIVERSAL-PUBLIC (e.g., a new standard) but embedding operator handle, absolute paths, or cross-repo issue refs that don't resolve in pmo-platform. The fix is [`depersonalization-spec.md`](depersonalization-spec.md) token substitution (`[OPERATOR_NAME]`, `[OPERATOR_GITHUB]`, `{REPO}`) — NOT reclassifying the artifact.

### §5.2 OPERATOR-INSTANCE content needing cross-session continuity

Operator state that the current operator's *next* session needs (e.g., a long-running release that spans days). The fix is to ship the schema as a CUSTOMIZABLE-PUBLIC template, write the runtime instance to an operator-instance path, and let the operator's machine-local state provide durability across sessions — this is the hub-state pattern per [`hub-session-continuity.md`](hub-session-continuity.md) and §4.3 above. The cross-session-continuity surface does NOT need to be git-tracked when the durability requirement is single-operator-across-sessions rather than cross-operator.

---

## §6 Cutover

Applies to every file authored in or migrated to pmo-platform from the reorg forward. Pre-reorg placements are grandfathered per the reorg state; subsequent cleanups align grandfathered placements with this taxonomy when divergence surfaces during audit.

The pre-flip security audit (the public-flip gate per [`secrets-handling-policy.md`](secrets-handling-policy.md) §8 Public-Flip Implications) is the gate that verifies no UNIVERSAL-PUBLIC artifact leaks operator-specific content and no OPERATOR-INSTANCE artifact is accidentally tracked. This taxonomy is what that audit audits against on the public-class axis.

---

## §7 Git-Tracking-Decision Policy (durable / derived / runtime)

§1-§6 own the **public-class** axis — *does this artifact ship?* (UNIVERSAL-PUBLIC / CUSTOMIZABLE-PUBLIC / OPERATOR-INSTANCE). §7 is the operational refinement of that axis's **YES branch**: of the paths that *do* ship and are therefore git-tracked, which are **durable** (author-maintained source of truth), which are **derived** (regenerable from durable source), and which are **runtime-scratch** (session state that must never track) — and, for each, what stays tracked. It answers a second, narrower question:

> **This path is already tracked — should it *stay* tracked, or should it be un-tracked (`git rm --cached`), or is it a coverage gap that should be tracked but isn't?**

The public-class axis (§1) decides eligibility to ship; the tracking-decision axis (§7) audits the *actual tracked set* against that eligibility and classifies every tracked path by its durability nature. The two are orthogonal-but-adjacent: a path can only reach §7 if §1 said YES, and §7 is where a YES-but-derived path (a built artifact) or a YES-but-should-not-have-shipped path (a leaked runtime file) is adjudicated. This section is authored append-only; it renames and moves nothing.

### §7.1 The seven per-class criteria

Every tracked path resolves to exactly one of seven classes, keyed to the observed tracked-file census (see §7.7 audit method), not invented. Each class carries a single default verdict.

| # | Per-class criterion | Representative tracked paths | Layer | Default verdict |
|---|---|---|---|---|
| 1 | **durable governance** | `core/governance/*`, `core/CLAUDE.md.template`, `.github/workflows/*`, `.github/ISSUE_TEMPLATE/*`, `packages/README.md` | L1 | KEEP-TRACKED |
| 2 | **durable reference** | `core/standards/*`, `core/disciplines/*`, `core/specs/*`, `core/schemas/*`, `release/references/**`, `docs/**` | L1 | KEEP-TRACKED |
| 3 | **durable skill source** | `*/skills/*/SKILL.md` + skill-source assets (`.html` eval-viewer, `.py` helpers, `NOTICE`, `LICENSE.txt`) | L1 | KEEP-TRACKED |
| 4 | **durable engineering script** | `core/deploy/**/*.sh`, `release/tools/*.sh`, `*.py` CI checks, `core/hooks/lib/*.awk` | L1 | KEEP-TRACKED |
| 5 | **durable release record** | `release/releases/RELEASE_LOG.md`, `release/releases/plans/**`, `release/releases/notes/**`, `CHANGELOG.md` | L1 | KEEP-TRACKED |
| 6 | **derived-regenerable** | `packages/*.skill`, `packages/*.sha256` (built by `core/deploy/tools/build-skill-packages.sh`) | L1 | **POLICY-AMBIGUOUS → resolved KEEP-TRACKED** (see §7.5) |
| 7 | **runtime-scratch** | `*.log`, `*.jsonl`, `.mode`, `.editor-session`, `audit-output/`, `analysis/*` content, `*-workspace/` | L2 | SHOULD-IGNORE (already `.gitignored`) |

### §7.2 Verdict tokens (closed four-set)

Exactly four tokens exist. The set is closed and mutually exclusive; every audit finding carries **exactly one** (§7.3).

- **KEEP-TRACKED** — the path is a durable class (1–5) — or the sanctioned derived exception (§7.5) — is currently tracked, and passes self-containment ([`depersonalization-spec.md`](depersonalization-spec.md)). No action.
- **SHOULD-IGNORE** — the path is a runtime-scratch class (7) yet is currently tracked (a leak). Action: un-track via `git rm --cached` **only** + add the covering `.gitignore` pattern. Compose with #368 (bulk runtime-artifact cleanup) in any such finding.
- **SHOULD-TRACK-BUT-NOT** — the path *would* be a durable class (1–5) and should ship, but is absent from tracking (a coverage gap, not a leak). Action: add it to tracking.
- **POLICY-AMBIGUOUS** — the path straddles durable/derived (class 6), or the §7.1 default and the §7.3 apply-test disagree. It is **resolved explicitly in this policy, never left open** (see §7.5).

### §7.3 Decision rule (one token per finding)

For each tracked path (evaluated at pattern-class granularity, §7.7):

1. Resolve its class (1–7) from §7.1.
2. Apply the class default verdict.
3. Emit **one** token per finding — the audit findings table has **row count == verdict-token count** (no finding carries two tokens; no token spans two findings).
4. The **sole** mechanism for acting on a SHOULD-IGNORE finding is `git rm --cached <path>` (un-track, preserve working copy) followed by a `.gitignore` pattern add. This policy names **no** history-rewrite mechanism: `git filter-repo`, `git filter-branch`, and history rewrite are **out of scope** and prohibited on this repo (public history has been established since the initial public release; rewriting it is IRREVERSIBLE and reserved by convention for secret-exposure remediation, not routine ignore-adds — see §7.6). Un-tracking a path with `git rm --cached` is CHEAP and non-destructive; that is the only tool this policy sanctions.

### §7.4 Layer 1 / Layer 2 reconciliation

The seven classes reconcile against the two-layer model in CLAUDE.md's *Platform vs. Working-Content Boundary* (Layer 1 = Platform, tracked via git; Layer 2 = Operations, git-ignored):

- **Layer 1 (Platform, tracked)** = classes 1–5 **plus** the one sanctioned class-6 derived-tracked exception (§7.5).
- **Layer 2 (Operations, ignored)** = class 7 **plus** everything under `projects/`, `personal/`, and `pmo-instance/` (OPERATOR-INSTANCE per §1).

The reconciliation states one invariant:

> **A tracked path MUST resolve to a Layer 1 class. A Layer 2 class MUST NOT be tracked. Class 6 (derived-regenerable) is the single sanctioned Layer-1-tracked-derived exception and MUST carry its rationale inline (§7.5).**

A tracked path that resolves to a Layer 2 class is a SHOULD-IGNORE finding (§7.2). A durable Layer 1 path that is absent from tracking is a SHOULD-TRACK-BUT-NOT finding. Any class-6-shaped path lacking the §7.5 rationale is POLICY-AMBIGUOUS until the rationale is recorded.

### §7.5 The sanctioned derived-tracked exception — `packages/*.skill`

Class 6 is the load-bearing POLICY-AMBIGUOUS case, and this policy resolves it to **KEEP-TRACKED** with a stated rationale so the decision stops being ad-hoc.

The `packages/` tree holds **96** compiled artifacts — 48 `.skill` bundles + 48 `.sha256` sidecars — plus `packages/README.md` (class 1, durable governance). The 96 are **derived**: `core/deploy/tools/build-skill-packages.sh` regenerates them from skill source. By the class-6 default (derived ⇒ ignore) they would be un-tracked. That default is **deliberately overridden** here because:

1. **Install-without-build contract.** `install.sh` deploys the compiled `.skill` packages directly, so a fresh clone is installable with **no build step**. Un-tracking `packages/` would break install-from-clone.
2. **Freshness is gated, not trusted.** `deploy.sh` **Check 7** verifies each tracked package against its source via the `.sha256` sidecar — a stale committed package fails the check. The tracked-derived risk (drift between source and built artifact) is therefore caught by a gate, not left latent.

Because a concrete install-contract requirement overrides the derived default, the resolution is **KEEP-TRACKED** and this rationale is recorded inline (per §7.4, a class-6 path without its rationale is POLICY-AMBIGUOUS). This is the *only* sanctioned derived-tracked exception; any *other* derived artifact defaults to ignore unless it earns an equivalent explicit override recorded here.

### §7.6 External tracking conventions

The durable/derived/runtime distinction and the `git rm --cached`-only mechanism follow established Git convention, not local invention:

- `[SOURCE: Pro Git, 2nd ed., Ch. 2.2 "Recording Changes to the Repository — Ignoring Files" and Ch. 10 "Git Internals" on tracked-vs-untracked state, git-scm.com/book]` — the tracked / ignored / untracked trichotomy; committing a build output is a deliberate, documented choice (an override of the usual "ignore generated files" default), not a Git default. Grounds §7.1 class 6 and the §7.5 override.
- `[SOURCE: git gitignore(5) man page, git-scm.com/docs/gitignore]` — `.gitignore` pattern semantics and the standard idiom that a path already committed is **not** retroactively ignored by adding a pattern; it must first be un-tracked with `git rm --cached` (which removes it from the index while leaving the working copy). Grounds §7.3's sole ignore mechanism.
- `[SOURCE: GitHub Docs, "Ignoring files" and "Removing sensitive data from a repository", docs.github.com]` — the convention that history-rewriting tools (`git filter-repo`) are reserved for removing sensitive/leaked data, not for routine ignore-adds — establishing that on a public repo with established history the correct un-track path is `git rm --cached`, never a rewrite. Grounds the §7.3 prohibition.

### §7.7 Audit method — documented-pattern level over the tracked set

The policy is verified by a one-pass audit run at **documented-pattern level**, not per-file. The audit is authored operator-local as a read-once artifact under `analysis/git-tracking-audit-<YYYY-MM-DD>/SUMMARY.md` (git-ignored per the `.gitignore` `/analysis/*` rule; the *policy* — this §7 — is the durable output, the audit is the read-once evidence). The audit steps:

1. **Enumerate + assert count (live).** `git ls-files core/ operations/ release/ | wc -l`. The count is **asserted live at audit time** — it is a moving figure as the corpus grows, not a hardcoded constant. Design-time baseline (Stage-5 solutioning, #73): **911**; the audit records whatever the live figure is on its run date and reconciles it to the class map below. The full tracked surface is `git ls-files | wc -l` (design-time baseline 1055), covered by the superset appendix (step 4).
2. **Bucket by pattern class.** Map the observed extensions to the seven §7.1 classes via a documented extension→class map. Design-time census: `.md` · `.sh` · `.py` · `.txt` · `.yaml` · `.template` · `.json` · `.csv` · `.html` · `.awk` · `NOTICE` (no-ext) · `.example` — twelve pattern buckets with a short oddball tail, each resolving to one of the seven classes.
3. **Assign one verdict per class.** Each class gets its single §7.1 default; only class 6 carries an exception (§7.5). Findings table: one row per class (+ per-exception), **row count == token count** (§7.3).
4. **Superset appendix.** Reconcile the remaining non-Engineering tracked paths (workspace-root files + `packages/` + `.github/` + `docs/` + `roadmaps/README.md` + `analysis/README.md`) against the same seven classes, so the policy accounts for the *whole* tracked surface without widening the gated 100%-coverage scope beyond `git ls-files core/ operations/ release/`.
5. **Current-tree result.** On the tree at authoring, every class resolves to **KEEP-TRACKED** except class 7 (runtime-scratch — already `.gitignored`; **zero** tracked leaks observed) and class 6 (POLICY-AMBIGUOUS → resolved KEEP-TRACKED per §7.5). The audit is baseline-pinned: a runtime-scratch path appearing later silently invalidates the zero-leak result, so the SHOULD-IGNORE token and the class-7 sweep exist for future drift and the superset check even though the current count is zero.
6. **Any SHOULD-IGNORE / deletion finding** cites #368 (compose-with) and uses `git rm --cached` only (§7.3) — never a history rewrite.

---

## Related

- [`knowledge-architecture.md`](../disciplines/knowledge-architecture.md) — K1-K5 tier taxonomy (orthogonal axis)
- [`universal-vs-release-pipeline-split-rule.md`](universal-vs-release-pipeline-split-rule.md) — subdirectory placement (orthogonal axis)
- [`public-repo-gitignore-template.md`](public-repo-gitignore-template.md) — extraction template applying the OPERATOR-INSTANCE class as gitignore patterns
- [`secrets-handling-policy.md`](secrets-handling-policy.md) — refinement of the OPERATOR-INSTANCE class for credential-shaped content (C1-C7)
- [`composition-surface-spec.md`](composition-surface-spec.md) — refinement of the CUSTOMIZABLE-PUBLIC class for files with operator-customization seams
- [`depersonalization-spec.md`](depersonalization-spec.md) — token vocabulary that keeps UNIVERSAL-PUBLIC files free of operator-specific leakage
- [`hub-session-continuity.md`](hub-session-continuity.md) — consumer that invokes the UNIVERSAL-PUBLIC class for hub-state substrate
