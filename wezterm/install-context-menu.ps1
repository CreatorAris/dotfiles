# Add "Open in WezTerm" to the Windows right-click menu.
# HKCU only — no admin required.
#
# Three entry points:
#   1. Right-click on a folder         (Directory\shell)
#   2. Right-click on a folder's blank space   (Directory\Background\shell)
#   3. Right-click on a drive               (Drive\shell)
#
# Re-run safely; uses -Force on every write.

$ErrorActionPreference = 'Stop'

$exe = "C:\Program Files\WezTerm\wezterm-gui.exe"
if (-not (Test-Path $exe)) {
  Write-Error "wezterm-gui.exe not found at $exe — install WezTerm first."
  exit 1
}

$label   = "在 WezTerm 中打开"
$key     = "WezTerm"
$command = "`"$exe`" start --cwd `"%V`""

$roots = @(
  "HKCU:\Software\Classes\Directory\shell\$key",
  "HKCU:\Software\Classes\Directory\Background\shell\$key",
  "HKCU:\Software\Classes\Drive\shell\$key"
)

foreach ($root in $roots) {
  New-Item -Path $root -Force | Out-Null
  Set-ItemProperty -Path $root -Name '(default)' -Value $label
  Set-ItemProperty -Path $root -Name 'Icon'      -Value $exe

  $cmdKey = "$root\command"
  New-Item -Path $cmdKey -Force | Out-Null
  Set-ItemProperty -Path $cmdKey -Name '(default)' -Value $command

  Write-Host "OK  $root"
}

Write-Host ""
Write-Host "Done. Right-click any folder / blank space / drive to see `"$label`"."
Write-Host "To uninstall, run uninstall-context-menu.ps1 or delete the three keys above."
