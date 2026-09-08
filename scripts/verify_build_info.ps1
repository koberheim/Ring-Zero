[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$verifyRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$metadata = Get-Content -LiteralPath (Join-Path $verifyRoot 'data/build_info.json') -Raw | ConvertFrom-Json
$currentPaths = @()
foreach ($folder in @('src','scenes','data','assets','scripts','tests')) {
    $currentPaths += @(Get-ChildItem -LiteralPath (Join-Path $verifyRoot $folder) -File -Recurse | Where-Object {
        -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $_.FullName -ne (Join-Path $verifyRoot 'data/build_info.json') -and $_.Extension -notin @('.log','.tmp','.bak') -and $_.Name -notlike 'profile.json*'
    } | ForEach-Object { $_.FullName.Substring($verifyRoot.Length+1).Replace('\','/') })
}
$currentPaths += @('project.godot','export_presets.cfg')
if (@(Compare-Object -ReferenceObject @($metadata.source_inventory.path) -DifferenceObject $currentPaths).Count -gt 0) { throw 'Source inventory membership changed; regenerate and re-export' }
$bad = @()
foreach ($entry in $metadata.source_inventory) {
    $path = [IO.Path]::GetFullPath((Join-Path $verifyRoot $entry.path))
    if (-not $path.StartsWith($verifyRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) { throw 'Build inventory path escaped source root' }
    if (-not (Test-Path -LiteralPath $path -PathType Leaf) -or (Get-FileHash -LiteralPath $path -Algorithm SHA256).Hash.ToLowerInvariant() -cne $entry.sha256) { $bad += $entry.path }
}
$canonical = ($metadata.source_inventory | ForEach-Object { $_.path + ':' + $_.sha256 }) -join "`n"
$hasher = [Security.Cryptography.SHA256]::Create()
try { $identity = ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical)))).Replace('-','').ToLowerInvariant() } finally { $hasher.Dispose() }
if ($identity -cne $metadata.build_id) { throw 'Build inventory identity mismatch' }
if ($bad.Count -gt 0) { throw "Source changed after build identity generation; regenerate and re-export: $($bad -join ', ')" }
Write-Output "Verified build identity $identity against $($metadata.source_inventory.Count) current source files."
