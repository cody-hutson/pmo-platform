---
version: public-flip-depersonalization-enforcement
date: 2026-06-21
type: note
issues: ["#383", "#324", "#1827", "#529", "#1137", "#323", "#411", "#1823", "#1098", "#376", "#1850"]
pr: "#1847"
links:
  log_anchor: "#public-flip-depersonalization-enforcement-version-less"
reversibility-tier: CHEAP
themes: ["cluster:governance-hygiene"]
summary: "The public repository now defends its own depersonalization boundary with standing checks and guards — operator-specific names, handles, and machine paths are kept out of the public corpus and out of issue/PR bodies automatically, instead of by manual review."
requires_action: false
breaking: false
components: ["deploy.sh", "setup-workspace.sh", "block-gh-path-leak.sh", "block-draft-files.sh", "depersonalization-spec.md", "operator.toml"]
followups: []
---

# The public repo now guards its own depersonalization boundary

2026-06-21 · public-flip-depersonalization-enforcement

The platform is a public repository, but it's operated from a private workspace that holds the operator's real name, GitHub handle, machine paths, and project IDs. Keeping those out of the public copy used to rely on remembering to scrub them by hand. This release makes that boundary self-defending: build-time checks and runtime guards catch operator-specific identifiers and machine paths before they reach the public repository — in tracked files, in the scripts that ship with it, and in the bodies of GitHub issues and PRs.

> **Skip the rest** unless you operate the platform or care how the public/private boundary is enforced.

## Who this affects

- **The workspace operator** — the main beneficiary: the private/public boundary is now enforced automatically rather than by manual vigilance.
- **Anyone installing the platform** — your local `operator.toml` config now survives a re-run of setup without losing sections you added.
- **Everyone else** — no visible change; this is internal hygiene.

## What changed for everyone using the platform

- **Two new build checks.** The deploy validator now flags non-portable machine paths (like `/Users/<you>/…`) in tracked scripts, and enforces the registry of `[OPERATOR_*]` placeholder tokens — so private values can't quietly reappear. *Why it matters:* a private detail reaching a public repository cannot be taken back, so this has to be caught before the push rather than noticed after it.
- **Two new guards (warn-only to start).** One scans GitHub issue/PR text you post through the CLI for operator-local paths; the other keeps draft/scratch notes out of the tracked public corpus. Both warn rather than block at first, so there's no disruption while they prove out. *Why it matters:* issue and PR text is a public surface that no file-level check was watching, and it is the one people paste raw paths into.
- **Config that survives setup.** Re-running workspace setup no longer drops custom sections from your `operator.toml`. *Why it matters:* re-running setup is routine, and silently losing settings you added is the kind of thing you only discover much later.
- **Cleaner placeholders.** The Jira URL and the GitHub-Projects field IDs now use proper localized placeholders, and a leftover internal path variable was unified onto the standard workspace-root variable. *Why it matters:* these were the last few spots where a real account or machine detail was still written out in full instead of standing in as a placeholder.

## Notes

All four new guards ship in warn-mode first — they report what they *would* block without blocking — so the enforcement can be observed before it's made strict. This release is version-less: it shipped under a theme name rather than a version number, because the next number was claimed by a release that landed in parallel.
