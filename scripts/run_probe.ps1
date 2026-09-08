param(
    [Parameter(Mandatory=$true)][string]$Script,
    [string]$Label = 'probe',
    [switch]$Rendered,
    [switch]$TraceObjects,
    [int]$TimeoutSeconds = 120
)
$ErrorActionPreference = 'Stop'
$taskRoot = [System.IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$taskLogs = Join-Path $taskRoot ('.godot/release-qa/' + $Label)
$null = New-Item -ItemType Directory -Force -Path $taskLogs
$env:APPDATA = Join-Path $taskRoot '.godot/appdata'
$env:LOCALAPPDATA = Join-Path $taskRoot '.godot/localappdata'
if ($Script -notmatch '^res://[a-zA-Z0-9_./-]+\.gd$') { throw 'Invalid probe script path' }
$taskArgs = @('--path', ('"' + $taskRoot + '"'), '--script', $Script)
if (-not $Rendered) { $taskArgs += '--headless' }
if ($TraceObjects) { $taskArgs += '--verbose' }
$taskProcess = Start-Process -FilePath 'E:/Godot/Godot_v4.7.2-stable_win64.exe' -ArgumentList $taskArgs -WorkingDirectory $taskRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $taskLogs 'stdout.log') -RedirectStandardError (Join-Path $taskLogs 'stderr.log')
$null = $taskProcess.Handle
if (-not $taskProcess.WaitForExit($TimeoutSeconds*1000)) {
    $taskProcess.Kill()
    $taskProcess.WaitForExit()
    throw "Probe timed out: $taskLogs"
}
$taskProcess.Refresh()
$taskErrorText = Get-Content -LiteralPath (Join-Path $taskLogs 'stderr.log') -Raw
Get-Content -LiteralPath (Join-Path $taskLogs 'stdout.log')
if ($taskErrorText -match 'SCRIPT ERROR:|Parse Error:') { Write-Output $taskErrorText; exit 1 }
Write-Output "Exit $($taskProcess.ExitCode). Evidence: $taskLogs"
exit $taskProcess.ExitCode
