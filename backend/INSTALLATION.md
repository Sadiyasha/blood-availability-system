# 🚀 Backend Setup Guide

## Prerequisites

1. **Python 3.8+** installed
2. **MySQL 8.0+** installed and running
3. **Git** (for version control)

## Step-by-Step Installation

### 1. Install MySQL (if not installed)

**Windows:**
- Download MySQL Installer from: https://dev.mysql.com/downloads/installer/
- Run installer and select "MySQL Server"
- Set root password (remember this!)
- Start MySQL service

**Verify MySQL is running:**
```powershell
mysql --version
```

### 2. Create Database

Open MySQL command line:
```powershell
mysql -u root -p
```

Create database:
```sql
CREATE DATABASE blood_availability_db CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'blood_admin'@'localhost' IDENTIFIED BY 'YourStrongPassword123!';
GRANT ALL PRIVILEGES ON blood_availability_db.* TO 'blood_admin'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### 3. Configure Environment

Navigate to backend folder:
```powershell
cd d:\blood_availability_system\backend
```

Create `.env` file:
```powershell
Copy-Item .env.example .env
```

Edit `.env` with your credentials:
```env
# Database
MYSQL_USER=blood_admin
MYSQL_PASSWORD=YourStrongPassword123!
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_DATABASE=blood_availability_db

# Flask
FLASK_ENV=development
FLASK_APP=app.py
SECRET_KEY=your-secret-key-here-change-in-production

# Google Maps API (Get key from: https://console.cloud.google.com/)
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here

# Firebase (Optional - for real-time notifications)
FIREBASE_CREDENTIALS_PATH=path/to/firebase-credentials.json
```

### 4. Install Python Dependencies

Create virtual environment:
```powershell
python -m venv venv
.\venv\Scripts\Activate.ps1
```

Install packages:
```powershell
pip install -r requirements.txt
```

**If you encounter errors:**
```powershell
pip install --upgrade pip
pip install -r requirements.txt --no-cache-dir
```

### 5. Initialize Database

Run migrations:
```powershell
flask db init
flask db migrate -m "Initial migration"
flask db upgrade
```

### 6. Seed Database with Test Data

```powershell
python seed_database.py
```

This will create:
- 150 donors across 8 Indian cities
- 14 hospitals (Government + Private)
- 10+ blood banks with inventory
- 30 blood requests
- 20 notifications

### 7. Download NLTK Data (for Chatbot)

```powershell
python -c "import nltk; nltk.download('punkt'); nltk.download('stopwords')"
```

### 8. Start Backend Server

```powershell
python app.py
```

You should see:
```
 * Running on http://127.0.0.1:5000
 * Serving Flask app 'app'
 * Debug mode: on
```

## 🧪 Test Endpoints

### Health Check
```powershell
curl http://localhost:5000/api/health
```

### Get All Donors
```powershell
curl http://localhost:5000/api/donors
```

### Find Nearby Donors
```powershell
curl -X POST http://localhost:5000/api/donors/nearby -H "Content-Type: application/json" -d "{\"latitude\": 19.0760, \"longitude\": 72.8777, \"maxDistance\": 10}"
```

### Smart Match Donors (AI)
```powershell
curl -X POST http://localhost:5000/api/smart-match/find-donors -H "Content-Type: application/json" -d "{\"bloodType\": \"O+\", \"location\": {\"latitude\": 19.0760, \"longitude\": 72.8777}, \"urgency\": \"Critical\"}"
```

### Chatbot Query
```powershell
curl -X POST http://localhost:5000/api/chatbot/query -H "Content-Type: application/json" -d "{\"message\": \"Who can donate blood?\"}"
```

## 📱 Connect Flutter Frontend

Update `lib/services/api_service.dart`:

```dart
class ApiService {
  static const String baseUrl = 'http://localhost:5000/api';
  // For Android emulator: 'http://10.0.2.2:5000/api'
}
```

## 🔧 Troubleshooting

### Error: "No module named 'MySQLdb'"
```powershell
pip install pymysql
```

### Error: "Can't connect to MySQL server"
- Verify MySQL is running: `Get-Service mysql`
- Check credentials in `.env`
- Test connection: `mysql -u blood_admin -p blood_availability_db`

### Error: "Google Maps API key invalid"
- Get API key from: https://console.cloud.google.com/
- Enable "Maps JavaScript API" and "Geocoding API"
- Update `GOOGLE_MAPS_API_KEY` in `.env`

### Port 5000 already in use
```powershell
# Find process using port 5000
Get-NetTCPConnection -LocalPort 5000

# Kill process (replace PID)
Stop-Process -Id <PID> -Force
```

## 📚 API Documentation

### Base URL
```
http://localhost:5000/api
```

### Endpoints

#### Donors
- `GET /donors` - List all donors
- `GET /donors/:id` - Get donor by ID
- `POST /donors/nearby` - Find nearby donors
- `POST /donors` - Create donor
- `PUT /donors/:id` - Update donor
- `DELETE /donors/:id` - Delete donor

#### Hospitals
- `GET /hospitals` - List all hospitals
- `POST /hospitals/nearby` - Find nearby hospitals

#### Blood Banks
- `GET /blood-banks` - List all blood banks
- `GET /blood-banks/blood-type/:type` - Search by blood type
- `PUT /blood-banks/:id/inventory` - Update inventory

#### Blood Requests
- `GET /blood-requests` - List requests
- `POST /blood-requests` - Create request
- `GET /blood-requests/urgent` - Get urgent requests
- `PUT /blood-requests/:id/status` - Update status

#### Smart Matching (AI)
- `POST /smart-match/find-donors` - AI donor matching
- `POST /smart-match/find-blood-banks` - Find blood banks
- `POST /smart-match/comprehensive-search` - Combined search

#### Notifications
- `GET /notifications?recipientId=1` - Get notifications
- `PUT /notifications/:id/read` - Mark as read

#### Chatbot
- `POST /chatbot/query` - Ask chatbot
- `GET /chatbot/suggestions` - Get suggestions

#### Map
- `POST /map/markers` - Get all markers
- `POST /map/heatmap` - Blood availability heatmap

## 🔐 Production Deployment

1. Change `FLASK_ENV=production` in `.env`
2. Use strong `SECRET_KEY`
3. Set up HTTPS with SSL certificate
4. Use Gunicorn: `gunicorn -w 4 -b 0.0.0.0:5000 app:app`
5. Configure MySQL for production (increase connections, optimize)
6. Set up Firebase for real-time notifications
7. Enable Google Maps API restrictions

## 📞 Support

For issues, contact the development team or check:
- Flask docs: https://flask.palletsprojects.com/
- MySQL docs: https://dev.mysql.com/doc/
- Google Maps API: https://developers.google.com/maps
