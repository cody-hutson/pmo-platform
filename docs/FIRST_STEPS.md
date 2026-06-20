# FIRST_STEPS.md — pmo-platform

> The "go further" guide. [INSTALL.md](INSTALL.md) gets it on your machine ("do this"); [GETTING_STARTED.md](GETTING_STARTED.md) is a 5-minute taste of one skill ("try this"); this guide gets your **repo and projects connected** and walks your **first real cycle of work** ("now do real work").
> Audience: operators who installed the platform and want to start using it for actual program or release work.

---

## How to use this guide

Four parts. The first two are for everyone; then you pick a track.

1. **[Explore](#1-explore--play-qa-with-the-repo)** — learn the platform by interrogating it.
2. **[Orient](#2-orient--how-work-flows)** — the one mental model the whole platform runs on.
3. **Pick your track:**
   - **[Track A — PMO practitioner](#3a-track-a--pmo-practitioner-configure-your-first-project)** (you manage projects → the `operations` module).
   - **[Track B — Platform builder](#3b-track-b--platform-builder-hook-up-your-repo--run-a-release)** (you ship software releases → the `release` module).
4. **[Pointers to be effective](#4-pointers-to-be-effective)** — conventions that make the platform behave. Read these whichever track you took.

You can do both tracks — the release module can even ship releases *for* the operations module.

---

## 1. Explore — play Q&A with the repo

**Before configuring anything, spend ten minutes learning how the platform thinks.** The fastest way is the one we recommend to every new operator: open Claude Code in the repo and *ask it questions about itself*. The repository is written to be self-explanatory — the governance files, stage specs, and disciplines are the platform's own documentation, and Claude reads them on demand.

```bash
cd ~/Claude/pmo-platform
claude
```

Then ask, in plain language. Starter questions, grouped by what they teach:

**Orientation**

- "Give me a tour of this repo — what are the three modules and who is each one for?"
- "What's the difference between the `operations` module and the `release` module?"
- "What is a skill here, and how do I invoke one?"
- "Walk me through the architecture — what does `core/` provide to the other two modules?"

**How work flows**

- "Explain the 13-stage release pipeline in plain English."
- "What's the difference between the *hub* and a *spoke*?"
- "How do I file a work item, and what are the four issue templates for?"
- "What's a Milestone here, and how does an issue end up in one?"

**Going deeper**

- "I'm a PMO practitioner. What should I set up first, and which skills will I use daily?"
- "I want to ship a release of my own changes. Walk me through it end to end."
- "What are the guardrails I should know about before I let the platform change things?"

You don't need to read the whole corpus. Ask, follow the references Claude cites, ask again. This Q&A habit is also the best debugging tool you have — when something behaves unexpectedly later, ask the repo *why*.

---

## 2. Orient — how work flows

Everything the platform does is one of two things: **a single skill** (one focused capability) or **the release pipeline** (many stages, orchestrated). Get this picture and the rest is detail.

### Two ways to operate

| Mode | What it is | Example |
|---|---|---|
| **Single skill** | One invocation, one capability. What you did in GETTING_STARTED.md. | `/comms-writer`, `/daily-status`, `/release-planner` |
| **The hub** | A Claude Code session that drives a whole release through the pipeline, spawning subagents per stage. | "Operate release `v1.0.0-initial`" |

### The pipeline, in one picture

Work enters as a typed GitHub Issue and moves left-to-right. The first three steps are lightweight; the rest are *operated* by a hub session.

```
1. Intake        2. Triage        3. Bundle          4–13. Operate the release
──────────       ─────────        ─────────          ─────────────────────────
File a       →   Approve /    →   Group approved →   Paste the Hub Prompt into a
typed Issue      Defer /          issues into a      fresh session. The hub reads
(improvement /   Reject           versioned          the Milestone and spawns one
 bug /                            Milestone           spoke per stage (plan, design,
 observation /                    (vX.Y-slug)         build, test, QA, gates),
 adr)                                                 brings you each result, then
                                                      closes the release.
```

### Hub vs. spoke

The hub-and-spoke split is the heart of the release module — worth internalizing:

- **Hub** = the session *you* drive. Your command center. It reads the Milestone, scaffolds a sub-task per stage per issue, launches spokes, and at every decision point hands you a **Decision Briefing** (see [§4](#4-pointers-to-be-effective)).
- **Spoke** = a subagent the hub spawns to do *one stage of one issue* (e.g., "Stage 6 Engineering for this issue"). It works in a focused context and reports back to the hub. You don't manage spokes directly — you review what they produce.

The authoritative how-to is [release/references/how-to/hub-spoke-bridge.md](../release/references/how-to/hub-spoke-bridge.md); the stage-by-stage specs are under [release/references/pipeline/](../release/references/pipeline/); the concise operating procedure is [release/governance/release-process.md](../release/governance/release-process.md).

---

## 3a. Track A — PMO practitioner: configure your first project

The `operations` module manages *projects*. A project is a folder with a state file (`PROJECT.md`) and a standard structure the skills read and write.

### Scaffold it

Let the platform create the project for you:

```
/project-initiator
```

It scaffolds the project folder, writes a starter `PROJECT.md`, lays down the `01-Governance/ … 08-Generated/` structure, and registers the project in your `PORTFOLIO.md`. (Project folders live in your `projects/` workspace directory — *not* in this package repo. See [workspace-setup.md §2.2](workspace-setup.md).)

### Tell it how the project runs

Open the generated `PROJECT.md` and set the frontmatter. The fields the skills depend on:

| Field | Required | Notes |
|---|---|---|
| `project_name` | yes | Display name; match the folder name. |
| `project_owner` | yes | Single accountable owner. |
| `status` | yes | `ACTIVE` / `CLOSING` / `CLOSED`. |
| `delivery_approach` | yes | One of: `Scrum`, `Kanban`, `XP`, `Waterfall`, `PRINCE2`, `SAFe`, `Hybrid`, `Custom`. |

`delivery_approach` is load-bearing: skills parameterize their behavior to it (a Waterfall project gets phase-gate framing; a Scrum project gets sprint/velocity framing) instead of assuming Agile. The full schema, including the `Custom` extension block, is [core/schemas/project-schema.md](../core/schemas/project-schema.md).

### Do something real

With a project configured, the daily skills have context to work from:

- `/ppm-agent` — drop in a transcript or status note; it extracts decisions, actions, risks, and pushes them toward resolution.
- `/daily-status` — generate an AM/PM Teams-ready update from your trackers.
- `/comms-writer` — draft an audience-calibrated stakeholder message.

The full roster is in [operations/README.md](../operations/README.md); the governing rules are [operations/OPERATIONS.md](../operations/OPERATIONS.md).

---

## 3b. Track B — Platform builder: hook up your repo + run a release

The `release` module drives software through the 13-stage pipeline against **your GitHub repository**. "Hooking up your repo" means giving the platform the GitHub surfaces it operates on: issues, milestones, and a project board.

### Prerequisite: the GitHub CLI

The release pipeline operates GitHub through the `gh` CLI. It is **not** part of the base install — add it once:

```bash
brew install gh
gh auth login          # authenticate to the account that owns your fork
gh auth status         # expect: logged in, with repo scope
```

### Step 1 — Fork and confirm your work-item templates

You already cloned the repo. For the release pipeline you operate against a GitHub repo you own (your fork). The four intake templates ship in the clone at `.github/ISSUE_TEMPLATE/` — confirm they're on your fork:

| Template | Use it for |
|---|---|
| `improvement.yml` | A proposed change with a defined outcome (the workhorse). |
| `bug.yml` | A defect to fix. |
| `observation.yml` | A lightweight "something's off here" note that may later graduate to a proposal. |
| `adr.yml` | An architectural decision to record. |

These typed templates are what make the pipeline's gates computable — every required field (priority, evidence, acceptance criteria, documentation impact) has a place to live.

### Step 2 — File your first work item

```bash
gh issue create --web        # opens the template chooser on your fork
```

Fill in `improvement.yml`. The acceptance criteria you write here are what QA checks against at Stage 8 — make them verifiable.

### Step 3 — Triage and bundle into a Milestone

Triage decides Approve / Defer / Reject. Approved issues get grouped into a **versioned Milestone** — that Milestone *is* the release. Create one (or use the GitHub UI):

```bash
gh api repos/{owner}/{repo}/milestones \
  -f title='v1.0.0-initial' \
  -f description='First release — <one-line outcome statement>'
```

Then assign your approved issue to it. (`release-planner` can analyze your backlog and suggest bundles — `/release-planner`.)

### Step 4 — Set up the pipeline project board

Pipeline state (Status, Stage, Priority, Decision Date) lives in a single **"PMO Pipeline"** GitHub Project with four saved views. Creating and wiring it up is a one-time setup with specific fields and option values — follow the operational reference rather than improvising it: [core/disciplines/github-projects-guide.md](../core/disciplines/github-projects-guide.md). The board is what gives you the board/backlog/active-release/roadmap lenses on the same issues.

### Step 5 — Start the hub and run the release

Open a **fresh** Claude Code session and paste the **Hub Prompt** from [hub-spoke-bridge.md § How to Start](../release/references/how-to/hub-spoke-bridge.md). You edit just two values at the top:

```
MILESTONE="v1.0.0-initial"
REPO="<your-org>/pmo-platform"
```

From there the hub takes over. Your job during the release is small and high-leverage:

1. **Approve the release plan** the planning spoke produces.
2. **Review scaffolding** — the per-issue, per-stage sub-tasks.
3. **Review spoke output** — read each Decision Briefing; approve or request iteration.
4. **Render the gates** — the GO/NO-GO at Stage 9 and the Execute authorization at Stage 12 are yours.
5. **Close** — the hub verifies everything's done and finalizes the release log.

You are not doing the 13 stages by hand; you are *deciding* at the points that need judgment while the spokes do the focused work.

---

## 4. Pointers to be effective

These conventions are what keep the platform safe and legible. Knowing them up front saves confusion later.

### Governed vs. day-to-day changes

There are two speeds, and the platform enforces the distinction:

- **Changing the platform itself** — skills, governance files, folder structure, pipeline rules — is **never** done silently. It requires a GitHub Issue + an implementation plan + a PR ("**no ungoverned changes**"). If you ask a skill to fix something about the platform mid-task, it will *log an Issue* rather than quietly edit.
- **Day-to-day project work** — trackers, status logs, generated artifacts — is the opposite: operational updates are written automatically after processing so you're not babysitting saves.

### Autonomy is "recommend, then you decide"

Skills draft and recommend; you render the consequential decisions. Intake and triage are *Recommend* tier (the agent proposes, you confirm). The release gates (Stage 9 GO/NO-GO, Stage 12 Execute) are operator decisions by design. Nothing irreversible happens without you in the loop.

### Write-first-speak-second

A skill never claims "tracker updated" or "file written" until the write has actually succeeded. If you see the confirmation, it happened; if a write fails, the skill tells you. Don't trust a "done" you didn't see confirmed.

### Read the evidence labels

Output is labeled by how sure the platform is. Scan for the uncertain ones:

| Label | Means |
|---|---|
| `[SOURCE]` | Directly stated in a cited artifact (with location). |
| `[INFERRED]` | A reasoned conclusion, with the reasoning shown. |
| `[ASSUMPTION – CONFIRM]` | Not in any source — a proposed answer for **you to confirm**. |
| `[CONTEXT]` | Pulled from project memory (`PROJECT.md`). |
| `[RECOMMENDED]` | An agent recommendation, distinct from a committed date/decision. |

When you skim a long output, jump to the `[ASSUMPTION – CONFIRM]` items first.

### Decision Briefings and gates (the hub)

When you run a release, the hub never routes to the next step before handing you a **Decision Briefing**: the decisions it needs from you, findings that change the plan, and a status summary — each with the spoke's recommendation *and* the hub's own (adversarial) take. At stage boundaries you'll see a gate verdict — **PROCEED**, **PROCEED WITH CAVEATS**, or **HOLD** — with the evidence behind it. You make the call; the briefing exists to make that call fast.

### When in doubt, ask the repo

The Q&A habit from [§1](#1-explore--play-qa-with-the-repo) is your standing tool. "Why did the hub hold at Stage 8?" or "What does this gate criterion mean?" — ask in the session; the platform explains itself from its own specs.

---

## Where to go next

- [operations/README.md](../operations/README.md) — the 13 PMO-practitioner skills.
- [release/README.md](../release/README.md) — the 6 release skills and pipeline references.
- [release/references/how-to/hub-spoke-bridge.md](../release/references/how-to/hub-spoke-bridge.md) — the full hub operating guide.
- [docs/module-apis.md](module-apis.md) — the consolidated cross-module API and composition patterns.
- [docs/workspace-setup.md](workspace-setup.md) — why the workspace is laid out the way it is.

Welcome to operating the platform.
