# Deploy the dashboard live to GitHub Pages (push main → automatic Pages build).
# Usage:
#   .\scripts\deploy-live.ps1
#   .\scripts\deploy-live.ps1 -Message "Fix Home sync banner"
#   .\scripts\deploy-live.ps1 -PushOnly
param(
  [string]$Message = "",
  [switch]$PushOnly
)

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host ""
Write-Host "Omena Consulting — deploy live"
Write-Host "Live URL: https://omenada2025.github.io/omenaconsulting/"
Write-Host ""

git status -sb
$dirty = git status --porcelain
if ($PushOnly) {
  if ($dirty) {
    throw "Working tree has uncommitted changes. Commit first, or run without -PushOnly and pass -Message."
  }
} elseif ($dirty) {
  if (-not $Message) {
    $Message = Read-Host "Commit message (required to deploy local changes)"
  }
  if (-not $Message) { throw "Commit message is required." }
  git add -A
  # Keep local-only / generated dumps out of deploy if present
  git reset HEAD -- artifacts/ 2>$null
  git status -sb
  git commit -m $Message
} else {
  Write-Host "No local changes to commit."
}

$branch = (git rev-parse --abbrev-ref HEAD).Trim()
if ($branch -ne "main") {
  throw "You are on '$branch'. Switch to main (or merge) before live deploy."
}

Write-Host "Pushing to origin/main..."
git push -u origin HEAD

Write-Host ""
Write-Host "GitHub Actions will publish Pages in ~30–60 seconds."
Write-Host "Dashboard: https://omenada2025.github.io/omenaconsulting/"
Write-Host "Team guide: https://omenada2025.github.io/omenaconsulting/guide-factory-dashboard-changes.html"
Write-Host "Actions:    https://github.com/omenada2025/omenaconsulting/actions"
Write-Host ""
Write-Host "Tip: hard-refresh (Ctrl+F5) after deploy if the browser shows an old build."
