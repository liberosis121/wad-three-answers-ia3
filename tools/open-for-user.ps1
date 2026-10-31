# Opens the three things the student photographs by hand, on the ORIGINAL code
# (server started from session5-starter-extracted on :5050):
#   1. Chrome window "version A" — mode normal, DevTools on Network, Disable cache
#   2. Chrome window "version B" — mode hang, same DevTools
#   3. VS Code on the starter copy, b.js with // @ts-check added as line 1
# Nothing is captured here; the student takes the screenshots.
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$starter = Join-Path $root 'session5-starter-extracted\session5-starter'
$chrome = @("$env:ProgramFiles\Google\Chrome\Application\chrome.exe", "${env:ProgramFiles(x86)}\Google\Chrome\Application\chrome.exe",
  "$env:LOCALAPPDATA\Google\Chrome\Application\chrome.exe") | Where-Object { Test-Path $_ } | Select-Object -First 1

$prefs = @'
{"browser":{"has_seen_welcome_page":true},
 "devtools":{"preferences":{
   "currentDockState":"\"bottom\"","current-dock-state":"\"bottom\"",
   "panel-selectedTab":"\"network\"","panel-selected-tab":"\"network\"",
   "cacheDisabled":"true","cache-disabled":"true",
   "help.show-release-note":"false","releaseNoteVersionSeen":"999","release-note-version-seen":"999",
   "InspectorView.splitViewState":"{\"vertical\":{\"size\":0},\"horizontal\":{\"size\":430}}",
   "inspector-view.split-view-state":"{\"vertical\":{\"size\":0},\"horizontal\":{\"size\":430}}"
 }}}
'@
function Open-Chrome($name, $url, $x) {
  $dir = Join-Path $env:TEMP "ia3-user-$name"
  if (Test-Path $dir) { Remove-Item -Recurse -Force $dir }
  New-Item -ItemType Directory -Force (Join-Path $dir 'Default') | Out-Null
  [IO.File]::WriteAllText((Join-Path $dir 'Default\Preferences'), $prefs)
  Start-Process $chrome -ArgumentList @("--user-data-dir=$dir", '--no-first-run', '--no-default-browser-check',
    '--auto-open-devtools-for-tabs', "--window-position=$x,0", '--window-size=1500,960', $url) | Out-Null
}
function Set-Mode($m) {
  Invoke-RestMethod -Method Post -Uri 'http://localhost:5050/__mode' -ContentType 'application/json' -Body ('{"mode":"' + $m + '"}') | Out-Null
}

Set-Mode 'normal'
Open-Chrome 'a' 'http://localhost:5050/?v=a' 0
Start-Sleep -Seconds 6          # A is loaded and has its 0 đ before B switches the mode
Set-Mode 'hang'
Open-Chrome 'b' 'http://localhost:5050/?v=b' 40
Write-Host 'Chrome A (normal) and Chrome B (hang) are open.'

$bjs = Join-Path $starter 'public\versions\b.js'
$text = [IO.File]::ReadAllText($bjs)
if (-not $text.StartsWith('// @ts-check')) { [IO.File]::WriteAllText($bjs, "// @ts-check`n" + $text) }
& code -n "$starter" -g "${bjs}:17:51"
Write-Host 'VS Code opened on the starter copy with // @ts-check on line 1 of b.js.'
