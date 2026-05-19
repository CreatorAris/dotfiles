# Symlink dotfiles into %USERPROFILE%.
# Needs either an elevated shell OR Windows Developer Mode enabled
# (Settings > For developers > Developer Mode).

$ErrorActionPreference = 'Stop'
$repo = $PSScriptRoot

$links = @{
  "$env:USERPROFILE\.wezterm.lua" = "$repo\wezterm\wezterm.lua"
}

foreach ($target in $links.Keys) {
  $source = $links[$target]
  if (-not (Test-Path $source)) {
    Write-Warning "Source missing: $source"
    continue
  }
  if (Test-Path $target) {
    $existing = Get-Item $target -Force
    if ($existing.LinkType -eq 'SymbolicLink' -and $existing.Target -contains $source) {
      Write-Host "OK  $target -> $source"
      continue
    }
    Write-Host "Backup existing $target -> $target.bak"
    Move-Item -Force $target "$target.bak"
  }
  New-Item -ItemType SymbolicLink -Path $target -Target $source | Out-Null
  Write-Host "LINK  $target -> $source"
}
