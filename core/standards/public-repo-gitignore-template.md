---
title: Public-Repo `.gitignore` Template
purpose: K1 codified-knowledge standard defining operator-local config patterns that MUST NOT enter tracked content in any public repo extracted from pmo-platform — a reusable PATTERN that applies to multiple repos (claude-account-switcher first; future extractions inherit)
type: standard
status: ACTIVE
source: ""
parallel_to: skill-deployment.md (operator-state preservation discipline at the skill surface); harness-deployment.md (operator-state preservation discipline at the harness surface — this standard generalizes the discipline to PUBLIC-REPO extractions)
reversibility: CHEAP (pattern additive; per-repo `.gitignore` instances are text files; revert removes; ALL pre-cutover repos exempt)
consumers: "pmo-platform/harness/account-switcher/.gitignore (first-instance consumer); [OPERATOR_GITHUB]/claude-account-switcher/.gitignore (new-repo consumer); future public-repo extractions from pmo-platform"
version:
---

# Public-Repo `.gitignore` Template

## 1. Purpose

When pmo-platform extracts a self-contained capability (harness artifact, skill bundle, slash-command pack, etc.) into a standalone PUBLIC repository, the new repo MUST never track operator-local config — account lists, session markers, swap-history logs, identity-specific paths, runtime caches. This standard codifies the file-class patterns the new repo's `.gitignore` MUST cover before the extraction's history is published.

The discipline composes with — but is distinct from — `harness-deployment.md` § Operator-State Preservation Policy: that policy governs the deploy-mechanism (source-of-truth in git; deploy script copies to runtime path; certain files NEVER overwritten). This standard governs the published-content boundary (certain file classes NEVER appear in the public repo's git history). The deploy-mechanism handles runtime; the .gitignore handles publication.

**Originating evidence:** Account-switcher relocation to a standalone public repo. Operator framing: "downloadable on any device with Claude Code / agent harness; remove account switcher, release notes, personal tools or references, or existing corporation references like '[COMPANY_X]'" + "gitignore local config for the new public repos". Account-switcher's `~/.claude/account-switcher/swap-history.log` and `~/.claude/account-switcher/.statusline-marker` are the canonical "operator-state file" exemplars — the deploy mechanism already protects them (per `deploy.sh` `HARNESS_OPERATOR_STATE`); this standard's `.gitignore` template provides defense-in-depth at the published-repo boundary.

**Scope:** PUBLIC repos extracted FROM pmo-platform (the K1 source-of-truth tree). PRIVATE repos and pmo-platform itself are out of scope — they have their own `.gitignore` per workspace classification (per `CLAUDE.md` § Platform vs. Working Content Boundary).

**Out of scope:** Skill-level operator-state (those live at `~/.claude/skills/<name>/runtime/` and are governed by per-skill SKILL.md); pmo-platform-internal Layer 2 patterns (`projects/`, `.claude/settings.local.json`, etc. — those are pmo-platform-specific per existing `.gitignore`).

## 2. When the convention fires (trigger predicate)

The convention applies to ANY new public repository created via extraction from pmo-platform, iff ALL hold:

1. The source content lives under `pmo-platform/` AND has a runtime install location at `~/.claude/<name>/` (or equivalent operator-local path).
2. The runtime path accumulates operator-state files during normal operation (logs, markers, customized config, swap history).
3. The new repo is intended for PUBLIC visibility (any visibility transition — PRIVATE-creation → PUBLIC-flip — fires the trigger at the moment of public-flip, NOT at private-creation).

**Does NOT fire when:**

- The extraction stays PRIVATE permanently (PRIVATE-only repos may use a tailored `.gitignore` without this standard's discipline).
- The extracted content has NO runtime operator-state surface (pure-content extractions — e.g., a `.skill` package bundle without an install-time customization seam).
- The extraction is an internal pmo-platform reorganization (no new repo created).

## 3. Four file-classes (the pattern set)

Every public-repo `.gitignore` extracted from pmo-platform MUST cover four file classes. Each class is one commented section in the `.gitignore`, named verbatim. The class names are normative — downstream consumers (extraction tools, audit checks) scan for the `# Operator-<class>` comment headers.

| # | File class | What it covers | Why it must not be tracked |
|---|---|---|---|
| **1** | **Operator-config** | Operator-customized config instances (e.g., `config.toml.local`, `*.local`) | Operator's per-environment customization — distinct from the template `config.toml` that DOES ship in the repo. Customizations are operator identity-specific (account lists, paths, credentials-adjacent fields). |
| **2** | **Operator-state** | Runtime logs and markers (e.g., `*.log`, `.*-marker`) | Runtime artifacts produced by tool execution. These should live at the operator-local runtime path (`~/.claude/<name>/`), NOT in the repo. Defense-in-depth — prevents accidental commit if a runtime file is misplaced. |
| **3** | **Operator-cache** | Snapshot backups and intermediate caches (e.g., `.*-bak.*`, `*-bak.*`) | Backup files produced by tooling during edits. Identity-specific timestamps + paths leak operator workflow patterns. |
| **4** | **Operator-bridge** | Cross-repo handoff files (e.g., `*-handoff.md`) | Files produced by cross-repo / cross-account coordination tooling (e.g., account-switcher's `SWAP_HANDOFF.md` pattern). Contains routing metadata that may leak operator workflow context. |

**Class-naming discipline:** The four `# Operator-<class>` headers are normative. Pattern lists WITHIN each class are illustrative — the consumer repo selects the specific globs that match its runtime file production. The header MUST be present even when the class has no globs (e.g., a repo with no cache files still emits `# Operator-cache` with an empty pattern body to signal class coverage was considered).

## 4. Reference `.gitignore` patterns

The following block is a ready-to-copy starting template. Consumers adjust pattern globs to their repo's specific runtime-file production, but the FOUR class headers MUST appear in the order shown.

```gitignore
# Public-Repo Operator-Local Config Template
# Source: core/standards/public-repo-gitignore-template.md
# Operator-local config MUST never enter tracked content in any public repo
# extracted from pmo-platform.

# Operator-config (operator-customized config instances; never tracked)
*.local
config.toml.local

# Operator-state (runtime logs/markers — should live at ~/.claude/<name>/ not here)
*.log
.*-marker

# Operator-cache (snapshot backups; identity-specific paths leak operator workflow)
.*-bak.*
*-bak.*

# Operator-bridge (cross-repo handoff files; contains routing metadata)
*-handoff.md
```

**Verification (consumer-side):**

```bash
# Class-header presence (MUST return 4)
grep -cE '^# Operator-' <repo-root>/.gitignore

# Smoke test — pattern enforcement against synthetic operator-state file
touch <repo-root>/test-operator.log
cd <repo-root> && git check-ignore test-operator.log && rm test-operator.log
# Expected: "test-operator.log" echoed to stdout; non-zero exit if pattern misses
```

## 5. Consumer instances

| Consumer repo | Path | Status | Release | Notes |
|---|---|---|---|---|
| `pmo-platform/harness/account-switcher/.gitignore` | First-instance consumer at current harness location (validates template against current-repo state) | LIVE | Current release | Bounded-lifetime: deletes with parent dir at the extraction cleanup step. Survival window covers the validation phase only — purpose is META-template validation against current state, not durable Layer-1 artifact. |
| `[OPERATOR_GITHUB]/claude-account-switcher/.gitignore` | New-repo consumer at extraction time | PLANNED | Account-switcher extraction release | Created via `gh repo create` + `.gitignore` authored from this template at repo init. PRIVATE at creation per D-AS-VisibilityPhasing; PUBLIC-flip at the visibility-flip step. |
| Future public-repo extractions | TBD | RESERVED | TBD | Any future extraction (additional harness tools, skill bundles, slash-command packs) inherits the four-class pattern. Add a row here at extraction time. |

## 6. Cross-references

- **`harness-deployment.md` § Operator-State Preservation Policy** — sibling discipline at the runtime-deploy surface (per-skill / per-harness deploy never overwrites operator-state files at runtime path).
- **`deploy.sh` `HARNESS_OPERATOR_STATE` array** — operational manifest of operator-state filenames the deploy mechanism preserves at runtime path.
- **account-switcher SWAP_HANDOFF.md** — origin of the cross-account-handoff file-class pattern (Class 4).
- **Parent extraction-readiness issue** — establishes this standard.
- **First new-repo consumer** — claude-account-switcher extraction.
- **Visibility-flip step** — IRREVERSIBLE PUBLIC-flip; the trigger predicate fires here for the first consumer.
- **`CLAUDE.md` § Platform vs. Working Content Boundary** — workspace-classification context that disambiguates Layer 1 / Layer 2 / Layer 3 (this standard governs published-repo boundary; complementary to Layer classification at workspace scope).

## 7. Cutover

Applies to PUBLIC-repo extractions whose extraction work executes strictly AFTER this standard's merge SHA recorded in `release/releases/RELEASE_LOG.md`. **The introducing release itself is exempt** for the META standard's authorship (the standard cannot fire on its own authorship without creating a reflexive-pipeline loop); the in-release `pmo-platform/harness/account-switcher/.gitignore` first-instance consumer applies the standard's patterns voluntarily at this release per the Pass 2 spec's FMF-3 mitigation. All public-repo extractions executed before this standard shipped are exempt (no PUBLIC repo had yet been extracted from pmo-platform).
