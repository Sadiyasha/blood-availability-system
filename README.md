# Blood Availability System

Flutter Web + Flask backend app for finding blood donors, checking blood bank inventory, and assisting with donation queries.

## Run locally (Windows / PowerShell)

Prereqs:
- Python 3.10+ and pip
- Flutter SDK

Install backend deps:
```powershell
Set-Location -Path 'd:\blood_availability_system (3)\blood_availability_system\backend'
pip install -r requirements.txt
```

One-click run (backend + web):
```powershell
Set-Location -Path 'd:\blood_availability_system (3)\blood_availability_system\scripts'
./start_all.ps1
# Optional live Flutter server too
./start_all.ps1 -Live
```

Manual run:
```powershell
# Backend
Set-Location -Path 'd:\blood_availability_system (3)\blood_availability_system'
python -u backend/app.py

# In another terminal: build & serve web
Set-Location -Path 'd:\blood_availability_system (3)\blood_availability_system'
flutter build web --release --no-wasm-dry-run --dart-define=BASE_URL=http://127.0.0.1:5000/api
Set-Location -Path 'd:\blood_availability_system (3)\blood_availability_system\build\web'
python -m http.server 8081 --bind 127.0.0.1

# Open http://127.0.0.1:8081
```

## Features
- Smart Match (AI-driven donor matching with distance)
- Blood bank inventory by blood type
- Hospitals lookup
- Chatbot (intents + live data enrichment)

## Chatbot examples
- "find donor O+ in Bangalore urgent" → shows nearby donors
- "O+ availability in Delhi" → shows banks with units
- "nearest hospital in Pune" → lists hospitals

## Troubleshooting
- If web shows empty results, confirm backend health:
```powershell
(Invoke-WebRequest -Uri "http://127.0.0.1:5000/api/health" -UseBasicParsing).Content
```
- If port is busy, change ports in `scripts/start_all.ps1` (WebPort/LivePort).
