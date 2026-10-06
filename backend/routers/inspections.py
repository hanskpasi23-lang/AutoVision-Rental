from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional
from pydantic import BaseModel
import json
import sys
sys.path.append('..')
import schemas, models, auth, database

router = APIRouter(
    prefix="/inspections",
    tags=["inspections"],
    responses={404: {"description": "Not found"}},
)

@router.get("/", response_model=List[schemas.Inspection])
def get_all_inspections(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get all inspections (Admin only)"""
    inspections = db.query(models.Inspection).offset(skip).limit(limit).all()
    return inspections

@router.get("/detailed")
def get_detailed_inspections(
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get all inspections with booking, vehicle, and user details grouped by booking"""
    inspections = db.query(models.Inspection).order_by(models.Inspection.booking_id.desc()).all()
    
    grouped = {}
    for insp in inspections:
        bid = insp.booking_id
        if bid not in grouped:
            booking = db.query(models.Booking).filter(models.Booking.id == bid).first()
            vehicle = None
            user = None
            if booking:
                vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
                user = db.query(models.User).filter(models.User.id == booking.user_id).first()
            
            grouped[bid] = {
                "booking_id": bid,
                "booking": {
                    "id": booking.id if booking else None,
                    "status": booking.status if booking else None,
                    "start_date": booking.start_date.isoformat() if booking and booking.start_date else None,
                    "end_date": booking.end_date.isoformat() if booking and booking.end_date else None,
                    "total_price": booking.total_price if booking else 0,
                    "refund_amount": booking.refund_amount if booking else 0,
                } if booking else None,
                "vehicle": {
                    "id": vehicle.id if vehicle else None,
                    "make": vehicle.make if vehicle else None,
                    "model": vehicle.model if vehicle else None,
                    "year": vehicle.year if vehicle else None,
                    "image_url": vehicle.image_url if vehicle else None,
                } if vehicle else None,
                "user": {
                    "id": user.id if user else None,
                    "email": user.email if user else None,
                    "full_name": user.full_name if user else None,
                    "credit_score": user.credit_score if user else None,
                } if user else None,
                "pre_inspection": None,
                "post_inspection": None,
            }
        
        insp_data = {
            "id": insp.id,
            "type": insp.type,
            "front_image_url": insp.front_image_url,
            "back_image_url": insp.back_image_url,
            "left_image_url": insp.left_image_url,
            "right_image_url": insp.right_image_url,
            "image_url": insp.image_url,
            "damage_detected": insp.damage_detected,
            "damage_summary": insp.damage_summary,
            "damage_cost_estimate": insp.damage_cost_estimate,
            "severity_grade": insp.severity_grade,
            "credit_adjustment": insp.credit_adjustment,
            "admin_reviewed": insp.admin_reviewed,
            "created_at": insp.created_at.isoformat() if insp.created_at else None,
            "ai_analysis": json.loads(insp.ai_analysis_json) if insp.ai_analysis_json else None,
        }
        
        if insp.type == "pre_rental":
            grouped[bid]["pre_inspection"] = insp_data
        else:
            grouped[bid]["post_inspection"] = insp_data
    
    return list(grouped.values())

@router.get("/{inspection_id}", response_model=schemas.Inspection)
def get_inspection(
    inspection_id: int,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get a specific inspection (Admin only)"""
    inspection = db.query(models.Inspection).filter(models.Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    return inspection

@router.put("/{inspection_id}/review")
def mark_inspection_reviewed(
    inspection_id: int,
    review_data: schemas.InspectionReview,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Mark an inspection as reviewed by admin"""
    inspection = db.query(models.Inspection).filter(models.Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    inspection.admin_reviewed = review_data.admin_reviewed
    db.commit()
    return {"message": "Inspection marked as reviewed"}

class AdminReviewRequest(BaseModel):
    action: str
    severity_grade: Optional[str] = None
    admin_notes: Optional[str] = None

@router.put("/{inspection_id}/review-complete")
def complete_admin_review(
    inspection_id: int,
    review: AdminReviewRequest,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """
    Complete admin review of a post-rental inspection.
    - Accepts AI assessment or overrides severity grade
    - Processes credit adjustments based on final severity
    - Processes any pending refund for early return
    - Creates a notification for the user
    - Completes the booking and releases the vehicle
    """
    inspection = db.query(models.Inspection).filter(models.Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    
    if inspection.type != "post_rental":
        raise HTTPException(status_code=400, detail="Can only review post-rental inspections")
    
    booking = db.query(models.Booking).filter(models.Booking.id == inspection.booking_id).first()
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    user = db.query(models.User).filter(models.User.id == booking.user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    original_severity = inspection.severity_grade
    if review.action == "override" and review.severity_grade:
        final_severity = review.severity_grade
        inspection.severity_grade = final_severity
    else:
        final_severity = inspection.severity_grade or "none"
    
    credit_map = {
        "none": 5.0,
        "minor": -5.0,
        "moderate": -15.0,
        "severe": -30.0,
    }
    credit_adjustment = credit_map.get(final_severity.lower(), 0.0)
    
    existing_analysis = json.loads(inspection.ai_analysis_json) if inspection.ai_analysis_json else {}
    existing_analysis["admin_action"] = review.action
    existing_analysis["admin_notes"] = review.admin_notes or ""
    existing_analysis["admin_override"] = review.action == "override"
    existing_analysis["original_severity"] = original_severity
    existing_analysis["final_severity"] = final_severity
    existing_analysis["final_credit_adjustment"] = credit_adjustment
    inspection.ai_analysis_json = json.dumps(existing_analysis)
    
    inspection.admin_reviewed = True
    inspection.credit_adjustment = credit_adjustment
    
    old_credit = user.credit_score
    user.credit_score = max(0, min(200, user.credit_score + credit_adjustment))
    new_credit = user.credit_score
    
    if credit_adjustment != 0:
        history_entry = models.CreditHistory(
            user_id=user.id,
            change=credit_adjustment,
            reason=f"Inspection Review: {final_severity.capitalize()} severity ({review.action})",
            booking_id=booking.id
        )
        db.add(history_entry)
    
    refund_amount = booking.refund_amount or 0.0
    if refund_amount > 0:
        user.wallet_balance += refund_amount
    
    booking.status = "completed"
    
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    vehicle_name = f"{vehicle.year} {vehicle.make} {vehicle.model}" if vehicle else "Vehicle"
    if vehicle:
        vehicle.status = "available"
    
    severity_display = final_severity.capitalize() if final_severity else "None"
    if review.action == "override":
        review_type = "Admin Override"
    else:
        review_type = "AI Assessment Accepted"
    
    cost_estimate = inspection.damage_cost_estimate or 0.0
    
    title = f"Inspection Review Complete — {vehicle_name}"
    message_parts = [
        f"Your rental inspection for {vehicle_name} has been reviewed.",
        f"Result: {severity_display} severity ({review_type}).",
    ]
    if credit_adjustment > 0:
        message_parts.append(f"Credit bonus: +{credit_adjustment} points.")
    elif credit_adjustment < 0:
        message_parts.append(f"Credit deduction: {credit_adjustment} points.")
    if refund_amount > 0:
        message_parts.append(f"Early return refund: ${refund_amount:.2f} added to wallet.")
    
    message = " ".join(message_parts)
    
    notification_data = {
        "booking_id": booking.id,
        "inspection_id": inspection.id,
        "vehicle_name": vehicle_name,
        "review_type": review_type,
        "severity_grade": final_severity,
        "original_severity": original_severity,
        "damage_detected": inspection.damage_detected,
        "damage_summary": inspection.damage_summary,
        "damage_cost_estimate": cost_estimate,
        "credit_adjustment": credit_adjustment,
        "old_credit_score": old_credit,
        "new_credit_score": new_credit,
        "refund_amount": refund_amount,
        "wallet_balance": user.wallet_balance,
        "admin_notes": review.admin_notes or "",
    }
    
    notification = models.Notification(
        user_id=user.id,
        booking_id=booking.id,
        type="review_complete",
        title=title,
        message=message,
        data_json=json.dumps(notification_data),
    )
    db.add(notification)
    
    db.commit()
    
    return {
        "message": "Review completed successfully",
        "final_severity": final_severity,
        "credit_adjustment": credit_adjustment,
        "new_credit_score": new_credit,
        "refund_processed": refund_amount,
        "notification_sent": True,
        "booking_status": "completed",
    }

@router.put("/{inspection_id}/severity")
def update_inspection_severity(
    inspection_id: int,
    severity_data: AdminReviewRequest,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Legacy: Update inspection severity grade only"""
    inspection = db.query(models.Inspection).filter(models.Inspection.id == inspection_id).first()
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
    if severity_data.severity_grade:
        inspection.severity_grade = severity_data.severity_grade
    inspection.admin_reviewed = True
    db.commit()
    return {"message": "Severity updated successfully", "admin_reviewed": True}

