import requests
import json
import sys

BASE_URL = "http://localhost:8000"
ADMIN_EMAIL = "admin@example.com"
ADMIN_PASSWORD = "admin123"
USER_EMAIL = "john@example.com"
USER_PASSWORD = "password123"

def login(email, password):
    print(f"Logging in as {email}...")
    response = requests.post(f"{BASE_URL}/users/token", json={
        "email": email,
        "password": password
    })
    if response.status_code == 200:
        return response.json()["access_token"]
    print("Login failed:", response.text)
    return None

def main():
    admin_token = login(ADMIN_EMAIL, ADMIN_PASSWORD)
    if not admin_token:
        sys.exit(1)
    
    admin_headers = {"Authorization": f"Bearer {admin_token}"}

    print("Fetching inspections...")
    res = requests.get(f"{BASE_URL}/inspections/detailed", headers=admin_headers)
    if res.status_code != 200:
        print("Failed to fetch inspections:", res.text)
        sys.exit(1)
    
    inspections = res.json()
    target_inspection = None
    
    for item in inspections:
        booking = item.get('booking')
        if booking and booking.get('id') == 4:
            target_inspection = item.get('post_inspection')
            break
    
    if not target_inspection:
        print("Target inspection for Booking 4 not found.")
        print("Available bookings:", [i['booking']['id'] for i in inspections if i.get('booking')])
        sys.exit(1)
    
    inspection_id = target_inspection['id']
    print(f"Found pending inspection ID: {inspection_id}")

    if target_inspection.get('admin_reviewed'):
        print("Inspection already reviewed. Skipping review step.")
    else:
        print(f"Submitting review for inspection {inspection_id}...")
        payload = {
            "action": "accept_ai",
            "admin_notes": "Verified by automated test script."
        }
        res = requests.put(
            f"{BASE_URL}/inspections/{inspection_id}/review-complete",
            headers=admin_headers,
            json=payload
        )
        if res.status_code != 200:
            print("Review submission failed:", res.text)
            sys.exit(1)
        
        result = res.json()
        print("Review submitted successfully.")
        print("Result:", json.dumps(result, indent=2))
        
        if result.get("booking_status") != "completed":
            print("ERROR: Booking status did not update to 'completed'")
            sys.exit(1)

    print("Verifying user notification...")
    user_token = login(USER_EMAIL, USER_PASSWORD)
    if not user_token:
        sys.exit(1)
        
    user_headers = {"Authorization": f"Bearer {user_token}"}
    
    res = requests.get(f"{BASE_URL}/notifications/", headers=user_headers)
    if res.status_code != 200:
        print("Failed to fetch notifications:", res.text)
        sys.exit(1)
        
    notifications = res.json()
    found = False
    for n in notifications:
        if n.get("type") == "review_complete" and n.get("booking_id") == 4:
            print("SUCCESS: Notification found!")
            print("Title:", n.get("title"))
            print("Message:", n.get("message"))
            found = True
            break
            
    if not found:
        print("ERROR: Notification not found for Booking 4.")
        sys.exit(1)

    print("\nXXX VERIFICATION COMPLETE: ALL CHECKS PASSED XXX")

if __name__ == "__main__":
    main()
