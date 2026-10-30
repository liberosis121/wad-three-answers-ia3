# View page source (what Ctrl+U opens) of both pages, for CSR vs SSR question 1.
# DevTools stays open at its usual height: with it closed or short, PrintWindow captured a blank page.
$s = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'shot.ps1'
& $s -Path 'view-source:http://localhost:5050/?v=c' -Mode normal -Wait 6 -Out csr-source-c.png
& $s -Path 'view-source:http://localhost:5050/ssr' -Mode normal -Wait 6 -Out csr-source-ssr.png
Write-Host 'both done'
