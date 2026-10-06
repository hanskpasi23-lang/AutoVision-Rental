from fastapi import APIRouter, Depends, HTTPException, status, UploadFile, File
from fastapi.responses import JSONResponse
from sqlalchemy.orm import Session
from typing import List, Optional
import os
import uuid
import shutil
import sys
sys.path.append('..')
import schemas, models, auth, database

router = APIRouter(
    prefix="/vehicles",
    tags=["vehicles"],
    responses={404: {"description": "Not found"}},
)

UPLOAD_DIR = os.path.join(os.path.dirname(os.path.dirname(__file__)), "uploads", "vehicles")
os.makedirs(UPLOAD_DIR, exist_ok=True)

@router.get("/", response_model=List[schemas.Vehicle])
def read_vehicles(skip: int = 0, limit: int = 100, db: Session = Depends(database.get_db)):
    vehicles = db.query(models.Vehicle).offset(skip).limit(limit).all()
    return vehicles

@router.post("/", response_model=schemas.Vehicle)
def create_vehicle(
    vehicle: schemas.VehicleCreate,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    db_vehicle = models.Vehicle(**vehicle.dict())
    db.add(db_vehicle)
    db.commit()
    db.refresh(db_vehicle)
    return db_vehicle

@router.post("/upload-image")
async def upload_vehicle_image(
    file: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_admin_user)
):
    """Upload a vehicle image and return the URL"""
    print(f"Upload request received: filename={file.filename}, content_type={file.content_type}")
    
    allowed_extensions = ["jpg", "jpeg", "png", "webp", "gif"]
    file_ext = file.filename.split(".")[-1].lower() if "." in file.filename else ""
    
    if file_ext not in allowed_extensions:
        raise HTTPException(
            status_code=400, 
            detail=f"Invalid file type '{file_ext}'. Allowed: {', '.join(allowed_extensions)}"
        )
    
    filename = f"{uuid.uuid4()}.{file_ext}"
    filepath = os.path.join(UPLOAD_DIR, filename)
    
    try:
        contents = await file.read()
        with open(filepath, "wb") as buffer:
            buffer.write(contents)
        print(f"File saved successfully: {filepath}")
    except Exception as e:
        print(f"Failed to save file: {str(e)}")
        raise HTTPException(status_code=500, detail=f"Failed to save file: {str(e)}")
    
    image_url = f"/uploads/vehicles/{filename}"
    return {"image_url": image_url, "filename": filename}

@router.get("/{vehicle_id}", response_model=schemas.Vehicle)
def read_vehicle(vehicle_id: int, db: Session = Depends(database.get_db)):
    db_vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if db_vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    return db_vehicle

@router.put("/{vehicle_id}", response_model=schemas.Vehicle)
def update_vehicle(
    vehicle_id: int,
    vehicle_update: schemas.VehicleUpdate,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    db_vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if db_vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    for key, value in vehicle_update.dict(exclude_unset=True).items():
        setattr(db_vehicle, key, value)
    
    db.commit()
    db.refresh(db_vehicle)
    return db_vehicle

@router.delete("/{vehicle_id}", response_model=schemas.Vehicle)
def delete_vehicle(
    vehicle_id: int,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    db_vehicle = db.query(models.Vehicle).filter(models.Vehicle.id == vehicle_id).first()
    if db_vehicle is None:
        raise HTTPException(status_code=404, detail="Vehicle not found")
    
    if db_vehicle.image_url:
        image_path = os.path.join(os.path.dirname(os.path.dirname(__file__)), db_vehicle.image_url.lstrip('/'))
        if os.path.exists(image_path):
            try:
                os.remove(image_path)
            except:
                pass
    
    db.delete(db_vehicle)
    db.commit()
    return db_vehicle

