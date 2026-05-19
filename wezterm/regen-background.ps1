# Regenerate dotfiles/wezterm/assets/background.png from a source image,
# applying a Gaussian blur so it doesn't fight terminal text for attention.
#
# Usage:
#   ./regen-background.ps1 -Source "D:\path\to\image.png"
#   ./regen-background.ps1 -Source "..." -Sigma 25
#
# Sigma rule of thumb:
#   10  — subtle, can still read shapes
#   20  — color-block atmosphere (default)
#   30  — heavy, only palette + flow visible

param(
  [Parameter(Mandatory = $true)][string]$Source,
  [int]$Sigma = 20
)

$ErrorActionPreference = 'Stop'

if (-not (Test-Path -LiteralPath $Source)) {
  throw "Source image not found: $Source"
}

$dest = Join-Path $PSScriptRoot 'assets\background.png'
New-Item -ItemType Directory -Force -Path (Split-Path $dest) | Out-Null

$py = @"
from PIL import Image, ImageFilter
img = Image.open(r'''$Source''').convert('RGBA')
img.filter(ImageFilter.GaussianBlur(radius=$Sigma)).save(r'''$dest''', optimize=True)
print(f'blurred -> {r"""$dest"""}')
"@

python -c $py
Write-Host "Done. Reload WezTerm (Ctrl+Shift+R) or restart to apply."
