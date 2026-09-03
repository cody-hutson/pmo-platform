# Onboarding journey

> **What this is:** the map across the whole clone → working-install journey, and where each external-host choice plugs in. One altitude above the individual walkthroughs — it names the full arc and the five host-adapter plug points, then **links out** to the step-by-step docs for every "how."

This document is the journey **spine**: a navigational map for the operator standing up a host configuration, and the contract an adapter author looks up. It does not restate install steps — for those, follow the links. Read it when you want to know *where am I in the whole journey, and where does my host plug in.*

It sits at the head of the onboarding set in [docs/README.md](README.md): INSTALL → GETTING_STARTED → FIRST_STEPS → workspace-setup → UPDATE. Each of those answers a "how"; this answers "what is the whole arc, and which parts are configurable."

## The journey — clone to working install

Seven named, ordered stages take you from a bare `git clone` to a verified working install running real work. Each stage names what happens and links to the authoritative how-to. The one stage with net-new substance here is **J4 (Configure hosts)** — where your external-surface choices are made and where the five adapter extension points converge.

| Stage | What happens | How-to |
|---|---|---|
| **J1 · Acquire** | `git clone` (HEAD-tracking, for builders) or fetch a pinned release tag (for users). The clone source is your repo host. | [INSTALL.md](INSTALL.md) |
| **J2 · Prerequisites** | Verify macOS, `git`, `jq`, and Claude Code are present. (Non-macOS support is roadmapped, not yet shipped.) | [INSTALL.md](INSTALL.md) |
| **J3 · Bootstrap** | `./install.sh` lays down the workspace layout, resolves operator-identity tokens, installs the security hooks, and seeds composition surfaces. It writes `operator.toml` — the config surface where your host choices live (see [Where your choices live](#where-your-choices-live)). | [INSTALL.md](INSTALL.md) |
| **J4 · Configure hosts** | **You declare your external-host choices** — repository host, ticketing surface, knowledge base, and AI tool — plus your default methodology. Each choice is written to the `operator.toml [adapters]` table. This is where all five adapter extension points below bind. Every choice ships a v1 default, so a fresh install runs end-to-end with no action; you change a choice only to point the platform at a different host. | [Adapter extension points](#adapter-extension-points) (this doc) · [workspace-setup.md](workspace-setup.md) |
| **J5 · Deploy** | `deploy.sh` mirrors skills, rules, and hooks to the runtime path your AI tool expects. The deployment target follows your AI-tool choice from J4. | [INSTALL.md](INSTALL.md) |
| **J6 · Verify** | `./docs/scripts/validate-install.sh` runs per-check validation and your first skill resolves. | [INSTALL.md](INSTALL.md) · [GETTING_STARTED.md](GETTING_STARTED.md) |
| **J7 · First work** | Invoke a real skill, then pick a track — configure a PMO project, or hook up a repo and drive a release. | [GETTING_STARTED.md](GETTING_STARTED.md) · [FIRST_STEPS.md](FIRST_STEPS.md) |

Stages J1–J3 and J5–J6 already have authoritative how-to in INSTALL.md; this spine names them and links out rather than reproducing their commands. J4 is the spine's contribution: a declared plug point for host choices that no current walkthrough owns (today's INSTALL.md ships GitHub + Claude Code as the built-in defaults), which is exactly why the adapters need a named place to converge.

## Adapter extension points

Each external-host dimension gets one **Adapter Extension Point** below. The five blocks share an identical seven-field shape, so each adapter extends the *same* contract instead of re-deriving its own. The spine fixes three things per dimension — the journey stage it plugs into, the config key it binds to, and the v1 default — and defers the full per-host enumeration and selection mechanism to each dimension's own roadmap milestone. The v1 defaults below ship today, so a fresh install runs end-to-end with no operator action.

The bare GitHub issue and milestone numbers behind each "Roadmap owner" line are listed once, with summaries, in [Provenance](#provenance) — the dimension names below are the durable handles.

### EP-REPO — repository-host extension point

- **Journey stage:** J1 (Acquire), J4 (Configure hosts).
- **Dimension owner (roadmap):** the `repo-host-adapter` milestone — enumerates supported hosts at its own design stage.
- **Config key (the seam):** `operator.toml [adapters].repo_host` — see [Where your choices live](#where-your-choices-live).
- **Default (v1 baseline):** `"github"` — GitHub via the `gh` CLI; ships first-class.
- **Contract the adapter must satisfy:** enumerate the supported repository hosts; declare a selection mechanism; bind the operator's choice to the config key; declare reduced-feature fallbacks for hosts that lack a GitHub-equivalent capability.
- **What the spine fixes (so adapters don't re-derive):** the journey stage, the config key name, and the v1 default. The adapter supplies only the per-host enumeration and selection mechanism.
- **Status:** Shipped default (`github`); broader host enumeration roadmapped under the `repo-host-adapter` milestone.

### EP-TICKETING — ticketing extension point

- **Journey stage:** J4 (Configure hosts).
- **Dimension owner (roadmap):** the `tracker-and-kb-adapters` milestone — enumerates supported ticketing surfaces at its own design stage.
- **Config key (the seam):** `operator.toml [adapters].ticketing` — see [Where your choices live](#where-your-choices-live).
- **Default (v1 baseline):** `"github"` — GitHub Projects (issues + milestones + a Projects v2 board); ships first-class, with partial Jira support.
- **Contract the adapter must satisfy:** enumerate the supported ticketing surfaces; declare a selection mechanism; bind the operator's choice to the config key; declare reduced-feature fallbacks where a surface lacks issues/milestones/board parity.
- **What the spine fixes (so adapters don't re-derive):** the journey stage, the config key name, and the v1 default. The adapter supplies only the per-host enumeration and selection mechanism.
- **Status:** Shipped default (`github`); broader surface enumeration roadmapped under the `tracker-and-kb-adapters` milestone.

### EP-KB — knowledge-base extension point

- **Journey stage:** J4 (Configure hosts).
- **Dimension owner (roadmap):** the `tracker-and-kb-adapters` milestone — enumerates supported KB platforms at its own design stage.
- **Config key (the seam):** `operator.toml [adapters].kb` — see [Where your choices live](#where-your-choices-live).
- **Default (v1 baseline):** `"markdown"` — a generic Markdown knowledge base (the repo's own `docs/` and reference tree); ships first-class.
- **Contract the adapter must satisfy:** enumerate the supported KB platforms; declare a selection mechanism; bind the operator's choice to the config key; declare reduced-feature fallbacks for platforms that lack local-Markdown parity.
- **What the spine fixes (so adapters don't re-derive):** the journey stage, the config key name, and the v1 default. The adapter supplies only the per-host enumeration and selection mechanism.
- **Status:** Shipped default (`markdown`); broader platform enumeration roadmapped under the `tracker-and-kb-adapters` milestone.

### EP-AITOOL — AI-tool extension point

- **Journey stage:** J4 (Configure hosts), J5 (Deploy).
- **Dimension owner (roadmap):** the `ai-tool-target-adapter` milestone — enumerates supported AI-tool targets at its own design stage.
- **Config key (the seam):** `operator.toml [adapters].ai_tool` — see [Where your choices live](#where-your-choices-live).
- **Default (v1 baseline):** `"claude-code"` — Claude Code (CLI or Desktop); ships first-class, and is the runtime `deploy.sh` mirrors to today.
- **Contract the adapter must satisfy:** enumerate the supported AI-tool targets; declare a selection mechanism; bind the operator's choice to the config key; declare the deployment target each tool expects so J5 (Deploy) mirrors to the right runtime path.
- **What the spine fixes (so adapters don't re-derive):** the journey stage, the config key name, and the v1 default. The adapter supplies only the per-target enumeration and selection mechanism.
- **Status:** Shipped default (`claude-code`); broader target enumeration roadmapped under the `ai-tool-target-adapter` milestone.

### EP-SCHED — scheduler extension point

- **Journey stage:** J4 (Configure hosts), J6 (Activate).
- **Dimension owner (roadmap):** the automation-registry milestone — enumerates supported scheduler surfaces at its own design stage.
- **Config key (the seam):** `operator.toml [adapters].scheduler` — see [Where your choices live](#where-your-choices-live).
- **Default (v1 baseline):** `"none"` — no scheduler on this install; every registered routine stays manually invocable. **This is the one extension point whose default is not a working backend, and that is deliberate:** registering a scheduled task is the one install step the installer cannot perform for you, so a backend default would have the config assert something the install guide denies. You lose nothing silently — the adapter prints a `MANUAL` line per routine saying exactly how to run it.
- **Contract the adapter must satisfy:** enumerate the supported scheduler surfaces; declare a selection mechanism; bind the operator's choice to the config key; **declare the reduced-feature fallback for an install with no scheduler** — the routine stays invocable and says so per routine, rather than falling silent (`SD-1`..`SD-4` in [scheduler-adapter-routine-firing.md](../core/standards/scheduler-adapter-routine-firing.md)).
- **What the spine fixes (so adapters don't re-derive):** the journey stage, the config key name, and the v1 default. The adapter supplies only the per-surface enumeration and selection mechanism.
- **Status:** Shipped defaults for both real backends — an agent-runtime scheduler for routines an agent session runs, and the repository host for routines whose entrypoint is a workflow (that class is derived from the entrypoint and does not consult this key). Broader enumeration gated on its own adapter ticket.

## Where your choices live

The host choices you make at **J4 (Configure hosts)** are written to one place: the **`operator.toml` config surface**, in its `[adapters]` table — `repo_host`, `ticketing`, `kb`, `ai_tool`, and `scheduler`. This is the single seam where onboarding-time operator choices land; the five extension points above all bind to keys in this one table.

This config surface is described in [ADR-017](../core/ADRs/ADR-017-distribution-architecture.md) (§Decision 1, the S2 Config surface), which names `operator.toml` — at `~/.config/pmo-platform/` — as the home for "identity, paths, methodology, adapters." The schema of that `[adapters]` table (its valid values, defaults, and field-level governance) is formalized in [core/config/operator.toml.template](../core/config/operator.toml.template); see also the [platform-config reference](platform-config-reference.md) for the broader config surface.

If you do nothing at J4, every selector keeps its v1 default and the platform runs end-to-end. You edit `operator.toml [adapters]` only to point the platform at a different host than the shipped default.

## How this fits — and what it is not

This spine **declares** the arc and the plug points; it **does not instruct**. For the step-by-step how of installing, exercising your first skill, or doing real work, follow the links to [INSTALL.md](INSTALL.md), [GETTING_STARTED.md](GETTING_STARTED.md), and [FIRST_STEPS.md](FIRST_STEPS.md) — those docs own the walkthrough, and this one never restates their steps.

This document is the *shipped, executable realization* of the roadmap-level onboarding-journey epic (the epic frames the cross-track composition across milestones but introduces no mechanism of its own; see [Provenance](#provenance)). The epic is the roadmap parent; this file is the artifact it points at — the two are distinct and not interchangeable. The codified architectural decision behind the journey — the four distribution surfaces and the clone-vs-install posture — lives in [ADR-017](../core/ADRs/ADR-017-distribution-architecture.md); this spine is its user-facing journey form, not a second copy of the decision.

## Provenance

The durable handles above are the dimension names and milestone slugs; the bare reference numbers are recorded here once for traceability.

### Issue References

- `#14` — the external-user plug-and-play onboarding-journey **epic**: roadmap-level cross-track framing across milestones, with no mechanism work of its own. This document is the shipped artifact that epic points at.
- `#703` — the story under which this onboarding-umbrella spine was authored (the `adapter-config-foundation` milestone): the canonical clone→working-install journey + extension-point contract the adapter tickets compose into.
- `#22` — the config-surface story (same milestone) that formalizes the `operator.toml [adapters]` schema this spine forward-references.
- `#10` — repository-host adapter (`repo-host-adapter` milestone): the dimension owner behind EP-REPO.
- `#11` — ticketing adapters (`tracker-and-kb-adapters` milestone): the dimension owner behind EP-TICKETING.
- `#12` — KB-platform adapters (`tracker-and-kb-adapters` milestone): the dimension owner behind EP-KB.
- `#13` — AI-tool target adapter (`ai-tool-target-adapter` milestone): the dimension owner behind EP-AITOOL.
