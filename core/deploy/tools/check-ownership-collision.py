#!/usr/bin/env python3
"""Ownership-collision reconciliation primitive (deploy.sh Check 54).

Implements ADR-044 invariants I1 (single maintainer) + I3 (output-contract <->
owning-agent consistency) + I4 (renderings are ownerless) as a build-time
reconciliation. It creates NO new ownership store: it reconciles two EXISTING
corpus surfaces of truth against each other and escalates a would-be *second
maintainer*.

  1. the §6 owning-agent matrix in `core/disciplines/project-entity-model.md`
     — the SSOT for who MAINTAINS each entity (ADR-044 Decision #1);
  2. the per-skill output declarations in `core/schemas/per-skill-output-contracts.md`
     — reconciled against §6 as PRODUCE-default (see below);
  3. the rendering set in `core/specs/operational-artifact-inventory.md`
     — the I4-exempt ownerless read-time projections.

Sibling deploy-primitive, NOT an extension of run_eval_audit.py (ADR-068:
sibling-vs-extend — the trigger-routing Jaccard harness stays independent).
Reads corpus markdown tables; needs no `gh` (pure local parse — no offline SKIP
leg). Cite ADR-044 (design-of-record) + ADR-068 (site choice) + ADR-019
(compose-not-absorb: audit primitives stay independent).

The ESCALATE predicate (R3 — the shippability crux). ESCALATE fires IFF:
  (I1) a §6 `Maintains` cell resolves to >= 2 distinct maintainer skills; OR
  (I3) a skill declares maintainer-write (`Maintains-entity: <E>`) to an entity
       E whose §6 Maintainer exists and is a DIFFERENT skill, and E is not a
       rendering; OR
  (I4) an output classified as a rendering carries a `Maintains-entity:` marker
       (renderings are ownerless by design).
A producer/creator declaration NEVER escalates — "many producers, one
maintainer" is ADR-044's governed pattern (in production for RAID Item /
Decision). Write-class is PRODUCE-default: every declared output is a PRODUCE
(create/emit routed to the maintainer) unless it carries an explicit
`Maintains-entity: <E>` marker. Because the current suite carries ZERO such
markers, the predicate is zero-ESCALATE on the current suite by construction,
with independent live teeth for a future duplicate §6 maintainer (I1) or a
contradictory maintain-marker (I3/I4).

Exit codes (the check-approved-queue-depth.py / check-doc-links.py family):
  0  no collisions — clean (silent-PASS)
  1  >= 1 ownership collision found (a FINDING; deploy.sh warn-mode downgrades
     it to a non-blocking WARN during the shakedown window)
  2  argument / usage error
  3  input failure — a required corpus surface was missing or unparseable
     (fail-loud: a blind read must not green a possibly-colliding model)

Ships warn-mode-initial per core/rules/bypass-mode-readiness.md; deploy.sh
Check 54 downgrades the exit-1 finding to a non-blocking WARN. Flip via an
`ownership-collision.mode` operator-instance file after the >=3-day review.
"""
from __future__ import annotations

import argparse
import re
import sys

# ── Canonical corpus surfaces (repo-relative; overridable for the self-test) ──
ENTITY_MODEL = "core/disciplines/project-entity-model.md"
OUTPUT_CONTRACTS = "core/schemas/per-skill-output-contracts.md"
ARTIFACT_INVENTORY = "core/specs/operational-artifact-inventory.md"

# `(route: file-router)` annotates a ROUTED PRODUCER, never a second maintainer.
_ROUTE_RE = re.compile(r"\(route:[^)]*\)", re.IGNORECASE)
# The canonical skill-name join key present in each output-contract section.
_SKILL_TOKEN_RE = re.compile(r"([a-z0-9][a-z0-9._-]+)/SKILL\.md")
# The one unambiguous maintainer-grade declaration marker (none exist today).
_MAINTAIN_MARKER_RE = re.compile(r"Maintains-entity:\s*([A-Za-z][A-Za-z0-9 /-]+)")
_H2_RE = re.compile(r"^##\s")
_SKILL_HDR_RE = re.compile(r"^##\s+Skill\s+\d+:", re.IGNORECASE)

# Producer-output section-title fragments -> the entity whose record they emit
# (the frozen SECTION_ENTITY_MAP; unmapped sections are not-entity-linked -> skip
# -> no false escalate). Order matters: first match wins.
SECTION_ENTITY_MAP = (
    ("findings & remediation", "Finding"),
    ("findings & gap", "Finding"),
    ("gap analysis", "Finding"),
    ("findings register", "Finding"),
    ("findings", "Finding"),
)
_RAID_PREFIX_RE = re.compile(r"\bR-[A-Z]{2,4}-#*\d*\b")  # R-PPM-###, R-DE-001, …


class InputError(Exception):
    """A required corpus surface was missing or unparseable (-> exit 3)."""


def _read(path):
    try:
        with open(path, "r", encoding="utf-8") as fh:
            return fh.read()
    except OSError as exc:
        raise InputError("cannot read %s: %s" % (path, exc))


def _row_cells(line):
    """A markdown table data row `| a | b | c |` -> ['a','b','c'] (trimmed)."""
    return [c.strip() for c in line.strip().strip("|").split("|")]


def _parse_maintainers(cell):
    """Maintainer skill(s) in a §6 `Maintains` cell. Strips `(route: X)` (a routed
    producer, not a maintainer), then splits on `/` or `,`. Returns the sorted set
    of distinct skills — len >= 2 is the I1 collision signal."""
    cell = _ROUTE_RE.sub("", cell)
    parts = re.split(r"[/,]", cell)
    out = set()
    for p in parts:
        p = p.strip().strip("`*")
        if p and p not in ("—", "-", ""):
            out.add(p)
    return sorted(out)


def _parse_creators(cell):
    """Creator skill(s) in a §6 `Creates` cell — split on `/` (many creators are
    LEGAL). Strips `(route: X)`."""
    cell = _ROUTE_RE.sub("", cell)
    return sorted({p.strip().strip("`*") for p in cell.split("/") if p.strip()})


def parse_owning_matrix(text):
    """§6 Owning-Agent Matrix -> {entity: {'maintainers': [...], 'creators': [...]}}.
    Raises InputError if the §6 table is absent/empty."""
    lines = text.splitlines()
    in_section = False
    rows = {}
    for line in lines:
        if line.startswith("## 6.") and "Owning-Agent Matrix" in line:
            in_section = True
            continue
        if in_section and _H2_RE.match(line) and not line.startswith("## 6."):
            break  # next H2 -> §6 is over
        if not in_section:
            continue
        if not line.lstrip().startswith("|"):
            continue
        cells = _row_cells(line)
        if len(cells) < 4:
            continue
        entity = cells[0].strip("`*")
        if entity in ("", "Entity") or set(entity) <= set("-: "):
            continue  # header or separator row
        rows[entity] = {
            "maintainers": _parse_maintainers(cells[2]),
            "creators": _parse_creators(cells[1]),
        }
    if not rows:
        raise InputError("§6 owning-agent matrix not found or empty in %s" % ENTITY_MODEL)
    return rows


def parse_output_contracts(text):
    """per-skill-output-contracts.md -> (maintain_decls, producer_count).

    maintain_decls: list of (skill, entity) from explicit `Maintains-entity:`
    markers (the only path to a maintainer-grade declaration). producer_count:
    the number of producer output declarations reconciled (findings-class
    sections + RAID R-*-### update streams) — all LEGAL, the metric denominator.
    Raises InputError if no skill section is found."""
    lines = text.splitlines()
    sections = []  # (skill_name_or_None, [lines])
    cur_lines = None
    for line in lines:
        if _SKILL_HDR_RE.match(line):
            if cur_lines is not None:
                sections.append(cur_lines)
            cur_lines = [line]
        elif cur_lines is not None:
            cur_lines.append(line)
    if cur_lines is not None:
        sections.append(cur_lines)
    if not sections:
        raise InputError("no `## Skill N:` sections found in %s" % OUTPUT_CONTRACTS)

    maintain_decls = []
    producer_count = 0
    for sec in sections:
        body = "\n".join(sec)
        tok = _SKILL_TOKEN_RE.search(body)
        skill = tok.group(1) if tok else None
        # (a) explicit maintainer-grade markers (I3/I4 input) — none exist today
        for m in _MAINTAIN_MARKER_RE.finditer(body):
            maintain_decls.append((skill, m.group(1).strip().strip("`")))
        # (b) producer declarations — findings-class section titles + RAID streams
        low = body.lower()
        for frag, _entity in SECTION_ENTITY_MAP:
            producer_count += low.count(frag)
        producer_count += len(set(_RAID_PREFIX_RE.findall(body)))
    return maintain_decls, producer_count


def parse_rendering_set(text):
    """operational-artifact-inventory.md -> set of rendering identifiers (the
    I4-exempt ownerless outputs), read from rows flagged `rendering-ownerless`.
    Missing file/flag is not fatal (the classification may not have landed yet):
    returns an empty set."""
    renderings = set()
    for line in text.splitlines():
        if not line.lstrip().startswith("|"):
            continue
        cells = _row_cells(line)
        # A real §5.4 rendering DATA row: the full 8-column+Notes inventory shape
        # with `RENDERING (ownerless …)` in the source_entity column (cells[2]).
        # This excludes the §2 schema-definition rows that merely mention the token
        # in prose (they carry < 8 cells and/or no source_entity cell).
        if len(cells) >= 8 and "rendering" in cells[2].lower() and cells[0]:
            renderings.add(cells[0].strip("`*").strip())
    return renderings


def reconcile(matrix, maintain_decls, renderings):
    """Apply I1/I3/I4. Returns (collisions, metrics) where collisions is a list of
    human-readable escalation strings and metrics is a dict of TSV counters."""
    collisions = []

    # I1 — a §6 `Maintains` cell resolving to >= 2 distinct maintainer skills.
    for entity, rec in sorted(matrix.items()):
        maints = rec["maintainers"]
        if len(maints) >= 2:
            collisions.append(
                "I1 second-maintainer: entity '%s' has >=2 maintainers in §6 Maintains: %s"
                % (entity, ", ".join(maints))
            )

    # single-maintainer lookup (post-I1): entity -> the one maintainer, if unique
    maintainer_of = {e: r["maintainers"][0] for e, r in matrix.items() if len(r["maintainers"]) == 1}

    for skill, entity in maintain_decls:
        # I4 — a rendering carrying a maintainer-grade marker (ownerless by design)
        if entity in renderings:
            collisions.append(
                "I4 rendering-owned: '%s' declares Maintains-entity on rendering '%s' (renderings are ownerless)"
                % (skill or "<unknown skill>", entity)
            )
            continue
        # I3 — a maintainer-grade declaration that contradicts §6's single maintainer
        owner = maintainer_of.get(entity)
        if owner is not None and skill is not None and skill != owner:
            collisions.append(
                "I3 contract<->matrix: '%s' declares Maintains-entity '%s' but §6 Maintainer is '%s'"
                % (skill, entity, owner)
            )

    metrics = {
        "ENTITIES_CHECKED": len(matrix),
        "MAINTAINER_CELLS": sum(1 for r in matrix.values() if r["maintainers"]),
    }
    return collisions, metrics


def run(entity_model, output_contracts, artifact_inventory):
    """Load + reconcile the three surfaces. Returns (collisions, metrics)."""
    matrix = parse_owning_matrix(_read(entity_model))
    maintain_decls, producer_count = parse_output_contracts(_read(output_contracts))
    try:
        renderings = parse_rendering_set(_read(artifact_inventory))
    except InputError:
        renderings = set()  # inventory optional — I4 simply has no exempt set
    collisions, metrics = reconcile(matrix, maintain_decls, renderings)
    metrics["PRODUCERS_RECONCILED"] = producer_count
    metrics["RENDERINGS_EXEMPT"] = len(renderings)
    return collisions, metrics


def _emit_tsv(collisions, metrics):
    print("COLLISIONS\t%d" % len(collisions))
    print("ENTITIES_CHECKED\t%d" % metrics.get("ENTITIES_CHECKED", 0))
    print("MAINTAINER_CELLS\t%d" % metrics.get("MAINTAINER_CELLS", 0))
    print("PRODUCERS_RECONCILED\t%d" % metrics.get("PRODUCERS_RECONCILED", 0))
    print("RENDERINGS_EXEMPT\t%d" % metrics.get("RENDERINGS_EXEMPT", 0))
    print("FP_ADJUDICATED\t0")
    for c in collisions:
        print("DETAIL\t%s" % c)


def _emit_text(collisions, metrics):
    if not collisions:
        print("ownership-collision: PASS — 0 collisions across %d entities "
              "(%d maintainer cells, %d producer declarations reconciled)"
              % (metrics["ENTITIES_CHECKED"], metrics["MAINTAINER_CELLS"],
                 metrics["PRODUCERS_RECONCILED"]))
        return
    print("ownership-collision: %d collision(s):" % len(collisions))
    for c in collisions:
        print("  - %s" % c)


# ─────────────────────────── offline self-test ───────────────────────────────
_FIX_MATRIX_CLEAN = """\
## 6. Owning-Agent Matrix

| Entity | Creates | Maintains | Primary Readers |
|---|---|---|---|
| Artifact | artifact-generator | ppm-agent (route: file-router) | all PMO skills |
| RAID Item | ppm-agent | tracker-manager | daily-status |
| Finding | build-reviewer / pmo-qa-auditor / pmo-technical-analyst | pmo-qa-lead | ppm-agent |

## 7. Next
"""
_FIX_MATRIX_I1 = _FIX_MATRIX_CLEAN.replace(
    "| Finding | build-reviewer / pmo-qa-auditor / pmo-technical-analyst | pmo-qa-lead | ppm-agent |",
    "| Finding | build-reviewer / pmo-qa-auditor | pmo-qa-lead / build-reviewer | ppm-agent |",
)
_FIX_CONTRACTS_CLEAN = """\
## Skill 1: PPM Agent
### Failure-Mode Conformance (G7)
`ppm-agent/SKILL.md` must contain … Prefix `R-PPM-001`.
### Output Contract
| 4. Findings & Remediations | Observation, evidence | blocks |

## Skill 2: Build Reviewer
`build-reviewer/SKILL.md` findings register.
### Findings Register
one block per finding.
"""
_FIX_CONTRACTS_I3 = _FIX_CONTRACTS_CLEAN + """\

## Skill 3: Rogue
`rogue-skill/SKILL.md`
Maintains-entity: Finding
"""
_FIX_INVENTORY = """\
| decision briefing | generated-artifact | RENDERING (ownerless — ADR-044) | .md | absent | absent | none (ownerless by design) | rendering-ownerless | ADR-044 rendering |
"""


def _self_test():
    ok = True

    def check(name, cond):
        nonlocal ok
        if not cond:
            print("FAIL %s" % name)
            ok = False

    # 1) clean suite -> zero collisions (the current-suite guarantee)
    m = parse_owning_matrix(_FIX_MATRIX_CLEAN)
    decls, prod = parse_output_contracts(_FIX_CONTRACTS_CLEAN)
    rends = parse_rendering_set(_FIX_INVENTORY)
    cols, met = reconcile(m, decls, rends)
    check("clean-zero-collisions", cols == [])
    check("clean-entities-3", met["ENTITIES_CHECKED"] == 3)
    check("clean-maintainer-cells-3", met["MAINTAINER_CELLS"] == 3)
    check("clean-producers-counted", prod >= 2)  # findings-class + R-PPM stream
    check("clean-finding-single-maintainer", m["Finding"]["maintainers"] == ["pmo-qa-lead"])
    check("clean-finding-3-creators", len(m["Finding"]["creators"]) == 3)
    check("clean-route-stripped", m["Artifact"]["maintainers"] == ["ppm-agent"])
    check("rendering-parsed", "decision briefing" in rends)

    # 2) I1 tooth — a second maintainer in a §6 cell escalates
    m1 = parse_owning_matrix(_FIX_MATRIX_I1)
    cols1, _ = reconcile(m1, [], set())
    check("I1-fires", any("I1" in c for c in cols1))
    check("I1-exactly-one", len(cols1) == 1)

    # 3) I3 tooth — a maintain-marker contradicting §6 escalates
    decls3, _ = parse_output_contracts(_FIX_CONTRACTS_I3)
    cols3, _ = reconcile(m, decls3, set())
    check("I3-fires", any("I3" in c for c in cols3))

    # 4) I4 tooth — a maintain-marker on a rendering escalates; and producers-only never do
    cols4, _ = reconcile(m, [("rogue-skill", "decision briefing")], {"decision briefing"})
    check("I4-fires", any("I4" in c for c in cols4))
    cols_prod, _ = reconcile(m, [], rends)  # producers only, no maintain markers
    check("producers-never-escalate", cols_prod == [])

    print("self-test: PASS" if ok else "self-test: FAIL")
    return 0 if ok else 1


def main(argv=None):
    ap = argparse.ArgumentParser(
        description="Ownership-collision reconciliation — ADR-044 I1/I3/I4 (deploy.sh Check 54)"
    )
    ap.add_argument("--entity-model", default=ENTITY_MODEL)
    ap.add_argument("--output-contracts", default=OUTPUT_CONTRACTS)
    ap.add_argument("--artifact-inventory", default=ARTIFACT_INVENTORY)
    ap.add_argument("--output-format", choices=("tsv", "text"), default="tsv")
    ap.add_argument("--self-test", action="store_true",
                    help="run the offline fixture suite; no corpus/network needed")
    args = ap.parse_args(argv)

    if args.self_test:
        return _self_test()

    try:
        collisions, metrics = run(args.entity_model, args.output_contracts, args.artifact_inventory)
    except InputError as exc:
        print("ownership-collision input failure: %s" % exc, file=sys.stderr)
        return 3

    if args.output_format == "tsv":
        _emit_tsv(collisions, metrics)
    else:
        _emit_text(collisions, metrics)
    return 1 if collisions else 0


if __name__ == "__main__":
    sys.exit(main())
