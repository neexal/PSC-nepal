# PSC Nepal - Civil Service Exam Preparation App

A comprehensive mobile and web application designed to help Nepali civil service (PSC) exam aspirants study efficiently, practice questions, track performance, and access study materials.

## Features

### Core Features
- ✅ **User Registration & Login** - Secure authentication with token-based system
- ✅ **Study Materials** - Access PDFs, notes, and links organized by category
- ✅ **Mock Tests & Quizzes** - Timed quizzes with multiple-choice questions
- ✅ **Performance Tracking & Analytics** - Detailed analytics showing performance, weak topics, and category-wise stats
- ✅ **Notifications** - Exam updates, reminders, and news
- ✅ **User Profile** - Manage profile information and target PSC posts
- 🆕 **Admin Panel Quiz Upload** - Upload quizzes with JSON directly from browser (no terminal needed!)
- 🆕 **Auto-Generated Topics** - Automatically creates quiz topics like "Subject Quiz #1"
- 🆕 **Bulk Question Import** - Upload 10, 20, 50+ questions at once
- 🆕 **Streak & Badge System** - Track daily activity and earn achievements

### Technology Stack

#### Frontend
- **Framework**: Flutter (Cross-platform: Android, iOS, Web)
- **State Management**: Provider
- **HTTP Client**: http
- **Local Storage**: SharedPreferences, Hive
- **Charts**: fl_chart
- **Firebase**: Core, Auth, Messaging, Analytics (optional)

#### Backend
- **Framework**: Django REST Framework
- **Database**: SQLite (development) / PostgreSQL (production)
- **Authentication**: Token-based authentication
- **CORS**: django-cors-headers

## Project Structure

```
PSC-nepal/
├── backend/                 # Django backend
│   ├── psc_nepal/          # Django project settings
│   ├── quizzes/            # Main app with models, views, serializers
│   ├── manage.py
│   └── requirements.txt
├── frontend/               # Flutter frontend
│   ├── lib/
│   │   ├── main.dart
│   │   ├── providers/      # State management
│   │   ├── screens/        # App screens
│   │   └── services/       # API service layer
│   └── pubspec.yaml
└── README.md
```

## Installation & Setup

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create virtual environment**
   ```bash
   python -m venv venv
   ```

3. **Activate virtual environment**
   - Windows:
     ```bash
     venv\Scripts\activate
     ```
   - Linux/Mac:
     ```bash
     source venv/bin/activate
     ```

4. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

5. **Run migrations**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

6. **Seed sample data (recommended)**
   ```bash
   python seed_data.py
   ```
   This creates:
   - Admin user (username: `admin`, password: `admin123`)
   - Sample subjects (GK, Nepali, English, etc.)
   - Sample quiz with questions
   - Study materials
   - Notifications

7. **Run development server**
   ```bash
   python manage.py runserver
   ```

   The backend will be available at `http://localhost:8000`
   Admin panel: `http://localhost:8000/admin`
   
   **Note**: If seeding fails, you can create superuser manually:
   ```bash
   python manage.py createsuperuser
   ```

### Frontend Setup

1. **Navigate to frontend directory**
   ```bash
   cd frontend
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Update API URL** (if needed)
   Edit `frontend/lib/services/api_service.dart` and update the `baseUrl`:
   ```dart
   static const String baseUrl = 'http://YOUR_BACKEND_IP:8000/api';
   ```

4. **Run the app**
   ```bash
   flutter run
   ```

## 📚 Adding Quizzes (New!)

You can add quizzes easily from the **Admin Panel** (no terminal commands needed):

### Quick Method: Admin Panel Upload

1. **Open admin panel:** http://localhost:8000/admin/
2. **Login** with admin credentials
3. **Click "Quizzes"** → **"Add Quiz"**
4. **Fill basic info:**
   - Title: "Nepal History Practice"
   - Subject: Select from dropdown (e.g., "General Knowledge")
   - Category: GK, Nepali, English, or IT
   - Duration: 20 (minutes)
5. **Paste JSON questions** in the "Bulk Upload Questions" section:
   ```json
   {
     "questions": [
       {
         "question_text": "What is the capital of Nepal?",
         "options": ["Kathmandu", "Pokhara", "Lalitpur", "Bhaktapur"],
         "correct_option": 0,
         "explanation": "Kathmandu is the capital city.",
         "difficulty": "easy"
       }
     ]
   }
   ```
6. **Click "Save"** - Done! ✅

**Features:**
- ✅ Upload 10, 20, 50+ questions at once
- ✅ Auto-generates topic (e.g., "General Knowledge Quiz #1")
- ✅ Auto-counts total questions
- ✅ Validates JSON before saving
- ✅ Works on cloud/production

**Full Guide:** See [ADMIN_QUIZ_UPLOAD.md](backend/ADMIN_QUIZ_UPLOAD.md)

**Sample Templates:** Check `backend/quiz_data/` folder for examples

## API Endpoints

### Authentication
- `POST /api/auth/register/` - Register new user
- `POST /api/auth/login/` - Login user

### Quizzes
- `GET /api/quizzes/` - List all quizzes
- `GET /api/quizzes/{id}/questions/` - Get quiz questions
- `POST /api/results/submit/` - Submit quiz answers

### Results
- `GET /api/results/` - Get user's quiz results

### Study Materials
- `GET /api/study-materials/` - List all study materials
- `POST /api/study-materials/{id}/increment_download/` - Increment download count

### Notifications
- `GET /api/notifications/` - Get all active notifications

### Analytics
- `GET /api/analytics/` - Get user performance analytics

### Profile
- `GET /api/profile/` - Get user profile
- `POST /api/profile/` - Create user profile
- `PUT /api/profile/{id}/` - Update user profile

## Database Models

### User
- Extended Django User model with profile information

### Quiz
- Title, category, total questions, duration

### Question
- Question text, options (JSON), correct option, explanation, difficulty

### Result
- User, quiz, score, correct/wrong count, date taken

### StudyMaterial
- Title, topic, category, material type, file URL, description, download count

### Notification
- Title, message, notification type, timestamp, target users

### UserProfile
- User, role, phone, address, target post, profile picture

## Configuration

### Backend Configuration

1. **Update ALLOWED_HOSTS** in `backend/psc_nepal/settings.py`
   ```python
   ALLOWED_HOSTS = ['your-domain.com', 'localhost', '127.0.0.1']
   ```

2. **Update CORS settings** (if needed)
   ```python
   CORS_ALLOW_ALL_ORIGINS = True  # Set to False in production
   CORS_ALLOWED_ORIGINS = [
       "http://localhost:3000",
       "https://your-domain.com",
   ]
   ```

### Frontend Configuration

1. **Update API base URL** in `frontend/lib/services/api_service.dart`
   ```dart
   static const String baseUrl = 'http://YOUR_BACKEND_IP:8000/api';
   ```

2. **Firebase Setup** (Optional)
   - Add `google-services.json` (Android) to `frontend/android/app/`
   - Add `GoogleService-Info.plist` (iOS) to `frontend/ios/Runner/`
   - Uncomment Firebase initialization in `main.dart`

## Deployment

### Backend Deployment

#### Using Render (Free Tier)
1. Create a new Web Service on Render
2. Connect your GitHub repository
3. Set build command: `pip install -r requirements.txt`
4. Set start command: `gunicorn psc_nepal.wsgi:application`
5. Add environment variables:
   - `SECRET_KEY`: Django secret key
   - `DATABASE_URL`: PostgreSQL connection string

#### Using Railway (Free Tier)
1. Create a new project on Railway
2. Connect your GitHub repository
3. Railway will auto-detect Django and install dependencies
4. Add PostgreSQL database addon
5. Update `DATABASES` in settings.py to use PostgreSQL

### Frontend Deployment

#### Android APK
```bash
cd frontend
flutter build apk --release
```
APK will be in `frontend/build/app/outputs/flutter-apk/app-release.apk`

#### iOS (Requires Apple Developer Account)
```bash
cd frontend
flutter build ios --release
```

## Free Tier Services

This project uses free tier services:

- **Render**: 500 hours/month free hosting
- **Railway**: Free tier with PostgreSQL
- **Supabase**: 500MB database, 500MB storage
- **Firebase**: 5GB storage, unlimited messaging
- **Firebase Analytics**: Free unlimited events

## Development

### Adding New Features

1. **Backend**: Add models in `backend/quizzes/models.py`, create serializers and views
2. **Frontend**: Create new screens in `frontend/lib/screens/` and add routes
3. **API**: Update `frontend/lib/services/api_service.dart` with new endpoints

### Running Tests

**Backend:**
```bash
cd backend
python manage.py test
```

**Frontend:**
```bash
cd frontend
flutter test
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Submit a pull request

## License

This project is open source and available under the MIT License.

## Support

For issues and questions, please open an issue on GitHub.

## New Features (2024 Update)

### Backend
- ✅ **JWT Authentication** - Modern token-based auth (alongside existing Token auth)
- ✅ **Subject Management** - Organize quizzes and questions by subject
- ✅ **Streaks & Badges** - Track user engagement and achievements
- ✅ **Enhanced Analytics** - Includes streak, badges, last 5 attempts
- ✅ **Production Ready** - PostgreSQL support, WhiteNoise static files, environment variables

### Frontend
- ✅ **Streak Display** - Shows current and longest streak on Analytics & Profile
- ✅ **Badge System** - Displays earned badges
- ✅ **In-app PDF Viewer** - View study materials without downloading
- ✅ **Charts & Graphs** - Visual performance tracking with fl_chart
- ✅ **Modern UI** - Clean design with rounded cards, gradients, and animations

## Deployment

For detailed deployment instructions to production (Render + Neon + Firebase), see [DEPLOYMENT.md](DEPLOYMENT.md).

Quick deployment summary:
1. **Database**: Neon.tech PostgreSQL (free)
2. **Backend**: Render.com (free tier)
3. **Frontend Web**: Firebase Hosting (free)
4. **Storage**: Firebase Storage (free)

## Future Enhancements

- [ ] Community forum/discussion feature
- [ ] Offline quiz functionality with local caching
- [ ] Push notifications for exam alerts
- [ ] Social login (Google, Facebook)
- [ ] Leaderboard system
- [ ] Advanced analytics and reporting
- [ ] Streak recovery feature
- [ ] Badge sharing on social media

