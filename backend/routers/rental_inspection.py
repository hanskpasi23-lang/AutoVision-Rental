"""
Rental Inspection Router
Handles the complete rental inspection workflow including:
- Pre-rental inspection with 4-angle photo upload
- Post-rental inspection with comparison analysis
- Start/End rental lifecycle
- Refund calculation for early returns
"""
from fastapi import APIRouter, Depends, HTTPException, UploadFile, File, Form
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime
import os
import uuid
import json
import sys
sys.path.append('..')
import models, auth, database
from services.ai_damage_analyzer import damage_analyzer

router = APIRouter(
    prefix="/rental",
    tags=["rental"],
    responses={404: {"description": "Not found"}},
)

INSPECTION_UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads", "inspections")
os.makedirs(INSPECTION_UPLOAD_DIR, exist_ok=True)

async def save_inspection_image(file: UploadFile, booking_id: int, angle: str, inspection_type: str) -> str:
    """Save an inspection image and return the URL"""
    file_ext = file.filename.split(".")[-1].lower() if "." in file.filename else "jpg"
    filename = f"{booking_id}_{inspection_type}_{angle}_{uuid.uuid4()}.{file_ext}"
    filepath = os.path.join(INSPECTION_UPLOAD_DIR, filename)
    
    contents = await file.read()
    with open(filepath, "wb") as f:
        f.write(contents)
    
    return f"/uploads/inspections/{filename}"

@router.post("/pre-inspection/{booking_id}")
async def upload_pre_inspection(
    booking_id: int,
    front: UploadFile = File(...),
    back: UploadFile = File(...),
    left: UploadFile = File(...),
    right: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """
    Upload pre-rental inspection images (4 angles).
    AI will validate images and analyze for existing damage.
    """
    def log(msg):
        print(msg)
        with open("debug_pre_inspection.log", "a") as f:
            f.write(msg + "\n")

    log(f"[PRE-INSPECTION] Starting for booking_id={booking_id}, user={current_user.id}")
    
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        log(f"[PRE-INSPECTION] Booking {booking_id} not found for user {current_user.id}")
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.pre_inspection_complete:
        log(f"[PRE-INSPECTION] Booking {booking_id} already has pre-inspection")
        raise HTTPException(status_code=400, detail="Pre-inspection already completed")
    
    log(f"[PRE-INSPECTION] Booking found: status={booking.status}, vehicle_id={booking.vehicle_id}")
    
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    vehicle_make = vehicle.make if vehicle else ""
    vehicle_model = vehicle.model if vehicle else ""
    vehicle_year = vehicle.year if vehicle else 0
    
    log(f"[PRE-INSPECTION] Vehicle: {vehicle_make} {vehicle_model} {vehicle_year}")
    
    try:
        front_url = await save_inspection_image(front, booking_id, "front", "pre")
        back_url = await save_inspection_image(back, booking_id, "back", "pre")
        left_url = await save_inspection_image(left, booking_id, "left", "pre")
        right_url = await save_inspection_image(right, booking_id, "right", "pre")
        log(f"[PRE-INSPECTION] Images saved: {front_url}, {back_url}, {left_url}, {right_url}")
    except Exception as e:
        log(f"[PRE-INSPECTION] ERROR saving images: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Failed to save images: {str(e)}")
    
    images = {
        'front': front_url,
        'back': back_url,
        'left': left_url,
        'right': right_url
    }
    try:
        log(f"[PRE-INSPECTION] Starting AI analysis...")
        analysis_result = damage_analyzer.analyze_pre_rental(
            images,
            vehicle_make=vehicle_make,
            vehicle_model=vehicle_model,
            vehicle_year=vehicle_year
        )
        log(f"[PRE-INSPECTION] AI analysis complete: damage={analysis_result.get('damage_detected')}, can_proceed={analysis_result.get('can_proceed')}")
    except Exception as e:
        log(f"[PRE-INSPECTION] AI analysis ERROR: {e}")
        import traceback
        traceback.print_exc()
        analysis_result = {
            "validation_passed": True,
            "damage_detected": False,
            "can_proceed": True,
            "damage_count": 0,
            "damage_details": [],
            "severity_grade": "none",
            "summary": "AI analysis encountered an error. Manual review recommended.",
            "recommendation": "AI could not analyze the images automatically. An admin will review the inspection.",
        }
    
    if not analysis_result.get("validation_passed", True):
        log(f"[PRE-INSPECTION] AI rejected images: {analysis_result.get('message')}")
        raise HTTPException(
            status_code=400,
            detail={
                "error": analysis_result.get("error", "validation_failed"),
                "message": analysis_result.get("message", "Image validation failed. Please re-upload."),
                "failed_angle": analysis_result.get("failed_angle"),
            }
        )
    
    try:
        inspection = models.Inspection(
            booking_id=booking_id,
            type="pre_rental",
            front_image_url=front_url,
            back_image_url=back_url,
            left_image_url=left_url,
            right_image_url=right_url,
            ai_analysis_json=json.dumps(analysis_result),
            damage_detected=analysis_result['damage_detected'],
            damage_summary=analysis_result['summary'],
            severity_grade=analysis_result.get('severity_grade', 'none')
        )
        db.add(inspection)
        
        booking.status = "pre_inspection"
        booking.pre_inspection_complete = True
        db.commit()
        log(f"[PRE-INSPECTION] DB commit successful, inspection_id={inspection.id}")
    except Exception as e:
        log(f"[PRE-INSPECTION] DB ERROR: {e}")
        import traceback
        traceback.print_exc()
        raise HTTPException(status_code=500, detail=f"Database error: {str(e)}")
    
    return {
        "message": "Pre-inspection completed",
        "inspection_id": inspection.id,
        "analysis": analysis_result,
        "can_proceed": analysis_result['can_proceed']
    }

@router.post("/start/{booking_id}")
async def start_rental(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """
    Start the rental after pre-inspection is complete.
    Processes payment and activates the rental.
    """
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if not booking.pre_inspection_complete:
        raise HTTPException(status_code=400, detail="Pre-inspection must be completed first")
    
    pre_inspection = db.query(models.Inspection).filter(
        models.Inspection.booking_id == booking_id,
        models.Inspection.type == "pre_rental"
    ).first()
    if pre_inspection and pre_inspection.damage_detected:
        raise HTTPException(
            status_code=400,
            detail="Vehicle has pre-existing damage. Cannot start rental. Please cancel this booking."
        )
    
    if booking.status == "active":
        raise HTTPException(status_code=400, detail="Rental is already active")
    
    booking.paid_amount = booking.total_price
    booking.status = "active"
    
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    if vehicle:
        vehicle.status = "rented"
    
    db.commit()
    
    return {
        "message": "Rental started successfully",
        "booking_id": booking_id,
        "status": "active",
        "amount_paid": booking.paid_amount,
        "start_date": booking.start_date.isoformat() if booking.start_date else None,
        "end_date": booking.end_date.isoformat() if booking.end_date else None
    }

@router.post("/end/{booking_id}")
async def end_rental(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """
    End the rental early or on time.
    Calculates refund if ending early.
    """
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.status != "active":
        raise HTTPException(status_code=400, detail="Rental is not active")
    
    booking.actual_end_date = datetime.now()
    booking.status = "post_inspection"
    
    refund_amount = 0.0
    if booking.end_date and booking.actual_end_date < booking.end_date:
        vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
        if vehicle:
            remaining_days = (booking.end_date - booking.actual_end_date).days
            if remaining_days > 0:
                refund_amount = remaining_days * vehicle.daily_rate
                booking.refund_amount = refund_amount
    
    db.commit()
    
    return {
        "message": "Rental ended. Please complete post-inspection.",
        "booking_id": booking_id,
        "actual_end_date": booking.actual_end_date.isoformat(),
        "refund_amount": refund_amount,
        "next_step": "post_inspection"
    }

@router.post("/post-inspection/{booking_id}")
async def upload_post_inspection(
    booking_id: int,
    front: UploadFile = File(...),
    back: UploadFile = File(...),
    left: UploadFile = File(...),
    right: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """
    Upload post-rental inspection images (4 angles).
    AI will validate images, match vehicle, and compare with pre-rental to detect new damage.
    """
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.status != "post_inspection":
        raise HTTPException(status_code=400, detail="Rental must be ended first")
    
    if booking.post_inspection_complete:
        raise HTTPException(status_code=400, detail="Post-inspection already completed")
    
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    vehicle_make = vehicle.make if vehicle else ""
    vehicle_model = vehicle.model if vehicle else ""
    vehicle_year = vehicle.year if vehicle else 0
    
    pre_inspection = db.query(models.Inspection).filter(
        models.Inspection.booking_id == booking_id,
        models.Inspection.type == "pre_rental"
    ).first()
    
    front_url = await save_inspection_image(front, booking_id, "front", "post")
    back_url = await save_inspection_image(back, booking_id, "back", "post")
    left_url = await save_inspection_image(left, booking_id, "left", "post")
    right_url = await save_inspection_image(right, booking_id, "right", "post")
    
    post_images = {
        'front': front_url,
        'back': back_url,
        'left': left_url,
        'right': right_url
    }
    
    pre_images = {}
    pre_analysis = None
    if pre_inspection:
        pre_images = {
            'front': pre_inspection.front_image_url,
            'back': pre_inspection.back_image_url,
            'left': pre_inspection.left_image_url,
            'right': pre_inspection.right_image_url
        }
        pre_analysis = json.loads(pre_inspection.ai_analysis_json) if pre_inspection.ai_analysis_json else None
    
    try:
        analysis_result = damage_analyzer.analyze_post_rental(
            pre_images, post_images, pre_analysis,
            vehicle_make=vehicle_make,
            vehicle_model=vehicle_model,
            vehicle_year=vehicle_year
        )
    except Exception as e:
        import traceback
        traceback.print_exc()
        analysis_result = {
            "validation_passed": True,
            "new_damage_detected": False,
            "damage_detected": False,
            "can_proceed": True,
            "damage_count": 0,
            "damage_details": [],
            "severity_grade": "none",
            "credit_adjustment": 0,
            "damage_cost_estimate": 0.0,
            "summary": "AI analysis encountered an error. Manual admin review required.",
        }
    
    if not analysis_result.get("validation_passed", True):
        raise HTTPException(
            status_code=400,
            detail={
                "error": analysis_result.get("error", "validation_failed"),
                "message": analysis_result.get("message", "Image validation failed. Please re-upload."),
                "failed_angle": analysis_result.get("failed_angle"),
            }
        )
    
    inspection = models.Inspection(
        booking_id=booking_id,
        type="post_rental",
        front_image_url=front_url,
        back_image_url=back_url,
        left_image_url=left_url,
        right_image_url=right_url,
        ai_analysis_json=json.dumps(analysis_result),
        damage_detected=analysis_result['new_damage_detected'],
        damage_summary=analysis_result['summary'],
        severity_grade=analysis_result['severity_grade'],
        credit_adjustment=analysis_result['credit_adjustment'],
        damage_cost_estimate=analysis_result['damage_cost_estimate']
    )
    db.add(inspection)
    
    booking.post_inspection_complete = True
    booking.status = "pending_review"
    
    db.commit()
    
    return {
        "message": "Post-inspection submitted. Awaiting admin review.",
        "inspection_id": inspection.id,
        "analysis": analysis_result,
        "status": "pending_review",
        "ai_severity_grade": analysis_result['severity_grade'],
        "ai_damage_cost_estimate": analysis_result['damage_cost_estimate'],
        "ai_credit_adjustment": analysis_result['credit_adjustment'],
        "refund_amount": booking.refund_amount,
    }

@router.get("/active")
async def get_active_rental(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Get the user's current active rental if any"""
    booking = db.query(models.Booking).filter(
        models.Booking.user_id == current_user.id,
        models.Booking.status.in_(["active", "post_inspection"])
    ).first()
    
    if not booking:
        return {"active_rental": None}
    
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    
    return {
        "active_rental": {
            "booking_id": booking.id,
            "vehicle": {
                "id": vehicle.id if vehicle else None,
                "make": vehicle.make if vehicle else None,
                "model": vehicle.model if vehicle else None,
                "year": vehicle.year if vehicle else None,
                "image_url": vehicle.image_url if vehicle else None
            },
            "start_date": booking.start_date.isoformat() if booking.start_date else None,
            "end_date": booking.end_date.isoformat() if booking.end_date else None,
            "status": booking.status,
            "total_price": booking.total_price,
            "paid_amount": booking.paid_amount
        }
    }

@router.post("/cancel/{booking_id}")
async def cancel_booking(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Cancel a booking before it starts"""
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id,
        models.Booking.user_id == current_user.id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
    
    if booking.status == "active":
        raise HTTPException(status_code=400, detail="Cannot cancel an active rental. End it instead.")
    
    if booking.status == "completed":
        raise HTTPException(status_code=400, detail="Cannot cancel a completed rental")
    
    booking.status = "cancelled"
    
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == booking.vehicle_id).first()
    if vehicle and vehicle.status == "rented":
        vehicle.status = "available"
    
    db.commit()
    
    return {"message": "Booking cancelled successfully"}

@router.get("/results/{booking_id}")
async def get_inspection_results(
    booking_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Get the inspection results for a completed booking"""
    booking = db.query(models.Booking).filter(
        models.Booking.id == booking_id
    ).first()
    
    if not booking:
        raise HTTPException(status_code=404, detail="Booking not found")
        
    if booking.user_id != current_user.id and current_user.role != "admin":
        raise HTTPException(status_code=403, detail="Not authorized")
    
    inspection = db.query(models.Inspection).filter(
        models.Inspection.booking_id == booking_id,
        models.Inspection.type == "post_rental"
    ).first()
    
    if not inspection:
        raise HTTPException(status_code=404, detail="Inspection not found")
        
    return {
        "id": inspection.id,
        "booking_id": booking.id,
        "vehicle_name": f"{booking.vehicle.make} {booking.vehicle.model}" if booking.vehicle else "Unknown Vehicle",
        "severity_grade": inspection.severity_grade,
        "original_severity": inspection.severity_grade,
        "damage_detected": inspection.damage_detected,
        "damage_summary": inspection.damage_summary,
        "damage_cost_estimate": inspection.damage_cost_estimate,
        "credit_adjustment": inspection.credit_adjustment,
        "review_type": "Admin Review" if inspection.admin_reviewed else "AI Assessment",
        "admin_notes": "",
        "old_credit_score": current_user.credit_score - inspection.credit_adjustment,
        "new_credit_score": current_user.credit_score,
        "wallet_balance": current_user.wallet_balance,
        "refund_amount": booking.refund_amount,
        "front_image_url": inspection.front_image_url,
        "back_image_url": inspection.back_image_url,
        "left_image_url": inspection.left_image_url,
        "right_image_url": inspection.right_image_url
    }
