# Start backend and serve web (static and optional Flutter web-server)
param(
  [int]$WebPort = 8081,
  [int]$LivePort = 8082,
  [switch]$Live
)

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $MyInvocation.MyCommand.Path
$proj = Join-Path $root '..'

Write-Host "==> Project: $proj"

# 1) Backend
$backend = Join-Path $proj 'backend'
Set-Location $proj

# Kill anything on 5000
try {
  $conn = Get-NetTCPConnection -LocalPort 5000 -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($conn) { Stop-Process -Id $conn.OwningProcess -Force }
} catch {}

Start-Process -FilePath python -ArgumentList @('-u','backend/app.py') -WorkingDirectory $proj | Out-Null

# Wait for backend to become healthy (retry up to ~25s)
$deadline = (Get-Date).AddSeconds(25)
$healthy = $false
while (-not $healthy -and (Get-Date) -lt $deadline) {
  try {
    $h = Invoke-RestMethod -Uri "http://127.0.0.1:5000/api/health" -TimeoutSec 3
    if ($h.success) { $healthy = $true; break }
  } catch {}
  Start-Sleep -Seconds 1
}

if ($healthy) {
  Write-Host "✅ Backend: http://127.0.0.1:5000"
} else {
  Write-Error "Backend not responding after retries"; exit 1
}

# 2) Build web with correct BASE_URL
Set-Location $proj
flutter build web --release --no-wasm-dry-run --dart-define=BASE_URL=http://127.0.0.1:5000/api

# 3) Static server
$webRoot = Join-Path $proj 'build/web'

# free desired port
try {
  $conn = Get-NetTCPConnection -LocalPort $WebPort -ErrorAction SilentlyContinue | Select-Object -First 1
  if ($conn) { Stop-Process -Id $conn.OwningProcess -Force }
} catch {}

Start-Process -FilePath python -ArgumentList @('-m','http.server',"$WebPort",'--bind','127.0.0.1') -WorkingDirectory $webRoot | Out-Null
Start-Sleep -Seconds 2

try {
  $status = (Invoke-WebRequest -Uri "http://127.0.0.1:$WebPort/" -UseBasicParsing -TimeoutSec 5).StatusCode
  if ($status -ne 200) { throw "Static server not healthy ($status)" }
  Write-Host "✅ Web (static): http://127.0.0.1:$WebPort"
} catch {
  Write-Error "Static server failed: $_"; exit 1
}

# 4) Optional Flutter live web-server
if ($Live) {
  try {
    Start-Process -FilePath flutter -ArgumentList @('run','-d','web-server','--web-hostname','127.0.0.1','--web-port',"$LivePort",'--dart-define=BASE_URL=http://127.0.0.1:5000/api') -WorkingDirectory $proj | Out-Null
    Write-Host "💡 Live server starting on http://127.0.0.1:$LivePort (watch the Flutter terminal)"
  } catch {
    Write-Warning "Failed to start Flutter live server: $_"
  }
}

# 5) Open browser
Start-Process "http://127.0.0.1:$WebPort/"
