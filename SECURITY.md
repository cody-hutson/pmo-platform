# Security Policy

## Supported Versions

Only the latest commit on `main` is supported. Tagged releases are historical reference only — fixes ship to `main`.

## Reporting a Vulnerability

If you believe you have found a security vulnerability in this repository, please report it privately. Do **not** open a public issue, PR, or discussion for security reports.

- **Preferred:** [open a private security advisory](https://github.com/cody-hutson/pmo-platform/security/advisories/new) (GitHub Private Vulnerability Reporting).
- **Email (alternate):** chutson.git@gmail.com — subject `[travel-planner security] <short description>`.
- **Include:** affected file(s) or commit, steps to reproduce, expected vs. actual behavior, and any proof-of-concept.

## Response Expectations

This is a personal project maintained by a single operator. Response targets are best-effort:

| Severity | Acknowledgement | Initial Response |
|----------|-----------------|------------------|
| Critical (RCE, credential exposure, data loss) | Within 1 business day | Within 3 business days |
| High (privilege escalation, secrets leakage) | Within 3 business days | Within 7 business days |
| Medium / Low | Within 7 business days | Best-effort |

You will receive an acknowledgement, an initial assessment, and a remediation plan or rationale for non-action.

## Scope

**In scope:**
- Code in `core/` (configuration, deploy mechanism, governance, hooks, rules, schemas, skills, specs, standards)
- Code in `release/` (release tooling, governance, skills)
- Code in `operations/` (PMO operations, skills, templates)
- GitHub Actions workflows in `.github/workflows/`
- Repository configuration (Dependabot, branch settings)

**Out of scope:**
- Third-party dependencies (report to upstream maintainers — Dependabot tracks CVEs here)
- Operator-local configuration (`~/.gitconfig`, IDE plugins, OS settings)
- Cowork plugin internals (proprietary, managed by Anthropic)

## Defenses Currently in Place

| Control | Status |
|---------|--------|
| Dependabot vulnerability alerts | Enabled (auto on visibility flip to public) |
| Dependabot security updates (auto-PR) | Enabled |
| Dependabot version updates (scheduled) | See `.github/dependabot.yml` |
| Workflow SAST (actionlint) | See `.github/workflows/security.yml` |
| Python SAST (bandit) | See `.github/workflows/security.yml` |
| Python dependency audit (pip-audit) | See `.github/workflows/security.yml` |
| Secret scanning (gitleaks, full history) | See `.github/workflows/security.yml` |
| Native GitHub Secret Scanning | Auto-enables on visibility flip to public |
| Native GitHub Push Protection | Auto-enables on visibility flip to public |
| Private Vulnerability Reporting (PVR) | Enable at public flip (manual toggle; free for public repos) — the preferred reporting channel above |
| Branch protection on `main` | Enabled (force-push blocked, deletions blocked, required status checks, stale-review dismissal, required conversation resolution) |
| Operational secrets-handling policy | See [`core/standards/secrets-handling-policy.md`](core/standards/secrets-handling-policy.md) — categorization, storage matrix, gitignore policy, rotation, audit grep |
| Runtime credential-read blocking (Claude tools) | See [`core/rules/bypass-mode-readiness.md`](core/rules/bypass-mode-readiness.md) |

## Automated Security PRs — Pipeline Exemption

Dependabot version-update PRs and Dependabot security-update PRs **bypass the 13-stage improvement pipeline** (Stages 1-9). They are not routed through Triage, Bundle, Planning, or Solutioning — they go directly to PR review. They carry the `dependabot` label for every ecosystem registered with an `updates:` entry in `.github/dependabot.yml`, which is where that label comes from. An ecosystem that receives security updates without such an entry gets Dependabot's default labels instead, and the guarantees in this section do not reach it.

Rationale: dependency bumps are self-contained, reversible, and CI-validated. Subjecting each to the full pipeline would create overhead disproportionate to risk. The pipeline is reserved for work routed via `improvement.yml` (any category label) that requires design judgment.

The `cluster: security` label is retained on these PRs — by that same `updates:` entry, and subject to that same condition — so they remain discoverable in security audits.

### Dependency PRs and the package-freshness gate

A dependency PR that rewrites a file inside a rostered skill's compiled-package content set turns the pre-merge `.skill` package-freshness gate red: the committed package no longer matches what its source would build. Today that is one skill and two manifests, under `release/skills/pmo-skill-refiner/eval-viewer/tests/`.

**Dependabot cannot clear it.** It rewrites the manifest; it does not rebuild packages. Workflows it triggers receive a read-only token and no secrets, and a commit pushed by Actions using `GITHUB_TOKEN` starts no new workflow run — so the check would never re-report and the PR would stay blocked. There is no automated path.

**Clear it by hand, on the bot's own branch:** fetch the `dependabot/…` branch (it lives in this repository, not a fork, so anyone with write access can push to it); run the rebuild the gate's own failure output names, and commit the package together with its `.sha256` sidecar; push to that same branch. The push re-runs every check, and Dependabot stops rebasing a branch once a commit has been pushed to it, so the rebuild is not overwritten.

The same path clears the out-of-band case — a non-release PR editing a skill's `references/` — with the fetch step omitted, since that author already owns the branch.

**Admin-merge is an exception, not a step.** An administrator can merge past the red check. That is defensible only where the vulnerability being patched plainly outweighs shipping a stale package, and it requires a rationale recorded on the PR. It does not retire the rebuild: the freshness workflow also runs on every push to `main`, so a bypassed merge turns `main` itself red on the next run, and the rebuild is still owed — now on the default branch.
