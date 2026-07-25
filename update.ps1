#!/usr/bin/env pwsh
# update.ps1 — pmo-platform Windows update entry-point (-DryRun proxy)
#
# Cross-platform sibling of ./update.sh at the repo root. For v3.90 (#303) this
# ships the Windows entry-point plus a NON-VACUOUS `-DryRun` proxy — the re-scoped
# AC-4 evidence.
#
# Unlike install, update HAS a genuinely portable phase: composition-surface
# regeneration (update.sh Phase 3) flows through compose.py, which is pure Python.
# The `-DryRun` compose round-trip therefore both proves the portable substrate AND
# stands in for Phase 3. The bash-only phases (skill redeploy via deploy.sh; hook
# refresh via setup-workspace.sh) require the POSIX path and are marked SKIPPED —
# they are owned by the #47 / #48 cross-platform arc (deploy.sh OS-portability
# #342/#44; orchestrate.sh phase decomposition #301).
#
# HOME shim (A6.5 PT-2 / CD-3): the Windows compose call is the ONLY site where
# compose.py's HOME-unset gap bites. The shim (set $env:HOME = <resolved home>) is
# applied at that real call inside Invoke-PmoComposeRoundTrip — NOT in the
# orchestrator, which never invokes compose.py. compose.py stays unchanged.
#
# -DryRun runs the pinned contract (see core/deploy/lib-dryrun-proxy.ps1):
#   (a) Python present + 3.8 version floor
#   (b) home + workspace-root resolution via %USERPROFILE% / $HOME
#   (c) required-file preflight (the update.sh repo-marker set)
#   (d) one real bash-free op — compose.py regen into a temp dir + installed_sha
#       round-trip (== Phase 3 portable regen)
#   (e) the phase plan below (Phase 3 EXERCISED; bash-only phases SKIPPED)
#
# Usage:
#   pwsh ./update.ps1 -DryRun [-WorkspaceRoot <path>] [-ConfigRoot <path>]
#   pwsh ./update.ps1 -Help
#
# On macOS / Linux, use ./update.sh (the working POSIX update).

[CmdletBinding()]
param(
    [switch]$DryRun,
    [string]$WorkspaceRoot,
    [string]$ConfigRoot,
    [switch]$Help
)

$ErrorActionPreference = 'Stop'
$RepoRoot = $PSScriptRoot

function Show-Usage {
    @'
Usage: pwsh ./update.ps1 [-DryRun] [-WorkspaceRoot <path>] [-ConfigRoot <path>] [-Help]

Windows update entry-point for pmo-platform.

  -DryRun         Run the cross-platform entry-point preflight proxy: assert
                  Python + floor, resolve paths, run the required-file preflight,
                  and execute one real bash-free compose.py regen round-trip
                  (== the portable Phase-3 composition regen). Prints the phase
                  plan; performs no writes to the workspace.
  -WorkspaceRoot  Workspace root (default: <home>/Claude). Interface parity with
                  update.sh; echoed under -DryRun.
  -ConfigRoot     Operator config root. Interface parity with update.sh.
  -Help           Show this help and exit.

The working native-Windows update (bash-free skill redeploy + hook refresh) is
tracked under milestones #47 / #48. On macOS / Linux use ./update.sh.
'@ | ForEach-Object { [Console]::Out.WriteLine($_) }
}

if ($Help) { Show-Usage; exit 0 }

# Load the shared -DryRun proof primitives.
$lib = Join-Path $RepoRoot 'core/deploy/lib-dryrun-proxy.ps1'
if (-not (Test-Path -LiteralPath $lib)) {
    [Console]::Error.WriteLine("ERROR: shared library not found at $lib")
    [Console]::Error.WriteLine('update.ps1 must be run from the root of a pmo-platform clone.')
    exit 65
}
. $lib

# The update-time required-file set — mirrors update.sh preflight (lib-composition
# + manifest) plus compose.py + orchestrate.sh. operator.toml is a RUNTIME (non-
# DryRun) requirement, not a repo file, so it is intentionally not in this set.
$requiredFiles = @(
    '.version',
    'core/deploy/composition-surface-manifest.sh',
    'core/deploy/lib-composition.sh',
    'core/deploy/orchestrate.sh',
    'core/deploy/compose.py'
)

if ($DryRun) {
    Write-PmoLine 'update.ps1 -DryRun — cross-platform entry-point preflight (re-scoped AC-4 proxy)'
    if ($WorkspaceRoot) { Write-PmoLine "Workspace root override: $WorkspaceRoot" }
    if ($ConfigRoot)    { Write-PmoLine "Config root override: $ConfigRoot" }

    $proofOk = Invoke-PmoDryRunProof -RepoRoot $RepoRoot -RequiredFiles $requiredFiles

    # (e) Phase plan. Phase 3 (composition regen) is portable and is EXERCISED by
    # the round-trip above; the remaining phases are bash-only and SKIPPED.
    Write-PmoLine 'Phase plan (update.ps1):'
    Write-PmoLine '  Phase 3 composition regen   : EXERCISED (portable compose.py round-trip above)'
    Write-PmoLine '  Phase 5 skill redeploy      : SKIPPED (bash-only; requires the POSIX path — native Windows update in progress)'
    Write-PmoLine '  Phase 5c hook refresh       : SKIPPED (bash-only; requires the POSIX path — native Windows update in progress)'

    if ($proofOk) {
        Write-PmoLine 'RESULT: PASS (portable substrate + Phase 3 verified bash-free)'
        exit 0
    }
    else {
        Write-PmoLine 'RESULT: FAIL (one or more -DryRun contract checks failed)'
        exit 1
    }
}

# Non-DryRun: the working native-Windows update is not yet available.
[Console]::Error.WriteLine('update.ps1 currently supports -DryRun only.')
[Console]::Error.WriteLine('The working native-Windows update requires the POSIX/bash path')
[Console]::Error.WriteLine('(core/deploy/deploy.sh skill redeploy + docs/scripts/setup-workspace.sh hook')
[Console]::Error.WriteLine('refresh); native Windows update is in progress under milestones #47 / #48.')
[Console]::Error.WriteLine('On macOS / Linux run ./update.sh. Re-run with -DryRun to validate the entry-point.')
exit 3
