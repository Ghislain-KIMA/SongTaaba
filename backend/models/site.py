import uuid
from datetime import datetime, timezone
from extensions import db


class Site(db.Model):
    __tablename__ = "sites"

    id = db.Column(db.String(36), primary_key=True, default=lambda: str(uuid.uuid4()))
    nom = db.Column(db.String(255), nullable=False)
    url = db.Column(db.String(255), nullable=False)
    title_selector = db.Column(db.String(255))
    description_selector = db.Column(db.String(255))
    deadline_selector = db.Column(db.String(255))
    link_selector = db.Column(db.String(255))
    type_site = db.Column(db.String(100))
    actif = db.Column(db.Boolean, default=True)
    frequence_scraping = db.Column(db.Integer)  # en jours
    derniere_execution = db.Column(db.DateTime)
    methode_scraping = db.Column(db.String(50))

    # Relations
    bourses = db.relationship("Bourse", back_populates="site", cascade="all, delete-orphan")

    def __repr__(self):
        return f"<Site {self.nom}>"