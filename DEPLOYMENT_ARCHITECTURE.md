# 🏗️ Deployment Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     PRODUCTION ARCHITECTURE                      │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│                          👤 END USERS                            │
│            (Anyone with internet access worldwide)               │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ HTTPS Request
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                    🌐 NETLIFY (Frontend CDN)                     │
│                 https://your-app.netlify.app                     │
├─────────────────────────────────────────────────────────────────┤
│  📱 Flutter Web App (Dart compiled to JavaScript)               │
│                                                                  │
│  Features:                                                       │
│  ✅ User Registration                                            │
│  ✅ Dashboard with Notifications                                 │
│  ✅ AI Chatbot Interface                                         │
│  ✅ Blood Donor Search                                           │
│  ✅ Blood Bank Finder                                            │
│  ✅ Real-time Updates (polling every 30s)                        │
│                                                                  │
│  Files Deployed:                                                 │
│  - index.html (entry point)                                      │
│  - main.dart.js (compiled Flutter app ~2MB)                      │
│  - flutter.js (Flutter engine)                                   │
│  - canvaskit/ (rendering engine)                                 │
│  - assets/ (fonts, images, etc.)                                 │
│                                                                  │
│  Hosting: Global CDN (Content Delivery Network)                 │
│  Speed: < 1s load time (after first load)                       │
│  Cost: FREE (100 GB bandwidth/month)                             │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ API Calls (HTTP/HTTPS)
                            │ Base URL from --dart-define
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                      🔧 RENDER (Backend API)                     │
│              https://your-backend.onrender.com                   │
├─────────────────────────────────────────────────────────────────┤
│  ⚙️ Flask REST API (Python 3.11)                                 │
│                                                                  │
│  Endpoints:                                                      │
│  - GET  /api/health (health check)                              │
│  - GET  /api/donors/ (list all donors)                          │
│  - POST /api/donors/ (create new donor)                         │
│  - GET  /api/blood-banks/ (search blood banks)                  │
│  - GET  /api/hospitals/ (list hospitals)                        │
│  - POST /api/chatbot/query (AI chat)                            │
│  - GET  /api/notifications/ (get notifications)                 │
│  - POST /api/smart-match/ (donor matching)                      │
│                                                                  │
│  Technologies:                                                   │
│  - Flask (web framework)                                         │
│  - SQLAlchemy (database ORM)                                     │
│  - Gunicorn (production server)                                  │
│  - scikit-learn (AI matching)                                    │
│  - NLTK (natural language processing)                            │
│                                                                  │
│  Features:                                                       │
│  ✅ RESTful API design                                           │
│  ✅ CORS enabled for frontend                                    │
│  ✅ AI-powered donor matching (100-point scoring)                │
│  ✅ NLP chatbot for user queries                                 │
│  ✅ Geolocation distance calculation                             │
│                                                                  │
│  Hosting: Render Free Tier                                       │
│  Speed: ~200ms response time                                     │
│  Sleep: After 15 min inactivity (wakes in 30-60s)               │
│  Cost: FREE (512 MB RAM, 750 hours/month)                        │
└───────────────────────────┬─────────────────────────────────────┘
                            │
                            │ SQL Queries
                            │ SQLAlchemy ORM
                            ▼
┌─────────────────────────────────────────────────────────────────┐
│                  🗄️ RENDER POSTGRESQL DATABASE                   │
│                   blood-availability-db                          │
├─────────────────────────────────────────────────────────────────┤
│  Tables:                                                         │
│  - donors (150+ records)                                         │
│  - blood_banks (41 records)                                      │
│  - hospitals (58 records)                                        │
│  - blood_requests (30+ records)                                  │
│  - notifications (20+ records)                                   │
│                                                                  │
│  Data:                                                           │
│  ✅ Clean donor names (no "Synthetic")                           │
│  ✅ Real blood bank information                                  │
│  ✅ Hospital contact details                                      │
│  ✅ Blood requests with status tracking                          │
│  ✅ User notifications with timestamps                            │
│                                                                  │
│  Features:                                                       │
│  - PostgreSQL 14+                                                │
│  - Automatic backups (90 days retention)                         │
│  - Connection pooling                                             │
│  - ACID compliance                                                │
│                                                                  │
│  Hosting: Render Managed PostgreSQL                              │
│  Size: 1 GB storage (free tier)                                  │
│  Cost: FREE                                                       │
└─────────────────────────────────────────────────────────────────┘


┌─────────────────────────────────────────────────────────────────┐
│                      📊 DATA FLOW DIAGRAM                        │
└─────────────────────────────────────────────────────────────────┘

USER REGISTRATION:
User → Netlify Frontend → Enters details → Flutter saves to localStorage
                       ↓
                Frontend calls POST /api/donors/
                       ↓
                Render Backend → Validates data → Creates donor
                       ↓
                PostgreSQL → Stores donor record
                       ↓
                Backend returns success ← Frontend shows confirmation


BLOOD SEARCH (Chatbot):
User → Netlify Frontend → Types "O+ blood in Mumbai"
                       ↓
                Frontend calls POST /api/chatbot/query
                       ↓
                Render Backend → NLP parses query → Identifies:
                                  - Blood type: O+
                                  - City: Mumbai
                       ↓
                Backend calls AI matching service
                       ↓
                PostgreSQL → Queries donors table
                       ↓
                Backend → Scores matches (0-100 points)
                         → Filters score ≥ 75
                         → Returns top 5 donors
                       ↓
                Frontend displays donor cards with scores


NOTIFICATIONS:
Timer (every 30s) → Frontend calls GET /api/notifications/
                       ↓
                Render Backend → Queries notifications table
                       ↓
                PostgreSQL → Returns unread notifications
                       ↓
                Frontend updates bell icon count
                       ↓
                User clicks notification → Mark as read
                       ↓
                Frontend calls POST /api/notifications/{id}/read


┌─────────────────────────────────────────────────────────────────┐
│                     🔐 SECURITY FEATURES                         │
└─────────────────────────────────────────────────────────────────┘

✅ HTTPS encryption (automatic on both Netlify & Render)
✅ CORS restricted to frontend domain
✅ SQL injection prevention (SQLAlchemy parameterized queries)
✅ XSS protection (Content Security Policy headers)
✅ Environment variables for secrets (SECRET_KEY, DATABASE_URL)
✅ No hardcoded credentials in code
✅ PostgreSQL password encryption
✅ SSL/TLS for database connections


┌─────────────────────────────────────────────────────────────────┐
│                    📈 SCALABILITY & LIMITS                       │
└─────────────────────────────────────────────────────────────────┘

FREE TIER LIMITS:

Netlify (Frontend):
✅ 100 GB bandwidth/month (~500,000 page loads)
✅ 300 build minutes/month
✅ Unlimited sites
✅ Instant cache invalidation
⚠️ No custom domain SSL on free tier (but .netlify.app has SSL)

Render (Backend):
✅ 750 hours/month (enough for 24/7 operation)
✅ 512 MB RAM (handles ~50 concurrent requests)
✅ Shared CPU
⚠️ Sleeps after 15 min inactivity (first request takes 30-60s)
⚠️ 1 free web service per account
✅ 100 GB bandwidth/month

PostgreSQL (Database):
✅ 1 GB storage (~10,000 donor records)
✅ 90 days automatic backups
✅ 100 simultaneous connections
⚠️ Limited to 1 database per account (free tier)

WHEN TO UPGRADE:
- Heavy traffic? → Render paid ($7/mo) = no sleeping
- Large database? → Render paid ($15/mo) = 10 GB storage
- High bandwidth? → Netlify Pro ($19/mo) = 1 TB bandwidth


┌─────────────────────────────────────────────────────────────────┐
│                      🔄 CI/CD PIPELINE                           │
└─────────────────────────────────────────────────────────────────┘

CODE CHANGES:
Developer → Makes changes locally
         ↓
    git add .
    git commit -m "Update feature"
    git push
         ↓
    GitHub → Receives push
         ↓
    ├─→ Render detects changes → Auto-deploy backend (2-3 min)
    │                          → Run migrations
    │                          → Restart service
    │
    └─→ Netlify detects changes → Auto-build frontend (2-3 min)
                                → Run flutter build web
                                → Deploy to CDN
                                → Purge cache

ZERO DOWNTIME: Both platforms use rolling deployments


┌─────────────────────────────────────────────────────────────────┐
│                    🌍 GLOBAL ACCESSIBILITY                       │
└─────────────────────────────────────────────────────────────────┘

Frontend (Netlify CDN):
- Deployed to 100+ edge locations worldwide
- Users connect to nearest edge server
- Response time: < 100ms globally

Backend (Render):
- Hosted in Oregon, USA datacenter
- Global latency: 50-300ms depending on user location
- Can upgrade to multi-region for better performance

Database (Render):
- Same datacenter as backend (Oregon)
- Low latency for backend-database communication (< 5ms)


┌─────────────────────────────────────────────────────────────────┐
│                       💰 TOTAL COST                              │
└─────────────────────────────────────────────────────────────────┘

DEPLOYMENT: $0/month

What you get for FREE:
✅ Production-ready backend API
✅ Global CDN for frontend
✅ PostgreSQL database with backups
✅ HTTPS/SSL certificates
✅ Automatic deployments
✅ 99.9% uptime SLA
✅ DDoS protection
✅ Global edge caching

Future costs (optional):
- Custom domain: $10-15/year
- Render paid (no sleeping): $7/month
- Netlify Pro (1TB bandwidth): $19/month
- Total potential: ~$30-35/month (only if needed)


┌─────────────────────────────────────────────────────────────────┐
│                      📞 MONITORING                               │
└─────────────────────────────────────────────────────────────────┘

Render Dashboard:
- Real-time logs
- CPU/Memory graphs
- Request metrics
- Error tracking

Netlify Dashboard:
- Build logs
- Deploy history
- Bandwidth usage
- Form submissions

Health Checks:
- Render pings /api/health every 5 minutes
- Auto-restart if unhealthy
- Email alerts on failures


┌─────────────────────────────────────────────────────────────────┐
│                   ✅ DEPLOYMENT COMPLETE!                        │
└─────────────────────────────────────────────────────────────────┘

Your app is now live at:

Frontend: https://your-app.netlify.app
Backend:  https://your-backend.onrender.com

Share the frontend URL with anyone worldwide! 🌍
```
