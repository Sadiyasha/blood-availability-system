# Blood Availability System - Python Flask Backend

## 🚀 Features

### AI/ML Integration
- **TensorFlow** - Deep learning for demand prediction
- **Scikit-learn** - Random Forest classifier for donor matching
- **Intelligent Matching Algorithm (IBDMA)** - AI-powered donor ranking based on:
  - Blood type compatibility
  - Geographic proximity (Google Maps API)
  - Donor reliability scores
  - Response time predictions
  - Historical donation patterns

### Database
- **MySQL** - Primary relational database for structured data
- **Firebase** (Optional) - Real-time notifications and authentication
- **SQLAlchemy ORM** - Database abstraction layer

### APIs & Services
- **Google Maps API** - Geocoding, distance calculations, directions
- **Chatbot (NLP)** - Natural language processing for queries using NLTK
- **RESTful API** - Complete CRUD operations for all entities

## 📋 Prerequisites

1. **Python 3.9+**
2. **MySQL Server 8.0+**
3. **pip** (Python package manager)
4. **Google Maps API Key** (optional but recommended)
5. **Firebase Project** (optional for real-time features)

## 🛠️ Installation

### Step 1: Install MySQL

**Windows:**
1. Download: https://dev.mysql.com/downloads/installer/
2. Install MySQL Server
3. Set root password during installation
4. Start MySQL service

**Verify Installation:**
```powershell
mysql --version
```

### Step 2: Create Database

```powershell
mysql -u root -p
```

```sql
CREATE DATABASE blood_availability_system;
CREATE USER 'blood_user'@'localhost' IDENTIFIED BY 'your_password';
GRANT ALL PRIVILEGES ON blood_availability_system.* TO 'blood_user'@'localhost';
FLUSH PRIVILEGES;
EXIT;
```

### Step 3: Install Python Dependencies

```powershell
cd backend
pip install -r requirements.txt
```

### Step 4: Configure Environment

Edit `.env` file:
```env
# MySQL Configuration
MYSQL_USER=blood_user
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=blood_availability_system

# Google Maps API (Get from: https://console.cloud.google.com/)
GOOGLE_MAPS_API_KEY=your_actual_google_maps_api_key
```

### Step 5: Initialize Database

```powershell
# Initialize Flask-Migrate
flask db init

# Create migration
flask db migrate -m "Initial migration"

# Apply migration
flask db upgrade
```

### Step 6: Seed Database (Optional)

```powershell
python scripts/seed_database.py
```

### Step 7: Run Server

```powershell
# Development mode
python app.py

# Or use Flask CLI
flask run
```

Server runs at: **http://localhost:5000**

## 🔑 Getting API Keys

### Google Maps API Key

1. Go to: https://console.cloud.google.com/
2. Create new project
3. Enable APIs:
   - Maps JavaScript API
   - Geocoding API
   - Distance Matrix API
   - Places API
4. Create credentials → API Key
5. Add to `.env` file

### Firebase (Optional)

1. Go to: https://console.firebase.google.com/
2. Create project
3. Add web app
4. Download `firebase-credentials.json`
5. Place in backend folder
6. Update `.env` with Firebase config

## 📡 API Endpoints

### Health & Status
- `GET /` - API information
- `GET /api/health` - Health check with DB status

### Donors
- `GET /api/donors` - List all donors
- `GET /api/donors/<id>` - Get donor details
- `POST /api/donors` - Create donor
- `PUT /api/donors/<id>` - Update donor
- `DELETE /api/donors/<id>` - Delete donor
- `POST /api/donors/nearby` - Find nearby donors

### Hospitals
- `GET /api/hospitals` - List hospitals
- `GET /api/hospitals/<id>` - Hospital details
- `POST /api/hospitals/nearby` - Find nearby hospitals

### Blood Banks
- `GET /api/blood-banks` - List blood banks
- `GET /api/blood-banks/<id>` - Blood bank details
- `GET /api/blood-banks/blood-type/<type>` - Find by blood type
- `POST /api/blood-banks/nearby` - Find nearby blood banks

### Smart Matching (AI/ML)
- `POST /api/smart-match/find-donors` - AI-powered donor matching
- `POST /api/smart-match/find-blood-banks` - Find blood banks
- `POST /api/smart-match/comprehensive-search` - Complete search

### Blood Requests
- `GET /api/blood-requests` - List requests
- `POST /api/blood-requests` - Create request
- `PUT /api/blood-requests/<id>` - Update request
- `GET /api/blood-requests/urgent` - Get urgent requests

### Chatbot
- `POST /api/chatbot/query` - Ask chatbot
- `GET /api/chatbot/suggestions` - Get suggestions

### Notifications
- `GET /api/notifications` - Get notifications
- `POST /api/notifications` - Create notification
- `PUT /api/notifications/<id>/read` - Mark as read

### Map
- `POST /api/map/markers` - Get map markers
- `POST /api/map/heatmap` - Blood availability heatmap

## 🧪 Testing API

### Using cURL (PowerShell)

```powershell
# Health check
curl http://localhost:5000/api/health

# Get all donors
curl http://localhost:5000/api/donors

# Smart match (POST request)
$body = @{
    bloodType = "O+"
    location = @{
        latitude = 19.0760
        longitude = 72.8777
    }
    urgency = "Normal"
    maxDistance = 50
} | ConvertTo-Json

curl -X POST http://localhost:5000/api/smart-match/find-donors `
  -H "Content-Type: application/json" `
  -d $body

# Chatbot query
$chatBody = @{
    message = "How do I donate blood?"
    userId = "user123"
} | ConvertTo-Json

curl -X POST http://localhost:5000/api/chatbot/query `
  -H "Content-Type: application/json" `
  -d $chatBody
```

### Using Browser
- http://localhost:5000/api/health
- http://localhost:5000/api/donors
- http://localhost:5000/api/hospitals

## 🤖 AI/ML Features

### Intelligent Donor Matching
The IBDMA uses multiple factors:
1. **Blood Type Compatibility** (30%) - Checks compatibility matrix
2. **Geographic Distance** (25%) - Using Google Maps API
3. **Availability Status** (20%) - Current donation eligibility
4. **Donor History** (15%) - Past donations and reliability
5. **Response Time** (10%) - Historical response patterns

### Predictive Analytics
- Blood demand forecasting
- Donor availability prediction
- Emergency response optimization

## 🗄️ Database Schema

### Tables
- `donors` - Registered blood donors
- `hospitals` - Hospital information
- `blood_banks` - Blood bank inventory
- `blood_requests` - Blood requirement requests
- `blood_request_matches` - Matched donors for requests
- `notifications` - System notifications

## 🔧 Configuration

### Environment Variables
```env
FLASK_ENV=development
SECRET_KEY=your-secret-key
MYSQL_HOST=localhost
MYSQL_PORT=3306
MYSQL_USER=blood_user
MYSQL_PASSWORD=your_password
MYSQL_DATABASE=blood_availability_system
GOOGLE_MAPS_API_KEY=your_key
USE_ML_MATCHING=True
MAX_MATCH_DISTANCE_KM=50
```

## 🐛 Troubleshooting

**MySQL Connection Error:**
- Verify MySQL is running: `Get-Service MySQL80`
- Check credentials in `.env`
- Test connection: `mysql -u blood_user -p`

**Import Errors:**
- Reinstall dependencies: `pip install -r requirements.txt`
- Use virtual environment: `python -m venv venv; .\venv\Scripts\activate`

**Google Maps API Not Working:**
- Verify API key is correct
- Enable required APIs in Google Cloud Console
- Check API usage limits

**Port Already in Use:**
- Change PORT in `.env`
- Or kill process: `Stop-Process -Id (Get-NetTCPConnection -LocalPort 5000).OwningProcess`

## 🌐 Integration with Flutter

Update Flutter `lib/services/api_service.dart`:

```dart
static const String baseUrl = 'http://localhost:5000/api';
```

For Android Emulator:
```dart
static const String baseUrl = 'http://10.0.2.2:5000/api';
```

## 📊 Sample Data

After seeding, you'll have:
- 100+ Donors across major Indian cities
- 20+ Hospitals (Government & Private)
- 12+ Blood Banks with inventory
- Realistic Indian addresses and contact info

## 🔒 Security

- Use environment variables for sensitive data
- Change SECRET_KEY in production
- Enable CORS only for trusted origins
- Use HTTPS in production
- Implement authentication (JWT recommended)

## 📝 License

MIT License

## 👨‍💻 Tech Stack

- **Backend**: Flask 3.0, Python 3.9+
- **Database**: MySQL 8.0, SQLAlchemy ORM
- **AI/ML**: TensorFlow 2.15, Scikit-learn 1.3
- **Maps**: Google Maps API, Geopy
- **NLP**: NLTK 3.8
- **Real-time**: Firebase Admin SDK (optional)

## 🚀 Production Deployment

```powershell
# Use Gunicorn for production
gunicorn -w 4 -b 0.0.0.0:5000 app:app
```

---

**Need Help?** Check documentation or create an issue!
