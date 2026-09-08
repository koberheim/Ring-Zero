[CmdletBinding()]
param([string]$Executable = 'E:/AI Projects/Games/Ring Zero/exports/windows/RingZero.exe')
$ErrorActionPreference = 'Stop'
# The external headless SceneTree driver did not execute reliably in the release
# export. Exercise the actual owned application window and durable reload instead.
# This helper creates isolated profiles and only targets windows it launches.
& (Join-Path $PSScriptRoot 'smoke_targeted.ps1') -Executable $Executable -QuitX 930
