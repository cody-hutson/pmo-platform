# Security Policy

## Supported Versions

Only the latest commit on `main` is supported. Tagged releases are historical reference only — fixes ship to `main`.

## Reporting a Vulnerability

If you believe you have found a security vulnerability in this repository, please report it privately. Do **not** open a public issue, PR, or discussion for security reports.

- **Preferred — GitHub Private Vulnerability Reporting (PVR).** Open a private security advisory from the repository's **Security → Advisories → "Report a vulnerability"** page. The report stays private until a fix is coordinated. _(Available once this repository is public and PVR is enabled — see Defenses below.)_
- **Alternate — Email.** chutson.git@gmail.com
  - **Subject:** `[pmo-platform security] <short description>`

**Please include:** affected file(s) or commit, steps to reproduce, expected vs. actual behavior, and any proof-of-concept.

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

Dependabot version-update PRs and Dependabot security-update PRs are tagged with the `dependabot` label and **bypass the 13-stage improvement pipeline** (Stages 1-9). They are not routed through Triage, Bundle, Planning, or Solutioning — they go directly to PR review.

Rationale: dependency bumps are self-contained, reversible, and CI-validated. Subjecting each to the full pipeline would create overhead disproportionate to risk. The pipeline is reserved for work routed via `improvement.yml` (any category label) that requires design judgment.

The `cluster: security` label is retained on these PRs so they remain discoverable in security audits.
