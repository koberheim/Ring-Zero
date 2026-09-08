[CmdletBinding()]
param([string]$Executable = 'E:/AI Projects/Games/Ring Zero/exports/windows/RingZero.exe')
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$packageRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$packageLogs = Join-Path $packageRoot ('.godot/package-input/run-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff') + "-$PID")
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$process = $null
$results = @()
try {
    $env:APPDATA = Join-Path $packageLogs 'appdata'
    $env:LOCALAPPDATA = Join-Path $packageLogs 'localappdata'
    $null = New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA -Force
    $driver = Join-Path $PSScriptRoot 'verify_packaged.gd'
    foreach ($stage in @('first','reload')) {
        $arguments = @('--headless','--script',('"' + $driver + '"'))
        if ($stage -eq 'reload') { $arguments += @('--','--verify-reload') }
        $stdout = Join-Path $packageLogs "$stage.stdout.log"
        $stderr = Join-Path $packageLogs "$stage.stderr.log"
        $process = Start-Process -FilePath $Executable -ArgumentList $arguments -WorkingDirectory ([IO.Path]::GetDirectoryName($Executable)) -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $null = $process.Handle
        Write-Host "$stage packaged PID=$($process.Id), timeout=40s"
        if (-not $process.WaitForExit(40000)) { throw "$stage packaged driver timed out" }
        $process.Refresh()
        if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "$stage packaged exit '$($process.ExitCode)'; inspect logs $packageLogs" }
        if (Select-String -LiteralPath @($stdout,$stderr) -Pattern 'SCRIPT ERROR:|Parse Error:|Shader Error:' -Quiet) { throw "$stage packaged script error; inspect logs $packageLogs" }
        $evidence = @(Get-ChildItem -LiteralPath $env:APPDATA -Filter "packaged-$stage.json" -Recurse -File)
        if ($evidence.Count -ne 1) { throw "$stage package did not persist evidence" }
        $data = Get-Content -LiteralPath $evidence[0].FullName -Raw | ConvertFrom-Json
        if (-not $data.ok -or -not $data.build.frozen) { throw "$stage package evidence invalid" }
        $results += [pscustomobject]@{stage=$stage;pid=$process.Id;exit_code=$process.ExitCode;evidence=$data}
        Get-Content -LiteralPath $stdout | Select-Object -Last 2
        $process.Dispose()
        $process = $null
    }
    $results | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath (Join-Path $packageLogs 'summary.json') -Encoding UTF8
    Write-Output "Packaged viewport-input lifecycle/reload passed. Logs: $packageLogs"
} finally {
    if ($null -ne $process) {
        if (-not $process.HasExited) { $process.Kill(); $null = $process.WaitForExit(5000) }
        $process.Dispose()
    }
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
}
