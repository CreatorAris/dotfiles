# Install dotfiles by dropping bootstrap stubs at well-known config locations.
# Stubs `dofile()` / `dot-source` the real config from this repo —
# no admin / no Developer Mode / no symlinks required.
# Re-run safely; stubs are overwritten.

$ErrorActionPreference = 'Stop'

# -------------------------------------------------------------------
# 1. WezTerm — ~/.wezterm.lua bootstrap
# -------------------------------------------------------------------
@'
-- Bootstrap: load real config from dotfiles repo.
local home = os.getenv('USERPROFILE') or os.getenv('HOME')
return dofile(home .. '/dotfiles/wezterm/wezterm.lua')
'@ | Set-Content -Encoding UTF8 "$env:USERPROFILE\.wezterm.lua"
Write-Host "STUB  $env:USERPROFILE\.wezterm.lua  ->  dotfiles/wezterm/wezterm.lua"

# -------------------------------------------------------------------
# 2. pwsh profile — $PROFILE bootstrap
# -------------------------------------------------------------------
$profilePath = $PROFILE
$profileDir  = Split-Path -Parent $profilePath
if (-not (Test-Path $profileDir)) {
  New-Item -ItemType Directory -Force -Path $profileDir | Out-Null
}

# Backup any existing profile before overwriting (only if it's not already our stub).
if (Test-Path $profilePath) {
  $existing = Get-Content $profilePath -Raw -ErrorAction SilentlyContinue
  if ($existing -notmatch 'dotfiles[\\/]pwsh[\\/]profile\.ps1') {
    $backup = "$profilePath.bak.$(Get-Date -Format 'yyyyMMddHHmmss')"
    Copy-Item -Force $profilePath $backup
    Write-Host "BACKUP  $profilePath  ->  $backup"
  }
}

@'
# Bootstrap: load real pwsh profile from dotfiles repo.
. "$env:USERPROFILE\dotfiles\pwsh\profile.ps1"
'@ | Set-Content -Encoding UTF8 $profilePath
Write-Host "STUB  $profilePath  ->  dotfiles/pwsh/profile.ps1"

# -------------------------------------------------------------------
# 3. ccstatusline — config file is consumed directly by the tool (no stub
#    indirection like the others), so we copy it. After TUI edits via
#    `npx ccstatusline`, copy back to dotfiles manually + push.
# -------------------------------------------------------------------
$ccslSrc  = "$PSScriptRoot\ccstatusline\settings.json"
$ccslDest = "$env:USERPROFILE\.config\ccstatusline\settings.json"
if (Test-Path $ccslSrc) {
  New-Item -ItemType Directory -Force -Path (Split-Path $ccslDest) | Out-Null
  Copy-Item -Force $ccslSrc $ccslDest
  Write-Host "COPY  $ccslDest  <-  dotfiles/ccstatusline/settings.json"
}

Write-Host ""
Write-Host "Done. Open a fresh WezTerm / pwsh window to see the new prompt."
