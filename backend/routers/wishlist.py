from fastapi import APIRouter, Depends, HTTPException, status
from sqlalchemy.orm import Session
from typing import List
import sys
sys.path.append('..')
import models, auth, database, schemas

router = APIRouter(
    prefix="/wishlist",
    tags=["wishlist"],
    responses={404: {"description": "Not found"}},
)

@router.post("/{vehicle_id}")
def add_to_wishlist(
    vehicle_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Add a vehicle to the user's wishlist"""
    vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if not vehicle:
        raise HTTPException(status_code=404, detail="Vehicle not found")

    existing = db.query(models.Wishlist).filter(
        models.Wishlist.user_id == current_user.id,
        models.Wishlist.vehicle_id == vehicle_id
    ).first()

    if existing:
        return {"message": "Vehicle already in wishlist"}

    wishlist_item = models.Wishlist(user_id=current_user.id, vehicle_id=vehicle_id)
    db.add(wishlist_item)
    db.commit()
    return {"message": "Vehicle added to wishlist"}

@router.delete("/{vehicle_id}")
def remove_from_wishlist(
    vehicle_id: int,
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Remove a vehicle from the user's wishlist"""
    item = db.query(models.Wishlist).filter(
        models.Wishlist.user_id == current_user.id,
        models.Wishlist.vehicle_id == vehicle_id
    ).first()

    if not item:
        raise HTTPException(status_code=404, detail="Item not found in wishlist")

    db.delete(item)
    db.commit()
    return {"message": "Vehicle removed from wishlist"}

@router.get("/", response_model=List[schemas.Vehicle])
def get_wishlist(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Get all vehicles in the user's wishlist"""
    items = db.query(models.Wishlist).filter(models.Wishlist.user_id == current_user.id).all()
    
    vehicles = []
    for item in items:
        if item.vehicle:
            vehicles.append(item.vehicle)
            
    return vehicles
