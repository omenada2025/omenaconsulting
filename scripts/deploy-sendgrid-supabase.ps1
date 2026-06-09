param(
  [string]$ProjectRef = "qjxdfqtzcrsopprcmicr",
  [string]$AllowedOrigin = "https://omenada2025.github.io",
  [string]$FromName = "Product & UI/UX Pulse"
)

$ErrorActionPreference = "Stop"

function Require-Command($Name) {
  $command = Get-Command $Name -ErrorAction SilentlyContinue
  if ($command) {
    return $command.Source
  }
  $localSupabase = Join-Path (Split-Path -Parent $PSScriptRoot) "tools\supabase\supabase.exe"
  if ($Name -eq "supabase" -and (Test-Path -LiteralPath $localSupabase)) {
    return $localSupabase
  }
  throw "$Name is required but was not found in PATH."
}

function Require-Env($Name) {
  $value = [Environment]::GetEnvironmentVariable($Name)
  if ([string]::IsNullOrWhiteSpace($value)) {
    throw "Missing environment variable $Name."
  }
  return $value
}

$supabase = Require-Command "supabase"

$sendgridKey = Require-Env "SENDGRID_API_KEY"
$fromEmail = Require-Env "SENDGRID_FROM_EMAIL"

Write-Host "Linking Supabase project $ProjectRef..."
& $supabase link --project-ref $ProjectRef

Write-Host "Setting SendGrid secrets..."
& $supabase secrets set "SENDGRID_API_KEY=$sendgridKey"
& $supabase secrets set "SENDGRID_FROM_EMAIL=$fromEmail"
& $supabase secrets set "SENDGRID_FROM_NAME=$FromName"
& $supabase secrets set "SENDGRID_ALLOWED_ORIGIN=$AllowedOrigin"

Write-Host "Deploying send-credentials Edge Function..."
& $supabase functions deploy send-credentials --project-ref $ProjectRef

Write-Host "Checking deployed endpoint..."
$endpoint = "https://$ProjectRef.supabase.co/functions/v1/send-credentials"
try {
  $response = Invoke-WebRequest -Uri $endpoint -Method Options -UseBasicParsing -TimeoutSec 20
  Write-Host "Endpoint responded with HTTP $($response.StatusCode): $endpoint"
} catch {
  if ($_.Exception.Response) {
    $status = [int]$_.Exception.Response.StatusCode
    throw "Endpoint check failed with HTTP ${status}: $endpoint"
  }
  throw
}

Write-Host "SendGrid email function setup complete."
