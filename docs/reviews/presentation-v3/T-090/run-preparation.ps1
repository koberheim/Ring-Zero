param([string]$Label = 'preparation-01')
$ErrorActionPreference = 'Stop'
$project = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '../../../..')).ProviderPath
$engine = 'E:/Godot/Godot_v4.7.2-stable_win64.exe'
if (@(Get-Process | Where-Object { $_.ProcessName -match '^Godot' }).Count) { throw 'Competing Godot process; refusing run.' }
$env:APPDATA = Join-Path $project '.godot/t090-appdata'
$env:LOCALAPPDATA = Join-Path $project '.godot/t090-localappdata'
New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA -Force | Out-Null
$arguments = @('--headless','--path',$project,'--script','res://tests/presentation/test_t090_readability.gd','--log-file',(Join-Path $PSScriptRoot ($Label+'.engine.log')))
$line = ($arguments | ForEach-Object { if ($_.Contains('"')) { throw 'Unsupported quote' }; '"'+($_ -replace '(\\+)$','$1$1')+'"' }) -join ' '
$stdout = Join-Path $PSScriptRoot ($Label+'.stdout.log')
$stderr = Join-Path $PSScriptRoot ($Label+'.stderr.log')
$started = [DateTime]::UtcNow.ToString('o')
$process = Start-Process -FilePath $engine -ArgumentList $line -WorkingDirectory $project -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
$null = $process.Handle
$timedOut = -not $process.WaitForExit(30000)
if ($timedOut) { $process.Kill(); $null = $process.WaitForExit(5000) }
$process.Refresh()
$record = [ordered]@{label=$Label; started_utc=$started; completed_utc=[DateTime]::UtcNow.ToString('o'); engine=$engine; arguments=$arguments; exit_code=$process.ExitCode; timed_out=$timedOut}
$process.Dispose()
$record | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $PSScriptRoot ($Label+'.command.json')) -Encoding UTF8
Get-Content -LiteralPath $stdout,$stderr
if ($timedOut -or $null -eq $record.exit_code -or $record.exit_code -ne 0) { throw 'Preparation test failed; logs retained.' }
if (Select-String -LiteralPath $stdout,$stderr -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet) { throw 'Script error; logs retained.' }
