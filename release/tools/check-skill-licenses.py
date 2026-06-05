#!/usr/bin/env python3
"""
Skill-package license gate.

Verifies that every distributed `.skill` archive under packages/ carries the
project's canonical Business Source License 1.1 at its top-level
`<skill_name>/LICENSE` entry, byte-for-byte identical to the repo-root LICENSE.

For each `packages/*.skill`:

- Assert a top-level `<skill_name>/LICENSE` entry exists in the namelist
- Assert its bytes exactly equal repo-root `LICENSE` (byte-for-byte, AC-b)

packages/ is intentionally empty between releases (see packages/README.md), so
if no `.skill` archives are present this gate is a no-op and exits 0.

Exit codes:
  0 — all packages carry a byte-identical canonical LICENSE (or none present)
  1 — at least one package missing or with a mismatched LICENSE

Usage:
  python3 release/tools/check-skill-licenses.py
"""
from __future__ import annotations
import sys
import zipfile
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[2]
PACKAGES_DIR = REPO_ROOT / "packages"
ROOT_LICENSE = REPO_ROOT / "LICENSE"


def check_package(pkg: Path, canonical: bytes) -> list[str]:
    """Return a list of failure reasons for one .skill package (empty == pass)."""
    failures: list[str] = []
    skill_name = pkg.stem
    license_arcname = f"{skill_name}/LICENSE"
    try:
        with zipfile.ZipFile(pkg) as zf:
            names = set(zf.namelist())
            if license_arcname not in names:
                failures.append(f"missing top-level LICENSE entry: {license_arcname}")
                return failures
            data = zf.read(license_arcname)
    except zipfile.BadZipFile:
        failures.append("not a valid zip/.skill archive")
        return failures
    if data != canonical:
        failures.append(
            f"LICENSE bytes do not match repo-root LICENSE "
            f"(got {len(data)} bytes, expected {len(canonical)})"
        )
    return failures


def main() -> int:
    if not ROOT_LICENSE.exists():
        print(f"❌ Canonical LICENSE not found: {ROOT_LICENSE}")
        return 1
    canonical = ROOT_LICENSE.read_bytes()

    packages = sorted(PACKAGES_DIR.glob("*.skill"))
    if not packages:
        print("No .skill packages present in packages/ — nothing to check (no-op).")
        return 0

    failed = 0
    for pkg in packages:
        reasons = check_package(pkg, canonical)
        if reasons:
            failed += 1
            print(f"\n❌ {pkg.relative_to(REPO_ROOT)}:")
            for r in reasons:
                print(f"   {r}")
        else:
            print(f"✅ {pkg.relative_to(REPO_ROOT)}")

    print(f"\n=== {len(packages) - failed}/{len(packages)} packages OK ===")
    return 1 if failed else 0


if __name__ == "__main__":
    sys.exit(main())
