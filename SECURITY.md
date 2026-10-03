# Security Policy

This is a personal project maintained by a single operator. This policy covers three things: how to report a vulnerability, what we treat as one, and how reports are handled and disclosed.

## Supported Versions

Only the latest commit on `main` is supported. Tagged releases are historical reference only — fixes ship to `main`.

To pick up a security fix:

1. Update to the latest `main` as described in [`docs/UPDATE.md`](docs/UPDATE.md).
2. Follow any extra remediation steps the advisory gives, such as refreshing the installed hooks.

## Reporting a Vulnerability

Report suspected vulnerabilities privately. Do **not** open a public issue, PR, or discussion for them.

- **Preferred:** [open a private security advisory](https://github.com/cody-hutson/pmo-platform/security/advisories/new) (GitHub Private Vulnerability Reporting).
- **Email (alternate):** chutson.git@gmail.com — subject `[pmo-platform security] <short description>`.
- **Include:**
  - the affected file(s) or commit;
  - steps to reproduce;
  - expected vs. actual behavior;
  - what an attacker gains;
  - any proof of concept.
- **Confirm before you report.** Reproduce the problem against the current `main`, or point to the shipped code that contains it. If a scanner or an AI assistant helped you find it, say so, and say what you verified yourself. Unconfirmed tool output is not a report.
- **If you are unsure** whether something is a vulnerability, report it privately anyway. We triage every private report. If one turns out to be a security-relevant bug rather than a vulnerability, we may move it to a public issue with your agreement.

Problems in Claude Code or Cowork themselves belong to Anthropic: report them through [Anthropic's security program](https://hackerone.com/anthropic). Problems in third-party dependencies belong upstream.

## What Counts as a Vulnerability

### Threat model

pmo-platform runs on the operator's own machine, under the operator's account, alongside an AI coding agent.

- **Trusted:**
  - the operator;
  - the operator's OS account and its configuration;
  - the environment that hooks and scripts run in;
  - the repository's tracked content and CI;
  - code the operator chooses to run.
- **Not trusted:**
  - content the agent reads or receives, such as web pages, issue and PR text, documents, tool output, and eval outputs produced by a model under test;
  - any instructions embedded in that content.

The PreToolUse hooks are defense in depth. They lower the chance that an agent takes a destructive, credential-reading, or data-egress action, whether because it is confused or because it is following injected instructions. They work by matching command text, so they have coverage limits. Those limits are documented in the hook registry's [Known Limitations](core/rules/bypass-mode-readiness.md#known-limitations) section and in each rule's accepted-residual entries. The hooks are not a sandbox: the operator's account permissions remain the security boundary.

### The bar

A finding is a vulnerability when all of these hold:

1. **It is confirmed.** It has been reproduced, or confirmed in shipped code.
2. **It affects what users install** (the current `main`), and users need to take some action because of it.
3. **Something untrusted gains what it should not**, by one of these routes:
   - it reads data it should not, such as credentials, secrets, or operator data;
   - it changes data or code it should not, or runs code;
   - it leaves a protection this project documents fully off on a supported setup — for example, every hook failing open on a documented install;
   - it gets past a hook in a way that reaches beyond the limitations the hook registry already documents.

### Not vulnerabilities

These are handled as public bugs or hardening work, not as advisories:

- Gaps inside the hook registry's documented limitations, including a new spelling of a gap already listed there.
- Anything that requires control of a hook's own environment, the operator's account, or the build and CI environment. All of these are trusted under the threat model.
- Effects limited to controls running in warn mode, which log rather than block by design.
- Defects in tests, fixtures, and test harnesses, including sandbox-isolation bugs with no attacker.
- Observations that have not been confirmed.

When the registry closes a documented limitation, findings previously classed against it are re-rated against this bar.

## How Reports Are Triaged

Each finding below gets one of four dispositions:

- every private report;
- every security-relevant finding that the maintainer's own tooling raises (the release pipeline, audits, and agents).

| Disposition | Meaning | Handling |
|---|---|---|
| **Vulnerability** | Meets the bar above | Filed as a draft security advisory with severity, CWE, affected and patched versions, and reproduction steps. Fixed privately. The advisory is published once the fix is on `main`. |
| **Security-relevant bug** | A real defect in a protection, below the bar | Filed as a public issue, described in general terms until it is fixed. Fixed as a regular bug. |
| **Bug** | A correctness or robustness issue with no security effect | Filed as a public issue. |
| **Not applicable** | Cannot be reproduced, is not part of this project, or is excluded above | Closed, with the reason given to the reporter. |

External reporters always start privately, as described above. The maintainer's own tooling applies the bar itself:

- It files a draft advisory only for a vulnerability.
- It routes everything else to a public issue, or to the existing issue that already owns the finding.

## Response and Disclosure

Response targets are best-effort:

| Severity | Acknowledgement | Initial Response |
|----------|-----------------|------------------|
| Critical (RCE, credential exposure, data loss) | Within 1 business day | Within 3 business days |
| High (privilege escalation, secrets leakage) | Within 3 business days | Within 7 business days |
| Medium / Low | Within 7 business days | Best-effort |

You will receive:

- an acknowledgement;
- an initial assessment that gives the disposition;
- a remediation plan, or the rationale for not acting.

- **Coordinated disclosure.** We aim to fix and publicly disclose a confirmed vulnerability within 90 days of acknowledging it. That happens sooner if the vulnerability is being actively exploited, and later only by agreement with the reporter. Please keep the details private until the advisory is published or the 90 days have passed.
- **Advisories.** Advisories are published on this repository's [security advisories page](https://github.com/cody-hutson/pmo-platform/security/advisories) after the fix is on `main`. Each one gives:
  - the impact;
  - the affected and fixed versions;
  - any workaround;
  - the steps users must take.

  Severity uses the four levels above. A published advisory may also carry a CVSS score from GitHub's calculator. When users must take action, a CVE is requested through GitHub.
- **Credit.** Reporters are credited in the advisory unless they prefer otherwise.

## Safe Harbor

We consider security research to be authorized when it follows this policy in good faith.

- We will not pursue legal action against you for that research.
- If a third party takes action against you over research that followed this policy, we will make that authorization known.

Test only against your own installation. Do not access, change, or delete data that is not yours. If you are unsure whether something is allowed, ask privately first.

*Adapted from the disclose.io Simple Safe Harbor terms (CC0).*

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
- Claude Code itself (report to Anthropic, as above)

## Defenses Currently in Place

| Control | Status |
|---------|--------|
| Private Vulnerability Reporting (PVR) | Enabled — the preferred reporting channel above |
| Dependabot vulnerability alerts | Enabled |
| Dependabot security updates (auto-PR) | Enabled |
| Dependabot version updates (scheduled) | See `.github/dependabot.yml` |
| Native GitHub secret scanning | Enabled |
| Native GitHub push protection | Enabled |
| Code scanning (CodeQL default setup) | Enabled — Actions, JavaScript/TypeScript, Python |
| Workflow SAST (actionlint) | See `.github/workflows/security.yml` |
| Python SAST (bandit) | See `.github/workflows/security.yml` |
| Custom SAST (semgrep, template-context XSS) | See `.github/workflows/security.yml` |
| Python dependency audit (pip-audit) | See `.github/workflows/security.yml` |
| Secret scanning (gitleaks, full history) | See `.github/workflows/security.yml` |
| Advisory regression gates (hook dependency fail-closed; eval-viewer security) | See `.github/workflows/security.yml` |
| Branch protection on `main` | Enabled (force-push blocked, deletions blocked, required status checks, stale-review dismissal, required conversation resolution) |
| Version-tag protection | Enabled — a tag ruleset blocks deleting or moving version tags |
| Operational secrets-handling policy | See [`core/standards/secrets-handling-policy.md`](core/standards/secrets-handling-policy.md) — categorization, storage matrix, gitignore policy, rotation, audit grep |
| Runtime credential-read blocking (Claude tools) | See [`core/rules/bypass-mode-readiness.md`](core/rules/bypass-mode-readiness.md) |

## Automated Security PRs — Pipeline Exemption

Dependabot version-update PRs and Dependabot security-update PRs **bypass the 13-stage improvement pipeline** (Stages 1-9). They are not routed through Triage, Bundle, Planning, or Solutioning — they go directly to PR review. They carry the `dependabot` label for every ecosystem registered with an `updates:` entry in `.github/dependabot.yml`, which is where that label comes from. An ecosystem that receives security updates without such an entry gets Dependabot's default labels instead, and the guarantees in this section do not reach it.

Rationale: dependency bumps are self-contained, reversible, and CI-validated. Subjecting each to the full pipeline would create overhead disproportionate to risk. The pipeline is reserved for work routed via `improvement.yml` (any category label) that requires design judgment.

The `cluster: security` label is retained on these PRs — by that same `updates:` entry, and subject to that same condition — so they remain discoverable in security audits.

### Dependency PRs and the package-freshness gate

A dependency PR that rewrites a file inside a rostered skill's compiled-package content set turns the pre-merge `.skill` package-freshness gate red: the committed package no longer matches what its source would build. Today that is one skill and two manifests, under `release/skills/pmo-skill-refiner/eval-viewer/tests/`.

**Dependabot cannot clear it.** It rewrites the manifest; it does not rebuild packages. Workflows it triggers receive a read-only token and no secrets, and a commit pushed by Actions using `GITHUB_TOKEN` starts no new workflow run — so the check would never re-report, and when the sentinel at `.github/skill-package-freshness.enforce` reads `enforce` and that check is among the required status checks on `main`, the PR would stay blocked. There is no automated path.

**Clear it by hand, on the bot's own branch:** fetch the `dependabot/…` branch (it lives in this repository, not a fork, so anyone with write access can push to it); run the rebuild the gate's own failure output names, and commit the package together with its `.sha256` sidecar; push to that same branch. The push re-runs every check, and Dependabot stops rebasing a branch once a commit has been pushed to it, so the rebuild is not overwritten.

The same path clears the out-of-band case — a non-release PR editing a skill's `references/` — with the fetch step omitted, since that author already owns the branch.

**Admin-merge is an exception, not a step.** When that check is among the required status checks on `main`, an administrator can merge past the red check. That is defensible only where the vulnerability being patched plainly outweighs shipping a stale package, and it requires a rationale recorded on the PR. It does not retire the rebuild: the freshness workflow also runs on every push to `main`, so a bypassed merge turns `main` itself red on the next run, and the rebuild is still owed — now on the default branch.
