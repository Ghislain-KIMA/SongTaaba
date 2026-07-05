import uuid
from extensions import db



class Bourse(db.Model):
    __tablename__ = "bourses"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    nom = db.Column(db.String(255), nullable=False)
    organisme = db.Column(db.String(255))
    montant = db.Column(db.Numeric(10, 2))
    niveau = db.Column(db.String(100))
    description = db.Column(db.Text)
    pays = db.Column(db.String(100))
    deadline = db.Column(db.Date)
    type = db.Column(db.String(100))
    lien_officiel = db.Column(db.String(255))
    site_id = db.Column(db.String(36), db.ForeignKey("sites.id"), nullable=False)

    # Relations
    site = db.relationship("Site", back_populates="bourses")
    utilisateurs = db.relationship("UsersBourses", back_populates="bourse", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Bourse {self.nom}>"