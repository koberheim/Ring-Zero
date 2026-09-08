[CmdletBinding()]
param([switch]$Frozen)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$buildRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$sourceFiles = @()
foreach ($folder in @('src','scenes','data','assets','scripts','tests')) {
    $sourceFiles += @(Get-ChildItem -LiteralPath (Join-Path $buildRoot $folder) -File -Recurse | Where-Object {
        -not ($_.Attributes -band [IO.FileAttributes]::ReparsePoint) -and $_.FullName -ne (Join-Path $buildRoot 'data/build_info.json') -and $_.Extension -notin @('.log','.tmp','.bak') -and $_.Name -notlike 'profile.json*'
    })
}
foreach ($name in @('project.godot','export_presets.cfg')) { $sourceFiles += Get-Item -LiteralPath (Join-Path $buildRoot $name) }
$inventory = @($sourceFiles | Sort-Object FullName | ForEach-Object {
    [pscustomobject]@{path=$_.FullName.Substring($buildRoot.Length+1).Replace('\','/'); sha256=(Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()}
})
$canonical = ($inventory | ForEach-Object { $_.path + ':' + $_.sha256 }) -join "`n"
$hasher = [Security.Cryptography.SHA256]::Create()
try { $identity = ([BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($canonical)))).Replace('-','').ToLowerInvariant() } finally { $hasher.Dispose() }
$metadata = [ordered]@{format=1; build_id=$identity; frozen=[bool]$Frozen; generated_utc=[DateTime]::UtcNow.ToString('o'); engine='4.7.2.stable'; source_files=$inventory.Count; source_inventory=$inventory}
[IO.File]::WriteAllText((Join-Path $buildRoot 'data/build_info.json'), ($metadata | ConvertTo-Json -Depth 5), [Text.UTF8Encoding]::new($false))
Write-Output "Build identity: $identity; frozen=$([bool]$Frozen); $($inventory.Count) source files. Excludes generated metadata and logs."
