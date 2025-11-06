import os
import subprocess
import sys
import django
import psycopg2

# -----------------------------
# 1. Django setup
# -----------------------------
os.environ.setdefault("DJANGO_SETTINGS_MODULE", "psc_nepal.settings")
django.setup()

# -----------------------------
# 2. Read PostgreSQL Credentials from Environment
# -----------------------------
PG_NAME = os.environ.get("DB_NAME")
PG_USER = os.environ.get("DB_USER")
PG_PASSWORD = os.environ.get("DB_PASSWORD")
PG_HOST = os.environ.get("DB_HOST")
PG_PORT = os.environ.get("DB_PORT", "5432")

if not all([PG_NAME, PG_USER, PG_PASSWORD, PG_HOST]):
    print("❌ Missing database credentials. Please set:")
    print("   DB_NAME, DB_USER, DB_PASSWORD, DB_HOST, DB_PORT")
    sys.exit(1)

# -----------------------------
# 3. Export SQLite Data
# -----------------------------
print("🔹 Exporting data from local SQLite...")
try:
    subprocess.run([
        "python", "manage.py", "dumpdata",
        "--natural-primary", "--natural-foreign",
        "--indent", "2", "-o", "db.json"
    ], check=True)
    print("✅ Data exported to db.json")
except subprocess.CalledProcessError as e:
    print("❌ Error exporting data:", e)
    sys.exit(1)

# -----------------------------
# 4. Connect to PostgreSQL
# -----------------------------
print("🔹 Connecting to PostgreSQL...")

try:
    conn = psycopg2.connect(
        dbname=PG_NAME,
        user=PG_USER,
        password=PG_PASSWORD,
        host=PG_HOST,
        port=PG_PORT
    )
    conn.autocommit = True
    cur = conn.cursor()
    print("✅ Connected to PostgreSQL")
except Exception as e:
    print("❌ Failed to connect to PostgreSQL:", e)
    sys.exit(1)

# -----------------------------
# 5. Drop Existing Tables (Optional Clean Slate)
# -----------------------------
print("🔹 Clearing existing PostgreSQL tables...")
try:
    cur.execute("""
        DO $$
        DECLARE
            r RECORD;
        BEGIN
            FOR r IN (SELECT tablename FROM pg_tables WHERE schemaname = current_schema()) LOOP
                EXECUTE 'DROP TABLE IF EXISTS ' || quote_ident(r.tablename) || ' CASCADE';
            END LOOP;
        END $$;
    """)
    print("✅ Tables cleared successfully.")
except Exception as e:
    print("⚠️ Skipping table drop:", e)

cur.close()
conn.close()

# -----------------------------
# 6. Apply Django Migrations
# -----------------------------
print("🔹 Running migrations on PostgreSQL...")
try:
    subprocess.run(["python", "manage.py", "migrate"], check=True)
    print("✅ Migrations applied successfully.")
except subprocess.CalledProcessError as e:
    print("❌ Migration failed:", e)
    sys.exit(1)

# -----------------------------
# 7. Load Data into PostgreSQL
# -----------------------------
print("🔹 Importing data to PostgreSQL...")
try:
    subprocess.run(["python", "manage.py", "loaddata", "db.json"], check=True)
    print("✅ Data migrated successfully to PostgreSQL!")
except subprocess.CalledProcessError as e:
    print("❌ Data import failed:", e)
    sys.exit(1)
