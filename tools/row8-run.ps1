# Runs INSIDE the console window that row8-shot.ps1 opens and photographs.
$ErrorActionPreference = 'Continue'
$Host.UI.RawUI.WindowTitle = 'Row 8 - tsc with // @ts-check on public/versions/b.js'
try {
  $Host.UI.RawUI.BufferSize = New-Object Management.Automation.Host.Size(150, 300)
  $Host.UI.RawUI.WindowSize = New-Object Management.Automation.Host.Size(150, 32)
} catch {}
Set-Location (Join-Path (Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)) 'session5')

[Console]::OutputEncoding = [Text.Encoding]::UTF8
Write-Host "PS $(Get-Location)> Get-Content -Encoding UTF8 public\versions\b.js -TotalCount 17   # line 1 = // @ts-check (added for row 8)" -ForegroundColor Yellow
$i = 0
Get-Content -Encoding UTF8 public\versions\b.js -TotalCount 17 | ForEach-Object { $i++; '{0,3}  {1}' -f $i, $_ }
Write-Host ''
Write-Host "PS $(Get-Location)> npx -y -p typescript@5.6.3 tsc --project jsconfig.json --noEmit --pretty" -ForegroundColor Yellow
& npx.cmd -y -p typescript@5.6.3 tsc --project jsconfig.json --noEmit --pretty
Write-Host "exit code: $LASTEXITCODE"
New-Item -ItemType File -Force (Join-Path $env:TEMP 'ia3-row8-done') | Out-Null
