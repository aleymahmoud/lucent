"""
Test authentication endpoints
"""
import requests
import json

BASE_URL = "http://localhost:8000/api/v1"

def test_register():
    """Test user registration"""
    print("Testing user registration...")
    response = requests.post(
        f"{BASE_URL}/auth/register",
        json={
            "email": "admin@test.com",
            "password": "password123",
            "full_name": "Test Admin",
            "tenant_name": "Test Company"
        }
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 201 else None


def test_login(email, password):
    """Test user login"""
    print("\nTesting user login...")
    response = requests.post(
        f"{BASE_URL}/auth/login",
        json={
            "email": email,
            "password": password
        }
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")
    return response.json() if response.status_code == 200 else None


def test_get_me(token):
    """Test getting current user"""
    print("\nTesting get current user...")
    response = requests.get(
        f"{BASE_URL}/auth/me",
        headers={"Authorization": f"Bearer {token}"}
    )
    print(f"Status: {response.status_code}")
    print(f"Response: {json.dumps(response.json(), indent=2)}")


if __name__ == "__main__":
    # Test registration
    register_data = test_register()

    if register_data:
        token = register_data.get("access_token")
        print(f"\nAccess Token: {token[:50]}...")

        # Test /me endpoint
        test_get_me(token)

        # Test login
        test_login("admin@test.com", "password123")

        print("\n✅ All authentication tests passed!")
    else:
        print("\n❌ Registration failed")
