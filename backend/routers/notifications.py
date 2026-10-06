from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
import json
import sys
sys.path.append('..')
import models, auth, database

router = APIRouter(
    prefix="/notifications",
    tags=["notifications"],
    responses={404: {"description": "Not found"}},
)

@router.get("/")
def get_my_notifications(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    """Get current user's notifications, newest first."""
    notifications = (
        db.query(models.Notification)
        .filter(models.Notification.user_id == current_user.id)
        .order_by(models.Notification.created_at.desc())
        .limit(50)
        .all()
    )
    
    return [
        {
            "id": n.id,
            "type": n.type,
            "title": n.title,
            "message": n.message,
            "data": json.loads(n.data_json) if n.data_json else None,
            "is_read": n.is_read,
            "booking_id": n.booking_id,
            "created_at": n.created_at.isoformat() if n.created_at else None,
        }
        for n in notifications
    ]

@router.get("/unread-count")
def get_unread_count(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    """Get count of unread notifications."""
    count = (
        db.query(models.Notification)
        .filter(
            models.Notification.user_id == current_user.id,
            models.Notification.is_read == False
        )
        .count()
    )
    return {"unread_count": count}

@router.put("/{notification_id}/read")
def mark_as_read(
    notification_id: int,
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    """Mark a notification as read."""
    notification = db.query(models.Notification).filter(
        models.Notification.id == notification_id,
        models.Notification.user_id == current_user.id
    ).first()
    
    if not notification:
        raise HTTPException(status_code=404, detail="Notification not found")
    
    notification.is_read = True
    db.commit()
    return {"message": "Notification marked as read"}

@router.put("/read-all")
def mark_all_as_read(
    current_user: models.User = Depends(auth.get_current_active_user),
    db: Session = Depends(database.get_db)
):
    """Mark all notifications as read."""
    db.query(models.Notification).filter(
        models.Notification.user_id == current_user.id,
        models.Notification.is_read == False
    ).update({"is_read": True})
    db.commit()
    return {"message": "All notifications marked as read"}
