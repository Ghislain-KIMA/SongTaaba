from config import db
from models.users_bourses import UsersBourses

def add_user_bourse(data):
    relation = UsersBourses(**data)
    db.session.add(relation)
    db.session.commit()
    return relation
