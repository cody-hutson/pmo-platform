# core/governance/

**Purpose:** Authoritative, git-tracked program-scoped governance — the single source of truth for PMO protocols, the release lifecycle, and the deployment audit trail.
**Organization:** `OPERATIONS.md` (PMO protocols), `RELEASE_PROTOCOL.md` (release lifecycle), `RELEASE_LOG.md` (version history), `adr/` (architecture decision records). Initiative-roadmap *instances* are authored operator-local (not tracked here) per [ADR-012](../ADRs/ADR-012-roadmap-instance-descope.md); the roadmap *framework* lives at [`initiative-roadmap-framework.md`](../standards/initiative-roadmap-framework.md).
**Governance:** [/CLAUDE.md](<OPERATOR_INSTANCE_CLAUDE_MD>) § Governance File Map (Program-scoped governance) and [release/governance/RELEASE_PROTOCOL.md](../../release/governance/RELEASE_PROTOCOL.md).
**Layer:** 1 (Engineering, git-tracked)

Changes here require the "No ungoverned changes" protocol (GitHub Issue + approved plan + PR). Operational config lives in `projects/_config/` (Layer 2), not here.
