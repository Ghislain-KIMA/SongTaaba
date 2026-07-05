from config import db
from models.site import Site

def create_site(data):
    site = Site(**data)
    db.session.add(site)
    db.session.commit()
    return site

def get_all_sites():
    return Site.query.all()
