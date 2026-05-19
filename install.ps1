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
@'
# Bootstrap: load real pwsh profile from dotfiles repo.
. "$env:USERPROFILE\dotfiles\pwsh\profile.ps1"
'@ | Set-Content -Encoding UTF8 $profilePath
Write-Host "STUB  $profilePath  ->  dotfiles/pwsh/profile.ps1"

Write-Host ""
Write-Host "Done. Open a fresh WezTerm / pwsh window to see the new prompt."
