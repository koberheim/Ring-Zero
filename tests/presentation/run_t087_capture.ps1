param([string]$Label='after',[switch]$Quick,[switch]$Before)
$ErrorActionPreference='Stop'
$taskRoot=(Resolve-Path (Join-Path $PSScriptRoot '../..')).Path
$evidence=Join-Path $taskRoot 'docs/reviews/presentation-v3/T-087'
$env:APPDATA=Join-Path $taskRoot '.godot/appdata'
$env:LOCALAPPDATA=Join-Path $taskRoot '.godot/localappdata'
$outLog=Join-Path $evidence ($Label+'.stdout.log')
$errLog=Join-Path $evidence ($Label+'.stderr.log')
$arguments=@('--path',('"'+$taskRoot+'"'),'--script','tests/presentation/capture_t087_layout.gd','--',('--evidence-dir=res://docs/reviews/presentation-v3/T-087/'+$Label))
if(-not $Before){$arguments+='--after'}
if($Quick){$arguments+='--quick'}
$process=Start-Process -FilePath 'E:/Godot/Godot_v4.7.2-stable_win64.exe' -ArgumentList $arguments -WindowStyle Hidden -PassThru -RedirectStandardOutput $outLog -RedirectStandardError $errLog
$null=$process.Handle
$watch=[Diagnostics.Stopwatch]::StartNew()
try {
    while(-not $process.WaitForExit(500)){
        if($watch.Elapsed.TotalSeconds -gt 230 -or ((Test-Path $errLog) -and (Select-String -LiteralPath $errLog -Pattern 'SCRIPT ERROR:|Parse Error:' -Quiet))){$process.Kill();$process.WaitForExit();break}
    }
    $process.Refresh()
    $code=$process.ExitCode
    Get-Content -LiteralPath $outLog -Tail 5
    Get-Content -LiteralPath $errLog -TotalCount 70
    Write-Output "Capture PID=$($process.Id) exit=$code"
}finally{if(-not $process.HasExited){$process.Kill()};$process.Dispose()}
exit $code
