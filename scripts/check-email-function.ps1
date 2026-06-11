param(
  [string]$ProjectRef = "vwvmfuktrkpzrzlklbkr"
)

$ErrorActionPreference = "Stop"
$endpoint = "https://$ProjectRef.supabase.co/functions/v1/send-credentials"

try {
  $response = Invoke-WebRequest -Uri $endpoint -Method Options -UseBasicParsing -TimeoutSec 20
  Write-Host "OK: $endpoint returned HTTP $($response.StatusCode)."
} catch {
  if ($_.Exception.Response) {
    $status = [int]$_.Exception.Response.StatusCode
    if ($status -eq 404) {
      Write-Host "NOT DEPLOYED: $endpoint returned HTTP 404."
      exit 2
    }
    Write-Host "ERROR: $endpoint returned HTTP $status."
    exit 1
  }
  Write-Host "ERROR: $($_.Exception.Message)"
  exit 1
}

