# Install dotfiles by dropping bootstrap stubs into $env:USERPROFILE.
# Stubs `dofile()` the real config from this repo — no admin / no Dev Mode needed.
# Re-run safely; existing stubs are overwritten.

$ErrorActionPreference = 'Stop'

# .wezterm.lua bootstrap
@'
-- Bootstrap: load real config from dotfiles repo.
local home = os.getenv('USERPROFILE') or os.getenv('HOME')
return dofile(home .. '/dotfiles/wezterm/wezterm.lua')
'@ | Set-Content -Encoding UTF8 "$env:USERPROFILE\.wezterm.lua"
Write-Host "STUB  $env:USERPROFILE\.wezterm.lua  ->  dotfiles/wezterm/wezterm.lua"

# Add more stubs here as the repo grows (starship.toml, pwsh profile, etc.)
