from app import db
from models.user import User


def get_all_users():
    return User.query.all()


def get_user_by_id(user_id):
    return User.query.get_or_404(user_id)


def get_user_by_email(email):
    return User.query.filter_by(email=email).first()


def create_user(data):
    if get_user_by_email(data.get("email")):
        return None, "Email déjà utilisé"

    user = User(
        nom=data["nom"],
        prenom=data["prenom"],
        email=data["email"],
        role=data.get("role", "user"),
    )
    user.set_password(data["password"])
    db.session.add(user)
    db.session.commit()
    return user, None


def update_user(user_id, data):
    user = get_user_by_id(user_id)
    for field in ("nom", "prenom", "role"):
        if field in data:
            setattr(user, field, data[field])
    if "password" in data:
        user.set_password(data["password"])
    db.session.commit()
    return user


def delete_user(user_id):
    user = get_user_by_id(user_id)
    db.session.delete(user)
    db.session.commit()