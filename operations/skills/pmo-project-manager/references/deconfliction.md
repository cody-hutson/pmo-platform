<!-- reference-durability: allow-link -->
# Project Manager — Deconfliction Reference

This reference is the lookup surface the **Project Manager Specialist** (`pmo-project-manager`) consults when deciding whether a request belongs to it or to an adjacent role. The SKILL.md `## Mode Selection` Step 2 and `## Dependency Graph Node` cite this file. The discriminators are keyed by **skill name + primary role + trigger surface** (the durable form), never by issue number.

## 1. The three delivery altitudes

The Project Manager owns **one** named project's delivery. The two roles above it operate at higher altitudes and compose different function-skills — the **composition set** is the decisive structural tell, and the **trigger surface** is the operative discriminator.

| Role | Tier / scope | Primary role | Composes | Distinguishing trigger surface |
|---|---|---|---|---|
| `pmo-portfolio-manager` | **Portfolio** — cross-program health / rollup | Portfolio steward | `ppm-agent` + `weekly-status-rollup` | "portfolio health", "SteerCo rollup", "across all programs/projects" — *aggregates programs*; owns no single project's delivery |
| `pmo-program-manager` | **Program** — multiple coordinated workstreams to outcomes | Program delivery driver | `ppm-agent` + `delivery-engine` | "program-level risk to delivery", "across these workstreams", "program go/no-go" — *drives one program's multi-workstream delivery*; cross-project synthesis is its core |
| **`pmo-project-manager` (this skill)** | **Single project** — one project end-to-end | **Single-project delivery owner** | **`delivery-engine` only** | "this project's backlog/sprint/DoR/DoD/RAID", a single named project, "is *this project* ready to release" — *owns one project's delivery*; **no** cross-workstream synthesis |

**No cross-fire with `pmo-program-manager` (above):** the decisive structural tell is the composition set — `pmo-program-manager` composes `ppm-agent` + `delivery-engine` (the `ppm-agent` half is the cross-project synthesis engine); this skill composes `delivery-engine` only and has *no* cross-project capability. Single-named-project framing ("this project's sprint", "is Project Atlas ready to release") → this skill; multi-workstream / program framing ("across these workstreams", "the program's release", "program go/no-go") → `pmo-program-manager`. This skill must not bleed cross-project content into its output (it has no `ppm-agent` to source it from — any cross-project claim would be invention) and must not absorb a genuinely program-scoped request (it routes up rather than collapsing the program to its one project).

**No cross-fire with `pmo-portfolio-manager` (above-above):** a request to *aggregate multiple projects/programs* into a portfolio view routes to `pmo-portfolio-manager`; a single project's delivery posture routes here. The `weekly-status-rollup` composition vs the `delivery-engine` composition is the structural tell.

## 2. The `delivery-engine`-composing cluster

Three roles compose `delivery-engine`. **Deconfliction is by primary-role + trigger, not by composed target** — the composed target (`delivery-engine`) is shared; the primary role and trigger surface differ.

| Cluster role | Primary role (the discriminator) | `delivery-engine` modes used | Trigger surface that fires it (NOT the others) |
|---|---|---|---|
| `pmo-program-manager` | **Program delivery accountability** (multi-workstream → outcomes) | A / D / E / F / G **+ `ppm-agent` synthesis** | "program", "across workstreams", "program go/no-go", "cross-project dependency" |
| **`pmo-project-manager` (this skill)** | **Single-project delivery accountability** | full 7-mode surface (A–G) against **one** project | a single named project, "this project's DoR/DoD/sprint/backlog/RAID", "is this project ready to release" |
| `pmo-scrum-master` | **Team process / flow facilitation** (NOT delivery accountability) | Sprint / Exec / Insight facilitation slice (B / D / E) | "facilitate the ceremony", "remove this impediment", "team velocity/flow health", "sprint retro" |

The decisive separations:

- **project-manager vs program-manager** — same *delivery-accountability* primary role, different **altitude** (single-project vs multi-workstream) AND different **composition set** (`delivery-engine` only vs `+ ppm-agent`). A program go/no-go never routes to project-manager; a single-project DoR check never routes to program-manager.
- **project-manager vs scrum-master** — both touch a single team's sprint, but **accountability vs facilitation** is the primary-role split: project-manager *owns* the delivery outcome (renders go/no-go, owns RAID + milestone — uses the full A–G surface); scrum-master *facilitates the team's flow* (impediment removal, ceremony support — uses only the B/D/E facilitation slice, renders no go/no-go, owns no milestone). A go/no-go or DoD-readiness request never routes to scrum-master; a "facilitate the retro / remove this impediment" request never routes to project-manager.

## 3. The sharpest pair — project-manager vs scrum-master

Both fire on sprint-board framing, so this is the hardest deconfliction case. The load-bearing tell:

- **project-manager** fires when the request asks for **a delivery decision or an owned artifact** — "is this sprint going to hit DoD", "plan the project's release", "update the project RAID", "is this project ready to release".
- **scrum-master** fires when the request asks for **process facilitation** — "run the retro", "what's blocking the team", "facilitate planning", "team flow health".

When a single-team sprint request does not clearly resolve to *decision/owned-artifact* vs *facilitation*, ask one disambiguating question before proceeding (SKILL.md `## Mode Selection` Step 3) — never silently default.
