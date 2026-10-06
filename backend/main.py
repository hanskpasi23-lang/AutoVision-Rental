from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from database import engine, Base
import models
from routers import users, vehicles, bookings, inspections, dashboard, rental_inspection, incidents, notifications, wishlist
import os

Base.metadata.create_all(bind=engine)

app = FastAPI(title="AutoVision Rent API", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://127.0.0.1:3000",
        "http://localhost:3001",
        "http://127.0.0.1:3001"
    ],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

uploads_dir = os.path.join(os.path.dirname(__file__), "uploads")
os.makedirs(uploads_dir, exist_ok=True)
app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")

app.include_router(users.router)
app.include_router(vehicles.router)
app.include_router(bookings.router)
app.include_router(inspections.router)
app.include_router(dashboard.router)
app.include_router(rental_inspection.router)
app.include_router(incidents.router)
app.include_router(notifications.router)
app.include_router(wishlist.router)

@app.get("/")
def read_root():
    return {"message": "Welcome to AutoVision Rent API"}

