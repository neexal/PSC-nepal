# Setup Guide for PSC Nepal App

## Quick Start

### Backend Setup

1. **Navigate to backend directory**
   ```bash
   cd backend
   ```

2. **Create and activate virtual environment**
   ```bash
   python -m venv venv
   # Windows
   venv\Scripts\activate
   # Linux/Mac
   source venv/bin/activate
   ```

3. **Install dependencies**
   ```bash
   pip install -r requirements.txt
   ```

4. **Create database migrations**
   ```bash
   python manage.py makemigrations
   python manage.py migrate
   ```

5. **Create superuser (optional, for admin panel)**
   ```bash
   python manage.py createsuperuser
   ```

6. **Run server**
   ```bash
   python manage.py runserver
   ```

   Backend will be available at `http://localhost:8000`
   Admin panel: `http://localhost:8000/admin`

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
   - Edit `lib/services/api_service.dart`
   - Change `baseUrl` to your backend IP address
   - Default: `http://192.168.1.117:8000/api`
   - For localhost: `http://127.0.0.1:8000/api` (works on Android emulator)

4. **Run the app**
   ```bash
   flutter run
   ```

## Configuring Backend IP Address

### For Android Emulator
- Use `http://10.0.2.2:8000/api` (special IP for Android emulator to access host machine)

### For Physical Device
- Find your computer's IP address:
  - Windows: `ipconfig` (look for IPv4 Address)
  - Linux/Mac: `ifconfig` or `ip addr`
- Update `baseUrl` in `frontend/lib/services/api_service.dart`
- Make sure your phone and computer are on the same network

### For iOS Simulator
- Use `http://localhost:8000/api`

## Testing the Setup

1. **Create a test user**
   - Open the app
   - Click "Register"
   - Enter username, email, and password
   - You should be automatically logged in

2. **Test API endpoints**
   - Use Django admin panel to create quizzes and study materials
   - Or use the API directly at `http://localhost:8000/api/`

## Adding Sample Data

### Using Django Admin

1. Go to `http://localhost:8000/admin`
2. Login with superuser credentials
3. Add:
   - Quizzes
   - Questions for each quiz
   - Study Materials
   - Notifications

### Using Python Script

Create a script in `backend/`:

```python
# create_sample_data.py
from django.contrib.auth.models import User
from quizzes.models import Quiz, Question, StudyMaterial, Notification, UserProfile

# Create sample quiz
quiz = Quiz.objects.create(
    title="Sample General Knowledge Quiz",
    category="GK",
    total_questions=5,
    duration=10
)

# Create sample questions
for i in range(5):
    Question.objects.create(
        quiz=quiz,
        question_text=f"Sample question {i+1}?",
        options=["Option A", "Option B", "Option C", "Option D"],
        correct_option=0,
        explanation=f"This is the explanation for question {i+1}",
        difficulty="medium"
    )

# Create sample study material
StudyMaterial.objects.create(
    title="PSC Exam Preparation Guide",
    category="GK",
    material_type="PDF",
    file_url="https://example.com/sample.pdf",
    description="A comprehensive guide for PSC exam preparation"
)

print("Sample data created successfully!")
```

Run it:
```bash
python manage.py shell < create_sample_data.py
```

## Troubleshooting

### Backend Issues

**Import errors:**
- Make sure virtual environment is activated
- Run `pip install -r requirements.txt` again

**Database errors:**
- Delete `db.sqlite3` and run migrations again
- `python manage.py migrate`

**CORS errors:**
- Check `CORS_ALLOW_ALL_ORIGINS = True` in `settings.py`
- Make sure `corsheaders` is in `INSTALLED_APPS`

### Frontend Issues

**Package errors:**
- Run `flutter pub get`
- Run `flutter clean` then `flutter pub get`

**Connection errors:**
- Check backend is running
- Verify API URL is correct
- Check firewall settings
- Make sure device/emulator can reach backend IP

**Build errors:**
- Run `flutter clean`
- Delete `build/` folder
- Run `flutter pub get` again

## Next Steps

1. Set up Firebase (optional) for push notifications
2. Configure production database (PostgreSQL)
3. Deploy backend to Render/Railway
4. Build APK for Android
5. Set up CI/CD pipeline

## Production Deployment

See `README.md` for deployment instructions using:
- Render (Backend)
- Railway (Backend)
- Firebase (Storage, Notifications)
- Supabase (Alternative to Firebase)

