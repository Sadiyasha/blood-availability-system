# Blood Availability System - Deployment Guide

## 🚀 Step-by-Step Deployment Process

### Prerequisites
1. GitHub account (free)
2. Netlify account (free) - https://netlify.com
3. Render account (free) - https://render.com
4. Git installed on your computer

---

## Part 1: Setup GitHub Repository

### 1. Create GitHub Repository
```bash
# Open PowerShell in your project directory
cd "c:\Users\NIZAM\Desktop\mini proj\blood_availability_system (3) (1)\blood_availability_system (3)\blood_availability_system"

# Initialize git (if not already done)
git init

# Create .gitignore file
echo "build/
.dart_tool/
.packages
pubspec.lock
.flutter-plugins
.flutter-plugins-dependencies
*.pyc
__pycache__/
instance/
*.db
.env
node_modules/" > .gitignore

# Add all files
git add .

# Commit
git commit -m "Initial commit for deployment"
```

### 2. Push to GitHub
1. Go to https://github.com and click "New Repository"
2. Name it: `blood-availability-system`
3. Don't initialize with README
4. Copy the repository URL
5. Run these commands:

```bash
git remote add origin https://github.com/YOUR_USERNAME/blood-availability-system.git
git branch -M main
git push -u origin main
```

---

## Part 2: Deploy Backend to Render (FREE)

### 1. Prepare Backend for Deployment

**Add gunicorn to requirements.txt:**
```bash
cd backend
echo "gunicorn==21.2.0" >> requirements.txt
```

### 2. Update app.py for production
Make sure your `backend/app.py` has this at the end:
```python
if __name__ == '__main__':
    app = create_app()
    app.run(host='0.0.0.0', port=int(os.environ.get('PORT', 5000)))
```

### 3. Deploy on Render
1. Go to https://render.com and sign up (use GitHub)
2. Click "New +" → "Web Service"
3. Connect your GitHub repository
4. Configure:
   - **Name:** `blood-availability-backend`
   - **Root Directory:** `backend`
   - **Environment:** `Python 3`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `gunicorn app:app`
5. Add Environment Variables:
   - `PYTHON_VERSION` = `3.11.0`
   - `FLASK_ENV` = `production`
6. Click "Create Web Service"
7. Wait 5-10 minutes for deployment
8. **Copy your backend URL** (e.g., `https://blood-availability-backend.onrender.com`)

---

## Part 3: Update Frontend API URL

### 1. Update API Service
Open `lib/main.dart` and find the `ApiService` class.

Update the `baseUrl` to your Render backend URL:
```dart
class ApiService {
  final String baseUrl = 'https://your-backend-url.onrender.com';
  // ... rest of the code
}
```

### 2. Commit changes
```bash
git add lib/main.dart
git commit -m "Update API URL for production"
git push
```

---

## Part 4: Deploy Frontend to Netlify

### Option A: Deploy via Netlify UI (Easiest)

1. Build your Flutter web app:
```bash
cd "c:\Users\NIZAM\Desktop\mini proj\blood_availability_system (3) (1)\blood_availability_system (3)\blood_availability_system"
flutter build web --release
```

2. Go to https://netlify.com and sign up
3. Click "Add new site" → "Deploy manually"
4. Drag and drop the **entire `build/web` folder**
5. Wait for deployment (1-2 minutes)
6. **Copy your frontend URL** (e.g., `https://your-app-name.netlify.app`)

### Option B: Deploy via Git (Automatic deployments)

1. Go to https://netlify.com
2. Click "Add new site" → "Import an existing project"
3. Connect to GitHub and select your repository
4. Configure:
   - **Build command:** `flutter build web --release`
   - **Publish directory:** `build/web`
5. Click "Deploy"
6. **Copy your frontend URL**

---

## Part 5: Initialize Backend Database

### 1. Run database migrations on Render

Go to your Render dashboard → Your service → Shell

Run these commands:
```bash
python -c "from app import create_app; from extensions import db; app = create_app(); ctx = app.app_context(); ctx.push(); db.create_all()"

# Seed blood banks
python backend/seed_database.py

# Add donors
python backend/seed_synthetic_donors.py
```

---

## Part 6: Test Your Deployment

### 1. Test Backend
Visit: `https://your-backend-url.onrender.com/api/health`
Should return: `{"status": "healthy"}`

### 2. Test Frontend
Visit: `https://your-app-name.netlify.app`
- Try logging in
- Search for blood banks
- Use the chatbot
- Test Smart Match

---

## 🎉 Your Shareable Links

**Frontend (Users access this):**
```
https://your-app-name.netlify.app
```

**Backend API:**
```
https://your-backend-url.onrender.com
```

---

## Alternative: Deploy Backend to Railway (Another Free Option)

### Railway Deployment Steps:
1. Go to https://railway.app and sign up
2. Click "New Project" → "Deploy from GitHub repo"
3. Select your repository
4. Railway will auto-detect Python
5. Add environment variables:
   - `PORT` = `5000`
   - `FLASK_ENV` = `production`
6. Click "Deploy"
7. Get your URL from Settings → Domains

---

## Troubleshooting

### Backend Issues:
- **Error: No module found:** Check `requirements.txt` includes all dependencies
- **Database errors:** Run migration commands in Render Shell
- **CORS errors:** Make sure Flask-CORS is configured in `app.py`

### Frontend Issues:
- **API connection failed:** Verify backend URL in `lib/main.dart`
- **Build fails:** Run `flutter pub get` before building
- **404 errors:** Check `netlify.toml` has correct redirects

---

## Important Notes

⚠️ **Free Tier Limitations:**
- Render: Backend may sleep after 15 minutes of inactivity (takes 30s to wake up)
- Netlify: 100GB bandwidth/month (usually sufficient)
- Railway: 500 hours/month free

💡 **Tips:**
- Use custom domain for professional look
- Enable HTTPS (automatic on both platforms)
- Monitor usage in dashboards
- Set up automatic deployments from GitHub

---

## Need Help?

Contact support:
- Netlify: https://docs.netlify.com
- Render: https://docs.render.com
- Railway: https://docs.railway.app
