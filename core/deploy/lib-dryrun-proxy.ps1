#!/usr/bin/env pwsh
# lib-dryrun-proxy.ps1 — shared -DryRun proof primitives for the Windows install/update entry-points.
#
# Dot-sourced by:
#   - install.ps1   (root)
#   - update.ps1    (root)
#
# Purpose (v3.90 / #303):
#   The working bash-free Windows install is a multi-card arc owned by milestones
#   #47 / #48 (deploy.sh OS-portability #342/#44 + orchestrate.sh phase
#   decomposition #301). For v3.90, #303 ships the Windows *entry-points* plus a
#   NON-VACUOUS `-DryRun` proxy that proves the portable substrate genuinely runs
#   bash-free on this platform — it is the re-scoped AC-4 evidence, NOT gate-theater.
#
# The pinned `-DryRun` contract (A6.5 Counter-Design CD-1, Option B) — every
# `-DryRun` invocation MUST:
#   (a) assert a Python interpreter is present and clears the 3.8 version floor;
#   (b) resolve and print the operator home + workspace root via the Windows
#       %USERPROFILE% / POSIX $HOME equivalent (Path.home());
#   (c) run the required-file preflight (the install.sh:73 repo-marker set);
#   (d) execute ONE real, bash-free operation — a compose.py `regen` into a temp
#       dir with an installed_sha round-trip assertion (write-stored SHA == read-
#       back SHA) — the single genuinely-portable install primitive; and
#   (e) print the phase plan with an explicit per-phase marker (the entry-point
#       prints this; bash-only phases are marked SKIPPED, the portable compose
#       phase is marked EXERCISED).
#
# HOME shim (A6.5 PT-2 / CD-3 correction): compose.py resolve_tokens reads
# os.environ["HOME"] (compose.py:152) as the fallback for [OPERATOR_HOMEDIR_PATH]
# / [CLAUDE_WORKSPACE_ROOT] when operator.toml omits [paths]. On Windows HOME is
# unset (%USERPROFILE% is the home var), so those tokens would resolve to "" /
# "Claude". The shim (set $env:HOME = <resolved home> before every compose.py
# invocation) is therefore anchored at the REAL compose call — here, and in
# update.ps1's Phase-3 wrapper — NOT in the orchestrator (which never invokes
# compose.py). This keeps compose.py unchanged (its SSOT write primitive, ADR-014).
#
# Observable-output discipline: proof lines are written via [Console]::Out to the
# process stdout, NOT the PowerShell output stream, so they are cleanly greppable
# by #304's Windows CI matrix AND do not pollute these functions' boolean return
# values (a PowerShell output-stream is the return channel).
#
# PowerShell floor: 5.1+ (Windows PowerShell) / 6+ (PowerShell Core). No exotic
# syntax; forward-slash paths (accepted on Windows); cross-platform cmdlets only.
# NOTE: PowerShell execution is validated on the Windows leg by #304 — this file
# cannot run on the macOS CI runner (no pwsh). The macOS runner instead exercises
# the identical compose round-trip in POSIX + statically lints this contract via
# core/deploy/tests/test_ps1_dryrun_contract.sh.

$ErrorActionPreference = 'Stop'

# Stable, greppable prefix for every proof line #304 asserts.
$script:PmoDryRunPrefix = '[dryrun]'

function Write-PmoLine {
    # Emit an observable line to real stdout (bypasses the PS output stream, so it
    # never merges into a caller function's return value).
    param([string]$Message)
    [Console]::Out.WriteLine("$script:PmoDryRunPrefix $Message")
}

function Get-PmoHome {
    # Resolve the operator home: Windows %USERPROFILE%, POSIX $HOME. This is the
    # PowerShell form of Python's Path.home() (AC-3 "%USERPROFILE% vs $HOME").
    $h = [System.Environment]::GetFolderPath('UserProfile')
    if ([string]::IsNullOrEmpty($h)) { $h = $env:USERPROFILE }
    if ([string]::IsNullOrEmpty($h)) { $h = $env:HOME }
    return $h
}

function Resolve-PmoPython {
    # Return the first available Python launcher name/path, or $null. Tries the
    # POSIX-idiomatic python3 first, then the Windows-idiomatic python, then the
    # Windows py launcher (which defaults to the latest installed Python 3).
    foreach ($cand in @('python3', 'python', 'py')) {
        $cmd = Get-Command $cand -ErrorAction SilentlyContinue
        if ($cmd) { return $cmd.Source }
    }
    return $null
}

function Get-PmoPythonVersion {
    # Return "MAJOR.MINOR" for the interpreter, or $null if it fails the 3.8 floor
    # or cannot be interrogated. Prints a FAIL line on a sub-floor interpreter.
    param(
        [string]$PythonExe,
        [int]$MinMajor = 3,
        [int]$MinMinor = 8
    )
    $ver = (& $PythonExe -c 'import sys;print("%d.%d" % sys.version_info[:2])' 2>&1 | Out-String).Trim()
    if ($LASTEXITCODE -ne 0 -or [string]::IsNullOrEmpty($ver)) { return $null }
    $parts = $ver.Split('.')
    if ($parts.Count -lt 2) { return $null }
    $maj = [int]$parts[0]
    $min = [int]$parts[1]
    if (($maj -lt $MinMajor) -or (($maj -eq $MinMajor) -and ($min -lt $MinMinor))) {
        Write-PmoLine "Python: FAIL ($ver is below the $MinMajor.$MinMinor floor)"
        return $null
    }
    return $ver
}

function Invoke-PmoComposeRoundTrip {
    # (d) The one REAL bash-free operation. Regenerate a composition surface into a
    # throwaway temp dir via compose.py, then read its tamper anchor back and assert
    # the write-stored installed_sha equals the reader-computed installed_sha. This
    # proves the portable composition primitive runs bash-free on this platform and
    # that the two-hash tamper contract (ADR-014) holds here. Non-destructive: writes
    # only under a fresh temp dir, never the operator workspace.
    param(
        [string]$RepoRoot,
        [string]$PythonExe
    )
    $composePy   = Join-Path $RepoRoot 'core/deploy/compose.py'
    $srcTemplate = Join-Path $RepoRoot 'core/config/allowlists/fs-boundary-allowlist.txt'
    if (-not (Test-Path -LiteralPath $composePy)) {
        Write-PmoLine 'Compose round-trip: FAIL (core/deploy/compose.py missing)'
        return $false
    }
    if (-not (Test-Path -LiteralPath $srcTemplate)) {
        Write-PmoLine 'Compose round-trip: FAIL (source template missing)'
        return $false
    }

    # HOME shim — load-bearing on Windows; set before the compose invocation so
    # compose.py's [CLAUDE_WORKSPACE_ROOT]/[OPERATOR_HOMEDIR_PATH] fallback resolves.
    $env:HOME = Get-PmoHome

    $tempDir = Join-Path ([System.IO.Path]::GetTempPath()) ('pmo-dryrun-' + [System.Guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Path $tempDir -Force | Out-Null
    try {
        $target     = Join-Path $tempDir 'fs-boundary-allowlist.txt'
        # Deliberately-absent operator.toml -> exercises the HOME-fallback token path
        # (the exact path the HOME shim protects). compose.py's parse_toml tolerates
        # the missing file (returns {}), so the fallback fires.
        $absentToml = Join-Path $tempDir 'operator.toml'
        $srcSha     = (Get-FileHash -LiteralPath $srcTemplate -Algorithm SHA256).Hash.ToLower()

        & $PythonExe $composePy regen --source $srcTemplate --target $target `
            --operator-toml $absentToml --tokens-flag tokens --source-sha $srcSha 2>&1 | Out-Null
        if (($LASTEXITCODE -ne 0) -or (-not (Test-Path -LiteralPath $target))) {
            Write-PmoLine "Compose round-trip: FAIL (regen exit $LASTEXITCODE)"
            return $false
        }

        $storedLine = Select-String -LiteralPath $target -Pattern '^# installed_sha:' | Select-Object -First 1
        $stored = ''
        if ($storedLine) { $stored = ($storedLine.Line -replace '^# installed_sha:\s*', '').Trim() }

        $readback = (& $PythonExe $composePy installed-sha --target $target | Out-String).Trim()
        if ($LASTEXITCODE -ne 0) {
            Write-PmoLine "Compose round-trip: FAIL (installed-sha exit $LASTEXITCODE)"
            return $false
        }

        if ([string]::IsNullOrEmpty($stored) -or ($stored -ne $readback)) {
            Write-PmoLine "Compose round-trip: FAIL (stored='$stored' != readback='$readback')"
            return $false
        }

        $short = $stored.Substring(0, [Math]::Min(12, $stored.Length))
        Write-PmoLine "Compose round-trip: PASS (installed_sha ${short}...)"
        return $true
    }
    finally {
        Remove-Item -LiteralPath $tempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

function Invoke-PmoDryRunProof {
    # Run the pinned CD-1 Option B contract items (a)-(d). Returns $true only when
    # every item passes. The caller (install.ps1 / update.ps1) prints its phase
    # plan (e) and maps this boolean to the process exit code.
    param(
        [string]$RepoRoot,
        [string[]]$RequiredFiles
    )
    $ok = $true

    # (a) Python present + version floor.
    $py = Resolve-PmoPython
    if (-not $py) {
        Write-PmoLine 'Python: FAIL (no python3/python/py on PATH)'
        return $false
    }
    $ver = Get-PmoPythonVersion -PythonExe $py
    if (-not $ver) { return $false }
    Write-PmoLine "Python: PASS ($py, $ver, floor 3.8)"

    # (b) Path resolution (Path.home() equivalent).
    $userHome = Get-PmoHome
    $wsRoot = Join-Path $userHome 'Claude'
    Write-PmoLine "Home resolved: $userHome"
    Write-PmoLine "Workspace root: $wsRoot"

    # (c) Required-file preflight.
    $missing = @()
    foreach ($rel in $RequiredFiles) {
        $p = Join-Path $RepoRoot $rel
        if (-not (Test-Path -LiteralPath $p)) { $missing += $rel }
    }
    $total = $RequiredFiles.Count
    $present = $total - $missing.Count
    if ($missing.Count -gt 0) {
        Write-PmoLine "Preflight: FAIL ($present/$total present; missing: $($missing -join ', '))"
        $ok = $false
    }
    else {
        Write-PmoLine "Preflight: PASS ($present/$total required files present)"
    }

    # (d) One real bash-free operation: compose.py regen round-trip.
    if (-not (Invoke-PmoComposeRoundTrip -RepoRoot $RepoRoot -PythonExe $py)) { $ok = $false }

    return $ok
}
