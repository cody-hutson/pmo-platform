<!-- reference-durability: allow-link -->
# Roadmaps — in-repo home for operator-local roadmap instances

Canonical home for **initiative-roadmap instances** — the per-initiative and
cross-initiative roadmap docs that sequence work Now / Next / Later toward a
Capability Outcome.

> **Everything you write in this folder is git-ignored.** Only this `README.md` is
> tracked, so the folder ships with the repo and agents/operators always know where to
> author and reference roadmaps — while the roadmap instances themselves never enter
> git history. This preserves ADR-012's "instances are not tracked" decision and
> corrects only its *location* indirection (see
> [ADR-046](../core/ADRs/ADR-046-roadmap-instance-in-repo-home.md)).
>
> **Update-safe:** nothing in the platform's update path (`update.sh`,
> `setup-workspace.sh`, `git pull`) reads or overwrites this folder's contents —
> it is absent from the regeneration manifest and the instances are git-ignored.
> Your roadmaps survive updates; only this tracked `README` can change.

## Where roadmaps live

This folder (`/roadmaps/`) is the **default** resolution of the
`<OPERATOR_INSTANCE_ROADMAPS_PATH>` token. A deployment may **repoint** that token to a
different location (plug-and-play storage); when it is unset, roadmaps live here. The
token is the indirection; this folder is what it points to by default.

## How to use it

- One file per roadmap: `<initiative-name>.md` (e.g. `governance-hygiene.md`).
- Each roadmap states a **Capability Outcome**, a **Now / Next / Later** sequence, and
  **Sunset Criteria**, per the convention in
  [`initiative-roadmap-framework.md`](../core/standards/initiative-roadmap-framework.md)
  (the framework stays tracked; the instances do not).
- Instances are **git-ignored** — author freely; nothing here is committed except this
  `README.md`. This mirrors the repo's `analysis/` workspace pattern
  ([`analysis-workspace-standard.md`](../core/standards/analysis-workspace-standard.md)).
