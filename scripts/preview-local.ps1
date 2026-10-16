# Start a local preview of the dashboard (edit files, then refresh browser).
$ErrorActionPreference = "Stop"
$root = Split-Path -Parent $PSScriptRoot
$port = if ($env:OMENA_PREVIEW_PORT) { [int]$env:OMENA_PREVIEW_PORT } else { 8765 }
$url = "http://127.0.0.1:$port/"

Set-Location $root
Write-Host ""
Write-Host "Omena Consulting dashboard — local preview"
Write-Host "Folder: $root"
Write-Host "URL:    $url"
Write-Host "Guide:  ${url}guide-factory-dashboard-changes.html"
Write-Host ""
Write-Host "Edit index.html (or other files), save, then refresh the browser."
Write-Host "Press Ctrl+C to stop the server."
Write-Host ""

$listener = [System.Net.HttpListener]::new()
$listener.Prefixes.Add($url)
try {
  $listener.Start()
} catch {
  throw "Could not bind $url. Is another preview already running? $($_.Exception.Message)"
}

Start-Process $url | Out-Null

$types = @{
  ".html" = "text/html; charset=utf-8"
  ".js"   = "text/javascript; charset=utf-8"
  ".css"  = "text/css; charset=utf-8"
  ".json" = "application/json; charset=utf-8"
  ".svg"  = "image/svg+xml"
  ".png"  = "image/png"
  ".jpg"  = "image/jpeg"
  ".ico"  = "image/x-icon"
  ".md"   = "text/plain; charset=utf-8"
}

while ($listener.IsListening) {
  $ctx = $listener.GetContext()
  $reqPath = [Uri]::UnescapeDataString($ctx.Request.Url.AbsolutePath)
  if ($reqPath -eq "/") { $reqPath = "/index.html" }
  $rel = $reqPath.TrimStart("/").Replace("/", [IO.Path]::DirectorySeparatorChar)
  $file = [IO.Path]::GetFullPath((Join-Path $root $rel))
  if (-not $file.StartsWith($root, [StringComparison]::OrdinalIgnoreCase) -or -not (Test-Path -LiteralPath $file) -or (Get-Item -LiteralPath $file).PSIsContainer) {
    $ctx.Response.StatusCode = 404
    $bytes = [Text.Encoding]::UTF8.GetBytes("Not found")
    $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
    $ctx.Response.Close()
    continue
  }
  $ext = [IO.Path]::GetExtension($file).ToLowerInvariant()
  $ctx.Response.ContentType = if ($types.ContainsKey($ext)) { $types[$ext] } else { "application/octet-stream" }
  $bytes = [IO.File]::ReadAllBytes($file)
  $ctx.Response.ContentLength64 = $bytes.Length
  $ctx.Response.OutputStream.Write($bytes, 0, $bytes.Length)
  $ctx.Response.Close()
}
