# Local state — repo-scoped, git-ignored

Home for **this repository's own release, run and operating state**: what a platform run
produces, and the configuration it reads, while releasing or operating this repository —
release-hub runs and the pipeline event log, for example — each in the subfolder the
placement standard names for it.

> **Nothing in this folder is ever committed.** Only this `README.md` is tracked, so the
> folder ships with the repository and a fresh clone finds the home. Everything else here
> is git-ignored, and a commit guard refuses any file staged under it — a forced
> `git add -f` included, and whether or not the session was launched with the hook bypass.
> The same guard reads every commit a push would publish, unless the push runs under the
> hook bypass. Those local checks are the only ones that run before a branch is published:
> a check on every pull request keeps a file here off `main`, but it runs after the branch
> is already on the remote.

## What does not belong here

- Anything about work outside this repository: another repository's runs, project or
  portfolio work, or any record that describes a session, folder or work item elsewhere.
  Removing an identifier does not make such a record admissible.
- Leak-risk content — the PII scan lists, the people roster and their backups — which
  lives outside every repository.
- Read-once analysis and roadmap instances, which have homes of their own.

## Governing standard

Classes, homes, the admission test and the protections:
[`core/standards/instance-data-placement-standard.md`](/core/standards/instance-data-placement-standard.md)
