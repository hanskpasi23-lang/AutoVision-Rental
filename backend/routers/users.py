from fastapi import APIRouter, Depends, HTTPException, status, File, UploadFile
from sqlalchemy.orm import Session
from datetime import timedelta
from typing import List
import sys
sys.path.append('..')
import schemas, models, auth, database

router = APIRouter(
    prefix="/users",
    tags=["users"],
    responses={404: {"description": "Not found"}},
)

@router.post("/", response_model=schemas.UserSchema)
def create_user(user: schemas.UserCreate, db: Session = Depends(database.get_db)):
    email_lower = user.email.lower()
    
    db_user = db.query(models.User).filter(models.User.email == email_lower).first()
    if db_user:
        raise HTTPException(status_code=400, detail="Email already registered")
    hashed_password = auth.get_password_hash(user.password)
    new_user = models.User(email=email_lower, hashed_password=hashed_password, full_name=user.full_name)
    db.add(new_user)
    db.commit()
    db.refresh(new_user)
    return new_user

@router.post("/token", response_model=schemas.Token)
def login_for_access_token(form_data: schemas.UserLogin, db: Session = Depends(database.get_db)):
    email_lower = form_data.email.lower()
    
    user = db.query(models.User).filter(models.User.email == email_lower).first()
    if not user or not auth.verify_password(form_data.password, user.hashed_password):
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Incorrect username or password",
            headers={"WWW-Authenticate": "Bearer"},
        )
    access_token_expires = timedelta(minutes=auth.ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = auth.create_access_token(
        data={"sub": user.email, "role": user.role}, expires_delta=access_token_expires
    )
    return {"access_token": access_token, "token_type": "bearer"}

@router.get("/me", response_model=schemas.UserSchema)
def read_users_me(current_user: models.User = Depends(auth.get_current_active_user)):
    return current_user

@router.get("/me/credit-history", response_model=List[schemas.CreditHistory])
def get_credit_history(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Get credit history for the current user"""
    history = db.query(models.CreditHistory).filter(
        models.CreditHistory.user_id == current_user.id
    ).order_by(models.CreditHistory.created_at.desc()).all()
    
    return history

@router.get("/", response_model=List[schemas.UserSchema])
def get_all_users(
    skip: int = 0,
    limit: int = 100,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get all users (Admin only)"""
    users = db.query(models.User).offset(skip).limit(limit).all()
    return users

@router.put("/{user_id}/role")
def update_user_role(
    user_id: int,
    role_data: schemas.RoleUpdate,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Update user role (Admin only)"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.role = role_data.role
    db.commit()
    return {"message": "Role updated successfully"}

@router.put("/{user_id}/toggle-status")
def toggle_user_status(
    user_id: int,
    status_data: schemas.StatusUpdate,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Toggle user active status (Admin only)"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    user.is_active = status_data.is_active
    db.commit()
    return {"message": "Status updated successfully"}

@router.post("/verification-documents", response_model=schemas.VerificationDocument)
def upload_verification_document(
    document_type: str,
    file: UploadFile = File(...),
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Upload a verification document (license_front, license_back, selfie, id_card)"""
    import shutil
    import os
    import uuid

    allowed_types = ["license_front", "license_back", "selfie", "id_card"]
    if document_type not in allowed_types:
        raise HTTPException(status_code=400, detail="Invalid document type")

    upload_dir = "uploads/verification_documents"
    os.makedirs(upload_dir, exist_ok=True)

    file_extension = os.path.splitext(file.filename)[1]
    file_name = f"{current_user.id}_{document_type}_{uuid.uuid4()}{file_extension}"
    file_path = f"{upload_dir}/{file_name}"
    
    with open(file_path, "wb") as buffer:
        shutil.copyfileobj(file.file, buffer)

    image_url = f"/uploads/verification_documents/{file_name}"

    db_document = models.VerificationDocument(
        user_id=current_user.id,
        document_type=document_type,
        image_url=image_url
    )
    db.add(db_document)
    
    if current_user.verification_status != "verified":
        current_user.verification_status = "pending"
    
    db.commit()
    db.refresh(db_document)
    return db_document

@router.get("/verification", response_model=List[schemas.VerificationDocument])
def get_my_verification_documents(
    current_user: models.User = Depends(auth.get_current_user),
    db: Session = Depends(database.get_db)
):
    """Get my uploaded verification documents"""
    return db.query(models.VerificationDocument).filter(models.VerificationDocument.user_id == current_user.id).all()

@router.get("/admin/{user_id}/verification", response_model=List[schemas.VerificationDocument])
def get_user_verification_documents(
    user_id: int,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Get a user's verification documents (Admin only)"""
    return db.query(models.VerificationDocument).filter(models.VerificationDocument.user_id == user_id).all()

@router.post("/admin/{user_id}/verify")
def verify_user(
    user_id: int,
    status_update: schemas.UserVerificationStatusUpdate,
    current_user: models.User = Depends(auth.get_current_admin_user),
    db: Session = Depends(database.get_db)
):
    """Approve or Reject user verification (Admin only)"""
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        raise HTTPException(status_code=404, detail="User not found")
    
    user.verification_status = status_update.verification_status
    user.verification_notes = status_update.verification_notes
    
    db.commit()
    return {"message": f"User verification status updated to {status_update.verification_status}"}

