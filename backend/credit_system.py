from sqlalchemy.orm import Session
import models

def update_user_credit_score(db: Session, user_id: int, score_change: float, reason: str):
    user = db.query(models.User).filter(models.User.id == user_id).first()
    if not user:
        return None
    
    user.credit_score += score_change
    
    if user.credit_score < 0:
        user.credit_score = 0.0
    if user.credit_score > 100:
        user.credit_score = 100.0

    db.commit()
    db.refresh(user)
    return user
