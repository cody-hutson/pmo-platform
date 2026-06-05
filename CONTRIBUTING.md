# Contributing

Thanks for your interest in `pmo-platform`. It's a modular-monolith of markdown agent
skills, governance specs, and Python release tooling driven by Claude Code — see the
[README](README.md) for the `operations`, `release`, and `core` modules.

## Contribution model

This is currently a single-maintainer project. Write access is limited to invited
collaborators, and unsolicited external pull requests generally won't be merged. If
you'd like to contribute, open an issue to ask about collaborator access — it's granted
by invitation only.

## Ground rules

- **Commit with a GitHub no-reply email, not a personal one.** Turn on
  *Settings → Emails → Keep my email address private*, then set your repo identity to
  the `…@users.noreply.github.com` address (`git config user.email`). A CI gate
  (`.github/workflows/commit-message-depersonalization.yml`) blocks personal email
  addresses and OS user-home paths from entering commit messages and author/committer
  identity.
- **No personal data in content.** Don't add real emails, tokens, machine paths, or
  private references to skills, specs, docs, or examples. The only sanctioned home for
  an owner contact email is `LICENSE` and `SECURITY.md`.
- **Keep references durable and links valid.** CI checks markdown link integrity and
  flags non-durable cross-references in the durable corpus
  (`.github/workflows/reference-durability.yml`, `release-link-check.yml`); summarize
  linked content inline rather than threading fragile paths through governed files.

## Making a change

1. Branch from `main`.
2. Make the change. If it changes skill or agent behavior, exercise it in Claude Code
   and sanity-check the output.
3. Open a PR and fill in the template. Put any `Closes #N` **only** in the *Issue
   References* block at the bottom of the PR body (the auto-close parser is lexical).
4. CI must be green: repo integrity, reference durability, link check, PR-body parser,
   secret scan, skill-license check, and the commit-message depersonalization gate.

## Reporting security issues

Please report vulnerabilities privately — see [SECURITY.md](SECURITY.md). Do not open a
public issue, PR, or discussion.
