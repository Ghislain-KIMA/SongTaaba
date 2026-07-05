from app import db
from models.users_bourses import UsersBourses


def get_bourses_by_user(user_id):
    return UsersBourses.query.filter_by(user_id=user_id).all()


def get_users_by_bourse(bourse_id):
    return UsersBourses.query.filter_by(bourse_id=bourse_id).all()


def add_interet(user_id, bourse_id, statut="interessé"):
    existing = UsersBourses.query.filter_by(user_id=user_id, bourse_id=bourse_id).first()
    if existing:
        return None, "Intérêt déjà enregistré"

    entry = UsersBourses(user_id=user_id, bourse_id=bourse_id, statut=statut)
    db.session.add(entry)
    db.session.commit()
    return entry, None


def update_statut(user_id, bourse_id, statut):
    entry = UsersBourses.query.filter_by(user_id=user_id, bourse_id=bourse_id).first_or_404()
    entry.statut = statut
    db.session.commit()
    return entry


def remove_interet(user_id, bourse_id):
    entry = UsersBourses.query.filter_by(user_id=user_id, bourse_id=bourse_id).first_or_404()
    db.session.delete(entry)
    db.session.commit()