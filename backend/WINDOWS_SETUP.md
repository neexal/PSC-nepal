# Windows Setup Guide

## PostgreSQL Installation Issue (psycopg2-binary)

If you're developing on Windows and encounter errors installing `psycopg2-binary`, **you can safely skip it** for local development!

### Why?
- The project uses **SQLite** for local development (no PostgreSQL needed)
- `psycopg2-binary` is only required when deploying to production with PostgreSQL
- Windows installation requires Visual C++ build tools which is a large download

### Solution for Local Development

✅ **Already fixed!** The `requirements.txt` has been updated to exclude `psycopg2-binary`

Just run:
```bash
pip install -r requirements.txt
```

All dependencies will install successfully, and you can use SQLite locally.

### For Production Deployment

When deploying to Render/Railway with PostgreSQL:
- The platform automatically installs `psycopg2-binary` with pre-built Linux wheels
- No build tools needed on Linux servers
- Use `requirements-production.txt` if needed

### If You Really Need PostgreSQL Locally

If you want to use PostgreSQL on your Windows machine:

**Option 1: Use psycopg3 (recommended)**
```bash
pip install psycopg[binary]
```

**Option 2: Install Build Tools**
1. Download [Microsoft C++ Build Tools](https://visualstudio.microsoft.com/visual-cpp-build-tools/)
2. Install with "Desktop development with C++" workload
3. Then: `pip install psycopg2-binary`

**Option 3: Use Docker**
```bash
docker run -d -p 5432:5432 -e POSTGRES_PASSWORD=postgres postgres
```

---

## Quick Start (Windows)

1. **Create virtual environment**
   ```bash
   python -m venv venv
   venv\Scripts\activate
   ```

2. **Install dependencies** (psycopg2 excluded for local dev)
   ```bash
   pip install -r requirements.txt
   ```

3. **Run migrations**
   ```bash
   python manage.py migrate
   ```

4. **Seed data**
   ```bash
   python seed_data.py
   ```

5. **Start server**
   ```bash
   python manage.py runserver
   ```

✅ **That's it! The backend is now running on SQLite.**

---

## Deployment Note

When you deploy to production:
- Set `DATABASE_URL` environment variable to your PostgreSQL connection string
- The platform will automatically install PostgreSQL drivers
- No changes needed to your code!

---

## Common Windows Issues

### Issue: "python not found"
**Solution:** Use `py` instead of `python`:
```bash
py -m venv venv
py manage.py runserver
```

### Issue: Permission errors
**Solution:** Run as administrator or check antivirus settings

### Issue: Port 8000 already in use
**Solution:** 
```bash
python manage.py runserver 8001
```

---

## Recommended: Use WSL2 (Windows Subsystem for Linux)

For the best development experience on Windows, consider using WSL2:

1. Install WSL2: `wsl --install`
2. Install Ubuntu from Microsoft Store
3. Run all commands in WSL2 Ubuntu terminal
4. Works exactly like Linux/Mac

Benefits:
- No build tool issues
- Better performance
- Closer to production environment

---

**You're all set! Continue with the QUICKSTART.md guide.**
