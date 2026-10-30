# Row 8 as the README describes it: VS Code, the session5 FOLDER open (so it
# reads jsconfig.json), `// @ts-check` as line 1 of public/versions/b.js, the
# red underline and the Problems panel. Uses a SEPARATE VS Code instance (own
# throwaway user-data and extensions dirs) so the user's open VS Code is never
# touched, photographs that window, closes only that instance, and writes b.js
# back byte for byte.
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Join-Path (Split-Path -Parent $tools) 'session5'
$file = Join-Path $repo 'public\versions\b.js'
$out = Join-Path $repo 'evidence\b-row8.png'
$codeExe = "$env:LOCALAPPDATA\Programs\Microsoft VS Code\Code.exe"

Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class WinV {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern IntPtr GetForegroundWindow();
  [DllImport("user32.dll")] public static extern bool MoveWindow(IntPtr h, int x, int y, int w, int hh, bool r);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
[WinV]::SetProcessDPIAware() | Out-Null

$data = Join-Path $env:TEMP 'ia3-vscode-data'
$ext = Join-Path $env:TEMP 'ia3-vscode-ext'
foreach ($d in $data, $ext) { if (Test-Path $d) { Remove-Item -Recurse -Force $d } }
New-Item -ItemType Directory -Force (Join-Path $data 'User'), $ext | Out-Null
@'
{
  "workbench.startupEditor": "none",
  "window.restoreWindows": "none",
  "security.workspace.trust.enabled": false,
  "workbench.tips.enabled": false,
  "update.mode": "none",
  "telemetry.telemetryLevel": "off",
  "editor.minimap.enabled": false,
  "chat.commandCenter.enabled": false,
  "workbench.secondarySideBar.defaultVisibility": "hidden"
}
'@ | ForEach-Object { [IO.File]::WriteAllText((Join-Path $data 'User\settings.json'), $_) }

$original = [IO.File]::ReadAllBytes($file)
$text = [Text.Encoding]::UTF8.GetString($original)
[IO.File]::WriteAllText($file, "// @ts-check`n" + $text)
try {
  Start-Process -FilePath $codeExe -ArgumentList @(
    '--user-data-dir', "`"$data`"", '--extensions-dir', "`"$ext`"", '--new-window',
    "`"$repo`"", '--goto', "`"$file`":17:51") | Out-Null
  Start-Sleep -Seconds 15   # let the TypeScript server check the file

  $mine = Get-CimInstance Win32_Process -Filter "Name='Code.exe'" | Where-Object { $_.CommandLine -like "*ia3-vscode-data*" }
  $win = Get-Process -Id ($mine.ProcessId) -ErrorAction SilentlyContinue | Where-Object { $_.MainWindowHandle -ne 0 } | Select-Object -First 1
  if (-not $win) { throw 'VS Code window not found' }
  $h = $win.MainWindowHandle
  [WinV]::MoveWindow($h, 0, 0, 1600, 1000, $true) | Out-Null
  [WinV]::SetForegroundWindow($h) | Out-Null
  Start-Sleep -Milliseconds 800
  if ([WinV]::GetForegroundWindow() -eq $h) {
    [System.Windows.Forms.SendKeys]::SendWait('^+m')   # View > Problems
    Start-Sleep -Seconds 2
  } else { Write-Host 'VS Code not in front: Problems panel not opened' }

  $r = New-Object WinV+RECT
  [WinV]::GetWindowRect($h, [ref]$r) | Out-Null
  $w = $r.R - $r.L; $hgt = $r.B - $r.T
  $bmp = New-Object System.Drawing.Bitmap $w, $hgt
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $dc = $g.GetHdc()
  [WinV]::PrintWindow($h, $dc, 2) | Out-Null
  $g.ReleaseHdc($dc); $g.Dispose()
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
  Write-Host "saved $out ($w x $hgt)"
} finally {
  Get-CimInstance Win32_Process -Filter "Name='Code.exe'" | Where-Object { $_.CommandLine -like "*ia3-vscode-data*" } |
    ForEach-Object { Stop-Process -Id $_.ProcessId -Force -ErrorAction SilentlyContinue }
  Start-Sleep -Seconds 1
  [IO.File]::WriteAllBytes($file, $original)
  Write-Host 'b.js written back:'; git -C $repo status --short
}
