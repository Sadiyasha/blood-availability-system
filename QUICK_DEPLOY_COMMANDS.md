# 🚀 QUICK DEPLOY COMMANDS

Copy-paste these commands for instant deployment!

---

## 📦 1. PUSH TO GITHUB

```powershell
# Navigate to project
cd "c:\Users\NIZAM\Desktop\mini proj\blood_availability_system (3) (1)\blood_availability_system (3)\blood_availability_system"

# Initialize git (if needed)
git init

# Add all files
git add .

# Commit
git commit -m "Ready for production deployment"

# Create repository on GitHub first: https://github.com/new
# Repository name: blood-availability-system

# Connect and push
git remote add origin https://github.com/YOUR_USERNAME/blood-availability-system.git
git branch -M main
git push -u origin main
```

**Replace `YOUR_USERNAME` with your actual GitHub username!**

---

## 🔧 2. DEPLOY BACKEND (Render)

### Via Render Dashboard:
1. Go to: https://dashboard.render.com/
2. Click: **"New +"** → **"Blueprint"**
3. Connect GitHub repository
4. Click **"Apply"**
5. Wait 5-10 minutes ⏳
6. **Copy backend URL**: `https://your-app.onrender.com`

### Seed Database:
Once deployed, open Render Shell and run:
```bash
python seed_database.py
```

---

## 🎨 3. DEPLOY FRONTEND (Netlify)

### Build for Production:
```powershell
# Navigate to project
cd "c:\Users\NIZAM\Desktop\mini proj\blood_availability_system (3) (1)\blood_availability_system (3)\blood_availability_system"

# Build with YOUR backend URL (REPLACE THIS!)
flutter build web --release --dart-define=BASE_URL=https://YOUR_BACKEND_URL.onrender.com/api
```

**Example** (use your actual backend URL):
```powershell
flutter build web --release --dart-define=BASE_URL=https://blood-availability-backend.onrender.com/api
```

### Deploy to Netlify:

**Method 1: Drag & Drop** (Fastest ⚡)
1. Go to: https://app.netlify.com/drop
2. Drag folder: `build\web`
3. Done! ✅

**Method 2: Git Integration** (Auto-updates 🔄)
1. Go to: https://app.netlify.com/
2. **"Add new site"** → **"Import existing project"**
3. Connect GitHub → Select repo
4. Build command:
   ```
   flutter build web --release --dart-define=BASE_URL=https://YOUR_BACKEND_URL.onrender.com/api
   ```
5. Publish directory: `build/web`
6. **Deploy site** ✅

---

## ✅ 4. VERIFY DEPLOYMENT

### Test Backend:
```powershell
# In browser, open these URLs:
https://your-backend.onrender.com/api/health
https://your-backend.onrender.com/api/donors/
https://your-backend.onrender.com/api/blood-banks/
```

### Test Frontend:
```
https://your-app.netlify.app
```

**Check**:
- ✅ Registration works
- ✅ Chatbot responds
- ✅ Blood bank search works
- ✅ Notifications show real data

---

## 🔄 UPDATE LATER

### Update Backend:
```powershell
git add .
git commit -m "Update backend"
git push
```
Render auto-deploys ✅

### Update Frontend:
```powershell
# Rebuild
flutter build web --release --dart-define=BASE_URL=https://YOUR_BACKEND_URL.onrender.com/api

# If using Git method: just push
git add .
git commit -m "Update frontend"
git push

# If using drag-drop: drag build\web again to Netlify
```

---

## 📝 IMPORTANT URLS TO SAVE

**Fill these in after deployment**:

```
Backend API:  https://________________________.onrender.com
Frontend App: https://________________________.netlify.app
GitHub Repo:  https://github.com/YOUR_USERNAME/blood-availability-system
```

**Share this with users**: 👉 `https://________________________.netlify.app`

---

## 🐛 QUICK TROUBLESHOOTING

### Backend not responding?
```powershell
# Wait 30-60 seconds (free tier wakes from sleep)
# Then test again
```

### Frontend shows Network Error?
```powershell
# Rebuild with correct backend URL
flutter build web --release --dart-define=BASE_URL=https://YOUR_ACTUAL_BACKEND.onrender.com/api

# Then redeploy to Netlify
```

### Need to see logs?
- **Render**: Dashboard → Service → Logs
- **Netlify**: Dashboard → Deploys → Deploy log
- **Browser**: Press F12 → Console tab

---

## ⚡ ONE-LINE REBUILDS

**Backend + Frontend full redeploy**:
```powershell
git add . ; git commit -m "Update" ; git push ; flutter build web --release --dart-define=BASE_URL=https://YOUR_BACKEND.onrender.com/api
```

Then drag `build\web` to Netlify if using drag-drop method.

---

**Total Time**: 20-30 minutes
**Total Cost**: $0 (free forever!)
**Result**: Live shareable app! 🎉
