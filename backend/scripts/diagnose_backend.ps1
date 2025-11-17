# Diagnostic script for Blood Availability System backend
# Checks:
#  - python process
#  - netstat for port 5000
#  - /api/health
#  - POST /api/chatbot/query
#  - last chat history lines (if present)

Write-Host "=== Backend Diagnostic - $(Get-Date -Format o) ===" -ForegroundColor Cyan

Write-Host "\n[1] Python process (if any):" -ForegroundColor Yellow
try {
    Get-Process python -ErrorAction Stop | Sort-Object Id | Format-Table Id, ProcessName, CPU -AutoSize
} catch {
    Write-Host "No python process found (Get-Process python returned nothing)." -ForegroundColor DarkYellow
}

Write-Host "\n[2] Netstat (listening on :5000):" -ForegroundColor Yellow
cmd /c "netstat -ano | findstr :5000" | ForEach-Object { Write-Host $_ }

Write-Host "\n[3] Health endpoint (/api/health):" -ForegroundColor Yellow
try {
    $health = Invoke-RestMethod -Uri http://127.0.0.1:5000/api/health -Method GET -TimeoutSec 5
    Write-Host "Health response:" -ForegroundColor Green
    $health | ConvertTo-Json -Depth 5 | Write-Host
} catch {
    Write-Host "Health check failed: $_" -ForegroundColor Red
}

Write-Host "\n[4] Chatbot POST (/api/chatbot/query):" -ForegroundColor Yellow
$body = @{ message = 'Diagnostic ping'; userId = 'diag' } | ConvertTo-Json
try {
    $resp = Invoke-RestMethod -Uri http://127.0.0.1:5000/api/chatbot/query -Method POST -Body $body -ContentType 'application/json' -TimeoutSec 10
    Write-Host "Chatbot response (full):" -ForegroundColor Green
    $resp | ConvertTo-Json -Depth 8 | Write-Host
} catch {
    Write-Host "Chatbot POST failed: $_" -ForegroundColor Red
}

Write-Host "\n[5] Chat history (last lines, if exists):" -ForegroundColor Yellow
$historyPath = Join-Path -Path (Resolve-Path ..\instance).Path -ChildPath 'chat_history.json'
if (Test-Path $historyPath) {
    Write-Host "Found chat history at: $historyPath" -ForegroundColor Green
    try {
        Get-Content $historyPath -Tail 30 | ForEach-Object { Write-Host $_ }
    } catch {
        Write-Host "Failed to read chat history: $_" -ForegroundColor Red
    }
} else {
    Write-Host "No chat_history.json found at $historyPath" -ForegroundColor DarkYellow
}

Write-Host "\n=== Diagnostic complete ===" -ForegroundColor Cyan
