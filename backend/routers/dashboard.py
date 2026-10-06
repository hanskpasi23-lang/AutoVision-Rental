from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from sqlalchemy import func
from datetime import datetime, timedelta
import sys
sys.path.append('..')
import models, auth, database

router = APIRouter(
    prefix="/dashboard",
    tags=["dashboard"],
    responses={404: {"description": "Not found"}},
)

@router.get("/stats")
def get_dashboard_stats(
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get real-time dashboard statistics (Admin only)"""
    total_users = db.query(func.count(models.User.id)).scalar()
    
    active_rentals = db.query(func.count(models.Booking.id)).filter(
        models.Booking.status == 'active'
    ).scalar()
    
    available_vehicles = db.query(func.count(models.Vehicle.id)).filter(
        models.Vehicle.status == 'available'
    ).scalar()
    
    total_vehicles = db.query(func.count(models.Vehicle.id)).scalar()
    
    first_day_of_month = datetime.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
    monthly_revenue = db.query(func.sum(models.Booking.total_price)).filter(
        models.Booking.created_at >= first_day_of_month,
        models.Booking.status.in_(['completed', 'active'])
    ).scalar() or 0
    
    pending_bookings = db.query(func.count(models.Booking.id)).filter(
        models.Booking.status == 'pending'
    ).scalar()
    
    pending_inspections = db.query(func.count(models.Inspection.id)).filter(
        models.Inspection.admin_reviewed == False
    ).scalar()
    
    return {
        "total_users": total_users,
        "active_rentals": active_rentals,
        "available_vehicles": available_vehicles,
        "total_vehicles": total_vehicles,
        "monthly_revenue": float(monthly_revenue),
        "pending_bookings": pending_bookings,
        "pending_inspections": pending_inspections
    }

@router.get("/recent-bookings")
def get_recent_bookings(
    limit: int = 5,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get recent bookings for dashboard (Admin only)"""
    bookings = db.query(models.Booking).order_by(
        models.Booking.created_at.desc()
    ).limit(limit).all()
    
    result = []
    for booking in bookings:
        user = db.query(models.User).filter(models.User.id == booking.user_id).first()
        vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
        result.append({
            "id": booking.id,
            "user_name": user.full_name or user.email if user else "Unknown",
            "vehicle": f"{vehicle.make} {vehicle.model}" if vehicle else "Unknown",
            "status": booking.status,
            "total_price": booking.total_price,
            "start_date": booking.start_date.isoformat(),
            "end_date": booking.end_date.isoformat()
        })
    
    return result

@router.get("/user-stats")
def get_user_dashboard_stats(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Get dashboard statistics for the current user"""
    
    active_rentals = db.query(func.count(models.Booking.id)).filter(
        models.Booking.user_id == current_user.id,
        models.Booking.status.in_(['active', 'post_inspection', 'pending_review'])
    ).scalar()
    
    completed_rentals = db.query(func.count(models.Booking.id)).filter(
        models.Booking.user_id == current_user.id,
        models.Booking.status == 'completed'
    ).scalar()
    
    recent_rentals_query = db.query(models.Booking).filter(
        models.Booking.user_id == current_user.id
    ).order_by(models.Booking.created_at.desc()).limit(5).all()

    recent_rentals_data = []
    for booking in recent_rentals_query:
        vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
        recent_rentals_data.append({
            "id": booking.id,
            "vehicle": f"{vehicle.make} {vehicle.model}" if vehicle else "Unknown",
            "vehicle_image": vehicle.image_url if vehicle else None,
            "start_date": booking.start_date,
            "end_date": booking.end_date,
            "total_price": booking.total_price,
            "status": booking.status
        })

    return {
        "active_rentals": active_rentals,
        "completed_rentals": completed_rentals,
        "credit_score": current_user.credit_score,
        "recent_rentals": recent_rentals_data
    }
