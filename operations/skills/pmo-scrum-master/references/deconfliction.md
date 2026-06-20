<!-- reference-durability: allow-link -->
# Scrum Master — Deconfliction Reference

This reference is the lookup surface the **Scrum Master Specialist** (`pmo-scrum-master`) consults when deciding whether a request belongs to it or to an adjacent role. The SKILL.md `## Mode Selection` Step 2 and `## Dependency Graph Node` cite this file. The discriminators are keyed by **skill name + primary role + trigger surface** (the durable form), never by issue number.

The Scrum Master's primary role is **team process / flow facilitation, NOT delivery accountability** — that single discriminator is what keeps it from cross-firing with the two delivery-accountability roles that compose the same `delivery-engine`, and from the ART-tier role that operates one altitude above it.

## 1. The `delivery-engine`-composing cluster — facilitation vs accountability

Three roles compose `delivery-engine`. **Deconfliction is by primary-role + trigger, not by composed target** — the composed target (`delivery-engine`) is shared; the primary role and trigger surface differ. The Scrum Master is the *facilitation* member of the trio; the other two are *accountability* members at different altitudes.

| Cluster role | Primary role (the discriminator) | Altitude | `delivery-engine` modes used | Trigger surface that fires it (NOT the others) | Renders go/no-go? Owns a milestone? |
|---|---|---|---|---|---|
| `pmo-program-manager` | **Program delivery accountability** (multi-workstream → outcomes) | Program (multi-project) | A / D / E / F / G **+ `ppm-agent` synthesis** | "program", "across workstreams", "program go/no-go", "cross-project dependency" | **Yes / Yes** |
| `pmo-project-manager` | **Single-project delivery accountability** | Single project | full 7-mode surface (A–G) against one project | a single named project, "this project's DoR/DoD/sprint/backlog/RAID", "is this project ready to release" | **Yes / Yes** |
| **`pmo-scrum-master` (this skill)** | **Team process / flow facilitation** (NOT accountability) | Single team | **B / C / D / E / G facilitation slice** (Mode F deliberately omitted) | "facilitate the ceremony", "remove this impediment", "team velocity/flow health", "run the retro", "set the sprint goal with the team" | **No / No** |

**The decisive separation (load-bearing):** program-manager and project-manager own **delivery accountability** at different altitudes (program vs single-project); the Scrum Master owns **process facilitation, not accountability** — it does **not render a go/no-go and does not own a milestone**; it facilitates the team's flow. A go/no-go, a release-readiness call, or a program/project delivery-status request **never routes to the Scrum Master**; a "facilitate the retro" / "remove this impediment" request **never routes to** the two accountability roles. This holds all three ADR-019 skill-boundary conjuncts vs each accountability sibling:
- **distinct trigger surface** — facilitation verbs ("facilitate", "remove this impediment", "team flow health") vs accountability/status verbs ("is this ready to release", "go/no-go", "project/program status");
- **distinct write-scope** — ceremony artifacts + the facilitated sprint goal + the impediment log vs project/program delivery trackers, milestone sign-offs, and go/no-go records;
- **distinct primary role** — facilitation vs accountability.

**Why `delivery-engine` Mode F is omitted from the Scrum Master's slice.** Mode F (DoD / Release-Readiness) produces a release-readiness go/no-go verdict — an **accountability** output. Routing F into the Scrum Master would re-introduce the accountability the boundary excludes. The Scrum Master facilitates the team *toward* a DoD (Mode 3 ceremony support), but the **DoD / release-readiness verdict itself** is the project/program-manager's (their Mode F). The omission is the boundary made mechanical: the absence of Mode F in the composition set is the structural tell that this is a facilitation role.

## 2. The sharpest pair — scrum-master vs project-manager (facilitation vs accountability)

Both fire on single-team sprint-board framing, so this is the hardest deconfliction case. The load-bearing tell:

- **scrum-master** fires when the request asks for **process facilitation** — "run the retro", "what's blocking the team", "facilitate planning", "set the sprint goal with the team", "team flow/velocity health". The output is a facilitation artifact (an option set the team chooses, an impediment with an owner, a coaching read).
- **project-manager** fires when the request asks for **a delivery decision or an owned artifact** — "is this sprint going to hit DoD", "plan the project's release", "update the project RAID", "is this project ready to release". The output is an owned accountability decision (a go/no-go, a RAID entry the PM owns, a milestone stewarded).

The role split made concrete: the project-manager *owns* the delivery outcome (renders go/no-go, owns RAID + milestone — uses the full A–G surface including Mode F); the scrum-master *facilitates the team's flow* (impediment removal, ceremony support — uses only the B/C/D/E/G facilitation slice, renders no go/no-go, owns no milestone).

When a single-team sprint request does not clearly resolve to *facilitation* vs *decision/owned-artifact*, ask one disambiguating question before proceeding (SKILL.md `## Mode Selection` Step 3) — never silently default to rendering an accountability decision.

## 3. The team-vs-ART boundary — scrum-master vs release-train-engineer (`pmo-release-train-engineer`)

The Scrum Master is the **Scrum-DEFAULT single-team role**; the Release Train Engineer (RTE) is the **SAFe-conditional ART-tier role**. The boundary depends on the active delivery configuration:

- **Under a non-SAFe config (including the platform default, Scrum):** the RTE is **dormant** and only the Scrum Master is active. A single-team Scrum intent has nowhere else to go — it is the Scrum Master's.
- **Under an active SAFe config:** *both* may be active, and the boundary is explicit by tier and trigger.

| | `pmo-scrum-master` (this skill) | `pmo-release-train-engineer` (SAFe-only) |
|---|---|---|
| Tier | **Single team** | **ART / Program Increment (multi-team)** |
| Activation | **Default-active** (Scrum is the platform default) | **SAFe-conditional** — dormant under non-SAFe `delivery_approach` |
| Trigger surface | single-team sprint vocabulary ("facilitate the sprint", "team velocity", "run the retro", "remove this team's impediment") | PI/ART vocabulary ("facilitate PI planning", "ART risk", "program-increment readiness", "cross-team ART dependency") |
| Write-scope | sprint backlog / team ceremony artifacts | ART backlog / PI objectives / program board |

**The non-cross-fire guarantee under SAFe:** a sprint *inside* an ART is still a Scrum Master concern — the RTE **coordinates across** teams, it does not absorb the single-team ceremony. A single-team-sprint trigger never routes to the RTE; a PI/ART trigger never routes to the Scrum Master. All three ADR-019 conjuncts hold (distinct trigger surface / write-scope / primary role).

**Routing on a multi-team / ART trigger:** name the appropriate role and state the boundary — `pmo-release-train-engineer` under an active SAFe config; `pmo-program-manager` for non-SAFe multi-workstream coordination — rather than collapsing the multi-team scope to a single team's ceremony (see SKILL.md `## Domain-Specific Failure Modes` → "Single-team facilitation applied to a multi-team / ART request — HAND").
