from pydantic import BaseModel, EmailStr
from typing import Optional, List

class UserBase(BaseModel):
    email: EmailStr
    full_name: Optional[str] = None

class UserCreate(UserBase):
    password: str

class UserLogin(BaseModel):
    email: EmailStr
    password: str

class VerificationDocumentBase(BaseModel):
    document_type: str
    image_url: str

class VerificationDocumentCreate(VerificationDocumentBase):
    pass

class VerificationDocument(VerificationDocumentBase):
    id: int
    user_id: int
    created_at: datetime

    class Config:
        from_attributes = True

class UserSchema(UserBase):
    id: int
    role: str
    credit_score: float
    is_active: bool
    verification_status: str
    verification_notes: Optional[str] = None
    documents: List[VerificationDocument] = []

    class Config:
        from_attributes = True

class UserVerificationStatusUpdate(BaseModel):
    verification_status: str
    verification_notes: Optional[str] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    email: Optional[str] = None
    role: Optional[str] = None

class VehicleBase(BaseModel):
    make: str
    model: str
    year: int
    daily_rate: float
    status: Optional[str] = "available"
    image_url: Optional[str] = None

class VehicleCreate(VehicleBase):
    pass

class VehicleUpdate(BaseModel):
    make: Optional[str] = None
    model: Optional[str] = None
    year: Optional[int] = None
    daily_rate: Optional[float] = None
    status: Optional[str] = None
    image_url: Optional[str] = None

class Vehicle(VehicleBase):
    id: int
    
    class Config:
        from_attributes = True

from datetime import datetime

class BookingBase(BaseModel):
    vehicle_id: int
    start_date: datetime
    end_date: datetime

class BookingCreate(BookingBase):
    pass

class Booking(BookingBase):
    id: int
    user_id: int
    total_price: float
    paid_amount: float = 0.0
    refund_amount: float = 0.0
    status: str
    created_at: datetime
    vehicle: Optional[Vehicle] = None
    
    class Config:
        from_attributes = True

class BookingStatusUpdate(BaseModel):
    status: str

class InspectionBase(BaseModel):
    booking_id: int
    type: str
    image_url: str

class InspectionCreate(InspectionBase):
    pass

class Inspection(InspectionBase):
    id: int
    front_image_url: Optional[str] = None
    back_image_url: Optional[str] = None
    left_image_url: Optional[str] = None
    right_image_url: Optional[str] = None
    ai_analysis_json: Optional[str] = None
    severity_grade: Optional[str] = None
    admin_reviewed: bool
    created_at: datetime

    class Config:
        from_attributes = True

class RoleUpdate(BaseModel):
    role: str

class StatusUpdate(BaseModel):
    is_active: bool

class InspectionReview(BaseModel):
    admin_reviewed: bool

class SeverityUpdate(BaseModel):
    severity_grade: str

class CreditHistory(BaseModel):
    id: int
    user_id: int
    change: float
    reason: str
    booking_id: Optional[int] = None
    created_at: datetime

    class Config:
        from_attributes = True
