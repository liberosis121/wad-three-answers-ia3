# Opens a SEPARATE Chrome (throwaway profile) with DevTools docked on the
# Network panel, loads http://localhost:5050/?v=<Version> under server mode
# <Mode>, waits <Wait> seconds, and saves a real screenshot of that window.
# Usage: & 'D:\HK7\WAD\IA\IA#3\tools\shot.ps1' -Version a -Mode normal -Wait 3 -Out a-row2.png
#        -Path '/ssr' loads that path instead of ?v=<Version>; -NoJs turns
#        JavaScript off in the throwaway profile (the CSR vs SSR question 3).
param(
  [string]$Version = '',
  [Parameter(Mandatory)][string]$Mode,
  [Parameter(Mandatory)][int]$Wait,
  [Parameter(Mandatory)][string]$Out,
  [string]$Path = '',
  [switch]$NoJs,
  [switch]$NoDevtools,
  [int]$DevtoolsHeight = 420,
  [int]$ScrollY = 0
)
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
$evidence = Join-Path (Split-Path -Parent $tools) 'session5\evidence'
New-Item -ItemType Directory -Force $evidence | Out-Null

Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
[Win]::SetProcessDPIAware() | Out-Null   # real pixel size of the window on a 125% display

$chrome = @(
  "$env:ProgramFiles\Google\Chrome\Application\chrome.exe",
  "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe"
) | Where-Object { Test-Path $_ } | Select-Object -First 1
if (-not $chrome) { throw 'chrome.exe not found' }

# Throwaway profile: DevTools docked at the bottom, Network panel, cache disabled.
$profileDir = Join-Path $env:TEMP 'ia3-chrome-shot'
if (Test-Path $profileDir) { Remove-Item -Recurse -Force $profileDir }
New-Item -ItemType Directory -Force (Join-Path $profileDir 'Default') | Out-Null
$prefs = @'
{"browser":{"has_seen_welcome_page":true},
 "devtools":{"preferences":{
   "currentDockState":"\"bottom\"","current-dock-state":"\"bottom\"",
   "panel-selectedTab":"\"network\"","panel-selected-tab":"\"network\"",
   "cacheDisabled":"true","cache-disabled":"true",
   "help.show-release-note":"false","releaseNoteVersionSeen":"999","release-note-version-seen":"999",
   "inspector.drawer-split-view-state":"{\"horizontal\":{\"size\":0,\"showMode\":\"OnlyMain\"}}",
   "InspectorView.splitViewState":"{\"vertical\":{\"size\":0},\"horizontal\":{\"size\":420}}",
   "inspector-view.split-view-state":"{\"vertical\":{\"size\":0},\"horizontal\":{\"size\":420}}"
 }}}
'@
$prefs = $prefs.Replace('\"size\":420', '\"size\":' + $DevtoolsHeight)
if ($NoJs) {
  # Content setting 2 = block: the same as Site settings -> JavaScript -> Don't allow.
  $prefs = $prefs.Replace('{"browser":', '{"profile":{"default_content_setting_values":{"javascript":2}},"browser":')
}
[IO.File]::WriteAllText((Join-Path $profileDir 'Default\Preferences'), $prefs)   # no BOM

Invoke-RestMethod -Method Post -Uri 'http://localhost:5050/__mode' -ContentType 'application/json' -Body ('{"mode":"' + $Mode + '"}') | Out-Null
Write-Host "server mode = $Mode"

$chromeArgs = @(
  "--user-data-dir=$profileDir", '--no-first-run', '--no-default-browser-check',
  '--remote-debugging-port=9333',
  '--window-position=0,0', '--window-size=1600,1000', '--force-device-scale-factor=1',
  'about:blank'
)
if (-not $NoDevtools) { $chromeArgs = @('--auto-open-devtools-for-tabs') + $chromeArgs }
$p = Start-Process -FilePath $chrome -ArgumentList $chromeArgs -PassThru
Start-Sleep -Seconds 5   # let the window and DevTools open before the page loads

$target = if ($Path -like 'view-source:*') { $Path } elseif ($Path) { "http://localhost:5050$Path" } else { "http://localhost:5050/?v=$Version" }
if ($ScrollY) { node (Join-Path $tools 'cdp-nav.mjs') 9333 $target $ScrollY } else { node (Join-Path $tools 'cdp-nav.mjs') 9333 $target }
Start-Sleep -Seconds $Wait

$p.Refresh()
$h = $p.MainWindowHandle
if ($h -eq [IntPtr]::Zero) { throw 'Chrome window not found' }
[Win]::SetForegroundWindow($h) | Out-Null
Start-Sleep -Milliseconds 400
$r = New-Object Win+RECT
[Win]::GetWindowRect($h, [ref]$r) | Out-Null
$w = $r.R - $r.L; $hgt = $r.B - $r.T
$bmp = New-Object System.Drawing.Bitmap $w, $hgt
$g = [System.Drawing.Graphics]::FromImage($bmp)
$dc = $g.GetHdc()
[Win]::PrintWindow($h, $dc, 2) | Out-Null   # PW_RENDERFULLCONTENT
$g.ReleaseHdc($dc); $g.Dispose()
$path = Join-Path $evidence $Out
$bmp.Save($path, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
Write-Host "saved $path ($w x $hgt)"

Stop-Process -Id $p.Id -Force
Invoke-RestMethod -Method Post -Uri 'http://localhost:5050/__mode' -ContentType 'application/json' -Body '{"mode":"normal"}' | Out-Null
Write-Host 'server mode = normal'
