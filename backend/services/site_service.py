from app import db
from models.site import Site


def get_all_sites(actif=None):
    query = Site.query
    if actif is not None:
        query = query.filter_by(actif=actif)
    return query.all()


def get_site_by_id(site_id):
    return Site.query.get_or_404(site_id)


def create_site(data):
    site = Site(**data)
    db.session.add(site)
    db.session.commit()
    return site


def update_site(site_id, data):
    site = get_site_by_id(site_id)
    for key, value in data.items():
        setattr(site, key, value)
    db.session.commit()
    return site


def delete_site(site_id):
    site = get_site_by_id(site_id)
    db.session.delete(site)
    db.session.commit()