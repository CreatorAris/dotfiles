# Bootstrap CreatorAris's terminal stack on a fresh Windows machine.
#
# One-shot install:
#   irm https://raw.githubusercontent.com/CreatorAris/dotfiles/main/bootstrap.ps1 | iex
#
# Prereqs: pwsh 7+ and git in PATH. Both come pre-installed on most dev machines.
# If missing:
#   winget install Microsoft.PowerShell Git.Git
#   # then close & reopen pwsh and re-run the irm | iex above
#
# Idempotent — safe to re-run; skips anything already installed.

$ErrorActionPreference = 'Stop'
$ProgressPreference    = 'SilentlyContinue'

function Step($msg) { Write-Host "`n==> $msg" -ForegroundColor Cyan }
function Ok($msg)   { Write-Host "    $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }

# ------------------------------------------------------------------
# 1. winget apps
# ------------------------------------------------------------------
Step "Installing apps via winget..."
$pkgs = @(
    'wez.wezterm',
    'Starship.Starship',
    'ajeetdsouza.zoxide',
    'junegunn.fzf',
    'eza-community.eza'
)
foreach ($p in $pkgs) {
    $check = winget list --id $p -e 2>$null
    if ($LASTEXITCODE -eq 0 -and $check -match $p) {
        Ok "already installed: $p"
    } else {
        winget install --id $p -e --silent --accept-package-agreements --accept-source-agreements | Out-Null
        Ok "installed: $p"
    }
}

# ------------------------------------------------------------------
# 2. PSGallery modules
# ------------------------------------------------------------------
Step "Installing PowerShell modules..."
foreach ($m in 'Terminal-Icons','PSFzf') {
    if (Get-Module -ListAvailable -Name $m) {
        Ok "already installed: $m"
    } else {
        Install-Module $m -Scope CurrentUser -Force -AllowClobber
        Ok "installed: $m"
    }
}

# ------------------------------------------------------------------
# 3. Clone or pull dotfiles
# ------------------------------------------------------------------
Step "Syncing dotfiles repo..."
$repo = "$env:USERPROFILE\dotfiles"
if (-not (Test-Path $repo)) {
    git clone https://github.com/CreatorAris/dotfiles.git $repo
} else {
    Ok "already at $repo, pulling latest..."
    git -C $repo pull --ff-only
}

# ------------------------------------------------------------------
# 4. Maple Mono NF CN font (user-level, no admin)
# ------------------------------------------------------------------
Step "Installing Maple Mono NF CN font..."
$regKey   = "HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Fonts"
$existing = (Get-ItemProperty $regKey -ErrorAction SilentlyContinue).PSObject.Properties |
    Where-Object { $_.Name -like "MapleMono-NF-CN-*" }
if ($existing.Count -ge 16) {
    Ok "already installed ($($existing.Count) faces)"
} else {
    $rel = Invoke-RestMethod 'https://api.github.com/repos/subframe7536/maple-font/releases/latest'
    $asset = $rel.assets | Where-Object name -eq 'MapleMono-NF-CN.zip' | Select-Object -First 1
    if (-not $asset) { throw "Could not find MapleMono-NF-CN.zip in latest release" }
    $tmpDir = "$env:TEMP\maple-nf-cn-bootstrap"
    if (Test-Path $tmpDir) { Remove-Item $tmpDir -Recurse -Force }
    New-Item -ItemType Directory -Force -Path $tmpDir | Out-Null
    Ok "downloading $($asset.name) ($([math]::Round($asset.size/1MB,1)) MB)..."
    Invoke-WebRequest $asset.browser_download_url -OutFile "$tmpDir\font.zip" -UseBasicParsing
    Expand-Archive "$tmpDir\font.zip" -DestinationPath $tmpDir -Force
    $destDir = "$env:LOCALAPPDATA\Microsoft\Windows\Fonts"
    New-Item -ItemType Directory -Force -Path $destDir | Out-Null
    if (-not (Test-Path $regKey)) { New-Item -Path $regKey -Force | Out-Null }
    $count = 0
    Get-ChildItem $tmpDir -Recurse -Filter "MapleMono-NF-CN-*.ttf" | ForEach-Object {
        $dest = Join-Path $destDir $_.Name
        Copy-Item -Force $_.FullName $dest
        New-ItemProperty -Path $regKey -Name "$($_.BaseName) (TrueType)" -Value $dest -PropertyType String -Force | Out-Null
        $count++
    }
    Ok "installed $count font faces"
}

# ------------------------------------------------------------------
# 5. Config stubs (.wezterm.lua + $PROFILE)
# ------------------------------------------------------------------
Step "Installing config stubs..."
& "$repo\install.ps1"

# ------------------------------------------------------------------
# 6. 'Open in WezTerm' right-click menu
# ------------------------------------------------------------------
Step "Installing 'Open in WezTerm' right-click menu..."
& "$repo\wezterm\install-context-menu.ps1"

# ------------------------------------------------------------------
# Done
# ------------------------------------------------------------------
Write-Host "`n[Done]" -ForegroundColor Green
Write-Host "Launch WezTerm: Win key -> 'wezterm', or 'wezterm' from Win+R" -ForegroundColor Green
Write-Host "Background image at ~/dotfiles/wezterm/assets/background.png — replace via regen-background.ps1" -ForegroundColor DarkGray
Write-Host "Win11 right-click 'Open in WezTerm' lives under Shift+right-click or 'Show more options'" -ForegroundColor DarkGray
