"""
Quick test script to verify API endpoints are working
Run this after starting the Django server to test if endpoints are accessible
"""
import requests
import json

BASE_URL = 'http://localhost:8000/api'

def test_endpoints():
    """Test if API endpoints are accessible"""
    print("Testing API endpoints...")
    print("=" * 50)
    
    # Test 1: Check if server is running
    try:
        response = requests.get(f'{BASE_URL}/quizzes/')
        print(f"✓ Quizzes endpoint: {response.status_code}")
        if response.status_code == 200:
            print(f"  Response: {response.json()[:2] if response.json() else 'Empty list'}")
        else:
            print(f"  Error: {response.text[:200]}")
    except Exception as e:
        print(f"✗ Failed to connect: {e}")
        print("  Make sure Django server is running: python manage.py runserver")
        return
    
    # Test 2: Test login endpoint (should return error for invalid credentials)
    try:
        response = requests.post(
            f'{BASE_URL}/auth/login/',
            headers={
                'Content-Type': 'application/json',
                'Accept': 'application/json'
            },
            data=json.dumps({'username': 'test', 'password': 'wrong'})
        )
        print(f"\n✓ Login endpoint: {response.status_code}")
        print(f"  Content-Type: {response.headers.get('Content-Type', 'N/A')}")
        if response.status_code == 200:
            try:
                print(f"  Response: {response.json()}")
            except:
                print(f"  Response is HTML (first 200 chars): {response.text[:200]}")
        elif response.status_code == 400:
            try:
                print(f"  Response (expected error): {response.json()}")
            except:
                print(f"  Response is HTML: {response.text[:200]}")
        else:
            print(f"  Unexpected status: {response.text[:200]}")
    except Exception as e:
        print(f"\n✗ Login endpoint failed: {e}")
    
    # Test 3: Test register endpoint
    try:
        response = requests.post(
            f'{BASE_URL}/auth/register/',
            headers={'Content-Type': 'application/json'},
            data=json.dumps({
                'username': 'testuser12321',
                'email': 'test12212@example.com',
                'password': 'testpass123'
            })
        )
        print(f"\n✓ Register endpoint: {response.status_code}")
        if response.status_code == 201:
            print(f"  Response: {response.json()}")
        elif response.status_code == 400:
            print(f"  Response (user might exist): {response.json()}")
        else:
            print(f"  Unexpected status: {response.text[:200]}")
    except Exception as e:
        print(f"\n✗ Register endpoint failed: {e}")
    
    print("\n" + "=" * 50)
    print("Test complete!")

if __name__ == '__main__':
    test_endpoints()
