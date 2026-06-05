# packages

Distribution artifacts — `.skill` packages produced from per-module skill directories.

## Purpose

Each `.skill` package is a self-contained archive of one skill's source, references, and frontmatter, suitable for distribution outside the monorepo. Packages here are produced from skills under `operations/skills/`, `release/skills/`, and `core/skills/` — one `.skill` per skill.

## Status

**Empty (intentional)** in the current release. The package-production pipeline emits `.skill` artifacts into this directory at release-cut time, not at every commit. This avoids storing build artifacts in the version-controlled tree between releases.

## Producing a package

The build invocation lives in the release tooling. Operators producing a one-off `.skill` for a single skill use:

```bash
python3 -m scripts.package_skill <skill-source-dir> packages/
```

`<skill-source-dir>` is the absolute or repo-relative path to the skill directory (e.g., `core/skills/prompt-builder`).

### License injection

Every emitted `.skill` carries a top-level `<skill>/LICENSE` — the project's Business Source License 1.1 — injected at build time by `package_skill.py`, byte-identical to the repo-root `/LICENSE`. This satisfies the BSL conspicuous-display requirement on each distributed artifact and is verified in CI by `release/tools/check-skill-licenses.py` (workflow `skill-license-check.yml`). `pmo-skill-refiner` additionally bundles `eval-viewer/LICENSE.txt` (Apache-2.0) plus a root `NOTICE` for its vendored Anthropic eval/optimization harness, path-scoped so the injected root `LICENSE` remains the package's primary license.

## Consuming a package

`.skill` packages here are produced for downstream Claude Code consumers. Installation outside this repo follows the standard Claude Code `.skill` install procedure.

## See also

- [core/README.md § Public API](../core/README.md#public-api) — skill enumeration for the core module.
- [operations/README.md § Public API](../operations/README.md#public-api) — skill enumeration for the operations module.
- [release/README.md § Public API](../release/README.md#public-api) — skill enumeration for the release module.
