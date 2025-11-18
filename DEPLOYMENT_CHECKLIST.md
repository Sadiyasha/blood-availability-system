# 📋 Deployment Checklist

Use this checklist to track your deployment progress!

---

## ✅ PRE-DEPLOYMENT (Preparation)

- [ ] GitHub account created
- [ ] Render account created (https://render.com)
- [ ] Netlify account created (https://netlify.com)
- [ ] Git installed on computer
- [ ] All code changes committed locally
- [ ] Backend tested locally (`python app.py` works)
- [ ] Frontend tested locally (`flutter run -d chrome` works)
- [ ] All features working:
  - [ ] User registration saves to database
  - [ ] Chatbot shows 2 buttons only (no "Show More Donors")
  - [ ] Top donors filter shows score ≥75
  - [ ] Blood banks display correctly
  - [ ] Notifications show real data

---

## 🔧 BACKEND DEPLOYMENT (Render)

### GitHub Setup
- [ ] Repository created on GitHub
- [ ] Code pushed to GitHub main branch
- [ ] `backend/render.yaml` file exists
- [ ] `backend/requirements.txt` includes `psycopg2-binary`
- [ ] `backend/config.py` supports PostgreSQL

### Render Deployment
- [ ] Logged into Render dashboard
- [ ] Clicked "New +" → "Blueprint"
- [ ] Connected GitHub repository
- [ ] Render detected `render.yaml` automatically
- [ ] Clicked "Apply" to create services
- [ ] Deployment started successfully
- [ ] Wait 5-10 minutes for completion
- [ ] Backend service shows "Live" status
- [ ] Database shows "Available" status

### Backend Verification
- [ ] Backend URL copied: `https://________________.onrender.com`
- [ ] Health check works: `/api/health` returns 200 OK
- [ ] Opened Render Shell
- [ ] Ran `python seed_database.py` successfully
- [ ] Verified donors: `/api/donors/` returns 150 donors
- [ ] Verified blood banks: `/api/blood-banks/` returns 41 banks
- [ ] Verified hospitals: `/api/hospitals/` returns data
- [ ] API responds without errors

---

## 🎨 FRONTEND DEPLOYMENT (Netlify)

### Build Preparation
- [ ] Backend URL copied from Render
- [ ] Opened PowerShell in project folder
- [ ] Ran build command with correct backend URL:
  ```powershell
  flutter build web --release --dart-define=BASE_URL=https://YOUR_BACKEND_URL.onrender.com/api
  ```
- [ ] Build completed successfully: `√ Built build\web`
- [ ] `build/web` folder contains files (index.html, main.dart.js, etc.)

### Netlify Deployment (Choose One)

**Option A: Drag & Drop**
- [ ] Opened https://app.netlify.com/drop
- [ ] Navigated to `build/web` folder in File Explorer
- [ ] Dragged `web` folder to Netlify
- [ ] Upload completed successfully
- [ ] Got deployment URL: `https://______________.netlify.app`

**Option B: Git Integration**
- [ ] Logged into Netlify
- [ ] Clicked "Add new site" → "Import existing project"
- [ ] Connected to GitHub
- [ ] Selected repository
- [ ] Configured build settings:
  - [ ] Build command includes backend URL
  - [ ] Publish directory: `build/web`
- [ ] Clicked "Deploy site"
- [ ] Deployment completed successfully
- [ ] Got deployment URL: `https://______________.netlify.app`

### Custom URL (Optional)
- [ ] Clicked "Site settings" → "Change site name"
- [ ] Entered custom name: `blood-availability-app`
- [ ] New URL: `https://blood-availability-app.netlify.app`

---

## ✅ POST-DEPLOYMENT TESTING

### Backend Tests
- [ ] Health endpoint works: `https://your-backend.onrender.com/api/health`
- [ ] Donors endpoint: `https://your-backend.onrender.com/api/donors/`
- [ ] Blood banks endpoint: `https://your-backend.onrender.com/api/blood-banks/`
- [ ] Chatbot endpoint responds
- [ ] No 500 errors in Render logs

### Frontend Tests
- [ ] **App loads**: `https://your-app.netlify.app` opens successfully
- [ ] **Registration page**: Visible and functional
- [ ] **Register new user**: Creates user successfully
- [ ] **Dashboard**: Loads without errors
- [ ] **Notifications**: Display real data (not fake)
- [ ] **Notification count**: Shows correct unread count
- [ ] **Chatbot button**: Opens chatbot interface
- [ ] **Chatbot response**: AI responds to messages
- [ ] **Quick actions**: Shows 2 buttons only (Contact Top Donors, Check Blood Banks)
- [ ] **NO "Show More Donors"**: Button is removed ✅
- [ ] **NO "Register" button**: Removed from chatbot ✅
- [ ] **Top Donors filter**: Click → Shows only donors with score ≥75
- [ ] **Donor scores visible**: Each donor shows match score
- [ ] **Blood bank search**: Type city → Shows actual blood banks
- [ ] **Blood bank results**: Names, cities, units, phone numbers visible
- [ ] **Distance or N/A**: Shows correctly
- [ ] **Mobile responsive**: Test on phone browser
- [ ] **HTTPS enabled**: URL shows 🔒 padlock

### Cross-Browser Testing
- [ ] Works on Chrome
- [ ] Works on Firefox
- [ ] Works on Edge
- [ ] Works on Safari (if available)
- [ ] Works on mobile Chrome
- [ ] Works on mobile Safari

### Performance
- [ ] First load: Under 3 seconds (after backend wakes up)
- [ ] Subsequent loads: Under 1 second
- [ ] API calls: Complete within 2 seconds
- [ ] Backend wake-up: 30-60 seconds (free tier - expected)

---

## 🎯 FINAL VERIFICATION

### Features Checklist
- [ ] **User Registration**:
  - [ ] Saves to localStorage
  - [ ] Saves to backend database
  - [ ] Confirmation message appears
  
- [ ] **Chatbot**:
  - [ ] Responds to "Find donors"
  - [ ] Responds to "Blood banks"
  - [ ] Responds to "Eligibility"
  - [ ] Shows correct quick actions
  - [ ] NO "Show More Donors" button
  - [ ] NO "Register" button
  
- [ ] **Top Donors**:
  - [ ] Filters score ≥75
  - [ ] Shows maximum 5 donors
  - [ ] Displays match scores
  - [ ] Shows contact information
  
- [ ] **Blood Banks**:
  - [ ] Search by city works
  - [ ] Shows real bank names
  - [ ] Displays units available
  - [ ] Shows phone numbers
  
- [ ] **Notifications**:
  - [ ] Fetches from backend API
  - [ ] Updates every 30 seconds
  - [ ] Shows unread count
  - [ ] Mark as read works
  
- [ ] **Data Persistence**:
  - [ ] Registered users persist after refresh
  - [ ] Donors visible in backend database
  - [ ] Notifications stored in database

---

## 📊 DEPLOYMENT SUMMARY

**Record your live URLs here**:

🔗 **Backend API**: `https://________________________________.onrender.com`

🔗 **Frontend App**: `https://________________________________.netlify.app`

**Database Info**:
- Type: PostgreSQL (Render)
- Donors: 150
- Blood Banks: 41
- Hospitals: 58
- Notifications: 20+

**Deployment Date**: _______________

**Deployment Time**: _______ minutes

**Status**: ✅ Live and Operational

---

## 🎉 READY TO SHARE!

Your app is now live! Share these links:

**Public Link (for users)**:
```
https://your-app.netlify.app
```

**API Documentation (for developers)**:
```
https://your-backend.onrender.com/api/health
https://your-backend.onrender.com/api/donors/
https://your-backend.onrender.com/api/blood-banks/
https://your-backend.onrender.com/api/hospitals/
```

**Features Users Can Access**:
✅ Register as blood donors
✅ Search for blood by type and location
✅ Chat with AI assistant for blood-related queries
✅ View nearby blood banks with contact info
✅ See real-time donor availability
✅ Match with high-score donors (≥75)
✅ Receive notifications
✅ Access from any device with internet

---

## 🔄 MAINTENANCE CHECKLIST

**Weekly**:
- [ ] Check backend is running (visit health endpoint)
- [ ] Verify frontend loads correctly
- [ ] Test one registration
- [ ] Check Render logs for errors

**Monthly**:
- [ ] Review database size (free tier: 1 GB)
- [ ] Check bandwidth usage
- [ ] Test all features end-to-end
- [ ] Backup database (Render auto-backups, but verify)

**When Issues Arise**:
- [ ] Check Render logs: Dashboard → Service → Logs
- [ ] Check Netlify logs: Dashboard → Deploys → Deploy log
- [ ] Test backend health endpoint
- [ ] Check browser console (F12) for errors
- [ ] Verify backend URL in frontend build

---

**Congratulations!** 🎊 

Your Blood Availability System is deployed and ready to help save lives! 🩸

**Share your app**: `https://your-app.netlify.app`
