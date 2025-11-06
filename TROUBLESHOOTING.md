# Troubleshooting Connection Issues

## "Failed to fetch" or "ClientException" Error

This error means the Flutter app cannot connect to the Django backend server.

### Step 1: Verify Backend is Running

1. **Open a new terminal/PowerShell window**
2. **Navigate to backend directory:**
   ```powershell
   cd backend
   ```

3. **Activate virtual environment:**
   ```powershell
   .\venv\Scripts\Activate.ps1
   ```

4. **Start the Django server:**
   ```powershell
   python manage.py runserver 0.0.0.0:8000
   ```
   
   The `0.0.0.0` makes the server accessible from other devices on your network.

5. **Check if server is running:**
   - You should see: `Starting development server at http://0.0.0.0:8000/`
   - Open browser and go to: `http://localhost:8000/admin` (should load Django admin)

### Step 2: Find Your Computer's IP Address

**Windows:**
```powershell
ipconfig
```
Look for "IPv4 Address" under your network adapter (usually Wi-Fi or Ethernet).
Example: `192.168.1.117`

**Alternative methods:**
```powershell
# PowerShell
Get-NetIPAddress -AddressFamily IPv4 | Where-Object {$_.IPAddress -like "192.168.*"}
```

### Step 3: Update API URL Based on Platform

#### For Chrome/Edge Web Browser:
- Use `http://localhost:8000/api` or `http://127.0.0.1:8000/api`

#### For Android Emulator:
- Use `http://10.0.2.2:8000/api` (special IP for Android emulator)

#### For Physical Android/iOS Device:
- Use your computer's IP: `http://192.168.1.117:8000/api` (replace with your actual IP)
- Make sure phone and computer are on the same Wi-Fi network

#### For Windows Desktop App:
- Use `http://localhost:8000/api` or your computer's IP

### Step 4: Update API URL in Flutter

Edit `frontend/lib/services/api_service.dart`:

```dart
class ApiService {
  // For Chrome/Edge web browser
  static const String baseUrl = 'http://localhost:8000/api';
  
  // OR for Android emulator
  // static const String baseUrl = 'http://10.0.2.2:8000/api';
  
  // OR for physical device (replace with your computer's IP)
  // static const String baseUrl = 'http://192.168.1.117:8000/api';
  
  // ...
}
```

**Hot reload won't work for this change** - you need to restart the app:
```powershell
flutter run
```

### Step 5: Test API Connection

**Test if backend is accessible:**

1. **From browser:**
   - Go to: `http://localhost:8000/api/quizzes/` (should show quizzes list or empty array)
   - Go to: `http://localhost:8000/api/study-materials/` (should show materials list)

2. **From command line (PowerShell):**
   ```powershell
   curl http://localhost:8000/api/quizzes/
   ```

3. **Test from Flutter app:**
   - Try to view quizzes list (should work without login)
   - If this fails, the connection issue persists

### Step 6: CORS Configuration

If running on **web browser** (Chrome/Edge), make sure CORS is configured:

In `backend/psc_nepal/settings.py`:
```python
CORS_ALLOW_ALL_ORIGINS = True  # For development only
CORS_ALLOW_CREDENTIALS = True
```

Make sure `corsheaders` is in `INSTALLED_APPS`:
```python
INSTALLED_APPS = [
    # ...
    'corsheaders',
    # ...
]
```

### Step 7: Firewall Settings

**Windows Firewall might be blocking the connection:**

1. **Allow Python through firewall:**
   - Go to Windows Defender Firewall
   - Click "Allow an app through firewall"
   - Find Python and check both Private and Public networks

2. **Or temporarily disable firewall** (for testing only)

### Step 8: Check Network

1. **Same Wi-Fi network:**
   - Make sure your computer and phone are on the same Wi-Fi network
   - Some networks block device-to-device communication

2. **Test connection:**
   ```powershell
   # From your phone's browser, try:
   http://YOUR_COMPUTER_IP:8000/admin
   ```
   If this doesn't work, the network is blocking the connection.

### Common Solutions

#### Solution 1: Use localhost for Web Browser
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

#### Solution 2: Use Android Emulator IP
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

#### Solution 3: Run backend on all interfaces
```powershell
python manage.py runserver 0.0.0.0:8000
```

#### Solution 4: Check if port 8000 is in use
```powershell
netstat -ano | findstr :8000
```
If port is in use, kill the process or use a different port:
```powershell
python manage.py runserver 0.0.0.0:8001
```

### Quick Fix Checklist

- [ ] Backend server is running (`python manage.py runserver 0.0.0.0:8000`)
- [ ] Backend is accessible from browser (`http://localhost:8000/admin`)
- [ ] API URL in `api_service.dart` matches your platform
- [ ] CORS is enabled in Django settings
- [ ] Firewall allows Python/port 8000
- [ ] Device/emulator and computer are on same network
- [ ] Flutter app was restarted after changing API URL

### Still Having Issues?

1. **Check backend logs** - Look at the terminal where Django is running for errors
2. **Check Flutter console** - Look for detailed error messages
3. **Try different IP addresses:**
   - `localhost` (for web)
   - `127.0.0.1` (for web)
   - `10.0.2.2` (for Android emulator)
   - Your computer's IP (for physical devices)

4. **Test with curl:**
   ```powershell
   curl http://localhost:8000/api/quizzes/
   ```

