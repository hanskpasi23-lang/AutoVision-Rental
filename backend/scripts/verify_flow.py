import requests
import json
import os
from PIL import Image
import io

BASE_URL = "http://localhost:8000"
EMAIL = "john@example.com"
PASSWORD = "password123"

def create_dummy_image():
    img = Image.new('RGB', (100, 100), color = 'red')
    img_byte_arr = io.BytesIO()
    img.save(img_byte_arr, format='JPEG')
    img_byte_arr.seek(0)
    return img_byte_arr

def register():
    print("Registering user...")
    res = requests.post(f"{BASE_URL}/users/", json={
        "email": EMAIL,
        "password": PASSWORD,
        "full_name": "John Doe"
    })
    if res.status_code == 200:
        print("User registered.")
    elif res.status_code == 400 and "already registered" in res.text:
        print("User already registered.")
    else:
        print("Registration failed:", res.text)

def login():
    register()
    print("Logging in...")
    response = requests.post(f"{BASE_URL}/users/token", json={
        "email": EMAIL,
        "password": PASSWORD
    })
    if response.status_code == 200:
        return response.json()["access_token"]
    print("Login failed:", response.text)
    return None

def main():
    token = login()
    if not token:
        return

    headers = {"Authorization": f"Bearer {token}"}
    
    print("Getting vehicles...")
    res = requests.get(f"{BASE_URL}/vehicles/", headers=headers)
    vehicles = res.json()
    if not vehicles:
        print("No vehicles found.")
        return
    vehicle_id = vehicles[0]['id']
    print(f"Selected vehicle ID: {vehicle_id}")

    print("Creating booking...")
    res = requests.post(f"{BASE_URL}/bookings/", headers=headers, json={
        "vehicle_id": vehicle_id,
        "start_date": "2024-01-01T10:00:00",
        "end_date": "2024-01-02T10:00:00",
        "total_price": 100.0
    })
    if res.status_code != 200:
        print("Booking failed:", res.text)
        return
    booking = res.json()
    booking_id = booking['id']
    print(f"Booking created: ID {booking_id}")

    print(f"Uploading pre-inspection for booking {booking_id}...")
    files = {
        'front': ('front.jpg', create_dummy_image(), 'image/jpeg'),
        'back': ('back.jpg', create_dummy_image(), 'image/jpeg'),
        'left': ('left.jpg', create_dummy_image(), 'image/jpeg'),
        'right': ('right.jpg', create_dummy_image(), 'image/jpeg'),
    }
    
    res = requests.post(
        f"{BASE_URL}/rental/pre-inspection/{booking_id}",
        headers=headers,
        files=files
    )
    if res.status_code != 200:
        print("Pre-inspection failed:", res.text)
        return
    print("Pre-inspection uploaded.")

    print(f"Starting rental for booking {booking_id}...")
    res = requests.post(f"{BASE_URL}/rental/start/{booking_id}", headers=headers)
    if res.status_code != 200:
        print("Start rental failed:", res.text)
        return
    print("Rental started.")

    print(f"Ending rental for booking {booking_id}...")
    res = requests.post(f"{BASE_URL}/rental/end/{booking_id}", headers=headers)
    if res.status_code != 200:
        print("End rental failed:", res.text)
        return
    print("Rental ended.")

    print(f"Uploading post-inspection for booking {booking_id}...")
    files_post = {
        'front': ('front.jpg', create_dummy_image(), 'image/jpeg'),
        'back': ('back.jpg', create_dummy_image(), 'image/jpeg'),
        'left': ('left.jpg', create_dummy_image(), 'image/jpeg'),
        'right': ('right.jpg', create_dummy_image(), 'image/jpeg'),
    }
    res = requests.post(
        f"{BASE_URL}/rental/post-inspection/{booking_id}",
        headers=headers,
        files=files_post
    )
    if res.status_code != 200:
        print("Post-inspection failed:", res.text)
        return
    print("Post-inspection uploaded.")
    print(res.json())

    print(f"\nSUCCESS! Booking {booking_id} is now pending admin review.")

if __name__ == "__main__":
    main()
