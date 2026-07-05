from datetime import datetime, timezone
from extensions import db


class UsersBourses(db.Model):
    __tablename__ = "users_bourses"

    user_id = db.Column(db.String(36), db.ForeignKey("users.id"), primary_key=True)
    bourse_id = db.Column(db.String(36), db.ForeignKey("bourses.id"), primary_key=True)
    datetime_interet = db.Column(db.DateTime, default=lambda: datetime.now(timezone.utc))
    statut = db.Column(db.String(50), default="interessé")

    # Relations
    user = db.relationship("User", back_populates="bourses")
    bourse = db.relationship("Bourse", back_populates="utilisateurs")

    def __repr__(self):
        return f"<UsersBourses user={self.user_id} bourse={self.bourse_id}>"