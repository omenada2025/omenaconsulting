# Apply pending Supabase migrations through the SQL Editor.
# Safe to run multiple times.

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$migrations = @(
  "supabase\migrations\20260821150000_training_lifecycle.sql",
  "supabase\migrations\20260824150000_governance_artifact_types.sql",
  "supabase\migrations\20261019120000_live_support_pm_roles.sql",
  "supabase\migrations\20261020180000_factory_cycle_fields.sql"
)
$projectRef = "vwvmfuktrkpzrzlklbkr"
$sqlEditorUrl = "https://supabase.com/dashboard/project/$projectRef/sql/new"

$sqlParts = @()
foreach ($relativePath in $migrations) {
  $path = Join-Path $root $relativePath
  if (-not (Test-Path $path)) {
    throw "Migration file not found: $path"
  }
  $sqlParts += "-- $relativePath"
  $sqlParts += (Get-Content $path -Raw).Trim()
  $sqlParts += ""
}

$sql = ($sqlParts -join "`r`n`r`n")

Write-Host ""
Write-Host "Pending Supabase migrations"
Write-Host "Project: $projectRef"
Write-Host "Files:"
foreach ($relativePath in $migrations) { Write-Host "  - $relativePath" }
Write-Host ""
Write-Host "Steps:"
Write-Host "1. Open Supabase SQL Editor:"
Write-Host "   $sqlEditorUrl"
Write-Host "2. Paste the combined SQL below."
Write-Host "3. Click Run."
Write-Host "4. Refresh the dashboard."
Write-Host ""

try {
  Set-Clipboard -Value $sql
  Write-Host "Combined migration SQL copied to clipboard."
} catch {
  Write-Host "Could not copy to clipboard. Open the migration files manually."
}

Write-Host ""
Write-Host "----- SQL START -----"
Write-Host $sql
Write-Host "----- SQL END -----"
Write-Host ""

try {
  Start-Process $sqlEditorUrl | Out-Null
  Write-Host "Opened Supabase SQL Editor in your browser."
} catch {
  Write-Host "Open the SQL Editor manually: $sqlEditorUrl"
}
