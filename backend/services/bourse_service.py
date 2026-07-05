from app import db
from models.bourse import Bourse


def get_all_bourses(pays=None, niveau=None, type_=None):
    query = Bourse.query
    if pays:
        query = query.filter_by(pays=pays)
    if niveau:
        query = query.filter_by(niveau=niveau)
    if type_:
        query = query.filter_by(type=type_)
    return query.all()


def get_bourse_by_id(bourse_id):
    return Bourse.query.get_or_404(bourse_id)


def create_bourse(data):
    bourse = Bourse(**data)
    db.session.add(bourse)
    db.session.commit()
    return bourse


def update_bourse(bourse_id, data):
    bourse = get_bourse_by_id(bourse_id)
    for key, value in data.items():
        setattr(bourse, key, value)
    db.session.commit()
    return bourse


def delete_bourse(bourse_id):
    bourse = get_bourse_by_id(bourse_id)
    db.session.delete(bourse)
    db.session.commit()