#!/usr/bin/env pwsh
# install.ps1 — pmo-platform Windows install entry-point (-DryRun proxy)
#
# Cross-platform sibling of ./install.sh at the repo root. For v3.90 (#303) this
# ships the Windows entry-point plus a NON-VACUOUS `-DryRun` proxy — the re-scoped
# AC-4 evidence. The working bash-free native-Windows install (running the bash
# bootstrap + skill-deploy phases without a POSIX prerequisite) is a multi-card arc
# owned by milestones #47 / #48 (deploy.sh OS-portability #342/#44 + orchestrate.sh
# phase decomposition #301); it is NOT delivered here, and this script does not
# pretend otherwise (no misleading partial success).
#
# -DryRun runs the pinned contract (see core/deploy/lib-dryrun-proxy.ps1):
#   (a) Python present + 3.8 version floor
#   (b) home + workspace-root resolution via %USERPROFILE% / $HOME
#   (c) required-file preflight (the install.sh repo-marker set)
#   (d) one real bash-free op — compose.py regen into a temp dir + installed_sha
#       round-trip (the portable substrate proof)
#   (e) the phase plan below, with each bash-only phase marked SKIPPED
#
# Usage:
#   pwsh ./install.ps1 -DryRun [-WorkspaceRoot <path>] [-ConfigRoot <path>]
#   pwsh ./install.ps1 -Help
#
# On macOS / Linux, use ./install.sh (the working POSIX install).

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
Usage: pwsh ./install.ps1 [-DryRun] [-WorkspaceRoot <path>] [-ConfigRoot <path>] [-Help]

Windows install entry-point for pmo-platform.

  -DryRun         Run the cross-platform entry-point preflight proxy: assert
                  Python + floor, resolve paths, run the required-file preflight,
                  and execute one real bash-free compose.py round-trip. Prints the
                  phase plan; performs no install writes to the workspace.
  -WorkspaceRoot  Workspace destination (default: <home>/Claude). Interface parity
                  with install.sh; echoed under -DryRun.
  -ConfigRoot     Operator config root. Interface parity with install.sh.
  -Help           Show this help and exit.

The working native-Windows install (bash-free bootstrap + skill deploy) is
tracked under milestones #47 / #48. On macOS / Linux use ./install.sh.
'@ | ForEach-Object { [Console]::Out.WriteLine($_) }
}

if ($Help) { Show-Usage; exit 0 }

# Load the shared -DryRun proof primitives.
$lib = Join-Path $RepoRoot 'core/deploy/lib-dryrun-proxy.ps1'
if (-not (Test-Path -LiteralPath $lib)) {
    [Console]::Error.WriteLine("ERROR: shared library not found at $lib")
    [Console]::Error.WriteLine('install.ps1 must be run from the root of a pmo-platform clone.')
    exit 65
}
. $lib

# The install-time required-file set — mirrors install.sh preflight (install.sh:73)
# plus compose.py (the -DryRun portable primitive).
$requiredFiles = @(
    '.version',
    'core/deploy/composition-surface-manifest.sh',
    'docs/scripts/setup-workspace.sh',
    'core/deploy/orchestrate.sh',
    'core/deploy/compose.py'
)

if ($DryRun) {
    Write-PmoLine 'install.ps1 -DryRun — cross-platform entry-point preflight (re-scoped AC-4 proxy)'
    if ($WorkspaceRoot) { Write-PmoLine "Workspace root override: $WorkspaceRoot" }
    if ($ConfigRoot)    { Write-PmoLine "Config root override: $ConfigRoot" }

    $proofOk = Invoke-PmoDryRunProof -RepoRoot $RepoRoot -RequiredFiles $requiredFiles

    # (e) Phase plan. install has NO portable phase of its own — both phases are
    # bash (setup-workspace.sh bootstrap; deploy.sh skill deploy). The compose
    # round-trip above is the portable-SUBSTRATE proof, not an install phase.
    Write-PmoLine 'Phase plan (install.ps1):'
    Write-PmoLine '  Phase 1 workspace bootstrap : SKIPPED (bash-only; requires the POSIX path — native Windows install in progress)'
    Write-PmoLine '  Phase 2 skill deploy        : SKIPPED (bash-only; requires the POSIX path — native Windows install in progress)'

    if ($proofOk) {
        Write-PmoLine 'RESULT: PASS (portable substrate verified bash-free)'
        exit 0
    }
    else {
        Write-PmoLine 'RESULT: FAIL (one or more -DryRun contract checks failed)'
        exit 1
    }
}

# Non-DryRun: the working native-Windows install is not yet available.
[Console]::Error.WriteLine('install.ps1 currently supports -DryRun only.')
[Console]::Error.WriteLine('The working native-Windows install requires the POSIX/bash path')
[Console]::Error.WriteLine('(docs/scripts/setup-workspace.sh + core/deploy/deploy.sh); native Windows')
[Console]::Error.WriteLine('install is in progress under milestones #47 / #48.')
[Console]::Error.WriteLine('On macOS / Linux run ./install.sh. Re-run with -DryRun to validate the entry-point.')
exit 3
