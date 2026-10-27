param(
  [Parameter(Mandatory = $true)][ValidateSet('Check', 'Register')][string]$Action,
  [Parameter(Mandatory = $true)][string]$ManifestPath,
  [string]$GmailMessageId = ''
)
$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
$manifest = Get-Content -Raw -LiteralPath $ManifestPath | ConvertFrom-Json
if ($manifest.reportingWeek -notmatch '^\d{4}-\d{2}-\d{2}$') { throw 'Invalid reporting week.' }
if ($manifest.senderEmail -ne 'rdaniglad@gmail.com') { throw 'Unexpected sender.' }
$config = Get-Content -Raw -LiteralPath (Join-Path $root 'supabase-config.js')
$url = [regex]::Match($config, 'url:\s*"([^"]+)"').Groups[1].Value
$key = [regex]::Match($config, 'anonKey:\s*"([^"]+)"').Groups[1].Value
$headers = @{ apikey = $key; Authorization = "Bearer $key" }
$historyUrl = "$url/rest/v1/weekly_review_sends?select=owner,email,status&filter_week=eq.$($manifest.reportingWeek)&status=eq.sent&limit=5000"
function Read-History {
  for ($attempt = 1; $attempt -le 3; $attempt++) {
    try {
      $rows = Invoke-RestMethod -Uri $historyUrl -Headers $headers -TimeoutSec 30
      # Invoke-RestMethod can emit the JSON array as one pipeline object.
      # Emit individual rows so email/owner comparisons never see an entire array.
      foreach ($row in $rows) { Write-Output $row }
      return
    }
    catch {
      if ($attempt -eq 3) { throw }
      Start-Sleep -Seconds (2 * $attempt)
    }
  }
}
$history = @(Read-History)
$existing = @($history | Where-Object {
  ([string]$_.email).Trim() -ieq ([string]$manifest.email).Trim() -or
  ([string]$_.owner).Trim() -ieq ([string]$manifest.owner).Trim()
})
if ($Action -eq 'Check') {
  @{ owner = $manifest.owner; email = $manifest.email; alreadySent = ($existing.Count -gt 0) } | ConvertTo-Json -Compress
  exit 0
}
if ($GmailMessageId -notmatch '^[a-zA-Z0-9_-]+$') { throw 'A confirmed Gmail message ID is required.' }
$auditPath = Join-Path (Split-Path -Parent $ManifestPath) ((Split-Path -LeafBase $ManifestPath) + '.gmail-delivery.json')
$record = @{
  batch_id = $manifest.batchId
  owner = $manifest.owner
  email = $manifest.email
  filter_product = 'all'
  filter_week = $manifest.reportingWeek
  filter_role = 'all'
  period_label = $manifest.reportingWeek
  report_count = $manifest.reportCount
  action_count = $manifest.actionCount
  feedback_tone = 'green'
  subject = $manifest.subject
  message_preview = $manifest.message.Substring(0, [Math]::Min(1200, $manifest.message.Length))
  status = 'sent'
  error_message = ''
  sent_by_username = 'automation'
  sent_by_name = 'Weekly feedback automation'
  sent_by_role = 'Role Manager'
  created_at = [datetime]::UtcNow.ToString('o')
}
$audit = @{ gmailMessageId = $GmailMessageId; owner = $manifest.owner; email = $manifest.email; registered = $false; record = $record }
$audit | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $auditPath -Encoding utf8
if ($existing.Count -eq 0) {
  try {
    $body = $record | ConvertTo-Json -Depth 8
    Invoke-RestMethod -Uri "$url/rest/v1/weekly_review_sends" -Headers ($headers + @{ Prefer = 'return=minimal' }) -Method Post -ContentType 'application/json; charset=utf-8' -Body ([Text.Encoding]::UTF8.GetBytes($body)) -TimeoutSec 30 | Out-Null
  } catch {
    # An interrupted POST may already have succeeded. Read back before reporting failure.
    $reconciled = @(Read-History | Where-Object { ([string]$_.email).Trim() -ieq ([string]$manifest.email).Trim() })
    if ($reconciled.Count -eq 0) { throw "Gmail sent ID $GmailMessageId, but history registration failed. Reconcile using $auditPath; do not resend." }
  }
}
$audit.registered = $true
$audit | ConvertTo-Json -Depth 8 | Set-Content -LiteralPath $auditPath -Encoding utf8
@{ owner = $manifest.owner; gmailMessageId = $GmailMessageId; registered = $true } | ConvertTo-Json -Compress
