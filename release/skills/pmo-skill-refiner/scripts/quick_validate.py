#!/usr/bin/env python3
"""
Quick validation script for skills - minimal version

Two layers:
  - validate_skill()             — full PMO validator (frontmatter + PMO-extension
                                   allow-list, license, kebab/length conventions).
  - assert_scaffolder_skeleton() — the pre-injection SCAFFOLDER-DRIFT GUARD (#193):
                                   a fail-loud structure assertion run against the
                                   RAW Anthropic skill-creator scaffold output,
                                   BEFORE PMO field injection (Workflow Create-New
                                   step 3 / the PROC "Injection before scaffold
                                   validation" failure mode). It asserts only the
                                   three upstream-REQUIRED invariants drawn from
                                   core/standards/upstream-reference-catalog.md
                                   (skill-md-frontmatter / skill-references-directory /
                                   skill-md-body-anatomy) and HALTs loud on drift.
                                   It composes with — does not duplicate — that
                                   catalog's drift_check_protocol: the catalog is
                                   the assertion contract and the cited authority.
                                   Detection-only (no compat-shim, no version-pin,
                                   per Stage 5 design for #193).
"""

import sys
import os
import re
import yaml
from pathlib import Path

# ---------------------------------------------------------------------------
# Scaffolder-drift guard (#193) — catalog-anchored, fail-loud, detection-only.
#
# The three asserted invariants are the `upstream_required` rows of the three
# skill-creator-sourced entries in core/standards/upstream-reference-catalog.md.
# The catalog is prose-table (not machine-parseable today; a runtime parser is
# YAGNI at ~4 entries — see the catalog's "Future deploy.sh --check Check
# (deferred)" note), so the invariant set is encoded here WITH the catalog entry
# name + upstream citation alongside each, and the diagnostic routes the operator
# back to the catalog so the two never silently diverge (single contract, two
# enforcement points: this runtime guard + the catalog's Stage-13 manual cadence).
# ---------------------------------------------------------------------------

# The catalog file the guard composes with (relative to the repo root). Surfaced
# in every drift diagnostic so a HALT points at the authoritative contract.
CATALOG_PATH = 'core/standards/upstream-reference-catalog.md'

# Per-invariant catalog binding: artifact_class entry + its upstream citation +
# the upstream_required summary, drawn verbatim from upstream-reference-catalog.md.
_CATALOG_ENTRIES = {
    'A1': {
        'artifact_class': 'skill-md-frontmatter',
        'upstream_citation': (
            '~/.claude/plugins/cache/claude-plugins-official/skill-creator/'
            'unknown/skills/skill-creator/SKILL.md:1-4'
        ),
        'upstream_required': 'name, description (present and non-empty)',
    },
    'A2': {
        'artifact_class': 'skill-references-directory',
        'upstream_citation': (
            '~/.claude/plugins/cache/claude-plugins-official/skill-creator/'
            'unknown/skills/skill-creator/SKILL.md  (Anatomy of a Skill)'
        ),
        'upstream_required': 'references/ (plural) when reference files apply',
    },
    'A3': {
        'artifact_class': 'skill-md-body-anatomy',
        'upstream_citation': (
            '~/.claude/plugins/cache/claude-plugins-official/skill-creator/'
            'unknown/skills/skill-creator/SKILL.md  (Anatomy of a Skill)'
        ),
        'upstream_required': 'H1 skill title + body sections per Anthropic skill-creator (Anatomy)',
    },
}

# The greppable fail-loud signal. Any change here must stay in lockstep with the
# Stage 5 design contract and the Stage 7 DT fixtures that assert on it.
DRIFT_SENTINEL = 'SCAFFOLDER DRIFT DETECTED'


def _read_frontmatter(skill_md_path):
    """
    Parse the YAML frontmatter of a SKILL.md.

    Returns (frontmatter_dict_or_None, body_text_or_None, error_or_None).
    On any structural problem returns (None, None, "<reason>").
    """
    if not skill_md_path.exists():
        return None, None, "SKILL.md not found"

    content = skill_md_path.read_text()
    if not content.startswith('---'):
        return None, None, "No YAML frontmatter found"

    match = re.match(r'^---\n(.*?)\n---(.*)$', content, re.DOTALL)
    if not match:
        return None, None, "Invalid frontmatter format"

    frontmatter_text = match.group(1)
    body_text = match.group(2)

    try:
        frontmatter = yaml.safe_load(frontmatter_text)
    except yaml.YAMLError as e:
        return None, None, f"Invalid YAML in frontmatter: {e}"

    if not isinstance(frontmatter, dict):
        return None, None, "Frontmatter must be a YAML dictionary"

    return frontmatter, body_text, None


def assert_scaffolder_skeleton(skill_path):
    """
    SCAFFOLDER-DRIFT GUARD (#193) — fail-loud, detection-only.

    Run this against the RAW Anthropic skill-creator scaffold output, BEFORE PMO
    field injection. It asserts the three upstream-REQUIRED invariants from
    core/standards/upstream-reference-catalog.md and returns EVERY failing
    invariant at once (not first-fail) so a drifted scaffold surfaces all of its
    divergences in a single HALT.

    Asserts (upstream-required set ONLY — never PMO extensions, which are injected
    downstream and would false-positive against a raw scaffold):
      A1 skill-md-frontmatter      : SKILL.md present; frontmatter parses;
                                     `name` and `description` present & non-empty.
      A2 skill-references-directory: reject a SINGULAR `reference/` directory at
                                     skill root (the documented plural canonical).
                                     Absence of `references/` is NOT a failure —
                                     reference docs are upstream-optional; the
                                     assertion is singular-form rejection, not
                                     presence-required.
      A3 skill-md-body-anatomy     : post-frontmatter body contains >=1 top-level
                                     `#` H1 heading (the skill title).

    Deliberately NOT asserted (scope discipline — asserting these would re-incur
    the over-engineering the Stage 5 design rejects): exact section names/order
    (upstream marks "section ordering varies"); scripts/ or assets/ presence
    (optional bundled resources); the description *wording* (drifts benignly).
    The guard asserts INVARIANTS, not SNAPSHOTS.

    Returns:
        (ok: bool, failures: list[dict]) where each failure dict carries:
          'invariant'        — 'A1' | 'A2' | 'A3'
          'artifact_class'   — the violated upstream-reference-catalog entry
          'upstream_citation'— the upstream authority pin for that entry
          'upstream_required'— the catalog's required-summary for that entry
          'expected'         — what the guard expected
          'actual'           — what it observed
        ok is True iff failures == [].
    """
    skill_path = Path(skill_path)
    skill_md = skill_path / 'SKILL.md'
    failures = []

    frontmatter, body_text, fm_error = _read_frontmatter(skill_md)

    # --- A1: frontmatter name + description present & non-empty ---------------
    if fm_error is not None:
        failures.append(_failure(
            'A1',
            expected="parseable YAML frontmatter with non-empty 'name' and 'description'",
            actual=fm_error,
        ))
    else:
        name = frontmatter.get('name', None)
        if not (isinstance(name, str) and name.strip()):
            failures.append(_failure(
                'A1',
                expected="frontmatter 'name' present and non-empty",
                actual=(
                    "'name' missing" if name is None
                    else f"'name' present but empty/blank ({name!r})"
                ),
            ))
        description = frontmatter.get('description', None)
        if not (isinstance(description, str) and description.strip()):
            failures.append(_failure(
                'A1',
                expected="frontmatter 'description' present and non-empty",
                actual=(
                    "'description' missing" if description is None
                    else f"'description' present but empty/blank ({description!r})"
                ),
            ))

    # --- A2: references/ plural convention (reject singular reference/) --------
    # Absence of references/ is fine (upstream-optional). A sibling SINGULAR
    # `reference/` directory at skill root is the drift signal.
    singular_dir = skill_path / 'reference'
    if singular_dir.is_dir():
        failures.append(_failure(
            'A2',
            expected="reference docs (if any) under 'references/' (plural) directory",
            actual=f"singular 'reference/' directory present at skill root ({singular_dir})",
        ))

    # --- A3: body anatomy — >=1 top-level '#' H1 heading ----------------------
    # Only meaningful when the frontmatter parsed (otherwise A1 already HALTs and
    # body_text may be None). A top-level H1 is a single '#' followed by a space,
    # at the start of a line, NOT '##'+.
    if fm_error is None:
        has_h1 = bool(re.search(r'^#[ \t]+\S', body_text or '', re.MULTILINE))
        if not has_h1:
            failures.append(_failure(
                'A3',
                expected="at least one top-level '#' H1 heading in the SKILL.md body",
                actual="no top-level '#' H1 heading found in body",
            ))

    return (len(failures) == 0), failures


def _failure(invariant, expected, actual):
    """Build a structured failure record bound to its catalog entry."""
    entry = _CATALOG_ENTRIES[invariant]
    return {
        'invariant': invariant,
        'artifact_class': entry['artifact_class'],
        'upstream_citation': entry['upstream_citation'],
        'upstream_required': entry['upstream_required'],
        'expected': expected,
        'actual': actual,
    }


def format_drift_diagnostic(failures):
    """
    Render the fail-loud SCAFFOLDER DRIFT DETECTED diagnostic.

    Contract (Stage 5 design): (1) the literal sentinel string; (2) per-invariant
    expected-vs-actual; (3) the catalog file path + the violated artifact_class
    entry + its upstream_citation; (4) explicit "injection NOT performed"; (5) the
    adapt-vs-bump fork pointing at the last_verified bump path. No emojis.
    """
    lines = []
    lines.append(f"{DRIFT_SENTINEL} — pmo-skill-refiner pre-injection guard HALTED.")
    lines.append(
        "The anthropic-skills:skill-creator scaffold output does not match the expected"
    )
    lines.append(
        "skeleton. PMO injection (Workflow step 4) was NOT performed (refusing to inject"
    )
    lines.append("into a non-conforming base).")
    lines.append("")
    lines.append("Failed invariant(s):")
    for f in failures:
        lines.append(
            f"  [{f['invariant']} {f['artifact_class']}] expected: {f['expected']}"
        )
        lines.append(
            f"  {' ' * (len(f['invariant']) + len(f['artifact_class']) + 3)}actual:   {f['actual']}"
        )
        lines.append(
            f"  {' ' * (len(f['invariant']) + len(f['artifact_class']) + 3)}"
            f"catalog:  {CATALOG_PATH} (entry: {f['artifact_class']})"
        )
        lines.append(
            f"  {' ' * (len(f['invariant']) + len(f['artifact_class']) + 3)}"
            f"upstream: {f['upstream_citation']}"
        )
        lines.append(
            f"  {' ' * (len(f['invariant']) + len(f['artifact_class']) + 3)}"
            f"required: {f['upstream_required']}"
        )
    lines.append("")
    lines.append(f"Catalog contract: {CATALOG_PATH}")
    lines.append(
        "This is either (a) a genuine upstream scaffolder change -> re-verify the upstream"
    )
    lines.append(
        "SKILL.md at the citation above, update the affected catalog entry + last_verified,"
    )
    lines.append(
        "and decide adapt-vs-halt; or (b) a malformed scaffold run -> re-run the scaffolder."
    )
    lines.append(
        "Do NOT hand-edit the scaffold to pass this guard without recording why."
    )
    return "\n".join(lines)


def validate_skill(skill_path):
    """Basic validation of a skill"""
    skill_path = Path(skill_path)

    # Check SKILL.md exists
    skill_md = skill_path / 'SKILL.md'
    if not skill_md.exists():
        return False, "SKILL.md not found"

    # ---- Scaffolder-drift guard (#193): FAIL LOUD before any other check -----
    # Run the pre-injection skeleton assertion FIRST so an upstream scaffolder
    # drift surfaces the SCAFFOLDER DRIFT DETECTED sentinel ahead of the generic
    # PMO-extension field errors below (license / allowed-keys). This is the
    # runtime teeth on the upstream-reference-catalog drift_check_protocol — the
    # validator's own invocation path now HALTs loud on scaffolder drift rather
    # than silently degrading or masking it behind a "Missing 'license'" message.
    # The guard asserts ONLY the three upstream-required invariants (it does not
    # impose the PMO-extension requirements, which are injected downstream).
    skeleton_ok, skeleton_failures = assert_scaffolder_skeleton(skill_path)
    if not skeleton_ok:
        return False, format_drift_diagnostic(skeleton_failures)

    # Read and validate frontmatter
    content = skill_md.read_text()
    if not content.startswith('---'):
        return False, "No YAML frontmatter found"

    # Extract frontmatter
    match = re.match(r'^---\n(.*?)\n---', content, re.DOTALL)
    if not match:
        return False, "Invalid frontmatter format"

    frontmatter_text = match.group(1)

    # Parse YAML frontmatter
    try:
        frontmatter = yaml.safe_load(frontmatter_text)
        if not isinstance(frontmatter, dict):
            return False, "Frontmatter must be a YAML dictionary"
    except yaml.YAMLError as e:
        return False, f"Invalid YAML in frontmatter: {e}"

    # Define allowed properties
    # Upstream Anthropic schema: name, description, license, allowed-tools, metadata, compatibility
    # PMO platform extensions: version (skill version), delivery_approach + principal_standard_pass
    # (PMO Principal Standard injection points per pmo-skill-refiner design)
    # skill-discipline extension: skill_discipline_migrated_v10_2 (gate-activation marker
    # per canonical-skill-structure.md §3)
    ALLOWED_PROPERTIES = {
        'name', 'description', 'license', 'allowed-tools', 'metadata', 'compatibility',
        'version', 'delivery_approach', 'principal_standard_pass',
        'skill_discipline_migrated_v10_2',
    }

    # Check for unexpected properties (excluding nested keys under metadata)
    unexpected_keys = set(frontmatter.keys()) - ALLOWED_PROPERTIES
    if unexpected_keys:
        return False, (
            f"Unexpected key(s) in SKILL.md frontmatter: {', '.join(sorted(unexpected_keys))}. "
            f"Allowed properties are: {', '.join(sorted(ALLOWED_PROPERTIES))}"
        )

    # Check required fields
    if 'name' not in frontmatter:
        return False, "Missing 'name' in frontmatter"
    if 'description' not in frontmatter:
        return False, "Missing 'description' in frontmatter"
    # `license` is REQUIRED: every packaged skill must declare its
    # license so the BSL injection / canary enforcement stays green.
    if 'license' not in frontmatter:
        return False, "Missing 'license' in frontmatter"

    # Extract name for validation
    name = frontmatter.get('name', '')
    if not isinstance(name, str):
        return False, f"Name must be a string, got {type(name).__name__}"
    name = name.strip()
    if name:
        # Check naming convention (kebab-case: lowercase with hyphens)
        if not re.match(r'^[a-z0-9-]+$', name):
            return False, f"Name '{name}' should be kebab-case (lowercase letters, digits, and hyphens only)"
        if name.startswith('-') or name.endswith('-') or '--' in name:
            return False, f"Name '{name}' cannot start/end with hyphen or contain consecutive hyphens"
        # Check name length (max 64 characters per spec)
        if len(name) > 64:
            return False, f"Name is too long ({len(name)} characters). Maximum is 64 characters."

    # Extract and validate description
    description = frontmatter.get('description', '')
    if not isinstance(description, str):
        return False, f"Description must be a string, got {type(description).__name__}"
    description = description.strip()
    if description:
        # Check for angle brackets
        if '<' in description or '>' in description:
            return False, "Description cannot contain angle brackets (< or >)"
        # Check description length (max 1024 characters per spec)
        if len(description) > 1024:
            return False, f"Description is too long ({len(description)} characters). Maximum is 1024 characters."

    # Validate compatibility field if present (optional)
    compatibility = frontmatter.get('compatibility', '')
    if compatibility:
        if not isinstance(compatibility, str):
            return False, f"Compatibility must be a string, got {type(compatibility).__name__}"
        if len(compatibility) > 500:
            return False, f"Compatibility is too long ({len(compatibility)} characters). Maximum is 500 characters."

    return True, "Skill is valid!"

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python quick_validate.py <skill_directory>")
        sys.exit(1)

    valid, message = validate_skill(sys.argv[1])
    print(message)
    sys.exit(0 if valid else 1)
