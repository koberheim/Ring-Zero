[CmdletBinding()]
param(
    [string]$GodotExecutable = 'E:/Godot/Godot_v4.7.2-stable_win64.exe',
    [ValidateRange(1, 3600)][int]$SuiteTimeoutSeconds = 90,
    [ValidateRange(1, 3600)][int]$ImportTimeoutSeconds = 90
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$expectedVersion = '4.7.2.stable.official.ed1daf0bf'
$projectRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$previousAppData = [Environment]::GetEnvironmentVariable('APPDATA', 'Process')
$previousLocalAppData = [Environment]::GetEnvironmentVariable('LOCALAPPDATA', 'Process')
$runnerStatus = 2

function ConvertTo-NativeArgument([string]$Value) {
    # Arguments go straight to CreateProcess, never through a command shell.
    # File paths on Windows cannot contain quotes. Double trailing backslashes
    # so they cannot escape the closing quote in native argument parsing.
    if ($Value.Contains('"')) { throw 'A native argument contains an unsupported quote.' }
    return '"' + ($Value -replace '(\\+)$', '$1$1') + '"'
}

function Invoke-TrackedGodot {
    param([string[]]$Arguments, [string]$Label, [int]$TimeoutSeconds)
    $stdoutPath = Join-Path $script:runLogDirectory "$Label.stdout.log"
    $stderrPath = Join-Path $script:runLogDirectory "$Label.stderr.log"
    $argumentLine = ($Arguments | ForEach-Object { ConvertTo-NativeArgument $_ }) -join ' '
    $process = $null
    $watch = [System.Diagnostics.Stopwatch]::StartNew()
    try {
        $process = Start-Process -FilePath $script:resolvedExecutable -ArgumentList $argumentLine -WorkingDirectory $script:projectRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdoutPath -RedirectStandardError $stderrPath
        # Windows PowerShell 5.1 can lose exit-code association for a short-lived
        # Start-Process child unless its native handle is retained before waiting.
        $null = $process.Handle
        Write-Host "$Label PID=$($process.Id), timeout=${TimeoutSeconds}s"
        $timedOut = -not $process.WaitForExit($TimeoutSeconds * 1000)
        if ($timedOut) {
            # Only this exact process object is stopped, never name-based kills.
            if (-not $process.HasExited) { $process.Kill() }
            if (-not $process.WaitForExit(5000)) { throw "$Label did not stop after termination." }
        }
        $process.Refresh()
        $exitCode = $process.ExitCode
        if ($null -eq $exitCode) { throw "$Label exited without a readable exit code; refusing to infer success." }
        $watch.Stop()
        return [pscustomobject]@{
            ExitCode = $exitCode
            TimedOut = $timedOut
            Seconds = [Math]::Round($watch.Elapsed.TotalSeconds, 3)
            Stdout = $stdoutPath
            Stderr = $stderrPath
        }
    }
    finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) {
                $process.Kill()
                $null = $process.WaitForExit(5000)
            }
            $process.Dispose()
        }
    }
}

function Test-ScriptErrors([string[]]$Paths) {
    foreach ($path in $Paths) {
        if ((Test-Path -LiteralPath $path -PathType Leaf) -and
            (Select-String -LiteralPath $path -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet)) {
            return $true
        }
    }
    return $false
}

try {
    if ($env:OS -ne 'Windows_NT') { throw 'Use this native runner on Windows.' }
    if (-not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) {
        throw "Godot executable not found: $GodotExecutable. Use -GodotExecutable with the pinned executable."
    }
    $resolvedExecutable = (Resolve-Path -LiteralPath $GodotExecutable).ProviderPath
    if (-not (Test-Path -LiteralPath (Join-Path $projectRoot 'project.godot') -PathType Leaf)) {
        throw "project.godot not found under script-relative root: $projectRoot"
    }
    $testsRoot = Join-Path $projectRoot 'tests'
    if (-not (Test-Path -LiteralPath $testsRoot -PathType Container)) { throw "Tests directory not found: $testsRoot" }
    # Discover before any engine launch; enumeration failures are terminating.
    $suites = @(Get-ChildItem -LiteralPath $testsRoot -Filter 'test_*.gd' -File -Recurse -ErrorAction Stop | Sort-Object FullName)
    if ($suites.Count -eq 0) { throw "No test_*.gd suites discovered under $testsRoot; refusing an empty success." }

    $cacheRoot = Join-Path $projectRoot '.godot'
    $runLogDirectory = Join-Path $cacheRoot ('test-logs/run-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff') + "-$PID")
    $env:APPDATA = Join-Path $cacheRoot 'appdata'
    $env:LOCALAPPDATA = Join-Path $cacheRoot 'localappdata'
    foreach ($directory in @($runLogDirectory, $env:APPDATA, $env:LOCALAPPDATA)) {
        $null = New-Item -ItemType Directory -Path $directory -Force
    }
    Write-Host "Project: $projectRoot"
    Write-Host "Discovered $($suites.Count) suites. Logs: $runLogDirectory"
    $version = Invoke-TrackedGodot -Arguments @('--version') -Label 'version' -TimeoutSeconds 10
    $versionText = (Get-Content -LiteralPath $version.Stdout -Raw).Trim()
    if ($version.TimedOut -or $version.ExitCode -ne 0 -or $versionText -cne $expectedVersion) {
        throw "Expected Godot $expectedVersion; got '$versionText' (exit $($version.ExitCode), timeout $($version.TimedOut))."
    }

    $importLog = Join-Path $runLogDirectory 'import.log'
    $import = Invoke-TrackedGodot -Arguments @('--headless', '--path', $projectRoot, '--editor', '--import', '--quit', '--log-file', $importLog) -Label 'import' -TimeoutSeconds $ImportTimeoutSeconds
    if ($import.TimedOut -or $import.ExitCode -ne 0 -or (Test-ScriptErrors @($importLog, $import.Stdout, $import.Stderr))) {
        throw "Import failed (exit $($import.ExitCode), timeout $($import.TimedOut)); see $importLog"
    }
    Write-Host "Import passed in $($import.Seconds)s; starting suites sequentially."
    $results = @()
    foreach ($suite in $suites) {
        $relative = $suite.FullName.Substring($projectRoot.Length).TrimStart([char[]]@('\', '/')).Replace('\', '/')
        # Relative hierarchy plus sequence prevents duplicate-basename logs.
        $label = '{0:D3}-{1}' -f ($results.Count + 1), $suite.BaseName
        $engineLog = Join-Path $runLogDirectory "$label.log"
        try {
            $run = Invoke-TrackedGodot -Arguments @('--headless', '--path', $projectRoot, '--script', $relative, '--log-file', $engineLog) -Label $label -TimeoutSeconds $SuiteTimeoutSeconds
            $failed = $run.TimedOut -or $run.ExitCode -ne 0 -or (Test-ScriptErrors @($engineLog, $run.Stdout, $run.Stderr))
            $summary = @(Get-Content -LiteralPath $run.Stdout | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Last 1) -join ''
            $results += [pscustomobject]@{ Suite = $relative; Passed = -not $failed; ExitCode = $run.ExitCode; TimedOut = $run.TimedOut; Seconds = $run.Seconds; Summary = $summary; Log = $engineLog }
            Write-Host "$(if ($failed) { 'FAIL' } else { 'PASS' }) $relative ($($run.Seconds)s, exit $($run.ExitCode), timeout $($run.TimedOut)) $summary"
        }
        catch {
            $results += [pscustomobject]@{ Suite = $relative; Passed = $false; ExitCode = $null; TimedOut = $false; Seconds = $null; Summary = $_.Exception.Message; Log = $engineLog }
            Write-Host "FAIL $relative : $($_.Exception.Message)"
        }
    }
    $failureCount = @($results | Where-Object { -not $_.Passed }).Count
    $results | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $runLogDirectory 'summary.json') -Encoding UTF8
    Write-Host "$($results.Count) suites run; $failureCount failed. Logs: $runLogDirectory"
    $runnerStatus = if ($failureCount -eq 0 -and $results.Count -eq $suites.Count -and $results.Count -gt 0) { 0 } else { 1 }
}
catch {
    [Console]::Error.WriteLine("Runner prerequisite/import failure: $($_.Exception.Message)")
    $runnerStatus = 2
}
finally {
    [Environment]::SetEnvironmentVariable('APPDATA', $previousAppData, 'Process')
    [Environment]::SetEnvironmentVariable('LOCALAPPDATA', $previousLocalAppData, 'Process')
}
exit $runnerStatus
