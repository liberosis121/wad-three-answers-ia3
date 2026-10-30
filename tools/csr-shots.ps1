# The four CSR vs SSR screenshots, one after another (server must be running).
$s = Join-Path (Split-Path -Parent $MyInvocation.MyCommand.Path) 'shot.ps1'
& $s -Path '/ssr' -Mode normal -Wait 3 -Out csr-requests-ssr.png
& $s -Version c -Mode normal -Wait 3 -Out csr-requests-c.png
& $s -Path '/ssr' -Mode normal -Wait 3 -Out csr-nojs-ssr.png -NoJs
& $s -Version c -Mode normal -Wait 3 -Out csr-nojs-c.png -NoJs
Write-Host 'all four done'
