# Sync local ccstatusline TUI edits back into this dotfiles repo.
#
# Usage:
#   pwsh -File ~/dotfiles/ccstatusline/sync-back.ps1            # just copy + show diff
#   pwsh -File ~/dotfiles/ccstatusline/sync-back.ps1 -Push      # copy + commit + push

param([switch]$Push)

$ErrorActionPreference = 'Stop'

$src  = "$env:USERPROFILE\.config\ccstatusline\settings.json"
$dest = Join-Path $PSScriptRoot 'settings.json'

if (-not (Test-Path $src)) {
  Write-Error "Source not found: $src"
  exit 1
}

$srcText  = Get-Content $src -Raw
$destText = if (Test-Path $dest) { Get-Content $dest -Raw } else { '' }

if ($srcText -eq $destText) {
  Write-Host "No changes — local settings already match dotfiles."
  exit 0
}

Copy-Item -Force $src $dest
Write-Host "COPIED  $src  ->  $dest`n"

# Show what's different from HEAD
$repoRoot = Split-Path $PSScriptRoot -Parent
Push-Location $repoRoot
try {
  git --no-pager diff -- ccstatusline/settings.json
  Write-Host ""

  if ($Push) {
    git add ccstatusline/settings.json
    git commit -m "tweak(ccstatusline): sync TUI changes"
    git push
  } else {
    Write-Host "Re-run with -Push to commit + push, or do it manually:" -ForegroundColor Yellow
    Write-Host "  git add ccstatusline/settings.json"                    -ForegroundColor Yellow
    Write-Host "  git commit -m 'tweak(ccstatusline): sync TUI changes'" -ForegroundColor Yellow
    Write-Host "  git push"                                              -ForegroundColor Yellow
  }
} finally {
  Pop-Location
}
