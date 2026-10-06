from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import json
import sys
sys.path.append('..')
import models, auth, database

router = APIRouter(
    prefix="/incidents",
    tags=["incidents"],
    responses={404: {"description": "Not found"}},
)

@router.get("/")
def get_all_incidents(
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """
    Get all damage incidents derived from post-rental inspections
    where damage was detected. Each incident includes booking, vehicle,
    and user context.
    """
    inspections = (
        db.query(models.Inspection)
        .filter(
            models.Inspection.type == "post_rental",
            models.Inspection.damage_detected == True
        )
        .order_by(models.Inspection.created_at.desc())
        .all()
    )

    unreviewed = (
        db.query(models.Inspection)
        .filter(
            models.Inspection.type == "post_rental",
            models.Inspection.admin_reviewed == False,
            models.Inspection.damage_detected == False
        )
        .order_by(models.Inspection.created_at.desc())
        .all()
    )

    all_inspections = inspections + unreviewed
    seen_ids = set()
    incidents = []

    for insp in all_inspections:
        if insp.id in seen_ids:
            continue
        seen_ids.add(insp.id)

        booking = db.query(models.Booking).filter(models.Booking.id == insp.booking_id).first()
        vehicle = None
        user = None
        if booking:
            vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
            user = db.query(models.User).filter(models.User.id == booking.user_id).first()

        ai_analysis = json.loads(insp.ai_analysis_json) if insp.ai_analysis_json else None

        incidents.append({
            "id": insp.id,
            "booking_id": insp.booking_id,
            "severity_grade": insp.severity_grade or "none",
            "damage_detected": insp.damage_detected,
            "damage_summary": insp.damage_summary or "No damage description available",
            "damage_cost_estimate": insp.damage_cost_estimate or 0.0,
            "credit_adjustment": insp.credit_adjustment or 0.0,
            "admin_reviewed": insp.admin_reviewed,
            "created_at": insp.created_at.isoformat() if insp.created_at else None,
            "vehicle": {
                "make": vehicle.make if vehicle else "Unknown",
                "model": vehicle.model if vehicle else "Unknown",
                "year": vehicle.year if vehicle else 0,
            } if vehicle else None,
            "user": {
                "full_name": user.full_name if user else "Unknown",
                "email": user.email if user else "Unknown",
                "credit_score": user.credit_score if user else 0,
            } if user else None,
            "booking_status": booking.status if booking else "unknown",
            "has_pre_inspection": db.query(models.Inspection).filter(
                models.Inspection.booking_id == insp.booking_id,
                models.Inspection.type == "pre_rental"
            ).first() is not None,
            "ai_analysis": ai_analysis,
        })

    return incidents

@router.get("/stats")
def get_incident_stats(
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get summary stats for the incidents dashboard."""
    total_damage = (
        db.query(models.Inspection)
        .filter(models.Inspection.type == "post_rental", models.Inspection.damage_detected == True)
        .count()
    )
    pending_review = (
        db.query(models.Inspection)
        .filter(models.Inspection.type == "post_rental", models.Inspection.admin_reviewed == False)
        .count()
    )
    reviewed = (
        db.query(models.Inspection)
        .filter(models.Inspection.type == "post_rental", models.Inspection.admin_reviewed == True)
        .count()
    )

    from sqlalchemy import func
    total_cost = (
        db.query(func.coalesce(func.sum(models.Inspection.damage_cost_estimate), 0))
        .filter(models.Inspection.type == "post_rental", models.Inspection.damage_detected == True)
        .scalar()
    )

    return {
        "total_incidents": total_damage,
        "pending_review": pending_review,
        "resolved": reviewed,
        "total_damage_cost": float(total_cost),
    }
