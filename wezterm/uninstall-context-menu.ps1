# Remove "Open in WezTerm" right-click menu entries.

$ErrorActionPreference = 'SilentlyContinue'
$key = "WezTerm"
$roots = @(
  "HKCU:\Software\Classes\Directory\shell\$key",
  "HKCU:\Software\Classes\Directory\Background\shell\$key",
  "HKCU:\Software\Classes\Drive\shell\$key"
)
foreach ($root in $roots) {
  if (Test-Path $root) {
    Remove-Item -Path $root -Recurse -Force
    Write-Host "REMOVED  $root"
  }
}
