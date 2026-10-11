param(
  [switch]$DryRun,
  [switch]$RecordOnly,
  [switch]$Force,
  [switch]$AllProductManagers,
  [switch]$AllOwners,
  [string]$Week = "",
  [string]$StartDate = "",
  [string]$EndDate = "",
  [string]$SenderEmail = "daniela@zenatech.com",
  [string]$Owner = "",
  [string]$PreviewDirectory = ""
)

$ErrorActionPreference = "Stop"
if ($PreviewDirectory -and -not $DryRun) { throw "PreviewDirectory requires -DryRun." }

function Get-ConfigValue {
  param([string]$Config, [string]$Name)
  $pattern = $Name + ':\s*"([^"]+)"'
  return [regex]::Match($Config, $pattern).Groups[1].Value
}

function Get-Field {
  param($Row, [string[]]$Names)
  foreach ($name in $Names) {
    if ($null -ne $Row.PSObject.Properties[$name]) {
      return [string]$Row.PSObject.Properties[$name].Value
    }
  }
  return ""
}

function Canonical {
  param([string]$Value)
  return (($Value -replace '\s+', ' ').Trim()).ToLowerInvariant()
}

function Is-Email {
  param([string]$Value)
  return $Value -match '^[^@\s]+@[^@\s]+\.[^@\s]+$'
}

function Average {
  param($Values)
  $numbers = @($Values | Where-Object { $_ -ne $null -and "$_" -ne "" } | ForEach-Object { [double]$_ })
  if ($numbers.Count -eq 0) { return 0 }
  return [math]::Round(($numbers | Measure-Object -Average).Average)
}

function Html {
  param([string]$Value)
  if ($null -eq $Value) { return "" }
  return [System.Net.WebUtility]::HtmlEncode($Value)
}

function Format-DateValue {
  param([string]$Value)
  if (-not $Value) { return "" }
  $parsed = [datetime]::MinValue
  if ([datetime]::TryParse($Value, [ref]$parsed)) {
    return $parsed.ToString("MMM d, yyyy")
  }
  return $Value
}

function Health-Style {
  param([string]$Health)
  switch -Regex ($Health.ToLowerInvariant()) {
    "green|good|on.track" { return @{ Background = "#dcfce7"; Foreground = "#166534" } }
    "amber|yellow|watch|risk" { return @{ Background = "#fef3c7"; Foreground = "#92400e" } }
    "red|critical|blocked" { return @{ Background = "#fee2e2"; Foreground = "#991b1b" } }
    default { return @{ Background = "#e2e8f0"; Foreground = "#334155" } }
  }
}

function Has-MeaningfulBlocker {
  param([string]$Value)
  if ([string]::IsNullOrWhiteSpace($Value)) { return $false }
  $normalized = (Canonical $Value)
  if ($normalized -match '^(no|none|n/?a|not applicable)([ .].*)?$') { return $false }
  if ($normalized -match '^no (current |major |technical )?blockers?([ .].*)?$') { return $false }
  return $true
}

function Add-HtmlDetail {
  param(
    [System.Text.StringBuilder]$Builder,
    [string]$Label,
    [string]$Value,
    [string]$Background = "#f8fafc"
  )
  if (-not [string]::IsNullOrWhiteSpace($Value)) {
    [void]$Builder.Append("<tr><td style=`"padding:10px 12px;border-top:1px solid #e2e8f0;background:$Background;`"><strong style=`"color:#334155;`">$(Html $Label)</strong><br><span style=`"color:#334155;`">$(Html $Value)</span></td></tr>")
  }
}

function As-Array {
  param($Value)
  if ($null -eq $Value) { return @() }
  if ($Value -is [System.Array]) { return @($Value) }
  return @($Value)
}

function Build-OwnerEmailMap {
  param($Users)
  $map = @{}

  $aliases = @{
    "sam" = "saurabh.jogdeo@zenatech.com"
    "saurabh" = "saurabh.jogdeo@zenatech.com"
    "swati" = "swati.gurbani@zenatech.com"
    "swatti" = "swati.gurbani@zenatech.com"
    "krishna" = "krishna@zenatech.com"
    "krishina" = "krishna@zenatech.com"
    "jojo" = "jocasta@zenatech.com"
    "jocasta" = "jocasta@zenatech.com"
    "nadishani" = "nadishani@zenatech.com"
    "deepa" = "deepa@zenatech.com"
    "faran" = "faran@zenatech.com"
    "riya" = "riya@zenatech.com"
    "reza" = "reza.boostani@zenatech.com"
    "sajjad" = "sajjad@zenatech.com"
    "daniela" = "daniela@zenatech.com"
  }

  foreach ($key in $aliases.Keys) {
    $map[$key] = $aliases[$key]
  }

  foreach ($user in $Users) {
    $isActive = $true
    if ($null -ne $user.PSObject.Properties["active"]) { $isActive = [bool]$user.active }
    if ($null -ne $user.PSObject.Properties["is_active"]) { $isActive = [bool]$user.is_active }
    if (-not $isActive) { continue }

    $name = Get-Field $user @("display_name", "name", "username")
    $username = Get-Field $user @("username", "email")
    $email = Get-Field $user @("email", "username")
    if (-not (Is-Email $email) -and (Is-Email $username)) { $email = $username }
    if (-not (Is-Email $email)) { continue }

    if ($name) { $map[(Canonical $name)] = $email }
    if ($username -and -not (Is-Email $username)) { $map[(Canonical $username)] = $email }
  }

  return $map
}

function Build-PortfolioHtml {
  param([string[]]$Lines)
  $builder = New-Object System.Text.StringBuilder
  [void]$builder.Append('<div style="margin:26px 30px;color:#334155;font-size:14px;line-height:1.65;">')
  $cardOpen = $false
  foreach ($line in $Lines) {
    if ([string]::IsNullOrWhiteSpace($line)) { continue }
    if ($line -match '^(.*) \(latest reported week: ([0-9-]+)\)$') {
      if ($cardOpen) { [void]$builder.Append('</td></tr></table>') }
      $projectTitle = Html $Matches[1]
      $dateLabel = Html $Matches[2]
      [void]$builder.Append("<table role=`"presentation`" width=`"100%`" cellpadding=`"0`" cellspacing=`"0`" style=`"margin:0 0 20px;border:1px solid #dbe3ec;border-collapse:collapse;`"><tr><td style=`"padding:16px 18px;background:#edf3f8;border-left:4px solid #17324d;`"><h3 style=`"margin:0 0 6px;font-size:21px;line-height:1.3;color:#17324d;`">$projectTitle</h3><span style=`"display:inline-block;padding:3px 9px;background:#ffffff;border:1px solid #cbd5e1;color:#475569;font-size:12px;`">(latest reported week: $dateLabel)</span></td></tr><tr><td style=`"padding:14px 18px;`">")
      $cardOpen = $true
    } elseif ($line -eq 'Feedback on all your projects:') {
      [void]$builder.Append("<h2 style=`"margin:0 0 18px;font-size:21px;color:#17324d;`">$(Html $line)</h2>")
    } else {
      $background = '#ffffff'
      $accent = '#e2e8f0'
      if ($line -match '^Positive (result|feedback):') { $background = '#f0fdf4'; $accent = '#22c55e' }
      elseif ($line -match '^(No update|Blocker/risk:|The delivery date|Please define|Please confirm)') { $background = '#fff7ed'; $accent = '#f59e0b' }
      elseif ($line -match '^Next action:') { $background = '#eff6ff'; $accent = '#3b82f6' }
      [void]$builder.Append("<p style=`"margin:0 0 10px;padding:9px 12px;background:$background;border-left:3px solid $accent;`">$(Html $line)</p>")
    }
  }
  if ($cardOpen) { [void]$builder.Append('</td></tr></table>') }
  [void]$builder.Append('</div>')
  return $builder.ToString()
}

function Summarize-Owner {
  param($OwnerName, $Rows)

  if (@($Rows).Count -eq 0) {
    return @(
      "Weekly feedback for $OwnerName",
      "",
      "Hi $OwnerName,",
      "",
      "No status reports were submitted for this reporting week.",
      "Please add this week's updates with health, progress, any blocker or risk, and a clear next action.",
      "",
      "Suggested improvement: submit the weekly status even when work is on track, so management review has a complete picture."
    ) -join "`n"
  }

  $products = @($Rows | ForEach-Object { Get-Field $_ @("product") } | Where-Object { $_ } | Sort-Object -Unique)
  $avgProgress = Average (@($Rows | ForEach-Object { Get-Field $_ @("progress") }))
  $healthGroups = @{}
  foreach ($row in $Rows) {
    $health = Get-Field $row @("health")
    if (-not $health) { $health = "Not set" }
    if (-not $healthGroups.ContainsKey($health)) { $healthGroups[$health] = 0 }
    $healthGroups[$health] += 1
  }
  $healthText = ($healthGroups.GetEnumerator() | Sort-Object Name | ForEach-Object { "$($_.Value) $($_.Key)" }) -join ", "

  $missingNext = @($Rows | Where-Object { -not (Get-Field $_ @("next", "next_action", "nextAction", "next action")) }).Count
  $blockers = @($Rows | Where-Object { Has-MeaningfulBlocker (Get-Field $_ @("blocker", "blocker_risk", "blocker_or_risk", "risk")) }).Count
  $activeRows = @($Rows | Where-Object {
    (Get-Field $_ @("stage")) -notmatch "completed|closed" -and [int](Get-Field $_ @("progress")) -lt 100
  })
  if ($activeRows.Count -eq 0) { $activeRows = @($Rows) }
  $priorityRows = @($activeRows | Sort-Object @{ Expression = {
    $priority = Get-Field $_ @("priority")
    if ($priority -match "critical") { 1 }
    elseif ((Get-Field $_ @("health")) -match "red|blocked") { 2 }
    elseif ((Get-Field $_ @("health")) -match "amber|risk") { 3 }
    elseif ($priority -match "high") { 4 }
    else { 5 }
  } }, @{ Expression = { [int](Get-Field $_ @("progress")) } } | Select-Object -First 5)

  $lines = New-Object System.Collections.Generic.List[string]
  $lines.Add("Weekly feedback for $OwnerName")
  $lines.Add("")
  $lines.Add("Hi $OwnerName,")
  $lines.Add("")
  $lines.Add("This feedback is based on the latest reporting week with submitted status reports.")
  $lines.Add("$($Rows.Count) reports reviewed across $($products.Count) products. Average progress is $avgProgress%. Health mix: $healthText.")
  $lines.Add("$blockers reports mention blockers or risks. $missingNext reports are missing a clear next action.")
  $lines.Add("")

  if ($priorityRows.Count -gt 0) {
    $lines.Add("Recommended focus for this week:")
    $index = 1
    foreach ($row in $priorityRows) {
      $product = Get-Field $row @("product")
      $feature = Get-Field $row @("feature", "feature_workstream", "workstream")
      $health = Get-Field $row @("health")
      $progress = Get-Field $row @("progress")
      $endDate = Get-Field $row @("due_date", "end_date", "endDate")
      $blocker = Get-Field $row @("blocker", "blocker_risk", "blocker_or_risk", "risk")
      $nextAction = Get-Field $row @("next", "next_action", "nextAction", "next action")
      if (-not $feature) { $feature = "Status report" }
      if (-not $product) { $product = "Product not set" }
      if (-not $health) { $health = "Health not set" }
      if (-not $progress) { $progress = "0" }
      if (-not $endDate) { $endDate = "No end date" }
      if (-not $blocker) { $blocker = "No blocker captured" }
      if (-not $nextAction) { $nextAction = "Please add a clear next action" }
      $lines.Add("$index. $product - $feature")
      $lines.Add("   Status: $health, $progress% progress, end date: $endDate.")
      $lines.Add("   Risk/blocker: $blocker")
      $lines.Add("   Next action: $nextAction")
      $index += 1
    }
  } else {
    $lines.Add("No active follow-up items were found for this owner.")
  }

  $lines.Add("")
  if ($blockers -gt 0 -or $missingNext -gt 0) {
    $lines.Add("Suggested improvement: turn every blocker into a named action with owner, target date, and decision needed. This will make the next management review easier and reduce follow-up churn.")
  } else {
    $lines.Add("Suggested improvement: keep the current reporting discipline and continue closing the week with clear next actions and delivery dates.")
  }

  return ($lines -join "`n")
}

function Build-OwnerHtml {
  param($OwnerName, $Rows, [string]$ReportingWeek)

  $products = @($Rows | ForEach-Object { Get-Field $_ @("product") } | Where-Object { $_ } | Sort-Object -Unique)
  $avgProgress = Average @($Rows | ForEach-Object { Get-Field $_ @("progress") })
  if (@($Rows).Count -eq 0) {
    $empty = New-Object System.Text.StringBuilder
    [void]$empty.Append('<div style="margin:0;padding:24px;background:#f1f5f9;font-family:Arial,sans-serif;color:#17212b;">')
    [void]$empty.Append('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:760px;margin:0 auto;background:#ffffff;border:1px solid #dbe3ec;border-collapse:collapse;">')
    [void]$empty.Append("<tr><td style=`"padding:28px 30px;background:#17324d;color:#ffffff;`"><div style=`"font-size:12px;letter-spacing:1.4px;font-weight:bold;`">OMENA CONSULTING</div><h1 style=`"margin:8px 0 4px;font-size:26px;line-height:1.25;`">Your Weekly Feedback</h1><div style=`"font-size:15px;color:#dbeafe;`">Reporting week: $(Html $ReportingWeek)</div></td></tr>")
    [void]$empty.Append("<tr><td style=`"padding:26px 30px;`"><p style=`"margin:0 0 8px;font-size:16px;`">Hello $(Html $OwnerName),</p><p style=`"margin:0 0 22px;color:#475569;`">No status reports were submitted for this reporting week. Please add this week's updates with health, progress, any blocker or risk, and a clear next action.</p>")
    [void]$empty.Append("<table role=`"presentation`" width=`"100%`" cellpadding=`"0`" cellspacing=`"0`" style=`"margin-top:8px;border-collapse:collapse;background:#eff6ff;border-left:4px solid #2563eb;`"><tr><td style=`"padding:14px 16px;`"><strong style=`"color:#1e3a8a;`">Suggested improvement</strong><br><span style=`"color:#334155;`">Submit the weekly status even when work is on track, so management review has a complete picture.</span></td></tr></table>")
    [void]$empty.Append('</td></tr><tr><td style="padding:18px 30px;border-top:1px solid #dbe3ec;background:#f8fafc;color:#64748b;font-size:12px;">Generated because no submitted status reports were found for this owner in the reporting week.</td></tr></table></div>')
    return $empty.ToString()
  }
  $atRisk = @($Rows | Where-Object {
    (Get-Field $_ @("health")) -match "red|amber|risk|blocked" -or
    (Get-Field $_ @("priority")) -match "critical" -or
    (Has-MeaningfulBlocker (Get-Field $_ @("blocker", "blocker_risk", "blocker_or_risk", "risk")))
  }).Count
  $missingNext = @($Rows | Where-Object { -not (Get-Field $_ @("next", "next_action", "nextAction", "next action")) }).Count

  $builder = New-Object System.Text.StringBuilder
  [void]$builder.Append('<div style="margin:0;padding:24px;background:#f1f5f9;font-family:Arial,sans-serif;color:#17212b;">')
  [void]$builder.Append('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="max-width:760px;margin:0 auto;background:#ffffff;border:1px solid #dbe3ec;border-collapse:collapse;">')
  [void]$builder.Append("<tr><td style=`"padding:28px 30px;background:#17324d;color:#ffffff;`"><div style=`"font-size:12px;letter-spacing:1.4px;font-weight:bold;`">OMENA CONSULTING</div><h1 style=`"margin:8px 0 4px;font-size:26px;line-height:1.25;`">Your Weekly Feedback</h1><div style=`"font-size:15px;color:#dbeafe;`">Reporting week: $(Html $ReportingWeek)</div></td></tr>")
  [void]$builder.Append("<tr><td style=`"padding:26px 30px;`"><p style=`"margin:0 0 8px;font-size:16px;`">Hello $(Html $OwnerName),</p><p style=`"margin:0 0 22px;color:#475569;`">Here is your weekly feedback based on the latest submitted status reports.</p>")
  [void]$builder.Append('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;margin-bottom:26px;"><tr>')
  $metrics = @(
    @{ Label = "Reports"; Value = $Rows.Count },
    @{ Label = "Products"; Value = $products.Count },
    @{ Label = "Avg. progress"; Value = "$avgProgress%" },
    @{ Label = "At risk"; Value = $atRisk }
  )
  foreach ($metric in $metrics) {
    [void]$builder.Append("<td width=`"25%`" style=`"padding:12px;border:1px solid #dbe3ec;vertical-align:top;`"><div style=`"font-size:12px;color:#64748b;margin-bottom:5px;`">$(Html $metric.Label)</div><div style=`"font-size:22px;font-weight:bold;color:#17324d;`">$(Html "$($metric.Value)")</div></td>")
  }
  [void]$builder.Append('</tr></table>')
  [void]$builder.Append('<h2 style="margin:0 0 14px;padding-bottom:9px;border-bottom:3px solid #17324d;font-size:21px;color:#17324d;">Recommended focus</h2>')

  $activeRows = @($Rows | Where-Object {
    (Get-Field $_ @("stage")) -notmatch "completed|closed" -and [int](Get-Field $_ @("progress")) -lt 100
  })
  if ($activeRows.Count -eq 0) { $activeRows = @($Rows) }
  $priorityRows = @($activeRows | Sort-Object @{ Expression = {
    $priority = Get-Field $_ @("priority")
    if ($priority -match "critical") { 1 }
    elseif ((Get-Field $_ @("health")) -match "red|blocked") { 2 }
    elseif ((Get-Field $_ @("health")) -match "amber|risk") { 3 }
    elseif ($priority -match "high") { 4 }
    else { 5 }
  } }, @{ Expression = { [int](Get-Field $_ @("progress")) } } | Select-Object -First 5)

  foreach ($row in $priorityRows) {
    $product = Get-Field $row @("product")
    $workstream = Get-Field $row @("feature_workstream", "feature", "workstream")
    if (-not $product) { $product = "Product not set" }
    if (-not $workstream) { $workstream = "Status report" }
    $health = Get-Field $row @("health")
    if (-not $health) { $health = "Not set" }
    $healthStyle = Health-Style $health
    $priority = Get-Field $row @("priority")
    $actionStatus = Get-Field $row @("action_status")
    $progress = Get-Field $row @("progress")
    $stage = Get-Field $row @("stage")
    $dueDate = Format-DateValue (Get-Field $row @("due_date", "end_date", "endDate"))
    $actionDue = Format-DateValue (Get-Field $row @("action_due_date"))

    [void]$builder.Append('<table role="presentation" width="100%" cellpadding="0" cellspacing="0" style="border:1px solid #dbe3ec;border-collapse:collapse;margin-bottom:16px;"><tr><td style="padding:16px 16px 12px;">')
    [void]$builder.Append("<h3 style=`"margin:0 0 10px;font-size:18px;color:#17212b;`">$(Html $product) <span style=`"color:#94a3b8;`">|</span> $(Html $workstream)</h3>")
    [void]$builder.Append("<span style=`"display:inline-block;margin:0 6px 6px 0;padding:4px 9px;border-radius:12px;background:$($healthStyle.Background);color:$($healthStyle.Foreground);font-size:12px;font-weight:bold;`">Health: $(Html $health)</span>")
    if ($priority) { [void]$builder.Append("<span style=`"display:inline-block;margin:0 6px 6px 0;padding:4px 9px;border-radius:12px;background:#e0e7ff;color:#3730a3;font-size:12px;font-weight:bold;`">Priority: $(Html $priority)</span>") }
    if ($actionStatus) { [void]$builder.Append("<span style=`"display:inline-block;margin:0 6px 6px 0;padding:4px 9px;border-radius:12px;background:#e2e8f0;color:#334155;font-size:12px;font-weight:bold;`">Action: $(Html $actionStatus)</span>") }
    [void]$builder.Append('</td></tr><tr><td style="padding:0 16px 14px;"><table width="100%" cellpadding="0" cellspacing="0" style="border-collapse:collapse;background:#f8fafc;"><tr>')
    [void]$builder.Append("<td width=`"25%`" style=`"padding:9px;border:1px solid #e2e8f0;vertical-align:top;`"><span style=`"font-size:12px;color:#64748b;`">Progress</span><br><strong>$(Html "$progress%")</strong></td>")
    [void]$builder.Append("<td width=`"25%`" style=`"padding:9px;border:1px solid #e2e8f0;vertical-align:top;`"><span style=`"font-size:12px;color:#64748b;`">Stage</span><br><strong>$(Html $stage)</strong></td>")
    [void]$builder.Append("<td width=`"25%`" style=`"padding:9px;border:1px solid #e2e8f0;vertical-align:top;`"><span style=`"font-size:12px;color:#64748b;`">Due date</span><br><strong>$(Html $dueDate)</strong></td>")
    [void]$builder.Append("<td width=`"25%`" style=`"padding:9px;border:1px solid #e2e8f0;vertical-align:top;`"><span style=`"font-size:12px;color:#64748b;`">Action due</span><br><strong>$(Html $actionDue)</strong></td>")
    [void]$builder.Append('</tr></table></td></tr>')
    Add-HtmlDetail $builder "Summary" (Get-Field $row @("summary"))
    Add-HtmlDetail $builder "Win" (Get-Field $row @("win")) "#f0fdf4"
    Add-HtmlDetail $builder "Blocker / Risk" (Get-Field $row @("blocker", "blocker_risk", "blocker_or_risk", "risk")) "#fff7ed"
    Add-HtmlDetail $builder "Next action" (Get-Field $row @("next", "next_action", "nextAction", "next action")) "#eff6ff"
    Add-HtmlDetail $builder "Action owner" (Get-Field $row @("action_owner"))
    Add-HtmlDetail $builder "Decision needed" (Get-Field $row @("decision_needed")) "#fefce8"
    [void]$builder.Append('</table>')
  }

  $improvement = "Keep the current reporting discipline and continue closing the week with clear next actions and delivery dates."
  if ($atRisk -gt 0 -or $missingNext -gt 0) {
    $improvement = "Turn every blocker into a named action with an owner, target date, and decision needed. This will make the next management review easier and reduce follow-up churn."
  }
  [void]$builder.Append("<table role=`"presentation`" width=`"100%`" cellpadding=`"0`" cellspacing=`"0`" style=`"margin-top:22px;border-collapse:collapse;background:#eff6ff;border-left:4px solid #2563eb;`"><tr><td style=`"padding:14px 16px;`"><strong style=`"color:#1e3a8a;`">Suggested improvement</strong><br><span style=`"color:#334155;`">$(Html $improvement)</span></td></tr></table>")
  [void]$builder.Append('</td></tr><tr><td style="padding:18px 30px;border-top:1px solid #dbe3ec;background:#f8fafc;color:#64748b;font-size:12px;">Generated from the latest reporting week with submitted status reports.</td></tr></table></div>')
  return $builder.ToString()
}

$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$configPath = Join-Path $root "supabase-config.js"
$config = Get-Content -Raw $configPath
$url = Get-ConfigValue $config "url"
$anonKey = Get-ConfigValue $config "anonKey"
$usersTable = Get-ConfigValue $config "usersTable"
$sendTable = Get-ConfigValue $config "weeklyReviewSendsTable"
$emailEndpoint = Get-ConfigValue $config "emailFunctionUrl"
$emailKey = Get-ConfigValue $config "emailFunctionAnonKey"

if (-not $usersTable) { $usersTable = "app_users" }
if (-not $sendTable) { $sendTable = "weekly_review_sends" }
if (-not $emailKey) { $emailKey = $anonKey }

$headers = @{ apikey = $anonKey; Authorization = "Bearer $anonKey" }
$emailHeaders = @{ apikey = $emailKey; Authorization = "Bearer $emailKey"; "Content-Type" = "application/json" }

$reports = As-Array (Invoke-RestMethod -Uri "$url/rest/v1/status_reports?select=*&order=week.desc&limit=5000" -Headers $headers -Method Get)
if ($reports.Count -eq 0) {
  Write-Output "No status reports found."
  exit 0
}

$targetWeek = $Week
$periodLabel = $targetWeek
if ($StartDate -and $EndDate) {
  $periodLabel = "$StartDate to $EndDate"
} elseif (-not $targetWeek) {
  $targetWeek = @($reports | ForEach-Object { Get-Field $_ @("week") } | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1)
  $periodLabel = $targetWeek
}

if (-not $targetWeek -and -not ($StartDate -and $EndDate)) {
  Write-Output "No reporting week found in status reports."
  exit 0
}

if ($StartDate -and $EndDate) {
  $weekRows = @($reports | Where-Object {
    $reportDate = Get-Field $_ @("week")
    $reportDate -ge $StartDate -and $reportDate -le $EndDate
  })
} else {
  $weekRows = @($reports | Where-Object { (Get-Field $_ @("week")) -eq $targetWeek })
}
if ($Owner) {
  $weekRows = @($weekRows | Where-Object { (Canonical (Get-Field $_ @("owner"))) -eq (Canonical $Owner) })
}

$users = As-Array (Invoke-RestMethod -Uri "$url/rest/v1/${usersTable}?select=*&limit=5000" -Headers $headers -Method Get)
$emailMap = Build-OwnerEmailMap $users

$existing = @()
try {
  $existing = As-Array (Invoke-RestMethod -Uri "$url/rest/v1/${sendTable}?select=owner,email,filter_week,status,created_at&status=eq.sent&limit=5000" -Headers $headers -Method Get)
} catch {
  Write-Output "Warning: could not read existing weekly send history. Continuing without skip list."
}

$alreadySent = @{}
foreach ($row in $existing) {
  $alreadySent["$(Canonical (Get-Field $row @("owner")))|$(Get-Field $row @("filter_week"))"] = $true
}

$groups = @()
if ($AllOwners) {
  $displayByKey = @{}
  foreach ($row in $reports) {
    $name = Get-Field $row @("owner")
    if ($name) {
      $key = Canonical $name
      if (-not $displayByKey.ContainsKey($key)) { $displayByKey[$key] = $name }
    }
  }
  foreach ($user in $users) {
    $isActive = $true
    if ($null -ne $user.PSObject.Properties["active"]) { $isActive = [bool]$user.active }
    if ($null -ne $user.PSObject.Properties["is_active"]) { $isActive = [bool]$user.is_active }
    if (-not $isActive) { continue }
    $name = Get-Field $user @("display_name", "name")
    if ($name -and -not (Is-Email $name)) {
      $key = Canonical $name
      if (-not $displayByKey.ContainsKey($key)) { $displayByKey[$key] = $name }
    }
  }
  foreach ($name in @("Deepa", "Faran", "Jojo", "Jocasta", "Krishna", "Nadishani", "Reza", "Riya", "Sajjad", "Sam", "Saurabh", "Swati")) {
    $key = Canonical $name
    if (-not $displayByKey.ContainsKey($key)) { $displayByKey[$key] = $name }
  }

  $rawGroups = @()
  foreach ($key in ($displayByKey.Keys | Sort-Object)) {
    $ownerName = [string]$displayByKey[$key]
    $ownerWeekRows = @($weekRows | Where-Object { (Canonical (Get-Field $_ @("owner"))) -eq $key })
    $rawGroups += [pscustomobject]@{
      Name = $ownerName
      Rows = $ownerWeekRows
      ReportingWeek = $targetWeek
    }
  }

  $seenEmail = @{}
  foreach ($group in ($rawGroups | Sort-Object @{ Expression = { -@($_.Rows).Count } }, Name)) {
    $email = $emailMap[(Canonical $group.Name)]
    if ($email) {
      $emailKey = Canonical $email
      if ($seenEmail.ContainsKey($emailKey)) { continue }
      $seenEmail[$emailKey] = $true
    }
    $groups += $group
  }
  $groups = @($groups | Sort-Object Name)
} elseif ($AllProductManagers) {
  # Every PM receives feedback based on all of their projects from their most recent submitted week.
  $pmRows = @($reports | Where-Object { (Get-Field $_ @("role")) -eq "Product Manager" -and (Get-Field $_ @("owner")) })
  foreach ($ownerGroup in ($pmRows | Group-Object { Get-Field $_ @("owner") } | Sort-Object Name)) {
    $ownerWeek = @($ownerGroup.Group | ForEach-Object { Get-Field $_ @("week") } | Where-Object { $_ } | Sort-Object -Descending | Select-Object -First 1)[0]
    if (-not $ownerWeek) { continue }
    $groups += [pscustomobject]@{
      Name = [string]$ownerGroup.Name
      Rows = @($ownerGroup.Group | Where-Object { (Get-Field $_ @("week")) -eq $ownerWeek })
      ReportingWeek = $ownerWeek
    }
  }
} else {
  $groups = @($weekRows | Group-Object { Get-Field $_ @("owner") } | Sort-Object Name | ForEach-Object {
    [pscustomobject]@{ Name = [string]$_.Name; Rows = @($_.Group); ReportingWeek = $periodLabel }
  })
}
$batchId = [guid]::NewGuid().ToString()
$sent = 0
$skipped = 0
$failed = 0

foreach ($group in $groups) {
  $ownerName = [string]$group.Name
  if (-not $ownerName) { continue }
  if ($Owner -and (Canonical $ownerName) -ne (Canonical $Owner)) { continue }
  $ownerKey = Canonical $ownerName
  $rows = @($group.Rows)
  $reportingWeek = [string]$group.ReportingWeek
  $sendKey = "$ownerKey|$reportingWeek"
  if (-not $Force -and $alreadySent.ContainsKey($sendKey)) {
    Write-Output "SKIP already sent: $ownerName ($reportingWeek)"
    $skipped += 1
    continue
  }

  $email = $emailMap[$ownerKey]
  if (-not $email) {
    Write-Output "SKIP no email: $ownerName"
    $skipped += 1
    continue
  }

  $recipientReports = @($reports | Where-Object {
    $reportOwner = Canonical (Get-Field $_ @("owner"))
    ($reportOwner -eq $ownerKey -or ($emailMap[$reportOwner] -and (Canonical $emailMap[$reportOwner]) -eq (Canonical $email))) -and
    (Get-Field $_ @("week")) -le $reportingWeek
  })
  $portfolioLines = @("Feedback on all your projects:")
  foreach ($projectGroup in ($recipientReports | Where-Object { Get-Field $_ @("product") } | Group-Object { Canonical (Get-Field $_ @("product")) } | Sort-Object Name)) {
    $latestWeek = @($projectGroup.Group | ForEach-Object { Get-Field $_ @("week") } | Sort-Object -Descending)[0]
    $latestRows = @($projectGroup.Group | Where-Object { (Get-Field $_ @("week")) -eq $latestWeek })
    $projectName = Get-Field $latestRows[0] @("product")
    $portfolioLines += ""
    $portfolioLines += "$projectName (latest reported week: $latestWeek)"
    if ($latestWeek -ne $reportingWeek) { $portfolioLines += "No update for the feedback week. The following assessment uses the last known report; please confirm the current status." }
    foreach ($projectRow in $latestRows) {
      $health = Get-Field $projectRow @("health")
      $progress = Get-Field $projectRow @("progress")
      $stage = Get-Field $projectRow @("stage")
      $blocker = Get-Field $projectRow @("blocker", "blocker_risk", "blocker_or_risk", "risk")
      $nextAction = Get-Field $projectRow @("next", "next_action", "nextAction", "next action")
      $win = Get-Field $projectRow @("win")
      $dueValue = Get-Field $projectRow @("due_date", "end_date", "endDate")
      $due = [datetime]::MinValue
      $reportDate = [datetime]::MinValue
      $issues = @()
      $completed = $stage -match 'completed|closed' -or $progress -eq '100'
      if ($health -match 'red|amber|yellow|risk|blocked|critical') { $issues += "Reported health is $health. Please provide a recovery plan." }
      if (Has-MeaningfulBlocker $blocker) { $issues += "Blocker/risk: $blocker. Confirm the resolution owner and target date." }
      if (-not $completed -and [datetime]::TryParse($dueValue, [ref]$due) -and [datetime]::TryParse($reportingWeek, [ref]$reportDate) -and $due.Date -lt $reportDate.Date.AddDays(7)) { $issues += "The delivery date ($dueValue) has passed by the end of the reporting week. Confirm delivery or explain the delay and provide a revised date." }
      if (-not $completed -and [string]::IsNullOrWhiteSpace($nextAction)) { $issues += "Please define the next action and its target date." }
      $workstream = Get-Field $projectRow @("feature_workstream", "feature", "workstream")
      $portfolioLines += "${workstream}: Health: $health; progress: $progress%; stage: $stage; delivery date: $dueValue."
      if ($win) { $portfolioLines += "Positive result: $win. Thank you for this progress." }
      if ($completed) { $portfolioLines += "Positive feedback: this work is reported as completed. Thank you for delivering it." }
      elseif ($issues.Count -eq 0 -and $health -match 'green|good|on.track') { $portfolioLines += "Positive feedback: this work is reported on track with no recorded blocker. Keep the momentum and follow through on the next milestone." }
      elseif ($issues.Count -eq 0) { $portfolioLines += "Please confirm project health so delivery can be assessed." }
      $portfolioLines += $issues
      if ($nextAction) { $portfolioLines += "Next action: $nextAction" }
    }
  }
  $portfolioText = $portfolioLines -join "`n"
  $message = (Summarize-Owner $ownerName $rows) + "`n`n" + $portfolioText
  $message += "`n`nRegards,`nDaniela`n$SenderEmail"
  $htmlMessage = Build-OwnerHtml $ownerName $rows $reportingWeek
  $portfolioHtml = Build-PortfolioHtml $portfolioLines
  $htmlMessage = $htmlMessage -replace '</div>$', "$portfolioHtml</div>"
  # Check each project separately; reporting another project does not fill its gaps.
  $missingProjects = @()
  $weekDate = [datetime]::MinValue
  if ([datetime]::TryParseExact($reportingWeek, "yyyy-MM-dd", [Globalization.CultureInfo]::InvariantCulture, [Globalization.DateTimeStyles]::None, [ref]$weekDate)) {
    $recipientReports = @($reports | Where-Object {
      $reportOwner = Canonical (Get-Field $_ @("owner"))
      $reportOwner -eq $ownerKey -or ($emailMap[$reportOwner] -and (Canonical $emailMap[$reportOwner]) -eq (Canonical $email))
    })
    foreach ($projectGroup in ($recipientReports | Where-Object { (Get-Field $_ @("product")) -and (Get-Field $_ @("week")) -le $reportingWeek } | Group-Object { Canonical (Get-Field $_ @("product")) })) {
      $projectRows = @($projectGroup.Group | Sort-Object week)
      $projectName = Get-Field $projectRows[-1] @("product")
      $firstWeek = Get-Field $projectRows[0] @("week")
      $submittedWeeks = @($projectRows | ForEach-Object { Get-Field $_ @("week") })
      $missingWeeks = @()
      for ($offset = 0; $offset -le 4; $offset++) {
        $expectedWeek = $weekDate.AddDays(-7 * $offset).ToString("yyyy-MM-dd")
        if ($expectedWeek -lt $firstWeek -or $submittedWeeks -contains $expectedWeek) { continue }
        $priorRows = @($projectRows | Where-Object { (Get-Field $_ @("week")) -le $expectedWeek })
        if ($priorRows.Count -gt 0 -and (Get-Field $priorRows[-1] @("stage")) -match '^(completed|closed|cancelled|canceled)$') { continue }
        $missingWeeks += $expectedWeek
      }
      if ($missingWeeks.Count -gt 0) { $missingProjects += "$projectName — weeks starting $($missingWeeks -join ', ')" }
    }
  }
  if ($missingProjects.Count -gt 0) {
    $reminder = "Project updates required: $($missingProjects -join '; '). No updates were found for these projects in the listed weeks. Please update each project's current status, progress, blockers or risks, next action, and expected delivery date, and submit the missing updates or explain each gap. Updates submitted for other projects do not resolve these pending items."
    $message = $message.Replace("`n`nRegards,", "`n`n$reminder`n`nRegards,")
    $reminderHtml = "<div style=`"margin:22px 30px;padding:16px;background:#fff7ed;border-left:4px solid #ea580c;color:#9a3412;`"><strong>Missing project updates — action required</strong><p>$(Html $reminder)</p></div>"
    $htmlMessage = $htmlMessage -replace '</div>$', "$reminderHtml</div>"
  }
  $signature = "<p style=`"margin:22px 30px;color:#334155;`">Regards,<br><strong>Daniela</strong><br>$(Html $SenderEmail)</p>"
  $htmlMessage = $htmlMessage -replace '</div>$', "$signature</div>"
  $subject = "Omena Consulting weekly feedback - $ownerName - $reportingWeek"
  $status = "sent"
  $errorMessage = ""

  if ($DryRun) {
    if ($PreviewDirectory) {
      [void](New-Item -ItemType Directory -Path $PreviewDirectory -Force)
      $previewName = ($ownerName -replace '[^a-zA-Z0-9_-]', '_') + '-' + ($reportingWeek -replace '[^a-zA-Z0-9_-]', '_')
      Set-Content -LiteralPath (Join-Path $PreviewDirectory "$previewName.html") -Value $htmlMessage -Encoding utf8
      Set-Content -LiteralPath (Join-Path $PreviewDirectory "$previewName.txt") -Value ("Subject: $subject`nTo: $email`n`n$message") -Encoding utf8
      Write-Output "PREVIEW: $(Join-Path $PreviewDirectory "$previewName.html")"
    }
    Write-Output "DRY RUN would send: $ownerName <$email> ($($rows.Count) reports)"
  } else {
    if ($RecordOnly) {
      Write-Output "RECORD ONLY: $ownerName <$email> ($($rows.Count) reports)"
      $sent += 1
    } else {
      try {
        $payload = @{
          mode = "feedback"
          to = $email
          email = $email
          displayName = $ownerName
          subject = $subject
          message = $message
          htmlMessage = $htmlMessage
        } | ConvertTo-Json -Depth 8
        Invoke-RestMethod -Uri $emailEndpoint -Headers $emailHeaders -Method Post -Body $payload | Out-Null
        Write-Output "SENT: $ownerName <$email> ($($rows.Count) reports)"
        $sent += 1
      } catch {
        $status = "failed"
        $errorMessage = $_.Exception.Message
        if ($_.ErrorDetails.Message) {
          $errorMessage = $_.ErrorDetails.Message
        } elseif ($_.Exception.Response) {
          try {
            $reader = New-Object System.IO.StreamReader($_.Exception.Response.GetResponseStream())
            $bodyText = $reader.ReadToEnd()
            if ($bodyText) { $errorMessage = $bodyText }
          } catch {}
        }
        Write-Output "FAILED: $ownerName <$email> - $errorMessage"
        $failed += 1
      }
    }

    $progress = Average (@($rows | ForEach-Object { Get-Field $_ @("progress") }))
    $actionCount = @($rows | Where-Object { Get-Field $_ @("next", "next_action", "nextAction", "next action") }).Count
    $record = @{
      batch_id = $batchId
      owner = $ownerName
      email = $email
      filter_product = "all"
      filter_week = $reportingWeek
      filter_role = "all"
      period_label = $reportingWeek
      report_count = $rows.Count
      action_count = $actionCount
      feedback_tone = $(if ($status -eq "failed") { "red" } elseif ($progress -lt 50) { "red" } elseif ($progress -lt 75) { "amber" } else { "green" })
      subject = $subject
      message_preview = $message.Substring(0, [Math]::Min(1200, $message.Length))
      status = $status
      error_message = $errorMessage
      sent_by_username = "automation"
      sent_by_name = "Weekly feedback automation"
      sent_by_role = "Role Manager"
      created_at = (Get-Date).ToUniversalTime().ToString("o")
    } | ConvertTo-Json -Depth 8

    try {
      Invoke-RestMethod -Uri "$url/rest/v1/${sendTable}" -Headers ($headers + @{ Prefer = "return=minimal"; "Content-Type" = "application/json" }) -Method Post -Body $record | Out-Null
    } catch {
      Write-Output "Warning: could not record weekly send history for $ownerName. $($_.Exception.Message)"
    }
  }
}

Write-Output "Weekly feedback complete. period=$periodLabel allOwners=$AllOwners allProductManagers=$AllProductManagers sent=$sent skipped=$skipped failed=$failed dryRun=$DryRun recordOnly=$RecordOnly"
