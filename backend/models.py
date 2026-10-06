from sqlalchemy import ForeignKey, Column, Integer, String, Boolean, Float, DateTime, Text
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
from database import Base

class User(Base):
    __tablename__ = "users"

    id = Column(Integer, primary_key=True, index=True)
    full_name = Column(String, index=True)
    email = Column(String, unique=True, index=True)
    hashed_password = Column(String)
    role = Column(String, default="user")
    is_active = Column(Boolean, default=True)
    credit_score = Column(Float, default=100.0)
    wallet_balance = Column(Float, default=0.0)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    verification_status = Column(String, default="unverified")
    verification_notes = Column(Text, nullable=True)

    documents = relationship("VerificationDocument", back_populates="user")

class VerificationDocument(Base):
    __tablename__ = "verification_documents"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    document_type = Column(String)
    image_url = Column(String)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User", back_populates="documents")

class Vehicle(Base):
    __tablename__ = "vehicles"

    id = Column(Integer, primary_key=True, index=True)
    make = Column(String, index=True)
    model = Column(String, index=True)
    year = Column(Integer)
    daily_rate = Column(Float)
    status = Column(String, default="available")
    image_url = Column(String, nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

class Booking(Base):
    __tablename__ = "bookings"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"))
    start_date = Column(DateTime)
    end_date = Column(DateTime)
    actual_end_date = Column(DateTime, nullable=True)
    total_price = Column(Float)
    paid_amount = Column(Float, default=0.0)
    refund_amount = Column(Float, default=0.0)
    status = Column(String, default="pending")
    pre_inspection_complete = Column(Boolean, default=False)
    post_inspection_complete = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    vehicle = relationship("Vehicle")

class Inspection(Base):
    __tablename__ = "inspections"

    id = Column(Integer, primary_key=True, index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"))
    type = Column(String)
    
    front_image_url = Column(String, nullable=True)
    back_image_url = Column(String, nullable=True)
    left_image_url = Column(String, nullable=True)
    right_image_url = Column(String, nullable=True)
    
    image_url = Column(String, nullable=True)
    
    ai_analysis_json = Column(Text, nullable=True)
    damage_detected = Column(Boolean, default=False)
    damage_summary = Column(Text, nullable=True)
    damage_cost_estimate = Column(Float, default=0.0)
    
    severity_grade = Column(String, nullable=True)
    credit_adjustment = Column(Float, default=0.0)
    
    admin_reviewed = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())
    
    booking = relationship("Booking")

class Notification(Base):
    __tablename__ = "notifications"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"), index=True)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
    type = Column(String)
    title = Column(String)
    message = Column(Text)
    data_json = Column(Text, nullable=True)
    is_read = Column(Boolean, default=False)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    booking = relationship("Booking")

class Wishlist(Base):
    __tablename__ = "wishlists"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    vehicle_id = Column(Integer, ForeignKey("vehicles.id"))
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    vehicle = relationship("Vehicle")

class CreditHistory(Base):
    __tablename__ = "credit_history"

    id = Column(Integer, primary_key=True, index=True)
    user_id = Column(Integer, ForeignKey("users.id"))
    change = Column(Float)
    reason = Column(String)
    booking_id = Column(Integer, ForeignKey("bookings.id"), nullable=True)
    created_at = Column(DateTime(timezone=True), server_default=func.now())

    user = relationship("User")
    booking = relationship("Booking")
