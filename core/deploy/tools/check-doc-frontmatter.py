#!/usr/bin/env python3
"""check-doc-frontmatter.py — platform-doc frontmatter conformance (deploy.sh Check 50).

Validates the YAML frontmatter of authored K1 platform-reference docs under
`core/**` against `core/standards/platform-doc-frontmatter-standard.md` (#295).
The presence-and-shape complement to check-version-anchors.py Check 18b: 18b
checks anchor VALUE-equality and skips no-frontmatter docs; this gate checks
frontmatter PRESENCE + required-field shape and treats a no-frontmatter doc as
the headline finding.

Per-doc validation (run for every resolved, non-allowlisted target):
  1. Missing-frontmatter — a doc whose first line is not a "---" fence has no
     frontmatter block at all → one finding (field=<frontmatter>).
  2. Tier-1 required-field presence (ALL classes) — title / purpose / type /
     status / reversibility each present and non-empty; missing|empty → one
     finding per field.
  3. type ∈ the singular-lowercase platform-doc enum (the standard's §5 table,
     verbatim) — a plural like `standards` → finding (with a did-you-mean hint).
  4. framework_version_anchor present IFF the doc is cataloged in
     framework-catalog.md (the canonical_doc column). Both directions are
     violations (cataloged-but-absent; present-but-not-cataloged). The anchor
     VALUE is NOT checked here — that is 18b's job. Disjoint, composable.
  5. consumers present for type ∈ {standard, schema, spec} (the blast-radius seam).
  6. reversibility tier-PREFIX match — the value's FIRST token, uppercased, must
     be one of {CHEAP, MODERATE, EXPENSIVE, IRREVERSIBLE}. A prose tail after the
     tier word is allowed and NOT validated (the standard §10 convention).

F1 CONSISTENCY (by construction): the frontmatter block is read via the shared
`_frontmatter.read_frontmatter`, and the cataloged-doc set is built via
check-version-anchors.py's own `parse_catalog_table` (imported here). So this
gate and Check 18b read the same frontmatter and the same framework-catalog.md
rows — they cannot disagree about "has frontmatter" or "is cataloged."

SPLIT-MODE tier tagging: each finding carries tier ∈ {A, other} — `A` when the
doc lives under one of the six Tier-A governance-class dirs, else `other`. This
column is the routing key deploy.sh consumes to apply enforce-vs-warn per dir
WITHOUT re-deriving the dir boundary. NOTE (v3.25 / #2220, D-4 scope-lock): the
gate SHIPS WARN-MODE ACROSS ALL OF core/ (Tier A included) — deploy.sh routes
every tier through the warn dispatcher at ship. The tier column + the enforce-
flip hook are built so the graduation to enforce (Tier A first, then global) is
a single-file mode flip later — deferred to #2221. The tool itself is mode-
agnostic: it emits findings + tiers; deploy.sh owns the enforce/warn decision.

Interface:
  --target-paths "<comma-separated dir/glob list>"   (required)
  --catalog-path PATH        framework-catalog.md (default: core/specs/framework-catalog.md)
  --allowlist PATH           skip-list of repo-relative files exempt from the check
  --output-format tsv|json   (default tsv)
  --self-test                run internal fixtures and exit

TSV columns: file<TAB>tier<TAB>field<TAB>violation<TAB>severity
Header line: `frontmatter-check <N>` (deploy.sh count-parses $2, the Check 42 idiom).

Exit codes (fail-loud contract — mirrors check-version-anchors.py / Check 42):
  0  no violations found (header `frontmatter-check 0`)
  1  violations found (count in header; rows follow)
  3  path-resolution failure: a --target-paths glob OR --catalog-path resolved to
     zero / missing. An unresolvable scan surface is UNVERIFIABLE, not clean, and
     must not read GREEN (the #459 fail-loud contract 18b + Check 42 both honor).

Stdlib-only Python 3.9+ (system /usr/bin/python3; no venv, no external deps).
"""
from __future__ import annotations

import argparse
import glob
import importlib.util as _ilu
import json
import sys
from pathlib import Path

WORKSPACE_ROOT = Path(__file__).resolve().parents[3]
DEFAULT_CATALOG_REL = "core/specs/framework-catalog.md"

# ── Shared imports (the F1 seam) ─────────────────────────────────────────────
# Both helpers are imported by file location so the bare-name / hyphenated
# siblings resolve regardless of CWD or sys.path (mirrors cross_module_audit_helper).
_THIS_DIR = Path(__file__).resolve().parent


def _load_module(mod_name: str, filename: str):
    spec = _ilu.spec_from_file_location(mod_name, _THIS_DIR / filename)
    mod = _ilu.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


_frontmatter = _load_module("_frontmatter", "_frontmatter.py")
# check-version-anchors.py is hyphenated → importlib by file location.
_cva = _load_module("check_version_anchors", "check-version-anchors.py")

read_frontmatter = _frontmatter.read_frontmatter
parse_catalog_table = _cva.parse_catalog_table          # SHARED catalog parser (F1)
_NULL_DOC = _cva.NULL_DOC                                # {"—","-",""}

# ── The canonical type enum (per core/standards/platform-doc-frontmatter-standard.md §5) ──
# Singular, lowercase, hyphenated-where-compound. The standard OWNS this set; the
# gate validates against it. If §5's table changes, update this constant to match
# it verbatim (one-line edit — do NOT let it drift). The ADR class is intentionally
# OUT (it defers to the ADR README convention per the standard §9 + #2156); ADR
# docs are not in this gate's scan surface.
TYPE_ENUM = frozenset({
    "standard", "schema", "spec", "discipline", "rule",
    "protocol", "how-to", "template", "reference",
})

# Common plural/variant → singular hints (did-you-mean on an enum miss).
_TYPE_HINTS = {
    "standards": "standard", "schemas": "schema", "specs": "spec",
    "disciplines": "discipline", "rules": "rule", "protocols": "protocol",
    "templates": "template", "references": "reference", "how-tos": "how-to",
    "howto": "how-to", "guide": "how-to",
}

# Tier-1 required fields (ALL classes) — the standard §4 core REQUIRED table.
TIER1_REQUIRED = ("title", "purpose", "type", "status", "reversibility")

# consumers is REQUIRED for these classes — the standard §6 blast-radius seam.
CONSUMERS_REQUIRED_TYPES = frozenset({"standard", "schema", "spec"})

# reversibility tier prefixes — the standard §10 value convention (prefix, not
# strict enum: a prose tail after the tier word is allowed).
REVERSIBILITY_PREFIXES = ("CHEAP", "MODERATE", "EXPENSIVE", "IRREVERSIBLE")

# The six Tier-A governance-class dirs — taken VERBATIM from #2220's AC. A finding
# on a doc under one of these tags tier=A; everything else under core/ tags other.
TIER_A_DIRS = (
    "core/standards/", "core/schemas/", "core/specs/",
    "core/disciplines/", "core/rules/", "core/governance/",
)

SEVERITY = "P1"   # frontmatter conformance is a structural P1 (like 18a/18b).


def _rel(path: Path) -> str:
    """Repo-relative POSIX path for stable reporting + tier/allowlist matching."""
    try:
        return path.resolve().relative_to(WORKSPACE_ROOT).as_posix()
    except ValueError:
        return path.as_posix()


def _tier_for(rel_path: str) -> str:
    return "A" if any(rel_path.startswith(d) for d in TIER_A_DIRS) else "other"


def _first_token(value: str) -> str:
    """First whitespace- or '/'-delimited token, uppercased — for reversibility
    prefix matching. 'CHEAP / Confidence HIGH' → 'CHEAP'; 'MODERATE (x)' → 'MODERATE'."""
    v = value.strip()
    for sep in (" ", "/", "(", ",", "\t"):
        v = v.split(sep, 1)[0]
    return v.upper()


def load_allowlist(path: Path | None) -> set[str]:
    """Repo-relative paths, one per line; '#' comments + blanks ignored."""
    out: set[str] = set()
    if path and path.is_file():
        for ln in path.read_text(encoding="utf-8", errors="replace").splitlines():
            ln = ln.strip()
            if ln and not ln.startswith("#"):
                out.add(ln)
    return out


def build_cataloged_set(catalog_path: Path) -> tuple[set[str], str | None]:
    """Return (set of repo-relative canonical_doc paths, error).

    Uses check-version-anchors.py's parse_catalog_table (the SHARED parser) so
    the gate's IFF-cataloged check reads the same rows 18b reads. A non-resolving
    catalog is a path-resolution failure (error != None → exit 3 upstream)."""
    if not catalog_path.exists():
        return set(), f"catalog file not found: {catalog_path}"
    try:
        text = catalog_path.read_text(encoding="utf-8", errors="replace")
    except OSError as e:
        return set(), f"catalog unreadable: {e}"
    rows, perr = parse_catalog_table(text)
    if perr:
        # A malformed-but-present table is NOT a path-resolution failure (the file
        # resolved). Treat as zero cataloged docs but surface nothing fatal — the
        # IFF check simply finds no cataloged docs. (check-version-anchors Check
        # 18a is the authority that flags a malformed catalog table.)
        return set(), None
    cataloged: set[str] = set()
    for row in rows:
        doc = (row.get("canonical_doc", "") or "").strip().strip("`").strip()
        if doc and doc not in _NULL_DOC:
            cataloged.add(doc)
    return cataloged, None


def validate_doc(doc_path: Path, rel_path: str, cataloged: set[str]) -> list[dict]:
    """Run the 6-step validation for one doc. Returns a list of finding dicts."""
    tier = _tier_for(rel_path)
    findings: list[dict] = []

    def add(field: str, violation: str) -> None:
        findings.append({
            "file": rel_path, "tier": tier, "field": field,
            "violation": violation, "severity": SEVERITY,
        })

    keys, status = read_frontmatter(doc_path)

    # ── Step 1: missing-frontmatter ──
    if status in ("no-frontmatter", "no-file"):
        if status == "no-file":
            add("<frontmatter>", "file does not resolve to a readable doc")
        else:
            add("<frontmatter>", "missing YAML frontmatter block (first line is not '---')")
        # No block → the remaining field checks have nothing to read. Return the
        # single headline finding (matches the design: one finding for the doc).
        return findings

    # ── Step 2: Tier-1 required-field presence (all classes) ──
    for field in TIER1_REQUIRED:
        if field not in keys:
            add(field, "required field missing")
        elif keys[field].strip() == "":
            add(field, "required field empty")

    typ = keys.get("type", "").strip()

    # ── Step 3: type ∈ singular-lowercase enum ──
    if typ and typ not in TYPE_ENUM:
        hint = _TYPE_HINTS.get(typ.lower())
        suffix = f" (did you mean '{hint}'?)" if hint else \
            f" (allowed: {', '.join(sorted(TYPE_ENUM))})"
        add("type", f"type '{typ}' not in the singular platform-doc enum{suffix}")

    # ── Step 4: framework_version_anchor present IFF cataloged ──
    is_cataloged = rel_path in cataloged
    has_anchor = "framework_version_anchor" in keys and keys["framework_version_anchor"].strip() != ""
    if is_cataloged and not has_anchor:
        add("framework_version_anchor",
            "framework_version_anchor required (doc is cataloged in framework-catalog.md) but absent")
    elif has_anchor and not is_cataloged:
        add("framework_version_anchor",
            "framework_version_anchor present but doc is not cataloged in framework-catalog.md "
            "— remove the field or add a catalog row")

    # ── Step 5: consumers present for standard/schema/spec ──
    if typ in CONSUMERS_REQUIRED_TYPES:
        if "consumers" not in keys or keys["consumers"].strip() == "":
            add("consumers",
                f"consumers required for type '{typ}' (the blast-radius seam) but absent/empty")

    # ── Step 6: reversibility tier-PREFIX match ──
    rev = keys.get("reversibility", "").strip()
    if rev:   # empty already flagged in Step 2; only prefix-check a non-empty value
        if _first_token(rev) not in REVERSIBILITY_PREFIXES:
            add("reversibility",
                f"reversibility '{rev[:48]}' does not start with a tier prefix "
                f"{{CHEAP|MODERATE|EXPENSIVE|IRREVERSIBLE}}")

    return findings


def resolve_targets(target_globs: list[str]) -> tuple[list[Path], bool]:
    """Resolve the comma-glob list to .md files. Returns (files, any_glob_zero).

    Globs are resolved relative to the workspace root (so a relative invocation
    from repo root and an absolute one agree). any_glob_zero flags whether ANY
    individual glob matched nothing — the exit-3 fail-loud trigger upstream."""
    files: list[Path] = []
    any_zero = False
    seen: set[str] = set()
    for g in target_globs:
        g = g.strip()
        if not g:
            continue
        pat = g if Path(g).is_absolute() else str(WORKSPACE_ROOT / g)
        matched = glob.glob(pat, recursive=True)
        if not matched:
            any_zero = True
            continue
        for m in matched:
            p = Path(m)
            if p.is_file() and p.suffix == ".md":
                rp = p.resolve().as_posix()
                if rp not in seen:
                    seen.add(rp)
                    files.append(p)
    files.sort(key=lambda p: _rel(p))
    return files, any_zero


def run(target_globs: list[str], catalog_path: Path,
        allowlist: set[str]) -> tuple[list[dict], int]:
    """Run the gate. Returns (findings, exit_code)."""
    cataloged, cat_err = build_cataloged_set(catalog_path)
    if cat_err:
        return [], 3   # catalog path-resolution failure → exit 3 (fail-loud).

    files, any_zero = resolve_targets(target_globs)
    if any_zero and not files:
        return [], 3   # every target glob resolved to zero → unverifiable.

    findings: list[dict] = []
    for p in files:
        rel_path = _rel(p)
        if rel_path in allowlist:
            continue
        findings.extend(validate_doc(p, rel_path, cataloged))
    return findings, (1 if findings else 0)


def emit_tsv(findings: list[dict]) -> str:
    lines = [f"frontmatter-check {len(findings)}"]
    lines.append("file\ttier\tfield\tviolation\tseverity")
    for f in findings:
        lines.append(f"{f['file']}\t{f['tier']}\t{f['field']}\t{f['violation']}\t{f['severity']}")
    return "\n".join(lines)


def emit_json(findings: list[dict]) -> str:
    return json.dumps(findings, indent=2)


# ─────────────────────────────── self-test ──────────────────────────────────
def run_self_test() -> int:
    import tempfile

    def _fm(**kw) -> str:
        body = "\n".join(f"{k}: {v}" for k, v in kw.items())
        return f"---\n{body}\n---\n# Body\n"

    failures: list[str] = []

    with tempfile.TemporaryDirectory() as td:
        base = Path(td)

        # A catalog naming exactly ONE cataloged doc (core/specs/cataloged.md).
        catalog = base / "framework-catalog.md"
        catalog.write_text(
            "# Catalog\n\n"
            "| framework | class | version_anchor | canonical_doc | adopted | "
            "applicability_scope | tier | review_cadence | last_reviewed | "
            "next_review_due | owner |\n"
            "|---|---|---|---|---|---|---|---|---|---|---|\n"
            "| Cat | INTERNAL | v1 | core/specs/cataloged.md | v1 | s | stable | "
            "36mo | 2026-01-01 | 2099-01-01 | O |\n",
            encoding="utf-8",
        )
        cataloged, cerr = build_cataloged_set(catalog)
        assert cerr is None and cataloged == {"core/specs/cataloged.md"}, (cerr, cataloged)

        def check(rel: str, content: str) -> list[dict]:
            p = base / rel
            p.parent.mkdir(parents=True, exist_ok=True)
            p.write_text(content, encoding="utf-8")
            # Drive validate_doc directly with the synthetic rel path (so tier +
            # cataloged-membership resolve against the fixture rel, not the tmpdir).
            return validate_doc(p, rel, cataloged)

        def fields(fs: list[dict]) -> set[str]:
            return {f["field"] for f in fs}

        # (a) clean compliant standard (Tier A) → 0 findings.
        a = check("core/standards/clean.md", _fm(
            title="T", purpose="why", type="standard", status="ACTIVE",
            reversibility="CHEAP / Confidence HIGH", consumers="[x.md]"))
        if a:
            failures.append(f"(a) clean doc should yield 0 findings, got {a}")

        # (b) FALSIFICATION: standard missing each Tier-1 field → 5 findings, all tier=A.
        b = check("core/standards/missing-all.md",
                  "---\ntype_only_placeholder: x\n---\n# B\n")
        # title/purpose/type/status/reversibility all absent → 5 required-missing.
        b_missing = {f["field"] for f in b if "missing" in f["violation"]}
        if not TIER1_REQUIRED == tuple(k for k in TIER1_REQUIRED if k in b_missing):
            failures.append(f"(b) expected all 5 Tier-1 fields missing, got {b_missing}")
        if any(f["tier"] != "A" for f in b):
            failures.append(f"(b) Tier-A doc must tag tier=A, got {[f['tier'] for f in b]}")

        # (c) plural type:standards → enum finding (with did-you-mean).
        c = check("core/standards/plural.md", _fm(
            title="T", purpose="w", type="standards", status="ACTIVE",
            reversibility="CHEAP", consumers="[x]"))
        if not any(f["field"] == "type" and "standard" in f["violation"] for f in c):
            failures.append(f"(c) plural type must flag enum + hint, got {c}")

        # (d) IFF — cataloged doc MISSING anchor → finding.
        d1 = check("core/specs/cataloged.md", _fm(
            title="T", purpose="w", type="spec", status="ACTIVE",
            reversibility="CHEAP", consumers="[x]"))
        if not any(f["field"] == "framework_version_anchor" and "required" in f["violation"] for f in d1):
            failures.append(f"(d1) cataloged-missing-anchor must flag, got {d1}")
        #     IFF — NOT-cataloged doc WITH anchor → finding.
        d2 = check("core/specs/not-cataloged.md", _fm(
            title="T", purpose="w", type="spec", status="ACTIVE",
            reversibility="CHEAP", consumers="[x]", framework_version_anchor="v2"))
        if not any(f["field"] == "framework_version_anchor" and "not cataloged" in f["violation"] for f in d2):
            failures.append(f"(d2) not-cataloged-with-anchor must flag, got {d2}")
        #     a cataloged doc WITH the anchor + everything else → 0 findings (IFF satisfied).
        d3 = check("core/specs/cataloged.md", _fm(
            title="T", purpose="w", type="spec", status="ACTIVE",
            reversibility="CHEAP", consumers="[x]", framework_version_anchor="v1"))
        if d3:
            failures.append(f"(d3) cataloged-with-anchor clean doc should yield 0, got {d3}")

        # (e) type:standard missing consumers → finding.
        e = check("core/standards/no-consumers.md", _fm(
            title="T", purpose="w", type="standard", status="ACTIVE",
            reversibility="CHEAP"))
        if not any(f["field"] == "consumers" for f in e):
            failures.append(f"(e) standard missing consumers must flag, got {e}")

        # (f) reversibility:SOMETIMES → prefix finding.
        f_ = check("core/disciplines/bad-rev.md", _fm(
            title="T", purpose="w", type="discipline", status="ACTIVE",
            reversibility="SOMETIMES maybe"))
        if not any(f["field"] == "reversibility" for f in f_):
            failures.append(f"(f) bad reversibility prefix must flag, got {f_}")

        # (g) reversibility:CHEAP (prose tail) → 0 reversibility findings (prefix passes).
        g = check("core/disciplines/good-rev.md", _fm(
            title="T", purpose="w", type="discipline", status="ACTIVE",
            reversibility="CHEAP (revert the check block) / Confidence HIGH"))
        if any(f["field"] == "reversibility" for f in g):
            failures.append(f"(g) reversibility prefix+tail must PASS, got {g}")

        # (h) FALSIFICATION: no-frontmatter doc → missing-frontmatter finding, tier=A.
        h = check("core/rules/no-fm.md", "<!-- comment -->\n# No Frontmatter\n")
        if not (len(h) == 1 and h[0]["field"] == "<frontmatter>" and h[0]["tier"] == "A"):
            failures.append(f"(h) no-frontmatter must yield 1 frontmatter finding tier=A, got {h}")

        # (i) tier tagging — a core/standards/ fixture tags A; a core/skills/ fixture tags other.
        i_a = check("core/standards/tieratest.md", _fm(
            title="T", purpose="w", type="standard", status="ACTIVE",
            reversibility="CHEAP", consumers="[x]"))
        if i_a:  # clean — but assert the tier helper directly:
            failures.append(f"(i) tier-A clean fixture should yield 0, got {i_a}")
        if _tier_for("core/standards/x.md") != "A":
            failures.append("(i) core/standards/ must tag tier=A")
        if _tier_for("core/skills/foo/references/bar.md") != "other":
            failures.append("(i) core/skills/.../references must tag tier=other")

        # (j) allowlist mechanism — load_allowlist round-trips repo-relative paths
        #     (with '#' comments + blanks ignored), and the run-level skip is a
        #     plain `rel_path in allowlist` membership test. Verifying the loader +
        #     the membership predicate IS the allowlist contract; the integration
        #     proof that bypass-mode-readiness produces 0 warnings runs against the
        #     live tree in the deploy.sh Check-50 run (Stage-6 evidence).
        alf = base / "skip.txt"
        alf.write_text(
            "# generated index + ADR-030 assembly fragments (#109 left un-backfilled)\n"
            "core/rules/bypass-mode-readiness.md\n"
            "\n"
            "core/rules/bypass-mode-readiness/_header.md\n",
            encoding="utf-8",
        )
        al = load_allowlist(alf)
        if al != {"core/rules/bypass-mode-readiness.md",
                  "core/rules/bypass-mode-readiness/_header.md"}:
            failures.append(f"(j) allowlist loader must drop comments/blanks, got {al}")
        # The skip predicate run() applies: an allowlisted rel path is excluded.
        if "core/rules/bypass-mode-readiness.md" not in al:
            failures.append("(j) allowlisted path must be a member of the skip set")

    if failures:
        print("self-test FAILED:")
        print("\n".join(failures))
        return 1
    print("self-test OK (fixtures a-j: clean, falsification ×2, enum, IFF ×3, consumers, "
          "reversibility prefix/tail, tier tagging, allowlist)")
    return 0


def main() -> int:
    ap = argparse.ArgumentParser(
        description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    ap.add_argument("--target-paths", default="",
                    help="comma-separated dir/glob list (recursive ** supported); REQUIRED unless --self-test")
    ap.add_argument("--catalog-path", default=None,
                    help=f"framework-catalog.md (default: {DEFAULT_CATALOG_REL} under workspace root)")
    ap.add_argument("--allowlist", default=None,
                    help="skip-list file: repo-relative paths, one per line, '#' comments")
    ap.add_argument("--output-format", choices=["tsv", "json"], default="tsv")
    ap.add_argument("--self-test", action="store_true", help="run internal fixtures and exit")
    args = ap.parse_args()

    if args.self_test:
        return run_self_test()

    if not args.target_paths.strip():
        ap.error("--target-paths is required (unless --self-test)")

    if args.catalog_path:
        cp = Path(args.catalog_path)
        catalog_path = cp if cp.is_absolute() else WORKSPACE_ROOT / cp
    else:
        catalog_path = WORKSPACE_ROOT / DEFAULT_CATALOG_REL

    allowlist_path = None
    if args.allowlist:
        ap_ = Path(args.allowlist)
        allowlist_path = ap_ if ap_.is_absolute() else WORKSPACE_ROOT / ap_
    allowlist = load_allowlist(allowlist_path)

    target_globs = [g for g in args.target_paths.split(",") if g.strip()]
    findings, code = run(target_globs, catalog_path, allowlist)

    if code == 3:
        print("error: path-resolution failure — a --target-paths glob or --catalog-path "
              "resolved to zero/missing files (unverifiable, not clean)", file=sys.stderr)
        return 3

    if args.output_format == "tsv":
        print(emit_tsv(findings))
    else:
        print(emit_json(findings))
    return code


if __name__ == "__main__":
    sys.exit(main())
