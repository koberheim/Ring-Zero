[CmdletBinding()]
param(
    [string]$GodotExecutable = 'E:/Godot/godot_mono/Godot_v4.7.2-stable_mono_win64/Godot_v4.7.2-stable_mono_win64.exe',
    [ValidateRange(1,600)][int]$TimeoutSeconds = 90,
    [switch]$FrozenSource
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$exportRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$exportDirectory = Join-Path $exportRoot 'exports/windows'
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
function Invoke-ExportStep([string[]]$Arguments, [string]$Label) {
    $process = $null
    $stdout = Join-Path $exportDirectory "$Label.stdout.log"
    $stderr = Join-Path $exportDirectory "$Label.stderr.log"
    try {
        $argumentLine = ($Arguments | ForEach-Object {
            if ($_.Contains('"')) { throw 'Unexpected quote in native argument' }
            '"' + ($_ -replace '(\\+)$', '$1$1') + '"'
        }) -join ' '
        $process = Start-Process -FilePath $GodotExecutable -ArgumentList $argumentLine -WorkingDirectory $exportRoot -WindowStyle Hidden -PassThru -RedirectStandardOutput $stdout -RedirectStandardError $stderr
        $null = $process.Handle
        Write-Host "$Label PID=$($process.Id) timeout=${TimeoutSeconds}s"
        if (-not $process.WaitForExit($TimeoutSeconds * 1000)) { throw "$Label timed out" }
        $process.Refresh()
        if ($null -eq $process.ExitCode -or $process.ExitCode -ne 0) { throw "$Label failed with exit '$($process.ExitCode)'" }
        if (Select-String -LiteralPath @($stdout,$stderr) -Pattern 'SCRIPT ERROR:|Parse Error:|Export failed|ERROR:.*[Ee]xport' -Quiet) { throw "$Label error in log" }
        Write-Host "$Label exit=0"
    } finally {
        if ($null -ne $process) {
            if (-not $process.HasExited) { $process.Kill(); $null = $process.WaitForExit(5000) }
            $process.Dispose()
        }
    }
}
try {
    if (-not (Test-Path -LiteralPath $GodotExecutable -PathType Leaf)) { throw "Missing pinned Mono editor: $GodotExecutable" }
    $templates = 'E:/Users/Kevin/AppData/Roaming/Godot/export_templates/4.7.2.stable.mono'
    foreach ($template in @('windows_debug_x86_64.exe','windows_release_x86_64.exe')) {
        if (-not (Test-Path -LiteralPath (Join-Path $templates $template))) { throw "Missing installed template: $template" }
    }
    $null = New-Item -ItemType Directory -Path $exportDirectory -Force
    $env:APPDATA = Join-Path $exportRoot '.godot/appdata'
    $env:LOCALAPPDATA = Join-Path $exportRoot '.godot/localappdata'
    Invoke-ExportStep @('--version') 'version'
    $version = (Get-Content -LiteralPath (Join-Path $exportDirectory 'version.stdout.log') -Raw).Trim()
    if ($version -cne '4.7.2.stable.mono.official.ed1daf0bf') { throw "Unexpected Mono version: $version" }
    Invoke-ExportStep @('--headless','--path',$exportRoot,'--editor','--import','--quit') 'import'
    & (Join-Path $PSScriptRoot 'write_build_info.ps1') -Frozen:$FrozenSource
    Invoke-ExportStep @('--headless','--path',$exportRoot,'--export-release','Windows Private',(Join-Path $exportDirectory 'RingZero.exe')) 'export'
    & (Join-Path $PSScriptRoot 'verify_build_info.ps1')
    foreach ($artifact in @('RingZero.exe','RingZero.pck')) {
        if (-not (Test-Path -LiteralPath (Join-Path $exportDirectory $artifact) -PathType Leaf)) { throw "Export missing $artifact" }
    }
    $fontNotices = Join-Path $exportDirectory 'licenses/barlow'
    $null = New-Item -ItemType Directory -Path $fontNotices -Force
    foreach ($notice in @('OFL.txt','PROVENANCE.md')) {
        Copy-Item -LiteralPath (Join-Path $exportRoot "assets/ui/fonts/barlow/$notice") -Destination (Join-Path $fontNotices $notice)
    }
    Copy-Item -LiteralPath (Join-Path $exportRoot 'data/build_info.json') -Destination (Join-Path $exportDirectory 'build_info.json')
    $engineNotices = Join-Path $exportDirectory 'licenses/godot'
    $null = New-Item -ItemType Directory -Path $engineNotices -Force
    foreach ($notice in @('LICENSE.txt','THIRD-PARTY.txt')) {
        Copy-Item -LiteralPath (Join-Path $exportRoot "assets/licenses/godot/$notice") -Destination (Join-Path $engineNotices $notice)
    }
    Write-Output "Private build: $(Join-Path $exportDirectory 'RingZero.exe') (keep adjacent exported files). Not published."
} finally {
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
}
