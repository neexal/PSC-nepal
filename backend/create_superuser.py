"""
Run this script once to create a superuser on Render.
Set these environment variables in Render Dashboard:
- DJANGO_SUPERUSER_USERNAME
- DJANGO_SUPERUSER_PASSWORD
- DJANGO_SUPERUSER_EMAIL (optional)
"""
import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'psc_nepal.settings')
django.setup()

from django.contrib.auth import get_user_model

User = get_user_model()

username = os.environ.get('DJANGO_SUPERUSER_USERNAME', 'neexal')
email = os.environ.get('DJANGO_SUPERUSER_EMAIL', 'pakaukhaujau@gmail.com')
password = os.environ.get('S@diksh@123')

if not password:
    print("ERROR: DJANGO_SUPERUSER_PASSWORD environment variable not set!")
    exit(1)

if not User.objects.filter(username=username).exists():
    User.objects.create_superuser(username=username, email=email, password=password)
    print(f"✅ Superuser '{username}' created successfully!")
else:
    print(f"ℹ️  Superuser '{username}' already exists.")
