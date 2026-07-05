# from flask import request
# from flask_restful import Resource
# from marshmallow import ValidationError
# from models.user import User, db
# from schemas.user_schema import UserSchema
# from sqlalchemy.exc import IntegrityError



# class UserResource(Resource):
#     user_schema = UserSchema()
#     user_list_schema = UserSchema(many=True)

#     def get(self, user_id=None):
#         if user_id:
#             user = User.query.get_or_404(user_id)
#             return self.user_schema.dump(user)
#         else:
#             all_users = User.query.all()
#             return self.user_list_schema.dump(all_users)

#     def post(self):
#         data = request.json

#         # Vérification avant insertion
#         existing_user = User.query.filter_by(email=data.get("email")).first()
#         if existing_user:
#             return {"message": "Email already exists"}, 400

#         try:
#             # Validation avec Marshmallow
#             new_user = self.user_schema.load(data)
#             db.session.add(new_user)
#             db.session.commit()
#             return self.user_schema.dump(new_user), 201

#         except ValidationError as err:
#             return {"message": "Validation error", "errors": err.messages}, 400

#         except IntegrityError:
#             # Filet de sécurité en cas de concurrence
#             db.session.rollback()


#     def put(self, user_id):
#         user = User.query.get_or_404(user_id)
#         try:
#             updated_user = self.user_schema.load(request.json, instance=user, partial=True)
#         except ValidationError as err:
#             return {"message": "Validation error", "errors": err.messages}, 400

#         db.session.commit()
#         return self.user_schema.dump(updated_user)

#     def delete(self, user_id):
#         user = User.query.get_or_404(user_id)
#         db.session.delete(user)
#         db.session.commit()
#         return {"message": "User deleted successfully"}, 200


from config import db
from models.user import User

def create_user(data):
    user = User(**data)
    db.session.add(user)
    db.session.commit()
    return user

def get_all_users():
    return User.query.all()
