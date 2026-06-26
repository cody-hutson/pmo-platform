# GETTING_STARTED.md — pmo-platform

> The "try this" companion to [INSTALL.md](INSTALL.md) ("do this") and [workspace-setup.md](workspace-setup.md) ("why this").
> Audience: operators who completed INSTALL.md and want a first hands-on touch.
> Voice: tutorial, second-person, action-anchored. For installation steps, see INSTALL.md. For architectural rationale, see workspace-setup.md.

---

## 1. What you'll do in this guide

In the next 5-8 minutes you'll:

1. **Invoke your first PMO skill** — `/prompt-builder` will turn a rough prompt draft into a working prompt with a short critique.
2. **Read the response panel** to see what the skill produced (no files written; the output lives in the conversation).
3. **Modify your workspace identity** — change the operator name in your workspace-root `CLAUDE.md` — and re-invoke the skill so the new context flows through.
4. **See cross-module composition without re-invoking** — read how `prompt-builder` (core) feeds `pmo-process-designer` (operations) and `build-reviewer` (release) at module-apis.md.

You'll end with a working prompt in your conversation, an understanding of how the three modules compose, and a clear pointer to the next thing to try.

---

## 2. Prerequisites

If you completed [INSTALL.md](INSTALL.md), you're ready. Two-second sanity check:

```bash
ls ~/.claude/skills/ | grep -E "^prompt-builder$"
ls ~/Claude/CLAUDE.md
```

Both commands should print a result. If `prompt-builder` is missing, the install's skill-deployment phase did not complete successfully — re-run `./install.sh` (idempotent) or invoke the skill deployment directly with `~/Claude/pmo-platform/core/deploy/deploy.sh --deploy prompt-builder`. If `CLAUDE.md` is missing, return to INSTALL.md § 2b.

---

## 3. Step 1 — Invoke your first PMO skill

Open Claude Code in your workspace (`cd ~/Claude && claude`), then type:

```
/prompt-builder
```

When Claude asks what you'd like help with, paste this:

> I want a prompt that asks Claude to summarize a long technical document for a non-technical stakeholder. It should produce a 5-line executive summary with the decisions, the risks, and one ask. Make it good for a CFO who reads twenty docs a week.

Press Enter.

**What you'll see (in the Claude Code response panel):** A short critique (3-6 points naming the highest-leverage issues with the request) followed by a copy/paste-ready prompt block tailored to your goal. The skill does live web research on current Anthropic prompting guidance before producing the output, so the result reflects what works for the current model — not stale recommendations.

The output stays in your conversation. You can scroll up to re-read it, copy it into a separate file if you want to keep it, or iterate on it ("now make it 3 lines instead of 5").

(~2-3 min, including model latency.)

---

## 4. Step 2 — Read the output

In the response panel, look for these elements:

- **A short critique** — three to six bullet points naming the highest-leverage issues with the request you pasted (audience clarity, output shape, success criteria, etc.).
- **A copy/paste-ready prompt block** — usually rendered in a fenced code block, ready to use against a long doc.
- **A live-research reference** — `prompt-builder` fetches current Anthropic prompting guidance every invocation; you may see a brief note about what it picked up.
- **Optional `[ASSUMPTION]` labels** — if `prompt-builder` had to make assumptions to produce the rewrite (e.g., assumed "CFO" means a typical finance-org CFO not a startup founder), those are named inline.

The output is structured but conversational. There is no separate file to open — the response panel IS the artifact. Copy the prompt block into your own workflow when you want to use it.

---

## 5. Step 3 — Modify your workspace identity and re-invoke

Your workspace-root `CLAUDE.md` (created during install) holds operator-identity context that every skill picks up. The `setup-workspace.sh` script substituted your name into it during install; let's change it and watch the change propagate.

Open `~/Claude/CLAUDE.md` in your editor. Find the line near the top with your name (something like "Workspace Owner: \<your name\>"). Change it to anything else — for this demo, use `Alex Reviewer`. Save the file.

Now re-invoke `/prompt-builder` with the same prompt request:

```
/prompt-builder
```

Paste the same CFO-summary description from § 3.

**What you'll see this time:** The output is structurally the same — critique plus prompt block — but the context shifts. If your prior invocation referenced you by name in the critique ("for your CFO use case"), the new invocation will reference Alex Reviewer's CFO use case. This is the platform's identity-substitution mechanism in action: one file (`CLAUDE.md`) drives operator context across every skill, no per-skill configuration needed.

**Reset your CLAUDE.md** when you're done playing — change `Alex Reviewer` back to your name. The file is yours; the platform reads it, never writes to it during skill invocation.

(~1-2 min to edit, save, re-invoke, observe.)

---

## 6. What just happened

You exercised the platform's smallest unit of capability — a single skill — and you saw the identity-resolution mechanism that ties every skill to your workspace.

The skill you invoked, `prompt-builder`, lives in the `core/` module. It is shared kernel — every other skill in the platform can consume it. That's not abstract: `operations/skills/pmo-process-designer` calls `prompt-builder` when it needs to refine a requirements prompt; `release/skills/release-planner` calls it when drafting a milestone description. The composition runs through `core/` because `core/` is the only thing both consumer modules are allowed to depend on.

That isolation is the load-bearing property of the modular monolith:

- **`operations/`** consumes `core/`. Cannot reference `release/`.
- **`release/`** consumes `core/`. Cannot reference `operations/`.
- **`core/`** depends on nothing. It is the shared substrate.

The boundary is enforced — see [`core/ADRs/ADR-007-core-module-boundary.md`](../core/ADRs/ADR-007-core-module-boundary.md) for the rationale. Run [`core/deploy/tools/cross-module-audit.sh`](../core/deploy/tools/cross-module-audit.sh) to verify the invariant at the current SHA.

You saw the operations and release modules indirectly: every skill you'll invoke from this point forward is one of them, and each pulls from `core/` the same way `prompt-builder` does. The walkthrough showed you the kernel; the next-task patterns below show you the consumers.

For the cross-module composition patterns in detail — including how `operations/skills/pmo-process-designer` (requirements builder) and `release/skills/build-reviewer` (production-readiness review) compose through `core/` — see [docs/module-apis.md § 5 — Cross-module composition patterns](module-apis.md#5-cross-module-composition-patterns).

---

## 7. People-graph adoption — one roster, every tier

The skills you just met can resolve *people* — owners, escalation targets, who-covers-whom — from a single source you fill once. This is the **people-graph**: an operator-instance roster that the platform reads at every tier (project, portfolio, program, initiative) so you never re-enter a name. This section is the end-to-end adoption path: where the roster lives, how to fill it, how each tier's owner points into it, and how four skills consume it.

### 7.1 Where the roster lives (auto-seeded on install)

The filled roster is **operator-instance** — it holds real people's names, so it is never committed to the repository. As of v2.26 it is **auto-seeded on install**: `setup-workspace.sh` copies the de-identified template to your instance directory on a fresh install, create-once (it never clobbers a roster you've already filled — that would be an irreversible loss of your data).

Its path is resolved by the `pmo_people_roster()` accessor in `core/deploy/lib-instance-path.sh`, not hardcoded:

```
pmo_people_roster()  →  ${PMO_PEOPLE_ROSTER:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/people-roster.yaml}
```

- **Default:** `${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/people-roster.yaml`.
- **Overridable:** set `PMO_PEOPLE_ROSTER` to point at an explicit file, or `PMO_INSTANCE_PATH` to relocate the whole instance directory (the roster leaf is appended to it).
- **Never committed:** the file sits *outside* the repository tree (primary protection), is matched by the `**/people-roster.yaml` `.gitignore` rule (catches a stray in-tree copy), and its names are fed into the PII pre-commit needle list. Three layers, all pointing the same way: roster data does not enter git.

To find your seeded copy:

```bash
echo "${PMO_PEOPLE_ROSTER:-${CLAUDE_WORKSPACE_ROOT:-$HOME/Claude}/personal/pmo-instance/people-roster.yaml}"
```

### 7.2 Fill it (post-seed)

The seeded file is the de-identified template with `[PLACEHOLDER]` fields. Open your instance copy and fill one entry per person — never edit the tracked template at `operations/templates/people-roster-template.yaml`. The fields each entry carries:

| Field | What it is |
|---|---|
| `person_id` | Stable identity (e.g. `person-id-001`). The spine — every owner-ref and coverage edge joins on this. |
| `preferred_name` / `name_spelling` | How to address and spell the person. |
| `roles` / `capability_tags` | Functional roles and capability **tags** (tags, never ratings). |
| `escalates_to` | A *functional* escalation target (a `person_id`) — a routing hint, **not** an HR reporting line. |
| `backup_coverage` | The `person_id`s who cover this person. |
| `comms_calibration` | Preferred tone/channel; `unknown` if not known. |
| `status` | `active` / `on-leave` / `departed`. A departed entry **persists** (a tombstone) so prior refs still resolve. |
| `linked_project_ids` | Projects this person is linked to. |

The roster is a *functional coordination* artifact — who does what, how to reach them, who covers whom. It is **not** an HR or performance system: capability is a tag, never a rating, and the excluded-fields list in the template header (no compensation, no performance, no free-text notes) is closed by construction. Unknown values stay `unknown` — never guessed. Full schema and the reading contract: [`operations/templates/people-roster-template.yaml`](../operations/templates/people-roster-template.yaml).

### 7.3 Wire the owner-refs — one roster serves all tiers

You don't keep a separate owner list per tier. Each tier's owner field is a **typed reference into the roster** (`ref→Person`, resolving on `person_id`), so one filled roster grounds every tier:

| Tier | Owner field | Where it lives |
|---|---|---|
| Project | `project_owner` → Person | `PROJECT.md` frontmatter |
| Portfolio | `portfolio_owner` → Person | the Portfolio entity |
| Program | `program_owner` → Person | the Program entity |
| Initiative | `sponsor` → Person | the Strategic-Initiative entity |

For an owner who is **not** in your roster (an external client or vendor contact), each tier carries an optional `*_external` free-text fallback (`project_owner_external`, etc.) — exactly one of {the ref, the external fallback} is populated. A populated ref that does not resolve to a roster Person is a malformed write (blocked); an existing free-text owner name migrates by resolving against the roster — a unique match becomes the ref, an ambiguous match routes to the operator clarification queue rather than being silently dropped.

The operational owner fields work the same way: a RAID item's `owner_person_id` and a decision's `decision_maker_person_id` are also refs that resolve on `person_id`. So setting `project_owner: person-id-001` in `PROJECT.md` and writing a RAID item owned by `person-id-001` both point at the same roster entry — the leadership-owner axis and the operational-owner axis unify on one anchor. Schema: [`core/schemas/project-schema.md`](../core/schemas/project-schema.md); the full entity model: [`core/disciplines/project-entity-model.md`](../core/disciplines/project-entity-model.md).

### 7.4 How four skills consume it (read-only)

The skills read the people-graph as a **composed view** — a read-time join, never a materialized copy. The view composes three sources on `person_id`: your roster (functional attributes), the Person entity (the global identity anchor), and the Resource entity (project-scoped allocation). It answers three queries: *who-does-what*, *who-covers-whom* (the `escalates_to` / `backup_coverage` edges), and *coverage-by-capability* (which active people carry a capability tag right now). The contract: [`core/disciplines/people-coverage-graph.md`](../core/disciplines/people-coverage-graph.md).

Four skills read that view — and only read it. None of them writes the roster, the Person entity, or the graph; an unresolved name is surfaced for you to confirm, never invented:

- **`comms-writer`** — resolves the preferred name and spelling of named and owner people for the message it drafts (*who-does-what*).
- **`tracker-manager`** — resolves a RAID item's `owner_person_id` and a decision-maker ref to a Person for display and identity (*who-does-what*).
- **`ppm-agent`** — finds the right owner, follows `escalates_to` for the functional escalation target, and uses coverage-by-capability to find a backup when the primary owner is unavailable.
- **`delivery-engine`** — answers read-only "who covers capability X / project Y" from the coverage-by-capability index, filtered by `status` for who-can-cover-right-now.

Fill the roster once, point your tier owners at it, and these four skills resolve people consistently across every project — no per-skill configuration, no duplicated people list.

---

## 8. Where to go next

Now that you've seen one composition, the rest of the platform is yours to explore.

**Ready to do real work?** [FIRST_STEPS.md](FIRST_STEPS.md) takes you from this single-skill taste to operating the platform — exploring by Q&A, the work→release mental model, and the two audience tracks (configure a project, or hook up a repo and run a release).

**Module catalogs:**

- [`operations/README.md` § Public API](../operations/README.md) — 13 invocation skills covering intake, daily-status, comms, requirements, project initiation, delivery management.
- [`release/README.md` § Public API](../release/README.md) — 6 invocation skills covering release planning, build review, implementation planning, deployment.
- [`core/README.md` § Public API](../core/README.md) — 3 invocation skills (`prompt-builder`, `pmo-qa-auditor`, `eval-writer`) plus the shared kernel.

**Cross-module reference:**

- [`docs/module-apis.md`](module-apis.md) — consolidated public-API catalog with composition patterns + versioning conventions.
- [`docs/workspace-setup.md`](workspace-setup.md) — architectural rationale for the four-sibling-directory layout.

**Common next-task patterns:**

- "I want to summarize a long document" → use the prompt block you just generated.
- "I want to draft a status update for stakeholders" → `/comms-writer` (operations).
- "I want to convert business context into structured requirements" → `/pmo-process-designer` (operations).
- "I want to scaffold a new project folder" → `/project-initiator` (operations).
- "I want to plan a release of my own work" → `/release-planner` (release).
- "I want to audit a markdown document for review-readiness" → `/build-reviewer` (release).
- "I want to author or edit a platform skill" → `/pmo-skill-editor` or `/pmo-skill-refiner` (release).

If something didn't work the way this guide described — a skill didn't appear in autocomplete, the response panel was empty, the CLAUDE.md edit didn't propagate — run the validator:

```bash
~/Claude/pmo-platform/docs/scripts/validate-install.sh
```

It diagnoses the install layer and the first-task layer separately, and tells you exactly what's missing.

Welcome to the platform.
