[CmdletBinding()]
param(
    [string]$Executable = 'E:/AI Projects/Games/Ring Zero/exports/windows/RingZero.exe',
    [double]$StartX = 307.5, [double]$StartY = 679,
    [double]$QuitX = 750, [double]$QuitY = 679,
    [double]$AbandonX = 720, [double]$AbandonY = 539,
    [double]$BuildX = 846.5, [double]$BuildY = 388.3
)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public static class RingZeroPrivateInput {
 [StructLayout(LayoutKind.Sequential)] public struct RECT { public int left,top,right,bottom; }
 [StructLayout(LayoutKind.Sequential)] public struct POINT { public int x,y; }
 [StructLayout(LayoutKind.Sequential)] struct MOUSEINPUT { public int dx,dy; public uint mouseData,dwFlags,time; public UIntPtr dwExtraInfo; }
 [StructLayout(LayoutKind.Sequential)] struct KEYBDINPUT { public ushort wVk,wScan; public uint dwFlags,time; public UIntPtr dwExtraInfo; }
 [StructLayout(LayoutKind.Explicit)] struct UNION { [FieldOffset(0)] public MOUSEINPUT mi; [FieldOffset(0)] public KEYBDINPUT ki; }
 [StructLayout(LayoutKind.Sequential)] struct INPUT { public uint type; public UNION data; }
 [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
 [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
 [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
 [DllImport("user32.dll")] static extern bool ShowWindow(IntPtr h,int command);
 [DllImport("user32.dll")] static extern bool BringWindowToTop(IntPtr h);
 [DllImport("user32.dll")] static extern uint GetWindowThreadProcessId(IntPtr h,out uint pid);
 [DllImport("user32.dll")] static extern bool GetClientRect(IntPtr h,out RECT r);
 [DllImport("user32.dll")] static extern bool ClientToScreen(IntPtr h,ref POINT p);
 [DllImport("user32.dll")] static extern bool SetCursorPos(int x,int y);
 [DllImport("user32.dll")] static extern short GetAsyncKeyState(int key);
 [DllImport("user32.dll")] static extern uint MapVirtualKey(uint code,uint map);
 [DllImport("user32.dll",SetLastError=true)] static extern uint SendInput(uint count,INPUT[] input,int size);
 public static void Activate(IntPtr h,int expected) {
   uint actual; GetWindowThreadProcessId(h,out actual);
   if(h==IntPtr.Zero || actual!=(uint)expected) throw new Exception("Activation window is not owned package");
   ShowWindow(h,9); BringWindowToTop(h); SetForegroundWindow(h);
 }
 public static void Guard(IntPtr h,int expected) {
   uint actual; GetWindowThreadProcessId(h,out actual);
   if(h==IntPtr.Zero || actual!=(uint)expected || GetForegroundWindow()!=h) throw new Exception("Owned package lost foreground; input aborted");
   foreach(int key in new[]{0x10,0x11,0x12,0x5B,0x5C}) if((GetAsyncKeyState(key)&0x8000)!=0) throw new Exception("User modifier held; input aborted");
 }
 public static void Click(IntPtr h,int pid,double x,double y,bool right) {
   Guard(h,pid); RECT r; if(!GetClientRect(h,out r)) throw new Exception("Cannot read owned client rectangle");
   double w=r.right-r.left, height=r.bottom-r.top, scale=Math.Min(w/1440.0,height/810.0);
   if(scale<=0) throw new Exception("Invalid package client size");
   POINT p=new POINT{x=(int)Math.Round((w-1440*scale)/2+x*scale),y=(int)Math.Round((height-810*scale)/2+y*scale)};
   if(!ClientToScreen(h,ref p)) throw new Exception("Cannot convert owned client coordinates");
   Guard(h,pid); if(!SetCursorPos(p.x,p.y)) throw new Exception("Cannot position pointer");
   INPUT[] events=new INPUT[2]; events[0].type=0; events[0].data.mi.dwFlags=right?0x0008u:0x0002u;
   events[1].type=0; events[1].data.mi.dwFlags=right?0x0010u:0x0004u;
   Guard(h,pid); if(SendInput(2,events,Marshal.SizeOf(typeof(INPUT)))!=2) throw new Exception("Native click injection failed");
 }
 public static void Key(IntPtr h,int pid,uint key) {
   INPUT[] events=new INPUT[2]; ushort scan=(ushort)MapVirtualKey(key,0);
   events[0].type=1; events[0].data.ki.wScan=scan; events[0].data.ki.dwFlags=0x0008;
   events[1].type=1; events[1].data.ki.wScan=scan; events[1].data.ki.dwFlags=0x0008|0x0002;
   Guard(h,pid); if(SendInput(2,events,Marshal.SizeOf(typeof(INPUT)))!=2) throw new Exception("Native key injection failed");
 }
}
'@
$null = [RingZeroPrivateInput]::SetProcessDPIAware()
$smokeRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$smokeLogs = Join-Path $smokeRoot ('.godot/package-smoke/run-' + [DateTime]::UtcNow.ToString('yyyyMMdd-HHmmss-fff') + "-$PID")
$oldAppData = $env:APPDATA
$oldLocalAppData = $env:LOCALAPPDATA
$process = $null
$launches = @()
$inputEvents = @()
function Launch-Package([string]$Label) {
    $script:process = Start-Process -FilePath $Executable -WorkingDirectory ([IO.Path]::GetDirectoryName($Executable)) -WindowStyle Hidden -PassThru -RedirectStandardOutput (Join-Path $smokeLogs "$Label.stdout.log") -RedirectStandardError (Join-Path $smokeLogs "$Label.stderr.log")
    $null = $script:process.Handle
    Write-Host "$Label PID=$($script:process.Id)"
    $deadline = [DateTime]::UtcNow.AddSeconds(15)
    do {
        if ($script:process.HasExited) { throw "$Label exited before input" }
        $script:process.Refresh()
        if ($script:process.MainWindowHandle -ne [IntPtr]::Zero) { break }
        Start-Sleep -Milliseconds 100
    } while ([DateTime]::UtcNow -lt $deadline)
    $script:ownedWindow = $script:process.MainWindowHandle
    if ($script:ownedWindow -eq [IntPtr]::Zero) { throw 'No owned package window within15seconds' }
    # Hidden startup may need an explicit restore for this interactive test.
    # Only the exact owned window may be restored/activated, never arbitrary foreground.
    [RingZeroPrivateInput]::Activate($script:ownedWindow,$script:process.Id)
    Start-Sleep -Milliseconds 800
    $script:process.Refresh()
    $script:ownedWindow = $script:process.MainWindowHandle
    [RingZeroPrivateInput]::Activate($script:ownedWindow,$script:process.Id)
    Start-Sleep -Milliseconds 200
    [RingZeroPrivateInput]::Guard($script:ownedWindow,$script:process.Id)
}
function Click-Owned([double]$X,[double]$Y,[bool]$Right=$false) {
    [RingZeroPrivateInput]::Click($script:ownedWindow,$script:process.Id,$X,$Y,$Right)
    $script:inputEvents += [pscustomobject]@{pid=$script:process.Id;type='click';x=$X;y=$Y;right=$Right;utc=[DateTime]::UtcNow.ToString('o')}
    Start-Sleep -Milliseconds 250
}
function Key-Owned([uint32]$Key) {
    [RingZeroPrivateInput]::Key($script:ownedWindow,$script:process.Id,$Key)
    $script:inputEvents += [pscustomobject]@{pid=$script:process.Id;type='key';virtual_key=$Key;utc=[DateTime]::UtcNow.ToString('o')}
    Start-Sleep -Milliseconds 250
}
function Finish-Package([string]$Label) {
    if (-not $script:process.WaitForExit(15000)) { throw "$Label did not quit through UI within15seconds" }
    $script:process.Refresh()
    if ($null -eq $script:process.ExitCode -or $script:process.ExitCode -ne 0) { throw "$Label exit is '$($script:process.ExitCode)'" }
    $script:launches += [pscustomobject]@{label=$Label;pid=$script:process.Id;exit_code=$script:process.ExitCode}
    Write-Host "$Label exit=0 via UI"
    $script:process.Dispose()
    $script:process = $null
}
try {
    if (-not (Test-Path -LiteralPath $Executable -PathType Leaf)) { throw "Missing private executable: $Executable" }
    $null = New-Item -ItemType Directory -Path $smokeLogs -Force
    $env:APPDATA = Join-Path $smokeLogs 'appdata'
    $env:LOCALAPPDATA = Join-Path $smokeLogs 'localappdata'
    $null = New-Item -ItemType Directory -Path $env:APPDATA,$env:LOCALAPPDATA -Force
    Launch-Package 'first'
    Click-Owned $StartX $StartY
    Start-Sleep -Milliseconds 750
    Key-Owned 0x31
    Click-Owned $BuildX $BuildY
    Click-Owned $BuildX $BuildY $true
    Start-Sleep -Milliseconds 500
    Key-Owned 0x1B
    Key-Owned 0x1B
    Key-Owned 0x1B
    Click-Owned $AbandonX $AbandonY
    Click-Owned $QuitX $QuitY
    Finish-Package 'first'
    $profiles = @(Get-ChildItem -LiteralPath $env:APPDATA -Filter 'profile.json' -Recurse -File)
    if ($profiles.Count -ne 1) { throw 'Expected exactly one isolated profile after start/abandon' }
    $profileBytes = Get-Content -LiteralPath $profiles[0].FullName -Raw
    $profile = $profileBytes | ConvertFrom-Json
    if ($profile.currency -ne 0 -or $profile.pending_run_id -ne '' -or $profile.next_run_id -ne 2 -or @($profile.settled_run_ids).Count -ne 1) { throw 'Abandon profile settlement mismatch' }
    $traces = @(Get-ChildItem -LiteralPath $env:APPDATA -Filter '*.jsonl' -Recurse -File)
    if ($traces.Count -ne 1) { throw 'Expected one real recorded run' }
    $rows = @(Get-Content -LiteralPath $traces[0].FullName | ForEach-Object { $_ | ConvertFrom-Json })
    $commands = @($rows | Where-Object { $_.type -eq 'command' })
    $markers = @($rows | Where-Object { $_.type -eq 'marker' })
    if ($rows[-1].type -ne 'end' -or $rows[-1].outcome -ne 'abandoned' -or $rows[-1].tick -lt 5) { throw 'Real play/end trace evidence missing' }
    if (@($commands | Where-Object { $_.ok }).Count -lt 1) { throw 'No accepted world command in package trace' }
    if (@($markers | Where-Object {$_.event -eq 'pause'}).Count -lt 2 -or @($markers | Where-Object {$_.event -eq 'resume'}).Count -lt 1) { throw 'Pause/resume native input did not reach application' }
    if (-not $rows[0].metadata.build.frozen) { throw 'Package trace is not identified as frozen source' }
    Launch-Package 'reload'
    if ((Get-Content -LiteralPath $profiles[0].FullName -Raw) -cne $profileBytes) { throw 'Reload unexpectedly changed durable profile' }
    Click-Owned $QuitX $QuitY
    Finish-Package 'reload'
    if ((Get-Content -LiteralPath $profiles[0].FullName -Raw) -cne $profileBytes) { throw 'Quit after reload changed durable profile' }
    $errors = @(Get-ChildItem -LiteralPath $smokeLogs -Filter '*.log' -File | Select-String -Pattern 'SCRIPT ERROR:|Parse Error:|Shader Error:')
    if ($errors.Count -gt 0) { throw 'Package script/parse/shader error in logs' }
    [ordered]@{ok=$true; launches=$launches; inputs=$inputEvents; build=$rows[0].metadata.build; engine=$rows[0].metadata.engine; run_id=$rows[0].metadata.run_id; ticks=$rows[-1].tick; commands=$commands.Count; markers=$markers.Count; currency=$profile.currency; profile=$profiles[0].FullName; trace=$traces[0].FullName} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $smokeLogs 'summary.json') -Encoding UTF8
    Write-Output "Packaged native lifecycle passed. Logs: $smokeLogs"
} catch {
    if (Test-Path -LiteralPath $smokeLogs -PathType Container) {
        $reason = $_.Exception.Message
        $classification = if ($reason -match 'foreground|modifier|injection|owned.*window|pointer|client') { 'driver_abort' } elseif ($reason -match 'script/parse/shader') { 'product_error' } else { 'verification_failure_requires_review' }
        [ordered]@{ok=$false;classification=$classification;error=$reason;launches=$launches;inputs=$inputEvents;owned_pid=$(if($null -ne $process){$process.Id}else{$null})} | ConvertTo-Json -Depth 6 | Set-Content -LiteralPath (Join-Path $smokeLogs 'failure.json') -Encoding UTF8
    }
    throw
} finally {
    if ($null -ne $process) {
        if (-not $process.HasExited) { $process.Kill(); $null = $process.WaitForExit(5000) }
        $process.Dispose()
    }
    $env:APPDATA = $oldAppData
    $env:LOCALAPPDATA = $oldLocalAppData
}
