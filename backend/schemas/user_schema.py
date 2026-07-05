# from extensions import ma
# from models.user import User
# from marshmallow import fields, validate


# class UserSchema(ma.SQLAlchemyAutoSchema):
#     class Meta:
#         model = User
#         load_instance = True
#         exclude = ("password",)

#     email = fields.Email(required=True)
#     nom = fields.String(required=True, validate=validate.Length(min=1, max=50))
#     prenom = fields.String(required=True, validate=validate.Length(min=1, max=100))
#     password = fields.String(load_only=True, required=True, validate=validate.Length(min=6))
#     role = fields.String(validate=validate.OneOf(["user", "admin"]))
#     datetime_inscription = fields.DateTime(dump_only=True)


# user_schema = UserSchema()
# users_schema = UserSchema(many=True)


# from extensions import ma
# from models.user import User
# from marshmallow import fields, validate


# class UserSchema(ma.SQLAlchemyAutoSchema):
#     class Meta:
#         model = User
#         load_instance = False        # ← changer True en False
#         exclude = ("password",)      # exclut du dump (réponse)
#         load_only = ("password",)    # ← ajouter cette ligne

#     email = fields.Email(required=True)
#     nom = fields.String(required=True, validate=validate.Length(min=1, max=50))
#     prenom = fields.String(required=True, validate=validate.Length(min=1, max=100))
#     password = fields.String(
#         load_only=True,
#         required=True,
#         validate=validate.Length(min=6)
#     )
#     role = fields.String(validate=validate.OneOf(["user", "admin"]))
#     datetime_inscription = fields.DateTime(dump_only=True)


# user_schema = UserSchema()
# users_schema = UserSchema(many=True)


from extensions import ma
from marshmallow import Schema, fields, validate


class UserSchema(Schema):
    id = fields.String(dump_only=True)
    nom = fields.String(required=True, validate=validate.Length(min=1, max=50))
    prenom = fields.String(required=True, validate=validate.Length(min=1, max=100))
    email = fields.Email(required=True)
    password = fields.String(
        load_only=True,
        required=True,
        validate=validate.Length(min=6)
    )
    role = fields.String(dump_only=True)
    datetime_inscription = fields.DateTime(dump_only=True)


user_schema = UserSchema()
users_schema = UserSchema(many=True)
