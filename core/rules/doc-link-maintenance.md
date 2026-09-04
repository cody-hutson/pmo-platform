---
title: Doc-Link Maintenance — pmo-platform
purpose: The operating rule for detecting and remediating stale cross-references in the documentation corpus, via Check 14, so reorganizations do not silently erode navigability.
type: rule
status: ACTIVE
reversibility: CHEAP / Confidence HIGH
---
<!-- reference-durability: allow-link -->
# Doc-Link Maintenance — pmo-platform

**Release:** doc-cleanup
**Authoritative standard:** [`core/standards/doc-link-maintenance-protocol.md`](../standards/doc-link-maintenance-protocol.md)

## Purpose

Detect and remediate stale cross-references in the workspace's documentation corpus. Stale links and outdated path references survive reorganizations and erode navigability. The protocol provides automated detection (governance + skill SKILL.md via Check 14; the earlier release-corpus Check 15 was retired in v2 — the release-corpus link surface is covered by the release-corpus link checker) and a manual-checklist clause for the semantic-drift pattern that automation cannot reach.

## Three Patterns

| Pattern | Description | Originating evidence | Detection mechanism |
|---|---|---|---|
| **A — deleted-target** | Link resolves to a file that no longer exists |  (`IMPROVEMENTS.md` references) | Link-resolver primitive |
| **B — path-drift** | Link points to an outdated directory after a reorg |  (e.g. a pre-restructure `pmo-platform/...` path → its live `core/`/`release/`/`operations/` location) | Link-resolver primitive |
| **C — temporal-language drift** | Stale "deferred", "interim", "Future:" framing |  | **Manual checklist; automation tracked at F-1** |

## The Primitive

`core/deploy/tools/check-doc-links.py` — Python stdlib-only (`/usr/bin/python3` 3.9+). Parses markdown links, resolves relative paths, reports broken refs as TSV/JSON.

**Usage:**
```bash
python3 core/deploy/tools/check-doc-links.py \
  --target-paths <comma-separated-globs> \
  [--allowlist <tracked-base>] [--allowlist <instance-additions>] \
  [--require-targets] \
  [--workspace-root <path>] \
  [--output-format tsv|json|github]
```

**Self-test:** `python3 core/deploy/tools/check-doc-links.py --self-test`

**Deployed-tree validation:** `--workspace-root <path>` resolves workspace-rooted links (the `/`-prefixed and prefix-table forms) and globs against a relocated root instead of the in-repo default, so a sandboxed/deployed install tree can be validated. Precedence is `--workspace-root` > `$CLAUDE_WORKSPACE_ROOT` (the canonical workspace-root variable the hooks and `deploy.sh` already export) > the in-repo default; with neither override set the behavior is unchanged. Pair with `--require-targets` so a relocated or missing surface fails loud rather than reading GREEN.

**Fail-loud on unresolved targets:** `--require-targets` treats a `--target-paths` glob entry that resolves to zero files as a path-resolution failure (exit 3) rather than a clean pass, so a relocated or typo'd scan surface cannot read GREEN. Check 14 passes this flag.

**Path resolution (the canonical rule — both checkers apply it identically):** both inline links (`[text]` followed by a parenthesized path) and reference-style links (`[text]` followed by a `[label]`) are parsed. Three clauses matching GitHub's rendered-blob behavior: (1) a link resolves **relative to the source-file directory**; (2) a **leading `/`** denotes the **workspace (repo) root** — the GitHub-faithful workspace-rooted form; (3) there is **no bare module-prefix fallback** — a bare `core/…`/`release/…` from a non-root file is an ordinary relative path and reads **broken** (as GitHub renders it). `release/tools/check-release-links.py` — the checker the Dead-file-reference gate delegates to — implements the same three clauses, so a workspace-rooted link and a relative link each receive an identical verdict from both checkers. (The earlier bare-prefix workspace-root fallback was retired per ADR-085; it masked GitHub-404s from non-root files.) Fenced code blocks excluded — including fences nested inside a blockquote (`> ` + fence), so a `>`-quoted worked example does not surface its illustrative links as findings.

**Mirror-pair link form (this file is itself one):** a **mirror-pair file** is an in-repo source with a byte-identical deployed copy at a second path — the set enforced by `deploy.sh --check` Check 9, whose array is the authoritative membership list. It is read from two locations, so its links must resolve from both. A link whose target is **also a member of the mirrored set** MAY remain relative: it resolves to the mirror's own copy, which Check 9 asserts is byte-identical, and rooting it would send a mirror reader back into the repo instead of to the copy beside it — worse still for an operations-branch session, which is deliberately rooted *outside* the platform repo ([`CLAUDE.md.template`](/core/CLAUDE.md.template) § Routing) where the rooted form does not resolve at all. Every other link — any target outside the mirrored set — MUST use the **leading-`/`** workspace-rooted form (clause 2), the only form correct at both locations; the bare module-prefix form is not workspace-rooted and MUST NOT be used (clause 3). Membership is the entire predicate, so a target **leaving** the mirrored set converts its inbound links from the first case to the second — root them in the same change that removes it, or they resolve today and break at the next deploy.

**Non-link target classes the primitive skips natively** (in `is_internal()`, so both deploy-time Check 14 and PR-time `link-check.yml` inherit them, and no allowlist upkeep is needed):

| Target shape | Example | Why it is not a link |
|---|---|---|
| External scheme | `http://…`, `https://…`, `mailto:…`, `tel:…`, `ftp://…` | Off-repo target |
| Pure anchor | `#section` | Same-page anchor, not a file |
| Angle-bracket placeholder | `<OPERATOR_INSTANCE_RELEASE_LOG_PATH>`, `<sibling.md>`, `../x/<mover>.md` | Templated placeholder — `<`/`>` are not valid in committed paths |
| Bareword meta-literal | `[text](path)`, `[#N](URL)` | No `/` and no `.` — link-SYNTAX illustration in prose, not a path |
| Ellipsis placeholder | `[#N](...)` | A path portion of three-or-more dots is a markdown ellipsis (`.`/`..` are genuine relative refs and are NOT skipped) |

## Enforcement Surfaces

| Check | Scope | Posture |
|---|---|---|
| **Check 14** (deploy-time) | Governance + reference + rules + skill SKILL.md across the live modules (`core/governance/`, `core/disciplines/`, `core/schemas/`, `core/standards/`, `core/specs/`, `core/rules/`, `core/CLAUDE.md.template`, `release/governance/`, `release/references/`, `operations/OPERATIONS.md`, and `{core,operations,release}/skills/*/SKILL.md`) | warn-mode initial; logs to the deploy-check warn-log surface |
| **`link-check.yml`** (PR-time) | Identical scope to Check 14 — the SAME primitive over the SAME `--target-paths`. The standing PR-gate companion to deploy-time Check 14: a broken outbound reference is caught when the PR opens, not only at the next deploy. | warn-mode initial; emits inline `::warning file=,line=::` annotations on the PR diff and passes. Flips to enforce (a broken ref fails the PR) via `WARN_MODE: 'false'` in the workflow per § Flip-to-Enforce |
| **Check 15** | RETIRED in v2 — the release-corpus cross-link integrity check was removed; the release-corpus link surface is covered by the release-corpus link checker, and note-content is linted by Check 20 via `lint_release_corpus.py` | n/a (retired) |
| **Dead-file-reference gate** (`repo-integrity.yml`, PR-time) — via `release/tools/check-release-links.py` | `core release docs .github` + top-level `*.md`, changed-delta / added-lines only | **required** (branch-protection); enforce — a broken added-line link fails the PR; anchors warn-mode |
| **`release-link-check.yml`** (PR-time) — via the same `check-release-links.py` | `release/` full walk (bare invocation) | advisory (path-filtered to `release/**`; absent-is-pass) |

Check 14 (deploy-time) and `link-check.yml` (PR-time) both call the `check-doc-links.py` primitive over the SAME shared `--target-paths-file` scan scope AND the SAME tracked base `--allowlist` (see § Allowlist) — one engine, one scope list, one tracked ignore list, so the deploy-time and PR-time verdicts cannot drift. Sharing scope alone is not sufficient: two callers scanning identical files with different allowlists still reach different verdicts. `check-release-links.py` (the Dead-file-reference gate + `release-link-check.yml`) implements the **same canonical resolution rule** (see § The Primitive → Path resolution), so the doc-links and release-links checker families cannot return opposite verdicts on a given link form either. The `operations/` **module** governance + skill surfaces (`operations/OPERATIONS.md`, `operations/skills/*/SKILL.md`) are **Layer 1** and are in scope; **Layer 2** (`projects/`, the deployed `.claude/skills/` tree, the operator-instance store) is excluded per the CLAUDE.md domain boundary — Claude Code cannot remediate Layer 2 drift. This matches [`doc-link-maintenance-protocol.md`](../standards/doc-link-maintenance-protocol.md) § 4.2, the authoritative standard; the `operations/` module is not Layer 2.

The PR-time gate runs on every pull request (no paths filter) so the status check always reports, and on push to `main` as a post-merge guard. A path-resolution failure (a `--target-paths` glob resolving to zero files, exit 3) is always hard-fail regardless of warn-mode — a relocated scan surface must never read green. The primitive's `--self-test` runs first as a precision probe: a parser/resolver/exclusion regression fails the PR independently of warn-mode.

## Allowlist

Two allowlist files, layered — **not** one per surface. Both use the same syntax: one pattern per line; trailing slash matches directories; `#` introduces comments.

| Allowlist | Consumed by | Tracked? | Role |
|---|---|---|---|
| `core/deploy/allowlists/skip-doc-link-check-ci.txt` | **Both** — `link-check.yml` (PR-time) and Check 14 (deploy-time) | **Yes** — tracked | The tracked **corpus-level base**: the skip class that is a property of the repository, so it must apply identically wherever the corpus is scanned. Also the deterministic CI allowlist after `actions/checkout`, where the operator-instance file does not exist. Thin by design — the engine's native skips (above) do the heavy lifting, not this file |
| `<OPERATOR_INSTANCE_CLAUDE_DIR>/skip-doc-link-check.txt` | Check 14 (deploy-time), **layered on top of the tracked base** | No — operator-instance (absent from a fresh checkout) | Operator-specific suppressions for paths that exist only in the operator's own workspace. Additions only — the operator never re-declares the tracked entries here |

**Why the tracked file is named `skip-doc-link-check-ci.txt`.** The `-ci` suffix is historical, not descriptive: the file was created by the commit that added the PR-time `link-check.yml` gate, when CI was its only reader. Check 14 was later wired to pass the same file as its base `--allowlist`, so both callers now read it and the suffix under-describes the role. **The name is ratified as the durable identifier and will not be renamed.** Renaming it is a reference-cascade operation rather than a file move: the identifier is a literal argument in the PR-time workflow and the deploy-time check, and it appears in the primitive's docstring, in the scan-scope list's header, in the standard, and in terminal release records that describe the state at their release and are not rewritten. Paying that cascade to correct a readability defect is not a trade this platform makes; naming the divergence here, where the allowlist model is documented, is. Read the file as *the tracked base allowlist*, not *the CI-only allowlist*.

The two are UNIONed, not chosen between: `--allowlist` is repeatable and additive, so Check 14 passes the tracked base **and** the instance file and a later file can never shadow an earlier one. This makes the ignore list single-sourced on the same principle `--target-paths-file` already applies to the scan scope. Both properties are required together: with scope shared but the allowlist split, the two callers scan byte-identical files and can still return different verdicts — which is precisely what happened when the repo-root `*.md` glob entered scope and the resulting skip class was recorded on the CI path only.

**Which file does a new entry belong in?** If the reason the path is skipped is a fact about the *repository* (a tracked file whose links point outside the scanned tree by design), it belongs in the tracked base so both surfaces agree. If the reason is a fact about *this operator's workspace* (a local analysis or archive subtree that does not exist in a fresh checkout), it belongs in the instance file.

**Operator-instance default entries (illustrative — that file itself is operator-instance):**
- `release/releases/archive/` — historical references by design
- audit-evidence subtrees (e.g. `legacy-imp-audit-*/`, `cross-domain-drift-audit-*/`) — read-once analysis artifacts

**Tracked base entries:** archive/snapshot subtrees (`_archived/`, `_snapshots/`, `archive/`) as forward-protection — none currently exist inside the scoped corpora, so they protect future additions rather than suppressing anything today. That is the whole tracked list. A repo-root `CHANGELOG.md` entry also lived there for a time, on the premise that its per-release links pointed into an instance-side `release/releases/notes/` tree; that tree is tracked, those links resolve against it, and the entry was retired rather than carried forward. The lesson the entry left behind is the one worth keeping: an allowlist entry states a fact about the corpus, and a fact can stop being true — re-derive an entry's premise before restating it, because a stale premise in an allowlist reads as a silent, permanent exemption.

**Adding entries:** standard text editor + governance approval for non-trivial scope expansion. Allowlist additions document WHY the path is allowlisted, not WHY the operator wants to silence warnings. Prefer a native engine skip (angle-bracket placeholder, etc.) over an allowlist entry where the target is genuinely a non-link — an allowlist is file-granular and would blind the gate to real drift in the rest of the file.

## When Scans Run

| Trigger | Authority |
|---|---|
| **PR open / push to PR branch** | **Automatic via `link-check.yml` (the standing PR-time gate)** |
| **Push to `main`** | **Automatic via `link-check.yml` (post-merge guard)** |
| Post-reorg | Operator-initiated |
| Post-PR-merge | Automatic via `./deploy.sh --check` |
| Scheduled (deploy-time) | Every `./deploy.sh --check` invocation |
| Pre-release (Stage 9) | Operator-initiated as release readiness verification |

## Manual Checklist for Pattern C

Until F-1 ships automated text-pattern detection, operators executing post-reorg, major-content-migration, or Stage 9 Plan Review workflows perform this grep:

```bash
grep -rEn "\b(deferred|interim|Future:|TODO:|pending|will be|to be added|not yet)\b" \
  core/standards/ core/specs/ core/rules/ release/references/ release/governance/
```

Findings route to the standard surgical-fix path — small commits, parser-clean PR body, mark stale framing as current-state or remove it.

## Initial Mode + Flip-to-Enforce Timeline

**Initial mode:** warn-mode per [`bypass-mode-readiness.md`](bypass-mode-readiness.md) precedent (Checks 8/9/10).

**Flip-to-enforce thresholds (per Collective Review CR-D6, whichever comes first):**

| Threshold | Action |
|---|---|
| 2-3 releases post-merge | Operator-driven warn-log review; broken-ref backlog drainage progress assessed |
| Broken-ref backlog drained to < 10 entries | Flip to enforce via `.claude/hooks/.mode` or `.claude/hooks/deploy-check.mode` |
| Until enforce-mode is activated | Operator must explicitly defer flip with rationale at each Stage 13 close; silent deferral is a process violation |

**Responsible party:** Workspace owner ([OPERATOR_NAME]). Stage 13 Close at the first release after merge MUST include a "Check 14 flip-to-enforce assessment" line item.

## Escalation

| Finding type | Routing |
|---|---|
| P1 in active governance | Tier 1 [ADJUST] commit on current release branch, or surface to operator |
| P2 in reference docs | Bundle into next release as surgical fix; create GitHub issue if not tracked |
| P3 informational | Log to warn-log; review during shakedown; bundle into the F-4 broken-ref drainage |
| Net-new drift | Operator decides: fix / defer / accept-as-residual / allowlist-with-rationale |

## Reference Durability vs Link Resolution

Link resolution (this protocol) is a distinct discipline from reference durability (the reference-durability standard under the core standards set, with its hook, deploy-check check, and CI workflow). The two are orthogonal and both run; neither subsumes the other.

| Discipline | Owns | Question it answers |
|---|---|---|
| Link resolution (this protocol plus its deploy-check check) | does a text-path link resolve to a file that exists? | Is this link alive today? |
| Reference durability (the standard plus its enforcement primitives) | should this reference exist at all in durable corpus, given it will break on renumber or migration? | Will this survive a rename, renumber, or migration? |

A link can be perfectly resolvable today — it passes the link-resolution check — yet still be a durability violation, because the durability standard says to summarize the content inline rather than carry a link. Conversely a durable inline summary has no link to resolve. Link resolution polices link liveness; reference durability polices whether a fragile construct belongs in durable corpus at all. When a reference fails link resolution, fix or remove the link; when it fails durability, rewrite it as an inline summary.

## Related

- Release-corpus link surface: covered by the release-corpus link checker (the earlier Check 15 was retired in v2)
- Pattern C automation: F-1
- Broken-ref backlog drainage: F-4
- Frontmatter schema backfill (corpus hygiene): F-3
- Mirror-pair discipline: [`skill-deployment.md`](skill-deployment.md)
- Hook layer precedent: [`bypass-mode-readiness.md`](bypass-mode-readiness.md)
- Identifier cascade at edit time (any reference form, any surface): [`rename-reference-cascade.md`](rename-reference-cascade.md) — this protocol detects an unresolvable link after the fact; that rule obliges the sweep at the moment of the rename.
