# Quick Deployment Commands

# Step 1: Initialize Git Repository
Write-Host "Step 1: Initializing Git Repository..." -ForegroundColor Green
git init
git add .
git commit -m "Initial commit for deployment"

# Step 2: Instructions for GitHub
Write-Host "`nStep 2: Create GitHub Repository" -ForegroundColor Yellow
Write-Host "1. Go to https://github.com/new"
Write-Host "2. Repository name: blood-availability-system"
Write-Host "3. Keep it public"
Write-Host "4. Don't initialize with README"
Write-Host "5. Click 'Create repository'"
Write-Host "`nPress Enter after creating the repository..."
Read-Host

# Step 3: Get GitHub URL
Write-Host "`nStep 3: Enter your GitHub repository URL" -ForegroundColor Yellow
Write-Host "Format: https://github.com/YOUR_USERNAME/blood-availability-system.git"
$repoUrl = Read-Host "Enter URL"

git remote add origin $repoUrl
git branch -M main
git push -u origin main

Write-Host "`n✅ Code pushed to GitHub!" -ForegroundColor Green

# Step 4: Backend Deployment
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "BACKEND DEPLOYMENT (Render)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "1. Go to https://render.com/signup"
Write-Host "2. Sign up with GitHub"
Write-Host "3. Click 'New +' → 'Web Service'"
Write-Host "4. Connect your repository: blood-availability-system"
Write-Host "5. Configure:"
Write-Host "   - Name: blood-availability-backend"
Write-Host "   - Root Directory: backend"
Write-Host "   - Environment: Python 3"
Write-Host "   - Build Command: pip install -r requirements.txt"
Write-Host "   - Start Command: gunicorn app:app"
Write-Host "6. Add Environment Variables:"
Write-Host "   - PYTHON_VERSION = 3.11.0"
Write-Host "   - FLASK_ENV = production"
Write-Host "7. Click 'Create Web Service'"
Write-Host "8. Wait 5-10 minutes for deployment"
Write-Host "`nPress Enter after deployment completes..."
Read-Host

Write-Host "`nEnter your Render backend URL (e.g., https://blood-availability-backend.onrender.com):"
$backendUrl = Read-Host "Backend URL"

Write-Host "`n✅ Backend URL saved: $backendUrl" -ForegroundColor Green

# Step 5: Update Frontend API URL
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "UPDATING FRONTEND API URL" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "⚠️  IMPORTANT: You need to manually update the API URL in lib/main.dart" -ForegroundColor Red
Write-Host "`nSearch for: final String baseUrl = 'http://127.0.0.1:5000';"
Write-Host "Replace with: final String baseUrl = '$backendUrl';"
Write-Host "`nPress Enter after updating the file..."
Read-Host

# Commit the change
git add lib/main.dart
git commit -m "Update API URL for production"
git push

# Step 6: Build Flutter Web
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "BUILDING FLUTTER WEB APP" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
flutter build web --release

Write-Host "`n✅ Flutter web app built successfully!" -ForegroundColor Green

# Step 7: Frontend Deployment
Write-Host "`n========================================" -ForegroundColor Cyan
Write-Host "FRONTEND DEPLOYMENT (Netlify)" -ForegroundColor Cyan
Write-Host "========================================" -ForegroundColor Cyan
Write-Host "Option 1: Manual Deploy (Drag & Drop)"
Write-Host "1. Go to https://app.netlify.com/drop"
Write-Host "2. Drag the 'build\web' folder to the upload area"
Write-Host "3. Wait for deployment (1-2 minutes)"
Write-Host "4. Copy your site URL"
Write-Host "`nOption 2: Git Deploy (Recommended)"
Write-Host "1. Go to https://app.netlify.com"
Write-Host "2. Click 'Add new site' → 'Import an existing project'"
Write-Host "3. Connect to GitHub"
Write-Host "4. Select: blood-availability-system"
Write-Host "5. Build settings:"
Write-Host "   - Build command: flutter build web --release"
Write-Host "   - Publish directory: build/web"
Write-Host "6. Click 'Deploy site'"
Write-Host "7. Copy your site URL"

Write-Host "`n========================================" -ForegroundColor Green
Write-Host "DEPLOYMENT COMPLETE! 🎉" -ForegroundColor Green
Write-Host "========================================" -ForegroundColor Green
Write-Host "`nYour app is now live!"
Write-Host "Backend API: $backendUrl"
Write-Host "Frontend URL: (Copy from Netlify)"
Write-Host "`nShare these links with anyone! 🚀"
