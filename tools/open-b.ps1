# Opens only the "version B" Chrome window (DevTools on Network) in mode hang,
# for retaking b-row6.png by hand. Captures nothing.
$ErrorActionPreference = 'Stop'
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1
$prefs = @'
{"browser":{"has_seen_welcome_page":true},
 "devtools":{"preferences":{
   "currentDockState":"\"bottom\"","current-dock-state":"\"bottom\"",
   "panel-selectedTab":"\"network\"","panel-selected-tab":"\"network\"",
   "cacheDisabled":"true","cache-disabled":"true",
   "help.show-release-note":"false","releaseNoteVersionSeen":"999","release-note-version-seen":"999",
   "InspectorView.splitViewState":"{\"vertical\":{\"size\":0},\"horizontal\":{\"size\":470}}",
   "inspector-view.split-view-state":"{\"vertical\":{\"size\":0},\"horizontal\":{\"size\":470}}"
 }}}
'@
$dir = Join-Path $env:TEMP 'ia3-user-b'
if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
New-Item -ItemType Directory -Force (Join-Path $dir 'Default') | Out-Null
[IO.File]::WriteAllText((Join-Path $dir 'Default\Preferences'), $prefs)
Invoke-RestMethod -Method Post -Uri 'http://localhost:5050/__mode' -ContentType 'application/json' -Body '{"mode":"hang"}' | Out-Null
Start-Process $chrome -ArgumentList @("--user-data-dir=$dir", '--no-first-run', '--no-default-browser-check',
  '--auto-open-devtools-for-tabs', '--window-position=0,0', '--window-size=1500,960', 'http://localhost:5050/?v=b') | Out-Null
Write-Host 'Chrome "version B" is open; server mode = hang.'
