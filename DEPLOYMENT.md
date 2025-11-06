# PSC Nepal - Deployment Guide

This guide walks you through deploying the PSC Nepal application to production using free-tier services.

## Tech Stack for Deployment

- **Backend**: Render (free tier)
- **Database**: Neon.tech PostgreSQL (free tier)
- **Frontend Web**: Firebase Hosting (free tier)
- **Storage**: Firebase Storage (free tier)

---

## Part 1: Database Setup (Neon.tech)

### 1.1 Create Neon.tech Account
1. Go to [Neon.tech](https://neon.tech/)
2. Sign up with GitHub or email
3. Create a new project named `psc-nepal-db`

### 1.2 Get Database Connection String
1. In your Neon dashboard, click on your project
2. Copy the **Connection String** (it looks like):
   ```
   postgresql://username:password@hostname.neon.tech/dbname?sslmode=require
   ```
3. Save this - you'll need it for backend deployment

---

## Part 2: Backend Deployment (Render)

### 2.1 Prepare Your Code
1. Make sure all changes are committed to Git
2. Push your code to GitHub:
   ```bash
   git add .
   git commit -m "Prepare for deployment"
   git push origin main
   ```

### 2.2 Deploy to Render
1. Go to [Render](https://render.com/)
2. Sign up/login with GitHub
3. Click **New +** → **Web Service**
4. Connect your GitHub repository
5. Configure the service:
   - **Name**: `psc-nepal-api`
   - **Region**: Choose closest to your users
   - **Branch**: `main`
   - **Root Directory**: `backend`
   - **Runtime**: `Python 3`
   - **Build Command**: `pip install -r requirements.txt`
   - **Start Command**: `gunicorn psc_nepal.wsgi:application`

### 2.3 Set Environment Variables
In Render dashboard, go to **Environment** tab and add:

```
SECRET_KEY=<generate-a-new-secret-key-here>
DEBUG=false
DATABASE_URL=<your-neon-postgres-connection-string>
ALLOWED_HOSTS=your-app-name.onrender.com
CORS_ALLOWED_ORIGINS=https://your-frontend-domain.web.app
```

**To generate a SECRET_KEY:**
```bash
python -c "from django.core.management.utils import get_random_secret_key; print(get_random_secret_key())"
```

### 2.4 Deploy
1. Click **Create Web Service**
2. Wait for deployment to complete (5-10 minutes)
3. Once deployed, your API will be available at: `https://your-app-name.onrender.com`

### 2.5 Test Your Backend
Visit: `https://your-app-name.onrender.com/api/quizzes/`
You should see a JSON response.

---

## Part 3: Firebase Setup (for Frontend Web + Storage)

### 3.1 Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click **Add Project**
3. Name it `psc-nepal-prep`
4. Disable Google Analytics (optional)
5. Create project

### 3.2 Enable Firebase Storage
1. In Firebase Console, go to **Storage**
2. Click **Get Started**
3. Use production rules (we'll configure later)
4. Choose a location close to your users

### 3.3 Configure Storage Security Rules
In Storage → Rules, paste:
```javascript
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /study-materials/{allPaths=**} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.token.admin == true;
    }
  }
}
```

### 3.4 Get Firebase Config
1. Go to **Project Settings** (gear icon)
2. Scroll to **Your apps** → Click **Web** icon
3. Register app as `PSC Nepal Web`
4. Copy the `firebaseConfig` object

---

## Part 4: Frontend Web Deployment

### 4.1 Update Flutter Web Config
1. Open `frontend/web/index.html`
2. Add Firebase SDK before `</body>`:
```html
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-app-compat.js"></script>
<script src="https://www.gstatic.com/firebasejs/9.0.0/firebase-storage-compat.js"></script>
<script>
  const firebaseConfig = {
    apiKey: "YOUR_API_KEY",
    authDomain: "YOUR_AUTH_DOMAIN",
    projectId: "YOUR_PROJECT_ID",
    storageBucket: "YOUR_STORAGE_BUCKET",
    messagingSenderId: "YOUR_MESSAGING_SENDER_ID",
    appId: "YOUR_APP_ID"
  };
  firebase.initializeApp(firebaseConfig);
</script>
```

### 4.2 Update API Base URL
Edit `frontend/lib/services/api_service.dart`:
```dart
static const String baseUrl = 'https://your-app-name.onrender.com/api';
```

### 4.3 Build Flutter Web
```bash
cd frontend
flutter build web --release
```

### 4.4 Deploy to Firebase Hosting
```bash
# Install Firebase CLI (if not installed)
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in frontend directory
cd frontend
firebase init hosting

# Choose:
# - Use existing project: psc-nepal-prep
# - Public directory: build/web
# - Single-page app: Yes
# - Overwrite index.html: No

# Deploy
firebase deploy --only hosting
```

Your web app will be live at: `https://psc-nepal-prep.web.app`

---

## Part 5: Android APK Build

### 5.1 Update API URL
Make sure `api_service.dart` points to production backend.

### 5.2 Build APK
```bash
cd frontend
flutter build apk --release
```

### 5.3 Find APK
APK location: `frontend/build/app/outputs/flutter-apk/app-release.apk`

### 5.4 Distribute
- Upload to Google Play Store, OR
- Share APK directly for testing

---

## Part 6: Post-Deployment Tasks

### 6.1 Create Admin User
SSH into Render or use Render shell:
```bash
python manage.py createsuperuser
```

### 6.2 Add Initial Data
1. Login to admin panel: `https://your-app-name.onrender.com/admin`
2. Add Subjects, Quizzes, Questions, Study Materials

### 6.3 Upload PDFs to Firebase Storage
1. Go to Firebase Console → Storage
2. Create folder: `study-materials`
3. Upload PDF files
4. Get download URLs
5. Add URLs to Study Materials in Django admin

### 6.4 Update CORS if Needed
If you get CORS errors, update in Render:
```
CORS_ALLOWED_ORIGINS=https://psc-nepal-prep.web.app,https://psc-nepal-prep.firebaseapp.com
```

---

## Monitoring & Maintenance

### Backend Monitoring (Render)
- Check logs in Render dashboard
- Set up alerts for downtime

### Database Monitoring (Neon)
- Monitor storage usage (free tier: 0.5 GB)
- Check connection limits

### Frontend Monitoring (Firebase)
- Monitor hosting usage
- Check storage quota

---

## Troubleshooting

### Issue: Backend returns 500 error
- Check Render logs
- Verify DATABASE_URL is correct
- Ensure migrations ran successfully

### Issue: CORS errors on frontend
- Add frontend domain to CORS_ALLOWED_ORIGINS
- Redeploy backend

### Issue: Static files not loading
- Run `python manage.py collectstatic`
- Verify STATIC_ROOT configuration

### Issue: Database connection failed
- Verify DATABASE_URL format
- Check Neon.tech database is active
- Ensure SSL mode is enabled

---

## Cost & Limits

All services used are **FREE TIER**:

- **Render**: 750 hours/month, sleeps after 15 min inactivity
- **Neon.tech**: 0.5 GB storage, 1 database
- **Firebase Hosting**: 10 GB storage, 360 MB/day transfer
- **Firebase Storage**: 5 GB storage, 1 GB/day download

---

## Next Steps

1. Set up custom domain (optional)
2. Enable Firebase Authentication for additional security
3. Set up automated backups for database
4. Configure monitoring/alerts
5. Add more content (quizzes, materials)

---

## Support

For issues, check:
- Backend logs in Render
- Browser console for frontend errors
- Firebase Console for storage/hosting issues

Good luck with your deployment! 🚀
