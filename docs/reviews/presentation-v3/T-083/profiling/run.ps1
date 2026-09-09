param(
    [Parameter(Mandatory=$true)][ValidateSet('import','normal','draw-off','admission-off','cache-hold')][string]$Mode,
    [Parameter(Mandatory=$true)][string]$Label
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
if ($Label -notmatch '^[a-z0-9-]+$') { throw 'Label must be a safe unique identifier' }
$workspace = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '../../../../..'))
$isolated = [IO.Path]::GetFullPath((Join-Path $workspace '.godot/release-qa/t083-profile-base'))
$intendedParent = [IO.Path]::GetFullPath((Join-Path $workspace '.godot/release-qa'))
if (-not $isolated.StartsWith($intendedParent + [IO.Path]::DirectorySeparatorChar,[StringComparison]::OrdinalIgnoreCase)) { throw 'Isolated project escapes intended parent' }
if (-not (Test-Path -LiteralPath (Join-Path $isolated 't083-instrumentation.json'))) { throw 'Run isolated archive preparation first' }
if (@(Get-Process | Where-Object { $_.ProcessName -match '^Godot' }).Count) { throw 'Competing Godot process: runtime window required' }
$evidence = Join-Path $PSScriptRoot $Label
if (Test-Path -LiteralPath $evidence) { throw 'Evidence label already exists; never overwrite an attempt' }
New-Item -ItemType Directory -Path $evidence -Force | Out-Null
$snapshots = Join-Path $evidence 'source'
New-Item -ItemType Directory -Path $snapshots -Force | Out-Null
$sourceNames = @('project.godot','src/presentation/release_view.gd','src/presentation/live_view.gd','src/presentation/effects/collapse_feedback.gd','src/gameplay/live_simulation.gd','tests/performance/profile_t083_dense.gd','data/balance/release.json','data/balance/testing.json')
$hashes = foreach ($name in $sourceNames) {
    $sourcePath = Join-Path $isolated $name
    $snapshotName = $name.Replace('/','__') + '.txt'
    Copy-Item -LiteralPath $sourcePath -Destination (Join-Path $snapshots $snapshotName)
    [ordered]@{ source=$name; snapshot=$snapshotName; sha256=(Get-FileHash -LiteralPath $sourcePath -Algorithm SHA256).Hash }
}
$hashes | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $evidence 'source-manifest.json') -Encoding UTF8
Copy-Item -LiteralPath (Join-Path $isolated 't083-instrumentation.json') -Destination (Join-Path $evidence 'instrumentation.json')
$engine = 'E:/Godot/Godot_v4.7.2-stable_win64.exe'
$env:APPDATA = Join-Path $isolated '.godot/profile-appdata'
$env:LOCALAPPDATA = Join-Path $isolated '.godot/profile-localappdata'
New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA -Force | Out-Null
$arguments = @('--path',$isolated,'--log-file',(Join-Path $evidence 'engine.log'))
if ($Mode -eq 'import') { $arguments += @('--headless','--editor','--import') }
else { $arguments += @('--script','res://tests/performance/profile_t083_dense.gd','--',('--profile-mode='+$Mode),('--evidence-dir='+$evidence.Replace('\','/'))) }
$line = ($arguments | ForEach-Object { if ($_.Contains('"')) { throw 'Unsupported quote in argument' }; '"'+($_ -replace '(\\+)$','$1$1')+'"' }) -join ' '
$started = [DateTime]::UtcNow.ToString('o')
$process = Start-Process -FilePath $engine -ArgumentList $line -WorkingDirectory $isolated -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $evidence 'stdout.log') -RedirectStandardError (Join-Path $evidence 'stderr.log')
$null = $process.Handle
Write-Output "$Label PID=$($process.Id)"
$timedOut = -not $process.WaitForExit(60000)
if ($timedOut) { $process.Kill(); $null = $process.WaitForExit(5000) }
$process.Refresh()
$record = [ordered]@{label=$Label;mode=$Mode;engine=$engine;arguments=$arguments;started_utc=$started;completed_utc=[DateTime]::UtcNow.ToString('o');pid=$process.Id;exit_code=$process.ExitCode;timed_out=$timedOut;fixture='reconstructed dense04';base_commit='67a49cb';source_snapshot_before_launch=$true}
$process.Dispose()
$record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidence 'command.json') -Encoding UTF8
Get-Content -LiteralPath (Join-Path $evidence 'stdout.log')
Get-Content -LiteralPath (Join-Path $evidence 'stderr.log')
if ($timedOut -or $null -eq $record.exit_code -or $record.exit_code -ne 0) { throw 'Profiling attempt failed; retain evidence' }
if (Select-String -LiteralPath (Join-Path $evidence 'stdout.log'),(Join-Path $evidence 'stderr.log') -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet) { throw 'Profiling script error; retain evidence' }
