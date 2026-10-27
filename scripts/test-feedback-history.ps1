$ErrorActionPreference = 'Stop'
$testRoot = Join-Path ([IO.Path]::GetTempPath()) ('feedback-history-test-' + [guid]::NewGuid().ToString('N'))
[void](New-Item -ItemType Directory -Path (Join-Path $testRoot 'scripts') -Force)
Copy-Item -LiteralPath (Join-Path $PSScriptRoot 'feedback-delivery-history.ps1') -Destination (Join-Path $testRoot 'scripts/history.ps1') -Force
Set-Content -LiteralPath (Join-Path $testRoot 'supabase-config.js') -Value 'url: "https://feedback-test.invalid", anonKey: "test-only"'
$manifestPath = Join-Path $testRoot 'Owner-2026-10-19.json'
$message = "Owner's update includes a smart apostrophe: it$([char]0x2019)s ready."
@{ owner='Owner';email='owner@example.test';senderEmail='rdaniglad@gmail.com';reportingWeek='2026-10-19';batchId='test';reportCount=1;actionCount=1;subject='Test feedback';message=$message } | ConvertTo-Json | Set-Content -LiteralPath $manifestPath -Encoding utf8
$global:FeedbackTestState=@{postCount=0;readCount=0;confirmed=$false;mode='register';message=$message}
function Start-Sleep { param($Seconds) }
function Invoke-RestMethod {
  param($Uri,$Headers,$Method='Get',$Body,$TimeoutSec,$ContentType)
  if ($Method -eq 'Post') {
    $global:FeedbackTestState.postCount++
    $payload=[Text.Encoding]::UTF8.GetString($Body) | ConvertFrom-Json
    if ($payload.message_preview -cne $global:FeedbackTestState.message) { throw 'Apostrophe/UTF-8 preservation failed' }
    $global:FeedbackTestState.confirmed=$true
    if ($global:FeedbackTestState.mode -eq 'lost-response') { throw 'Simulated response lost after database commit' }
    return
  }
  $global:FeedbackTestState.readCount++
  if ($global:FeedbackTestState.mode -eq 'read-failure') { throw 'Simulated unavailable history' }
  if ($global:FeedbackTestState.confirmed) { return ,@([pscustomobject]@{owner='Other';email='other@example.test';status='sent'},[pscustomobject]@{owner='Owner';email='OWNER@example.test';status='sent'}) }
  return @()
}
$helper=Join-Path $testRoot 'scripts/history.ps1'
$result=(& $helper -Action Register -ManifestPath $manifestPath -GmailMessageId testGmailId | ConvertFrom-Json)
if (-not $result.registered -or $global:FeedbackTestState.postCount -ne 1) { throw 'Registration failed' }
'PASS: registration preserves straight and smart apostrophes and UTF-8'
$check=(& $helper -Action Check -ManifestPath $manifestPath | ConvertFrom-Json)
if (-not $check.alreadySent) { throw 'Email case-insensitive duplicate check failed' }
$null=& $helper -Action Register -ManifestPath $manifestPath -GmailMessageId testGmailId
if ($global:FeedbackTestState.postCount -ne 1) { throw 'Duplicate POST created' }
'PASS: repeated registration does not create another send record'
$global:FeedbackTestState.confirmed=$false
$global:FeedbackTestState.mode='lost-response'
$result=(& $helper -Action Register -ManifestPath $manifestPath -GmailMessageId anotherGmailId | ConvertFrom-Json)
if (-not $result.registered -or $global:FeedbackTestState.postCount -ne 2) { throw 'Lost POST response was not reconciled safely' }
'PASS: uncertain database response is reconciled without retrying POST'
$global:FeedbackTestState.mode='read-failure'
$global:FeedbackTestState.readCount=0
$failed=$false
try { $null=& $helper -Action Check -ManifestPath $manifestPath } catch { $failed=$true }
if (-not $failed -or $global:FeedbackTestState.readCount -ne 3 -or $global:FeedbackTestState.postCount -ne 2) { throw 'History lookup must retry three times then fail closed' }
'PASS: failed history reads retry then stop without recording or sending'
