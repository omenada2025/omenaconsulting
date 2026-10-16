# Add Cloudflare Pages secrets to GitHub and verify deploy.
# Run in a normal PowerShell window (interactive):
#   .\scripts\setup-cloudflare-secrets.ps1
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
Set-Location $root

Write-Host ""
Write-Host "Cloudflare → GitHub Actions setup"
Write-Host "1) Create an API token: Cloudflare → My Profile → API Tokens"
Write-Host "   Template: Edit Cloudflare Workers (or custom with Account · Cloudflare Pages · Edit)"
Write-Host "2) Account ID: Workers & Pages overview (right sidebar) or any domain overview"
Write-Host ""

Start-Process "https://dash.cloudflare.com/profile/api-tokens" | Out-Null
Start-Process "https://dash.cloudflare.com/?to=/:account/workers-and-pages" | Out-Null
Start-Process "https://github.com/omenada2025/omenaconsulting/settings/secrets/actions" | Out-Null

$accountId = Read-Host "Paste CLOUDFLARE_ACCOUNT_ID"
$token = Read-Host "Paste CLOUDFLARE_API_TOKEN"
if (-not $accountId -or -not $token) { throw "Both values are required." }

$accountId | gh secret set CLOUDFLARE_ACCOUNT_ID -R omenada2025/omenaconsulting
$token | gh secret set CLOUDFLARE_API_TOKEN -R omenada2025/omenaconsulting

Write-Host ""
Write-Host "Secrets saved. Listing secret names:"
gh secret list -R omenada2025/omenaconsulting

Write-Host ""
Write-Host "Triggering Cloudflare Pages deploy workflow..."
gh workflow run "Deploy to Cloudflare Pages" -R omenada2025/omenaconsulting
Start-Sleep -Seconds 3
gh run list -R omenada2025/omenaconsulting -L 3

Write-Host ""
Write-Host "When green, site will be at: https://omenaconsulting.pages.dev/"
Write-Host "(Exact subdomain is shown in the workflow log / Cloudflare dashboard.)"
