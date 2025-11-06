# PSC Nepal - Quick Start Guide

Get the PSC Nepal app running locally in under 10 minutes!

## Prerequisites

- Python 3.8+ installed
- Flutter SDK installed ([Installation Guide](https://docs.flutter.dev/get-started/install))
- Git installed
- A code editor (VS Code recommended)

---

## Step 1: Clone the Repository

```bash
git clone <your-repo-url>
cd PSC-nepal
```

---

## Step 2: Backend Setup (5 minutes)

### 1. Navigate to backend
```bash
cd backend
```

### 2. Create and activate virtual environment

**Windows:**
```bash
python -m venv venv
venv\Scripts\activate
```

**Mac/Linux:**
```bash
python3 -m venv venv
source venv/bin/activate
```

### 3. Install dependencies
```bash
pip install -r requirements.txt
```

### 4. Run migrations
```bash
python manage.py migrate
```

### 5. Seed sample data
```bash
python seed_data.py
```

This creates:
- Admin user (username: `admin`, password: `admin123`)
- 8 subjects (GK, Nepali, English, etc.)
- Sample quiz with 5 questions
- Study materials
- Notifications

### 6. Start the backend server
```bash
python manage.py runserver
```

✅ Backend is now running at `http://localhost:8000`

**Test it:** Visit `http://localhost:8000/api/quizzes/` - you should see JSON data

---

## Step 3: Frontend Setup (3 minutes)

### 1. Open a new terminal and navigate to frontend
```bash
cd frontend
```

### 2. Install Flutter dependencies
```bash
flutter pub get
```

### 3. Run the app

**For Chrome/Edge (easiest):**
```bash
flutter run -d chrome
```

**For Android Emulator:**
```bash
flutter run
```

**For Physical Device:**
- Connect your phone via USB
- Enable USB debugging
- Run: `flutter run`

✅ Frontend is now running!

---

## Step 4: Test the App

### Create a test account
1. Click "Register" on the login screen
2. Fill in:
   - Username: `testuser`
   - Email: `test@example.com`
   - Password: `test123`
3. Click "Register"

### Try these features:
- ✅ Take a quiz (GK Quiz is already loaded)
- ✅ View your results
- ✅ Check analytics (after taking at least one quiz)
- ✅ View study materials
- ✅ Check notifications
- ✅ Update your profile

---

## Step 5: Access Admin Panel (Optional)

1. Visit `http://localhost:8000/admin`
2. Login with:
   - Username: `admin`
   - Password: `admin123`

### Add more content:
- Create more quizzes
- Add questions
- Upload study materials
- Send notifications

---

## Common Issues & Solutions

### Issue: "Connection refused" error in Flutter app
**Solution:** Make sure the backend is running on port 8000

### Issue: "Module not found" in backend
**Solution:** Make sure virtual environment is activated and dependencies are installed:
```bash
pip install -r requirements.txt
```

### Issue: Flutter command not found
**Solution:** Install Flutter SDK and add to PATH:
- [Windows](https://docs.flutter.dev/get-started/install/windows)
- [Mac](https://docs.flutter.dev/get-started/install/macos)
- [Linux](https://docs.flutter.dev/get-started/install/linux)

### Issue: CORS error in browser
**Solution:** Backend is configured to allow all origins in development. If issue persists, check that backend is running.

### Issue: No data showing in app
**Solution:** Run the seed script:
```bash
cd backend
python seed_data.py
```

---

## Next Steps

### For Development:
1. Read the full [README.md](README.md) for detailed information
2. Check out the API endpoints documentation
3. Explore the codebase structure

### For Deployment:
1. Read [DEPLOYMENT.md](DEPLOYMENT.md) for production deployment
2. Set up Neon.tech database
3. Deploy to Render
4. Deploy web app to Firebase Hosting

---

## Project Structure

```
PSC-nepal/
├── backend/                # Django REST Framework API
│   ├── psc_nepal/         # Project settings
│   ├── quizzes/           # Main app (models, views, serializers)
│   ├── manage.py
│   ├── seed_data.py       # Sample data script
│   └── requirements.txt
│
├── frontend/              # Flutter app
│   ├── lib/
│   │   ├── screens/       # UI screens
│   │   ├── services/      # API service
│   │   ├── providers/     # State management
│   │   └── theme/         # App theme
│   └── pubspec.yaml
│
├── README.md              # Full documentation
├── QUICKSTART.md          # This file
└── DEPLOYMENT.md          # Deployment guide
```

---

## API Endpoints (for reference)

### Authentication
- `POST /api/auth/register/` - Register new user
- `POST /api/auth/login/` - Login user

### Quizzes
- `GET /api/quizzes/` - List all quizzes
- `GET /api/quizzes/{id}/questions/` - Get quiz questions
- `POST /api/results/submit/` - Submit quiz answers

### Analytics
- `GET /api/analytics/` - Get user analytics (requires auth)

### Study Materials
- `GET /api/study-materials/` - List study materials

### Other
- `GET /api/notifications/` - Get notifications
- `GET /api/subjects/` - List subjects
- `GET /api/badges/` - Get user badges (requires auth)
- `GET /api/streak/` - Get user streak (requires auth)

---

## Help & Support

- **Issues**: Open an issue on GitHub
- **Questions**: Check existing issues or create a new one
- **Documentation**: See README.md and DEPLOYMENT.md

---

## Quick Commands Cheat Sheet

### Backend
```bash
# Activate virtual environment
venv\Scripts\activate          # Windows
source venv/bin/activate       # Mac/Linux

# Run server
python manage.py runserver

# Create superuser
python manage.py createsuperuser

# Make migrations
python manage.py makemigrations
python manage.py migrate

# Seed data
python seed_data.py
```

### Frontend
```bash
# Get dependencies
flutter pub get

# Run on Chrome
flutter run -d chrome

# Run on Android
flutter run

# Build APK
flutter build apk --release

# Build Web
flutter build web --release
```

---

Happy coding! 🚀

If you encounter any issues, check the [TROUBLESHOOTING.md](TROUBLESHOOTING.md) or open an issue.
