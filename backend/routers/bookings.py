from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from datetime import datetime
import schemas, models, auth, database, credit_system

router = APIRouter(
    prefix="/bookings",
    tags=["bookings"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[schemas.Booking])
def read_bookings(
    skip: int = 0, 
    limit: int = 100, 
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    if current_user.role == "admin":
        bookings = db.query(models.Booking).options(joinedload(models.Booking.vehicle)).offset(skip).limit(limit).all()
    else:
        bookings = db.query(models.Booking).options(joinedload(models.Booking.vehicle)).filter(models.Booking.user_id == current_user.id).offset(skip).limit(limit).all()
    return bookings

@router.post("/", response_model=schemas.Booking)
def create_booking(
    booking: schemas.BookingCreate,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    if current_user.verification_status != "verified":
        raise HTTPException(
            status_code=403, 
            detail="Account not verified. Please upload verification documents."
        )

    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    if vehicle.status != "available":
        raise HTTPException(status_code=400, detail="Vehicle not available")
    
    days = (booking.end_date - booking.start_date).days
    if days <= 0:
        days = 1
    total_price = days * vehicle.daily_rate

    db_booking = models.Booking(
        user_id=current_user.id,
        vehicle_id=booking.vehicle_id,
        start_date=booking.start_date,
        end_date=booking.end_date,
        total_price=total_price,
        status="pending"
    )
    
    vehicle.status = "rented"
    
    db.add(db_booking)
    db.commit()
    db.refresh(db_booking)
    return db_booking

@router.get("/{booking_id}", response_model=schemas.Booking)
def read_booking(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    booking = db.query(models.Booking).options(joinedload(models.Booking.vehicle)).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    if booking.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    return booking

@router.put("/{booking_id}/status")
def update_booking_status(
    booking_id: int,
    status_update: schemas.BookingStatusUpdate,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Update booking status (Admin only) - approve, reject, cancel, complete"""
    booking = db.query(models.Booking).filter(models.Booking.id == booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    old_status = booking.status
    booking.status = status_update.status
    
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    if vehicle:
        if status_update.status in ["completed", "cancelled", "rejected"]:
            vehicle.status = "available"
        elif status_update.status == "active":
            vehicle.status = "rented"
    
    if status_update.status == "completed" and old_status == "active":
        credit_system.update_user_credit_score(
            db, booking.user_id, 5.0, "Rental completed successfully"
        )
    
    db.commit()
    return {"message": f"Booking status updated to {status_update.status}"}

