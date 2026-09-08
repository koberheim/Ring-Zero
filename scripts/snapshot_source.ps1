[CmdletBinding()]
param()
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$snapshotRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$snapshotOutput = Join-Path $snapshotRoot ('exports/source-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff'))
$null = New-Item -ItemType Directory -Path $snapshotOutput
$pending = [Collections.Generic.Stack[string]]::new()
$pending.Push($snapshotRoot)
$inventory = @()
while ($pending.Count -gt 0) {
    $directory = $pending.Pop()
    foreach ($item in Get-ChildItem -LiteralPath $directory -Force) {
        if ($item.Attributes -band [IO.FileAttributes]::ReparsePoint) { continue }
        $relative = $item.FullName.Substring($snapshotRoot.Length + 1).Replace('\', '/')
        if ($item.PSIsContainer) {
            if ($item.Name -in @('.godot', '.git', 'exports', '.codex', '.agents') -or $relative -eq 'docs/reviews/artifacts') { continue }
            $pending.Push($item.FullName)
            continue
        }
        if ($item.Name -like 'profile.json*' -or $item.Extension -in @('.log', '.tmp', '.bak', '.mp4')) { continue }
        $destination = Join-Path $snapshotOutput $relative
        $null = New-Item -ItemType Directory -Path ([IO.Path]::GetDirectoryName($destination)) -Force
        Copy-Item -LiteralPath $item.FullName -Destination $destination
        $inventory += [pscustomobject]@{ Path = $relative; Bytes = $item.Length; SHA256 = (Get-FileHash -LiteralPath $destination -Algorithm SHA256).Hash }
    }
}
$inventory | Sort-Object Path | ConvertTo-Json -Depth 3 | Set-Content -LiteralPath (Join-Path $snapshotOutput 'inventory.json') -Encoding UTF8
Write-Output "Snapshot: $snapshotOutput ($($inventory.Count) files). Inventory hashes copied source; no caches, user profiles or review captures."
