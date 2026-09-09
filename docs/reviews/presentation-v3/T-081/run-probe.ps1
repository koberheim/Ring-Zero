param(
    [Parameter(Mandatory=$true)][string]$ProjectPath,
    [Parameter(Mandatory=$true)][string]$Label,
    [string]$Script = '',
    [switch]$Import,
    [string]$Backend = '',
    [string]$EvidenceDirectory = ''
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$evidence = $PSScriptRoot
$project = (Resolve-Path -LiteralPath $ProjectPath).ProviderPath
$engine = 'E:/Godot/Godot_v4.7.2-stable_win64.exe'
$env:APPDATA = Join-Path $project '.godot/t081-appdata'
$env:LOCALAPPDATA = Join-Path $project '.godot/t081-localappdata'
New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA -Force | Out-Null
if (@(Get-Process | Where-Object { $_.ProcessName -match '^Godot' }).Count) { throw 'Competing Godot process; refusing run.' }
$arguments = @('--path',$project,'--log-file',(Join-Path $evidence ($Label+'.engine.log')))
if ($Import) { $arguments += @('--headless','--editor','--import') }
else {
    if ($Backend) { $arguments += @('--rendering-method',$Backend) }
    $arguments += @('--script',$Script)
    if ($EvidenceDirectory) { $arguments += @('--',('--evidence-dir='+$EvidenceDirectory)) }
}
$line = ($arguments | ForEach-Object { if ($_.Contains('"')) { throw 'Unsupported quote in argument' }; '"'+($_ -replace '(\\+)$','$1$1')+'"' }) -join ' '
$out = Join-Path $evidence ($Label+'.stdout.log')
$err = Join-Path $evidence ($Label+'.stderr.log')
$started = [DateTime]::UtcNow.ToString('o')
$process = Start-Process -FilePath $engine -ArgumentList $line -WorkingDirectory $project -WindowStyle Hidden -PassThru -RedirectStandardOutput $out -RedirectStandardError $err
$null = $process.Handle
Write-Output "$Label PID=$($process.Id)"
$timedOut = -not $process.WaitForExit(60000)
if ($timedOut) { $process.Kill(); $null = $process.WaitForExit(5000) }
$process.Refresh()
$record = [ordered]@{ label=$Label; engine=$engine; arguments=$arguments; working_directory=$project; started_utc=$started; completed_utc=[DateTime]::UtcNow.ToString('o'); pid=$process.Id; exit_code=$process.ExitCode; timed_out=$timedOut; isolated_appdata=$env:APPDATA; isolated_localappdata=$env:LOCALAPPDATA }
$process.Dispose()
$record | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $evidence ($Label+'.command.json')) -Encoding UTF8
Get-Content -LiteralPath $out
Get-Content -LiteralPath $err
if ($timedOut -or $null -eq $record.exit_code -or $record.exit_code -ne 0) { throw "Probe failed: $Label" }
if (Select-String -LiteralPath $out,$err -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet) { throw "Script error: $Label" }
if (-not $Import) {
    $sampleText = @(Get-Content -LiteralPath $out | Where-Object { $_.StartsWith('{') -and $_.Contains('median_frame_ms') })
    if ($sampleText.Count -eq 1) {
        $sample = $sampleText[0] | ConvertFrom-Json
        if ($sample.PSObject.Properties.Name -contains 'diagnostic') {
            Write-Output 'Uncapped diagnostic retained; not a matched acceptance sample.'
        } else {
            $breached = $sample.median_frame_ms -gt 18.3348 -or $sample.p95_frame_ms -gt 18.4360 -or $sample.max_frame_ms -gt 20.3379 -or $sample.simulation_wall_ratio -lt 0.99
            if ($breached) { throw 'PERFORMANCE ENVELOPE BREACHED: retain/report; further diagnosis requires owner orchestration.' }
            Write-Output 'Matched historical envelope PASS for this individual sample.'
        }
    }
}
