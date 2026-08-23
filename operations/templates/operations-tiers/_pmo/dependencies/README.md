# _pmo/dependencies/ — Cross-Project Dependency view

One page per dependency edge between two projects — where one project's milestone or freeze window constrains another's. Authored from `pmo-platform/operations/templates/dependency-entity-template.md`. `dependency_id` is unique within the portfolio-level tier.

**A view, not a relocation.** These pages carry `storage_tier: portfolio-level` frontmatter: the Cross-Project Dependency entity's authoritative home is `projects/_config/`, and this folder composes a portfolio-level view over it. The frontmatter is what says so — do not read the folder as a second home.

**What lands here:** the edge itself — its two endpoints, its kind, and its state. Endpoints resolve to real records; a dependency whose endpoints do not resolve is malformed, and one whose endpoints are the same record is not a dependency.

**What does not:** a project's internal task dependencies. Those live in the project's own delivery artifacts.

**Authority:** ADR-058 §4; `pmo-platform/core/schemas/entity-field-schemas.md` §3.15 and § Cross-Project Dependency.

_Orientation only. If this card ever disagrees with its cited authority, the authority wins._
