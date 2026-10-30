# Row 8 evidence: adds `// @ts-check` as line 1 of session5/public/versions/b.js,
# opens a real PowerShell console that prints the file head and runs tsc,
# screenshots that console window, then restores b.js with `git checkout`.
$ErrorActionPreference = 'Stop'
$tools = Split-Path -Parent $MyInvocation.MyCommand.Path
$repo = Join-Path (Split-Path -Parent $tools) 'session5'
$file = Join-Path $repo 'public\versions\b.js'
$done = Join-Path $env:TEMP 'ia3-row8-done'
if (Test-Path $done) { Remove-Item $done }

Add-Type -AssemblyName System.Drawing
Add-Type @'
using System;
using System.Runtime.InteropServices;
public static class Win8 {
  [StructLayout(LayoutKind.Sequential)] public struct RECT { public int L, T, R, B; }
  [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
  [DllImport("user32.dll")] public static extern bool PrintWindow(IntPtr h, IntPtr dc, uint flags);
  [DllImport("user32.dll")] public static extern bool SetForegroundWindow(IntPtr h);
  [DllImport("user32.dll")] public static extern bool SetProcessDPIAware();
}
'@
[Win8]::SetProcessDPIAware() | Out-Null

# Add the line exactly as the README says (keep the file's LF line endings).
$text = [IO.File]::ReadAllText($file)
[IO.File]::WriteAllText($file, "// @ts-check`n" + $text)

try {
  $p = Start-Process conhost.exe -ArgumentList "powershell.exe -NoExit -NoProfile -ExecutionPolicy Bypass -File `"$tools\row8-run.ps1`"" -PassThru
  $deadline = (Get-Date).AddSeconds(90)
  while (-not (Test-Path $done) -and (Get-Date) -lt $deadline) { Start-Sleep -Milliseconds 300 }
  Start-Sleep -Milliseconds 800
  # The window belongs to the inner powershell.exe, not to conhost.exe.
  $inner = Get-Process powershell | Where-Object { $_.MainWindowTitle -like 'Row 8 - tsc*' } | Select-Object -First 1
  if (-not $inner) { throw 'console window not found' }
  $h = $inner.MainWindowHandle
  [Win8]::SetForegroundWindow($h) | Out-Null
  Start-Sleep -Milliseconds 400
  $r = New-Object Win8+RECT
  [Win8]::GetWindowRect($h, [ref]$r) | Out-Null
  $w = $r.R - $r.L; $hgt = $r.B - $r.T
  $bmp = New-Object System.Drawing.Bitmap $w, $hgt
  $g = [System.Drawing.Graphics]::FromImage($bmp)
  $dc = $g.GetHdc()
  [Win8]::PrintWindow($h, $dc, 2) | Out-Null
  $g.ReleaseHdc($dc); $g.Dispose()
  $out = Join-Path $repo 'evidence\b-row8.png'
  $bmp.Save($out, [System.Drawing.Imaging.ImageFormat]::Png); $bmp.Dispose()
  Write-Host "saved $out ($w x $hgt)"
  Stop-Process -Id $inner.Id -Force
  Get-Process -Id $p.Id -ErrorAction SilentlyContinue | Stop-Process -Force
} finally {
  git -C $repo checkout -- public/versions/b.js
  Write-Host 'b.js restored:'; git -C $repo status --short
}
