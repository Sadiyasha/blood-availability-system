# 🚀 Quick Deployment Guide

## Automatic Deployment Script

Run this command in PowerShell:
```powershell
.\deploy.ps1
```

This script will:
✅ Initialize Git repository
✅ Guide you through GitHub setup
✅ Push code to GitHub
✅ Provide step-by-step Render (backend) deployment
✅ Build Flutter web app
✅ Guide you through Netlify (frontend) deployment

---

## Manual Deployment (Step-by-Step)

### 1️⃣ Push to GitHub (5 minutes)

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/YOUR_USERNAME/blood-availability-system.git
git push -u origin main
```

### 2️⃣ Deploy Backend to Render (10 minutes)

1. Go to https://render.com → Sign up with GitHub
2. Click "New +" → "Web Service"
3. Select your GitHub repository
4. Settings:
   - **Root Directory:** `backend`
   - **Build Command:** `pip install -r requirements.txt`
   - **Start Command:** `gunicorn app:app`
5. Add environment variables:
   - `PYTHON_VERSION` = `3.11.0`
6. Click "Create Web Service"
7. **Copy your backend URL** (e.g., https://xxx.onrender.com)

### 3️⃣ Update Frontend API URL (2 minutes)

Open `lib/main.dart` and update line ~100:
```dart
final String baseUrl = 'https://YOUR-BACKEND-URL.onrender.com';
```

Commit and push:
```bash
git add lib/main.dart
git commit -m "Update API URL"
git push
```

### 4️⃣ Deploy Frontend to Netlify (5 minutes)

**Option A: Drag & Drop**
```bash
flutter build web --release
```
1. Go to https://app.netlify.com/drop
2. Drag `build/web` folder
3. Done! Copy your URL

**Option B: Git Deploy (Auto-updates)**
1. Go to https://app.netlify.com
2. "Add new site" → "Import from Git"
3. Connect GitHub repo
4. Build settings:
   - **Build command:** `flutter build web --release`
   - **Publish directory:** `build/web`
5. Deploy!

---

## 🎉 Done!

Your shareable links:
- **Frontend:** https://your-app.netlify.app
- **Backend:** https://your-backend.onrender.com

---

## 📝 Important Notes

⚠️ **Free Tier Limits:**
- Render: Backend sleeps after 15 min inactivity (30s to wake)
- Netlify: 100GB bandwidth/month

💡 **Tips:**
- Custom domain available on both platforms
- HTTPS automatic
- Monitor in dashboards
- Render may need database seeding (see DEPLOYMENT_GUIDE.md)

---

## Need Detailed Guide?

See `DEPLOYMENT_GUIDE.md` for:
- Troubleshooting
- Alternative platforms (Railway)
- Database seeding
- Custom domains
- Production optimizations
