import sys
import os
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from database import SessionLocal
import models
import auth

def create_admin():
    db = SessionLocal()
    email = "admin@example.com"
    password = "admin123"

    user = db.query(models.User).filter(models.User.email == email).first()
    if not user:
        hashed_password = auth.get_password_hash(password)
        user = models.User(email=email, hashed_password=hashed_password, full_name="Admin User", role="admin")
        db.add(user)
        db.commit()
        print("Admin user created.")
    else:
        print("User already exists.")
        if user.role != "admin":
            user.role = "admin"
            db.commit()
            print("Updated user to admin role.")
        else:
            print("User is already admin.")

    db.close()

if __name__ == "__main__":
    create_admin()
