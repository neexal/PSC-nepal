# 📱 Android Setup Guide - Fix Connection Issues

## Problem

Getting `Connection refused` error when trying to login/register on Android:
```
SocketException: Connection refused (OS Error: Connection refused, errno = 111), 
address = localhost, port = 8000
```

## Why This Happens

**Android devices/emulators can't use `localhost`** to access your computer!

- `localhost` on Android = the Android device itself (not your computer)
- Your backend is running on your computer, not on the Android device
- We need to use a different address to reach your computer

---

## ✅ Quick Fix (Android Emulator)

The app is now **automatically configured** for Android emulator!

### Just Follow These Steps:

#### 1. **Make Sure Backend is Running**

Open a terminal in your backend folder:

```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

⚠️ **Important:** Use `0.0.0.0:8000` (not just `8000`)!

#### 2. **Hot Restart Your App**

In your Flutter terminal:

```bash
Press 'R' (capital R) for hot restart
```

#### 3. **Try Login/Register**

It should work now! ✅

---

## 🔧 How It Works

### Automatic Detection:

The app now automatically uses the correct URL:

| Platform | URL Used | Why |
|----------|----------|-----|
| **Android Emulator** | `http://10.0.2.2:8000/api` | Special alias for host PC |
| **Physical Android** | `http://YOUR_IP:8000/api` | Your computer's network IP |
| **iOS Simulator** | `http://localhost:8000/api` | Can use localhost |
| **Web/Desktop** | `http://localhost:8000/api` | Running on same machine |

### Magic Number: `10.0.2.2`

This is a **special IP address** that Android emulators use to refer to your computer:
- `10.0.2.2` = Your host computer (where the backend runs)
- `localhost` = The Android emulator itself

---

## 📱 Using a Physical Android Device

If testing on a **real phone** (not emulator):

### Step 1: Find Your Computer's IP Address

**On Windows:**
```bash
ipconfig
```
Look for "IPv4 Address" under your Wi-Fi adapter.
Example: `192.168.1.100`

**On Mac/Linux:**
```bash
ifconfig
# or
ip addr
```
Look for your network interface IP.

### Step 2: Update Configuration

Open: `frontend/lib/config/api_config.dart`

Change these lines:

```dart
// Set to true for physical device
static const bool usePhysicalDevice = true;  // ← Change to true

// Set your computer's IP address
static const String computerIpAddress = '192.168.1.100';  // ← Your IP here
```

### Step 3: Ensure Same Network

⚠️ **Both your phone and computer must be on the SAME Wi-Fi network!**

### Step 4: Allow Firewall Access

**Windows:**
1. Search for "Windows Defender Firewall"
2. Click "Allow an app through firewall"
3. Make sure Python is allowed on Private networks

**Mac:**
1. System Preferences → Security & Privacy → Firewall
2. Click "Firewall Options"
3. Allow Python

### Step 5: Restart Backend with 0.0.0.0

```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

### Step 6: Hot Restart App

```bash
# In Flutter terminal
Press 'R'
```

---

## 🔍 Verification

### Test Connection from Phone Browser

Before testing the app, verify connection:

1. Open Chrome on your Android device
2. Go to: `http://YOUR_IP:8000/admin`
   - Replace `YOUR_IP` with your computer's IP
   - Example: `http://192.168.1.100:8000/admin`
3. You should see the Django admin login page

If this works, the app will work too! ✅

---

## 🐛 Troubleshooting

### Issue 1: Still Getting "Connection Refused"

**Check:**
- [ ] Backend running with `0.0.0.0:8000`
- [ ] Hot restarted Flutter app (R, not r)
- [ ] Same Wi-Fi network (for physical device)
- [ ] Correct IP in `api_config.dart` (for physical device)
- [ ] Firewall allows Python

**Test:**
```bash
# From your computer, test if backend is accessible
curl http://YOUR_IP:8000/api/subjects/
```

### Issue 2: Backend Says "Invalid Host Header"

**Problem:** Django ALLOWED_HOSTS doesn't include your IP

**Solution:**

Edit `backend/psc_nepal/settings.py`:

```python
ALLOWED_HOSTS = [
    'localhost',
    '127.0.0.1',
    '10.0.2.2',  # For Android emulator
    '192.168.1.100',  # Your computer's IP (change this!)
    '*',  # Allow all (only for development!)
]
```

Then restart Django.

### Issue 3: Timeout Instead of Connection Refused

**Possible causes:**
- Wrong IP address
- Firewall blocking
- Different networks
- Backend not running on 0.0.0.0

**Solution:**
1. Verify IP with `ipconfig` / `ifconfig`
2. Check firewall settings
3. Ensure same Wi-Fi network
4. Restart backend: `python manage.py runserver 0.0.0.0:8000`

### Issue 4: Works on Emulator but not Physical Device

**Most likely:** Wrong IP or different networks

**Solution:**
1. Verify you set `usePhysicalDevice = true`
2. Double-check your computer's IP
3. Ensure phone and PC on same Wi-Fi
4. Try accessing `http://YOUR_IP:8000/admin` from phone browser

---

## 📋 Quick Checklist

### For Android Emulator:
- [ ] Backend running: `python manage.py runserver 0.0.0.0:8000`
- [ ] App uses `10.0.2.2` (automatic)
- [ ] Hot restarted app (R)
- [ ] Try login/register

### For Physical Device:
- [ ] Found computer's IP address
- [ ] Updated `api_config.dart` with IP
- [ ] Set `usePhysicalDevice = true`
- [ ] Same Wi-Fi network
- [ ] Backend running: `python manage.py runserver 0.0.0.0:8000`
- [ ] Firewall allows Python
- [ ] Updated ALLOWED_HOSTS in settings.py
- [ ] Hot restarted app (R)
- [ ] Can access backend from phone browser
- [ ] Try login/register

---

## 🎯 Commands Summary

### Start Backend (Accessible from Network):
```bash
cd backend
python manage.py runserver 0.0.0.0:8000
```

### Find Your IP:
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
# or
ip addr
```

### Hot Restart Flutter:
```bash
# In Flutter terminal
Press 'R' (capital R)
```

### Test Backend from Command Line:
```bash
# From your computer
curl http://10.0.2.2:8000/api/subjects/

# From another device
curl http://YOUR_IP:8000/api/subjects/
```

---

## 💡 Pro Tips

### 1. Keep Backend Running Visible

Keep the backend terminal visible so you can see:
- API requests coming in
- Any errors
- Connection attempts

### 2. Use Hot Restart, Not Hot Reload

After changing config:
- **Hot Restart (R)** - Restarts entire app ✅
- **Hot Reload (r)** - May not update config ❌

### 3. Test Backend First

Before testing the Flutter app:
1. Open phone browser
2. Go to `http://YOUR_IP:8000/admin`
3. If you see Django admin, backend is accessible ✅

### 4. Static IP (Optional)

For easier development, set a static IP on your computer:
- Windows: Network settings → Change adapter options
- Mac: System Preferences → Network → Advanced
- Less hassle than updating IP each time!

---

## 🔐 Security Note

### Development vs Production

**Current setup is for DEVELOPMENT ONLY!**

- `0.0.0.0:8000` - Accessible from network (good for testing)
- `ALLOWED_HOSTS = ['*']` - Allows any host (only for dev!)

**For production:**
- Use proper domain names
- Set specific ALLOWED_HOSTS
- Use HTTPS
- Deploy to proper hosting (Render, Heroku, etc.)

---

## 📱 Platform-Specific Notes

### Android Emulator:
- ✅ Automatically works with `10.0.2.2`
- ✅ No extra configuration needed
- ✅ No firewall issues

### Physical Android:
- ⚠️ Requires computer's IP
- ⚠️ Must be on same Wi-Fi
- ⚠️ May need firewall configuration
- ⚠️ IP may change (use static IP)

### iOS Simulator:
- ✅ Works with `localhost`
- ✅ No special configuration needed

---

## ✅ Success Indicators

**You'll know it's working when:**

1. ✅ No "Connection refused" errors
2. ✅ Backend terminal shows API requests
3. ✅ Login/register completes successfully
4. ✅ Can fetch quizzes and data
5. ✅ App navigates to home screen after login

---

## 🆘 Still Not Working?

### Debug Steps:

1. **Check Backend Logs**
   - Look at terminal where Django is running
   - Do you see incoming requests?
   - Any error messages?

2. **Check App Logs**
   - Look at Flutter terminal
   - What's the exact error?
   - Does it mention the correct IP?

3. **Network Test**
   - Can you ping your computer from phone?
   - Can you access any website on phone?
   - Is Wi-Fi working properly?

4. **Try Simplest Test**
   ```bash
   # From phone browser
   http://YOUR_IP:8000
   
   # Should show Django's "The install worked successfully!"
   ```

---

## 📚 Additional Resources

### Documentation:
- [Django ALLOWED_HOSTS](https://docs.djangoproject.com/en/stable/ref/settings/#allowed-hosts)
- [Flutter Platform Channels](https://flutter.dev/docs/development/platform-integration/platform-channels)
- [Android Emulator Networking](https://developer.android.com/studio/run/emulator-networking)

### Related Files:
- `frontend/lib/config/api_config.dart` - API configuration
- `frontend/lib/services/api_service.dart` - API service
- `backend/psc_nepal/settings.py` - Django settings

---

## ✅ Summary

### What We Fixed:

1. ✅ Auto-detect Android emulator
2. ✅ Use `10.0.2.2` instead of `localhost`
3. ✅ Easy config for physical devices
4. ✅ Platform-specific URL handling

### What You Need to Do:

**For Emulator:**
1. Run backend: `python manage.py runserver 0.0.0.0:8000`
2. Hot restart app: Press 'R'
3. That's it! ✅

**For Physical Device:**
1. Find your IP: `ipconfig`
2. Update `api_config.dart`
3. Same Wi-Fi network
4. Run backend: `python manage.py runserver 0.0.0.0:8000`
5. Hot restart: Press 'R'
6. Done! ✅

---

**Your Android app should now connect successfully!** 🎉📱
